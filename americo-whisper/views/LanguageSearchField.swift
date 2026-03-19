//
//  LanguageSearchField.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct LanguageSearchField: View {
    @Binding var searchText: String
    var onArrowUp: () -> Void = {}
    var onArrowDown: () -> Void = {}
    var onConfirm: () -> Void = {}

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField("Search languages...", text: $searchText)
                .textFieldStyle(.plain)
                .onKeyPress(.downArrow) { onArrowDown(); return .handled }
                .onKeyPress(.upArrow) { onArrowUp(); return .handled }
                .onKeyPress(.return) { onConfirm(); return .handled }

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
