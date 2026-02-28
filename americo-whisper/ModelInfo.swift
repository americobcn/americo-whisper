//
//  ModelInfo.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import Foundation

struct ModelInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let fileName: String

    init(fileName: String) {
        self.id = fileName
        self.fileName = fileName
        self.name = fileName.replacingOccurrences(of: ".bin", with: "")
    }
}
