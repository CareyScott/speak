import type { Engine } from "./engines/engine.js";

export interface Speaker {
  speak(text: string, engine: Engine, voice: string | undefined): Promise<{ chunks: number }>;
  enqueue(text: string, engine: Engine, voice: string | undefined): Promise<{ chunks: number }>;
  showLoading(): void;
  stop(): boolean;
  pause(): void;
  resume(): void;
  back(): void;
  skip(): void;
  readonly isSpeaking: boolean;
}
