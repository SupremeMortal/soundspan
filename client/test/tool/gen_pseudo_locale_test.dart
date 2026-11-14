// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/gen_pseudo_locale.dart';

/// The text of [message] with every ICU argument (`{...}`, nested) removed.
String _withoutArguments(String message) {
  final out = StringBuffer();
  var depth = 0;
  for (final rune in message.runes) {
    final char = String.fromCharCode(rune);
    if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
    } else if (depth == 0) {
      out.write(char);
    }
  }
  return out.toString();
}

void main() {
  group('pseudoLocalize', () {
    test('plain text is accented, bracketed and at least 40 % longer', () {
      const english = 'Add server';
      final pseudo = pseudoLocalize(english);
      expect(pseudo, startsWith('['));
      expect(pseudo, endsWith(']'));
      expect(pseudo, isNot(contains('Add server')));
      expect(pseudo, contains('Åðð šéŕvéŕ'));
      expect(pseudo.runes.length, greaterThanOrEqualTo(english.length * 1.4));
    });

    test('placeholders are preserved byte for byte', () {
      const english = '{username} on {host}';
      final pseudo = pseudoLocalize(english);
      expect(pseudo, startsWith('[{username} öñ {host}'));
      expect(pseudo, contains('{username}'));
      expect(pseudo, contains('{host}'));
      expect(
        pseudoLocalize('{screen} · soundspan'),
        startsWith('[{screen} · šöûñðšþåñ'),
      );
      expect(pseudoLocalize('{count, number}'), startsWith('[{count, number}'));
    });

    test('plural branches are transformed and their keywords, selectors and # '
        'are not', () {
      const english =
          '{count, plural, =0{No songs} =1{One song} other{# songs}}';
      final pseudo = pseudoLocalize(english);
      expect(pseudo, startsWith('[{count, plural, =0{Ñö šöñĝš'));
      expect(pseudo, contains('} =1{Öñé šöñĝ'));
      expect(pseudo, contains('} other{# šöñĝš'));
      expect(pseudo, endsWith('}}]'));
      expect(pseudo, isNot(contains('No songs')));
    });

    test('plural branches with nested placeholders keep them', () {
      final pseudo = pseudoLocalize(
        '{count, plural, offset:1 one{{name} only} other{{name} and #}}',
      );
      expect(pseudo, startsWith('[{count, plural, offset:1 one{{name} öñļý'));
      expect(pseudo, contains('other{{name} åñð #'));
    });

    test('select branches likewise', () {
      const english =
          '{kind, select, album{Album by {artist}} other{Unknown kind}}';
      final pseudo = pseudoLocalize(english);
      expect(pseudo, startsWith('[{kind, select, album{Åļbûm bý {artist}'));
      expect(pseudo, contains('} other{Ûñķñöŵñ ķîñð'));
      expect(pseudo, endsWith('}}]'));
    });

    test('escaped quotes and braces survive', () {
      final pseudo = pseudoLocalize("It''s '{literal}' text");
      expect(pseudo, startsWith("[Îţ''š '{literal}' ţéxţ"));
      expect(pseudoLocalize("'{'open"), startsWith("['{'öþéñ"));
    });

    test('every branch of a message is at least 40 % longer', () {
      final pseudo = pseudoLocalize(
        '{count, plural, one{One song} other{Many songs}}',
      );
      final branches = RegExp(r'(one|other)\{([^{}]*)\}')
          .allMatches(pseudo)
          .toList();
      expect(branches, hasLength(2));
      expect(branches[0][2]!.runes.length, greaterThanOrEqualTo(8 * 1.4));
      expect(branches[1][2]!.runes.length, greaterThanOrEqualTo(10 * 1.4));
    });
  });

  group('pseudoArb', () {
    const english = {
      '@@locale': 'en',
      'navHome': 'Home',
      '@navHome': {'description': 'The home screen.'},
      'windowTitle': '{screen} · soundspan',
      '@windowTitle': {
        'description': 'The window title.',
        'placeholders': {
          'screen': {'type': 'String', 'example': 'Home'},
        },
      },
    };

    test('metadata is copied and @@locale is en_XA', () {
      final pseudo = pseudoArb(english);
      expect(pseudo['@@locale'], 'en_XA');
      expect(pseudo['@navHome'], english['@navHome']);
      expect(pseudo['@windowTitle'], english['@windowTitle']);
      expect(pseudo.keys, english.keys);
      expect(pseudo['navHome'], isNot('Home'));
    });

    test('running twice gives identical output', () {
      final source = const JsonEncoder.withIndent('  ').convert(english);
      final first = generatePseudoArb(source);
      expect(generatePseudoArb(source), first);
      expect(first, endsWith('}\n'));
      expect(generatePseudoArb(first.replaceAll('en_XA', 'en')), isNotEmpty);
    });

    test("the committed app_en_XA.arb equals the generator's output for the "
        'committed app_en.arb', () {
      final source = File('lib/app/l10n/app_en.arb').readAsStringSync();
      final committed = File('lib/app/l10n/app_en_XA.arb').readAsStringSync();
      expect(committed, generatePseudoArb(source));
    });

    test('every English message gets at least 40 % longer visible text', () {
      final source = jsonDecode(
        File('lib/app/l10n/app_en.arb').readAsStringSync(),
      ) as Map<String, Object?>;
      final pseudo = pseudoArb(source);
      for (final MapEntry(:key, :value) in source.entries) {
        if (key.startsWith('@')) continue;
        final english = _withoutArguments(value! as String).runes.length;
        final padded = _withoutArguments(pseudo[key]! as String).runes.length;
        expect(padded, greaterThanOrEqualTo(english * 1.4), reason: key);
      }
    });
  });
}
