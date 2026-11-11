const mockGetSystemSettings = jest.fn();
const mockTrackFindUnique = jest.fn();

jest.mock("../../../utils/systemSettings", () => ({
    getSystemSettings: (...args: unknown[]) => mockGetSystemSettings(...args),
}));
jest.mock("../../../utils/db", () => ({
    prisma: {
        track: { findUnique: (...a: unknown[]) => mockTrackFindUnique(...a) },
    },
}));

import { resolveOfflinePolicy } from "../offlinePolicy";
import type { ParsedPlaybackId } from "../../playback/playbackId";

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
        mockGetSystemSettings.mockResolvedValue({
            offlineDownloadsEnabled: true,
        });
        mockTrackFindUnique.mockImplementation(async ({ where }: any) =>
            where.id === "trk1"
                ? { id: "trk1" }
                : where.id === "trk2"
                  ? { id: "trk2" }
                  : null,
        );
    });

    it("allows every source while offline downloads are enabled", async () => {
        for (const parsed of Object.values(IDS)) {
            await expect(resolveOfflinePolicy("u1", parsed)).resolves.toEqual({
                downloadable: true,
            });
        }
    });

    it("allows everything when no settings row exists", async () => {
        mockGetSystemSettings.mockResolvedValue(null);
        for (const parsed of Object.values(IDS)) {
            await expect(resolveOfflinePolicy("u1", parsed)).resolves.toEqual({
                downloadable: true,
            });
        }
    });

    it("blocks every source when offline downloads are disabled", async () => {
        mockGetSystemSettings.mockResolvedValue({
            offlineDownloadsEnabled: false,
        });
        for (const parsed of Object.values(IDS)) {
            await expect(resolveOfflinePolicy("u1", parsed)).resolves.toEqual({
                downloadable: false,
                reason: "SOURCE_DOWNLOADS_DISABLED",
            });
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
});
