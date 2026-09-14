import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsModel

    var body: some View {
        Form {
            Section {
                ForEach(SpeakCommand.allCases) { command in
                    LabeledContent(command.title) {
                        HStack(spacing: 8) {
                            Button(hotkeyButtonTitle(for: command)) { settings.startRecording(command) }
                                .disabled(settings.isBusy)
                            if settings.hotkeys[command] != nil && !settings.isBusy {
                                Button("Clear") { settings.clearHotkey(for: command) }
                            }
                        }
                    }
                }
            } header: {
                Text("Hotkeys")
            } footer: {
                Text(settings.hotkeyMessage ?? "Optional. Each works from any app. The selection commands copy what is selected, so macOS asks once for Accessibility for SpeakHotkeys.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Engine", selection: $settings.engine) {
                    ForEach(SettingsModel.engines) { choice in
                        Text(choice.title).tag(choice.id)
                    }
                }
                if settings.usesMacVoices {
                    Picker("Voice", selection: $settings.voice) {
                        Text("System voice").tag("")
                        ForEach(settings.voiceChoices, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                } else {
                    TextField("Voice", text: $settings.voice, prompt: Text("Engine default"))
                }
            } header: {
                Text("Voice")
            } footer: {
                Text("SPEAK_ENGINE and SPEAK_VOICE still win when they are set.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Translate into", selection: $settings.translateLanguage) {
                    ForEach(SettingsModel.translationLanguages) { choice in
                        Text(choice.title).tag(choice.id)
                    }
                }
            } header: {
                Text("Speak Translated")
            } footer: {
                Text("Used when no language is picked, for example from the hotkey.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Read a summary after every Claude Code answer", isOn: $settings.autoSpeakOn)
                if settings.autoSpeakOn {
                    Picker("Style", selection: $settings.autoSpeakStyle) {
                        ForEach(SettingsModel.autoSpeakStyles) { choice in
                            Text(choice.title).tag(choice.id)
                        }
                    }
                }
            } header: {
                Text("Auto-speak")
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 680)
    }

    private func hotkeyButtonTitle(for command: SpeakCommand) -> String {
        if settings.recordingCommand == command { return "Press shortcut…" }
        if settings.savingCommand == command { return "Saving…" }
        return settings.hotkeys[command].map(HotkeyText.symbols(for:)) ?? "Record Shortcut"
    }
}
