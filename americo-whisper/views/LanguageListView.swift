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
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                AutoDetectLanguageButton(selectedLanguage: $selectedLanguage, onDismiss: onDismiss)

                if !filteredLanguages.isEmpty {
                    Divider()
                        .padding(.vertical, 4)
                }

                ForEach(filteredLanguages) { language in
                    LanguageRowView(language: language, selectedLanguage: $selectedLanguage, onDismiss: onDismiss)
                }
            }
            .padding()
        }
    }
}
