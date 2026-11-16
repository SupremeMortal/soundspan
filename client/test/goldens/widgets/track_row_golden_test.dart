// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

import '../../helpers/golden.dart';

const Duration _duration = Duration(minutes: 3, seconds: 41);

/// Index (liked), thumbnail (not liked), with the album column, selected,
/// disabled, and both skeletons.
Widget _rows(BuildContext context) => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TrackRow(
        title: 'Come Together',
        artist: 'The Beatles',
        album: 'Abbey Road',
        duration: _duration,
        leading: const TrackRowLeading.index(1),
        onTap: () {},
        liked: true,
        onToggleLike: () {},
      ),
      TrackRow(
        title: 'So What',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
        duration: const Duration(minutes: 9, seconds: 22),
        leading: const TrackRowLeading.thumbnail('album-2'),
        onTap: () {},
        onToggleLike: () {},
      ),
      TrackRow(
        title: 'A title far too long to fit on one line of any window',
        artist: 'An artist with a long name, featuring several others',
        album: 'An album with a long title as well',
        duration: const Duration(hours: 1, minutes: 2, seconds: 3),
        leading: const TrackRowLeading.thumbnail('album-3'),
        showAlbumColumn: true,
        onTap: () {},
      ),
      TrackRow(
        title: 'Feeling Good',
        artist: 'Nina Simone',
        album: 'I Put a Spell on You',
        duration: const Duration(minutes: 2, seconds: 53),
        leading: const TrackRowLeading.index(4),
        selected: true,
        onTap: () {},
      ),
      TrackRow(
        title: 'Not Here',
        artist: 'Somebody',
        duration: const Duration(seconds: 9),
        leading: const TrackRowLeading.index(5),
        enabled: false,
        disabledReason: 'Not available offline',
        onTap: () {},
      ),
      const TrackRowSkeleton(withThumbnail: true),
      const TrackRowSkeleton(withThumbnail: false),
    ],
  ),
);

void main() {
  goldenMatrix(
    'track_row',
    sizes: const [Size(390, 440), Size(800, 440), Size(1440, 440)],
    builder: _rows,
  );
  goldenMatrix(
    'track_row',
    sizes: const [Size(390, 720), Size(1440, 720)],
    themes: const [ThemeMode.dark],
    textScales: const [2],
    builder: _rows,
  );
}
