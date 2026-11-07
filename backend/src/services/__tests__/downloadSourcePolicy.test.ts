const isLidarrEnabled = jest.fn();
const isSoulseekAvailable = jest.fn();
const isTidalAvailable = jest.fn();
const isYoutubeAvailable = jest.fn();

jest.mock("../lidarr", () => ({
    lidarrService: { isEnabled: isLidarrEnabled },
}));
jest.mock("../soulseek", () => ({
    soulseekService: { isAvailable: isSoulseekAvailable },
}));
jest.mock("../tidal", () => ({
    tidalService: { isAvailable: isTidalAvailable },
}));
jest.mock("../youtubeDownload", () => ({
    youtubeDownloadService: { isAvailable: isYoutubeAvailable },
}));

import {
    downloadSourceChain,
    probeDownloadSourceAvailability,
    resolveDownloadSource,
    resolveRuntimeFallback,
} from "../downloadSourcePolicy";

const availability = {
    tidal: true,
    lidarr: true,
    soulseek: true,
    youtube: true,
};

describe("probeDownloadSourceAvailability", () => {
    it("fans out all source probes and returns the named availability snapshot", async () => {
        isLidarrEnabled.mockResolvedValueOnce(true);
        isSoulseekAvailable.mockResolvedValueOnce(false);
        isTidalAvailable.mockResolvedValueOnce(true);
        isYoutubeAvailable.mockResolvedValueOnce(false);

        await expect(probeDownloadSourceAvailability()).resolves.toEqual({
            tidal: true,
            lidarr: true,
            soulseek: false,
            youtube: false,
        });
        expect(isLidarrEnabled).toHaveBeenCalledTimes(1);
        expect(isSoulseekAvailable).toHaveBeenCalledTimes(1);
        expect(isTidalAvailable).toHaveBeenCalledTimes(1);
        expect(isYoutubeAvailable).toHaveBeenCalledTimes(1);
    });
});

describe("downloadSourceChain", () => {
    it("keeps the download providers of the list in order", () => {
        expect(
            downloadSourceChain("peers,lidarr,ytmusic,soulseek,tidal"),
        ).toEqual(["lidarr", "youtube", "soulseek", "tidal"]);
    });

    it("is empty when no download provider is in the list", () => {
        expect(downloadSourceChain("peers")).toEqual([]);
        expect(downloadSourceChain("")).toEqual([]);
    });
});

describe("resolveDownloadSource", () => {
    it.each(["tidal", "lidarr", "soulseek", "youtube"] as const)(
        "dispatches %s when it leads the chain and is available",
        (source) => {
            expect(
                resolveDownloadSource({ chain: [source], availability }),
            ).toEqual({ kind: "dispatch", source });
        },
    );

    it("dispatches the first available source in chain order", () => {
        expect(
            resolveDownloadSource({
                chain: ["tidal", "youtube", "soulseek"],
                availability: { ...availability, tidal: false },
            }),
        ).toEqual({ kind: "dispatch", source: "youtube" });
    });

    it("never dispatches a source outside the chain", () => {
        expect(
            resolveDownloadSource({
                chain: ["tidal"],
                availability: { ...availability, tidal: false },
            }),
        ).toEqual({
            kind: "fail",
            statusText: "Download sources unavailable — skipped",
            error: "No enabled download source is available (tried tidal)",
        });
    });

    it("fails clearly when the chain is empty", () => {
        expect(resolveDownloadSource({ chain: [], availability })).toEqual({
            kind: "fail",
            statusText: "No download source enabled — skipped",
            error: "No download source is enabled in the playback provider list",
        });
    });
});

describe("resolveRuntimeFallback", () => {
    it("hands off to the next available source after the dispatched one", () => {
        expect(
            resolveRuntimeFallback(
                ["tidal", "lidarr", "youtube", "soulseek"],
                "tidal",
                { ...availability, lidarr: false },
            ),
        ).toBe("youtube");
    });

    it("never falls back to a source ahead of the dispatched one", () => {
        expect(
            resolveRuntimeFallback(
                ["tidal", "youtube"],
                "youtube",
                availability,
            ),
        ).toBeUndefined();
    });

    it("has no fallback when nothing later is available", () => {
        expect(
            resolveRuntimeFallback(["tidal", "soulseek"], "tidal", {
                ...availability,
                soulseek: false,
            }),
        ).toBeUndefined();
    });
});
