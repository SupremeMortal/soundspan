// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Radio" of doc 03's endpoint inventory: the library's
/// genre and decade lists and a station of each, against the seeded server
/// with response validation on. Radio needs no server feature. Genres come
/// from artist enrichment, which the contract server does not run, so the
/// genre list may be empty; the fixture albums' years fill the decades.
@Tags(['contract'])
library;

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late ContractCredentials credentials;
  late SoundspanApi api;

  setUp(() async {
    credentials = ContractCredentials.load();
    api = await signedInApi(credentials, credentials.listener);
  });

  Future<void> expectStation(RadioTypeValue type, String value) async {
    const limit = 5;
    final station = await api.send(
      (rest) => rest.discovery.getRadio(
        type: RadioTypeKnown(type),
        value: value,
        limit: limit,
      ),
    );
    expect(station.tracks, isNotEmpty);
    expect(station.tracks.length, lessThanOrEqualTo(limit));
    for (final track in station.tracks) {
      expect(track.id, isNotEmpty);
      expect(track.title, isNotEmpty);
      expect(track.playbackId, isNotEmpty);
    }
  }

  test('genres and decades decode, and are not both empty', () async {
    final genres = await api.send((rest) => rest.discovery.listRadioGenres());
    final decades = await api.send((rest) => rest.discovery.listRadioDecades());
    for (final genre in genres.genres) {
      expect(genre.genre, isNotEmpty);
      expect(genre.count, greaterThan(0));
    }
    for (final decade in decades.decades) {
      expect(decade.decade % 10, 0);
      expect(decade.count, greaterThan(0));
    }
    expect(genres.genres.length + decades.decades.length, greaterThan(0));
  });

  test('the first genre station returns playable tracks within the '
      'limit', () async {
    final genres = await api.send((rest) => rest.discovery.listRadioGenres());
    if (genres.genres.isEmpty) return;
    await expectStation(RadioTypeValue.genre, genres.genres.first.genre);
  });

  test('the first decade station returns playable tracks within the '
      'limit', () async {
    final decades = await api.send((rest) => rest.discovery.listRadioDecades());
    expect(decades.decades, isNotEmpty);
    await expectStation(
      RadioTypeValue.decade,
      '${decades.decades.first.decade}',
    );
  });
}
