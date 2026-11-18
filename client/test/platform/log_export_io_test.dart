// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/log_export/log_export.dart';
import 'package:soundspan/platform/log_export/log_export_io.dart';

import '../helpers/fake_clock.dart';

void main() {
  late Directory root;
  late Directory logs;
  late Directory temp;
  late FakeClock clock;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('soundspan_log_export_');
    logs = Directory(p.join(root.path, 'logs'))..createSync();
    temp = Directory(p.join(root.path, 'tmp'))..createSync();
    clock = FakeClock(start: DateTime.utc(2026, 3, 4, 5, 6, 7));
  });

  tearDown(() => root.delete(recursive: true));

  void writeLogs() {
    File(p.join(logs.path, 'app.0.log')).writeAsStringSync('{"m":"new"}\n');
    File(p.join(logs.path, 'app.1.log')).writeAsStringSync('{"m":"old"}\n');
    File(p.join(logs.path, 'other.txt')).writeAsStringSync('not a log');
  }

  List<String> tempFiles() => temp.listSync().map((f) => f.path).toList();

  IoLogExporter exporter({
    bool useShareSheet = false,
    ShareLogBundle? share,
    PickSavePath? pickSavePath,
    Future<void> Function()? flush,
  }) => IoLogExporter(
    logsDirectory: logs.path,
    temporaryDirectory: () async => temp.path,
    clock: clock,
    useShareSheet: useShareSheet,
    share: share ?? (_) async => fail('share sheet opened'),
    pickSavePath: pickSavePath ?? (_) async => fail('save dialog opened'),
    flush: flush ?? () async {},
  );

  test(
    'the share sheet gets a zip of every log file, named by the clock',
    () async {
      writeLogs();
      String? sharedPath;
      Archive? shared;
      var flushed = false;

      final result = await exporter(
        useShareSheet: true,
        flush: () async => flushed = true,
        share: (path) async {
          sharedPath = path;
          shared = ZipDecoder().decodeBytes(File(path).readAsBytesSync());
          return true;
        },
      ).export();

      expect(result, LogExportResult.done);
      expect(flushed, isTrue);
      expect(p.basename(sharedPath!), 'soundspan-logs-20260304-050607.zip');
      expect(shared!.files.map((f) => f.name), ['app.0.log', 'app.1.log']);
      expect(utf8.decode(shared!.files.first.content), '{"m":"new"}\n');
      expect(tempFiles(), isEmpty);
    },
  );

  test('a dismissed share sheet is cancelled', () async {
    writeLogs();
    final result = await exporter(
      useShareSheet: true,
      share: (_) async => false,
    ).export();
    expect(result, LogExportResult.cancelled);
    expect(tempFiles(), isEmpty);
  });

  test('no log files is nothingToExport and opens no dialog', () async {
    File(p.join(logs.path, 'other.txt')).writeAsStringSync('not a log');
    expect(await exporter().export(), LogExportResult.nothingToExport);
    expect(
      await exporter(useShareSheet: true).export(),
      LogExportResult.nothingToExport,
    );
    expect(tempFiles(), isEmpty);
  });

  test('a missing logs directory is nothingToExport', () async {
    logs.deleteSync();
    expect(await exporter().export(), LogExportResult.nothingToExport);
  });

  test('a dismissed save dialog is cancelled', () async {
    writeLogs();
    String? suggested;
    final result = await exporter(
      pickSavePath: (name) async {
        suggested = name;
        return null;
      },
    ).export();
    expect(result, LogExportResult.cancelled);
    expect(suggested, 'soundspan-logs-20260304-050607.zip');
    expect(tempFiles(), isEmpty);
  });

  test('a chosen path receives a copy of the zip', () async {
    writeLogs();
    final target = p.join(root.path, 'saved.zip');
    final result = await exporter(pickSavePath: (_) async => target).export();
    expect(result, LogExportResult.done);
    final archive = ZipDecoder().decodeBytes(File(target).readAsBytesSync());
    expect(archive.files.map((f) => f.name), ['app.0.log', 'app.1.log']);
    expect(tempFiles(), isEmpty);
  });

  test('a share step that throws is failed', () async {
    writeLogs();
    final result = await exporter(
      useShareSheet: true,
      share: (_) async => throw StateError('no share sheet'),
    ).export();
    expect(result, LogExportResult.failed);
    expect(tempFiles(), isEmpty);
  });

  test('a copy step that throws is failed', () async {
    writeLogs();
    final target = p.join(root.path, 'missing', 'dir', 'saved.zip');
    final result = await exporter(pickSavePath: (_) async => target).export();
    expect(result, LogExportResult.failed);
    expect(tempFiles(), isEmpty);
  });
}
