//
//  LanguageModelToolbar.swift
//  americo-whisper
//
//  Created by Americo Cot on 08/03/26.
//

import SwiftUI

struct LanguageModelToolbar: View {
    @Binding var selectedLanguage: WhisperLanguage
    let availableModels: [ModelInfo]
    @Binding var selectedModel: ModelInfo?
    @Binding var mode: TranscriptionMode
    let onSetDefaultModel: (ModelInfo) -> Void
    let availableSources: [AudioSource]
    @Binding var selectedSource: AudioSource
    let isRecording: Bool
    let isTranscribing: Bool

    @State private var showLanguagePicker = false
    @State private var showModelPicker = false
    @State private var showModePicker = false
    @State private var showSourcePicker = false

    var body: some View {
        HStack(spacing: 30) {
            languageSection
            modelSection
            modeSection
            sourceSection
        }
    }

    private var languageSection: some View {
        VStack {
            Text("Language:")
                .font(.headline)

            Button(action: { showLanguagePicker = true }) {
                HStack {
                    if selectedLanguage.id == -1 {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(selectedLanguage.name)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .clipShape(.rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showLanguagePicker, arrowEdge: .bottom) {
                LanguagePickerView(selectedLanguage: $selectedLanguage)
            }
        }
    }

    private var modelSection: some View {
        VStack {
            Text("Model:")
                .font(.headline)

            if availableModels.isEmpty {
                ContentUnavailableView("No Models Found", systemImage: "brain.slash")
            } else {
                Button(action: { showModelPicker = true }) {
                    HStack {
                        Image(systemName: "brain")
                        Text(selectedModel?.name ?? "Select model")
                            .foregroundStyle(selectedModel == nil ? .secondary : .primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showModelPicker, arrowEdge: .bottom) {
                    ModelPickerView(
                        models: availableModels,
                        selectedModel: $selectedModel,
                        onSetDefault: onSetDefaultModel
                    )
                }
            }
        }
    }

    private var modeSection: some View {
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

    private var sourceSection: some View {
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
