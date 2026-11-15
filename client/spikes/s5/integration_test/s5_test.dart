// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Spike S5 harness (docs/designs/flutter-client/13-milestones-and-work-breakdown.md,
// Spikes, row S5), Linux part: questions 1 to 3. Every case prints one
// `S5-Q<n> ... answer=<yes|no>` line and the `S5-HTTP {json}` lines of the
// requests it caused; the workflow turns those into the job summary and the
// proxy-log artifact. A case fails only on a harness error, never on a "no".
//
// Dart defines: S5_SEED, the absolute path of the contract suite's
// .seed/credentials.json.
@Timeout(Duration(minutes: 6))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:spike_s5/harness.dart';

const _seedPath = String.fromEnvironment('S5_SEED');
const _fixtureTitle = 'Aster Tone';
const _pluginVersion = '9.6.6';

/// What one pause-and-resume run observed.
typedef _Run = ({
  double pausedAtProgress,
  TaskStatus finalStatus,
  String? exception,
  List<int> file,
});

/// The plugin's single-subscription update stream, shared by the cases.
late final Stream<TaskUpdate> _updates;

void _say(String line) => debugPrint(line);

Future<T> _within<T>(Future<T> future, int seconds, String what) =>
    future.timeout(Duration(seconds: seconds), onTimeout: () => throw what);

/// Enqueues [task], pauses it once progress reaches 0.4, resumes it and
/// waits for a final status; returns the downloaded file's bytes.
Future<_Run> _pauseAndResume(DownloadTask task) async {
  final paused = Completer<void>();
  final done = Completer<TaskStatusUpdate>();
  final reachedTarget = Completer<double>();
  final subscription = _updates
      .where((update) => update.task.taskId == task.taskId)
      .listen((update) {
        switch (update) {
          case TaskProgressUpdate(:final progress):
            if (progress >= 0.4 && !reachedTarget.isCompleted) {
              reachedTarget.complete(progress);
            }
          case TaskStatusUpdate(:final status):
            _say('S5-STATUS taskId=${task.taskId} status=${status.name}');
            if (status == TaskStatus.paused && !paused.isCompleted) {
              paused.complete();
            } else if (status.isFinalState && !done.isCompleted) {
              done.complete(update);
            }
        }
      });
  try {
    expect(await FileDownloader().enqueue(task), isTrue, reason: 'enqueue');
    final at = await _within(reachedTarget.future, 60, 'never reached 40 %');
    expect(await FileDownloader().pause(task), isTrue, reason: 'pause');
    await _within(paused.future, 30, 'never reported paused');
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(await FileDownloader().resume(task), isTrue, reason: 'resume');
    final last = await _within(done.future, 120, 'never finished');
    final path = await task.filePath();
    final file = File(path).existsSync()
        ? await File(path).readAsBytes()
        : <int>[];
    return (
      pausedAtProgress: at,
      finalStatus: last.status,
      exception: last.exception?.description,
      file: file,
    );
  } finally {
    await subscription.cancel();
  }
}

DownloadTask _task(String id, Uri url, Map<String, String> headers) =>
    DownloadTask(
      taskId: id,
      url: url.toString(),
      headers: headers,
      baseDirectory: BaseDirectory.applicationSupport,
      directory: 's5',
      filename: '$id.part',
      updates: Updates.statusAndProgress,
      retries: 0,
      allowPause: true,
    );

