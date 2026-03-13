//
//  TranscriptionOutputView.swift
//  americo-whisper
//
//  Created by Americo Cot on 08/03/26.
//

import SwiftUI

struct TranscriptionOutputView: View {
    let transcription: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !transcription.isEmpty {
                Text("Transcription")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Text(transcription.isEmpty ? "Transcription will appear here..." : transcription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .foregroundStyle(transcription.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled)
                    .font(.body)
            }
            .frame(maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
            .shadow(radius: 10)
        }
    }
}
