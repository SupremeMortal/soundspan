// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Reads the `S2RESULT {json}` lines from a `flutter test` log and prints a
// Markdown summary with the per-question answers of spike S2. Usage:
// `dart run tool/summarize.dart <log> <platform label>`.

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final log = File(args[0]).readAsLinesSync();
  final label = args.length > 1 ? args[1] : 'unknown';
  final results = <Map<String, Object?>>[];
  for (final line in log) {
    final i = line.indexOf('S2RESULT ');
    if (i < 0) continue;
    results.add(
      jsonDecode(line.substring(i + 'S2RESULT '.length))
          as Map<String, Object?>,
    );
  }
  List<Map<String, Object?>> runs(String c) =>
      results.where((r) => r['case'] == c).toList();
  int count(String c, String key) =>
      runs(c).where((r) => r[key] == true).length;
  Map<String, Object?> transition(Map<String, Object?> r) =>
      (r['transition'] ?? r) as Map<String, Object?>;
  String values(List<Map<String, Object?>> rs, String key) => rs
      .map((r) => '${transition(r)[key] ?? r[key] ?? r['error'] ?? '-'}')
      .join(', ');

  final versions = runs('versions').firstOrNull ?? const {};
  final gapless = runs('gapless_two_items');
  final headers = runs('headers_per_item');
  final fallback = runs('fallback_headers_per_item');
  final noPrefetch = runs('no_prefetch_headers_and_gap');
  final wrong = runs('wrong_key_fails');
  final index = runs('index_events_twenty_transitions');
  final replace = runs('replace_next_while_playing');
  final anyAudio = [
    ...gapless,
    ...replace,
  ].any((r) => transition(r)['played'] == true);

  String answer(bool yes) => !anyAudio
      ? 'unanswerable by CI (no playback on the runner)'
      : (yes ? 'yes' : 'no');

  final q1 = gapless.length == 5 && count('gapless_two_items', 'pass') >= 4;
  final q2 =
      headers.length == 5 &&
      count('headers_per_item', 'keyOnEveryRequest') == 5 &&
      count('headers_per_item', 'ownHeaderPerItem') == 5 &&
      wrong.length == 5 &&
      count('wrong_key_fails', 'pass') == 5;
  final q3 =
      index.length == 1 &&
      index.single['pass'] == true &&
      replace.length == 5 &&
      count('replace_next_while_playing', 'pass') >= 4;

  String headerEvidence(List<Map<String, Object?>> rs, String c) =>
      'key on every request ${count(c, 'keyOnEveryRequest')}/${rs.length}; '
      'own header per item ${count(c, 'ownHeaderPerItem')}/${rs.length}; '
      'X-Item seen on B: ${values(rs, 'itemHeadersB')}';

  final out = StringBuffer()
    ..writeln('## Spike S2: $label')
    ..writeln()
    ..writeln(
      'mpv: ${versions['mpvVersion'] ?? '-'}; ffmpeg: '
      '${versions['ffmpegVersion'] ?? '-'}; media_kit: '
      '${versions['mediaKit'] ?? '-'}',
    )
    ..writeln()
    ..writeln('| Question | Answer | Passing runs | Evidence |')
    ..writeln('|---|---|---|---|')
    ..writeln(
      '| 1. Gapless `[A, B]` | ${answer(q1)} | '
      '${count('gapless_two_items', 'pass')}/${gapless.length} | '
      'position gap ms: ${values(gapless, 'gapMs')}; audio-pts gap ms: '
      '${values(gapless, 'ptsGapMs')}; paused-for-cache: '
      '${values(gapless, 'pausedForCache')}; index changes: '
      '${values(gapless, 'indexChanges')} |',
    )
    ..writeln(
      '| 2. Per-item headers; wrong key fails | ${answer(q2)} | '
      '${count('headers_per_item', 'ownHeaderPerItem')}/${headers.length} '
      'and ${count('wrong_key_fails', 'pass')}/${wrong.length} | '
      '${headerEvidence(headers, 'headers_per_item')}; wrong key errors: '
      '${wrong.map((r) => (r['errors'] as List?)?.join(' / ') ?? r['error']).join(' | ')} |',
    )
    ..writeln(
      '| 3. Index events; replace next | ${answer(q3)} | '
      '${index.where((r) => r['pass'] == true).length}/${index.length} and '
      '${count('replace_next_while_playing', 'pass')}/${replace.length} | '
      'index changes: ${values(index, 'indexChanges')}; events per index: '
      '${index.map((r) => jsonEncode(r['eventsPerIndex'])).join()}; playing '
      'after replacement: ${values(replace, 'playingAfterIndexChange')}; '
      'B requested after replacement: ${values(replace, 'bRequestedAfter')} |',
    )
    ..writeln(
      '| 2 (fallback: `loadfile … append` with per-file headers) | '
      '${answer(count('fallback_headers_per_item', 'ownHeaderPerItem') == 5 && count('fallback_headers_per_item', 'keyOnEveryRequest') == 5)} | '
      '${count('fallback_headers_per_item', 'ownHeaderPerItem')}/${fallback.length} | '
      'loadfile layout: ${fallback.map((r) => r['loadfileLayout'] ?? r['error']).toSet().join(', ')}; '
      '${headerEvidence(fallback, 'fallback_headers_per_item')} |',
    )
    ..writeln(
      '| 1 and 2 with `prefetch-playlist=no` | - | '
      '${count('no_prefetch_headers_and_gap', 'ownHeaderPerItem')}/${noPrefetch.length} own header; '
      '${noPrefetch.where((r) => transition(r)['pass'] == true).length}/${noPrefetch.length} gapless | '
      'X-Item seen on B: ${values(noPrefetch, 'itemHeadersB')}; position gap ms: '
      '${values(noPrefetch, 'gapMs')}; audio-pts gap ms: ${values(noPrefetch, 'ptsGapMs')} |',
    )
    ..writeln()
    ..writeln(
      'Gaps between the 20 natural transitions (position ms): '
      '${index.map((r) => r['gapsMs']).join()}',
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
