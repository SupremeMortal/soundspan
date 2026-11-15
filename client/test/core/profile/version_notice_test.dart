// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan/core/profile/version_notice.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';

import 'profile_harness.dart';

final VersionGate _gate = VersionGate(
  Version.tryParse('1.4.0')!,
  Version.tryParse('1.6.0')!,
);

/// Keeps each profile's `state.db` in a file, so it survives a restart of
/// the profile scope.
class _FileOpener extends TestOpener {
  new(this.directory);

  final Directory directory;

  @override
  QueryExecutor open(DatabaseTarget target) {
    if (target case StateDatabaseTarget(:final profileId)) {
      opened.add(target);
      return NativeDatabase(File('${directory.path}/$profileId-state.db'));
    }
    return super.open(target);
  }
}

void main() {
  late ProfileHarness harness;
  late ProfileRuntime runtime;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('version_notice');
    addTearDown(() => directory.delete(recursive: true));
    harness = await ProfileHarness.create(
      opener: _FileOpener(directory),
      overrides: [versionGateProvider.overrideWithValue(_gate)],
    );
    runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
  });

  /// Stores [version] as profile A's last refreshed version (null:
  /// unknown), then starts A's scope again, as an app restart does.
  Future<VersionNotice?> restartAt(String? version) async {
    await runtime.switchTo(harness.b);
    await harness.root
        .read(profileRepositoryProvider)
        .updateServerInfo(
          harness.a,
          serverVersion: version,
          features: const {},
          featuresFetchedAt: harness.clock.now(),
        );
    await runtime.switchTo(harness.a);
    return await runtime.container!.read(versionNoticeProvider.future);
  }

  Future<void> dismiss() =>
      runtime.container!.read(versionNoticeProvider.notifier).dismiss();

  test('above tested shows once per server version', () async {
    expect(
      await restartAt('1.7.0'),
      VersionNotice.newerThanTested(Version.tryParse('1.7.0')!),
    );
    await dismiss();
    expect(runtime.container!.read(versionNoticeProvider).value, isNull);

    expect(await restartAt('1.7.0'), isNull);
    expect(
      await restartAt('1.8.0'),
      VersionNotice.newerThanTested(Version.tryParse('1.8.0')!),
    );
  });

  test('unknown shows until dismissed', () async {
    expect(await restartAt(null), VersionNotice.versionUnknown);
    expect(await restartAt(null), VersionNotice.versionUnknown);
    await dismiss();
    expect(runtime.container!.read(versionNoticeProvider).value, isNull);
    expect(await restartAt(null), isNull);
    expect(
      await restartAt('1.7.0'),
      VersionNotice.newerThanTested(Version.tryParse('1.7.0')!),
    );
  });

  test('in range shows nothing', () async {
    for (final version in ['1.4.0', '1.5.2', '1.6.0', '1.3.0']) {
      expect(await restartAt(version), isNull, reason: version);
    }
  });

  test('nothing shows before the first refresh', () async {
    await runtime.switchTo(harness.a);
    expect(await runtime.container!.read(versionNoticeProvider.future), isNull);
  });
}
