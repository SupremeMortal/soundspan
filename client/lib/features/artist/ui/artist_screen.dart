// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/placeholder_screen.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/shell/window_class.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// The artist with albums, top tracks, similar artists and biography, from
/// [LibraryRepository.artist].
final StreamProviderFamily<Cached<ArtistDetail>, String> artistDetailProvider =
    StreamProvider.autoDispose.family<Cached<ArtistDetail>, String>(
      (ref, id) async* {
        final repository = await ref.watch(libraryRepositoryProvider.future);
        yield* repository.artist(id);
      },
      retry: _noRetry,
      dependencies: [libraryRepositoryProvider],
    );

/// The artist page (`/artist/:artistId`; doc 09, Album, Artist, Playlist).
///
/// A [DetailHeader] with round artwork, "Artist", the name and up to three
/// genres, then Popular (five top tracks, expandable to ten), Albums,
/// Singles and EPs, Similar Artists (only those the library holds) and
/// About (the biography as plain text, collapsed to three lines). Each
/// section is hidden when it has no content. Read-only: rows do nothing on
/// tap, and a track without a playback id is disabled as not playable.
class ArtistScreen extends ConsumerWidget {
  /// Creates the page of artist [artistId].
  const new({required this.artistId, super.key});

  /// The server's artist id.
  final String artistId;

  /// How many popular tracks show before "Show more".
  static const int popularCollapsed = 5;

  /// How many popular tracks show at most.
  static const int popularExpanded = 10;

  /// How many genres the metadata line shows at most.
  static const int maxGenres = 3;

  /// How many lines the collapsed biography shows.
  static const int biographyLines = 3;

  /// The key of the biography text.
  static const Key biographyKey = ValueKey('ArtistScreen.biography');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(artistDetailProvider(artistId));
    return RouteTitle(
      screen: l10n.screenArtist,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: DetailPage<ArtistDetail>(
          value: detail.whenData((cached) => cached.value),
          refreshError: detail.value?.refreshError,
          onRefresh: () async {
            final repository = await ref.read(libraryRepositoryProvider.future);
            await repository.refreshArtist(artistId);
          },
          onRetry: () => ref.invalidate(artistDetailProvider(artistId)),
          builder: _slivers,
        ),
      ),
    );
  }

  List<Widget> _slivers(BuildContext context, ArtistDetail detail) {
    final l10n = AppLocalizations.of(context);
    final artist = detail.artist;
    final albums = <Album>[];
    final singles = <Album>[];
    for (final album in detail.albums) {
      (isSingleOrEp(album.releaseType) ? singles : albums).add(album);
    }
    final similar = [
      for (final other in detail.similarArtists)
        if (other.libraryId != null) other,
    ];
    final biography = plainBiography(detail.biography ?? '');

    Widget shelf(String title, List<Album> items) => _ShelfSection(
      child: Shelf(
        title: title,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final album = items[index];
          return Consumer(
            builder: (context, ref, _) => MediaCard(
              title: album.title,
              subtitle: album.year?.toString() ?? album.artistName,
              artworkRef: album.artworkRef,
              onTap: () => DetailNavigation.openAlbum(context, album.id),
              onPlay: () =>
                  unawaited(ref.read(playActionsProvider).playAlbum(album.id)),
              onMenu: (position) => unawaited(
                openAlbumMenu(
                  context,
                  ref,
                  album,
                  position: position,
                  onArtistPage: true,
                ),
              ),
            ),
          );
        },
      ),
    );

    return [
      DetailHeader(
        artworkRef: artist.artworkRef,
        artworkShape: ArtworkShape.circle,
        overline: l10n.artistOverline,
        title: artist.name,
        metadata: DetailMetadataLine(
          parts: detail.genres.take(maxGenres).toList(),
        ),
        actions: Consumer(
          builder: (context, ref, _) {
            final playable = detail.topTracks.any(
              (track) => track.playbackId != null,
            );
            PlayActions play() => ref.read(playActionsProvider);
            return ActionBar(
              onPlay: playable
                  ? () => unawaited(play().playArtist(artist.id))
                  : null,
              onShuffle: playable
                  ? () => unawaited(play().playArtist(artist.id, shuffle: true))
                  : null,
              onMenu: (position) => unawaited(
                showContextMenu(
                  context,
                  artistActions(
                    artist.id,
                    l10n: l10n,
                    commands: AppMenuCommands(context, ref),
                  ),
                  position: position,
                ),
              ),
            );
          },
        ),
        slivers: [
          if (detail.topTracks.isNotEmpty)
            _PopularSection(tracks: detail.topTracks, artist: artist),
          if (albums.isNotEmpty) shelf(l10n.artistAlbums, albums),
          if (singles.isNotEmpty) shelf(l10n.artistSinglesAndEps, singles),
          if (similar.isNotEmpty)
            _ShelfSection(
              child: Shelf(
                title: l10n.artistSimilar,
                itemCount: similar.length,
                itemBuilder: (context, index) {
                  final other = similar[index];
                  return MediaCard(
                    title: other.name,
                    subtitle: l10n.artistCardSubtitle,
                    artworkRef: other.artworkRef,
                    shape: ArtworkShape.circle,
                    onTap: () =>
                        DetailNavigation.openArtist(context, other.libraryId!),
                  );
                },
              ),
            ),
          if (biography.isNotEmpty)
            SliverToBoxAdapter(child: _Biography(text: biography)),
          const SliverToBoxAdapter(child: SizedBox(height: Spacing.x32)),
        ],
      ),
    ];
  }
}

