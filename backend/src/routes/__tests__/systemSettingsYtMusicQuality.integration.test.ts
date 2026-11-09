import { createPrismaClient } from "../../utils/prismaClientFactory";

const databaseUrl = process.env.DATABASE_URL;
const describeWithDatabase = databaseUrl ? describe : describe.skip;

describeWithDatabase("SystemSettings.ytMusicQuality (PostgreSQL)", () => {
    const id = "yt-music-quality-integration";
    let client: ReturnType<typeof createPrismaClient>;

    beforeAll(() => {
        if (!databaseUrl) return;
        client = createPrismaClient({
            databaseUrl,
            connectionLimit: 1,
            poolTimeoutSeconds: 2,
        });
    });

    afterAll(async () => {
        await client?.systemSettings.deleteMany({ where: { id } });
        await client?.$disconnect();
    });

    it("defaults to HIGH and persists an updated value", async () => {
        const created = await client.systemSettings.create({ data: { id } });
        expect(created.ytMusicQuality).toBe("HIGH");

        const updated = await client.systemSettings.update({
            where: { id },
            data: { ytMusicQuality: "LOSSLESS" },
        });
        expect(updated.ytMusicQuality).toBe("LOSSLESS");
        expect(updated.tidalQuality).toBe(created.tidalQuality);
    });
});
