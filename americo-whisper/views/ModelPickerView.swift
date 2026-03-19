//
//  ModelPickerView.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import SwiftUI

struct ModelPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let models: [ModelInfo]
    @Binding var selectedModel: ModelInfo?
    let onSetDefault: (ModelInfo) -> Void
    @State private var focusedIndex: Int?

    var body: some View {
        VStack(spacing: 12) {
            Text("Select Model")
                .font(.headline)
                .padding(.top, 8)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(models.enumerated()), id: \.element.id) { index, model in
                            ModelRowView(
                                model: model,
                                selectedModel: $selectedModel,
                                onSelect: { m in
                                    selectedModel = m
                                    onSetDefault(m)
                                },
                                onDismiss: { dismiss() }
                            )
                            .background(focusedIndex == index ? Color.accentColor.opacity(0.15) : .clear)
                            .clipShape(.rect(cornerRadius: 4))
                            .id(model.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: focusedIndex) { _, newIndex in
                    if let index = newIndex, models.indices.contains(index) {
                        withAnimation { proxy.scrollTo(models[index].id) }
                    }
                }
            }
        }
        .frame(width: 250, height: 300)
        .focusable()
        .focusEffectDisabled()
        .onAppear {
            focusedIndex = models.firstIndex(where: { $0.id == selectedModel?.id })
        }
        .onKeyPress(.downArrow) {
            focusedIndex = min((focusedIndex ?? -1) + 1, models.count - 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            focusedIndex = max((focusedIndex ?? 0) - 1, 0)
            return .handled
        }
        .onKeyPress(.return) {
            if let index = focusedIndex, models.indices.contains(index) {
                selectedModel = models[index]
                onSetDefault(models[index])
                dismiss()
            }
            return .handled
        }
    }
}
