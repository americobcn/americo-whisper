//
//  LanguageListView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct LanguageListView: View {
    let filteredLanguages: [WhisperLanguage]
    @Binding var selectedLanguage: WhisperLanguage
    var focusedIndex: Int?
    let onDismiss: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    AutoDetectLanguageButton(selectedLanguage: $selectedLanguage, onDismiss: onDismiss)
                        .background(focusedIndex == 0 ? Color.accentColor.opacity(0.15) : .clear)
                        .clipShape(.rect(cornerRadius: 4))
                        .id(WhisperLanguage.autoDetect.id)

                    if !filteredLanguages.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                    }

                    ForEach(Array(filteredLanguages.enumerated()), id: \.element.id) { index, language in
                        LanguageRowView(language: language, selectedLanguage: $selectedLanguage, onDismiss: onDismiss)
                            .background(focusedIndex == index + 1 ? Color.accentColor.opacity(0.15) : .clear)
                            .clipShape(.rect(cornerRadius: 4))
                            .id(language.id)
                    }
                }
                .padding()
            }
            .onChange(of: focusedIndex) { _, newIndex in
                guard let newIndex else { return }
                if newIndex == 0 {
                    withAnimation { proxy.scrollTo(WhisperLanguage.autoDetect.id) }
                } else {
                    let languageIndex = newIndex - 1
                    if filteredLanguages.indices.contains(languageIndex) {
                        withAnimation { proxy.scrollTo(filteredLanguages[languageIndex].id) }
                    }
                }
            }
        }
    }
}
