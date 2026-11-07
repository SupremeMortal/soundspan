const mockTrackFindUnique = jest.fn();
const mockTrackMappingFindMany = jest.fn();
const mockSystemSettingsFindUnique = jest.fn();

jest.mock("../../utils/db", () => ({
    prisma: {
        track: { findUnique: mockTrackFindUnique },
        trackMapping: { findMany: mockTrackMappingFindMany },
        systemSettings: { findUnique: mockSystemSettingsFindUnique },
    },
}));

const mockGetSystemSettings = jest.fn();
jest.mock("../../utils/systemSettings", () => ({
    getSystemSettings: () => mockGetSystemSettings(),
}));

import {
    choosePeerPlaybackFallback,
    isPeerPlaybackActive,
    loadPeerPlaybackFallback,
} from "../peerPlaybackFallback";

describe("isPeerPlaybackActive", () => {
    it.each([
        ["peers,tidal", true],
        ["tidal,soulseek", false],
        ["", false],
    ])("reads %p as %p", async (playbackProviders, expected) => {
        mockGetSystemSettings.mockResolvedValueOnce({ playbackProviders });
        await expect(isPeerPlaybackActive()).resolves.toBe(expected);
    });

    it("treats a missing settings row as the default list", async () => {
        mockGetSystemSettings.mockResolvedValueOnce(null);
        await expect(isPeerPlaybackActive()).resolves.toBe(true);
    });
});

describe("peer playback fallback ladder", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockTrackFindUnique.mockResolvedValue({
            dedupOfTrackId: null,
            duration: 180,
        });
        mockSystemSettingsFindUnique.mockResolvedValue({
            playbackProviders: "peers,tidal,ytmusic",
        });
    });

    it("selects the local dedup twin before provider mappings", () => {
        expect(
            choosePeerPlaybackFallback({
                localTwinId: "local-1",
                tidalTrackId: 42,
                youtubeVideoId: "video-1",
            }),
        ).toEqual([
            { source: "library", trackId: "local-1" },
            { source: "tidal", tidalTrackId: 42 },
            { source: "ytmusic", youtubeVideoId: "video-1" },
        ]);
    });

    it("selects an existing TIDAL mapping without a local twin", () => {
        expect(
            choosePeerPlaybackFallback({
                localTwinId: null,
                tidalTrackId: 42,
                youtubeVideoId: "video-1",
            }),
        ).toEqual([
            { source: "tidal", tidalTrackId: 42 },
            { source: "ytmusic", youtubeVideoId: "video-1" },
        ]);
    });

    it("honors the configured order for provider rungs", () => {
        expect(
            choosePeerPlaybackFallback(
                {
                    localTwinId: null,
                    tidalTrackId: 42,
                    youtubeVideoId: "video-1",
                },
                "peers,ytmusic,tidal",
            ),
        ).toEqual([
            { source: "ytmusic", youtubeVideoId: "video-1" },
            { source: "tidal", tidalTrackId: 42 },
        ]);
    });

    it("leaves out providers that are not in the provider list", () => {
        expect(
            choosePeerPlaybackFallback(
                {
                    localTwinId: "local-1",
                    tidalTrackId: 42,
                    youtubeVideoId: "video-1",
                },
                "peers,ytmusic,soulseek",
            ),
        ).toEqual([
            { source: "library", trackId: "local-1" },
            { source: "ytmusic", youtubeVideoId: "video-1" },
        ]);
    });

    it("returns an empty ladder when no fallback exists", () => {
        expect(
            choosePeerPlaybackFallback({
                localTwinId: null,
                tidalTrackId: null,
                youtubeVideoId: null,
            }),
        ).toEqual([]);
    });

    it.each([
        ["low-confidence", 0.69, 180],
        ["duration-mismatch", 0.9, 196],
    ])("skips a %s provider mapping", async (_name, confidence, duration) => {
        mockTrackMappingFindMany.mockResolvedValueOnce([
            {
                confidence,
                trackTidal: { tidalId: 42, duration },
                trackYtMusic: null,
            },
        ]);

        await expect(loadPeerPlaybackFallback("peer-track")).resolves.toEqual(
            [],
        );
    });

    it("selects an eligible provider mapping", async () => {
        mockTrackMappingFindMany.mockResolvedValueOnce([
            {
                confidence: 0.7,
                trackTidal: { tidalId: 42, duration: 195 },
                trackYtMusic: null,
            },
        ]);

        await expect(loadPeerPlaybackFallback("peer-track")).resolves.toEqual([
            { source: "tidal", tidalTrackId: 42 },
        ]);
    });
});
