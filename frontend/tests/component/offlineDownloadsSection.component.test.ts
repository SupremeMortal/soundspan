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

async function mountNode(
    build: (
        onUpdate: (u: Partial<SystemSettings>) => void,
    ) => React.ReactElement,
) {
    const { createRoot } = await import("react-dom/client");
    const updates: Array<Partial<SystemSettings>> = [];
    const container = document.createElement("div");
    document.body.appendChild(container);
    const root = createRoot(container);
    await React.act(async () => {
        root.render(build((u) => updates.push(u)));
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

function toggleFor(container: HTMLElement, id: string): HTMLInputElement {
    const input = container.querySelector<HTMLInputElement>(`#${id}`);
    assert.ok(input, `toggle #${id} renders`);
    return input;
}

async function click(input: HTMLInputElement) {
    await React.act(async () => {
        input.click();
    });
}

async function mountSection(settings: Partial<SystemSettings>) {
    const { OfflineDownloadsSection } =
        await import("../../features/settings/components/sections/OfflineDownloadsSection");
    return mountNode((onUpdate) =>
        React.createElement(OfflineDownloadsSection, {
            settings: settings as SystemSettings,
            onUpdate,
        }),
    );
}

test("Offline downloads section has one switch for every source", async () => {
    const view = await mountSection({ offlineDownloadsEnabled: true });
    const text = view.container.textContent ?? "";
    assert.match(text, /Offline downloads/);
    assert.match(text, /Allow offline downloads/);
    assert.match(
        text,
        /removes already-downloaded songs from devices the next time they sync/,
    );
    assert.equal(
        view.container.querySelectorAll('input[type="checkbox"]').length,
        1,
    );
    const input = toggleFor(view.container, "offline-downloads-enabled");
    assert.equal(input.checked, true);
    await click(input);
    assert.deepEqual(view.updates, [{ offlineDownloadsEnabled: false }]);
    await view.unmount();
});

test("Offline downloads switch shows a saved off value and turns it on", async () => {
    const view = await mountSection({ offlineDownloadsEnabled: false });
    const input = toggleFor(view.container, "offline-downloads-enabled");
    assert.equal(input.checked, false);
    await click(input);
    assert.deepEqual(view.updates, [{ offlineDownloadsEnabled: true }]);
    await view.unmount();
});

test("Offline downloads switch is on when the setting is unset", async () => {
    const view = await mountSection({});
    assert.equal(
        toggleFor(view.container, "offline-downloads-enabled").checked,
        true,
    );
    await view.unmount();
});

test("Provider blocks carry no per-source offline switch or source quality", async () => {
    const { TidalProviderSettings } =
        await import("../../features/settings/components/sections/TidalSection");
    const { YouTubeMusicProviderSettings } =
        await import("../../features/settings/components/sections/YouTubeMusicSection");
    const tidal = await mountNode((onUpdate) =>
        React.createElement(TidalProviderSettings, {
            settings: {
                offlineDownloadsEnabled: true,
                tidalConnected: true,
                tidalUserId: "1",
            } as SystemSettings,
            onUpdate,
            onTest: async () => ({ success: true }),
            isTesting: false,
        }),
    );
    const ytm = await mountNode((onUpdate) =>
        React.createElement(YouTubeMusicProviderSettings, {
            settings: { offlineDownloadsEnabled: true } as SystemSettings,
            onUpdate,
        }),
    );
    for (const view of [tidal, ytm]) {
        assert.doesNotMatch(
            view.container.textContent ?? "",
            /Allow offline downloads/,
        );
        assert.equal(
            view.container.querySelector("#yt-music-source-quality"),
            null,
        );
        await view.unmount();
    }
});
