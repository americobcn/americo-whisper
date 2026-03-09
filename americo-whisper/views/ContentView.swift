//
//  ContentView.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var recorder = AudioRecorder()
    @State private var systemCapture = SystemAudioCapture()
    @State private var audioSource: AudioSource = .systemAudio
    @State private var availableSources: [AudioSource] = [.systemAudio]
    @Bindable var coordinator: AppCoordinator
    @State private var transcription: TextDocument = TextDocument()
    @State private var isTranscribing = false
    @State private var whisperState: WhisperState?
    @State private var currentFileName: String?
    @State private var errorMessage: String?
    @State private var isDraggingOver = false
    @State private var selectedLanguage: WhisperLanguage = .autoDetect
    @State private var availableModels: [ModelInfo] = []
    @State private var selectedModel: ModelInfo?
    @State private var mode: TranscriptionMode = .transcribe
    @State private var isHovered = false
    @State private var captureTimer: Timer?
    @State private var isChunkTranscribing = false

    // Replaces inline Binding(get:set:) in view body
    private var modelBinding: Binding<ModelInfo?> {
        Binding(
            get: { selectedModel },
            set: { newModel in
                if let newModel { selectModel(newModel) }
            }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Whisper Transcription")
                .font(.largeTitle)

            Divider()
                .frame(width: 200)

            LanguageModelToolbar(
                selectedLanguage: $selectedLanguage,
                availableModels: availableModels,
                selectedModel: modelBinding,
                mode: $mode,
                onSetDefaultModel: { ModelManager.shared.setDefaultModel($0) },
                availableSources: availableSources,
                selectedSource: $audioSource,
                isRecording: recorder.isRecording || systemCapture.isCapturing,
                isTranscribing: isTranscribing
            )

            AudioDropZone(isDraggingOver: $isDraggingOver, onFileDropped: handleDroppedFile)
            
            Divider()
                .frame(width: 200)
            
            RecordingControls(
                isRecording: recorder.isRecording || systemCapture.isCapturing,
                isTranscribing: isTranscribing,
                onToggle: toggleRecording
            )

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.callout)
            }

            if isTranscribing {
                HStack {
                    ProgressView()
                    if let fileName = currentFileName {
                        Text("Transcribing \(fileName)...")
                    } else {
                        Text("Transcribing...")
                    }
                }
            }
            
            Spacer()

            TranscriptionOutputView(transcription: transcription.text)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 550)
        .onAppear(perform: loadModels)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            ModelManager.shared.stopAccessingFolder()
            if !isTranscribing {
                whisperState?.cleanup()
            }
            whisperState = nil
        }
        .onChange(of: coordinator.shouldOpenFilePicker) { _, newValue in
            if newValue {
                coordinator.shouldOpenFilePicker = false
                browseFiles()
            }
        }
        .onChange(of: coordinator.shouldStartRecording) { _, newValue in
            if newValue {
                coordinator.shouldStartRecording = false
                toggleRecording()
            }
        }
        .onChange(of: coordinator.shouldReloadModel) { _, newValue in
            if newValue {
                coordinator.shouldReloadModel = false
                reloadCurrentModel()
            }
        }
        .onChange(of: coordinator.shouldSelectModelsFolder) { _, newValue in
            if newValue {
                coordinator.shouldSelectModelsFolder = false
                selectModelsFolder()
            }
        }
        .onChange(of: coordinator.shouldSaveTextToFile) { _, newValue in
            if newValue {
                coordinator.shouldSaveTextToFile = false
                saveText()
            }
        }

        Divider()
                    
        Button("Save Transcription", action: saveText)
            .frame(width: 100, height: 40)
            .buttonStyle(.borderless)
            .foregroundColor(isHovered ? .blue : .white)
            .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .onHover { isHovered = $0 }
        
    }

    
    private func saveText() {
        guard !transcription.text.isEmpty else { return }
        let savePanel = NSSavePanel()
        savePanel.title = "Save Transcription"
        savePanel.message = "Choose a location to save the transcription."
        savePanel.prompt = "Save"
        savePanel.nameFieldLabel = "File name:"
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowedContentTypes = [.plainText]
        let fileName = "\(currentFileName ?? "")_\(Date().timeIntervalSince1970)"
        savePanel.nameFieldStringValue = "\(fileName).txt"
        let resp = savePanel.runModal()
        if resp == .OK, let url = savePanel.url {
            do {
                try transcription.text.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

 private func loadModels() {
        ModelManager.shared.resolveBookmark()

        let devices = AudioSource.enumerateInputDevices()
        availableSources = [.systemAudio] + devices

        guard ModelManager.shared.isModelsFolderConfigured else {
            selectModelsFolder()
            return
        }

        availableModels = ModelManager.shared.availableModels()

        guard !availableModels.isEmpty else {
            errorMessage = "No models found in selected folder."
            return
        }

        if availableModels.count == 1 {
            selectModel(availableModels[0])
        } else if let defaultModel = ModelManager.shared.getDefaultModel() {
            selectModel(defaultModel)
        }
        // Multiple models with no saved default: leave selectedModel nil; user picks from UI
    }

    func selectModelsFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select the folder containing Whisper model files (.bin)"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            ModelManager.shared.saveFolderBookmark(url: url)
            loadModels()
        } else if !ModelManager.shared.isModelsFolderConfigured {
            errorMessage = "Please select a models folder to continue"
        }
    }

    private func selectModel(_ model: ModelInfo) {
        guard !isTranscribing else { return }
        selectedModel = model

        guard let modelPath = ModelManager.shared.modelPath(for: model) else {
            errorMessage = "Model file not found: \(model.fileName)"
            return
        }

        whisperState?.cleanup()
        whisperState = nil

        whisperState = WhisperState(modelPath: modelPath)

        if whisperState == nil {
            errorMessage = "Failed to load model: \(model.name)"
        } else {
            errorMessage = nil
        }
    }

    private func reloadCurrentModel() {
        if let model = selectedModel {
            selectModel(model)
        } else if let firstModel = availableModels.first {
            selectModel(firstModel)
        }
    }

    private func transcribeChunk(_ samples: [Float]) async {
        guard !samples.isEmpty else { return }
        let language = selectedLanguage.code
        let isTranslation = mode == .translate
        let whisper = whisperState
        let text = await Task.detached(priority: .userInitiated) {
            await whisper?.transcribe(audioData: samples, language: language, translate: isTranslation) ?? ""
        }.value
        transcription.text += text
    }

    private func toggleRecording() {
        let isCurrentlyRecording: Bool
        switch audioSource {
        case .systemAudio: isCurrentlyRecording = systemCapture.isCapturing
        case .inputDevice: isCurrentlyRecording = recorder.isRecording
        }

        guard whisperState != nil || isCurrentlyRecording else {
            errorMessage = "Please select a model first."
            return
        }

        if isCurrentlyRecording {
            if case .systemAudio = audioSource {
                captureTimer?.invalidate()
                captureTimer = nil
            }
            let audioSamples: [Float]
            if case .systemAudio = audioSource {
                audioSamples = systemCapture.stopCapturing()
            } else {
                audioSamples = recorder.stopRecording()
            }
            currentFileName = nil
            isTranscribing = true

            let language = selectedLanguage.code
            let isTranslation = mode == .translate
            let whisper = whisperState

            let isSystemAudio: Bool
            if case .systemAudio = audioSource { isSystemAudio = true } else { isSystemAudio = false }
            Task.detached(priority: .userInitiated) {
                let result = await Task.detached(priority: .userInitiated) {
                    await whisper?.transcribe(
                        audioData: audioSamples,
                        language: language,
                        translate: isTranslation
                    ) ?? ""
                }.value

                await MainActor.run {
                    if isSystemAudio {
                        self.transcription.text += result
                    } else {
                        self.transcription.text = result.isEmpty ? "Transcription failed" : result
                    }
                    self.isTranscribing = false
                }
            }
        } else {
            transcription.text = ""
            errorMessage = nil
            switch audioSource {
            case .inputDevice(let uid, _):
                Task { await recorder.startRecording(deviceUID: uid) }
            case .systemAudio:
                Task {
                    do {
                        try await systemCapture.startCapturing()
                        captureTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [self] _ in
                            Task { @MainActor in
                                guard !isChunkTranscribing else { return }
                                isChunkTranscribing = true
                                await transcribeChunk(systemCapture.drainSamples())
                                isChunkTranscribing = false
                            }
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    func browseFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio]

        if panel.runModal() == .OK, let url = panel.url {
            handleDroppedFile(url: url)
        }
    }

    private func handleDroppedFile(url: URL) {
        guard whisperState != nil else {
            errorMessage = "Please select a model first."
            return
        }

        guard AudioFileReader.isSupported(url: url) else {
            errorMessage = "Unsupported file format. Please use WAV, MP3, M4A, FLAC, or AAC."
            return
        }

        transcription.text = ""
        errorMessage = nil
        currentFileName = url.deletingPathExtension().lastPathComponent
        isTranscribing = true

        let language = selectedLanguage.code
        let isTranslation = mode == .translate
        let whisper = whisperState

        Task.detached(priority: .userInitiated) {
            do {
                var fullResult = ""
                try await AudioFileReader.loadAudioInChunks(from: url) { chunk in
                    let chunkText = await Task.detached(priority: .userInitiated) {
                        await whisper?.transcribe(
                            audioData: chunk,
                            language: language,
                            translate: isTranslation
                        ) ?? ""
                    }.value
                    fullResult += chunkText
                    await MainActor.run {
                        self.transcription.text += chunkText
                    }
                }
                
                let fullText = fullResult.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    self.transcription.text = fullText.isEmpty ? "Transcription failed" : fullText
                    self.isTranscribing = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isTranscribing = false
                }
            }
        }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] = [.plainText]
    static var writableContentTypes: [UTType] = [.plainText]

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.text = String(decoding: data, as: UTF8.self)
        } else {
            self.text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
