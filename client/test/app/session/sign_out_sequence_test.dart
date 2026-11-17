// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/session/sign_out_participant.dart';
import 'package:soundspan/app/session/sign_out_sequence.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/play_reporter_input.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/core/sync/outbox/outbox_worker.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/core/sync/play_reporter.dart';
import 'package:soundspan/core/sync/play_session_store.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/database_opener/database_opener_io.dart';
import 'package:soundspan/platform/paths/paths_io.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../core/logging/recording_sink.dart';
import '../../core/playback/controller/controller_harness.dart';
import '../../core/playback/queue/queue_test_items.dart';
import '../../core/profile/profile_harness.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_reachability.dart';
import '../../helpers/in_memory_secret_store.dart';

/// What happened, in order, across every fake of the sequence.
typedef _Log = List<String>;

/// A server that records each request as `METHOD /path` and answers with
/// [status], hangs, or fails as if the network were down.
class _Server implements HttpClientAdapter {
  new(this.log);

  final _Log log;

  /// The status of every answer.
  int status = 200;

  /// Whether requests never complete.
  bool hang = false;

  /// Whether requests fail with a connection error.
  bool offline = false;

  /// The headers of every request, in order.
  final List<Map<String, Object?>> headers = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    log.add('${options.method} ${options.uri.path}');
    headers.add(Map.of(options.headers));
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    if (hang) await Completer<void>().future;
    return ResponseBody.fromString(
      jsonEncode(status == 200 ? {'message': 'ok'} : {'error': 'nope'}),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A participant that records its calls and can throw.
class _Participant implements SignOutParticipant {
  new(this.log, this.name, {this.fail = false});

  final _Log log;
  final String name;
  final bool fail;

  @override
  Future<void> onSignOut({required bool removeDownloads}) async {
    log.add('$name.onSignOut(removeDownloads: $removeDownloads)');
    if (fail) throw StateError('participant failed');
  }

  @override
  Future<void> beforeRemove() async => log.add('$name.beforeRemove');
}

/// The scope of the active profile as the sequence sees it.
class _Scope implements SignOutScope {
  new(this.log, this.participants);

  final _Log log;

  @override
  final List<SignOutParticipant> participants;

  /// What the flush does after it is recorded.
  Future<void> Function() onFlush = () async {};

  /// What [pendingChanges] answers.
  int pending = 0;

  @override
  Future<void> flushOutbox() async {
    log.add('flush');
    await onFlush();
  }

  @override
  Future<int> pendingChanges() async => pending;
}

/// A secret store that records deletes and can fail them.
class _Secrets extends InMemorySecretStore {
  new(this.log);

  final _Log log;
  bool failDelete = false;

  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('keychain locked');
    log.add('delete ${key.split('/').last}');
    await super.delete(key);
  }
}

/// The root scope with profiles A (password) and B (API key), an
/// [_Server], a recorded [_Scope] for the active profile and the sequence.
class _Rig {
  new _(this.h, this.server, this.secretsLog);

  static Future<_Rig> create({List<SignOutParticipant>? participants}) async {
    final log = <String>[];
    final h = await ProfileHarness.create(secrets: _Secrets(log));
    log.clear();
    final rig = _Rig._(h, _Server(log), log)
      ..scope = _Scope(log, participants ?? [_Participant(log, 'playback')])
      ..runtime = h.root.read(profileRuntimeProvider);
    addTearDown(rig.runtime.dispose);
    return rig..sequence = rig.build();
  }

  final ProfileHarness h;
  final _Server server;
  final _Timers timers = _Timers();
  final _Log secretsLog;
  late _Scope scope;
  late ProfileRuntime runtime;
  late SignOutSequence sequence;

  _Log get log => secretsLog;

  ProfileRepository get profiles => h.root.read(profileRepositoryProvider);

  SignOutSequence build() => SignOutSequence(
    runtime: runtime,
    profiles: profiles,
    revoker: ApiSessionRevoker(
      userAgent: 'soundspan-test',
      apis: (config, credentials) =>
          SoundspanApi(config, credentials: credentials, adapter: server),
    ),
    opener: h.opener,
    clock: h.clock,
    scopeOf: (_) => scope,
    timer: timers.create,
  );

