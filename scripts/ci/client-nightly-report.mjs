#!/usr/bin/env node
// Reports a failed client-nightly.yml run on one tracking issue
// (docs/designs/flutter-client/11-testing-and-ci.md, client-nightly.yml).
//
// Finds the open issue titled "Flutter client nightly failures" labelled
// flutter-client and comments on it, or creates it when there is none. The
// body lists the failed jobs and the run URL. It never closes an issue.
//
// Environment:
//   GH_REPO     owner/name of the repository
//   RUN_URL     the workflow run URL
//   NEEDS_JSON  the `needs` context of the report job, as JSON
//   GH_BIN      the gh executable (default: gh); the self-test stubs it

import { execFileSync } from "node:child_process";

const TITLE = "Flutter client nightly failures";
const LABEL = "flutter-client";

function required(name) {
    const value = process.env[name];
    if (!value) {
        console.error(`client-nightly-report: ${name} is required`);
        process.exit(2);
    }
    return value;
}

const repo = required("GH_REPO");
const runUrl = required("RUN_URL");
const needs = JSON.parse(process.env.NEEDS_JSON || "{}");
const gh = process.env.GH_BIN || "gh";

function run(args) {
    return execFileSync(gh, args, { encoding: "utf8" });
}

const failed = Object.entries(needs)
    .filter(
        ([, job]) =>
            job && job.result !== "success" && job.result !== "skipped",
    )
    .map(([name, job]) => `- \`${name}\`: ${job.result}`);

const body = [
    "The Flutter client nightly run failed.",
    "",
    ...(failed.length > 0 ? failed : ["- (no failed job reported)"]),
    "",
    `Run: ${runUrl}`,
].join("\n");

const issues = JSON.parse(
    run([
        "issue",
        "list",
        "--repo",
        repo,
        "--state",
        "open",
        "--label",
        LABEL,
        "--search",
        `"${TITLE}" in:title`,
        "--json",
        "number,title",
        "--limit",
        "100",
    ]) || "[]",
);
const existing = issues.find((issue) => issue.title === TITLE);

if (existing) {
    run([
        "issue",
        "comment",
        String(existing.number),
        "--repo",
        repo,
        "--body",
        body,
    ]);
    console.log(`Commented on #${existing.number}.`);
} else {
    run([
        "issue",
        "create",
        "--repo",
        repo,
        "--title",
        TITLE,
        "--label",
        LABEL,
        "--body",
        body,
    ]);
    console.log(`Created "${TITLE}".`);
}
