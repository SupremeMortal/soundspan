const mockLog = {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
};

jest.mock("../../utils/logger", () => ({
    logger: {
        child: jest.fn(() => mockLog),
    },
}));

const mockFindUnique = jest.fn();
const mockUpdate = jest.fn();
jest.mock("../../utils/db", () => ({
    prisma: {
        downloadJob: {
            findUnique: (...args: unknown[]) => mockFindUnique(...args),
            update: (...args: unknown[]) => mockUpdate(...args),
        },
    },
}));

const mockGetSystemSettings = jest.fn();
jest.mock("../../utils/systemSettings", () => ({
    getSystemSettings: (...args: unknown[]) => mockGetSystemSettings(...args),
}));

const mockLidarrAvailable = jest.fn();
jest.mock("../lidarr", () => ({
    lidarrService: {
        isEnabled: (...args: unknown[]) => mockLidarrAvailable(...args),
    },
}));

const mockSoulseekAvailable = jest.fn();
jest.mock("../soulseek", () => ({
    soulseekService: {
        isAvailable: (...args: unknown[]) => mockSoulseekAvailable(...args),
    },
}));

const mockTidalAvailable = jest.fn();
jest.mock("../tidal", () => ({
    tidalService: {
        isAvailable: (...args: unknown[]) => mockTidalAvailable(...args),
    },
}));

const mockYoutubeAvailable = jest.fn();
jest.mock("../youtubeDownload", () => ({
    youtubeDownloadService: {
        isAvailable: (...args: unknown[]) => mockYoutubeAvailable(...args),
    },
}));

const mockProcessTidalDownload = jest.fn();
jest.mock("../tidalLibraryDownload", () => ({
    processTidalDownload: (...args: unknown[]) =>
        mockProcessTidalDownload(...args),
}));

const mockProcessYoutubeDownload = jest.fn();
jest.mock("../youtubeLibraryDownload", () => ({
    processYoutubeDownload: (...args: unknown[]) =>
        mockProcessYoutubeDownload(...args),
}));

const mockProcessSoulseekDownload = jest.fn();
jest.mock("../soulseekLibraryDownload", () => ({
    processSoulseekDownload: (...args: unknown[]) =>
        mockProcessSoulseekDownload(...args),
}));

const mockStartDownload = jest.fn();
jest.mock("../simpleDownloadManager", () => ({
    simpleDownloadManager: {
        startDownload: (...args: unknown[]) => mockStartDownload(...args),
    },
}));

import {
    dispatchAlbumDownload,
    dispatchResolvedAlbumDownload,
    resolveAlbumDownloadRouting,
} from "../downloadDispatcher";

const baseParams = {
    jobId: "job-1",
    type: "album",
    mbid: "rg-1",
    subject: "Artist - Album",
    artistName: "Artist",
    albumTitle: "Album",
};

