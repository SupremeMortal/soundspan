import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";

const repoRoot = path.resolve(import.meta.dirname, "../../..");
const reporter = path.join(repoRoot, "scripts/ci/client-nightly-report.mjs");
const title = "Flutter client nightly failures";

const needs = JSON.stringify({
    "device-tests": { result: "failure", outputs: {} },
    "contract-matrix": { result: "success", outputs: {} },
});

// A stub `gh` that appends its arguments to calls.jsonl and answers
// `issue list` with the issues in issues.json.
const stubGh = `#!/usr/bin/env node
const fs = require("node:fs");
const path = require("node:path");
const dir = path.dirname(process.argv[1]);
const args = process.argv.slice(2);
fs.appendFileSync(path.join(dir, "calls.jsonl"), JSON.stringify(args) + "\\n");
if (args[0] === "issue" && args[1] === "list") {
    process.stdout.write(fs.readFileSync(path.join(dir, "issues.json"), "utf8"));
}
`;

function runReporter(t, issues) {
    const directory = fs.mkdtempSync(
        path.join(os.tmpdir(), "soundspan-nightly-report-test-"),
    );
    t.after(() => fs.rmSync(directory, { recursive: true }));
    const gh = path.join(directory, "gh");
    fs.writeFileSync(gh, stubGh, { mode: 0o755 });
    fs.writeFileSync(
        path.join(directory, "issues.json"),
        JSON.stringify(issues),
    );
    const result = spawnSync(process.execPath, [reporter], {
        cwd: repoRoot,
        encoding: "utf8",
        env: {
            ...process.env,
            GH_BIN: gh,
            GH_REPO: "owner/repo",
            NEEDS_JSON: needs,
            RUN_URL: "https://github.com/owner/repo/actions/runs/42",
        },
    });
    const callsFile = path.join(directory, "calls.jsonl");
    const calls = fs.existsSync(callsFile)
        ? fs
              .readFileSync(callsFile, "utf8")
              .trim()
              .split("\n")
              .map((line) => JSON.parse(line))
        : [];
    return { result, calls };
}

function valueOf(args, flag) {
    const index = args.indexOf(flag);
    return index === -1 ? undefined : args[index + 1];
}

test("with no open tracking issue it creates one labelled flutter-client", (t) => {
    const { result, calls } = runReporter(t, []);
    assert.equal(result.status, 0, result.stderr);
    const create = calls.find((c) => c[0] === "issue" && c[1] === "create");
    assert.ok(create, JSON.stringify(calls));
    assert.equal(valueOf(create, "--title"), title);
    assert.equal(valueOf(create, "--label"), "flutter-client");
    assert.equal(valueOf(create, "--repo"), "owner/repo");
    const body = valueOf(create, "--body");
    assert.match(body, /device-tests/);
    assert.doesNotMatch(body, /contract-matrix/);
    assert.match(body, /actions\/runs\/42/);
    assert.ok(!calls.some((c) => c[1] === "comment"));
});

test("with an open tracking issue it comments on it", (t) => {
    const { result, calls } = runReporter(t, [
        { number: 7, title: "Flutter client nightly failures (old)" },
        { number: 9, title },
    ]);
    assert.equal(result.status, 0, result.stderr);
    const comment = calls.find((c) => c[0] === "issue" && c[1] === "comment");
    assert.ok(comment, JSON.stringify(calls));
    assert.equal(comment[2], "9");
    assert.match(valueOf(comment, "--body"), /device-tests/);
    assert.ok(!calls.some((c) => c[1] === "create"));
});

test("it never closes or edits an issue", (t) => {
    for (const issues of [[], [{ number: 9, title }]]) {
        const { result, calls } = runReporter(t, issues);
        assert.equal(result.status, 0, result.stderr);
        assert.ok(
            !calls.some((c) => ["close", "edit", "delete"].includes(c[1])),
            JSON.stringify(calls),
        );
    }
});

test("it fails without the run URL", (t) => {
    const directory = fs.mkdtempSync(
        path.join(os.tmpdir(), "soundspan-nightly-report-test-"),
    );
    t.after(() => fs.rmSync(directory, { recursive: true }));
    const result = spawnSync(process.execPath, [reporter], {
        cwd: repoRoot,
        encoding: "utf8",
        env: {
            ...process.env,
            GH_BIN: path.join(directory, "missing-gh"),
            GH_REPO: "owner/repo",
            NEEDS_JSON: needs,
            RUN_URL: "",
        },
    });
    assert.notEqual(result.status, 0);
});
