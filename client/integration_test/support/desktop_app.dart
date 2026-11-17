// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The real app on a desktop runner for the desktop integration tests (doc
/// 11, Integration (desktop)): an in-process API server and a launcher that
/// starts the app through `bootstrap` with a signed-in profile of that
/// server, so no backend is needed.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show FlutterError, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:soundspan/app/app.dart';
import 'package:soundspan/app/shell/adaptive_shell.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/playback/engines/media_kit_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/core/storage/app/app_database.dart' hide Profile;
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/platform/clock/system_clock.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths_io.dart';
import 'package:soundspan_api/soundspan_api.dart'
    show JwtCredentials, StreamStatusProbe;

import '../../test/helpers/in_memory_secret_store.dart';
import 'device_audio_output.dart';
import 'tone_server.dart';

/// One track of the [DesktopApiServer] album.
typedef SmokeTrack = ({String id, String title});

/// A `shelf` server on the loopback interface that answers what the app
/// asks for at start-up, one album and its streams; every other path is a
/// 404. It never answers 401, so the profile stays signed in.
final class DesktopApiServer {
  new _(this._server);

  /// Starts the server on a free port.
  static Future<DesktopApiServer> start() async {
    // A test binding may mock HttpClient; the app talks to this server.
    HttpOverrides.global = null;
    late DesktopApiServer api;
    final server = await shelf_io.serve(
      (request) => api._handle(request),
      InternetAddress.loopbackIPv4,
      0,
    );
    return api = DesktopApiServer._(server);
  }

  /// The server version: the client's `minServer`.
  static const String version = '2.7.0';

  /// The id of the album.
  static const String albumId = 'smoke-album';

  /// The album's title.
  static const String albumTitle = 'Smoke Album';

  /// The album's tracks, in order; each streams a [trackLength] tone.
  static const List<SmokeTrack> tracks = [
    (id: 'smoke-1', title: 'First smoke tone'),
    (id: 'smoke-2', title: 'Second smoke tone'),
    (id: 'smoke-3', title: 'Third smoke tone'),
  ];

  /// The length of every track.
  static const Duration trackLength = Duration(seconds: 30);

  final HttpServer _server;
  late final List<int> _tone = ToneServer.wav(trackLength);

  /// The paths requested, in order.
  final List<String> requested = [];

  /// The server base URL.
  Uri get baseUrl => Uri.parse('http://127.0.0.1:${_server.port}');

  /// Stops the server.
  Future<void> close() => _server.close(force: true);

  Response _json(Object body, {int status = 200}) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );

  Future<Response> _handle(Request request) async {
    final path = '/${request.url.path}';
    requested.add('${request.method} $path');
    if (path.startsWith('/api/playback/stream/')) {
      return Response.ok(
        _tone,
        headers: {
          'content-type': 'audio/wav',
          'content-length': '${_tone.length}',
          'accept-ranges': 'none',
        },
      );
    }
    if (path.startsWith('/api/playback/stream-info/')) {
      return _json({
        'playbackId': path.split('/').last,
        'quality': 'original',
        'codec': 'wav',
        'contentType': 'audio/wav',
        'contentLength': _tone.length,
        'durationMs': trackLength.inMilliseconds,
        'sampleRate': ToneServer.sampleRate,
        'bitDepth': 16,
        'bitrate': 706,
      });
    }
    return switch ((request.method, path)) {
      ('GET', '/api/health') => _json({
        'status': 'ok',
        'draining': false,
        'startupComplete': true,
        'role': 'all',
        'uptimeSeconds': 1,
        'version': version,
      }),
      ('GET', '/api/docs.json') => _json({
        'openapi': '3.1.0',
        'info': {'title': 'soundspan', 'version': version},
        'paths': <String, Object?>{},
      }),
      ('GET', '/api/system/features') => _json({
        'audioAnalysis': false,
        'autoPlaylists': false,
        'discovery': false,
        'federation': false,
        'loudnessTargetLufs': -14,
        'vibeEmbeddings': false,
      }),
      ('GET', '/api/auth/me') => _json({
        'id': 'smoke-user',
        'username': 'smoke',
        'role': 'user',
        'onboardingComplete': true,
        'displayName': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
      }),
      ('POST', '/api/auth/refresh') => _json({
        'token': 'access',
        'refreshToken': 'refresh',
      }),
      ('GET', '/api/library/albums/$albumId') => _json(_album()),
      _ => _json({'error': 'not found'}, status: 404),
    };
  }

  Map<String, Object?> _album() => {
    'id': albumId,
    'title': albumTitle,
    'artistId': 'smoke-artist',
    'artist': {'id': 'smoke-artist', 'name': 'Smoke Artist'},
    'coverArt': null,
    'matchedInLibrary': false,
    'matchedRgMbid': null,
    'owned': true,
    'rgMbid': null,
    'source': 'local',
    'year': 2026,
    'tracks': [
      for (final (index, track) in tracks.indexed)
        {
          'id': track.id,
          'title': track.title,
          'duration': trackLength.inSeconds,
          'trackNo': index + 1,
          'discNo': 1,
          'albumId': albumId,
          'playbackId': 't.${track.id}',
        },
    ],
  };
}

