// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// Encodes the JSON of a value to a JSON string and back, as the cache and the queue
/// snapshot do.
Map<String, Object?> _roundTrip(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  const meta = TrackMeta(
    title: 'Song',
    artist: 'Band',
    album: 'Record',
    durationSec: 215,
    artworkRef: 'cover-1',
    isrc: 'USRC17607839',
  );
  const track = Track(
    meta: meta,
    playbackId: PlaybackId('pb-1'),
    albumId: 'al-1',
    artistId: 'ar-1',
    loudness: Loudness(
      loudnessLufs: -9.5,
      truePeakDb: -0.4,
      albumLoudnessLufs: -10,
      albumTruePeakDb: -0.2,
    ),
    preference: Preference.liked,
    discNumber: 1,
    trackNumber: 3,
    libraryTrackId: 't-1',
  );
  const album = Album(
    id: 'al-1',
    title: 'Record',
    artistName: 'Band',
    artistId: 'ar-1',
    year: 1999,
    artworkRef: 'cover-1',
    trackCount: 12,
    releaseType: 'album',
  );
  const artist = Artist(id: 'ar-1', name: 'Band', artworkRef: 'cover-2');
  const podcast = Podcast(
    id: 'p-1',
    title: 'Show',
    author: 'Host',
    artworkRef: '/podcasts/p-1/cover',
  );
  final episode = Episode(
    id: 'e-1',
    podcastId: 'p-1',
    title: 'Episode one',
    durationSec: 3600,
    publishedAt: DateTime.utc(2024, 5, 6, 7, 8, 9),
    artworkRef: '/podcasts/p-1/cover',
  );

  group('domain types round-trip through JSON', () {
    test('TrackMeta', () {
      expect(TrackMeta.fromJson(_roundTrip(meta.toJson())), meta);
    });

    test('Loudness', () {
      final loudness = track.loudness!;
      expect(Loudness.fromJson(_roundTrip(loudness.toJson())), loudness);
    });

    test('Track, playable and not playable', () {
      expect(Track.fromJson(_roundTrip(track.toJson())), track);
      const unplayable = Track(meta: meta);
      final decoded = Track.fromJson(_roundTrip(unplayable.toJson()));
      expect(decoded, unplayable);
      expect(decoded.playbackId, isNull);
      expect(decoded.preference, Preference.neutral);
    });

    test('a playback id is written as its plain string', () {
      expect(track.toJson()['playbackId'], 'pb-1');
    });

    test('Album and AlbumDetail', () {
      expect(Album.fromJson(_roundTrip(album.toJson())), album);
      const detail = AlbumDetail(album: album, tracks: [track], owned: true);
      expect(AlbumDetail.fromJson(_roundTrip(detail.toJson())), detail);
    });

    test('Artist, SimilarArtist and ArtistDetail', () {
      expect(Artist.fromJson(_roundTrip(artist.toJson())), artist);
      const similar = SimilarArtist(name: 'Other', libraryId: 'ar-2');
      expect(SimilarArtist.fromJson(_roundTrip(similar.toJson())), similar);
      const detail = ArtistDetail(
        artist: artist,
        albums: [album],
        topTracks: [track],
        similarArtists: [
          similar,
          SimilarArtist(name: 'Elsewhere'),
        ],
        biography: 'A band.',
        genres: ['rock'],
      );
      expect(ArtistDetail.fromJson(_roundTrip(detail.toJson())), detail);
    });

    test('Podcast and Episode', () {
      expect(Podcast.fromJson(_roundTrip(podcast.toJson())), podcast);
      final decoded = Episode.fromJson(_roundTrip(episode.toJson()));
      expect(decoded, episode);
      expect(decoded.publishedAt!.isUtc, isTrue);
    });

    test('QueueContext', () {
      const context = QueueContext(
        kind: QueueContextKind.album,
        id: 'al-1',
        title: 'Record',
      );
      expect(QueueContext.fromJson(_roundTrip(context.toJson())), context);
    });
  });

  group('QueueItem', () {
    test('a TrackQueueItem round-trips through the sealed QueueItem', () {
      const item = QueueItem.track(
        queueItemId: 'q-1',
        track: track,
        context: QueueContext(kind: QueueContextKind.single),
      );
      final decoded = QueueItem.fromJson(_roundTrip(item.toJson()));
      expect(decoded, isA<TrackQueueItem>());
      expect(decoded, item);
      expect(decoded.queueItemId, 'q-1');
    });

    test('an EpisodeQueueItem round-trips through the sealed QueueItem', () {
      final item = QueueItem.episode(
        queueItemId: 'q-2',
        episode: episode,
        podcast: podcast,
      );
      final decoded = QueueItem.fromJson(_roundTrip(item.toJson()));
      expect(decoded, isA<EpisodeQueueItem>());
      expect(decoded, item);
      expect(decoded.queueItemId, 'q-2');
    });
  });

  test('two PlaybackIds compare by value', () {
    // Built at run time so the comparison is not of one canonical constant.
    final a = PlaybackId(['pb', '7'].join('-'));
    final b = PlaybackId(['pb', '7'].join('-'));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a == const PlaybackId('pb-8'), isFalse);
  });
}
