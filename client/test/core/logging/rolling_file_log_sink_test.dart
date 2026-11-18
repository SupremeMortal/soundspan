// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/log_sink/log_sink.dart' as seam;
import 'package:soundspan/platform/log_sink/log_sink_io.dart';

import 'recording_sink.dart';

const int _megabyte = 1024 * 1024;

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('soundspan_logs_');
  });

  tearDown(() async {
    AppLogging.reset();
    await dir.delete(recursive: true);
  });

  File logFile(int n) => File(p.join(dir.path, 'app.$n.log'));

  List<String> logFiles() =>
      dir.listSync().map((f) => p.basename(f.path)).toList()..sort();

  // An entry whose JSON line is a little over 100 KB.
  LogEntry big(int n) => entryWith(message: '$n:${'x' * (100 * 1024)}');

  test('writes one JSON line per entry to app.0.log', () async {
    final sink = RollingFileLogSink(dir.path)
      ..write(entryWith(message: 'one', fields: {'bytes': 3}))
      ..write(entryWith(message: 'two', error: 'e'));
    await sink.close();

    final lines = logFile(0).readAsLinesSync();
    expect(lines, hasLength(2));
    final first = jsonDecode(lines[0]) as Map<String, Object?>;
    expect(first['message'], 'one');
    expect(first['level'], 'info');
    expect(first['scope'], 'Test');
    expect(first['fields'], {'bytes': 3});
    expect(first['time'], '2026-01-01T00:00:00.000Z');
    expect((jsonDecode(lines[1]) as Map<String, Object?>)['error'], 'e');
  });

  test('exceeding 1 MB rotates to app.1.log', () async {
    final sink = RollingFileLogSink(dir.path);
    for (var i = 0; i < 11; i++) {
      sink.write(big(i));
    }
    await sink.close();

    expect(logFiles(), ['app.0.log', 'app.1.log']);
    expect(logFile(1).lengthSync(), lessThanOrEqualTo(_megabyte));
    expect(logFile(1).readAsStringSync(), startsWith('{'));
    expect(logFile(1).readAsStringSync(), contains('"0:x'));
    expect(logFile(0).readAsStringSync(), contains('"10:x'));
  });

  test('keeps exactly five files and drops the oldest content', () async {
    final sink = RollingFileLogSink(dir.path);
    for (var i = 0; i < 70; i++) {
      sink.write(big(i));
    }
    await sink.close();

    expect(logFiles(), [
      'app.0.log',
      'app.1.log',
      'app.2.log',
      'app.3.log',
      'app.4.log',
    ]);
    final all = [for (var n = 0; n < 5; n++) logFile(n).readAsStringSync()];
    expect(all.any((s) => s.contains('"0:x')), isFalse);
    expect(all.first, contains('"69:x'));
    for (var n = 0; n < 5; n++) {
      expect(logFile(n).lengthSync(), lessThanOrEqualTo(_megabyte));
    }
  });

  test('close flushes pending writes', () async {
    final sink = RollingFileLogSink(dir.path);
    for (var i = 0; i < 50; i++) {
      sink.write(entryWith(message: 'line $i'));
    }
    await sink.close();
    expect(logFile(0).readAsLinesSync(), hasLength(50));
  });

  test('continues an existing app.0.log', () async {
    final first = RollingFileLogSink(dir.path)..write(entryWith(message: 'a'));
    await first.close();
    final second = RollingFileLogSink(dir.path)..write(entryWith(message: 'b'));
    await second.close();
    expect(logFile(0).readAsLinesSync(), hasLength(2));
  });

  test('no file contains a secret logged through AppLogger', () async {
    final sink = seam.createPersistentLogSink(directory: dir.path);
    AppLogging.configure(sinks: [sink], releaseMode: true);
    AppLogger.scope('Auth').info('GET /api/stream?token=tok-raw-1', {
      'password': 'pw-raw-2',
      'nested': {'refreshToken': 'rt-raw-3'},
    });
    await sink.close();

    final text = logFile(0).readAsStringSync();
    expect(text, contains('<redacted>'));
    for (final secret in ['tok-raw-1', 'pw-raw-2', 'rt-raw-3']) {
      expect(text, isNot(contains(secret)));
    }
  });

  test('createPersistentLogSink requires a directory', () {
    expect(seam.createPersistentLogSink, throwsArgumentError);
  });
}
