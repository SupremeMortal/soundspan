# 08. Realtime

Status: design phase.

Milestone M4. Code lives in `lib/core/realtime/` and `lib/features/listen_together/`.

## Socket Client

One socket per active profile, to the `/listen-together` namespace, which carries both Listen Together and social presence.

```dart
final socket = io(
  '${baseOrigin}/listen-together',
  OptionBuilder()
      .setPath('${basePathPrefix}/socket.io/listen-together')   // Keeps a reverse-proxy sub-path
      .setTransports(['websocket'])                             // Server default allows websocket only
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionDelay(1000)
      .setReconnectionDelayMax(30000)
      .setRandomizationFactor(0.5)
      .setAuthFn((cb) => cb(_authPayload()))                    // Evaluated on every (re)connect
      .build(),
);
```

- `_authPayload()` returns exactly one of `{ token: <access JWT> }` or `{ apiKey: <key> }`. Sending both is rejected by the server. For JWT sessions it calls `ensureFresh` first so a reconnect after a long sleep does not present an expired token.
- The namespace URL is built from the origin, and the path from the profile's prefix, because socket.io treats the URL path as the namespace.
- Connection errors: `Invalid token` or `Token expired` → refresh once and reconnect; a second failure, or `User not found`, is handed to `SessionController.onUnauthenticated`. A server-initiated disconnect of an API-key socket (key revoked) is treated the same way after one confirming REST call (`GET /auth/me`).

### Lifecycle

| Situation | Behaviour |
|---|---|
| App start | Not connected. The socket is opened lazily: when presence is enabled in the UI or a Listen Together group is joined |
| Mobile app backgrounded, not in a group | Disconnect after 30 s |
| Mobile app backgrounded, in a group and playing | Stay connected (the audio background mode or foreground service keeps the process alive) |
| Resume | Reconnect; rejoin the group; refetch presence over REST |
| Reachability not `online` | Reconnection attempts pause; resume on `online` |
| Profile switch or sign-out | Dispose |

### Typed Events

`SocketClient` exposes typed streams and `Future`-returning emitters with acknowledgement and a 5 s timeout. Socket events are not part of the OpenAPI document, so their payloads are hand-written `freezed` models in `core/realtime`, tolerant of unknown keys.

```dart
Stream<GroupSnapshot> get groupState;                 // group:state
Stream<PlaybackDelta> get playbackDelta;              // group:playback-delta
Stream<QueueDelta> get queueDelta;                    // group:queue-delta
Stream<WaitingEvent> get waiting;                     // group:waiting
Stream<PlayAtEvent> get playAt;                       // group:play-at
Stream<MemberEvent> get members;                      // member-joined | member-presence | member-left
Stream<GroupEnded> get ended;                         // group:ended | group:membership-revoked
Stream<PresenceUpdated> get presenceUpdated;          // social:presence-updated

Future<Ack> joinGroup(String groupId);
Future<Ack> leaveGroup();
Future<Ack> playback(PlaybackAction action, {int? positionMs, int? index, int? stateVersion});
Future<QueueAck> queue(QueueAction action, {List<PlaybackRef>? tracks, int? index, int? fromIndex, int? toIndex});
Future<Ack> ready();
Future<Ack> playbackFailed(int queueIndex);
Future<int> ping();                                   // lt-ping → serverTime
```

Queue additions always send `tracks: [{ playbackId, metadata }]`. The legacy `trackIds` form and the source-specific fields of `SyncQueueItem` (`streamSource`, `provider`, `tidalTrackId`, …) are not declared in the client's models.

Error acknowledgements `{ error, code?, transient?, retryable?, retryAfterMs? }` map to `SocketCommandException`; a `retryable` conflict is retried once after `retryAfterMs`.

## Listen Together

`ListenTogetherController` attaches to `PlaybackController` as a `RemoteDriver` ([06](06-playback.md)).

### Joining

1. REST: create (`POST /listen-together`, optionally with `queueTracks` built from the current local queue as `{ playbackId, metadata }`) or join by code (`POST /listen-together/join { joinCode }`). Both return a `GroupSnapshot`.
2. Save the local queue and position in memory so leaving can restore them.
3. Connect the socket if needed; `join-group { groupId }`; the server emits `group:state`.
4. Attach the driver. The controller's queue becomes the group's queue.

