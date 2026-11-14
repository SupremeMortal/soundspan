// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
//
// Spike S6 driver. Usage: node driver.cjs <chromium|firefox|safari> [url]
//
// Opens the harness, waits for the `S6:<json>` title, reloads, reads it again
// and prints `S6-<browser>` with both results and `yes`, `no` or
// `unanswerable`. Writes results/<browser>.json for the job summary. Exits
// non-zero only when no measurement could be taken.
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const browser = process.argv[2];
const url = process.argv[3] ?? "http://localhost:8080/";
const timeoutMs = 120_000;

function isResult(title) {
    return typeof title === "string" && title.startsWith("S6:{");
}

function verdict(before, after) {
    const names = Object.keys(before.databases);
    const ok =
        names.length === 3 &&
        before.crossOriginIsolated === false &&
        after.crossOriginIsolated === false &&
        names.every((name) => {
            const b = before.databases[name];
            const a = after.databases[name];
            return (
                b.opened &&
                a?.opened &&
                b.implementation !== "inMemory" &&
                a.implementation !== "inMemory" &&
                a.counter === b.counter + 1
            );
        });
    return ok ? "yes" : "no";
}

async function withPlaywright(name) {
    const playwright = require("playwright");
    const instance = await playwright[name].launch({ headless: true });
    try {
        const context = await instance.newContext();
        const page = await context.newPage();
        const read = async () => {
            await page.waitForFunction(
                () => document.title.startsWith("S6:{"),
                undefined,
                { timeout: timeoutMs },
            );
            return JSON.parse((await page.title()).slice(3));
        };
        await page.goto(url);
        const before = await read();
        await page.reload();
        const after = await read();
        return { before, after, version: instance.version() };
    } finally {
        await instance.close();
    }
}

async function withSafariDriver() {
    const base = process.env.WEBDRIVER_URL ?? "http://localhost:4444";
    const call = async (method, route, body) => {
        const response = await fetch(`${base}${route}`, {
            method,
            headers: { "content-type": "application/json" },
            body: body === undefined ? undefined : JSON.stringify(body),
        });
        const json = await response.json();
        if (!response.ok) {
            throw new Error(`${method} ${route}: ${JSON.stringify(json)}`);
        }
        return json.value;
    };
    const session = await call("POST", "/session", {
        capabilities: { alwaysMatch: { browserName: "safari" } },
    });
    const id = session.sessionId;
    try {
        const read = async () => {
            const deadline = Date.now() + timeoutMs;
            while (Date.now() < deadline) {
                const title = await call("GET", `/session/${id}/title`);
                if (isResult(title)) return JSON.parse(title.slice(3));
                await new Promise((resolve) => setTimeout(resolve, 500));
            }
            throw new Error("timed out waiting for the S6 result title");
        };
        await call("POST", `/session/${id}/url`, { url });
        const before = await read();
        await call("POST", `/session/${id}/refresh`, {});
        const after = await read();
        return {
            before,
            after,
            version: session.capabilities?.browserVersion ?? "unknown",
        };
    } finally {
        await call("DELETE", `/session/${id}`).catch(() => {});
    }
}

function summary() {
    const rows = [
        "| Browser | Version | Answer | `app` | `p_spike_state` | `p_spike_cache` | Counters before → after reload | Missing features | crossOriginIsolated |",
        "|---|---|---|---|---|---|---|---|---|",
    ];
    const files = fs.existsSync("results") ? fs.readdirSync("results") : [];
    for (const file of files.sort()) {
        const r = JSON.parse(fs.readFileSync(path.join("results", file), "utf8"));
        if (!r.before) {
            rows.push(`| ${r.browser} | | ${r.answer} | | | | ${r.error} | | |`);
            continue;
        }
        const names = Object.keys(r.before.databases);
        const impl = (name) => {
            const b = r.before.databases[name];
            return b.opened ? b.implementation : `failed: ${b.error}`;
        };
        const counters = names
            .map((n) => `${r.before.databases[n].counter}→${r.after.databases[n]?.counter}`)
            .join(", ");
        const missing = r.before.databases[names[0]].missingFeatures?.join(", ") ?? "";
        rows.push(
            `| ${r.browser} | ${r.version} | ${r.answer} | ${names.map(impl).join(" | ")} | ${counters} | ${missing} | ${r.before.crossOriginIsolated} |`,
        );
    }
    console.log(rows.join("\n"));
}

async function main() {
    if (browser === "summary") return summary();
    fs.mkdirSync("results", { recursive: true });
    const out = path.join("results", `${browser}.json`);
    try {
        const measured =
            browser === "safari"
                ? await withSafariDriver()
                : await withPlaywright(browser);
        const answer = verdict(measured.before, measured.after);
        fs.writeFileSync(out, JSON.stringify({ browser, answer, ...measured }));
        console.log(
            `S6-${browser} before=${JSON.stringify(measured.before)} after=${JSON.stringify(measured.after)} ${answer}`,
        );
    } catch (error) {
        fs.writeFileSync(
            out,
            JSON.stringify({ browser, answer: "unanswerable", error: String(error) }),
        );
        console.log(`S6-${browser} error=${String(error)} unanswerable`);
        process.exitCode = 1;
    }
}

main();
