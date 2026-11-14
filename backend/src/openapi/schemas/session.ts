import { z } from "zod";

/** Health probe payload; sent with 200 when ready and 503 when not. */
export const HealthStatus = z
    .object({
        status: z.string(),
        draining: z.boolean(),
        startupComplete: z.boolean(),
        version: z.string(),
        role: z.enum(["all", "api", "worker"]),
        uptimeSeconds: z.number().int(),
    })
    .meta({ id: "HealthStatus" });

/** Sign-in methods the server offers. */
export const AuthConfig = z
    .object({
        localLoginEnabled: z.boolean(),
        oidcEnabled: z.boolean(),
        oidcProviderName: z.string(),
    })
    .meta({ id: "AuthConfig" });

/** Whether the server or the signed-in user still needs onboarding. */
export const OnboardingStatus = z
    .object({
        needsOnboarding: z.boolean(),
        hasAccount: z.boolean(),
    })
    .meta({ id: "OnboardingStatus" });

/** Body of `POST /api/auth/login`; validated by the route. */
export const LoginRequest = z
    .object({
        username: z.string().min(1),
        password: z.string().min(1),
        token: z.string().min(1).optional(),
    })
    .meta({ id: "LoginRequest" });

/** The signed-in user as returned by login and `/api/auth/me`. */
export const LoginUser = z
    .object({
        id: z.string(),
        username: z.string(),
        displayName: z.string().nullable(),
        role: z.enum(["user", "admin"]),
    })
    .meta({ id: "LoginUser" });

/** Access and refresh tokens. */
export const SessionTokens = z
    .object({
        token: z.string(),
        refreshToken: z.string(),
    })
    .meta({ id: "SessionTokens" });

/** Successful sign-in. */
export const LoginTokenResponse = z
    .object({
        token: z.string(),
        refreshToken: z.string(),
        user: LoginUser,
    })
    .meta({ id: "LoginTokenResponse" });

/** Sign-in that needs a TOTP or recovery code in `token`. */
export const LoginTwoFactorChallenge = z
    .object({
        requires2FA: z.literal(true),
        message: z.string(),
    })
    .meta({ id: "LoginTwoFactorChallenge" });

/** Either a successful sign-in or a second-factor challenge (`oneOf`). */
export const LoginResponse = z.xor([
    LoginTokenResponse,
    LoginTwoFactorChallenge,
]);

/** Body of `POST /api/auth/refresh`. */
export const RefreshSessionRequest = z
    .object({ refreshToken: z.string() })
    .meta({ id: "RefreshSessionRequest" });

/** A plain confirmation message. */
export const MessageResponse = z
    .object({ message: z.string() })
    .meta({ id: "MessageResponse" });

/** The part of the OpenAPI document the client reads. */
export const ApiDocumentInfo = z
    .object({ info: z.object({ version: z.string() }) })
    .meta({ id: "ApiDocumentInfo" });

/** Feature flags and detected capabilities of the server. */
export const SystemFeatures = z
    .object({
        audioAnalysis: z.boolean(),
        discovery: z.boolean(),
        autoPlaylists: z.boolean(),
        federation: z.boolean(),
        vibeEmbeddings: z.boolean(),
        loudnessTargetLufs: z.number(),
    })
    .meta({ id: "SystemFeatures" });
