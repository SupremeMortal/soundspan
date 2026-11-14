// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Reads the `S1RESULT {json}` lines from a `flutter test` log and prints a
// Markdown summary with the per-question answers of spike S1. Usage:
// `dart run tool/summarize.dart <log> <platform label>`.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final log = File(args[0]).readAsLinesSync();
  final label = args.length > 1 ? args[1] : 'unknown';
  final results = <Map<String, Object?>>[];
  for (final line in log) {
    final i = line.indexOf('S1RESULT ');
    if (i < 0) continue;
    results.add(
      jsonDecode(line.substring(i + 'S1RESULT '.length))
          as Map<String, Object?>,
    );
  }
  List<Map<String, Object?>> runs(String c) =>
      results.where((r) => r['case'] == c).toList();
  int passes(String c) => runs(c).where((r) => r['pass'] == true).length;
  bool played(Map<String, Object?> r) {
    final t = (r['transition'] ?? r) as Map<String, Object?>;
    return t['played'] == true || r['completed'] == true;
  }

  final gapless = runs('gapless_two_items');
  final headers = runs('headers_on_every_request');
  final wrong = runs('wrong_key_fails');
  final replace = runs('replace_next_while_playing');
  final anyAudio = [...gapless, ...headers, ...replace].any(played);

  String answer(bool yes) => !anyAudio
      ? 'unanswerable by CI (no playback on the runner)'
      : (yes ? 'yes' : 'no');

  final q1 = gapless.length == 5 && passes('gapless_two_items') >= 4;
  final q2 =
      headers.length == 5 &&
      passes('headers_on_every_request') == 5 &&
      wrong.length == 5 &&
      passes('wrong_key_fails') == 5;
  final q3 = replace.length == 5 && passes('replace_next_while_playing') >= 4;

  String gaps(List<Map<String, Object?>> rs, String key, [String? nested]) => rs
      .map((r) {
        final m = nested == null ? r : r[nested] as Map<String, Object?>?;
        return '${m?[key] ?? r['error'] ?? '-'}';
      })
      .join(', ');

  final out = StringBuffer()
    ..writeln('## Spike S1: $label')
    ..writeln()
    ..writeln('| Question | Answer | Passing runs | Evidence |')
    ..writeln('|---|---|---|---|')
    ..writeln(
      '| 1. Gapless two-item playlist | ${answer(q1)} | '
      '${passes('gapless_two_items')}/${gapless.length} | gap ms: '
      '${gaps(gapless, 'gapMs')} (raw consecutive-sample ms: '
      '${gaps(gapless, 'rawGapMs')}; stale index samples: '
      '${gaps(gapless, 'staleSamples')}); index changes: '
      '${gaps(gapless, 'indexChanges')}; left ready: '
      '${gaps(gapless, 'leftReady')} |',
    )
    ..writeln(
      '| 2. Header on every request; wrong key fails | ${answer(q2)} | '
      '${passes('headers_on_every_request')}/${headers.length} and '
      '${passes('wrong_key_fails')}/${wrong.length} | requests with key: '
      '${headers.map((r) => '${r['withKey']}/${r['requests']} (range ${r['rangeRequests']})').join(', ')}; '
      'wrong key errors: ${wrong.map((r) => (r['errors'] as List?)?.join(' / ') ?? r['error']).join(' | ')} |',
    )
    ..writeln(
      '| 3. Replace next while playing | ${answer(q3)} | '
      '${passes('replace_next_while_playing')}/${replace.length} | replacement gap ms: '
      '${gaps(replace, 'replacementGapMs')}; state changes: '
      '${gaps(replace, 'replacementStateChanges')}; next tag: '
      '${gaps(replace, 'nextTag')}; index changes: '
      '${gaps(replace, 'indexChanges', 'transition')}; transition gap ms: '
      '${gaps(replace, 'gapMs', 'transition')} |',
    )
    ..writeln()
    ..writeln('<details><summary>Raw results</summary>')
    ..writeln()
    ..writeln('```')
    ..writeln(results.map(jsonEncode).join('\n'))
    ..writeln('```')
    ..writeln()
    ..writeln('</details>');
  stdout.write(out);
}
