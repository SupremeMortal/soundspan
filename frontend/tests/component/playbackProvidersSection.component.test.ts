import assert from "node:assert/strict";
import { after, beforeEach, mock, test } from "node:test";
import React from "react";
import { GlobalRegistrator } from "@happy-dom/global-registrator";
import type { SystemSettings } from "../../features/settings/types";

GlobalRegistrator.register();
(
    globalThis as unknown as { IS_REACT_ACT_ENVIRONMENT?: boolean }
).IS_REACT_ACT_ENVIRONMENT = true;

mock.module("@/lib/api", {
    namedExports: {
        api: {
            tidalDeviceAuth: async () => ({}),
            tidalPollAuth: async () => ({ success: false }),
        },
    },
});

mock.module("@/lib/logger", {
    namedExports: {
        createFrontendLogger: () => ({
            error: () => undefined,
            warn: () => undefined,
            info: () => undefined,
            debug: () => undefined,
        }),
    },
});

after(() => {
    try {
        GlobalRegistrator.unregister();
    } catch {
        // Best-effort teardown.
    }
});

beforeEach(() => {
    document.body.replaceChildren();
});

const baseSettings = {
    playbackProviders: "tidal",
    tidalEnabled: true,
    tidalConnected: true,
    tidalUserId: "12345",
    ytMusicEnabled: false,
    lidarrEnabled: false,
    lidarrUrl: "",
    lidarrApiKey: "",
    soulseekUsername: "",
    soulseekPassword: "",
    soulseekConcurrentDownloads: 4,
    musicPath: "/music",
    downloadPath: "/downloads",
    libraryDeletionEnabled: false,
} as SystemSettings;

async function mount(
    settings: Partial<SystemSettings>,
    peerSettings?: React.ReactNode,
) {
    const { PlaybackProvidersSection } =
        await import("../../features/settings/components/sections/PlaybackProvidersSection");
    const { createRoot } = await import("react-dom/client");
    const updates: Array<Partial<SystemSettings>> = [];
    const container = document.createElement("div");
    document.body.appendChild(container);
    const root = createRoot(container);
    await React.act(async () => {
        root.render(
            React.createElement(PlaybackProvidersSection, {
                settings: { ...baseSettings, ...settings },
                onUpdate: (update: Partial<SystemSettings>) =>
                    updates.push(update),
                onTest: async () => ({ success: true }),
                testingServices: {},
                peerSettings,
            }),
        );
    });
    return {
        container,
        updates,
        unmount: async () => {
            await React.act(async () => root.unmount());
            container.remove();
        },
    };
}

function names(container: HTMLElement, attribute: string): string[] {
    return Array.from(container.querySelectorAll(`[${attribute}]`)).map(
        (row) => row.getAttribute(attribute) ?? "",
    );
}

async function click(element: Element | null): Promise<void> {
    assert.ok(element instanceof HTMLElement, "missing element");
    await React.act(async () => {
        element.click();
    });
}

test("the local library is pinned first, ahead of the active providers", async (t) => {
    const harness = await mount({ playbackProviders: "tidal,lidarr" });
    t.after(harness.unmount);

    assert.deepEqual(names(harness.container, "data-provider"), [
        "pinned",
        "tidal",
        "lidarr",
    ]);
    assert.match(harness.container.textContent ?? "", /Local library/);
    assert.deepEqual(names(harness.container, "data-available-provider"), [
        "ytmusic",
        "soulseek",
    ]);
});

test("providers have no on/off toggle; enabling one adds it to the list", async (t) => {
    const harness = await mount({});
    t.after(harness.unmount);

    assert.equal(harness.container.querySelector("#tidal-enabled"), null);
    assert.equal(harness.container.querySelector("#lidarr-enabled"), null);

    await click(
        harness.container.querySelector('[aria-label="Enable Soulseek"]'),
    );

    assert.deepEqual(harness.updates, [
        {
            playbackProviders: "tidal,soulseek",
            tidalEnabled: true,
            ytMusicEnabled: false,
            lidarrEnabled: false,
        },
    ]);
});

test("a newly enabled provider opens its settings", async (t) => {
    const { useState } = React;
    const { PlaybackProvidersSection } =
        await import("../../features/settings/components/sections/PlaybackProvidersSection");
    const { createRoot } = await import("react-dom/client");
    function Harness() {
        const [settings, setSettings] = useState<SystemSettings>(baseSettings);
        return React.createElement(PlaybackProvidersSection, {
            settings,
            onUpdate: (update: Partial<SystemSettings>) =>
                setSettings((prev) => ({ ...prev, ...update })),
            onTest: async () => ({ success: true }),
            testingServices: {},
        });
    }
    const container = document.createElement("div");
    document.body.appendChild(container);
    const root = createRoot(container);
    await React.act(async () => root.render(React.createElement(Harness)));
    t.after(async () => {
        await React.act(async () => root.unmount());
        container.remove();
    });

    await click(container.querySelector('[aria-label="Enable Soulseek"]'));

    assert.match(container.textContent ?? "", /Concurrent downloads/);
});

test("disabling a provider removes it and turns its flag off", async (t) => {
    const harness = await mount({});
    t.after(harness.unmount);

    await click(
        harness.container.querySelector('[aria-label="Disable TIDAL"]'),
    );

    assert.deepEqual(harness.updates, [
        {
            playbackProviders: "",
            tidalEnabled: false,
            ytMusicEnabled: false,
            lidarrEnabled: false,
        },
    ]);
});

test("peer libraries are hidden without federation but keep their place", async (t) => {
    const harness = await mount({ playbackProviders: "peers,tidal" });
    t.after(harness.unmount);

    assert.deepEqual(names(harness.container, "data-provider"), [
        "pinned",
        "tidal",
    ]);
    await click(
        harness.container.querySelector('[aria-label="Enable Lidarr"]'),
    );
    assert.equal(harness.updates[0]?.playbackProviders, "tidal,lidarr,peers");
});

test("peer libraries can be ordered when federation is on", async (t) => {
    const harness = await mount(
        { playbackProviders: "tidal,peers" },
        React.createElement("p", null, "Federation settings"),
    );
    t.after(harness.unmount);

    await click(
        harness.container.querySelector(
            '[aria-label="Move Peer libraries up"]',
        ),
    );
    assert.equal(harness.updates[0]?.playbackProviders, "peers,tidal");
});
