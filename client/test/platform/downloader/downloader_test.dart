// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/downloader/downloader.dart';
import 'package:soundspan/platform/downloader/downloader_io.dart';
import 'package:soundspan/platform/downloader/downloader_web.dart';

DownloadTask _task(String id) => DownloadTask(
  taskId: id,
  url: 'https://music.example.com/api/offline/download/x',
  filename: '$id.part',
  group: 'p:prof-1',
);

Future<List<DownloaderEvent>> _events(TaskUpdate update) =>
    BackgroundDownloader.eventsOf(update).toList();

void main() {
  test('the web downloader throws UnsupportedError from every method', () {
    const downloader = UnsupportedDownloader();
    expect(downloader.start, throwsUnsupportedError);
    expect(
      () => downloader.enqueue(
        DownloadRequest(
          taskId: 't',
          url: Uri.parse('https://x/api/a'),
          headers: const {},
          profileId: 'p',
          relativeDirectory: 'media/aa',
          filename: 't.part',
          requiresWifi: false,
          highPriority: false,
          metaData: 't:a',
        ),
      ),
      throwsUnsupportedError,
    );
    expect(() => downloader.pause('t'), throwsUnsupportedError);
    expect(() => downloader.resume('t'), throwsUnsupportedError);
    expect(() => downloader.cancel('t'), throwsUnsupportedError);
    expect(() => downloader.liveTaskIds(group: 'p:p'), throwsUnsupportedError);
    expect(() => downloader.events, throwsUnsupportedError);
  });

  test('downloaderGroup names the profile group', () {
    expect(downloaderGroup('prof-1'), 'p:prof-1');
  });

  test('isStrongEtag rejects weak and missing tags', () {
    expect(isStrongEtag('"abc"'), isTrue);
    expect(isStrongEtag('W/"abc"'), isFalse);
    expect(isStrongEtag(null), isFalse);
    expect(isStrongEtag(''), isFalse);
  });

  group('plugin updates', () {
    test('progress becomes received and expected bytes', () async {
      expect(await _events(TaskProgressUpdate(_task('p1'), 0.25, 400)), [
        const DownloaderProgress(
          taskId: 'p1',
          group: 'p:prof-1',
          receivedBytes: 100,
          expectedBytes: 400,
        ),
      ]);
    });

    test('an unknown size reports no expected bytes, and negative progress '
        'is left to the status update', () async {
      expect(await _events(TaskProgressUpdate(_task('p2'), 0.5)), [
        const DownloaderProgress(
          taskId: 'p2',
          group: 'p:prof-1',
          receivedBytes: 0,
        ),
      ]);
      expect(await _events(TaskProgressUpdate(_task('p2'), -1)), isEmpty);
    });

    test('the first response headers are reported once', () async {
      final update = TaskStatusUpdate(
        _task('h1'),
        TaskStatus.failed,
        TaskHttpException('Unauthorized', 401),
        null,
        {
          'ETag': 'W/"weak"',
          'Content-Type': 'text/plain',
          'Content-Length': '12',
        },
        401,
      );

      expect(await _events(update), [
        const DownloaderResponseInfo(
          taskId: 'h1',
          group: 'p:prof-1',
          etag: 'W/"weak"',
          isStrongEtag: false,
          contentType: 'text/plain',
          contentLength: 12,
        ),
        const DownloaderFailed(
          taskId: 'h1',
          group: 'p:prof-1',
          kind: DownloaderFailureKind.http,
          httpStatus: 401,
        ),
      ]);
      expect(
        await _events(update),
        hasLength(1),
        reason: 'the headers were already reported',
      );
    });

    test('statuses map to events', () async {
      Future<List<DownloaderEvent>> status(
        TaskStatus status, [
        TaskException? exception,
      ]) => _events(TaskStatusUpdate(_task('s1'), status, exception));

      expect(await status(TaskStatus.notFound), [
        const DownloaderFailed(
          taskId: 's1',
          group: 'p:prof-1',
          kind: DownloaderFailureKind.http,
          httpStatus: 404,
        ),
      ]);
      expect(await status(TaskStatus.canceled), [
        const DownloaderFailed(
          taskId: 's1',
          group: 'p:prof-1',
          kind: DownloaderFailureKind.cancelled,
        ),
      ]);
      expect(await status(TaskStatus.paused), [
        const DownloaderPaused(taskId: 's1', group: 'p:prof-1'),
      ]);
      expect(await status(TaskStatus.running), isEmpty);
      expect(await status(TaskStatus.enqueued), isEmpty);
      expect(await status(TaskStatus.waitingToRetry), isEmpty);

      Future<DownloaderFailureKind> kind(TaskException exception) async =>
          ((await status(TaskStatus.failed, exception)).single
                  as DownloaderFailed)
              .kind;
      expect(
        await kind(TaskConnectionException('reset')),
        DownloaderFailureKind.network,
      );
      expect(
        await kind(TaskFileSystemException('Insufficient space to store file')),
        DownloaderFailureKind.noSpace,
      );
      expect(
        await kind(TaskFileSystemException('cannot move')),
        DownloaderFailureKind.fileSystem,
      );
      expect(
        await kind(TaskResumeException('etag')),
        DownloaderFailureKind.unknown,
      );
    });
  });
}
