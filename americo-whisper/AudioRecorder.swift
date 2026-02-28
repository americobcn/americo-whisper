//
//  AudioRecorder.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioSamples: [Float] = []
    
    private var audioEngine: AVAudioEngine?

    func startRecording() {
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            guard granted else {
                print("Microphone access denied")
                return
            }
            
            DispatchQueue.main.async {
                self.setupAudioEngine()
            }
        }
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

    deinit {
        if isRecording {
            stopRecording()
        }
    }
}
