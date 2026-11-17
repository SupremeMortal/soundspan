// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/playlist/ui/playlist_dialogs.dart';
import 'package:soundspan/features/playlist/ui/playlist_view_model.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/actions/track_row_selection.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/mosaic_artwork.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan/shared/widgets/track_selection.dart';

/// The reserved playlist id of the user's liked tracks (doc 02, Routing).
const String likedPlaylistId = 'liked';

/// The playlist with its items, from [PlaylistRepository.playlist].
final StreamProviderFamily<Cached<PlaylistDetail>, String>
playlistDetailProvider = StreamProvider.autoDispose
    .family<Cached<PlaylistDetail>, String>(
      (ref, id) async* {
        final repository = await ref.watch(playlistRepositoryProvider.future);
        yield* withDownloadedFallback(
          ref,
          repository.playlist(id),
          (library) => library.playlistDetail(id),
        );
      },
      retry: _noRetry,
      dependencies: [
        playlistRepositoryProvider,
        showDownloadedOnlyProvider,
        downloadedLibraryProvider,
      ],
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
/// yet loaded. The owner of a playlist whose items all have a `playbackId`
/// reorders them by dragging: a drag handle on touch platforms, the row
/// itself with a pointer. Other viewers see no edit affordance.
///
/// The header's [ActionBar] plays the playlist from its start or shuffled,
/// adds its playable tracks to another playlist and opens the playlist
/// menu (Rename and Delete for the owner; a deleted playlist's page
/// closes). Liked Songs has Play and Shuffle. Each row opens the track
/// menu, with "Remove from this playlist" for the owner.
///
/// A playlist created on this device opens under its temporary id; when
/// the server assigns its id the page stays mounted, follows the new id
/// and replaces the location with it.
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
  final SelectionController<PlaylistItem> _selection =
      SelectionController<PlaylistItem>();

  String? _resolvedId;
  StreamSubscription<PlaylistIdResolved>? _resolvedSub;

  bool get _liked => widget.playlistId == likedPlaylistId;

  /// The id the page shows: the server's once a temporary id is replaced.
  String get _id => _resolvedId ?? widget.playlistId;

  @override
  void initState() {
    super.initState();
    if (!_liked) unawaited(_listenForResolvedIds());
  }

  Future<void> _listenForResolvedIds() async {
    final repository = await ref.read(playlistRepositoryProvider.future);
    if (!mounted) return;
    _resolvedSub = repository.resolvedIds.listen(_onResolved);
  }

  void _onResolved(PlaylistIdResolved event) {
    if (!mounted || event.tempId != _id) return;
    setState(() => _resolvedId = event.realId);
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    final location = router.routerDelegate.currentConfiguration.uri;
    final segments = [...location.pathSegments];
    if (segments.isEmpty || segments.last != event.tempId) return;
    segments.last = event.realId;
    // `replace` keeps the page, so the screen is not built again.
    unawaited(
      router.replace<void>(location.replace(pathSegments: segments).toString()),
    );
  }

  @override
  void didUpdateWidget(PlaylistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playlistId == _resolvedId) _resolvedId = null;
  }

  @override
  void dispose() {
    unawaited(_resolvedSub?.cancel());
    _selection.dispose();
    super.dispose();
  }

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
    final id = _id;
    final detail = ref.watch(playlistDetailProvider(id));
    return SelectionShortcuts<PlaylistItem>(
      controller: _selection,
      child: DetailPage<PlaylistDetail>(
        value: detail.whenData((cached) => cached.value),
        refreshError: detail.value?.refreshError,
        thumbnails: true,
        onRefresh: () async {
          final repository = await ref.read(playlistRepositoryProvider.future);
          await repository.refreshPlaylist(id);
          await refreshDownloadedCollection(ref, CollectionKind.playlist, id);
        },
        onRetry: () => ref.invalidate(playlistDetailProvider(id)),
        builder: _playlistSlivers,
      ),
    );
  }

  List<Widget> _playlistSlivers(BuildContext context, PlaylistDetail detail) {
    final l10n = AppLocalizations.of(context);
    final summary = detail.summary;
    final items = detail.items;
    _selection.items = items;
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
        actions: _playlistActions(detail),
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
          else if (canReorderPlaylist(detail))
            _reorderableRows(context, detail, windowClass)
          else
            _rows(
              windowClass,
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  _itemRow(detail, items[index], l10n),
            ),
        ],
      ),
    ];
  }

  Widget _itemRow(
    PlaylistDetail detail,
    PlaylistItem item,
    AppLocalizations l10n,
  ) {
    final queued = _playableTracks(detail);
    final summary = detail.summary;
    TrackActionScope scopeOf(PlaylistItem item) => TrackActionScope(
      track: item.track,
      tracks: queued,
      index: queued.indexWhere((track) => identical(track, item.track)),
      context: _contextOf(summary),
      ownedPlaylist: summary.isOwner
          ? OwnedPlaylist(playlistId: summary.id, item: item)
          : null,
      playable: item.isPlayable && item.track.playbackId != null,
    );
    final scope = scopeOf(item);
    return selectableTrackRow<PlaylistItem>(
      ref,
      selection: _selection,
      index: detail.items.indexOf(item),
      scopeOf: scopeOf,
      play: () => _playItem(detail, item),
      builder: (wiring) => _row(
        item.track,
        WindowClass.of(context),
        enabled: scope.playable,
        reason: item.message ?? l10n.trackNotPlayable,
        onTap: () => _playItem(detail, item),
        onAddToQueue: addToQueueOf(ref, item.track, playable: scope.playable),
        scope: scope,
        wiring: wiring,
      ),
    );
  }

  static List<Track> _playableTracks(PlaylistDetail detail) => [
    for (final item in detail.items)
      if (item.isPlayable) item.track,
  ];

  static QueueContext _contextOf(PlaylistSummary summary) => QueueContext(
    kind: QueueContextKind.playlist,
    id: summary.id,
    title: summary.name,
  );

  /// The [ActionBar] of an ordinary playlist.
  Widget _playlistActions(PlaylistDetail detail) {
    final summary = detail.summary;
    final playable = [
      for (final track in _playableTracks(detail))
        if (track.playbackId != null) track,
    ];
    PlayActions play() => ref.read(playActionsProvider);
    return ActionBar(
      onPlay: playable.isEmpty
          ? null
          : () => unawaited(play().playPlaylist(summary.id)),
      onShuffle: playable.isEmpty
          ? null
          : () => unawaited(play().playPlaylist(summary.id, shuffle: true)),
      download: CollectionDownloadButton.orNull(
        ref,
        kind: CollectionKind.playlist,
        refId: summary.id,
        snapshot: () => CollectionSnapshot(
          title: summary.name,
          artworkRef: summary.coverRefs.firstOrNull,
          tracks: [for (final item in detail.items) item.track],
        ),
      ),
      onAddToPlaylist: playable.isEmpty
          ? null
          : () => unawaited(addTracksToPlaylist(context, ref, playable)),
      onMenu: (position) => unawaited(
        openPlaylistMenu(
          context,
          ref,
          summary,
          position: position,
          onDeleted: (_) => _close(),
        ),
      ),
    );
  }

  /// Leaves the page of a deleted playlist: back, or to the Library.
  void _close() {
    if (!mounted) return;
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(RoutePaths.library);
    }
  }

  /// Plays the playable items of [detail] from [item].
  void _playItem(PlaylistDetail detail, PlaylistItem item) {
    final playable = [
      for (final other in detail.items)
        if (other.isPlayable) other,
    ];
    unawaited(
      ref
          .read(playActionsProvider)
          .playTracks(
            [for (final other in playable) other.track],
            startIndex: playable.indexWhere((other) => identical(other, item)),
            context: _contextOf(detail.summary),
          ),
    );
  }

  /// Plays the liked tracks loaded so far, in list order, from row [index].
  void _playLiked(PagedSnapshot<Track> snapshot, int index) {
    final loaded = snapshot.loaded.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    unawaited(
      ref
          .read(playActionsProvider)
          .playTracks(
            [for (final entry in loaded) entry.value],
            startIndex: loaded.indexWhere((entry) => entry.key == index),
            context: QueueContext(
              kind: QueueContextKind.playlist,
              id: likedPlaylistId,
              title: AppLocalizations.of(context).playlistLikedTitle,
            ),
          ),
    );
  }

  /// The owner's rows, reordered by dragging: by a trailing handle on touch
  /// platforms and by the whole row with a pointer.
  Widget _reorderableRows(
    BuildContext context,
    PlaylistDetail detail,
    WindowClass windowClass,
  ) {
    final l10n = AppLocalizations.of(context);
    final items = detail.items;
    final touch = isTouchPlatform(context);
    final viewModel = ref.read(playlistViewModelProvider(_id));
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        pageGutter(windowClass) - Spacing.x8,
        0,
        pageGutter(windowClass) - Spacing.x8,
        Spacing.x32,
      ),
      sliver: SliverReorderableList(
        itemCount: items.length,
        onReorderItem: (oldIndex, newIndex) =>
            unawaited(viewModel.reorder(items, oldIndex, newIndex)),
        itemBuilder: (context, index) {
          final item = items[index];
          final row = _itemRow(detail, item, l10n);
          if (!touch) {
            return ReorderableDragStartListener(
              key: ValueKey(item.id),
              index: index,
              child: row,
            );
          }
          return Row(
            key: ValueKey(item.id),
            children: [
              Expanded(child: row),
              ReorderableDragStartListener(
                index: index,
                child: SizedBox.square(
                  dimension: Sizes.touchTarget,
                  child: Tooltip(
                    message: l10n.playlistReorderHandle,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: context.colors.contentSecondary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
        actions: total == null || total == 0
            ? null
            : ActionBar(
                onPlay: () => unawaited(
                  ref.read(playActionsProvider).playPlaylist(likedPlaylistId),
                ),
                onShuffle: () => unawaited(
                  ref
                      .read(playActionsProvider)
                      .playPlaylist(likedPlaylistId, shuffle: true),
                ),
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
                  onTap: () => _playLiked(snapshot, index),
                  onAddToQueue: addToQueueOf(ref, track),
                  scope: _likedScope(snapshot, index, track, l10n),
                );
              },
            ),
        ],
      ),
    ];
  }

  /// The menu scope of liked row [index]: Play now plays the loaded
  /// tracks in list order from it.
  TrackActionScope _likedScope(
    PagedSnapshot<Track> snapshot,
    int index,
    Track track,
    AppLocalizations l10n,
  ) {
    final loaded = snapshot.loaded.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return TrackActionScope(
      track: track,
      tracks: [for (final entry in loaded) entry.value],
      index: loaded.indexWhere((entry) => entry.key == index),
      context: QueueContext(
        kind: QueueContextKind.playlist,
        id: likedPlaylistId,
        title: l10n.playlistLikedTitle,
      ),
    );
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
    required VoidCallback onTap,
    required VoidCallback? onAddToQueue,
    required TrackActionScope scope,
    TrackRowSelection? wiring,
  }) => TrackRow(
    title: track.meta.title,
    artist: track.meta.artist,
    album: track.meta.album,
    showAlbumColumn: windowClass == WindowClass.expanded,
    duration: Duration(seconds: track.meta.durationSec),
    leading: TrackRowLeading.thumbnail(track.meta.artworkRef),
    enabled: enabled,
    disabledReason: reason,
    liked: track.isLiked,
    onToggleLike: toggleLikeOf(ref, track),
    playbackId: track.playbackId,
    onTap: onTap,
    onAddToQueue: onAddToQueue,
    selected: wiring?.selected ?? false,
    onSelect: wiring?.onSelect,
    focusNode: wiring?.focusNode,
    rowActions: wiring?.rowActions ?? const {},
    onMenu:
        wiring?.onMenu ??
        (position) =>
            unawaited(openTrackMenu(context, ref, scope, position: position)),
  );
}

/// Reads are not retried: the repository already falls back to the cache,
/// and the error view offers Retry.
Duration? _noRetry(int retryCount, Object error) => null;
