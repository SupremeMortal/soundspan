// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The one definition of the track, album, playlist and artist menus (doc
/// 09, Track Actions: one definition, every surface).
///
/// Each function answers the [MenuEntry]s of one entity in their fixed
/// order. An entry is left out, never disabled, when it cannot work. The
/// effects go through [MenuCommands], so the definitions are plain values
/// a test can read without pumping a widget. No definition branches on
/// where a track comes from.
library;

import 'dart:async';

import 'package:material_ui/material_ui.dart' show Icons;
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

/// The entry ids of the menus, in no particular order.
abstract final class MenuIds {
  /// Play now.
  static const String playNow = 'playNow';

  /// Play next.
  static const String playNext = 'playNext';

  /// Add to queue.
  static const String addToQueue = 'addToQueue';

  /// Add to playlist….
  static const String addToPlaylist = 'addToPlaylist';

  /// Like or Remove like.
  static const String like = 'like';

  /// Download.
  static const String download = 'download';

  /// Retry download.
  static const String retryDownload = 'retryDownload';

  /// Remove download.
  static const String removeDownload = 'removeDownload';

  /// Remove from this playlist.
  static const String removeFromPlaylist = 'removeFromPlaylist';

  /// Go to album.
  static const String goToAlbum = 'goToAlbum';

  /// Go to artist.
  static const String goToArtist = 'goToArtist';

  /// Share link.
  static const String share = 'share';

  /// Rename (playlist owners).
  static const String rename = 'rename';

  /// Delete (playlist owners).
  static const String delete = 'delete';
}

/// The effects of the menus' entries; the app's implementation is
/// `AppMenuCommands`.
abstract interface class MenuCommands {
  /// Replaces the queue with [tracks] and plays the one at [index].
  Future<void> playTracks(List<Track> tracks, int index, QueueContext context);

  /// Inserts [tracks] after the current item.
  Future<void> playNext(List<Track> tracks);

  /// Appends [tracks] to the queue.
  Future<void> addToQueue(List<Track> tracks);

  /// Asks for a playlist and adds [tracks] to it.
  Future<void> addToPlaylist(List<Track> tracks);

  /// Likes or removes the like of [track].
  Future<void> toggleLike(Track track);

  /// Removes [item] from the playlist [playlistId].
  Future<void> removeFromPlaylist(String playlistId, PlaylistItem item);

  /// Keeps [track] on this device.
  Future<void> downloadTrack(Track track);

  /// Tries the failed download of [track] again.
  Future<void> retryTrackDownload(Track track);

  /// Confirms and deletes the download of [track] from this device.
  Future<void> removeTrackDownload(Track track);

  /// Opens the album [id].
  void openAlbum(String id);

  /// Opens the artist [id].
  void openArtist(String id);

  /// Copies [link] to the clipboard and confirms it.
  Future<void> share(String link);

  /// Plays the album [id], from its start or shuffled.
  Future<void> playAlbum(String id, {bool shuffle = false});

  /// The playable tracks of the album [id].
  Future<List<Track>> albumTracks(String id);

  /// Likes the album [id] when [liked], removes its like otherwise.
  Future<void> setAlbumLiked(String id, {required bool liked});

  /// Plays the playlist [id], from its start or shuffled.
  Future<void> playPlaylist(String id, {bool shuffle = false});

  /// The playable tracks of the playlist [id].
  Future<List<Track>> playlistTracks(String id);

  /// Asks for a new name and renames [playlist].
  Future<void> renamePlaylist(PlaylistSummary playlist);

  /// Confirms and deletes [playlist].
  Future<void> deletePlaylist(PlaylistSummary playlist);

  /// Plays the artist [id]'s Popular tracks, from the top or shuffled.
  Future<void> playArtist(String id, {bool shuffle = false});
}

/// The playlist a track row sits in when the user owns it.
class OwnedPlaylist {
  /// The row of [item] in the owned playlist [playlistId].
  const new({required this.playlistId, required this.item});

  /// The playlist's id.
  final String playlistId;

  /// The row's item.
  final PlaylistItem item;
}

/// Where a track's menu is opened: the track, the list it sits in, its
/// index there, the list's [QueueContext] and, inside a playlist the user
/// owns, that playlist.
class TrackActionScope {
  /// Creates the scope of [track] at [index] of [tracks].
  ///
  /// [playable] defaults to the rule of `PlayActions`: the track has a
  /// `playbackId` (and, in a playlist, the server did not mark it not
  /// playable).
  new({
    required this.track,
    required this.tracks,
    required this.index,
    required this.context,
    this.ownedPlaylist,
    bool? playable,
  }) : playable =
           playable ??
           (track.playbackId != null &&
               (ownedPlaylist?.item.isPlayable ?? true));

