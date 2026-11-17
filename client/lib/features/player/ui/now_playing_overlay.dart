// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/features/player/ui/now_playing_screen.dart';
import 'package:soundspan/features/player/ui/player_item.dart';
import 'package:soundspan/features/player/ui/queue_view.dart';
import 'package:soundspan/features/player/ui/right_panel.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/backdrop.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';

/// Now playing on expanded windows: the current item's large artwork,
/// title and artist over the content area, on the artwork's [Backdrop]
/// (doc 09, Now Playing, Queue, Lyrics).
///
/// The player bar's expand button shows and hides it through
/// [nowPlayingOverlayProvider]; Escape hides it too.
class NowPlayingOverlay extends ConsumerWidget {
  /// Creates the overlay.
  const new({super.key});

  /// The largest edge of the artwork.
  static const double maxArtworkSize = 480;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(playbackControllerProvider.exists)
        ? ref.watch(playbackStateProvider).value?.current
        : null;
    void close() => ref.read(nowPlayingOverlayProvider.notifier).close();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: Material(
          color: context.colors.surface,
          child: Backdrop(
            artworkRef: current?.playerArtworkRef,
            child: current == null
                ? EmptyState(
                    icon: Icons.queue_music_rounded,
                    message: l10n.queueEmpty,
                    actionLabel: l10n.nowPlayingCollapse,
                    onAction: close,
                  )
                : Padding(
                    padding: const EdgeInsets.all(Spacing.x32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nowPlayingOverline.toUpperCase(),
                          style: context.typography.overline.copyWith(
                            color: context.colors.contentSecondary,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.x24,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) => Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Artwork(
                                  ref: current.playerArtworkRef,
                                  size: math.min(
                                    maxArtworkSize,
                                    math.min(
                                      constraints.maxWidth,
                                      constraints.maxHeight,
                                    ),
                                  ),
                                  radius: Radii.large,
                                ),
                              ),
                            ),
                          ),
                        ),
                        NowPlayingTitle(
                          item: current,
                          large: true,
                          linkArtist: false,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The queue in the right-hand panel of expanded windows: a "Queue" title
/// above the [QueueView].
class QueuePanel extends StatelessWidget {
  /// Creates the panel content.
  const new({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          Spacing.x16,
          Spacing.x16,
          Spacing.x16,
          0,
        ),
        child: Semantics(
          header: true,
          child: Text(
            AppLocalizations.of(context).queueTitle,
            style: context.typography.title.copyWith(
              color: context.colors.content,
            ),
          ),
        ),
      ),
      const Expanded(child: QueueView()),
    ],
  );
}
