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
});
