import { pathShape, toOpenApiPaths } from "../expressPath";

describe("toOpenApiPaths", () => {
    test("converts a plain parameter", () => {
        expect(toOpenApiPaths("/albums/:id")).toEqual(["/albums/{id}"]);
    });

    test("converts two parameters", () => {
        expect(toOpenApiPaths("/albums/:albumId/tracks/:trackId")).toEqual([
            "/albums/{albumId}/tracks/{trackId}",
        ]);
    });

    test("expands an optional group to both paths", () => {
        expect(toOpenApiPaths("/cover-art{/:id}")).toEqual([
            "/cover-art",
            "/cover-art/{id}",
        ]);
    });

    test("leaves a path without parameters alone", () => {
        expect(toOpenApiPaths("/albums")).toEqual(["/albums"]);
    });
});

describe("pathShape", () => {
    test("is equal across different parameter names", () => {
        expect(pathShape("/albums/{id}")).toBe(pathShape("/albums/{albumId}"));
        expect(pathShape("/albums/{id}/tracks/{trackId}")).toBe(
            "/albums/{}/tracks/{}",
        );
    });

    test("differs when literal segments differ", () => {
        expect(pathShape("/albums/{id}")).not.toBe(pathShape("/artists/{id}"));
    });
});
