// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show immutable;

/// A like, a dislike, or clearing both, as sent to the preference endpoints.
enum PreferenceSignal {
  /// A like.
  thumbsUp('thumbs_up'),

  /// A dislike.
  thumbsDown('thumbs_down'),

  /// Neither.
  clear('clear');

  new(this.wire);

  /// The value on the wire.
  final String wire;

  static PreferenceSignal _parse(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () => throw FormatException('unknown preference signal', wire),
  );
}

/// A write the server has not received yet (doc 07, Outbox).
///
/// There is one subclass per row of the Operations table. [opType] and
/// [entityKey] are stored in the `outbox` table; [toPayload] is stored as
/// JSON and read back with [decode]. Two ops are equal when they have the
/// same type and payload. `metadata` fields hold the JSON form of the
/// track's `TrackMeta`; `playbackId` values are opaque strings.
@immutable
sealed class OutboxOp {
  const new();

  /// The operation's type, for example `preference`.
  String get opType;

  /// The coalescing key, for example `pref:<playbackId>`.
  String get entityKey;

  /// The operation's fields as JSON values.
  Map<String, Object?> toPayload();

  /// Reads the op stored as [opType] with [payloadJson].
  ///
  /// Throws [FormatException] for an unknown [opType] or a payload that is
  /// not a JSON object with every field of that type.
  static OutboxOp decode(String opType, String payloadJson) {
    final Object? decoded;
    try {
      decoded = jsonDecode(payloadJson);
    } on FormatException catch (e) {
      throw FormatException('outbox payload is not JSON: ${e.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw FormatException('outbox payload is not an object', payloadJson);
    }
    final p = _Payload(opType, decoded);
    return switch (opType) {
      PreferenceOp.type => PreferenceOp(
        playbackId: p.string('playbackId'),
        signal: PreferenceSignal._parse(p.string('signal')),
        metadata: p.object('metadata'),
      ),
      AlbumPreferenceOp.type => AlbumPreferenceOp(
        albumId: p.string('albumId'),
        signal: PreferenceSignal._parse(p.string('signal')),
      ),
      PlayOp.type => PlayOp(
        sessionId: p.string('sessionId'),
        playbackId: p.string('playbackId'),
        metadata: p.object('metadata'),
        playedAt: p.time('playedAt'),
        listenedMs: p.integer('listenedMs'),
      ),
      PlaylistCreateOp.type => PlaylistCreateOp(
        tempId: p.string('tempId'),
        name: p.string('name'),
        isPublic: p.optionalBool('isPublic'),
      ),
      PlaylistRenameOp.type => PlaylistRenameOp(
        playlistId: p.string('playlistId'),
        name: p.string('name'),
      ),
      PlaylistDeleteOp.type => PlaylistDeleteOp(
        playlistId: p.string('playlistId'),
      ),
      PlaylistAddOp.type => PlaylistAddOp(
        playlistId: p.string('playlistId'),
        opUuid: p.string('opUuid'),
        playbackId: p.string('playbackId'),
        metadata: p.object('metadata'),
      ),
      PlaylistRemoveOp.type => PlaylistRemoveOp(
        playlistId: p.string('playlistId'),
        opUuid: p.string('opUuid'),
        playbackId: p.string('playbackId'),
      ),
      PlaylistReorderOp.type => PlaylistReorderOp(
        playlistId: p.string('playlistId'),
        playbackIds: p.strings('playbackIds'),
      ),
      EpisodeProgressOp.type => EpisodeProgressOp(
        podcastId: p.string('podcastId'),
        episodeId: p.string('episodeId'),
        currentTime: p.number('currentTime'),
        duration: p.number('duration'),
        isFinished: p.boolean('isFinished'),
      ),
      OfflineCompleteOp.type => OfflineCompleteOp(
        deviceId: p.string('deviceId'),
        playbackId: p.string('playbackId'),
        quality: p.string('quality'),
        sizeBytes: p.integer('sizeBytes'),
      ),
      OfflineDeleteOp.type => OfflineDeleteOp(
        batchUuid: p.string('batchUuid'),
        deviceId: p.string('deviceId'),
        playbackIds: p.strings('playbackIds'),
      ),
      _ => throw FormatException('unknown outbox opType', opType),
    };
  }

  static const _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is OutboxOp &&
      other.opType == opType &&
      _equality.equals(other.toPayload(), toPayload());

  @override
  int get hashCode => Object.hash(opType, _equality.hash(toPayload()));

  @override
  String toString() => 'OutboxOp($opType, $entityKey)';
}

/// A track like, dislike or clear: `POST /library/preferences`.
final class PreferenceOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.playbackId,
    required this.signal,
    required this.metadata,
  });

  /// The [opType] of this class.
  static const type = 'preference';

  /// The track.
  final String playbackId;

  /// The signal.
  final PreferenceSignal signal;

  /// The track's `TrackMeta` as JSON.
  final Map<String, Object?> metadata;

  @override
  String get opType => type;

  @override
  String get entityKey => 'pref:$playbackId';

  @override
  Map<String, Object?> toPayload() => {
    'playbackId': playbackId,
    'signal': signal.wire,
    'metadata': metadata,
  };
}

