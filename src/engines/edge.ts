import type { Engine } from "./engine.js";

const DEFAULT_VOICE = "en-IE-ConnorNeural";

export const edgeEngine: Engine = {
  name: "edge",

  async isAvailable() {
    return true;
  },

  async listVoices() {
    const { listVoices } = await import("edge-tts-universal");
    const voices = await listVoices();
    return voices.map((voice) => voice.ShortName);
  },

  async synthesize(text, voice, signal) {
    const { EdgeTTS } = await import("edge-tts-universal");
    const tts = new EdgeTTS(text, voice ?? DEFAULT_VOICE);
    const result = await tts.synthesize();
    signal.throwIfAborted();
    return Buffer.from(await result.audio.arrayBuffer());
  },
};