/// Whether [releaseType] names a single or an EP; any other value, or none,
/// is an album.
bool isSingleOrEp(String? releaseType) =>
    switch (releaseType?.trim().toLowerCase()) {
      'single' || 'ep' => true,
      _ => false,
    };

/// [raw] without markup: tags are removed and the common character
/// entities decoded, so a biography shows as plain text.
String plainBiography(String raw) => raw
    .replaceAll(RegExp('<[^>]*>'), '')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&')
    .trim();

/// A shelf with the space the page puts above it.
class _ShelfSection extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.only(top: Spacing.x24),
    sliver: SliverToBoxAdapter(child: child),
  );
}

/// A section title with an optional text button at the end.
class _SectionHeader extends StatelessWidget {
  const new({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    final gutter = pageGutter(WindowClass.of(context));
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, Spacing.x24, gutter, Spacing.x8),
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
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    );
  }
}

/// The Popular section: the first five [tracks], or up to ten once
/// expanded.
class _PopularSection extends StatefulWidget {
  const new({required this.tracks, required this.artist});

  final List<Track> tracks;
  final Artist artist;

  @override
  State<_PopularSection> createState() => _PopularSectionState();
}

class _PopularSectionState extends State<_PopularSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gutter = pageGutter(WindowClass.of(context));
    final tracks = widget.tracks;
    final expandable = tracks.length > ArtistScreen.popularCollapsed;
    final shown = math.min(
      tracks.length,
      _expanded ? ArtistScreen.popularExpanded : ArtistScreen.popularCollapsed,
    );
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: l10n.artistPopular,
            action: expandable
                ? (_expanded ? l10n.artistShowLess : l10n.artistShowMore)
                : null,
            onAction: () => setState(() => _expanded = !_expanded),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
          sliver: SliverList.builder(
            itemCount: shown,
            itemBuilder: (context, index) {
              final track = tracks[index];
              final artist = track.meta.artist;
              final queueContext = QueueContext(
                kind: QueueContextKind.artist,
                id: widget.artist.id,
                title: widget.artist.name,
              );
              return Consumer(
                builder: (context, ref, _) => TrackRow(
                  title: track.meta.title,
                  artist: artist == widget.artist.name ? '' : artist,
                  duration: Duration(seconds: track.meta.durationSec),
                  leading: TrackRowLeading.index(index + 1),
                  enabled: track.playbackId != null,
                  disabledReason: l10n.trackNotPlayable,
                  liked: track.isLiked,
                  onToggleLike: toggleLikeOf(ref, track),
                  playbackId: track.playbackId,
                  onTap: () => unawaited(
                    ref
                        .read(playActionsProvider)
                        .playTracks(
                          tracks.sublist(0, shown),
                          startIndex: index,
                          context: queueContext,
                        ),
                  ),
                  onAddToQueue: addToQueueOf(ref, track),
                  onMenu: (position) => unawaited(
                    openTrackMenu(
                      context,
                      ref,
                      TrackActionScope(
                        track: track,
                        tracks: tracks.sublist(0, shown),
                        index: index,
                        context: queueContext,
                      ),
                      position: position,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// The About section: [text] collapsed to three lines, with "Read more"
/// when it does not fit.
class _Biography extends StatefulWidget {
  const new({required this.text});

  final String text;

  @override
  State<_Biography> createState() => _BiographyState();
}

class _BiographyState extends State<_Biography> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final style = context.typography.body.copyWith(
      color: colors.contentSecondary,
    );
    final gutter = pageGutter(WindowClass.of(context));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max<double>(0, constraints.maxWidth - gutter * 2);
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: ArtistScreen.biographyLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: width);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(title: l10n.artistAbout),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Text(
                widget.text,
                key: ArtistScreen.biographyKey,
                maxLines: _expanded ? null : ArtistScreen.biographyLines,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: style,
              ),
            ),
            if (overflows || _expanded)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? l10n.artistShowLess : l10n.artistReadMore,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Reads are not retried: the repository already falls back to the cache,
/// and the error view offers Retry.
Duration? _noRetry(int retryCount, Object error) => null;
