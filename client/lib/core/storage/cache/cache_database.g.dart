// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_database.dart';

// ignore_for_file: type=lint
class $TracksTable extends Tracks with TableInfo<$TracksTable, CacheTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playbackIdMeta = const VerificationMeta(
    'playbackId',
  );
  @override
  late final GeneratedColumn<String> playbackId = GeneratedColumn<String>(
    'playback_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistIdMeta = const VerificationMeta(
    'artistId',
  );
  @override
  late final GeneratedColumn<String> artistId = GeneratedColumn<String>(
    'artist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    playbackId,
    json,
    albumId,
    artistId,
    title,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('playback_id')) {
      context.handle(
        _playbackIdMeta,
        playbackId.isAcceptableOrUnknown(data['playback_id']!, _playbackIdMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('artist_id')) {
      context.handle(
        _artistIdMeta,
        artistId.isAcceptableOrUnknown(data['artist_id']!, _artistIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheTrack(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      playbackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playback_id'],
      ),
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      artistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }
}

class CacheTrack extends DataClass implements Insertable<CacheTrack> {
  /// The track's cache key.
  final String key;

  /// The playback id; null for a track that cannot be played.
  final String? playbackId;

  /// The domain track, JSON-encoded.
  final String json;

  /// The album's id, for local queries.
  final String? albumId;

  /// The artist's id, for local queries.
  final String? artistId;

  /// The title, for local search.
  final String title;

  /// When the row was fetched, in UTC.
  final DateTime fetchedAt;
  const CacheTrack({
    required this.key,
    this.playbackId,
    required this.json,
    this.albumId,
    this.artistId,
    required this.title,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || playbackId != null) {
      map['playback_id'] = Variable<String>(playbackId);
    }
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || artistId != null) {
      map['artist_id'] = Variable<String>(artistId);
    }
    map['title'] = Variable<String>(title);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      key: Value(key),
      playbackId: playbackId == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackId),
      json: Value(json),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      artistId: artistId == null && nullToAbsent
          ? const Value.absent()
          : Value(artistId),
      title: Value(title),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CacheTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheTrack(
      key: serializer.fromJson<String>(json['key']),
      playbackId: serializer.fromJson<String?>(json['playbackId']),
      json: serializer.fromJson<String>(json['json']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      artistId: serializer.fromJson<String?>(json['artistId']),
      title: serializer.fromJson<String>(json['title']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'playbackId': serializer.toJson<String?>(playbackId),
      'json': serializer.toJson<String>(json),
      'albumId': serializer.toJson<String?>(albumId),
      'artistId': serializer.toJson<String?>(artistId),
      'title': serializer.toJson<String>(title),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CacheTrack copyWith({
    String? key,
    Value<String?> playbackId = const Value.absent(),
    String? json,
    Value<String?> albumId = const Value.absent(),
    Value<String?> artistId = const Value.absent(),
    String? title,
    DateTime? fetchedAt,
  }) => CacheTrack(
    key: key ?? this.key,
    playbackId: playbackId.present ? playbackId.value : this.playbackId,
    json: json ?? this.json,
    albumId: albumId.present ? albumId.value : this.albumId,
    artistId: artistId.present ? artistId.value : this.artistId,
    title: title ?? this.title,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CacheTrack copyWithCompanion(TracksCompanion data) {
    return CacheTrack(
      key: data.key.present ? data.key.value : this.key,
      playbackId: data.playbackId.present
          ? data.playbackId.value
          : this.playbackId,
      json: data.json.present ? data.json.value : this.json,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      artistId: data.artistId.present ? data.artistId.value : this.artistId,
      title: data.title.present ? data.title.value : this.title,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheTrack(')
          ..write('key: $key, ')
          ..write('playbackId: $playbackId, ')
          ..write('json: $json, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('title: $title, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, playbackId, json, albumId, artistId, title, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheTrack &&
          other.key == this.key &&
          other.playbackId == this.playbackId &&
          other.json == this.json &&
          other.albumId == this.albumId &&
          other.artistId == this.artistId &&
          other.title == this.title &&
          other.fetchedAt == this.fetchedAt);
}

class TracksCompanion extends UpdateCompanion<CacheTrack> {
  final Value<String> key;
  final Value<String?> playbackId;
  final Value<String> json;
  final Value<String?> albumId;
  final Value<String?> artistId;
  final Value<String> title;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const TracksCompanion({
    this.key = const Value.absent(),
    this.playbackId = const Value.absent(),
    this.json = const Value.absent(),
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    this.title = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String key,
    this.playbackId = const Value.absent(),
    required String json,
    this.albumId = const Value.absent(),
    this.artistId = const Value.absent(),
    required String title,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       json = Value(json),
       title = Value(title),
       fetchedAt = Value(fetchedAt);
  static Insertable<CacheTrack> custom({
    Expression<String>? key,
    Expression<String>? playbackId,
    Expression<String>? json,
    Expression<String>? albumId,
    Expression<String>? artistId,
    Expression<String>? title,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (playbackId != null) 'playback_id': playbackId,
      if (json != null) 'json': json,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
      if (title != null) 'title': title,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? key,
    Value<String?>? playbackId,
    Value<String>? json,
    Value<String?>? albumId,
    Value<String?>? artistId,
    Value<String>? title,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
      key: key ?? this.key,
      playbackId: playbackId ?? this.playbackId,
      json: json ?? this.json,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      title: title ?? this.title,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (playbackId.present) {
      map['playback_id'] = Variable<String>(playbackId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (artistId.present) {
      map['artist_id'] = Variable<String>(artistId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('key: $key, ')
          ..write('playbackId: $playbackId, ')
          ..write('json: $json, ')
          ..write('albumId: $albumId, ')
          ..write('artistId: $artistId, ')
          ..write('title: $title, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, CacheAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNameMeta = const VerificationMeta(
    'artistName',
  );
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
    'artist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailFetchedAtMeta = const VerificationMeta(
    'detailFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detailFetchedAt =
      GeneratedColumn<DateTime>(
        'detail_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    title,
    artistName,
    year,
    fetchedAt,
    detailFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheAlbum> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
        _artistNameMeta,
        artistName.isAcceptableOrUnknown(data['artist_name']!, _artistNameMeta),
      );
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('detail_fetched_at')) {
      context.handle(
        _detailFetchedAtMeta,
        detailFetchedAt.isAcceptableOrUnknown(
          data['detail_fetched_at']!,
          _detailFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheAlbum(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artistName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist_name'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      detailFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detail_fetched_at'],
      ),
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class CacheAlbum extends DataClass implements Insertable<CacheAlbum> {
  /// The album's id.
  final String id;

  /// The domain album, JSON-encoded.
  final String json;

  /// The title, for local search and sorting.
  final String title;

  /// The album artist's name, for local sorting.
  final String artistName;

  /// The release year, when known.
  final int? year;

  /// When the row was fetched, in UTC.
  final DateTime fetchedAt;

  /// When the album's detail was last fetched, in UTC.
  final DateTime? detailFetchedAt;
  const CacheAlbum({
    required this.id,
    required this.json,
    required this.title,
    required this.artistName,
    this.year,
    required this.fetchedAt,
    this.detailFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['title'] = Variable<String>(title);
    map['artist_name'] = Variable<String>(artistName);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || detailFetchedAt != null) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt);
    }
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      json: Value(json),
      title: Value(title),
      artistName: Value(artistName),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      fetchedAt: Value(fetchedAt),
      detailFetchedAt: detailFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detailFetchedAt),
    );
  }

  factory CacheAlbum.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheAlbum(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      title: serializer.fromJson<String>(json['title']),
      artistName: serializer.fromJson<String>(json['artistName']),
      year: serializer.fromJson<int?>(json['year']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      detailFetchedAt: serializer.fromJson<DateTime?>(json['detailFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'title': serializer.toJson<String>(title),
      'artistName': serializer.toJson<String>(artistName),
      'year': serializer.toJson<int?>(year),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'detailFetchedAt': serializer.toJson<DateTime?>(detailFetchedAt),
    };
  }

  CacheAlbum copyWith({
    String? id,
    String? json,
    String? title,
    String? artistName,
    Value<int?> year = const Value.absent(),
    DateTime? fetchedAt,
    Value<DateTime?> detailFetchedAt = const Value.absent(),
  }) => CacheAlbum(
    id: id ?? this.id,
    json: json ?? this.json,
    title: title ?? this.title,
    artistName: artistName ?? this.artistName,
    year: year.present ? year.value : this.year,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    detailFetchedAt: detailFetchedAt.present
        ? detailFetchedAt.value
        : this.detailFetchedAt,
  );
  CacheAlbum copyWithCompanion(AlbumsCompanion data) {
    return CacheAlbum(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      title: data.title.present ? data.title.value : this.title,
      artistName: data.artistName.present
          ? data.artistName.value
          : this.artistName,
      year: data.year.present ? data.year.value : this.year,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      detailFetchedAt: data.detailFetchedAt.present
          ? data.detailFetchedAt.value
          : this.detailFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheAlbum(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('year: $year, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailFetchedAt: $detailFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    json,
    title,
    artistName,
    year,
    fetchedAt,
    detailFetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheAlbum &&
          other.id == this.id &&
          other.json == this.json &&
          other.title == this.title &&
          other.artistName == this.artistName &&
          other.year == this.year &&
          other.fetchedAt == this.fetchedAt &&
          other.detailFetchedAt == this.detailFetchedAt);
}

class AlbumsCompanion extends UpdateCompanion<CacheAlbum> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> title;
  final Value<String> artistName;
  final Value<int?> year;
  final Value<DateTime> fetchedAt;
  final Value<DateTime?> detailFetchedAt;
  final Value<int> rowid;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.title = const Value.absent(),
    this.artistName = const Value.absent(),
    this.year = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.detailFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumsCompanion.insert({
    required String id,
    required String json,
    required String title,
    required String artistName,
    this.year = const Value.absent(),
    required DateTime fetchedAt,
    this.detailFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       title = Value(title),
       artistName = Value(artistName),
       fetchedAt = Value(fetchedAt);
  static Insertable<CacheAlbum> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? title,
    Expression<String>? artistName,
    Expression<int>? year,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? detailFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (title != null) 'title': title,
      if (artistName != null) 'artist_name': artistName,
      if (year != null) 'year': year,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (detailFetchedAt != null) 'detail_fetched_at': detailFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? title,
    Value<String>? artistName,
    Value<int?>? year,
    Value<DateTime>? fetchedAt,
    Value<DateTime?>? detailFetchedAt,
    Value<int>? rowid,
  }) {
    return AlbumsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      year: year ?? this.year,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      detailFetchedAt: detailFetchedAt ?? this.detailFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (detailFetchedAt.present) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('year: $year, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailFetchedAt: $detailFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArtistsTable extends Artists with TableInfo<$ArtistsTable, CacheArtist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailFetchedAtMeta = const VerificationMeta(
    'detailFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detailFetchedAt =
      GeneratedColumn<DateTime>(
        'detail_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    name,
    fetchedAt,
    detailFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheArtist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('detail_fetched_at')) {
      context.handle(
        _detailFetchedAtMeta,
        detailFetchedAt.isAcceptableOrUnknown(
          data['detail_fetched_at']!,
          _detailFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheArtist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheArtist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      detailFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detail_fetched_at'],
      ),
    );
  }

  @override
  $ArtistsTable createAlias(String alias) {
    return $ArtistsTable(attachedDatabase, alias);
  }
}

class CacheArtist extends DataClass implements Insertable<CacheArtist> {
  /// The artist's id.
  final String id;

  /// The domain artist, JSON-encoded.
  final String json;

  /// The name, for local search and sorting.
  final String name;

  /// When the row was fetched, in UTC.
  final DateTime fetchedAt;

  /// When the artist's detail was last fetched, in UTC.
  final DateTime? detailFetchedAt;
  const CacheArtist({
    required this.id,
    required this.json,
    required this.name,
    required this.fetchedAt,
    this.detailFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['name'] = Variable<String>(name);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || detailFetchedAt != null) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt);
    }
    return map;
  }

  ArtistsCompanion toCompanion(bool nullToAbsent) {
    return ArtistsCompanion(
      id: Value(id),
      json: Value(json),
      name: Value(name),
      fetchedAt: Value(fetchedAt),
      detailFetchedAt: detailFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detailFetchedAt),
    );
  }

  factory CacheArtist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheArtist(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      name: serializer.fromJson<String>(json['name']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      detailFetchedAt: serializer.fromJson<DateTime?>(json['detailFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'name': serializer.toJson<String>(name),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'detailFetchedAt': serializer.toJson<DateTime?>(detailFetchedAt),
    };
  }

  CacheArtist copyWith({
    String? id,
    String? json,
    String? name,
    DateTime? fetchedAt,
    Value<DateTime?> detailFetchedAt = const Value.absent(),
  }) => CacheArtist(
    id: id ?? this.id,
    json: json ?? this.json,
    name: name ?? this.name,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    detailFetchedAt: detailFetchedAt.present
        ? detailFetchedAt.value
        : this.detailFetchedAt,
  );
  CacheArtist copyWithCompanion(ArtistsCompanion data) {
    return CacheArtist(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      name: data.name.present ? data.name.value : this.name,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      detailFetchedAt: data.detailFetchedAt.present
          ? data.detailFetchedAt.value
          : this.detailFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheArtist(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('name: $name, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailFetchedAt: $detailFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, name, fetchedAt, detailFetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheArtist &&
          other.id == this.id &&
          other.json == this.json &&
          other.name == this.name &&
          other.fetchedAt == this.fetchedAt &&
          other.detailFetchedAt == this.detailFetchedAt);
}

class ArtistsCompanion extends UpdateCompanion<CacheArtist> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> name;
  final Value<DateTime> fetchedAt;
  final Value<DateTime?> detailFetchedAt;
  final Value<int> rowid;
  const ArtistsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.name = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.detailFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArtistsCompanion.insert({
    required String id,
    required String json,
    required String name,
    required DateTime fetchedAt,
    this.detailFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       name = Value(name),
       fetchedAt = Value(fetchedAt);
  static Insertable<CacheArtist> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? name,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? detailFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (name != null) 'name': name,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (detailFetchedAt != null) 'detail_fetched_at': detailFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArtistsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? name,
    Value<DateTime>? fetchedAt,
    Value<DateTime?>? detailFetchedAt,
    Value<int>? rowid,
  }) {
    return ArtistsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      name: name ?? this.name,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      detailFetchedAt: detailFetchedAt ?? this.detailFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (detailFetchedAt.present) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtistsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('name: $name, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailFetchedAt: $detailFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, CachePlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailFetchedAtMeta = const VerificationMeta(
    'detailFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detailFetchedAt =
      GeneratedColumn<DateTime>(
        'detail_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    name,
    fetchedAt,
    detailFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachePlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('detail_fetched_at')) {
      context.handle(
        _detailFetchedAtMeta,
        detailFetchedAt.isAcceptableOrUnknown(
          data['detail_fetched_at']!,
          _detailFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachePlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachePlaylist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      detailFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}detail_fetched_at'],
      ),
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class CachePlaylist extends DataClass implements Insertable<CachePlaylist> {
  /// The playlist's id.
  final String id;

  /// The domain playlist, JSON-encoded.
  final String json;

  /// The name, for local search and sorting.
  final String name;

  /// When the row was fetched, in UTC.
  final DateTime fetchedAt;

  /// When the playlist's detail was last fetched, in UTC.
  final DateTime? detailFetchedAt;
  const CachePlaylist({
    required this.id,
    required this.json,
    required this.name,
    required this.fetchedAt,
    this.detailFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['name'] = Variable<String>(name);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || detailFetchedAt != null) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt);
    }
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      json: Value(json),
      name: Value(name),
      fetchedAt: Value(fetchedAt),
      detailFetchedAt: detailFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detailFetchedAt),
    );
  }

  factory CachePlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachePlaylist(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      name: serializer.fromJson<String>(json['name']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      detailFetchedAt: serializer.fromJson<DateTime?>(json['detailFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'name': serializer.toJson<String>(name),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'detailFetchedAt': serializer.toJson<DateTime?>(detailFetchedAt),
    };
  }

  CachePlaylist copyWith({
    String? id,
    String? json,
    String? name,
    DateTime? fetchedAt,
    Value<DateTime?> detailFetchedAt = const Value.absent(),
  }) => CachePlaylist(
    id: id ?? this.id,
    json: json ?? this.json,
    name: name ?? this.name,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    detailFetchedAt: detailFetchedAt.present
        ? detailFetchedAt.value
        : this.detailFetchedAt,
  );
  CachePlaylist copyWithCompanion(PlaylistsCompanion data) {
    return CachePlaylist(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      name: data.name.present ? data.name.value : this.name,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      detailFetchedAt: data.detailFetchedAt.present
          ? data.detailFetchedAt.value
          : this.detailFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachePlaylist(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('name: $name, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailFetchedAt: $detailFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, name, fetchedAt, detailFetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachePlaylist &&
          other.id == this.id &&
          other.json == this.json &&
          other.name == this.name &&
          other.fetchedAt == this.fetchedAt &&
          other.detailFetchedAt == this.detailFetchedAt);
}

class PlaylistsCompanion extends UpdateCompanion<CachePlaylist> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> name;
  final Value<DateTime> fetchedAt;
  final Value<DateTime?> detailFetchedAt;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.name = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.detailFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String json,
    required String name,
    required DateTime fetchedAt,
    this.detailFetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       name = Value(name),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachePlaylist> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? name,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? detailFetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (name != null) 'name': name,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (detailFetchedAt != null) 'detail_fetched_at': detailFetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? name,
    Value<DateTime>? fetchedAt,
    Value<DateTime?>? detailFetchedAt,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      name: name ?? this.name,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      detailFetchedAt: detailFetchedAt ?? this.detailFetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (detailFetchedAt.present) {
      map['detail_fetched_at'] = Variable<DateTime>(detailFetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('name: $name, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailFetchedAt: $detailFetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PodcastsTable extends Podcasts
    with TableInfo<$PodcastsTable, CachePodcast> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PodcastsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'podcasts';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachePodcast> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachePodcast map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachePodcast(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $PodcastsTable createAlias(String alias) {
    return $PodcastsTable(attachedDatabase, alias);
  }
}

class CachePodcast extends DataClass implements Insertable<CachePodcast> {
  /// The podcast's id.
  final String id;

  /// The domain podcast, JSON-encoded.
  final String json;

  /// When the row was fetched, in UTC.
  final DateTime fetchedAt;
  const CachePodcast({
    required this.id,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  PodcastsCompanion toCompanion(bool nullToAbsent) {
    return PodcastsCompanion(
      id: Value(id),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachePodcast.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachePodcast(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachePodcast copyWith({String? id, String? json, DateTime? fetchedAt}) =>
      CachePodcast(
        id: id ?? this.id,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  CachePodcast copyWithCompanion(PodcastsCompanion data) {
    return CachePodcast(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachePodcast(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachePodcast &&
          other.id == this.id &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class PodcastsCompanion extends UpdateCompanion<CachePodcast> {
  final Value<String> id;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const PodcastsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PodcastsCompanion.insert({
    required String id,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachePodcast> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PodcastsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return PodcastsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PodcastsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes
    with TableInfo<$EpisodesTable, CacheEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _podcastIdMeta = const VerificationMeta(
    'podcastId',
  );
  @override
  late final GeneratedColumn<String> podcastId = GeneratedColumn<String>(
    'podcast_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, podcastId, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEpisode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('podcast_id')) {
      context.handle(
        _podcastIdMeta,
        podcastId.isAcceptableOrUnknown(data['podcast_id']!, _podcastIdMeta),
      );
    } else if (isInserting) {
      context.missing(_podcastIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CacheEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEpisode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      podcastId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}podcast_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class CacheEpisode extends DataClass implements Insertable<CacheEpisode> {
  /// The episode's id.
  final String id;

  /// The id of the podcast the episode belongs to.
  final String podcastId;

  /// The domain episode, JSON-encoded.
  final String json;

  /// When the row was fetched, in UTC.
  final DateTime fetchedAt;
  const CacheEpisode({
    required this.id,
    required this.podcastId,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['podcast_id'] = Variable<String>(podcastId);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      podcastId: Value(podcastId),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CacheEpisode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEpisode(
      id: serializer.fromJson<String>(json['id']),
      podcastId: serializer.fromJson<String>(json['podcastId']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'podcastId': serializer.toJson<String>(podcastId),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CacheEpisode copyWith({
    String? id,
    String? podcastId,
    String? json,
    DateTime? fetchedAt,
  }) => CacheEpisode(
    id: id ?? this.id,
    podcastId: podcastId ?? this.podcastId,
    json: json ?? this.json,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CacheEpisode copyWithCompanion(EpisodesCompanion data) {
    return CacheEpisode(
      id: data.id.present ? data.id.value : this.id,
      podcastId: data.podcastId.present ? data.podcastId.value : this.podcastId,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEpisode(')
          ..write('id: $id, ')
          ..write('podcastId: $podcastId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, podcastId, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEpisode &&
          other.id == this.id &&
          other.podcastId == this.podcastId &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class EpisodesCompanion extends UpdateCompanion<CacheEpisode> {
  final Value<String> id;
  final Value<String> podcastId;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.podcastId = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String id,
    required String podcastId,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       podcastId = Value(podcastId),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<CacheEpisode> custom({
    Expression<String>? id,
    Expression<String>? podcastId,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (podcastId != null) 'podcast_id': podcastId,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? id,
    Value<String>? podcastId,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (podcastId.present) {
      map['podcast_id'] = Variable<String>(podcastId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('podcastId: $podcastId, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListsTable extends Lists with TableInfo<$ListsTable, CacheList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listKeyMeta = const VerificationMeta(
    'listKey',
  );
  @override
  late final GeneratedColumn<String> listKey = GeneratedColumn<String>(
    'list_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReadAt = GeneratedColumn<DateTime>(
    'last_read_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    listKey,
    total,
    fetchedAt,
    complete,
    lastReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_key')) {
      context.handle(
        _listKeyMeta,
        listKey.isAcceptableOrUnknown(data['list_key']!, _listKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_listKeyMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastReadAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listKey};
  @override
  CacheList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheList(
      listKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_key'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_read_at'],
      )!,
    );
  }

  @override
  $ListsTable createAlias(String alias) {
    return $ListsTable(attachedDatabase, alias);
  }
}

class CacheList extends DataClass implements Insertable<CacheList> {
  /// The endpoint and parameters, for example `playlist:<id>`.
  final String listKey;

  /// The server's total, when it reported one.
  final int? total;

  /// When the list was last fetched, in UTC.
  final DateTime fetchedAt;

  /// Whether every entry of the list is cached.
  final bool complete;

  /// When the list was last read, in UTC; pruning removes lists not read
  /// for 30 days.
  final DateTime lastReadAt;
  const CacheList({
    required this.listKey,
    this.total,
    required this.fetchedAt,
    required this.complete,
    required this.lastReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_key'] = Variable<String>(listKey);
    if (!nullToAbsent || total != null) {
      map['total'] = Variable<int>(total);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['complete'] = Variable<bool>(complete);
    map['last_read_at'] = Variable<DateTime>(lastReadAt);
    return map;
  }

  ListsCompanion toCompanion(bool nullToAbsent) {
    return ListsCompanion(
      listKey: Value(listKey),
      total: total == null && nullToAbsent
          ? const Value.absent()
          : Value(total),
      fetchedAt: Value(fetchedAt),
      complete: Value(complete),
      lastReadAt: Value(lastReadAt),
    );
  }

  factory CacheList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheList(
      listKey: serializer.fromJson<String>(json['listKey']),
      total: serializer.fromJson<int?>(json['total']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      complete: serializer.fromJson<bool>(json['complete']),
      lastReadAt: serializer.fromJson<DateTime>(json['lastReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listKey': serializer.toJson<String>(listKey),
      'total': serializer.toJson<int?>(total),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'complete': serializer.toJson<bool>(complete),
      'lastReadAt': serializer.toJson<DateTime>(lastReadAt),
    };
  }

  CacheList copyWith({
    String? listKey,
    Value<int?> total = const Value.absent(),
    DateTime? fetchedAt,
    bool? complete,
    DateTime? lastReadAt,
  }) => CacheList(
    listKey: listKey ?? this.listKey,
    total: total.present ? total.value : this.total,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    complete: complete ?? this.complete,
    lastReadAt: lastReadAt ?? this.lastReadAt,
  );
  CacheList copyWithCompanion(ListsCompanion data) {
    return CacheList(
      listKey: data.listKey.present ? data.listKey.value : this.listKey,
      total: data.total.present ? data.total.value : this.total,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      complete: data.complete.present ? data.complete.value : this.complete,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheList(')
          ..write('listKey: $listKey, ')
          ..write('total: $total, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('complete: $complete, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(listKey, total, fetchedAt, complete, lastReadAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheList &&
          other.listKey == this.listKey &&
          other.total == this.total &&
          other.fetchedAt == this.fetchedAt &&
          other.complete == this.complete &&
          other.lastReadAt == this.lastReadAt);
}

class ListsCompanion extends UpdateCompanion<CacheList> {
  final Value<String> listKey;
  final Value<int?> total;
  final Value<DateTime> fetchedAt;
  final Value<bool> complete;
  final Value<DateTime> lastReadAt;
  final Value<int> rowid;
  const ListsCompanion({
    this.listKey = const Value.absent(),
    this.total = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.complete = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListsCompanion.insert({
    required String listKey,
    this.total = const Value.absent(),
    required DateTime fetchedAt,
    this.complete = const Value.absent(),
    required DateTime lastReadAt,
    this.rowid = const Value.absent(),
  }) : listKey = Value(listKey),
       fetchedAt = Value(fetchedAt),
       lastReadAt = Value(lastReadAt);
  static Insertable<CacheList> custom({
    Expression<String>? listKey,
    Expression<int>? total,
    Expression<DateTime>? fetchedAt,
    Expression<bool>? complete,
    Expression<DateTime>? lastReadAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listKey != null) 'list_key': listKey,
      if (total != null) 'total': total,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (complete != null) 'complete': complete,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListsCompanion copyWith({
    Value<String>? listKey,
    Value<int?>? total,
    Value<DateTime>? fetchedAt,
    Value<bool>? complete,
    Value<DateTime>? lastReadAt,
    Value<int>? rowid,
  }) {
    return ListsCompanion(
      listKey: listKey ?? this.listKey,
      total: total ?? this.total,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      complete: complete ?? this.complete,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listKey.present) {
      map['list_key'] = Variable<String>(listKey.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<DateTime>(lastReadAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListsCompanion(')
          ..write('listKey: $listKey, ')
          ..write('total: $total, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('complete: $complete, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListEntriesTable extends ListEntries
    with TableInfo<$ListEntriesTable, CacheListEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listKeyMeta = const VerificationMeta(
    'listKey',
  );
  @override
  late final GeneratedColumn<String> listKey = GeneratedColumn<String>(
    'list_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lists (list_key) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<CacheEntityKind, String>
  entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<CacheEntityKind>($ListEntriesTable.$converterentityKind);
  static const VerificationMeta _entityKeyMeta = const VerificationMeta(
    'entityKey',
  );
  @override
  late final GeneratedColumn<String> entityKey = GeneratedColumn<String>(
    'entity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    listKey,
    position,
    entityKind,
    entityKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'list_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheListEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('list_key')) {
      context.handle(
        _listKeyMeta,
        listKey.isAcceptableOrUnknown(data['list_key']!, _listKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_listKeyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('entity_key')) {
      context.handle(
        _entityKeyMeta,
        entityKey.isAcceptableOrUnknown(data['entity_key']!, _entityKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listKey, position};
  @override
  CacheListEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheListEntry(
      listKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_key'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      entityKind: $ListEntriesTable.$converterentityKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}entity_kind'],
        )!,
      ),
      entityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_key'],
      )!,
    );
  }

  @override
  $ListEntriesTable createAlias(String alias) {
    return $ListEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CacheEntityKind, String, String>
  $converterentityKind = const EnumNameConverter<CacheEntityKind>(
    CacheEntityKind.values,
  );
}

class CacheListEntry extends DataClass implements Insertable<CacheListEntry> {
  /// The list the entry belongs to.
  final String listKey;

  /// The entry's position in the list.
  final int position;

  /// The kind of entity the entry points at.
  final CacheEntityKind entityKind;

  /// The entity's key: `tracks.key` or the other tables' `id`.
  final String entityKey;
  const CacheListEntry({
    required this.listKey,
    required this.position,
    required this.entityKind,
    required this.entityKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['list_key'] = Variable<String>(listKey);
    map['position'] = Variable<int>(position);
    {
      map['entity_kind'] = Variable<String>(
        $ListEntriesTable.$converterentityKind.toSql(entityKind),
      );
    }
    map['entity_key'] = Variable<String>(entityKey);
    return map;
  }

  ListEntriesCompanion toCompanion(bool nullToAbsent) {
    return ListEntriesCompanion(
      listKey: Value(listKey),
      position: Value(position),
      entityKind: Value(entityKind),
      entityKey: Value(entityKey),
    );
  }

  factory CacheListEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheListEntry(
      listKey: serializer.fromJson<String>(json['listKey']),
      position: serializer.fromJson<int>(json['position']),
      entityKind: $ListEntriesTable.$converterentityKind.fromJson(
        serializer.fromJson<String>(json['entityKind']),
      ),
      entityKey: serializer.fromJson<String>(json['entityKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listKey': serializer.toJson<String>(listKey),
      'position': serializer.toJson<int>(position),
      'entityKind': serializer.toJson<String>(
        $ListEntriesTable.$converterentityKind.toJson(entityKind),
      ),
      'entityKey': serializer.toJson<String>(entityKey),
    };
  }

  CacheListEntry copyWith({
    String? listKey,
    int? position,
    CacheEntityKind? entityKind,
    String? entityKey,
  }) => CacheListEntry(
    listKey: listKey ?? this.listKey,
    position: position ?? this.position,
    entityKind: entityKind ?? this.entityKind,
    entityKey: entityKey ?? this.entityKey,
  );
  CacheListEntry copyWithCompanion(ListEntriesCompanion data) {
    return CacheListEntry(
      listKey: data.listKey.present ? data.listKey.value : this.listKey,
      position: data.position.present ? data.position.value : this.position,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      entityKey: data.entityKey.present ? data.entityKey.value : this.entityKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheListEntry(')
          ..write('listKey: $listKey, ')
          ..write('position: $position, ')
          ..write('entityKind: $entityKind, ')
          ..write('entityKey: $entityKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listKey, position, entityKind, entityKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheListEntry &&
          other.listKey == this.listKey &&
          other.position == this.position &&
          other.entityKind == this.entityKind &&
          other.entityKey == this.entityKey);
}

class ListEntriesCompanion extends UpdateCompanion<CacheListEntry> {
  final Value<String> listKey;
  final Value<int> position;
  final Value<CacheEntityKind> entityKind;
  final Value<String> entityKey;
  final Value<int> rowid;
  const ListEntriesCompanion({
    this.listKey = const Value.absent(),
    this.position = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.entityKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListEntriesCompanion.insert({
    required String listKey,
    required int position,
    required CacheEntityKind entityKind,
    required String entityKey,
    this.rowid = const Value.absent(),
  }) : listKey = Value(listKey),
       position = Value(position),
       entityKind = Value(entityKind),
       entityKey = Value(entityKey);
  static Insertable<CacheListEntry> custom({
    Expression<String>? listKey,
    Expression<int>? position,
    Expression<String>? entityKind,
    Expression<String>? entityKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listKey != null) 'list_key': listKey,
      if (position != null) 'position': position,
      if (entityKind != null) 'entity_kind': entityKind,
      if (entityKey != null) 'entity_key': entityKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListEntriesCompanion copyWith({
    Value<String>? listKey,
    Value<int>? position,
    Value<CacheEntityKind>? entityKind,
    Value<String>? entityKey,
    Value<int>? rowid,
  }) {
    return ListEntriesCompanion(
      listKey: listKey ?? this.listKey,
      position: position ?? this.position,
      entityKind: entityKind ?? this.entityKind,
      entityKey: entityKey ?? this.entityKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listKey.present) {
      map['list_key'] = Variable<String>(listKey.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(
        $ListEntriesTable.$converterentityKind.toSql(entityKind.value),
      );
    }
    if (entityKey.present) {
      map['entity_key'] = Variable<String>(entityKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListEntriesCompanion(')
          ..write('listKey: $listKey, ')
          ..write('position: $position, ')
          ..write('entityKind: $entityKind, ')
          ..write('entityKey: $entityKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlobsTable extends Blobs with TableInfo<$BlobsTable, CacheBlob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, json, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheBlob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheBlob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheBlob(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $BlobsTable createAlias(String alias) {
    return $BlobsTable(attachedDatabase, alias);
  }
}

class CacheBlob extends DataClass implements Insertable<CacheBlob> {
  /// The payload's key.
  final String key;

  /// The payload, JSON-encoded.
  final String json;

  /// When the payload was fetched, in UTC.
  final DateTime fetchedAt;
  const CacheBlob({
    required this.key,
    required this.json,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['json'] = Variable<String>(json);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  BlobsCompanion toCompanion(bool nullToAbsent) {
    return BlobsCompanion(
      key: Value(key),
      json: Value(json),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CacheBlob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheBlob(
      key: serializer.fromJson<String>(json['key']),
      json: serializer.fromJson<String>(json['json']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'json': serializer.toJson<String>(json),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CacheBlob copyWith({String? key, String? json, DateTime? fetchedAt}) =>
      CacheBlob(
        key: key ?? this.key,
        json: json ?? this.json,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  CacheBlob copyWithCompanion(BlobsCompanion data) {
    return CacheBlob(
      key: data.key.present ? data.key.value : this.key,
      json: data.json.present ? data.json.value : this.json,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheBlob(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, json, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheBlob &&
          other.key == this.key &&
          other.json == this.json &&
          other.fetchedAt == this.fetchedAt);
}

class BlobsCompanion extends UpdateCompanion<CacheBlob> {
  final Value<String> key;
  final Value<String> json;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const BlobsCompanion({
    this.key = const Value.absent(),
    this.json = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlobsCompanion.insert({
    required String key,
    required String json,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       json = Value(json),
       fetchedAt = Value(fetchedAt);
  static Insertable<CacheBlob> custom({
    Expression<String>? key,
    Expression<String>? json,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (json != null) 'json': json,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlobsCompanion copyWith({
    Value<String>? key,
    Value<String>? json,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return BlobsCompanion(
      key: key ?? this.key,
      json: json ?? this.json,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlobsCompanion(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CacheDatabase extends GeneratedDatabase {
  _$CacheDatabase(QueryExecutor e) : super(e);
  $CacheDatabaseManager get managers => $CacheDatabaseManager(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $ArtistsTable artists = $ArtistsTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PodcastsTable podcasts = $PodcastsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $ListsTable lists = $ListsTable(this);
  late final $ListEntriesTable listEntries = $ListEntriesTable(this);
  late final $BlobsTable blobs = $BlobsTable(this);
  late final Index tracksTitle = Index(
    'tracks_title',
    'CREATE INDEX tracks_title ON tracks (title)',
  );
  late final Index tracksAlbumId = Index(
    'tracks_album_id',
    'CREATE INDEX tracks_album_id ON tracks (album_id)',
  );
  late final Index albumsTitle = Index(
    'albums_title',
    'CREATE INDEX albums_title ON albums (title)',
  );
  late final Index artistsName = Index(
    'artists_name',
    'CREATE INDEX artists_name ON artists (name)',
  );
  late final Index playlistsName = Index(
    'playlists_name',
    'CREATE INDEX playlists_name ON playlists (name)',
  );
  late final Index listEntriesEntity = Index(
    'list_entries_entity',
    'CREATE INDEX list_entries_entity ON list_entries (entity_kind, entity_key)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tracks,
    albums,
    artists,
    playlists,
    podcasts,
    episodes,
    lists,
    listEntries,
    blobs,
    tracksTitle,
    tracksAlbumId,
    albumsTitle,
    artistsName,
    playlistsName,
    listEntriesEntity,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('list_entries', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  required String key,
  Value<String?> playbackId,
  required String json,
  Value<String?> albumId,
  Value<String?> artistId,
  required String title,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> key,
  Value<String?> playbackId,
  Value<String> json,
  Value<String?> albumId,
  Value<String?> artistId,
  Value<String> title,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$TracksTableFilterComposer
    extends Composer<_$CacheDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playbackId => $composableBuilder(
    column: $table.playbackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TracksTableOrderingComposer
    extends Composer<_$CacheDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playbackId => $composableBuilder(
    column: $table.playbackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistId => $composableBuilder(
    column: $table.artistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TracksTableAnnotationComposer
    extends Composer<_$CacheDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get playbackId => $composableBuilder(
    column: $table.playbackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get artistId =>
      $composableBuilder(column: $table.artistId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $TracksTable,
          CacheTrack,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (
            CacheTrack,
            BaseReferences<_$CacheDatabase, $TracksTable, CacheTrack>,
          ),
          CacheTrack,
          PrefetchHooks Function()
        > {
  $$TracksTableTableManager(_$CacheDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> playbackId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                key: key,
                playbackId: playbackId,
                json: json,
                albumId: albumId,
                artistId: artistId,
                title: title,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> playbackId = const Value.absent(),
                required String json,
                Value<String?> albumId = const Value.absent(),
                Value<String?> artistId = const Value.absent(),
                required String title,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                key: key,
                playbackId: playbackId,
                json: json,
                albumId: albumId,
                artistId: artistId,
                title: title,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TracksTable, CacheTrack>(table),
                  BaseReferences<_$CacheDatabase, $TracksTable, CacheTrack>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $TracksTable,
      CacheTrack,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (CacheTrack, BaseReferences<_$CacheDatabase, $TracksTable, CacheTrack>),
      CacheTrack,
      PrefetchHooks Function()
    >;
typedef $$AlbumsTableCreateCompanionBuilder = AlbumsCompanion Function({
  required String id,
  required String json,
  required String title,
  required String artistName,
  Value<int?> year,
  required DateTime fetchedAt,
  Value<DateTime?> detailFetchedAt,
  Value<int> rowid,
});
typedef $$AlbumsTableUpdateCompanionBuilder = AlbumsCompanion Function({
  Value<String> id,
  Value<String> json,
  Value<String> title,
  Value<String> artistName,
  Value<int?> year,
  Value<DateTime> fetchedAt,
  Value<DateTime?> detailFetchedAt,
  Value<int> rowid,
});

class $$AlbumsTableFilterComposer
    extends Composer<_$CacheDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$CacheDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => column,
  );
}

class $$AlbumsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $AlbumsTable,
          CacheAlbum,
          $$AlbumsTableFilterComposer,
          $$AlbumsTableOrderingComposer,
          $$AlbumsTableAnnotationComposer,
          $$AlbumsTableCreateCompanionBuilder,
          $$AlbumsTableUpdateCompanionBuilder,
          (
            CacheAlbum,
            BaseReferences<_$CacheDatabase, $AlbumsTable, CacheAlbum>,
          ),
          CacheAlbum,
          PrefetchHooks Function()
        > {
  $$AlbumsTableTableManager(_$CacheDatabase db, $AlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsCompanion(
                id: id,
                json: json,
                title: title,
                artistName: artistName,
                year: year,
                fetchedAt: fetchedAt,
                detailFetchedAt: detailFetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String title,
                required String artistName,
                Value<int?> year = const Value.absent(),
                required DateTime fetchedAt,
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumsCompanion.insert(
                id: id,
                json: json,
                title: title,
                artistName: artistName,
                year: year,
                fetchedAt: fetchedAt,
                detailFetchedAt: detailFetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AlbumsTable, CacheAlbum>(table),
                  BaseReferences<_$CacheDatabase, $AlbumsTable, CacheAlbum>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $AlbumsTable,
      CacheAlbum,
      $$AlbumsTableFilterComposer,
      $$AlbumsTableOrderingComposer,
      $$AlbumsTableAnnotationComposer,
      $$AlbumsTableCreateCompanionBuilder,
      $$AlbumsTableUpdateCompanionBuilder,
      (CacheAlbum, BaseReferences<_$CacheDatabase, $AlbumsTable, CacheAlbum>),
      CacheAlbum,
      PrefetchHooks Function()
    >;
typedef $$ArtistsTableCreateCompanionBuilder = ArtistsCompanion Function({
  required String id,
  required String json,
  required String name,
  required DateTime fetchedAt,
  Value<DateTime?> detailFetchedAt,
  Value<int> rowid,
});
typedef $$ArtistsTableUpdateCompanionBuilder = ArtistsCompanion Function({
  Value<String> id,
  Value<String> json,
  Value<String> name,
  Value<DateTime> fetchedAt,
  Value<DateTime?> detailFetchedAt,
  Value<int> rowid,
});

class $$ArtistsTableFilterComposer
    extends Composer<_$CacheDatabase, $ArtistsTable> {
  $$ArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArtistsTableOrderingComposer
    extends Composer<_$CacheDatabase, $ArtistsTable> {
  $$ArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtistsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $ArtistsTable> {
  $$ArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => column,
  );
}

class $$ArtistsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $ArtistsTable,
          CacheArtist,
          $$ArtistsTableFilterComposer,
          $$ArtistsTableOrderingComposer,
          $$ArtistsTableAnnotationComposer,
          $$ArtistsTableCreateCompanionBuilder,
          $$ArtistsTableUpdateCompanionBuilder,
          (
            CacheArtist,
            BaseReferences<_$CacheDatabase, $ArtistsTable, CacheArtist>,
          ),
          CacheArtist,
          PrefetchHooks Function()
        > {
  $$ArtistsTableTableManager(_$CacheDatabase db, $ArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistsCompanion(
                id: id,
                json: json,
                name: name,
                fetchedAt: fetchedAt,
                detailFetchedAt: detailFetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String name,
                required DateTime fetchedAt,
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArtistsCompanion.insert(
                id: id,
                json: json,
                name: name,
                fetchedAt: fetchedAt,
                detailFetchedAt: detailFetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ArtistsTable, CacheArtist>(table),
                  BaseReferences<_$CacheDatabase, $ArtistsTable, CacheArtist>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $ArtistsTable,
      CacheArtist,
      $$ArtistsTableFilterComposer,
      $$ArtistsTableOrderingComposer,
      $$ArtistsTableAnnotationComposer,
      $$ArtistsTableCreateCompanionBuilder,
      $$ArtistsTableUpdateCompanionBuilder,
      (
        CacheArtist,
        BaseReferences<_$CacheDatabase, $ArtistsTable, CacheArtist>,
      ),
      CacheArtist,
      PrefetchHooks Function()
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String json,
  required String name,
  required DateTime fetchedAt,
  Value<DateTime?> detailFetchedAt,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> json,
  Value<String> name,
  Value<DateTime> fetchedAt,
  Value<DateTime?> detailFetchedAt,
  Value<int> rowid,
});

class $$PlaylistsTableFilterComposer
    extends Composer<_$CacheDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$CacheDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get detailFetchedAt => $composableBuilder(
    column: $table.detailFetchedAt,
    builder: (column) => column,
  );
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $PlaylistsTable,
          CachePlaylist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (
            CachePlaylist,
            BaseReferences<_$CacheDatabase, $PlaylistsTable, CachePlaylist>,
          ),
          CachePlaylist,
          PrefetchHooks Function()
        > {
  $$PlaylistsTableTableManager(_$CacheDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                json: json,
                name: name,
                fetchedAt: fetchedAt,
                detailFetchedAt: detailFetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String name,
                required DateTime fetchedAt,
                Value<DateTime?> detailFetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                json: json,
                name: name,
                fetchedAt: fetchedAt,
                detailFetchedAt: detailFetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaylistsTable, CachePlaylist>(table),
                  BaseReferences<
                    _$CacheDatabase,
                    $PlaylistsTable,
                    CachePlaylist
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $PlaylistsTable,
      CachePlaylist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (
        CachePlaylist,
        BaseReferences<_$CacheDatabase, $PlaylistsTable, CachePlaylist>,
      ),
      CachePlaylist,
      PrefetchHooks Function()
    >;
typedef $$PodcastsTableCreateCompanionBuilder = PodcastsCompanion Function({
  required String id,
  required String json,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$PodcastsTableUpdateCompanionBuilder = PodcastsCompanion Function({
  Value<String> id,
  Value<String> json,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$PodcastsTableFilterComposer
    extends Composer<_$CacheDatabase, $PodcastsTable> {
  $$PodcastsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PodcastsTableOrderingComposer
    extends Composer<_$CacheDatabase, $PodcastsTable> {
  $$PodcastsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PodcastsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $PodcastsTable> {
  $$PodcastsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$PodcastsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $PodcastsTable,
          CachePodcast,
          $$PodcastsTableFilterComposer,
          $$PodcastsTableOrderingComposer,
          $$PodcastsTableAnnotationComposer,
          $$PodcastsTableCreateCompanionBuilder,
          $$PodcastsTableUpdateCompanionBuilder,
          (
            CachePodcast,
            BaseReferences<_$CacheDatabase, $PodcastsTable, CachePodcast>,
          ),
          CachePodcast,
          PrefetchHooks Function()
        > {
  $$PodcastsTableTableManager(_$CacheDatabase db, $PodcastsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PodcastsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PodcastsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PodcastsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PodcastsCompanion(
                id: id,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => PodcastsCompanion.insert(
                id: id,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PodcastsTable, CachePodcast>(table),
                  BaseReferences<_$CacheDatabase, $PodcastsTable, CachePodcast>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PodcastsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $PodcastsTable,
      CachePodcast,
      $$PodcastsTableFilterComposer,
      $$PodcastsTableOrderingComposer,
      $$PodcastsTableAnnotationComposer,
      $$PodcastsTableCreateCompanionBuilder,
      $$PodcastsTableUpdateCompanionBuilder,
      (
        CachePodcast,
        BaseReferences<_$CacheDatabase, $PodcastsTable, CachePodcast>,
      ),
      CachePodcast,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  required String id,
  required String podcastId,
  required String json,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<String> id,
  Value<String> podcastId,
  Value<String> json,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$EpisodesTableFilterComposer
    extends Composer<_$CacheDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get podcastId => $composableBuilder(
    column: $table.podcastId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$CacheDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get podcastId => $composableBuilder(
    column: $table.podcastId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$CacheDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get podcastId =>
      $composableBuilder(column: $table.podcastId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $EpisodesTable,
          CacheEpisode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (
            CacheEpisode,
            BaseReferences<_$CacheDatabase, $EpisodesTable, CacheEpisode>,
          ),
          CacheEpisode,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableManager(_$CacheDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> podcastId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                podcastId: podcastId,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String podcastId,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                podcastId: podcastId,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpisodesTable, CacheEpisode>(table),
                  BaseReferences<_$CacheDatabase, $EpisodesTable, CacheEpisode>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $EpisodesTable,
      CacheEpisode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (
        CacheEpisode,
        BaseReferences<_$CacheDatabase, $EpisodesTable, CacheEpisode>,
      ),
      CacheEpisode,
      PrefetchHooks Function()
    >;
typedef $$ListsTableCreateCompanionBuilder = ListsCompanion Function({
  required String listKey,
  Value<int?> total,
  required DateTime fetchedAt,
  Value<bool> complete,
  required DateTime lastReadAt,
  Value<int> rowid,
});
typedef $$ListsTableUpdateCompanionBuilder = ListsCompanion Function({
  Value<String> listKey,
  Value<int?> total,
  Value<DateTime> fetchedAt,
  Value<bool> complete,
  Value<DateTime> lastReadAt,
  Value<int> rowid,
});

final class $$ListsTableReferences
    extends BaseReferences<_$CacheDatabase, $ListsTable, CacheList> {
  $$ListsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ListEntriesTable, List<CacheListEntry>>
  _listEntriesRefsTable(_$CacheDatabase db) => MultiTypedResultKey.fromTable(
    db.listEntries,
    aliasName: 'lists__list_key__list_entries__list_key',
  );

  $$ListEntriesTableProcessedTableManager get listEntriesRefs {
    final manager = $$ListEntriesTableTableManager($_db, $_db.listEntries)
        .filter(
          (f) => f.listKey.listKey.sqlEquals($_itemColumn<String>('list_key')!),
        );

    final cache = $_typedResult.readTableOrNull(_listEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ListsTableFilterComposer
    extends Composer<_$CacheDatabase, $ListsTable> {
  $$ListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> listEntriesRefs(
    Expression<bool> Function($$ListEntriesTableFilterComposer f) f,
  ) {
    final $$ListEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listKey,
      referencedTable: $db.listEntries,
      getReferencedColumn: (t) => t.listKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListEntriesTableFilterComposer(
            $db: $db,
            $table: $db.listEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListsTableOrderingComposer
    extends Composer<_$CacheDatabase, $ListsTable> {
  $$ListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get listKey => $composableBuilder(
    column: $table.listKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $ListsTable> {
  $$ListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get listKey =>
      $composableBuilder(column: $table.listKey, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReadAt => $composableBuilder(
    column: $table.lastReadAt,
    builder: (column) => column,
  );

  Expression<T> listEntriesRefs<T extends Object>(
    Expression<T> Function($$ListEntriesTableAnnotationComposer a) f,
  ) {
    final $$ListEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listKey,
      referencedTable: $db.listEntries,
      getReferencedColumn: (t) => t.listKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.listEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ListsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $ListsTable,
          CacheList,
          $$ListsTableFilterComposer,
          $$ListsTableOrderingComposer,
          $$ListsTableAnnotationComposer,
          $$ListsTableCreateCompanionBuilder,
          $$ListsTableUpdateCompanionBuilder,
          (CacheList, $$ListsTableReferences),
          CacheList,
          PrefetchHooks Function({bool listEntriesRefs})
        > {
  $$ListsTableTableManager(_$CacheDatabase db, $ListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listKey = const Value.absent(),
                Value<int?> total = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<DateTime> lastReadAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion(
                listKey: listKey,
                total: total,
                fetchedAt: fetchedAt,
                complete: complete,
                lastReadAt: lastReadAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listKey,
                Value<int?> total = const Value.absent(),
                required DateTime fetchedAt,
                Value<bool> complete = const Value.absent(),
                required DateTime lastReadAt,
                Value<int> rowid = const Value.absent(),
              }) => ListsCompanion.insert(
                listKey: listKey,
                total: total,
                fetchedAt: fetchedAt,
                complete: complete,
                lastReadAt: lastReadAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListsTable, CacheList>(table),
                  $$ListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (listEntriesRefs) db.listEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (listEntriesRefs)
                    await $_getPrefetchedDataByColumns<
                      CacheList,
                      $ListsTable,
                      CacheListEntry,
                      $ListEntriesTable
                    >(
                      currentTable: table,
                      referencedTable: $$ListsTableReferences
                          ._listEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ListsTableReferences(db, table, p0).listEntriesRefs,
                      currentColumn: 'list_key',
                      referencedColumn: 'list_key',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ListsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $ListsTable,
      CacheList,
      $$ListsTableFilterComposer,
      $$ListsTableOrderingComposer,
      $$ListsTableAnnotationComposer,
      $$ListsTableCreateCompanionBuilder,
      $$ListsTableUpdateCompanionBuilder,
      (CacheList, $$ListsTableReferences),
      CacheList,
      PrefetchHooks Function({bool listEntriesRefs})
    >;
typedef $$ListEntriesTableCreateCompanionBuilder =
    ListEntriesCompanion Function({
      required String listKey,
      required int position,
      required CacheEntityKind entityKind,
      required String entityKey,
      Value<int> rowid,
    });
typedef $$ListEntriesTableUpdateCompanionBuilder =
    ListEntriesCompanion Function({
      Value<String> listKey,
      Value<int> position,
      Value<CacheEntityKind> entityKind,
      Value<String> entityKey,
      Value<int> rowid,
    });

final class $$ListEntriesTableReferences
    extends BaseReferences<_$CacheDatabase, $ListEntriesTable, CacheListEntry> {
  $$ListEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ListsTable _listKeyTable(_$CacheDatabase db) =>
      db.lists.createAlias('list_entries__list_key__lists__list_key');

  $$ListsTableProcessedTableManager get listKey {
    final $_column = $_itemColumn<String>('list_key')!;

    final manager = $$ListsTableTableManager(
      $_db,
      $_db.lists,
    ).filter((f) => f.listKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListEntriesTableFilterComposer
    extends Composer<_$CacheDatabase, $ListEntriesTable> {
  $$ListEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CacheEntityKind, CacheEntityKind, String>
  get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnFilters(column),
  );

  $$ListsTableFilterComposer get listKey {
    final $$ListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listKey,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.listKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableFilterComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListEntriesTableOrderingComposer
    extends Composer<_$CacheDatabase, $ListEntriesTable> {
  $$ListEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKind => $composableBuilder(
    column: $table.entityKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnOrderings(column),
  );

  $$ListsTableOrderingComposer get listKey {
    final $$ListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listKey,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.listKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableOrderingComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListEntriesTableAnnotationComposer
    extends Composer<_$CacheDatabase, $ListEntriesTable> {
  $$ListEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CacheEntityKind, String> get entityKind =>
      $composableBuilder(
        column: $table.entityKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get entityKey =>
      $composableBuilder(column: $table.entityKey, builder: (column) => column);

  $$ListsTableAnnotationComposer get listKey {
    final $$ListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listKey,
      referencedTable: $db.lists,
      getReferencedColumn: (t) => t.listKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListsTableAnnotationComposer(
            $db: $db,
            $table: $db.lists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListEntriesTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $ListEntriesTable,
          CacheListEntry,
          $$ListEntriesTableFilterComposer,
          $$ListEntriesTableOrderingComposer,
          $$ListEntriesTableAnnotationComposer,
          $$ListEntriesTableCreateCompanionBuilder,
          $$ListEntriesTableUpdateCompanionBuilder,
          (CacheListEntry, $$ListEntriesTableReferences),
          CacheListEntry,
          PrefetchHooks Function({bool listKey})
        > {
  $$ListEntriesTableTableManager(_$CacheDatabase db, $ListEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listKey = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<CacheEntityKind> entityKind = const Value.absent(),
                Value<String> entityKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListEntriesCompanion(
                listKey: listKey,
                position: position,
                entityKind: entityKind,
                entityKey: entityKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listKey,
                required int position,
                required CacheEntityKind entityKind,
                required String entityKey,
                Value<int> rowid = const Value.absent(),
              }) => ListEntriesCompanion.insert(
                listKey: listKey,
                position: position,
                entityKind: entityKind,
                entityKey: entityKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListEntriesTable, CacheListEntry>(table),
                  $$ListEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.listKey,
                        referencedTable: $$ListEntriesTableReferences
                            ._listKeyTable(db),
                        referencedColumn: $$ListEntriesTableReferences
                            ._listKeyTable(db)
                            .listKey,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ListEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $ListEntriesTable,
      CacheListEntry,
      $$ListEntriesTableFilterComposer,
      $$ListEntriesTableOrderingComposer,
      $$ListEntriesTableAnnotationComposer,
      $$ListEntriesTableCreateCompanionBuilder,
      $$ListEntriesTableUpdateCompanionBuilder,
      (CacheListEntry, $$ListEntriesTableReferences),
      CacheListEntry,
      PrefetchHooks Function({bool listKey})
    >;
typedef $$BlobsTableCreateCompanionBuilder = BlobsCompanion Function({
  required String key,
  required String json,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$BlobsTableUpdateCompanionBuilder = BlobsCompanion Function({
  Value<String> key,
  Value<String> json,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$BlobsTableFilterComposer
    extends Composer<_$CacheDatabase, $BlobsTable> {
  $$BlobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BlobsTableOrderingComposer
    extends Composer<_$CacheDatabase, $BlobsTable> {
  $$BlobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BlobsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $BlobsTable> {
  $$BlobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$BlobsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $BlobsTable,
          CacheBlob,
          $$BlobsTableFilterComposer,
          $$BlobsTableOrderingComposer,
          $$BlobsTableAnnotationComposer,
          $$BlobsTableCreateCompanionBuilder,
          $$BlobsTableUpdateCompanionBuilder,
          (CacheBlob, BaseReferences<_$CacheDatabase, $BlobsTable, CacheBlob>),
          CacheBlob,
          PrefetchHooks Function()
        > {
  $$BlobsTableTableManager(_$CacheDatabase db, $BlobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlobsCompanion(
                key: key,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String json,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => BlobsCompanion.insert(
                key: key,
                json: json,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BlobsTable, CacheBlob>(table),
                  BaseReferences<_$CacheDatabase, $BlobsTable, CacheBlob>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BlobsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $BlobsTable,
      CacheBlob,
      $$BlobsTableFilterComposer,
      $$BlobsTableOrderingComposer,
      $$BlobsTableAnnotationComposer,
      $$BlobsTableCreateCompanionBuilder,
      $$BlobsTableUpdateCompanionBuilder,
      (CacheBlob, BaseReferences<_$CacheDatabase, $BlobsTable, CacheBlob>),
      CacheBlob,
      PrefetchHooks Function()
    >;

class $CacheDatabaseManager {
  final _$CacheDatabase _db;
  $CacheDatabaseManager(this._db);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$ArtistsTableTableManager get artists =>
      $$ArtistsTableTableManager(_db, _db.artists);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db, _db.podcasts);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$ListsTableTableManager get lists =>
      $$ListsTableTableManager(_db, _db.lists);
  $$ListEntriesTableTableManager get listEntries =>
      $$ListEntriesTableTableManager(_db, _db.listEntries);
  $$BlobsTableTableManager get blobs =>
      $$BlobsTableTableManager(_db, _db.blobs);
}
