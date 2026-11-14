// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/check_l10n.dart';

late Directory _root;

/// Writes [expression] inside a widget build method to
/// [path] under a fresh client root and returns the violations.
List<L10nViolation> _checkExpr(
  String expression, {
  String path = 'lib/features/home/ui/x.dart',
}) => _checkSource('Object build() =>\n    $expression;\n', path: path);

List<L10nViolation> _checkSource(String source, {required String path}) {
  File(p.join(_root.path, path))
    ..createSync(recursive: true)
    ..writeAsStringSync(source);
  return checkL10n(_root);
}

List<String> _literals(List<L10nViolation> violations) => [
  for (final v in violations) v.literal,
];

void main() {
  setUp(() => _root = Directory.systemTemp.createTempSync('check_l10n'));
  tearDown(() => _root.deleteSync(recursive: true));

  group('scope', () {
    test('Text literal under lib/**/ui/ is a violation with its line', () {
      final violations = _checkSource(
        "// header\n\nObject build() => Text('Hello');\n",
        path: 'lib/features/home/ui/x.dart',
      );
      expect(violations, hasLength(1));
      expect(violations.single.path, 'lib/features/home/ui/x.dart');
      expect(violations.single.line, 3);
      expect(violations.single.literal, 'Hello');
      expect(
        violations.single.toString(),
        'lib/features/home/ui/x.dart:3: hard-coded string "Hello"',
      );
    });

    test('Text literal under lib/shared/widgets/ is a violation', () {
      expect(
        _literals(
          _checkExpr("Text('Hello')", path: 'lib/shared/widgets/x.dart'),
        ),
        ['Hello'],
      );
    });

    test('Text literal outside a ui directory is not', () {
      expect(
        _checkExpr("Text('Hello')", path: 'lib/features/home/data/x.dart'),
        isEmpty,
      );
    });

    test('generated files are skipped', () {
      expect(
        _checkExpr("Text('x')", path: 'lib/features/home/ui/x.g.dart'),
        isEmpty,
      );
    });
  });

  group('Text', () {
    test('a localized getter is not a violation', () {
      expect(_checkExpr('Text(l10n.homeTitle)'), isEmpty);
    });

    test('an interpolated literal with letters is a violation', () {
      expect(_literals(_checkExpr(r"Text('Hello $name')")), [r'Hello $name']);
    });

    test('interpolation-only, letterless and empty literals are not', () {
      expect(_checkExpr(r"Text('$count')"), isEmpty);
      expect(_checkExpr(r"Text('${a.title}')"), isEmpty);
      expect(_checkExpr("Text('·')"), isEmpty);
      expect(_checkExpr("Text('0:00')"), isEmpty);
      expect(_checkExpr("Text('')"), isEmpty);
    });

    test('letters in any script count', () {
      expect(_literals(_checkExpr("Text('مرحبا')")), ['مرحبا']);
    });

    test('adjacent literals are a violation', () {
      expect(_literals(_checkExpr("Text('Hel' 'lo')")), ['Hello']);
    });

    test('SelectableText and a constructor with a const keyword', () {
      expect(_literals(_checkExpr("const SelectableText('Hi')")), ['Hi']);
    });

    test('TextSpan text: is a violation', () {
      expect(_literals(_checkExpr("TextSpan(text: 'Hi')")), ['Hi']);
    });
  });

  group('named arguments', () {
    for (final name in [
      'tooltip',
      'label',
      'semanticLabel',
      'semanticsLabel',
      'hintText',
      'labelText',
      'helperText',
      'errorText',
      'message',
    ]) {
      test('$name: literal is a violation', () {
        expect(_literals(_checkExpr("Widget($name: 'Close')")), ['Close']);
      });
    }

    test('label: Text(l10n.ok) is not', () {
      expect(_checkExpr('Chip(label: Text(l10n.ok))'), isEmpty);
    });
  });

  test('the real client tree has no violations', () {
    expect(checkL10n(Directory.current), isEmpty);
  });

  // `required-resource-attributes: true` in l10n.yaml is the ARB completeness
  // gate of doc 11.
  test('flutter gen-l10n fails for a message without a description', () {
    final real = Directory.current;
    File(p.join(_root.path, 'l10n.yaml')).writeAsStringSync(
      File(p.join(real.path, 'l10n.yaml')).readAsStringSync(),
    );
    File(p.join(_root.path, 'pubspec.yaml')).writeAsStringSync(
      'name: l10n_check\n'
      'environment:\n'
      "  sdk: '>=3.0.0 <4.0.0'\n"
      'dependencies:\n'
      '  flutter:\n'
      '    sdk: flutter\n'
      '  flutter_localizations:\n'
      '    sdk: flutter\n'
      '  intl: any\n'
      'flutter:\n'
      '  generate: true\n',
    );
    File(p.join(_root.path, 'lib/app/l10n/app_en.arb'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        '{\n'
        '  "@@locale": "en",\n'
        '  "appTitle": "soundspan",\n'
        '  "@appTitle": {"description": "The application name."},\n'
        '  "homeTitle": "Home"\n'
        '}\n',
      );
    final result = Process.runSync(
      Platform.isWindows ? 'flutter.bat' : 'flutter',
      ['gen-l10n'],
      workingDirectory: _root.path,
    );
    expect(result.exitCode, isNot(0), reason: '${result.stdout}');
    expect('${result.stdout}${result.stderr}', contains('@homeTitle'));
  });
}
