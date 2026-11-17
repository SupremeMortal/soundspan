// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/ui/download_providers.dart';
import 'package:soundspan/features/mixes/domain/mix_detail.dart';
import 'package:soundspan/shared/domain/domain.dart';

import '../features/podcasts/ui/podcast_fixtures.dart';
import '../helpers/fake_discovery_repository.dart';
import '../helpers/fake_mix_repository.dart';
import '../helpers/fake_podcast_repository.dart';
import '../helpers/fake_radio_repository.dart';
import '../helpers/fake_repositories.dart';
import '../helpers/fake_vibe_repository.dart';
import '../helpers/fakes/fake_download_controller.dart';

/// A title long enough to be cut off on every window size.
const String longTitle =
    'An Unreasonably Long Title That Keeps Going Well Past the Edge of '
    'Any Window (Remastered Deluxe Edition)';

/// An artist name long enough to be cut off on a phone.
const String longArtist = 'The Extraordinarily Named Orchestra and Friends';

/// The id of the album, artist, playlist, mix and podcast the detail cases
/// open.
const String registryId = 'id-1';

/// The search query of the Search case.
const String registryQuery = 'love';

/// Track [n]: [longTitle] for the first, a plain title for the rest; the
/// third has no playback id.
Track registryTrack(int n) => Track(
  meta: TrackMeta(
    title: n == 1 ? longTitle : 'Song $n',
    artist: n == 1 ? longArtist : 'Artist $n',
    album: n == 1 ? longTitle : 'Album $n',
    durationSec: 180 + n * 7,
    artworkRef: 'cover-$n',
  ),
  playbackId: n == 3 ? null : PlaybackId('p-$n'),
  albumId: registryId,
  artistId: registryId,
  discNumber: 1,
  trackNumber: n,
);

/// Eight tracks of [registryTrack].
final List<Track> registryTracks = [
  for (var n = 1; n <= 8; n++) registryTrack(n),
];

/// Album [id]; [registryId] has [longTitle].
Album registryAlbum(String id) => Album(
  id: id,
  title: id == registryId ? longTitle : 'Album $id',
  artistName: longArtist,
  artistId: registryId,
  year: 2021,
  artworkRef: 'cover-$id',
);

/// Artist [id]; [registryId] has [longArtist].
Artist registryArtist(String id) => Artist(
  id: id,
  name: id == registryId ? longArtist : 'Artist $id',
  artworkRef: 'face-$id',
);

/// Playlist [id]; [registryId] has [longTitle].
PlaylistSummary registryPlaylist(String id) => PlaylistSummary(
  id: id,
  name: id == registryId ? longTitle : 'Playlist $id',
  trackCount: registryTracks.length,
  isOwner: true,
  isPublic: false,
  coverRefs: ['c-$id-1', 'c-$id-2', 'c-$id-3', 'c-$id-4'],
);

final List<String> _ids = [registryId, for (var i = 2; i <= 6; i++) 'id-$i'];

/// The fakes behind every registry case, loaded with realistic content.
class RegistryContent {
  /// Creates the content.
  new() {
    repositories.library
      ..albumList = [for (final id in _ids) registryAlbum(id)]
      ..artistList = [for (final id in _ids) registryArtist(id)]
      ..trackList = registryTracks
      ..likedList = registryTracks.take(2).toList()
      ..albumDetails[registryId] = AlbumDetail(
        album: registryAlbum(registryId),
        tracks: registryTracks,
        owned: true,
      )
      ..artistDetails[registryId] = ArtistDetail(
        artist: registryArtist(registryId),
        topTracks: registryTracks.take(5).toList(),
        albums: [for (final id in _ids) registryAlbum(id)],
        similarArtists: const [
          SimilarArtist(name: 'Kindred', artworkRef: 'face-2', libraryId: 'x'),
          SimilarArtist(name: 'Elsewhere', artworkRef: 'face-3'),
        ],
        genres: const ['Jazz', 'Soul'],
        biography: fixtureDescription,
      );
    repositories.playlists
      ..playlistList = [for (final id in _ids) registryPlaylist(id)]
      ..playlistDetails[registryId] = PlaylistDetail(
        summary: registryPlaylist(registryId),
        items: [
          for (final (i, track) in registryTracks.indexed)
            PlaylistItem(
              id: 'item-$i',
              sort: i,
              track: track,
              isPlayable: track.playbackId != null,
            ),
        ],
      );
    repositories.home
      ..recent = [
        for (final id in _ids.take(4))
          RecentItem.artist(artist: registryArtist(id)),
      ]
      ..added = [for (final id in _ids) registryArtist(id)]
      ..mixList = [
        for (final id in _ids.take(4))
          MixSummary(id: id, name: 'Mix $id', description: longTitle),
      ]
      ..podcasts = [for (final id in _ids.take(4)) fixtureTopPodcast(id)];
    repositories.search.results[registryQuery] = SearchResults(
      library: LibrarySearchResults(
        artists: [for (final id in _ids.take(3)) registryArtist(id)],
        albums: [for (final id in _ids.take(3)) registryAlbum(id)],
        tracks: registryTracks.take(5).toList(),
      ),
    );
    podcasts
      // The detail fixture's podcast is `pc-1`; it is one of the subscriptions.
      ..subscribedList = [
        fixturePodcast('pc-1'),
        for (final id in _ids.skip(1)) fixturePodcast(id),
      ]
      ..details[registryId] = fixtureDetail(fixtureEpisodes());
    mixes.mixes[registryId] = MixDetail(
      id: registryId,
      name: longTitle,
      description: fixtureDescription,
      artworkRefs: const ['c1', 'c2', 'c3', 'c4'],
      tracks: registryTracks,
    );
    vibe
      ..similarTracks = registryTracks
      ..searchTracks = registryTracks;
  }

  /// The library, playlist, home and search fakes.
  final FakeRepositories repositories = FakeRepositories();

  /// The podcast fake.
  final FakePodcastRepository podcasts = FakePodcastRepository();

  /// The mix fake.
  final FakeMixRepository mixes = FakeMixRepository();

  /// The discovery fake.
  final FakeDiscoveryRepository discovery = FakeDiscoveryRepository();

  /// The radio fake.
  final FakeRadioRepository radio = FakeRadioRepository();

  /// The vibe fake.
  final FakeVibeRepository vibe = FakeVibeRepository();

  /// The download controller fake; one track is downloaded.
  final FakeDownloadController downloads = FakeDownloadController()
    ..setItem(const TrackItemKey('p-2'), itemState(DownloadStatus.completed));

  /// The overrides that supply every fake.
  List<Override> get overrides => [
    ...repositories.overrides,
    podcasts.providerOverride,
    mixes.providerOverride,
    discovery.providerOverride,
    radio.providerOverride,
    vibe.providerOverride,
    downloadControllerProvider.overrideWithValue(downloads),
    downloadArtworkFileProvider.overrideWith((ref, _) async => null),
  ];
}
