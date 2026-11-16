// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/providers/playlist_list.dart';
import 'package:soundspan/shared/widgets/built_range_reporter.dart';

/// The playlist list of the expanded sidebar (doc 09, Shell by Window
/// Class): Liked Songs pinned, then the user's playlists as one-line text
/// rows, scrolling inside the sidebar under the fixed destinations.
///
/// A "New playlist" row after Liked Songs names, creates and opens a
/// playlist. It reads the same paged source as the Library's Playlists
/// tab. The row
/// of [selectedPlaylistId] (`liked` for Liked Songs) is drawn selected;
/// tapping a row opens the playlist in the current branch.
class SidebarPlaylists extends ConsumerStatefulWidget {
  /// Creates the list, marking [selectedPlaylistId] selected.
  const new({this.selectedPlaylistId, super.key});

  /// The id of the playlist the window shows, or null.
  final String? selectedPlaylistId;

  /// The key of the list's scroll view.
  static const Key listKey = Key('shell.sidebarPlaylists');

  /// The key of the "New playlist" row.
  static const Key createKey = Key('shell.sidebarPlaylists.new');

  /// The height of a row at the ambient text scale.
  static double extentFor(BuildContext context) {
    final style = context.typography.body;
    final line =
        MediaQuery.textScalerOf(context).scale(style.fontSize!) *
        (style.height ?? 1);
    final content = line + Spacing.x16;
    return content > Sizes.touchTarget ? content : Sizes.touchTarget;
  }

  @override
  ConsumerState<SidebarPlaylists> createState() => _SidebarPlaylistsState();
}

class _SidebarPlaylistsState extends ConsumerState<SidebarPlaylists> {
  late final BuiltRangeReporter _reporter = BuiltRangeReporter(
    (first, last) =>
        ref.read(playlistListSourceProvider).value?.ensureVisible(first, last),
  );

  @override
  void dispose() {
    _reporter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(playlistListProvider).value;
    final extent = SidebarPlaylists.extentFor(context);
    final selected = widget.selectedPlaylistId;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l10n.sidebarPlaylistsLabel,
      child: CustomScrollView(
        key: SidebarPlaylists.listKey,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.x8,
              0,
              Spacing.x8,
              Spacing.x8,
            ),
            sliver: SliverFixedExtentList.builder(
              itemExtent: extent,
              itemCount: 2 + (snapshot?.total ?? 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _SidebarPlaylistRow(
                    name: l10n.libraryLikedSongs,
                    selected: selected == 'liked',
                    onTap: () =>
                        DetailNavigation.openPlaylist(context, 'liked'),
                  );
                }
                if (index == 1) {
                  return _SidebarPlaylistRow(
                    key: SidebarPlaylists.createKey,
                    name: l10n.playlistNew,
                    icon: Icons.add_rounded,
                    selected: false,
                    onTap: () => unawaited(createPlaylistAndOpen(context, ref)),
                  );
                }
                _reporter.built(index - 2);
                final playlist = snapshot?.itemAt(index - 2);
                if (playlist == null) return const SizedBox.shrink();
                return _SidebarPlaylistRow(
                  name: playlist.name,
                  selected: selected == playlist.id,
                  onTap: () =>
                      DetailNavigation.openPlaylist(context, playlist.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarPlaylistRow extends StatelessWidget {
  const new({
    required this.name,
    required this.selected,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? colors.surfaceActive : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.small),
        child: InkWell(
          onTap: onTap,
          hoverColor: colors.surfaceHover,
          borderRadius: BorderRadius.circular(Radii.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.x16),
            child: Row(
              children: [
                if (icon case final icon?) ...[
                  Icon(icon, size: 20, color: colors.contentSecondary),
                  const SizedBox(width: Spacing.x8),
                ],
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typography.body.copyWith(
                      color: selected
                          ? colors.content
                          : colors.contentSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
