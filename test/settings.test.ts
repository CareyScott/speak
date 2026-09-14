import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import { defaultEngine, defaultVoice, loadSettings } from "../src/settings.js";

function settingsFile(contents: string): string {
  const file = join(mkdtempSync(join(tmpdir(), "speak-settings-")), "settings.json");
  writeFileSync(file, contents);
  return file;
}

describe("loadSettings", () => {
  it("reads engine, voice and translation language from the settings file", () => {
    expect(loadSettings(settingsFile('{"engine":"edge","voice":"Jamie","translateLanguage":"German"}'))).toEqual({
      engine: "edge",
      voice: "Jamie",
      translateLanguage: "German",
    });
  });

  it("treats a missing or broken settings file as no settings", () => {
    expect(loadSettings(join(tmpdir(), "speak-settings-missing", "settings.json"))).toEqual({});
    expect(loadSettings(settingsFile("{not json"))).toEqual({});
  });
});

describe("defaultEngine and defaultVoice", () => {
  it("prefer the environment over the settings file", () => {
    const settings = { engine: "edge", voice: "Jamie" };
    const environment = { SPEAK_ENGINE: "say", SPEAK_VOICE: "Daniel" };
    expect(defaultEngine(settings, environment)).toBe("say");
    expect(defaultVoice(settings, environment)).toBe("Daniel");
  });

  it("fall back to the settings file when the environment is empty", () => {
    expect(defaultEngine({ engine: "edge" }, { SPEAK_ENGINE: "" })).toBe("edge");
    expect(defaultVoice({ voice: "Jamie" }, {})).toBe("Jamie");
  });

  it("leave the choice to the engine when neither is set", () => {
    expect(defaultEngine({}, {})).toBeUndefined();
    expect(defaultVoice({ voice: "" }, {})).toBeUndefined();
  });
});
