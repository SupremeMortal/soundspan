// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spike_s5/harness.dart';

/// The host's slow server as the Android emulator reaches it.
const _host = String.fromEnvironment(
  'S5_HOST',
  defaultValue: 'http://10.0.2.2:8765',
);

/// The one task of the harness; the driver checks it keeps this id.
const _taskId = 's5-q4';

/// Spike S5 harness app, Android part (question 4). On its first start it
/// enqueues one slow download as doc 07's `DownloadTask` sketch does; on
/// every start it registers its listener, then calls
/// `FileDownloader().start()` and `resumeFromBackground()`. Every event is
/// one logcat line with tag `SPIKE_S5`; `run.sh` kills and relaunches the
/// process and reads those lines.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Center(child: Text('S5', textDirection: TextDirection.ltr)));
  _log('event=launch');
  final dir = await getApplicationSupportDirectory();
  final marker = File('${dir.path}/s5-enqueued');
  var lastTenth = -1;
  FileDownloader().updates.listen((update) async {
    switch (update) {
      case TaskProgressUpdate(:final progress):
        final tenth = (progress * 10).floor();
        if (tenth != lastTenth) {
          lastTenth = tenth;
          _log(
            'event=progress taskId=${update.task.taskId} '
            'progress=${progress.toStringAsFixed(2)}',
          );
        }
      case TaskStatusUpdate(:final status):
        _log(
          'event=status taskId=${update.task.taskId} status=${status.name} '
          'exception=${update.exception?.description.replaceAll(' ', '_')}',
        );
        if (status == TaskStatus.complete) await _verify(update.task);
    }
  });
  await FileDownloader().start();
  await FileDownloader().resumeFromBackground();
  final record = await FileDownloader().database.recordForId(_taskId);
  final native = await FileDownloader().allTasks(allGroups: true);
  _log(
    'event=started recordStatus=${record?.status.name} '
    'nativeTasks=${native.map((t) => t.taskId).join(',')}',
  );
  if (!marker.existsSync()) {
    final task = DownloadTask(
      taskId: _taskId,
      url: '$_host/ranged?seconds=40',
      headers: const {'Authorization': 'Bearer s5-spike'},
      baseDirectory: BaseDirectory.applicationSupport,
      directory: 's5',
      filename: '$_taskId.part',
      updates: Updates.statusAndProgress,
      retries: 0,
      allowPause: true,
      metaData: 'spike-s5',
    );
    final ok = await FileDownloader().enqueue(task);
    marker.createSync(recursive: true);
    _log('event=enqueued taskId=$_taskId ok=$ok');
  }
  // rescheduleKilledTasks runs 5 s after start(); log what it found.
  Timer(const Duration(seconds: 8), () async {
    final again = await FileDownloader().database.recordForId(_taskId);
    final live = await FileDownloader().allTasks(allGroups: true);
    _log(
      'event=after-reschedule recordStatus=${again?.status.name} '
      'nativeTasks=${live.map((t) => t.taskId).join(',')}',
    );
  });
}

/// Logs the downloaded file's SHA-256 next to the reference bytes'.
Future<void> _verify(Task task) async {
  try {
    final bytes = await File(await task.filePath()).readAsBytes();
    final reference = await fetchReference(Uri.parse('$_host/full?seconds=0'));
    _log(
      'event=complete taskId=${task.taskId} bytes=${bytes.length} '
      'sha256=${sha256Hex(bytes)} referenceSha256=${sha256Hex(reference)}',
    );
  } on Object catch (error) {
    _log('event=verify-error taskId=${task.taskId} error=$error');
  }
}

/// Writes one logcat line with tag `SPIKE_S5` through the device's `log`
/// command, so the driver can filter by tag.
void _log(String message) {
  final line =
      'pid=$pid wallMs=${DateTime.now().millisecondsSinceEpoch} $message';
  unawaited(
    Process.run('/system/bin/log', [
      '-t',
      'SPIKE_S5',
      line,
    ]).then((_) {}, onError: (Object _) => debugPrint('SPIKE_S5 $line')),
  );
}
