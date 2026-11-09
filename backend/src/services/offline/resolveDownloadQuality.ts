import type { ParsedPlaybackId } from "../playback/playbackId";

/** The library's quality vocabulary, highest first. */
export type DownloadQuality = "original" | "high" | "medium" | "low";

/** The admin source qualities that fix how TIDAL and YT Music tracks are stored. */
export interface DownloadSourceQualities {
    /** `SystemSettings.tidalQuality` (LOW, HIGH, LOSSLESS, HI_RES_LOSSLESS). */
    tidalQuality?: string | null;
    /** `SystemSettings.ytMusicQuality` (LOW, MEDIUM, HIGH, LOSSLESS). */
    ytMusicQuality?: string | null;
}

/** The outcome of {@link resolveDownloadQuality}. */
export interface ResolvedDownloadQuality {
    /** The quality the download is served at: the lower of source and requested. */
    quality: DownloadQuality;
    /** The provider tier to fetch (the source quality's tier); `null` when the source has no admin tier. */
    providerTier: string | null;
    /** True when the effective quality is lower than the source quality. */
    needsTranscode: boolean;
}

const QUALITY_RANK: Record<DownloadQuality, number> = {
    original: 3,
    high: 2,
    medium: 1,
    low: 0,
};

/** The one table mapping provider tiers to the library vocabulary. */
const TIDAL_TIERS: Record<string, DownloadQuality> = {
    HI_RES_LOSSLESS: "original",
    LOSSLESS: "original",
    HIGH: "high",
    LOW: "low",
};

const YT_MUSIC_TIERS: Record<string, DownloadQuality> = {
    LOSSLESS: "original",
    HIGH: "high",
    MEDIUM: "medium",
    LOW: "low",
};

const DEFAULT_TIER = "HIGH";

function sourceFor(
    tiers: Record<string, DownloadQuality>,
    adminTier: string | null | undefined,
): { tier: string; quality: DownloadQuality } {
    const tier = adminTier && adminTier in tiers ? adminTier : DEFAULT_TIER;
    return { tier, quality: tiers[tier] };
}

/**
 * Decides the quality of a download in one place. The effective quality is the
 * lower of the admin source quality (`tidalQuality` for `td.*`,
 * `ytMusicQuality` for `ym.*`; none for `yt.*` and library tracks) and the
 * requested quality. A request above the source quality is served at the
 * source quality; a lower one needs a transcode of the source copy.
 *
 * `yt.*` has no admin setting, so its source quality is the requested one.
 * Library tracks are stored as `original`, so any lower request transcodes.
 */
export function resolveDownloadQuality(
    parsedId: ParsedPlaybackId,
    requested: DownloadQuality,
    admin: DownloadSourceQualities,
): ResolvedDownloadQuality {
    let source: { tier: string | null; quality: DownloadQuality };
    switch (parsedId.kind) {
        case "td":
            source = sourceFor(TIDAL_TIERS, admin.tidalQuality);
            break;
        case "ym":
            source = sourceFor(YT_MUSIC_TIERS, admin.ytMusicQuality);
            break;
        case "yt":
            source = { tier: null, quality: requested };
            break;
        default:
            source = { tier: null, quality: "original" };
    }
    const needsTranscode =
        QUALITY_RANK[requested] < QUALITY_RANK[source.quality];
    return {
        quality: needsTranscode ? requested : source.quality,
        providerTier: source.tier,
        needsTranscode,
    };
}
