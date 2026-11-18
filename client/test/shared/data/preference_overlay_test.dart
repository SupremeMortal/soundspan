// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/outbox_store.dart';
import 'package:soundspan/shared/data/preference_overlay.dart';
import 'package:soundspan/shared/domain/domain.dart';

Track _track(String id, {Preference preference = Preference.neutral}) => Track(
  meta: TrackMeta(title: id, artist: 'A', album: 'B', durationSec: 1),
  playbackId: PlaybackId(id),
  preference: preference,
);

var _seq = 0;

OutboxEntry _entry(OutboxOp op) => OutboxEntry(
  seq: ++_seq,
  op: op,
  createdAt: DateTime.utc(2025),
  attempts: 0,
);

OutboxEntry _like(String id, {bool liked = true}) => _entry(
  PreferenceOp(
    playbackId: id,
    signal: liked ? PreferenceSignal.thumbsUp : PreferenceSignal.clear,
    metadata: _track(id).meta.toJson(),
  ),
);

const _album = Album(id: 'al', title: 'T', artistName: 'A', artistId: 'ar');

void main() {
  test('the latest op of a track wins', () {
    final ops = [_like('a'), _like('a', liked: false)];

    expect(pendingTrackPreferences(ops), {'a': Preference.neutral});
  });

  test('a track list shows pending likes and leaves other tracks alone', () {
    final tracks = [_track('a'), _track('b')];
    final out = overlayTracks(tracks, [_like('a')]);

    expect(out[0].preference, Preference.liked);
    expect(out[1], same(tracks[1]));
  });

  test('a track without a playbackId is never overlaid', () {
    final track = _track('a').copyWith(playbackId: null);

    expect(overlayTracks([track], [_like('a')]).single, same(track));
  });

  test('album detail overlays the album and its tracks', () {
    final detail = AlbumDetail(
      album: _album,
      tracks: [_track('a')],
      owned: true,
    );
    final out = overlayAlbumDetail(detail, [
      _like('a'),
      _entry(
        const AlbumPreferenceOp(
          albumId: 'al',
          signal: PreferenceSignal.thumbsUp,
        ),
      ),
    ]);

    expect(out.album.preference, Preference.liked);
    expect(out.tracks.single.preference, Preference.liked);
  });

  test('an album op of another album changes nothing', () {
    final out = overlayAlbum(_album, [
      _entry(
        const AlbumPreferenceOp(
          albumId: 'x',
          signal: PreferenceSignal.thumbsUp,
        ),
      ),
    ]);

    expect(out, same(_album));
  });

  test('playlist detail and search results show pending likes', () {
    const summary = PlaylistSummary(
      id: 'p',
      name: 'P',
      trackCount: 1,
      isOwner: true,
      isPublic: false,
    );
    final playlist = PlaylistDetail(
      summary: summary,
      items: [
        PlaylistItem(id: 'i', sort: 0, track: _track('a'), isPlayable: true),
      ],
    );
    final search = SearchResults(
      library: LibrarySearchResults(tracks: [_track('a')]),
      discover: DiscoverResults(hits: [SearchHit.track(track: _track('a'))]),
    );
    final ops = [_like('a')];

    expect(
      overlayPlaylistDetail(playlist, ops).items.single.track.preference,
      Preference.liked,
    );
    final results = overlaySearchResults(search, ops);
    expect(results.library!.tracks.single.preference, Preference.liked);
    expect(
      (results.discover!.hits.single as TrackHit).track.preference,
      Preference.liked,
    );
  });

  group('liked list', () {
    PagedSnapshot<Track> page(Map<int, Track> items, int total) =>
        PagedSnapshot<Track>(total: total, items: items);

    List<String?> ids(PagedSnapshot<Track> snapshot) => [
      for (var i = 0; i < snapshot.total!; i++)
        snapshot.itemAt(i)?.playbackId?.value,
    ];

    final liked = {
      0: _track('x', preference: Preference.liked),
      1: _track('y', preference: Preference.liked),
      2: _track('z', preference: Preference.liked),
    };

    test('a pending like is prepended, newest first', () {
      final out = overlayLikedPage(page(liked, 3), [_like('a'), _like('b')]);

      expect(ids(out), ['b', 'a', 'x', 'y', 'z']);
      expect(out.itemAt(0)!.preference, Preference.liked);
      expect(out.itemAt(0)!.meta.title, 'b');
    });

    test('a pending unlike is left out and the rest move up', () {
      final out = overlayLikedPage(page(liked, 3), [_like('y', liked: false)]);

      expect(ids(out), ['x', 'z']);
    });

    test('a like of a track already in the list does not duplicate it', () {
      final out = overlayLikedPage(page(liked, 3), [_like('y')]);

      expect(ids(out), ['x', 'y', 'z']);
    });

    test('unloaded pages keep their places', () {
      final sparse = {
        0: liked[0]!,
        5: _track('w', preference: Preference.liked),
      };
      final out = overlayLikedPage(page(sparse, 6), [_like('a')]);

      expect(out.total, 7);
      expect(out.itemAt(0)!.playbackId!.value, 'a');
      expect(out.itemAt(1)!.playbackId!.value, 'x');
      expect(out.itemAt(6)!.playbackId!.value, 'w');
    });
  });
}
