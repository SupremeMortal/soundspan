import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";

const repoRoot = path.resolve(import.meta.dirname, "../../..");
const script = path.join(repoRoot, "scripts/ci/ensure-ubuntu-apt-sources.sh");

const ubuntuPolicy = `Package files:
 100 /var/lib/dpkg/status
     release a=now
 500 http://azure.archive.ubuntu.com/ubuntu resolute/main amd64 Packages
     release v=26.04,o=Ubuntu,a=resolute,n=resolute,l=Ubuntu,c=main,b=amd64
     origin azure.archive.ubuntu.com
`;

const microsoftOnlyPolicy = `Package files:
 100 /var/lib/dpkg/status
     release a=now
 500 https://packages.microsoft.com/ubuntu/26.04/prod resolute/main amd64 Packages
     release o=microsoft-ubuntu-resolute-prod resolute,a=resolute,n=resolute,l=microsoft-ubuntu-resolute-prod resolute,c=main,b=amd64
     origin packages.microsoft.com
`;

// Stub apt-get, apt-cache and dpkg. apt-get logs its arguments; apt-cache
// answers `policy` with policy.txt, or with the Ubuntu policy once a
// sources file exists in the sources directory.
function setUp(t, { policy, arch = "amd64", mirrors }) {
    const directory = fs.mkdtempSync(
        path.join(os.tmpdir(), "soundspan-apt-sources-test-"),
    );
    t.after(() => fs.rmSync(directory, { recursive: true }));
    const bin = path.join(directory, "bin");
    const sources = path.join(directory, "sources.list.d");
    fs.mkdirSync(bin);
    fs.mkdirSync(sources);
    fs.writeFileSync(path.join(directory, "policy.txt"), policy);
    fs.writeFileSync(
        path.join(directory, "os-release"),
        'NAME="Ubuntu"\nID=ubuntu\nVERSION_ID="26.04"\nVERSION_CODENAME=resolute\n',
    );
    const stub = (name, body) =>
        fs.writeFileSync(
            path.join(bin, name),
            `#!/usr/bin/env bash\n${body}\n`,
            { mode: 0o755 },
        );
    stub("apt-get", `echo "$*" >> "${directory}/apt-get.log"`);
    stub(
        "apt-cache",
        `if ls "${sources}"/*.sources >/dev/null 2>&1; then printf '%s' ${JSON.stringify(ubuntuPolicy)}; else cat "${directory}/policy.txt"; fi`,
    );
    stub("dpkg", `echo ${arch}`);
    const mirrorsFile = path.join(directory, "apt-mirrors.txt");
    if (mirrors !== undefined) fs.writeFileSync(mirrorsFile, mirrors);
    return { directory, bin, sources, mirrorsFile };
}

function run({ directory, bin, sources, mirrorsFile }) {
    const result = spawnSync("bash", [script], {
        encoding: "utf8",
        env: {
            ...process.env,
            PATH: `${bin}:${process.env.PATH}`,
            APT_SOURCES_DIR: sources,
            OS_RELEASE_FILE: path.join(directory, "os-release"),
            APT_MIRRORS_FILE: mirrorsFile,
        },
    });
    const log = path.join(directory, "apt-get.log");
    return {
        ...result,
        aptGetCalls: fs.existsSync(log)
            ? fs.readFileSync(log, "utf8").trim().split("\n")
            : [],
        written: fs.readdirSync(sources),
        mirrors: fs.existsSync(mirrorsFile)
            ? fs.readFileSync(mirrorsFile, "utf8")
            : undefined,
    };
}

test("leaves the sources alone when an Ubuntu archive is configured", (t) => {
    const env = setUp(t, { policy: ubuntuPolicy });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(result.aptGetCalls, ["update"]);
    assert.deepEqual(result.written, []);
});

test("adds the Ubuntu archive for the image's codename when none is configured", (t) => {
    const env = setUp(t, { policy: microsoftOnlyPolicy });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.deepEqual(result.aptGetCalls, ["update", "update"]);
    assert.deepEqual(result.written, ["ubuntu-archive.sources"]);
    const written = fs.readFileSync(
        path.join(env.sources, "ubuntu-archive.sources"),
        "utf8",
    );
    assert.match(written, /^URIs: http:\/\/archive\.ubuntu\.com\/ubuntu$/m);
    assert.match(
        written,
        /^Suites: resolute resolute-updates resolute-backports$/m,
    );
    assert.match(written, /^URIs: http:\/\/security\.ubuntu\.com\/ubuntu$/m);
    assert.match(written, /^Suites: resolute-security$/m);
    assert.match(written, /^Components: main restricted universe multiverse$/m);
    assert.match(
        written,
        /^Signed-By: \/usr\/share\/keyrings\/ubuntu-archive-keyring\.gpg$/m,
    );
});

test("uses the ports archive on architectures other than amd64", (t) => {
    const env = setUp(t, { policy: microsoftOnlyPolicy, arch: "arm64" });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    const written = fs.readFileSync(
        path.join(env.sources, "ubuntu-archive.sources"),
        "utf8",
    );
    assert.match(written, /^URIs: http:\/\/ports\.ubuntu\.com\/ubuntu-ports$/m);
    assert.doesNotMatch(written, /security\.ubuntu\.com/);
});

const ec2Mirrors = [
    "http://us-east-2.ec2.archive.ubuntu.com/ubuntu/\tpriority:1",
    "https://archive.ubuntu.com/ubuntu/\tpriority:2",
    "https://security.ubuntu.com/ubuntu/\tpriority:3",
    "",
].join("\n");

test("drops an EC2 mirror from the apt mirror list before updating", (t) => {
    const env = setUp(t, { policy: ubuntuPolicy, mirrors: ec2Mirrors });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(
        result.mirrors,
        [
            "https://archive.ubuntu.com/ubuntu/\tpriority:2",
            "https://security.ubuntu.com/ubuntu/\tpriority:3",
            "",
        ].join("\n"),
    );
    assert.deepEqual(result.aptGetCalls, ["update"]);
    assert.match(result.stderr, /us-east-2\.ec2\.archive\.ubuntu\.com/);
});

test("falls back to the Ubuntu archive when the mirror list holds only an EC2 mirror", (t) => {
    const env = setUp(t, {
        policy: ubuntuPolicy,
        mirrors:
            "http://us-east-2.ec2.archive.ubuntu.com/ubuntu/\tpriority:1\n",
    });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(
        result.mirrors,
        "http://archive.ubuntu.com/ubuntu/\tpriority:1\n",
    );
});

test("leaves a mirror list without an EC2 mirror unchanged", (t) => {
    const azureMirrors = [
        "http://azure.archive.ubuntu.com/ubuntu/\tpriority:1",
        "https://archive.ubuntu.com/ubuntu/\tpriority:2",
        "https://security.ubuntu.com/ubuntu/\tpriority:3",
        "",
    ].join("\n");
    const env = setUp(t, { policy: ubuntuPolicy, mirrors: azureMirrors });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.mirrors, azureMirrors);
    assert.equal(result.stderr, "");
});

test("does not create a mirror list when the runner has none", (t) => {
    const env = setUp(t, { policy: ubuntuPolicy });
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.mirrors, undefined);
});
