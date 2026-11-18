// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/features/album/album.dart';
import 'package:soundspan/shared/providers/tint.dart';

import '../../features/detail_fixtures.dart';
import '../../helpers/fake_tint_extractor.dart';
import '../../helpers/golden.dart';

void main() {
  goldenMatrix(
    'album',
    builder: (context) => WindowClassScope(
      windowClass: windowClassOf(MediaQuery.sizeOf(context)),
      child: const AlbumScreen(albumId: 'al-1'),
    ),
    overrides: [
      ...albumRepositories(
        [
          fixtureTrack(1),
          fixtureTrack(2, artist: 'A Guest'),
          fixtureTrack(3),
          fixtureTrack(1, disc: 2),
          fixtureTrack(2, disc: 2, playable: false),
        ],
        others: [fixtureAlbum('al-2'), fixtureAlbum('al-3')],
      ).overrides,
      tintExtractorProvider.overrideWithValue(
        AsyncData(FakeTintExtractor({'cover-al-1': const Color(0xFF7C3AED)})),
      ),
    ],
  );
}
