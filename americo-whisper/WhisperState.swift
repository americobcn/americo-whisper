//
//  WhisperState.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import Foundation

class WhisperState {
    private var context: OpaquePointer?
    private var isCleanedUp = false
    private let chunkSamples = 30 * 16_000  // WHISPER_CHUNK_SIZE × WHISPER_SAMPLE_RATE
    
    init?(modelPath: String) {
        let cparams = whisper_context_default_params()
        context = whisper_init_from_file_with_params(modelPath, cparams)
        
        guard context != nil else {
            print("Failed to initialize whisper context")
            return nil
        }
    }
    
    func cleanup() {
        guard !isCleanedUp, let context = context else { return }
        whisper_free(context)
        self.context = nil
        isCleanedUp = true
    }
    
    deinit {
        cleanup()
    }
    
    func transcribe(
        audioData: [Float],
        language: String = "auto",
        translate: Bool = false,
        onChunkComplete: ((String) -> Void)? = nil
    ) -> String? {
        guard !audioData.isEmpty else { return nil }
        guard let context = context else { return nil }

        if audioData.count > chunkSamples {
            return transcribeInChunks(
                audioData: audioData,
                language: language,
                translate: translate,
                onChunkComplete: onChunkComplete
            )
        }

        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        params.print_progress = false
        params.print_timestamps = false
        params.print_realtime = false
        params.translate = translate

        language.withCString { langPtr in
            params.language = langPtr

            audioData.withUnsafeBufferPointer { buffer in
                if whisper_full(context, params, buffer.baseAddress, Int32(buffer.count)) != 0 {
                    print("Failed to process audio")
                }
            }
        }

        let nSegments = whisper_full_n_segments(context)
        var transcription = ""

        for i in 0..<nSegments {
            if let text = whisper_full_get_segment_text(context, i) {
                transcription += String(cString: text)
            }
        }

        return transcription
    }

    private func transcribeInChunks(
        audioData: [Float],
        language: String,
        translate: Bool,
        onChunkComplete: ((String) -> Void)? = nil
    ) -> String? {
        guard let context = context else { return nil }

        var result = ""
        var offset = 0

        while offset < audioData.count {
            let end = min(offset + chunkSamples, audioData.count)
            let chunk = Array(audioData[offset..<end])

            var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
            params.print_progress = false
            params.print_timestamps = false
            params.print_realtime = false
            params.translate = translate

            language.withCString { langPtr in
                params.language = langPtr
                chunk.withUnsafeBufferPointer { buffer in
                    if whisper_full(context, params, buffer.baseAddress, Int32(buffer.count)) != 0 {
                        print("Whisper chunk failed at offset \(offset)")
                    }
                }
            }

            let nSegments = whisper_full_n_segments(context)
            var chunkText = ""
            for i in 0..<nSegments {
                if let text = whisper_full_get_segment_text(context, i) {
                    chunkText += String(cString: text)
                }
            }

            onChunkComplete?(chunkText)
            result += chunkText
            offset = end
        }

        return result.isEmpty ? nil : result
    }
}