describe("dispatchAlbumDownload", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockFindUnique.mockResolvedValue({
            id: "job-1",
            userId: "user-1",
            metadata: { preserved: true },
        });
        mockUpdate.mockResolvedValue({});
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "soulseek",
        });
        mockTidalAvailable.mockResolvedValue(false);
        mockLidarrAvailable.mockResolvedValue(true);
        mockSoulseekAvailable.mockResolvedValue(true);
        mockYoutubeAvailable.mockResolvedValue(false);
        mockProcessTidalDownload.mockResolvedValue(undefined);
        mockProcessYoutubeDownload.mockResolvedValue(undefined);
        mockProcessSoulseekDownload.mockResolvedValue(undefined);
        mockStartDownload.mockResolvedValue({ success: true });
    });

    it("dispatches an available configured YouTube source", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "ytmusic",
        });
        mockYoutubeAvailable.mockResolvedValue(true);

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessYoutubeDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "user-1",
        );
        expect(mockStartDownload).not.toHaveBeenCalled();
    });

    it("dispatches an available configured TIDAL source", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal",
        });
        mockTidalAvailable.mockResolvedValue(true);

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessTidalDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "user-1",
        );
        expect(mockTidalAvailable).toHaveBeenCalledTimes(1);
        expect(mockLidarrAvailable).toHaveBeenCalledTimes(1);
        expect(mockSoulseekAvailable).toHaveBeenCalledTimes(1);
        expect(mockYoutubeAvailable).toHaveBeenCalledTimes(1);
        expect(mockStartDownload).not.toHaveBeenCalled();
    });

    it("dispatches a resolved routing snapshot without probing sources twice", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal",
        });
        mockTidalAvailable.mockResolvedValue(true);
        const routing = await resolveAlbumDownloadRouting(baseParams);

        await dispatchResolvedAlbumDownload(routing, baseParams);

        expect(mockGetSystemSettings).toHaveBeenCalledTimes(1);
        expect(mockTidalAvailable).toHaveBeenCalledTimes(1);
        expect(mockLidarrAvailable).toHaveBeenCalledTimes(1);
        expect(mockSoulseekAvailable).toHaveBeenCalledTimes(1);
        expect(mockYoutubeAvailable).toHaveBeenCalledTimes(1);
        expect(mockProcessTidalDownload).toHaveBeenCalledTimes(1);
    });

    it("passes the resolved runtime fallback snapshot to TIDAL", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal,soulseek",
        });
        mockTidalAvailable.mockResolvedValue(true);
        const routing = await resolveAlbumDownloadRouting(baseParams);
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal,lidarr",
        });

        await dispatchResolvedAlbumDownload(routing, baseParams);

        expect(mockGetSystemSettings).toHaveBeenCalledTimes(1);
        expect(mockProcessTidalDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "user-1",
            { fallbackSource: "soulseek" },
        );
        expect(mockStartDownload).not.toHaveBeenCalled();
    });

    it("dispatches YouTube when it is the first available listed source", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal,ytmusic",
        });
        mockYoutubeAvailable.mockResolvedValue(true);

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessYoutubeDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "user-1",
        );
    });

    it("falls back from unavailable YouTube to Soulseek", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "ytmusic,soulseek",
        });

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessSoulseekDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "user-1",
        );
        expect(mockProcessYoutubeDownload).not.toHaveBeenCalled();
        expect(mockStartDownload).not.toHaveBeenCalled();
    });

    it("dispatches an available configured Soulseek source", async () => {
        await dispatchAlbumDownload({
            ...baseParams,
            artistName: undefined,
            albumTitle: undefined,
            subject: "Split Artist - Split - Album",
        });

        expect(mockProcessSoulseekDownload).toHaveBeenCalledWith(
            "job-1",
            "Split Artist",
            "Split - Album",
            "user-1",
        );
        expect(mockStartDownload).not.toHaveBeenCalled();
    });

    it("hands off at runtime to the next available source in the chain", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "peers,tidal,ytmusic,lidarr",
        });
        mockTidalAvailable.mockResolvedValue(true);

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessTidalDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "user-1",
            { fallbackSource: "lidarr" },
        );
    });

    it("never dispatches an available source that is not listed", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "soulseek",
        });
        mockSoulseekAvailable.mockResolvedValue(false);

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessSoulseekDownload).not.toHaveBeenCalled();
        expect(mockStartDownload).not.toHaveBeenCalled();
        expect(mockUpdate).toHaveBeenCalledWith(
            expect.objectContaining({
                data: expect.objectContaining({
                    status: "failed",
                    error: "No enabled download source is available (tried soulseek)",
                }),
            }),
        );
    });

    it("passes a supplied artist MBID to the Lidarr manager", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "lidarr",
        });

        await dispatchAlbumDownload({
            ...baseParams,
            artistMbid: "artist-mbid-1",
        });

        expect(mockStartDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "rg-1",
            "user-1",
            false,
            "artist-mbid-1",
        );
    });

    it("uses the subject for both names when no delimiter or metadata exists", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "lidarr",
        });

        await dispatchAlbumDownload({
            ...baseParams,
            artistName: undefined,
            albumTitle: undefined,
            subject: "SingleSubject",
        });

        expect(mockStartDownload).toHaveBeenCalledWith(
            "job-1",
            "SingleSubject",
            "SingleSubject",
            "rg-1",
            "user-1",
        );
    });

    it("logs unsuccessful manager starts without throwing", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "lidarr",
        });

        mockStartDownload.mockResolvedValueOnce({
            success: false,
            error: "unavailable indexer",
        });

        await dispatchAlbumDownload(baseParams);

        expect(mockLog.error).toHaveBeenCalledWith(
            "Failed to start download: unavailable indexer",
        );
    });

    it("fails without dispatch when the only listed source is unavailable", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal",
        });

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessTidalDownload).not.toHaveBeenCalled();
        expect(mockStartDownload).not.toHaveBeenCalled();
        expect(mockUpdate).toHaveBeenCalledWith({
            where: { id: "job-1" },
            data: {
                status: "failed",
                error: "No enabled download source is available (tried tidal)",
                completedAt: expect.any(Date),
                metadata: {
                    preserved: true,
                    currentSource: "tidal",
                    statusText: "Download sources unavailable — skipped",
                    failedAt: expect.any(String),
                },
            },
        });
    });

    it("dispatches the next listed source when the first is unavailable", async () => {
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal,lidarr",
        });

        await dispatchAlbumDownload(baseParams);

        expect(mockStartDownload).toHaveBeenCalledWith(
            "job-1",
            "Artist",
            "Album",
            "rg-1",
            "user-1",
        );
    });

    it("fails when every listed source is unavailable", async () => {
        mockFindUnique.mockResolvedValueOnce({
            id: "job-1",
            userId: "user-1",
            metadata: "scalar metadata",
        });
        mockGetSystemSettings.mockResolvedValue({
            playbackProviders: "tidal,lidarr",
        });
        mockLidarrAvailable.mockResolvedValue(false);

        await dispatchAlbumDownload(baseParams);

        expect(mockStartDownload).not.toHaveBeenCalled();
        expect(mockUpdate).toHaveBeenCalledWith({
            where: { id: "job-1" },
            data: {
                status: "failed",
                error: "No enabled download source is available (tried tidal, lidarr)",
                completedAt: expect.any(Date),
                metadata: {
                    currentSource: "tidal",
                    statusText: "Download sources unavailable — skipped",
                    failedAt: expect.any(String),
                },
            },
        });
    });

    it("fails clearly when no download provider is listed", async () => {
        mockGetSystemSettings.mockResolvedValue({ playbackProviders: "peers" });

        await dispatchAlbumDownload(baseParams);

        expect(mockProcessSoulseekDownload).not.toHaveBeenCalled();
        expect(mockStartDownload).not.toHaveBeenCalled();
        expect(mockUpdate).toHaveBeenCalledWith({
            where: { id: "job-1" },
            data: {
                status: "failed",
                error: "No download source is enabled in the playback provider list",
                completedAt: expect.any(Date),
                metadata: {
                    preserved: true,
                    currentSource: null,
                    statusText: "No download source enabled — skipped",
                    failedAt: expect.any(String),
                },
            },
        });
    });

    it("returns without probing sources when the job no longer exists", async () => {
        mockFindUnique.mockResolvedValueOnce(null);

        await dispatchAlbumDownload(baseParams);

        expect(mockGetSystemSettings).not.toHaveBeenCalled();
        expect(mockLog.error).toHaveBeenCalledWith("Job job-1 not found");
    });

    it("leaves non-album jobs undispatched", async () => {
        await dispatchAlbumDownload({ ...baseParams, type: "artist" });

        expect(mockGetSystemSettings).not.toHaveBeenCalled();
        expect(mockStartDownload).not.toHaveBeenCalled();
    });
});
