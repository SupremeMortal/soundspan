import { PassThrough } from "node:stream";

jest.mock("../../../utils/logger", () => {
    const l: any = {
        debug: jest.fn(),
        info: jest.fn(),
        warn: jest.fn(),
        error: jest.fn(),
    };
    l.child = () => l;
    return { logger: l };
});

const mockService = {
    getUserPreferredQuality: jest.fn(),
    getStreamProxy: jest.fn(),
    getStreamInfo: jest.fn(),
};
jest.mock("../../tidalStreaming", () => ({
    tidalStreamingService: mockService,
}));

const mockSession = {
    ensureUserOAuth: jest.fn(),
    markTidalSessionStale: jest.fn(),
    setTidalOAuthCache: jest.fn(),
};
jest.mock("../../tidalUserSession", () => mockSession);

const mockDownloads = {
    isTidalPlayDownloadEnabled: jest.fn(),
    findTidalPlayDownload: jest.fn(),
    openTidalPlayDownload: jest.fn(),
    awaitTidalPlayDownload: jest.fn(),
    tidalPlayDownloadInfo: jest.fn(),
    tidalPlayDownloadStartInfo: jest.fn(),
    resolveTidalPlayDownloadQuality: jest.fn(),
    streamTidalPlayDownload: jest.fn(),
    tidalPlayDownloadStreamInfo: jest.fn(),
};
jest.mock("../../tidalPlayDownloads", () => mockDownloads);

import { getTidalStreamInfo, streamTidalTrack } from "../streamTidalTrack";

function makeRes() {
    const res: any = new PassThrough();
    res.headersSent = false;
    res.headers = {} as Record<string, string>;
    res.statusCode = 200;
    res.status = jest.fn((code: number) => {
        res.statusCode = code;
        return res;
    });
    res.setHeader = jest.fn((k: string, v: string) => {
        res.headers[k] = v;
    });
    res.json = jest.fn((body: unknown) => {
        res.headersSent = true;
        res.body = body;
        return res;
    });
    return res;
}

const input = (over: Record<string, unknown> = {}) => {
    const res = makeRes();
    return {
        res,
        args: {
            userId: "u1",
            trackId: 42,
            quality: undefined as unknown,
            req: { headers: {} } as any,
            res,
            ...over,
        },
    };
};

beforeEach(() => {
    jest.resetAllMocks();
    mockDownloads.isTidalPlayDownloadEnabled.mockResolvedValue(false);
    mockSession.ensureUserOAuth.mockResolvedValue(true);
    mockService.getUserPreferredQuality.mockResolvedValue("HIGH");
});

