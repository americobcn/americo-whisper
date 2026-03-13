//
//  LanguageRowView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct LanguageRowView: View {
    let language: WhisperLanguage
    @Binding var selectedLanguage: WhisperLanguage
    let onDismiss: () -> Void

    var body: some View {
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
