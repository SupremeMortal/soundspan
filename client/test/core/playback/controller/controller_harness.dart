// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/playback/data/playback_info_repository.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/persistence.dart';
import 'package:soundspan/core/playback/playback_controller.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_reducer.dart';
import 'package:soundspan/core/playback/source_resolver.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

import '../../../helpers/fake_clock.dart';

/// The length of every scripted test source.
const trackLength = Duration(seconds: 10);

/// The stream address the [FakeResolver] gives the entry [queueItemId].
Uri uriOf(String queueItemId) => Uri.parse('https://t.example/$queueItemId');

/// A [PlayerEngine] that records every call made to it and forwards it to
/// a [FakeEngine].
class RecordingEngine implements PlayerEngine {
  /// Wraps [fake].
  new(this.fake);

  /// The engine calls are forwarded to.
  final FakeEngine fake;

  /// Every call, as `load(a, autoPlay: true, at: 0:00:00.000000)`,
  /// `setNext(b)`, `setNext(null)`, `play`, `pause`, `seek(…)`, `stop`,
  /// `setVolume(…)`, `dispose`.
  final List<String> calls = [];

  @override
  Stream<EngineState> get state => fake.state;

  @override
  Stream<EngineEvent> get events => fake.events;

  @override
  Future<void> load(
    EngineSource current, {
    EngineSource? next,
    bool autoPlay = true,
  }) {
    calls.add(
      'load(${current.queueItemId}, autoPlay: $autoPlay, '
      'at: ${current.startAt})',
    );
    return fake.load(current, next: next, autoPlay: autoPlay);
  }

  @override
  Future<void> setNext(EngineSource? next) {
    calls.add('setNext(${next?.queueItemId})');
    return fake.setNext(next);
  }

  @override
  Future<void> play() {
    calls.add('play');
    return fake.play();
  }

  @override
  Future<void> pause() {
    calls.add('pause');
    return fake.pause();
  }

  @override
  Future<void> seek(Duration position) {
    calls.add('seek($position)');
    return fake.seek(position);
  }

  @override
  Future<void> stop() {
    calls.add('stop');
    return fake.stop();
  }

  @override
  Future<void> setVolume(double linear) {
    calls.add('setVolume($linear)');
    return fake.setVolume(linear);
  }

  @override
  Future<void> setSpeed(double speed) {
    calls.add('setSpeed($speed)');
    return fake.setSpeed(speed);
  }

  @override
  Future<void> dispose() {
    calls.add('dispose');
    return fake.dispose();
  }
}

/// A [SourceResolver] that turns an entry into [uriOf] its id, without a
/// server.
class FakeResolver implements SourceResolver {
  /// Entries that throw [NotPlayable].
  final Set<String> unplayable = {};

  /// Entries whose next resolution waits for the completer; each gate is
  /// used once.
  final Map<String, Completer<void>> gates = {};

  /// Every entry resolved, in order.
  final List<String> resolved = [];

  /// Entries that resolve to a local file, `file:///music/<id>.flac`.
  final Set<String> local = {};

  /// The quality the next track sources are built with.
  String? quality;

  /// The headers of the next sources, read at each resolution; none when
  /// null.
  Map<String, String> Function()? headers;

  /// Entries whose resolution throws the mapped exception instead of
  /// returning a source.
  final Map<String, Exception> errors = {};

  @override
  Future<EngineSource> resolve(
    QueueItem item, {
    Duration startAt = Duration.zero,
  }) async {
    final id = item.queueItemId;
    resolved.add(id);
    if (gates.remove(id) case final gate?) await gate.future;
    if (unplayable.contains(id)) throw NotPlayable(id);
    if (errors[id] case final error?) throw error;
    if (local.contains(id)) {
      return EngineSource(
        queueItemId: id,
        uri: Uri.parse('file:///music/$id.flac'),
        startAt: startAt,
      );
    }
    return EngineSource(
      queueItemId: id,
      uri: uriOf(id),
      headers: headers?.call() ?? const {},
      startAt: startAt,
      streamQuality: item is TrackQueueItem ? quality : null,
    );
  }
}

