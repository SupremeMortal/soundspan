// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Decodes every captured server response in `test/fixtures/` with its
/// generated model and checks that `toJson` round-trips it.
///
/// Fixtures come from `client/contract_test/tool/capture_fixtures.dart`
/// (the `client-captured-fixtures` artifact of the `client-contract` job).
/// The client issue that first uses a group of operations adds their
/// capture steps, fixtures and entries here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

/// Decodes a fixture body and encodes a decoded model back to JSON.
final class FixtureDecoder {
  /// Creates a decoder from a model's `fromJson` and `toJson`.
  const new(this._fromJson, this._toJson);

  final Object Function(Object? json) _fromJson;
  final Object? Function(Object model) _toJson;

  /// Decodes [json] into its model.
  Object decode(Object? json) => _fromJson(json);

  /// Encodes [model], a value [decode] returned, as JSON text and decodes
  /// that text, so values `toJson` leaves as Dart objects are encoded too.
  Object? reencode(Object model) => jsonDecode(jsonEncode(_toJson(model)));
}

/// A decoder for an object response.
FixtureDecoder _object<T extends Object>(
  T Function(Map<String, Object?> json) fromJson,
  Object? Function(T model) toJson,
) => FixtureDecoder(
  (json) => fromJson(json! as Map<String, Object?>),
  (model) => toJson(model as T),
);

/// A decoder for a response with several shapes (`oneOf` or `anyOf`).
FixtureDecoder _union<T extends Object>(
  T Function(Object? json) fromJson,
  Object? Function(T model) toJson,
) => FixtureDecoder(fromJson, (model) => toJson(model as T));

/// A decoder for an array response, decoding each element.
FixtureDecoder _list<T extends Object>(
  T Function(Map<String, Object?> json) fromJson,
  Object? Function(T model) toJson,
) => FixtureDecoder(
  (json) => [
    for (final element in json! as List<Object?>)
      fromJson(element! as Map<String, Object?>),
  ],
  (models) => [for (final model in models as List<T>) toJson(model)],
);

