import express, { Router, type ErrorRequestHandler } from "express";
import { Readable } from "node:stream";
import request from "supertest";
import { z } from "zod";
import { defineOperation } from "../defineOperation";
import {
    checkClientSurfaceResponse,
    ResponseSchemaMismatchError,
    validateClientSurfaceResponses,
} from "../responseValidation";
import { standardErrors } from "../schemas/common";

const Podcast = z.object({
    id: z.string(),
    title: z.string(),
    episodeCount: z.number().int(),
    updatedAt: z.iso.datetime(),
});

const getPodcast = defineOperation({
    method: "get",
    path: "/api/podcasts/{id}",
    operationId: "getPodcast",
    tag: "podcasts",
    summary: "One podcast",
    params: z.object({ id: z.string() }),
    responses: {
        200: Podcast,
        204: null,
        ...standardErrors,
    },
});

const getMix = defineOperation({
    method: "get",
    path: "/api/mixes/{id}",
    operationId: "getMix",
    tag: "discovery",
    summary: "One mix",
    params: z.object({ id: z.string() }),
    responses: { 200: z.object({ id: z.string() }), 404: standardErrors[401] },
});

const getCover = defineOperation({
    method: "get",
    path: "/api/podcasts/{id}/cover",
    operationId: "getPodcastCover",
    tag: "podcasts",
    summary: "Cover art",
    params: z.object({ id: z.string() }),
    responses: { 200: { binary: "image/jpeg" }, ...standardErrors },
});

const operations = [getPodcast, getMix, getCover];
const mockOperations = operations;

jest.mock("../clientSurface", () => {
    const actual = jest.requireActual("../clientSurface");
    return {
        ...actual,
        getOperation: (operationId: string) => {
            const found = mockOperations.find(
                (operation) => operation.operationId === operationId,
            );
            if (!found) throw new Error(`No operation ${operationId}`);
            return found;
        },
    };
});

// Imported after the mock so the helper resolves the fixture surface.
import { expectClientSurfaceResponse } from "../../routes/__tests__/helpers/expectClientSurfaceResponse";

const conforming = {
    id: "p1",
    title: "Show",
    episodeCount: 3,
    updatedAt: "2026-01-02T03:04:05.000Z",
};

type Body = unknown;

function buildApp(onMismatch: "respond" | "throw", body: () => Body) {
    const app = express();
    app.use(validateClientSurfaceResponses({ operations, onMismatch }));
    const podcasts = Router();
    podcasts.get("/peers", (_req, res) => {
        res.json({ peers: "not a podcast" });
    });
    podcasts.get("/text", (_req, res) => {
        res.status(429).type("text/plain").send("Too many requests");
    });
    podcasts.get("/:id/cover", (_req, res) => {
        res.type("image/jpeg");
        Readable.from([Buffer.from("jpeg-bytes")]).pipe(res);
    });
    podcasts.get("/:id", (req, res) => {
        const status = Number(req.query.status ?? 200);
        res.status(status).json(body());
    });
    app.use("/api/podcasts", podcasts);
    app.use("/api/mixes", (_req, res) => {
        res.status(404).json(body());
    });
    const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
        if (err instanceof ResponseSchemaMismatchError) {
            res.status(599)
                .type("text/plain")
                .send(
                    JSON.stringify({
                        thrown: true,
                        operationId: err.operationId,
                        status: err.status,
                        path: err.path,
                    }),
                );
            return;
        }
        res.status(598).send(String(err));
    };
    app.use(errorHandler);
    return app;
}

describe("checkClientSurfaceResponse", () => {
    it("accepts a conforming body with extra keys", () => {
        expect(
            checkClientSurfaceResponse(getPodcast, 200, {
                ...conforming,
                extra: true,
            }),
        ).toEqual({ ok: true });
    });

    it("reports a missing required key with its path", () => {
        const { title: _title, ...missing } = conforming;
        expect(checkClientSurfaceResponse(getPodcast, 200, missing)).toEqual(
            expect.objectContaining({ ok: false, path: "$.title" }),
        );
    });

    it("reports a wrong type with its path", () => {
        expect(
            checkClientSurfaceResponse(getPodcast, 200, {
                ...conforming,
                episodeCount: "3",
            }),
        ).toEqual(
            expect.objectContaining({ ok: false, path: "$.episodeCount" }),
        );
    });

    it("reports an undeclared status as $status", () => {
        expect(checkClientSurfaceResponse(getPodcast, 418, conforming)).toEqual(
            expect.objectContaining({ ok: false, path: "$status" }),
        );
    });

    it("checks the serialised body, so a Date passes a datetime field", () => {
        expect(
            checkClientSurfaceResponse(getPodcast, 200, {
                ...conforming,
                updatedAt: new Date("2026-01-02T03:04:05Z"),
            }),
        ).toEqual({ ok: true });
    });

    it("does not check null or binary statuses", () => {
        expect(checkClientSurfaceResponse(getPodcast, 204, "anything")).toEqual(
            { ok: true },
        );
        expect(checkClientSurfaceResponse(getCover, 200, { a: 1 })).toEqual({
            ok: true,
        });
    });
});

