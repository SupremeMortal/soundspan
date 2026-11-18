import { logger } from "../utils/logger";
import { redisClient } from "../utils/redis";
import { getSystemSettings } from "../utils/systemSettings";
import {
    resolveUsableSearchProviders,
    searchDiscoverMusic,
    type PlayableProvider,
} from "./discoverMusicSearch";
import { searchPlaylists } from "./playlistSearch";
import { searchItunesPodcasts } from "./podcastDirectorySearch";
import { searchRemoteLibrary } from "./remoteLibrary/remoteLibrarySearch";
import {
    normalizeCacheQuery,
    searchService,
    type AlbumSearchResult,
    type ArtistSearchResult,
    type PodcastSearchResult,
    type TrackSearchResult,
} from "./search";
import { getSearchCacheVersion } from "./searchCacheVersion";
import {
    toSearchAlbumPayload,
    toSearchArtistPayload,
    toSearchTrackPayload,
} from "./searchPayloads";
import { resolveSearchProviders } from "./searchProviderSettings";
import {
    dedupeLibraryFirst,
    foldForMatch,
    rankSearchItems,
    withinTierFromProviderOrder,
    withinTierFromSimilarity,
    withinTierFromTsRank,
    type RankCandidate,
    type SearchItemKind,
    type SearchItemSource,
} from "./searchRanking";

const log = logger.child("UnifiedSearch");

/** The `type` filter of the unified search. */
export const UNIFIED_SEARCH_TYPES = [
    "all",
    "tracks",
    "artists",
    "albums",
    "playlists",
    "podcasts",
] as const;

/** One value of {@link UNIFIED_SEARCH_TYPES}. */
export type UnifiedSearchType = (typeof UNIFIED_SEARCH_TYPES)[number];

/** Highest `offset` a single-type search honours; paging re-ranks every earlier row. */
export const UNIFIED_SEARCH_MAX_OFFSET = 1000;

/** Catalogue providers return at most this many results per request. */
const CATALOGUE_MAX_LIMIT = 50;

/** Seconds a unified result stays cached. */
const CACHE_TTL_SECONDS = 120;

/** The payload field each result carries, by kind and origin. */
type PayloadField =
    | "track"
    | "remoteTrack"
    | "artist"
    | "album"
    | "remoteAlbum"
    | "playlist"
    | "podcast"
    | "catalogue";

interface Payload {
    field: PayloadField;
    value: unknown;
}

/** One unified search result. Exactly one payload field is set. */
export type UnifiedSearchItem = {
    kind: SearchItemKind;
    score: number;
    source: SearchItemSource;
} & Partial<Record<PayloadField, unknown>>;

/** A page of unified search results. */
export interface UnifiedSearchPage {
    items: UnifiedSearchItem[];
    hasMore: boolean;
}

/** Input of {@link unifiedSearch}. */
export interface UnifiedSearchInput {
    userId: string;
    query: string;
    type: UnifiedSearchType;
    limit: number;
    offset: number;
}

type Candidate = RankCandidate<Payload>;

const KINDS_BY_TYPE: Record<UnifiedSearchType, readonly SearchItemKind[]> = {
    all: ["track", "artist", "album", "playlist", "podcast"],
    tracks: ["track"],
    artists: ["artist"],
    albums: ["album"],
    playlists: ["playlist"],
    podcasts: ["podcast"],
};

function nameKey(
    kind: string,
    ...parts: Array<string | null | undefined>
): string {
    return `${kind}:${parts.map((part) => foldForMatch(part ?? "")).join("|")}`;
}

function libraryWithinTier(row: {
    rank?: number;
    matchedBy?: "trigram";
}): number {
    if (typeof row.rank !== "number") return 0;
    return row.matchedBy === "trigram"
        ? withinTierFromSimilarity(row.rank)
        : withinTierFromTsRank(row.rank);
}

async function settle<T>(label: string, run: () => Promise<T[]>): Promise<T[]> {
    try {
        return await run();
    } catch (error) {
        log.warn(`${label} search failed`, { error });
        return [];
    }
}

function artistCandidates(rows: ArtistSearchResult[]): Candidate[] {
    return rows.map((row) => ({
        kind: "artist",
        source: "library",
        name: row.name,
        withinTier: libraryWithinTier(row),
        keys: [nameKey("artist", row.name)],
        payload: { field: "artist", value: toSearchArtistPayload(row) },
    }));
}

