# Cross-Device Playback Handoff

Status: design phase.

Not scheduled. This document records the design so it can be picked up later; nothing in the Flutter client plan ([`flutter-client/`](flutter-client/README.md)) depends on it.

## Goal

A listener who is playing on one device can continue on another: open the app on a phone, see "Playing on Living-room PC", and take over the same queue at the same position.

Two levels are described. Level 1 is a copy of the queue to the new device. Level 2 adds remote control of the device that keeps playing. Level 1 is useful alone and is a prerequisite for level 2.

## Current State

- The server stores one `PlaybackState` row per user and device (`backend/prisma/schema.prisma`, key `userId` + `deviceId`). The device is named by the `X-Playback-Device-Id` request header; requests without it use the id `legacy` (`backend/src/routes/playbackState.ts`).
- `GET`, `POST`, and `DELETE /api/playback-state` act only on the calling device's row. No endpoint lists a user's other rows.
- A row holds `playbackType`, the current item, `queue` (at most 100 items), `currentIndex`, `isShuffle`, `isPlaying`, `currentTime`, and `updatedAt`. It holds no device name or device kind.
- Clients write their row every 15 seconds while playing, on pause, on track change, and when backgrounded, so `currentTime` in a row can be up to 15 seconds old.
- The Listen Together socket namespace already authenticates JWT and API-key sessions and carries per-user presence.

## Level 1: Continue From Another Device

### Server

| Change | Detail |
|---|---|
| Device label | `POST /api/playback-state` accepts optional `deviceName` (1–64 characters) and `deviceKind` (`phone`, `tablet`, `desktop`, `web`, `tv`, `car`, `other`), stored in two new nullable `PlaybackState` columns. Absent values leave the stored ones unchanged. |
| List devices | `GET /api/playback-state/devices` returns the caller's rows, newest first: `deviceId`, `deviceName`, `deviceKind`, `playbackType`, `isPlaying`, `currentTime`, `updatedAt`, and the current item's display fields and `playbackId`. The queue is not included. Rows older than 30 days are omitted. |
| Read one device | `GET /api/playback-state/devices/:deviceId` returns that row including its queue, in the same shape as `GET /api/playback-state`. |
| Forget a device | `DELETE /api/playback-state/devices/:deviceId` removes a stale row. |

All four are scoped to the authenticated user; a `deviceId` belonging to another user answers 404. All are additive and follow the Unified Playback API rules (`playbackId` only, no source fields). They are added to the typed client surface ([P9](flutter-client/12-server-prerequisites-p6-p9.md)).

### Client

- The client sends `deviceName` (the name the user gave the device at sign-in, else the platform's device name) and `deviceKind` with its playback-state writes.
- **Where it appears.** A "Continue listening" row at the top of Home when another device's row is newer than this device's and less than 24 hours old, and a "Devices" entry in the now-playing screen that lists every device with its current item.
- **Taking over.** The client reads the chosen device's row, replaces its own queue with it (the usual "replace queue" rules in [`flutter-client/06-playback.md`](flutter-client/06-playback.md)), and seeks to the estimated position: `currentTime` plus the time since `updatedAt` when the row says `isPlaying`, clamped to the track length; plain `currentTime` otherwise. Playback starts only after the user's tap, never automatically.
- **Staleness.** A row marked `isPlaying` whose `updatedAt` is more than 60 seconds old is shown as paused, because the device stopped writing.
- **The other device keeps playing** at level 1. The takeover sheet says so.
- **Offline.** The list needs the server; when unreachable the row and entry are hidden.
- **Queue cap.** A queue longer than 100 items arrives as the 100-item window around the current item, as it does for this device's own restore.

### Tests

- Server: listing returns only the caller's rows; label fields round-trip; another user's `deviceId` is 404; the 30-day cut-off.
- Client: position estimate for playing and paused rows, staleness rule, takeover replaces the queue and does not auto-play, hidden when offline.

## Level 2: Remote Control

The device that is playing stops, or is controlled, when another device takes over.

- **Transport.** A per-user room on the existing socket namespace. Each connected client joins `user:<userId>:devices` and announces `deviceId`, `deviceName`, `deviceKind`, and whether it can play.
- **Commands.** `device:command { targetDeviceId, command, args }` with `command` one of `pause`, `play`, `next`, `previous`, `seek`, `setQueue`, `transferTo`. The server relays only between sockets of the same user and never executes a command itself.
- **State.** A playing device broadcasts its playback state to the room on change, so controllers show live position without polling the REST row.
- **Transfer.** `transferTo` is "pause here, then the target loads my queue and position and starts". The target confirms with `device:transferred`; the source resumes if no confirmation arrives within 5 seconds.
- **Reachability.** Only devices with a live socket can be controlled. Mobile clients disconnect the socket in the background unless they are playing, so a paused phone in a pocket is listed (from its REST row) as "not reachable".
- **Interaction with Listen Together.** A device in a Listen Together group refuses `setQueue` and `transferTo`; the group owns its queue.

Level 2 changes the socket protocol and the lifetime of the mobile socket connection, and needs its own design pass before work starts.

## Open Questions

| # | Question |
|---|---|
| H1 | Should the web player take part, sending labels and appearing in the list? It already writes playback state with a device id. |
| H2 | Should taking over at level 1 mark the source row as not playing, so a third device does not offer a stale "playing" state? |
| H3 | Is one "Continue listening" row enough, or should Home list several devices? |
| H4 | Should podcasts hand off through this mechanism, or through their existing per-episode progress, which already follows the user across devices? |
