// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Fails when a shipped dependency's licence is not on the allowlist, when a
// bundled font has no licence text, or when the notice manifest
// assets/licenses/index.json and the files beside it disagree (doc 11, Gates
// Specific to the Client).
//
// Usage, from client/ after `flutter pub get`:
//   dart run tool/license_audit.dart [--report]
// Prints `<subject>: <reason>` per finding and exits 1 when there is any. With
// `--report` it first prints every audited package with its detected licences.
//
// Exceptions live in tool/license_overrides.yaml, a list of entries:
//   - package: <name>
//     license: <allowed id>    # for an unknown text or a missing file
//     reason: <why>
//   - package: <name>
//     linking: dynamic         # for an LGPL package
//     reason: <why>
// GPL and AGPL cannot be overridden. An entry for a package that is not in the
// audited set is itself a finding.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// A package or font that fails the audit.
class LicenseFinding {
  /// Creates a finding for [subject] with [reason].
  const new(this.subject, this.reason);

  /// The package name, or the font path relative to the client root.
  final String subject;

  /// Why [subject] fails.
  final String reason;

  @override
  String toString() => '$subject: $reason';
}

/// Licences a shipped dependency may carry without an override entry.
const allowedLicenses = {
  'MIT',
  'BSD-2-Clause',
  'BSD-3-Clause',
  'Apache-2.0',
  'MPL-2.0',
  'ISC',
  'Zlib',
};

/// Licences allowed only for a package overridden with `linking: dynamic`.
const lgplLicenses = {'LGPL-2.1', 'LGPL-3.0'};

/// Licences that always fail.
const forbiddenLicenses = {'GPL-2.0', 'GPL-3.0', 'AGPL-3.0'};

/// The licence files read from a package root, in order.
const licenseFileNames = ['LICENSE', 'LICENSE.md', 'LICENSE.txt', 'COPYING'];

/// Flutter SDK packages, skipped even when not declared with `sdk:`.
const _sdkPackages = {
  'flutter',
  'flutter_localizations',
  'flutter_test',
  'flutter_web_plugins',
  'flutter_driver',
  'integration_test',
  'sky_engine',
};

/// Audits the shipped dependencies of the app and of `packages/soundspan_api`,
/// the bundled fonts, and the notice manifest `assets/licenses/index.json`.
///
/// The audited set is the transitive closure of the non-dev `dependencies` of
/// `pubspec.yaml` and `packages/soundspan_api/pubspec.yaml` under
/// [clientRoot], resolved through `.dart_tool/package_config.json`; Flutter
/// SDK packages and the two root packages are skipped. [onAudited] receives
/// each audited package with its detected licence ids (`unknown` when none
/// was recognised, empty when there is no licence file).
Future<List<LicenseFinding>> auditLicenses(
  Directory clientRoot, {
  void Function(String package, List<String> licenses)? onAudited,
}) async {
  final findings = <LicenseFinding>[
    ..._auditDependencies(clientRoot, onAudited),
    ..._auditFonts(clientRoot),
    ..._auditNotices(clientRoot),
  ];
  return findings;
}

/// Classifies a licence [text] into the ids it contains, or `['unknown']`.
List<String> classifyLicense(String text) {
  final t = text.replaceAll(RegExp(r'\s+'), ' ');
  final ids = <String>[];
  bool has(String pattern) => RegExp(pattern, caseSensitive: false).hasMatch(t);

  if (has('Permission is hereby granted, free of charge, to any person')) {
    ids.add('MIT');
  }
  if (has('Redistribution and use in source and binary forms')) {
    ids.add(
      has('endorse or promote products') ? 'BSD-3-Clause' : 'BSD-2-Clause',
    );
  }
  if (has(r'Apache License,? Version 2\.0')) ids.add('Apache-2.0');
  if (has(r'Mozilla Public License,? (Version|v\.?) ?2\.0')) {
    ids.add('MPL-2.0');
  }
  if (has(
    'Permission to use, copy, modify, (and/or|and) distribute this software '
    'for any purpose with or without fee is hereby granted',
  )) {
    ids.add('ISC');
  }
  if (has(
    'Permission is granted to anyone to use this software for any purpose, '
    'including commercial applications',
  )) {
    ids.add('Zlib');
  }
  if (has(r'GNU LESSER GENERAL PUBLIC LICENSE Version 2\.1') ||
      has('GNU LIBRARY GENERAL PUBLIC LICENSE Version 2')) {
    ids.add('LGPL-2.1');
  }
  if (has('GNU LESSER GENERAL PUBLIC LICENSE Version 3')) ids.add('LGPL-3.0');
  // The GPL and AGPL titles are matched in capitals so that the LGPL-3.0 text,
  // which names "version 3 of the GNU General Public License", is not a GPL.
  if (RegExp(r'GNU GENERAL PUBLIC LICENSE Version 2\b').hasMatch(t)) {
    ids.add('GPL-2.0');
  }
  if (RegExp(r'GNU GENERAL PUBLIC LICENSE Version 3\b').hasMatch(t)) {
    ids.add('GPL-3.0');
  }
  if (RegExp('GNU AFFERO GENERAL PUBLIC LICENSE Version 3').hasMatch(t)) {
    ids.add('AGPL-3.0');
  }
  return ids.isEmpty ? ['unknown'] : ids;
}

