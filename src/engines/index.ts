import type { Engine } from "./engine.js";
import { EngineUnavailable } from "./engine.js";
import { sayEngine } from "./say.js";
import { edgeEngine } from "./edge.js";
import { kokoroEngine } from "./kokoro.js";
import { openaiEngine } from "./openai.js";
import { elevenlabsEngine } from "./elevenlabs.js";

export const ENGINES: Engine[] = [sayEngine, edgeEngine, kokoroEngine, openaiEngine, elevenlabsEngine];
export const ENGINE_NAMES = ENGINES.map((engine) => engine.name);

export async function resolveEngine(requested: string | undefined): Promise<Engine> {
  if (requested) {
    const engine = ENGINES.find((candidate) => candidate.name === requested);
    if (!engine) throw new EngineUnavailable(requested, `unknown engine, choose one of ${ENGINE_NAMES.join(", ")}`);
    if (!(await engine.isAvailable())) throw new EngineUnavailable(requested, "not available on this machine");
    return engine;
  }
  for (const engine of ENGINES) {
    if (await engine.isAvailable()) return engine;
  }
  throw new EngineUnavailable("any", "no engine available");
}
