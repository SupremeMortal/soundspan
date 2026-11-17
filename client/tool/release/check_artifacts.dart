// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// The name of the checksum file written beside the release artifacts.
const sumsFileName = 'SHA256SUMS';

/// The macOS artifacts, with `{version}` standing for the version: the
/// zipped app and the disk image holding it.
const List<String> macosArtifactNameTemplates = [
  'soundspan-{version}-macos-universal-unsigned.zip',
  'soundspan-{version}-macos-universal-unsigned.dmg',
];

/// Every release artifact, with `{version}` standing for the version.
///
/// This is the one list of expected file names; packaging adds to it.
const List<String> artifactNameTemplates = [
  'soundspan-{version}-android-unsigned.apk',
  'soundspan-{version}-linux-x64-unsigned.tar.gz',
  'soundspan-{version}-windows-x64-unsigned.zip',
  'soundspan-{version}-windows-x64-unsigned.msix',
  'soundspan-{version}-windows-x64-unsigned-setup.exe',
  ...macosArtifactNameTemplates,
  'soundspan-{version}-web.tar.gz',
  'soundspan-{version}-web-image.tar.gz',
];

/// The expected artifact file names for [version].
///
/// With [macos] false the macOS artifacts are left out, for a build that
/// skipped the macOS job.
List<String> expectedArtifactNames(String version, {bool macos = true}) => [
  for (final template in artifactNameTemplates)
    if (macos || !macosArtifactNameTemplates.contains(template))
      template.replaceAll('{version}', version),
];

/// The outcome of [checkArtifacts].
class ArtifactCheck {
  /// Creates a result.
  const new({required this.ok, required this.lines});

  /// Whether the directory holds exactly the expected, non-empty files and,
  /// in verify mode, they match `SHA256SUMS`.
  final bool ok;

  /// One line per problem, or a summary when [ok].
  final List<String> lines;
}

/// Checks the release artifacts for [version] in [dir].
///
/// Fails when an expected file is missing, an unexpected entry is present,
/// or a file is empty. With [writeSums] it then writes `SHA256SUMS` in
/// `sha256sum` format, sorted by file name; without it, it verifies an
/// existing `SHA256SUMS` against the files. With [macos] false the macOS
/// artifacts are not expected (see [expectedArtifactNames]).
ArtifactCheck checkArtifacts({
  required Directory dir,
  required String version,
  required bool writeSums,
  bool macos = true,
}) {
  final problems = <String>[];
  final expected = expectedArtifactNames(version, macos: macos).toSet();
  final present = <String>{};

  for (final entity in dir.listSync()) {
    final name = p.basename(entity.path);
    if (name == sumsFileName) continue;
    if (!expected.contains(name) || entity is! File) {
      problems.add('unexpected: $name');
      continue;
    }
    present.add(name);
    if (entity.lengthSync() == 0) problems.add('empty: $name');
  }
  for (final name in expected.difference(present)) {
    problems.add('missing: $name');
  }
  if (problems.isNotEmpty) {
    return ArtifactCheck(ok: false, lines: problems..sort());
  }

  final names = present.toList()..sort();
  final digests = {
    for (final name in names)
      name: sha256
          .convert(File(p.join(dir.path, name)).readAsBytesSync())
          .toString(),
  };
  final sums = File(p.join(dir.path, sumsFileName));

  if (writeSums) {
    sums.writeAsStringSync(
      names.map((name) => '${digests[name]}  $name\n').join(),
    );
    return ArtifactCheck(
      ok: true,
      lines: ['wrote $sumsFileName for ${names.length} files'],
    );
  }

  if (!sums.existsSync()) {
    return const ArtifactCheck(ok: false, lines: ['missing: $sumsFileName']);
  }
  final listed = <String, String>{};
  for (final line in sums.readAsLinesSync()) {
    if (line.isEmpty) continue;
    final match = RegExp(r'^([0-9a-f]{64}) [ *](.+)$').firstMatch(line);
    if (match == null) {
      problems.add('malformed $sumsFileName line: $line');
      continue;
    }
    listed[match.group(2)!] = match.group(1)!;
  }
  for (final name in names) {
    final digest = listed.remove(name);
    if (digest == null) {
      problems.add('not in $sumsFileName: $name');
    } else if (digest != digests[name]) {
      problems.add('checksum mismatch: $name');
    }
  }
  for (final name in listed.keys) {
    problems.add('listed in $sumsFileName but not present: $name');
  }
  if (problems.isNotEmpty) {
    return ArtifactCheck(ok: false, lines: problems..sort());
  }
  return ArtifactCheck(
    ok: true,
    lines: ['$sumsFileName matches ${names.length} files'],
  );
}

const _usage =
    'usage: dart run tool/release/check_artifacts.dart '
    '--dir <dir> --version <version> [--write-sums] [--no-macos]';

/// Runs [checkArtifacts] from the command line.
void main(List<String> args) {
  String? dir;
  String? version;
  var writeSums = false;
  var macos = true;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--dir' when i + 1 < args.length:
        dir = args[++i];
      case '--version' when i + 1 < args.length:
        version = args[++i];
      case '--write-sums':
        writeSums = true;
      case '--no-macos':
        macos = false;
      default:
        stderr.writeln(_usage);
        exitCode = 64;
        return;
    }
  }
  if (dir == null || version == null || version.isEmpty) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  final directory = Directory(dir);
  if (!directory.existsSync()) {
    stderr.writeln('not a directory: $dir');
    exitCode = 1;
    return;
  }

  final result = checkArtifacts(
    dir: directory,
    version: version,
    writeSums: writeSums,
    macos: macos,
  );
  (result.ok ? stdout : stderr).writeln(result.lines.join('\n'));
  if (!result.ok) exitCode = 1;
}
