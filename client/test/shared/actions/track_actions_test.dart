// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

/// Records each command as a string.
class _RecordingCommands implements MenuCommands {
  final List<String> calls = [];

  @override
  Future<void> playTracks(
    List<Track> tracks,
    int index,
    QueueContext context,
  ) async => calls.add('playTracks $index ${context.kind.name}');

  @override
  Future<void> playNext(List<Track> tracks) async =>
      calls.add('playNext ${tracks.length}');

  @override
  Future<void> addToQueue(List<Track> tracks) async =>
      calls.add('addToQueue ${tracks.length}');

  @override
  Future<void> addToPlaylist(List<Track> tracks) async =>
      calls.add('addToPlaylist ${tracks.length}');

  @override
  Future<void> toggleLike(Track track) async =>
      calls.add('toggleLike ${track.meta.title}');

  @override
  Future<void> removeFromPlaylist(String playlistId, PlaylistItem item) async =>
      calls.add('remove $playlistId ${item.id}');

  @override
  Future<void> downloadTrack(Track track) async =>
      calls.add('download ${track.playbackId?.value}');

  @override
  Future<void> retryTrackDownload(Track track) async =>
      calls.add('retryDownload ${track.playbackId?.value}');

  @override
  Future<void> removeTrackDownload(Track track) async =>
      calls.add('removeDownload ${track.playbackId?.value}');

  @override
  void openAlbum(String id) => calls.add('openAlbum $id');

  @override
  void openArtist(String id) => calls.add('openArtist $id');

  @override
  Future<void> share(String link) async => calls.add('share $link');

  @override
  Future<void> playAlbum(String id, {bool shuffle = false}) async =>
      calls.add('playAlbum $id $shuffle');

  @override
  Future<List<Track>> albumTracks(String id) async => [_track(), _track()];

  @override
  Future<void> setAlbumLiked(String id, {required bool liked}) async =>
      calls.add('setAlbumLiked $id $liked');

  @override
  Future<void> playPlaylist(String id, {bool shuffle = false}) async =>
      calls.add('playPlaylist $id $shuffle');

  @override
  Future<List<Track>> playlistTracks(String id) async => [_track()];

  @override
  Future<void> renamePlaylist(PlaylistSummary playlist) async =>
      calls.add('rename ${playlist.id}');

  @override
  Future<void> deletePlaylist(PlaylistSummary playlist) async =>
      calls.add('delete ${playlist.id}');

  @override
  Future<void> playArtist(String id, {bool shuffle = false}) async =>
      calls.add('playArtist $id $shuffle');
}

Track _track({
  bool playable = true,
  String? albumId = 'al-1',
  String? artistId = 'ar-1',
  bool liked = false,
}) => Track(
  meta: const TrackMeta(
    title: 'Song',
    artist: 'Artist',
    album: 'Album',
    durationSec: 200,
  ),
  playbackId: playable ? const PlaybackId('p-1') : null,
  albumId: albumId,
  artistId: artistId,
  preference: liked ? Preference.liked : Preference.neutral,
);

const QueueContext _library = QueueContext(kind: QueueContextKind.library);

