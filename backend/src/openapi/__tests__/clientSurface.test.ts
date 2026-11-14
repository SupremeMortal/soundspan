import express from "express";
import { z } from "zod";
import {
    clientSurfaceOperations,
    createClientSurface,
    findDuplicateOperationIds,
    findInvalidOperations,
    findUntypedSchemas,
    getOperation,
    type ClientSurfaceOperation,
} from "../clientSurface";
import { defineOperation } from "../defineOperation";
import { findDuplicateDescriptions } from "../document";
import { ApiError, standardErrors } from "../schemas/common";
import { isMounted, isMountedIn, routerServes } from "./helpers/mountedRoutes";

jest.mock("../../config", () => ({
    config: { port: 3006, music: { musicPath: "/music" } },
}));
jest.mock("../../utils/db", () => ({ prisma: {} }));
jest.mock("../../utils/redis", () => ({ redisClient: {} }));
jest.mock("../../workers/queues", () => ({ scanQueue: {} }));
jest.mock("../../services/lastfm", () => ({ lastFmService: {} }));
jest.mock("../../utils/schedulerClaim", () => ({
    acquireSchedulerClaim: jest.fn(),
    releaseSchedulerClaim: jest.fn(),
}));
jest.mock("../../services/audioStreaming", () => ({
    AudioStreamingService: jest.fn(),
}));
jest.mock("../../middleware/auth", () => {
    const pass = (_req: unknown, _res: unknown, next: () => void) => next();
    return new Proxy({}, { get: () => pass });
});

function fixture(
    overrides: Partial<Parameters<typeof defineOperation>[0]> = {},
): ClientSurfaceOperation {
    return defineOperation({
        method: "get",
        path: "/api/health",
        operationId: "getHealth",
        tag: "session",
        summary: "Health",
        anonymous: true,
        responses: {
            200: z.object({ status: z.string() }),
            ...standardErrors,
        },
        ...overrides,
    });
}

function unmounted(surface: readonly ClientSurfaceOperation[]): string[] {
    return surface
        .filter((operation) => !isMounted(operation.method, operation.path))
        .map((operation) => `${operation.method} ${operation.path}`);
}

describe("the registered client surface", () => {
    const surface = clientSurfaceOperations;

    test("operationIds are unique", () => {
        expect(findDuplicateOperationIds(surface)).toEqual([]);
    });

    test("every operation has one known tag and a body declaration per status", () => {
        expect(findInvalidOperations(surface)).toEqual([]);
    });

    test("no schema contains an untyped object", () => {
        expect(findUntypedSchemas(surface)).toEqual([]);
    });

    test("every operation resolves to a mounted route", () => {
        expect(unmounted(surface)).toEqual([]);
    });

    test("no registered operation keeps an @openapi comment", () => {
        const { commentDocument } = require("../../config/swagger");

        expect(findDuplicateDescriptions(commentDocument, surface)).toEqual([]);
    });

    test("getOperation finds every registered operation by id", () => {
        for (const operation of surface) {
            expect(getOperation(operation.operationId)).toBe(operation);
        }
        expect(() => getOperation("noSuchOperation")).toThrow(
            /noSuchOperation/,
        );
    });
});

describe("each rule fails on a fixture surface that breaks it", () => {
    test("a passing fixture surface passes every rule", () => {
        const surface = createClientSurface([fixture()]);

        expect(findDuplicateOperationIds(surface)).toEqual([]);
        expect(findInvalidOperations(surface)).toEqual([]);
        expect(findUntypedSchemas(surface)).toEqual([]);
        expect(unmounted(surface)).toEqual([]);
    });

    test("duplicate operationIds", () => {
        const surface = createClientSurface([
            fixture(),
            fixture({ path: "/api/docs.json" }),
        ]);

        expect(findDuplicateOperationIds(surface)).toEqual(["getHealth"]);
    });

    test("an unknown tag", () => {
        const surface = createClientSurface([
            { ...fixture(), tag: "admin" } as unknown as ClientSurfaceOperation,
        ]);

        expect(findInvalidOperations(surface)).toEqual([
            expect.stringContaining("admin"),
        ]);
    });

    test("a status without a schema, binary marker or null", () => {
        const surface = createClientSurface([
            {
                ...fixture(),
                responses: { 200: undefined },
            } as unknown as ClientSurfaceOperation,
        ]);

        expect(findInvalidOperations(surface)).toEqual([
            expect.stringContaining("200"),
        ]);
    });

    test.each([
        ["z.any", z.any()],
        ["z.unknown", z.unknown()],
        ["an empty object", z.object({})],
        ["a record of unknown", z.record(z.string(), z.unknown())],
    ])("an untyped schema: %s", (_label, untyped) => {
        const surface = createClientSurface([
            fixture({
                responses: {
                    200: z.object({ status: z.string(), extra: untyped }),
                    500: ApiError,
                },
            }),
        ]);

        expect(findUntypedSchemas(surface)).toEqual([
            expect.stringContaining("getHealth"),
        ]);
    });

    test("an untyped request body", () => {
        const surface = createClientSurface([
            fixture({ method: "post", body: z.record(z.string(), z.any()) }),
        ]);

        expect(findUntypedSchemas(surface)).toEqual([
            expect.stringContaining("request body"),
        ]);
    });

    test("an operation that is not mounted", () => {
        const surface = createClientSurface([
            fixture({ path: "/api/not-mounted" }),
        ]);

        expect(unmounted(surface)).toEqual(["get /api/not-mounted"]);
    });

    test("an operation that still has an @openapi comment", () => {
        const surface = createClientSurface([fixture()]);
        const commentDocument = {
            paths: { "/api/health": { get: { summary: "comment" } } },
        };

        expect(findDuplicateDescriptions(commentDocument, surface)).toEqual([
            "GET /api/health",
        ]);
    });
});

describe("mounted route resolution", () => {
    function libraryRouter() {
        const albums = express.Router();
        albums.get("/:albumId", (_req, res) => {
            res.end();
        });
        const router = express.Router();
        router.use("/albums", albums);
        router.get("/cover-art{/:id}", (_req, res) => {
            res.end();
        });
        router.post("/scan", (_req, res) => {
            res.end();
        });
        return router;
    }

    test("walks nested routers and compares by path shape", () => {
        expect(routerServes(libraryRouter(), "get", "/albums/{id}")).toBe(true);
        expect(routerServes(libraryRouter(), "get", "/albums")).toBe(false);
    });

    test("matches both forms of an optional group", () => {
        expect(routerServes(libraryRouter(), "get", "/cover-art")).toBe(true);
        expect(routerServes(libraryRouter(), "get", "/cover-art/{id}")).toBe(
            true,
        );
    });

    test("requires the method to match", () => {
        expect(routerServes(libraryRouter(), "post", "/scan")).toBe(true);
        expect(routerServes(libraryRouter(), "get", "/scan")).toBe(false);
    });

    test("resolves through a mount prefix", () => {
        const mounts = { "/api/library": libraryRouter };

        expect(isMountedIn(mounts, "get", "/api/library/albums/{id}")).toBe(
            true,
        );
        expect(isMountedIn(mounts, "get", "/api/libraryx/albums/{id}")).toBe(
            false,
        );
        expect(isMountedIn(mounts, "get", "/api/health")).toBe(true);
    });
});
