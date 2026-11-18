type JsonRecord = Record<string, unknown>;

const COMPONENT_PREFIX = "#/components/schemas/";

function isRecord(value: unknown): value is JsonRecord {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}

function escapePointer(segment: string): string {
    return segment.replace(/~/g, "~0").replace(/\//g, "~1");
}

/**
 * JSON pointers of every `additionalProperties: false` inside a response
 * schema of `document` or a component a response schema references
 * (transitively). Request bodies and parameters are not inspected.
 */
export function closedResponseObjects(document: unknown): string[] {
    const found: string[] = [];
    if (!isRecord(document)) return found;
    const components = isRecord(document.components) ? document.components : {};
    const schemas = isRecord(components.schemas) ? components.schemas : {};
    const visited = new Set<string>();

    const walk = (value: unknown, pointer: string): void => {
        if (Array.isArray(value)) {
            value.forEach((child, index) => walk(child, `${pointer}/${index}`));
            return;
        }
        if (!isRecord(value)) return;
        for (const [key, child] of Object.entries(value)) {
            const at = `${pointer}/${escapePointer(key)}`;
            if (key === "additionalProperties" && child === false) {
                found.push(at);
            } else if (
                key === "$ref" &&
                typeof child === "string" &&
                child.startsWith(COMPONENT_PREFIX)
            ) {
                const id = child.slice(COMPONENT_PREFIX.length);
                if (!visited.has(id)) {
                    visited.add(id);
                    walk(
                        schemas[id],
                        `/components/schemas/${escapePointer(id)}`,
                    );
                }
            } else {
                walk(child, at);
            }
        }
    };

    const paths = isRecord(document.paths) ? document.paths : {};
    for (const [path, item] of Object.entries(paths)) {
        if (!isRecord(item)) continue;
        for (const [method, operation] of Object.entries(item)) {
            if (!isRecord(operation) || !isRecord(operation.responses)) {
                continue;
            }
            walk(
                operation.responses,
                `/paths/${escapePointer(path)}/${method}/responses`,
            );
        }
    }
    return found.sort();
}