PlaylistItem _item(Track track, {bool playable = true}) =>
    PlaylistItem(id: 'item-1', sort: 1, track: track, isPlayable: playable);

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  late _RecordingCommands commands;

  setUp(() => commands = _RecordingCommands());

  List<String> ids(TrackActionScope scope) => [
    for (final entry in trackActions(scope, l10n: l10n, commands: commands))
      entry.id,
  ];

  TrackActionScope scope(
    Track track, {
    QueueContext context = _library,
    OwnedPlaylist? owned,
  }) => TrackActionScope(
    track: track,
    tracks: [track],
    index: 0,
    context: context,
    ownedPlaylist: owned,
  );

  test('a playable library track has every entry in order', () {
    final entries = trackActions(
      scope(_track()),
      l10n: l10n,
      commands: commands,
    );
    expect(entries.map((entry) => entry.id), [
      MenuIds.playNow,
      MenuIds.playNext,
      MenuIds.addToQueue,
      MenuIds.addToPlaylist,
      MenuIds.like,
      MenuIds.goToAlbum,
      MenuIds.goToArtist,
      MenuIds.share,
    ]);
    expect(entries.map((entry) => entry.label), [
      'Play now',
      'Play next',
      'Add to queue',
      'Add to playlist…',
      'Like',
      'Go to album',
      'Go to artist',
      'Share link',
    ]);
    expect(entries.where((entry) => entry.destructive), isEmpty);
  });

  test('a liked track offers Remove like', () {
    final like = trackActions(
      scope(_track(liked: true)),
      l10n: l10n,
      commands: commands,
    ).singleWhere((entry) => entry.id == MenuIds.like);
    expect(like.label, 'Remove like');
  });

  test('a track without a playbackId has only Go to album, Go to artist and '
      'Share link', () {
    expect(ids(scope(_track(playable: false))), [
      MenuIds.goToAlbum,
      MenuIds.goToArtist,
      MenuIds.share,
    ]);
    expect(
      ids(scope(_track(playable: false, albumId: null, artistId: null))),
      isEmpty,
    );
  });

  test('no albumId leaves out Go to album and Share link', () {
    expect(ids(scope(_track(albumId: null))), [
      MenuIds.playNow,
      MenuIds.playNext,
      MenuIds.addToQueue,
      MenuIds.addToPlaylist,
      MenuIds.like,
      MenuIds.goToArtist,
    ]);
  });

  test('no artistId leaves out Go to artist', () {
    expect(ids(scope(_track(artistId: null))), isNot(contains('goToArtist')));
    expect(ids(scope(_track(artistId: null))), contains(MenuIds.goToAlbum));
  });

  test('inside an owned playlist, Remove from this playlist follows Like', () {
    final track = _track();
    final entries = trackActions(
      scope(
        track,
        context: const QueueContext(
          kind: QueueContextKind.playlist,
          id: 'pl-1',
        ),
        owned: OwnedPlaylist(playlistId: 'pl-1', item: _item(track)),
      ),
      l10n: l10n,
      commands: commands,
    );
    expect(entries.map((entry) => entry.id), [
      MenuIds.playNow,
      MenuIds.playNext,
      MenuIds.addToQueue,
      MenuIds.addToPlaylist,
      MenuIds.like,
      MenuIds.removeFromPlaylist,
      MenuIds.goToAlbum,
      MenuIds.goToArtist,
      MenuIds.share,
    ]);
    final remove = entries.singleWhere(
      (entry) => entry.id == MenuIds.removeFromPlaylist,
    );
    expect(remove.label, 'Remove from this playlist');
    expect(remove.destructive, isTrue);
    remove.onSelected();
    expect(commands.calls, ['remove pl-1 item-1']);
  });

  test('an item the server marks not playable in an owned playlist can only '
      'be removed, liked and navigated from', () {
    final track = _track();
    expect(
      ids(
        scope(
          track,
          owned: OwnedPlaylist(
            playlistId: 'pl-1',
            item: _item(track, playable: false),
          ),
        ),
      ),
      [
        MenuIds.like,
        MenuIds.removeFromPlaylist,
        MenuIds.goToAlbum,
        MenuIds.goToArtist,
        MenuIds.share,
      ],
    );
  });

  test("inside someone else's playlist there is no Remove", () {
    expect(
      ids(
        scope(
          _track(),
          context: const QueueContext(
            kind: QueueContextKind.playlist,
            id: 'pl-2',
          ),
        ),
      ),
      isNot(contains(MenuIds.removeFromPlaylist)),
    );
  });

  test("on the album's own page there is no Go to album", () {
    expect(
      ids(
        scope(
          _track(),
          context: const QueueContext(kind: QueueContextKind.album, id: 'al-1'),
        ),
      ),
      [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.goToArtist,
        MenuIds.share,
      ],
    );
    // Another album's page keeps it.
    expect(
      ids(
        scope(
          _track(),
          context: const QueueContext(kind: QueueContextKind.album, id: 'al-9'),
        ),
      ),
      contains(MenuIds.goToAlbum),
    );
  });

  test("on the artist's own page there is no Go to artist", () {
    expect(
      ids(
        scope(
          _track(),
          context: const QueueContext(
            kind: QueueContextKind.artist,
            id: 'ar-1',
          ),
        ),
      ),
      isNot(contains(MenuIds.goToArtist)),
    );
  });

  test('no entry for download or radio exists', () {
    final all = {
      ...ids(scope(_track())),
      ...ids(
        scope(
          _track(),
          owned: OwnedPlaylist(playlistId: 'pl-1', item: _item(_track())),
        ),
      ),
    };
    for (final id in all) {
      expect(id.toLowerCase(), isNot(contains('download')));
      expect(id.toLowerCase(), isNot(contains('radio')));
    }
  });

  test('each entry calls its command', () {
    final track = _track();
    for (final entry in trackActions(
      TrackActionScope(
        track: track,
        tracks: [track, track],
        index: 1,
        context: _library,
      ),
      l10n: l10n,
      commands: commands,
    )) {
      entry.onSelected();
    }
    expect(commands.calls, [
      'playTracks 1 library',
      'playNext 1',
      'addToQueue 1',
      'addToPlaylist 1',
      'toggleLike Song',
      'openAlbum al-1',
      'openArtist ar-1',
      'share soundspan://album/al-1',
    ]);
  });

  group('album menu', () {
    const album = Album(
      id: 'al-1',
      title: 'Album',
      artistName: 'Artist',
      artistId: 'ar-1',
    );

    test('has its entries in order and calls each command', () async {
      final entries = albumActions(album, l10n: l10n, commands: commands);
      expect(entries.map((entry) => entry.id), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
        MenuIds.like,
        MenuIds.goToArtist,
        MenuIds.share,
      ]);
      for (final entry in entries) {
        entry.onSelected();
      }
      await Future<void>.delayed(Duration.zero);
      expect(commands.calls, [
        'playAlbum al-1 false',
        'setAlbumLiked al-1 true',
        'openArtist ar-1',
        'share soundspan://album/al-1',
        'playNext 2',
        'addToQueue 2',
        'addToPlaylist 2',
      ]);
    });

    test('a liked album offers Remove like; the artist page has no Go to '
        'artist', () {
      final entries = albumActions(
        album.copyWith(preference: Preference.liked),
        l10n: l10n,
        commands: commands,
        onArtistPage: true,
      );
      expect(
        entries.singleWhere((entry) => entry.id == MenuIds.like).label,
        'Remove like',
      );
      expect(entries.map((entry) => entry.id), isNot(contains('goToArtist')));
    });
  });

  group('playlist menu', () {
    PlaylistSummary playlist({required bool owner}) => PlaylistSummary(
      id: 'pl-1',
      name: 'Road Trip',
      trackCount: 3,
      isOwner: owner,
      isPublic: false,
    );

    test('the owner can rename and delete', () async {
      final entries = playlistActions(
        playlist(owner: true),
        l10n: l10n,
        commands: commands,
      );
      expect(entries.map((entry) => entry.id), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.share,
        MenuIds.rename,
        MenuIds.delete,
      ]);
      expect(entries.last.destructive, isTrue);
      for (final entry in entries) {
        entry.onSelected();
      }
      await Future<void>.delayed(Duration.zero);
      expect(commands.calls, [
        'playPlaylist pl-1 false',
        'share soundspan://playlist/pl-1',
        'rename pl-1',
        'delete pl-1',
        'playNext 1',
        'addToQueue 1',
      ]);
    });

    test('someone else cannot', () {
      expect(
        playlistActions(
          playlist(owner: false),
          l10n: l10n,
          commands: commands,
        ).map((entry) => entry.id),
        [MenuIds.playNow, MenuIds.playNext, MenuIds.addToQueue, MenuIds.share],
      );
    });
  });

  test('the artist menu shares the artist link', () {
    final entries = artistActions('ar 1', l10n: l10n, commands: commands);
    expect(entries.map((entry) => entry.id), [MenuIds.share]);
    entries.single.onSelected();
    expect(commands.calls, ['share soundspan://artist/ar%201']);
  });

  group('downloads', () {
    List<String> withDownload(Track track, DownloadGlyphState? glyph) => [
      for (final entry in trackActions(
        scope(track),
        l10n: l10n,
        commands: commands,
        download: glyph,
      ))
        entry.id,
    ];

    test('a track not downloaded offers Download after Like, which calls '
        'downloadTrack', () {
      final entries = trackActions(
        scope(_track()),
        l10n: l10n,
        commands: commands,
        download: DownloadGlyphState.none,
      );
      final ids = [for (final e in entries) e.id];
      expect(ids.indexOf(MenuIds.download), ids.indexOf(MenuIds.like) + 1);
      expect(ids, isNot(contains(MenuIds.removeDownload)));
      final download = entries.firstWhere((e) => e.id == MenuIds.download);
      expect(download.label, 'Download');
      download.onSelected();
      expect(commands.calls, ['download p-1']);
    });

    test('a downloaded or downloading track offers Remove download', () {
      for (final glyph in [
        DownloadGlyphState.completed,
        DownloadGlyphState.queued,
        const DownloadGlyphState.running(0.3),
        DownloadGlyphState.unavailable,
      ]) {
        final ids = withDownload(_track(), glyph);
        expect(ids, contains(MenuIds.removeDownload), reason: '$glyph');
        expect(ids, isNot(contains(MenuIds.download)), reason: '$glyph');
        expect(ids, isNot(contains(MenuIds.retryDownload)), reason: '$glyph');
      }
      trackActions(
        scope(_track()),
        l10n: l10n,
        commands: commands,
        download: DownloadGlyphState.completed,
      ).firstWhere((e) => e.id == MenuIds.removeDownload).onSelected();
      expect(commands.calls, ['removeDownload p-1']);
    });

    test('a failed download offers Retry download, which calls '
        'retryTrackDownload, and Remove download', () {
      final entries = trackActions(
        scope(_track()),
        l10n: l10n,
        commands: commands,
        download: DownloadGlyphState.failed,
      );
      final ids = [for (final e in entries) e.id];
      expect(
        ids.indexOf(MenuIds.removeDownload),
        ids.indexOf(MenuIds.retryDownload) + 1,
      );
      entries.firstWhere((e) => e.id == MenuIds.retryDownload).onSelected();
      expect(commands.calls, ['retryDownload p-1']);
    });

    test('hidden where the platform does not download and for a track '
        'without playbackId', () {
      const download = [
        MenuIds.download,
        MenuIds.removeDownload,
        MenuIds.retryDownload,
      ];
      expect(withDownload(_track(), null), isNot(anyElement(isIn(download))));
      expect(
        withDownload(_track(playable: false), DownloadGlyphState.none),
        isNot(anyElement(isIn(download))),
      );
    });
  });

  group('selection menu', () {
    const playlist = QueueContext(kind: QueueContextKind.playlist, id: 'pl-1');
    TrackActionScope row(String itemId, {bool playable = true, bool? owned}) {
      final track = _track(playable: playable);
      return TrackActionScope(
        track: track,
        tracks: [track],
        index: 0,
        context: playlist,
        ownedPlaylist: owned == null
            ? null
            : OwnedPlaylist(
                playlistId: owned ? 'pl-1' : 'pl-2',
                item: PlaylistItem(
                  id: itemId,
                  sort: 1,
                  track: track,
                  isPlayable: playable,
                ),
              ),
      );
    }

    test('one scope is the single track menu', () {
      final one = row('item-1', owned: true);
      expect(
        trackSelectionActions(
          [one],
          l10n: l10n,
          commands: commands,
        ).map((entry) => entry.id),
        ids(one),
      );
    });

    test('several scopes have the multi-track entries over the playable '
        'tracks, and each calls its command', () {
      final entries = trackSelectionActions(
        [row('item-1'), row('item-2', playable: false), row('item-3')],
        l10n: l10n,
        commands: commands,
      );
      expect(entries.map((entry) => entry.id), [
        MenuIds.playNow,
        MenuIds.playNext,
        MenuIds.addToQueue,
        MenuIds.addToPlaylist,
      ]);
      for (final entry in entries) {
        entry.onSelected();
      }
      expect(commands.calls, [
        'playTracks 0 playlist',
        'playNext 2',
        'addToQueue 2',
        'addToPlaylist 2',
      ]);
    });

    test('rows of one owned playlist can be removed together', () async {
      final entries = trackSelectionActions(
        [row('item-1', owned: true), row('item-2', owned: true)],
        l10n: l10n,
        commands: commands,
      );
      expect(entries.last.id, MenuIds.removeFromPlaylist);
      entries.last.onSelected();
      await Future<void>.delayed(Duration.zero);
      expect(commands.calls, ['remove pl-1 item-1', 'remove pl-1 item-2']);
    });

    test('rows of different playlists, or one not owned, cannot', () {
      for (final scopes in [
        [row('item-1', owned: true), row('item-2', owned: false)],
        [row('item-1', owned: true), row('item-2')],
      ]) {
        expect(
          trackSelectionActions(
            scopes,
            l10n: l10n,
            commands: commands,
          ).map((entry) => entry.id),
          isNot(contains(MenuIds.removeFromPlaylist)),
        );
      }
    });
  });
}
