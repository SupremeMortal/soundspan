/**
 * Loads a federation peer eligible for outbound stream proxying.
 *
 * Extracted from tracks.ts (its only caller) to keep that route module
 * inside its file-size baseline.
 */

import { prisma } from "../../utils/db";
import { isPeerPlaybackActive } from "../../services/peerPlaybackFallback";

/**
 * Returns the track's peer when it can stream: the peer is active and peers
 * are in the admin's playback provider list. Otherwise returns null, so the
 * caller uses the peer fallback ladder.
 */
export async function loadActiveFederationStreamPeer(peerId: string | null) {
    if (!peerId || !(await isPeerPlaybackActive())) return null;
    const peer = await prisma.federationPeer.findUnique({
        where: { id: peerId },
        select: {
            id: true,
            name: true,
            baseUrl: true,
            outboundToken: true,
            outboundStatus: true,
        },
    });
    if (
        !peer ||
        peer.outboundStatus !== "ACTIVE" ||
        !peer.baseUrl ||
        !peer.outboundToken
    ) {
        return null;
    }
    return {
        ...peer,
        baseUrl: peer.baseUrl,
        outboundToken: peer.outboundToken,
    };
}
