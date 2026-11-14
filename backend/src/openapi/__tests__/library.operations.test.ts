import { clientSurfaceOperations, getOperation } from "../clientSurface";
import { renderClientSurfaceSpec } from "../emit";
import { checkClientSurfaceResponse } from "../responseValidation";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

function emitted(): JsonObject {
    return JSON.parse(
        renderClientSurfaceSpec(clientSurfaceOperations, "0.0.0-test"),
    ) as JsonObject;
}

function track(overrides: JsonObject = {}): JsonObject {
    return {
        id: "track-1",
        title: "Track",
        duration: 200,
        trackNo: 1,
        discNo: 1,
        ...overrides,
    };
}

function albumDetail(tracks: JsonObject[]): JsonObject {
    return {
        id: "album-1",
        title: "Album",
        year: 2020,
        coverArt: null,
        artistId: "artist-1",
        rgMbid: null,
        source: "local",
        artist: { id: "artist-1", name: "Artist", mbid: null },
        owned: true,
        matchedRgMbid: null,
        matchedInLibrary: false,
        tracks,
    };
}

describe("library operations in the emitted client spec", () => {
    test("the JSON browse operations are emitted under the library tag", () => {
        const library = Object.values(emitted().paths as JsonObject)
            .flatMap((item) => Object.values(item as JsonObject))
            .filter((operation: JsonObject) =>
                operation.tags.includes("library"),
            )
            .map((operation: JsonObject) => operation.operationId)
            .sort();

        expect(library).toEqual([
            "getAlbum",
            "getArtist",
            "listAlbums",
            "listArtists",
            "listLikedTracks",
            "listRecentlyAdded",
            "listRecentlyListened",
            "listTracks",
        ]);
    });

    test("the cover-art operations stay out of the emitted file", () => {
        const paths = Object.keys(emitted().paths as JsonObject);

        expect(paths).not.toContain("/api/library/cover-art");
        expect(paths).not.toContain("/api/library/cover-art/{id}");
    });

    test("the summary components are named", () => {
        const components = Object.keys(emitted().components.schemas);

        expect(components).toEqual(
            expect.arrayContaining([
                "ArtistSummary",
                "ArtistDetail",
                "ArtistListResponse",
                "AlbumSummary",
                "AlbumDetail",
                "AlbumListResponse",
                "TrackSummary",
                "LibraryTrack",
                "LibraryTrackListResponse",
                "LikedTrack",
                "LikedTracksResponse",
                "RecentlyListenedItem",
                "RecentlyAddedArtist",
            ]),
        );
    });

    test("listArtists declares exactly the inventory query parameters", () => {
        const parameters = emitted().paths["/api/library/artists"].get
            .parameters as JsonObject[];

        expect(parameters.map((p) => p.name).sort()).toEqual(
            [
                "cursor",
                "filter",
                "limit",
                "offset",
                "origin",
                "query",
                "sortBy",
            ].sort(),
        );
    });

    test.each(["TrackSummary", "LibraryTrack", "LikedTrack"])(
        "%s never declares provider-specific fields",
        (component) => {
            const track = emitted().components.schemas[component];

            for (const field of [
                "streamSource",
                "tidalTrackId",
                "youtubeVideoId",
                "provider",
            ]) {
                expect(track.properties).not.toHaveProperty(field);
            }
            expect(track.required).not.toContain("playbackId");
        },
    );

    test.each([
        [
            "/api/library/tracks",
            ["albumId", "limit", "offset", "origin", "sortBy"],
        ],
        ["/api/library/liked", ["cursorLikedAt", "cursorTrackId", "limit"]],
        ["/api/library/recently-listened", ["limit"]],
        ["/api/library/recently-added", ["limit"]],
    ])("%s declares exactly the inventory query parameters", (path, names) => {
        const parameters = emitted().paths[path].get.parameters as JsonObject[];

        expect(parameters.map((p) => p.name).sort()).toEqual(names);
    });
});

describe("cover-art operations in the served document", () => {
    test("both paths answer an image and declare their JSON errors", () => {
        for (const operationId of ["getCoverArt", "getCoverArtByUrl"]) {
            const operation = getOperation(operationId);

            expect(operation.responses[200]).toEqual({ binary: "image/*" });
            expect(
                checkClientSurfaceResponse(operation, 404, {
                    error: "Cover art not found",
                }),
            ).toEqual({ ok: true });
            expect(
                checkClientSurfaceResponse(operation, 200, Buffer.from("img")),
            ).toEqual({ ok: true });
        }
    });
});

describe("liked tracks validation", () => {
    test("a next cursor without its track id fails", () => {
        const check = checkClientSurfaceResponse(
            getOperation("listLikedTracks"),
            200,
            {
                playlist: { id: "my-liked", name: "My Liked", description: "" },
                tracks: [],
                total: 0,
                pagination: {
                    limit: 1,
                    hasMore: true,
                    nextCursor: { likedAt: "2026-01-01T00:00:00.000Z" },
                },
            },
        );

        expect(check).toMatchObject({
            ok: false,
            path: "$.pagination.nextCursor.trackId",
        });
    });
});

describe("detail track validation", () => {
    test("an album track with a wrong duration type fails", () => {
        const check = checkClientSurfaceResponse(
            getOperation("getAlbum"),
            200,
            albumDetail([track({ duration: "200" })]),
        );

        expect(check).toMatchObject({
            ok: false,
            path: "$.tracks[0].duration",
        });
    });
});
