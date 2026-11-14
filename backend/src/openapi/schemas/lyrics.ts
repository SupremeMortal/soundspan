import { z } from "zod";

/** Path parameter of `GET /api/lyrics/{trackId}`. */
export const LyricsParams = z.object({
    trackId: z
        .string()
        .describe(
            "A library track id, or any opaque value for a track that is not in the library, in which case the query parameters drive the lookup.",
        ),
});

/** Query of `GET /api/lyrics/{trackId}`. */
export const LyricsQuery = z.object({
    artist: z.string().optional(),
    title: z.string().optional(),
    album: z.string().optional(),
    duration: z.number().optional().describe("Track duration in seconds"),
});

/** Lyrics of one track; both texts are `null` when `source` is `none`. */
export const Lyrics = z
    .object({
        syncedLyrics: z
            .string()
            .nullable()
            .describe('LRC-format synced lyrics ("[00:12.34] Line text")'),
        plainLyrics: z.string().nullable(),
        synced: z.boolean(),
        source: z.enum(["lrclib", "embedded", "none"]),
    })
    .meta({ id: "Lyrics" });