describe("validateClientSurfaceResponses", () => {
    describe.each(["respond", "throw"] as const)("in %s mode", (mode) => {
        function expectMismatch(
            response: request.Response,
            path: string,
            operationId = "getPodcast",
        ) {
            if (mode === "respond") {
                expect(response.status).toBe(500);
                expect(response.body).toEqual({
                    error: "Response does not match its schema",
                    code: "RESPONSE_SCHEMA_MISMATCH",
                    operationId,
                    path,
                });
            } else {
                expect(response.status).toBe(599);
                expect(JSON.parse(response.text)).toEqual(
                    expect.objectContaining({
                        thrown: true,
                        operationId,
                        path,
                    }),
                );
            }
        }

        it("sends a conforming body unchanged, extra keys included", async () => {
            const body = { ...conforming, extra: { nested: [1, 2] } };
            const response = await request(buildApp(mode, () => body)).get(
                "/api/podcasts/p1",
            );
            expect(response.status).toBe(200);
            expect(response.body).toEqual(body);
        });

        it("fails a missing required key", async () => {
            const { title: _title, ...missing } = conforming;
            const response = await request(buildApp(mode, () => missing)).get(
                "/api/podcasts/p1",
            );
            expectMismatch(response, "$.title");
        });

        it("fails a wrong type", async () => {
            const response = await request(
                buildApp(mode, () => ({ ...conforming, episodeCount: "x" })),
            ).get("/api/podcasts/p1");
            expectMismatch(response, "$.episodeCount");
        });

        it("fails an undeclared status", async () => {
            const response = await request(
                buildApp(mode, () => conforming),
            ).get("/api/podcasts/p1?status=418");
            expectMismatch(response, "$status");
        });

        it("passes a Date for a datetime field", async () => {
            const response = await request(
                buildApp(mode, () => ({
                    ...conforming,
                    updatedAt: new Date("2026-01-02T03:04:05Z"),
                })),
            ).get("/api/podcasts/p1");
            expect(response.status).toBe(200);
            expect(response.body.updatedAt).toBe("2026-01-02T03:04:05.000Z");
        });

        it("leaves a sibling route with the same path shape untouched", async () => {
            const response = await request(
                buildApp(mode, () => conforming),
            ).get("/api/podcasts/peers");
            expect(response.status).toBe(200);
            expect(response.body).toEqual({ peers: "not a podcast" });
        });

        it("validates a registered path served by an app.use handler", async () => {
            const ok = await request(
                buildApp(mode, () => ({ error: "Not found" })),
            ).get("/api/mixes/m1");
            expect(ok.status).toBe(404);
            expect(ok.body).toEqual({ error: "Not found" });

            const bad = await request(
                buildApp(mode, () => ({ message: "Not found" })),
            ).get("/api/mixes/m1");
            expectMismatch(bad, "$.error", "getMix");
        });

        it("leaves a plain-text res.send untouched", async () => {
            const response = await request(
                buildApp(mode, () => conforming),
            ).get("/api/podcasts/text");
            expect(response.status).toBe(429);
            expect(response.text).toBe("Too many requests");
        });

        it("leaves a streamed response untouched", async () => {
            const response = await request(buildApp(mode, () => conforming))
                .get("/api/podcasts/p1/cover")
                .buffer(true)
                .parse((res, callback) => {
                    const chunks: Buffer[] = [];
                    res.on("data", (chunk: Buffer) => chunks.push(chunk));
                    res.on("end", () => callback(null, Buffer.concat(chunks)));
                });
            expect(response.status).toBe(200);
            expect((response.body as Buffer).toString()).toBe("jpeg-bytes");
        });

        it("leaves an unregistered route untouched", async () => {
            const app = express();
            app.use(
                validateClientSurfaceResponses({
                    operations,
                    onMismatch: mode,
                }),
            );
            app.get("/api/elsewhere", (_req, res) => {
                res.status(418).json({ anything: 1 });
            });
            const response = await request(app).get("/api/elsewhere");
            expect(response.status).toBe(418);
            expect(response.body).toEqual({ anything: 1 });
        });
    });
});

describe("expectClientSurfaceResponse", () => {
    it("passes a conforming response", () => {
        expect(() =>
            expectClientSurfaceResponse("getPodcast", {
                statusCode: 200,
                body: {
                    ...conforming,
                    updatedAt: new Date(conforming.updatedAt),
                },
            }),
        ).not.toThrow();
        expect(() =>
            expectClientSurfaceResponse("getPodcast", 200, conforming),
        ).not.toThrow();
    });

    it("throws naming the operation, status and path for a missing key", () => {
        const { title: _title, ...missing } = conforming;
        expect(() =>
            expectClientSurfaceResponse("getPodcast", {
                statusCode: 200,
                body: missing,
            }),
        ).toThrow(/getPodcast.*200.*\$\.title/);
    });

    it("throws for a wrong type", () => {
        expect(() =>
            expectClientSurfaceResponse("getPodcast", 200, {
                ...conforming,
                episodeCount: 1.5,
            }),
        ).toThrow(/getPodcast.*200.*\$\.episodeCount/);
    });

    it("throws for an undeclared status", () => {
        expect(() =>
            expectClientSurfaceResponse("getPodcast", 418, conforming),
        ).toThrow(/getPodcast.*418.*\$status/);
    });
});
