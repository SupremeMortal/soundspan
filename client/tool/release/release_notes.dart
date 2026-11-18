// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:soundspan/app/build_config.dart';

/// The line used when a release has no new Client bullets.
const noChangesLine = 'No user-visible client changes.';

/// Every bullet under every `### Client` subsection of [changelog], in order
/// of appearance.
///
/// A bullet is a top-level `- ` or `* ` line with the indented lines that
/// follow it, kept whole with its line breaks.
List<String> clientBullets(String changelog) {
  final bullets = <String>[];
  var inClient = false;
  List<String>? current;
  var pendingBlank = 0;

  void finish() {
    if (current != null) bullets.add(current!.join('\n'));
    current = null;
    pendingBlank = 0;
  }

  for (final line in changelog.split(RegExp(r'\r?\n'))) {
    if (line.startsWith('#')) {
      finish();
      inClient = RegExp(r'^###\s+Client\s*$').hasMatch(line);
      continue;
    }
    if (!inClient) continue;
    if (line.startsWith('- ') || line.startsWith('* ')) {
      finish();
      current = [line.trimRight()];
    } else if (line.trim().isEmpty) {
      if (current != null) pendingBlank++;
    } else if (current != null && line.startsWith(RegExp(r'\s'))) {
      current!
        ..addAll(List.filled(pendingBlank, ''))
        ..add(line.trimRight());
      pendingBlank = 0;
    } else {
      finish();
    }
  }
  finish();
  return bullets;
}

/// The release notes for client [version], in Markdown.
///
/// Lists the Client bullets of [changelog] that [previousChangelog] (the
/// changelog at the previous release tag) does not have, word for word.
/// [repository] (`owner/name`) is named in the attestation command.
String releaseNotes({
  required String changelog,
  required String version,
  required String repository,
  String? previousChangelog,
  String minServer = BuildConfig.minServer,
  String maxTestedServer = BuildConfig.maxTestedServer,
}) {
  final previous = previousChangelog == null
      ? const <String>{}
      : clientBullets(previousChangelog).toSet();
  final changes = [
    for (final bullet in clientBullets(changelog))
      if (!previous.contains(bullet)) bullet,
  ];

  final unsigned =
      'These are unsigned test builds of the soundspan client $version. '
      'Windows SmartScreen and macOS ask for confirmation before they '
      'open them; on macOS, approve the app in System Settings → Privacy & '
      'Security → Open Anyway. The Android build is debug-signed: '
      'uninstall it, which removes its data, before installing a later '
      'signed build. There is no iOS build. The Windows MSIX package is '
      'unsigned and installs only where unsigned packages are allowed; most '
      'users should use the Windows setup program.';
  final verify =
      'Verify downloads against `SHA256SUMS` with '
      '`sha256sum --check SHA256SUMS`, and their build provenance with '
      '`gh attestation verify <file> --repo $repository`.';
  final sections = [
    unsigned,
    'Works with soundspan server `$minServer` to `$maxTestedServer`.',
    '## Changes',
    if (changes.isEmpty) noChangesLine else changes.join('\n'),
    '## Verify downloads',
    verify,
  ];
  return '${sections.join('\n\n')}\n';
}

const _usage =
    'usage: dart run tool/release/release_notes.dart --changelog <path> '
    '[--previous-changelog <path>] --version <v> '
    '--repository <owner/name> --out <file>';

/// Writes [releaseNotes] from the command line.
void main(List<String> args) {
  final values = <String, String>{};
  const options = {
    '--changelog',
    '--previous-changelog',
    '--version',
    '--repository',
    '--out',
  };
  for (var i = 0; i < args.length; i++) {
    if (!options.contains(args[i]) || i + 1 >= args.length) {
      stderr.writeln(_usage);
      exitCode = 64;
      return;
    }
    values[args[i]] = args[++i];
  }
  final changelog = values['--changelog'];
  final version = values['--version'];
  final repository = values['--repository'];
  final out = values['--out'];
  if (changelog == null ||
      version == null ||
      repository == null ||
      out == null) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  String? read(String path) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    stderr.writeln('not a file: $path');
    exitCode = 1;
    return null;
  }

  final current = read(changelog);
  final previousPath = values['--previous-changelog'];
  final previous = previousPath == null ? null : read(previousPath);
  if (current == null || (previousPath != null && previous == null)) return;

  final notes = releaseNotes(
    changelog: current,
    previousChangelog: previous,
    version: version,
    repository: repository,
  );
  File(out).writeAsStringSync(notes);
  stdout.write(notes);
}
