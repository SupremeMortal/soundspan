import {
    DEFAULT_ALBUM_COVER_PROVIDERS_VALUE,
    DEFAULT_ARTIST_IMAGE_PROVIDERS_VALUE,
    fanartEnabledFor,
    isAlbumCoverProviderList,
    isArtistImageProviderList,
    metadataProviderFields,
    parseAlbumCoverProviders,
    parseArtistImageProviders,
} from "../metadataProviderSettings";

describe("metadata provider settings", () => {
    it("defaults to every provider in the canonical order", () => {
        expect(DEFAULT_ARTIST_IMAGE_PROVIDERS_VALUE).toBe(
            "wikidata,fanart,deezer,lastfm",
        );
        expect(DEFAULT_ALBUM_COVER_PROVIDERS_VALUE).toBe(
            "coverartarchive,deezer,fanart",
        );
        expect(parseArtistImageProviders(undefined)).toEqual([
            "wikidata",
            "fanart",
            "deezer",
            "lastfm",
        ]);
        expect(parseAlbumCoverProviders(null)).toEqual([
            "coverartarchive",
            "deezer",
            "fanart",
        ]);
    });

    it("keeps the stored order and drops unknown and repeated entries", () => {
        expect(parseArtistImageProviders("lastfm,bogus,deezer,lastfm")).toEqual(
            ["lastfm", "deezer"],
        );
        expect(
            parseAlbumCoverProviders("fanart, coverartarchive,lastfm"),
        ).toEqual(["fanart", "coverartarchive"]);
    });

    it("treats an empty stored list as no active providers", () => {
        expect(parseArtistImageProviders("")).toEqual([]);
        expect(parseAlbumCoverProviders("")).toEqual([]);
    });

    it.each([
        ["", true],
        ["lastfm,wikidata", true],
        ["lastfm,lastfm", false],
        ["coverartarchive", false],
    ])("validates artist image list %p as %p", (value, expected) => {
        expect(isArtistImageProviderList(value)).toBe(expected);
    });

    it.each([
        ["", true],
        ["fanart,deezer,coverartarchive", true],
        ["deezer,deezer", false],
        ["wikidata", false],
    ])("validates album cover list %p as %p", (value, expected) => {
        expect(isAlbumCoverProviderList(value)).toBe(expected);
    });

    it("enables Fanart.tv when either list includes it", () => {
        expect(fanartEnabledFor("wikidata", "deezer,fanart")).toBe(true);
        expect(fanartEnabledFor("fanart", "")).toBe(true);
        expect(fanartEnabledFor("wikidata,lastfm", "coverartarchive")).toBe(
            false,
        );
    });

    it("validates the API fields", () => {
        expect(
            metadataProviderFields.artistImageProviders.safeParse("deezer")
                .success,
        ).toBe(true);
        expect(
            metadataProviderFields.albumCoverProviders.safeParse("lastfm")
                .success,
        ).toBe(false);
    });
});
