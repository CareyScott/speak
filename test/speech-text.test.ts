import { describe, expect, it } from "vitest";
import { splitIntoChunks, splitIntoSentences, toSpeechText } from "../src/speech-text.js";

describe("toSpeechText", () => {
  it("replaces code blocks and strips inline code", () => {
    expect(toSpeechText("Run `npm test`.\n\n```ts\nconst x = 1;\n```\n\nDone.")).toBe("Run npm test.\n\nCode block omitted.\n\nDone.");
  });

  it("strips headings, emphasis, links and list markers", () => {
    expect(toSpeechText("## Title\n\n- **bold** and _soft_ [link](https://x.y)\n1. second")).toBe("Title\n\nbold and soft link\nsecond");
  });

  it("turns table rows into sentences", () => {
    expect(toSpeechText("| a | b |\n|---|---|\n| 1 | 2 |")).toBe("a, b.\n1, 2.");
  });
});

describe("splitIntoChunks", () => {
  it("splits on blank lines and collapses whitespace", () => {
    expect(splitIntoChunks("one\ntwo\n\n\n  three  ")).toEqual(["one two", "three"]);
  });
});

describe("splitIntoSentences", () => {
  it("splits on sentence ends and keeps punctuation", () => {
    expect(splitIntoSentences("First one. Second one! Third?\n\nNo end")).toEqual(["First one.", "Second one!", "Third?", "No end"]);
  });
});

describe("speakUrls", () => {
  it("reads links and emails aloud", () => {
    expect(toSpeechText("See https://www.example.com/login/ or mail jane.d@example.de.")).toBe("See example dot com slash login or mail jane dot d at example dot d e.");
  });

  it("spells endings already written as spoken", () => {
    expect(toSpeechText("go to fancyapp dot de, or example dot com, or the dot io one.")).toBe("go to fancyapp dot d e, or example dot com, or the dot i o one.");
  });

  it("spells short country and tech TLDs letter by letter", () => {
    expect(toSpeechText("shop.example.de and speak.io and bbc.co.uk")).toBe("shop dot example dot d e and speak dot i o and bbc dot c o dot u k");
  });
});

describe("respellLive", () => {
  it("respells live as in running, leaves the verb alone", () => {
    expect(toSpeechText("The feature is live. It went live today. Live traffic. People who live here. We live in Dublin. It lives in config.")).toBe(
      "The feature is lyive. It went lyive today. Lyive traffic. People who live here. We live in Dublin. It lives in config.",
    );
  });
});
