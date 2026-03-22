# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS SwiftUI app that performs audio transcription using whisper.cpp. Supports real-time microphone recording, system audio capture, and audio file loading, with language selection, model management, and translation mode.

- **Target**: macOS 14.6+, Xcode 26.2+, Swift 5.0+
- **Bundle ID**: `com.americobcn.americo-whisper`

## Required Skills

Always load these skills before writing code in this project:

- **swiftui-pro** — for all SwiftUI code
- **swift-concurrency-pro** — for all async/await, actors, `@MainActor`, and `Sendable` work

## Build Commands

```bash
# Build (Debug)
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -configuration Debug build

# Build (Release)
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -configuration Release build

# Static analysis
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper analyze

# SwiftLint (if installed)
swiftlint lint
```

## Test Commands

```bash
# Run all tests
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -destination 'platform=macOS' test

# Run a single test class
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -destination 'platform=macOS' -only-testing:americo-whisperTests/TestClassName test

# Run a single test method
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -destination 'platform=macOS' -only-testing:americo-whisperTests/TestClassName/testMethodName test
```

## Architecture

### Source Layout

```
americo-whisper/
├── src/          # Non-view logic (models, state, audio)
└── views/        # SwiftUI views
```

### Data Flow

1. User selects an `AudioSource` (mic input device or system audio) or loads a file
2. **Mic/device**: `AudioRecorder` uses `AVAudioEngine`; **system audio**: `SystemAudioCapture` uses `ScreenCaptureKit`; **file**: `AudioFileReader`
3. All paths produce `[Float]` samples at 16kHz mono
4. Samples passed to `WhisperState`, which calls whisper.cpp C functions via bridging header
5. Results returned as `String` and displayed in `ContentView`

### Key Components

- **`WhisperState.swift`** — Core C interop wrapper. Manages an `OpaquePointer` to whisper context; calls `whisper_full`, `whisper_full_get_segment_text`, etc. This is the only file that crosses the Swift/C boundary.
- **`AudioRecorder.swift`** — `ObservableObject` using `AVAudioEngine` for live mic/device capture; produces 16kHz mono float samples.
- **`SystemAudioCapture.swift`** — `@MainActor @Observable` class using `ScreenCaptureKit` to capture system audio. Requires Screen Recording permission. Uses `nonisolated(unsafe)` + `NSLock` for audio buffer access from the SCStream callback thread. Also registers a no-op screen output to silence internal SCStream errors.
- **`AudioSource.swift`** — `enum AudioSource` unifying `.systemAudio` and `.inputDevice(uid:name:)`. Used to drive input source selection in the UI; `enumerateInputDevices()` queries `AVCaptureDevice`.
- **`AudioFileReader.swift`** — Static utilities for loading and converting audio files to 16kHz mono Float32. `loadAudioInChunks` is the primary path for file transcription (streams 30s chunks); `readAudioFile` loads the whole file at once.
- **`ModelManager.swift`** — Singleton; discovers `.bin` model files in a user-selected folder, persists the folder via security-scoped bookmark and the default model selection in `UserDefaults`.
- **`ModelInfo.swift`** — Value type (`struct`) wrapping a model `.bin` filename; `name` strips the `.bin` extension for display.
- **`TranscriptionMode.swift`** — Simple `enum` with `.transcribe` and `.translate` cases; passed to `WhisperState` to control whisper task mode.
- **`AppCoordinator.swift`** — `@Observable` signal object; holds Bool trigger flags (`shouldOpenFilePicker`, `shouldStartRecording`, etc.) that `ContentView` observes via `onChange` to bridge menu commands to view actions.

### C/C++ Integration

Bridging header: `WhisperCpp/include/americo-whisper-Bridging-Header.h`

Pre-built static libs in `WhisperCpp/lib/`:

- `libwhisper.a` — transcription engine
- `libggml-base.a`, `libggml-cpu.a`, `libggml-metal.a`, `libggml-blas.a` — GGML backends (Metal for GPU)
- `libwhisper.coreml.a` — CoreML support

Use `OpaquePointer` for C struct handles and `withUnsafeBufferPointer` when passing arrays to C functions.

`WhisperState.transcribe` is synchronous — always call it from `Task.detached(priority: .userInitiated)`. Long audio is split into 30s chunks internally (`chunkSamples = 30 × 16_000`); for file input, chunking happens at the `AudioFileReader` level instead.

## Code Style

### File Header

```swift
//
//  FileName.swift
//  americo-whisper
//
//  Created by Americo Cot on DD/MM/YY.
//
```

### Imports

Apple frameworks first, alphabetically, one per line.

### Concurrency

Prefer Swift Concurrency (`async/await`, `@MainActor`, `Task`) over `DispatchQueue`. Audio APIs may still require `DispatchQueue` for AVAudioEngine callbacks.

- Use `Task.detached(priority: .userInitiated)` for transcription work
- Use `await MainActor.run {}` for UI updates from background tasks
- Use `[weak self]` in closures; clean up resources in `deinit`

### SwiftUI State

- `@StateObject` for view-owned `ObservableObject` instances
- `@Observable` + `@Bindable` for newer coordinator-style classes
- `@Published` on all `ObservableObject` properties that drive UI

### Menu Commands (defined in `americo_whisperApp.swift`)

| Action               | Shortcut |
| -------------------- | -------- |
| Open Audio File      | ⌘O       |
| Select Models Folder | ⌘⇧O      |
| Start/Stop Recording | ⌘R       |
| Reload Model         | ⌘⇧M      |

## Testing Conventions

- Test files: `americo-whisperTests/`
- Class naming: `ClassNameTests`
- Method naming: `test_methodName_condition_expectedResult`
- Use `XCTest`; set up `sut` in `setUp()`, nil in `tearDown()`
