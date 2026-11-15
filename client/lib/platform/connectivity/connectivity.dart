// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The kind of network a device is connected through.
enum ConnectivityType {
  /// Wi-Fi.
  wifi,

  /// A mobile network.
  cellular,

  /// Anything else: ethernet, VPN, Bluetooth, or no interface at all.
  other,
}

/// What the operating system reports about the device's network
/// interfaces. It says nothing about whether a server answers.
@immutable
final class ConnectivityInfo {
  /// Creates the report.
  const new({required this.hasInterface, required this.type});

  /// No interface is up.
  static const ConnectivityInfo none = ConnectivityInfo(
    hasInterface: false,
    type: ConnectivityType.other,
  );

  /// Whether any network interface is up.
  final bool hasInterface;

  /// The kind of the preferred interface.
  final ConnectivityType type;

  @override
  bool operator ==(Object other) =>
      other is ConnectivityInfo &&
      other.hasInterface == hasInterface &&
      other.type == type;

  @override
  int get hashCode => Object.hash(hasInterface, type);

  @override
  String toString() =>
      'ConnectivityInfo(hasInterface: $hasInterface, type: ${type.name})';
}

/// The device's network interfaces (doc 02, Platform Seams).
abstract interface class ConnectivitySource {
  /// The current report first, then every change.
  Stream<ConnectivityInfo> watch();
}

/// Maps the results of `connectivity_plus` to a [ConnectivityInfo]: Wi-Fi
/// wins over mobile, mobile over anything else.
ConnectivityInfo connectivityInfoFrom(List<ConnectivityResult> results) {
  final up = results.where((r) => r != ConnectivityResult.none).toSet();
  if (up.isEmpty) return ConnectivityInfo.none;
  return ConnectivityInfo(
    hasInterface: true,
    type: up.contains(ConnectivityResult.wifi)
        ? ConnectivityType.wifi
        : up.contains(ConnectivityResult.mobile)
        ? ConnectivityType.cellular
        : ConnectivityType.other,
  );
}

/// The [ConnectivitySource] of the running app, through `connectivity_plus`.
class PlusConnectivitySource implements ConnectivitySource {
  /// Creates the source.
  new([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<ConnectivityInfo> watch() async* {
    yield connectivityInfoFrom(await _connectivity.checkConnectivity());
    yield* _connectivity.onConnectivityChanged.map(connectivityInfoFrom);
  }
}

/// The app's [ConnectivitySource]; tests override it.
final Provider<ConnectivitySource> connectivitySourceProvider =
    Provider<ConnectivitySource>((ref) => PlusConnectivitySource());