  Future<ProfileState?> stateOf(String id) async =>
      (await profiles.byId(id))?.state;

  Iterable<String> secretsOf(String id) =>
      h.secrets.values.keys.where((key) => key.startsWith('p/$id/'));
}

void main() {
  late RecordingSink logs;

  setUp(() {
    logs = RecordingSink();
    AppLogging.configure(sinks: [logs], releaseMode: false);
  });
  tearDown(AppLogging.reset);

  /// Every log entry as one string.
  Iterable<String> logLines() => logs.entries.map(
    (e) => '${e.message} ${e.fields} ${e.error} ${e.stackTrace}',
  );

  group('signOut, active profile', () {
    test('password: stop, flush, POST /auth/logout, delete the secrets, then '
        'signedOut, and the container is created again', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);
      final before = rig.runtime.container;
      rig.scope.onFlush = () async =>
          rig.log.add('state ${(await rig.stateOf(rig.h.a))!.name}');

      await rig.sequence.signOut(rig.h.a);

      expect(rig.log, [
        'playback.onSignOut(removeDownloads: false)',
        'flush',
        'state active',
        'POST /api/auth/logout',
        'delete refresh',
        'delete access',
        'delete apikey',
      ]);
      expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      expect(rig.secretsOf(rig.h.a), isEmpty);
      expect(rig.runtime.container, isNot(same(before)));
      expect(rig.runtime.state.value, ProfileRuntimeActive(rig.h.a));
      expect(rig.h.root.read(activeProfileIdProvider), rig.h.a);
    });

    test(
      'device link: DELETE /api-keys/current carries the profile key',
      () async {
        final rig = await _Rig.create();
        final linked = await rig.profiles.upsertSignedIn(
          baseUrl: Uri.parse('https://c.example.com'),
          userId: 'user-c',
          username: 'c',
          role: 'user',
          authKind: AuthKind.deviceLink,
          credentials: const ApiKeyCredentials(apiKey: 'c-linked-key'),
          credentialCreatedAt: rig.h.clock.now(),
        );
        await rig.runtime.switchTo(linked.id);

        await rig.sequence.signOut(linked.id);

        expect(rig.log, contains('DELETE /api/api-keys/current'));
        expect(rig.server.headers.single['X-API-Key'], 'c-linked-key');
        expect(await rig.stateOf(linked.id), ProfileState.signedOut);
        expect(rig.secretsOf(linked.id), isEmpty);
      },
    );

    test('removeDownloads reaches every participant', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);

      await rig.sequence.signOut(rig.h.a, removeDownloads: true);

      expect(rig.log.first, 'playback.onSignOut(removeDownloads: true)');
    });

    test('a flush that never completes is abandoned after 5 seconds and the '
        'operations stay stored', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);
      final db = StateDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = OutboxStore(db, rig.h.clock);
      await store.enqueue(
        PlayOp(
          sessionId: 's1',
          playbackId: 'pb-1',
          metadata: const {},
          playedAt: rig.h.clock.now(),
          listenedMs: 20000,
        ),
      );
      rig.scope.onFlush = () => Completer<void>().future;
      var done = false;
      final run = rig.sequence.signOut(rig.h.a).then((_) => done = true);

      await _until(() => rig.timers.created.isNotEmpty);
      expect(rig.timers.created.single.duration, SignOutSequence.budget);
      expect(SignOutSequence.budget, const Duration(seconds: 5));
      expect(done, isFalse);
      expect(rig.log, isNot(contains('POST /api/auth/logout')));

      rig.timers.created.single.fire();
      await run;

      expect(rig.log, contains('POST /api/auth/logout'));
      expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      expect(await store.watchCount().first, 1);
      expect(
        logs.entries.map((e) => e.message),
        contains('Outbox flush timed out'),
      );
    });

    test('a flush that throws is logged and the sequence continues', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);
      rig.scope.onFlush = () async => throw const Offline();

      await rig.sequence.signOut(rig.h.a);

      expect(rig.log, contains('POST /api/auth/logout'));
      expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      expect(
        logs.entries.map((e) => e.message),
        contains('Outbox flush failed'),
      );
    });

    test(
      'a participant that throws is logged and the next one still runs',
      () async {
        final log = <String>[];
        final rig = await _Rig.create(
          participants: [
            _Participant(log, 'first', fail: true),
            _Participant(log, 'second'),
          ],
        );
        await rig.runtime.switchTo(rig.h.a);

        await rig.sequence.signOut(rig.h.a);

        expect(log, [
          'first.onSignOut(removeDownloads: false)',
          'second.onSignOut(removeDownloads: false)',
        ]);
        expect(rig.log, containsAllInOrder(['flush', 'POST /api/auth/logout']));
        expect(await rig.stateOf(rig.h.a), ProfileState.signedOut);
      },
    );

    test('a secret store that fails propagates and leaves the profile '
        'signed in', () async {
      final log = <String>[];
      final secrets = _Secrets(log);
      final h = await ProfileHarness.create(secrets: secrets);
      final runtime = h.root.read(profileRuntimeProvider);
      addTearDown(runtime.dispose);
      await runtime.switchTo(h.a);
      final server = _Server(log);
      final sequence = SignOutSequence(
        runtime: runtime,
        profiles: h.root.read(profileRepositoryProvider),
        revoker: ApiSessionRevoker(
          userAgent: 'soundspan-test',
          apis: (config, credentials) =>
              SoundspanApi(config, credentials: credentials, adapter: server),
        ),
        opener: h.opener,
        clock: h.clock,
        scopeOf: (_) => _Scope(log, const []),
      );
      secrets.failDelete = true;

      await expectLater(sequence.signOut(h.a), throwsStateError);

      final profile = await h.root.read(profileRepositoryProvider).byId(h.a);
      expect(profile!.state, ProfileState.active);
    });

    test('the play open for 20 seconds is in the outbox before the flush '
        'runs', () async {
      final db = StateDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final clock = FakeClock();
      final controller = ControllerHarness(clock: clock);
      for (final id in const ['a', 'b']) {
        controller.fake.sources[uriOf(id)] = const FakeSource(
          duration: Duration(minutes: 5),
        );
      }
      final store = OutboxStore(db, clock);
      final outbox = Outbox(
        store,
        OutboxWorker(
          store,
          OutboxHandlerRegistry(const []),
          FakeReachability(initial: Reachability.noNetwork),
          clock,
          AppLogger.scope('Test'),
          rewriter: TempIdRewriter(
            db,
            () async => CacheDatabase(NativeDatabase.memory()),
          ),
        ),
      );
      final lifecycle = StreamController<AppLifecycleState>.broadcast();
      addTearDown(lifecycle.close);
      final reporter = PlayReporter(
        ControllerListeningSource(controller.controller),
        PlaySessionStore(db),
        outbox,
        clock,
        lifecycle.stream,
      );
      addTearDown(reporter.dispose);
      await controller.controller.playItems(trackItems(['a', 'b']));
      await controller.settle();
      clock.advance(const Duration(seconds: 20));
      await controller.settle();

      final log = <String>[];
      final rig = await _Rig.create(
        participants: [
          PlaybackSignOutParticipant(
            () => controller.controller,
            reporter.flush,
          ),
        ],
      );
      await rig.runtime.switchTo(rig.h.a);
      final plays = <int>[];
      rig.scope.onFlush = () async {
        log.add('flush');
        plays.add((await store.pending()).where((e) => e.op is PlayOp).length);
      };

      await rig.sequence.signOut(rig.h.a);

      expect(log, ['flush']);
      expect(plays, [1]);
      final op = (await store.pending()).single.op as PlayOp;
      expect(op.listenedMs, 20000);
      expect(controller.controller.snapshot.playing, isFalse);
    });

    for (final (name, configure) in <(String, void Function(_Server))>[
      ('500', (s) => s.status = 500),
      ('401', (s) => s.status = 401),
      ('offline', (s) => s.offline = true),
    ]) {
      test('a revoke that fails with $name still ends signedOut with no '
          'secrets', () async {
        final rig = await _Rig.create();
        await rig.runtime.switchTo(rig.h.b);
        configure(rig.server);

        await rig.sequence.signOut(rig.h.b);

        expect(await rig.stateOf(rig.h.b), ProfileState.signedOut);
        expect(rig.secretsOf(rig.h.b), isEmpty);
      });
    }

    test('a revoke that never answers is abandoned after 5 seconds', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.b);
      rig.server.hang = true;
      var done = false;
      final run = rig.sequence.signOut(rig.h.b).then((_) => done = true);

      await _until(() => rig.log.contains('DELETE /api/api-keys/current'));
      expect(done, isFalse);
      final revokeTimer = rig.timers.created.last;
      expect(revokeTimer.duration, SignOutSequence.budget);
      revokeTimer.fire();
      await run;

      expect(rig.secretsOf(rig.h.b), isEmpty);
      expect(await rig.stateOf(rig.h.b), ProfileState.signedOut);
    });
  });

  test('signOut of an inactive profile: no stop, no flush, revoke with its '
      'stored credential', () async {
    final rig = await _Rig.create();
    await rig.runtime.switchTo(rig.h.a);
    final container = rig.runtime.container;

    await rig.sequence.signOut(rig.h.b);

    expect(rig.log, [
      'DELETE /api/api-keys/current',
      'delete refresh',
      'delete access',
      'delete apikey',
    ]);
    expect(rig.server.headers.single['X-API-Key'], 'b-key');
    expect(await rig.stateOf(rig.h.b), ProfileState.signedOut);
    expect(await rig.stateOf(rig.h.a), ProfileState.active);
    expect(rig.runtime.container, same(container));
  });

  group('removeServer', () {
    test('beforeRemove runs before the flush; the directory and row go and '
        'the most recently used signed-in profile becomes active', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.b);
      rig.h.clock.advance(const Duration(minutes: 1));
      await rig.runtime.switchTo(rig.h.a);

      await rig.sequence.removeServer(rig.h.a);

      expect(rig.log.take(4), [
        'playback.onSignOut(removeDownloads: false)',
        'playback.beforeRemove',
        'flush',
        'POST /api/auth/logout',
      ]);
      expect(await rig.profiles.byId(rig.h.a), isNull);
      expect(rig.h.paths.deletedTrees, [rig.h.a]);
      expect(rig.h.opener.deleted, [
        StateDatabaseTarget(rig.h.a),
        CacheDatabaseTarget(rig.h.a),
      ]);
      expect(rig.secretsOf(rig.h.a), isEmpty);
      expect(rig.h.root.read(activeProfileIdProvider), rig.h.b);
      expect(rig.runtime.state.value, ProfileRuntimeActive(rig.h.b));
    });

    test('a signed-out profile is not chosen; with no other signed-in '
        'profile none is active', () async {
      final rig = await _Rig.create();
      await rig.profiles.setState(rig.h.b, ProfileState.signedOut);
      await rig.runtime.switchTo(rig.h.a);

      await rig.sequence.removeServer(rig.h.a);

      expect(rig.h.root.read(activeProfileIdProvider), isNull);
      expect(rig.runtime.state.value, ProfileRuntimeState.none);
      expect(await rig.profiles.byId(rig.h.a), isNull);
    });

    test('removing an inactive profile keeps the active one', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);

      await rig.sequence.removeServer(rig.h.b);

      expect(await rig.profiles.byId(rig.h.b), isNull);
      expect(rig.runtime.state.value, ProfileRuntimeActive(rig.h.a));
      expect(rig.log, isNot(contains('flush')));
    });
  });

  group('pendingChanges', () {
    test('of the active profile: its outbox count', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);
      rig.scope.pending = 3;

      expect(await rig.sequence.pendingChanges(rig.h.a), 3);
    });

    test('of an inactive profile: counted in its state.db', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);

      expect(await rig.sequence.pendingChanges(rig.h.b), 0);
      expect(rig.h.opener.closed, contains(StateDatabaseTarget(rig.h.b)));
    });
  });

  group('downloadsSummary', () {
    test('is null with no downloads participant', () async {
      final rig = await _Rig.create();
      await rig.runtime.switchTo(rig.h.a);

      expect(await rig.sequence.downloadsSummary(rig.h.a), isNull);
    });

    test('is what a participant reports for the active profile, and null '
        'for an inactive one', () async {
      const summary = DownloadsSummary(itemCount: 3, bytes: 900);
      final rig = await _Rig.create(participants: [_Downloads(summary)]);
      await rig.runtime.switchTo(rig.h.a);

      expect(await rig.sequence.downloadsSummary(rig.h.a), summary);
      expect(await rig.sequence.downloadsSummary(rig.h.b), isNull);
    });

    test('is null when the participant reports none or fails', () async {
      final none = await _Rig.create(
        participants: [
          _Downloads(const DownloadsSummary(itemCount: 0, bytes: 0)),
        ],
      );
      await none.runtime.switchTo(none.h.a);
      expect(await none.sequence.downloadsSummary(none.h.a), isNull);

      final failing = await _Rig.create(
        participants: [_Downloads(null, failure: StateError('db closed'))],
      );
      await failing.runtime.switchTo(failing.h.a);
      expect(await failing.sequence.downloadsSummary(failing.h.a), isNull);
    });
  });

  test('after signOut, cache.db, state.db and a file in the media directory '
      'still exist', () async {
    final root = await Directory.systemTemp.createTemp('sign_out');
    addTearDown(() => root.delete(recursive: true));
    final paths = IoAppPaths(
      appSupport: '${root.path}/support',
      appCache: '${root.path}/cache',
    );
    final opener = IoDatabaseOpener(paths);
    final h = await ProfileHarness.create(
      appPaths: paths,
      databaseOpener: opener,
    );
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    await runtime.switchTo(h.a);
    final profilePaths = paths.profile(h.a);
    final cache = CacheDatabase(opener.open(CacheDatabaseTarget(h.a)));
    await cache.customSelect('SELECT 1').get();
    await cache.close();
    final song = File('${profilePaths.media}/song.flac');
    await song.create(recursive: true);
    final log = <String>[];
    final server = _Server(log);
    final sequence = SignOutSequence(
      runtime: runtime,
      profiles: h.root.read(profileRepositoryProvider),
      revoker: ApiSessionRevoker(
        userAgent: 'soundspan-test',
        apis: (config, credentials) =>
            SoundspanApi(config, credentials: credentials, adapter: server),
      ),
      opener: opener,
      clock: h.clock,
      scopeOf: (_) => _Scope(log, const []),
    );

    await sequence.signOut(h.a);

    expect(File(profilePaths.stateDb).existsSync(), isTrue);
    expect(File(profilePaths.cacheDb).existsSync(), isTrue);
    expect(song.existsSync(), isTrue);
    await runtime.dispose();
  });

  test('no log line contains a token or a key', () async {
    final rig = await _Rig.create(
      participants: [_Participant(<String>[], 'p', fail: true)],
    );
    await rig.runtime.switchTo(rig.h.a);
    rig.server.status = 401;
    await rig.sequence.signOut(rig.h.a);
    await rig.runtime.switchTo(rig.h.b);
    rig.server.offline = true;
    await rig.sequence.removeServer(rig.h.b);

    expect(logs.entries, isNotEmpty);
    for (final line in logLines()) {
      for (final secret in ['a-access', 'a-r', 'b-key']) {
        expect(line, isNot(contains(secret)));
      }
    }
  });
}

/// Waits until [done] holds, for at most 100 rounds of the event queue.
Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await pumpEventQueue();
  }
}

/// The one-shot timers the sequence created; a test fires them.
class _Timers {
  final List<_OneShot> created = [];

  Timer create(Duration duration, void Function() callback) {
    final timer = _OneShot(duration, callback);
    created.add(timer);
    return timer;
  }
}

class _OneShot implements Timer {
  new(this.duration, this._callback);

  final Duration duration;
  final void Function() _callback;
  bool _active = true;

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
  int get tick => 0;
}

/// A participant that reports [summary] as its downloads, or throws
/// [failure].
class _Downloads implements SignOutParticipant, ReportsDownloads {
  new(this.summary, {this.failure});

  final DownloadsSummary? summary;
  final Error? failure;

  @override
  Future<DownloadsSummary?> downloadsSummary() async {
    if (failure case final error?) throw error;
    return summary;
  }

  @override
  Future<void> onSignOut({required bool removeDownloads}) async {}

  @override
  Future<void> beforeRemove() async {}
}
