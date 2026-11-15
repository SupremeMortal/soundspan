// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// The reserved playlist id of the user's liked tracks (doc 02, Routing).
const String likedPlaylistId = 'liked';

/// The playlist with its items, from [PlaylistRepository.playlist].
final StreamProviderFamily<Cached<PlaylistDetail>, String>
playlistDetailProvider = StreamProvider.autoDispose
    .family<Cached<PlaylistDetail>, String>(
      (ref, id) async* {
        final repository = await ref.watch(playlistRepositoryProvider.future);
        yield* repository.playlist(id);
      },
      retry: _noRetry,
      dependencies: [playlistRepositoryProvider],
    );

/// The paged source of the liked tracks, disposed with the page.
final FutureProvider<PagedSource<Track>> likedTracksSourceProvider =
    FutureProvider.autoDispose<PagedSource<Track>>(
      (ref) async {
        final repository = await ref.watch(libraryRepositoryProvider.future);
        final source = repository.likedTracks();
        ref.onDispose(source.dispose);
        source.ensureVisible(0, 0);
        return source;
      },
      retry: _noRetry,
      dependencies: [libraryRepositoryProvider],
    );

/// Every state of [likedTracksSourceProvider].
final StreamProvider<PagedSnapshot<Track>> likedTracksProvider =
    StreamProvider.autoDispose<PagedSnapshot<Track>>(
      (ref) async* {
        yield* (await ref.watch(likedTracksSourceProvider.future)).watch();
      },
      retry: _noRetry,
      dependencies: [likedTracksSourceProvider],
    );

/// The playlist page (`/playlist/:playlistId`; doc 09, Album, Artist,
/// Playlist).
///
/// An ordinary id shows a [DetailHeader] with the playlist's mosaic, name
/// and "N songs · duration[ · Public]", then its items in the server's
/// order as rows with thumbnails (and the album column on expanded
/// windows). An item the server cannot play is disabled with the server's
/// message. The reserved id [likedPlaylistId] shows Liked Songs from the
/// paged [LibraryRepository.likedTracks], with skeleton rows for pages not
/// yet loaded. Read-only: no editing controls, and rows do nothing on tap.
class PlaylistScreen extends ConsumerStatefulWidget {
  /// Creates the page of playlist [playlistId].
  const new({required this.playlistId, super.key});

  /// The server's playlist id, or [likedPlaylistId].
  final String playlistId;

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  int? _first;
  int? _last;
  bool _reportScheduled = false;

