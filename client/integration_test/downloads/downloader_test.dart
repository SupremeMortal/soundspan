// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// The native downloader on a real desktop target (doc 07, Transfers;
// doc 11, Integration). Run by the client-downloads-integration job on
// Linux under Xvfb, with the contract server started and seeded:
//
//   xvfb-run -a flutter test integration_test/downloads -d linux \
//     --tags downloads \
//     --dart-define=DOWNLOADS_SEED=<abs path>/contract_test/.seed/credentials.json
@Tags(['downloads'])
@Timeout(Duration(minutes: 6))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/download_request_builder.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/platform/downloader/downloader_io.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../support/throttled_file_server.dart';

/// The contract suite's `credentials.json`, written by `seed.ts`.
const _seedPath = String.fromEnvironment(
  'DOWNLOADS_SEED',
  defaultValue: 'contract_test/.seed/credentials.json',
);

/// The 30-second fixture track of the contract library.
const _fixtureTitle = 'Aster Tone';

const _userAgent = 'soundspan-downloads-test';

/// Holds one JWT session in memory.
final class _Session implements CredentialProvider {
  new(this.current);

  @override
  Credentials? current;

  @override
  Future<void> onTokensRotated(JwtCredentials next) async => current = next;

  @override
  void onUnauthenticated(UnauthenticatedReason reason) => current = null;
}

/// The events of one task until its final one.
final class _Run {
  new(this.events);

  final List<DownloaderEvent> events;

  DownloaderEvent get last => events.last;

  DownloaderResponseInfo? get info =>
      events.whereType<DownloaderResponseInfo>().firstOrNull;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final downloader = BackgroundDownloader();
  late Stream<DownloaderEvent> events;
  late String appSupport;
  final profiles = <String>[];

  setUpAll(() async {
    await downloader.start();
    events = downloader.events.asBroadcastStream();
    appSupport = (await getApplicationSupportDirectory()).path;
  });

