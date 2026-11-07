"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import { useAuth } from "@/lib/auth-context";
import { createFrontendLogger } from "@/lib/logger";
import { RestartModal } from "@/components/ui/RestartModal";
import { useSystemSettings } from "@/features/settings/hooks/useSystemSettings";
import { GradientSpinner } from "@/components/ui/GradientSpinner";
import { InlineStatus, useInlineStatus } from "@/components/ui/InlineStatus";
import { SettingsTabsLayout } from "@/features/settings/components/ui";
import {
    ADMIN_TABS,
    ADMIN_TABS_WITH_SAVE,
    AdminTab,
    resolveAdminTab,
} from "@/features/settings/adminTabs";
import { useFeatures } from "@/lib/features-context";

function renderSectionFallback() {
    return (
        <div className="flex items-center justify-center py-8">
            <GradientSpinner size="sm" />
        </div>
    );
}

const SearchProvidersSection = dynamic(
    () =>
        import("@/features/settings/components/sections/SearchProvidersSection").then(
            (mod) => mod.SearchProvidersSection,
        ),
    { loading: renderSectionFallback },
);

const PlaybackProvidersSection = dynamic(
    () =>
        import("@/features/settings/components/sections/PlaybackProvidersSection").then(
            (mod) => mod.PlaybackProvidersSection,
        ),
    { loading: renderSectionFallback },
);

const MetadataProvidersSection = dynamic(
    () =>
        import("@/features/settings/components/sections/MetadataProvidersSection").then(
            (mod) => mod.MetadataProvidersSection,
        ),
    { loading: renderSectionFallback },
);

const DisplaySection = dynamic(
    () =>
        import("@/features/settings/components/sections/DisplaySection").then(
            (mod) => mod.DisplaySection,
        ),
    { loading: renderSectionFallback },
);

const AudiobookshelfSection = dynamic(
    () =>
        import("@/features/settings/components/sections/AudiobookshelfSection").then(
            (mod) => mod.AudiobookshelfSection,
        ),
    { loading: renderSectionFallback },
);

const LibraryHealthSection = dynamic(
    () =>
        import("@/features/settings/components/sections/LibraryHealthSection").then(
            (mod) => mod.LibraryHealthSection,
        ),
    { loading: renderSectionFallback },
);

const QueueDashboardSection = dynamic(
    () =>
        import("@/features/settings/components/sections/QueueDashboardSection").then(
            (mod) => mod.QueueDashboardSection,
        ),
    { loading: renderSectionFallback },
);

const BackupSection = dynamic(
    () =>
        import("@/features/settings/components/sections/BackupSection").then(
            (mod) => mod.BackupSection,
        ),
    { loading: renderSectionFallback },
);

const LibraryInsightsSection = dynamic(
    () =>
        import("@/features/library-health/components/LibraryInsightsSection").then(
            (mod) => mod.LibraryInsightsSection,
        ),
    { loading: renderSectionFallback },
);

const CacheSection = dynamic(
    () =>
        import("@/features/settings/components/sections/CacheSection").then(
            (mod) => mod.CacheSection,
        ),
    { loading: renderSectionFallback },
);

const UserManagementSection = dynamic(
    () =>
        import("@/features/settings/components/sections/UserManagementSection").then(
            (mod) => mod.UserManagementSection,
        ),
    { loading: renderSectionFallback },
);

const FederationSection = dynamic(
    () =>
        import("@/features/settings/components/sections/FederationSection").then(
            (mod) => mod.FederationSection,
        ),
    { loading: renderSectionFallback },
);

const logger = createFrontendLogger("Admin.Page");

/**
 * Renders the AdminPage component.
 */
