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

const allOn = {
    offlineAllowLocal: true,
    offlineAllowFederated: true,
    offlineAllowTidal: true,
    offlineAllowYtMusic: true,
    offlineAllowYouTube: true,
};

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

test("Offline downloads group renders saved values and saves changes", async () => {
    const { OfflineDownloadsSection } =
        await import("../../features/settings/components/sections/OfflineDownloadsSection");
    const view = await mountNode((onUpdate) =>
        React.createElement(OfflineDownloadsSection, {
            settings: {
                ...allOn,
                offlineAllowFederated: false,
            } as SystemSettings,
            onUpdate,
        }),
    );
    assert.match(view.container.textContent ?? "", /Offline downloads/);
    assert.match(view.container.textContent ?? "", /Allow offline downloads/);
    assert.match(
        view.container.textContent ?? "",
        /removes already-downloaded songs from devices the next time they sync/,
    );
    assert.equal(
        toggleFor(view.container, "offline-allow-local").checked,
        true,
    );
    assert.equal(
        toggleFor(view.container, "offline-allow-federated").checked,
        false,
    );
    assert.equal(
        toggleFor(view.container, "offline-allow-youtube").checked,
        true,
    );

    await click(toggleFor(view.container, "offline-allow-local"));
    await click(toggleFor(view.container, "offline-allow-federated"));
    await click(toggleFor(view.container, "offline-allow-youtube"));
    assert.deepEqual(view.updates, [
        { offlineAllowLocal: false },
        { offlineAllowFederated: true },
        { offlineAllowYouTube: false },
    ]);
    await view.unmount();
});

test("TIDAL provider settings carry the offline toggle", async () => {
    const { TidalProviderSettings } =
        await import("../../features/settings/components/sections/TidalSection");
    const view = await mountNode((onUpdate) =>
        React.createElement(TidalProviderSettings, {
            settings: {
                ...allOn,
                offlineAllowTidal: false,
                tidalConnected: true,
                tidalUserId: "1",
            } as SystemSettings,
            onUpdate,
            onTest: async () => ({ success: true }),
            isTesting: false,
        }),
    );
    const input = toggleFor(view.container, "offline-allow-tidal");
    assert.equal(input.checked, false);
    await click(input);
    assert.deepEqual(view.updates, [{ offlineAllowTidal: true }]);
    await view.unmount();
});

test("YouTube Music provider settings carry the offline toggle", async () => {
    const { YouTubeMusicProviderSettings } =
        await import("../../features/settings/components/sections/YouTubeMusicSection");
    const view = await mountNode((onUpdate) =>
        React.createElement(YouTubeMusicProviderSettings, {
            settings: { ...allOn } as SystemSettings,
            onUpdate,
        }),
    );
    const input = toggleFor(view.container, "offline-allow-ytmusic");
    assert.equal(input.checked, true);
    await click(input);
    assert.deepEqual(view.updates, [{ offlineAllowYtMusic: false }]);
    await view.unmount();
});

function qualitySelect(container: HTMLElement): HTMLSelectElement {
    const select = container.querySelector<HTMLSelectElement>(
        "#yt-music-source-quality",
    );
    assert.ok(select, "YT Music source quality select renders");
    return select;
}

test("YouTube Music provider settings show and change the source quality", async () => {
    const { YouTubeMusicProviderSettings } =
        await import("../../features/settings/components/sections/YouTubeMusicSection");
    const view = await mountNode((onUpdate) =>
        React.createElement(YouTubeMusicProviderSettings, {
            settings: {
                ...allOn,
                ytMusicQuality: "LOSSLESS",
            } as SystemSettings,
            onUpdate,
        }),
    );
    const select = qualitySelect(view.container);
    assert.equal(select.value, "LOSSLESS");
    assert.match(
        view.container.textContent ?? "",
        /stored at this quality for every user\. A lower quality requested by a user is transcoded from it/,
    );
    await React.act(async () => {
        select.value = "MEDIUM";
        select.dispatchEvent(new Event("change", { bubbles: true }));
    });
    assert.deepEqual(view.updates, [{ ytMusicQuality: "MEDIUM" }]);
    await view.unmount();
});

test("YouTube Music source quality falls back to High when unset", async () => {
    const { YouTubeMusicProviderSettings } =
        await import("../../features/settings/components/sections/YouTubeMusicSection");
    const view = await mountNode((onUpdate) =>
        React.createElement(YouTubeMusicProviderSettings, {
            settings: { ...allOn } as SystemSettings,
            onUpdate,
        }),
    );
    assert.equal(qualitySelect(view.container).value, "HIGH");
    await view.unmount();
});
