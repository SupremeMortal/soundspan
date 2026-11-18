// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/shortcuts/search_focus.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/search/ui/search_view_model.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/actions/track_row_selection.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_row.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan/shared/widgets/track_selection.dart';

/// Search (doc 09, Search): a field, filter chips (All, Songs, Artists,
/// Albums, Playlists, Podcasts) and one list of results ranked by
/// relevance, with the recent searches while the field is empty. All mixes
/// every kind, each row labelled with its kind; every other chip lists one
/// kind and loads further pages as the list scrolls.
///
/// The query follows the route (`/search?q=`). On expanded windows the top
/// bar's field is the search field and the screen has none of its own.
class SearchScreen extends ConsumerStatefulWidget {
  /// Creates the screen searching [query], the route's `q`.
  const new({this.query, super.key});

  /// How long typing pauses before the results update.
  static const Duration debounce = Duration(milliseconds: 300);

  /// The key of the screen's search field.
  static const Key fieldKey = Key('search.field');

  /// The key of the "Results from this device" label shown while offline.
  static const Key deviceResultsKey = Key('search.deviceResults');

  /// The query from the route, if any.
  final String? query;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _field = TextEditingController(
    text: widget.query ?? '',
  );
  final FocusNode _fieldFocus = FocusNode(debugLabel: 'search.field');
  Timer? _debounce;
  late String _query = (widget.query ?? '').trim();
  SearchFilter _filter = SearchFilter.all;

  /// How many pages of a single-kind filter are requested.
  int _pageCount = 1;

  @override
  void initState() {
    super.initState();
    // The search shortcut opened Search: focus the field once it is built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeFocusRequest());
  }

