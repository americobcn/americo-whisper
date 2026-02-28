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
            language.name.localizedCaseInsensitiveContains(searchText) ||
            language.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding()
            
            Divider()
            
            languageList
        }
        .frame(width: 300, height: 400)
        .onAppear(perform: loadLanguages)
    }
    
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search languages...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))
    }
    
    private var languageList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                autoDetectButton
                
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
    
    private var autoDetectButton: some View {
        Button(action: {
            selectedLanguage = .autoDetect
            dismiss()
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
    
    private func languageRow(_ language: WhisperLanguage) -> some View {
        Button(action: {
            selectedLanguage = language
            dismiss()
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
    
    private func loadLanguages() {
        languages = WhisperLanguage.allLanguages()
    }
}
