# soundspan Client (Flutter): Implementation Plan

Status: design phase.

This directory is the technical plan for building the client described in [`../flutter-client.md`](../flutter-client.md). That document says what the client is and why. This directory says how it is built: file layout, interfaces, schemas, algorithms, platform configuration, tests, and the order of the pull requests.

Where the two disagree, the design document wins on product scope and this directory wins on implementation detail.

## Reading Order

| # | Document | Covers |
|---|---|---|
| 01 | [Toolchain and repository](01-toolchain-and-repository.md) | Flutter pin, `client/` tree, `pubspec.yaml`, lints, code generation, flavors, repo-contract changes |
| 02 | [Architecture](02-architecture.md) | Layers, dependency rules, profile scope, bootstrap, routing, errors, logging, platform seams |
| 03 | [API layer](03-api-layer.md) | `soundspan_api` package: client generated from the server's typed spec, hand-written transport, interceptors, error mapping, endpoint inventory |
| 04 | [Auth and server profiles](04-auth-and-server-profiles.md) | Address normalization, probe, sign-in flows, credentials, key expiry, version gate |
| 05 | [Local data](05-local-data.md) | drift databases, tables, cache policy, migrations, file layout |
| 06 | [Playback](06-playback.md) | `PlayerEngine`, queue model, gapless, loudness, OS media controls, play reporting, podcasts |
| 07 | [Offline and downloads](07-offline-and-downloads.md) | Download state machine, background transfers, quota, reconciliation, outbox |
| 08 | [Realtime](08-realtime.md) | socket.io client, Listen Together sync, presence |
| 09 | [UI and design system](09-ui-and-design-system.md) | Tokens for dark and light, type, components, adaptive layouts, screen specs, shortcuts, accessibility |
| 10 | [Platform integration](10-platform-integration.md) | Per-target manifests, entitlements, services, deep links, packaging |
| 11 | [Testing and CI](11-testing-and-ci.md) | Test layers, contract harness, engine conformance, workflows, gates, release |
| 12 | [Server prerequisites P6–P9](12-server-prerequisites-p6-p9.md) | Four additive server changes the client needs beyond the Unified Playback API, including the typed OpenAPI description the client is generated from |
| 13 | [Milestones and work breakdown](13-milestones-and-work-breakdown.md) | Spikes, PR-sized tasks with dependencies and acceptance criteria, risk register |

[`assets/`](assets/) holds the vector masters of the logo mark. A related design that is not part of this plan, picking up playback from another device, is in [`../cross-device-playback-handoff.md`](../cross-device-playback-handoff.md).

## Conventions Used in This Plan

- Paths starting with `client/` are new. Paths starting with `backend/` or `frontend/` exist and are cited as evidence.
- Dart snippets are interface sketches. They fix names, responsibilities, and signatures; bodies are written test-first during implementation (`AGENTS.md`, TDD rule).
- "Verify in spike Sx" marks a behaviour of a third-party package that the plan depends on and that is proven by a named spike in [13](13-milestones-and-work-breakdown.md) before code is built on it.
- Task ids (`M0-03`, `S1-P7`) are stable and are used in PR titles.
