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

    var body: some View {
        VStack(spacing: 12) {
            Text("Record from Microphone")
                .font(.headline)
                .foregroundStyle(.secondary)

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
