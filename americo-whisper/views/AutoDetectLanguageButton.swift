//
//  AutoDetectLanguageButton.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct AutoDetectLanguageButton: View {
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
