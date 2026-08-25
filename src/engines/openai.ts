import type { Engine } from "./engine.js";
import { EngineUnavailable } from "./engine.js";

const VOICES = ["alloy", "ash", "coral", "echo", "fable", "nova", "onyx", "sage", "shimmer"];
const DEFAULT_VOICE = "nova";

export const openaiEngine: Engine = {
  name: "openai",

  async isAvailable() {
    return Boolean(process.env.OPENAI_API_KEY);
  },

  async listVoices() {
    return VOICES;
  },

  async synthesize(text, voice, signal) {
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) throw new EngineUnavailable("openai", "OPENAI_API_KEY not set");
    const response = await fetch("https://api.openai.com/v1/audio/speech", {
      method: "POST",
      signal,
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: "gpt-4o-mini-tts", input: text, voice: voice ?? DEFAULT_VOICE, response_format: "mp3" }),
    });
    if (!response.ok) throw new Error(`OpenAI TTS ${response.status}: ${await response.text()}`);
    return Buffer.from(await response.arrayBuffer());
  },
};
