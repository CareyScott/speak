import { execFile, spawn } from "node:child_process";
import { promisify } from "node:util";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Engine } from "./engine.js";

const execFileAsync = promisify(execFile);

export const sayEngine: Engine = {
  name: "say",

  async isAvailable() {
    return process.platform === "darwin";
  },

  async listVoices() {
    const { stdout } = await execFileAsync("say", ["-v", "?"]);
    return stdout
      .split("\n")
      .map((line) => line.replace(/\s{2,}.*$/, "").trim())
      .filter((name) => name.length > 0);
  },

  async synthesize(text, voice, signal) {
    const dir = await mkdtemp(join(tmpdir(), "speak-"));
    const outPath = join(dir, "out.aiff");
    const args = ["-o", outPath, ...(voice ? ["-v", voice] : [])];
    await new Promise<void>((resolve, reject) => {
      const child = spawn("say", args, { signal });
      child.stdin.end(text);
      child.on("error", reject);
      child.on("exit", (code) => (code === 0 ? resolve() : reject(new Error(`say exited ${code}`))));
    });
    const audio = await readFile(outPath);
    await rm(dir, { recursive: true, force: true });
    return audio;
  },
};