function albumCandidates(rows: AlbumSearchResult[]): Candidate[] {
    return rows.map((row) => ({
        kind: "album",
        source: "library",
        name: row.title,
        withinTier: libraryWithinTier(row),
        keys: [nameKey("album", row.title, row.artistName)],
        payload: { field: "album", value: toSearchAlbumPayload(row) },
    }));
}

function trackCandidates(rows: TrackSearchResult[]): Candidate[] {
    return rows.map((row) => {
        const value = toSearchTrackPayload(row);
        return {
            kind: "track",
            source: "library",
            name: row.title,
            withinTier: libraryWithinTier(row),
            keys: [
                ...(value.playbackId ? [value.playbackId] : []),
                nameKey("track", row.title, row.artistName),
            ],
            payload: { field: "track", value },
        };
    });
}

function podcastCandidates(rows: PodcastSearchResult[]): Candidate[] {
    return rows.map((row) => ({
        kind: "podcast",
        source: "library",
        name: row.title,
        withinTier: libraryWithinTier(row),
        keys: [nameKey("podcast", row.title, row.author)],
        payload: { field: "podcast", value: row },
    }));
}

type RemoteResults = Awaited<ReturnType<typeof searchRemoteLibrary>>;

function remoteCandidates(remote: RemoteResults): Candidate[] {
    const tracks: Candidate[] = remote.tracks.map((track, index) => ({
        kind: "track",
        source: "library",
        name: track.title,
        withinTier: withinTierFromProviderOrder(index, remote.tracks.length),
        keys: [
            ...(track.playbackId ? [track.playbackId] : []),
            nameKey("track", track.title, track.artist?.name),
        ],
        payload: { field: "remoteTrack", value: track },
    }));
    const albums: Candidate[] = remote.albums.map((album, index) => ({
        kind: "album",
        source: "library",
        name: album.title,
        withinTier: withinTierFromProviderOrder(index, remote.albums.length),
        keys: [nameKey("album", album.title, album.artist?.name)],
        payload: { field: "remoteAlbum", value: album },
    }));
    return [...tracks, ...albums];
}

/** Catalogue rows (`DiscoverResult`), scored by their provider order. */
function catalogueCandidates(
    kind: SearchItemKind,
    rows: ReadonlyArray<{
        name: string;
        artist?: unknown;
        playbackId?: unknown;
    }>,
): Candidate[] {
    return rows.map((row, index) => {
        const artist = typeof row.artist === "string" ? row.artist : undefined;
        const keys =
            kind === "artist"
                ? [nameKey("artist", row.name)]
                : [
                      ...(typeof row.playbackId === "string"
                          ? [row.playbackId]
                          : []),
                      nameKey(kind, row.name, artist),
                  ];
        return {
            kind,
            source: "catalogue",
            name: row.name,
            withinTier: withinTierFromProviderOrder(index, rows.length),
            keys,
            payload: { field: "catalogue", value: row },
        };
    });
}

async function searchCatalogueMusic(
    input: UnifiedSearchInput,
    limit: number,
    kinds: readonly SearchItemKind[],
): Promise<Candidate[]> {
    if (!kinds.includes("artist") && !kinds.includes("track")) return [];
    try {
        const providers = await resolveUsableSearchProviders(
            resolveSearchProviders((await getSystemSettings()) ?? {}),
            input.userId,
        );
        if (providers.length === 0) return [];
        const playableProviders =
            await resolveUsableSearchProviders<PlayableProvider>(
                ["tidal", "youtube"],
                input.userId,
            );
        const music = await searchDiscoverMusic({
            query: input.query,
            limit: Math.min(limit, CATALOGUE_MAX_LIMIT),
            userId: input.userId,
            providers,
            playableProviders,
        });
        return [
            ...(kinds.includes("artist")
                ? catalogueCandidates("artist", music.artists)
                : []),
            ...(kinds.includes("track")
                ? catalogueCandidates("track", music.tracks)
                : []),
        ];
    } catch (error) {
        log.warn("Catalogue music search failed", { error });
        return [];
    }
}

