// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/connectivity/connectivity.dart';

import '../../core/logging/recording_sink.dart';

/// A [Connectivity] whose first check fails, as on a Linux desktop
/// without NetworkManager, and whose changes the test drives.
class _FailingConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> changes =
      StreamController<List<ConnectivityResult>>();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => throw Exception(
    'org.freedesktop.DBus.Error.ServiceUnknown: The name '
    'org.freedesktop.NetworkManager was not provided by any .service files',
  );

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => changes.stream;
}

void main() {
  test('no result or only none is no interface', () {
    expect(connectivityInfoFrom(const []), ConnectivityInfo.none);
    expect(
      connectivityInfoFrom(const [ConnectivityResult.none]),
      ConnectivityInfo.none,
    );
  });

  test('Wi-Fi wins over mobile, mobile over anything else', () {
    expect(
      connectivityInfoFrom(const [
        ConnectivityResult.mobile,
        ConnectivityResult.wifi,
      ]),
      const ConnectivityInfo(hasInterface: true, type: ConnectivityType.wifi),
    );
    expect(
      connectivityInfoFrom(const [
        ConnectivityResult.vpn,
        ConnectivityResult.mobile,
      ]),
      const ConnectivityInfo(
        hasInterface: true,
        type: ConnectivityType.cellular,
      ),
    );
    expect(
      connectivityInfoFrom(const [ConnectivityResult.ethernet]),
      const ConnectivityInfo(hasInterface: true, type: ConnectivityType.other),
    );
  });

  test('a failing platform is logged once, reports nothing, and later '
      'changes still arrive', () async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: true);
    addTearDown(AppLogging.reset);
    final connectivity = _FailingConnectivity();
    final reports = <ConnectivityInfo>[];
    final errors = <Object>[];
    final subscription = PlusConnectivitySource(connectivity)
        .watch()
        .listen(reports.add, onError: errors.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    connectivity.changes
      ..addError(StateError('NetworkManager is not running'))
      ..add(const [ConnectivityResult.wifi]);
    await pumpEventQueue();

    expect(errors, isEmpty);
    expect(reports, [
      const ConnectivityInfo(hasInterface: true, type: ConnectivityType.wifi),
    ]);
    expect(sink.entries.where((e) => e.scope == 'Connectivity').length, 1);
  });
}
