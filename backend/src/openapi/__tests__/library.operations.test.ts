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
    test("the four browse operations are emitted under the library tag", () => {
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
        ]);
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

    test("track shapes never declare provider-specific fields", () => {
        const track = emitted().components.schemas.TrackSummary;

        for (const field of [
            "streamSource",
            "tidalTrackId",
            "youtubeVideoId",
        ]) {
            expect(track.properties).not.toHaveProperty(field);
        }
        expect(track.required).not.toContain("playbackId");
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
