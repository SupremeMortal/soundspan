jest.mock("../../config", () => ({ config: { port: 3006 } }));

type RequestSchema = {
    required?: string[];
    properties?: Record<string, unknown>;
};

type Operation = {
    description?: string;
    requestBody: {
        content: { "application/json": { schema: { $ref?: string } } };
    };
};

function mergedOperation(path: string, method: "post" | "put"): Operation {
    const { swaggerSpec } = require("../swagger");
    const operation = swaggerSpec.paths?.[path]?.[method] as
        | Operation
        | undefined;

    expect(operation).toBeDefined();
    return operation as Operation;
}

/** The named component a request body references. */
function bodyComponent(operation: Operation): RequestSchema {
    const { swaggerSpec } = require("../swagger");
    const ref = operation.requestBody.content["application/json"].schema.$ref;

    expect(ref).toMatch(/^#\/components\/schemas\//);
    const name = (ref as string).replace("#/components/schemas/", "");
    return swaggerSpec.components.schemas[name] as RequestSchema;
}

describe("remote-media OpenAPI request contracts", () => {
    test("play logging documents the playbackId form and names the legacy forms", () => {
        const operation = mergedOperation("/api/plays", "post");
        const schema = bodyComponent(operation);

        expect(
            operation.requestBody.content["application/json"].schema,
        ).toEqual({ $ref: "#/components/schemas/RecordPlayRequest" });
        expect(schema.required).toEqual(["playbackId"]);
        expect(Object.keys(schema.properties ?? {}).sort()).toEqual([
            "listenedMs",
            "metadata",
            "playbackId",
            "playedAt",
        ]);
        expect(operation.description).toContain("`tidalTrackId`");
        expect(operation.description).toContain("`youtubeVideoId`");
    });

    test("playlist add documents the playbackId form and names the legacy forms", () => {
        const operation = mergedOperation("/api/playlists/{id}/items", "post");
        const schema = bodyComponent(operation);

        expect(schema.required).toEqual(["playbackId"]);
        expect(Object.keys(schema.properties ?? {}).sort()).toEqual([
            "metadata",
            "playbackId",
        ]);
        expect(operation.description).toContain("`trackId`");
        expect(operation.description).toContain("`tidalTrackId`");
        expect(operation.description).toContain("`youtubeVideoId`");
    });

    test("playlist reorder documents playbackIds and names the legacy arrays", () => {
        const operation = mergedOperation(
            "/api/playlists/{id}/items/reorder",
            "put",
        );
        const schema = bodyComponent(operation);

        expect(schema.required).toEqual(["playbackIds"]);
        expect(Object.keys(schema.properties ?? {})).toEqual(["playbackIds"]);
        expect(operation.description).toContain("`itemIds`");
        expect(operation.description).toContain("`trackIds`");
    });
});
