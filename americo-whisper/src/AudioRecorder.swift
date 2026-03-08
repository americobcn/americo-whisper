//
//  AudioRecorder.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

@preconcurrency import AVFoundation

@MainActor @Observable
class AudioRecorder: NSObject {
    var isRecording = false
    var audioSamples: [Float] = []

    private var audioEngine: AVAudioEngine?
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 16000,
        channels: 1,
        interleaved: false
    )!

    func startRecording() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        guard granted else {
            print("Microphone access denied")
            return
        }
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        let engine = AVAudioEngine()
        audioEngine = engine

        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: hwFormat, to: targetFormat) else {
            print("Failed to create audio converter")
            return
        }

        let targetFmt = self.targetFormat

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hwFormat) { [weak self] buffer, _ in
            let frameCapacity = AVAudioFrameCount(
                Double(buffer.frameLength) * targetFmt.sampleRate / hwFormat.sampleRate
            ) + 256

            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: targetFmt,
                frameCapacity: frameCapacity
            ) else { return }

            var error: NSError?
            var hasProvided = false
            converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                if hasProvided {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                hasProvided = true
                outStatus.pointee = .haveData
                return buffer
            }

            guard let self,
                  let channelData = outputBuffer.floatChannelData,
                  outputBuffer.frameLength > 0 else { return }
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: Int(outputBuffer.frameLength)))
            self.audioSamples.append(contentsOf: samples)
        }

        engine.prepare()

        do {
            try engine.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    @discardableResult
    func stopRecording() -> [Float] {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false

        let samples = audioSamples
        audioSamples = []
        return samples
    }

}
