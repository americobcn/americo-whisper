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

    var filteredLanguages: [WhisperLanguage] {
        if searchText.isEmpty {
            return languages
        }
        return languages.filter { language in
            language.name.localizedStandardContains(searchText) ||
            language.code.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            LanguageSearchField(searchText: $searchText)
                .padding()

            Divider()

            LanguageListView(
                filteredLanguages: filteredLanguages,
                selectedLanguage: $selectedLanguage,
                onDismiss: { dismiss() }
            )
        }
        .frame(width: 300, height: 400)
        .onAppear(perform: loadLanguages)
    }

    private func loadLanguages() {
        languages = WhisperLanguage.allLanguages()
    }
}

