// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/shared/clock.dart';

import '../../core/auth/probe/probe_fakes.dart';

const _starting = {'status': 'starting'};
const _health = {'status': 'ok'};

/// Runs [body] on fake time with a container whose probe uses [client].
void _withController(
  FakeProbeClient client,
  void Function(FakeAsync async, ProviderContainer container) body,
) {
  fakeAsync((async) {
    final clock = FakeAsyncClock(async);
    client.timeSource = clock;
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        probeIsWebProvider.overrideWithValue(false),
        probeClientFactoryProvider.overrideWithValue(() => client),
        probeSessionFactoryProvider.overrideWithValue(FakeProbeSessions().call),
      ],
    )..listen(probeControllerProvider, (_, _) {});
    body(async, container);
    container.dispose();
    async.flushMicrotasks();
  });
}

ProbeController _controller(ProviderContainer container) =>
    container.read(probeControllerProvider.notifier);

ProbeState? _state(ProviderContainer container) =>
    container.read(probeControllerProvider).value;

void main() {
  test('start then start cancels the first run', () {
    final client = FakeProbeClient({
      'https://slow.example.com/api/health': [reply(503, _starting)],
      'https://fast.example.com/api/health': [ok(_health)],
    });
    _withController(client, (async, container) {
      _controller(container).start(ServerAddress.parse('slow.example.com'));
      async.elapse(const Duration(seconds: 1));
      expect(_state(container), isA<ProbeStarting>());

      _controller(container).start(ServerAddress.parse('fast.example.com'));
      async.elapse(const Duration(minutes: 1));
      expect(_state(container), isA<ProbeReady>());
      expect(
        client.requested.where((u) => u.contains('slow')),
        hasLength(1),
        reason: 'the first run made no retry after the second start',
      );
    });
  });

  test('retry repeats the last address', () {
    final client = FakeProbeClient({
      'https://example.com/api/health': [reply(404), ok(_health)],
    });
    _withController(client, (async, container) {
      _controller(container).start(ServerAddress.parse('example.com'));
      async.elapse(const Duration(seconds: 1));
      expect(_state(container), isA<ProbeFailed>());

      _controller(container).retry();
      async.elapse(const Duration(seconds: 1));
      expect(_state(container), isA<ProbeReady>());
      expect(client.requested, [
        'https://example.com/api/health',
        'https://example.com/api/health',
      ]);
    });
  });

  test('cancel stops pending retries', () {
    final client = FakeProbeClient({
      'https://example.com/api/health': [reply(503, _starting)],
    });
    _withController(client, (async, container) {
      _controller(container).start(ServerAddress.parse('example.com'));
      async.elapse(const Duration(seconds: 4));
      expect(client.requested, hasLength(2));

      _controller(container).cancel();
      async.elapse(const Duration(minutes: 1));
      expect(client.requested, hasLength(2));
      expect(async.pendingTimers, isEmpty);
      expect(client.closed, isTrue);
    });
  });
}