/// The started app: its root container and the directory it keeps its
/// files in.
final class DesktopApp {
  new _(this.container, this.directory);

  /// The root container `bootstrap` built.
  final ProviderContainer container;

  /// The app's support and cache directories live under it.
  final Directory directory;
}

/// Starts the real app through `bootstrap` with a signed-in profile of
/// [server], its files in a new temporary directory, an in-memory secret
/// store and mpv's audio output of the device harness (doc 06), and pumps
/// until the shell shows.
Future<DesktopApp> startDesktopApp(
  WidgetTester tester,
  DesktopApiServer server,
) async {
  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('soundspan-desktop-'),
  ))!;
  final paths = IoAppPaths(
    appSupport: '${directory.path}/support',
    appCache: '${directory.path}/cache',
  );
  final secrets = InMemorySecretStore();
  await tester.runAsync(() => _seedProfile(paths, secrets, server.baseUrl));
  final ao = deviceAudioOutput(operatingSystem: Platform.operatingSystem);
  _guardStartupTasks();
  // bootstrap routes framework errors to the app's logger; the test's own
  // handler is put back so an error fails the test.
  final testOnError = FlutterError.onError;
  await tester.runAsync(
    () => bootstrap(
      paths: paths,
      secretStore: secrets,
      overrides: [
        if (ao != null)
          playerEngineBuilderProvider.overrideWithValue(() {
            MediaKitEngine.ensureInitialized();
            final probe = StreamStatusProbe();
            return MediaKitEngine(
              statusOf: (uri, headers) => probe.status(uri, headers: headers),
              audioOutputOverride: ao,
            );
          }),
      ],
    ),
  );
  FlutterError.onError = testOnError;
  await pumpUntil(
    tester,
    () => find.byType(AdaptiveShell).evaluate().isNotEmpty,
    reason: 'the app reaches the shell',
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SoundspanApp)),
  );
  return DesktopApp._(container, directory);
}

/// The errors the start-up tasks raised, which the app logs.
final List<Object> startupTaskErrors = [];

bool _guarded = false;

/// In the app, `bootstrap` creates the binding inside its guarded zone, so
/// an uncaught error of a start-up task is logged (doc 02). Here the test
/// binding exists first and runs frame callbacks in the test's zone, so each
/// task runs in a guarded zone of its own that records and prints the error
/// instead: a runner without a system bus or NetworkManager fails
/// connectivity checks the app tolerates.
void _guardStartupTasks() {
  if (_guarded) return;
  _guarded = true;
  for (var i = 0; i < postFirstFrameTasks.length; i++) {
    final task = postFirstFrameTasks[i];
    postFirstFrameTasks[i] = (root) {
      final done = Completer<void>();
      runZonedGuarded(
        () => unawaited(
          task(root).whenComplete(() {
            if (!done.isCompleted) done.complete();
          }),
        ),
        (error, stackTrace) {
          startupTaskErrors.add(error);
          debugPrint('Start-up task error (logged by the app): $error');
          if (!done.isCompleted) done.complete();
        },
      );
      return done.future;
    };
  }
}

Future<void> _seedProfile(
  IoAppPaths paths,
  InMemorySecretStore secrets,
  Uri baseUrl,
) async {
  final opener = createDatabaseOpener(paths);
  final database = AppDatabase(opener.open(const AppDatabaseTarget()));
  try {
    const clock = SystemClock();
    final profile =
        await ProfileRepository(
          database,
          secrets,
          paths,
          opener,
          clock,
        ).upsertSignedIn(
          baseUrl: baseUrl,
          userId: 'smoke-user',
          username: 'smoke',
          role: 'user',
          authKind: AuthKind.password,
          credentials: const JwtCredentials(
            accessToken: 'access',
            refreshToken: 'refresh',
          ),
          credentialCreatedAt: clock.now(),
        );
    await AppSettingsStore(database)
        .write(AppSettingKeys.activeProfileId, profile.id);
  } finally {
    await database.close();
  }
}

/// Pumps in real time until [done] holds, failing with [reason] after
/// [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  required String reason,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final watch = Stopwatch()..start();
  while (!done()) {
    if (watch.elapsed > timeout) fail('Timed out: $reason');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}
