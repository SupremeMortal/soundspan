// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';

import '../../helpers/golden.dart';

/// [bar] in a [WindowClassScope] for the window, with the page gutter.
Widget _scoped(Widget bar) => Builder(
  builder: (context) => WindowClassScope(
    windowClass: windowClassOf(MediaQuery.sizeOf(context)),
    child: Padding(padding: const EdgeInsets.all(16), child: bar),
  ),
);

const List<Size> _barSizes = [Size(390, 120), Size(800, 100), Size(1440, 100)];

/// The entries of an owned playlist's menu, for the menu images.
List<MenuEntry> _entries() => [
  for (final (id, label, icon) in [
    ('playNow', 'Play now', Icons.play_arrow_rounded),
    ('playNext', 'Play next', Icons.playlist_play_rounded),
    ('addToQueue', 'Add to queue', Icons.queue_music_rounded),
    ('share', 'Share link', Icons.link_rounded),
    ('rename', 'Rename', Icons.edit_rounded),
  ])
    MenuEntry(id: id, label: label, icon: icon, onSelected: () {}),
  MenuEntry(
    id: 'delete',
    label: 'Delete',
    icon: Icons.delete_outline_rounded,
    destructive: true,
    onSelected: () {},
  ),
];

void main() {
  goldenMatrix(
    'action_bar_album',
    sizes: _barSizes,
    builder: (_) => _scoped(
      ActionBar(
        onPlay: () {},
        onShuffle: () {},
        liked: true,
        onToggleLike: () {},
        onAddToPlaylist: () {},
        onMenu: (_) {},
      ),
    ),
  );

  goldenMatrix(
    'action_bar_playlist_owner',
    sizes: _barSizes,
    builder: (_) => _scoped(
      ActionBar(
        onPlay: () {},
        onShuffle: () {},
        onAddToPlaylist: () {},
        onMenu: (_) {},
      ),
    ),
  );

  goldenMatrix(
    'action_bar_artist',
    sizes: _barSizes,
    builder: (_) =>
        _scoped(ActionBar(onPlay: () {}, onShuffle: () {}, onMenu: (_) {})),
  );

  // The menu as a bottom sheet on a phone and as a popup at the pointer on
  // a desktop-sized window (a desktop platform).
  for (final (size, platform) in [
    (const Size(390, 640), TargetPlatform.android),
    (const Size(1440, 640), TargetPlatform.linux),
  ]) {
    goldenMatrix(
      'context_menu_${platform == TargetPlatform.android ? 'sheet' : 'popup'}',
      sizes: [size],
      builder: (_) => Builder(
        builder: (context) => Align(
          alignment: Alignment.topLeft,
          child: TextButton(
            onPressed: () => unawaited(
              showContextMenu(
                context,
                _entries(),
                position: const Offset(120, 80),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      act: (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        await tester.tap(find.text('open'));
      },
    );
  }
}
