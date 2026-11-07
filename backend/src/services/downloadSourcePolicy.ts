/** Supported sources for library album downloads. */
import { lidarrService } from "./lidarr";
import { soulseekService } from "./soulseek";
import { tidalService } from "./tidal";
import { youtubeDownloadService } from "./youtubeDownload";
import {
    parsePlaybackProviders,
    type PlaybackProvider,
} from "./playbackSourcePriority";

export type DownloadSource = "tidal" | "lidarr" | "soulseek" | "youtube";

/** Health snapshot used by the pure source-resolution policy. */
export type DownloadSourceAvailability = Record<DownloadSource, boolean>;

/** Result of resolving the admin's download chain against availability. */
export type DownloadSourceResolution =
    | { kind: "dispatch"; source: DownloadSource }
    | { kind: "fail"; statusText: string; error: string };

interface DownloadSourcePolicyInput {
    chain: readonly DownloadSource[];
    availability: DownloadSourceAvailability;
}

const DOWNLOAD_SOURCE_BY_PROVIDER: Partial<
    Record<PlaybackProvider, DownloadSource>
> = {
    tidal: "tidal",
    ytmusic: "youtube",
    soulseek: "soulseek",
    lidarr: "lidarr",
};

/** Probe every supported album-download source concurrently. */
export async function probeDownloadSourceAvailability(): Promise<DownloadSourceAvailability> {
    const [tidal, lidarr, soulseek, youtube] = await Promise.all([
        tidalService.isAvailable(),
        lidarrService.isEnabled(),
        soulseekService.isAvailable(),
        youtubeDownloadService.isAvailable(),
    ]);
    return { tidal, lidarr, soulseek, youtube };
}

/**
 * Download sources in the order the admin listed their providers. Providers
 * that cannot download (peers) and providers absent from the list are left out.
 */
export function downloadSourceChain(
    playbackProviders: unknown,
): DownloadSource[] {
    return parsePlaybackProviders(playbackProviders).flatMap((provider) => {
        const source = DOWNLOAD_SOURCE_BY_PROVIDER[provider];
        return source ? [source] : [];
    });
}

/** Resolve the source without performing settings, health, or persistence I/O. */
export function resolveDownloadSource({
    chain,
    availability,
}: DownloadSourcePolicyInput): DownloadSourceResolution {
    const source = chain.find((candidate) => availability[candidate]);
    if (source) return { kind: "dispatch", source };
    if (chain.length === 0) {
        return {
            kind: "fail",
            error: "No download source is enabled in the playback provider list",
            statusText: "No download source enabled — skipped",
        };
    }
    return {
        kind: "fail",
        error: `No enabled download source is available (tried ${chain.join(", ")})`,
        statusText: "Download sources unavailable — skipped",
    };
}

/** The next available source after the dispatched one, for a runtime hand-off. */
export function resolveRuntimeFallback(
    chain: readonly DownloadSource[],
    dispatchedSource: DownloadSource,
    availability: DownloadSourceAvailability,
): DownloadSource | undefined {
    const index = chain.indexOf(dispatchedSource);
    if (index < 0) return undefined;
    return chain.slice(index + 1).find((candidate) => availability[candidate]);
}
