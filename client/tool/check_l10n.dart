// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Fails on a hard-coded user-visible string in UI code (doc 09,
// Localization).
//
// Usage, from client/: dart run tool/check_l10n.dart
// Prints `path:line: hard-coded string "<literal>"` per violation and exits 1
// when there is any. There is no ignore comment: server-provided text is shown
// through variables, which the rule does not flag.

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:path/path.dart' as p;

/// One hard-coded user-visible string.
class L10nViolation {
  /// Creates a violation for [literal] at [line] of [path].
  const new(this.path, this.line, this.literal);

  /// The file, relative to the client root, with `/` separators.
  final String path;

  /// The 1-based line of the literal.
  final int line;

  /// The literal's text; adjacent literals are joined and interpolations are
  /// kept as written (`Hello $name`).
  final String literal;

  @override
  String toString() => '$path:$line: hard-coded string "$literal"';
}

/// Checks Dart files under `lib/**/ui/` and `lib/shared/widgets/` of
/// [clientRoot] and returns the violations, sorted by path and line.
///
/// A violation is a string literal with at least one letter (outside its
/// interpolations) passed as the first positional argument of `Text` or
/// `SelectableText`, as the `text:` argument of `TextSpan`, or as one of the
/// named arguments in [checkedNamedArguments]. Generated files are skipped.
List<L10nViolation> checkL10n(Directory clientRoot) {
  final violations = <L10nViolation>[];
  final lib = Directory(p.join(clientRoot.path, 'lib'));
  if (!lib.existsSync()) return violations;
  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = p
        .relative(entity.path, from: clientRoot.path)
        .replaceAll(r'\', '/');
    if (!_inScope(path) || _isGenerated(path)) continue;
    final result = parseString(
      content: entity.readAsStringSync(),
      path: path,
      throwIfDiagnostics: false,
    );
    final visitor = _L10nVisitor(path, result.lineInfo);
    result.unit.accept(visitor);
    violations.addAll(visitor.violations);
  }
  violations.sort((a, b) {
    final byPath = a.path.compareTo(b.path);
    return byPath != 0 ? byPath : a.line.compareTo(b.line);
  });
  return violations;
}

/// Named arguments whose string-literal value is user-visible text.
const checkedNamedArguments = {
  'tooltip',
  'label',
  'semanticLabel',
  'semanticsLabel',
  'hintText',
  'labelText',
  'helperText',
  'errorText',
  'message',
};

/// Widgets whose first positional argument is the text they show.
const _textWidgets = {'Text', 'SelectableText'};

void main() {
  final violations = checkL10n(Directory.current)..forEach(stdout.writeln);
  if (violations.isNotEmpty) {
    stderr.writeln('check_l10n: ${violations.length} violation(s)');
    exitCode = 1;
  } else {
    stdout.writeln('check_l10n: no violations');
  }
}

bool _inScope(String path) {
  final dirs = path.split('/')..removeLast();
  return dirs.first == 'lib' &&
      (dirs.contains('ui') || path.startsWith('lib/shared/widgets/'));
}

bool _isGenerated(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.split('/').contains('generated');

final _letter = RegExp(r'\p{L}', unicode: true);

class _L10nVisitor extends RecursiveAstVisitor<void> {
  new(this.path, this.lines);

  final String path;
  final LineInfo lines;
  final violations = <L10nViolation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Without resolution, `Text('x')` parses as a method call named `Text`
    // with no target; `Text.rich(...)` has the target `Text` and is skipped.
    if (node.target == null) {
      _checkCall(node.methodName.name, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructor = node.constructorName;
    if (constructor.name == null) {
      _checkCall(constructor.type.name.lexeme, node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitNamedArgument(NamedArgument node) {
    if (checkedNamedArguments.contains(node.name.lexeme)) {
      _checkLiteral(node.argumentExpression);
    }
    super.visitNamedArgument(node);
  }

  void _checkCall(String name, ArgumentList arguments) {
    if (_textWidgets.contains(name)) {
      final first = arguments.arguments.firstOrNull;
      if (first != null && first is! NamedArgument) {
        _checkLiteral(first.argumentExpression);
      }
    } else if (name == 'TextSpan') {
      for (final argument in arguments.arguments) {
        if (argument is NamedArgument && argument.name.lexeme == 'text') {
          _checkLiteral(argument.argumentExpression);
        }
      }
    }
  }

  void _checkLiteral(Expression expression) {
    if (expression is! StringLiteral) return;
    final parts = _parts(expression);
    if (parts == null) return;
    final (text, letters) = parts;
    if (!_letter.hasMatch(letters)) return;
    violations.add(
      L10nViolation(
        path,
        lines.getLocation(expression.offset).lineNumber,
        text,
      ),
    );
  }

  /// The literal's display text and the text outside its interpolations.
  (String, String)? _parts(StringLiteral literal) {
    switch (literal) {
      case SimpleStringLiteral(:final value):
        return (value, value);
      case AdjacentStrings(:final strings):
        final text = StringBuffer();
        final letters = StringBuffer();
        for (final string in strings) {
          final (t, l) = _parts(string)!;
          text.write(t);
          letters.write(l);
        }
        return (text.toString(), letters.toString());
      case StringInterpolation(:final elements):
        final text = StringBuffer();
        final letters = StringBuffer();
        for (final element in elements) {
          switch (element) {
            case InterpolationString(:final value):
              text.write(value);
              letters.write(value);
            case InterpolationExpression():
              text.write(element.toSource());
          }
        }
        return (text.toString(), letters.toString());
    }
  }
}
