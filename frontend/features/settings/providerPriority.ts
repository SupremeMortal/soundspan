import type { SystemSettings } from "./types";

/**
 * Providers that can sit in the Playback priority list. The local library is
 * always first and is never part of the stored list.
 */
export const PLAYBACK_PROVIDERS = [
    "peers",
    "tidal",
    "ytmusic",
    "soulseek",
    "lidarr",
] as const;
/** One provider in the Playback priority list. */
export type PlaybackProvider = (typeof PLAYBACK_PROVIDERS)[number];

/** Catalog providers behind Search's Discover results. */
export const SEARCH_PROVIDERS = [
    "lastfm",
    "deezer",
    "tidal",
    "youtube",
] as const;
/** One Search provider. */
export type SearchProvider = (typeof SEARCH_PROVIDERS)[number];

/** Providers tried for artist images. */
export const ARTIST_IMAGE_PROVIDERS = [
    "wikidata",
    "fanart",
    "deezer",
    "lastfm",
] as const;
/** One artist-image provider. */
export type ArtistImageProvider = (typeof ARTIST_IMAGE_PROVIDERS)[number];

/** Providers tried for album covers. */
export const ALBUM_COVER_PROVIDERS = [
    "coverartarchive",
    "deezer",
    "fanart",
] as const;
/** One album-cover provider. */
export type AlbumCoverProvider = (typeof ALBUM_COVER_PROVIDERS)[number];

/**
 * Parses a stored comma-separated provider list: unknown and repeated entries
 * are dropped, and the stored order is kept.
 */
export function parseProviderList<T extends string>(
    value: string | undefined | null,
    known: readonly T[],
): T[] {
    const entries = (value ?? "")
        .split(",")
        .map((entry) => entry.trim())
        .filter((entry): entry is T =>
            (known as readonly string[]).includes(entry),
        );
    return [...new Set(entries)];
}

/** Moves the entry at `from` to `to`; out-of-range indexes change nothing. */
export function moveProvider<T>(
    list: readonly T[],
    from: number,
    to: number,
): T[] {
    if (from < 0 || from >= list.length || to < 0 || to >= list.length) {
        return [...list];
    }
    const next = [...list];
    const [entry] = next.splice(from, 1);
    next.splice(to, 0, entry);
    return next;
}

/**
 * Places `provider` at `index` of the list as it is rendered. A provider that
 * is already in the list is moved instead of duplicated.
 */
export function insertProvider<T>(
    list: readonly T[],
    provider: T,
    index: number,
): T[] {
    const current = list.indexOf(provider);
    const next = list.filter((entry) => entry !== provider);
    const target = current >= 0 && current < index ? index - 1 : index;
    next.splice(Math.max(0, Math.min(target, next.length)), 0, provider);
    return next;
}

/** Removes `provider` from the list. */
export function removeProvider<T>(list: readonly T[], provider: T): T[] {
    return list.filter((entry) => entry !== provider);
}

/**
 * Settings update for a new Playback priority list. Being in the list is what
 * enables a provider, so the enable flags follow membership.
 */
export function playbackProvidersUpdate(
    active: readonly PlaybackProvider[],
): Partial<SystemSettings> {
    return {
        playbackProviders: active.join(","),
        tidalEnabled: active.includes("tidal"),
        ytMusicEnabled: active.includes("ytmusic"),
        lidarrEnabled: active.includes("lidarr"),
    };
}

/**
 * Settings update for a new Search priority list. The stored order stays a
 * full permutation, with inactive providers after the active ones.
 */
export function searchProvidersUpdate(
    active: readonly SearchProvider[],
    storedOrder: string | undefined,
): Partial<SystemSettings> {
    const previous = parseProviderList(storedOrder, SEARCH_PROVIDERS);
    const rest = [...previous, ...SEARCH_PROVIDERS].filter(
        (provider) => !active.includes(provider),
    );
    return {
        searchProviderOrder: [...new Set([...active, ...rest])].join(","),
        searchProvidersEnabled: active.join(","),
    };
}

/** Settings update for a new artist-image list; Fanart.tv follows both lists. */
export function artistImageProvidersUpdate(
    active: readonly ArtistImageProvider[],
    albumCoverProviders: string | undefined,
): Partial<SystemSettings> {
    return {
        artistImageProviders: active.join(","),
        fanartEnabled:
            active.includes("fanart") ||
            parseProviderList(
                albumCoverProviders,
                ALBUM_COVER_PROVIDERS,
            ).includes("fanart"),
    };
}

/** Settings update for a new album-cover list; Fanart.tv follows both lists. */
export function albumCoverProvidersUpdate(
    active: readonly AlbumCoverProvider[],
    artistImageProviders: string | undefined,
): Partial<SystemSettings> {
    return {
        albumCoverProviders: active.join(","),
        fanartEnabled:
            active.includes("fanart") ||
            parseProviderList(
                artistImageProviders,
                ARTIST_IMAGE_PROVIDERS,
            ).includes("fanart"),
    };
}
