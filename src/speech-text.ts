const CODE_BLOCK = /```[\s\S]*?```/g;
const INLINE_CODE = /`([^`]+)`/g;
const LINK = /\[([^\]]+)\]\([^)]+\)/g;
const IMAGE = /!\[[^\]]*\]\([^)]+\)/g;
const HEADING = /^[ \t]*#{1,6}[ \t]+/gm;
const EMPHASIS = /(\*\*|__|\*|_)(?=\S)([\s\S]*?\S)\1/g;
const LIST_MARKER = /^[ \t]*(?:[-*+]|\d+\.)[ \t]+/gm;
const TABLE_ROW = /^[ \t]*\|.*\|[ \t]*$/gm;
const TABLE_RULE = /^[ \t]*\|?[ \t]*:?-+:?[ \t]*(\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*$\n?/gm;
const BLOCKQUOTE = /^[ \t]*>[ \t]?/gm;
const HTML_TAG = /<[^>]+>/g;
const MULTI_BLANK = /\n{3,}/g;
const URL = /\b(?:https?:\/\/)?(?:www\.)?([a-z0-9-]+(?:\.[a-z0-9-]+)+)(\/[^\s)>\]]*)?/gi;
const EMAIL = /\b([a-z0-9._-]+)@([a-z0-9.-]+\.[a-z]{2,})\b/gi;

const TLDS_SAID_AS_WORDS = new Set(["com", "org", "net", "dev", "app", "info", "biz", "gov", "edu", "cloud", "shop", "tech", "online", "site", "xyz", "me"]);

export function spellLetters(part: string): string {
  return part.toLowerCase().split("").join(" ");
}

function speakHost(host: string): string {
  const labels = host.split(".");
  return labels
    .map((label, index) => (index === 0 || TLDS_SAID_AS_WORDS.has(label.toLowerCase()) || label.length > 3 ? label : spellLetters(label)))
    .join(" dot ");
}

const SPOKEN_DOT_LABEL = /\bdot ([a-z]{2,3})\b(?=[\s.,;:!?)]|$)/gi;

function speakSpokenDots(text: string): string {
  return text.replace(SPOKEN_DOT_LABEL, (match, label: string) => (TLDS_SAID_AS_WORDS.has(label.toLowerCase()) ? match : `dot ${spellLetters(label)}`));
}

export function speakUrls(text: string): string {
  return speakSpokenDots(text)
    .replace(EMAIL, (_, user: string, domain: string) => `${user.replace(/\./g, " dot ")} at ${speakHost(domain)}`)
    .replace(URL, (_, host: string, path: string | undefined) => {
      const spokenHost = speakHost(host);
      const spokenPath = (path ?? "").replace(/\/+$/, "").replace(/\//g, " slash ").replace(/[-_]/g, " ");
      return `${spokenHost}${spokenPath}`;
    });
}

function tableRowToSentence(row: string): string {
  const cells = row.split("|").map((cell) => cell.trim()).filter((cell) => cell.length > 0);
  return `${cells.join(", ")}.`;
}

export function toSpeechText(markdown: string): string {
  return markdown
    .replace(CODE_BLOCK, "\n\nCode block omitted.\n\n")
    .replace(IMAGE, "")
    .replace(LINK, "$1")
    .replace(INLINE_CODE, "$1")
    .replace(HEADING, "")
    .replace(EMPHASIS, "$2")
    .replace(TABLE_RULE, "")
    .replace(TABLE_ROW, tableRowToSentence)
    .replace(LIST_MARKER, "")
    .replace(BLOCKQUOTE, "")
    .replace(HTML_TAG, "")
    .replace(MULTI_BLANK, "\n\n")
    .split("\n")
    .map(speakUrls)
    .join("\n")
    .trim();
}

export function splitIntoChunks(text: string): string[] {
  return text
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.replace(/\s+/g, " ").trim())
    .filter((paragraph) => paragraph.length > 0);
}

const SENTENCE = /[^.!?\n]+(?:[.!?]+["')\]]*|$)/g;

export function splitIntoSentences(text: string): string[] {
  return splitIntoChunks(text)
    .flatMap((paragraph) => paragraph.match(SENTENCE) ?? [paragraph])
    .map((sentence) => sentence.trim())
    .filter((sentence) => sentence.length > 0);
}
