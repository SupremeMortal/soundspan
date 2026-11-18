import assert from "node:assert/strict";
import { after, mock, test } from "node:test";
import React from "react";
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
(
    globalThis as unknown as { IS_REACT_ACT_ENVIRONMENT?: boolean }
).IS_REACT_ACT_ENVIRONMENT = true;

const nothing = () => null;

mock.module("next/navigation", {
    namedExports: { useSearchParams: () => new URLSearchParams() },
});

mock.module("next/dynamic", { defaultExport: () => nothing });

mock.module("next/link", {
    defaultExport: ({
        href,
        children,
        ...rest
    }: {
        href: string;
        children: React.ReactNode;
    } & Record<string, unknown>) =>
        React.createElement("a", { href, ...rest }, children),
});

mock.module("@/lib/auth-context", {
    namedExports: {
        useAuth: () => ({ isAuthenticated: true, isLoading: false }),
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

mock.module("@/features/settings/hooks/useSettingsData", {
    namedExports: {
        useSettingsData: () => ({
            settings: {},
            isLoading: false,
            updateSettings: () => undefined,
            saveSettings: async () => undefined,
            loadSettings: async () => undefined,
        }),
    },
});

for (const [path, name] of [
    ["AccountSection", "AccountSection"],
    ["SignInSecuritySection", "SignInSecuritySection"],
    ["SocialSection", "SocialSection"],
    ["PlaybackSection", "PlaybackSection"],
    ["IntegrationsSection", "IntegrationsSection"],
]) {
    mock.module(`@/features/settings/components/sections/${path}`, {
        namedExports: { [name]: nothing },
    });
}

after(() => {
    try {
        GlobalRegistrator.unregister();
    } catch {
        // Best-effort teardown.
    }
});

test("the Settings page links to the Link Device page", async (t) => {
    const { default: SettingsPage } = await import("../../app/settings/page");
    const { createRoot } = await import("react-dom/client");
    const container = document.createElement("div");
    document.body.appendChild(container);
    const root = createRoot(container);
    t.after(async () => {
        await React.act(async () => root.unmount());
        container.remove();
    });

    await React.act(async () => {
        root.render(React.createElement(SettingsPage));
        await Promise.resolve();
    });

    const section = document.getElementById("link-device");
    assert.ok(section, "Missing the Link Device section");
    const link = Array.from(section.querySelectorAll("a")).find(
        (anchor) => anchor.getAttribute("href") === "/device",
    );
    assert.ok(link, "Missing a link to /device");
    assert.equal(link.textContent?.trim(), "Link Device");

    const sidebarEntry = Array.from(document.querySelectorAll("button")).find(
        (button) => button.textContent?.trim() === "Link Device",
    );
    assert.ok(sidebarEntry, "Missing the Link Device sidebar entry");
});
