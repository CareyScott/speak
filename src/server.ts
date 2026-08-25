#!/usr/bin/env node
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { ENGINE_NAMES, resolveEngine } from "./engines/index.js";
import { FilePlayer } from "./player.js";
import { OverlayPlayer, overlayAvailable } from "./overlay-player.js";
import type { Speaker } from "./speaker.js";
import { toSpeechText } from "./speech-text.js";
import { applyPronunciations, loadPronunciations, PRONUNCIATIONS_FILE, savePronunciation } from "./pronunciations.js";

const player: Speaker = overlayAvailable() ? new OverlayPlayer() : new FilePlayer();
const defaults = {
  engine: process.env.SPEAK_ENGINE,
  voice: process.env.SPEAK_VOICE,
};

const server = new McpServer({ name: "speak", version: "0.1.0" });

server.registerTool(
  "speak",
  {
    description:
      "Read text aloud through the speakers. Pass a spoken script, not raw markdown: plain sentences, no code, no headings. Interrupts anything already playing.",
    inputSchema: {
      text: z.string().min(1).describe("Script to read aloud"),
      engine: z.enum(ENGINE_NAMES as [string, ...string[]]).optional().describe("TTS engine, defaults to SPEAK_ENGINE or first available"),
      voice: z.string().optional().describe("Voice name for the engine, defaults to SPEAK_VOICE or engine default"),
      wait: z.boolean().optional().describe("Wait for playback to finish before returning. Default false."),
    },
  },
  async ({ text, engine, voice, wait }) => {
    const chosen = await resolveEngine(engine ?? defaults.engine);
    const script = applyPronunciations(toSpeechText(text), await loadPronunciations());
    const playback = player.speak(script, chosen, voice ?? defaults.voice);
    playback.catch((error) => console.error("speak failed:", error));
    if (wait) await playback;
    return { content: [{ type: "text", text: `Speaking with ${chosen.name}${voice ?? defaults.voice ? ` (${voice ?? defaults.voice})` : ""}.` }] };
  },
);

server.registerTool(
  "enqueue",
  {
    description:
      "Append text to the current reading instead of interrupting it. Use for reading as you write: call once per few sentences, and playback starts on the first call while later calls keep it going. Starts a new reading if nothing is playing.",
    inputSchema: {
      text: z.string().min(1).describe("Spoken script fragment, whole sentences only"),
      engine: z.enum(ENGINE_NAMES as [string, ...string[]]).optional().describe("TTS engine, defaults to SPEAK_ENGINE or first available"),
      voice: z.string().optional().describe("Voice name for the engine, defaults to SPEAK_VOICE or engine default"),
    },
  },
  async ({ text, engine, voice }) => {
    const chosen = await resolveEngine(engine ?? defaults.engine);
    const script = applyPronunciations(toSpeechText(text), await loadPronunciations());
    const wasSpeaking = player.isSpeaking;
    const playback = player.enqueue(script, chosen, voice ?? defaults.voice);
    playback.catch((error) => console.error("enqueue failed:", error));
    return { content: [{ type: "text", text: wasSpeaking ? "Queued." : `Speaking with ${chosen.name}.` }] };
  },
);

server.registerTool(
  "stop",
  { description: "Stop whatever is currently being read aloud.", inputSchema: {} },
  async () => ({ content: [{ type: "text", text: player.stop() ? "Stopped." : "Nothing was playing." }] }),
);

server.registerTool(
  "pause",
  { description: "Pause the current reading. Resume continues from the same point.", inputSchema: {} },
  async () => {
    player.pause();
    return { content: [{ type: "text", text: "Paused." }] };
  },
);

server.registerTool(
  "resume",
  { description: "Resume a paused reading from where it stopped.", inputSchema: {} },
  async () => {
    player.resume();
    return { content: [{ type: "text", text: "Resumed." }] };
  },
);

server.registerTool(
  "back",
  { description: "Go back one sentence and continue reading from there.", inputSchema: {} },
  async () => {
    player.back();
    return { content: [{ type: "text", text: "Back one sentence." }] };
  },
);

server.registerTool(
  "skip",
  { description: "Skip the current sentence and continue with the next one.", inputSchema: {} },
  async () => {
    player.skip();
    return { content: [{ type: "text", text: "Skipped a sentence." }] };
  },
);

server.registerTool(
  "add_pronunciation",
  {
    description: "Remember how a word should be spoken. Stored in the user's config and applied to every future reading. Use when the user says something like: pronounce fancyapp as fan-see-app from now on.",
    inputSchema: {
      word: z.string().min(1).describe("Word as written, matched whole-word and case-insensitive"),
      spoken: z.string().min(1).describe("How it should sound, spelled phonetically, e.g. 'beh VEST or'"),
    },
  },
  async ({ word, spoken }) => {
    await savePronunciation(word, spoken);
    return { content: [{ type: "text", text: `Will say "${word}" as "${spoken}". Saved to ${PRONUNCIATIONS_FILE}.` }] };
  },
);

server.registerTool(
  "list_pronunciations",
  { description: "Show the saved pronunciation overrides.", inputSchema: {} },
  async () => {
    const entries = Object.entries(await loadPronunciations());
    const text = entries.length ? entries.map(([word, spoken]) => `${word} -> ${spoken}`).join("\n") : `None saved. File: ${PRONUNCIATIONS_FILE}`;
    return { content: [{ type: "text", text }] };
  },
);

server.registerTool(
  "list_voices",
  {
    description: "List voices for an engine. Without an engine, lists which engines are available on this machine.",
    inputSchema: { engine: z.enum(ENGINE_NAMES as [string, ...string[]]).optional() },
  },
  async ({ engine }) => {
    if (!engine) {
      const { ENGINES } = await import("./engines/index.js");
      const lines = await Promise.all(ENGINES.map(async (candidate) => `${candidate.name}: ${(await candidate.isAvailable()) ? "available" : "unavailable"}`));
      return { content: [{ type: "text", text: lines.join("\n") }] };
    }
    const chosen = await resolveEngine(engine);
    return { content: [{ type: "text", text: (await chosen.listVoices()).join("\n") }] };
  },
);

server.registerTool(
  "set_default",
  {
    description: "Set the default engine and voice for this session.",
    inputSchema: { engine: z.enum(ENGINE_NAMES as [string, ...string[]]).optional(), voice: z.string().optional() },
  },
  async ({ engine, voice }) => {
    if (engine) defaults.engine = engine;
    if (voice !== undefined) defaults.voice = voice;
    return { content: [{ type: "text", text: `Defaults: engine=${defaults.engine ?? "auto"}, voice=${defaults.voice ?? "engine default"}` }] };
  },
);

await server.connect(new StdioServerTransport());
