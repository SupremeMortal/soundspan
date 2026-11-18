// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/downloader/downloader.dart';

import 'fake_downloader.dart';

DownloadRequest _request(String taskId) => DownloadRequest(
  taskId: taskId,
  url: Uri.parse('https://music.example.com/api/offline/download/$taskId'),
  headers: const {'X-API-Key': 'k'},
  profileId: 'prof-1',
  relativeDirectory: p.join('media', taskId.substring(0, 2)),
  filename: '$taskId.part',
  requiresWifi: false,
  highPriority: true,
  metaData: 't:$taskId',
);

void main() {
  late Directory root;
  late FakeDownloader downloader;
  late List<DownloaderEvent> events;

  setUp(() async {
    root = Directory.systemTemp.createTempSync('fake_downloader_test');
    downloader = FakeDownloader(appSupport: root.path);
    events = [];
    downloader.events.listen(events.add);
    await downloader.start();
  });

  tearDown(() async {
    await downloader.dispose();
    root.deleteSync(recursive: true);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('records requests and lists them as live in their group', () async {
    await downloader.enqueue(_request('aa11'));
    await downloader.enqueue(_request('bb22'));

    expect(downloader.requests.map((r) => r.taskId), ['aa11', 'bb22']);
    expect(await downloader.liveTaskIds(group: 'p:prof-1'), {'aa11', 'bb22'});
    expect(await downloader.liveTaskIds(group: 'p:other'), isEmpty);
  });

  test('emits the scripted events in order and writes a file of the '
      'scripted size at the requested path', () async {
    await downloader.enqueue(_request('aa11'));

    downloader.emitProgress('aa11', receivedBytes: 10, expectedBytes: 100);
    final path = await downloader.complete(
      'aa11',
      bytes: 100,
      etag: '"e1"',
      contentType: 'audio/flac',
      contentLength: 100,
    );
    await settle();

    expect(
      path,
      p.join(root.path, 'profiles', 'prof-1', 'media', 'aa', 'aa11.part'),
    );
    expect(File(path).lengthSync(), 100);
    expect(events, [
      const DownloaderProgress(
        taskId: 'aa11',
        group: 'p:prof-1',
        receivedBytes: 10,
        expectedBytes: 100,
      ),
      const DownloaderResponseInfo(
        taskId: 'aa11',
        group: 'p:prof-1',
        etag: '"e1"',
        isStrongEtag: true,
        contentType: 'audio/flac',
        contentLength: 100,
      ),
      DownloaderCompleted(taskId: 'aa11', group: 'p:prof-1', filePath: path),
    ]);
    expect(await downloader.liveTaskIds(group: 'p:prof-1'), isEmpty);
  });

  test('a truncated completion writes fewer bytes than announced', () async {
    await downloader.enqueue(_request('aa11'));

    final path = await downloader.completeTruncated(
      'aa11',
      bytes: 40,
      contentLength: 100,
    );
    await settle();

    expect(File(path).lengthSync(), 40);
    expect(
      events.whereType<DownloaderResponseInfo>().single.contentLength,
      100,
    );
    expect(events.last, isA<DownloaderCompleted>());
  });

  test('injects 401 and 404 failures', () async {
    await downloader.enqueue(_request('aa11'));
    await downloader.enqueue(_request('bb22'));

    downloader
      ..fail('aa11', kind: DownloaderFailureKind.http, httpStatus: 401)
      ..fail('bb22', kind: DownloaderFailureKind.http, httpStatus: 404);
    await settle();

    expect(events, [
      const DownloaderFailed(
        taskId: 'aa11',
        group: 'p:prof-1',
        kind: DownloaderFailureKind.http,
        httpStatus: 401,
      ),
      const DownloaderFailed(
        taskId: 'bb22',
        group: 'p:prof-1',
        kind: DownloaderFailureKind.http,
        httpStatus: 404,
      ),
    ]);
    expect(await downloader.liveTaskIds(group: 'p:prof-1'), isEmpty);
  });

  test('dropTask removes a task from the live set without an event', () async {
    await downloader.enqueue(_request('aa11'));

    downloader.dropTask('aa11');
    await settle();

    expect(await downloader.liveTaskIds(group: 'p:prof-1'), isEmpty);
    expect(events, isEmpty);
  });

  test('by default pause cancels and resume asks for a restart, as the '
      'Resume Rule says', () async {
    await downloader.enqueue(_request('aa11'));

    expect(await downloader.pause('aa11'), isFalse);
    expect(await downloader.resume('aa11'), isFalse);
    await settle();

    expect(events, [
      const DownloaderFailed(
        taskId: 'aa11',
        group: 'p:prof-1',
        kind: DownloaderFailureKind.cancelled,
      ),
    ]);
    expect(await downloader.liveTaskIds(group: 'p:prof-1'), isEmpty);
  });

  test('with pauseResumable on, pause and resume keep the task', () async {
    downloader.pauseResumable = true;
    await downloader.enqueue(_request('aa11'));

    expect(await downloader.pause('aa11'), isTrue);
    expect(await downloader.resume('aa11'), isTrue);
    await settle();

    expect(events, [const DownloaderPaused(taskId: 'aa11', group: 'p:prof-1')]);
    expect(await downloader.liveTaskIds(group: 'p:prof-1'), {'aa11'});
  });

  test('cancel with deletePartial deletes the .part file', () async {
    await downloader.enqueue(_request('aa11'));
    final path = downloader.pathOf('aa11');
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3]);

    await downloader.cancel('aa11', deletePartial: true);

    expect(File(path).existsSync(), isFalse);
    expect(downloader.cancelled, ['aa11']);
  });
}
