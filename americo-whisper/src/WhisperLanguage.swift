//
//  WhisperLanguage.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import Foundation
import whisper

struct WhisperLanguage: Identifiable, Hashable, Comparable {
    let id: Int
    let code: String
    let name: String
    
    var displayName: String {
        "\(name) (\(code.uppercased()))"
    }
    
    static let autoDetect = WhisperLanguage(id: -1, code: "auto", name: "Auto-detect")
    
    static func allLanguages() -> [WhisperLanguage] {
        let maxId = whisper_lang_max_id()
        var languages: [WhisperLanguage] = []
        
        for i in 0...maxId {
            guard let codePtr = whisper_lang_str(i),
                  let namePtr = whisper_lang_str_full(i) else {
                continue
            }
            
            let code = String(cString: codePtr)
            let name = String(cString: namePtr).capitalized
            
            languages.append(WhisperLanguage(id: Int(i), code: code, name: name))
        }
        
        return languages.sorted()
    }
    
    static func < (lhs: WhisperLanguage, rhs: WhisperLanguage) -> Bool {
        if lhs.id == -1 { return true }
        if rhs.id == -1 { return false }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }
    
    static func == (lhs: WhisperLanguage, rhs: WhisperLanguage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
