import {
    DEFAULT_PLAYBACK_PROVIDERS_VALUE,
    DEFAULT_PLAYBACK_SOURCE_ORDER,
    isPlaybackProviderList,
    isPlaybackSourceUsable,
    parsePlaybackProviders,
    parsePlaybackSourceOrder,
    playbackProviderEnableFlags,
    rankPlaybackSource,
} from "../playbackSourcePriority";

describe("playback providers", () => {
    it("defaults to every provider when no setting is stored", () => {
        expect(DEFAULT_PLAYBACK_PROVIDERS_VALUE).toBe(
            "peers,tidal,ytmusic,soulseek,lidarr",
        );
        expect(parsePlaybackProviders(undefined)).toEqual([
            "peers",
            "tidal",
            "ytmusic",
            "soulseek",
            "lidarr",
        ]);
    });

    it("keeps the stored order and drops unknown and repeated entries", () => {
        expect(
            parsePlaybackProviders(" lidarr,bogus,tidal,lidarr,peers "),
        ).toEqual(["lidarr", "tidal", "peers"]);
    });

    it("treats an empty stored list as no active providers", () => {
        expect(parsePlaybackProviders("")).toEqual([]);
    });

    it.each([
        ["", true],
        ["tidal", true],
        ["lidarr,soulseek,ytmusic,tidal,peers", true],
        ["library", false],
        ["tidal,tidal", false],
        ["tidal,bogus", false],
    ])("validates %p as %p", (value, expected) => {
        expect(isPlaybackProviderList(value)).toBe(expected);
    });

    it("derives the enable flags from membership", () => {
        expect(playbackProviderEnableFlags("soulseek,tidal")).toEqual({
            lidarrEnabled: false,
            tidalEnabled: true,
            ytMusicEnabled: false,
        });
        expect(playbackProviderEnableFlags("lidarr,ytmusic")).toEqual({
            lidarrEnabled: true,
            tidalEnabled: false,
            ytMusicEnabled: true,
        });
    });
});

describe("playback source order", () => {
    it.each([
        ["library", true, 500],
        ["peers", true, 400],
        ["tidal", true, 300],
        ["ytmusic", true, 200],
        ["peers", false, 100],
    ] as const)("ranks %s availability=%s", (source, available, expected) => {
        expect(
            rankPlaybackSource(
                { source, available },
                DEFAULT_PLAYBACK_SOURCE_ORDER,
            ),
        ).toBe(expected);
    });

    it("puts the library first, then the streaming providers in list order", () => {
        expect(
            parsePlaybackSourceOrder("soulseek,ytmusic,lidarr,tidal,peers"),
        ).toEqual(["library", "ytmusic", "tidal", "peers"]);
    });

    it("ranks a configured streaming provider ahead of a later one", () => {
        const order = parsePlaybackSourceOrder("ytmusic,tidal");

        expect(
            rankPlaybackSource({ source: "ytmusic", available: true }, order),
        ).toBeGreaterThan(
            rankPlaybackSource({ source: "tidal", available: true }, order),
        );
        expect(
            rankPlaybackSource({ source: "library", available: true }, order),
        ).toBeGreaterThan(
            rankPlaybackSource({ source: "ytmusic", available: true }, order),
        );
    });

    it("ranks a provider missing from the list like an unavailable one", () => {
        const order = parsePlaybackSourceOrder("tidal");

        expect(
            rankPlaybackSource({ source: "ytmusic", available: true }, order),
        ).toBe(100);
        expect(
            rankPlaybackSource({ source: "peers", available: true }, order),
        ).toBe(100);
        expect(
            isPlaybackSourceUsable({ source: "peers", available: true }, order),
        ).toBe(false);
        expect(
            isPlaybackSourceUsable({ source: "tidal", available: true }, order),
        ).toBe(true);
        expect(
            isPlaybackSourceUsable(
                { source: "tidal", available: false },
                order,
            ),
        ).toBe(false);
    });

    it("keeps only the library for an empty provider list", () => {
        expect(parsePlaybackSourceOrder("")).toEqual(["library"]);
    });
});
