// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// The width from which the [trackRowSamples] show the album column, as
/// screens do on expanded windows.
const double trackRowSamplesAlbumColumnWidth = 1200;

/// [TrackRow]s with an index, with a thumbnail, with text too long for the
/// row, and one disabled row, in a padded column; the album column is shown
/// when the window is at least [trackRowSamplesAlbumColumnWidth] wide.
///
/// Track text is server text, shown as received in every locale.
Widget trackRowSamples(BuildContext context) {
  final showAlbumColumn =
      MediaQuery.sizeOf(context).width >= trackRowSamplesAlbumColumnWidth;
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrackRow(
          title: 'Come Together',
          artist: 'The Beatles',
          album: 'Abbey Road',
          duration: const Duration(minutes: 4, seconds: 20),
          leading: const TrackRowLeading.index(1),
          showAlbumColumn: showAlbumColumn,
          onTap: () {},
        ),
        TrackRow(
          title: 'Café Società',
          artist: 'Ñandú Ørkestær',
          album: 'Ĉanzoni',
          duration: const Duration(minutes: 9, seconds: 22),
          leading: const TrackRowLeading.thumbnail('album-2'),
          showAlbumColumn: showAlbumColumn,
          onTap: () {},
        ),
        TrackRow(
          title:
              'A title far too long to fit on one line of any window, '
              'even the widest one a desktop offers',
          artist: 'An artist with a long name, featuring several others',
          album: 'An album with a long title as well, in two volumes',
          duration: const Duration(hours: 1, minutes: 2, seconds: 3),
          leading: const TrackRowLeading.thumbnail('album-3'),
          showAlbumColumn: showAlbumColumn,
          onTap: () {},
        ),
        TrackRow(
          title: 'Not Here',
          artist: 'Somebody',
          album: 'Elsewhere',
          duration: const Duration(seconds: 9),
          leading: const TrackRowLeading.index(124),
          showAlbumColumn: showAlbumColumn,
          enabled: false,
          disabledReason: 'Not available offline',
          onTap: () {},
        ),
      ],
    ),
  );
}
