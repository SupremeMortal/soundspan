// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/reachability_binding.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_server_adapter.dart';
import 'profile_harness.dart';

class _Wifi implements ConnectivitySource {
  @override
  Stream<ConnectivityInfo> watch() => Stream.value(
    const ConnectivityInfo(hasInterface: true, type: ConnectivityType.wifi),
  );
}

/// A [FakeServerAdapter] that fails every request with a connection error
/// while [down].
class _FlakyServer extends FakeServerAdapter {
  new() : super(version: '1.5.0');

  bool down = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (down) {
      requested.add(options.uri.path);
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'down',
      );
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

Future<(ProfileHarness, ProfileRuntime)> _start(_FlakyServer server) async {
  final harness = await ProfileHarness.create(
    overrides: [
      connectivitySourceProvider.overrideWithValue(_Wifi()),
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

Future<void> _setForced(ProfileRuntime runtime, {required bool forced}) {
  final database = runtime.container!.read(stateDatabaseProvider);
  return database
      .into(database.deviceSettings)
      .insertOnConflictUpdate(
        DeviceSettingsCompanion.insert(
          key: offlineForcedKey,
          value: jsonEncode(forced),
        ),
      );
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 500 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

void main() {
  test("the active profile's offline.forced setting drives the state, and "
      'clearing it probes GET /api/health', () async {
    final server = _FlakyServer();
    final (harness, runtime) = await _start(server);
    await runtime.switchTo(harness.a);
    await startReachability(harness.root);
    final reachability = harness.root.read(reachabilityProvider);

    await _setForced(runtime, forced: true);
    await _until(() => reachability.current == Reachability.forcedOffline);
    expect(server.count('/api/health'), 0);

    server.down = true;
    await _setForced(runtime, forced: false);
    await _until(() => server.count('/api/health') == 1);
    expect(reachability.current, Reachability.serverUnreachable);

    server.down = false;
    await reachability.probeNow();
    expect(reachability.current, Reachability.online);
    expect(server.count('/api/health'), 2);
  });

  test('returning online refreshes capabilities only when due', () async {
    final server = _FlakyServer();
    final (harness, runtime) = await _start(server);
    await runtime.switchTo(harness.a);
    await startReachability(harness.root);
    final reachability = harness.root.read(reachabilityProvider);

    for (var i = 0; i < 2; i++) {
      await _setForced(runtime, forced: true);
      await _until(() => reachability.current == Reachability.forcedOffline);
      await _setForced(runtime, forced: false);
      await _until(() => reachability.current == Reachability.online);
    }
    await _until(() => server.count('/api/system/features') == 1);
    await pumpEventQueue();
    expect(server.count('/api/system/features'), 1);
  });

  test('switching profiles binds the next profile afresh', () async {
    final server = _FlakyServer();
    final (harness, runtime) = await _start(server);
    await runtime.switchTo(harness.a);
    await startReachability(harness.root);
    final reachability = harness.root.read(reachabilityProvider);
    await _setForced(runtime, forced: true);
    await _until(() => reachability.current == Reachability.forcedOffline);

    await runtime.switchTo(harness.b);
    await _until(() => reachability.current == Reachability.online);
    await _setForced(runtime, forced: true);
    await _until(() => reachability.current == Reachability.forcedOffline);
  });

  test('an unreadable offline.forced value is off', () async {
    final server = _FlakyServer();
    final (harness, runtime) = await _start(server);
    await runtime.switchTo(harness.a);
    final database = runtime.container!.read(stateDatabaseProvider);
    await database
        .into(database.deviceSettings)
        .insert(
          DeviceSettingsCompanion.insert(key: offlineForcedKey, value: '{'),
        );
    expect(await watchOfflineForced(database).first, isFalse);
  });
}
