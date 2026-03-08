//
//  SystemAudioCapture.swift
//  americo-whisper
//
//  Created by Americo Cot on 09/03/26.
//

import CoreMedia
import ScreenCaptureKit

@MainActor @Observable
class SystemAudioCapture: NSObject {
    var isCapturing = false

    private var stream: SCStream?
    private nonisolated(unsafe) let bufferLock = NSLock()
    private nonisolated(unsafe) var _audioBuffer: [Float] = []

    func startCapturing() async throws {
        let content = try await SCShareableContent.current
        guard let display = content.displays.first else { throw CaptureError.noDisplayFound }

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 16_000
        config.channelCount = 1
        config.excludesCurrentProcessAudio = true
        // Minimize video overhead — display filter always produces video frames
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        bufferLock.lock(); _audioBuffer = []; bufferLock.unlock()

        let newStream = SCStream(filter: filter, configuration: config, delegate: nil)
        try newStream.addStreamOutput(self, type: .audio, sampleHandlerQueue: nil)
        // Register no-op screen handler to silence "_SCStream_RemoteVideoQueueOperationHandlerWithError" errors
        try newStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: nil)
        try await newStream.startCapture()
        stream = newStream
        isCapturing = true
    }

    func drainSamples() -> [Float] {
        bufferLock.lock()
        defer { _audioBuffer = []; bufferLock.unlock() }
        return _audioBuffer
    }

    func stopCapturing() -> [Float] {
        let remaining = drainSamples()
        Task { [stream] in try? await stream?.stopCapture() }
        stream = nil
        isCapturing = false
        return remaining
    }

    enum CaptureError: LocalizedError {
        case noDisplayFound

        var errorDescription: String? {
            switch self {
            case .noDisplayFound:
                return "No display found for system audio capture."
            }
        }
    }
}

extension SystemAudioCapture: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }

        var blockBuffer: CMBlockBuffer?
        var audioBufferList = AudioBufferList()
        var bufferListSize = 0

        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &bufferListSize,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
            blockBufferOut: &blockBuffer
        )

        guard status == noErr, audioBufferList.mNumberBuffers > 0 else { return }

        let buf = audioBufferList.mBuffers
        guard let data = buf.mData else { return }
        let count = Int(buf.mDataByteSize) / MemoryLayout<Float>.size
        let samples = Array(UnsafeBufferPointer(
            start: data.bindMemory(to: Float.self, capacity: count),
            count: count
        ))

        bufferLock.lock()
        _audioBuffer.append(contentsOf: samples)
        bufferLock.unlock()
    }
}
