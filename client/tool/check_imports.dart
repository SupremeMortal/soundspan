// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Checks the client's layering, platform-seam, colour-literal, clock,
// licence-header and source-agnostic rules (doc 01, Static Analysis).
//
// Usage, from client/: dart run tool/check_imports.dart
// Prints `path:line: [rule] message` per violation and exits 1 when there is
// any. There is no ignore comment and no baseline: an exception to a rule is
// made here, with a test.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// The licence header every hand-written Dart file starts with.
const spdxHeader =
    '// SPDX-License-Identifier: GPL-3.0-or-later WITH '
    'LicenseRef-soundspan-store-exception';

/// One broken rule at one location.
class Violation {
  /// Creates a violation of [rule] at [line] of [path].
  const new(this.rule, this.path, this.line, this.message);

  /// The rule id, for example `platform-imports`.
  final String rule;

  /// The file, relative to the client root, with `/` separators.
  final String path;

  /// The 1-based line of the offending code.
  final int line;

  /// What is wrong.
  final String message;

  @override
  String toString() => '$path:$line: [$rule] $message';
}

/// Checks every Dart file under [clientRoot] and returns the violations,
/// sorted by path and line.
///
/// Scanned: `lib/`, `test/`, `tool/`, `integration_test/`, `contract_test/`
/// and `packages/*/{lib,test}`. The import and code rules apply to `lib/` and
/// `packages/*/lib/`; the `spdx` rule applies to all of them. Generated files
/// are skipped.
List<Violation> checkImports(Directory clientRoot) {
  final violations = <Violation>[];
  for (final path in _dartFiles(clientRoot)) {
    final file = File(p.join(clientRoot.path, path));
    violations.addAll(_checkFile(path, file.readAsStringSync()));
  }
  violations.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });
  return violations;
}

void main() {
  final violations = checkImports(Directory.current)..forEach(stdout.writeln);
  if (violations.isNotEmpty) {
    stderr.writeln('check_imports: ${violations.length} violation(s)');
    exitCode = 1;
  } else {
    stdout.writeln('check_imports: no violations');
  }
}

const _scannedRoots = [
  'lib',
  'test',
  'tool',
  'integration_test',
  'contract_test',
];

/// Relative, `/`-separated paths of the hand-written Dart files to check.
List<String> _dartFiles(Directory clientRoot) {
  final roots = [..._scannedRoots];
  final packages = Directory(p.join(clientRoot.path, 'packages'));
  if (packages.existsSync()) {
    for (final package in packages.listSync().whereType<Directory>()) {
      final name = p.basename(package.path);
      roots.addAll(['packages/$name/lib', 'packages/$name/test']);
    }
  }
  final files = <String>[];
  for (final root in roots) {
    final dir = Directory(p.join(clientRoot.path, root));
    if (!dir.existsSync()) continue;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = p
          .relative(entity.path, from: clientRoot.path)
          .replaceAll(r'\', '/');
      if (!_isGenerated(rel)) files.add(rel);
    }
  }
  return files;
}

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.split('/').contains('generated');

/// Whether [path] is production code: under `lib/` or `packages/*/lib/`.
bool _isSource(String path) {
  final parts = path.split('/');
  return parts.first == 'lib' ||
      (parts.length > 3 && parts[0] == 'packages' && parts[2] == 'lib');
}

bool _under(String path, String dir) => path.startsWith('$dir/');

/// The directory segments of [path] (its file name excluded).
List<String> _dirs(String path) {
  final parts = path.split('/');
  return parts.sublist(0, parts.length - 1);
}

