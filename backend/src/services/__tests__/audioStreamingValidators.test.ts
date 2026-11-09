import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { AudioStreamingService } from "../audioStreaming";

jest.mock("../../utils/db", () => ({ prisma: {} }));
jest.mock("music-metadata", () => ({ parseFile: jest.fn() }), {
    virtual: true,
});
jest.mock("../../config", () => ({
    config: {
        allowedOrigins: [],
        nodeEnv: "test",
        streaming: { ffmpegPathOverride: undefined },
    },
}));
jest.mock("../../utils/configValidator", () => ({
    inspectFfmpegVersion: jest.fn(),
    resolveFfmpegBinaryPath: jest.fn(() => "ffmpeg"),
}));

/** Minimal express Response that records status, headers and body bytes. */
function createRes() {
    const chunks: Buffer[] = [];
    const res: any = {
        statusCode: 200,
        headers: {} as Record<string, string>,
        headersSent: false,
    };
    const { Writable } = require("stream");
    const sink = new Writable({
        write(chunk: Buffer, _enc: string, cb: () => void) {
            chunks.push(Buffer.from(chunk));
            cb();
        },
    });
    Object.assign(res, {
        status(code: number) {
            res.statusCode = code;
            return res;
        },
        set(h: Record<string, string>) {
            Object.assign(res.headers, h);
            return res;
        },
        end(...a: unknown[]) {
            return sink.end(...a);
        },
        write: sink.write.bind(sink),
        on: sink.on.bind(sink),
        once: sink.once.bind(sink),
        emit: sink.emit.bind(sink),
        removeListener: sink.removeListener.bind(sink),
        off: sink.off.bind(sink),
    });
    Object.defineProperty(res, "writableEnded", {
        get: () => sink.writableEnded,
    });
    res.body = () => Buffer.concat(chunks);
    res._sink = sink;
    return res;
}

describe("streamFileWithRangeSupport validators", () => {
    let dir: string;
    let file: string;
    let service: AudioStreamingService;
    const content = Buffer.from("0123456789abcdefghij");

    beforeEach(() => {
        dir = fs.mkdtempSync(path.join(os.tmpdir(), "etag-"));
        file = path.join(dir, "a.flac");
        fs.writeFileSync(file, content);
        service = new AudioStreamingService(dir, dir, 1);
    });
    afterEach(() => {
        service.destroy();
        fs.rmSync(dir, { recursive: true, force: true });
    });

    async function serve(
        headers: Record<string, string>,
        validator?: { playbackId: string; variant: string },
    ) {
        const res = createRes();
        await service.streamFileWithRangeSupport(
            { headers } as any,
            res,
            file,
            "audio/flac",
            undefined,
            validator,
        );
        await new Promise((r) => setImmediate(r));
        return res;
    }

    const validator = { playbackId: "t.abc", variant: "original" };

    it("sends no ETag when no validator is given", async () => {
        const res = await serve({});
        expect(res.headers.ETag).toBeUndefined();
    });

    it("sends the same strong ETag on two requests", async () => {
        const a = await serve({}, validator);
        const b = await serve({}, validator);
        expect(a.headers.ETag).toMatch(/^"[0-9a-f]{32}"$/);
        expect(b.headers.ETag).toBe(a.headers.ETag);
    });

    it("gives a different ETag to a different variant of the same track", async () => {
        const original = await serve({}, validator);
        const other = await serve({}, { ...validator, variant: "high" });
        expect(other.headers.ETag).not.toBe(original.headers.ETag);
    });

    it("changes the ETag when the served file changes", async () => {
        const before = await serve({}, validator);
        fs.writeFileSync(file, Buffer.from("0123456789abcdefghijKLMN"));
        const after = await serve({}, validator);
        expect(after.headers.ETag).not.toBe(before.headers.ETag);
    });

    it("serves 206 when Range comes with a matching If-Range", async () => {
        const { headers } = await serve({}, validator);
        const res = await serve(
            { range: "bytes=5-9", "if-range": headers.ETag },
            validator,
        );
        expect(res.statusCode).toBe(206);
        expect(res.headers["Content-Range"]).toBe(
            `bytes 5-9/${content.length}`,
        );
        expect(res.body().toString()).toBe("56789");
    });

    it("serves the full 200 body when If-Range does not match", async () => {
        const res = await serve(
            { range: "bytes=5-9", "if-range": '"stale"' },
            validator,
        );
        expect(res.statusCode).toBe(200);
        expect(res.headers["Content-Range"]).toBeUndefined();
        expect(res.headers["Content-Length"]).toBe(String(content.length));
        expect(res.body().toString()).toBe(content.toString());
    });

    it("ignores If-Range on a request without a validator", async () => {
        const res = await serve({ range: "bytes=5-9", "if-range": '"stale"' });
        expect(res.statusCode).toBe(206);
    });
});
