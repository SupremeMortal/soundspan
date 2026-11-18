// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:yaml/yaml.dart';

/// The prefix of every client release tag.
const tagPrefix = 'client-v';

/// `MAJOR.MINOR.PATCH` with an optional pre-release and no build metadata.
final _semver = RegExp(
  r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
  r'(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$',
);

/// The outcome of [validateTag].
class TagValidation {
  /// Creates a result.
  const new({required this.ok, required this.message, this.version});

  /// Whether the tag names the pubspec version.
  final bool ok;

  /// The release version when [ok], otherwise null.
  final String? version;

  /// The version when [ok], otherwise what is wrong, naming both values.
  final String message;
}

/// Checks that [tag] is `client-v<version>`, where `<version>` is semver
/// without build metadata and equals [pubspecVersion] without its `+build`
/// suffix.
TagValidation validateTag({
  required String tag,
  required String pubspecVersion,
}) {
  final expected = pubspecVersion.split('+').first;
  TagValidation fail(String reason) => TagValidation(
    ok: false,
    message:
        '$reason: tag "$tag", pubspec version "$pubspecVersion" '
        '(expected tag "$tagPrefix$expected")',
  );

  if (!_semver.hasMatch(expected)) {
    return fail('the pubspec version is not semver');
  }
  if (!tag.startsWith(tagPrefix)) {
    return fail('the tag does not start with "$tagPrefix"');
  }
  final version = tag.substring(tagPrefix.length);
  if (!_semver.hasMatch(version)) {
    return fail(
      'the tag version is not MAJOR.MINOR.PATCH[-pre-release] '
      'without build metadata',
    );
  }
  if (version != expected) {
    return fail('the tag version differs from the pubspec version');
  }
  return TagValidation(ok: true, message: version, version: version);
}

/// The `version` field of the pubspec in [pubspecYaml], or null.
String? pubspecVersion(String pubspecYaml) {
  final document = loadYaml(pubspecYaml);
  if (document is! YamlMap) return null;
  final version = document['version'];
  return version?.toString();
}

const _usage =
    'usage: dart run tool/release/validate_tag.dart '
    '--tag <ref name> --pubspec <pubspec.yaml>';

/// Runs [validateTag] from the command line and prints the version.
void main(List<String> args) {
  String? tag;
  String? pubspec;
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--tag' when i + 1 < args.length:
        tag = args[++i];
      case '--pubspec' when i + 1 < args.length:
        pubspec = args[++i];
      default:
        stderr.writeln(_usage);
        exitCode = 64;
        return;
    }
  }
  if (tag == null || pubspec == null) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }
  final file = File(pubspec);
  if (!file.existsSync()) {
    stderr.writeln('not a file: $pubspec');
    exitCode = 1;
    return;
  }
  final version = pubspecVersion(file.readAsStringSync());
  if (version == null) {
    stderr.writeln('no version in $pubspec');
    exitCode = 1;
    return;
  }

  final result = validateTag(tag: tag, pubspecVersion: version);
  (result.ok ? stdout : stderr).writeln(result.message);
  if (!result.ok) exitCode = 1;
}
