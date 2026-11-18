import express, { Router } from "express";
import { clientSurfaceOperations } from "../../../openapi/clientSurface";
import { validateClientSurfaceResponses } from "../../../openapi/responseValidation";

export function createRouteTestApp(basePath: string, router: Router) {
    const app = express();
    app.use(
        validateClientSurfaceResponses({
            operations: clientSurfaceOperations,
            onMismatch: "throw",
        }),
    );
    app.use(express.json());
    app.use(basePath, router);
    return app;
}
