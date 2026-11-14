// backend/scripts/emitClientSurfaceSpec.ts
//
// Writes the client-surface OpenAPI document that the Flutter client's API
// package is generated from. With `--check`, writes nothing and exits 1 when
// the committed file is missing or differs. `--root <dir>` replaces the
// repository root (tests). Needs no database, Redis or environment variables.

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";
import { resolveAppVersion } from "../src/config/appVersion";
import { clientSurfaceOperations } from "../src/openapi/clientSurface";
import { renderClientSurfaceSpec } from "../src/openapi/emit";

const RELATIVE_PATH = path.join(
    "client",
    "packages",
    "soundspan_api",
    "openapi",
    "soundspan-client.json",
);

function main(argv: string[]): number {
    const check = argv.includes("--check");
    const rootIndex = argv.indexOf("--root");
    const root =
        rootIndex >= 0 && argv[rootIndex + 1]
            ? path.resolve(argv[rootIndex + 1])
            : path.resolve(__dirname, "..", "..");
    const target = path.join(root, RELATIVE_PATH);
    const rendered = renderClientSurfaceSpec(
        clientSurfaceOperations,
        resolveAppVersion(),
    );

    if (check) {
        const current = existsSync(target)
            ? readFileSync(target, "utf8")
            : null;
        if (current === rendered) return 0;
        process.stderr.write(
            `${RELATIVE_PATH} is ${current === null ? "missing" : "stale"}: run npm --prefix backend run openapi:emit-client and commit the result\n`,
        );
        return 1;
    }

    mkdirSync(path.dirname(target), { recursive: true });
    writeFileSync(target, rendered);
    process.stdout.write(`wrote ${RELATIVE_PATH}\n`);
    return 0;
}

process.exitCode = main(process.argv.slice(2));
