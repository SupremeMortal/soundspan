import type { PrismaPg } from "@prisma/adapter-pg";

const prismaClientConstructor = jest.fn();

jest.mock("@prisma/client", () => ({
    Prisma: {},
    PrismaClient: class {
        constructor(...args: unknown[]) {
            prismaClientConstructor(...args);
        }
    },
}));

import { createPrismaClient } from "../prismaClientFactory";

interface PgPoolOptions {
    keepAlive?: boolean;
    keepAliveInitialDelayMillis?: number;
    max?: number;
    connectionTimeoutMillis?: number;
}

/**
 * Builds the REAL PrismaPg adapter through the factory and returns the pg
 * pool options it hands to pg.Pool. connect() constructs the pool lazily,
 * so no database connection is opened.
 */
async function poolOptionsFor(
    options: Parameters<typeof createPrismaClient>[0],
): Promise<{ poolOptions: PgPoolOptions; adapterFactory: PrismaPg }> {
    createPrismaClient(options);
    const clientArgs = prismaClientConstructor.mock.calls.at(-1)?.[0] as {
        adapter: PrismaPg;
    };
    const adapterFactory = clientArgs.adapter;
    const adapter = await adapterFactory.connect();
    const pool = adapter.underlyingDriver() as unknown as {
        options: PgPoolOptions;
    };
    const poolOptions = pool.options;
    await adapter.dispose();
    return { poolOptions, adapterFactory };
}

describe("createPrismaClient", () => {
    beforeEach(() => {
        prismaClientConstructor.mockClear();
    });

    it("enables TCP keepalive on the pg pool", async () => {
        const { poolOptions } = await poolOptionsFor({
            databaseUrl: "postgresql://u:p@db:5432/app",
        });

        expect(poolOptions.keepAlive).toBe(true);
        expect(poolOptions.keepAliveInitialDelayMillis).toBe(10_000);
    });

    it("applies pool sizing and schema options", async () => {
        const { poolOptions, adapterFactory } = await poolOptionsFor({
            databaseUrl: "postgresql://u:p@db:5432/app?schema=tenant",
            connectionLimit: 12,
            poolTimeoutSeconds: 20,
        });

        expect(poolOptions.max).toBe(12);
        expect(poolOptions.connectionTimeoutMillis).toBe(20_000);
        expect(
            (adapterFactory as unknown as { options?: { schema?: string } })
                .options?.schema,
        ).toBe("tenant");
    });

    it("builds the URL from POSTGRES_* components when DATABASE_URL is empty", async () => {
        const originalEnv = process.env;
        process.env = {
            ...originalEnv,
            DATABASE_URL: "",
            POSTGRES_HOST: "postgres",
            POSTGRES_PORT: "5432",
            POSTGRES_USER: "soundspan",
            POSTGRES_PASSWORD: "p@ss word",
            POSTGRES_DB: "soundspan",
        };
        try {
            const { poolOptions } = await poolOptionsFor({});
            expect(
                (poolOptions as { connectionString?: string }).connectionString,
            ).toBe(
                "postgresql://soundspan:p%40ss%20word@postgres:5432/soundspan",
            );
        } finally {
            process.env = originalEnv;
        }
    });

    it("rejects invalid pool bounds", () => {
        expect(() => createPrismaClient({ connectionLimit: 0 })).toThrow(
            "connectionLimit must be >= 1",
        );
        expect(() => createPrismaClient({ poolTimeoutSeconds: 0 })).toThrow(
            "poolTimeoutSeconds must be > 0",
        );
    });
});
