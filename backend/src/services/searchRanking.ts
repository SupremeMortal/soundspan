/**
 * Comparable relevance scores for the unified search list. Library and
 * catalogue sources rank on different scales (`ts_rank`, trigram
 * `similarity`, provider order); every item is scored as
 * `tier + withinTier * WITHIN_TIER_SPAN + typePrior` so they sort together.
 */

/** The kinds of result the unified search returns. */
export type SearchItemKind =
    | "track"
    | "artist"
    | "album"
    | "playlist"
    | "podcast";

/** Where a unified search result comes from. */
export type SearchItemSource = "library" | "catalogue";

/** How closely an item's primary name matches the query: 4 is best. */
export type MatchTier = 1 | 2 | 3 | 4;

/**
 * The share of a tier the within-tier value may fill, so the best item of a
 * tier never reaches the worst item of the next one.
 */
const WITHIN_TIER_SPAN = 0.99;

/** Breaks ties between equal names: artist > album > track > playlist > podcast. */
const TYPE_PRIOR: Record<SearchItemKind, number> = {
    artist: 0.0004,
    album: 0.0003,
    track: 0.0002,
    playlist: 0.0001,
    podcast: 0,
};

function clampUnit(value: number): number {
    if (!Number.isFinite(value) || value <= 0) return 0;
    return value >= 1 ? 1 : value;
}

/** Folds case and diacritics and turns punctuation runs into single spaces. */
export function foldForMatch(value: string): string {
    return value
        .normalize("NFKD")
        .replace(/\p{M}+/gu, "")
        .toLocaleLowerCase("en")
        .replace(/æ/g, "ae")
        .replace(/œ/g, "oe")
        .replace(/ø/g, "o")
        .replace(/ß/g, "ss")
        .replace(/[^\p{L}\p{N}]+/gu, " ")
        .trim();
}

/**
 * The tier of `name` against `query` after folding: exact = 4, prefix = 3,
 * every query token prefixes a word of the name = 2, anything else = 1 (the
 * item was still a full-text, trigram or catalogue hit).
 */
export function matchTier(name: string, query: string): MatchTier {
    const foldedQuery = foldForMatch(query);
    if (!foldedQuery) return 1;
    const foldedName = foldForMatch(name);
    if (foldedName === foldedQuery) return 4;
    if (foldedName.startsWith(foldedQuery)) return 3;
    const words = foldedName.split(" ");
    const tokens = foldedQuery.split(" ");
    return tokens.every((token) => words.some((word) => word.startsWith(token)))
        ? 2
        : 1;
}

/** A full-text `ts_rank` normalised to 0..1 as `rank / (rank + 1)`. */
export function withinTierFromTsRank(rank: number): number {
    if (!Number.isFinite(rank) || rank <= 0) return 0;
    return rank / (rank + 1);
}

/** A trigram `similarity` clamped to 0..1. */
export function withinTierFromSimilarity(similarity: number): number {
    return clampUnit(similarity);
}

/** A catalogue item's position in provider order, as `1 - index / count`. */
export function withinTierFromProviderOrder(
    index: number,
    count: number,
): number {
    if (count <= 0) return 0;
    return clampUnit(1 - index / count);
}

/** The comparable score of one item. */
export function scoreSearchItem(input: {
    kind: SearchItemKind;
    name: string;
    query: string;
    withinTier: number;
}): number {
    return (
        matchTier(input.name, input.query) +
        clampUnit(input.withinTier) * WITHIN_TIER_SPAN +
        TYPE_PRIOR[input.kind]
    );
}

/** One result before ranking. */
export interface RankCandidate<T> {
    kind: SearchItemKind;
    source: SearchItemSource;
    /** The primary name the tier is computed from. */
    name: string;
    /** 0..1 position within the tier, from the helpers above. */
    withinTier: number;
    /** Identity keys; a catalogue item sharing one with a library item is dropped. */
    keys: readonly string[];
    payload: T;
}

/** A ranked result. */
export type RankedItem<T> = RankCandidate<T> & { score: number };

/**
 * Drops catalogue duplicates: a catalogue item sharing a key with any library
 * item or an earlier catalogue item is dropped. Library items are always
 * kept, as are items without keys. Order is otherwise preserved.
 */
export function dedupeLibraryFirst<C extends RankCandidate<unknown>>(
    candidates: readonly C[],
): C[] {
    const seen = new Set<string>();
    for (const item of candidates) {
        if (item.source === "library")
            item.keys.forEach((key) => seen.add(key));
    }
    return candidates.filter((item) => {
        if (item.source === "library") return true;
        if (item.keys.some((key) => seen.has(key))) return false;
        item.keys.forEach((key) => seen.add(key));
        return true;
    });
}

/** Scores and sorts candidates, best first; ties keep their input order. */
export function rankSearchItems<T>(
    query: string,
    candidates: readonly RankCandidate<T>[],
): RankedItem<T>[] {
    return candidates
        .map((item, index) => ({
            index,
            item: {
                ...item,
                score: scoreSearchItem({
                    kind: item.kind,
                    name: item.name,
                    query,
                    withinTier: item.withinTier,
                }),
            },
        }))
        .sort(
            (left, right) =>
                right.item.score - left.item.score || left.index - right.index,
        )
        .map(({ item }) => item);
}
