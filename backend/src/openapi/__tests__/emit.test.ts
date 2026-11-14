import { z } from "zod";
import { createClientSurface } from "../clientSurface";
import { defineOperation } from "../defineOperation";
import { renderClientSurfaceSpec } from "../emit";
import { ApiError, standardErrors } from "../schemas/common";

type JsonObject = Record<string, any>;

const ArtistRef = z
    .object({ name: z.string(), id: z.string() })
    .meta({ id: "EmitTestArtistRef" });

const AlbumSummary = z
    .object({
        title: z.string(),
        id: z.string(),
        year: z.number().int().nullable(),
        artist: ArtistRef,
    })
    .meta({ id: "EmitTestAlbumSummary" });

const AlbumSummaryReordered = z
    .object({
        artist: ArtistRef,
        year: z.number().int().nullable(),
        id: z.string(),
        title: z.string(),
    })
    .meta({ id: "EmitTestAlbumSummary" });

const albumList = (summary: z.ZodType) =>
    z.object({ albums: z.array(summary) }).meta({ id: "EmitTestAlbumList" });

const StreamQuery = z
    .object({ playbackId: z.string() })
    .meta({ id: "EmitTestStreamQuery" });

const listAlbumsWith = (summary: z.ZodType) =>
    defineOperation({
        method: "get",
        path: "/api/library/albums",
        operationId: "listAlbums",
        tag: "library",
        summary: "List albums",
        responses: { 200: albumList(summary), ...standardErrors },
    });

const listAlbums = listAlbumsWith(AlbumSummary);

const getAlbum = (schema: z.ZodType) =>
    defineOperation({
        method: "get",
        path: "/api/library/albums/{id}",
        operationId: "getAlbum",
        tag: "library",
        summary: "Get one album",
        params: z.object({ id: z.string() }),
        responses: { 200: schema, 404: ApiError },
    });

const streamTrack = defineOperation({
    method: "get",
    path: "/api/playback/stream",
    operationId: "streamTrack",
    tag: "playback",
    summary: "Stream a track",
    query: StreamQuery,
    responses: { 200: { binary: "audio/*" }, 404: ApiError },
});

const coverArt = defineOperation({
    method: "get",
    path: "/api/library/cover-art/{id}",
    operationId: "getCoverArt",
    tag: "library",
    summary: "Cover art",
    params: z.object({ id: z.string() }),
    responses: { 206: { binary: "image/*" }, 404: ApiError },
});

const VERSION = "9.8.7";

function render(...operations: Parameters<typeof createClientSurface>[0]) {
    return renderClientSurfaceSpec(createClientSurface(operations), VERSION);
}

function parse(text: string): JsonObject {
    return JSON.parse(text) as JsonObject;
}

describe("renderClientSurfaceSpec", () => {
    it("is byte-identical across renders", () => {
        expect(render(listAlbums, getAlbum(AlbumSummary))).toBe(
            render(listAlbums, getAlbum(AlbumSummary)),
        );
    });

    it("does not depend on operation order or schema key order", () => {
        const forward = render(listAlbums, getAlbum(AlbumSummary));
        const reordered = render(
            getAlbum(AlbumSummaryReordered),
            listAlbumsWith(AlbumSummaryReordered),
        );
        expect(reordered).toBe(forward);
    });

    it("sorts every object key and every required list", () => {
        const text = render(
            listAlbumsWith(AlbumSummaryReordered),
            getAlbum(AlbumSummaryReordered),
        );
        const visit = (value: unknown, key?: string) => {
            if (Array.isArray(value)) {
                if (key === "required") {
                    expect(value).toEqual([...value].sort());
                }
                value.forEach((child) => visit(child));
                return;
            }
            if (typeof value !== "object" || value === null) return;
            const keys = Object.keys(value);
            expect(keys).toEqual([...keys].sort());
            for (const [childKey, child] of Object.entries(value)) {
                visit(child, childKey);
            }
        };
        visit(parse(text));
        const album = parse(text).components.schemas.EmitTestAlbumSummary;
        expect(album.required).toEqual(["artist", "id", "title", "year"]);
        // Status codes and property names appear in the text in sorted order.
        expect(text.indexOf('"200"')).toBeLessThan(text.indexOf('"401"'));
        expect(text.indexOf('"artist"')).toBeLessThan(text.indexOf('"title"'));
    });

    it("writes the document envelope with no servers or security schemes", () => {
        const document = parse(render(listAlbums));
        expect(document.openapi).toBe("3.0.0");
        expect(document.info).toEqual({
            title: "soundspan client surface",
            version: VERSION,
        });
        expect(Object.keys(document).sort()).toEqual([
            "components",
            "info",
            "openapi",
            "paths",
        ]);
        expect(Object.keys(document.components)).toEqual(["schemas"]);
    });

    it("keeps only referenced components, transitively", () => {
        const document = parse(render(listAlbums, streamTrack));
        expect(Object.keys(document.components.schemas).sort()).toEqual([
            "ApiError",
            "EmitTestAlbumList",
            "EmitTestAlbumSummary",
            "EmitTestArtistRef",
        ]);
    });

    it("leaves out operations with a binary success response", () => {
        const document = parse(render(listAlbums, streamTrack, coverArt));
        expect(Object.keys(document.paths)).toEqual(["/api/library/albums"]);
        expect(document.paths["/api/library/albums"].get.operationId).toBe(
            "listAlbums",
        );
        expect(document.components.schemas.EmitTestStreamQuery).toBeUndefined();
    });

    it("renders an empty surface as empty paths and schemas", () => {
        expect(parse(render())).toEqual({
            components: { schemas: {} },
            info: { title: "soundspan client surface", version: VERSION },
            openapi: "3.0.0",
            paths: {},
        });
    });

    it("uses two-space indentation and ends with exactly one newline", () => {
        const text = render(listAlbums);
        expect(text.endsWith("}\n")).toBe(true);
        expect(text.endsWith("\n\n")).toBe(false);
        expect(text).toBe(`${JSON.stringify(parse(text), null, 2)}\n`);
    });
});
