import { GroupError } from "./listenTogetherGroupError";
import { parsePlaybackId } from "./playback/playbackId";
import type { QueueTrackInput } from "./listenTogether";

/**
 * Rewrites a `{ playbackId, metadata? }` input into the legacy identifier
 * fields the resolution below consumes. Inputs without a `playbackId` pass
 * through untouched.
 *
 * @throws GroupError `INVALID_PLAYBACK_ID` when the id cannot be parsed.
 */
export function legacyQueueInput(input: QueueTrackInput): QueueTrackInput {
    if (input.playbackId === undefined) return input;
    const ref = parsePlaybackId(input.playbackId);
    if (!ref) {
        throw new GroupError("INVALID_PLAYBACK_ID", "Invalid playbackId");
    }
    const { metadata } = input;
    const display = metadata
        ? {
              title: metadata.title,
              artist: metadata.artist,
              album: metadata.album,
              duration: metadata.durationSec,
              thumbnailUrl: metadata.artworkUrl,
              isrc: metadata.isrc,
          }
        : {};
    if (ref.kind === "t") return { trackId: ref.trackId };
    if (ref.kind === "td") return { tidalTrackId: ref.tidalId, ...display };
    return { youtubeVideoId: ref.videoId, ...display };
}
