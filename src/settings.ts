import { readFileSync } from "node:fs";
import { join } from "node:path";
import { CONFIG_DIR } from "./pronunciations.js";

export const SETTINGS_FILE = join(CONFIG_DIR, "settings.json");

export type SpeakSettings = {
  engine?: string;
  voice?: string;
  translateLanguage?: string;
};

export function loadSettings(file: string = SETTINGS_FILE): SpeakSettings {
  try {
    return JSON.parse(readFileSync(file, "utf8")) as SpeakSettings;
  } catch {
    return {};
  }
}

export function defaultEngine(settings: SpeakSettings, environment: NodeJS.ProcessEnv = process.env): string | undefined {
  return environment.SPEAK_ENGINE || settings.engine || undefined;
}

export function defaultVoice(settings: SpeakSettings, environment: NodeJS.ProcessEnv = process.env): string | undefined {
  return environment.SPEAK_VOICE || settings.voice || undefined;
}