/// An album like, dislike or clear: `POST /library/albums/:id/preference`.
final class AlbumPreferenceOp extends OutboxOp {
  /// Creates the op.
  const new({required this.albumId, required this.signal});

  /// The [opType] of this class.
  static const type = 'albumPreference';

  /// The album.
  final String albumId;

  /// The signal.
  final PreferenceSignal signal;

  @override
  String get opType => type;

  @override
  String get entityKey => 'apref:$albumId';

  @override
  Map<String, Object?> toPayload() => {
    'albumId': albumId,
    'signal': signal.wire,
  };
}

/// A play report: `POST /plays`.
final class PlayOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.sessionId,
    required this.playbackId,
    required this.metadata,
    required this.playedAt,
    required this.listenedMs,
  });

  /// The [opType] of this class.
  static const type = 'play';

  /// The client's play session.
  final String sessionId;

  /// The track.
  final String playbackId;

  /// The track's `TrackMeta` as JSON.
  final Map<String, Object?> metadata;

  /// When the play started; stored in UTC.
  final DateTime playedAt;

  /// How long the track was listened to.
  final int listenedMs;

  @override
  String get opType => type;

  @override
  String get entityKey => 'play:$sessionId';

  @override
  Map<String, Object?> toPayload() => {
    'sessionId': sessionId,
    'playbackId': playbackId,
    'metadata': metadata,
    'playedAt': playedAt.toUtc().toIso8601String(),
    'listenedMs': listenedMs,
  };
}

/// A playlist created on this device: `POST /playlists`.
final class PlaylistCreateOp extends OutboxOp {
  /// Creates the op.
  const new({required this.tempId, required this.name, this.isPublic});

  /// The [opType] of this class.
  static const type = 'playlistCreate';

  /// The temporary id, `tmp_<uuid>`, until the server assigns one.
  final String tempId;

  /// The name.
  final String name;

  /// Whether the playlist is public; the server's default when null.
  final bool? isPublic;

  @override
  String get opType => type;

  @override
  String get entityKey => 'pl:$tempId';

  @override
  Map<String, Object?> toPayload() => {
    'tempId': tempId,
    'name': name,
    if (isPublic != null) 'isPublic': isPublic,
  };
}

/// A playlist rename: `PUT /playlists/:id`.
final class PlaylistRenameOp extends OutboxOp {
  /// Creates the op.
  const new({required this.playlistId, required this.name});

  /// The [opType] of this class.
  static const type = 'playlistRename';

  /// The playlist.
  final String playlistId;

  /// The new name.
  final String name;

  @override
  String get opType => type;

  @override
  String get entityKey => 'plname:$playlistId';

  @override
  Map<String, Object?> toPayload() => {'playlistId': playlistId, 'name': name};
}

/// A playlist deletion: `DELETE /playlists/:id`.
final class PlaylistDeleteOp extends OutboxOp {
  /// Creates the op.
  const new({required this.playlistId});

  /// The [opType] of this class.
  static const type = 'playlistDelete';

  /// The playlist.
  final String playlistId;

  @override
  String get opType => type;

  @override
  String get entityKey => 'pl:$playlistId';

  @override
  Map<String, Object?> toPayload() => {'playlistId': playlistId};
}

/// A track added to a playlist: `POST /playlists/:id/items`.
final class PlaylistAddOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.playlistId,
    required this.opUuid,
    required this.playbackId,
    required this.metadata,
  });

  /// The [opType] of this class.
  static const type = 'playlistAdd';

  /// The playlist.
  final String playlistId;

  /// Identifies this add, so a remove of the same pending item cancels it.
  final String opUuid;

  /// The track.
  final String playbackId;

  /// The track's `TrackMeta` as JSON.
  final Map<String, Object?> metadata;

  @override
  String get opType => type;

  @override
  String get entityKey => 'plitem:$playlistId:$opUuid';

  @override
  Map<String, Object?> toPayload() => {
    'playlistId': playlistId,
    'opUuid': opUuid,
    'playbackId': playbackId,
    'metadata': metadata,
  };
}