class _Override {
  const new(this.package, {this.license, this.dynamicLinking = false});

  final String package;
  final String? license;
  final bool dynamicLinking;
}

List<LicenseFinding> _auditDependencies(
  Directory clientRoot,
  void Function(String, List<String>)? onAudited,
) {
  final configFile = File(
    p.join(clientRoot.path, '.dart_tool', 'package_config.json'),
  );
  if (!configFile.existsSync()) {
    return [
      const LicenseFinding(
        '.dart_tool/package_config.json',
        'missing; run `flutter pub get` in client/ first',
      ),
    ];
  }
  final locations = _packageLocations(configFile);
  final findings = <LicenseFinding>[];
  final overridesResult = _readOverrides(clientRoot);
  findings.addAll(overridesResult.findings);
  final overrides = overridesResult.overrides;

  const roots = {'soundspan', 'soundspan_api'};
  final rootPubspecs = [
    p.join(clientRoot.path, 'pubspec.yaml'),
    p.join(clientRoot.path, 'packages', 'soundspan_api', 'pubspec.yaml'),
  ];
  final audited = <String>{};
  final queue = <String>[];
  for (final path in rootPubspecs) {
    queue.addAll(_dependencies(File(path)));
  }
  while (queue.isNotEmpty) {
    final name = queue.removeLast();
    if (roots.contains(name) || !audited.add(name)) continue;
    final location = locations[name];
    if (location == null) {
      findings.add(
        LicenseFinding(
          name,
          'not in package_config.json; run `flutter pub get`',
        ),
      );
      continue;
    }
    queue.addAll(_dependencies(File(p.join(location, 'pubspec.yaml'))));
  }

  final names = audited.toList()..sort();
  for (final name in names) {
    final location = locations[name];
    if (location == null) continue;
    final texts = [
      for (final file in licenseFileNames)
        if (File(p.join(location, file)).existsSync())
          File(p.join(location, file)).readAsStringSync(),
    ];
    final ids = texts.isEmpty
        ? <String>[]
        : {for (final text in texts) ...classifyLicense(text)}.toList();
    onAudited?.call(name, ids);
    final reason = _verdict(ids, overrides[name] ?? const []);
    if (reason != null) findings.add(LicenseFinding(name, reason));
  }

  for (final name in overrides.keys) {
    if (!audited.contains(name)) {
      findings.add(
        LicenseFinding(
          name,
          'override in tool/license_overrides.yaml for a package that is not '
          'a shipped dependency; remove it',
        ),
      );
    }
  }
  return findings;
}

/// Returns why a package with licence [ids] fails, or `null` when it passes.
String? _verdict(List<String> ids, List<_Override> overrides) {
  final forbidden = ids.where(forbiddenLicenses.contains).toList();
  if (forbidden.isNotEmpty) {
    return 'licence ${forbidden.join(', ')} is not allowed in the client';
  }
  if (ids.isEmpty || ids.contains('unknown')) {
    final allowed = overrides.any(
      (o) => o.license != null && allowedLicenses.contains(o.license),
    );
    if (allowed) return null;
    return ids.isEmpty
        ? 'no licence file (${licenseFileNames.join(', ')})'
        : 'licence text not recognised';
  }
  final lgpl = ids.where(lgplLicenses.contains).toList();
  if (lgpl.isNotEmpty && !overrides.any((o) => o.dynamicLinking)) {
    return 'licence ${lgpl.join(', ')} needs an override with '
        '`linking: dynamic`';
  }
  return null;
}

