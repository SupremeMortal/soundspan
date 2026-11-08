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

const mockService = { getStreamProxy: jest.fn() };
jest.mock("../../youtubeDownload", () => ({
    youtubeDownloadService: mockService,
}));

import { streamYouTubeVideo } from "../streamYouTubeVideo";

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

const run = (over: Record<string, unknown> = {}) => {
    const res = makeRes();
    return {
        res,
        args: {
            videoId: "dQw4w9WgXcQ",
            quality: undefined as unknown,
            range: undefined as string | undefined,
            res,
            ...over,
        },
    };
};

const proxy = (status = 200, headers: Record<string, string> = {}) => ({
    status,
    headers,
    data: new PassThrough(),
});

beforeEach(() => jest.clearAllMocks());

describe("streamYouTubeVideo", () => {
    it("defaults quality to HIGH and uppercases a given quality", async () => {
        mockService.getStreamProxy.mockResolvedValue(proxy());
        const a = run();
        await streamYouTubeVideo(a.args);
        expect(mockService.getStreamProxy).toHaveBeenCalledWith(
            "dQw4w9WgXcQ",
            "HIGH",
            undefined,
        );
        const b = run({ quality: "low", range: "bytes=5-" });
        mockService.getStreamProxy.mockResolvedValue(proxy());
        await streamYouTubeVideo(b.args);
        expect(mockService.getStreamProxy).toHaveBeenLastCalledWith(
            "dQw4w9WgXcQ",
            "LOW",
            "bytes=5-",
        );
    });

    it("forwards the upstream status, allowed headers and body", async () => {
        const p = proxy(206, {
            "content-type": "audio/webm",
            "content-length": "3",
            "content-range": "bytes 0-2/10",
            "accept-ranges": "bytes",
            "set-cookie": "nope",
        });
        mockService.getStreamProxy.mockResolvedValue(p);
        const { res, args } = run();
        const chunks: Buffer[] = [];
        res.on("data", (c: Buffer) => chunks.push(c));
        await streamYouTubeVideo(args);
        p.data.end("abc");
        await new Promise((r) => res.on("end", r));
        expect(res.status).toHaveBeenCalledWith(206);
        expect(res.headers["content-type"]).toBe("audio/webm");
        expect(res.headers["content-range"]).toBe("bytes 0-2/10");
        expect(res.headers["accept-ranges"]).toBe("bytes");
        expect(res.headers["set-cookie"]).toBeUndefined();
        expect(Buffer.concat(chunks).toString()).toBe("abc");
    });

    it("destroys the upstream stream when the client disconnects", async () => {
        const p = proxy();
        mockService.getStreamProxy.mockResolvedValue(p);
        const { res, args } = run();
        await streamYouTubeVideo(args);
        res.emit("close");
        expect(p.data.destroyed).toBe(true);
    });

    it("answers 502 on an upstream error before headers are sent", async () => {
        const p = proxy();
        mockService.getStreamProxy.mockResolvedValue(p);
        const { res, args } = run();
        await streamYouTubeVideo(args);
        p.data.emit("error", new Error("boom"));
        expect(res.status).toHaveBeenLastCalledWith(502);
        expect(res.body).toEqual({ error: "Upstream stream failed" });
    });

    it("ends the response on an upstream error after headers are sent", async () => {
        const p = proxy();
        mockService.getStreamProxy.mockResolvedValue(p);
        const { res, args } = run();
        await streamYouTubeVideo(args);
        res.headersSent = true;
        const end = jest.spyOn(res, "end");
        p.data.emit("error", new Error("boom"));
        expect(end).toHaveBeenCalled();
        expect(res.json).not.toHaveBeenCalled();
    });

    it.each([
        [404, 404, "Stream not found"],
        [
            451,
            451,
            "This content requires age verification and cannot be streamed.",
        ],
    ])("maps sidecar %i to %i", async (upstream, status, message) => {
        mockService.getStreamProxy.mockRejectedValue(
            Object.assign(new Error("x"), { response: { status: upstream } }),
        );
        const { res, args } = run();
        await streamYouTubeVideo(args);
        expect(res.status).toHaveBeenCalledWith(status);
        expect(JSON.stringify(res.body)).toContain(message);
    });

    it("answers 500 for any other failure", async () => {
        mockService.getStreamProxy.mockRejectedValue(new Error("kaput"));
        const { res, args } = run();
        await streamYouTubeVideo(args);
        expect(res.status).toHaveBeenCalledWith(500);
        expect(res.body).toEqual({ error: "Failed to stream audio" });
    });
});
