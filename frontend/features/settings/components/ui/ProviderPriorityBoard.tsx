"use client";

import { DragEvent, Fragment, ReactNode, useState } from "react";
import {
    ChevronDown,
    ChevronRight,
    ChevronUp,
    GripVertical,
    Plus,
    X,
} from "lucide-react";
import {
    insertProvider,
    moveProvider,
    removeProvider,
} from "../../providerPriority";

/** Status line shown under a provider's name. */
export interface ProviderStatus {
    text: string;
    tone: "ok" | "warn" | "muted";
}

/** One provider the board can place in the priority list. */
export interface ProviderDefinition<T extends string> {
    id: T;
    label: string;
    description: string;
    icon?: ReactNode;
    status?: ProviderStatus;
    /** Configuration shown inside the block while the provider is active. */
    renderSettings?: () => ReactNode;
}

interface ProviderPriorityBoardProps<T extends string> {
    /** Prefix for element ids and test hooks, such as "playback". */
    name: string;
    providers: readonly ProviderDefinition<T>[];
    /** Active providers in priority order. */
    active: readonly T[];
    onChange: (next: T[]) => void;
    /** A fixed block shown above the active providers, such as the library. */
    pinned?: ReactNode;
    activeLabel?: string;
    emptyText?: string;
}

const DRAG_TYPE = "application/x-soundspan-provider";

const STATUS_TONE: Record<ProviderStatus["tone"], string> = {
    ok: "text-green-400",
    warn: "text-amber-300",
    muted: "text-gray-400",
};

/**
 * Drag-ordered provider list. Providers in the list are enabled, in priority
 * order; dragging one in from Available enables it and dragging it back out
 * disables it. Every drag action also has a button for keyboard use.
 */