/// Maps each package in [configFile] to its root directory.
Map<String, String> _packageLocations(File configFile) {
  final json =
      jsonDecode(configFile.readAsStringSync()) as Map<String, Object?>;
  final base = Uri.file(configFile.path);
  return {
    for (final entry
        in (json['packages']! as List<Object?>).cast<Map<String, Object?>>())
      entry['name']! as String: p.fromUri(
        base.resolve(_asDirectory(entry['rootUri']! as String)),
      ),
  };
}

String _asDirectory(String uri) => uri.endsWith('/') ? uri : '$uri/';

/// The non-dev, non-SDK dependency names of the pubspec [file].
List<String> _dependencies(File file) {
  if (!file.existsSync()) return const [];
  final yaml = loadYaml(file.readAsStringSync());
  if (yaml is! YamlMap) return const [];
  final deps = yaml['dependencies'];
  if (deps is! YamlMap) return const [];
  return [
    for (final MapEntry(:key, :value) in deps.entries)
      if (!_sdkPackages.contains(key) &&
          !(value is YamlMap && value.containsKey('sdk')))
        key as String,
  ];
}

({Map<String, List<_Override>> overrides, List<LicenseFinding> findings})
_readOverrides(Directory clientRoot) {
  final file = File(p.join(clientRoot.path, 'tool', 'license_overrides.yaml'));
  final overrides = <String, List<_Override>>{};
  final findings = <LicenseFinding>[];
  if (!file.existsSync()) return (overrides: overrides, findings: findings);
  final yaml = loadYaml(file.readAsStringSync());
  if (yaml == null) return (overrides: overrides, findings: findings);
  if (yaml is! YamlList) {
    findings.add(
      const LicenseFinding(
        'tool/license_overrides.yaml',
        'must be a list of {package, license | linking, reason} entries',
      ),
    );
    return (overrides: overrides, findings: findings);
  }
  for (final entry in yaml) {
    final package = entry is YamlMap ? entry['package'] : null;
    final reason = entry is YamlMap ? entry['reason'] : null;
    if (package is! String || reason is! String || reason.trim().isEmpty) {
      findings.add(
        LicenseFinding(
          'tool/license_overrides.yaml',
          'entry $entry needs `package` and a non-empty `reason`',
        ),
      );
      continue;
    }
    entry as YamlMap;
    overrides
        .putIfAbsent(package, () => [])
        .add(
          _Override(
            package,
            license: entry['license'] as String?,
            dynamicLinking: entry['linking'] == 'dynamic',
          ),
        );
  }
  return (overrides: overrides, findings: findings);
}

/// Extensions of the font files the font gate audits.
const _fontExtensions = {'.ttf', '.otf', '.ttc', '.woff', '.woff2'};

/// Every font file under `assets/fonts/` needs a non-empty
/// `assets/licenses/fonts/<Family>.txt`, where the family is the file name up
/// to its first `-` (or its extension). Other files there, such as the
/// README that records each font's source, are not fonts.
List<LicenseFinding> _auditFonts(Directory clientRoot) {
  final fonts = Directory(p.join(clientRoot.path, 'assets', 'fonts'));
  if (!fonts.existsSync()) return const [];
  final findings = <LicenseFinding>[];
  final files =
      fonts
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) => _fontExtensions.contains(p.extension(f.path).toLowerCase()),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final font in files) {
    final family = p.basenameWithoutExtension(font.path).split('-').first;
    final licence = File(
      p.join(clientRoot.path, 'assets', 'licenses', 'fonts', '$family.txt'),
    );
    if (!licence.existsSync() || licence.readAsStringSync().trim().isEmpty) {
      findings.add(
        LicenseFinding(
          p.relative(font.path, from: clientRoot.path).replaceAll(r'\', '/'),
          'no licence text in assets/licenses/fonts/$family.txt',
        ),
      );
    }
  }
  return findings;
}

/// The notices `pubspec.lock` requires while it contains a `media_kit_libs_*`
/// package, which ships libmpv and the FFmpeg libraries inside it.
const mediaKitNotices = ['mpv-NOTICE.txt', 'FFmpeg-NOTICE.txt'];

