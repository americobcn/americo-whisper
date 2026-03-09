//
//  AudioSource.swift
//  americo-whisper
//
//  Created by Americo Cot on 09/03/26.
//

import AVFoundation

enum AudioSource: Hashable, Identifiable {
    case systemAudio
    case inputDevice(uid: String, name: String)

    var id: String {
        switch self {
        case .systemAudio: return "system-audio"
        case .inputDevice(let uid, _): return uid
        }
    }

    var displayName: String {
        switch self {
        case .systemAudio: return "System Audio"
        case .inputDevice(_, let name): return name
        }
    }

    static func enumerateInputDevices() -> [AudioSource] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        return session.devices.map { .inputDevice(uid: $0.uniqueID, name: $0.localizedName) }
    }
}
