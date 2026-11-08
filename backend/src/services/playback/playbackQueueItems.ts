import { prisma } from "../../utils/db";
import { PlaybackInputError, playbackTrackInputSchema } from "./playbackInput";
import { parsePlaybackId, type ParsedPlaybackId } from "./playbackId";

/**
 * Turns queue entries that carry a `playbackId` into the legacy item shape
 * the playback-state store already persists (`streamSource` plus provider
 * ids, display fields from the library row or the client's `metadata`).
 * Entries without a `playbackId` pass through untouched. When `playbackId`
 * is present it wins and the entry's legacy source fields are ignored.
 *
 * @throws PlaybackInputError `INVALID_PLAYBACK_ID` for an unparseable id and
 *   `TRACK_NOT_FOUND` for a library id with no stored track.
 */
export async function expandPlaybackIdQueueItems(
    queue: unknown[],
): Promise<unknown[]> {
    const parsedById = new Map<string, ParsedPlaybackId>();
    for (const item of queue) {
        const playbackId = playbackIdOf(item);
        if (playbackId === undefined) continue;
        const parsed = parsePlaybackId(playbackId);
        if (!parsed) {
            throw new PlaybackInputError(
                "INVALID_PLAYBACK_ID",
                "Invalid playbackId",
            );
        }
        parsedById.set(playbackId, parsed);
    }
    if (parsedById.size === 0) return queue;

    const libraryIds = [...parsedById.values()].flatMap((ref) =>
        ref.kind === "t" ? [ref.trackId] : [],
    );
    const tracks = libraryIds.length
        ? await prisma.track.findMany({
              where: { id: { in: libraryIds } },
              select: {
                  id: true,
                  title: true,
                  duration: true,
                  origin: true,
                  album: {
                      select: {
                          id: true,
                          title: true,
                          coverUrl: true,
                          artist: { select: { id: true, name: true } },
                      },
                  },
              },
          })
        : [];
    const trackById = new Map(tracks.map((track) => [track.id, track]));

    return queue.map((item) => {
        const playbackId = playbackIdOf(item);
        if (playbackId === undefined) return item;
        const ref = parsedById.get(playbackId)!;
        if (ref.kind === "t") {
            const track = trackById.get(ref.trackId);
            if (!track) {
                throw new PlaybackInputError(
                    "TRACK_NOT_FOUND",
                    "Track not found",
                );
            }
            return {
                itemType: "track",
                id: track.id,
                streamSource: track.origin === "FEDERATED" ? "peer" : "local",
                title: track.title,
                duration: track.duration,
                artist: track.album.artist,
                album: {
                    id: track.album.id,
                    title: track.album.title,
                    coverArt: track.album.coverUrl,
                },
            };
        }
        const metadata = playbackTrackInputSchema.shape.metadata.parse(
            (item as Record<string, unknown>).metadata,
        );
        const display = {
            itemType: "track",
            ...(metadata
                ? {
                      title: metadata.title,
                      duration: metadata.durationSec,
                      artist: { id: "", name: metadata.artist },
                      album: {
                          id: "",
                          title: metadata.album,
                          coverArt: metadata.artworkUrl ?? null,
                      },
                  }
                : {}),
        };
        if (ref.kind === "td") {
            return {
                ...display,
                id: `tidal:${ref.tidalId}`,
                streamSource: "tidal",
                tidalTrackId: ref.tidalId,
            };
        }
        return {
            ...display,
            id: `yt:${ref.videoId}`,
            streamSource: ref.kind === "ym" ? "youtube" : "youtube-direct",
            youtubeVideoId: ref.videoId,
        };
    });
}

function playbackIdOf(item: unknown): string | undefined {
    if (!item || typeof item !== "object") return undefined;
    const value = (item as Record<string, unknown>).playbackId;
    return typeof value === "string" ? value : undefined;
}