async function collectCandidates(
    input: UnifiedSearchInput,
    fetchLimit: number,
): Promise<Candidate[]> {
    const kinds = KINDS_BY_TYPE[input.type];
    const wants = (kind: SearchItemKind) => kinds.includes(kind);
    const query = input.query;
    const library = { query, limit: fetchLimit, offset: 0 };
    const none = async () => [];

    const [
        artists,
        albums,
        tracks,
        podcasts,
        playlists,
        remote,
        music,
        directory,
    ] = await Promise.all([
        wants("artist")
            ? settle("Library artist", () =>
                  searchService.searchArtists(library),
              )
            : none(),
        wants("album")
            ? settle("Library album", () => searchService.searchAlbums(library))
            : none(),
        wants("track")
            ? settle("Library track", () => searchService.searchTracks(library))
            : none(),
        wants("podcast")
            ? settle("Library podcast", () =>
                  searchService.searchPodcastsFTS(library),
              )
            : none(),
        wants("playlist")
            ? settle("Playlist", () =>
                  searchPlaylists({
                      userId: input.userId,
                      query,
                      limit: fetchLimit,
                      offset: 0,
                  }),
              )
            : none(),
        wants("track") || wants("album")
            ? searchRemoteLibrary(input.userId, query, {
                  tracks: wants("track") ? fetchLimit : 0,
                  albums: wants("album") ? fetchLimit : 0,
              }).catch((error) => {
                  log.warn("Remote library search failed", { error });
                  return { tracks: [], albums: [] } as RemoteResults;
              })
            : Promise.resolve({ tracks: [], albums: [] } as RemoteResults),
        searchCatalogueMusic(input, fetchLimit, kinds),
        wants("podcast")
            ? settle("Podcast directory", () =>
                  searchItunesPodcasts(
                      query,
                      Math.min(fetchLimit, CATALOGUE_MAX_LIMIT),
                  ),
              )
            : none(),
    ]);

    return [
        ...artistCandidates(artists as ArtistSearchResult[]),
        ...albumCandidates(albums as AlbumSearchResult[]),
        ...trackCandidates(tracks as TrackSearchResult[]),
        ...podcastCandidates(podcasts as PodcastSearchResult[]),
        ...(playlists as Awaited<ReturnType<typeof searchPlaylists>>).map(
            (hit): Candidate => ({
                kind: "playlist",
                source: "library",
                name: hit.playlist.name,
                withinTier: withinTierFromSimilarity(hit.similarity),
                keys: [],
                payload: { field: "playlist", value: hit.playlist },
            }),
        ),
        ...remoteCandidates(remote),
        ...music,
        ...catalogueCandidates(
            "podcast",
            directory as Awaited<ReturnType<typeof searchItunesPodcasts>>,
        ),
    ].filter((candidate) => wants(candidate.kind));
}

async function runUnifiedSearch(
    input: UnifiedSearchInput,
): Promise<UnifiedSearchPage> {
    const single = input.type !== "all";
    const offset = single ? input.offset : 0;
    // `all` merges each source's top 2 × limit; a single type re-ranks every
    // row up to the requested page plus one to learn whether more follow.
    const fetchLimit = single ? offset + input.limit + 1 : input.limit * 2;
    const candidates = await collectCandidates(input, fetchLimit);
    const ranked = rankSearchItems(input.query, dedupeLibraryFirst(candidates));
    const page = ranked.slice(offset, offset + input.limit);
    return {
        items: page.map((item) => ({
            kind: item.kind,
            score: item.score,
            source: item.source,
            [item.payload.field]: item.payload.value,
        })),
        hasMore: ranked.length > offset + input.limit,
    };
}

/**
 * Searches the library, the user's liked streaming items, their visible
 * playlists and the catalogue, and returns one list ordered by
 * {@link rankSearchItems}. A catalogue or remote failure degrades to the
 * remaining sources. Results are cached per user for two minutes.
 */
export async function unifiedSearch(
    input: UnifiedSearchInput,
): Promise<UnifiedSearchPage> {
    const offset = input.type === "all" ? 0 : input.offset;
    const cacheVersion = await getSearchCacheVersion();
    const cacheKey = `search:unified:v${cacheVersion}:${input.userId}:${input.type}:${input.limit}:${offset}:${normalizeCacheQuery(input.query)}`;
    try {
        const cached = await redisClient.get(cacheKey);
        if (cached) return JSON.parse(cached) as UnifiedSearchPage;
    } catch (error) {
        log.warn("Redis read failed", { error });
    }

    const page = await runUnifiedSearch(input);

    try {
        await redisClient.setEx(
            cacheKey,
            CACHE_TTL_SECONDS,
            JSON.stringify(page),
        );
    } catch (error) {
        log.warn("Redis write failed", { error });
    }
    return page;
}
