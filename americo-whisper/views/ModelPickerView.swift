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
                        ModelRowView(
                            model: model,
                            selectedModel: $selectedModel,
                            onSelect: { m in
                                selectedModel = m
                                onSetDefault(m)
                            },
                            onDismiss: { dismiss() }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(width: 250, height: 300)
    }
    
}
