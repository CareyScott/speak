import { mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

export type Pronunciations = Record<string, string>;

export const CONFIG_DIR = process.env.SPEAK_CONFIG_DIR ?? join(homedir(), ".config", "speak");
export const PRONUNCIATIONS_FILE = join(CONFIG_DIR, "pronunciations.json");

export async function loadPronunciations(): Promise<Pronunciations> {
  try {
    return JSON.parse(await readFile(PRONUNCIATIONS_FILE, "utf8")) as Pronunciations;
  } catch {
    return {};
  }
}

export async function savePronunciation(word: string, spoken: string): Promise<Pronunciations> {
  const current = await loadPronunciations();
  current[word] = spoken;
  await mkdir(CONFIG_DIR, { recursive: true });
  await writeFile(PRONUNCIATIONS_FILE, `${JSON.stringify(current, null, 2)}\n`);
  return current;
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

export function applyPronunciations(text: string, pronunciations: Pronunciations): string {
  return Object.entries(pronunciations)
    .sort(([a], [b]) => b.length - a.length)
    .reduce((result, [word, spoken]) => result.replace(new RegExp(`\\b${escapeRegex(word)}\\b`, "gi"), spoken), text);
}
