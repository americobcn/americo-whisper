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
    
    static func isSupported(url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
}