export default function AdminPage() {
    const { federation } = useFeatures();
    const { isAuthenticated, isLoading: authLoading, user } = useAuth();
    const router = useRouter();
    const [isSaving, setIsSaving] = useState(false);
    const [showRestartModal, setShowRestartModal] = useState(false);
    const [testingServices, setTestingServices] = useState<
        Record<string, boolean>
    >({});
    const saveStatus = useInlineStatus();
    const [activeTab, setActiveTab] = useState<AdminTab>(ADMIN_TABS[0].id);

    const isAdmin = user?.role === "admin";

    const {
        systemSettings,
        isLoading: systemSettingsLoading,
        changedServices,
        updateSystemSettings,
        saveSystemSettings,
        testService,
        loadError: systemSettingsLoadError,
        loadSystemSettings,
    } = useSystemSettings();

    // Redirect non-admins to /settings
    useEffect(() => {
        if (!authLoading && isAuthenticated && !isAdmin) {
            router.replace("/settings");
        }
    }, [authLoading, isAuthenticated, isAdmin, router]);

    // Open the tab named by the URL hash, including old section anchors.
    useEffect(() => {
        const syncFromHash = () =>
            setActiveTab(resolveAdminTab(window.location.hash));
        syncFromHash();
        window.addEventListener("hashchange", syncFromHash);
        return () => window.removeEventListener("hashchange", syncFromHash);
    }, []);

    const handleTabChange = useCallback((tab: AdminTab) => {
        setActiveTab(tab);
        window.history.replaceState(null, "", `#${tab}`);
    }, []);

    const handleSaveAll = useCallback(async () => {
        if (!systemSettings) return;

        setIsSaving(true);
        saveStatus.setLoading();

        try {
            const changedSystemServices =
                (await saveSystemSettings(systemSettings)) || [];
            setIsSaving(false);
            saveStatus.setSuccess("Saved");
            if (changedSystemServices.length > 0) {
                setShowRestartModal(true);
            }
        } catch (error) {
            logger.error("Failed to save system settings from admin page", {
                error,
            });
            setIsSaving(false);
            saveStatus.setError("Failed to save");
        }
    }, [systemSettings, saveSystemSettings, saveStatus]);

    const handleTestService = useCallback(
        async (service: string) => {
            setTestingServices((prev) => ({ ...prev, [service]: true }));
            try {
                return await testService(service);
            } finally {
                setTestingServices((prev) => ({ ...prev, [service]: false }));
            }
        },
        [testService],
    );

    if (authLoading) {
        return (
            <div className="flex items-center justify-center min-h-screen bg-surface">
                <GradientSpinner size="md" />
            </div>
        );
    }

    if (!isAuthenticated || !isAdmin) {
        return null;
    }

    if (systemSettingsLoading) {
        return (
            <div className="flex items-center justify-center min-h-screen bg-surface">
                <GradientSpinner size="md" />
            </div>
        );
    }

    if (systemSettingsLoadError || !systemSettings) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen bg-surface gap-4 px-4">
                <p className="text-red-400 text-sm text-center">
                    Failed to load settings from the server. Settings cannot be
                    edited until they are loaded.
                </p>
                <button
                    onClick={() => loadSystemSettings()}
                    className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white text-sm rounded-full transition-colors"
                >
                    Retry
                </button>
            </div>
        );
    }

    return (
        <>
            <SettingsTabsLayout
                title="Admin"
                tabs={ADMIN_TABS}
                activeTab={activeTab}
                onTabChange={handleTabChange}
            >
                {activeTab === "playback" && (
                    <>
                        <PlaybackProvidersSection
                            settings={systemSettings}
                            onUpdate={updateSystemSettings}
                            onTest={handleTestService}
                            testingServices={testingServices}
                            peerSettings={
                                federation ? (
                                    <FederationSection
                                        settings={systemSettings}
                                        onUpdateSettings={updateSystemSettings}
                                    />
                                ) : undefined
                            }
                        />
                        <AudiobookshelfSection
                            settings={systemSettings}
                            onUpdate={updateSystemSettings}
                            onTest={handleTestService}
                            isTesting={testingServices.audiobookshelf || false}
                        />
                    </>
                )}

                {activeTab === "search" && (
                    <SearchProvidersSection
                        settings={systemSettings}
                        onUpdate={updateSystemSettings}
                        onTest={handleTestService}
                        testingServices={testingServices}
                    />
                )}

                {activeTab === "metadata" && (
                    <>
                        <MetadataProvidersSection
                            settings={systemSettings}
                            onUpdate={updateSystemSettings}
                            onTest={handleTestService}
                            testingServices={testingServices}
                        />
                        <CacheSection
                            settings={systemSettings}
                            onUpdate={updateSystemSettings}
                        />
                    </>
                )}

                {activeTab === "insights" && (
                    <>
                        <LibraryHealthSection />
                        <LibraryInsightsSection />
                        <QueueDashboardSection />
                    </>
                )}

                {activeTab === "users" && <UserManagementSection />}

                {activeTab === "system" && (
                    <>
                        <DisplaySection
                            settings={systemSettings}
                            onUpdate={updateSystemSettings}
                        />
                        <BackupSection />
                    </>
                )}

                {ADMIN_TABS_WITH_SAVE.has(activeTab) && (
                    <div className="sticky bottom-0 pt-8 pb-8">
                        <div className="relative">
                            <button
                                onClick={handleSaveAll}
                                disabled={isSaving}
                                className="w-full bg-white text-black font-semibold py-3 px-4 rounded-full
                                    hover:scale-[1.02] active:scale-[0.98] transition-transform
                                    disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
                            >
                                {isSaving ? "Saving..." : "Save"}
                            </button>
                            <div className="absolute -bottom-6 left-1/2 -translate-x-1/2 bg-surface/90 backdrop-blur-sm px-3 py-0.5 rounded-full">
                                <InlineStatus {...saveStatus.props} />
                            </div>
                        </div>
                    </div>
                )}
            </SettingsTabsLayout>

            <RestartModal
                isOpen={showRestartModal}
                onClose={() => setShowRestartModal(false)}
                changedServices={changedServices}
            />
        </>
    );
}
