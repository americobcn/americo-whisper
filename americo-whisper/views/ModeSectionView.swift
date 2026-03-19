//
//  ModeSectionView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct ModeSectionView: View {
    @Binding var mode: TranscriptionMode
    @State private var showModePicker = false
    @State private var focusedIndex: Int?

    var body: some View {
        VStack {
            Text("Mode:")
                .font(.headline)

            Button(action: { showModePicker = true }) {
                HStack {
                    Image(systemName: mode == .translate ? "globe" : "text.word.spacing")
                    Text(mode.rawValue)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(.rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showModePicker, arrowEdge: .bottom) {
                let cases = TranscriptionMode.allCases
                VStack(spacing: 2) {
                    ForEach(Array(cases.enumerated()), id: \.element) { index, modeOption in
                        Button(action: {
                            mode = modeOption
                            showModePicker = false
                        }) {
                            HStack {
                                Image(systemName: modeOption == .translate ? "globe" : "text.word.spacing")
                                Text(modeOption.rawValue)
                                Spacer()
                                if mode == modeOption {
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
                .frame(width: 150)
                .focusable()
                .focusEffectDisabled()
                .onAppear {
                    focusedIndex = cases.firstIndex(of: mode)
                }
                .onKeyPress(.downArrow) {
                    focusedIndex = min((focusedIndex ?? -1) + 1, cases.count - 1)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    focusedIndex = max((focusedIndex ?? 0) - 1, 0)
                    return .handled
                }
                .onKeyPress(.return) {
                    if let index = focusedIndex, cases.indices.contains(index) {
                        mode = cases[index]
                        showModePicker = false
                    }
                    return .handled
                }
            }
        }
    }
}
