import { z } from "zod";

/** The kinds of playable track a `playbackId` can name. */
export type PlaybackKind = "t" | "td" | "ym" | "yt";

/** The structured form of a `playbackId`. */
export type ParsedPlaybackId =
    | { kind: "t"; trackId: string }
    | { kind: "td"; tidalId: number }
    | { kind: "ym"; videoId: string }
    | { kind: "yt"; videoId: string };

const PLAYBACK_ID_PATTERN = /^(t|td|ym|yt)\.([A-Za-z0-9_-]{1,64})$/;
const CANONICAL_POSITIVE_INTEGER = /^[1-9][0-9]*$/;

function isValidTidalId(value: number): boolean {
    return Number.isSafeInteger(value) && value > 0;
}

/**
 * Parses a `playbackId` string into its structured form.
 * Returns `null` for anything that is not a canonical, valid id.
 */
export function parsePlaybackId(value: string): ParsedPlaybackId | null {
    if (typeof value !== "string") return null;
    const match = PLAYBACK_ID_PATTERN.exec(value);
    if (!match) return null;
    const kind = match[1] as PlaybackKind;
    const key = match[2];
    switch (kind) {
        case "t":
            return { kind, trackId: key };
        case "td": {
            if (!CANONICAL_POSITIVE_INTEGER.test(key)) return null;
            const tidalId = Number(key);
            return isValidTidalId(tidalId) ? { kind, tidalId } : null;
        }
        case "ym":
        case "yt":
            return { kind, videoId: key };
    }
}

/**
 * Encodes a structured reference as a `playbackId` string.
 * Throws when the input would not parse back to the same value.
 */
export function encodePlaybackId(ref: ParsedPlaybackId): string {
    let encoded: string;
    switch (ref?.kind) {
        case "t":
            encoded = `t.${ref.trackId}`;
            break;
        case "td":
            encoded = `td.${ref.tidalId}`;
            break;
        case "ym":
            encoded = `ym.${ref.videoId}`;
            break;
        case "yt":
            encoded = `yt.${ref.videoId}`;
            break;
        default:
            throw new Error("Invalid playbackId reference");
    }
    const parsed = parsePlaybackId(encoded);
    if (!parsed || JSON.stringify(parsed) !== JSON.stringify(ref)) {
        throw new Error(`Invalid playbackId reference: ${encoded}`);
    }
    return encoded;
}

/** Zod schema that validates and parses the string form of a `playbackId`. */
export const playbackIdSchema: z.ZodType<ParsedPlaybackId> = z
    .string()
    .transform((value, ctx) => {
        const parsed = parsePlaybackId(value);
        if (!parsed) {
            ctx.addIssue({ code: "custom", message: "Invalid playbackId" });
            return z.NEVER;
        }
        return parsed;
    });