/// Every file under `assets/licenses/` other than `index.json` must be named
/// by an `index.json` entry, and every entry must name an existing file. A
/// `media_kit_libs_*` package in `pubspec.lock` requires [mediaKitNotices].
List<LicenseFinding> _auditNotices(Directory clientRoot) {
  final dir = Directory(p.join(clientRoot.path, 'assets', 'licenses'));
  final findings = <LicenseFinding>[];
  String relative(String path) =>
      p.relative(path, from: dir.path).replaceAll(r'\', '/');
  const indexSubject = 'assets/licenses/index.json';

  final files = dir.existsSync()
      ? (dir
            .listSync(recursive: true)
            .whereType<File>()
            .map((f) => relative(f.path))
            .where((f) => f != 'index.json' && !p.basename(f).startsWith('.'))
            .toList()
          ..sort())
      : <String>[];
  final index = File(p.join(dir.path, 'index.json'));
  if (!index.existsSync()) {
    if (files.isNotEmpty) {
      findings.add(
        const LicenseFinding(
          indexSubject,
          'missing; list every notice file in assets/licenses/',
        ),
      );
    }
  } else {
    final listed = _readNoticeIndex(index, findings, indexSubject);
    for (final file in files) {
      if (!listed.contains(file)) {
        findings.add(
          LicenseFinding(
            'assets/licenses/$file',
            'not listed in assets/licenses/index.json',
          ),
        );
      }
    }
    for (final file in listed) {
      if (!File(p.join(dir.path, file)).existsSync()) {
        findings.add(
          LicenseFinding(
            indexSubject,
            'an entry names $file, which does not exist',
          ),
        );
      }
    }
  }

  final lock = File(p.join(clientRoot.path, 'pubspec.lock'));
  if (lock.existsSync()) {
    final yaml = loadYaml(lock.readAsStringSync());
    final packages = yaml is YamlMap ? yaml['packages'] : null;
    final mediaKitLibs = packages is YamlMap
        ? (packages.keys
              .whereType<String>()
              .where((name) => name.startsWith('media_kit_libs_'))
              .toList()
            ..sort())
        : const <String>[];
    if (mediaKitLibs.isNotEmpty) {
      for (final notice in mediaKitNotices) {
        if (!files.contains(notice)) {
          findings.add(
            LicenseFinding(
              'assets/licenses/$notice',
              'missing; pubspec.lock contains ${mediaKitLibs.join(', ')}',
            ),
          );
        }
      }
    }
  }
  return findings;
}

/// The files named by the notice manifest [index]. A malformed manifest or
/// entry adds a finding under [subject].
Set<String> _readNoticeIndex(
  File index,
  List<LicenseFinding> findings,
  String subject,
) {
  Object? json;
  try {
    json = jsonDecode(index.readAsStringSync());
  } on FormatException catch (error) {
    findings.add(LicenseFinding(subject, 'not valid JSON: ${error.message}'));
    return const {};
  }
  if (json is! List<Object?>) {
    findings.add(
      LicenseFinding(
        subject,
        'must be an array of {title, file, spdx, platforms} entries',
      ),
    );
    return const {};
  }
  final listed = <String>{};
  for (final entry in json) {
    final valid =
        entry is Map<String, Object?> &&
        entry['title'] is String &&
        (entry['title']! as String).trim().isNotEmpty &&
        entry['file'] is String &&
        entry['spdx'] is String &&
        entry['platforms'] is List<Object?> &&
        (entry['platforms']! as List<Object?>).every((e) => e is String);
    if (!valid) {
      findings.add(
        LicenseFinding(
          subject,
          'entry $entry needs a non-empty `title`, `file`, `spdx` and a '
          '`platforms` array of strings',
        ),
      );
      continue;
    }
    listed.add(entry['file']! as String);
  }
  return listed;
}

Future<void> main(List<String> args) async {
  final report = args.contains('--report');
  final findings = await auditLicenses(
    Directory.current,
    onAudited: report
        ? (pkg, ids) => stdout.writeln(
            '$pkg: ${ids.isEmpty ? 'no licence file' : ids.join(', ')}',
          )
        : null,
  );
  findings.forEach(stdout.writeln);
  if (findings.isNotEmpty) {
    stderr.writeln('license_audit: ${findings.length} finding(s)');
    exitCode = 1;
  } else {
    stdout.writeln('license_audit: no findings');
  }
}
