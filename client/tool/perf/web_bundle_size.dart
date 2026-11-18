// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'budgets.dart';

/// The CanvasKit script the default renderer loads in Chrome.
const String canvasKitJs = 'canvaskit/chromium/canvaskit.js';

/// The CanvasKit module the default renderer loads in Chrome.
const String canvasKitWasm = 'canvaskit/chromium/canvaskit.wasm';

/// The initial-load budget of Risk Register K8: 5 MB compressed.
const int defaultWebBundleLimitBytes = 5 * 1024 * 1024;

/// The files of the initial load besides the fonts of `FontManifest.json`.
/// Deferred parts (`main.dart.js_*.part.js`) are never in it.
const List<String> initialLoadFiles = [
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  canvasKitJs,
  canvasKitWasm,
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'sqlite3.wasm',
  'drift_worker.js',
];

/// One file of the initial load.
class BundleFile {
  /// The file at [path] of [rawBytes], [gzipBytes] once compressed.
  const new({
    required this.path,
    required this.rawBytes,
    required this.gzipBytes,
  });

  /// The path relative to the build directory.
  final String path;

  /// The size on disk.
  final int rawBytes;

  /// The size compressed with gzip at level 9.
  final int gzipBytes;
}

/// The outcome of [measureWebBundle].
class WebBundleReport {
  /// A report of [files] against [limitBytes], with [errors].
  const new({
    required this.files,
    required this.limitBytes,
    required this.errors,
  });

  /// The files of the initial load that exist.
  final List<BundleFile> files;

  /// The budget, gzip-compressed bytes.
  final int limitBytes;

  /// The files of the set that are missing, and an unreadable manifest.
  final List<String> errors;

  /// The gzip-compressed size of [files].
  int get totalGzipBytes => files.fold(0, (sum, file) => sum + file.gzipBytes);

  /// Whether every file exists and the total is within the budget.
  bool get ok => errors.isEmpty && totalGzipBytes <= limitBytes;

  /// The report as Markdown: a table per file, the total and the budget.
  String markdown() {
    final buffer = StringBuffer()
      ..writeln('### Web bundle size (initial load)')
      ..writeln()
      ..writeln('| File | Raw (bytes) | Gzip (bytes) |')
      ..writeln('|---|---:|---:|');
    for (final file in [
      ...files,
    ]..sort((a, b) => b.gzipBytes.compareTo(a.gzipBytes))) {
      buffer.writeln(
        '| `${file.path}` | ${file.rawBytes} | ${file.gzipBytes} |',
      );
    }
    buffer
      ..writeln('| **Total** | | **$totalGzipBytes** |')
      ..writeln()
      ..writeln(
        '${ok ? 'Within' : '**Over**'} the budget of $limitBytes bytes '
        '(${(totalGzipBytes / 1024).round()} KiB of '
        '${(limitBytes / 1024).round()} KiB).',
      );
    for (final error in errors) {
      buffer.writeln('- **Error:** $error');
    }
    return buffer.toString();
  }
}

/// Measures the gzip-compressed initial load of the web build in [dir]
/// against [limitBytes]: [initialLoadFiles] and every font listed in
/// `assets/FontManifest.json`. A missing file is an error, not zero bytes.
WebBundleReport measureWebBundle(Directory dir, {required int limitBytes}) {
  final files = <BundleFile>[];
  final errors = <String>[];
  final paths = [...initialLoadFiles];

  final manifest = File('${dir.path}/assets/FontManifest.json');
  if (manifest.existsSync()) {
    try {
      final families = jsonDecode(manifest.readAsStringSync()) as List<Object?>;
      for (final family in families.cast<Map<String, Object?>>()) {
        for (final font
            in (family['fonts']! as List<Object?>)
                .cast<Map<String, Object?>>()) {
          final asset = Uri.decodeFull(font['asset']! as String);
          paths.add('assets/$asset');
        }
      }
    } on Object catch (error) {
      errors.add('assets/FontManifest.json cannot be read: $error');
    }
  }

  final gzip = GZipCodec(level: 9);
  for (final path in paths.toSet()) {
    final file = File('${dir.path}/$path');
    if (!file.existsSync()) {
      errors.add('$path is missing');
      continue;
    }
    final bytes = file.readAsBytesSync();
    files.add(
      BundleFile(
        path: path,
        rawBytes: bytes.length,
        gzipBytes: gzip.encode(bytes).length,
      ),
    );
  }
  return WebBundleReport(files: files, limitBytes: limitBytes, errors: errors);
}

/// `--dir <build/web>` and an optional `--limit <bytes>` (by default
/// `web_initial_load_gzip_bytes` of `tool/perf/budgets.json`). Prints the
/// report and appends it to the file named by `GITHUB_STEP_SUMMARY` in
/// [environment]. Returns 0 within the budget, 1 over it or with a file
/// missing, 2 on a usage error.
int runWebBundleSize(
  List<String> args, {
  required void Function(String) out,
  Map<String, String>? environment,
}) {
  String? dir;
  int? limit;
  for (var i = 0; i < args.length; i++) {
    final value = i + 1 < args.length ? args[i + 1] : null;
    switch (args[i]) {
      case '--dir' when value != null:
        dir = value;
        i++;
      case '--limit' when value != null && int.tryParse(value) != null:
        limit = int.parse(value);
        i++;
      default:
        dir = null;
        i = args.length;
    }
  }
  if (dir == null || !Directory(dir).existsSync()) {
    out(
      'usage: dart run tool/perf/web_bundle_size.dart --dir <build/web> '
      '[--limit <bytes>]',
    );
    return 2;
  }
  final report = measureWebBundle(
    Directory(dir),
    limitBytes: limit ?? PerfBudgets.load().webInitialLoadGzipBytes,
  );
  final markdown = report.markdown();
  out(markdown);
  final summary = (environment ?? Platform.environment)['GITHUB_STEP_SUMMARY'];
  if (summary != null && summary.isNotEmpty) {
    File(summary).writeAsStringSync('$markdown\n', mode: FileMode.append);
  }
  return report.ok ? 0 : 1;
}

/// Checks the web build's initial load; run from `client/`.
void main(List<String> args) {
  exitCode = runWebBundleSize(args, out: stdout.writeln);
}
