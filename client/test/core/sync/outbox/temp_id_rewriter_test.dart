// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/cache/cache_database.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/core/sync/outbox/temp_id_rewriter.dart';
import 'package:soundspan/shared/domain/playlist.dart';

import 'outbox_test_support.dart';

const _tmp = 'tmp_0b6a';
const _real = 'pl-42';

PlaylistSummary _summary(String id) => PlaylistSummary(
  id: id,
  name: 'Road trip',
  trackCount: 0,
  isOwner: true,
  isPublic: false,
);

void main() {
  late WorkerRig rig;

  setUp(() => rig = WorkerRig());
  tearDown(() => rig.close());

  Future<void> cachePlaylist(String id, {int position = 0}) async {
    final cache = rig.cache;
    final now = rig.clock.now();
    await cache
        .into(cache.playlists)
        .insert(
          CachePlaylist(
            id: id,
            json: jsonEncode(_summary(id).toJson()),
            name: 'Road trip',
            fetchedAt: now,
          ),
        );
    for (final key in ['playlists', 'playlist:$id']) {
      await cache
          .into(cache.lists)
          .insertOnConflictUpdate(
            CacheList(
              listKey: key,
              fetchedAt: now,
              complete: true,
              lastReadAt: now,
            ),
          );
    }
    await cache
        .into(cache.listEntries)
        .insert(
          CacheListEntry(
            listKey: 'playlists',
            position: position,
            entityKind: CacheEntityKind.playlist,
            entityKey: id,
          ),
        );
    await cache
        .into(cache.listEntries)
        .insert(
          CacheListEntry(
            listKey: 'playlist:$id',
            position: 0,
            entityKind: CacheEntityKind.track,
            entityKey: 'track-1',
          ),
        );
    await cache
        .into(cache.blobs)
        .insert(
          CacheBlob(
            key: 'playlist:$id',
            json: jsonEncode({
              'summary': _summary(id).toJson(),
              'items': <Object>[],
            }),
            fetchedAt: now,
          ),
        );
  }

  test('create, add, rename and reorder against a temporary id are sent '
      'with the real id after the create succeeds', () async {
    rig.handler.script = (op) =>
        op is PlaylistCreateOp ? _summary(_real) : null;
    await rig.put(const PlaylistCreateOp(tempId: _tmp, name: 'Road trip'));
    await rig.put(
      const PlaylistAddOp(
        playlistId: _tmp,
        opUuid: 'u1',
        playbackId: 'pb-1',
        metadata: {'title': 'Song'},
      ),
    );
    await rig.put(const PlaylistRenameOp(playlistId: _tmp, name: 'Trip'));
    await rig.put(
      const PlaylistReorderOp(playlistId: _tmp, playbackIds: ['pb-1']),
    );

    await rig.pass();

    expect(rig.handler.sent, [
      const PlaylistCreateOp(tempId: _tmp, name: 'Road trip'),
      const PlaylistAddOp(
        playlistId: _real,
        opUuid: 'u1',
        playbackId: 'pb-1',
        metadata: {'title': 'Song'},
      ),
      const PlaylistRenameOp(playlistId: _real, name: 'Trip'),
      const PlaylistReorderOp(playlistId: _real, playbackIds: ['pb-1']),
    ]);
    expect(await rig.pending(), isEmpty);
    expect(rig.resolved, [const TempIdResolved(_tmp, _real)]);
    expect(rig.handler.succeeded.first.$2, _summary(_real));
  });

  test('pending ops carry the real id in payload and entityKey', () async {
    var fail = false;
    rig.handler.script = (op) {
      if (op is PlaylistCreateOp) return _summary(_real);
      if (fail) throw StateError('stop here');
      return null;
    };
    fail = true;
    await rig.put(const PlaylistCreateOp(tempId: _tmp, name: 'Road trip'));
    await rig.put(
      const PlaylistAddOp(
        playlistId: _tmp,
        opUuid: 'u1',
        playbackId: 'pb-1',
        metadata: {'title': 'Song'},
      ),
    );

    await rig.pass();

    final entry = (await rig.pending()).single;
    expect(entry.op.entityKey, 'plitem:$_real:u1');
    expect((entry.op as PlaylistAddOp).playlistId, _real);
  });

  test('the cache row, list key, list entries and blob carry the real '
      'id', () async {
    await cachePlaylist(_tmp);
    rig.handler.script = (op) => _summary(_real);
    await rig.put(const PlaylistCreateOp(tempId: _tmp, name: 'Road trip'));

    await rig.pass();

    final cache = rig.cache;
    final playlist = await cache.select(cache.playlists).getSingle();
    expect(playlist.id, _real);
    expect(jsonDecode(playlist.json), containsPair('id', _real));
    final lists = await cache.select(cache.lists).get();
    expect(
      lists.map((l) => l.listKey),
      unorderedEquals(['playlists', 'playlist:$_real']),
    );
    final entries = await cache.select(cache.listEntries).get();
    expect(
      entries.map((e) => (e.listKey, e.entityKey)),
      unorderedEquals([('playlists', _real), ('playlist:$_real', 'track-1')]),
    );
    final blob = await cache.select(cache.blobs).getSingle();
    expect(blob.key, 'playlist:$_real');
    expect(blob.json, isNot(contains(_tmp)));
    expect(rig.resolved, hasLength(1));
  });

  test('orphaned temporary cache rows are removed at start', () async {
    await cachePlaylist('tmp_orphan');
    await cachePlaylist(_tmp, position: 1);
    await rig.put(const PlaylistCreateOp(tempId: _tmp, name: 'Road trip'));
    rig.handler.script = (_) => throw StateError('keep it pending');

    await rig.worker.start();
    await rig.settle();

    final cache = rig.cache;
    final ids = [
      for (final row in await cache.select(cache.playlists).get()) row.id,
    ];
    expect(ids, [_tmp]);
    final keys = [
      for (final row in await cache.select(cache.lists).get()) row.listKey,
    ];
    expect(keys, unorderedEquals(['playlists', 'playlist:$_tmp']));
    final blobs = [
      for (final row in await cache.select(cache.blobs).get()) row.key,
    ];
    expect(blobs, ['playlist:$_tmp']);
    final entries = await cache.select(cache.listEntries).get();
    expect(entries.map((e) => e.entityKey), isNot(contains('tmp_orphan')));
  });
}
