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
    getStreamProxy: jest.fn(),
    getStreamInfo: jest.fn(),
};
jest.mock("../../youtubeMusic", () => ({
    ytMusicService: mockService,
    normalizeYtMusicStreamQuality: (q?: string | null) =>
        q ? q.toLowerCase() : undefined,
}));

const mockSession = {
    getUserIdOrPublic: jest.fn(),
    invalidateAllYtOAuthSessions: jest.fn(),
    getHttpErrorStatus: jest.fn(),
};
jest.mock("../../ytMusicUserSession", () => mockSession);

const mockPrisma = { userSettings: { findUnique: jest.fn() } };
jest.mock("../../../utils/db", () => ({ prisma: mockPrisma }));

import {
    getYtMusicStreamInfo,
    streamYtMusicTrack,
} from "../streamYtMusicTrack";

function makeRes() {
    const res: any = new PassThrough();
    res.headersSent = false;
    res.headers = {} as Record<string, string>;
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
            videoId: "vid1",
            quality: undefined as unknown,
            mode: "authenticated" as "authenticated" | "public",
            req: { headers: {} } as any,
            res,
            ...over,
        } as any,
    };
};

const httpError = (status: number) => ({ response: { status } });

beforeEach(() => {
    jest.resetAllMocks();
    mockSession.getUserIdOrPublic.mockResolvedValue("u1");
    mockSession.getHttpErrorStatus.mockImplementation(
        (e: any) => e?.response?.status,
    );
    mockPrisma.userSettings.findUnique.mockResolvedValue(null);
});

describe("streamYtMusicTrack", () => {
    it("pipes the sidecar stream with forwarded headers, Range and the saved quality", async () => {
        mockPrisma.userSettings.findUnique.mockResolvedValue({
            ytMusicQuality: "LOW",
        });
        const data = new PassThrough();
        mockService.getStreamProxy.mockResolvedValue({
            status: 206,
            headers: {
                "content-type": "audio/webm",
                "content-range": "bytes 0-3/10",
                "x-ignored": "1",
            },
            data,
        });
        const { res, args } = input({
            req: { headers: { range: "bytes=0-3" } },
        });
        const done = new Promise((r) => res.on("finish", r));
        await streamYtMusicTrack(args);
        data.end("abcd");
        await done;

        expect(mockService.getStreamProxy).toHaveBeenCalledWith(
            "u1",
            "vid1",
            "low",
            "bytes=0-3",
        );
        expect(res.statusCode).toBe(206);
        expect(res.headers).toEqual({
            "content-type": "audio/webm",
            "content-range": "bytes 0-3/10",
        });
        expect(res.read().toString()).toBe("abcd");
    });

    it("prefers an explicit quality over the saved one", async () => {
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data: Object.assign(new PassThrough(), {}),
        });
        const { args } = input({ quality: "  medium " });
        await streamYtMusicTrack(args);
        expect(mockService.getStreamProxy.mock.calls[0][2]).toBe("medium");
        expect(mockPrisma.userSettings.findUnique).not.toHaveBeenCalled();
    });

    it("falls back to high when reading the saved quality fails", async () => {
        mockPrisma.userSettings.findUnique.mockRejectedValue(new Error("db"));
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data: new PassThrough(),
        });
        const { args } = input();
        await streamYtMusicTrack(args);
        expect(mockService.getStreamProxy.mock.calls[0][2]).toBe("high");
    });

    it("streams as the public identity with HIGH default in public mode", async () => {
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data: new PassThrough(),
        });
        const { args } = input({ mode: "public", userId: undefined });
        await streamYtMusicTrack(args);
        expect(mockSession.getUserIdOrPublic).not.toHaveBeenCalled();
        expect(mockService.getStreamProxy).toHaveBeenCalledWith(
            "__public__",
            "vid1",
            "high",
            undefined,
        );
    });

    it.each([
        [404, { error: "Stream not found" }],
        [503, { error: "YouTube Music streaming is busy" }],
        [504, { error: "YouTube Music stream timed out" }],
    ])("maps upstream %i to its message", async (status, body) => {
        mockService.getStreamProxy.mockRejectedValue(httpError(status));
        const { res, args } = input();
        await streamYtMusicTrack(args);
        expect(res.statusCode).toBe(status);
        expect(res.body).toEqual(body);
    });

    it("maps upstream 451 to age_restricted", async () => {
        mockService.getStreamProxy.mockRejectedValue(httpError(451));
        const { res, args } = input();
        await streamYtMusicTrack(args);
        expect(res.statusCode).toBe(451);
        expect(res.body.error).toBe("age_restricted");
    });

    it("answers 401 and drops cached sessions in authenticated mode", async () => {
        mockService.getStreamProxy.mockRejectedValue(httpError(401));
        const { res, args } = input();
        await streamYtMusicTrack(args);
        expect(res.statusCode).toBe(401);
        expect(mockSession.invalidateAllYtOAuthSessions).toHaveBeenCalled();
    });

    it("answers 500 for an upstream 401 in public mode", async () => {
        mockService.getStreamProxy.mockRejectedValue(httpError(401));
        const { res, args } = input({ mode: "public" });
        await streamYtMusicTrack(args);
        expect(res.statusCode).toBe(500);
        expect(mockSession.invalidateAllYtOAuthSessions).not.toHaveBeenCalled();
    });

    it("answers 502 when the upstream stream errors before any bytes", async () => {
        const data = new PassThrough();
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data,
        });
        const { res, args } = input();
        await streamYtMusicTrack(args);
        data.emit("error", new Error("boom"));
        expect(res.statusCode).toBe(502);
        expect(res.body).toEqual({ error: "Upstream stream failed" });
    });

    it("destroys the upstream stream when the client disconnects", async () => {
        const data = new PassThrough();
        mockService.getStreamProxy.mockResolvedValue({
            status: 200,
            headers: {},
            data,
        });
        const { res, args } = input();
        await streamYtMusicTrack(args);
        res.emit("close");
        expect(data.destroyed).toBe(true);
    });
});

