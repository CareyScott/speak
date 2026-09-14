import AppKit
import Carbon.HIToolbox
import SwiftUI

struct SettingChoice: Identifiable, Hashable {
    let id: String
    let title: String
}

final class SettingsModel: ObservableObject {
    static let engines = [
        SettingChoice(id: "", title: "Automatic"),
        SettingChoice(id: "say", title: "macOS voices"),
        SettingChoice(id: "edge", title: "Microsoft neural voices"),
        SettingChoice(id: "kokoro", title: "Kokoro, on this Mac"),
        SettingChoice(id: "openai", title: "OpenAI"),
        SettingChoice(id: "elevenlabs", title: "ElevenLabs"),
    ]

    static let translationLanguages = [
        "English", "German", "French", "Spanish", "Italian", "Dutch",
        "Portuguese", "Swedish", "Danish", "Norwegian", "Finnish", "Polish",
    ].map { SettingChoice(id: $0, title: $0) }

    static let autoSpeakStyles = [
        SettingChoice(id: "brief", title: "Brief summary"),
        SettingChoice(id: "decisions", title: "Only what needs deciding"),
        SettingChoice(id: "simple", title: "Simple"),
        SettingChoice(id: "full", title: "Full answer"),
        SettingChoice(id: "eli5", title: "Explain like I am five"),
    ]

    private enum CommandResult {
        case succeeded
        case failed(String)
    }

    @Published private(set) var hotkeys: [SpeakCommand: String]
    @Published private(set) var recordingCommand: SpeakCommand?
    @Published private(set) var savingCommand: SpeakCommand?
    @Published private(set) var hotkeyMessage: String?
    @Published var engine: String {
        didSet { SpeakSettingsFile.setString("engine", engine) }
    }
    @Published var voice: String {
        didSet { SpeakSettingsFile.setString("voice", voice) }
    }
    @Published var translateLanguage: String {
        didSet { SpeakSettingsFile.setString("translateLanguage", translateLanguage) }
    }
    @Published var autoSpeakOn: Bool {
        didSet { applyAutoSpeak() }
    }
    @Published var autoSpeakStyle: String {
        didSet { if autoSpeakOn { applyAutoSpeak() } }
    }

    let macVoices: [String]

    private let speakRoot = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
    private var keyMonitor: Any?

    init() {
        hotkeys = SpeakSettingsFile.hotkeys
        engine = SpeakSettingsFile.string("engine")
        voice = SpeakSettingsFile.string("voice")
        let savedLanguage = SpeakSettingsFile.string("translateLanguage")
        translateLanguage = savedLanguage.isEmpty ? "English" : savedLanguage
        let savedStyle = (try? String(contentsOf: SpeakSettingsFile.autoSpeakFlag, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        autoSpeakOn = savedStyle != nil
        autoSpeakStyle = (savedStyle?.isEmpty ?? true) ? "brief" : savedStyle!
        macVoices = Self.installedEnglishMacVoices()
    }

    var isBusy: Bool {
        recordingCommand != nil || savingCommand != nil
    }

    var usesMacVoices: Bool {
        engine.isEmpty || engine == "say"
    }

    var voiceChoices: [String] {
        voice.isEmpty || macVoices.contains(voice) ? macVoices : [voice] + macVoices
    }

    func startRecording(_ command: SpeakCommand) {
        guard !isBusy else { return }
        _ = runSpeakHotkeys(["pause"])
        recordingCommand = command
        hotkeyMessage = "Press the shortcut for \(command.title), or Esc to cancel."
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.record(event)
            return nil
        }
    }

    func cancelRecording() {
        guard recordingCommand != nil else { return }
        stopMonitoringKeys()
        hotkeyMessage = nil
        _ = runSpeakHotkeys(["reload"])
    }

    func clearHotkey(for command: SpeakCommand) {
        guard !isBusy else { return }
        SpeakSettingsFile.setHotkey(nil, for: command)
        savingCommand = command
        DispatchQueue.global(qos: .userInitiated).async {
            let reload = self.runSpeakHotkeys(["reload"])
            DispatchQueue.main.async {
                self.savingCommand = nil
                self.hotkeys[command] = nil
                if case let .failed(message) = reload { self.hotkeyMessage = message } else { self.hotkeyMessage = "\(command.title) has no hotkey now." }
            }
        }
    }

    private func record(_ event: NSEvent) {
        guard let command = recordingCommand else { return }
        if Int(event.keyCode) == kVK_Escape {
            cancelRecording()
            return
        }
        guard let text = HotkeyText.text(for: event) else {
            hotkeyMessage = "That key cannot be used. Use a letter, a digit, space or return with cmd, option or control."
            return
        }
        if let problem = HotkeyText.problem(with: text) {
            hotkeyMessage = problem
            return
        }
        let symbols = HotkeyText.symbols(for: text)
        stopMonitoringKeys()
        savingCommand = command
        hotkeyMessage = "Saving…"
        DispatchQueue.global(qos: .userInitiated).async {
            let check = self.runSpeakHotkeys(["check", command.rawValue, text])
            if case .succeeded = check { SpeakSettingsFile.setHotkey(text, for: command) }
            let reload = self.runSpeakHotkeys(["reload"])
            DispatchQueue.main.async {
                self.savingCommand = nil
                switch (check, reload) {
                case (.succeeded, .succeeded):
                    self.hotkeys[command] = text
                    self.hotkeyMessage = "Press \(symbols) in any app for \(command.title)."
                case let (.failed(message), _), let (_, .failed(message)):
                    self.hotkeyMessage = message
                }
            }
        }
    }

    private func stopMonitoringKeys() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        recordingCommand = nil
    }

    private func applyAutoSpeak() {
        let arguments = autoSpeakOn ? ["on", autoSpeakStyle] : ["off"]
        DispatchQueue.global(qos: .utility).async {
            _ = self.run(self.speakRoot.appendingPathComponent("hooks/speak-auto"), arguments)
        }
    }

    private func runSpeakHotkeys(_ arguments: [String]) -> CommandResult {
        run(speakRoot.appendingPathComponent("bin/speak-hotkeys"), arguments)
    }

    private func run(_ executable: URL, _ arguments: [String]) -> CommandResult {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        let errors = Pipe()
        process.standardError = errors
        process.standardOutput = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return .failed("Could not run \(executable.lastPathComponent): \(error.localizedDescription)")
        }
        let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        process.waitUntilExit()
        guard process.terminationStatus != 0 else { return .succeeded }
        return .failed(message.isEmpty ? "\(executable.lastPathComponent) failed." : message)
    }

    private static func installedEnglishMacVoices() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-v", "?"]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return [] }
        let listing = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()
        let pattern = try! NSRegularExpression(pattern: "^(.+?)\\s+(en_[A-Z0-9]{2,3})\\s+#")
        let names = listing.split(separator: "\n").compactMap { line -> String? in
            let text = String(line)
            guard let match = pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[range])
        }
        return Array(Set(names)).sorted()
    }
}
