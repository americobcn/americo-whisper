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
    @State private var focusedIndex: Int?

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
                    ForEach(Array(availableSources.enumerated()), id: \.element.id) { index, source in
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
                            .background(focusedIndex == index ? Color.accentColor.opacity(0.15) : .clear)
                            .clipShape(.rect(cornerRadius: 4))
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(width: 200)
                .focusable()
                .focusEffectDisabled()
                .onAppear {
                    focusedIndex = availableSources.firstIndex(of: selectedSource)
                }
                .onKeyPress(.downArrow) {
                    focusedIndex = min((focusedIndex ?? -1) + 1, availableSources.count - 1)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    focusedIndex = max((focusedIndex ?? 0) - 1, 0)
                    return .handled
                }
                .onKeyPress(.return) {
                    if let index = focusedIndex, availableSources.indices.contains(index) {
                        selectedSource = availableSources[index]
                        showSourcePicker = false
                    }
                    return .handled
                }
            }
        }
    }
}
