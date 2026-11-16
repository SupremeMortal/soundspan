// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/avatar_menu.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/features/search/domain/search_sections.dart';
import 'package:soundspan/features/search/ui/search_view_model.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/empty_state.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// Search (doc 09, Search): a field, filter chips, and the results of the
/// library and catalogue searches merged into one set of sections, with
/// the recent searches while the field is empty.
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

  /// The query from the route, if any.
  final String? query;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _field = TextEditingController(
    text: widget.query ?? '',
  );
  Timer? _debounce;
  late String _query = (widget.query ?? '').trim();
  SearchScope _scope = SearchScope.all;
  final Set<SearchSectionKind> _expanded = {};

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
    super.dispose();
  }

  void _setQuery(String query) {
    setState(() {
      _query = query;
      _expanded.clear();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final windowClass = WindowClass.of(context);
    final gutter = _gutter(windowClass);
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
    String label(SearchScope scope) => switch (scope) {
      SearchScope.all => l10n.searchScopeAll,
      SearchScope.library => l10n.searchScopeLibrary,
      SearchScope.discover => l10n.searchScopeDiscover,
      SearchScope.podcasts => l10n.searchScopePodcasts,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: gutter, vertical: Spacing.x4),
      child: Row(
        children: [
          for (final scope in SearchScope.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: Spacing.x8),
              child: ChoiceChip(
                label: Text(label(scope)),
                selected: _scope == scope,
                onSelected: (_) => setState(() {
                  _scope = scope;
                  _expanded.clear();
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _results(BuildContext context, double gutter) {
    final l10n = AppLocalizations.of(context);
    final requests = searchRequests(_query, _scope);
    final parts = {
      for (final request in requests)
        request: ref.watch(searchPartProvider(request)),
    };
    final includesPlaylists =
        _scope == SearchScope.all || _scope == SearchScope.library;
    final playlists = includesPlaylists
        ? ref.watch(searchPlaylistsProvider).value ?? const <PlaylistSummary>[]
        : const <PlaylistSummary>[];
    final outcome = searchOutcome(
      query: _query,
      scope: _scope,
      parts: parts,
      playlists: playlists,
    );
    return switch (outcome) {
      SearchLoading() => _Skeletons(gutter: gutter),
      SearchNothingFound() => EmptyState(
        icon: Icons.search_off_rounded,
        message: l10n.searchNoResults(_query),
      ),
      SearchFailed(:final error) => ErrorView(
        error: error,
        onRetry: () => retrySearch(ref, _query, _scope),
      ),
      SearchFound(:final sections) => ListView(
        padding: const EdgeInsets.only(bottom: Spacing.x24),
        children: [
          if (sections.topResult case final top?)
            _Section(
              title: l10n.searchTopResult,
              gutter: gutter,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: _TopResult(item: top, onOpened: _opened),
              ),
            ),
          for (final section in sections.sections)
            _Section(
              title: _sectionTitle(l10n, section.kind),
              gutter: gutter,
              expanded: section.hasMore
                  ? _expanded.contains(section.kind)
                  : null,
              onToggle: () => setState(() {
                if (!_expanded.remove(section.kind)) {
                  _expanded.add(section.kind);
                }
              }),
              child: _SectionItems(
                kind: section.kind,
                items: _expanded.contains(section.kind)
                    ? section.items
                    : section.preview,
                gutter: gutter,
                onOpened: _opened,
              ),
            ),
        ],
      ),
    };
  }
}

String _sectionTitle(AppLocalizations l10n, SearchSectionKind kind) =>
    switch (kind) {
      SearchSectionKind.songs => l10n.searchSectionSongs,
      SearchSectionKind.artists => l10n.searchSectionArtists,
      SearchSectionKind.albums => l10n.searchSectionAlbums,
      SearchSectionKind.playlists => l10n.searchSectionPlaylists,
      SearchSectionKind.podcasts => l10n.searchSectionPodcasts,
    };

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

/// A titled section; [expanded] non-null adds "Show all" or "Show less".
class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.gutter,
    required this.child,
    this.expanded,
    this.onToggle,
  });

  final String title;
  final double gutter;
  final Widget child;
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expanded = this.expanded;
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.title.copyWith(
                        color: context.colors.content,
                      ),
                    ),
                  ),
                ),
                if (expanded != null)
                  TextButton(
                    onPressed: onToggle,
                    child: Text(
                      expanded ? l10n.searchShowLess : l10n.searchShowAll,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.x8),
          child,
        ],
      ),
    );
  }
}

