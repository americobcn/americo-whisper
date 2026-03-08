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
            SearchField(searchText: $searchText)
                .padding()

            Divider()

            LanguageList(
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

private struct SearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Search languages...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button("Clear search", systemImage: "xmark.circle.fill", action: { searchText = "" })
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))
    }
}

private struct LanguageList: View {
    let filteredLanguages: [WhisperLanguage]
    @Binding var selectedLanguage: WhisperLanguage
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                AutoDetectButton(selectedLanguage: $selectedLanguage, onDismiss: onDismiss)

                if !filteredLanguages.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                }

                ForEach(filteredLanguages) { language in
                    languageRow(language)
                }
            }
            .padding()
        }
    }

    private func languageRow(_ language: WhisperLanguage) -> some View {
        Button(action: {
            selectedLanguage = language
            onDismiss()
        }) {
            HStack {
                Text(language.displayName)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedLanguage.id == language.id {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }
}

private struct AutoDetectButton: View {
    @Binding var selectedLanguage: WhisperLanguage
    let onDismiss: () -> Void

    var body: some View {
        Button(action: {
            selectedLanguage = .autoDetect
            onDismiss()
        }) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .frame(width: 24)
                    .foregroundStyle(.blue)

                Text(WhisperLanguage.autoDetect.name)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedLanguage.id == -1 {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
    }
}
