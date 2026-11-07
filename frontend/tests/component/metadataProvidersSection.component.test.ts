import assert from "node:assert/strict";
import { after, beforeEach, test } from "node:test";
import React from "react";
import { GlobalRegistrator } from "@happy-dom/global-registrator";
import type { SystemSettings } from "../../features/settings/types";

GlobalRegistrator.register();
(
    globalThis as unknown as { IS_REACT_ACT_ENVIRONMENT?: boolean }
).IS_REACT_ACT_ENVIRONMENT = true;

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
    artistImageProviders: "fanart,lastfm",
    albumCoverProviders: "coverartarchive,fanart",
    fanartApiKey: "",
    lastfmApiKey: "",
} as SystemSettings;

async function mount() {
    const { MetadataProvidersSection } =
        await import("../../features/settings/components/sections/MetadataProvidersSection");
    const { createRoot } = await import("react-dom/client");
    const updates: Array<Partial<SystemSettings>> = [];
    const tested: string[] = [];
    const container = document.createElement("div");
    document.body.appendChild(container);
    const root = createRoot(container);
    await React.act(async () => {
        root.render(
            React.createElement(MetadataProvidersSection, {
                settings: baseSettings,
                onUpdate: (update: Partial<SystemSettings>) =>
                    updates.push(update),
                onTest: async (service: string) => {
                    tested.push(service);
                    return { success: true };
                },
                testingServices: {},
            }),
        );
    });
    return {
        container,
        updates,
        tested,
        unmount: async () => {
            await React.act(async () => root.unmount());
            container.remove();
        },
    };
}

async function click(element: Element | null): Promise<void> {
    assert.ok(element instanceof HTMLElement, "missing element");
    await React.act(async () => {
        element.click();
    });
}

async function type(input: HTMLInputElement, value: string): Promise<void> {
    await React.act(async () => {
        const setter = Object.getOwnPropertyDescriptor(
            HTMLInputElement.prototype,
            "value",
        )?.set;
        setter?.call(input, value);
        input.dispatchEvent(new Event("input", { bubbles: true }));
    });
}

function board(container: HTMLElement, name: string): HTMLElement {
    const element = container.querySelector(`[data-provider-board="${name}"]`);
    assert.ok(element instanceof HTMLElement, `missing board ${name}`);
    return element;
}

test("the Fanart.tv block in a list holds the Fanart.tv API key", async (t) => {
    const harness = await mount();
    t.after(harness.unmount);
    const covers = board(harness.container, "album-covers");

    await click(covers.querySelector('[aria-label="Show Fanart.tv settings"]'));
    const input = covers.querySelector<HTMLInputElement>(
        "#album-covers-fanart-api-key",
    );
    assert.ok(input, "expected the key inside the Fanart.tv block");
    await type(input, "secret");

    assert.deepEqual(harness.updates, [{ fanartApiKey: "secret" }]);
});

test("the Last.fm block holds the Last.fm API key", async (t) => {
    const harness = await mount();
    t.after(harness.unmount);
    const artists = board(harness.container, "artist-images");

    await click(artists.querySelector('[aria-label="Show Last.fm settings"]'));

    assert.ok(artists.querySelector("#artist-images-lastfm-api-key"));
});

test("providers without a key have no settings to open", async (t) => {
    const harness = await mount();
    t.after(harness.unmount);
    const covers = board(harness.container, "album-covers");

    assert.equal(
        covers.querySelector('[aria-label="Show Cover Art Archive settings"]'),
        null,
    );
});

test("key fields stay out of the page until a provider block is opened", async (t) => {
    const harness = await mount();
    t.after(harness.unmount);

    assert.equal(
        harness.container.querySelector('input[type="password"]'),
        null,
    );
    assert.doesNotMatch(harness.container.textContent ?? "", /Provider Keys/);
});
