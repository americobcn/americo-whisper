//
//  AppCoordinator.swift
//  americo-whisper
//
//  Created by Americo Cot on 22/2/26.
//

import Foundation

@Observable
class AppCoordinator {
    var shouldOpenFilePicker = false
    var shouldStartRecording = false
    var shouldReloadModel = false
    var shouldSelectModelsFolder = false
}
