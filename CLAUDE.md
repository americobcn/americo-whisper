# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

macOS SwiftUI app that performs audio transcription using whisper.cpp. Supports real-time microphone recording and audio file loading, with language selection, model management, and translation mode.

- **Target**: macOS 15.7+, Xcode 26.2+, Swift 5.0+
- **Bundle ID**: `com.americobcn.americo-whisper`

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

### Data Flow

1. User records via mic (`AudioRecorder`) or loads a file (`AudioFileReader`)
2. Both produce `[Float]` samples at 16kHz mono
3. Samples passed to `WhisperState`, which calls whisper.cpp C functions via bridging header
4. Results returned as `String` and displayed in `ContentView`

### Key Components

- **`WhisperState.swift`** — Core C interop wrapper. Manages an `OpaquePointer` to whisper context; calls `whisper_full`, `whisper_full_get_segment_text`, etc. This is the only file that crosses the Swift/C boundary.
- **`AudioRecorder.swift`** — `ObservableObject` using `AVAudioEngine` for live mic capture; produces 16kHz mono float samples.
- **`AudioFileReader.swift`** — Static async utilities for loading and converting audio files to 16kHz mono.
- **`ModelManager.swift`** — Singleton; discovers model files on disk, persists selection in `UserDefaults`.
- **`AppCoordinator.swift`** — `@Observable` navigation/state coordinator at the app level.

### C/C++ Integration

Bridging header: `WhisperCpp/include/americo-whisper-Bridging-Header.h`

Pre-built static libs in `WhisperCpp/lib/`:
- `libwhisper.a` — transcription engine
- `libggml-base.a`, `libggml-cpu.a`, `libggml-metal.a`, `libggml-blas.a` — GGML backends (Metal for GPU)
- `libwhisper.coreml.a` — CoreML support

Use `OpaquePointer` for C struct handles and `withUnsafeBufferPointer` when passing arrays to C functions.

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

## Testing Conventions

- Test files: `americo-whisperTests/`
- Class naming: `ClassNameTests`
- Method naming: `test_methodName_condition_expectedResult`
- Use `XCTest`; set up `sut` in `setUp()`, nil in `tearDown()`
