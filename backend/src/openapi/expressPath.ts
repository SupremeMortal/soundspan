/**
 * Converts an Express 5 route path to its OpenAPI path(s): `:name` and
 * `*name` become `{name}`, and each optional `{...}` group expands to the
 * path without and with the group.
 */
export function toOpenApiPaths(expressPath: string): string[] {
    const open = expressPath.indexOf("{");
    if (open === -1) {
        return [expressPath.replace(/[:*]([A-Za-z0-9_$]+)/g, "{$1}")];
    }
    let depth = 0;
    let close = -1;
    for (let index = open; index < expressPath.length; index += 1) {
        if (expressPath[index] === "{") depth += 1;
        if (expressPath[index] === "}") depth -= 1;
        if (depth === 0) {
            close = index;
            break;
        }
    }
    if (close === -1) {
        throw new Error(`Unbalanced optional group in "${expressPath}"`);
    }
    const before = expressPath.slice(0, open);
    const group = expressPath.slice(open + 1, close);
    const after = expressPath.slice(close + 1);
    return [
        ...toOpenApiPaths(before + after),
        ...toOpenApiPaths(before + group + after),
    ];
}

/** Replaces every `{parameter}` with `{}` so paths compare by shape. */
export function pathShape(path: string): string {
    return path.replace(/\{[^}]*\}/g, "{}");
}
