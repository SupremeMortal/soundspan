import express from "express";
import request from "supertest";
import { clientSurfaceOperations } from "../clientSurface";
import { validateClientSurfaceResponses } from "../responseValidation";
import { createFeatureDisabledHandler } from "../../utils/featureGate";

jest.mock("../../config", () => ({ config: { port: 3006 } }));

describe("a feature-disabled mount of a registered operation", () => {
    it("answers GET /api/mixes with a 404 that validates as ApiError for listMixes", async () => {
        const app = express();
        app.use(
            validateClientSurfaceResponses({
                operations: clientSurfaceOperations,
                onMismatch: "throw",
            }),
        );
        app.use("/api/mixes", createFeatureDisabledHandler());

        const res = await request(app).get("/api/mixes");

        expect(res.status).toBe(404);
        expect(res.body).toEqual({
            error: "feature disabled",
            code: "FEATURE_DISABLED",
        });
    });

    it.each([
        ["/api/mixes", "get", "/api/mixes/mix-1", "getMix"],
        [
            "/api/recommendations",
            "get",
            "/api/recommendations/for-you",
            "getRecommendationsForYou",
        ],
        ["/api/discover", "get", "/api/discover/current", "getCurrentDiscover"],
        ["/api/vibe", "post", "/api/vibe/search", "searchVibe"],
    ] as const)(
        "answers %s with a 404 that validates as ApiError (%s %s, %s)",
        async (prefix, method, path, operationId) => {
            const app = express();
            app.use(express.json());
            app.use(
                validateClientSurfaceResponses({
                    operations: clientSurfaceOperations,
                    onMismatch: "throw",
                }),
            );
            app.use(prefix, createFeatureDisabledHandler());

            const res = await request(app)[method](path).send();

            expect(clientSurfaceOperations.map((o) => o.operationId)).toContain(
                operationId,
            );
            expect(res.status).toBe(404);
            expect(res.body).toEqual({
                error: "feature disabled",
                code: "FEATURE_DISABLED",
            });
        },
    );
});
