#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { resolveEngine } from "./engines/index.js";
import { FilePlayer } from "./player.js";
import { OverlayPlayer, overlayAvailable } from "./overlay-player.js";
import { toSpeechText } from "./speech-text.js";
import { applyPronunciations, loadPronunciations } from "./pronunciations.js";

const [, , ...args] = process.argv;
const input = args.length > 0 ? args.join(" ") : readFileSync(0, "utf8");
const engine = await resolveEngine(process.env.SPEAK_ENGINE);
await (overlayAvailable() ? new OverlayPlayer() : new FilePlayer()).speak(applyPronunciations(toSpeechText(input), await loadPronunciations()), engine, process.env.SPEAK_VOICE);
process.exit(0);
