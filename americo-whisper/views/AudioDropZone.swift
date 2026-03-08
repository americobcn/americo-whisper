//
//  AudioDropZone.swift
//  americo-whisper
//
//  Created by Americo Cot on 08/03/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AudioDropZone: View {
    @Binding var isDraggingOver: Bool
    let onFileDropped: (URL) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 36))
                .foregroundStyle(isDraggingOver ? .blue : .secondary)

            Text("Drop Audio File Here")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("WAV, MP3, M4A, FLAC, AAC")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDraggingOver ? Color.blue : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDraggingOver ? Color.blue.opacity(0.1) : Color.clear)
        )
        .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                if let data = data as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task { @MainActor in onFileDropped(url) }
                } else if let url = data as? URL {
                    Task { @MainActor in onFileDropped(url) }
                }
            }
            return true
        }
    }
}
