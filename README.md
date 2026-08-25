# speak

Ask Claude to read its answer out loud.

Not a text-to-speech dump of the raw reply. You say "read that back to me simply" and Claude rewrites what it said as a short spoken script, then plays it. The script never appears in chat. It is a conversation between you and the model, with the text kept out of your way.

Works in Claude Code today. The playback half is a plain MCP server, so it also drops into Claude Desktop, Cursor, or any MCP client.

## What you get

- `speak` MCP server with tools `speak`, `stop`, `pause`, `resume`, `back`, `skip`, `add_pronunciation`, `list_pronunciations`, `list_voices`, `set_default`
- Floating overlay on macOS while Claude speaks: a small pill above every window with a live waveform, back one sentence, skip one sentence, pause and resume from the exact point, stop
- `/speak` skill for Claude Code, with styles: `simple` (default), `brief`, `decisions`, `full`, `eli5`
- Auto-speak: a `Stop` hook that reads a `brief` script after every answer, off by default
- `speak` CLI: `echo "hello" | speak`

## Engines

| Engine | Cost | Needs | Notes |
|---|---|---|---|
| `say` | free | macOS | Default. Download a Premium or Enhanced voice in System Settings > Accessibility > Spoken Content for good quality. Set a Siri voice as system default and bare `say` uses it. |
| `edge` | free | network | Microsoft neural voices via `edge-tts-universal`. Very good quality. Unofficial API. |
| `kokoro` | free | `npm i kokoro-js`, ~300MB model on first run | Local neural TTS, runs on CPU. |
| `openai` | paid | `OPENAI_API_KEY` | `gpt-4o-mini-tts`. |
| `elevenlabs` | free tier | `ELEVENLABS_API_KEY` | `eleven_flash_v2_5`. |

### Picking a voice on macOS

The default `say` engine uses your Mac's system voice, so set it up once in macOS and every reading uses it:

1. Open System Settings > Accessibility > Read & Speak (Spoken Content on older versions).
2. Under System Voice, pick a voice. Apple ships a large library per language; the Premium and Enhanced ones download on demand and sound far better than the compact defaults. Siri voices can be chosen here too.
3. Set the speaking rate to taste.

### Pronunciations

Tell Claude in chat:

- "pronounce fancyapp as fan-see-app from now on"
- "what pronunciations have you saved"

They live in `~/.config/speak/pronunciations.json` (override the folder with `SPEAK_CONFIG_DIR`), matched whole-word and case-insensitive, and applied to every reading:

```json
{
  "fancyapp": "fan-see-app",
  "OAuth": "oh auth"
}
```

Links and emails are read as spoken: `https://example.com/login` becomes "example dot com slash login", `jane@example.de` becomes "jane at example dot d e". Short endings like `de`, `io`, `co.uk` are spelled letter by letter, since "de" read as a word comes out as "duh".

Words with two readings ("live", "read", "lead") cannot be fixed by a word list. The skill tells Claude to respell them in the script so the voice cannot guess wrong: "lyve" for live as in alive, "red" for read in the past tense, "led" for the metal.

Leave `SPEAK_VOICE` unset to follow the system voice, or set it to a voice name from `say -v ?` to override for Claude only.

First available engine wins unless you set `SPEAK_ENGINE`. `SPEAK_VOICE` sets the voice. Both can be changed per session with the `set_default` tool ("switch to the edge engine").

## Install

Needs Node 20+, `jq`, and Claude Code.

```sh
git clone https://github.com/CareyScott/speak
cd speak
./install.sh
```

This builds the server and the macOS overlay helper (needs `swiftc` from the Xcode command line tools), registers the MCP server at user scope, links the skill into `~/.claude/skills`, adds the `Stop` hook to `~/.claude/settings.json`, and links `speak` and `speak-auto` into `~/.local/bin`.

Restart Claude Code.

## Use

Talk to Claude:

- "read that back to me"
- "say it simply"
- "what do you need from me, out loud"
- "/speak decisions"
- "stop"

Auto-speak after every answer:

```sh
speak-auto on            # brief style
speak-auto on decisions  # only the questions for you
speak-auto off
```

While it speaks, use the overlay or just say it:

- "pause", "resume", "go back a sentence", "skip that", "stop"

Pause holds the exact position. Resume continues from it. Back replays the previous sentence. Skip jumps to the next. Nothing is spoken about pausing or resuming; it just does it.

Pick an engine or voice:

```sh
export SPEAK_ENGINE=edge
export SPEAK_VOICE=en-IE-ConnorNeural
```

Or in chat: "list the say voices", "use Jamie from now on".

## How it works

The skill tells Claude how to write for the ear: short sentences, lead with the point, describe code instead of reading it, end with the decision it needs from you. Claude calls the `speak` tool with that script.

The server strips any leftover markdown, splits the script into sentences, and synthesises the next sentence while the current one plays.

On macOS a small Swift helper (`overlay/main.swift`) owns playback with `AVAudioPlayer` and draws the overlay: an always-on-top, non-activating panel that never steals focus. Node sends it one sentence file at a time over JSON lines on stdin and it reports `finished`, `back`, or `stop` on stdout. Pause and resume happen inside the helper, so the position is exact. Back and skip tell the server which sentence to play next. Elsewhere the server falls back to `afplay` or `ffplay` with no overlay.

Auto-speak is a Claude Code `Stop` hook. When the flag file `~/.config/speak/auto` exists, the hook blocks the stop once and asks Claude to speak a script in the style named in the file. The `stop_hook_active` guard stops it looping.

## Development

```sh
npm run dev        # run the server with tsx
npm test           # vitest
npm run typecheck
```

MIT.