List<Violation> _checkFile(String path, String content) {
  final violations = <Violation>[];
  if (!content.startsWith('$spdxHeader\n') && content != spdxHeader) {
    violations.add(
      Violation('spdx', path, 1, 'file does not start with "$spdxHeader"'),
    );
  }
  if (!_isSource(path)) return violations;

  final result = parseString(
    content: content,
    path: path,
    throwIfDiagnostics: false,
  );
  final unit = result.unit;
  final lines = result.lineInfo;

  for (final directive in unit.directives.whereType<NamespaceDirective>()) {
    final line = lines.getLocation(directive.offset).lineNumber;
    final uris = [
      directive.uri.stringValue,
      for (final configuration in directive.configurations)
        configuration.uri.stringValue,
    ].whereType<String>();
    for (final uri in uris) {
      for (final (rule, message) in _checkImport(path, uri)) {
        violations.add(Violation(rule, path, line, message));
      }
    }
  }

  final visitor = _CodeVisitor(path, lines);
  unit.accept(visitor);
  violations.addAll(visitor.violations);

  if (_isSourceAgnosticScope(path)) {
    for (
      Token? token = unit.beginToken;
      token != null && !token.isEof;
      token = token.next
    ) {
      if (token.isIdentifier && _sourceIdentifiers.contains(token.lexeme)) {
        violations.add(
          Violation(
            'source-agnostic',
            path,
            lines.getLocation(token.offset).lineNumber,
            'identifier "${token.lexeme}" names a track source; '
                'use the playback id',
          ),
        );
      }
    }
  }
  return violations;
}

/// Resolves [uri], imported by the file at [from], to a client-relative path
/// (`lib/...`) for local files, or returns it unchanged (`dart:`, other
/// packages).
String _resolve(String from, String uri) {
  if (uri.startsWith('package:soundspan/')) {
    return 'lib/${uri.substring('package:soundspan/'.length)}';
  }
  if (uri.startsWith('package:soundspan_api/')) {
    return 'packages/soundspan_api/lib/'
        '${uri.substring('package:soundspan_api/'.length)}';
  }
  if (uri.contains(':')) return uri;
  return p.posix.normalize(p.posix.join(p.posix.dirname(from), uri));
}

bool _isLocal(String resolved) => !resolved.contains(':');

const _coreOrder = {
  'storage': 0,
  'auth': 1,
  'profile': 2,
  'sync': 3,
  'downloads': 3,
  'realtime': 3,
  'playback': 4,
};

/// The core directory of [path] (`lib/core/<x>/...`), or null.
String? _coreDir(String path) {
  final parts = path.split('/');
  if (parts.length > 3 && parts[0] == 'lib' && parts[1] == 'core') {
    return parts[2];
  }
  return null;
}

/// The feature of [path] (`lib/features/<f>/...`), or null.
String? _feature(String path) {
  final parts = path.split('/');
  if (parts.length > 3 && parts[0] == 'lib' && parts[1] == 'features') {
    return parts[2];
  }
  return null;
}

/// Whether core directory [from] may import core directory [to] (doc 02).
bool _coreMayImport(String from, String to) {
  if (from == to) return true;
  final fromLevel = _coreOrder[from];
  final toLevel = _coreOrder[to];
  if (toLevel == null) return true;
  if (fromLevel == null) return to == 'storage';
  return toLevel < fromLevel;
}

Iterable<(String, String)> _checkImport(String path, String uri) sync* {
  final target = _resolve(path, uri);

  if ((uri == 'dart:io' ||
          uri == 'dart:js_interop' ||
          uri.startsWith('package:web/')) &&
      _under(path, 'lib') &&
      !_under(path, 'lib/platform')) {
    yield (
      'platform-imports',
      '"$uri" is allowed only under lib/platform/ and packages/',
    );
  }

  if ((uri.startsWith('package:just_audio/') ||
          uri.startsWith('package:media_kit/')) &&
      !_under(path, 'lib/core/playback/engines')) {
    yield (
      'playback-packages',
      '"$uri" is allowed only under lib/core/playback/engines/',
    );
  }

  if (uri.startsWith('package:dio/') &&
      !_under(path, 'packages') &&
      !_under(path, 'lib/core/downloads')) {
    yield (
      'dio-boundary',
      '"$uri" is allowed only in packages/soundspan_api and lib/core/downloads',
    );
  }

  final fromFeature = _feature(path);
  final toFeature = _feature(target);
  if (fromFeature != null &&
      toFeature != null &&
      fromFeature != toFeature &&
      target != 'lib/features/$toFeature/$toFeature.dart') {
    yield (
      'feature-isolation',
      'import lib/features/$toFeature/$toFeature.dart instead of $target',
    );
  }

  if (_dirs(path).contains('domain') &&
      (uri.startsWith('package:flutter/') ||
          uri == 'dart:ui' ||
          uri.startsWith('package:drift/') ||
          uri.startsWith('package:dio/'))) {
    yield ('pure-domain', 'domain code may not import "$uri"');
  }

  if (_dirs(path).contains('ui') &&
      _isLocal(target) &&
      _dirs(target).contains('data')) {
    yield ('ui-no-data', 'ui code may not import the data layer ($target)');
  }

  if (_under(path, 'lib/core')) {
    if (_under(target, 'lib/features')) {
      yield ('core-direction', 'core may not import features ($target)');
    }
    final from = _coreDir(path);
    final to = _coreDir(target);
    if (from != null && to != null && !_coreMayImport(from, to)) {
      yield (
        'core-direction',
        'core/$from may not import core/$to '
            '(storage <- auth <- profile <- sync, downloads, realtime '
            '<- playback)',
      );
    }
  }
}

