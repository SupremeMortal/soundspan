jest.mock("../../config", () => ({ config: { port: 3006 } }));

const pkg = require("../../../package.json");

describe("openapi route sync", () => {
    beforeEach(() => {
        jest.resetModules();
    });

    test("every documented path is namespaced under /api, /health or /rest", () => {
        const { swaggerSpec } = require("../swagger");
        const keys = Object.keys(swaggerSpec.paths || {});
        const bad = keys.filter((k) => !/^\/(api|health|rest)(\/|$)/.test(k));

        expect(bad).toEqual([]);
    });

    test("formerly un-prefixed endpoints are documented at their mounted /api keys", () => {
        const { swaggerSpec } = require("../swagger");
        const keys = [
            "/api/api-keys",
            "/api/api-keys/{id}",
            "/api/auth/login",
            "/api/auth/me",
            "/api/library/scan",
            "/api/lyrics/{trackId}",
            "/api/mixes",
            "/api/mixes/{id}",
            "/api/search",
            "/api/listen-together",
            "/api/listen-together/join",
        ];

        for (const key of keys) {
            expect(swaggerSpec.paths).toHaveProperty([key]);
        }
    });

    test("no un-prefixed phantom duplicates remain", () => {
        const { swaggerSpec } = require("../swagger");
        const keys = [
            "/auth/login",
            "/auth/me",
            "/api-keys",
            "/api-keys/{id}",
            "/library/scan",
            "/lyrics/{trackId}",
            "/mixes",
            "/mixes/{id}",
            "/search",
            "/listen-together",
        ];

        for (const key of keys) {
            expect(swaggerSpec.paths).not.toHaveProperty([key]);
        }
    });

    test("info.version tracks the backend package version", () => {
        const { swaggerSpec } = require("../swagger");

        expect(swaggerSpec.info.version).toBe(pkg.version);
        expect(swaggerSpec.info.version).not.toBe("1.0.0");
    });

    function resolve(spec: any, schema: any): any {
        if (schema?.allOf?.length === 1) return resolve(spec, schema.allOf[0]);
        if (!schema?.$ref) return schema;
        return spec.components.schemas[schema.$ref.split("/").pop()];
    }

    function searchResponseProperty(spec: any, name: string): any {
        const response = resolve(
            spec,
            spec.paths["/api/search"].get.responses["200"].content[
                "application/json"
            ].schema,
        );
        return response.properties[name];
    }

    test("search documents the nullable remote track response shape", () => {
        const { swaggerSpec } = require("../swagger");
        const remoteTrackSchema = resolve(
            swaggerSpec,
            searchResponseProperty(swaggerSpec, "remoteTracks").items,
        );

        expect(remoteTrackSchema).not.toHaveProperty("allOf");
        expect(remoteTrackSchema.required).toEqual(
            expect.arrayContaining(["albumId", "trackNo", "album"]),
        );
        expect(remoteTrackSchema.properties).toEqual(
            expect.objectContaining({
                albumId: { type: "string", nullable: true },
                trackNo: expect.objectContaining({
                    type: "integer",
                    nullable: true,
                }),
            }),
        );
        for (const field of [
            "source",
            "streamSource",
            "tidalTrackId",
            "youtubeVideoId",
            "provider",
        ]) {
            expect(remoteTrackSchema.properties).not.toHaveProperty(field);
        }

        const album = resolve(swaggerSpec, remoteTrackSchema.properties.album);
        expect(album.required).toEqual(
            expect.arrayContaining(["id", "title", "coverArt"]),
        );
        expect(album.properties).toEqual(
            expect.objectContaining({
                id: { type: "string", nullable: true },
                title: { type: "string" },
                rgMbid: { type: "string", nullable: true },
                matchedRgMbid: { type: "string", nullable: true },
                matchedInLibrary: { type: "boolean" },
                coverArt: { type: "string", nullable: true },
            }),
        );
        const artist = resolve(swaggerSpec, album.properties.artist);
        expect(artist).toEqual(
            expect.objectContaining({
                required: ["id", "name"],
                properties: {
                    id: { type: "string", nullable: true },
                    name: { type: "string" },
                },
            }),
        );
    });

    test("search documents the per-user remote album response shape", () => {
        const { swaggerSpec } = require("../swagger");
        const description = swaggerSpec.paths["/api/search"].get
            .description as string;
        const remoteAlbumSchema = resolve(
            swaggerSpec,
            searchResponseProperty(swaggerSpec, "remoteAlbums").items,
        );

        expect(description).toContain("per user");
        expect(description).toContain("not cached");
        expect(remoteAlbumSchema.required).toEqual([
            "id",
            "title",
            "artistId",
            "year",
            "coverUrl",
            "source",
            "remoteSources",
            "artist",
        ]);
        expect(remoteAlbumSchema.properties.source).toEqual({
            type: "string",
            enum: ["remote"],
        });
        expect(
            resolve(
                swaggerSpec,
                remoteAlbumSchema.properties.remoteSources.items,
            ),
        ).toEqual(
            expect.objectContaining({
                type: "string",
                enum: ["tidal", "youtube"],
            }),
        );
        expect(
            resolve(swaggerSpec, remoteAlbumSchema.properties.artist),
        ).toEqual(
            expect.objectContaining({
                required: ["id", "name"],
                properties: {
                    id: { type: "string" },
                    name: { type: "string" },
                    mbid: { type: "string", nullable: true },
                },
            }),
        );
    });

    test("album detail documents matched library state", () => {
        const { swaggerSpec } = require("../swagger");
        const operation = swaggerSpec.paths["/api/library/albums/{id}"].get;
        const ref =
            operation.responses["200"].content["application/json"].schema.$ref;

        expect(operation.operationId).toBe("getAlbum");
        expect(ref).toBe("#/components/schemas/AlbumDetail");
        const albumSchema =
            swaggerSpec.components.schemas[ref.split("/").pop() as string];
        expect(albumSchema.properties).toEqual(
            expect.objectContaining({
                matchedRgMbid: expect.objectContaining({
                    type: "string",
                    nullable: true,
                }),
                matchedInLibrary: expect.objectContaining({
                    type: "boolean",
                }),
            }),
        );
        expect(albumSchema.required).toEqual(
            expect.arrayContaining(["matchedRgMbid", "matchedInLibrary"]),
        );
    });
});
