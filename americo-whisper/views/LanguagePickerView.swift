//
//  LanguagePickerView.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import SwiftUI

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedLanguage: WhisperLanguage
    @State private var searchText = ""
    @State private var languages: [WhisperLanguage] = []
    @State private var focusedIndex: Int?

    var filteredLanguages: [WhisperLanguage] {
        if searchText.isEmpty {
            return languages
        }
        return languages.filter { language in
            language.name.localizedStandardContains(searchText) ||
            language.code.localizedStandardContains(searchText)
        }
    }

    private var allItems: [WhisperLanguage] {
        [.autoDetect] + filteredLanguages
    }

    var body: some View {
        VStack(spacing: 0) {
            LanguageSearchField(
                searchText: $searchText,
                onArrowUp: { focusedIndex = max((focusedIndex ?? 0) - 1, 0) },
                onArrowDown: { focusedIndex = min((focusedIndex ?? -1) + 1, allItems.count - 1) },
                onConfirm: {
                    if let index = focusedIndex, allItems.indices.contains(index) {
                        selectedLanguage = allItems[index]
                        dismiss()
                    }
                }
            )
            .padding()

            Divider()

            LanguageListView(
                filteredLanguages: filteredLanguages,
                selectedLanguage: $selectedLanguage,
                focusedIndex: focusedIndex,
                onDismiss: { dismiss() }
            )
        }
        .frame(width: 300, height: 400)
        .onAppear(perform: loadLanguages)
        .onChange(of: searchText) {
            focusedIndex = 0
        }
    }

    private func loadLanguages() {
        languages = WhisperLanguage.allLanguages()
        focusedIndex = allItems.firstIndex(of: selectedLanguage)
    }
}

