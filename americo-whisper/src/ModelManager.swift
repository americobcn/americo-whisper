//
//  ModelManager.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import Foundation

class ModelManager {
    static let shared = ModelManager()
    
    private let modelsFolderPathKey = "modelsFolderPath"
    private let modelExtension = "bin"
    private let defaultModelKey = "defaultModelName"
    private let modelsFolderBookmarkKey = "modelsFolderBookmark"
    
    private init() {}
    
    var modelsFolderPath: String? {
        get { UserDefaults.standard.string(forKey: modelsFolderPathKey) }
        set { UserDefaults.standard.set(newValue, forKey: modelsFolderPathKey) }
    }
    
    var isModelsFolderConfigured: Bool {
        guard let path = modelsFolderPath else { return false }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    func availableModels() -> [ModelInfo] {
        guard let folderPath = modelsFolderPath else {
            return []
        }
        
        guard let modelFiles = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: folderPath),
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        
        let models = modelFiles
            .filter { $0.pathExtension == modelExtension }
            .map { $0.lastPathComponent }
            .sorted()
            .map { ModelInfo(fileName: $0) }
        
        return models
    }
    
    func getDefaultModel() -> ModelInfo? {
        let models = availableModels()
        guard !models.isEmpty else { return nil }
        guard let savedName = UserDefaults.standard.string(forKey: defaultModelKey),
              let savedModel = models.first(where: { $0.fileName == savedName }) else {
            return nil
        }
        return savedModel
    }

    func saveFolderBookmark(url: URL) {
        modelsFolderPath = url.path
        guard let bookmarkData = try? url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else { return }
        UserDefaults.standard.set(bookmarkData, forKey: modelsFolderBookmarkKey)
    }

    func resolveBookmark() {
        guard let data = UserDefaults.standard.data(forKey: modelsFolderBookmarkKey) else { return }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return }

        if isStale {
            saveFolderBookmark(url: url)
        }
        if url.startAccessingSecurityScopedResource()  {
            modelsFolderPath = url.path
        }
        
    }

    func stopAccessingFolder() {
        guard let path = modelsFolderPath else { return }
        URL(fileURLWithPath: path).stopAccessingSecurityScopedResource()
    }
    
    func setDefaultModel(_ model: ModelInfo) {
        UserDefaults.standard.set(model.fileName, forKey: defaultModelKey)
    }
    
    func modelPath(for model: ModelInfo) -> String? {
        guard let folderPath = modelsFolderPath else {
            return nil
        }
        
        let fullPath = URL(fileURLWithPath: folderPath).appendingPathComponent(model.fileName).path
        
        if FileManager.default.fileExists(atPath: fullPath) {
            return fullPath
        }
        
        return nil
    }
}
