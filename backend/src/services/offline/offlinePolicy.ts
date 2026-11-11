import { prisma } from "../../utils/db";
import { TRACK_VISIBLE_WHERE } from "../../utils/librarySorting";
import { getSystemSettings } from "../../utils/systemSettings";
import type { ParsedPlaybackId } from "../playback/playbackId";

/** Why a track cannot be downloaded for offline use. */
export type OfflineBlockReason =
    | "SOURCE_DOWNLOADS_DISABLED"
    | "TRACK_UNAVAILABLE"
    | "SOURCE_UNAVAILABLE";

/** The outcome of {@link resolveOfflinePolicy}. */
export type OfflinePolicyResult =
    | { downloadable: true }
    | { downloadable: false; reason: OfflineBlockReason };

const ALLOWED: OfflinePolicyResult = { downloadable: true };

function blocked(reason: OfflineBlockReason): OfflinePolicyResult {
    return { downloadable: false, reason };
}

/**
 * Decides whether a user may download a track for offline use. One admin
 * switch (`SystemSettings.offlineDownloadsEnabled`, default on) applies to
 * every source alike. A library track must also still exist; whether a
 * remote source can serve the user is decided by `resolvePlayback`, exactly
 * as for streaming.
 */
export async function resolveOfflinePolicy(
    _userId: string,
    parsed: ParsedPlaybackId,
): Promise<OfflinePolicyResult> {
    const settings = await getSystemSettings();
    if (settings?.offlineDownloadsEnabled === false) {
        return blocked("SOURCE_DOWNLOADS_DISABLED");
    }
    if (parsed.kind === "t") {
        const track = await prisma.track.findUnique({
            where: { id: parsed.trackId, ...TRACK_VISIBLE_WHERE },
            select: { id: true },
        });
        if (!track) return blocked("TRACK_UNAVAILABLE");
    }
    return ALLOWED;
}
