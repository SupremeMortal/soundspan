// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/mixes/domain/mix_detail.dart';
import 'package:soundspan/features/mixes/mixes_providers.dart';
import 'package:soundspan/features/mixes/ui/mix_view_model.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/actions/track_row_selection.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan/shared/widgets/offline_banner.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan/shared/widgets/track_selection.dart';
import 'package:soundspan_api/soundspan_api.dart' show FeatureDisabled;

/// The page of a generated mix of Made For You (`/mix/:mixId`; doc 09,
/// Home and Album, Artist, Playlist).
///
/// Built only while the server has `autoPlaylists` on: otherwise, and when
/// the server answers `FeatureDisabled` (which also requests a capability
/// refresh), the page shows the neutral "Not available on this server"
/// view, without calling the API while the capability is off.
///
/// The header is the playlist page's: the mosaic of the first four covers,
/// the "Mix" overline, the name, the description and "N songs · duration".
/// Its [ActionBar] plays the mix from its start or shuffled, saves it as a
/// playlist ([saveMixAsPlaylist]; disabled while no track is playable) and
/// opens a menu with Play next and Add to queue. A mix has no Download and
/// no Like action. The rows have thumbnails and the album column on
/// expanded windows, open the track menu, and play the mix from the row;
/// with a pointer they are a selectable list (doc 09, Desktop Interaction:
/// Selection).
/// The offline banner sits above the page.
class MixDetailScreen extends ConsumerWidget {
  /// Creates the page of mix [mixId].
  const new({required this.mixId, super.key});

  /// The server's mix id.
  final String mixId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(mixesEnabledProvider);
    return RouteTitle(
      screen: l10n.screenMix,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: enabled ? _MixPage(mixId: mixId) : const _NotAvailable(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The neutral view of a server without mixes.
class _NotAvailable extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverAppBar(
        pinned: true,
        automaticallyImplyLeading:
            WindowClass.of(context) != WindowClass.expanded,
        scrolledUnderElevation: 0,
      ),
      SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.auto_awesome_outlined,
          message: AppLocalizations.of(context).mixNotAvailable,
        ),
      ),
    ],
  );
}

class _MixPage extends ConsumerWidget {
  const new({required this.mixId});

  final String mixId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(mixDetailProvider(mixId));
    if (detail.error is FeatureDisabled) return const _NotAvailable();
    return SelectableList<ListedTrack>(
      builder: (context, selection) => DetailPage<MixDetail>(
        value: detail.whenData((cached) => cached.value),
        refreshError: detail.value?.refreshError,
        thumbnails: true,
        onRefresh: () async {
          final repository = await ref.read(mixRepositoryProvider.future);
          await repository.refreshMix(mixId);
        },
        onRetry: () => ref.invalidate(mixDetailProvider(mixId)),
        builder: (context, mix) => _slivers(context, ref, mix, selection),
      ),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    WidgetRef ref,
    MixDetail mix,
    SelectionController<ListedTrack> selection,
  ) {
    selection.items = listedTracks(mix.tracks);
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final compact = windowClass == WindowClass.compact;
    final total = Duration(
      seconds: mix.tracks.fold(0, (sum, track) => sum + track.meta.durationSec),
    );
    final description = mix.description;
    return [
      DetailHeader(
        artworkRef: mix.artworkRefs.firstOrNull,
        artworkBuilder: (size) =>
            MosaicArtwork(refs: mix.artworkRefs.take(4).toList(), size: size),
        overline: l10n.mixOverline,
        title: mix.name,
        metadata: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              Text(
                description,
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: context.typography.body.copyWith(
                  color: context.colors.contentSecondary,
                ),
              ),
              const SizedBox(height: Spacing.x4),
            ],
            DetailMetadataLine(
              parts: [
                l10n.detailSongCount(mix.tracks.length),
                formatTotalDuration(l10n, total),
              ],
            ),
          ],
        ),
        actions: _actions(context, ref, mix),
        slivers: [
          if (mix.tracks.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.x32),
              sliver: SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.queue_music_rounded,
                  message: l10n.mixEmpty,
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                pageGutter(windowClass) - Spacing.x8,
                0,
                pageGutter(windowClass) - Spacing.x8,
                Spacing.x32,
              ),
              sliver: SliverList.builder(
                itemCount: mix.tracks.length,
                itemBuilder: (context, index) =>
                    _row(context, ref, mix, index, windowClass, selection),
              ),
            ),
        ],
      ),
    ];
  }

  Widget _actions(BuildContext context, WidgetRef ref, MixDetail mix) {
    final l10n = AppLocalizations.of(context);
    final playable = playableMixTracks(mix);
    PlayActions play() => ref.read(playActionsProvider);
    Future<void> playMix({required bool shuffle}) => play().playCollection(
      playable,
      context: mixQueueContext(mix),
      shuffle: shuffle,
    );
    return ActionBar(
      onPlay: playable.isEmpty
          ? null
          : () => unawaited(playMix(shuffle: false)),
      onShuffle: playable.isEmpty
          ? null
          : () => unawaited(playMix(shuffle: true)),
      saveAsPlaylist: true,
      onSaveAsPlaylist: playable.isEmpty
          ? null
          : () => unawaited(saveMixAsPlaylist(context, ref, mix)),
      onMenu: playable.isEmpty
          ? null
          : (position) => unawaited(
              showContextMenu(context, [
                MenuEntry(
                  id: MenuIds.playNext,
                  label: l10n.menuPlayNext,
                  icon: Icons.playlist_play_rounded,
                  onSelected: () => unawaited(play().playNext(playable)),
                ),
                MenuEntry(
                  id: MenuIds.addToQueue,
                  label: l10n.menuAddToQueue,
                  icon: Icons.queue_music_rounded,
                  onSelected: () => unawaited(play().addToQueue(playable)),
                ),
              ], position: position),
            ),
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref,
    MixDetail mix,
    int index,
    WindowClass windowClass,
    SelectionController<ListedTrack> selection,
  ) {
    final l10n = AppLocalizations.of(context);
    final track = mix.tracks[index];
    final playable = track.playbackId != null;
    final queued = playableMixTracks(mix);
    TrackActionScope scopeOf(ListedTrack row) => TrackActionScope(
      track: row.$2,
      tracks: queued,
      index: queued.indexWhere((other) => identical(other, row.$2)),
      context: mixQueueContext(mix),
      playable: row.$2.playbackId != null,
    );
    void play() => unawaited(
      ref
          .read(playActionsProvider)
          .playTracks(
            mix.tracks,
            startIndex: index,
            context: mixQueueContext(mix),
          ),
    );
    return selectableTrackRow<ListedTrack>(
      ref,
      selection: selection,
      index: index,
      scopeOf: scopeOf,
      play: play,
      builder: (wiring) => TrackRow(
        title: track.meta.title,
        artist: track.meta.artist,
        album: track.meta.album,
        showAlbumColumn: windowClass == WindowClass.expanded,
        duration: Duration(seconds: track.meta.durationSec),
        leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
        enabled: playable,
        disabledReason: l10n.trackNotPlayable,
        liked: track.isLiked,
        onToggleLike: toggleLikeOf(ref, track),
        playbackId: track.playbackId,
        onTap: play,
        onAddToQueue: addToQueueOf(ref, track, playable: playable),
        selected: wiring.selected,
        onSelect: wiring.onSelect,
        focusNode: wiring.focusNode,
        rowActions: wiring.rowActions,
        onMenu: wiring.onMenu,
        dragPayload: wiring.dragPayload,
      ),
    );
  }
}
