import { encodePlaybackId } from "./playback/playbackId";

interface FederatedPayloadPeer {
    id: string;
    name: string;
    outboundStatus: string | null;
}

/** Adds playback-only peer provenance without changing federation envelopes. */
export function withFederatedTrackPlayback<
    Track extends { id: string; origin: string },
>(
    track: Track,
    peer: FederatedPayloadPeer | null,
): Track & { playbackId?: string } {
    if (track.origin !== "FEDERATED") return track;
    const playbackId = encodePlaybackId({ kind: "t", trackId: track.id });
    if (!peer) return { ...track, playbackId };
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
