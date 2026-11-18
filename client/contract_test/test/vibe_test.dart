// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Contract group "Vibe" of doc 03's endpoint inventory: similar tracks of
/// a library track and the search by description, gated by
/// `audioAnalysis`, against the seeded server with response validation
/// on.
///
/// The contract compose file sets `AUDIO_ANALYSIS_ENABLED` to `false`, so
/// the branch that runs there is the disabled one: both calls answer 404
/// `FEATURE_DISABLED`. The enabled branch covers a server with analysis
/// on, where the fixture library has no analysed tracks and no text
/// embedding service runs: similar tracks decode or are the documented 404,
/// and the search decodes or fails with a 5xx the client handles.
@Tags(['contract'])
library;

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  late ContractCredentials credentials;
  late SoundspanApi api;
  late bool audioAnalysis;

  setUp(() async {
    credentials = ContractCredentials.load();
    api = await signedInApi(credentials, credentials.listener);
    final features = await api.send((rest) => rest.session.getSystemFeatures());
    audioAnalysis = features.audioAnalysis;
  });

  /// A seeded library track's id, from a decade station.
  Future<String> seededTrackId() async {
    final decades = await api.send((rest) => rest.discovery.listRadioDecades());
    final station = await api.send(
      (rest) => rest.discovery.getRadio(
        type: const RadioTypeKnown(RadioTypeValue.decade),
        value: '${decades.decades.first.decade}',
        limit: 1,
      ),
    );
    return station.tracks.first.id;
  }

  Matcher featureDisabled() => throwsA(
    isA<FeatureDisabled>()
        .having((error) => error.status, 'status', 404)
        .having((error) => error.code, 'code', 'FEATURE_DISABLED'),
  );

  test('similar tracks of a seeded track', () async {
    final trackId = await seededTrackId();
    Future<SimilarTracksResponse> call() => api.send(
      (rest) => rest.discovery.getSimilarTracks(trackId: trackId, limit: 5),
    );
    if (!audioAnalysis) {
      await expectLater(call(), featureDisabled());
      return;
    }
    try {
      final similar = await call();
      expect(similar.sourceTrackId, trackId);
      expect(similar.tracks.length, lessThanOrEqualTo(5));
      for (final track in similar.tracks) {
        expect(track.id, isNotEmpty);
        expect(track.title, isNotEmpty);
      }
    } on NotFound {
      // "No similar tracks found": the client shows an empty list.
    }
  });

  test('search by description', () async {
    Future<VibeSearchResponse> call() => api.send(
      (rest) => rest.discovery.searchVibe(
        body: const VibeSearchRequest(query: 'calm piano', limit: 5),
      ),
    );
    if (!audioAnalysis) {
      await expectLater(call(), featureDisabled());
      return;
    }
    try {
      final found = await call();
      expect(found.query, 'calm piano');
      expect(found.tracks.length, lessThanOrEqualTo(5));
    } on ApiException catch (error) {
      // No text embedding service: 502, 503 or 504, shown as "Vibe search
      // is unavailable right now".
      expect(error, anyOf(isA<Upstream>(), isA<ServerError>()));
      expect(error.status, inInclusiveRange(502, 504));
    }
  });
}