describe("streamTidalTrack", () => {
    it("rejects with 401 and marks the session unauthenticated when TIDAL is not linked", async () => {
        mockSession.ensureUserOAuth.mockResolvedValue(false);
        const { res, args } = input();
        await streamTidalTrack(args);
        expect(res.statusCode).toBe(401);
        expect(res.body).toEqual({ error: "Not authenticated to TIDAL" });
        expect(mockSession.setTidalOAuthCache).toHaveBeenCalledWith(
            "u1",
            false,
        );
        expect(mockService.getStreamProxy).not.toHaveBeenCalled();
    });

    it("uses the requested quality and forwards Range, status and upstream headers", async () => {
        const data = new PassThrough();
        mockService.getStreamProxy.mockResolvedValue({
            status: 206,
            headers: {
                "content-type": "audio/flac",
                "content-range": "bytes 0-9/100",
            },
            data,
        });
        const { res, args } = input({
            quality: "LOSSLESS",
            req: { headers: { range: "bytes=0-9" } },
        });
        const chunks: Buffer[] = [];
        res.on("data", (c: Buffer) => chunks.push(c));
        await streamTidalTrack(args);
        data.end("abc");
        await new Promise((r) => res.on("end", r));

        expect(mockService.getStreamProxy).toHaveBeenCalledWith(
            "u1",
            42,
            "LOSSLESS",
            "bytes=0-9",
        );
        expect(mockService.getUserPreferredQuality).not.toHaveBeenCalled();
        expect(res.statusCode).toBe(206);
        expect(res.headers).toEqual({
            "Accept-Ranges": "bytes",
            "Cache-Control": "no-cache",
            "Content-Type": "audio/flac",
            "Content-Range": "bytes 0-9/100",
        });
        expect(Buffer.concat(chunks).toString()).toBe("abc");
    });

    it("falls back to the user's preferred quality when quality is not a string", async () => {
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data: new PassThrough(),
        });
        const { args } = input({ quality: ["x"] });
        await streamTidalTrack(args);
        expect(mockService.getStreamProxy).toHaveBeenCalledWith(
            "u1",
            42,
            "HIGH",
            undefined,
        );
    });

    it("destroys the upstream stream when the client disconnects", async () => {
        const data = new PassThrough();
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data,
        });
        const { res, args } = input();
        await streamTidalTrack(args);
        res.emit("close");
        expect(data.destroyed).toBe(true);
    });

    it("answers 500 and marks the session stale when the sidecar rejects the session", async () => {
        mockService.getStreamProxy.mockRejectedValue(
            Object.assign(new Error("denied"), { response: { status: 401 } }),
        );
        const { res, args } = input();
        await streamTidalTrack(args);
        expect(mockSession.markTidalSessionStale).toHaveBeenCalledWith("u1");
        expect(res.statusCode).toBe(500);
        expect(res.body).toEqual({ error: "Stream failed" });
    });

    it("answers 502 when the upstream stream errors before headers are sent", async () => {
        const data = new PassThrough();
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data,
        });
        const { res, args } = input();
        await streamTidalTrack(args);
        data.emit("error", new Error("boom"));
        expect(res.statusCode).toBe(502);
        expect(res.body).toEqual({ error: "Upstream stream failed" });
    });

    describe("download-as-you-play", () => {
        beforeEach(() => {
            mockDownloads.isTidalPlayDownloadEnabled.mockResolvedValue(true);
        });

        it("plays a finished download without touching the sidecar proxy", async () => {
            const file = { path: "/x.flac" };
            mockDownloads.findTidalPlayDownload.mockResolvedValue(file);
            mockDownloads.resolveTidalPlayDownloadQuality.mockResolvedValue(
                "LOSSLESS",
            );
            mockDownloads.streamTidalPlayDownload.mockResolvedValue(undefined);
            const { res, args } = input();
            await streamTidalTrack(args);
            expect(mockDownloads.streamTidalPlayDownload).toHaveBeenCalledWith(
                args.req,
                res,
                file,
                "LOSSLESS",
            );
            expect(mockService.getStreamProxy).not.toHaveBeenCalled();
            expect(mockSession.ensureUserOAuth).not.toHaveBeenCalled();
        });

        it("waits for the whole file when the request seeks past the start", async () => {
            mockDownloads.findTidalPlayDownload.mockResolvedValue(null);
            mockDownloads.awaitTidalPlayDownload.mockResolvedValue({
                path: "/x.flac",
            });
            mockDownloads.resolveTidalPlayDownloadQuality.mockResolvedValue(
                "HIGH",
            );
            const { args } = input({
                req: { headers: { range: "bytes=500-" } },
            });
            await streamTidalTrack(args);
            expect(mockDownloads.awaitTidalPlayDownload).toHaveBeenCalledWith(
                42,
                "u1",
            );
            expect(mockDownloads.streamTidalPlayDownload).toHaveBeenCalled();
        });

        it("streams the in-progress download with seeking disabled", async () => {
            mockDownloads.findTidalPlayDownload.mockResolvedValue(null);
            const stream = new PassThrough();
            mockDownloads.openTidalPlayDownload.mockResolvedValue({
                stream,
                info: { contentType: "audio/flac" },
            });
            const { res, args } = input();
            await streamTidalTrack(args);
            expect(res.statusCode).toBe(200);
            expect(res.headers).toEqual({
                "Content-Type": "audio/flac",
                "Cache-Control": "no-cache",
                "Accept-Ranges": "none",
            });
        });

        it("answers 502 when the download cannot start", async () => {
            mockDownloads.findTidalPlayDownload.mockResolvedValue(null);
            mockDownloads.openTidalPlayDownload.mockRejectedValue(
                new Error("nope"),
            );
            const { res, args } = input();
            await streamTidalTrack(args);
            expect(res.statusCode).toBe(502);
        });
    });
});

