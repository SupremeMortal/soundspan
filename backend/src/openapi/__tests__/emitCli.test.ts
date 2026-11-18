import { spawnSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";

const BACKEND = path.resolve(__dirname, "..", "..", "..");
const TSX = path.join(BACKEND, "node_modules", ".bin", "tsx");
const SCRIPT = path.join(BACKEND, "scripts", "emitClientSurfaceSpec.ts");
const RELATIVE = path.join(
    "client",
    "packages",
    "soundspan_api",
    "openapi",
    "soundspan-client.json",
);

function run(root: string, ...args: string[]) {
    return spawnSync(TSX, [SCRIPT, "--root", root, ...args], {
        cwd: BACKEND,
        env: { PATH: process.env.PATH ?? "" },
        encoding: "utf8",
    });
}

describe("emitClientSurfaceSpec", () => {
    let root: string;

    beforeEach(() => {
        root = mkdtempSync(path.join(tmpdir(), "emit-client-spec-"));
    });

    afterEach(() => {
        rmSync(root, { recursive: true, force: true });
    });

    it("writes the spec with an environment stripped to PATH", () => {
        const result = run(root);
        expect(result.stderr).toBe("");
        expect(result.status).toBe(0);
        const written = JSON.parse(
            readFileSync(path.join(root, RELATIVE), "utf8"),
        );
        expect(written.openapi).toBe("3.0.0");
        expect(written.info.title).toBe("soundspan client surface");
    }, 60_000);

    it("--check passes after a write and fails after an edit or a delete", () => {
        expect(run(root).status).toBe(0);
        expect(run(root, "--check").status).toBe(0);

        const file = path.join(root, RELATIVE);
        writeFileSync(file, `${readFileSync(file, "utf8")} `);
        const edited = run(root, "--check");
        expect(edited.status).toBe(1);
        expect(edited.stderr).toMatch(
            /run npm --prefix backend run openapi:emit-client/,
        );
        expect(readFileSync(file, "utf8").endsWith(" ")).toBe(true);

        rmSync(file);
        expect(run(root, "--check").status).toBe(1);
    }, 60_000);
});
