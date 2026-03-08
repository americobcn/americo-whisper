//
//  AudioRecorder.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import AVFoundation

@MainActor @Observable
class AudioRecorder: NSObject {
    var isRecording = false
    var audioSamples: [Float] = []

    private var audioEngine: AVAudioEngine?

    func startRecording() async {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        guard granted else {
            print("Microphone access denied")
            return
        }
        setupAudioEngine()
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()

        guard let inputNode = audioEngine?.inputNode else { return }

        // Whisper expects 16kHz mono
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )

        guard let recordingFormat = recordingFormat else { return }

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: recordingFormat
        ) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        audioEngine?.prepare()

        do {
            try audioEngine?.start()
            isRecording = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(
            from: 0,
            to: Int(buffer.frameLength),
            by: buffer.stride
        ).map { channelDataValue[$0] }

        audioSamples.append(contentsOf: channelDataValueArray)
    }

    @discardableResult
    func stopRecording() -> [Float] {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        isRecording = false

        let samples = audioSamples
        audioSamples = []
        return samples
    }

}
