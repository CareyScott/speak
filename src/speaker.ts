import type { Engine } from "./engines/engine.js";

export interface Speaker {
  speak(text: string, engine: Engine, voice: string | undefined): Promise<{ chunks: number }>;
  stop(): boolean;
  pause(): void;
  resume(): void;
  back(): void;
  readonly isSpeaking: boolean;
}