  /// The track.
  final Track track;

  /// The list Play now plays from.
  final List<Track> tracks;

  /// The track's index in [tracks].
  final int index;

  /// The list's queue context.
  final QueueContext context;

  /// The playlist the user owns that the row sits in, if any.
  final OwnedPlaylist? ownedPlaylist;

  /// Whether the track can be queued.
  final bool playable;
}

/// The menu of one track (doc 09, Track Actions), in this order: Play now,
/// Play next, Add to queue, Add to playlist… (each when playable), Like or
/// Remove like (with a `playbackId`), Download or Retry download and
/// Remove download (with a `playbackId`, where the platform downloads:
/// [download] is the track's glyph, null where it does not), Remove from
/// this playlist (in an owned playlist), Go to album and Go to artist (with
/// the id, and not on that album's or artist's own page) and Share link
/// (with an album id; the link scheme has no track route, so the album's
/// link is copied).
List<MenuEntry> trackActions(
  TrackActionScope scope, {
  required AppLocalizations l10n,
  required MenuCommands commands,
  DownloadGlyphState? download,
}) {
  final track = scope.track;
  final context = scope.context;
  final albumId = track.albumId;
  final artistId = track.artistId;
  final owned = scope.ownedPlaylist;
  bool onPage(QueueContextKind kind, String id) =>
      context.kind == kind && context.id == id;
  return [
    if (scope.playable) ...[
      MenuEntry(
        id: MenuIds.playNow,
        label: l10n.menuPlayNow,
        icon: Icons.play_arrow_rounded,
        onSelected: () => unawaited(
          commands.playTracks(scope.tracks, scope.index, scope.context),
        ),
      ),
      MenuEntry(
        id: MenuIds.playNext,
        label: l10n.menuPlayNext,
        icon: Icons.playlist_play_rounded,
        onSelected: () => unawaited(commands.playNext([track])),
      ),
      MenuEntry(
        id: MenuIds.addToQueue,
        label: l10n.menuAddToQueue,
        icon: Icons.queue_music_rounded,
        onSelected: () => unawaited(commands.addToQueue([track])),
      ),
      MenuEntry(
        id: MenuIds.addToPlaylist,
        label: l10n.menuAddToPlaylist,
        icon: Icons.playlist_add_rounded,
        onSelected: () => unawaited(commands.addToPlaylist([track])),
      ),
    ],
    if (track.playbackId != null)
      MenuEntry(
        id: MenuIds.like,
        label: track.isLiked ? l10n.likeButtonRemove : l10n.likeButtonLike,
        icon: track.isLiked
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
        onSelected: () => unawaited(commands.toggleLike(track)),
      ),
    if (track.playbackId != null && download != null)
      ..._downloadEntries(track, download, l10n, commands),
    if (owned != null)
      MenuEntry(
        id: MenuIds.removeFromPlaylist,
        label: l10n.menuRemoveFromPlaylist,
        icon: Icons.playlist_remove_rounded,
        destructive: true,
        onSelected: () => unawaited(
          commands.removeFromPlaylist(owned.playlistId, owned.item),
        ),
      ),
    if (albumId != null && !onPage(QueueContextKind.album, albumId))
      MenuEntry(
        id: MenuIds.goToAlbum,
        label: l10n.menuGoToAlbum,
        icon: Icons.album_rounded,
        onSelected: () => commands.openAlbum(albumId),
      ),
    if (artistId != null && !onPage(QueueContextKind.artist, artistId))
      MenuEntry(
        id: MenuIds.goToArtist,
        label: l10n.menuGoToArtist,
        icon: Icons.person_rounded,
        onSelected: () => commands.openArtist(artistId),
      ),
    if (albumId != null) _share(l10n, commands, albumLink(albumId)),
  ];
}