  void _takeFocusRequest() {
    if (!mounted) return;
    if (ref.read(searchFocusRequestProvider.notifier).take()) {
      _fieldFocus.requestFocus();
    }
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = (widget.query ?? '').trim();
    if (widget.query != oldWidget.query && query != _query) {
      _debounce?.cancel();
      if (_field.text.trim() != query) _field.text = query;
      _setQuery(query);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  void _setQuery(String query) {
    setState(() {
      _query = query;
      _pageCount = 1;
    });
  }

  /// Searches [text] now, mirrors it to the route and, when [record] is
  /// set, remembers it.
  void _run(String text, {bool record = false}) {
    _debounce?.cancel();
    final query = text.trim();
    if (query != _query) {
      _setQuery(query);
      GoRouter.of(context).go(
        Uri(
          path: RoutePaths.search,
          queryParameters: query.isEmpty ? null : {'q': query},
        ).toString(),
      );
    }
    if (record) unawaited(recordSearch(ref, query));
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(SearchScreen.debounce, () => _run(text));
    setState(() {});
  }

  void _clear() {
    _field.clear();
    _run('');
  }

  void _runRecent(String query) {
    _field.text = query;
    _run(query, record: true);
  }

  /// Remembers the query, then runs [open].
  void _opened(VoidCallback open) {
    unawaited(recordSearch(ref, _query));
    open();
  }

  /// Requests the next page of a single-kind filter.
  void _loadMore() {
    if (mounted) setState(() => _pageCount++);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final gutter = _gutter(windowClass);
    ref.listen(searchFocusRequestProvider, (_, requested) {
      // After the frame that shows Search, when it was hidden.
      if (requested) {
        WidgetsBinding.instance
          ..addPostFrameCallback((_) => _takeFocusRequest())
          ..scheduleFrame();
      }
    });
    return RouteTitle(
      screen: l10n.navSearch,
      child: Scaffold(
        appBar: windowClass == WindowClass.compact
            ? AppBar(
                title: Text(l10n.navSearch),
                actions: const [AvatarButton()],
              )
            : null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (windowClass != WindowClass.expanded)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Spacing.x8,
                  gutter,
                  Spacing.x8,
                ),
                child: _searchField(context, windowClass),
              ),
            if (_query.isNotEmpty) _chips(context, gutter),
            Expanded(
              child: _query.isEmpty
                  ? _Recent(onRun: _runRecent, gutter: gutter)
                  : _results(context, gutter),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context, WindowClass windowClass) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return TextField(
      key: SearchScreen.fieldKey,
      controller: _field,
      focusNode: _fieldFocus,
      autofocus: windowClass == WindowClass.compact,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      onSubmitted: (text) => _run(text, record: true),
      style: context.typography.body.copyWith(color: colors.content),
      decoration: InputDecoration(
        hintText: l10n.searchFieldHint,
        hintStyle: context.typography.body.copyWith(
          color: colors.contentSecondary,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: colors.contentSecondary),
        suffixIcon: _field.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                tooltip: l10n.searchClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: colors.surfaceHover,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.large)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _chips(BuildContext context, double gutter) {
    final l10n = AppLocalizations.of(context);
    String label(SearchFilter filter) => switch (filter) {
      SearchFilter.all => l10n.searchFilterAll,
      SearchFilter.songs => l10n.searchFilterSongs,
      SearchFilter.artists => l10n.searchFilterArtists,
      SearchFilter.albums => l10n.searchFilterAlbums,
      SearchFilter.playlists => l10n.searchFilterPlaylists,
      SearchFilter.podcasts => l10n.searchFilterPodcasts,
    };
    final filters = _filters(ref.watch(isOfflineProvider));
    final current = _effectiveFilter(filters);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Spacing.x4),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Spacing.x8),
              child: ChoiceChip(
                label: Text(label(filter)),
                selected: current == filter,
                onSelected: (_) => setState(() {
                  _filter = filter;
                  _pageCount = 1;
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// The filters offered: while offline every one but Podcasts, which this
  /// device cannot answer.
  static List<SearchFilter> _filters(bool offline) => [
    for (final filter in SearchFilter.values)
      if (!offline || filter != SearchFilter.podcasts) filter,
  ];

  /// The chosen filter, or All when it is not offered now.
  SearchFilter _effectiveFilter(List<SearchFilter> offered) =>
      offered.contains(_filter) ? _filter : SearchFilter.all;

  Widget _results(BuildContext context, double gutter) {
    if (ref.watch(isOfflineProvider)) return _localResults(context, gutter);
    final l10n = AppLocalizations.of(context);
    final requests = searchRequests(_query, _filter, _pageCount);
    final pages = [
      for (final request in requests) ref.watch(searchPageProvider(request)),
    ];
    return switch (searchOutcome(pages)) {
      SearchLoading() => _Skeletons(gutter: gutter),
      SearchNothingFound() => EmptyState(
        icon: Icons.search_off_rounded,
        message: l10n.searchNoResults(_query),
      ),
      SearchFailed(:final error) => ErrorView(
        error: error,
        onRetry: () => retrySearch(ref, requests),
      ),
      SearchFound(
        :final results,
        :final hasMore,
        :final loadingMore,
        :final moreError,
      ) =>
        _list(
          context,
          results,
          gutter,
          more: _filter == SearchFilter.all || !hasMore
              ? null
              : loadingMore
              ? _More.loading
              : moreError != null
              ? _More.failed
              : _More.available,
          onRetryMore: () => retrySearch(ref, requests),
        ),
    };
  }

  /// The results of the query from this device only, labelled "Results
  /// from this device"; no request reaches the server.
  Widget _localResults(BuildContext context, double gutter) {
    final l10n = AppLocalizations.of(context);
    final local = ref.watch(localSearchProvider(_query));
    final found = local.value;
    if (found == null) {
      if (local.error case final error?) {
        return ErrorView(
          error: error,
          onRetry: () => ref.invalidate(localSearchProvider(_query)),
        );
      }
      return _Skeletons(gutter: gutter);
    }
    final filter = _effectiveFilter(_filters(true));
    final results = [
      for (final result in found)
        if (filter.admits(result.hit)) result,
    ];
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        message: l10n.searchNoResults(_query),
      );
    }
    return _list(
      context,
      results,
      gutter,
      label: l10n.searchResultsFromDevice,
      filter: filter,
    );
  }

  /// One list of [results] in order, songs as [TrackRow]s and everything
  /// else as [MediaRow]s, with [label] above and the [more] footer below.
  Widget _list(
    BuildContext context,
    List<SearchResult> results,
    double gutter, {
    String? label,
    SearchFilter? filter,
    _More? more,
    VoidCallback? onRetryMore,
  }) {
    final tracks = <Track>[];
    final trackIndex = <int?>[];
    for (final result in results) {
      if (result.hit case TrackHit(:final track)) {
        trackIndex.add(tracks.length);
        tracks.add(track);
      } else {
        trackIndex.add(null);
      }
    }
    final labelKinds = (filter ?? _filter) == SearchFilter.all;
    return SelectableList<ListedTrack>(
      builder: (context, selection) {
        selection.items = listedTracks(tracks);
        return CustomScrollView(
          slivers: [
            if (label != null)
              SliverToBoxAdapter(
                child: Padding(
                  key: SearchScreen.deviceResultsKey,
                  padding: EdgeInsets.fromLTRB(gutter, Spacing.x8, gutter, 0),
                  child: Text(
                    label,
                    style: context.typography.body.copyWith(
                      color: context.colors.contentSecondary,
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                gutter - Spacing.x8,
                Spacing.x8,
                gutter - Spacing.x8,
                Spacing.x24,
              ),
              sliver: SliverList.builder(
                itemCount: results.length + (more == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (index == results.length) {
                    return switch (more!) {
                      _More.loading => const TrackRowSkeleton(
                        withThumbnail: true,
                      ),
                      _More.available => _LoadMore(
                        key: ValueKey(_pageCount),
                        onVisible: _loadMore,
                      ),
                      _More.failed => _MoreFailed(onRetry: onRetryMore!),
                    };
                  }
                  final result = results[index];
                  if (trackIndex[index] case final position?) {
                    return _songRow(
                      context,
                      tracks,
                      position,
                      selection,
                      labelKind: labelKinds,
                    );
                  }
                  return _mediaRow(context, result, _opened);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

double _gutter(WindowClass windowClass) => switch (windowClass) {
  WindowClass.compact => Gutters.compact,
  WindowClass.medium => Gutters.medium,
  WindowClass.expanded => Gutters.expanded,
};

/// The recent searches, or an invitation to search when there are none.
class _Recent extends ConsumerWidget {
  const new({required this.onRun, required this.gutter});

  final ValueChanged<String> onRun;
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final recent = ref.watch(searchRecentProvider).value ?? const <String>[];
    if (recent.isEmpty) {
      return EmptyState(icon: Icons.search_rounded, message: l10n.searchPrompt);
    }
    return ListView(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, Spacing.x8, gutter, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.searchRecentTitle,
                    style: context.typography.title.copyWith(
                      color: colors.content,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => unawaited(clearRecentSearches(ref)),
                child: Text(l10n.searchRecentClearAll),
              ),
            ],
          ),
        ),
        for (final query in recent)
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: gutter - Spacing.x4,
            ),
            leading: Icon(
              Icons.history_rounded,
              color: colors.contentSecondary,
            ),
            title: Text(
              query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typography.body.copyWith(color: colors.content),
            ),
            onTap: () => onRun(query),
            trailing: IconButton(
              onPressed: () => unawaited(removeRecentSearch(ref, query)),
              tooltip: l10n.searchRecentRemove(query),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
      ],
    );
  }
}

/// What ends a list of a single-kind filter.
enum _More {
  /// The next page is in flight.
  loading,

  /// The server holds more: loading starts when the footer is built.
  available,

  /// The next page failed.
  failed,
}

/// A row skeleton that requests the next page once it is built, that is
/// once the list scrolls near its end.
class _LoadMore extends StatefulWidget {
  const new({required this.onVisible, super.key});

  final VoidCallback onVisible;

  @override
  State<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends State<_LoadMore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) =>
      const TrackRowSkeleton(withThumbnail: true);
}

/// The end of a list whose next page failed: a message and Retry.
class _MoreFailed extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.x8,
        vertical: Spacing.x8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.searchMoreFailed,
              style: context.typography.bodySmall.copyWith(
                color: context.colors.contentSecondary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(l10n.searchMoreRetry)),
        ],
      ),
    );
  }
}

/// Song row [index] of [tracks], playing [tracks] from that song; with a
/// pointer the rows are a selectable list (doc 09, Desktop Interaction:
/// Selection). With [labelKind] the second line starts with "Song".
Widget _songRow(
  BuildContext context,
  List<Track> tracks,
  int index,
  SelectionController<ListedTrack> selection, {
  required bool labelKind,
}) {
  final track = tracks[index];
  final l10n = AppLocalizations.of(context);
  final artist = !labelKind
      ? track.meta.artist
      : track.meta.artist.isEmpty
      ? l10n.searchKindSong
      : l10n.searchResultSubtitle(l10n.searchKindSong, track.meta.artist);
  return Consumer(
    builder: (context, ref, _) {
      void play() => unawaited(
        ref
            .read(playActionsProvider)
            .playTracks(tracks, startIndex: index, context: _searchContext),
      );
      return selectableTrackRow<ListedTrack>(
        ref,
        selection: selection,
        index: index,
        scopeOf: (row) => TrackActionScope(
          track: row.$2,
          tracks: tracks,
          index: row.$1,
          context: _searchContext,
        ),
        play: play,
        builder: (wiring) => TrackRow(
          title: track.meta.title,
          artist: artist,
          album: track.meta.album,
          duration: Duration(seconds: track.meta.durationSec),
          leading: TrackRowThumbnail(track.meta.artworkRef),
          enabled: track.playbackId != null,
          disabledReason: l10n.searchNotPlayable,
          liked: track.isLiked,
          onToggleLike: toggleLikeOf(ref, track),
          playbackId: track.playbackId,
          onTap: play,
          onAddToQueue: addToQueueOf(ref, track),
          selected: wiring.selected,
          onSelect: wiring.onSelect,
          focusNode: wiring.focusNode,
          rowActions: wiring.rowActions,
          onMenu: wiring.onMenu,
          dragPayload: wiring.dragPayload,
        ),
      );
    },
  );
}

/// The context of tracks played from search results.
const QueueContext _searchContext = QueueContext(kind: QueueContextKind.search);

/// The row of an artist, album, playlist or podcast [result]; its second
/// line starts with its kind. An artist or album opens its page, plays and
/// has a menu only when the library holds it; a playlist always does.
Widget _mediaRow(
  BuildContext context,
  SearchResult result,
  ValueChanged<VoidCallback> onOpened,
) => Consumer(
  builder: (context, ref, _) {
    final l10n = AppLocalizations.of(context);
    String subtitle(String kind, String? detail) =>
        detail == null || detail.isEmpty
        ? kind
        : l10n.searchResultSubtitle(kind, detail);
    PlayActions actions() => ref.read(playActionsProvider);
    final inLibrary = result.source == SearchResultSource.library;
    return switch (result.hit) {
      TrackHit() => const SizedBox.shrink(),
      ArtistHit(:final artist) => MediaRow(
        title: artist.name,
        subtitle: l10n.searchKindArtist,
        artworkRef: artist.artworkRef,
        shape: ArtworkShape.circle,
        onTap: inLibrary
            ? () => onOpened(
                () => DetailNavigation.openArtist(context, artist.id),
              )
            : null,
      ),
      AlbumHit(:final album) => MediaRow(
        title: album.title,
        subtitle: subtitle(l10n.searchKindAlbum, album.artistName),
        artworkRef: album.artworkRef,
        onTap: inLibrary
            ? () =>
                  onOpened(() => DetailNavigation.openAlbum(context, album.id))
            : null,
        dragPayload: inLibrary
            ? AlbumPayload(album.id, album.title, null)
            : null,
        onPlay: inLibrary
            ? () => unawaited(actions().playAlbum(album.id))
            : null,
        onMenu: inLibrary
            ? (position) => unawaited(
                openAlbumMenu(context, ref, album, position: position),
              )
            : null,
      ),
      PlaylistHit(:final playlist) => MediaRow(
        title: playlist.name,
        subtitle: subtitle(
          l10n.searchKindPlaylist,
          l10n.searchPlaylistSongs(playlist.trackCount),
        ),
        mosaicRefs: playlist.coverRefs,
        onTap: () =>
            onOpened(() => DetailNavigation.openPlaylist(context, playlist.id)),
        onPlay: () => unawaited(actions().playPlaylist(playlist.id)),
        onMenu: (position) => unawaited(
          openPlaylistMenu(context, ref, playlist, position: position),
        ),
      ),
      PodcastHit(:final podcast) => MediaRow(
        title: podcast.title,
        subtitle: subtitle(l10n.searchKindPodcast, podcast.author),
        artworkRef: podcast.artworkRef,
      ),
    };
  },
);

/// Row skeletons while the first page has not answered.
class _Skeletons extends StatelessWidget {
  const new({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.symmetric(
      horizontal: gutter - Spacing.x8,
      vertical: Spacing.x16,
    ),
    children: [
      for (var index = 0; index < 6; index++)
        const TrackRowSkeleton(withThumbnail: true),
    ],
  );
}
