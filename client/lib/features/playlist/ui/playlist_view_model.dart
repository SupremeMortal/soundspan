// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The edit commands of one playlist page (doc 09, Album, Artist,
/// Playlist): each enqueues through the [PlaylistRepository] and shows at
/// once through its overlays.
class PlaylistViewModel {
  /// Creates the commands of the playlist [playlistId] over the repository
  /// [_repository] opens.
  new(this._repository, this.playlistId);

  final Future<PlaylistRepository> Function() _repository;

  /// The playlist the commands edit.
  final String playlistId;

  /// Renames the playlist to [name].
  Future<void> rename(String name) async =>
      await (await _repository()).rename(playlistId, name);

  /// Deletes the playlist; the page then navigates back.
  Future<void> delete() async => await (await _repository()).delete(playlistId);

  /// Removes [item] from the playlist.
  Future<void> removeItem(PlaylistItem item) async =>
      await (await _repository()).removeItem(playlistId, item);

  /// Moves the item at [oldIndex] of [items] to its final place
  /// [newIndex] and sends the full order. Nothing is sent when the item
  /// does not move.
  Future<void> reorder(
    List<PlaylistItem> items,
    int oldIndex,
    int newIndex,
  ) async {
    final target = newIndex;
    if (target == oldIndex) return;
    final moved = [...items];
    moved.insert(target, moved.removeAt(oldIndex));
    await (await _repository()).reorder(playlistId, [
      for (final item in moved) item.track.playbackId!,
    ]);
  }

  /// Appends [tracks]; answers how many were added.
  Future<int> addTracks(List<Track> tracks) async =>
      await (await _repository()).addTracks(playlistId, tracks);
}

/// The [PlaylistViewModel] of a playlist id.
final ProviderFamily<PlaylistViewModel, String> playlistViewModelProvider =
    Provider.autoDispose.family<PlaylistViewModel, String>((ref, id) {
      // Kept, so a command still reaches the repository after the
      // provider is disposed.
      final repository = ref.watch(playlistRepositoryProvider.future);
      return PlaylistViewModel(() => repository, id);
    }, dependencies: [playlistRepositoryProvider]);