/// Fixture file name to the decoder of its response model.
final Map<String, FixtureDecoder> fixtureDecoders = {
  'addPlaylistItem.duplicate.json': _union(
    AddPlaylistItemResponse200.fromJson,
    (model) => model.toJson(),
  ),
  'addPlaylistItem.json': _union(
    AddPlaylistItemResponse200.fromJson,
    (model) => model.toJson(),
  ),
  'clearPlaybackState.json': _object(
    ClearPlaybackStateResponse.fromJson,
    (model) => model.toJson(),
  ),
  'completeOfflineItem.json': _object(
    CompletedOfflineItem.fromJson,
    (model) => model.toJson(),
  ),
  'createListenGroup.json': _object(
    ListenGroupSnapshot.fromJson,
    (model) => model.toJson(),
  ),
  'createPlaylist.json': _object(
    PlaylistRecord.fromJson,
    (model) => model.toJson(),
  ),
  'deleteOfflineItems.json': _object(
    DeleteOfflineItemsResponse.fromJson,
    (model) => model.toJson(),
  ),
  'deletePlaylist.json': _object(
    PlaylistWriteResult.fromJson,
    (model) => model.toJson(),
  ),
  'discoverListenGroups.json': _list(
    ListenGroupSummary.fromJson,
    (model) => model.toJson(),
  ),
  'endListenGroup.json': _object(
    EndListenGroupResponse.fromJson,
    (model) => model.toJson(),
  ),
  'getAlbum.json': _object(AlbumDetail.fromJson, (model) => model.toJson()),
  'getApiDocument.json': _object(
    ApiDocumentInfo.fromJson,
    (model) => model.toJson(),
  ),
  'getArtist.json': _object(ArtistDetail.fromJson, (model) => model.toJson()),
  'getAuthConfig.json': _object(AuthConfig.fromJson, (model) => model.toJson()),
  'getCurrentDiscover.json': _object(
    DiscoverCurrent.fromJson,
    (model) => model.toJson(),
  ),
  'getCurrentUser.json': _object(LoginUser.fromJson, (model) => model.toJson()),
  'getHealth.json': _object(HealthStatus.fromJson, (model) => model.toJson()),
  'getMix.json': _object(MixDetail.fromJson, (model) => model.toJson()),
  'getMyListenGroup.json': _object(
    ListenGroupSnapshot.fromJson,
    (model) => model.toJson(),
  ),
  'getOfflineStats.json': _object(
    OfflineStats.fromJson,
    (model) => model.toJson(),
  ),
  'getOnboardingStatus.json': _object(
    OnboardingStatus.fromJson,
    (model) => model.toJson(),
  ),
  'getPlaybackState.json': _object(
    PlaybackState.fromJson,
    (model) => model.toJson(),
  ),
  'getPlaylist.json': _object(
    PlaylistDetail.fromJson,
    (model) => model.toJson(),
  ),
  'getPodcast.json': _object(PodcastDetail.fromJson, (model) => model.toJson()),
  'getRadio.json': _object(RadioResponse.fromJson, (model) => model.toJson()),
  'getRecommendationsForYou.json': _object(
    RecommendationsForYou.fromJson,
    (model) => model.toJson(),
  ),
  'getSettings.json': _object(UserSettings.fromJson, (model) => model.toJson()),
  'getStreamInfo.json': _object(StreamInfo.fromJson, (model) => model.toJson()),
  'getSystemFeatures.json': _object(
    SystemFeatures.fromJson,
    (model) => model.toJson(),
  ),
  'joinListenGroup.json': _object(
    ListenGroupSnapshot.fromJson,
    (model) => model.toJson(),
  ),
  'leaveListenGroup.json': _object(
    LeaveListenGroupResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listAlbums.json': _object(
    AlbumListResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listApiKeys.json': _object(
    ApiKeyListResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listArtists.json': _object(
    ArtistListResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listLikedTracks.json': _object(
    LikedTracksResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listMixes.json': _list(MixSummary.fromJson, (model) => model.toJson()),
  'listOfflineItems.json': _object(
    DeviceOfflineItemsResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listOnlineUsers.json': _object(
    OnlineUsersResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listPlaylists.json': _list(
    PlaylistSummary.fromJson,
    (model) => model.toJson(),
  ),
  'listPodcasts.json': _list(
    SubscribedPodcast.fromJson,
    (model) => model.toJson(),
  ),
  'listRadioDecades.json': _object(
    RadioDecadesResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listRadioGenres.json': _object(
    RadioGenresResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listRecentlyAdded.json': _object(
    RecentlyAddedResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listRecentlyListened.json': _object(
    RecentlyListenedResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listShuffledTracks.json': _object(
    ShuffledTracksResponse.fromJson,
    (model) => model.toJson(),
  ),
  'listTracks.json': _object(
    LibraryTrackListResponse.fromJson,
    (model) => model.toJson(),
  ),
  'login.json': _union(LoginResponse200.fromJson, (model) => model.toJson()),
  'login.requires2FA.json': _union(
    LoginResponse200.fromJson,
    (model) => model.toJson(),
  ),
  'logout.json': _object(MessageResponse.fromJson, (model) => model.toJson()),
  'recordPlay.json': _union(
    RecordPlayResponse200.fromJson,
    (model) => model.toJson(),
  ),
  'recordPlay.notRecorded.json': _union(
    RecordPlayResponse200.fromJson,
    (model) => model.toJson(),
  ),
  'refreshSession.json': _object(
    SessionTokens.fromJson,
    (model) => model.toJson(),
  ),
  'removePlaylistItem.json': _object(
    PlaylistWriteResult.fromJson,
    (model) => model.toJson(),
  ),
  'reorderPlaylistItems.json': _object(
    PlaylistWriteResult.fromJson,
    (model) => model.toJson(),
  ),
  'requestOfflineItems.json': _object(
    OfflineItemsResponse.fromJson,
    (model) => model.toJson(),
  ),
  'savePlaybackState.json': _object(
    PlaybackState.fromJson,
    (model) => model.toJson(),
  ),
  'search.json': _object(SearchResponse.fromJson, (model) => model.toJson()),
  'sendPresenceHeartbeat.json': _object(
    PresenceHeartbeatResponse.fromJson,
    (model) => model.toJson(),
  ),
  'setAlbumPreference.json': _object(
    AlbumPreferenceResponse.fromJson,
    (model) => model.toJson(),
  ),
  'setTrackPreference.json': _object(
    TrackPreferenceResponse.fromJson,
    (model) => model.toJson(),
  ),
  'subscribePodcast.json': _object(
    SubscribePodcastResponse.fromJson,
    (model) => model.toJson(),
  ),
  'unsubscribePodcast.json': _object(
    UnsubscribePodcastResponse.fromJson,
    (model) => model.toJson(),
  ),
  'updateEpisodeProgress.json': _object(
    UpdateEpisodeProgressResponse.fromJson,
    (model) => model.toJson(),
  ),
  'updatePlaylist.json': _object(
    PlaylistRecord.fromJson,
    (model) => model.toJson(),
  ),
  'updateSettings.json': _object(
    UserSettings.fromJson,
    (model) => model.toJson(),
  ),
};

/// The directory of the captured fixtures.
final _fixtures = Directory('test/fixtures');

/// The keys `capture_fixtures.dart` scrubs, with the value it writes.
const _scrubbed = {
  'token': '<redacted>',
  'refreshToken': '<redacted>',
  'apiKey': '<redacted>',
  'secret': '<redacted>',
  'password': '<redacted>',
  'passwordHash': '<redacted>',
  'email': 'user@example.invalid',
};

/// Three base64url segments separated by dots, as in a JWT.
final _jwtShape = RegExp(
  r'[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
);

List<File> _fixtureFiles() =>
    _fixtures.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

String _name(File file) => file.uri.pathSegments.last;

Object? _read(String name) =>
    jsonDecode(File('${_fixtures.path}/$name').readAsStringSync());

/// Every value under a scrubbed key that is not its replacement, and every
/// JWT-shaped string, anywhere in [json], as `path: value`.
List<String> _leaks(Object? json, String path) => switch (json) {
  final Map<String, Object?> object => [
    for (final MapEntry(:key, :value) in object.entries)
      if (_scrubbed.containsKey(key))
        if (value != _scrubbed[key]) '$path.$key: $value' else ...[]
      else
        ..._leaks(value, '$path.$key'),
  ],
  final List<Object?> array => [
    for (var i = 0; i < array.length; i++) ..._leaks(array[i], '$path[$i]'),
  ],
  final String text when _jwtShape.hasMatch(text) => ['$path: $text'],
  _ => const [],
};

void main() {
  group('decode smoke', () {
    for (final MapEntry(key: name, value: decoder) in fixtureDecoders.entries) {
      test('$name decodes and round-trips through toJson', () {
        final model = decoder.decode(_read(name));
        expect(decoder.decode(decoder.reencode(model)), equals(model));
      });
    }
  });

  test('every fixture has a decoder and every decoder a fixture', () {
    final files = _fixtureFiles().map(_name).toSet();
    expect(files, isNotEmpty);
    expect(
      files.difference(fixtureDecoders.keys.toSet()),
      isEmpty,
      reason: 'fixtures without a decoder',
    );
    expect(
      fixtureDecoders.keys.toSet().difference(files),
      isEmpty,
      reason: 'decoders without a fixture',
    );
  });

  test('login is captured as both of its response shapes', () {
    expect(
      LoginResponse200.fromJson(_read('login.json')),
      isA<LoginTokenResponse>(),
    );
    expect(
      LoginResponse200.fromJson(_read('login.requires2FA.json')),
      isA<LoginTwoFactorChallenge>(),
    );
  });

  test('no fixture holds a secret or a JWT-shaped string', () {
    final leaks = [
      for (final file in _fixtureFiles())
        ..._leaks(jsonDecode(file.readAsStringSync()), _name(file)),
    ];
    expect(leaks, isEmpty);
  });
}
