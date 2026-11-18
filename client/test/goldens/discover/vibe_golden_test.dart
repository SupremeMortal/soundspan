// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/playback/engines/player_engine.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/profile/capabilities.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/features/vibe/ui/vibe_screen.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_vibe_repository.dart';
import '../../helpers/golden.dart';

class _VibeOn extends ServerCapabilitiesNotifier {
  @override
  ServerCapabilities build() => ServerCapabilities(
    serverVersion: Version.tryParse('2.7.0'),
    hasP6SelfRevoke: true,
    hasP7PlayMarker: true,
    hasP8PlayedAt: true,
    audioAnalysis: true,
    vibe: true,
  );
}

const List<(String, String, String)> _songs = [
  ('Low Tide', 'Aurora Vale', 'Shorelines'),
  ('Glass Rooms', 'The Night Shift', 'After Hours'),
  ('Slow Bloom', 'Marisol', 'Garden Light'),
  ('Paper Moons', 'Paper Lanterns', 'Lanterns'),
  ('Northbound', 'Kestrel & Co', 'Field Notes'),
  ('Undertow', 'Ondine', 'Deep Water'),
];

List<Track> _tracks(String prefix) => [
  for (final (index, (title, artist, album)) in _songs.indexed)
    Track(
      meta: TrackMeta(
        title: title,
        artist: artist,
        album: album,
        durationSec: 180 + index * 23,
        artworkRef: 'cover-$prefix-$index',
      ),
      playbackId: index == 3 ? null : PlaybackId('pb-$prefix-$index'),
      libraryTrackId: '$prefix-$index',
    ),
];

const Track _seed = Track(
  meta: TrackMeta(
    title: 'Evening Haze',
    artist: 'Aurora Vale',
    album: 'Shorelines',
    durationSec: 241,
    artworkRef: 'cover-seed',
  ),
  playbackId: PlaybackId('pb-seed'),
  libraryTrackId: 'seed',
);

List<Override> _overrides({required bool playing}) {
  final vibe = FakeVibeRepository()
    ..searchTracks = _tracks('found')
    ..similarTracks = _tracks('near');
  final snapshot = PlaybackSnapshot(
    queue: QueueState.empty(),
    status: EngineStatus.idle,
    playing: false,
    current: playing
        ? const QueueItem.track(
            queueItemId: 'q-seed',
            track: _seed,
            context: QueueContext(kind: QueueContextKind.library),
          )
        : null,
  );
  return [
    vibe.providerOverride,
    serverCapabilitiesProvider.overrideWith(_VibeOn.new),
    playbackStateProvider.overrideWith((ref) => Stream.value(snapshot)),
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
    'vibe_search',
    builder: (context) => _scoped(context, const VibeScreen()),
    overrides: _overrides(playing: false),
    act: (tester) async {
      await tester.enterText(find.byKey(VibeScreen.searchKey), 'rainy piano');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    },
  );

  goldenMatrix(
    'vibe_similar',
    builder: (context) => _scoped(context, const VibeScreen()),
    overrides: _overrides(playing: true),
  );
}
