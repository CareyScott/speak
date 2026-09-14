import Foundation

enum SpeakSettingsFile {
    static let directory: URL = ProcessInfo.processInfo.environment["SPEAK_CONFIG_DIR"].map { URL(fileURLWithPath: $0) }
        ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/speak")
    static let file = directory.appendingPathComponent("settings.json")
    static let autoSpeakFlag = directory.appendingPathComponent("auto")

    static var hotkeys: [SpeakCommand: String] {
        let saved = values()["hotkeys"] as? [String: String] ?? [:]
        var hotkeys: [SpeakCommand: String] = [:]
        for command in SpeakCommand.allCases {
            if let hotkey = saved[command.rawValue], !hotkey.isEmpty { hotkeys[command] = hotkey }
        }
        return hotkeys
    }

    static func string(_ key: String) -> String {
        values()[key] as? String ?? ""
    }

    static func setString(_ key: String, _ value: String) {
        var updated = values()
        updated[key] = value.isEmpty ? nil : value
        save(updated)
    }

    static func setHotkey(_ hotkey: String?, for command: SpeakCommand) {
        var updated = values()
        var saved = updated["hotkeys"] as? [String: String] ?? [:]
        saved[command.rawValue] = hotkey
        updated["hotkeys"] = saved.isEmpty ? nil : saved
        save(updated)
    }

    private static func values() -> [String: Any] {
        guard let data = try? Data(contentsOf: file) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }

    private static func save(_ values: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys]) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
    }
}
