// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/shared/data/playlist/playlist_mappers.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan_api/soundspan_api.dart' as api;

Map<String, Object?> _owner() => {'username': 'listener'};

Map<String, Object?> _cover(String id, String? coverArt) => {
  'id': id,
  'track': {
    'album': {'coverArt': coverArt},
  },
};

Map<String, Object?> _summaryJson({List<Map<String, Object?>>? items}) => {
  'id': 'pl-1',
  'name': 'Road trip',
  'trackCount': 6,
  'isOwner': true,
  'isPublic': false,
  'isHidden': false,
  'items': items ?? <Object?>[],
  'createdAt': '2024-01-01T00:00:00.000Z',
  'updatedAt': '2024-01-02T00:00:00.000Z',
  'user': _owner(),
  'userId': 'u-1',
};

Map<String, Object?> _itemJson(
  String id, {
  required int sort,
  bool isPlayable = true,
  String? message,
  String? playbackId = 'pb',
}) => {
  'id': id,
  'playlistId': 'pl-1',
  'sort': sort,
  'type': 'track',
  'playback': {
    'isPlayable': isPlayable,
    'reason': isPlayable ? null : 'SOURCE_UNAVAILABLE',
    'message': message,
  },
  'track': {
    'id': 't-$id',
    'title': 'Song $id',
    'duration': 180,
    'trackNo': 1,
    'source': 'local',
    'albumId': 'al-1',
    'artistId': 'ar-1',
    'playbackId': ?(playbackId == null ? null : '$playbackId-$id'),
    'album': {'id': 'al-1', 'title': 'Record', 'coverArt': 'cover-al-1'},
    'artist': {'id': 'ar-1', 'name': 'Band'},
  },
};

Map<String, Object?> _detailJson(List<Map<String, Object?>> items) => {
  ..._summaryJson(),
  'items': items,
  'pendingCount': 0,
  'totalItemCount': items.length,
  'truncated': false,
};

void main() {
  test('summary takes up to four cover refs', () {
    final summary = playlistSummaryFromWire(
      api.PlaylistSummary.fromJson(
        _summaryJson(
          items: [
            _cover('i-1', 'c-1'),
            _cover('i-2', null),
            {'id': 'i-3', 'track': null},
            _cover('i-4', 'c-4'),
            _cover('i-5', 'c-5'),
            _cover('i-6', 'c-6'),
            _cover('i-7', 'c-7'),
          ],
        ),
      ),
    );

    expect(
      summary,
      const PlaylistSummary(
        id: 'pl-1',
        name: 'Road trip',
        trackCount: 6,
        isOwner: true,
        isPublic: false,
        coverRefs: ['c-1', 'c-4', 'c-5', 'c-6'],
      ),
    );
  });

  test('unplayable item keeps the server message', () {
    final detail = playlistDetailFromWire(
      api.PlaylistDetail.fromJson(
        _detailJson([
          _itemJson(
            'i-1',
            sort: 0,
            isPlayable: false,
            message: 'TIDAL is turned off on this server',
          ),
          _itemJson('i-2', sort: 1),
        ]),
      ),
    );

    expect(detail.items.first.isPlayable, isFalse);
    expect(detail.items.first.message, 'TIDAL is turned off on this server');
    expect(detail.items.last.isPlayable, isTrue);
    expect(detail.items.last.message, isNull);
  });

  test('item order follows sort', () {
    final detail = playlistDetailFromWire(
      api.PlaylistDetail.fromJson(
        _detailJson([
          _itemJson('i-3', sort: 7),
          _itemJson('i-1', sort: 1),
          _itemJson('i-2', sort: 4),
        ]),
      ),
    );

    expect([for (final item in detail.items) item.id], ['i-1', 'i-2', 'i-3']);
    expect([for (final item in detail.items) item.sort], [1, 4, 7]);
  });

  test('an item maps its track; one without a playbackId is not playable', () {
    final detail = playlistDetailFromWire(
      api.PlaylistDetail.fromJson(
        _detailJson([_itemJson('i-1', sort: 0, playbackId: null)]),
      ),
    );

    final track = detail.items.single.track;
    expect(track.playbackId, isNull);
    expect(track.meta.title, 'Song i-1');
    expect(track.meta.artist, 'Band');
    expect(track.meta.album, 'Record');
    expect(track.meta.artworkRef, 'cover-al-1');
    expect(detail.summary.id, 'pl-1');
    expect(detail.summary.trackCount, 6);
  });

  test('an item whose track is null is left out of the detail', () {
    final detail = playlistDetailFromWire(
      api.PlaylistDetail.fromJson(
        _detailJson([
          _itemJson('i-1', sort: 0),
          {..._itemJson('i-2', sort: 1), 'track': null},
        ]),
      ),
    );

    expect([for (final item in detail.items) item.id], ['i-1']);
  });

  test('an item without a track maps to null', () {
    final wire = api.PlaylistItem.fromJson({
      ..._itemJson('i-1', sort: 0),
      'track': null,
    });

    expect(playlistItemFromWire(wire), isNull);
  });
}
