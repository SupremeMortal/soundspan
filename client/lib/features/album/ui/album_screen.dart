// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

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
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/widgets/action_bar.dart';
import 'package:soundspan/shared/widgets/detail_header.dart';
import 'package:soundspan/shared/widgets/detail_page.dart';
import 'package:soundspan/shared/widgets/media_card.dart';
import 'package:soundspan/shared/widgets/shelf.dart';
import 'package:soundspan/shared/widgets/track_row.dart';

/// The album with its tracks, from [LibraryRepository.album].
final StreamProviderFamily<Cached<AlbumDetail>, String> albumDetailProvider =
    StreamProvider.autoDispose.family<Cached<AlbumDetail>, String>(
      (ref, id) async* {
        final repository = await ref.watch(libraryRepositoryProvider.future);
        yield* repository.album(id);
      },
      retry: _noRetry,
      dependencies: [libraryRepositoryProvider],
    );

/// The loaded albums of the artist named by the argument, in list order.
final StreamProviderFamily<List<Album>, String> artistAlbumsProvider =
    StreamProvider.autoDispose.family<List<Album>, String>(
      (ref, artistId) async* {
        final repository = await ref.watch(libraryRepositoryProvider.future);
        final source = repository.albums(AlbumQuery(artistId: artistId));
        ref.onDispose(source.dispose);
        source.ensureVisible(0, 0);
        yield* source.watch().map(
          (snapshot) => [
            for (var index = 0; index < (snapshot.total ?? 0); index++)
              ?snapshot.itemAt(index),
          ],
        );
      },
      retry: _noRetry,
      dependencies: [libraryRepositoryProvider],
    );

/// The album page (`/album/:albumId`; doc 09, Album, Artist, Playlist).
///
/// A [DetailHeader] with the album's cover, release type, title and
/// "Artist · Year · N songs · duration" (the artist opens the artist page),
/// then the tracks grouped by disc ("Disc N" only with more than one disc)
/// and a "More by this artist" shelf. Tapping a row plays the album from
/// that track ([PlayActions.playTracks], context `album`); a track without
/// a playback id is disabled as not playable. The shelf's cards play their
/// album from the play button.
///
/// The header's [ActionBar] plays the album from its start or shuffled,
/// likes it, adds its playable tracks to a playlist and opens the album
/// menu; Play, Shuffle and Add to playlist are left out when no track is
/// playable. Each row and card opens its menu ([trackActions],
/// [albumActions]).
class AlbumScreen extends ConsumerWidget {
  /// Creates the page of album [albumId].
  const new({required this.albumId, super.key});

  /// The server's album id.
  final String albumId;

