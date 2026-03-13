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

    var body: some View {
        HStack(spacing: 30) {
            LanguageSectionView(selectedLanguage: $selectedLanguage)
            ModelSectionView(availableModels: availableModels, selectedModel: $selectedModel, onSetDefaultModel: onSetDefaultModel)
            ModeSectionView(mode: $mode)
            SourceSectionView(availableSources: availableSources, selectedSource: $selectedSource, isRecording: isRecording, isTranscribing: isTranscribing)
        }
    }
}
