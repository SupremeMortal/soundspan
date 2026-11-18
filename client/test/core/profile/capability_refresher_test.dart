// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/capability_refresher.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_server_adapter.dart';
import 'profile_harness.dart';

final VersionGate _gate = VersionGate(
  Version.tryParse('1.4.0')!,
  Version.tryParse('1.6.0')!,
);

/// A profile harness whose APIs all talk to [server].
Future<(ProfileHarness, ProfileRuntime)> _start(
  FakeServerAdapter server,
) async {
  final harness = await ProfileHarness.create(
    overrides: [
      versionGateProvider.overrideWithValue(_gate),
      soundspanApiFactoryProvider.overrideWithValue(
        (config, credentials) =>
            SoundspanApi(config, credentials: credentials, adapter: server),
      ),
    ],
  );
  final runtime = harness.root.read(profileRuntimeProvider);
  addTearDown(runtime.dispose);
  return (harness, runtime);
}

/// Lets queued work run until [done] holds, failing after a few seconds.
Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 500 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

void main() {
  test('refresh stores version and features on the profile', () async {
    final server = FakeServerAdapter(version: '1.5.0');
    final (harness, runtime) = await _start(server);
    await runtime.switchTo(harness.a);
    final container = runtime.container!;

    expect(await container.read(capabilityRefresherProvider).refresh(), isTrue);

    final profile = await harness.root
        .read(profileRepositoryProvider)
        .byId(harness.a);
    expect(profile!.serverVersion, '1.5.0');
    expect(profile.features, {
      ...FakeServerAdapter.defaultFeatures,
      'loudnessTargetLufs': -14.0,
    });
    expect(profile.featuresFetchedAt, harness.clock.now());
    final capabilities = container.read(serverCapabilitiesProvider);
    expect(capabilities.serverVersion, Version.tryParse('1.5.0'));
    expect(capabilities.vibe, isTrue);
    expect(capabilities.audioAnalysis, isTrue);
    expect(capabilities.loudnessTargetLufs, -14);
    expect(server.count('/api/docs.json'), 1);
    expect(server.count('/api/system/features'), 1);
  });

  test('the cached value is emitted before the refresh returns', () async {
    final server = FakeServerAdapter(version: '1.5.0');
    final (harness, runtime) = await _start(server);
    await harness.root
        .read(profileRepositoryProvider)
        .updateServerInfo(
          harness.a,
          serverVersion: '1.4.2',
          features: const {'discovery': true, 'vibeEmbeddings': false},
          featuresFetchedAt: harness.clock.now(),
        );
    await runtime.switchTo(harness.a);
    final container = runtime.container!;
    final seen = <ServerCapabilities>[];
    container.listen(
      serverCapabilitiesProvider,
      (_, next) => seen.add(next),
      fireImmediately: true,
    );

    server.gate = Completer<void>();
    final refresh = container.read(capabilityRefresherProvider).refresh();
    await pumpEventQueue();
    expect(seen.single.serverVersion, Version.tryParse('1.4.2'));
    expect(seen.single.discovery, isTrue);
    expect(seen.single.vibe, isFalse);

    server.gate!.complete();
    await refresh;
    expect(seen, hasLength(2));
    expect(seen.last.serverVersion, Version.tryParse('1.5.0'));
    expect(seen.last.vibe, isTrue);
  });

  test('a failed refresh keeps the cached value', () async {
    final server = FakeServerAdapter()..fail = true;
    final (harness, runtime) = await _start(server);
    final repository = harness.root.read(profileRepositoryProvider);
    final fetchedAt = harness.clock.now();
    await repository.updateServerInfo(
      harness.a,
      serverVersion: '1.4.2',
      features: const {'discovery': true},
      featuresFetchedAt: fetchedAt,
    );
    await runtime.switchTo(harness.a);
    final container = runtime.container!;
    final cached = container.read(serverCapabilitiesProvider);
    harness.clock.advance(const Duration(minutes: 5));

    expect(
      await container.read(capabilityRefresherProvider).refresh(),
      isFalse,
    );

    expect(container.read(serverCapabilitiesProvider), cached);
    final profile = await repository.byId(harness.a);
    expect(profile!.serverVersion, '1.4.2');
    expect(profile.featuresFetchedAt, fetchedAt);
  });

  test(
    'refreshIfDue refreshes after a failure or an hour, not before',
    () async {
      final server = FakeServerAdapter(version: '1.5.0')..fail = true;
      final (harness, runtime) = await _start(server);
      await runtime.switchTo(harness.a);
      final refresher = runtime.container!.read(capabilityRefresherProvider);

      expect(await refresher.refreshIfDue(), isFalse);
      expect(server.count('/api/docs.json'), 1);

      server.fail = false;
      expect(await refresher.refreshIfDue(), isTrue);
      expect(server.count('/api/system/features'), 1);

      harness.clock.advance(const Duration(minutes: 59));
      expect(await refresher.refreshIfDue(), isFalse);
      expect(server.count('/api/system/features'), 1);

      harness.clock.advance(const Duration(minutes: 2));
      expect(await refresher.refreshIfDue(), isTrue);
      expect(server.count('/api/system/features'), 2);
    },
  );

  test('resume after 61 minutes refreshes, after 59 does not', () async {
    final server = FakeServerAdapter(version: '1.5.0');
    final (harness, runtime) = await _start(server);
    await runtime.switchTo(harness.a);
    final refresher = runtime.container!.read(capabilityRefresherProvider)
      ..handleLifecycle(AppLifecycleState.hidden)
      ..handleLifecycle(AppLifecycleState.paused);
    harness.clock.advance(const Duration(minutes: 59));
    refresher
      ..handleLifecycle(AppLifecycleState.hidden)
      ..handleLifecycle(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(server.requested, isEmpty);

    refresher.handleLifecycle(AppLifecycleState.paused);
    harness.clock.advance(const Duration(minutes: 61));
    refresher.handleLifecycle(AppLifecycleState.resumed);
    await _until(() => server.count('/api/system/features') == 1);
    expect(server.count('/api/docs.json'), 1);
  });

  test(
    'refreshNow runs immediately and concurrent calls share one run',
    () async {
      final server = FakeServerAdapter(version: '1.5.0')
        ..gate = Completer<void>();
      final (harness, runtime) = await _start(server);
      await runtime.switchTo(harness.a);
      final refresher = runtime.container!.read(capabilityRefresherProvider);

      final first = refresher.refreshNow();
      await pumpEventQueue();
      expect(server.count('/api/docs.json'), 1);
      final second = refresher.refreshNow();
      final third = refresher.refresh();
      await pumpEventQueue();
      expect(server.count('/api/docs.json'), 1);

      server.gate!.complete();
      expect(await Future.wait([first, second, third]), [true, true, true]);
      expect(server.count('/api/docs.json'), 1);
      expect(server.count('/api/system/features'), 1);

      expect(await refresher.refreshNow(), isTrue);
      expect(server.count('/api/docs.json'), 2);
    },
  );

  test('the API client is disposed when the profile is switched', () async {
    final servers = <FakeServerAdapter>[];
    final harness = await ProfileHarness.create(
      overrides: [
        versionGateProvider.overrideWithValue(_gate),
        soundspanApiFactoryProvider.overrideWithValue((config, credentials) {
          final server = FakeServerAdapter(version: '1.5.0');
          servers.add(server);
          return SoundspanApi(
            config,
            credentials: credentials,
            adapter: server,
          );
        }),
      ],
    );
    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(harness.a);
    await runtime.container!.read(capabilityRefresherProvider).refresh();
    expect(servers.single.closed, isFalse);

    await runtime.switchTo(harness.b);
    expect(servers.single.closed, isTrue);
    await runtime.container!.read(capabilityRefresherProvider).refresh();
    expect(servers, hasLength(2));
    expect(servers.last.closed, isFalse);
  });

  test(
    'startCapabilityRefresh refreshes each profile that becomes active',
    () async {
      final server = FakeServerAdapter(version: '1.5.0');
      final (harness, runtime) = await _start(server);
      await runtime.switchTo(harness.a);
      TestWidgetsFlutterBinding.ensureInitialized();

      await startCapabilityRefresh(harness.root);
      await _until(() => server.count('/api/system/features') == 1);

      await runtime.switchTo(harness.b);
      final repository = harness.root.read(profileRepositoryProvider);
      String? version;
      await _until(() {
        unawaited(
          repository.byId(harness.b).then((b) => version = b?.serverVersion),
        );
        return version == '1.5.0';
      });
      expect(server.count('/api/system/features'), 2);
    },
  );

  test(
    'a FeatureDisabled refresh request runs the profile refresher',
    () async {
      final server = FakeServerAdapter(version: '1.5.0');
      final (harness, runtime) = await _start(server);
      await runtime.switchTo(harness.a);

      runtime.container!.read(capabilityRefreshProvider)();
      await _until(() => server.count('/api/system/features') == 1);
      expect(server.count('/api/docs.json'), 1);
    },
  );

  test('outside a profile scope there is no refresher', () async {
    final harness = await ProfileHarness.create();
    expect(
      () => harness.root.read(capabilityRefresherProvider),
      throwsA(anything),
    );
    expect(
      () => harness.root.read(serverCapabilitiesProvider),
      throwsA(anything),
    );
  });
}
