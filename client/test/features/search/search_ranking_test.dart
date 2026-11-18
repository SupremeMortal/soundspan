// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/features/search/domain/search_ranking.dart';
import 'package:soundspan/shared/domain/domain.dart';

SearchHit _track(String title) => SearchHit.track(
  track: Track(
    meta: TrackMeta(title: title, artist: '', album: '', durationSec: 1),
  ),
);

SearchHit _artist(String name) => SearchHit.artist(
  artist: Artist(id: name, name: name),
);

SearchHit _album(String title) => SearchHit.album(
  album: Album(id: title, title: title, artistName: '', artistId: ''),
);

SearchHit _playlist(String name) => SearchHit.playlist(
  playlist: PlaylistSummary(
    id: name,
    name: name,
    trackCount: 1,
    isOwner: true,
    isPublic: false,
  ),
);

SearchHit _podcast(String title) => SearchHit.podcast(
  podcast: PodcastSummary(id: title, title: title),
);

void main() {
  group('foldForMatch', () {
    test('folds case and diacritics and collapses punctuation', () {
      expect(foldForMatch('  Björk '), 'bjork');
      expect(foldForMatch('AC/DC'), 'ac dc');
      expect(
        foldForMatch('Sigur Rós — Ágætis byrjun'),
        'sigur ros agaetis byrjun',
      );
    });

    test('drops combining marks of decomposed text', () {
      expect(foldForMatch('Björk'), 'bjork');
    });
  });

  group('matchTier', () {
    test('treats a folded equal name as exact', () {
      expect(matchTier('Björk', 'Bjork'), 4);
      expect(matchTier('bjork', 'BJÖRK'), 4);
    });

    test('ranks a prefix, then word prefixes, then any other hit', () {
      expect(matchTier('Radiohead', 'radio'), 3);
      expect(matchTier('The Dark Side of the Moon', 'dark moo'), 2);
      expect(matchTier('Paranoid Android', 'radiohead'), 1);
      expect(matchTier('Anything', '   '), 1);
    });
  });

  group('scoreSearchHit', () {
    test('ranks an exact artist match above a prefix track match', () {
      final artist = scoreSearchHit(_artist('Radiohead'), 'radiohead');
      final track = scoreSearchHit(
        _track('Radiohead Medley'),
        'radiohead',
        withinTier: 1,
      );
      expect(artist, greaterThan(track));
    });

    test('never lets the within-tier value reach the next tier', () {
      final tierOneBest = scoreSearchHit(
        _artist('Something else'),
        'radio',
        withinTier: 1,
      );
      final tierTwoWorst = scoreSearchHit(_podcast('Radio Days'), 'days radio');
      expect(tierTwoWorst, greaterThan(tierOneBest));
    });

    test('a higher within-tier value wins within a tier', () {
      expect(
        scoreSearchHit(_track('Creep (Acoustic)'), 'creep', withinTier: 0.4),
        greaterThan(
          scoreSearchHit(_track('Creep (Live)'), 'creep', withinTier: 0.1),
        ),
      );
    });

    test('breaks exact ties by kind: artist, album, track, playlist, '
        'podcast', () {
      final ranked = rankSearchHits('low', [
        _podcast('Low'),
        _track('Low'),
        _artist('Low'),
        _playlist('Low'),
        _album('Low'),
      ]);
      expect(
        [for (final result in ranked) result.hit.runtimeType],
        [ArtistHit, AlbumHit, TrackHit, PlaylistHit, PodcastHit],
      );
    });
  });

  group('rankSearchHits', () {
    test('orders by score, keeping the input order of equal scores', () {
      final ranked = rankSearchHits('creep', [
        _track('Creep (Live)'),
        _track('Pop Creep'),
        _track('Creep'),
        _track('Creep (Acoustic)'),
      ]);
      expect(
        [for (final result in ranked) primaryName(result.hit)],
        ['Creep', 'Creep (Live)', 'Creep (Acoustic)', 'Pop Creep'],
      );
      expect(ranked.first.score, greaterThan(ranked[1].score));
      expect(ranked[1].score, ranked[2].score);
    });
  });
}
