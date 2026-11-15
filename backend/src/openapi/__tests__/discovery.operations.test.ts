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

function component(spec: JsonObject, id: string): JsonObject {
    return spec.components.schemas[id] as JsonObject;
}

function operation(spec: JsonObject, method: string, path: string) {
    return spec.paths[path][method] as JsonObject;
}

const PROVIDER_FIELDS = ["streamSource", "tidalTrackId", "youtubeVideoId"];

describe("discovery operations in the emitted client spec", () => {
    test("the discovery tag holds the mixes, discover, recommendation, radio and vibe operations", () => {
        expect(operationIdsByTag(emitted(), "discovery")).toEqual([
            "getCurrentDiscover",
            "getMix",
            "getRadio",
            "getRecommendationsForYou",
            "getSimilarTracks",
            "listMixes",
            "listPopularArtists",
            "listRadioDecades",
            "listRadioGenres",
            "searchVibe",
        ]);
    });

    test("the genre and decade lists sit at their mounted library paths", () => {
        const spec = emitted();

        expect(operation(spec, "get", "/api/library/genres").operationId).toBe(
            "listRadioGenres",
        );
        expect(operation(spec, "get", "/api/library/decades").operationId).toBe(
            "listRadioDecades",
        );
        expect(spec.paths["/api/library/radio/genres"]).toBeUndefined();
    });

    test.each([
        ["get", "/api/mixes/{id}"],
        ["get", "/api/recommendations/for-you"],
        ["get", "/api/discover/current"],
        ["get", "/api/discover/popular-artists"],
        ["get", "/api/vibe/similar/{trackId}"],
        ["post", "/api/vibe/search"],
    ])("feature-gated %s %s declares a 404", (method, path) => {
        const responses = operation(emitted(), method, path).responses;

        expect(Object.keys(responses)).toContain("404");
    });

    test("getRadio takes the radio type as an enum", () => {
        const spec = emitted();
        const type = operation(
            spec,
            "get",
            "/api/library/radio",
        ).parameters.find((parameter: JsonObject) => parameter.name === "type");

        expect(type.in).toBe("query");
        expect(type.required).toBe(true);
        expect(type.schema.$ref).toBe("#/components/schemas/RadioType");
        expect(component(spec, "RadioType").enum).toEqual(
            expect.arrayContaining([
                "all",
                "liked",
                "genre",
                "decade",
                "artist",
                "artist-name",
                "vibe",
                "playlist",
                "tracks",
            ]),
        );
    });

    test("searchVibe declares its request body", () => {
        const body = component(emitted(), "VibeSearchRequest");

        expect(body.required).toEqual(["query"]);
        expect(body.properties.query).toMatchObject({
            type: "string",
            minLength: 2,
            maxLength: 512,
        });
    });

    test("no discovery track shape declares a provider field", () => {
        const spec = emitted();
        for (const id of [
            "MixDetail",
            "DiscoverTrack",
            "RadioTrack",
            "SimilarTrack",
            "VibeSearchTrack",
        ]) {
            const properties = Object.keys(component(spec, id).properties);
            for (const field of PROVIDER_FIELDS) {
                expect(properties).not.toContain(field);
            }
        }
    });
});
