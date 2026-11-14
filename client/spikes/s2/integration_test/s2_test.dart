// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Spike S2 harness (docs/designs/flutter-client/13-milestones-and-work-breakdown.md,
// Spikes, row S2). Every case prints one machine-readable `S2RESULT {json}`
// line per run; the workflow turns those lines into the job summary. The
// cases fail only on harness errors, never on a "no" answer.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';

const _runs = 5;
const _apiKey = 'spike';
const _pollInterval = Duration(milliseconds: 5);
const _itemDurationUs = 3000000;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  late _SpikeServer server;

  setUpAll(() async {
    server = await _SpikeServer.start();
    final probe = await _newPlayer();
    _emit('versions', 0, {
      'mpvVersion': await probe.native.getProperty('mpv-version'),
      'ffmpegVersion': await probe.native.getProperty('ffmpeg-version'),
      'mediaKit': '1.2.6',
    });
    await probe.player.dispose();
  });

  tearDownAll(() async {
    await server.close();
  });

  testWidgets('gapless_two_items', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final p = await _newPlayer();
      try {
        final rec = _Recorder(p)..start();
        await p.player.open(
          Playlist([server.media('a'), server.media('b')]),
          play: true,
        );
        await _waitFor(() => _finished(p.player), const Duration(seconds: 20));
        await rec.stop();
        _emit('gapless_two_items', run, rec.transitionResult(0));
      } on Object catch (e) {
        _emit('gapless_two_items', run, {'error': e.toString()});
      } finally {
        await p.player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('headers_per_item', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final p = await _newPlayer();
      try {
        await p.player.open(
          Playlist([
            server.media('a', extra: {'X-Item': 'a'}),
            server.media('b', extra: {'X-Item': 'b'}),
          ]),
          play: true,
        );
        await _waitFor(() => _finished(p.player), const Duration(seconds: 20));
        List<_Request> of(String name) =>
            server.requests.where((r) => r.path == '/$name.flac').toList();
        final a = of('a');
        final b = of('b');
        String items(List<_Request> rs) =>
            rs.map((r) => r.item ?? '-').join(',');
        _emit('headers_per_item', run, {
          'completed': p.player.state.completed,
          'requestsA': a.length,
          'requestsB': b.length,
          'withKey': [...a, ...b].where((r) => r.apiKey == _apiKey).length,
          'itemHeadersA': items(a),
          'itemHeadersB': items(b),
          'unauthorized': server.unauthorized,
          'keyOnEveryRequest':
              a.isNotEmpty &&
              b.isNotEmpty &&
              [...a, ...b].every((r) => r.apiKey == _apiKey),
          'ownHeaderPerItem':
              a.isNotEmpty &&
              b.isNotEmpty &&
              a.every((r) => r.item == 'a') &&
              b.every((r) => r.item == 'b'),
        });
      } on Object catch (e) {
        _emit('headers_per_item', run, {'error': e.toString()});
      } finally {
        await p.player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  // Decision-rule fallback of doc 13 for question 2: libmpv driven through
  // NativePlayer's command interface, each file appended with
  // `loadfile <url> append` and its headers as per-file options.
  testWidgets('fallback_headers_per_item', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final p = await _newPlayer();
      try {
        final layout = await _appendWithOptions(
          p.native,
          server.url('a', query: 'fallback=$run'),
          {'X-API-Key': _apiKey, 'X-Item': 'a'},
          replace: true,
        );
        await _appendWithOptions(
          p.native,
          server.url('b', query: 'fallback=$run'),
          {'X-API-Key': _apiKey, 'X-Item': 'b'},
        );
        final count = await p.native.getProperty('playlist-count');
        await p.native.setProperty('pause', 'no');
        await _waitForAsync(() async {
          final pos = await p.native.getProperty('playlist-playing-pos');
          final eof = await p.native.getProperty('eof-reached');
          return pos == '1' && eof == 'yes';
        }, const Duration(seconds: 20));
        List<_Request> of(String name) =>
            server.requests.where((r) => r.path == '/$name.flac').toList();
        final a = of('a');
        final b = of('b');
        String items(List<_Request> rs) =>
            rs.map((r) => r.item ?? '-').join(',');
        _emit('fallback_headers_per_item', run, {
          'loadfileLayout': layout,
          'playlistCount': count,
          'requestsA': a.length,
          'requestsB': b.length,
          'itemHeadersA': items(a),
          'itemHeadersB': items(b),
          'unauthorized': server.unauthorized,
          'keyOnEveryRequest':
              a.isNotEmpty &&
              b.isNotEmpty &&
              [...a, ...b].every((r) => r.apiKey == _apiKey),
          'ownHeaderPerItem':
              a.isNotEmpty &&
              b.isNotEmpty &&
              a.every((r) => r.item == 'a') &&
              b.every((r) => r.item == 'b'),
        });
      } on Object catch (e) {
        _emit('fallback_headers_per_item', run, {'error': e.toString()});
      } finally {
        await p.player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  // Evidence for #119 when question 2 fails: the primary path with
  // `prefetch-playlist=no`, measuring both the headers and the gap.
  testWidgets('no_prefetch_headers_and_gap', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final p = await _newPlayer(prefetch: false);
      try {
        final rec = _Recorder(p)..start();
        await p.player.open(
          Playlist([
            server.media('a', extra: {'X-Item': 'a'}, query: 'np=$run'),
            server.media('b', extra: {'X-Item': 'b'}, query: 'np=$run'),
          ]),
          play: true,
        );
        await _waitFor(() => _finished(p.player), const Duration(seconds: 20));
        await rec.stop();
        List<_Request> of(String name) =>
            server.requests.where((r) => r.path == '/$name.flac').toList();
        final a = of('a');
        final b = of('b');
        _emit('no_prefetch_headers_and_gap', run, {
          'itemHeadersA': a.map((r) => r.item ?? '-').join(','),
          'itemHeadersB': b.map((r) => r.item ?? '-').join(','),
          'ownHeaderPerItem':
              a.isNotEmpty &&
              b.isNotEmpty &&
              a.every((r) => r.item == 'a') &&
              b.every((r) => r.item == 'b'),
          'transition': rec.transitionResult(0),
        });
      } on Object catch (e) {
        _emit('no_prefetch_headers_and_gap', run, {'error': e.toString()});
      } finally {
        await p.player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('wrong_key_fails', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final p = await _newPlayer();
      final errors = <String>[];
      final sub = p.player.stream.error.listen(errors.add);
      try {
        await p.player.open(
          Playlist([server.media('a', key: 'wrong', query: 'wrong=$run')]),
          play: true,
        );
        await _waitFor(
          () => errors.isNotEmpty || p.player.state.completed,
          const Duration(seconds: 15),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final played = p.player.state.position > Duration.zero;
        _emit('wrong_key_fails', run, {
          'errors': errors,
          'completed': p.player.state.completed,
          'unauthorized': server.unauthorized,
          'positionMs': p.player.state.position.inMilliseconds,
          'pass': errors.isNotEmpty && !played && server.unauthorized > 0,
        });
      } on Object catch (e) {
        _emit('wrong_key_fails', run, {'error': e.toString()});
      } finally {
        await sub.cancel();
        await p.player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('index_events_twenty_transitions', (tester) async {
    server.clear();
    final p = await _newPlayer();
    try {
      final rec = _Recorder(p)..start();
      await p.player.open(
        Playlist([
          for (var i = 0; i < 21; i++) server.media(i.isEven ? 'a' : 'b'),
        ]),
        play: true,
      );
      await _waitFor(() => _finished(p.player), const Duration(seconds: 120));
      await rec.stop();
      final changes = rec.indexChanges;
      final expected = [for (var i = 1; i <= 20; i++) i];
      final perIndex = <int, int>{};
      for (final e in rec.indexEvents) {
        perIndex[e.$2] = (perIndex[e.$2] ?? 0) + 1;
      }
      final gaps = [
        for (var i = 0; i < 20; i++) rec.transitionResult(i)['gapMs'],
      ];
      _emit('index_events_twenty_transitions', 1, {
        'completed': p.player.state.completed,
        'indexChanges': changes.join(','),
        'playlistEvents': rec.indexEvents.length,
        'eventsPerIndex': perIndex.map((k, v) => MapEntry('$k', v)),
        'gapsMs': gaps,
        'pass': changes.join(',') == expected.join(','),
      });
    } on Object catch (e) {
      _emit('index_events_twenty_transitions', 1, {'error': e.toString()});
    } finally {
      await p.player.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('replace_next_while_playing', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final p = await _newPlayer();
      try {
        final rec = _Recorder(p)..start();
        await p.player.open(
          Playlist([server.media('a'), server.media('b')]),
          play: true,
        );
        await _waitFor(
          () => p.player.state.position >= const Duration(milliseconds: 1000),
          const Duration(seconds: 10),
        );
        final replaceStart = rec.elapsedUs;
        final requestsBefore = server.requests.length;
        await p.player.remove(1);
        await p.player.add(server.media('c'));
        final replaceEnd = rec.elapsedUs;
        await _waitFor(
          () => p.player.state.playlist.index == 1,
          const Duration(seconds: 10),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final playingPath = await p.native.getProperty('path');
        await _waitFor(() => _finished(p.player), const Duration(seconds: 20));
        await rec.stop();
        final after = server.requests.skip(requestsBefore).toList();
        final transition = rec.transitionResult(0);
        final replacement = rec.windowResult(
          replaceStart - 250000,
          replaceEnd + 250000,
        );
        final cRequested = after.any((r) => r.path == '/c.flac');
        final bRequested = after.any((r) => r.path == '/b.flac');
        _emit('replace_next_while_playing', run, {
          'replaceMs': (replaceEnd - replaceStart) / 1000,
          'replacementGapMs': replacement['gapMs'],
          'replacementPtsGapMs': replacement['ptsGapMs'],
          'playingAfterIndexChange': Uri.parse(playingPath).path,
          'cRequestedAfter': cRequested,
          'bRequestedAfter': bRequested,
          'transition': transition,
          'pass':
              (replacement['gapMs']! as num) <= 20 &&
              playingPath.contains('/c.flac') &&
              cRequested &&
              !bRequested &&
              transition['indexChanges'] == '1',
        });
      } on Object catch (e) {
        _emit('replace_next_while_playing', run, {'error': e.toString()});
      } finally {
        await p.player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

typedef _Players = ({Player player, NativePlayer native});

/// The player as doc 06 configures it for `MediaKitEngine`, plus `ao=null`
/// because CI runners have no sound card.
Future<_Players> _newPlayer({bool prefetch = true}) async {
  final player = Player(
    configuration: const PlayerConfiguration(title: 'soundspan'),
  );
  final native = player.platform! as NativePlayer;
  final properties = {
    'vid': 'no',
    'ao': 'null',
    'gapless-audio': 'yes',
    'prefetch-playlist': prefetch ? 'yes' : 'no',
    'audio-client-name': 'soundspan',
    'cache': 'yes',
    'demuxer-max-bytes': '64MiB',
    'network-timeout': '30',
    'volume-max': '100',
  };
  for (final e in properties.entries) {
    await native.setProperty(e.key, e.value);
  }
  return (player: player, native: native);
}

void _emit(String testCase, int run, Map<String, Object?> data) {
  // The workflow greps these lines from the test output.
  // ignore: avoid_print
  print(
    'S2RESULT ${jsonEncode({'case': testCase, 'platform': Platform.operatingSystem, 'run': run, ...data})}',
  );
}

/// `stream.completed` also turns true for a moment at the end of every item
/// before mpv advances, so the run ends on completion of the last item.
bool _finished(Player player) =>
    player.state.completed &&
    player.state.playlist.index == player.state.playlist.medias.length - 1;

/// Appends [url] with its headers as the per-file option
/// `http-header-fields`. mpv 0.38 added an index argument before the options
/// argument, so the layout is chosen by trying both and checking the
/// playlist length; returns the layout that worked.
Future<String> _appendWithOptions(
  NativePlayer native,
  String url,
  Map<String, String> headers, {
  bool replace = false,
}) async {
  final value = headers.entries.map((e) => '${e.key}: ${e.value}').join(',');
  final options = 'http-header-fields=[$value]';
  final flag = replace ? 'replace' : 'append';
  final before = int.parse(await native.getProperty('playlist-count'));
  final expected = replace ? 1 : before + 1;
  await native.command(['loadfile', url, flag, '-1', options]);
  if (int.parse(await native.getProperty('playlist-count')) == expected) {
    return 'url flag index options';
  }
  await native.command(['loadfile', url, flag, options]);
  if (int.parse(await native.getProperty('playlist-count')) == expected) {
    return 'url flag options';
  }
  throw StateError('loadfile with per-file options failed for $url');
}

Future<void> _waitForAsync(
  Future<bool> Function() done,
  Duration timeout,
) async {
  final sw = Stopwatch()..start();
  while (!await done() && sw.elapsed < timeout) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<void> _waitFor(bool Function() done, Duration timeout) async {
  final sw = Stopwatch()..start();
  while (!done() && sw.elapsed < timeout) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _Sample {
  _Sample(
    this.wallUs,
    this.index,
    this.positionUs,
    this.mpvIndex,
    this.audioPtsUs,
    this.pausedForCache,
  );
  final int wallUs;

  /// `player.state.playlist.index` and `player.state.position`.
  final int index;
  final int positionUs;

  /// mpv's `playlist-playing-pos` and `audio-pts`, read in the same tick.
  final int? mpvIndex;
  final int? audioPtsUs;
  final bool pausedForCache;
}

/// Polls every 5 ms against a [Stopwatch]: `player.state` (position and
/// playlist index, the measurement the spike names) and mpv's `audio-pts`,
/// `playlist-playing-pos` and `paused-for-cache` (finer evidence: media_kit's
/// position follows `time-pos`, which mpv updates about every 100 ms, and
/// media_kit resets it to zero when a file starts). Also records
/// `stream.playlist` and `stream.buffering` events with their wall time.
class _Recorder {
  _Recorder(this.p);

  final _Players p;
  final Stopwatch _clock = Stopwatch();
  final List<_Sample> samples = [];
  final List<(int, int)> indexEvents = [];
  final List<(int, bool)> bufferingEvents = [];
  Timer? _timer;
  StreamSubscription<Playlist>? _playlistSub;
  StreamSubscription<bool>? _bufferingSub;

  int get elapsedUs => _clock.elapsedMicroseconds;

  void start() {
    _clock.start();
    _playlistSub = p.player.stream.playlist.listen(
      (pl) => indexEvents.add((elapsedUs, pl.index)),
    );
    _bufferingSub = p.player.stream.buffering.listen(
      (b) => bufferingEvents.add((elapsedUs, b)),
    );
    _timer = Timer.periodic(_pollInterval, (_) => _sample());
  }

  Future<void> _sample() async {
    final s = p.player.state;
    final wall = elapsedUs;
    final index = s.playlist.index;
    final position = s.position.inMicroseconds;
    try {
      final pos = int.tryParse(
        await p.native.getProperty('playlist-playing-pos'),
      );
      final pts = double.tryParse(await p.native.getProperty('audio-pts'));
      final pfc = await p.native.getProperty('paused-for-cache');
      samples.add(
        _Sample(
          wall,
          index,
          position,
          pos,
          pts == null ? null : (pts * 1e6).round(),
          pfc == 'yes',
        ),
      );
    } on Object {
      // The player was disposed between ticks.
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await _playlistSub?.cancel();
    await _bufferingSub?.cancel();
  }

  /// Distinct index changes reported by `stream.playlist`, in order.
  List<int> get indexChanges {
    final out = <int>[];
    int? previous;
    for (final e in indexEvents) {
      if (previous != null && e.$2 != previous) out.add(e.$2);
      previous = e.$2;
    }
    return out;
  }

  /// Largest `wallClockDelta - timelineDelta` (ms) between consecutive usable
  /// samples whose wall time lies in [fromUs, toUs], for the media_kit
  /// position (`gapMs`) and for mpv's `audio-pts` (`ptsGapMs`).
  ///
  /// media_kit timeline: `index × 3 s + position`. A sample whose index has
  /// advanced but whose position is still the previous item's (past half an
  /// item) or the zero media_kit writes when a file starts is skipped
  /// (`staleSamples`): it carries no position of the new item yet. The new
  /// item's first real position is negative (mpv subtracts the previous
  /// item's audio still buffered) or close to zero. mpv timeline:
  /// `playlist-playing-pos × 3 s + audio-pts`.
  Map<String, Object> windowResult(int fromUs, int toUs) {
    final window = samples
        .where((s) => s.wallUs >= fromUs && s.wallUs <= toUs)
        .toList();
    var gapUs = 0;
    var ptsGapUs = 0;
    var stale = 0;
    _Sample? anchor;
    _Sample? ptsAnchor;
    for (final b in window) {
      final a = anchor;
      if (a == null || (a.index == 0 && a.positionUs <= 0)) {
        anchor = b;
      } else if (b.index > a.index &&
          (b.positionUs == 0 || b.positionUs > _itemDurationUs ~/ 2)) {
        stale++;
      } else {
        final d =
            (b.wallUs - a.wallUs) -
            ((b.index - a.index) * _itemDurationUs +
                b.positionUs -
                a.positionUs);
        if (d > gapUs) gapUs = d;
        anchor = b;
      }
      if (b.mpvIndex == null || b.audioPtsUs == null) continue;
      final pa = ptsAnchor;
      if (pa != null && (pa.mpvIndex! > 0 || pa.audioPtsUs! > 0)) {
        final d =
            (b.wallUs - pa.wallUs) -
            ((b.mpvIndex! - pa.mpvIndex!) * _itemDurationUs +
                b.audioPtsUs! -
                pa.audioPtsUs!);
        if (d > ptsGapUs) ptsGapUs = d;
      }
      ptsAnchor = b;
    }
    return {
      'gapMs': gapUs / 1000,
      'ptsGapMs': ptsGapUs / 1000,
      'staleSamples': stale,
      'pausedForCache': window.any((s) => s.pausedForCache),
      'samples': window.length,
    };
  }

  /// The question-1 measurement around the transition `from -> from + 1`.
  Map<String, Object?> transitionResult(int from) {
    final first = samples.indexWhere((s) => s.index == from + 1);
    final played = samples.any((s) => s.positionUs > 0);
    final changes = indexChanges;
    if (first <= 0) {
      return {
        'played': played,
        'indexChanges': changes.join(','),
        'samples': samples.length,
        'pass': false,
      };
    }
    final at = samples[first].wallUs;
    final window = windowResult(at - 500000, at + 500000);
    final gapMs = window['gapMs']! as double;
    final pausedForCache = window['pausedForCache']! as bool;
    // media_kit sets `buffering` true on every MPV_EVENT_START_FILE, gapless
    // or not, so its events are reported but mpv's own `paused-for-cache`
    // decides whether playback waited for data.
    final mediaKitBuffering = bufferingEvents
        .where((e) => e.$1 >= at - 500000 && e.$1 <= at + 500000 && e.$2)
        .length;
    return {
      'played': played,
      'indexChanges': changes.join(','),
      'gapMs': gapMs,
      'ptsGapMs': window['ptsGapMs'],
      'staleSamples': window['staleSamples'],
      'pausedForCache': pausedForCache,
      'mediaKitBufferingEvents': mediaKitBuffering,
      'samples': window['samples'],
      'pass':
          (from > 0 || changes.join(',') == '1') &&
          !pausedForCache &&
          gapMs <= 20,
    };
  }
}

class _Request {
  _Request(this.path, this.apiKey, this.item, this.range);
  final String path;
  final String? apiKey;
  final String? item;
  final String? range;
}

/// Serves the three FLAC files with Range support on 127.0.0.1, rejects any
/// request without `X-API-Key: spike` with 401, and records every request.
class _SpikeServer {
  _SpikeServer._(this._server, this._files);

  final HttpServer _server;
  final Map<String, Uint8List> _files;
  final List<_Request> requests = [];
  int unauthorized = 0;

  static Future<_SpikeServer> start() async {
    final files = <String, Uint8List>{};
    for (final name in ['a', 'b', 'c']) {
      final data = await rootBundle.load('assets/$name.flac');
      files['/$name.flac'] = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final spike = _SpikeServer._(server, files);
    server.listen(spike._handle);
    return spike;
  }

  void clear() {
    requests.clear();
    unauthorized = 0;
  }

  String url(String name, {String? query}) =>
      'http://127.0.0.1:${_server.port}/$name.flac${query == null ? '' : '?$query'}';

  Media media(
    String name, {
    String key = _apiKey,
    Map<String, String> extra = const {},
    String? query,
  }) =>
      Media(url(name, query: query), httpHeaders: {'X-API-Key': key, ...extra});

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    final key = req.headers.value('x-api-key');
    final range = req.headers.value(HttpHeaders.rangeHeader);
    requests.add(
      _Request(req.uri.path, key, req.headers.value('x-item'), range),
    );
    final res = req.response;
    try {
      if (key != _apiKey) {
        unauthorized++;
        res.statusCode = HttpStatus.unauthorized;
        return;
      }
      final body = _files[req.uri.path];
      if (body == null) {
        res.statusCode = HttpStatus.notFound;
        return;
      }
      res.headers
        ..contentType = ContentType('audio', 'flac')
        ..set(HttpHeaders.acceptRangesHeader, 'bytes');
      var start = 0;
      var end = body.length - 1;
      final match = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(range ?? '');
      if (match != null) {
        final s = match.group(1)!;
        final e = match.group(2)!;
        if (s.isEmpty && e.isNotEmpty) {
          start = body.length - int.parse(e);
        } else {
          start = int.parse(s);
          if (e.isNotEmpty) end = int.parse(e).clamp(0, body.length - 1);
        }
        if (start >= body.length || start > end) {
          res
            ..statusCode = HttpStatus.requestedRangeNotSatisfiable
            ..headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes */${body.length}',
            );
          return;
        }
        res
          ..statusCode = HttpStatus.partialContent
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-$end/${body.length}',
          );
      }
      res.contentLength = end - start + 1;
      if (req.method != 'HEAD') res.add(body.sublist(start, end + 1));
    } finally {
      await res.close();
    }
  }
}
