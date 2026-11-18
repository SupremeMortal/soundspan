import type { Request, Response, Router } from "express";
import bcrypt from "bcrypt";
import { z } from "zod";
import { prisma } from "../../utils/db";
import { logger } from "../../utils/logger";
import {
    generateRefreshToken,
    generateToken,
    requireAuth,
    verifyAuthToken,
} from "../../middleware/auth";
import { apiLimiter } from "../../middleware/rateLimiter";
import { config } from "../../config";
import { runDummyBcrypt } from "../../utils/dummyCredential";
import { sendRouteError } from "../../utils/routeErrorResponse";
import { sendLoginSuccess, verifyLoginSecondFactor } from "./shared";
import { LoginRequest } from "../../openapi/schemas/session";

/** Register local login, logout, refresh, and current-user routes. */
export default function registerLocalCredentialRoutes(router: Router): void {
    async function findLocalLoginUser(username: string) {
        return (
            (await prisma.user.findUnique({ where: { username } })) ??
            (await prisma.user.findUnique({ where: { email: username } }))
        );
    }

    async function localLoginHandler(
        req: Request,
        res: Response,
    ): Promise<Response> {
        if (!config.localLoginEnabled) {
            return sendRouteError(res, 403, "Local login is disabled");
        }
        try {
            const { username, password, token } = LoginRequest.parse(req.body);
            const user = await findLocalLoginUser(username);
            if (!user || !user.passwordHash) {
                await runDummyBcrypt();
                return sendRouteError(res, 401, "Invalid credentials");
            }
            const valid = await bcrypt.compare(password, user.passwordHash);
            if (!valid) return sendRouteError(res, 401, "Invalid credentials");
            const secondFactor = await verifyLoginSecondFactor(user, token);
            if (secondFactor.kind === "required") {
                return res.json({
                    requires2FA: true,
                    message: "2FA token required",
                });
            }
            if (secondFactor.kind === "invalid") {
                return sendRouteError(res, 401, secondFactor.message);
            }
            return sendLoginSuccess(res, user);
        } catch (err) {
            if (err instanceof z.ZodError) {
                return res
                    .status(400)
                    .json({ error: "Invalid request", details: err.issues });
            }
            logger.error("Login error:", err);
            return res.status(500).json({ error: "Internal error" });
        }
    }

    // POST /auth/login
    router.post("/login", localLoginHandler);

    // POST /auth/logout - JWT is stateless, logout is handled client-side
    router.post("/logout", (req, res) => {
        // With JWT, logout is handled by client removing the token
        // No server-side session to destroy
        res.json({ message: "Logged out" });
    });

    // POST /auth/refresh - Refresh access token using refresh token
    router.post("/refresh", async (req, res) => {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return res.status(400).json({ error: "Refresh token required" });
        }

        let decoded;
        try {
            decoded = verifyAuthToken(refreshToken);
        } catch {
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        if (decoded.type !== "refresh") {
            return res.status(401).json({ error: "Invalid refresh token" });
        }

        let user;
        try {
            user = await prisma.user.findUnique({
                where: { id: decoded.userId },
                select: {
                    id: true,
                    username: true,
                    role: true,
                    tokenVersion: true,
                },
            });
        } catch (cause) {
            logger.warn("Refresh authentication backend unavailable", cause);
            return sendRouteError(
                res,
                503,
                "Authentication service unavailable",
                { code: "AUTH_BACKEND_UNAVAILABLE" },
            );
        }

        if (!user) {
            return res.status(401).json({ error: "User not found" });
        }

        // Validate tokenVersion
        if (decoded.tokenVersion !== user.tokenVersion) {
            return res.status(401).json({ error: "Token invalidated" });
        }

        const newAccessToken = generateToken(user);
        const newRefreshToken = generateRefreshToken(user);

        return res.json({
            token: newAccessToken,
            refreshToken: newRefreshToken,
        });
    });

    // GET /auth/me
    router.get("/me", apiLimiter, requireAuth, async (req, res) => {
        const user = await prisma.user.findUnique({
            where: { id: req.user!.id },
            select: {
                id: true,
                username: true,
                displayName: true,
                email: true,
                role: true,
                onboardingComplete: true,
                enrichmentSettings: true,
                createdAt: true,
            },
        });

        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }

        res.json(user);
    });
}
