"use client";

import { SettingsRow, SettingsInput, SettingsSelect } from "../ui";
import { SystemSettings } from "../../types";
import { AlertTriangle, ExternalLink } from "lucide-react";
import { InlineStatus } from "@/components/ui/InlineStatus";
import { useConnectionTest } from "@/features/settings/hooks/useConnectionTest";

interface SoulseekProviderSettingsProps {
    settings: SystemSettings;
    onUpdate: (updates: Partial<SystemSettings>) => void;
    onTest: (
        service: string,
    ) => Promise<{ success: boolean; version?: string; error?: string }>;
    isTesting: boolean;
}

const CONCURRENCY_OPTIONS = Array.from({ length: 10 }, (_, index) => {
    const value = String(index + 1);
    return { value, label: value === "4" ? "4 (Default)" : value };
});

/**
 * Soulseek account and download settings, shown inside its Playback provider
 * block.
 */
export function SoulseekProviderSettings({
    settings,
    onUpdate,
    onTest,
    isTesting,
}: SoulseekProviderSettingsProps) {
    const {
        status: testStatus,
        message: testMessage,
        runTest,
        reset,
    } = useConnectionTest({
        loadingMessage: "Connecting...",
        successMessage: "Connected to Soulseek",
    });

    const handleTest = () => runTest(() => onTest("soulseek"));

    const hasCredentials =
        settings.soulseekUsername && settings.soulseekPassword;

    const warningBanner = (
        <div className="flex items-start gap-2 rounded-lg border border-amber-500/30 bg-amber-500/10 px-3 py-2">
            <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <p className="text-xs text-amber-200/80">
                Soulseek is a peer-to-peer network. You are responsible for
                ensuring your use complies with applicable copyright laws. Do
                not use this feature to download or distribute copyrighted
                material without authorization.
            </p>
        </div>
    );

    return (
        <div className="space-y-3">
            {warningBanner}
            <div className="space-y-1">
                <SettingsRow
                    label="Soulseek Username"
                    description={
                        <span className="flex items-center gap-1.5">
                            Your Soulseek account username
                            <a
                                href="https://www.slsknet.org/news/node/1"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center gap-1 text-brand hover:underline"
                            >
                                <ExternalLink className="w-3 h-3" />
                                Create Account
                            </a>
                        </span>
                    }
                >
                    <SettingsInput
                        value={settings.soulseekUsername || ""}
                        onChange={(v) => onUpdate({ soulseekUsername: v })}
                        placeholder="your_username"
                        className="w-64"
                    />
                </SettingsRow>

                <SettingsRow
                    label="Soulseek Password"
                    description="Your Soulseek account password"
                >
                    <SettingsInput
                        type="password"
                        value={settings.soulseekPassword || ""}
                        onChange={(v) => onUpdate({ soulseekPassword: v })}
                        placeholder="your_password"
                        className="w-64"
                    />
                </SettingsRow>

                <SettingsRow
                    label="Concurrent downloads"
                    description="Number of songs Soulseek downloads at the same time"
                >
                    <SettingsSelect
                        value={String(
                            settings.soulseekConcurrentDownloads ?? 4,
                        )}
                        onChange={(v) =>
                            onUpdate({
                                soulseekConcurrentDownloads: parseInt(v, 10),
                            })
                        }
                        options={CONCURRENCY_OPTIONS}
                    />
                </SettingsRow>

                <div className="pt-2 space-y-2">
                    <div className="inline-flex items-center gap-3">
                        <button
                            onClick={handleTest}
                            disabled={isTesting || !hasCredentials}
                            className="px-4 py-1.5 text-sm bg-white text-black font-medium rounded-full
                                hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed transition-transform"
                        >
                            {testStatus === "loading"
                                ? "Connecting..."
                                : "Test Connection"}
                        </button>
                        <InlineStatus
                            status={testStatus}
                            message={testMessage}
                            onClear={reset}
                        />
                    </div>
                    <p className="text-xs text-white/40">
                        Downloads will be saved to your Singles folder
                        automatically
                    </p>
                </div>
            </div>
        </div>
    );
}
