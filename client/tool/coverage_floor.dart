// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

/// Line-coverage floors in percent, read from `tool/coverage_floor.json`.
class CoverageFloors {
  /// Creates the floors for each group.
  const new({required this.core, required this.api, required this.overall});

  /// Reads the floors from the JSON object in [source].
  factory fromJson(String source) {
    final json = jsonDecode(source) as Map<String, Object?>;
    return CoverageFloors(
      core: json['core']! as num,
      api: json['api']! as num,
      overall: json['overall']! as num,
    );
  }

  /// Floor for `lib/core/**`.
  final num core;

  /// Floor for `packages/soundspan_api/lib/**`.
  final num api;

  /// Floor for both reports merged.
  final num overall;
}

/// The outcome of [evaluateCoverage].
class CoverageReport {
  /// Creates a report.
  const new({required this.ok, required this.lines});

  /// Whether every floor is met and the exclusion list is valid.
  final bool ok;

  /// One line per group, then exclusion errors and ratchet notices.
  final List<String> lines;
}

const _apiPrefix = 'packages/soundspan_api/';

/// Checks the app and API lcov reports against [floors].
///
/// [exclusions] is the text of `tool/coverage_exclusions.txt` and
/// [clientFiles] the Dart files under `client/`, relative to it, that its
/// globs are matched against.
CoverageReport evaluateCoverage({
  required String appLcov,
  required String apiLcov,
  required CoverageFloors floors,
  required String exclusions,
  required Iterable<String> clientFiles,
}) {
  final lines = <String>[];
  var ok = true;

  final patterns = <RegExp>[];
  for (final raw in const LineSplitter().convert(exclusions)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final hash = line.indexOf(' #');
    final glob = (hash < 0 ? line : line.substring(0, hash)).trim();
    final reason = hash < 0 ? '' : line.substring(hash + 2).trim();
    if (reason.isEmpty) {
      lines.add('FAIL exclusion "$glob" has no reason');
      ok = false;
      continue;
    }
    final pattern = _globToRegExp(glob);
    if (!clientFiles.any(pattern.hasMatch)) {
      lines.add('FAIL exclusion "$glob" matches no file');
      ok = false;
    }
    patterns.add(pattern);
  }

  bool counted(String path) =>
      !path.endsWith('.g.dart') &&
      !path.endsWith('.freezed.dart') &&
      !path.split('/').contains('generated') &&
      !patterns.any((p) => p.hasMatch(path));

  final files = <String, _Lines>{
    for (final entry in _parseLcov(appLcov).entries)
      _appPath(entry.key): entry.value,
    for (final entry in _parseLcov(apiLcov).entries)
      _apiPath(entry.key): entry.value,
  }..removeWhere((path, _) => !counted(path));

  _Lines sum(bool Function(String) include) => files.entries
      .where((e) => include(e.key))
      .fold(const _Lines(0, 0), (total, e) => total + e.value);

  final groups = <(String, num, _Lines)>[
    ('core', floors.core, sum((p) => p.startsWith('lib/core/'))),
    ('api', floors.api, sum((p) => p.startsWith('${_apiPrefix}lib/'))),
    ('overall', floors.overall, sum((_) => true)),
  ];
  final notices = <String>[];
  final groupLines = <String>[];
  for (final (name, floor, counts) in groups) {
    if (counts.found == 0) {
      groupLines.add('ok   $name: no instrumented lines (floor $floor %)');
      continue;
    }
    final percent = counts.hit * 100 / counts.found;
    final rounded = percent.toStringAsFixed(1);
    final passed = percent >= floor;
    ok = ok && passed;
    groupLines.add(
      '${passed ? 'ok  ' : 'FAIL'} $name: $rounded % of ${counts.found} '
      'lines (floor $floor %)',
    );
    if (percent >= floor + 5) {
      notices.add(
        'notice: $name is $rounded %, 5 or more points over its floor of '
        '$floor %; commit a floor of ${percent.floor()}',
      );
    }
  }
  return CoverageReport(ok: ok, lines: [...groupLines, ...lines, ...notices]);
}

class _Lines {
  const new(this.found, this.hit);

  final int found;
  final int hit;

  _Lines operator +(_Lines other) =>
      _Lines(found + other.found, hit + other.hit);
}

Map<String, _Lines> _parseLcov(String lcov) {
  final result = <String, _Lines>{};
  String? file;
  final hits = <int, bool>{};
  for (final line in const LineSplitter().convert(lcov)) {
    if (line.startsWith('SF:')) {
      file = line.substring(3).replaceAll(r'\', '/');
      hits.clear();
    } else if (line.startsWith('DA:') && file != null) {
      final parts = line.substring(3).split(',');
      final number = int.parse(parts[0]);
      hits[number] = (hits[number] ?? false) || int.parse(parts[1]) > 0;
    } else if (line == 'end_of_record' && file != null) {
      final previous = result[file] ?? const _Lines(0, 0);
      result[file] =
          previous + _Lines(hits.length, hits.values.where((h) => h).length);
      file = null;
    }
  }
  return result;
}

String _appPath(String path) {
  final index = path.lastIndexOf('/client/lib/');
  return index < 0 ? path : path.substring(index + '/client/'.length);
}

String _apiPath(String path) {
  final index = path.lastIndexOf('/$_apiPrefix');
  if (index >= 0) return path.substring(index + 1);
  return path.startsWith('lib/') ? '$_apiPrefix$path' : path;
}

RegExp _globToRegExp(String glob) {
  final buffer = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final char = glob[i];
    if (char == '*' && i + 1 < glob.length && glob[i + 1] == '*') {
      buffer.write('.*');
      i++;
      if (i + 1 < glob.length && glob[i + 1] == '/') i++;
    } else if (char == '*') {
      buffer.write('[^/]*');
    } else if (char == '?') {
      buffer.write('[^/]');
    } else {
      buffer.write(RegExp.escape(char));
    }
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}

List<String> _dartFiles(Directory client) {
  final root = client.absolute.path;
  return [
    for (final entity in client.listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.contains('/.dart_tool/') &&
          !entity.path.contains('/build/'))
        entity.absolute.path.substring(root.length + 1).replaceAll(r'\', '/'),
  ];
}

String _readOrEmpty(String path) {
  final file = File(path);
  return file.existsSync() ? file.readAsStringSync() : '';
}

/// Checks `coverage/lcov.info` and the API package's lcov report against
/// `tool/coverage_floor.json`. Run from `client/`; exits 1 on a violation.
void main() {
  final client = Directory.current;
  final report = evaluateCoverage(
    appLcov: _readOrEmpty('coverage/lcov.info'),
    apiLcov: _readOrEmpty('packages/soundspan_api/coverage/lcov.info'),
    floors: CoverageFloors.fromJson(
      File('tool/coverage_floor.json').readAsStringSync(),
    ),
    exclusions: _readOrEmpty('tool/coverage_exclusions.txt'),
    clientFiles: _dartFiles(client),
  );
  report.lines.forEach(stdout.writeln);
  if (!report.ok) exitCode = 1;
}
