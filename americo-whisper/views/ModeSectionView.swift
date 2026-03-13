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
                VStack(spacing: 2) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { modeOption in
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
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .frame(width: 150)
            }
        }
    }
}
