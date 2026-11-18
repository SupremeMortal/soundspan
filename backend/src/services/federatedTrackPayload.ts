import { encodePlaybackId } from "./playback/playbackId";

interface FederatedPayloadPeer {
    id: string;
    name: string;
    outboundStatus: string | null;
}

/**
 * Adds a `playbackId` to a library track, plus playback-only peer provenance
 * for federated tracks, without changing federation envelopes.
 */
export function withLibraryTrackPlayback<
    Track extends { id: string; origin: string },
>(
    track: Track,
    peer: FederatedPayloadPeer | null,
): Track & { playbackId: string } {
    const playbackId = encodePlaybackId({ kind: "t", trackId: track.id });
    if (track.origin !== "FEDERATED" || !peer) return { ...track, playbackId };
    return {
        ...track,
        playbackId,
        source: "federated" as const,
        streamSource: "peer" as const,
        peer: {
            id: peer.id,
            name: peer.name,
            online: peer.outboundStatus === "ACTIVE",
        },
    };
}
