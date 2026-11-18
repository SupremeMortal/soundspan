import { clientSurfaceOperations } from "../clientSurface";
import { renderClientSurfaceSpec } from "../emit";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

function emitted(): JsonObject {
    return JSON.parse(
        renderClientSurfaceSpec(clientSurfaceOperations, "0.0.0-test"),
    ) as JsonObject;
}

function operation(path: string, method: string): JsonObject {
    const item = emitted().paths[path] as JsonObject | undefined;
    if (!item?.[method]) throw new Error(`${method} ${path} is not emitted`);
    return item[method] as JsonObject;
}

function jsonSchema(path: string, method: string, status: number): JsonObject {
    return operation(path, method).responses[String(status)].content[
        "application/json"
    ].schema;
}

function bodyProperties(path: string, method: string): string[] {
    const ref: string = operation(path, method).requestBody.content[
        "application/json"
    ].schema.$ref;
    const name = ref.replace("#/components/schemas/", "");
    return Object.keys(emitted().components.schemas[name].properties).sort();
}

describe("settings, preference, shuffle and playlist write operations in the emitted client spec", () => {
    test.each([
        ["/api/settings", "get", "getSettings", "session"],
        ["/api/settings", "post", "updateSettings", "session"],
        ["/api/library/preferences", "post", "setTrackPreference", "library"],
        [
            "/api/library/albums/{id}/preference",
            "post",
            "setAlbumPreference",
            "library",
        ],
        ["/api/library/tracks/shuffle", "get", "listShuffledTracks", "library"],
        ["/api/playlists", "post", "createPlaylist", "playlists"],
        ["/api/playlists/{id}", "put", "updatePlaylist", "playlists"],
        ["/api/playlists/{id}", "delete", "deletePlaylist", "playlists"],
        ["/api/playlists/{id}/items", "post", "addPlaylistItem", "playlists"],
        [
            "/api/playlists/{id}/items/{playbackId}",
            "delete",
            "removePlaylistItem",
            "playlists",
        ],
        [
            "/api/playlists/{id}/items/reorder",
            "put",
            "reorderPlaylistItems",
            "playlists",
        ],
    ])("%s %s is %s under %s", (path, method, operationId, tag) => {
        const emittedOperation = operation(path, method);

        expect(emittedOperation.operationId).toBe(operationId);
        expect(emittedOperation.tags).toEqual([tag]);
    });

    test("settings declare the playback fields with their accepted values", () => {
        const settings = emitted().components.schemas.UserSettings;

        expect(settings.properties.playbackQuality).toEqual({
            $ref: "#/components/schemas/PlaybackQuality",
        });
        expect(emitted().components.schemas.LoudnessMode.enum).toEqual([
            "off",
            "track",
            "album",
            "auto",
        ]);
        expect(settings.properties.maxCacheSizeMb.type).toBe("integer");
        expect(bodyProperties("/api/settings", "post")).toEqual([
            "loudnessMode",
            "maxCacheSizeMb",
            "playbackQuality",
        ]);
    });

    test("write bodies declare only the playbackId forms", () => {
        expect(bodyProperties("/api/library/preferences", "post")).toEqual([
            "metadata",
            "playbackId",
            "signal",
        ]);
        expect(bodyProperties("/api/playlists/{id}/items", "post")).toEqual([
            "metadata",
            "playbackId",
        ]);
        expect(
            bodyProperties("/api/playlists/{id}/items/reorder", "put"),
        ).toEqual(["playbackIds"]);
    });

    test("the track preference answer carries state, likedAt and playbackId", () => {
        const answer = emitted().components.schemas.TrackPreferenceResponse;

        expect(answer.required).toEqual(
            expect.arrayContaining(["state", "likedAt", "playbackId"]),
        );
        expect(answer.properties.likedAt.nullable).toBe(true);
    });

    test("addPlaylistItem answers the item, or the item already in the playlist", () => {
        const schema = jsonSchema("/api/playlists/{id}/items", "post", 200);
        const variants = (schema.oneOf ?? schema.anyOf) as JsonObject[];

        expect(variants).toEqual(
            expect.arrayContaining([
                { $ref: "#/components/schemas/PlaylistItem" },
                { $ref: "#/components/schemas/PlaylistItemDuplicate" },
            ]),
        );
    });

    test("shuffle reuses TrackSummary", () => {
        const answer = emitted().components.schemas.ShuffledTracksResponse;

        expect(answer.properties.tracks.items).toEqual({
            $ref: "#/components/schemas/TrackSummary",
        });
    });

    test.each([
        ["/api/settings", "post", [400]],
        ["/api/library/preferences", "post", [400, 404, 409]],
        ["/api/library/albums/{id}/preference", "post", [400, 404, 422]],
        ["/api/playlists", "post", [400]],
        ["/api/playlists/{id}", "put", [400, 403, 404]],
        ["/api/playlists/{id}", "delete", [403, 404]],
        ["/api/playlists/{id}/items", "post", [400, 403, 404, 409]],
        ["/api/playlists/{id}/items/{playbackId}", "delete", [403, 404]],
        ["/api/playlists/{id}/items/reorder", "put", [400, 403, 404]],
    ])(
        "%s %s declares the error statuses %j as ApiError",
        (path, method, statuses) => {
            for (const status of [401, ...statuses]) {
                expect(jsonSchema(path, method, status)).toEqual({
                    $ref: "#/components/schemas/ApiError",
                });
            }
        },
    );
});
