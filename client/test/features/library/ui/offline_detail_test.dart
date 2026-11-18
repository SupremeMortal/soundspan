// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';

import '../../../helpers/fake_reachability.dart';
import '../../../helpers/fake_repositories.dart';
import '../../../helpers/fakes/fake_download_controller.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/play_rig.dart';
import '../../detail_fixtures.dart';

const _screen = AlbumScreen(albumId: 'al-1');

final List<Track> _onDevice = [fixtureTrack(1), fixtureTrack(3)];

/// This device's downloads: tracks 1 and 3 of the fixture album.
final class _Downloaded implements DownloadedLibrary {
  const new();

  @override
  Future<Set<PlaybackId>> downloadedPlaybackIds() async => {
    for (final track in _onDevice) track.playbackId!,
  };

  @override
  Future<AlbumDetail?> albumDetail(String albumId) async =>
      AlbumDetail(album: fixtureAlbum(albumId), tracks: _onDevice, owned: true);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeDownloadController downloads;

  setUp(() {
    downloads = FakeDownloadController();
    for (final track in _onDevice) {
      downloads.setItem(
        TrackItemKey(track.playbackId!.value),
        itemState(DownloadStatus.completed),
      );
    }
  });

  List<Override> overrides(Reachability state) => [
    ...downloads.overrides(),
    reachabilityProvider.overrideWithValue(FakeReachability(initial: state)),
    downloadedLibraryProvider.overrideWithValue(const _Downloaded()),
  ];

  Finder offlineRow(String title) =>
      find.bySemanticsLabel(RegExp('^$title,.*Not available offline\$'));

  testWidgets('offline album detail: downloaded rows enabled, the others '
      'disabled as not available offline; Play queues only the downloaded '
      'ones', (tester) async {
    final rig = PlayRig();
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([
        fixtureTrack(1),
        fixtureTrack(2),
        fixtureTrack(3),
      ]),
      overrides: [...overrides(Reachability.noNetwork), ...rig.overrides],
    );

    expect(offlineRow('Song 1.1'), findsNothing);
    expect(offlineRow('Song 1.2'), findsOneWidget);
    expect(offlineRow('Song 1.3'), findsNothing);
    await expectMeetsGuidelines(tester);

    await tester.tap(find.byKey(ActionBar.playKey));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await rig.settle(tester);
    expect(rig.queued, ['p-1-1', 'p-1-3']);
    await rig.close(tester);
  });

  testWidgets('online: no row is disabled by the offline rule', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: albumRepositories([fixtureTrack(1), fixtureTrack(2)]),
      overrides: overrides(Reachability.online),
    );
    expect(
      find.bySemanticsLabel(RegExp('Not available offline')),
      findsNothing,
    );
  });

  testWidgets('offline with nothing cached: the detail is built from the '
      'downloaded tracks', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: FakeRepositories(),
      overrides: overrides(Reachability.noNetwork),
    );
    expect(find.text('Album al-1'), findsWidgets);
    expect(find.text('Song 1.1'), findsOneWidget);
    expect(find.text('Song 1.3'), findsOneWidget);
    expect(find.text('Song 1.2'), findsNothing);
  });

  testWidgets('online with nothing cached: no detail is built', (tester) async {
    await pumpDetail(
      tester,
      _screen,
      repositories: FakeRepositories(),
      overrides: overrides(Reachability.online),
    );
    expect(find.text('This item is no longer available'), findsOneWidget);
  });
}
