import { prisma } from "../../utils/db";
import { TRACK_VISIBLE_WHERE } from "../../utils/librarySorting";
import { getSystemSettings } from "../../utils/systemSettings";
import { tidalStreamingService } from "../tidalStreaming";
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
 * Decides whether a user may download a track for offline use. The admin's
 * per-source toggles (`SystemSettings.offlineAllow*`, default on) are checked
 * first; then the source itself must be usable for this user.
 */
export async function resolveOfflinePolicy(
    userId: string,
    parsed: ParsedPlaybackId,
): Promise<OfflinePolicyResult> {
    const settings = await getSystemSettings();
    const allows = (field: string): boolean => settings?.[field] !== false;

    switch (parsed.kind) {
        case "t": {
            const track = await prisma.track.findUnique({
                where: { id: parsed.trackId, ...TRACK_VISIBLE_WHERE },
                select: { origin: true },
            });
            if (!track) return blocked("TRACK_UNAVAILABLE");
            const field =
                track.origin === "FEDERATED"
                    ? "offlineAllowFederated"
                    : "offlineAllowLocal";
            return allows(field)
                ? ALLOWED
                : blocked("SOURCE_DOWNLOADS_DISABLED");
        }
        case "td": {
            if (!allows("offlineAllowTidal")) {
                return blocked("SOURCE_DOWNLOADS_DISABLED");
            }
            const usable =
                (await tidalStreamingService.isEnabled()) &&
                (await tidalStreamingService.isAvailable()) &&
                (await tidalStreamingService.getAuthStatus(userId))
                    .authenticated;
            return usable ? ALLOWED : blocked("SOURCE_UNAVAILABLE");
        }
        case "ym": {
            if (!allows("offlineAllowYtMusic")) {
                return blocked("SOURCE_DOWNLOADS_DISABLED");
            }
            return settings?.ytMusicEnabled
                ? ALLOWED
                : blocked("SOURCE_UNAVAILABLE");
        }
        case "yt":
            return allows("offlineAllowYouTube")
                ? ALLOWED
                : blocked("SOURCE_DOWNLOADS_DISABLED");
    }
}
