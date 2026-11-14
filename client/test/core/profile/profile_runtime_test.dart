// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/session_controller.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan_api/soundspan_api.dart';

import 'profile_harness.dart';

/// Every `ref.onDispose` call of the profile tests, by provider name.
final List<String> _disposed = [];

/// Whether the async closer registered by [_asyncCloserProbe] completed.
bool _asyncCloserDone = false;

final Provider<ProfileContext> _plainProbe = Provider<ProfileContext>((ref) {
  ref.onDispose(() => _disposed.add('plainProbe'));
  return ref.watch(profileContextProvider);
}, dependencies: [profileContextProvider]);

final Provider<ProfileContext> _asyncCloserProbe = Provider<ProfileContext>((
  ref,
) {
  ref
    ..onDispose(() => _disposed.add('asyncCloserProbe'))
    ..watch(profileDisposerProvider).register(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      _asyncCloserDone = true;
    });
  return ref.watch(profileContextProvider);
}, dependencies: [profileContextProvider, profileDisposerProvider]);

/// Records `ref.onDispose` of the providers under test, per container.
final class _DisposeObserver extends ProviderObserver {
  final List<(ProviderContainer, ProviderBase<Object?>)> disposed = [];

  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      disposed.add((context.container, context.provider));
}

void main() {
  setUp(() {
    _disposed.clear();
    _asyncCloserDone = false;
  });

  Future<(ProfileHarness, ProfileRuntime)> setUpRuntime({
    String? storedActiveId,
  }) async {
    final harness = await ProfileHarness.create(storedActiveId: storedActiveId);
    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    return (harness, runtime);
  }

  test('switching profiles disposes every profile-scoped provider', () async {
    final (h, _) = await setUpRuntime();
    final observer = _DisposeObserver();
    // Observers are inherited by child containers; attach one through a
    // root of its own for this test.
    final root = ProviderContainer(parent: h.root, observers: [observer]);
    addTearDown(root.dispose);
    final observed = ProfileRuntime(root);
    addTearDown(observed.dispose);

    await observed.switchTo(h.a);
    final a = observed.container!;
    final watched = <ProviderBase<Object?>>[
      sessionControllerProvider,
      apiConfigProvider,
      stateDatabaseProvider,
      _plainProbe,
      _asyncCloserProbe,
    ];
    final session = a.read(sessionControllerProvider);
    final config = a.read(apiConfigProvider);
    final database = a.read(stateDatabaseProvider);
    expect(a.read(_plainProbe).profile.id, h.a);
    a.read(_asyncCloserProbe);
    expect(config.baseUrl, Uri.parse('https://a.example.com'));
    expect(session.current, isA<JwtCredentials>());

    await observed.switchTo(h.b);

    for (final provider in watched) {
      expect(
        observer.disposed.where(
          (e) => identical(e.$1, a) && identical(e.$2, provider),
        ),
        hasLength(1),
        reason: '$provider disposed once in A',
      );
    }
    expect(_disposed, unorderedEquals(['plainProbe', 'asyncCloserProbe']));
    expect(_asyncCloserDone, isTrue);
    expect(h.opener.closed, contains(StateDatabaseTarget(h.a)));
    expect(() => a.read(profileContextProvider), throwsA(anything));

    final b = observed.container!;
    expect(b, isNot(same(a)));
    expect(b.read(profileContextProvider).profile.id, h.b);
    expect(b.read(_plainProbe).profile.id, h.b);
    expect(b.read(sessionControllerProvider), isNot(same(session)));
    expect(b.read(sessionControllerProvider).current, isA<ApiKeyCredentials>());
    expect(
      b.read(apiConfigProvider).baseUrl,
      Uri.parse('https://b.example.com'),
    );
    expect(b.read(stateDatabaseProvider), isNot(same(database)));
    expect(observed.state.value, ProfileRuntimeActive(h.b));
  });

  test('the profile scope carries the profile, paths and api config', () async {
    final (h, runtime) = await setUpRuntime();
    await runtime.switchTo(h.a);
    final container = runtime.container!;
    final context = container.read(profileContextProvider);
    expect(context.paths, h.paths.profile(h.a));
    final profile = context.profile;
    final config = container.read(apiConfigProvider);
    expect(config.playbackDeviceId, profile.deviceId);
    expect(config.userAgent, 'soundspan-client/test (test)');
    expect(config.connectTimeout, const Duration(seconds: 10));
    expect(config.receiveTimeout, const Duration(seconds: 30));
    expect(h.opener.opened, [StateDatabaseTarget(h.a)]);
  });

  test('closers run in reverse registration order', () async {
    final (h, runtime) = await setUpRuntime();
    await runtime.switchTo(h.a);
    final order = <String>[];
    final disposer = runtime.container!.read(profileDisposerProvider);
    for (final name in ['first', 'second', 'third']) {
      disposer.register(() async {
        await Future<void>.delayed(Duration.zero);
        order.add(name);
      });
    }
    disposer.register(() async => throw StateError('closing failed'));
    await runtime.switchTo(null);
    expect(order, ['third', 'second', 'first']);
  });

  test('concurrent switchTo calls run one after another and end on the last requested profile', () async {
    final (h, runtime) = await setUpRuntime();
    final states = <ProfileRuntimeState>[];
    runtime.state.addListener(() => states.add(runtime.state.value));

    await Future.wait([
      runtime.switchTo(h.a),
      runtime.switchTo(h.b),
      runtime.switchTo(h.a),
    ]);

    expect(states, [
      ProfileRuntimeState.switching,
      ProfileRuntimeActive(h.a),
      ProfileRuntimeState.switching,
      ProfileRuntimeActive(h.b),
      ProfileRuntimeState.switching,
      ProfileRuntimeActive(h.a),
    ]);
    expect(runtime.container!.read(profileContextProvider).profile.id, h.a);
    expect(h.root.read(activeProfileIdProvider), h.a);
    expect(h.opener.closed, [
      StateDatabaseTarget(h.a),
      StateDatabaseTarget(h.b),
    ]);
  });

  test('switching to the active profile does nothing', () async {
    final (h, runtime) = await setUpRuntime();
    await runtime.switchTo(h.a);
    final container = runtime.container;
    await runtime.switchTo(h.a);
    expect(runtime.container, same(container));
    expect(h.opener.opened, hasLength(1));
  });

  test(
    'switchTo(null) leaves no container and clears the stored active id',
    () async {
      final (h, runtime) = await setUpRuntime();
      await runtime.switchTo(h.a);
      expect(h.root.read(activeProfileIdProvider), h.a);

      await runtime.switchTo(null);

      expect(runtime.container, isNull);
      expect(runtime.state.value, ProfileRuntimeState.none);
      expect(h.root.read(activeProfileIdProvider), isNull);
      expect(h.opener.closed, [StateDatabaseTarget(h.a)]);
    },
  );

  test('switching marks the profile used and stores it as active', () async {
    final (h, runtime) = await setUpRuntime();
    h.clock.advance(const Duration(hours: 2));
    await runtime.switchTo(h.a);
    final repository = h.root.read(profileRepositoryProvider);
    expect((await repository.byId(h.a))!.lastUsedAt, h.clock.now());
    expect(h.root.read(activeProfileIdProvider), h.a);
  });

  test(
    'start activates the stored profile; with none stored the state is none',
    () async {
      final (h, runtime) = await setUpRuntime();
      await runtime.start();
      expect(runtime.state.value, ProfileRuntimeState.none);
      expect(runtime.container, isNull);

      expect(h.opener.opened, isEmpty);

      // A stored id is activated.
      await h.root.read(activeProfileIdProvider.notifier).set(h.b);
      await runtime.start();
      expect(runtime.state.value, ProfileRuntimeActive(h.b));
      expect(runtime.container!.read(profileContextProvider).profile.id, h.b);
    },
  );

  test('a stored id without a profile leaves no profile active', () async {
    final (h, runtime) = await setUpRuntime(storedActiveId: 'gone');
    await runtime.start();
    expect(runtime.state.value, ProfileRuntimeState.none);
    expect(h.root.read(activeProfileIdProvider), isNull);
  });

  test('a state database written by a newer version yields localDataTooNew and deletes nothing', () async {
    final (h, runtime) = await setUpRuntime();
    await runtime.switchTo(h.a);
    h.opener.tooNew.add(h.b);
    final secretsBefore = Map.of(h.secrets.values);

    await runtime.switchTo(h.b);

    expect(runtime.state.value, ProfileRuntimeLocalDataTooNew(h.b));
    expect(runtime.container, isNull);
    expect(h.opener.deleted, isEmpty);
    expect(h.paths.deletedTrees, isEmpty);
    expect(h.secrets.values, secretsBefore);
    expect(h.root.read(activeProfileIdProvider), h.a);
  });

  test(
    'resetLocalState removes the state database and activates the profile',
    () async {
      final (h, runtime) = await setUpRuntime();
      h.opener.tooNew.add(h.b);
      await runtime.switchTo(h.b);
      expect(runtime.state.value, ProfileRuntimeLocalDataTooNew(h.b));

      await runtime.resetLocalState(h.b);

      expect(h.opener.deleted, [StateDatabaseTarget(h.b)]);
      expect(h.paths.deletedTrees, [h.b]);
      expect(runtime.state.value, ProfileRuntimeActive(h.b));
      expect(
        runtime.container!.read(stateDatabaseProvider),
        isA<StateDatabase>(),
      );
      expect(h.root.read(activeProfileIdProvider), h.b);
    },
  );

  test('profileContextProvider throws outside a profile scope', () async {
    final (h, _) = await setUpRuntime();
    expect(() => h.root.read(profileContextProvider), throwsA(anything));
    expect(() => h.root.read(sessionControllerProvider), throwsA(anything));
  });

  test('a session rejected in the scope signs the profile out', () async {
    final (h, runtime) = await setUpRuntime();
    await runtime.switchTo(h.a);
    final session = runtime.container!.read(sessionControllerProvider);
    final next = session.states.first;
    session.onUnauthenticated(UnauthenticatedReason.sessionExpired);
    expect(
      await next,
      const SessionState.signedOut(UnauthenticatedReason.sessionExpired),
    );
    final repository = h.root.read(profileRepositoryProvider);
    expect(await repository.readCredentials(h.a), isNull);
  });
}
