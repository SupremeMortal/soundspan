"use client";

import { KeyboardEvent, ReactNode, useRef } from "react";

/** One tab in a tabbed settings page. */
export interface SettingsTab<T extends string> {
    id: T;
    label: string;
}

interface SettingsTabsLayoutProps<T extends string> {
    title: string;
    tabs: readonly SettingsTab<T>[];
    activeTab: T;
    onTabChange: (tab: T) => void;
    children: ReactNode;
}

/**
 * Settings page with a tab bar across the top and the active tab's content
 * at full width below it.
 */
export function SettingsTabsLayout<T extends string>({
    title,
    tabs,
    activeTab,
    onTabChange,
    children,
}: SettingsTabsLayoutProps<T>) {
    const tabRefs = useRef(new Map<T, HTMLButtonElement>());

    // Arrow keys move between tabs, per the WAI-ARIA tabs pattern.
    const handleKeyDown = (event: KeyboardEvent<HTMLButtonElement>) => {
        const offset =
            event.key === "ArrowRight" ? 1 : event.key === "ArrowLeft" ? -1 : 0;
        if (offset === 0) return;
        event.preventDefault();
        const index = tabs.findIndex((tab) => tab.id === activeTab);
        const next = tabs[(index + offset + tabs.length) % tabs.length];
        onTabChange(next.id);
        tabRefs.current.get(next.id)?.focus();
    };

    return (
        <div className="min-h-screen bg-surface relative">
            <div className="absolute inset-0 pointer-events-none bg-gradient-to-b from-surface-highlight/40 via-surface to-surface" />

            <div className="relative max-w-5xl mx-auto px-4 md:px-8 py-8">
                <h1 className="text-2xl font-bold text-white mb-3">{title}</h1>

                {/* The bar sticks while scrolling; the pill track scrolls
                    sideways on narrow screens without showing a scrollbar. */}
                <div className="sticky top-0 z-10 mb-8 py-3">
                    <div
                        role="tablist"
                        aria-label={`${title} sections`}
                        className="scrollbar-hide flex w-fit max-w-full gap-1 overflow-x-auto rounded-full border border-white/10 bg-surface-hover/80 p-1 shadow-lg shadow-black/20 backdrop-blur-md"
                    >
                        {tabs.map((tab) => {
                            const selected = tab.id === activeTab;
                            return (
                                <button
                                    key={tab.id}
                                    ref={(node) => {
                                        if (node)
                                            tabRefs.current.set(tab.id, node);
                                        else tabRefs.current.delete(tab.id);
                                    }}
                                    type="button"
                                    role="tab"
                                    id={`settings-tab-${tab.id}`}
                                    aria-selected={selected}
                                    aria-controls={`settings-panel-${tab.id}`}
                                    tabIndex={selected ? 0 : -1}
                                    onClick={() => onTabChange(tab.id)}
                                    onKeyDown={handleKeyDown}
                                    className={`shrink-0 rounded-full px-4 py-1.5 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/40 ${
                                        selected
                                            ? "bg-white text-black shadow-sm"
                                            : "text-gray-400 hover:bg-white/[0.06] hover:text-white"
                                    }`}
                                >
                                    {tab.label}
                                </button>
                            );
                        })}
                    </div>
                </div>

                <main
                    role="tabpanel"
                    id={`settings-panel-${activeTab}`}
                    aria-labelledby={`settings-tab-${activeTab}`}
                    className="min-w-0"
                >
                    {children}
                </main>
            </div>
        </div>
    );
}
