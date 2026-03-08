//
//  RecordingControls.swift
//  americo-whisper
//
//  Created by Americo Cot on 08/03/26.
//

import SwiftUI

struct RecordingControls: View {
    let isRecording: Bool
    let isTranscribing: Bool
    let onToggle: () -> Void
    @Binding var audioSource: AudioSource

    var body: some View {
        VStack(spacing: 12) {
            Picker("Source", selection: $audioSource) {
                ForEach(AudioSource.allCases, id: \.self) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isRecording || isTranscribing)

            Button(action: onToggle) {
                HStack {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 40))
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
                .foregroundStyle(isRecording ? .red : .blue)
            }
            .buttonStyle(.plain)
            .disabled(isTranscribing)
        }
    }
}
