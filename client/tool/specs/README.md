# Spec snapshots

`min-server.json` is the client-surface OpenAPI document of the oldest server
release the client supports (`BuildConfig.minServer`). `tool/spec_compat.dart`
compares the committed spec in `packages/soundspan_api/openapi/` with it and
fails when an operation was removed or moved, a response field became
required, or a response field changed type or lost nullability.

Only the `minServer` procedure of the client project (the issue that sets
`BuildConfig.minServer`) replaces this file, with the spec emitted by that
release. It is never edited by hand and never regenerated from the current
spec.
