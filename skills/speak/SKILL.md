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

- Words with two readings get respelled so the voice cannot pick the wrong one. Keep the word, change the letters. Spelling tricks beat synonyms: the listener hears the word they expect. Before calling the tool, search the script for every word in this table and replace it:

  | written | meaning | write instead |
  |---|---|---|
  | live | alive, running, on air | lyive |
  | live | to live somewhere | liv |
  | read | past tense | red |
  | lead | the metal | led |
  | close | the verb, to shut | cloze |
  | wind | the verb, to turn | wynd |
  | record | the verb | ri-cord |
  | minute | tiny | my-newt |
  | tear | to rip | tair |
  | bass | the instrument | base |
  | produce | the verb | pro-dewss |

  "live" is the one that bites most in this work ("the feature is live", "the site is live"): it is always "lyive" unless someone lives somewhere.
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

## Speak in chunks, always

Never write the whole script and then call a tool. Load `mcp__speak__enqueue` and `mcp__speak__speak` together in one `ToolSearch` call (`select:mcp__speak__enqueue,mcp__speak__speak`) if they are not loaded yet. Then call `enqueue` with the first sentence alone, before writing anything else. Continue with `enqueue` calls of two to four whole sentences each, sent as soon as written. The first call starts playback; later calls append. Chunk boundaries are sentence ends only. Apply the respelling table and pronunciation rules to every chunk. Use `speak` only when the reading must interrupt whatever is playing.

This applies to reading an existing answer back as much as to writing something new: do not draft the full script first.

## Steps

1. Work out what to speak: the last assistant message unless the user names something else (a file, a diff, a paragraph).
2. Send the first sentence with `enqueue` straight away, then the rest in chunks. Do not print the script in the reply. Pass `engine` or `voice` only if the user asked.
3. Do not plan or rewrite the whole script before the first call. One sentence, send, next chunk.
4. Reply with one line: "Speaking." Nothing else. If the user asked to stop, call `stop`.
