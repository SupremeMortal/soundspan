// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The optimistic overlays of likes (doc 07, Worker: optimistic state): pure
/// functions that show pending `preference` and `albumPreference` ops on the
/// values the repositories read from the cache.
library;

import 'dart:async';

import 'package:soundspan/core/sync/data/preference_repository.dart'
    show preferenceOfSignal;
import 'package:soundspan/core/sync/outbox/optimistic_overlay.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// The pending ops of [opTypes], again on every change.
typedef PendingOps = Stream<List<OutboxEntry>> Function(Set<String> opTypes);

/// [PendingOps] with nothing pending, for repositories without an outbox.
Stream<List<OutboxEntry>> noPendingOps(Set<String> opTypes) =>
    Stream.value(const []);

/// How long a like the outbox no longer holds is still shown while the
/// cache catches up (`hold` of [overlayEach]): a confirmed like never
/// flickers, and a dropped one is rolled back after it.
const Duration preferenceHold = Duration(milliseconds: 250);

/// The op types the track overlays read.
const Set<String> trackPreferenceOps = {PreferenceOp.type};

/// The op types the album overlays read.
const Set<String> albumPreferenceOps = {
  PreferenceOp.type,
  AlbumPreferenceOp.type,
};

/// The preference each pending `preference` op of [ops] sets, by
/// `playbackId`; the latest op of a track wins.
Map<String, Preference> pendingTrackPreferences(List<OutboxEntry> ops) => {
  for (final entry in ops)
    if (entry.op case PreferenceOp(:final playbackId, :final signal))
      playbackId: preferenceOfSignal(signal),
};

/// [track] with the preference a pending op in [pending] sets, if any.
Track overlayTrack(Track track, Map<String, Preference> pending) {
  final id = track.playbackId;
  if (id == null) return track;
  final preference = pending[id.value];
  if (preference == null || preference == track.preference) return track;
  return track.copyWith(preference: preference);
}

/// [tracks] with the pending `preference` ops of [ops] applied: the one
/// helper every track list uses.
List<Track> overlayTracks(List<Track> tracks, List<OutboxEntry> ops) {
  final pending = pendingTrackPreferences(ops);
  if (pending.isEmpty) return tracks;
  return [for (final track in tracks) overlayTrack(track, pending)];
}

/// [album] with the preference a pending `albumPreference` op of [ops]
/// sets, if any; the latest op wins.
Album overlayAlbum(Album album, List<OutboxEntry> ops) {
  Preference? preference;
  for (final entry in ops) {
    if (entry.op case AlbumPreferenceOp(:final albumId, :final signal)
        when albumId == album.id) {
      preference = preferenceOfSignal(signal);
    }
  }
  if (preference == null || preference == album.preference) return album;
  return album.copyWith(preference: preference);
}

/// [detail] with its album's and tracks' pending likes applied.
AlbumDetail overlayAlbumDetail(AlbumDetail detail, List<OutboxEntry> ops) =>
    detail.copyWith(
      album: overlayAlbum(detail.album, ops),
      tracks: overlayTracks(detail.tracks, ops),
    );

/// [detail] with its top tracks' pending likes applied.
ArtistDetail overlayArtistDetail(ArtistDetail detail, List<OutboxEntry> ops) =>
    detail.copyWith(topTracks: overlayTracks(detail.topTracks, ops));

/// [detail] with its items' pending likes applied.
PlaylistDetail overlayPlaylistDetail(
  PlaylistDetail detail,
  List<OutboxEntry> ops,
) {
  final pending = pendingTrackPreferences(ops);
  if (pending.isEmpty) return detail;
  return detail.copyWith(
    items: [
      for (final item in detail.items)
        item.copyWith(track: overlayTrack(item.track, pending)),
    ],
  );
}

