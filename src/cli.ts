#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { resolveEngine } from "./engines/index.js";
import { FilePlayer } from "./player.js";
import { OverlayPlayer, overlayAvailable } from "./overlay-player.js";
import { splitIntoSentences, toSpeechText } from "./speech-text.js";
import { applyPronunciations, loadPronunciations, type Pronunciations } from "./pronunciations.js";

const [, , ...args] = process.argv;
const streaming = args.includes("--stream");
const words = args.filter((arg) => arg !== "--stream");
const player = overlayAvailable() ? new OverlayPlayer() : new FilePlayer();
player.showLoading();
const engine = await resolveEngine(process.env.SPEAK_ENGINE);
const pronunciations = await loadPronunciations();
const voice = process.env.SPEAK_VOICE;

const prepare = (text: string, saved: Pronunciations) => applyPronunciations(toSpeechText(text), saved);

if (streaming) {
  await speakAsItArrives();
} else {
  const input = words.length > 0 ? words.join(" ") : readFileSync(0, "utf8");
  await player.speak(prepare(input, pronunciations), engine, voice);
}
process.exit(0);

async function speakAsItArrives(): Promise<void> {
  let pending = "";
  const endsComplete = () => /[.!?…]["'”’)\]]?\s$/.test(pending);
  const flush = (all: boolean) => {
    const sentences = splitIntoSentences(pending);
    if (sentences.length === 0) return;
    const ready = all || endsComplete() ? sentences : sentences.slice(0, -1);
    if (ready.length === 0) return;
    pending = ready.length === sentences.length ? "" : pending.slice(pending.lastIndexOf(sentences[sentences.length - 1]));
    player.enqueue(prepare(ready.join(" "), pronunciations), engine, voice).catch((error) => console.error("enqueue failed:", error));
  };
  process.stdin.setEncoding("utf8");
  for await (const piece of process.stdin) {
    pending += piece;
    flush(false);
  }
  flush(true);
  while (player.isSpeaking) await new Promise((resolve) => setTimeout(resolve, 100));
}