export function ProviderPriorityBoard<T extends string>({
    name,
    providers,
    active,
    onChange,
    pinned,
    activeLabel = "Priority",
    emptyText = "No providers active. Drag one here to enable it.",
}: ProviderPriorityBoardProps<T>) {
    const [expanded, setExpanded] = useState<ReadonlySet<T>>(new Set());
    const [dropIndex, setDropIndex] = useState<number | null>(null);
    const [poolHover, setPoolHover] = useState(false);

    const byId = new Map(providers.map((provider) => [provider.id, provider]));
    const activeDefs = active
        .map((id) => byId.get(id))
        .filter((def): def is ProviderDefinition<T> => def !== undefined);
    const inactiveDefs = providers.filter((def) => !active.includes(def.id));
    const visibleActive = activeDefs.map((def) => def.id);
    // Stored entries without a definition (a hidden provider) keep their place
    // at the end so editing the visible list never drops them.
    const hidden = active.filter((id) => !byId.has(id));
    const commit = (next: T[]) => onChange([...next, ...hidden]);

    const toggleExpanded = (id: T, open?: boolean) =>
        setExpanded((prev) => {
            const next = new Set(prev);
            if (open ?? !next.has(id)) next.add(id);
            else next.delete(id);
            return next;
        });

    const enable = (id: T, index = visibleActive.length) => {
        commit(insertProvider(visibleActive, id, index));
        if (!visibleActive.includes(id) && byId.get(id)?.renderSettings) {
            toggleExpanded(id, true);
        }
    };
    const disable = (id: T) => {
        commit(removeProvider(visibleActive, id));
        toggleExpanded(id, false);
    };

    const readDragged = (event: DragEvent): T | null => {
        const id = event.dataTransfer.getData(DRAG_TYPE) as T;
        return byId.has(id) ? id : null;
    };
    const startDrag = (event: DragEvent, id: T) => {
        event.dataTransfer.setData(DRAG_TYPE, id);
        event.dataTransfer.effectAllowed = "move";
    };
    const overItem = (event: DragEvent<HTMLElement>, index: number) => {
        if (!event.dataTransfer.types.includes(DRAG_TYPE)) return;
        event.preventDefault();
        const rect = event.currentTarget.getBoundingClientRect();
        const after = event.clientY > rect.top + rect.height / 2;
        setDropIndex(after ? index + 1 : index);
    };
    const dropOnList = (event: DragEvent) => {
        event.preventDefault();
        const id = readDragged(event);
        const index = dropIndex ?? visibleActive.length;
        setDropIndex(null);
        if (id) enable(id, index);
    };
    const dropOnPool = (event: DragEvent) => {
        event.preventDefault();
        setPoolHover(false);
        const id = readDragged(event);
        if (id && visibleActive.includes(id)) disable(id);
    };
    const endDrag = () => {
        setDropIndex(null);
        setPoolHover(false);
    };

    const dropLine = (index: number) =>
        dropIndex === index ? (
            <li aria-hidden className="h-0.5 rounded-full bg-brand" />
        ) : null;

    return (
        <div className="space-y-5" data-provider-board={name}>
            <div>
                <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-400">
                    {activeLabel}
                </p>
                <ol
                    aria-label={`${activeLabel} providers`}
                    className="space-y-2"
                    onDragOver={(event) => {
                        if (event.dataTransfer.types.includes(DRAG_TYPE)) {
                            event.preventDefault();
                        }
                    }}
                    onDragLeave={(event) => {
                        if (
                            !event.currentTarget.contains(
                                event.relatedTarget as Node | null,
                            )
                        ) {
                            setDropIndex(null);
                        }
                    }}
                    onDrop={dropOnList}
                >
                    {pinned && <li>{pinned}</li>}
                    {activeDefs.map((def, index) => {
                        const isOpen = expanded.has(def.id);
                        const rank = index + 1 + (pinned ? 1 : 0);
                        return (
                            <Fragment key={def.id}>
                                {dropLine(index)}
                                <li
                                    data-provider={def.id}
                                    onDragOver={(event) =>
                                        overItem(event, index)
                                    }
                                    className="rounded-lg border border-white/[0.06] bg-surface-hover"
                                >
                                    {/* Only the header drags, so text in the
                                        settings below stays selectable. */}
                                    <div
                                        role="group"
                                        aria-label={def.label}
                                        draggable
                                        onDragStart={(event) =>
                                            startDrag(event, def.id)
                                        }
                                        onDragEnd={endDrag}
                                        className="flex items-center gap-2 px-3 py-3"
                                    >
                                        <GripVertical
                                            aria-hidden
                                            className="h-4 w-4 shrink-0 cursor-grab text-gray-500"
                                        />
                                        <span className="w-5 shrink-0 text-center text-sm tabular-nums text-gray-400">
                                            {rank}
                                        </span>
                                        <ProviderHeading def={def} />
                                        <div className="flex shrink-0 items-center">
                                            <IconButton
                                                label={`Move ${def.label} up`}
                                                disabled={index === 0}
                                                onClick={() =>
                                                    commit(
                                                        moveProvider(
                                                            visibleActive,
                                                            index,
                                                            index - 1,
                                                        ),
                                                    )
                                                }
                                            >
                                                <ChevronUp className="h-4 w-4" />
                                            </IconButton>
                                            <IconButton
                                                label={`Move ${def.label} down`}
                                                disabled={
                                                    index ===
                                                    activeDefs.length - 1
                                                }
                                                onClick={() =>
                                                    commit(
                                                        moveProvider(
                                                            visibleActive,
                                                            index,
                                                            index + 1,
                                                        ),
                                                    )
                                                }
                                            >
                                                <ChevronDown className="h-4 w-4" />
                                            </IconButton>
                                            {def.renderSettings && (
                                                <IconButton
                                                    label={`${isOpen ? "Hide" : "Show"} ${def.label} settings`}
                                                    expanded={isOpen}
                                                    onClick={() =>
                                                        toggleExpanded(def.id)
                                                    }
                                                >
                                                    <ChevronRight
                                                        className={`h-4 w-4 transition-transform ${isOpen ? "rotate-90" : ""}`}
                                                    />
                                                </IconButton>
                                            )}
                                            <IconButton
                                                label={`Disable ${def.label}`}
                                                onClick={() => disable(def.id)}
                                            >
                                                <X className="h-4 w-4" />
                                            </IconButton>
                                        </div>
                                    </div>
                                    {isOpen && def.renderSettings && (
                                        <div className="border-t border-white/5 px-4 pb-4 pt-3">
                                            {def.renderSettings()}
                                        </div>
                                    )}
                                </li>
                            </Fragment>
                        );
                    })}
                    {dropLine(activeDefs.length)}
                    {activeDefs.length === 0 && (
                        <li
                            className="rounded-lg border border-dashed border-white/10 px-4 py-6 text-center text-sm text-gray-400"
                            onDragOver={(event) => overItem(event, 0)}
                        >
                            {emptyText}
                        </li>
                    )}
                </ol>
            </div>

            {inactiveDefs.length > 0 && (
                <div>
                    <p className="mb-2 text-xs font-semibold uppercase tracking-wider text-gray-400">
                        Available
                    </p>
                    <ul
                        aria-label="Available providers"
                        onDragOver={(event) => {
                            if (event.dataTransfer.types.includes(DRAG_TYPE)) {
                                event.preventDefault();
                                setPoolHover(true);
                            }
                        }}
                        onDragLeave={() => setPoolHover(false)}
                        onDrop={dropOnPool}
                        className={`grid gap-2 rounded-lg p-1 transition-colors sm:grid-cols-2 ${
                            poolHover ? "bg-white/[0.04]" : ""
                        }`}
                    >
                        {inactiveDefs.map((def) => (
                            <li
                                key={def.id}
                                data-available-provider={def.id}
                                draggable
                                onDragStart={(event) =>
                                    startDrag(event, def.id)
                                }
                                onDragEnd={endDrag}
                                className="flex items-center gap-2 rounded-lg border border-dashed border-white/10 px-3 py-2.5"
                            >
                                <GripVertical
                                    aria-hidden
                                    className="h-4 w-4 shrink-0 cursor-grab text-gray-500"
                                />
                                <ProviderHeading def={def} muted />
                                <IconButton
                                    label={`Enable ${def.label}`}
                                    onClick={() => enable(def.id)}
                                >
                                    <Plus className="h-4 w-4" />
                                </IconButton>
                            </li>
                        ))}
                    </ul>
                </div>
            )}
        </div>
    );
}