/// [results] with the pending likes of their tracks and albums applied.
SearchResults overlaySearchResults(
  SearchResults results,
  List<OutboxEntry> ops,
) {
  final pending = pendingTrackPreferences(ops);
  final library = results.library;
  final discover = results.discover;
  return results.copyWith(
    library: library?.copyWith(
      tracks: [for (final t in library.tracks) overlayTrack(t, pending)],
      albums: [for (final a in library.albums) overlayAlbum(a, ops)],
    ),
    discover: discover?.copyWith(
      hits: [
        for (final hit in discover.hits)
          switch (hit) {
            TrackHit(:final track) => TrackHit(
              track: overlayTrack(track, pending),
            ),
            AlbumHit(:final album) => AlbumHit(album: overlayAlbum(album, ops)),
            _ => hit,
          },
      ],
    ),
  );
}

/// [snapshot] of a track list with the pending likes applied in place.
PagedSnapshot<Track> overlayTrackPage(
  PagedSnapshot<Track> snapshot,
  List<OutboxEntry> ops,
) {
  final pending = pendingTrackPreferences(ops);
  if (pending.isEmpty) return snapshot;
  return PagedSnapshot<Track>(
    total: snapshot.total,
    items: {
      for (final MapEntry(:key, :value) in snapshot.loaded.entries)
        key: overlayTrack(value, pending),
    },
    refreshing: snapshot.refreshing,
    refreshError: snapshot.refreshError,
  );
}

/// [snapshot] of the liked list with the pending likes applied: a track
/// liked while pending and not loaded is prepended, newest first, and a
/// loaded track unliked while pending is left out, the items after it
/// moving up.
PagedSnapshot<Track> overlayLikedPage(
  PagedSnapshot<Track> snapshot,
  List<OutboxEntry> ops,
) {
  final pending = pendingTrackPreferences(ops);
  if (pending.isEmpty) return snapshot;
  final loaded = snapshot.loaded;
  final loadedIds = {
    for (final track in loaded.values)
      if (track.playbackId case final id?) id.value,
  };
  final prepended = <Track>[];
  final seen = <String>{};
  for (final entry in ops.reversed) {
    if (entry.op
        case PreferenceOp(:final playbackId, :final signal, :final metadata)
        when seen.add(playbackId)) {
      if (preferenceOfSignal(signal) != Preference.liked) continue;
      if (loadedIds.contains(playbackId)) continue;
      prepended.add(
        Track(
          meta: TrackMeta.fromJson(metadata),
          playbackId: PlaybackId(playbackId),
          preference: Preference.liked,
        ),
      );
    }
  }
  final items = <int, Track>{
    for (final (index, track) in prepended.indexed) index: track,
  };
  var omitted = 0;
  for (final index in loaded.keys.toList()..sort()) {
    final track = overlayTrack(loaded[index]!, pending);
    if (track.preference != Preference.liked) {
      omitted++;
      continue;
    }
    items[index + prepended.length - omitted] = track;
  }
  final total = snapshot.total;
  return PagedSnapshot<Track>(
    total: total == null ? null : total + prepended.length - omitted,
    items: items,
    refreshing: snapshot.refreshing,
    refreshError: snapshot.refreshError,
  );
}

/// A [PagedSource] whose snapshots show the pending ops of [_opTypes]
/// through [_apply]; every other call goes to [_inner].
final class OverlaidPagedSource<T> implements PagedSource<T> {
  /// Wraps [_inner].
  new(this._inner, this._pending, this._opTypes, this._apply);

  final PagedSource<T> _inner;
  final PendingOps _pending;
  final Set<String> _opTypes;
  final PagedSnapshot<T> Function(PagedSnapshot<T>, List<OutboxEntry>) _apply;

  @override
  int get pageSize => _inner.pageSize;

  @override
  Stream<PagedSnapshot<T>> watch() => overlayEach(
    _inner.watch(),
    _pending(_opTypes),
    _apply,
    hold: preferenceHold,
  );

  @override
  void ensureVisible(int first, int last) => _inner.ensureVisible(first, last);

  @override
  Future<void> refresh() => _inner.refresh();

  @override
  void dispose() => _inner.dispose();
}
