// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The place of the `PlayerBar` on expanded windows: a [height] panel of
/// `surfaceRaised` across the bottom, separated from the panels above by
/// [Spacing.x8] of `ground`. Nothing is drawn inside it yet.
class PlayerBarSlot extends StatelessWidget {
  /// Creates the slot.
  const new({super.key});

  /// The height of the player bar.
  static const double height = 96;

  /// The key of the panel.
  static const Key panelKey = Key('shell.playerBar');

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Spacing.x8, 0, Spacing.x8, Spacing.x8),
    child: SizedBox(
      key: panelKey,
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceRaised,
          borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
        ),
      ),
    ),
  );
}

/// The place of the `MiniPlayer` on compact and medium windows. It has no
/// height, because the mini player appears only when a queue exists.
class MiniPlayerSlot extends StatelessWidget {
  /// Creates the slot.
  const new({super.key});

  /// The key of the slot.
  static const Key slotKey = Key('shell.miniPlayer');

  @override
  Widget build(BuildContext context) =>
      const SizedBox(key: slotKey, height: 0, width: double.infinity);
}