/// A controller over a [RecordingEngine] whose sources are scripted for the
/// given ids, with a [FakeResolver] and, unless another is given, a
/// [FakeClock].
class ControllerHarness {
  /// Creates the harness; [reducer] defaults to a plain one. The
  /// controller persists its queue through [persistence] when one is given.
  /// It keeps its volume in [deviceSettings] when one is given.
  new({
    List<String> ids = const ['a', 'b', 'c', 'd'],
    QueueReducer reducer = const QueueReducer(),
    Clock? clock,
    QueuePersistence? persistence,
    DeviceSettingsDao? deviceSettings,
  }) : clock = clock ?? FakeClock() {
    for (final id in ids) {
      fake.sources[uriOf(id)] = const FakeSource(duration: trackLength);
    }
    registerFallbackValue(api.PlaybackQuality.medium);
    registerFallbackValue(const api.ApiKeyCredentials(apiKey: 'fallback'));
    when(() => profiles.readCredentials(any())).thenAnswer((_) async => null);
    when(() => profiles.writeCredentials(any(), any()))
        .thenAnswer((_) async {});
    session.refresher = () async {
      refreshes++;
      final next = api.JwtCredentials(
        accessToken: 'access-$refreshes',
        refreshToken: 'refresh-$refreshes',
      );
      await session.onTokensRotated(next);
      return next;
    };
    when(
      () => playbackClient.getStreamInfo(
        playbackId: any(named: 'playbackId'),
        quality: any(named: 'quality'),
      ),
    ).thenAnswer((invocation) async {
      final playbackId = invocation.namedArguments[#playbackId] as String;
      final quality =
          (invocation.namedArguments[#quality] as api.PlaybackQuality?)
              ?.toJson();
      infoRequests.add((playbackId, quality));
      if (failInfo) throw const api.ServerError(status: 500);
      return api.StreamInfo.fromJson({
        'playbackId': playbackId,
        'quality': quality ?? 'medium',
        'contentType': 'audio/flac',
        'codec': 'flac',
        'bitrate': 900,
        'sampleRate': 44100,
        'bitDepth': 16,
        'durationMs': 10000,
        'contentLength': 1125000,
      });
    });
    controller = PlaybackController(
      engine: engine,
      resolver: resolver,
      info: PlaybackInfoRepository(playbackClient),
      session: session,
      clock: this.clock,
      deviceSettings: deviceSettings,
      reducer: reducer,
      createTimer: timers.create,
      persistence: persistence,
    );
    controller.snapshots.listen(snapshots.add);
    controller.notices.listen(notices.add);
  }

  /// The engine behind [engine].
  final FakeEngine fake = FakeEngine();

  /// The engine the controller drives.
  late final RecordingEngine engine = RecordingEngine(fake);

  /// The resolver the controller uses.
  final FakeResolver resolver = FakeResolver();

  /// The clock the controller reads.
  final Clock clock;

  /// The controller under test.
  late final PlaybackController controller;

  /// The profile store behind [session].
  final MockProfileRepository profiles = MockProfileRepository();

  /// The session the controller renews; signed out until [signIn].
  late final SessionController session = SessionController(
    profileId: 'p1',
    repository: profiles,
    clock: clock,
  );

  /// How many times the session renewed its JWT.
  int refreshes = 0;

  /// The API client behind the controller's stream-info repository.
  final MockPlaybackClient playbackClient = MockPlaybackClient();

  /// Every stream-info request as `(playbackId, quality)`.
  final List<(String, String?)> infoRequests = [];

  /// Whether stream-info requests fail with a server error.
  bool failInfo = false;

  /// The controller's timers; none fires until a test fires it.
  final ManualTimers timers = ManualTimers();

  /// Makes [credentials] the session's credential.
  Future<void> signIn(api.Credentials credentials) async {
    when(() => profiles.readCredentials(any()))
        .thenAnswer((_) async => credentials);
    await session.load();
  }

  /// Every snapshot the controller emitted.
  final List<PlaybackSnapshot> snapshots = [];

  /// Every notice the controller emitted.
  final List<PlaybackNotice> notices = [];

  /// The engine calls, without the volume calls.
  List<String> get calls => engine.calls;

  /// Lets [d] of playback pass on the engine and the clock, then lets the
  /// controller handle what happened.
  Future<void> play(Duration d) async {
    var left = d;
    const step = FakeEngine.positionInterval;
    while (left > Duration.zero) {
      final move = left < step ? left : step;
      fake.advance(move);
      if (clock case final FakeClock fakeClock) fakeClock.advance(move);
      left -= move;
      await pumpEventQueue();
    }
  }

  /// Lets every pending microtask and event run.
  Future<void> settle() => pumpEventQueue();
}

/// A [ProfileRepository] whose answers a test scripts.
class MockProfileRepository extends Mock implements ProfileRepository;

/// A generated playback client whose answers a test scripts.
class MockPlaybackClient extends Mock implements api.PlaybackClient;

/// One-shot timers that fire only when a test fires them.
class ManualTimers {
  /// The timers created, in order, fired or not.
  final List<ManualTimer> created = [];

  /// The timers that are still waiting.
  List<ManualTimer> get pending => [
    for (final timer in created)
      if (timer.isActive) timer,
  ];

  /// Creates a timer of [duration] that runs [callback] when fired.
  Timer create(Duration duration, void Function() callback) {
    final timer = ManualTimer(duration, callback);
    created.add(timer);
    return timer;
  }

  /// Fires every waiting timer, then lets the controller handle it.
  Future<void> fireAll() async {
    for (final timer in pending) {
      timer.fire();
    }
    await pumpEventQueue();
  }
}

/// A one-shot timer that runs its callback when [fire] is called.
class ManualTimer implements Timer {
  /// Creates a timer of [duration].
  new(this.duration, this._callback);

  /// What the controller asked for.
  final Duration duration;
  final void Function() _callback;
  bool _active = true;

  /// Runs the callback, as [duration] elapsing would.
  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _active ? 0 : 1;
}