const _sourceIdentifiers = {'streamSource', 'tidalTrackId', 'youtubeVideoId'};

const _stringInspections = {
  'startsWith',
  'endsWith',
  'contains',
  'split',
  'substring',
  'indexOf',
  'codeUnitAt',
  'replaceFirst',
  'replaceAll',
};

bool _isSourceAgnosticScope(String path) =>
    _under(path, 'lib') || _under(path, 'packages/soundspan_api/lib');

bool _mentionsPlaybackId(Expression? target) =>
    target != null && target.toSource().toLowerCase().contains('playbackid');

class _CodeVisitor extends RecursiveAstVisitor<void> {
  new(this.path, this.lines);

  final String path;
  final LineInfo lines;
  final violations = <Violation>[];

  bool get _colourScope =>
      _under(path, 'lib') && !_under(path, 'lib/app/theme');

  bool get _clockScope => _under(path, 'lib') && !_under(path, 'lib/platform');

  void _add(String rule, AstNode node, String message) {
    violations.add(
      Violation(rule, path, lines.getLocation(node.offset).lineNumber, message),
    );
  }

  static const _colourMessage =
      'colour literal outside lib/app/theme/; use a SoundspanColors token';

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final target = node.realTarget;
    final targetName = target is SimpleIdentifier ? target.name : null;

    if (_colourScope &&
        ((target == null && name == 'Color') ||
            (targetName == 'Color' && name.startsWith('from')))) {
      _add('colour-literal', node, _colourMessage);
    }
    if (_clockScope && targetName == 'DateTime' && name == 'now') {
      _add('clock', node, 'DateTime.now() outside lib/platform/; use Clock');
    }
    if (_isSourceAgnosticScope(path) &&
        _stringInspections.contains(name) &&
        _mentionsPlaybackId(target)) {
      _add(
        'source-agnostic',
        node,
        'string inspection on a playback id; playback ids are opaque',
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    if (_isSourceAgnosticScope(path) && _mentionsPlaybackId(node.realTarget)) {
      _add(
        'source-agnostic',
        node,
        'index into a playback id; playback ids are opaque',
      );
    }
    super.visitIndexExpression(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final type = node.constructorName.type.name.lexeme;
    final constructor = node.constructorName.name?.name;
    if (_colourScope &&
        type == 'Color' &&
        (constructor == null || constructor.startsWith('from'))) {
      _add('colour-literal', node, _colourMessage);
    }
    if (_clockScope && type == 'DateTime' && constructor == 'now') {
      _add('clock', node, 'DateTime.now() outside lib/platform/; use Clock');
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (_colourScope &&
        node.prefix.name == 'Colors' &&
        node.identifier.name != 'transparent') {
      _add('colour-literal', node, _colourMessage);
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    // `material.Colors.red`: an import-prefixed Colors reference.
    final target = node.realTarget;
    if (_colourScope &&
        target is PrefixedIdentifier &&
        target.identifier.name == 'Colors' &&
        node.propertyName.name != 'transparent') {
      _add('colour-literal', node, _colourMessage);
    }
    super.visitPropertyAccess(node);
  }
}