describe("getYtMusicStreamInfo", () => {
    const info = {
        videoId: "vid1",
        abr: 128,
        acodec: "opus",
        duration: 200,
        content_type: "audio/webm",
        extra: "dropped",
    };

    it("writes the whitelisted stream metadata", async () => {
        mockService.getStreamInfo.mockResolvedValue(info);
        const { res, args } = input({ quality: "high" });
        await getYtMusicStreamInfo(args);
        expect(mockService.getStreamInfo).toHaveBeenCalledWith(
            "u1",
            "vid1",
            "high",
        );
        expect(res.body).toEqual({
            videoId: "vid1",
            abr: 128,
            acodec: "opus",
            duration: 200,
            content_type: "audio/webm",
        });
    });

    it("uses the public identity in public mode", async () => {
        mockService.getStreamInfo.mockResolvedValue(info);
        const { args } = input({ mode: "public", userId: undefined });
        await getYtMusicStreamInfo(args);
        expect(mockService.getStreamInfo).toHaveBeenCalledWith(
            "__public__",
            "vid1",
            "high",
        );
    });

    it("maps 404 and 451", async () => {
        mockService.getStreamInfo.mockRejectedValueOnce(httpError(404));
        let r = input();
        await getYtMusicStreamInfo(r.args);
        expect(r.res.statusCode).toBe(404);
        expect(r.res.body).toEqual({ error: "Stream not found" });

        mockService.getStreamInfo.mockRejectedValueOnce(httpError(451));
        r = input();
        await getYtMusicStreamInfo(r.args);
        expect(r.res.statusCode).toBe(451);
        expect(r.res.body.error).toBe("age_restricted");
    });

    it("answers 401 only in authenticated mode, else 500", async () => {
        mockService.getStreamInfo.mockRejectedValue(httpError(401));
        let r = input();
        await getYtMusicStreamInfo(r.args);
        expect(r.res.statusCode).toBe(401);
        r = input({ mode: "public" });
        await getYtMusicStreamInfo(r.args);
        expect(r.res.statusCode).toBe(500);
    });
});
