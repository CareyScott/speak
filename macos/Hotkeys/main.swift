import AppKit
import Carbon.HIToolbox

enum HotkeyCommands {
    static let speakRoot = URL(fileURLWithPath: CommandLine.arguments[0])
        .resolvingSymlinksInPath()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static let heldModifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
    private static let modifierReleaseTimeout: TimeInterval = 1.5

    static func run(_ command: SpeakCommand) {
        DispatchQueue.global(qos: .userInitiated).async {
            waitForModifierRelease()
            let process = Process()
            process.executableURL = speakRoot.appendingPathComponent("bin/\(command.rawValue)")
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            process.environment = environment
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            try? process.run()
        }
    }

    private static func waitForModifierRelease() {
        let deadline = Date().addingTimeInterval(modifierReleaseTimeout)
        while Date() < deadline && !CGEventSource.flagsState(.combinedSessionState).intersection(heldModifiers).isEmpty {
            usleep(30_000)
        }
    }
}

func report(_ message: String) {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
}

func register(_ combination: HotkeyCombination, identifier: UInt32) -> EventHotKeyRef? {
    var reference: EventHotKeyRef?
    let hotkeyIdentifier = EventHotKeyID(signature: OSType(0x5350_4B48), id: identifier)
    let status = RegisterEventHotKey(combination.keyCode, combination.carbonModifiers, hotkeyIdentifier, GetApplicationEventTarget(), 0, &reference)
    return status == noErr ? reference : nil
}

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.first == "--check" {
    let commandID = arguments.dropFirst().first ?? ""
    let text = arguments.dropFirst(2).joined(separator: " ")
    do {
        let combination = try HotkeyCombination.parse(text)
        if let conflict = HotkeyConflicts.conflict(for: text, claimedBy: HotkeyConflicts.speakOwner(commandID)) {
            report(conflict)
            exit(1)
        }
        guard let reference = register(combination, identifier: 99) else {
            report("\(text) is already taken by another app. Pick another hotkey.")
            exit(1)
        }
        UnregisterEventHotKey(reference)
        exit(0)
    } catch {
        report((error as? HotkeyCombination.ParseError)?.message ?? "\(error)")
        exit(1)
    }
}

let configuredHotkeys = SpeakSettingsFile.hotkeys
guard !configuredHotkeys.isEmpty else {
    print("No speak hotkeys in \(SpeakSettingsFile.file.path). Nothing to do.")
    exit(0)
}

var pressedEvent = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
    var pressed = EventHotKeyID()
    GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &pressed)
    if let command = SpeakCommand.withHotkeyIdentifier(pressed.id) {
        HotkeyCommands.run(command)
    }
    return noErr
}, 1, &pressedEvent, nil, nil)

var registeredHotkeys: [EventHotKeyRef] = []
for (command, hotkey) in configuredHotkeys {
    guard let combination = try? HotkeyCombination.parse(hotkey) else {
        report("Skipping \(command.title): \(hotkey) is not a valid hotkey.")
        continue
    }
    guard let reference = register(combination, identifier: command.hotkeyIdentifier) else {
        report("Skipping \(command.title): \(hotkey) is already taken by another app.")
        continue
    }
    registeredHotkeys.append(reference)
}

guard !registeredHotkeys.isEmpty else {
    report("None of the speak hotkeys could be registered. Change them in Speak Settings.")
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
app.run()