Future<Map<String, Object?>> _json(
  HttpClient client,
  String method,
  Uri uri, {
  String? token,
  Object? body,
}) async {
  final request = await client.openUrl(method, uri);
  if (token != null) request.headers.set('authorization', 'Bearer $token');
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  if (response.statusCode != 200) {
    throw HttpException('$method ${uri.path} answered ${response.statusCode}');
  }
  return jsonDecode(text) as Map<String, Object?>;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // The plugin is created in its own zone: without NetworkManager on the
    // system bus, connectivity_plus fails asynchronously and the plugin does
    // not handle that error (it then keeps its default "connected").
    final ready = Completer<void>();
    runZonedGuarded(
      () async {
        await FileDownloader().start(doRescheduleKilledTasks: false);
        ready.complete();
      },
      (error, _) {
        _say('S5-NOTE unhandled plugin error: ${'$error'.split('\n').first}');
      },
    );
    await ready.future;
    _updates = FileDownloader().updates.asBroadcastStream();
    _say('S5-VERSION background_downloader=$_pluginVersion');
  });

  group('real server through the proxy', () {
    late ThrottleProxy proxy;
    late Uri streamPath;
    late Map<String, String> auth;
    late List<int> reference;

    setUpAll(() async {
      expect(_seedPath, isNotEmpty, reason: 'pass --dart-define=S5_SEED');
      final seed = jsonDecode(
        File(_seedPath).readAsStringSync(),
      ) as Map<String, Object?>;
      final base = Uri.parse(seed['baseUrl']! as String);
      final listener = seed['listener']! as Map<String, Object?>;
      final client = HttpClient();
      try {
        final login = await _json(
          client,
          'POST',
          base.resolve('/api/auth/login'),
          body: {
            'username': listener['username'],
            'password': listener['password'],
          },
        );
        final token = login['token']! as String;
        auth = {'Authorization': 'Bearer $token'};
        final page = await _json(
          client,
          'GET',
          base.resolve('/api/library/tracks?limit=100'),
          token: token,
        );
        final track = (page['tracks']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .singleWhere((t) => t['title'] == _fixtureTitle);
        streamPath = Uri(
          path: '/api/playback/stream/${track['playbackId']}',
          queryParameters: {'quality': 'original', 'report': '0'},
        );
      } finally {
        client.close(force: true);
      }
      reference = await fetchReference(base.resolve('$streamPath'), auth);
      proxy = await ThrottleProxy.start(base);
    });

    tearDownAll(() => proxy.close());

    testWidgets('resume_sends_range_and_if_range and appends_on_206', (
      tester,
    ) async {
      final id = 's5-real-${DateTime.now().millisecondsSinceEpoch}';
      final run = await _pauseAndResume(
        _task(id, proxy.uri.resolve('$streamPath'), auth),
      );
      for (final exchange in proxy.exchanges) {
        _say(exchange.toLine());
      }
      expect(
        proxy.exchanges.length,
        greaterThanOrEqualTo(2),
        reason: 'pause and resume make two requests',
      );
      final first = proxy.exchanges.first;
      final second = proxy.exchanges[1];
      final start = second.rangeStart;
      final rangeAtOffset =
          start != null && start > 0 && start <= first.bytesSent;
      final ifRangeIsEtag =
          second.ifRange != null && second.ifRange == first.etag;
      _say(
        'S5-Q1 test=resume_sends_range_and_if_range '
        'pausedAtProgress=${run.pausedAtProgress.toStringAsFixed(2)} '
        'firstStatus=${first.status} firstEtag=${first.etag} '
        'firstBytesSent=${first.bytesSent} '
        'resumeRange=${second.range} resumeIfRange=${second.ifRange} '
        'rangeAtPausedOffset=$rangeAtOffset ifRangeEqualsEtag=$ifRangeIsEtag '
        'answer=${rangeAtOffset && ifRangeIsEtag ? 'yes' : 'no'}',
      );
      final identical =
          run.file.length == reference.length &&
          sha256Hex(run.file) == sha256Hex(reference);
      _say(
        'S5-Q2 test=appends_on_206 resumeStatus=${second.status} '
        'resumeContentRange=${second.contentRange} '
        'finalStatus=${run.finalStatus.name} exception=${run.exception} '
        'fileBytes=${run.file.length} referenceBytes=${reference.length} '
        'fileSha256=${sha256Hex(run.file)} '
        'referenceSha256=${sha256Hex(reference)} '
        'answer=${second.status == 206 && identical ? 'yes' : 'no'}',
      );
    });
  });

  group('local server answering 200 to every request', () {
    late SlowServer server;

    setUpAll(() async => server = await SlowServer.start());
    tearDownAll(() => server.close());

    for (final (name, path) in [
      ('restarts_on_200_with_etag', '/full'),
      ('restarts_on_200_without_etag', '/full-noetag'),
    ]) {
      testWidgets(name, (tester) async {
        server.exchanges.clear();
        final id = 's5-$name-${DateTime.now().millisecondsSinceEpoch}';
        final run = await _pauseAndResume(
          _task(id, server.uri.resolve('$path?seconds=10'), const {}),
        );
        for (final exchange in server.exchanges) {
          _say(exchange.toLine());
        }
        expect(server.exchanges.length, greaterThanOrEqualTo(2));
        final second = server.exchanges[1];
        final identical =
            run.file.length == slowBody.length &&
            sha256Hex(run.file) == sha256Hex(slowBody);
        _say(
          'S5-Q3 test=$name '
          'pausedAtProgress=${run.pausedAtProgress.toStringAsFixed(2)} '
          'resumeRange=${second.range} resumeIfRange=${second.ifRange} '
          'resumeStatus=${second.status} '
          'finalStatus=${run.finalStatus.name} exception=${run.exception} '
          'fileBytes=${run.file.length} bodyBytes=${slowBody.length} '
          'fileSha256=${sha256Hex(run.file)} '
          'bodySha256=${sha256Hex(slowBody)} '
          'answer=${run.finalStatus == TaskStatus.complete && identical ? 'yes' : 'no'}',
        );
      });
    }
  });
}
