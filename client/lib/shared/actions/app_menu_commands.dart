// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/features/downloads/downloads.dart';
import 'package:soundspan/features/playlist/playlist.dart';
import 'package:soundspan/features/vibe/vibe.dart' as vibe;
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/play_actions.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan/shared/widgets/context_menu.dart';

/// The app's [MenuCommands]: playback through `PlayActions`, likes through
/// the like commands, playlist edits through the playlist repository and
/// its dialogs, navigation through [DetailNavigation], from the widget
/// [_context] that opened the menu.
class AppMenuCommands implements MenuCommands {
  /// Creates the commands of [_context] and [_ref]; [onPlaylistDeleted] is
  /// called after a playlist is deleted, so its own page can close.
  new(this._context, this._ref, {this.onPlaylistDeleted});

  final BuildContext _context;
  final WidgetRef _ref;

  /// Called with the id of a playlist after it is deleted.
  final void Function(String playlistId)? onPlaylistDeleted;

  PlayActions get _play => _ref.read(playActionsProvider);

  @override
  Future<void> playTracks(
    List<Track> tracks,
    int index,
    QueueContext context,
  ) => _play.playTracks(tracks, startIndex: index, context: context);

  @override
  Future<void> playNext(List<Track> tracks) => _play.playNext(tracks);

  @override
  Future<void> addToQueue(List<Track> tracks) => _play.addToQueue(tracks);

  @override
  Future<void> addToPlaylist(List<Track> tracks) async {
    if (tracks.isEmpty || !_context.mounted) return;
    await addTracksToPlaylist(_context, _ref, tracks);
  }

  @override
  Future<void> toggleLike(Track track) =>
      _ref.read(trackLikesProvider).toggleLike(track);

  @override
  Future<void> removeFromPlaylist(String playlistId, PlaylistItem item) async {
    final repository = await _ref.read(playlistRepositoryProvider.future);
    await repository.removeItem(playlistId, item);
  }

  @override
  Future<void> downloadTrack(Track track) async {
    final playbackId = track.playbackId;
    if (playbackId == null || !_context.mounted) return;
    await pinCollection(
      _context,
      _ref,
      CollectionKind.track,
      playbackId.value,
      trackSnapshot(track),
    );
  }

  @override
  Future<void> retryTrackDownload(Track track) async {
    final playbackId = track.playbackId;
    if (playbackId == null) return;
    await _ref
        .read(downloadControllerProvider)
        .retry(TrackItemKey(playbackId.value));
  }

  @override
  Future<void> removeTrackDownload(Track track) async {
    final playbackId = track.playbackId;
    if (playbackId == null || !_context.mounted) return;
    await confirmAndUnpin(
      _context,
      _ref,
      CollectionKind.track,
      playbackId.value,
    );
  }

  @override
  void openAlbum(String id) {
    if (_context.mounted) DetailNavigation.openAlbum(_context, id);
  }

  @override
  void openArtist(String id) {
    if (_context.mounted) DetailNavigation.openArtist(_context, id);
  }

  @override
  Future<void> startRadio(Track track) async {
    if (_context.mounted) await vibe.startRadio(_context, _ref, track);
  }

  @override
  Future<void> share(String link) async {
    final messenger = ScaffoldMessenger.maybeOf(_context);
    final l10n = AppLocalizations.of(_context);
    await Clipboard.setData(ClipboardData(text: link));
    messenger?.showSnackBar(SnackBar(content: Text(l10n.menuLinkCopied)));
  }

  @override
  Future<void> playAlbum(String id, {bool shuffle = false}) =>
      _play.playAlbum(id, shuffle: shuffle);

  @override
  Future<List<Track>> albumTracks(String id) => _play.albumTracks(id);

  @override
  Future<void> setAlbumLiked(String id, {required bool liked}) =>
      _ref.read(albumLikesProvider).setAlbumLiked(id, liked: liked);

  @override
  Future<void> playPlaylist(String id, {bool shuffle = false}) =>
      _play.playPlaylist(id, shuffle: shuffle);

  @override
  Future<List<Track>> playlistTracks(String id) => _play.playlistTracks(id);

  @override
  Future<void> renamePlaylist(PlaylistSummary playlist) async {
    if (!_context.mounted) return;
    final name = await PlaylistNameDialog.showRename(_context, playlist.name);
    if (name == null || name == playlist.name) return;
    final repository = await _ref.read(playlistRepositoryProvider.future);
    await repository.rename(playlist.id, name);
  }

  @override
  Future<void> deletePlaylist(PlaylistSummary playlist) async {
    if (!_context.mounted) return;
    if (!await DeletePlaylistDialog.show(_context, playlist.name)) return;
    final repository = await _ref.read(playlistRepositoryProvider.future);
    await repository.delete(playlist.id);
    onPlaylistDeleted?.call(playlist.id);
  }

  @override
  Future<void> playArtist(String id, {bool shuffle = false}) =>
      _play.playArtist(id, shuffle: shuffle);
}

/// Opens the menu of the track in [scope] from [context] (doc 09, Track
/// Actions), at [position] with a pointer.
Future<void> openTrackMenu(
  BuildContext context,
  WidgetRef ref,
  TrackActionScope scope, {
  Offset? position,
}) => showContextMenu(
  context,
  trackActions(
    scope,
    l10n: AppLocalizations.of(context),
    commands: AppMenuCommands(context, ref),
    download: trackMenuGlyph(ref, scope.track.playbackId),
    startRadio: vibe.startRadioOffered(ref),
  ),
  position: position,
);

/// Opens the menu of [album] from [context], at [position] with a pointer.
Future<void> openAlbumMenu(
  BuildContext context,
  WidgetRef ref,
  Album album, {
  Offset? position,
  bool onArtistPage = false,
}) => showContextMenu(
  context,
  albumActions(
    album,
    l10n: AppLocalizations.of(context),
    commands: AppMenuCommands(context, ref),
    onArtistPage: onArtistPage,
  ),
  position: position,
);

/// Opens the menu of [playlist] from [context], at [position] with a
/// pointer; [onDeleted] runs after the owner deleted it.
Future<void> openPlaylistMenu(
  BuildContext context,
  WidgetRef ref,
  PlaylistSummary playlist, {
  Offset? position,
  void Function(String playlistId)? onDeleted,
}) => showContextMenu(
  context,
  playlistActions(
    playlist,
    l10n: AppLocalizations.of(context),
    commands: AppMenuCommands(context, ref, onPlaylistDeleted: onDeleted),
  ),
  position: position,
);

/// The `onAddToQueue` of a row showing [track]: Add to queue through
/// `PlayActions`; null when [playable] is false.
VoidCallback? addToQueueOf(WidgetRef ref, Track track, {bool? playable}) {
  if (!(playable ?? track.playbackId != null)) return null;
  return () => unawaited(ref.read(playActionsProvider).addToQueue([track]));
}

/// Opens the menu of the tracks of [scopes] from [context], at [position]
/// with a pointer: [trackSelectionActions], which is the single track's
/// menu for one scope.
Future<void> openTrackSelectionMenu(
  BuildContext context,
  WidgetRef ref,
  List<TrackActionScope> scopes, {
  Offset? position,
}) {
  if (scopes.length == 1) {
    return openTrackMenu(context, ref, scopes.single, position: position);
  }
  return showContextMenu(
    context,
    trackSelectionActions(
      scopes,
      l10n: AppLocalizations.of(context),
      commands: AppMenuCommands(context, ref),
    ),
    position: position,
  );
}
