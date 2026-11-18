import { z } from "zod";
import { CLIENT_SURFACE_TAGS, defineOperation } from "../defineOperation";
import { ApiError, standardErrors } from "../schemas/common";

const AlbumDetail = z
    .object({ id: z.string(), title: z.string() })
    .meta({ id: "DefineOperationTestAlbumDetail" });

function validInput() {
    return {
        method: "get" as const,
        path: "/api/library/albums/{id}",
        operationId: "getAlbum",
        tag: "library" as const,
        summary: "Get one album",
        params: z.object({ id: z.string() }),
        responses: { 200: AlbumDetail, 404: ApiError, ...standardErrors },
    };
}

describe("defineOperation", () => {
    test("fixes the client surface tag list", () => {
        expect(CLIENT_SURFACE_TAGS).toEqual([
            "session",
            "library",
            "playlists",
            "search",
            "playback",
            "offline",
            "podcasts",
            "discovery",
            "listenTogether",
            "social",
        ]);
    });

    test("accepts the design document example", () => {
        const operation = defineOperation(validInput());

        expect(operation.operationId).toBe("getAlbum");
        expect(operation.tag).toBe("library");
        expect(Object.keys(operation.responses)).toEqual([
            "200",
            "401",
            "404",
            "500",
            "503",
        ]);
    });

    test("accepts binary and empty responses", () => {
        expect(() =>
            defineOperation({
                method: "get",
                path: "/api/playback/stream",
                operationId: "streamTrack",
                tag: "playback",
                summary: "Stream a track",
                responses: { 200: { binary: "audio/*" }, 204: null },
            }),
        ).not.toThrow();
    });

    test("rejects an unknown tag", () => {
        expect(() =>
            defineOperation({
                ...validInput(),
                tag: "admin" as never,
            }),
        ).toThrow(/tag/);
    });

    test.each(["GetAlbum", "get_album", "get-album", "1album", ""])(
        "rejects the non-camelCase operationId %p",
        (operationId) => {
            expect(() =>
                defineOperation({ ...validInput(), operationId }),
            ).toThrow(/operationId/);
        },
    );

    test.each(["/library/albums/{id}", "/health", "api/library/albums/{id}"])(
        "rejects the path %p outside /api/",
        (path) => {
            expect(() => defineOperation({ ...validInput(), path })).toThrow(
                /path/,
            );
        },
    );

    test("rejects a path parameter missing from params", () => {
        expect(() =>
            defineOperation({ ...validInput(), params: undefined }),
        ).toThrow(/id/);
        expect(() =>
            defineOperation({
                ...validInput(),
                params: z.object({ albumId: z.string() }),
            }),
        ).toThrow(/id/);
    });

    test("rejects a params key that is not in the path", () => {
        expect(() =>
            defineOperation({
                ...validInput(),
                params: z.object({ id: z.string(), extra: z.string() }),
            }),
        ).toThrow(/extra/);
    });

    test("rejects empty responses", () => {
        expect(() =>
            defineOperation({ ...validInput(), responses: {} }),
        ).toThrow(/responses/);
    });
});
