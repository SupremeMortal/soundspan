// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/core/storage/state/state_database.dart';

/// The notice about a server version the client was not tested against
/// (doc 04, Capability Discovery and Version Gate).
@immutable
sealed class VersionNotice {
  const new();

  /// The server is newer than the newest tested version.
  const factory newerThanTested(Version version) = NewerThanTested;

  /// The server did not say which version it runs.
  static const VersionNotice versionUnknown = VersionUnknown();
}

/// The server runs [version], newer than the newest tested one.
final class NewerThanTested extends VersionNotice {
  /// Creates the notice for [version].
  const new(this.version);

  /// The server's version.
  final Version version;

  @override
  bool operator ==(Object other) =>
      other is NewerThanTested && other.version == version;

  @override
  int get hashCode => Object.hash(NewerThanTested, version);

  @override
  String toString() => 'VersionNotice.newerThanTested($version)';
}

/// The server's version is unknown.
final class VersionUnknown extends VersionNotice {
  /// The notice.
  const new();

  @override
  String toString() => 'VersionNotice.versionUnknown';
}

/// The `device_settings` key holding the dismissed server version, or
/// `unknown`.
const String versionNoticeDismissedKey = 'versionNotice.dismissed';

/// The active profile's [VersionNotice], or null when there is none or it
/// was dismissed for this server version.
///
/// A server newer than the tested range, or one that does not say its
/// version, has a notice once a capability refresh has run, until
/// [dismiss]. Dismissing stores the version (or `unknown`) under
/// [versionNoticeDismissedKey] in the profile's `state.db`, so the notice
/// returns once for each new server version.
class VersionNoticeController extends AsyncNotifier<VersionNotice?> {
  @override
  Future<VersionNotice?> build() async {
    final capabilities = ref.watch(serverCapabilitiesProvider);
    final key = _keyFor(capabilities);
    if (key == null) return null;
    final dismissed = await _read(ref.watch(stateDatabaseProvider));
    if (dismissed == key) return null;
    final version = capabilities.serverVersion;
    return version == null
        ? VersionNotice.versionUnknown
        : VersionNotice.newerThanTested(version);
  }

  /// Hides the notice until the server reports another version.
  Future<void> dismiss() async {
    final key = _keyFor(ref.read(serverCapabilitiesProvider));
    if (key == null) return;
    final database = ref.read(stateDatabaseProvider);
    await database
        .into(database.deviceSettings)
        .insertOnConflictUpdate(
          DeviceSettingsCompanion.insert(
            key: versionNoticeDismissedKey,
            value: jsonEncode(key),
          ),
        );
    state = const AsyncData(null);
  }

  /// The dismissal key of [capabilities], or null when they need no notice.
  String? _keyFor(ServerCapabilities capabilities) {
    if (capabilities.fetchedAt == null) return null;
    final version = capabilities.serverVersion;
    return switch (ref.read(versionGateProvider).evaluate(version)) {
      VersionGateResult.aboveTested => version.toString(),
      VersionGateResult.unknown => 'unknown',
      VersionGateResult.belowMin || VersionGateResult.inRange => null,
    };
  }

  static Future<String?> _read(StateDatabase database) async {
    final row = await (database.select(
      database.deviceSettings,
    )..where((t) => t.key.equals(versionNoticeDismissedKey))).getSingleOrNull();
    if (row == null) return null;
    try {
      return switch (jsonDecode(row.value)) {
        final String value => value,
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}

/// The [VersionNotice] of the profile scope. Rendering it is the shell's.
final AsyncNotifierProvider<VersionNoticeController, VersionNotice?>
versionNoticeProvider =
    AsyncNotifierProvider<VersionNoticeController, VersionNotice?>(
      VersionNoticeController.new,
      dependencies: [serverCapabilitiesProvider, stateDatabaseProvider],
    );
