// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';

import '../engine_conformance.dart';

void main() {
  runEngineConformance('FakeEngine', FakeEngineHarness.new);
}

/// Runs the conformance suite on virtual time against [FakeEngine]: sources
/// are scripted by URI and the "server" is the engine's request log.
final class FakeEngineHarness implements EngineHarness {
  static const _key = {'Authorization': 'Bearer conformance'};
  static const _toneLength = Duration(seconds: 3);

  final Map<Uri, FakeSource> _sources = {};
  final List<FakeEngine> _engines = [];
  Duration _now = Duration.zero;
  bool _networkDisabled = false;

  @override
  PlayerEngine createEngine() {
    final engine = FakeEngine(sources: _sources)
      ..networkAvailable = !_networkDisabled;
    _engines.add(engine);
    return engine;
  }

  Uri _served(String id) => Uri.parse('https://music.test/stream/$id');

  @override
  EngineSource tone(
    String queueItemId, {
    Duration? duration,
    Duration startAt = Duration.zero,
  }) {
    final uri = _served(queueItemId);
    _sources[uri] = FakeSource(
      duration: duration ?? _toneLength,
      requiredHeaders: _key,
    );
    return EngineSource(
      queueItemId: queueItemId,
      uri: uri,
      headers: _key,
      startAt: startAt,
    );
  }

  @override
  EngineSource slowTone(String queueItemId) {
    final uri = _served(queueItemId);
    _sources[uri] = const FakeSource(
      duration: Duration(seconds: 60),
      bufferedAhead: Duration(seconds: 5),
      requiredHeaders: _key,
    );
    return EngineSource(queueItemId: queueItemId, uri: uri, headers: _key);
  }

  @override
  EngineSource missing(String queueItemId) {
    final uri = _served(queueItemId);
    _sources[uri] = const FakeSource(
      duration: _toneLength,
      failure: EngineError(EngineErrorKind.notFound, httpStatus: 404),
    );
    return EngineSource(queueItemId: queueItemId, uri: uri, headers: _key);
  }

  @override
  EngineSource forbidden(String queueItemId) {
    final uri = _served(queueItemId);
    _sources[uri] = const FakeSource(
      duration: _toneLength,
      requiredHeaders: {'Authorization': 'Bearer someone-else'},
    );
    return EngineSource(queueItemId: queueItemId, uri: uri, headers: _key);
  }

  @override
  EngineSource localFile(String queueItemId) {
    final uri = Uri.file('/downloads/$queueItemId.flac');
    _sources[uri] = const FakeSource(duration: _toneLength);
    return EngineSource(queueItemId: queueItemId, uri: uri);
  }

  @override
  Map<String, String> headersSeenFor(String queueItemId) => _engines
      .expand((e) => e.requested)
      .lastWhere((s) => s.queueItemId == queueItemId)
      .headers;

  @override
  Future<void> disableNetwork() async {
    _networkDisabled = true;
    for (final e in _engines.where((e) => !e.isDisposed)) {
      e.networkAvailable = false;
    }
  }

  @override
  Future<void> elapse(Duration d) async {
    for (final e in _engines.where((e) => !e.isDisposed)) {
      e.advance(d);
    }
    _now += d;
    await pumpEventQueue();
  }

  @override
  Duration get now => _now;

  @override
  Duration get gapTolerance => const Duration(milliseconds: 20);

  @override
  Set<ConformanceCase> get skipped => const {};

  @override
  Future<void> dispose() async {
    for (final e in _engines.where((e) => !e.isDisposed)) {
      await e.dispose();
    }
  }
}
