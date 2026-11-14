import { z } from "zod";

/**
 * One entry of the recently listened shelf: a library artist, an audiobook in
 * progress or a podcast with an episode in progress. Fields after
 * `lastPlayedAt` are sent only for the kinds named on them.
 */
export const RecentlyListenedItem = z
    .object({
        id: z.string(),
        type: z.enum(["artist", "audiobook", "podcast"]),
        name: z.string(),
        coverArt: z.string().nullable(),
        lastPlayedAt: z.iso.datetime(),
        /** Artist. */
        mbid: z.string().nullable().optional(),
        /** Artist. */
        albumCount: z.number().int().optional(),
        /** Audiobook and podcast. */
        author: z.string().nullable().optional(),
        /** Audiobook and podcast: percent listened, 0 to 100. */
        progress: z.number().int().optional(),
        /** Podcast: the episode in progress. */
        episodeId: z.string().optional(),
    })
    .meta({ id: "RecentlyListenedItem" });

/** The recently listened shelf, most recent first. */
export const RecentlyListenedResponse = z
    .object({ items: z.array(RecentlyListenedItem) })
    .meta({ id: "RecentlyListenedResponse" });

/** An artist with a recently added library album. */
export const RecentlyAddedArtist = z
    .object({
        id: z.string(),
        mbid: z.string().nullable(),
        name: z.string(),
        coverArt: z.string().nullable(),
        albumCount: z.number().int(),
    })
    .meta({ id: "RecentlyAddedArtist" });

/** Artists of the most recently added library albums, newest first. */
export const RecentlyAddedResponse = z
    .object({ artists: z.array(RecentlyAddedArtist) })
    .meta({ id: "RecentlyAddedResponse" });

/** Query of the recently listened and recently added shelves. */
export const RecentShelfQuery = z.object({
    limit: z.number().int().optional(),
});
