// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../features/detail_fixtures.dart';
import '../../helpers/fake_repositories.dart';
import '../../helpers/golden.dart';

void main() {
  final repositories = FakeRepositories();
  repositories.playlists.playlistDetails['pl-1'] = PlaylistDetail(
    summary: const PlaylistSummary(
      id: 'pl-1',
      name: 'Road Trip',
      trackCount: 4,
      isOwner: true,
      isPublic: true,
      coverRefs: ['cover-1', 'cover-2', 'cover-3', 'cover-4'],
    ),
    items: [
      for (var n = 1; n <= 4; n++)
        PlaylistItem(
          id: 'item-$n',
          sort: n,
          track: fixtureTrack(n, artworkRef: 'cover-$n'),
          isPlayable: n != 3,
          message: n == 3 ? 'This track is no longer available' : null,
        ),
    ],
  );
  goldenMatrix(
    'playlist',
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: const PlaylistScreen(playlistId: 'pl-1'),
    ),
    overrides: repositories.overrides,
  );
}