/// The menu of [album]: Play now, Play next, Add to queue, Add to
/// playlist…, Like or Remove like, Go to artist (not on that artist's
/// page) and Share link.
List<MenuEntry> albumActions(
  Album album, {
  required AppLocalizations l10n,
  required MenuCommands commands,
  bool onArtistPage = false,
}) {
  final liked = album.preference == Preference.liked;
  return [
    MenuEntry(
      id: MenuIds.playNow,
      label: l10n.menuPlayNow,
      icon: Icons.play_arrow_rounded,
      onSelected: () => unawaited(commands.playAlbum(album.id)),
    ),
    MenuEntry(
      id: MenuIds.playNext,
      label: l10n.menuPlayNext,
      icon: Icons.playlist_play_rounded,
      onSelected: () =>
          unawaited(commands.albumTracks(album.id).then(commands.playNext)),
    ),
    MenuEntry(
      id: MenuIds.addToQueue,
      label: l10n.menuAddToQueue,
      icon: Icons.queue_music_rounded,
      onSelected: () =>
          unawaited(commands.albumTracks(album.id).then(commands.addToQueue)),
    ),
    MenuEntry(
      id: MenuIds.addToPlaylist,
      label: l10n.menuAddToPlaylist,
      icon: Icons.playlist_add_rounded,
      onSelected: () => unawaited(
        commands.albumTracks(album.id).then(commands.addToPlaylist),
      ),
    ),
    MenuEntry(
      id: MenuIds.like,
      label: liked ? l10n.likeButtonRemove : l10n.likeButtonLike,
      icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      onSelected: () =>
          unawaited(commands.setAlbumLiked(album.id, liked: !liked)),
    ),
    if (!onArtistPage)
      MenuEntry(
        id: MenuIds.goToArtist,
        label: l10n.menuGoToArtist,
        icon: Icons.person_rounded,
        onSelected: () => commands.openArtist(album.artistId),
      ),
    _share(l10n, commands, albumLink(album.id)),
  ];
}

/// The menu of [playlist]: Play now, Play next, Add to queue, Share link,
/// and for its owner Rename and Delete.
List<MenuEntry> playlistActions(
  PlaylistSummary playlist, {
  required AppLocalizations l10n,
  required MenuCommands commands,
}) => [
  MenuEntry(
    id: MenuIds.playNow,
    label: l10n.menuPlayNow,
    icon: Icons.play_arrow_rounded,
    onSelected: () => unawaited(commands.playPlaylist(playlist.id)),
  ),
  MenuEntry(
    id: MenuIds.playNext,
    label: l10n.menuPlayNext,
    icon: Icons.playlist_play_rounded,
    onSelected: () =>
        unawaited(commands.playlistTracks(playlist.id).then(commands.playNext)),
  ),
  MenuEntry(
    id: MenuIds.addToQueue,
    label: l10n.menuAddToQueue,
    icon: Icons.queue_music_rounded,
    onSelected: () => unawaited(
      commands.playlistTracks(playlist.id).then(commands.addToQueue),
    ),
  ),
  _share(l10n, commands, playlistLink(playlist.id)),
  if (playlist.isOwner) ...[
    MenuEntry(
      id: MenuIds.rename,
      label: l10n.menuRename,
      icon: Icons.edit_rounded,
      onSelected: () => unawaited(commands.renamePlaylist(playlist)),
    ),
    MenuEntry(
      id: MenuIds.delete,
      label: l10n.menuDelete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
      onSelected: () => unawaited(commands.deletePlaylist(playlist)),
    ),
  ],
];

/// The menu of the artist [artistId]: Share link.
List<MenuEntry> artistActions(
  String artistId, {
  required AppLocalizations l10n,
  required MenuCommands commands,
}) => [_share(l10n, commands, artistLink(artistId))];

/// The `soundspan://` link of the album [id].
String albumLink(String id) => 'soundspan://album/${Uri.encodeComponent(id)}';

/// The `soundspan://` link of the playlist [id].
String playlistLink(String id) =>
    'soundspan://playlist/${Uri.encodeComponent(id)}';

/// The `soundspan://` link of the artist [id].
String artistLink(String id) => 'soundspan://artist/${Uri.encodeComponent(id)}';

List<MenuEntry> _downloadEntries(
  Track track,
  DownloadGlyphState download,
  AppLocalizations l10n,
  MenuCommands commands,
) => [
  if (download == DownloadGlyphState.none)
    MenuEntry(
      id: MenuIds.download,
      label: l10n.menuDownload,
      icon: Icons.download_rounded,
      onSelected: () => unawaited(commands.downloadTrack(track)),
    )
  else ...[
    if (download == DownloadGlyphState.failed)
      MenuEntry(
        id: MenuIds.retryDownload,
        label: l10n.menuRetryDownload,
        icon: Icons.refresh_rounded,
        onSelected: () => unawaited(commands.retryTrackDownload(track)),
      ),
    MenuEntry(
      id: MenuIds.removeDownload,
      label: l10n.menuRemoveDownload,
      icon: Icons.delete_outline_rounded,
      onSelected: () => unawaited(commands.removeTrackDownload(track)),
    ),
  ],
];

MenuEntry _share(AppLocalizations l10n, MenuCommands commands, String link) =>
    MenuEntry(
      id: MenuIds.share,
      label: l10n.menuShareLink,
      icon: Icons.link_rounded,
      onSelected: () => unawaited(commands.share(link)),
    );
