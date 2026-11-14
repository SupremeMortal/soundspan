import type { Router } from "express";
import { pathShape, toOpenApiPaths } from "../../expressPath";

/**
 * Client-surface mount prefixes (as mounted in `backend/src/index.ts`) mapped
 * to a lazy `require` of the route module. A registry issue adds its prefix
 * here and mocks the module's heavy dependencies in the test file.
 */
export const CLIENT_SURFACE_MOUNTS: Record<string, () => Router> = {};

/** Operations declared on `app` itself in `backend/src/index.ts`. */
export const APP_LEVEL_ROUTES: ReadonlyArray<readonly [string, string]> = [
    ["get", "/api/health"],
    ["get", "/api/docs.json"],
];

const PARAM_SAMPLE = "__param__";

interface RouteLike {
    path: unknown;
    methods: Record<string, boolean | undefined>;
}

interface LayerLike {
    route?: RouteLike;
    handle: unknown;
    path?: string;
    match(path: string): boolean;
}

function hasStack(handle: unknown): handle is { stack: LayerLike[] } {
    return (
        typeof handle === "function" &&
        Array.isArray((handle as { stack?: unknown }).stack)
    );
}

function routePaths(path: unknown): string[] {
    const candidates = Array.isArray(path) ? path : [path];
    return candidates
        .filter(
            (candidate): candidate is string => typeof candidate === "string",
        )
        .flatMap((candidate) => toOpenApiPaths(candidate));
}

function sampleToShape(sample: string): string {
    const shape = sample.split(PARAM_SAMPLE).join("{}");
    return shape === "" ? "/" : shape;
}

function stackHasRoute(
    stack: LayerLike[],
    method: string,
    sample: string,
): boolean {
    for (const layer of stack) {
        if (layer.route) {
            if (!layer.route.methods[method]) continue;
            const wanted = sampleToShape(sample);
            if (
                routePaths(layer.route.path).some(
                    (p) => pathShape(p) === wanted,
                )
            ) {
                return true;
            }
            continue;
        }
        if (!hasStack(layer.handle) || !layer.match(sample)) continue;
        const matched = layer.path ?? "";
        const rest = sample.slice(matched.length) || "/";
        if (stackHasRoute(layer.handle.stack, method, rest)) return true;
    }
    return false;
}

/** Whether `router` (nested routers included) serves `method` at `path`. */
export function routerServes(
    router: Router,
    method: string,
    path: string,
): boolean {
    const sample = pathShape(path).split("{}").join(PARAM_SAMPLE);
    return stackHasRoute(
        (router as unknown as { stack: LayerLike[] }).stack,
        method.toLowerCase(),
        sample,
    );
}

/** Whether `method path` is served by `app` or one of `mounts`. */
export function isMountedIn(
    mounts: Record<string, () => Router>,
    method: string,
    path: string,
): boolean {
    const shape = pathShape(path);
    if (
        APP_LEVEL_ROUTES.some(
            ([appMethod, appPath]) =>
                appMethod === method.toLowerCase() &&
                pathShape(appPath) === shape,
        )
    ) {
        return true;
    }
    return Object.entries(mounts).some(([prefix, load]) => {
        if (path !== prefix && !path.startsWith(`${prefix}/`)) return false;
        return routerServes(load(), method, path.slice(prefix.length) || "/");
    });
}

/** Whether `method path` is served by `app` or a client-surface mount. */
export function isMounted(method: string, path: string): boolean {
    return isMountedIn(CLIENT_SURFACE_MOUNTS, method, path);
}