  tearDownAll(() async {
    for (final profile in profiles) {
      final dir = Directory('$appSupport/profiles/$profile');
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
  });

  /// A new profile's download paths, deleted when the suite ends.
  DownloadPaths newProfile() {
    final id = 'dl-${DateTime.now().microsecondsSinceEpoch}';
    profiles.add(id);
    return DownloadPaths(
      ProfilePaths.derive(
        appSupport: appSupport,
        appCache: appSupport,
        profileId: id,
      ),
    );
  }

  /// Collects [taskId]'s events from now until it completes or fails.
  Future<_Run> runOf(
    String taskId, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    final seen = <DownloaderEvent>[];
    await for (final event in events.timeout(timeout)) {
      if (event.taskId != taskId) continue;
      seen.add(event);
      if (event is DownloaderCompleted || event is DownloaderFailed) break;
    }
    return _Run(seen);
  }

  /// Waits until [taskId] has received at least [fraction] of its bytes.
  Future<void> progressOf(String taskId, double fraction) => events
      .where((e) => e.taskId == taskId)
      .firstWhere(
        (e) =>
            e is DownloaderProgress &&
            e.expectedBytes != null &&
            e.receivedBytes >= e.expectedBytes! * fraction,
      )
      .timeout(const Duration(minutes: 1));

  DownloadItem item(String itemKey, String downloadUrl) => DownloadItem(
    itemKey: itemKey,
    mediaType: MediaType.track,
    metaJson: '{}',
    status: DownloadStatus.queued,
    downloadUrl: downloadUrl,
    receivedBytes: 0,
    attempts: 0,
    serverConfirmed: false,
    requestedAt: DateTime.now().toUtc(),
  );

  group('against the contract server', () {
    late Uri baseUrl;
    late _Session session;
    late SoundspanApi api;
    late String playbackId;

    setUpAll(() async {
      final seed = jsonDecode(
        File(_seedPath).readAsStringSync(),
      ) as Map<String, Object?>;
      baseUrl = Uri.parse(seed['baseUrl']! as String);
      final listener = seed['listener']! as Map<String, Object?>;
      final anonymous = SoundspanApi.anonymous(baseUrl, userAgent: _userAgent);
      final login = await anonymous.send(
        (rest) => rest.session.login(
          body: LoginRequest(
            username: listener['username']! as String,
            password: listener['password']! as String,
          ),
        ),
      );
      anonymous.close();
      if (login is! LoginTokenResponse) {
        fail('the listener did not sign in: $login');
      }
      session = _Session(
        JwtCredentials(
          accessToken: login.token,
          refreshToken: login.refreshToken,
        ),
      );
      api = SoundspanApi(
        ApiConfig(baseUrl: baseUrl, userAgent: _userAgent),
        credentials: session,
      );
      final page = await api.send(
        (rest) => rest.library2.listTracks(limit: 100),
      );
      playbackId = page.tracks
          .singleWhere((t) => t.title == _fixtureTitle)
          .playbackId!;
    });

    tearDownAll(() => api.close());

    /// The request for [streamUrl] built as the app builds it.
    Future<DownloadRequest> buildFor(
      DownloadPaths paths,
      String itemKey,
      Uri streamUrl,
    ) =>
        DownloadRequestBuilder(
          paths: paths,
          urls: StreamUrls(baseUrl),
          currentCredentials: () => session.current,
          ensureFresh: ({required minRemaining}) async => session.current!,
        ).build(
          item(itemKey, streamUrl.toString().substring('$baseUrl'.length)),
          wifiOnly: false,
          userInitiated: true,
        );

    testWidgets('a track downloads with auth headers to its .part file, of '
        'the size stream-info reports', (tester) async {
      final paths = newProfile();
      final info = await api.send(
        (rest) => rest.playback.getStreamInfo(
          playbackId: playbackId,
          quality: PlaybackQuality.original,
        ),
      );
      final request = await buildFor(
        paths,
        't:$playbackId',
        StreamUrls(baseUrl).track(playbackId, quality: 'original'),
      );
      expect(request.headers, contains('Authorization'));

      final run = runOf(request.taskId);
      await downloader.enqueue(request);
      final result = await run;

      final completed = result.last;
      expect(completed, isA<DownloaderCompleted>(), reason: '${result.events}');
      final hash = itemKeyHash(TrackItemKey(playbackId));
      expect((completed as DownloaderCompleted).filePath, paths.partFile(hash));
      expect(File(completed.filePath).lengthSync(), info.contentLength);
      expect(result.info?.isStrongEtag, isTrue);
    });

    testWidgets('a request without credentials fails with 401', (tester) async {
      final paths = newProfile();
      final built = await buildFor(
        paths,
        't:$playbackId',
        StreamUrls(baseUrl).track(playbackId, quality: 'original'),
      );
      final request = DownloadRequest(
        taskId: built.taskId,
        url: built.url,
        headers: const {},
        profileId: built.profileId,
        relativeDirectory: built.relativeDirectory,
        filename: built.filename,
        requiresWifi: false,
        highPriority: true,
        metaData: built.metaData,
      );

      final run = runOf(request.taskId);
      await downloader.enqueue(request);

      expect(
        (await run).last,
        DownloaderFailed(
          taskId: request.taskId,
          group: request.group,
          kind: DownloaderFailureKind.http,
          httpStatus: 401,
        ),
      );
    });

    testWidgets('an unknown id fails with 404', (tester) async {
      final paths = newProfile();
      const unknown = 't.no-such-download-track';
      final request = await buildFor(
        paths,
        't:$unknown',
        StreamUrls(baseUrl).track(unknown, quality: 'original'),
      );

      final run = runOf(request.taskId);
      await downloader.enqueue(request);

      expect(
        (await run).last,
        DownloaderFailed(
          taskId: request.taskId,
          group: request.group,
          kind: DownloaderFailureKind.http,
          httpStatus: 404,
        ),
      );
    });
  });

  group('Resume Rule against a throttled local server', () {
    late ThrottledFileServer server;

    setUpAll(() async => server = await ThrottledFileServer.start());
    tearDownAll(() => server.close());

    DownloadRequest requestFor(DownloadPaths paths, String path) {
      final key = TrackItemKey('throttled$path-${paths.profile.profileId}');
      final hash = itemKeyHash(key);
      return DownloadRequest(
        taskId: hash,
        url: server.uri.resolve(path),
        headers: const {},
        profileId: paths.profile.profileId,
        relativeDirectory: 'media/${hash.substring(0, 2)}',
        filename: '$hash.part',
        requiresWifi: false,
        highPriority: true,
        metaData: key.encode(),
      );
    }

    for (final (path, description) in [
      ('/ranged', 'a server that answers 206 to a range'),
      ('/full200', 'a server that answers 200 to a range'),
      ('/weak', 'a weak ETag'),
    ]) {
      testWidgets('with $description, pause cancels, resume asks for a '
          'restart, and the restarted file is byte-identical', (tester) async {
        server.requests.clear();
        final paths = newProfile();
        final request = requestFor(paths, path);

        final first = runOf(request.taskId);
        await downloader.enqueue(request);
        await progressOf(request.taskId, 0.3);
        expect(await downloader.pause(request.taskId), isFalse);
        expect(
          (await first).last,
          isA<DownloaderFailed>().having(
            (f) => f.kind,
            'kind',
            DownloaderFailureKind.cancelled,
          ),
        );
        expect(await downloader.resume(request.taskId), isFalse);

        final second = runOf(request.taskId);
        await downloader.enqueue(request);
        final completed = (await second).last;

        expect(completed, isA<DownloaderCompleted>());
        final bytes = File((completed as DownloaderCompleted).filePath)
            .readAsBytesSync();
        expect(bytes.length, server.body.length);
        expect(bytes, server.body);
        expect(
          server.requests.where((r) => r.path == path).map((r) => r.range),
          everyElement(isNull),
          reason: 'a restart fetches the whole file, never a range',
        );
      });
    }

    testWidgets('a second instance sees, after start(), the task the first '
        'enqueued', (tester) async {
      final paths = newProfile();
      final request = requestFor(paths, '/ranged');

      final run = runOf(request.taskId);
      await downloader.enqueue(request);

      final second = BackgroundDownloader();
      await second.start();
      final completedBySecond = second.events.firstWhere(
        (e) => e.taskId == request.taskId && e is DownloaderCompleted,
      );
      expect(
        await second.liveTaskIds(group: request.group),
        contains(request.taskId),
      );

      expect((await run).last, isA<DownloaderCompleted>());
      expect(
        await completedBySecond.timeout(const Duration(seconds: 30)),
        isA<DownloaderCompleted>(),
      );
      expect(
        await second.liveTaskIds(group: request.group),
        isNot(contains(request.taskId)),
      );
    });
  });
}
