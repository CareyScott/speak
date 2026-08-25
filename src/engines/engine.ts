export interface Engine {
  readonly name: string;
  isAvailable(): Promise<boolean>;
  listVoices(): Promise<string[]>;
  synthesize(text: string, voice: string | undefined, signal: AbortSignal): Promise<Buffer>;
}

export class EngineUnavailable extends Error {
  constructor(engineName: string, reason: string) {
    super(`Engine "${engineName}" unavailable: ${reason}`);
  }
}
