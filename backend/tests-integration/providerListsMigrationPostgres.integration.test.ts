import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { Client } from "pg";
import { createScaleDatabase, dropScaleDatabase } from "./scaleTestDatabase";

const integrationDatabaseUrl = process.env.INTEGRATION_DATABASE_URL;
const databaseName = process.env.VIBE_INTEGRATION_DATABASE;
const describeWithPostgres =
    integrationDatabaseUrl && databaseName ? describe : describe.skip;

const migrationSql = readFileSync(
    resolve(
        __dirname,
        "../prisma/migrations/20261107140000_provider_lists/migration.sql",
    ),
    "utf8",
);

interface LegacySettings {
    id: string;
    playbackSourceOrder?: string;
    downloadSource?: string;
    primaryFailureFallback?: string;
    tidalEnabled?: boolean;
    ytMusicEnabled?: boolean;
    lidarrEnabled?: boolean;
    soulseekUsername?: string | null;
    soulseekPassword?: string | null;
}

// The backfill only reads and writes SystemSettings, so the test runs it
// against that table's pre-migration columns instead of the full migration
// chain (which needs pgvector).
const LEGACY_TABLE = `
    CREATE TABLE "SystemSettings" (
        "id" TEXT PRIMARY KEY,
        "lidarrEnabled" BOOLEAN NOT NULL DEFAULT false,
        "soulseekUsername" TEXT,
        "soulseekPassword" TEXT,
        "tidalEnabled" BOOLEAN NOT NULL DEFAULT false,
        "ytMusicEnabled" BOOLEAN NOT NULL DEFAULT false,
        "fanartEnabled" BOOLEAN NOT NULL DEFAULT false,
        "downloadSource" TEXT NOT NULL DEFAULT 'soulseek',
        "playbackSourceOrder" TEXT NOT NULL DEFAULT 'library,peers,tidal,ytmusic',
        "primaryFailureFallback" TEXT NOT NULL DEFAULT 'none'
    )`;

const ALL_ENABLED = {
    tidalEnabled: true,
    ytMusicEnabled: true,
    lidarrEnabled: true,
    soulseekUsername: "user",
    soulseekPassword: "v2:encrypted",
};

const CASES: Array<[string, LegacySettings, string]> = [
    [
        "defaults with nothing configured keep only peers",
        { id: "defaults" },
        "peers",
    ],
    [
        "the configured download source leads, then the streaming order",
        { id: "soulseek-primary", ...ALL_ENABLED },
        "soulseek,peers,tidal,ytmusic,lidarr",
    ],
    [
        "the fallback follows the download source",
        {
            id: "tidal-then-soulseek",
            ...ALL_ENABLED,
            downloadSource: "tidal",
            primaryFailureFallback: "soulseek",
        },
        "peers,tidal,soulseek,ytmusic,lidarr",
    ],
    [
        "the streaming order wins over the download settings for tidal vs ytmusic",
        {
            id: "stream-wins",
            ...ALL_ENABLED,
            playbackSourceOrder: "library,peers,tidal,ytmusic",
            downloadSource: "youtube",
            primaryFailureFallback: "tidal",
        },
        "peers,tidal,ytmusic,soulseek,lidarr",
    ],
    [
        "a custom streaming order is kept",
        {
            id: "custom-stream",
            ...ALL_ENABLED,
            playbackSourceOrder: "ytmusic,library,tidal,peers",
            downloadSource: "lidarr",
            primaryFailureFallback: "tidal",
        },
        "lidarr,ytmusic,tidal,peers,soulseek",
    ],
    [
        "disabled providers and empty Soulseek credentials are dropped",
        {
            id: "partial",
            tidalEnabled: false,
            ytMusicEnabled: true,
            lidarrEnabled: true,
            soulseekUsername: "user",
            soulseekPassword: "",
            downloadSource: "lidarr",
            primaryFailureFallback: "youtube",
        },
        "lidarr,peers,ytmusic",
    ],
    [
        "a malformed streaming order falls back to the default order",
        {
            id: "malformed",
            ...ALL_ENABLED,
            playbackSourceOrder: "bogus",
            downloadSource: "unknown",
            primaryFailureFallback: "none",
        },
        "peers,tidal,ytmusic,soulseek,lidarr",
    ],
];

async function insertLegacyRow(
    client: Client,
    row: LegacySettings,
): Promise<void> {
    await client.query(
        `INSERT INTO "SystemSettings" (
            "id", "playbackSourceOrder", "downloadSource",
            "primaryFailureFallback", "tidalEnabled", "ytMusicEnabled",
            "lidarrEnabled", "soulseekUsername", "soulseekPassword"
         ) VALUES (
            $1, COALESCE($2, 'library,peers,tidal,ytmusic'),
            COALESCE($3, 'soulseek'), COALESCE($4, 'none'), $5, $6, $7, $8, $9
         )`,
        [
            row.id,
            row.playbackSourceOrder ?? null,
            row.downloadSource ?? null,
            row.primaryFailureFallback ?? null,
            row.tidalEnabled ?? false,
            row.ytMusicEnabled ?? false,
            row.lidarrEnabled ?? false,
            row.soulseekUsername ?? null,
            row.soulseekPassword ?? null,
        ],
    );
}

describeWithPostgres("provider lists migration (PostgreSQL)", () => {
    let admin: Client | undefined;
    let client: Client;

    beforeAll(async () => {
        admin = await createScaleDatabase(
            integrationDatabaseUrl!,
            databaseName!,
        );
        client = new Client({ connectionString: process.env.DATABASE_URL });
        await client.connect();
        await client.query(LEGACY_TABLE);
        for (const [, row] of CASES) await insertLegacyRow(client, row);
        await client.query(migrationSql);
    });

    afterAll(async () => {
        await client?.end();
        if (admin && databaseName) {
            await dropScaleDatabase(admin, databaseName);
        }
    });

    it.each(CASES)("backfills: %s", async (_name, row, expected) => {
        const result = await client.query<{ playbackProviders: string }>(
            `SELECT "playbackProviders" FROM "SystemSettings" WHERE "id" = $1`,
            [row.id],
        );
        expect(result.rows[0].playbackProviders).toBe(expected);
    });

    it("keeps the full metadata chains and drops the replaced columns", async () => {
        const settings = await client.query(
            `SELECT "artistImageProviders", "albumCoverProviders"
             FROM "SystemSettings" WHERE "id" = 'defaults'`,
        );
        expect(settings.rows[0]).toEqual({
            artistImageProviders: "wikidata,fanart,deezer,lastfm",
            albumCoverProviders: "coverartarchive,deezer,fanart",
        });
        const columns = await client.query<{ column_name: string }>(
            `SELECT column_name FROM information_schema.columns
             WHERE table_name = 'SystemSettings'
               AND column_name IN ('playbackSourceOrder', 'downloadSource',
                                   'primaryFailureFallback')`,
        );
        expect(columns.rows).toEqual([]);
    });

    it("defaults a row inserted after the migration to peers only", async () => {
        await client.query(
            `INSERT INTO "SystemSettings" ("id") VALUES ('fresh')`,
        );
        const result = await client.query<{ playbackProviders: string }>(
            `SELECT "playbackProviders" FROM "SystemSettings" WHERE "id" = 'fresh'`,
        );
        expect(result.rows[0].playbackProviders).toBe("peers");
    });
});
