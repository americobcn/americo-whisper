//
//  LanguageSectionView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct LanguageSectionView: View {
    @Binding var selectedLanguage: WhisperLanguage
    @State private var showLanguagePicker = false

    var body: some View {
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
}
