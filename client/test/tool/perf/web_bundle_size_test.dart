// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/perf/web_bundle_size.dart';

/// Writes [bytes] incompressible bytes to [path] under [dir].
void put(Directory dir, String path, int bytes) {
  final random = Random(path.hashCode);
  File('${dir.path}/$path')
    ..createSync(recursive: true)
    ..writeAsBytesSync([for (var i = 0; i < bytes; i++) random.nextInt(256)]);
}

/// A web build of the initial-load set with [fonts] in `FontManifest.json`.
void bundle(
  Directory dir, {
  int mainBytes = 1000,
  List<String> fonts = const ['fonts/MaterialIcons-Regular.otf'],
}) {
  for (final path in [
    'index.html',
    'flutter_bootstrap.js',
    canvasKitJs,
    canvasKitWasm,
    'assets/AssetManifest.bin.json',
    'sqlite3.wasm',
    'drift_worker.js',
  ]) {
    put(dir, path, 100);
  }
  put(dir, 'main.dart.js', mainBytes);
  File('${dir.path}/assets/FontManifest.json').writeAsStringSync(
    jsonEncode([
      {
        'family': 'Fonts',
        'fonts': [
          for (final font in fonts) {'asset': font},
        ],
      },
    ]),
  );
  for (final font in fonts) {
    put(dir, 'assets/${Uri.decodeFull(font)}', 100);
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('web_bundle'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a set under the limit passes and lists every file', () {
    bundle(dir);
    final report = measureWebBundle(dir, limitBytes: 1 << 20);
    expect(report.ok, isTrue);
    expect(report.errors, isEmpty);
    expect(
      report.files.map((file) => file.path),
      containsAll([
        'index.html',
        'main.dart.js',
        canvasKitWasm,
        'assets/FontManifest.json',
        'assets/fonts/MaterialIcons-Regular.otf',
        'sqlite3.wasm',
        'drift_worker.js',
      ]),
    );
    expect(
      report.totalGzipBytes,
      report.files.fold<int>(0, (sum, file) => sum + file.gzipBytes),
    );
    expect(report.markdown(), contains('| `main.dart.js` |'));
  });

  test('a set over the limit fails', () {
    bundle(dir, mainBytes: 20000);
    final report = measureWebBundle(dir, limitBytes: 10000);
    expect(report.ok, isFalse);
    expect(report.markdown(), contains('10000'));
  });

  test('the default limit is 5 MB', () {
    expect(defaultWebBundleLimitBytes, 5242880);
  });

  test('a missing main.dart.js fails naming it', () {
    bundle(dir);
    File('${dir.path}/main.dart.js').deleteSync();
    final report = measureWebBundle(dir, limitBytes: 1 << 20);
    expect(report.ok, isFalse);
    expect(report.errors.single, contains('main.dart.js'));
  });

  test('deferred parts are ignored', () {
    bundle(dir);
    final before = measureWebBundle(dir, limitBytes: 1 << 20).totalGzipBytes;
    put(dir, 'main.dart.js_1.part.js', 50000);
    put(dir, 'main.dart.js_12.part.js', 50000);
    final report = measureWebBundle(dir, limitBytes: 1 << 20);
    expect(report.totalGzipBytes, before);
    expect(
      report.files.map((f) => f.path),
      isNot(contains(endsWith('.part.js'))),
    );
  });

  test('fonts are taken from FontManifest.json', () {
    bundle(
      dir,
      fonts: const [
        'fonts/A.ttf',
        'packages/cupertino_icons/assets/Cupertino%20Icons.ttf',
      ],
    );
    put(dir, 'assets/fonts/Unlisted.ttf', 50000);
    final report = measureWebBundle(dir, limitBytes: 1 << 20);
    final paths = report.files.map((f) => f.path);
    expect(paths, contains('assets/fonts/A.ttf'));
    expect(
      paths,
      contains('assets/packages/cupertino_icons/assets/Cupertino Icons.ttf'),
    );
    expect(paths, isNot(contains('assets/fonts/Unlisted.ttf')));
  });

  test('a font listed but missing fails naming it', () {
    bundle(dir, fonts: const ['fonts/A.ttf']);
    File('${dir.path}/assets/fonts/A.ttf').deleteSync();
    final report = measureWebBundle(dir, limitBytes: 1 << 20);
    expect(report.ok, isFalse);
    expect(report.errors.single, contains('assets/fonts/A.ttf'));
  });

  test('the command exits 1 over the budget and writes the job summary', () {
    bundle(dir, mainBytes: 20000);
    final summary = File('${dir.path}/summary.md');
    final code = runWebBundleSize(
      ['--dir', dir.path, '--limit', '10000'],
      out: (_) {},
      environment: {'GITHUB_STEP_SUMMARY': summary.path},
    );
    expect(code, 1);
    expect(summary.readAsStringSync(), contains('main.dart.js'));
  });

  test('the command reads the limit from budgets.json by default', () {
    bundle(dir);
    expect(
      runWebBundleSize(['--dir', dir.path], out: (_) {}, environment: {}),
      0,
    );
  });
}