/// The rows or cards of one section.
class _SectionItems extends StatelessWidget {
  const new({
    required this.kind,
    required this.items,
    required this.gutter,
    required this.onOpened,
  });

  final SearchSectionKind kind;
  final List<SearchItem> items;
  final double gutter;
  final ValueChanged<VoidCallback> onOpened;

  @override
  Widget build(BuildContext context) {
    if (kind == SearchSectionKind.songs) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              _songRow(context, (item as SearchTrackItem).track),
          ],
        ),
      );
    }
    final height = MediaCard.extentFor(context, width: Shelf.cardWidth);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter - MediaCard.padding),
      child: Wrap(
        children: [
          for (final item in items)
            SizedBox(
              width: Shelf.cardWidth,
              height: height,
              child: _card(context, item, onOpened),
            ),
        ],
      ),
    );
  }
}

Widget _songRow(BuildContext context, Track track) => Consumer(
  builder: (context, ref, _) => TrackRow(
    title: track.meta.title,
    artist: track.meta.artist,
    album: track.meta.album,
    duration: Duration(seconds: track.meta.durationSec),
    leading: TrackRowThumbnail(track.meta.artworkRef),
    enabled: track.playbackId != null,
    disabledReason: AppLocalizations.of(context).searchNotPlayable,
    liked: track.isLiked,
    onToggleLike: toggleLikeOf(ref, track),
  ),
);

/// The card of [item]; it opens a page only when the item has one.
Widget _card(
  BuildContext context,
  SearchItem item,
  ValueChanged<VoidCallback> onOpened,
) {
  final l10n = AppLocalizations.of(context);
  return switch (item) {
    SearchTrackItem(:final track) => MediaCard(
      title: track.meta.title,
      subtitle: track.meta.artist.isEmpty
          ? l10n.searchKindSong
          : track.meta.artist,
      artworkRef: track.meta.artworkRef,
    ),
    SearchArtistItem(:final artist, :final libraryId) => MediaCard(
      title: artist.name,
      subtitle: l10n.searchKindArtist,
      artworkRef: artist.artworkRef,
      shape: ArtworkShape.circle,
      onTap: libraryId == null
          ? null
          : () =>
                onOpened(() => DetailNavigation.openArtist(context, libraryId)),
    ),
    SearchAlbumItem(:final album, :final libraryId) => MediaCard(
      title: album.title,
      subtitle: album.artistName,
      artworkRef: album.artworkRef,
      onTap: libraryId == null
          ? null
          : () =>
                onOpened(() => DetailNavigation.openAlbum(context, libraryId)),
    ),
    SearchPlaylistItem(:final playlist) => MediaCard(
      title: playlist.name,
      subtitle: l10n.searchPlaylistSongs(playlist.trackCount),
      artworkRef: null,
      mosaicRefs: playlist.coverRefs,
      onTap: () =>
          onOpened(() => DetailNavigation.openPlaylist(context, playlist.id)),
    ),
    SearchPodcastItem(:final podcast) => MediaCard(
      title: podcast.title,
      subtitle: podcast.author ?? l10n.searchKindPodcast,
      artworkRef: podcast.artworkRef,
    ),
  };
}

/// The top result as one large card.
class _TopResult extends StatelessWidget {
  const new({required this.item, required this.onOpened});

  /// The width of the card.
  static const double width = 220;

  final SearchItem item;
  final ValueChanged<VoidCallback> onOpened;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: _gutter(WindowClass.of(context)) - MediaCard.padding,
    ),
    child: SizedBox(
      width: width,
      height: MediaCard.extentFor(context, width: width),
      child: _card(context, item, onOpened),
    ),
  );
}

/// Section skeletons while no request has answered.
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
