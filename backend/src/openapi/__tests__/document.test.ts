import { z } from "zod";
import { createClientSurface } from "../clientSurface";
import { defineOperation } from "../defineOperation";
import {
    buildClientSurfaceDocument,
    findDuplicateDescriptions,
    mergeClientSurface,
} from "../document";
import { ApiError, standardErrors } from "../schemas/common";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

const ArtistRef = z
    .object({ id: z.string(), name: z.string() })
    .meta({ id: "DocumentTestArtistRef" });

const AlbumSummary = z
    .object({
        id: z.string(),
        title: z.string(),
        year: z.number().int().nullable(),
        playbackId: z.string().optional(),
        kind: z.enum(["album", "single"]),
        addedAt: z.iso.datetime(),
        artist: ArtistRef,
    })
    .meta({ id: "DocumentTestAlbumSummary" });

const AlbumList = z
    .object({ albums: z.array(AlbumSummary) })
    .meta({ id: "DocumentTestAlbumList" });

const listAlbums = defineOperation({
    method: "get",
    path: "/api/library/albums",
    operationId: "listAlbums",
    tag: "library",
    summary: "List albums",
    query: z.object({ limit: z.coerce.number().int().optional() }),
    responses: { 200: AlbumList, ...standardErrors },
});

const getAlbum = defineOperation({
    method: "get",
    path: "/api/library/albums/{id}",
    operationId: "getAlbum",
    tag: "library",
    summary: "Get one album",
    params: z.object({ id: z.string() }),
    responses: { 200: AlbumSummary, 404: ApiError, ...standardErrors },
});

const streamTrack = defineOperation({
    method: "get",
    path: "/api/playback/stream",
    operationId: "streamTrack",
    tag: "playback",
    summary: "Stream a track",
    responses: { 200: { binary: "audio/*" }, 204: null },
});

const login = defineOperation({
    method: "post",
    path: "/api/auth/login",
    operationId: "login",
    tag: "session",
    summary: "Log in",
    anonymous: true,
    body: z.object({ username: z.string(), password: z.string() }),
    responses: { 200: z.object({ token: z.string() }), 401: ApiError },
});

function build(...operations: Parameters<typeof createClientSurface>[0]) {
    return buildClientSurfaceDocument(
        createClientSurface(operations),
    ) as JsonObject;
}

function jsonBody(operation: JsonObject, status: string): JsonObject {
    return operation.responses[status].content["application/json"].schema;
}

describe("buildClientSurfaceDocument", () => {
    test("a named schema becomes a component referenced by $ref", () => {
        const document = build(getAlbum);
        const operation = document.paths["/api/library/albums/{id}"].get;

        expect(jsonBody(operation, "200")).toEqual({
            $ref: "#/components/schemas/DocumentTestAlbumSummary",
        });
        expect(jsonBody(operation, "404")).toEqual({
            $ref: "#/components/schemas/ApiError",
        });
        expect(document.components.schemas.ApiError).toEqual({
            type: "object",
            properties: {
                error: { type: "string" },
                code: { type: "string" },
            },
            required: ["error"],
            additionalProperties: false,
        });
        expect(operation.operationId).toBe("getAlbum");
        expect(operation.tags).toEqual(["library"]);
        expect(operation.summary).toBe("Get one album");
    });

    test("nested named schemas are components too", () => {
        const document = build(listAlbums);
        const { schemas } = document.components;

        expect(schemas.DocumentTestAlbumList.properties.albums.items).toEqual({
            $ref: "#/components/schemas/DocumentTestAlbumSummary",
        });
        expect(schemas.DocumentTestAlbumSummary.properties.artist).toEqual({
            $ref: "#/components/schemas/DocumentTestArtistRef",
        });
        expect(schemas.DocumentTestArtistRef.required).toEqual(["id", "name"]);
        expect(JSON.stringify(document)).not.toContain("#/definitions/");
    });

    test("fields convert as the serialisation rules say", () => {
        const schema =
            build(getAlbum).components.schemas.DocumentTestAlbumSummary;

        expect(schema.properties.year).toEqual(
            expect.objectContaining({ type: "integer", nullable: true }),
        );
        expect(schema.required).toContain("year");
        expect(schema.properties.playbackId).toEqual({ type: "string" });
        expect(schema.required).not.toContain("playbackId");
        expect(schema.properties.kind).toEqual({
            type: "string",
            enum: ["album", "single"],
        });
        expect(schema.properties.addedAt).toEqual(
            expect.objectContaining({ type: "string", format: "date-time" }),
        );
    });

    test("params, query and body become parameters and a request body", () => {
        const document = build(getAlbum, listAlbums, login);

        expect(
            document.paths["/api/library/albums/{id}"].get.parameters,
        ).toEqual([
            {
                name: "id",
                in: "path",
                required: true,
                schema: { type: "string" },
            },
        ]);
        expect(document.paths["/api/library/albums"].get.parameters).toEqual([
            {
                name: "limit",
                in: "query",
                required: false,
                schema: expect.objectContaining({ type: "integer" }),
            },
        ]);
        expect(document.paths["/api/auth/login"].post.requestBody).toEqual({
            required: true,
            content: {
                "application/json": {
                    schema: expect.objectContaining({
                        type: "object",
                        required: ["username", "password"],
                    }),
                },
            },
        });
    });

    test("a binary response has a media type and no schema; null has no body", () => {
        const operation = build(streamTrack).paths["/api/playback/stream"].get;

        expect(operation.responses["200"].content).toEqual({ "audio/*": {} });
        expect(operation.responses["200"].description).toEqual(
            expect.any(String),
        );
        expect(operation.responses["204"]).not.toHaveProperty("content");
        expect(operation.responses["204"].description).toEqual(
            expect.any(String),
        );
    });

    test("anonymous emits security: [] and authenticated operations inherit", () => {
        const document = build(login, getAlbum);

        expect(document.paths["/api/auth/login"].post.security).toEqual([]);
        expect(
            document.paths["/api/library/albums/{id}"].get,
        ).not.toHaveProperty("security");
    });

    test("two different schemas with the same component id throw", () => {
        const Other = z
            .object({ id: z.number() })
            .meta({ id: "DocumentTestArtistRef" });
        const clash = defineOperation({
            method: "get",
            path: "/api/library/artists",
            operationId: "listArtists",
            tag: "library",
            summary: "List artists",
            responses: { 200: z.object({ artists: z.array(Other) }) },
        });

        expect(() => build(listAlbums, clash)).toThrow(/DocumentTestArtistRef/);
    });
});

