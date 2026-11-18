// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The parts of the device engine harness shared by native targets and the
/// web: sources on the tone server, real time and the platform engine.
library;

import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/platform/player_engine/player_engine_factory.dart';

import 'engine_conformance.dart';
import 'tone_server.dart' show ToneServer;

/// Runs the conformance suite against the platform's real engine, built by
/// `createPlayerEngine()`, with tones from a [ToneServer] at [baseUrl] and
/// real time for `elapse`.
abstract class DeviceEngineHarnessBase implements EngineHarness {
  /// Creates a harness whose source paths are unique to it.
  new(this.baseUrl) : _prefix = 'h${_count++}';

  static int _count = 0;

  /// The tone server address.
  final Uri baseUrl;

  final String _prefix;
  final Stopwatch _clock = Stopwatch()..start();
  final List<PlayerEngine> _engines = [];
  final Set<PlayerEngine> _closed = {};
  final Map<String, String> _paths = {};

  /// Whether credentials travel as the `token` query value (web) instead of
  /// the [ToneServer.keyHeader] header.
  bool get credentialsInQuery;

  /// The server path of the last source made for [queueItemId].
  String pathOf(String queueItemId) => _paths[queueItemId]!;

  /// A source for [queueItemId] at `/<kind>/<unique name>.wav`.
  EngineSource source(
    String queueItemId,
    String kind, {
    Duration? duration,
    Duration startAt = Duration.zero,
  }) {
    final path = '/$kind/$_prefix-$queueItemId.wav';
    _paths[queueItemId] = path;
    final query = {
      'ms': ?duration?.inMilliseconds.toString(),
      if (credentialsInQuery) 'token': ToneServer.key,
    };
    return EngineSource(
      queueItemId: queueItemId,
      uri: baseUrl.replace(
        path: path,
        queryParameters: query.isEmpty ? null : query,
      ),
      headers: credentialsInQuery
          ? const {}
          : const {ToneServer.keyHeader: ToneServer.key},
      startAt: startAt,
    );
  }

  /// Builds the engine under test: the platform's `createPlayerEngine()`.
  PlayerEngine buildEngine() => createPlayerEngine();

  @override
  PlayerEngine createEngine() {
    final engine = buildEngine();
    _engines.add(engine);
    engine.state.listen(null, onDone: () => _closed.add(engine));
    return engine;
  }

  @override
  EngineSource tone(
    String queueItemId, {
    Duration? duration,
    Duration startAt = Duration.zero,
  }) => source(queueItemId, 'tone', duration: duration, startAt: startAt);

  @override
  EngineSource slowTone(String queueItemId) => source(queueItemId, 'slow');

  @override
  EngineSource missing(String queueItemId) => source(queueItemId, 'missing');

  @override
  EngineSource forbidden(String queueItemId) =>
      source(queueItemId, 'unauthorized');

  @override
  Map<String, String> credentialsOf(EngineSource source) => credentialsInQuery
      ? {'token': ?source.uri.queryParameters['token']}
      : source.headers;

  @override
  Future<void> elapse(Duration d) => Future<void>.delayed(d);

  @override
  Duration get now => _clock.elapsed;

  @override
  Future<void> dispose() async {
    // An engine whose state stream closed was disposed by the test.
    for (final engine in _engines.where((e) => !_closed.contains(e))) {
      await engine.dispose();
    }
  }
}