  /// The key of the group header over the tracks of disc [number].
  static Key discHeaderKey(int number) => ValueKey('AlbumScreen.disc.$number');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(albumDetailProvider(albumId));
    return RouteTitle(
      screen: l10n.screenAlbum,
      child: Scaffold(
        backgroundColor: context.colors.surface,
        body: DetailPage<AlbumDetail>(
          value: detail.whenData((cached) => cached.value),
          refreshError: detail.value?.refreshError,
          onRefresh: () async {
            final repository = await ref.read(libraryRepositoryProvider.future);
            await repository.refreshAlbum(albumId);
            await refreshDownloadedCollection(
              ref,
              CollectionKind.album,
              albumId,
            );
          },
          onRetry: () => ref.invalidate(albumDetailProvider(albumId)),
          builder: (context, detail) => _slivers(context, ref, detail),
        ),
      ),
    );
  }

  List<Widget> _slivers(
    BuildContext context,
    WidgetRef ref,
    AlbumDetail detail,
  ) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final album = detail.album;
    final tracks = detail.tracks;
    final gutter = pageGutter(WindowClass.of(context));
    final total = Duration(
      seconds: tracks.fold(0, (sum, track) => sum + track.meta.durationSec),
    );
    final discs = <int, List<Track>>{};
    for (final track in tracks) {
      (discs[track.discNumber ?? 1] ??= []).add(track);
    }
    final grouped = discs.length > 1;
    final ordered = [for (final disc in discs.values) ...disc];
    final queueContext = QueueContext(
      kind: QueueContextKind.album,
      id: album.id,
      title: album.title,
    );
    void play(Track track) => unawaited(
      ref
          .read(playActionsProvider)
          .playTracks(
            ordered,
            startIndex: ordered.indexWhere((t) => identical(t, track)),
            context: queueContext,
          ),
    );
    final playable = [
      for (final track in ordered)
        if (track.playbackId != null) track,
    ];
    final liked = album.preference == Preference.liked;
    final more = [
      for (final other
          in ref.watch(artistAlbumsProvider(album.artistId)).value ??
              const <Album>[])
        if (other.id != album.id) other,
    ];

    return [
      DetailHeader(
        artworkRef: album.artworkRef,
        overline: album.releaseType ?? l10n.albumOverline,
        title: album.title,
        metadata: DetailMetadataLine(
          link: album.artistName,
          onLink: () => DetailNavigation.openArtist(context, album.artistId),
          parts: [
            if (album.year case final year?) '$year',
            l10n.detailSongCount(tracks.length),
            formatTotalDuration(l10n, total),
          ],
        ),
        actions: ActionBar(
          onPlay: playable.isEmpty
              ? null
              : () => unawaited(
                  ref.read(playActionsProvider).playAlbum(album.id),
                ),
          onShuffle: playable.isEmpty
              ? null
              : () => unawaited(
                  ref
                      .read(playActionsProvider)
                      .playAlbum(album.id, shuffle: true),
                ),
          download: CollectionDownloadButton.orNull(
            ref,
            kind: CollectionKind.album,
            refId: album.id,
            snapshot: () => CollectionSnapshot(
              title: album.title,
              subtitle: album.artistName,
              artworkRef: album.artworkRef,
              tracks: ordered,
            ),
          ),
          liked: liked,
          onToggleLike: () => unawaited(
            ref.read(albumLikesProvider).setAlbumLiked(album.id, liked: !liked),
          ),
          onAddToPlaylist: playable.isEmpty
              ? null
              : () => unawaited(addTracksToPlaylist(context, ref, playable)),
          onMenu: (position) =>
              unawaited(openAlbumMenu(context, ref, album, position: position)),
        ),
        slivers: [
          for (final MapEntry(key: disc, value: discTracks)
              in discs.entries) ...[
            if (grouped)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  Spacing.x16,
                  gutter,
                  Spacing.x8,
                ),
                sliver: SliverToBoxAdapter(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l10n.albumDisc(disc),
                      key: discHeaderKey(disc),
                      style: typography.subtitle.copyWith(
                        color: colors.contentSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: gutter - Spacing.x8),
              sliver: SliverList.builder(
                itemCount: discTracks.length,
                itemBuilder: (context, index) {
                  final track = discTracks[index];
                  final artist = track.meta.artist;
                  return TrackRow(
                    title: track.meta.title,
                    artist: artist == album.artistName ? '' : artist,
                    duration: Duration(seconds: track.meta.durationSec),
                    leading: TrackRowLeading.index(
                      track.trackNumber ?? index + 1,
                    ),
                    enabled: track.playbackId != null,
                    disabledReason: l10n.trackNotPlayable,
                    liked: track.isLiked,
                    onToggleLike: toggleLikeOf(ref, track),
                    playbackId: track.playbackId,
                    onTap: () => play(track),
                    onAddToQueue: addToQueueOf(ref, track),
                    onMenu: (position) => unawaited(
                      openTrackMenu(
                        context,
                        ref,
                        TrackActionScope(
                          track: track,
                          tracks: ordered,
                          index: ordered.indexWhere((t) => identical(t, track)),
                          context: queueContext,
                        ),
                        position: position,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          SliverPadding(
            padding: const EdgeInsets.only(
              top: Spacing.x24,
              bottom: Spacing.x32,
            ),
            sliver: SliverToBoxAdapter(
              child: Shelf(
                title: l10n.albumMoreByArtist,
                itemCount: more.length,
                itemBuilder: (context, index) {
                  final other = more[index];
                  return MediaCard(
                    title: other.title,
                    subtitle: other.year?.toString() ?? other.artistName,
                    artworkRef: other.artworkRef,
                    onTap: () => DetailNavigation.openAlbum(context, other.id),
                    onPlay: () => unawaited(
                      ref.read(playActionsProvider).playAlbum(other.id),
                    ),
                    onMenu: (position) => unawaited(
                      openAlbumMenu(context, ref, other, position: position),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

/// Reads are not retried: the repository already falls back to the cache,
/// and the error view offers Retry.
Duration? _noRetry(int retryCount, Object error) => null;
