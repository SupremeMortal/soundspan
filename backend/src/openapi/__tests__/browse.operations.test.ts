import { clientSurfaceOperations } from "../clientSurface";
import { renderClientSurfaceSpec } from "../emit";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

function emitted(): JsonObject {
    return JSON.parse(
        renderClientSurfaceSpec(clientSurfaceOperations, "0.0.0-test"),
    ) as JsonObject;
}

function operationIdsByTag(spec: JsonObject, tag: string): string[] {
    return Object.values(spec.paths as JsonObject)
        .flatMap((item) => Object.values(item as JsonObject))
        .filter((operation: JsonObject) => operation.tags.includes(tag))
        .map((operation: JsonObject) => operation.operationId)
        .sort();
}

/** Every property name declared anywhere under `value`. */
function propertyNames(value: unknown, out = new Set<string>()): Set<string> {
    if (Array.isArray(value)) {
        value.forEach((child) => propertyNames(child, out));
    } else if (typeof value === "object" && value !== null) {
        const record = value as JsonObject;
        if (
            typeof record.properties === "object" &&
            record.properties !== null
        ) {
            Object.keys(record.properties).forEach((name) => out.add(name));
        }
        Object.values(record).forEach((child) => propertyNames(child, out));
    }
    return out;
}

describe("playlist, search and home-shelf operations in the emitted client spec", () => {
    test.each([
        ["playlists", ["getPlaylist", "listPlaylists"]],
        ["search", ["search", "searchDiscover"]],
        ["discovery", ["listMixes"]],
        ["podcasts", ["listTopPodcasts"]],
    ])("the %s tag holds exactly %j", (tag, operationIds) => {
        expect(operationIdsByTag(emitted(), tag)).toEqual(operationIds);
    });

    test("no schema in the file declares a provider-specific field", () => {
        const names = propertyNames(emitted());

        expect(names.has("streamSource")).toBe(false);
        expect(names.has("tidalTrackId")).toBe(false);
        expect(names.has("youtubeVideoId")).toBe(false);
    });

    test("the response components are named", () => {
        expect(Object.keys(emitted().components.schemas)).toEqual(
            expect.arrayContaining([
                "PlaylistSummary",
                "PlaylistDetail",
                "PlaylistItem",
                "SearchResponse",
                "SearchRemoteTrack",
                "SearchRemoteAlbum",
                "DiscoverSearchResponse",
                "MixSummary",
                "PodcastSummary",
            ]),
        );
    });

    test("listMixes declares the feature-disabled 404 as ApiError", () => {
        const response =
            emitted().paths["/api/mixes"].get.responses["404"].content[
                "application/json"
            ].schema;

        expect(response).toEqual({ $ref: "#/components/schemas/ApiError" });
    });

    test.each([
        ["/api/playlists", ["limit", "offset"]],
        ["/api/search", ["genre", "limit", "offset", "q", "source", "type"]],
        ["/api/search/discover", ["limit", "q", "type"]],
        ["/api/podcasts/discover/top", ["limit"]],
    ])("%s declares the query parameters %j", (path, names) => {
        const parameters = emitted().paths[path].get.parameters as JsonObject[];

        expect(parameters.map((parameter) => parameter.name).sort()).toEqual(
            names,
        );
    });
});
