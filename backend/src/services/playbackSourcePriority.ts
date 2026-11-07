/**
 * Admin-ordered playback providers. One ordered list both enables providers
 * (membership) and ranks them; the owned library is implicit and always first.
 */
export const PLAYBACK_PROVIDER_VALUES = [
    "peers",
    "tidal",
    "ytmusic",
    "soulseek",
    "lidarr",
] as const;

/** One provider an admin can place in the playback provider list. */
export type PlaybackProvider = (typeof PLAYBACK_PROVIDER_VALUES)[number];

/**
 * Persisted default list. The TIDAL, YouTube Music and Lidarr enable flags
 * still default to off and Soulseek still needs credentials, so the default
 * turns nothing on by itself.
 */
export const DEFAULT_PLAYBACK_PROVIDERS_VALUE =
    PLAYBACK_PROVIDER_VALUES.join(",");

/** Sources considered when choosing what plays a track. */
export const PLAYBACK_SOURCE_VALUES = [
    "library",
    "peers",
    "tidal",
    "ytmusic",
] as const;

/** One tier in playback source selection. */
export type PlaybackSource = (typeof PLAYBACK_SOURCE_VALUES)[number];
/** Library first, then the active streaming providers in admin order. */
export type PlaybackSourceOrder = readonly PlaybackSource[];

/** Order used when every streaming provider is active. */
export const DEFAULT_PLAYBACK_SOURCE_ORDER: PlaybackSourceOrder =
    PLAYBACK_SOURCE_VALUES;
// Offline peers and providers absent from the list remain a last-resort
// identity at 100, below the lowest active provider tier (200).
const UNAVAILABLE_SOURCE_PRIORITY = 100;

const PROVIDER_SET = new Set<string>(PLAYBACK_PROVIDER_VALUES);

function isPlaybackProvider(value: string): value is PlaybackProvider {
    return PROVIDER_SET.has(value);
}

function isStreamingSource(
    provider: PlaybackProvider,
): provider is Exclude<PlaybackSource, "library"> {
    return (
        provider === "peers" || provider === "tidal" || provider === "ytmusic"
    );
}

function splitList(value: string): string[] {
    return value
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean);
}

/**
 * Parses the stored provider list. Unknown and repeated entries are dropped;
 * a missing value (no settings row) means the default list.
 */
export function parsePlaybackProviders(value: unknown): PlaybackProvider[] {
    const stored =
        typeof value === "string" ? value : DEFAULT_PLAYBACK_PROVIDERS_VALUE;
    return [...new Set(splitList(stored).filter(isPlaybackProvider))];
}

/** Returns true for a duplicate-free list of known providers (may be empty). */
export function isPlaybackProviderList(value: string): boolean {
    const entries = splitList(value);
    return (
        entries.every(isPlaybackProvider) &&
        new Set(entries).size === entries.length
    );
}

/** Returns whether a provider is in the stored playback provider list. */
export function isPlaybackProviderActive(
    value: unknown,
    provider: PlaybackProvider,
): boolean {
    return parsePlaybackProviders(value).includes(provider);
}

/** Enable flags that mirror provider list membership. */
export function playbackProviderEnableFlags(value: string): {
    lidarrEnabled: boolean;
    tidalEnabled: boolean;
    ytMusicEnabled: boolean;
} {
    const providers = parsePlaybackProviders(value);
    return {
        lidarrEnabled: providers.includes("lidarr"),
        tidalEnabled: providers.includes("tidal"),
        ytMusicEnabled: providers.includes("ytmusic"),
    };
}

/** Derives the playback source order from the stored provider list. */
export function parsePlaybackSourceOrder(value: unknown): PlaybackSourceOrder {
    return [
        "library",
        ...parsePlaybackProviders(value).filter(isStreamingSource),
    ];
}

/** Returns whether a candidate is available and its source is active. */
export function isPlaybackSourceUsable(
    candidate: { source: PlaybackSource; available: boolean },
    order: PlaybackSourceOrder,
): boolean {
    return candidate.available && order.includes(candidate.source);
}

/**
 * Ranks a candidate. Offline sources and sources absent from the order always
 * remain below active providers.
 */
export function rankPlaybackSource(
    candidate: { source: PlaybackSource; available: boolean },
    order: PlaybackSourceOrder,
): number {
    if (!isPlaybackSourceUsable(candidate, order)) {
        return UNAVAILABLE_SOURCE_PRIORITY;
    }
    const index = order.indexOf(candidate.source);
    return (order.length - index + 1) * 100;
}
