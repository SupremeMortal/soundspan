import type { Client } from "pg";
import { searchPlaylists } from "../src/services/playlistSearch";
import { prisma } from "../src/utils/db";
import {
    applyScaleMigrations,
    createScaleDatabase,
    dropScaleDatabase,
} from "./scaleTestDatabase";

const integrationDatabaseUrl = process.env.INTEGRATION_DATABASE_URL;
const databaseName = process.env.VIBE_INTEGRATION_DATABASE;
const describeWithPostgres =
    integrationDatabaseUrl && databaseName ? describe : describe.skip;

const VIEWER = "playlist-search-viewer";
const OTHER = "playlist-search-other";

async function seedUser(id: string): Promise<void> {
    await prisma.user.create({
        data: { id, username: id, passwordHash: "x" },
    });
}

async function seedPlaylist(
    id: string,
    userId: string,
    name: string,
    extra: { isPublic?: boolean; mixId?: string } = {},
): Promise<void> {
    await prisma.playlist.create({
        data: { id, userId, name, ...extra },
    });
}

describeWithPostgres("playlist search PostgreSQL behavior", () => {
    let admin: Client | undefined;

    beforeAll(async () => {
        if (!integrationDatabaseUrl || !databaseName) {
            throw new Error("PostgreSQL integration environment is missing");
        }
        admin = await createScaleDatabase(integrationDatabaseUrl, databaseName);
        const runtimeDatabaseUrl = process.env.DATABASE_URL;
        if (!runtimeDatabaseUrl) {
            throw new Error("Integration database URL was not initialized");
        }
        await applyScaleMigrations(runtimeDatabaseUrl);
        await seedUser(VIEWER);
        await seedUser(OTHER);
        await seedPlaylist("pl-own", VIEWER, "Road Trip");
        await seedPlaylist("pl-own-long", VIEWER, "Summer Road Trip Mix");
        await seedPlaylist("pl-public", OTHER, "Road Trip Classics", {
            isPublic: true,
        });
        await seedPlaylist("pl-private", OTHER, "Road Trip Secrets");
        await seedPlaylist("pl-radio", VIEWER, "Road Trip Radio", {
            mixId: "radio-ephemeral:seed",
        });
        await seedPlaylist("pl-unrelated", VIEWER, "Gym");
    });

    afterAll(async () => {
        await prisma.$disconnect();
        if (admin && databaseName) {
            await dropScaleDatabase(admin, databaseName);
        }
    });

    it("returns own and public playlists, never another user's private one", async () => {
        const hits = await searchPlaylists({
            userId: VIEWER,
            query: "road trip",
            limit: 10,
            offset: 0,
        });

        const ids = hits.map((hit) => hit.playlist.id);
        expect(ids).toEqual(
            expect.arrayContaining(["pl-own", "pl-own-long", "pl-public"]),
        );
        expect(ids).not.toContain("pl-private");
        expect(ids).not.toContain("pl-radio");
        expect(ids).not.toContain("pl-unrelated");
        expect(ids[0]).toBe("pl-own");
        expect(hits[0]?.similarity).toBeGreaterThan(hits[1]?.similarity ?? 1);
        expect(
            hits.find((hit) => hit.playlist.id === "pl-public")?.playlist,
        ).toMatchObject({
            isOwner: false,
            isPublic: true,
            user: { username: OTHER },
            trackCount: 0,
            items: [],
        });
    });

    it("finds a typo through the trigram operator and pages by offset", async () => {
        const typo = await searchPlaylists({
            userId: VIEWER,
            query: "raod trip",
            limit: 10,
            offset: 0,
        });
        expect(typo.map((hit) => hit.playlist.id)).toContain("pl-own");

        const all = await searchPlaylists({
            userId: VIEWER,
            query: "road trip",
            limit: 10,
            offset: 0,
        });
        const second = await searchPlaylists({
            userId: VIEWER,
            query: "road trip",
            limit: 1,
            offset: 1,
        });
        expect(second.map((hit) => hit.playlist.id)).toEqual([
            all[1]?.playlist.id,
        ]);
    });

    it("backs the name match with a trigram index", async () => {
        const indexes = await prisma.$queryRaw<Array<{ indexdef: string }>>`
            SELECT indexdef FROM pg_indexes
            WHERE tablename = 'Playlist' AND indexname = 'Playlist_name_trgm_idx'
        `;
        expect(indexes).toHaveLength(1);
        expect(indexes[0]?.indexdef).toContain("gin_trgm_ops");
    });

    it("lets the other user see their private playlist", async () => {
        const hits = await searchPlaylists({
            userId: OTHER,
            query: "secrets",
            limit: 10,
            offset: 0,
        });
        expect(hits.map((hit) => hit.playlist.id)).toEqual(["pl-private"]);
    });
});
