import { describe, expect, it } from "vitest";
import { applyPronunciations } from "../src/pronunciations.js";

describe("applyPronunciations", () => {
  it("replaces whole words case-insensitively, longest first", () => {
    expect(applyPronunciations("Fancyapp and fancyapp-web, not fancyapps.", { fancyapp: "fan-see-app", "fancyapp-web": "fan-see-app web" })).toBe(
      "fan-see-app and fan-see-app web, not fancyapps.",
    );
  });
});
