/** Tabs on the admin settings page, in display order. */
export const ADMIN_TABS = [
    { id: "playback", label: "Playback" },
    { id: "search", label: "Search" },
    { id: "metadata", label: "Metadata" },
    { id: "insights", label: "Insights" },
    { id: "users", label: "Users" },
    { id: "system", label: "System" },
] as const;

/** One admin settings tab. */
export type AdminTab = (typeof ADMIN_TABS)[number]["id"];

/** Admin tabs that hold editable settings and so show the Save button. */
export const ADMIN_TABS_WITH_SAVE: ReadonlySet<AdminTab> = new Set([
    "playback",
    "search",
    "metadata",
    "system",
]);

// Section anchors from the single-page admin layout, so old links still land
// on the tab that holds the section.
const SECTION_TABS: Record<string, AdminTab> = {
    "playback-sources": "playback",
    "download-preferences": "playback",
    "download-services": "playback",
    audiobookshelf: "playback",
    "youtube-music-admin": "playback",
    storage: "playback",
    "library-safety": "playback",
    federation: "playback",
    "search-providers": "search",
    "ai-services": "metadata",
    cache: "metadata",
    "library-health": "insights",
    "library-insights": "insights",
    "queue-dashboard": "insights",
    backup: "system",
};

/** Resolves a URL hash (with or without `#`) to the tab it should open. */
export function resolveAdminTab(hash: string): AdminTab {
    const id = hash.replace(/^#/, "");
    const tab = ADMIN_TABS.find((entry) => entry.id === id);
    if (tab) return tab.id;
    return SECTION_TABS[id] ?? ADMIN_TABS[0].id;
}
