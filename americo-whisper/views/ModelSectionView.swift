//
//  ModelSectionView.swift
//  americo-whisper
//
//  Created by Americo Cot on 13/03/26.
//

import SwiftUI

struct ModelSectionView: View {
    let availableModels: [ModelInfo]
    @Binding var selectedModel: ModelInfo?
    let onSetDefaultModel: (ModelInfo) -> Void
    @State private var showModelPicker = false

    var body: some View {
        VStack {
            Text("Model:")
                .font(.headline)

            if availableModels.isEmpty {
                ContentUnavailableView("No Models Found", systemImage: "brain.slash")
            } else {
                Button(action: { showModelPicker = true }) {
                    HStack {
                        Image(systemName: "brain")
                        Text(selectedModel?.name ?? "Select model")
                            .foregroundStyle(selectedModel == nil ? .secondary : .primary)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showModelPicker, arrowEdge: .bottom) {
                    ModelPickerView(
                        models: availableModels,
                        selectedModel: $selectedModel,
                        onSetDefault: onSetDefaultModel
                    )
                }
            }
        }
    }
}
