// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/disk_space/disk_space.dart';

import '../../helpers/fake_reachability.dart';
import '../../helpers/fakes/fake_disk_space.dart';
import '../../helpers/fakes/fake_downloader.dart';
import '../profile/profile_harness.dart';

void main() {
  Future<(ProfileHarness, FakeDownloader)> harness(
    PlatformCapabilities capabilities,
  ) async {
    final downloader = FakeDownloader(appSupport: '/support');
    addTearDown(downloader.dispose);
    final harness = await ProfileHarness.create(
      overrides: [
        platformCapabilitiesProvider.overrideWithValue(capabilities),
        downloaderProvider.overrideWithValue(downloader),
        diskSpaceProvider.overrideWithValue(FakeDiskSpace()),
        reachabilityProvider.overrideWithValue(FakeReachability()),
      ],
    );
    return (harness, downloader);
  }

  test('after the first frame each activated profile starts its own '
      'download scheduler', () async {
    expect(postFirstFrameTasks, contains(startDownloads));
    final (h, downloader) = await harness(PlatformCapabilities.android);
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(h.a);
    final a = runtime.container!.read(downloadSchedulerProvider);
    await startDownloads(h.root);
    await pumpEventQueue();
    expect(downloader.startCount, 1);

    await runtime.switchTo(h.b);
    await pumpEventQueue();
    expect(runtime.container!.read(downloadSchedulerProvider), isNot(same(a)));
    expect(downloader.startCount, 2);
  });

  test('a target that cannot download starts no scheduler', () async {
    final (h, downloader) = await harness(PlatformCapabilities.web);
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    await runtime.switchTo(h.a);

    await startDownloads(h.root);
    await pumpEventQueue();

    expect(downloader.startCount, 0);
  });
}
