// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

// Spike S1 harness (docs/designs/flutter-client/13-milestones-and-work-breakdown.md,
// Spikes, row S1). Each case runs five times and prints one machine-readable
// `S1RESULT {json}` line per run; the workflow turns those lines into the
// job summary. The cases fail only on harness errors, never on a "no" answer.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

const _runs = 5;
const _apiKey = 'spike';
const _itemDuration = Duration(seconds: 3);
const _pollInterval = Duration(milliseconds: 5);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _SpikeServer server;

  setUpAll(() async {
    server = await _SpikeServer.start();
  });

  tearDownAll(() async {
    await server.close();
  });

  testWidgets('gapless_two_items', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final player = _newPlayer();
      try {
        await player.setAudioSources([
          server.source('a', _apiKey),
          server.source('b', _apiKey),
        ]);
        final rec = _Recorder(player)..start();
        unawaited(player.play());
        await _waitFor(
          () => player.processingState == ProcessingState.completed,
          const Duration(seconds: 20),
        );
        await rec.stop();
        _emit('gapless_two_items', run, rec.transitionResult());
      } on Object catch (e) {
        _emit('gapless_two_items', run, {'error': e.toString()});
      } finally {
        await player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('headers_on_every_request', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final player = _newPlayer();
      try {
        await player.setAudioSources([
          server.source('a', _apiKey),
          server.source('b', _apiKey),
        ]);
        unawaited(player.play());
        await _waitFor(
          () => player.processingState == ProcessingState.completed,
          const Duration(seconds: 20),
        );
        final requests = server.requests
            .where((r) => r.path == '/a.flac' || r.path == '/b.flac')
            .toList();
        _emit('headers_on_every_request', run, {
          'completed': player.processingState == ProcessingState.completed,
          'requests': requests.length,
          'rangeRequests': requests.where((r) => r.range != null).length,
          'withKey': requests.where((r) => r.apiKey == _apiKey).length,
          'paths': requests.map((r) => r.path).toSet().toList()..sort(),
          'unauthorized': server.unauthorized,
          'pass':
              requests.isNotEmpty &&
              requests.every((r) => r.apiKey == _apiKey) &&
              requests.any((r) => r.path == '/a.flac') &&
              requests.any((r) => r.path == '/b.flac'),
        });
      } on Object catch (e) {
        _emit('headers_on_every_request', run, {'error': e.toString()});
      } finally {
        await player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('wrong_key_fails', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final player = _newPlayer();
      final errors = <String>[];
      final sub = player.errorStream.listen(
        (e) => errors.add('errorStream: $e'),
      );
      final eventSub = player.playbackEventStream.listen(
        (_) {},
        onError: (Object e, StackTrace _) => errors.add('playbackEvent: $e'),
      );
      try {
        try {
          await player
              .setAudioSources([server.source('a', 'wrong')])
              .timeout(const Duration(seconds: 15));
          unawaited(player.play());
          await _waitFor(() => errors.isNotEmpty, const Duration(seconds: 10));
        } on PlayerException catch (e) {
          errors.add('PlayerException(code: ${e.code}, message: ${e.message})');
        } on TimeoutException catch (e) {
          errors.add('timeout: $e');
        }
        final played = player.position > Duration.zero;
        _emit('wrong_key_fails', run, {
          'errors': errors,
          'unauthorized': server.unauthorized,
          'positionMs': player.position.inMilliseconds,
          'pass':
              errors.any((e) => !e.startsWith('timeout')) &&
              !played &&
              server.unauthorized > 0,
        });
      } on Object catch (e) {
        _emit('wrong_key_fails', run, {'error': e.toString()});
      } finally {
        await sub.cancel();
        await eventSub.cancel();
        await player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('replace_next_while_playing', (tester) async {
    for (var run = 1; run <= _runs; run++) {
      server.clear();
      final player = _newPlayer();
      try {
        await player.setAudioSources([
          server.source('a', _apiKey),
          server.source('b', _apiKey),
        ]);
        final rec = _Recorder(player)..start();
        unawaited(player.play());
        await _waitFor(
          () => player.position >= const Duration(milliseconds: 1000),
          const Duration(seconds: 10),
        );
        final replaceStart = rec.elapsedUs;
        await player.removeAudioSourceAt(1);
        await player.addAudioSource(server.source('c', _apiKey));
        final replaceEnd = rec.elapsedUs;
        await _waitFor(
          () => player.processingState == ProcessingState.completed,
          const Duration(seconds: 20),
        );
        await rec.stop();
        final transition = rec.transitionResult();
        final replacement = rec.windowResult(
          replaceStart - 250000,
          replaceEnd + 250000,
        );
        final nextTag = rec.tagAfterFirstIndexChange;
        _emit('replace_next_while_playing', run, {
          'replaceMs': (replaceEnd - replaceStart) / 1000,
          'replacementGapMs': replacement['gapMs'],
          'replacementStateChanges': replacement['stateChanges'],
          'nextTag': nextTag,
          'cRequested': server.requests.any((r) => r.path == '/c.flac'),
          'transition': transition,
          'pass':
              (replacement['gapMs']! as num) <= 20 &&
              (replacement['stateChanges']! as int) == 0 &&
              nextTag == 'c' &&
              (transition['indexChanges']! as List).join(',') == '0->1',
        });
      } on Object catch (e) {
        _emit('replace_next_while_playing', run, {'error': e.toString()});
      } finally {
        await player.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

/// The player as doc 06 configures it for `JustAudioEngine`.
AudioPlayer _newPlayer() => AudioPlayer(
  handleInterruptions: false,
  androidApplyAudioAttributes: true,
  audioLoadConfiguration: const AudioLoadConfiguration(
    androidLoadControl: AndroidLoadControl(
      minBufferDuration: Duration(seconds: 30),
      maxBufferDuration: Duration(seconds: 120),
    ),
  ),
);

void _emit(String testCase, int run, Map<String, Object?> data) {
  final platform = Platform.operatingSystem;
  // The workflow greps these lines; `print` is the only channel from the device.
  // ignore: avoid_print
  print(
    'S1RESULT ${jsonEncode({'case': testCase, 'platform': platform, 'run': run, ...data})}',
  );
}

Future<void> _waitFor(bool Function() done, Duration timeout) async {
  final sw = Stopwatch()..start();
  while (!done() && sw.elapsed < timeout) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

class _Sample {
  _Sample(this.wallUs, this.index, this.positionUs, this.state, this.tag);
  final int wallUs;
  final int? index;
  final int positionUs;
  final ProcessingState state;
  final Object? tag;
}

/// Polls position and index every 5 ms against a [Stopwatch] and records
/// processing-state and index events with their wall-clock time.
class _Recorder {
  _Recorder(this.player);

  final AudioPlayer player;
  final Stopwatch _clock = Stopwatch();
  final List<_Sample> samples = [];
  final List<(int, ProcessingState)> stateEvents = [];
  final List<(int, int?)> indexEvents = [];
  Timer? _timer;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<int?>? _indexSub;
  int durationAUs = _itemDuration.inMicroseconds;

  int get elapsedUs => _clock.elapsedMicroseconds;

  void start() {
    _clock.start();
    _stateSub = player.playerStateStream.listen(
      (s) => stateEvents.add((elapsedUs, s.processingState)),
    );
    _indexSub = player.currentIndexStream.listen(
      (i) => indexEvents.add((elapsedUs, i)),
    );
    _timer = Timer.periodic(_pollInterval, (_) {
      final index = player.currentIndex;
      if (index == 0 && player.duration != null) {
        durationAUs = player.duration!.inMicroseconds;
      }
      samples.add(
        _Sample(
          elapsedUs,
          index,
          player.position.inMicroseconds,
          player.processingState,
          player.sequenceState.currentSource?.tag,
        ),
      );
    });
  }

  Future<void> stop() async {
    _timer?.cancel();
    await _stateSub?.cancel();
    await _indexSub?.cancel();
  }

  int _timeline(_Sample s) => (s.index ?? 0) * durationAUs + s.positionUs;

  bool _started(_Sample s) => (s.index ?? 0) > 0 || s.positionUs > 0;

  bool _stale(_Sample s) =>
      (s.index ?? 0) > 0 && s.positionUs >= durationAUs - 100000;

  /// Largest `wallClockDelta - timelineDelta` (ms) between consecutive
  /// samples whose wall time lies in [fromUs, toUs], and the number of
  /// processing-state events in that window.
  Map<String, Object> windowResult(int fromUs, int toUs) {
    var gapUs = 0;
    final window = samples
        .where((s) => s.wallUs >= fromUs && s.wallUs <= toUs)
        .toList();
    var rawGapUs = 0;
    var stale = 0;
    _Sample? a;
    for (var i = 1; i < window.length; i++) {
      final prev = window[i - 1];
      final b = window[i];
      // Before playback first advances and after completion, wall time
      // passes without timeline by design; every other stall counts.
      if (!_started(prev) || b.state == ProcessingState.completed) {
        a = b;
        continue;
      }
      final raw = (b.wallUs - prev.wallUs) - (_timeline(b) - _timeline(prev));
      if (raw > rawGapUs) rawGapUs = raw;
      // A sample that already reports the next index but still carries the
      // previous item's end position is skipped: the plugin delivered the
      // index change before the position reset.
      if (_stale(b)) {
        stale++;
        continue;
      }
      final from = a ?? prev;
      a = b;
      final d = (b.wallUs - from.wallUs) - (_timeline(b) - _timeline(from));
      if (d > gapUs) gapUs = d;
    }
    final stateChanges = stateEvents
        .where((e) => e.$1 >= fromUs && e.$1 <= toUs)
        .length;
    return {
      'gapMs': gapUs / 1000,
      'rawGapMs': rawGapUs / 1000,
      'staleSamples': stale,
      'stateChanges': stateChanges,
      'samples': window.length,
    };
  }

  Object? get tagAfterFirstIndexChange {
    final first = samples.firstWhere(
      (s) => s.index == 1,
      orElse: () => _Sample(0, null, 0, ProcessingState.idle, null),
    );
    return first.tag;
  }

  /// The question-1 measurement around the 0 → 1 transition.
  Map<String, Object?> transitionResult() {
    final changes = <String>[];
    int? previous;
    for (final e in indexEvents) {
      if (e.$2 != previous) {
        if (previous != null) changes.add('$previous->${e.$2}');
        previous = e.$2;
      }
    }
    final firstB = samples.indexWhere((s) => s.index == 1 && !_stale(s));
    final played = samples.any((s) => s.positionUs > 0);
    if (firstB <= 0) {
      return {
        'played': played,
        'indexChanges': changes,
        'samples': samples.length,
        'pass': false,
      };
    }
    final lastA = samples.lastWhere(
      (s) => s.wallUs < samples[firstB].wallUs && (s.index ?? 0) == 0,
      orElse: () => samples[firstB - 1],
    );
    final firstBSample = samples[firstB];
    final notReadyBetween =
        lastA.state != ProcessingState.ready ||
        firstBSample.state != ProcessingState.ready ||
        stateEvents.any(
          (e) =>
              e.$1 >= lastA.wallUs &&
              e.$1 <= firstBSample.wallUs &&
              e.$2 != ProcessingState.ready,
        );
    final window = windowResult(
      firstBSample.wallUs - 500000,
      firstBSample.wallUs + 500000,
    );
    final gapMs = window['gapMs']! as double;
    return {
      'played': played,
      'indexChanges': changes,
      'gapMs': gapMs,
      'rawGapMs': window['rawGapMs'],
      'staleSamples': window['staleSamples'],
      'leftReady': notReadyBetween,
      'durationAMs': durationAUs / 1000,
      'lastAPositionMs': lastA.positionUs / 1000,
      'firstBPositionMs': firstBSample.positionUs / 1000,
      'samples': samples.length,
      'pass':
          changes.length == 1 &&
          changes.single == '0->1' &&
          !notReadyBetween &&
          gapMs <= 20,
    };
  }
}

class _Request {
  _Request(this.path, this.apiKey, this.range);
  final String path;
  final String? apiKey;
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

  AudioSource source(String name, String key) => AudioSource.uri(
    Uri.parse('http://127.0.0.1:${_server.port}/$name.flac'),
    headers: {'X-API-Key': key},
    tag: name,
  );

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest req) async {
    final key = req.headers.value('x-api-key');
    final range = req.headers.value(HttpHeaders.rangeHeader);
    requests.add(_Request(req.uri.path, key, range));
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
