//
//  ContentView.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

enum TranscriptionMode: String, CaseIterable {
    case transcribe = "Transcribe"
    case translate = "Translate"
}

struct ContentView: View {
    @StateObject private var recorder = AudioRecorder()
    @Bindable var coordinator: AppCoordinator
    @State private var transcription = ""
    @State private var isTranscribing = false
    @State private var whisperState: WhisperState?
    @State private var currentFileName: String?
    @State private var errorMessage: String?
    @State private var isDraggingOver = false
    @State private var selectedLanguage: WhisperLanguage = .autoDetect
    @State private var showLanguagePicker = false
    @State private var availableModels: [ModelInfo] = []
    @State private var selectedModel: ModelInfo?
    @State private var showModelPicker = false
    @State private var mode: TranscriptionMode = .transcribe
    @State private var showModePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Whisper Transcription")
                .font(.largeTitle)
            
            Divider()
                .frame(width: 200)

            languageAndModelSection

            dropZone
            
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
            
            transcriptionSection
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
    }
    
    private var languageAndModelSection: some View {
        HStack(spacing: 30) {
            VStack {
                Text("Language:")
                    .font(.headline)
                
                Button(action: { showLanguagePicker = true }) {
                    HStack {
                        if selectedLanguage.id == -1 {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(selectedLanguage.name)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showLanguagePicker, arrowEdge: .bottom) {
                    LanguagePickerView(selectedLanguage: $selectedLanguage)
                }
            }
            
            VStack {
                Text("Model:")
                    .font(.headline)
                
                if availableModels.isEmpty {
                    Text("No models found")
                        .foregroundStyle(.red)
                } else if let selectedModel = selectedModel {
                    Button(action: { showModelPicker = true }) {
                        HStack {
                            Image(systemName: "brain")
                            Text(selectedModel.name)
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
                            selectedModel: Binding(
                                get: { selectedModel },
                                set: { newModel in
                                    if let newModel = newModel {
                                        selectModel(newModel)
                                    }
                                }
                            ),
                            onSetDefault: { model in
                                ModelManager.shared.setDefaultModel(model)
                            }
                        )
                    }
                } else {
                    Button(action: { showModelPicker = true }) {
                        HStack {
                            Image(systemName: "brain")
                            Text("Select model")
                                .foregroundStyle(.secondary)
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
                            selectedModel: Binding(
                                get: { nil },
                                set: { newModel in
                                    if let newModel = newModel {
                                        selectModel(newModel)
                                    }
                                }
                            ),
                            onSetDefault: { model in
                                ModelManager.shared.setDefaultModel(model)
                            }
                        )
                    }
                }
            }
                                    
            VStack {
                Text("Mode:")
                    .font(.headline)
                
                Button(action: { showModePicker = true }) {
                    HStack {
                        Image(systemName: mode == .translate ? "globe" : "text.word.spacing")
                        Text(mode.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showModePicker, arrowEdge: .bottom) {
                    VStack(spacing: 2) {
                        ForEach(TranscriptionMode.allCases, id: \.self) { modeOption in
                            Button(action: {
                                mode = modeOption
                                showModePicker = false
                            }) {
                                HStack {
                                    Image(systemName: modeOption == .translate ? "globe" : "text.word.spacing")
                                    Text(modeOption.rawValue)
                                    Spacer()
                                    if mode == modeOption {
                                        Image(systemName: "checkmark")
                                    }
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .frame(width: 150)
                }
            }
        }
    }
    
    private var recordingSection: some View {
        VStack(spacing: 12) {
            Text("Record from Microphone")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button(action: toggleRecording) {
                HStack {
                    Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 40))
                    Text(recorder.isRecording ? "Stop Recording" : "Start Recording")
                        .font(.headline)
                }
                .foregroundStyle(recorder.isRecording ? .red : .blue)
            }
            .buttonStyle(.plain)
            .disabled(isTranscribing)
        }
    }
    
    private var dropZone: some View {
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
                    DispatchQueue.main.async {
                        handleDroppedFile(url: url)
                    }
                } else if let url = data as? URL {
                    DispatchQueue.main.async {
                        handleDroppedFile(url: url)
                    }
                }
            }
            return true
        }
    }
    
    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !transcription.isEmpty {
                Text("Transcription")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            ScrollView {
                Text(transcription.isEmpty ? "Transcription will appear here..." : transcription)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .foregroundStyle(transcription.isEmpty ? .tertiary : .primary)
                    .textSelection(.enabled)
                    .font(.system(size: 14))
            }
            .frame(maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
            .clipShape(.rect(cornerRadius: 8))
            .shadow(radius: 10)
        }
    }
    
    private func loadModels() {
        ModelManager.shared.resolveBookmark()

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
        
        showModelPicker = false
    }
    
    private func reloadCurrentModel() {
        if let model = selectedModel {
            selectModel(model)
        } else if let firstModel = availableModels.first {
            selectModel(firstModel)
        }
    }
    
    private func toggleRecording() {
        guard whisperState != nil || recorder.isRecording else {
            errorMessage = "Please select a model first."
            return
        }

        if recorder.isRecording {
            let audioSamples = recorder.stopRecording()
            currentFileName = nil
            isTranscribing = true
            
            let language = selectedLanguage.code
            let isTranslation = mode == .translate
            let whisper = whisperState
            
            Task.detached(priority: .userInitiated) {
                let result = await whisper?.transcribe(
                    audioData: audioSamples,
                    language: language,
                    translate: isTranslation
                ) ?? "Transcription failed"
                
                await MainActor.run {
                    self.transcription = result
                    self.isTranscribing = false
                }
            }
        } else {
            transcription = ""
            errorMessage = nil
            recorder.startRecording()
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
        
        transcription = ""
        errorMessage = nil
        currentFileName = url.lastPathComponent
        isTranscribing = true
        
        let language = selectedLanguage.code
        let isTranslation = mode == .translate
        let whisper = whisperState
        
        Task.detached(priority: .userInitiated) {
            do {
                let samples = try AudioFileReader.loadAudioFileSync(from: url)

                let result = await whisper?.transcribe(
                    audioData: samples,
                    language: language,
                    translate: isTranslation,
                    onChunkComplete: { partial in
                        Task { @MainActor in
                            self.transcription += partial
                        }
                    }
                ) ?? "Transcription failed"

                await MainActor.run {
                    self.transcription = result
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


// #Preview {
//     ContentView(coordinator: AppCoordinator())
// }