function ProviderHeading<T extends string>({
    def,
    muted = false,
}: {
    def: ProviderDefinition<T>;
    muted?: boolean;
}) {
    return (
        <>
            {def.icon && (
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-surface-highlight">
                    {def.icon}
                </div>
            )}
            <div className="min-w-0 flex-1">
                <p
                    className={`text-sm font-medium ${muted ? "text-gray-300" : "text-white"}`}
                >
                    {def.label}
                </p>
                <p className="text-xs text-gray-400">
                    {!muted && def.status ? (
                        <span className={STATUS_TONE[def.status.tone]}>
                            {def.status.text}
                        </span>
                    ) : (
                        def.description
                    )}
                </p>
            </div>
        </>
    );
}

function IconButton({
    label,
    disabled,
    expanded,
    onClick,
    children,
}: {
    label: string;
    disabled?: boolean;
    expanded?: boolean;
    onClick: () => void;
    children: ReactNode;
}) {
    return (
        <button
            type="button"
            aria-label={label}
            aria-expanded={expanded}
            disabled={disabled}
            onClick={onClick}
            className="rounded p-1 text-gray-400 hover:bg-white/5 hover:text-white disabled:opacity-30 disabled:hover:bg-transparent disabled:hover:text-gray-400"
        >
            {children}
        </button>
    );
}

/** Fixed block for the top of a board, such as the local library. */
export function PinnedProviderBlock({
    icon,
    label,
    description,
    children,
}: {
    icon?: ReactNode;
    label: string;
    description: string;
    children?: ReactNode;
}) {
    const [open, setOpen] = useState(false);
    return (
        <div
            data-provider="pinned"
            className="rounded-lg border border-white/[0.06] bg-surface-hover"
        >
            <div className="flex items-center gap-2 px-3 py-3">
                <span className="w-4 shrink-0" aria-hidden />
                <span className="w-5 shrink-0 text-center text-sm tabular-nums text-gray-400">
                    1
                </span>
                {icon && (
                    <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-surface-highlight">
                        {icon}
                    </div>
                )}
                <div className="min-w-0 flex-1">
                    <p className="text-sm font-medium text-white">{label}</p>
                    <p className="text-xs text-gray-400">{description}</p>
                </div>
                {children && (
                    <IconButton
                        label={`${open ? "Hide" : "Show"} ${label} settings`}
                        expanded={open}
                        onClick={() => setOpen((value) => !value)}
                    >
                        <ChevronRight
                            className={`h-4 w-4 transition-transform ${open ? "rotate-90" : ""}`}
                        />
                    </IconButton>
                )}
            </div>
            {open && children && (
                <div className="border-t border-white/5 px-4 pb-4 pt-3">
                    {children}
                </div>
            )}
        </div>
    );
}