describe("getTidalStreamInfo", () => {
    it("answers 401 when TIDAL is not linked", async () => {
        mockSession.ensureUserOAuth.mockResolvedValue(false);
        const { res, args } = input();
        await getTidalStreamInfo(args);
        expect(res.statusCode).toBe(401);
        expect(mockSession.setTidalOAuthCache).toHaveBeenCalledWith(
            "u1",
            false,
        );
    });

    it("returns sidecar info using the requested quality", async () => {
        mockService.getStreamInfo.mockResolvedValue({ codec: "flac" });
        const { res, args } = input({ quality: "LOSSLESS" });
        await getTidalStreamInfo(args);
        expect(mockService.getStreamInfo).toHaveBeenCalledWith(
            "u1",
            42,
            "LOSSLESS",
        );
        expect(res.body).toEqual({ codec: "flac" });
    });

    it("defaults to the user's preferred quality", async () => {
        mockService.getStreamInfo.mockResolvedValue({});
        const { args } = input();
        await getTidalStreamInfo(args);
        expect(mockService.getStreamInfo).toHaveBeenCalledWith(
            "u1",
            42,
            "HIGH",
        );
    });

    it("answers 500 and marks the session stale on an upstream 401", async () => {
        mockService.getStreamInfo.mockRejectedValue(
            Object.assign(new Error("denied"), { response: { status: 401 } }),
        );
        const { res, args } = input();
        await getTidalStreamInfo(args);
        expect(mockSession.markTidalSessionStale).toHaveBeenCalledWith("u1");
        expect(res.statusCode).toBe(500);
        expect(res.body).toEqual({ error: "Failed to get stream info" });
    });

    describe("download-as-you-play", () => {
        beforeEach(() => {
            mockDownloads.isTidalPlayDownloadEnabled.mockResolvedValue(true);
        });

        it("describes a finished download", async () => {
            const file = { path: "/x.flac" };
            mockDownloads.findTidalPlayDownload.mockResolvedValue(file);
            mockDownloads.resolveTidalPlayDownloadQuality.mockResolvedValue(
                "LOSSLESS",
            );
            mockDownloads.tidalPlayDownloadStreamInfo.mockReturnValue({
                codec: "flac",
            });
            const { res, args } = input();
            await getTidalStreamInfo(args);
            expect(
                mockDownloads.tidalPlayDownloadStreamInfo,
            ).toHaveBeenCalledWith(file, "LOSSLESS");
            expect(res.body).toEqual({ codec: "flac" });
            expect(mockService.getStreamInfo).not.toHaveBeenCalled();
        });

        it("describes a download that is about to start", async () => {
            mockDownloads.findTidalPlayDownload.mockResolvedValue(null);
            mockDownloads.tidalPlayDownloadInfo.mockResolvedValue({ a: 1 });
            mockDownloads.tidalPlayDownloadStartInfo.mockReturnValue({ b: 2 });
            const { res, args } = input();
            await getTidalStreamInfo(args);
            expect(
                mockDownloads.tidalPlayDownloadStartInfo,
            ).toHaveBeenCalledWith(42, { a: 1 });
            expect(res.body).toEqual({ b: 2 });
        });

        it("answers 502 when the download info fails", async () => {
            mockDownloads.findTidalPlayDownload.mockRejectedValue(
                new Error("x"),
            );
            const { res, args } = input();
            await getTidalStreamInfo(args);
            expect(res.statusCode).toBe(502);
        });
    });
});
