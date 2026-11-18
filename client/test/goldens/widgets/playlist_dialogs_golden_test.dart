// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../../helpers/fake_repositories.dart';
import '../../helpers/golden.dart';
import '../../helpers/pump_app.dart';

/// A button that opens a dialog with [open].
Widget _launcher(void Function(BuildContext context) open) => Builder(
  builder: (context) => Center(
    child: TextButton(
      onPressed: () => open(context),
      child: const Text('open'),
    ),
  ),
);

Future<void> _open(WidgetTester tester) => tester.tap(find.text('open'));

void main() {
  const sizes = [TestSizes.compact, TestSizes.expanded];

  goldenMatrix(
    'playlist_name_dialog',
    sizes: sizes,
    builder: (_) => _launcher(
      (context) =>
          unawaited(PlaylistNameDialog.showRename(context, 'Road Trip')),
    ),
    act: _open,
  );

  goldenMatrix(
    'delete_playlist_dialog',
    sizes: sizes,
    builder: (_) => _launcher(
      (context) => unawaited(DeletePlaylistDialog.show(context, 'Road Trip')),
    ),
    act: _open,
  );

  goldenMatrix(
    'add_to_playlist_picker',
    sizes: sizes,
    builder: (_) =>
        _launcher((context) => unawaited(AddToPlaylistPicker.show(context))),
    overrides: FakeRepositories(
      playlists: FakePlaylistRepository()
        ..playlistList = [
          for (var i = 1; i <= 3; i++)
            PlaylistSummary(
              id: 'pl$i',
              name: 'Playlist $i',
              trackCount: i * 4,
              isOwner: true,
              isPublic: false,
            ),
        ],
    ).overrides,
    act: _open,
  );
}
