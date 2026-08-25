import type { Engine } from "./engine.js";

const MODEL_ID = "onnx-community/Kokoro-82M-v1.0-ONNX";
const DEFAULT_VOICE = "bf_emma";

type KokoroModel = {
  generate(text: string, options: { voice: string }): Promise<{ toWav(): ArrayBuffer }>;
  list_voices(): unknown;
};

let modelPromise: Promise<KokoroModel> | undefined;

async function loadModel(): Promise<KokoroModel> {
  modelPromise ??= import("kokoro-js").then((kokoro) =>
    kokoro.KokoroTTS.from_pretrained(MODEL_ID, { dtype: "q8", device: "cpu" }),
  ) as Promise<KokoroModel>;
  return modelPromise;
}

export const kokoroEngine: Engine = {
  name: "kokoro",

  async isAvailable() {
    try {
      await import("kokoro-js");
      return true;
    } catch {
      return false;
    }
  },

  async listVoices() {
    const model = await loadModel();
    return Object.keys(model.list_voices() as Record<string, unknown>);
  },

  async synthesize(text, voice, signal) {
    const model = await loadModel();
    const audio = await model.generate(text, { voice: voice ?? DEFAULT_VOICE });
    signal.throwIfAborted();
    return Buffer.from(audio.toWav());
  },
};
