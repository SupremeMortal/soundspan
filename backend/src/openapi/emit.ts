import { isBinaryResponse } from "./defineOperation";
import type { ClientSurface } from "./clientSurface";
import { buildClientSurfaceDocument } from "./document";

const COMPONENT_PREFIX = "#/components/schemas/";

function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}

/** True when any 2xx status of the operation is a binary body. */
function hasBinarySuccess(operation: ClientSurface[number]): boolean {
    return Object.entries(operation.responses).some(
        ([status, body]) => status.startsWith("2") && isBinaryResponse(body),
    );
}

function collectRefs(value: unknown, out: Set<string>): void {
    if (Array.isArray(value)) {
        value.forEach((child) => collectRefs(child, out));
        return;
    }
    if (!isRecord(value)) return;
    for (const [key, child] of Object.entries(value)) {
        if (
            key === "$ref" &&
            typeof child === "string" &&
            child.startsWith(COMPONENT_PREFIX)
        ) {
            out.add(child.slice(COMPONENT_PREFIX.length));
        } else {
            collectRefs(child, out);
        }
    }
}

/** Components reachable from `paths`, following references between components. */
function referencedComponents(
    paths: unknown,
    schemas: Record<string, unknown>,
): Set<string> {
    const reached = new Set<string>();
    const pending = new Set<string>();
    collectRefs(paths, pending);
    while (pending.size > 0) {
        const [id] = pending;
        pending.delete(id);
        if (reached.has(id)) continue;
        reached.add(id);
        const found = new Set<string>();
        collectRefs(schemas[id], found);
        for (const next of found) if (!reached.has(next)) pending.add(next);
    }
    return reached;
}

function compareCodePoints(a: string, b: string): number {
    const left = Array.from(a, (char) => char.codePointAt(0) as number);
    const right = Array.from(b, (char) => char.codePointAt(0) as number);
    for (let i = 0; i < Math.min(left.length, right.length); i += 1) {
        if (left[i] !== right[i]) return left[i] - right[i];
    }
    return left.length - right.length;
}

/**
 * Serialises like `JSON.stringify(value, null, 2)` with object keys in
 * code-point order (integer-like keys included) and `required` lists sorted.
 */
function serialise(value: unknown, indent: string, key?: string): string {
    if (Array.isArray(value)) {
        const items =
            key === "required" &&
            value.every((item) => typeof item === "string")
                ? [...(value as string[])].sort(compareCodePoints)
                : value;
        if (items.length === 0) return "[]";
        const inner = `${indent}  `;
        const lines = items.map(
            (item) => `${inner}${serialise(item ?? null, inner)}`,
        );
        return `[\n${lines.join(",\n")}\n${indent}]`;
    }
    if (isRecord(value)) {
        const keys = Object.keys(value)
            .filter((name) => value[name] !== undefined)
            .sort(compareCodePoints);
        if (keys.length === 0) return "{}";
        const inner = `${indent}  `;
        const lines = keys.map(
            (name) =>
                `${inner}${JSON.stringify(name)}: ${serialise(value[name], inner, name)}`,
        );
        return `{\n${lines.join(",\n")}\n${indent}}`;
    }
    return JSON.stringify(value);
}

/**
 * Renders the client-surface OpenAPI document written to
 * `client/packages/soundspan_api/openapi/soundspan-client.json`: the
 * operations of `operations` with a JSON success response and the components
 * they reference, serialised deterministically.
 */
export function renderClientSurfaceSpec(
    operations: ClientSurface,
    version: string,
): string {
    const surface = buildClientSurfaceDocument(
        operations.filter((operation) => !hasBinarySuccess(operation)),
    );
    const reached = referencedComponents(
        surface.paths,
        surface.components.schemas,
    );
    const schemas: Record<string, unknown> = {};
    for (const id of reached) schemas[id] = surface.components.schemas[id];
    const document = {
        openapi: "3.0.0",
        info: { title: "soundspan client surface", version },
        paths: surface.paths,
        components: { schemas },
    };
    return `${serialise(document, "")}\n`;
}
