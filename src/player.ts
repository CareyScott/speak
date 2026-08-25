import { spawn } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Engine } from "./engines/engine.js";
import type { Speaker } from "./speaker.js";
import { splitIntoChunks } from "./speech-text.js";

function playerCommand(): string {
  if (process.platform === "darwin") return "afplay";
  if (process.platform === "win32") return "powershell";
  return "ffplay";
}

function playerArgs(path: string): string[] {
  if (process.platform === "win32") return ["-c", `(New-Object Media.SoundPlayer '${path}').PlaySync()`];
  if (process.platform === "linux") return ["-nodisp", "-autoexit", "-loglevel", "quiet", path];
  return [path];
}

async function playFile(path: string, signal: AbortSignal): Promise<void> {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(playerCommand(), playerArgs(path), { signal, stdio: "ignore" });
    child.on("error", (error) => (signal.aborted ? resolve() : reject(error)));
    child.on("exit", () => resolve());
  });
}

export class FilePlayer implements Speaker {
  private controller: AbortController | undefined;
  private queue: string[] = [];

  async speak(text: string, engine: Engine, voice: string | undefined): Promise<{ chunks: number }> {
    this.stop();
    this.queue = splitIntoChunks(text);
    return this.drain(engine, voice);
  }

  async enqueue(text: string, engine: Engine, voice: string | undefined): Promise<{ chunks: number }> {
    const chunks = splitIntoChunks(text);
    if (this.isSpeaking) {
      this.queue.push(...chunks);
      return { chunks: chunks.length };
    }
    this.queue = chunks;
    return this.drain(engine, voice);
  }

  private async drain(engine: Engine, voice: string | undefined): Promise<{ chunks: number }> {
    const controller = new AbortController();
    this.controller = controller;
    const chunks = this.queue;
    const dir = await mkdtemp(join(tmpdir(), "speak-play-"));
    try {
      let next = engine.synthesize(chunks[0], voice, controller.signal);
      for (let index = 0; index < chunks.length; index++) {
        const audio = await next;
        if (controller.signal.aborted) break;
        if (index + 1 < chunks.length) next = engine.synthesize(chunks[index + 1], voice, controller.signal);
        const path = join(dir, `${index}.audio`);
        await writeFile(path, audio);
        await playFile(path, controller.signal);
      }
    } finally {
      if (this.controller === controller) this.controller = undefined;
      await rm(dir, { recursive: true, force: true });
    }
    return { chunks: chunks.length };
  }

  pause(): void {}

  resume(): void {}

  back(): void {}

  skip(): void {}

  stop(): boolean {
    if (!this.controller) return false;
    this.controller.abort();
    this.controller = undefined;
    this.queue = [];
    return true;
  }

  get isSpeaking(): boolean {
    return this.controller !== undefined;
  }
}
