import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {
    type BackendProcess,
    printLogTail,
    randomSecret,
    redisDatabaseUrl,
    requiredEnv,
    startBackend,
    stopBackend,
    waitForReady,
} from "./backupRestoreSmoke/support";
import {
    migrate,
    recreateDatabase,
    seedLibrary,
} from "./unifiedPlaybackSmoke/fixtures";
import {
    assertOffline,
    assertRemoteUnavailable,
    assertSocketApiKey,
    assertStreaming,
    assertTrackListing,
    assertWrites,
    bootstrapCredentials,
} from "./unifiedPlaybackSmoke/flow";

const PORT = 3103;

function backendEnvironment(
    database: string,
    redis: string,
    runtimeRoot: string,
): NodeJS.ProcessEnv {
    const secret = randomSecret();
    return {
        ...process.env,
        NODE_ENV: "production",
        BACKEND_PROCESS_ROLE: "api",
        PORT: String(PORT),
        DATABASE_URL: database,
        REDIS_URL: redis,
        SESSION_SECRET: secret,
        JWT_SECRET: secret,
        SETTINGS_ENCRYPTION_KEY: randomSecret(),
        INTERNAL_API_SECRET: randomSecret(),
        MUSIC_PATH: path.join(runtimeRoot, "music"),
        TRANSCODE_CACHE_PATH: path.join(runtimeRoot, "cache", "transcodes"),
        SECURE_COOKIES: "false",
        ALLOWED_ORIGINS: `http://127.0.0.1:${PORT}`,
        ADMIN_RESET_PASSWORD: "",
        LOCAL_LOGIN_ENABLED: "true",
        OIDC_ENABLED: "false",
        SECRETS_DB_ONLY: "false",
        AUDIO_ANALYSIS_ENABLED: "false",
        DISCOVERY_ENABLED: "false",
        AUTO_PLAYLISTS_ENABLED: "false",
        FEATURE_REQUESTS: "false",
        CATALOG_PERSISTENCE: "off",
        ENABLE_ENV_FILE_SYNC: "false",
        LOG_LEVEL: "info",
    };
}

async function main(): Promise<void> {
    const backendRoot = path.resolve(__dirname, "..");
    const tempRoot = await fs.mkdtemp(
        path.join(os.tmpdir(), "soundspan-unified-playback-smoke-"),
    );
    const logDir =
        process.env.SMOKE_LOG_DIR?.trim() || path.join(tempRoot, "logs");
    await fs.mkdir(logDir, { recursive: true });
    const logPath = path.join(logDir, "backend.log");
    const baseUrl = `http://127.0.0.1:${PORT}`;
    let backend: BackendProcess | null = null;
    try {
        const databaseUrl = await recreateDatabase(
            requiredEnv("SMOKE_ADMIN_DATABASE_URL"),
        );
        await migrate(backendRoot, databaseUrl);
        const library = await seedLibrary(
            databaseUrl,
            path.join(tempRoot, "music"),
        );
        backend = startBackend(
            backendRoot,
            backendEnvironment(
                databaseUrl,
                redisDatabaseUrl(requiredEnv("SMOKE_REDIS_URL"), 2),
                tempRoot,
            ),
            logPath,
        );
        await waitForReady(baseUrl, backend);
        const creds = await bootstrapCredentials(baseUrl);
        const playbackId = await assertTrackListing(baseUrl, creds, library);
        await assertStreaming(baseUrl, creds, library, playbackId);
        await assertRemoteUnavailable(baseUrl, creds);
        await assertWrites(baseUrl, creds, playbackId);
        await assertOffline(baseUrl, creds, library, playbackId);
        await assertSocketApiKey(baseUrl, creds);
        process.stdout.write("Unified playback smoke passed.\n");
    } catch (error) {
        await printLogTail(logPath);
        throw error;
    } finally {
        await stopBackend(backend);
        if (!process.env.SMOKE_LOG_DIR) {
            await fs.rm(tempRoot, { recursive: true, force: true });
        }
    }
}

main().catch((error: unknown) => {
    process.stderr.write(
        `${error instanceof Error ? (error.stack ?? error.message) : String(error)}\n`,
    );
    process.exit(1);
});
