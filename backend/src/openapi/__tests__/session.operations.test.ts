import { clientSurfaceOperations } from "../clientSurface";
import { renderClientSurfaceSpec } from "../emit";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

type JsonObject = Record<string, any>;

const ANONYMOUS = [
    ["get", "/api/health"],
    ["get", "/api/auth/config"],
    ["get", "/api/onboarding/status"],
    ["post", "/api/auth/login"],
    ["post", "/api/auth/refresh"],
    ["post", "/api/auth/logout"],
] as const;

const AUTHENTICATED = [
    ["get", "/api/auth/me"],
    ["get", "/api/docs.json"],
    ["get", "/api/system/features"],
] as const;

describe("session operations in the merged document", () => {
    let document: JsonObject;

    beforeAll(() => {
        document = require("../../config/swagger").swaggerSpec;
    });

    test("login answers 200 with a oneOf of the token response and the 2FA challenge", () => {
        const schema =
            document.paths["/api/auth/login"].post.responses["200"].content[
                "application/json"
            ].schema;

        expect(schema).toEqual({
            oneOf: [
                { $ref: "#/components/schemas/LoginTokenResponse" },
                { $ref: "#/components/schemas/LoginTwoFactorChallenge" },
            ],
        });
    });

    test.each(ANONYMOUS)("%s %s is anonymous", (method, path) => {
        const operation = document.paths[path][method];

        expect(operation.tags).toEqual(["session"]);
        expect(operation.security).toEqual([]);
    });

    test.each(AUTHENTICATED)(
        "%s %s keeps the document's default security",
        (method, path) => {
            const operation = document.paths[path][method];

            expect(operation.tags).toEqual(["session"]);
            expect(operation).not.toHaveProperty("security");
        },
    );
});

describe("session operations in the emitted client spec", () => {
    test("all nine operationIds are emitted under the session tag", () => {
        const emitted = JSON.parse(
            renderClientSurfaceSpec(clientSurfaceOperations, "0.0.0-test"),
        ) as JsonObject;
        const session = Object.values(emitted.paths as JsonObject)
            .flatMap((item) => Object.values(item as JsonObject))
            .filter((operation: JsonObject) =>
                operation.tags.includes("session"),
            )
            .map((operation: JsonObject) => operation.operationId)
            .sort();

        expect(session).toEqual([
            "getApiDocument",
            "getAuthConfig",
            "getCurrentUser",
            "getHealth",
            "getOnboardingStatus",
            "getSystemFeatures",
            "login",
            "logout",
            "refreshSession",
        ]);
    });
});
