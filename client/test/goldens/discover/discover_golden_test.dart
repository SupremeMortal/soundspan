// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_notice.dart';
import 'package:soundspan/features/discover/discover.dart';
import 'package:soundspan/features/home/home.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_discovery_repository.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/golden.dart';

class _DiscoveryOn extends ServerCapabilitiesNotifier {
  @override
  ServerCapabilities build() => ServerCapabilities(
    serverVersion: Version.tryParse('2.7.0'),
    hasP6SelfRevoke: true,
    hasP7PlayMarker: true,
    hasP8PlayedAt: true,
    autoPlaylists: true,
    discovery: true,
  );
}

class _NoNotice extends VersionNoticeController {
  @override
  Future<VersionNotice?> build() async => null;
}

const List<String> _names = [
  'Aurora Vale',
  'The Night Shift',
  'Marisol',
  'Kestrel & Co',
  'Ondine',
  'Paper Lanterns',
];

List<Override> _overrides() {
  final discovery = FakeDiscoveryRepository()
    ..playlist = DiscoveryPlaylist(
      tracks: [
        for (var n = 1; n <= 12; n++)
          Track(
            meta: TrackMeta(
              title: 'Discovery track $n',
              artist: _names[n % _names.length],
              album: 'Album $n',
              durationSec: 180 + n * 7,
              artworkRef: 'cover-$n',
            ),
            playbackId: n.isEven ? null : PlaybackId('pb-$n'),
          ),
      ],
    )
    ..recommended = [
      for (final (index, name) in _names.indexed)
        DiscoveryArtist(
          name: name,
          artworkRef: 'artist-$index',
          libraryArtistId: 'ar-$index',
        ),
    ]
    ..popular = [
      for (final (index, name) in _names.reversed.indexed)
        DiscoveryArtist(name: name, artworkRef: 'chart-$index'),
    ];
  final repositories = FakeRepositories();
  repositories.home
    ..added = const [Artist(id: 'a1', name: 'Björk', artworkRef: 'a1')]
    ..mixList = const [
      MixSummary(id: 'm1', name: 'Daily Mix 1', description: 'Upbeat'),
    ];
  return [
    ...repositories.overrides,
    discovery.providerOverride,
    serverCapabilitiesProvider.overrideWith(_DiscoveryOn.new),
    versionNoticeProvider.overrideWith(_NoNotice.new),
    profilesProvider.overrideWith((ref) => Stream.value(const <Profile>[])),
    initialActiveProfileIdProvider.overrideWithValue(null),
  ];
}

Widget _scoped(BuildContext context, Widget child) => WindowClassScope(
  windowClass: windowClassOf(MediaQuery.sizeOf(context)),
  child: child,
);

void main() {
  goldenMatrix(
    'explore',
    builder: (context) => _scoped(context, const ExploreScreen()),
    overrides: _overrides(),
  );

  goldenMatrix(
    'home_discovery',
    sizes: const [Size(1440, 1400)],
    themes: const [ThemeMode.dark],
    builder: (context) => _scoped(context, const HomeScreen()),
    overrides: _overrides(),
  );
}
