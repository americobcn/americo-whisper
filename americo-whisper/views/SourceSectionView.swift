//
//  SourceSectionView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct SourceSectionView: View {
    let availableSources: [AudioSource]
    @Binding var selectedSource: AudioSource
    let isRecording: Bool
    let isTranscribing: Bool
    @State private var showSourcePicker = false

    var body: some View {
        VStack {
            Text("Source:")
                .font(.headline)

            Button(action: { showSourcePicker = true }) {
                HStack {
                    Image(systemName: "mic")
                    Text(selectedSource.displayName)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(.rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(isRecording || isTranscribing)
            .popover(isPresented: $showSourcePicker, arrowEdge: .bottom) {
                VStack(spacing: 2) {
                    ForEach(availableSources) { source in
                        Button(action: {
                            selectedSource = source
                            showSourcePicker = false
                        }) {
                            HStack {
                                Text(source.displayName)
                                Spacer()
                                if selectedSource == source {
                                    Image(systemName: "checkmark")
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(width: 200)
            }
        }
    }
}
