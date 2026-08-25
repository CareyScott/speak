import type { Engine } from "./engine.js";
import { EngineUnavailable } from "./engine.js";

const DEFAULT_VOICE_ID = "21m00Tcm4TlvDq8ikWAM";

function apiKey(): string {
  const key = process.env.ELEVENLABS_API_KEY;
  if (!key) throw new EngineUnavailable("elevenlabs", "ELEVENLABS_API_KEY not set");
  return key;
}

export const elevenlabsEngine: Engine = {
  name: "elevenlabs",

  async isAvailable() {
    return Boolean(process.env.ELEVENLABS_API_KEY);
  },

  async listVoices() {
    const response = await fetch("https://api.elevenlabs.io/v1/voices", { headers: { "xi-api-key": apiKey() } });
    if (!response.ok) throw new Error(`ElevenLabs voices ${response.status}`);
    const body = (await response.json()) as { voices: { voice_id: string; name: string }[] };
    return body.voices.map((voice) => `${voice.voice_id} (${voice.name})`);
  },

  async synthesize(text, voice, signal) {
    const voiceId = voice ?? DEFAULT_VOICE_ID;
    const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
      method: "POST",
      signal,
      headers: { "xi-api-key": apiKey(), "Content-Type": "application/json", Accept: "audio/mpeg" },
      body: JSON.stringify({ text, model_id: "eleven_flash_v2_5" }),
    });
    if (!response.ok) throw new Error(`ElevenLabs TTS ${response.status}: ${await response.text()}`);
    return Buffer.from(await response.arrayBuffer());
  },
};
