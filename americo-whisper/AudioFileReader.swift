//
//  AudioFileReader.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import AVFoundation
import Foundation

enum AudioFileError: LocalizedError {
    case fileNotFound
    case unableToOpenFile
    case unsupportedFormat
    case conversionFailed
    case noAudioData
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Audio file not found"
        case .unableToOpenFile:
            return "Unable to open audio file"
        case .unsupportedFormat:
            return "Unsupported audio format"
        case .conversionFailed:
            return "Failed to convert audio format"
        case .noAudioData:
            return "No audio data found in file"
        }
    }
}

struct AudioFileReader {
    static let supportedExtensions: Set<String> = [
        "wav", "mp3", "m4a", "aac", "flac", "caf", "aiff", "aif", "mp4", "m4b", "ogg"
    ]
    
    static func readAudioFile(from url: URL) async throws -> [Float] {
        try await Task.detached(priority: .userInitiated) {
            try Self.loadAudioFileSync(from: url)
        }.value
    }
    
    static func loadAudioFileSync(from url: URL) throws -> [Float] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioFileError.fileNotFound
        }
        
        let audioFile = try AVAudioFile(forReading: url)
        
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        
        guard let targetFormat = targetFormat else {
            throw AudioFileError.conversionFailed
        }
        
        let sourceFormat = audioFile.processingFormat
        let frameCount = UInt32(audioFile.length)
        
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw AudioFileError.conversionFailed
        }
        
        let estimatedFrameCount = AVAudioFrameCount(
            Double(frameCount) * targetFormat.sampleRate / sourceFormat.sampleRate
        ) + 1024
        
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: estimatedFrameCount
        ) else {
            throw AudioFileError.conversionFailed
        }
        
        guard let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: frameCount
        ) else {
            throw AudioFileError.conversionFailed
        }

        try audioFile.read(into: inputBuffer, frameCount: frameCount)
        
        var inputPosition: UInt32 = 0
        let inputTotalFrames = inputBuffer.frameLength
        
        converter.convert(to: outputBuffer, error: nil) { outNumFrames, outStatus in
            if inputPosition >= inputTotalFrames {
                outStatus.pointee = .noDataNow
                return nil
            }
            
            let framesAvailable = inputTotalFrames - inputPosition
            let framesToRead = min(framesAvailable, outNumFrames)
            
            guard let inputBufferSlice = AVAudioPCMBuffer(
                pcmFormat: sourceFormat,
                frameCapacity: framesToRead
            ) else {
                outStatus.pointee = .endOfStream
                return nil
            }
            inputBufferSlice.frameLength = framesToRead
            
            if let srcData = inputBuffer.floatChannelData,
               let dstData = inputBufferSlice.floatChannelData {
                for channel in 0..<Int(sourceFormat.channelCount) {
                    memcpy(
                        dstData[channel],
                        srcData[channel].advanced(by: Int(inputPosition)),
                        Int(framesToRead) * MemoryLayout<Float>.size
                    )
                }
            }
            
            inputPosition += framesToRead
            outStatus.pointee = .haveData
            return inputBufferSlice
        }
        
        guard let floatData = outputBuffer.floatChannelData else {
            throw AudioFileError.noAudioData
        }
        
        let frameLength = Int(outputBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(
            start: floatData[0],
            count: frameLength
        ))
        
        guard !samples.isEmpty else {
            throw AudioFileError.noAudioData
        }
        
        return samples
    }
    
    static func loadAudioInChunks(
        from url: URL,
        chunkDuration: Double = 30.0,
        onChunk: ([Float]) async throws -> Void
    ) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioFileError.fileNotFound
        }

        let audioFile = try AVAudioFile(forReading: url)
        let sourceFormat = audioFile.processingFormat

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioFileError.conversionFailed
        }

        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw AudioFileError.conversionFailed
        }

        // Source frames per chunk (e.g. 48000×30 = 1_440_000 → ~11 MB Float32 stereo)
        let sourceFramesPerChunk = AVAudioFrameCount(chunkDuration * sourceFormat.sampleRate)
        // Output frames per chunk (16000×30 = 480_000 → ~2 MB Float32 mono)
        let outputFramesPerChunk = AVAudioFrameCount(chunkDuration * targetFormat.sampleRate) + 1024

        // Reusable buffers — allocated once, reused every iteration
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: sourceFramesPerChunk),
              let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFramesPerChunk) else {
            throw AudioFileError.conversionFailed
        }

        // AVAudioConverter is stateful: keep alive across chunks so resampler
        // filter tail is preserved at chunk boundaries
        while audioFile.framePosition < audioFile.length {
            let remaining = AVAudioFrameCount(min(
                Int64(sourceFramesPerChunk),
                audioFile.length - audioFile.framePosition
            ))

            inputBuffer.frameLength = 0
            outputBuffer.frameLength = 0
            try audioFile.read(into: inputBuffer, frameCount: remaining)

            var inputPos: AVAudioFrameCount = 0

            converter.convert(to: outputBuffer, error: nil) { outFrames, outStatus in
                let available = inputBuffer.frameLength - inputPos
                if available == 0 {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                let toProvide = min(available, outFrames)
                guard let slice = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: toProvide) else {
                    outStatus.pointee = .endOfStream
                    return nil
                }
                slice.frameLength = toProvide
                if let src = inputBuffer.floatChannelData,
                   let dst = slice.floatChannelData {
                    for ch in 0..<Int(sourceFormat.channelCount) {
                        memcpy(
                            dst[ch],
                            src[ch].advanced(by: Int(inputPos)),
                            Int(toProvide) * MemoryLayout<Float>.size
                        )
                    }
                }
                inputPos += toProvide
                outStatus.pointee = .haveData
                return slice
            }

            guard let floatData = outputBuffer.floatChannelData else { continue }
            let count = Int(outputBuffer.frameLength)
            if count > 0 {
                let samples = Array(UnsafeBufferPointer(start: floatData[0], count: count))
                try await onChunk(samples)
            }
        }
    }

    static func isSupported(url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
}
