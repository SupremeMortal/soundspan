// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/probe/probe_failure.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'probe_fakes.dart';

const _health = {'status': 'ok', 'version': '2.6.1'};

/// Runs [address] through a probe over [client] and [sessions] on fake
/// time, and returns every state it emitted.
List<ProbeState> _run(
  String address,
  FakeProbeClient client, {
  FakeProbeSessions? sessions,
  bool isWeb = false,
}) {
  final states = <ProbeState>[];
  fakeAsync((async) {
    final clock = FakeAsyncClock(async);
    client.timeSource = clock;
    final probe = ServerProbe(
      client: () => client,
      session: (sessions ?? FakeProbeSessions()).call,
      clock: clock,
      isWeb: isWeb,
    );
    probe.run(ServerAddress.parse(address)).listen(states.add);
    async.elapse(const Duration(minutes: 2));
  });
  return states;
}

T _last<T extends ProbeState>(List<ProbeState> states) => states.last as T;

void main() {
  group('candidates', () {
    test('first candidate ready stops the run', () {
      final client = FakeProbeClient({
        'http://nas.local/api/health': [ok(_health)],
      });
      final states = _run('nas.local', client);
      expect(states.first, isA<ProbeResolving>());
      final result = _last<ProbeReady>(states).result;
      expect(result.baseUrl, Uri.parse('http://nas.local'));
      expect(result.baseChanged, isFalse);
      expect(result.isCleartext, isTrue);
      expect(result.isPrivateHost, isTrue);
      expect(client.requested, ['http://nas.local/api/health']);
      expect(client.closed, isTrue);
    });

    test('http refused then https ready', () {
      final client = FakeProbeClient({
        'http://nas.local/api/health': [
          refused(TransportFailure.connectionRefused),
        ],
        'https://nas.local/api/health': [ok(_health)],
      });
      final states = _run('nas.local', client);
      expect(
        states
            .whereType<ProbeResolving>()
            .map((s) => s.candidate.toString())
            .toList(),
        ['http://nas.local', 'https://nas.local'],
      );
      final result = _last<ProbeReady>(states).result;
      expect(result.baseUrl, Uri.parse('https://nas.local'));
      expect(result.isCleartext, isFalse);
    });

    test('all candidates fail reports the failure that got an HTTP '
        'response', () {
      final client = FakeProbeClient({
        'http://nas.local/api/health': [
          refused(TransportFailure.connectionRefused),
        ],
        'https://nas.local/api/health': [reply(404)],
      });
      final failure = _last<ProbeFailed>(_run('nas.local', client)).failure;
      expect(failure.failureClass, ProbeFailureClass.notSoundspan);
      expect(failure.candidate, Uri.parse('https://nas.local'));
      expect(failure.status, 404);
    });

    test('all candidates fail without a response reports the first', () {
      final client = FakeProbeClient({
        'http://nas.local/api/health': [
          refused(TransportFailure.connectionRefused),
        ],
        'https://nas.local/api/health': [refused(TransportFailure.timeout)],
      });
      final failure = _last<ProbeFailed>(_run('nas.local', client)).failure;
      expect(failure.failureClass, ProbeFailureClass.refused);
      expect(failure.candidate, Uri.parse('http://nas.local'));
      expect(failure.status, isNull);
    });

    test('a transport failure on web is corsOrNetwork', () {
      final client = FakeProbeClient({
        'https://music.example.com/api/health': [
          refused(TransportFailure.connection),
        ],
      });
      final failure = _last<ProbeFailed>(
        _run('music.example.com', client, isWeb: true),
      ).failure;
      expect(failure.failureClass, ProbeFailureClass.corsOrNetwork);
    });
  });

  group('redirects', () {
    test('301 to another host is followed and baseChanged is true', () {
      final client = FakeProbeClient({
        'https://old.example.com/api/health': [
          redirect(301, 'https://new.example.com/api/health'),
        ],
        'https://new.example.com/api/health': [ok(_health)],
      });
      final sessions = FakeProbeSessions();
      final result = _last<ProbeReady>(
        _run('old.example.com', client, sessions: sessions),
      ).result;
      expect(result.baseUrl, Uri.parse('https://new.example.com'));
      expect(result.requestedBaseUrl, Uri.parse('https://old.example.com'));
      expect(result.baseChanged, isTrue);
      expect(sessions.bases, [Uri.parse('https://new.example.com')]);
    });

    test('path prefix is preserved through a redirect', () {
      final client = FakeProbeClient({
        'https://example.com/music/api/health': [
          redirect(308, 'https://example.com/soundspan/api/health'),
        ],
        'https://example.com/soundspan/api/health': [ok(_health)],
      });
      final result = _last<ProbeReady>(
        _run('https://example.com/music', client),
      ).result;
      expect(result.baseUrl, Uri.parse('https://example.com/soundspan'));
      expect(result.baseChanged, isTrue);
    });

    test('fourth hop is refused', () {
      final client = FakeProbeClient({
        'https://a.example.com/api/health': [
          redirect(302, 'https://b.example.com/api/health'),
        ],
        'https://b.example.com/api/health': [
          redirect(307, 'https://c.example.com/api/health'),
        ],
        'https://c.example.com/api/health': [
          redirect(301, 'https://d.example.com/api/health'),
        ],
        'https://d.example.com/api/health': [
          redirect(301, 'https://e.example.com/api/health'),
        ],
        'https://e.example.com/api/health': [ok(_health)],
      });
      final failure = _last<ProbeFailed>(_run('a.example.com', client)).failure;
      expect(failure.failureClass, ProbeFailureClass.redirectRefused);
      expect(failure.status, 301);
      expect(
        client.requested,
        isNot(contains(endsWith('e.example.com/api/health'))),
      );
    });

    test('three hops are followed', () {
      final client = FakeProbeClient({
        'https://a.example.com/api/health': [
          redirect(302, 'https://b.example.com/api/health'),
        ],
        'https://b.example.com/api/health': [
          redirect(307, 'https://c.example.com/api/health'),
        ],
        'https://c.example.com/api/health': [
          redirect(301, 'https://d.example.com/api/health'),
        ],
        'https://d.example.com/api/health': [ok(_health)],
      });
      final result = _last<ProbeReady>(_run('a.example.com', client)).result;
      expect(result.baseUrl, Uri.parse('https://d.example.com'));
    });

    test('https to http is refused', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [
          redirect(301, 'http://example.com/api/health'),
        ],
        'http://example.com/api/health': [ok(_health)],
      });
      final failure = _last<ProbeFailed>(_run('example.com', client)).failure;
      expect(failure.failureClass, ProbeFailureClass.redirectRefused);
      expect(client.requested, ['https://example.com/api/health']);
    });

    test('redirect to a non-http scheme is refused', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [
          redirect(302, 'ftp://example.com/api/health'),
        ],
      });
      final failure = _last<ProbeFailed>(_run('example.com', client)).failure;
      expect(failure.failureClass, ProbeFailureClass.redirectRefused);
    });

    test('final URL without /api/health is notSoundspan', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [
          redirect(302, 'https://example.com/login'),
        ],
        'https://example.com/login': [ok(_health)],
      });
      final failure = _last<ProbeFailed>(_run('example.com', client)).failure;
      expect(failure.failureClass, ProbeFailureClass.notSoundspan);
    });
  });

  group('starting', () {
    test('503 with a health body retries every 3 s and becomes ready', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [
          reply(503, {'status': 'starting'}),
          reply(503, {'status': 'starting'}),
          ok(_health),
        ],
      });
      final states = _run('example.com', client);
      final starting = states.whereType<ProbeStarting>().toList();
      expect(starting.map((s) => s.secondsLeft), [30, 27]);
      expect(starting.first.candidate, Uri.parse('https://example.com'));
      expect(client.times, [
        Duration.zero,
        const Duration(seconds: 3),
        const Duration(seconds: 6),
      ]);
      expect(states.last, isA<ProbeReady>());
    });

    test('still 503 after 30 s is serverError', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [
          for (var i = 0; i < 20; i++) reply(503, {'status': 'starting'}),
        ],
      });
      final states = _run('example.com', client);
      final failure = _last<ProbeFailed>(states).failure;
      expect(failure.failureClass, ProbeFailureClass.serverError);
      expect(failure.status, 503);
      expect(client.times.last, const Duration(seconds: 30));
      expect(client.times, hasLength(11));
    });
  });

  group('auth config and onboarding', () {
    test('hasAccount false yields needsSetup', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [ok(_health)],
      });
      final sessions = FakeProbeSessions(hasAccount: false);
      final states = _run('example.com', client, sessions: sessions);
      expect(states.last, isA<ProbeNeedsSetup>());
      expect(sessions.closed, 1);
    });

    test('auth config fields reach ProbeResult', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [ok(_health)],
      });
      final sessions = FakeProbeSessions(
        config: const AuthConfig(
          localLoginEnabled: false,
          oidcEnabled: true,
          oidcProviderName: 'Authentik',
        ),
      );
      final result = _last<ProbeReady>(
        _run('example.com', client, sessions: sessions),
      ).result;
      expect(result.localLoginEnabled, isFalse);
      expect(result.oidcEnabled, isTrue);
      expect(result.oidcProviderName, 'Authentik');
      expect(result.healthVersion, '2.6.1');
      expect(result.isPrivateHost, isFalse);
    });

    test('healthVersion unknown is null', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [
          ok({'status': 'ok', 'version': 'unknown'}),
        ],
        'https://other.example.com/api/health': [
          ok({'status': 'ok'}),
        ],
      });
      expect(
        _last<ProbeReady>(_run('example.com', client)).result.healthVersion,
        isNull,
      );
      expect(
        _last<ProbeReady>(_run('other.example.com', client))
            .result
            .healthVersion,
        isNull,
      );
    });

    test('auth/config 403 is blockedByProxy', () {
      final client = FakeProbeClient({
        'https://example.com/api/health': [ok(_health)],
      });
      final sessions = FakeProbeSessions(
        configError: const Forbidden(status: 403),
      );
      final failure = _last<ProbeFailed>(
        _run('example.com', client, sessions: sessions),
      ).failure;
      expect(failure.failureClass, ProbeFailureClass.blockedByProxy);
      expect(failure.status, 403);
      expect(sessions.closed, 1);
    });

    test('auth/config errors map by exception type', () {
      final cases = <ApiException, (bool, ProbeFailureClass)>{
        const Unauthenticated(status: 401): (
          false,
          ProbeFailureClass.blockedByProxy,
        ),
        const ServerError(status: 500): (false, ProbeFailureClass.serverError),
        const Upstream(status: 502): (false, ProbeFailureClass.serverError),
        const Offline(): (false, ProbeFailureClass.timeout),
        const NotFound(status: 404): (false, ProbeFailureClass.notSoundspan),
        const InvalidResponse(status: 200): (
          false,
          ProbeFailureClass.notSoundspan,
        ),
      };
      for (final MapEntry(key: error, value: (isWeb, expected))
          in cases.entries) {
        final client = FakeProbeClient({
          'https://example.com/api/health': [ok(_health)],
        });
        final failure = _last<ProbeFailed>(
          _run(
            'example.com',
            client,
            sessions: FakeProbeSessions(onboardingError: error),
            isWeb: isWeb,
          ),
        ).failure;
        expect(failure.failureClass, expected, reason: '$error');
      }
      final client = FakeProbeClient({
        'https://example.com/api/health': [ok(_health)],
      });
      final failure = _last<ProbeFailed>(
        _run(
          'example.com',
          client,
          sessions: FakeProbeSessions(configError: const Offline()),
          isWeb: true,
        ),
      ).failure;
      expect(failure.failureClass, ProbeFailureClass.corsOrNetwork);
    });

    test('the link code is carried into the result and into a failure', () {
      const link = 'soundspan://link?server=example.com&code=ABC234';
      final good = FakeProbeClient({
        'https://example.com/api/health': [ok(_health)],
      });
      expect(_last<ProbeReady>(_run(link, good)).result.linkCode, 'ABC234');

      final bad = FakeProbeClient({
        'https://example.com/api/health': [reply(404)],
      });
      final failure = _last<ProbeFailed>(_run(link, bad)).failure;
      expect(failure.linkCode, 'ABC234');
    });
  });

  test('cancelling the subscription stops pending retries', () {
    final client = FakeProbeClient({
      'https://example.com/api/health': [
        for (var i = 0; i < 20; i++) reply(503, {'status': 'starting'}),
      ],
    });
    fakeAsync((async) {
      final clock = FakeAsyncClock(async);
      client.timeSource = clock;
      final probe = ServerProbe(
        client: () => client,
        session: FakeProbeSessions().call,
        clock: clock,
        isWeb: false,
      );
      final sub = probe.run(ServerAddress.parse('example.com')).listen((_) {});
      async.elapse(const Duration(seconds: 4));
      unawaited(sub.cancel());
      async.elapse(const Duration(minutes: 1));
      expect(client.times, hasLength(2));
      expect(client.closed, isTrue);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('FakeAsyncClock reads fake time', () {
    fakeAsync((async) {
      final Clock clock = FakeAsyncClock(async);
      final start = clock.now();
      async.elapse(const Duration(seconds: 3));
      expect(clock.now().difference(start), const Duration(seconds: 3));
    });
  });
}