describe("mergeClientSurface", () => {
    const base = {
        openapi: "3.0.0",
        info: { title: "t", version: "1" },
        paths: {
            "/api/unrelated": {
                get: { summary: "untouched", responses: { 200: {} } },
            },
            "/api/library/albums/{id}": {
                delete: { summary: "comment-described sibling" },
                get: { summary: "replaced" },
            },
        },
        components: {
            schemas: { Error: { type: "object" } },
            securitySchemes: { bearerAuth: { type: "http" } },
        },
    };

    test("an empty surface leaves the document byte-for-byte unchanged", () => {
        const before = JSON.stringify(base);
        const merged = mergeClientSurface(base, createClientSurface([]));

        expect(JSON.stringify(merged)).toBe(before);
        expect(JSON.stringify(base)).toBe(before);
    });

    test("registered operations replace comment operations and keep unrelated paths", () => {
        const merged = mergeClientSurface(
            base,
            createClientSurface([getAlbum]),
        ) as JsonObject;

        expect(JSON.stringify(merged.paths["/api/unrelated"])).toBe(
            JSON.stringify(base.paths["/api/unrelated"]),
        );
        expect(merged.paths["/api/library/albums/{id}"].delete).toEqual({
            summary: "comment-described sibling",
        });
        expect(merged.paths["/api/library/albums/{id}"].get.operationId).toBe(
            "getAlbum",
        );
        expect(Object.keys(merged.components.schemas)).toEqual([
            "Error",
            "ApiError",
            "DocumentTestAlbumSummary",
            "DocumentTestArtistRef",
        ]);
        expect(merged.components.securitySchemes).toEqual(
            base.components.securitySchemes,
        );
        expect(base.paths["/api/library/albums/{id}"].get).toEqual({
            summary: "replaced",
        });
    });

    test("a registered component that clashes with a comment component throws", () => {
        const Error = z.object({ message: z.string() }).meta({ id: "Error" });
        const clash = defineOperation({
            method: "get",
            path: "/api/library/albums",
            operationId: "listAlbums",
            tag: "library",
            summary: "List albums",
            responses: { 200: Error },
        });

        expect(() =>
            mergeClientSurface(base, createClientSurface([clash])),
        ).toThrow(/Error/);
    });

    test("an empty surface leaves the comment document unchanged", () => {
        const swagger = require("../../config/swagger");
        const merged = mergeClientSurface(
            swagger.commentDocument,
            createClientSurface([]),
        );

        expect(JSON.stringify(merged)).toBe(
            JSON.stringify(swagger.commentDocument),
        );
    });

    test("the served document carries every registered operation", () => {
        const swagger = require("../../config/swagger");
        const { clientSurfaceOperations } = require("../clientSurface");

        for (const operation of clientSurfaceOperations) {
            expect(
                swagger.swaggerSpec.paths[operation.path][operation.method]
                    .operationId,
            ).toBe(operation.operationId);
        }
    });
});

describe("findDuplicateDescriptions", () => {
    test("reports a registered operation that still has a comment description", () => {
        const commentDocument = {
            paths: {
                "/api/library/albums/{albumId}": { get: { summary: "x" } },
                "/api/auth/login": { get: { summary: "other method" } },
            },
        };

        expect(
            findDuplicateDescriptions(
                commentDocument,
                createClientSurface([getAlbum, login]),
            ),
        ).toEqual(["GET /api/library/albums/{id}"]);
    });

    test("reports nothing when no registered operation is described", () => {
        expect(
            findDuplicateDescriptions(
                { paths: {} },
                createClientSurface([getAlbum]),
            ),
        ).toEqual([]);
    });
});
