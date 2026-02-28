# AGENTS.md

This document provides guidance for AI coding agents working in this repository.

## Project Overview

This is a macOS SwiftUI application that performs real-time audio transcription using whisper.cpp. The app captures audio from the microphone and transcribes it using the whisper large-v3 model.

## Required Tools & Skills

When working on this project, AI agents MUST always use the following:

### Skills (Load via `skill` tool)
- **swiftui-expert-skill**: Use for all SwiftUI code - view composition, state management, performance optimization, and modern iOS/macOS patterns
- **swift-concurrency**: Use for all Swift Concurrency code - async/await, actors, tasks, @MainActor, Sendable conformance, and data race prevention

### MCP Tools
- **context7**: Use for up-to-date Swift/SwiftUI documentation via `context7_resolve-library-id` and `context7_query-docs` before implementing features

## Build/Lint/Test Commands

### Building

```bash
# Build the project (Debug)
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -configuration Debug build

# Build the project (Release)
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -configuration Release build

# Build and run from command line
open americo-whisper.xcodeproj
```

### Running Tests

```bash
# Run all tests
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -destination 'platform=macOS' test

# Run a single test file (replace TestClassName with actual test class)
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -destination 'platform=macOS' -only-testing:americo-whisperTests/TestClassName test

# Run a single test method
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper -destination 'platform=macOS' -only-testing:americo-whisperTests/TestClassName/testMethodName test
```

### Linting/Static Analysis

```bash
# Swift compiler warnings are enabled by default in Xcode
# Run static analysis
xcodebuild -project americo-whisper.xcodeproj -scheme americo-whisper analyze

# SwiftLint (if installed)
swiftlint lint
```

## Project Structure

```
americo-whisper/
├── americo-whisper.xcodeproj/    # Xcode project file
├── americo-whisper/              # Swift source files
│   ├── americo_whisperApp.swift  # App entry point
│   ├── ContentView.swift         # Main UI view
│   ├── AudioRecorder.swift       # Audio capture logic
│   ├── WhisperState.swift        # Whisper.cpp wrapper
│   └── Assets.xcassets/          # App assets
└── WhisperCpp/                   # whisper.cpp integration
    ├── include/                  # Header files
    │   ├── americo-whisper-Bridging-Header.h
    │   ├── whisper.h
    │   └── ggml*.h
    └── lib/                      # Static libraries
        ├── libwhisper.a
        ├── libggml-base.a
        ├── libggml-cpu.a
        ├── libggml-metal.a
        └── libggml-blas.a
```

## Code Style Guidelines

### File Headers

All Swift files should include a file header:

```swift
//
//  FileName.swift
//  americo-whisper
//
//  Created by Americo Cot on DD/MM/YY.
//
```

### Imports

- Group imports by framework type (Apple frameworks first, then third-party)
- One import per line
- Imports at the top of the file after the header

```swift
import AVFoundation
import Combine
import Foundation
import SwiftUI
```

### Naming Conventions

- **Types**: PascalCase (e.g., `AudioRecorder`, `WhisperState`)
- **Properties/Variables**: camelCase (e.g., `audioEngine`, `isRecording`)
- **Functions**: camelCase, descriptive verbs (e.g., `startRecording()`, `toggleRecording()`)
- **Private members**: Prefix with `private` access modifier
- **Published properties**: Use `@Published` for ObservableObject properties
- **State properties**: Use `$` prefix for bindings, not for state declarations

### Formatting

- Indent with 4 spaces (Swift standard)
- Opening braces on the same line
- One space after keywords (if, guard, for, etc.)
- Blank line between logical sections
- Maximum line length: 120 characters (soft limit)

### SwiftUI Patterns

```swift
// View structure
struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
    @State private var someValue = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // View content
        }
        .padding()
        .onAppear(perform: someAction)
    }
    
    private func someAction() {
        // Implementation
    }
}
```

### ObservableObject Pattern

```swift
class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    
    private var internalProperty: SomeType?
    
    func publicMethod() {
        // Implementation
    }
    
    private func privateHelperMethod() {
        // Implementation
    }
}
```

### Error Handling

- Use `guard` statements for early returns and validation
- Prefer `guard let` over `if let` when the value is required to proceed
- Print meaningful error messages to console
- Use failable initializers (`init?`) when initialization can fail

```swift
guard let requiredValue = optionalValue else {
    print("Descriptive error message")
    return
}
```

### Optional Handling

```swift
// Preferred: guard let for required values
guard let context = context else { return nil }

// Preferred: if let for conditional processing
if let text = whisper_full_get_segment_text(context, i) {
    transcription += String(cString: text)
}

// Use nil-coalescing for default values
let result = whisperState?.transcribe(audioData: samples) ?? "Transcription failed"
```

### Thread Safety

- Prefer Swift Concurrency (async/await, @MainActor) over DispatchQueue
- Use `@MainActor` for UI-related code and classes
- Use `Task` for async operations

```swift
@MainActor
func updateUI() {
    // UI updates
}

func processData() async {
    // Background work
    await updateUI()
}
```

For legacy code or C interop, DispatchQueue may still be used:

```swift
DispatchQueue.global(qos: .userInitiated).async {
    // Background work
    DispatchQueue.main.async {
        // UI updates
    }
}
```

### Memory Management

- Use `[weak self]` in closures to avoid retain cycles
- Use `deinit` for cleanup of resources

```swift
inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
    self?.processAudioBuffer(buffer)
}

deinit {
    if let context = context {
        whisper_free(context)
    }
}
```

### C/C++ Interoperability

- Bridging header is located at `WhisperCpp/include/americo-whisper-Bridging-Header.h`
- Use `OpaquePointer` for C pointers in Swift
- Use `withUnsafeBufferPointer` for passing arrays to C functions

```swift
private var context: OpaquePointer?

audioData.withUnsafeBufferPointer { buffer in
    whisper_full(context, params, buffer.baseAddress, Int32(buffer.count))
}
```

### Testing Conventions

- Test files should be in `americo-whisperTests/` directory
- Test class naming: `ClassNameTests` (e.g., `AudioRecorderTests`)
- Test method naming: `test_methodName_condition_expectedResult`
- Use `XCTest` framework

```swift
class AudioRecorderTests: XCTestCase {
    var sut: AudioRecorder!
    
    override func setUp() {
        super.setUp()
        sut = AudioRecorder()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_startRecording_whenPermissionGranted_setsIsRecordingTrue() {
        // Test implementation
    }
}
```

## Dependencies

- **whisper.cpp**: Local static libraries in `WhisperCpp/lib/`
  - `libwhisper.a` - main whisper library
  - `libggml-base.a` - core tensor operations
  - `libggml-cpu.a` - CPU backend
  - `libggml-metal.a` - Metal GPU backend
  - `libggml-blas.a` - BLAS/Accelerate backend
- **Frameworks**: AVFoundation, Metal, Accelerate (system frameworks)
- **C++ Standard Library**: libc++.tbd

## Requirements

- macOS 15.7+
- Xcode 26.2+
- Swift 5.0+
- whisper.cpp model file (ggml-large-v3.bin) in app bundle
