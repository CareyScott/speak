import Foundation

enum SpeakCommand: String, CaseIterable, Identifiable {
    case speakSelection = "speak-selection"
    case speakSimply = "speak-simply"
    case speakTranslated = "speak-translated"
    case stopSpeaking = "speak-stop"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .speakSelection: return "Speak Selection"
        case .speakSimply: return "Speak Simply"
        case .speakTranslated: return "Speak Translated"
        case .stopSpeaking: return "Stop Speaking"
        }
    }

    var readsSelection: Bool {
        self != .stopSpeaking
    }

    var hotkeyIdentifier: UInt32 {
        UInt32(Self.allCases.firstIndex(of: self)! + 1)
    }

    static func withHotkeyIdentifier(_ identifier: UInt32) -> SpeakCommand? {
        allCases.first { $0.hotkeyIdentifier == identifier }
    }
}
