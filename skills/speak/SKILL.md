---
name: speak
description: Read Claude's answer out loud through the speakers, rewritten as a spoken script instead of the raw text. Use when the user says "read that to me", "say it out loud", "speak", "tell me simply", "what do you need from me, out loud", "/speak", or asks for a spoken version of anything. Requires the speak MCP server.
---

# Speak

Turn the last answer (or whatever the user points at) into a short spoken script and hand it to the `speak` MCP tool. The user hears it. They do not read the script. Do not print the script in chat.

## Styles

Pick from the argument or the phrasing. Default `simple`.

- `simple`: plain words, no jargon, no identifiers unless unavoidable. Explain what happened and what it means. Under 120 words.
- `brief`: three sentences. What was done, what changed, what the user must decide.
- `decisions`: only the questions that need the user's input, each with the recommended answer. Skip everything else.
- `full`: the whole answer, spoken. Describe code instead of reading it ("a function that checks the token expiry"). Read tables as sentences.
- `eli5`: explain like the listener is new to programming. Analogies allowed.

## Write it how it sounds

The voice reads letters, not meaning. Fix that in the script:

- Words with two readings get respelled so the voice cannot pick the wrong one. Keep the word, change the letters: "live" as in alive becomes "lyve", "live" as in to live somewhere becomes "liv"; "read" past tense becomes "red"; "lead" the metal becomes "led"; "close" the verb becomes "cloze"; "record" the verb becomes "ri-CORD"; "wind" the verb becomes "wynd". Spelling tricks beat synonyms: the listener hears the word they expect.
- Brand and product names that are not dictionary words: spell them how they sound the first time, e.g. "fan-see-app" for fancyapp. The user can save these permanently with the `add_pronunciation` tool ("pronounce X as Y from now on"), and saved ones apply automatically, so check `list_pronunciations` if unsure.
- Acronyms: write them the way people say them. "API" as "ay pee eye", "SQL" as "sequel", "JSON" as "jason", "OAuth" as "oh auth".
- Links and emails: say them as spoken, "example dot com slash login", "jane at example dot com". Short endings are spelled out, "dot d e", "dot i o", "dot c o dot u k", because "de" read as a word comes out as "duh". The server does this for any that slip through, but writing them spoken keeps the rhythm right.
- Numbers, versions, times: "version two point one", "half three", "eleven forty five".

## Rules for the script

- Write for the ear. Short sentences. One idea each.
- Never read markdown, file paths, URLs, hashes, or code verbatim. Say what they are.
- Say numbers and names the way a person would.
- Start with the point, not with context.
- End with the ask if there is one: "I need you to decide X. I recommend Y."
- Irish English spelling. No em dashes.

## Steps

1. Work out what to speak: the last assistant message unless the user names something else (a file, a diff, a paragraph).
2. Write the script for the chosen style. Keep it in your head, not in the reply.
3. Call `speak` with `text` set to the script. Pass `engine` or `voice` only if the user asked.
4. Reply with one line: "Speaking." Nothing else. If the user asked to stop, call `stop`.
