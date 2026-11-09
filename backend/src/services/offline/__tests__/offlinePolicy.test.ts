const mockGetSystemSettings = jest.fn();
const mockTrackFindUnique = jest.fn();
const mockTidalEnabled = jest.fn();
const mockTidalAvailable = jest.fn();
const mockTidalAuth = jest.fn();

jest.mock("../../../utils/systemSettings", () => ({
    getSystemSettings: (...args: unknown[]) => mockGetSystemSettings(...args),
}));
jest.mock("../../../utils/db", () => ({
    prisma: {
        track: { findUnique: (...a: unknown[]) => mockTrackFindUnique(...a) },
    },
}));
jest.mock("../../tidalStreaming", () => ({
    tidalStreamingService: {
        isEnabled: () => mockTidalEnabled(),
        isAvailable: () => mockTidalAvailable(),
        getAuthStatus: (...a: unknown[]) => mockTidalAuth(...a),
    },
}));

import { resolveOfflinePolicy } from "../offlinePolicy";
import type { ParsedPlaybackId } from "../../playback/playbackId";

const ALL_ON = {
    offlineAllowLocal: true,
    offlineAllowFederated: true,
    offlineAllowTidal: true,
    offlineAllowYtMusic: true,
    offlineAllowYouTube: true,
    ytMusicEnabled: true,
};

const IDS: Record<string, ParsedPlaybackId> = {
    local: { kind: "t", trackId: "trk1" },
    federated: { kind: "t", trackId: "trk2" },
    tidal: { kind: "td", tidalId: 5 },
    ytm: { kind: "ym", videoId: "abc" },
    yt: { kind: "yt", videoId: "def" },
};

describe("resolveOfflinePolicy", () => {
    beforeEach(() => {
        jest.resetAllMocks();
        mockGetSystemSettings.mockResolvedValue({ ...ALL_ON });
        mockTrackFindUnique.mockImplementation(async ({ where }: any) =>
            where.id === "trk1"
                ? { origin: "LOCAL" }
                : where.id === "trk2"
                  ? { origin: "FEDERATED" }
                  : null,
        );
        mockTidalEnabled.mockResolvedValue(true);
        mockTidalAvailable.mockResolvedValue(true);
        mockTidalAuth.mockResolvedValue({ authenticated: true });
    });

    it("allows every source by default", async () => {
        for (const parsed of Object.values(IDS)) {
            await expect(resolveOfflinePolicy("u1", parsed)).resolves.toEqual({
                downloadable: true,
            });
        }
    });

    it("allows everything when no settings row exists", async () => {
        mockGetSystemSettings.mockResolvedValue(null);
        mockTidalEnabled.mockResolvedValue(true);
        await expect(resolveOfflinePolicy("u1", IDS.local)).resolves.toEqual({
            downloadable: true,
        });
    });

    it.each([
        ["offlineAllowLocal", "local"],
        ["offlineAllowFederated", "federated"],
        ["offlineAllowTidal", "tidal"],
        ["offlineAllowYtMusic", "ytm"],
        ["offlineAllowYouTube", "yt"],
    ])("%s off blocks only %s", async (field, blocked) => {
        mockGetSystemSettings.mockResolvedValue({ ...ALL_ON, [field]: false });
        for (const [name, parsed] of Object.entries(IDS)) {
            const result = await resolveOfflinePolicy("u1", parsed);
            expect(result).toEqual(
                name === blocked
                    ? {
                          downloadable: false,
                          reason: "SOURCE_DOWNLOADS_DISABLED",
                      }
                    : { downloadable: true },
            );
        }
    });

    it("reports a missing library track as TRACK_UNAVAILABLE", async () => {
        await expect(
            resolveOfflinePolicy("u1", { kind: "t", trackId: "nope" }),
        ).resolves.toEqual({
            downloadable: false,
            reason: "TRACK_UNAVAILABLE",
        });
    });

    it("reports TIDAL as SOURCE_UNAVAILABLE when the user cannot stream it", async () => {
        mockTidalAuth.mockResolvedValue({ authenticated: false });
        await expect(resolveOfflinePolicy("u1", IDS.tidal)).resolves.toEqual({
            downloadable: false,
            reason: "SOURCE_UNAVAILABLE",
        });
    });

    it("reports YouTube Music as SOURCE_UNAVAILABLE when the integration is disabled", async () => {
        mockGetSystemSettings.mockResolvedValue({
            ...ALL_ON,
            ytMusicEnabled: false,
        });
        await expect(resolveOfflinePolicy("u1", IDS.ytm)).resolves.toEqual({
            downloadable: false,
            reason: "SOURCE_UNAVAILABLE",
        });
    });
});
