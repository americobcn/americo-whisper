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
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Select Model")
                .font(.headline)
                .padding(.top, 8)
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(models) { model in
                        modelRow(model)
                    }
                }
                .padding()
            }
        }
        .frame(width: 250, height: 300)
    }
    
    private func modelRow(_ model: ModelInfo) -> some View {
        HStack {
            Button(action: {
                selectedModel = model
                onSetDefault(model)
                dismiss()
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
}