### Clock Synchronisation

Server events carry `serverTime` (server clock, ms) and `positionMs`. The client estimates the offset between its monotonic clock and the server clock:

```text
on connect, then every 30 s while in a group:
    repeat 5 times, 200 ms apart:
        t0 = monotonicNow(); serverTime = await ping(); t1 = monotonicNow()
        rtt = t1 − t0
        sample = (serverTime + rtt/2) − t1          # offset: serverNow ≈ monotonicNow + offset
    offset = sample with the smallest rtt
```

`serverNow() = monotonicNow() + offset`. A monotonic clock (`Stopwatch`) is used so wall-clock adjustments on the device do not disturb sync.

### Applying State

```text
expectedPositionMs(state) = state.isPlaying
        ? state.positionMs + (serverNow() − state.serverTime)
        : state.positionMs
```

| Server message | Client action |
|---|---|
| `group:state` (full snapshot) | Replace queue; set cursor to `currentIndex`; load the current item paused at `expectedPositionMs`; then follow `syncState` |
| `group:queue-delta` | Replace queue and cursor; update the preloaded next |
| `group:waiting { currentIndex }` | Load that item, pause at zero, and emit `ready` once the engine reports `ready` (buffered enough to start) |
| `group:play-at { positionMs, serverTime }` | Seek to `positionMs`; schedule `play()` at local time `serverTime − offset`; if that time has passed, seek to the expected position and play now |
| `group:playback-delta` | Apply play/pause; correct position (below) |
| `group:ended`, `membership-revoked` | Detach the driver; restore the saved local queue, paused; show why |

Messages carry `stateVersion`; one older than the last applied is ignored.

### Drift Correction

Every 5 s while playing, and on each `playback-delta`:

```text
drift = enginePosition − expectedPositionMs
|drift| < 250 ms            → do nothing
250 ms ≤ |drift| < 1500 ms  → seek to expected (one correction per 10 s at most)
|drift| ≥ 1500 ms           → seek to expected immediately
```

Rate nudging (playing slightly faster or slower) is not used: engine speed changes are audible on some backends.

### Commands From This Device

While attached, UI transport and queue commands are sent to the server and **not** applied locally; the UI updates when the resulting delta arrives. Buttons show a pending state for up to 5 s (the ack timeout), then an error.

- Host-follower groups: followers see transport controls disabled, with "The host controls playback". Volume, lyrics, and liking stay local.
- If the current item fails to load on this device: `track:playback-failed { queueIndex }`.
- Play reporting, loudness, and downloads behave as in solo playback. A downloaded file is used when present; sync works on position, not on bytes.

### Leaving

`leave-group` (socket) and `POST /listen-together/:id/leave` (REST fallback when the socket is down), detach, restore the saved queue paused.

## Social Presence

- **Heartbeat:** `POST /api/social/presence/heartbeat` every 25 s while the app is in the foreground (the web cadence). Stopped in the background and while offline. Playback state posts ([06](06-playback.md)) already publish what is playing.
- **Reading presence:** `GET /api/social/online` when the presence panel opens. While it is open the socket is connected and each `social:presence-updated` event schedules a debounced (1 s) refetch. The event names only a user id, so the list is always re-read over REST.
- **UI:** an "Activity" panel on expanded layouts (toggled from the top bar) and a sheet from the avatar menu elsewhere, listing users with Playing/Paused/Idle and the current track. Federation peers appear in a second section when the server has `federation` enabled.
- Presence is off until the user opens the panel once per session; it is not needed for playback.

## Testing

- `SocketClient` against a local `socket_io` test server in `dart test`: handshake payloads for both credential kinds, reconnect with a refreshed token, ack timeout, error mapping.
- `ListenTogetherController` with `FakeEngine`, a fake clock, and a scripted event stream: each row of the "Applying State" table, drift thresholds, stale `stateVersion`, leave restores the queue.
- Contract suite: two API clients (JWT and API key) join one group on the real server; a queue add by `playbackId` from one is observed by the other.
- Manual: two physical devices in one room, playing the same group; audible offset below 100 ms on the same network.
