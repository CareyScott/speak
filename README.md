# speak

Have Claude read to you.

Ask Claude Code to "read that back to me" and it rewrites its answer as a short spoken script and plays it. You hear it, you never see it. Select text in any app and a right-click, hotkey or Raycast command reads it aloud, summarises it first, or translates it first. Playback starts on the first sentence while the rest is still being written.

The playback half is a plain MCP server, so it also works from Claude Desktop, Cursor, or any other MCP client.

## What you get

- MCP server `speak` with tools `speak`, `enqueue`, `stop`, `pause`, `resume`, `back`, `skip`, `add_pronunciation`, `list_pronunciations`, `list_voices`, `set_default`
- A floating pill on macOS while it reads: live waveform, back a sentence, pause and resume from the exact spot, skip, stop. It pulses while audio is loading and remembers where you dragged it until the next reboot.
- `/speak` skill for Claude Code with styles `simple` (default), `brief`, `decisions`, `full`, `eli5`
- Auto-speak: a `Stop` hook that reads a short summary after every answer, off by default
- Four commands for the selected text: `speak-selection`, `speak-simply`, `speak-translated`, `speak-stop`. Available as macOS Quick Actions (right-click > Services), Raycast script commands, and plain shell commands for any launcher.
- `speak` CLI: `echo "hello" | speak`, or `speak --stream` to read sentences as they arrive on stdin

## Install

Needs macOS or Linux, Node 20+, `jq`, and Claude Code. The overlay needs `swiftc` from the Xcode command line tools.

```sh
git clone https://github.com/CareyScott/speak
cd speak
./install.sh
```

The script builds the server and overlay, registers the MCP server at user scope, links the skill into `~/.claude/skills`, adds the `Stop` hook to `~/.claude/settings.json`, links the commands into `~/.local/bin`, and installs the Quick Actions into `~/Library/Services`.

If you use Raycast, point it at a directory Raycast already loads script commands from and the four commands are linked there too:

```sh
RAYCAST_SCRIPTS_DIR=~/raycast-scripts ./install.sh
```

Restart Claude Code afterwards.

## Use

In Claude Code:

- "read that back to me"
- "say it simply"
- "what do you need from me, out loud"
- "/speak decisions"
- "pause", "go back a sentence", "skip that", "stop"

On selected text, in any app:

- Right-click > Services > Speak, Speak Simply, Speak Translated, Speak Stop. Give them hotkeys once in System Settings > Keyboard > Keyboard Shortcuts > Services > Text.
- Raycast: the same four commands. Speak Translated takes a language as its argument.
- Any other launcher: call `speak-selection`, `speak-simply`, `speak-translated [language]`, or `speak-stop`. They read stdin when piped and copy the selection otherwise, which needs Accessibility permission for the app that runs them. Quick Actions get the selection natively and need no permission.

Speak Simply and Speak Translated send the text through `claude -p` and start reading as soon as the first sentence comes back. Translation is into English unless you name a language, or set `SPEAK_TRANSLATE_LANGUAGE`. A non-English translation is read with the best installed macOS voice for that language; English keeps whatever voice you normally use.

Auto-speak after every answer:

```sh
speak-auto on            # brief style
speak-auto on decisions  # only the questions for you
speak-auto off
```

## Voices and engines

| Engine | Cost | Needs | Notes |
|---|---|---|---|
| `say` | free | macOS | Default. Uses your system voice. |
| `edge` | free | network | Microsoft neural voices via `edge-tts-universal`. Unofficial API. |
| `kokoro` | free | `npm i kokoro-js`, ~300MB model | Local neural TTS on CPU. |
| `openai` | paid | `OPENAI_API_KEY` | `gpt-4o-mini-tts`. |
| `elevenlabs` | free tier | `ELEVENLABS_API_KEY` | `eleven_flash_v2_5`. |

The first available engine wins unless you set `SPEAK_ENGINE`. `SPEAK_VOICE` picks the voice. Both can be changed for a session in chat: "switch to the edge engine", "use Jamie from now on".

The `say` engine follows your macOS system voice, so set it once in System Settings > Accessibility > Read & Speak. The compact voices are rough; download a Premium or Enhanced one under Manage Voices and it sounds far better. Do the same for any language you translate into.

### Pronunciations

Tell Claude "pronounce fancyapp as fan-see-app from now on" and it is saved to `~/.config/speak/pronunciations.json` (or `$SPEAK_CONFIG_DIR`), matched whole word, case-insensitive, and applied to every reading.

Links and emails are read as spoken: `https://example.com/login` becomes "example dot com slash login", and short endings like `de` or `io` are spelled letter by letter so "de" does not come out as "duh".

Words with two readings ("live", "read", "lead") cannot be fixed with a word list, so the skill has Claude respell them in the script: "lyive" for live as in alive, "red" for read in the past tense.

## How it works

The skill tells Claude how to write for the ear: short sentences, lead with the point, describe code rather than read it, end with the decision it needs from you. Claude sends the first sentence with `enqueue` straight away and the rest in small chunks, so audio starts before the script is finished.

The server strips leftover markdown, splits the text into sentences, and synthesises the next sentence while the current one plays.

On macOS a small Swift helper (`overlay/main.swift`) owns playback with `AVAudioPlayer` and draws the pill as an always-on-top panel that never takes focus. Node sends it one sentence file at a time as JSON lines on stdin; it reports `finished`, `back`, `skip`, or `stop` on stdout. Elsewhere the server falls back to `afplay` or `ffplay` without the overlay.

Auto-speak is a Claude Code `Stop` hook. When `~/.config/speak/auto` exists, the hook blocks the stop once and asks Claude to speak a script in the style named in the file.

## Development

```sh
npm run dev        # run the server with tsx
npm test           # vitest
npm run typecheck
```

MIT.
