// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/background_download_router.dart';
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_scheduler.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
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
    // The background router starts the downloader first, then the scheduler.
    expect(downloader.startCount, 2);
    final router = h.root.read(backgroundDownloadRouterProvider);
    expect(router.activeProfileId, h.a);

    await runtime.switchTo(h.b);
    await pumpEventQueue();
    expect(runtime.container!.read(downloadSchedulerProvider), isNot(same(a)));
    expect(downloader.startCount, 3);
    expect(router.activeProfileId, h.b);
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

  test('each activated profile has its own download controller, reachable '
      'through the profile runtime', () async {
    final (h, _) = await harness(PlatformCapabilities.android);
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(h.a);
    await startDownloads(h.root);
    final a = runtime.container!.read(downloadControllerProvider);
    expect(runtime.container!.read(downloadControllerProvider), same(a));
    expect(await a.watchCollection(CollectionKind.album, 'none').first, isNull);

    await runtime.switchTo(h.b);
    expect(runtime.container!.read(downloadControllerProvider), isNot(same(a)));
  });

  test('each activated profile that can download has its own download '
      'artwork', () async {
    final (h, _) = await harness(PlatformCapabilities.android);
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(h.a);
    await startDownloads(h.root);
    await pumpEventQueue();
    final a = runtime.container!.read(downloadArtworkProvider);
    expect(a, isA<ProfileDownloadArtwork>());
    expect(await a.fileFor('cover-1'), isNull);

    await runtime.switchTo(h.b);
    expect(runtime.container!.read(downloadArtworkProvider), isNot(same(a)));
  });

  test('a target that cannot download has the no-op download '
      'artwork', () async {
    final (h, _) = await harness(PlatformCapabilities.web);
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    await runtime.switchTo(h.a);

    expect(
      runtime.container!.read(downloadArtworkProvider),
      isA<NoDownloadArtwork>(),
    );
  });
}
