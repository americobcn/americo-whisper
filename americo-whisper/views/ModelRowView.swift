//
//  ModelRowView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct ModelRowView: View {
    let model: ModelInfo
    @Binding var selectedModel: ModelInfo?
    let onSelect: (ModelInfo) -> Void
    let onDismiss: () -> Void

    var body: some View {
        Button(action: {
            onSelect(model)
            onDismiss()
        }) {
            HStack {
                Image(systemName: "brain")
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                Text(model.name)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedModel?.id == model.id {
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