  bool get _liked => widget.playlistId == likedPlaylistId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RouteTitle(
      screen: _liked ? l10n.playlistLikedTitle : l10n.screenPlaylist,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: _liked ? _likedPage() : _playlistPage(),
      ),
    );
  }

  Widget _playlistPage() {
    final id = widget.playlistId;
    final detail = ref.watch(playlistDetailProvider(id));
    return DetailPage<PlaylistDetail>(
      value: detail.whenData((cached) => cached.value),
      refreshError: detail.value?.refreshError,
      thumbnails: true,
      onRefresh: () async {
        final repository = await ref.read(playlistRepositoryProvider.future);
        await repository.refreshPlaylist(id);
      },
      onRetry: () => ref.invalidate(playlistDetailProvider(id)),
      builder: _playlistSlivers,
    );
  }

  List<Widget> _playlistSlivers(BuildContext context, PlaylistDetail detail) {
    final l10n = AppLocalizations.of(context);
    final summary = detail.summary;
    final items = detail.items;
    final windowClass = WindowClass.of(context);
    final total = Duration(
      seconds: items.fold(0, (sum, item) => sum + item.track.meta.durationSec),
    );
    return [
      DetailHeader(
        artworkRef: summary.coverRefs.firstOrNull,
        artworkBuilder: (size) =>
            MosaicArtwork(refs: summary.coverRefs, size: size),
        overline: l10n.playlistOverline,
        title: summary.name,
        metadata: DetailMetadataLine(
          parts: [
            l10n.detailSongCount(items.length),
            formatTotalDuration(l10n, total),
            if (summary.isPublic) l10n.playlistPublic,
          ],
        ),
        slivers: [
          if (items.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.x32),
              sliver: SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.queue_music_rounded,
                  message: l10n.playlistEmpty,
                ),
              ),
            )
          else
            _rows(
              windowClass,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _row(
                  item.track,
                  windowClass,
                  enabled: item.isPlayable && item.track.playbackId != null,
                  reason: item.message ?? l10n.trackNotPlayable,
                );
              },
            ),
        ],
      ),
    ];
  }

  Widget _likedPage() {
    final snapshot = ref.watch(likedTracksProvider);
    return DetailPage<PagedSnapshot<Track>>(
      value: snapshot,
      refreshError: snapshot.value?.refreshError,
      thumbnails: true,
      onRefresh: () async {
        final source = await ref.read(likedTracksSourceProvider.future);
        await source.refresh();
      },
      onRetry: () => ref.invalidate(likedTracksSourceProvider),
      builder: _likedSlivers,
    );
  }

  List<Widget> _likedSlivers(
    BuildContext context,
    PagedSnapshot<Track> snapshot,
  ) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final total = snapshot.total;
    return [
      DetailHeader(
        artworkRef: null,
        overline: l10n.playlistOverline,
        title: l10n.playlistLikedTitle,
        metadata: DetailMetadataLine(
          parts: [if (total != null) l10n.detailSongCount(total)],
        ),
        slivers: [
          if (total == 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.x32),
              sliver: SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.favorite_border_rounded,
                  message: l10n.playlistEmpty,
                ),
              ),
            )
          else
            _rows(
              windowClass,
              itemCount: total ?? 0,
              itemExtent: TrackRow.extentFor(context, withThumbnail: true),
              itemBuilder: (context, index) {
                _built(index);
                final track = snapshot.itemAt(index);
                if (track == null) {
                  return const TrackRowSkeleton(withThumbnail: true);
                }
                return _row(
                  track,
                  windowClass,
                  enabled: track.playbackId != null,
                  reason: l10n.trackNotPlayable,
                );
              },
            ),
        ],
      ),
    ];
  }

  /// Records that row [index] was built, and tells the liked source the
  /// built range once the frame is done.
  void _built(int index) {
    _first = math.min(_first ?? index, index);
    _last = math.max(_last ?? index, index);
    if (_reportScheduled) return;
    _reportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reportScheduled = false;
      final (first, last) = (_first, _last);
      _first = _last = null;
      if (!mounted || first == null || last == null) return;
      ref.read(likedTracksSourceProvider).value?.ensureVisible(first, last);
    });
  }

  Widget _rows(
    WindowClass windowClass, {
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    double? itemExtent,
  }) => SliverPadding(
    padding: EdgeInsets.fromLTRB(
      pageGutter(windowClass) - Spacing.x8,
      0,
      pageGutter(windowClass) - Spacing.x8,
      Spacing.x32,
    ),
    sliver: itemExtent == null
        ? SliverList.builder(itemCount: itemCount, itemBuilder: itemBuilder)
        : SliverFixedExtentList.builder(
            itemExtent: itemExtent,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
  );

  Widget _row(
    Track track,
    WindowClass windowClass, {
    required bool enabled,
    required String reason,
  }) => TrackRow(
    title: track.meta.title,
    artist: track.meta.artist,
    album: track.meta.album,
    showAlbumColumn: windowClass == WindowClass.expanded,
    duration: Duration(seconds: track.meta.durationSec),
    leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
    enabled: enabled,
    disabledReason: reason,
  );
}

/// Reads are not retried: the repository already falls back to the cache,
/// and the error view offers Retry.
Duration? _noRetry(int retryCount, Object error) => null;
