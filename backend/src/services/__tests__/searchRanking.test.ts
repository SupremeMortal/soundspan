import {
    dedupeLibraryFirst,
    foldForMatch,
    matchTier,
    rankSearchItems,
    scoreSearchItem,
    withinTierFromProviderOrder,
    withinTierFromSimilarity,
    withinTierFromTsRank,
    type RankCandidate,
} from "../searchRanking";

function candidate(
    overrides: Partial<RankCandidate<string>> &
        Pick<RankCandidate<string>, "kind" | "name">,
): RankCandidate<string> {
    return {
        source: "library",
        withinTier: 0,
        keys: [],
        payload: overrides.name,
        ...overrides,
    };
}

describe("foldForMatch", () => {
    it("folds case and diacritics and collapses punctuation", () => {
        expect(foldForMatch("  Björk ")).toBe("bjork");
        expect(foldForMatch("AC/DC")).toBe("ac dc");
        expect(foldForMatch("Sigur Rós — Ágætis byrjun")).toBe(
            "sigur ros agaetis byrjun",
        );
    });
});

describe("matchTier", () => {
    it("treats a folded equal name as exact", () => {
        expect(matchTier("Björk", "Bjork")).toBe(4);
        expect(matchTier("bjork", "BJÖRK")).toBe(4);
    });

    it("ranks a prefix, then word prefixes, then any other hit", () => {
        expect(matchTier("Radiohead", "radio")).toBe(3);
        expect(matchTier("The Dark Side of the Moon", "dark moo")).toBe(2);
        expect(matchTier("Paranoid Android", "radiohead")).toBe(1);
        expect(matchTier("Anything", "   ")).toBe(1);
    });
});

describe("within-tier values", () => {
    it("normalises ts_rank as rank / (rank + 1)", () => {
        expect(withinTierFromTsRank(1)).toBeCloseTo(0.5);
        expect(withinTierFromTsRank(0)).toBe(0);
        expect(withinTierFromTsRank(-3)).toBe(0);
        expect(withinTierFromTsRank(Number.NaN)).toBe(0);
    });

    it("clamps trigram similarity to 0..1", () => {
        expect(withinTierFromSimilarity(0.42)).toBeCloseTo(0.42);
        expect(withinTierFromSimilarity(3)).toBe(1);
        expect(withinTierFromSimilarity(-1)).toBe(0);
    });

    it("scores catalogue items by provider order", () => {
        expect(withinTierFromProviderOrder(0, 4)).toBe(1);
        expect(withinTierFromProviderOrder(2, 4)).toBe(0.5);
        expect(withinTierFromProviderOrder(0, 0)).toBe(0);
    });
});

describe("scoreSearchItem", () => {
    it("ranks an exact artist match above a prefix track match", () => {
        const artist = scoreSearchItem({
            kind: "artist",
            name: "Radiohead",
            query: "radiohead",
            withinTier: 0,
        });
        const track = scoreSearchItem({
            kind: "track",
            name: "Radiohead Medley",
            query: "radiohead",
            withinTier: 1,
        });
        expect(artist).toBeGreaterThan(track);
    });

    it("never lets the within-tier value reach the next tier", () => {
        const tierOneBest = scoreSearchItem({
            kind: "artist",
            name: "Something else",
            query: "radio",
            withinTier: 1,
        });
        const tierTwoWorst = scoreSearchItem({
            kind: "podcast",
            name: "Radio Days",
            query: "days radio",
            withinTier: 0,
        });
        expect(tierTwoWorst).toBeGreaterThan(tierOneBest);
    });

    it("breaks exact ties by kind: artist, album, track, playlist, podcast", () => {
        const kinds = [
            "podcast",
            "track",
            "artist",
            "playlist",
            "album",
        ] as const;
        const ordered = [...kinds].sort(
            (left, right) =>
                scoreSearchItem({
                    kind: right,
                    name: "Low",
                    query: "low",
                    withinTier: 0.3,
                }) -
                scoreSearchItem({
                    kind: left,
                    name: "Low",
                    query: "low",
                    withinTier: 0.3,
                }),
        );
        expect(ordered).toEqual([
            "artist",
            "album",
            "track",
            "playlist",
            "podcast",
        ]);
    });
});

describe("rankSearchItems", () => {
    it("orders by score and lets the higher ts_rank win within a tier", () => {
        const ranked = rankSearchItems("creep", [
            candidate({ kind: "track", name: "Creep (Live)", withinTier: 0.1 }),
            candidate({
                kind: "track",
                name: "Creep (Acoustic)",
                withinTier: 0.4,
            }),
            candidate({ kind: "track", name: "Creep", withinTier: 0 }),
        ]);
        expect(ranked.map((item) => item.payload)).toEqual([
            "Creep",
            "Creep (Acoustic)",
            "Creep (Live)",
        ]);
        expect(ranked[0].score).toBeGreaterThan(ranked[1].score);
    });
});

describe("dedupeLibraryFirst", () => {
    it("drops a catalogue duplicate of a library item even when it comes first", () => {
        const kept = dedupeLibraryFirst([
            candidate({
                kind: "artist",
                name: "Björk",
                source: "catalogue",
                keys: ["artist:bjork"],
            }),
            candidate({
                kind: "artist",
                name: "Bjork",
                keys: ["artist:bjork"],
            }),
            candidate({
                kind: "artist",
                name: "Sugarcubes",
                source: "catalogue",
                keys: ["artist:sugarcubes"],
            }),
        ]);
        expect(kept.map((item) => `${item.source}:${item.name}`)).toEqual([
            "library:Bjork",
            "catalogue:Sugarcubes",
        ]);
    });

    it("never drops a library item for another library item", () => {
        const kept = dedupeLibraryFirst([
            candidate({
                kind: "track",
                name: "Creep",
                keys: ["track:creep|radiohead"],
            }),
            candidate({
                kind: "track",
                name: "Creep",
                keys: ["track:creep|radiohead"],
            }),
        ]);
        expect(kept).toHaveLength(2);
    });

    it("keeps the first of two catalogue duplicates and every keyless item", () => {
        const kept = dedupeLibraryFirst([
            candidate({
                kind: "track",
                name: "A",
                source: "catalogue",
                keys: ["td.1"],
            }),
            candidate({
                kind: "track",
                name: "B",
                source: "catalogue",
                keys: ["td.1"],
            }),
            candidate({ kind: "track", name: "C", source: "catalogue" }),
            candidate({ kind: "track", name: "D", source: "catalogue" }),
        ]);
        expect(kept.map((item) => item.name)).toEqual(["A", "C", "D"]);
    });
});
