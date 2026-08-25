import { spawn, type ChildProcessByStdio } from "node:child_process";
import type { Readable, Writable } from "node:stream";
import { createInterface } from "node:readline";
import { existsSync } from "node:fs";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import type { Engine } from "./engines/engine.js";
import type { Speaker } from "./speaker.js";
import { splitIntoSentences } from "./speech-text.js";

type HelperEvent = { type: "finished" | "back" | "stop" | "paused" | "resumed"; index?: number };
type Outcome = "finished" | "back" | "stop";

export const OVERLAY_BINARY = join(dirname(fileURLToPath(import.meta.url)), "..", "overlay", "SpeakOverlay");

export function overlayAvailable(): boolean {
  return process.platform === "darwin" && existsSync(OVERLAY_BINARY);
}

export class OverlayPlayer implements Speaker {
  private helper: ChildProcessByStdio<Writable, Readable, null> | undefined;
  private waiting: ((outcome: Outcome) => void) | undefined;
  private controller: AbortController | undefined;

  async speak(text: string, engine: Engine, voice: string | undefined): Promise<{ chunks: number }> {
    this.stop();
    const controller = new AbortController();
    this.controller = controller;
    const sentences = splitIntoSentences(text);
    const dir = await mkdtemp(join(tmpdir(), "speak-overlay-"));
    const files = new Map<number, Promise<string>>();
    const fileFor = (index: number) => {
      let file = files.get(index);
      if (!file) {
        file = engine.synthesize(sentences[index], voice, controller.signal).then(async (audio) => {
          const path = join(dir, `${index}.audio`);
          await writeFile(path, audio);
          return path;
        });
        files.set(index, file);
      }
      return file;
    };
    try {
      let index = 0;
      while (index < sentences.length && !controller.signal.aborted) {
        if (index + 1 < sentences.length) void fileFor(index + 1).catch(() => undefined);
        const path = await fileFor(index);
        if (controller.signal.aborted) break;
        const outcome = await this.playSentence(path, index, sentences.length, controller.signal);
        if (outcome === "stop") break;
        index = outcome === "back" ? Math.max(0, index - 1) : index + 1;
      }
    } finally {
      this.send({ type: "idle" });
      await rm(dir, { recursive: true, force: true });
      if (this.controller === controller) this.controller = undefined;
    }
    return { chunks: sentences.length };
  }

  stop(): boolean {
    if (!this.controller) return false;
    this.controller.abort();
    this.controller = undefined;
    this.send({ type: "stop" });
    this.waiting?.("stop");
    return true;
  }

  pause(): void {
    this.send({ type: "pause" });
  }

  resume(): void {
    this.send({ type: "resume" });
  }

  back(): void {
    this.waiting?.("back");
  }

  get isSpeaking(): boolean {
    return this.controller !== undefined;
  }

  private playSentence(path: string, index: number, total: number, signal: AbortSignal): Promise<Outcome> {
    return new Promise((resolve) => {
      const settle = (outcome: Outcome) => {
        this.waiting = undefined;
        signal.removeEventListener("abort", onAbort);
        resolve(outcome);
      };
      const onAbort = () => settle("stop");
      signal.addEventListener("abort", onAbort, { once: true });
      this.waiting = settle;
      this.send({ type: "play", path, index, total });
    });
  }

  private send(message: Record<string, unknown>): void {
    this.ensureHelper().stdin.write(`${JSON.stringify(message)}\n`);
  }

  private ensureHelper(): ChildProcessByStdio<Writable, Readable, null> {
    if (this.helper && this.helper.exitCode === null) return this.helper;
    const helper = spawn(OVERLAY_BINARY, [], { stdio: ["pipe", "pipe", "inherit"] });
    createInterface({ input: helper.stdout }).on("line", (line) => this.onHelperEvent(line));
    helper.on("exit", () => {
      if (this.helper === helper) this.helper = undefined;
    });
    this.helper = helper;
    return helper;
  }

  private onHelperEvent(line: string): void {
    let event: HelperEvent;
    try {
      event = JSON.parse(line) as HelperEvent;
    } catch {
      return;
    }
    if (event.type === "finished" || event.type === "back") this.waiting?.(event.type);
    if (event.type === "stop") this.stop();
  }
}
