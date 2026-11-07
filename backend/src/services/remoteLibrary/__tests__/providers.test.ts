jest.mock("../../../utils/db", () => ({
    prisma: { userSettings: { findUnique: jest.fn() } },
}));

jest.mock("../../../utils/systemSettings", () => ({
    getSystemSettings: jest.fn(),
}));

import { prisma } from "../../../utils/db";
import { getSystemSettings } from "../../../utils/systemSettings";
import { loadRemoteLibraryAccess } from "../providers";

const mockFindUserSettings = prisma.userSettings.findUnique as jest.Mock;
const mockGetSystemSettings = getSystemSettings as jest.Mock;

describe("remote library provider access", () => {
    beforeEach(() => {
        jest.clearAllMocks();
        mockFindUserSettings.mockResolvedValue({
            tidalOAuthJson: "tidal-token",
            ytMusicOAuthJson: null,
        });
        mockGetSystemSettings.mockResolvedValue({
            tidalEnabled: true,
            ytMusicEnabled: true,
            playbackProviders: "peers,tidal,ytmusic",
        });
    });

    it("performs no reads without an authenticated user", async () => {
        await expect(loadRemoteLibraryAccess(undefined)).resolves.toEqual({
            providers: { tidal: false, youtube: false },
            playbackSourceOrder: ["library", "peers", "tidal", "ytmusic"],
        });
        expect(mockFindUserSettings).not.toHaveBeenCalled();
        expect(mockGetSystemSettings).not.toHaveBeenCalled();
    });

    it("requires the system flag and a stored token for TIDAL", async () => {
        mockFindUserSettings.mockResolvedValueOnce({
            tidalOAuthJson: "   ",
            ytMusicOAuthJson: "ignored-for-public-playback",
        });

        const access = await loadRemoteLibraryAccess("user-1");

        expect(access.providers).toEqual({
            tidal: false,
            youtube: true,
        });
    });

    it("grants TIDAL to users without a link when the instance account is shared", async () => {
        mockFindUserSettings.mockResolvedValueOnce({
            tidalOAuthJson: null,
            ytMusicOAuthJson: null,
        });
        mockGetSystemSettings.mockResolvedValueOnce({
            tidalEnabled: true,
            tidalStreamingUseInstanceAccount: true,
            ytMusicEnabled: true,
            playbackProviders: "peers,tidal,ytmusic",
        });

        const access = await loadRemoteLibraryAccess("user-1");

        expect(access.providers.tidal).toBe(true);
    });

    it("keeps the shared instance account off while TIDAL is disabled", async () => {
        mockFindUserSettings.mockResolvedValueOnce({
            tidalOAuthJson: null,
            ytMusicOAuthJson: null,
        });
        mockGetSystemSettings.mockResolvedValueOnce({
            tidalEnabled: false,
            tidalStreamingUseInstanceAccount: true,
            ytMusicEnabled: true,
            playbackProviders: "peers,tidal,ytmusic",
        });

        const access = await loadRemoteLibraryAccess("user-1");

        expect(access.providers.tidal).toBe(false);
    });

    it("allows enabled YouTube Music through its public playback path", async () => {
        mockFindUserSettings.mockResolvedValueOnce({
            tidalOAuthJson: null,
            ytMusicOAuthJson: null,
        });

        const access = await loadRemoteLibraryAccess("user-1");

        expect(access.providers).toEqual({
            tidal: false,
            youtube: true,
        });
    });

    it("disables providers whose system flags are off", async () => {
        mockGetSystemSettings.mockResolvedValueOnce({
            tidalEnabled: false,
            ytMusicEnabled: false,
            playbackProviders: "peers,tidal,ytmusic",
        });

        const access = await loadRemoteLibraryAccess("user-1");

        expect(access.providers).toEqual({
            tidal: false,
            youtube: false,
        });
    });

    it("loads user and system settings once and derives the playback order from the provider list", async () => {
        mockGetSystemSettings.mockResolvedValueOnce({
            tidalEnabled: true,
            ytMusicEnabled: true,
            playbackProviders: "ytmusic,lidarr,tidal,peers",
        });

        const access = await loadRemoteLibraryAccess("user-1");

        expect(access.providers).toEqual({ tidal: true, youtube: true });
        expect(access.playbackSourceOrder).toEqual([
            "library",
            "ytmusic",
            "tidal",
            "peers",
        ]);
        expect(mockFindUserSettings).toHaveBeenCalledTimes(1);
        expect(mockGetSystemSettings).toHaveBeenCalledTimes(1);
    });
});