/// A track removed from a playlist:
/// `DELETE /playlists/:id/items/:playbackId`.
final class PlaylistRemoveOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.playlistId,
    required this.opUuid,
    required this.playbackId,
  });

  /// The [opType] of this class.
  static const type = 'playlistRemove';

  /// The playlist.
  final String playlistId;

  /// The `opUuid` of the pending add this removes, or a fresh uuid.
  final String opUuid;

  /// The track.
  final String playbackId;

  @override
  String get opType => type;

  @override
  String get entityKey => 'plitem:$playlistId:$opUuid';

  @override
  Map<String, Object?> toPayload() => {
    'playlistId': playlistId,
    'opUuid': opUuid,
    'playbackId': playbackId,
  };
}

/// A playlist's new order: `PUT /playlists/:id/items/reorder`.
final class PlaylistReorderOp extends OutboxOp {
  /// Creates the op.
  const new({required this.playlistId, required this.playbackIds});

  /// The [opType] of this class.
  static const type = 'playlistReorder';

  /// The playlist.
  final String playlistId;

  /// Every track of the playlist, in the new order.
  final List<String> playbackIds;

  @override
  String get opType => type;

  @override
  String get entityKey => 'plorder:$playlistId';

  @override
  Map<String, Object?> toPayload() => {
    'playlistId': playlistId,
    'playbackIds': playbackIds,
  };
}

/// An episode's playback progress:
/// `POST /podcasts/:podcastId/episodes/:episodeId/progress`.
final class EpisodeProgressOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.podcastId,
    required this.episodeId,
    required this.currentTime,
    required this.duration,
    required this.isFinished,
  });

  /// The [opType] of this class.
  static const type = 'episodeProgress';

  /// The podcast.
  final String podcastId;

  /// The episode.
  final String episodeId;

  /// The position, in seconds.
  final num currentTime;

  /// The episode's length, in seconds.
  final num duration;

  /// Whether the episode was played to the end.
  final bool isFinished;

  @override
  String get opType => type;

  @override
  String get entityKey => 'ep:$episodeId';

  @override
  Map<String, Object?> toPayload() => {
    'podcastId': podcastId,
    'episodeId': episodeId,
    'currentTime': currentTime,
    'duration': duration,
    'isFinished': isFinished,
  };
}

/// A finished download: `POST /offline/items/complete`.
final class OfflineCompleteOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.deviceId,
    required this.playbackId,
    required this.quality,
    required this.sizeBytes,
  });

  /// The [opType] of this class.
  static const type = 'offlineComplete';

  /// The device the file is on.
  final String deviceId;

  /// The track.
  final String playbackId;

  /// The quality that was downloaded.
  final String quality;

  /// The file's size.
  final int sizeBytes;

  @override
  String get opType => type;

  @override
  String get entityKey => 'oc:$playbackId';

  @override
  Map<String, Object?> toPayload() => {
    'deviceId': deviceId,
    'playbackId': playbackId,
    'quality': quality,
    'sizeBytes': sizeBytes,
  };
}

/// Downloads removed from this device: `DELETE /offline/items`.
final class OfflineDeleteOp extends OutboxOp {
  /// Creates the op.
  const new({
    required this.batchUuid,
    required this.deviceId,
    required this.playbackIds,
  });

  /// The [opType] of this class.
  static const type = 'offlineDelete';

  /// The most ids one request carries.
  static const maxIds = 500;

  /// Identifies this batch in the outbox; never sent.
  final String batchUuid;

  /// The device the files were on.
  final String deviceId;

  /// The removed tracks.
  final List<String> playbackIds;

  @override
  String get opType => type;

  @override
  String get entityKey => 'od:$batchUuid';

  @override
  Map<String, Object?> toPayload() => {
    'batchUuid': batchUuid,
    'deviceId': deviceId,
    'playbackIds': playbackIds,
  };
}

/// Typed field access over a decoded payload; every miss is a
/// [FormatException].
class _Payload {
  const new(this.opType, this.json);

  final String opType;
  final Map<String, Object?> json;

  T _field<T>(String key) {
    final value = json[key];
    if (value is T) return value;
    throw FormatException('outbox $opType: field $key is not a $T', value);
  }

  String string(String key) => _field<String>(key);

  int integer(String key) => _field<int>(key);

  num number(String key) => _field<num>(key);

  bool boolean(String key) => _field<bool>(key);

  bool? optionalBool(String key) => _field<bool?>(key);

  Map<String, Object?> object(String key) => _field<Map<String, Object?>>(key);

  List<String> strings(String key) {
    final list = _field<List<Object?>>(key);
    if (list.every((e) => e is String)) return List.unmodifiable(list);
    throw FormatException('outbox $opType: $key holds a non-string', list);
  }

  DateTime time(String key) {
    final parsed = DateTime.tryParse(string(key));
    if (parsed == null) {
      throw FormatException('outbox $opType: $key is not a time');
    }
    return parsed.toUtc();
  }
}
