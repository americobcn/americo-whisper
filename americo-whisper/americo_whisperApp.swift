//
//  americo_whisperApp.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import SwiftUI

@main
struct americo_whisperApp: App {
    @State private var coordinator = AppCoordinator()
    
    var body: some Scene {
        WindowGroup {
            ContentView(coordinator: coordinator)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Audio File...") {
                    coordinator.shouldOpenFilePicker = true
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Select Models Folder...") {
                    coordinator.shouldSelectModelsFolder = true
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Start/Stop Recording") {
                    coordinator.shouldStartRecording = true
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Reload Model") {
                    coordinator.shouldReloadModel = true
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
    }
}
