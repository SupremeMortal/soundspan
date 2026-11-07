import { z } from "zod";

/** Providers the artist image resolver can try. */
export const ARTIST_IMAGE_PROVIDER_VALUES = [
    "wikidata",
    "fanart",
    "deezer",
    "lastfm",
] as const;

/** Providers the album cover resolver can try. */
export const ALBUM_COVER_PROVIDER_VALUES = [
    "coverartarchive",
    "deezer",
    "fanart",
] as const;

/** One artist image provider. */
export type ArtistImageProvider = (typeof ARTIST_IMAGE_PROVIDER_VALUES)[number];
/** One album cover provider. */
export type AlbumCoverProvider = (typeof ALBUM_COVER_PROVIDER_VALUES)[number];

/** Persisted default artist image list: every provider, Wikidata first. */
export const DEFAULT_ARTIST_IMAGE_PROVIDERS_VALUE =
    ARTIST_IMAGE_PROVIDER_VALUES.join(",");
/** Persisted default album cover list: every provider, Cover Art Archive first. */
export const DEFAULT_ALBUM_COVER_PROVIDERS_VALUE =
    ALBUM_COVER_PROVIDER_VALUES.join(",");

function splitList(value: string): string[] {
    return value
        .split(",")
        .map((entry) => entry.trim())
        .filter(Boolean);
}

function parseProviderList<T extends string>(
    known: readonly T[],
    value: unknown,
    fallback: string,
): T[] {
    const stored = typeof value === "string" ? value : fallback;
    const entries = splitList(stored).filter((entry): entry is T =>
        (known as readonly string[]).includes(entry),
    );
    return [...new Set(entries)];
}

function isProviderList(known: readonly string[], value: string): boolean {
    const entries = splitList(value);
    return (
        entries.every((entry) => known.includes(entry)) &&
        new Set(entries).size === entries.length
    );
}

/**
 * Parses the stored artist image list. Unknown and repeated entries are
 * dropped; a missing value (no settings row) means the default list.
 */
export function parseArtistImageProviders(
    value: unknown,
): ArtistImageProvider[] {
    return parseProviderList(
        ARTIST_IMAGE_PROVIDER_VALUES,
        value,
        DEFAULT_ARTIST_IMAGE_PROVIDERS_VALUE,
    );
}

/**
 * Parses the stored album cover list. Unknown and repeated entries are
 * dropped; a missing value (no settings row) means the default list.
 */
export function parseAlbumCoverProviders(value: unknown): AlbumCoverProvider[] {
    return parseProviderList(
        ALBUM_COVER_PROVIDER_VALUES,
        value,
        DEFAULT_ALBUM_COVER_PROVIDERS_VALUE,
    );
}

/** Returns true for a duplicate-free list of artist image providers. */
export function isArtistImageProviderList(value: string): boolean {
    return isProviderList(ARTIST_IMAGE_PROVIDER_VALUES, value);
}

/** Returns true for a duplicate-free list of album cover providers. */
export function isAlbumCoverProviderList(value: string): boolean {
    return isProviderList(ALBUM_COVER_PROVIDER_VALUES, value);
}

/** Fanart.tv is enabled exactly when either metadata list includes it. */
export function fanartEnabledFor(
    artistImageProviders: unknown,
    albumCoverProviders: unknown,
): boolean {
    return (
        parseArtistImageProviders(artistImageProviders).includes("fanart") ||
        parseAlbumCoverProviders(albumCoverProviders).includes("fanart")
    );
}

/** System-settings API fields for the metadata provider lists. */
export const metadataProviderFields = {
    artistImageProviders: z
        .string()
        .refine(isArtistImageProviderList, "Invalid artist image providers")
        .optional(),
    albumCoverProviders: z
        .string()
        .refine(isAlbumCoverProviderList, "Invalid album cover providers")
        .optional(),
};
