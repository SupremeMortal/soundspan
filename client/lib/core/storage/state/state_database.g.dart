// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_database.dart';

// ignore_for_file: type=lint
class $DeviceSettingsTable extends DeviceSettings
    with TableInfo<$DeviceSettingsTable, DeviceSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceSetting> instance, {
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
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DeviceSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $DeviceSettingsTable createAlias(String alias) {
    return $DeviceSettingsTable(attachedDatabase, alias);
  }
}

class DeviceSetting extends DataClass implements Insertable<DeviceSetting> {
  /// The setting's key, for example `playback.volume`.
  final String key;

  /// The setting's value, JSON-encoded.
  final String value;
  const DeviceSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  DeviceSettingsCompanion toCompanion(bool nullToAbsent) {
    return DeviceSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory DeviceSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  DeviceSetting copyWith({String? key, String? value}) =>
      DeviceSetting(key: key ?? this.key, value: value ?? this.value);
  DeviceSetting copyWithCompanion(DeviceSettingsCompanion data) {
    return DeviceSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class DeviceSettingsCompanion extends UpdateCompanion<DeviceSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const DeviceSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<DeviceSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return DeviceSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueSnapshotTable extends QueueSnapshot
    with TableInfo<$QueueSnapshotTable, QueueSnapshotData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueSnapshotTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _queueItemIdMeta = const VerificationMeta(
    'queueItemId',
  );
  @override
  late final GeneratedColumn<String> queueItemId = GeneratedColumn<String>(
    'queue_item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemJsonMeta = const VerificationMeta(
    'itemJson',
  );
  @override
  late final GeneratedColumn<String> itemJson = GeneratedColumn<String>(
    'item_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [position, queueItemId, kind, itemJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_snapshot';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueSnapshotData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('queue_item_id')) {
      context.handle(
        _queueItemIdMeta,
        queueItemId.isAcceptableOrUnknown(
          data['queue_item_id']!,
          _queueItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queueItemIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('item_json')) {
      context.handle(
        _itemJsonMeta,
        itemJson.isAcceptableOrUnknown(data['item_json']!, _itemJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_itemJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {position};
  @override
  QueueSnapshotData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueSnapshotData(
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      queueItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queue_item_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      itemJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_json'],
      )!,
    );
  }

  @override
  $QueueSnapshotTable createAlias(String alias) {
    return $QueueSnapshotTable(attachedDatabase, alias);
  }
}

class QueueSnapshotData extends DataClass
    implements Insertable<QueueSnapshotData> {
  /// The item's index in canonical order, from 0.
  final int position;

  /// The queue entry's id, unique within the queue.
  final String queueItemId;

  /// `track` or `episode`.
  final String kind;

  /// The serialized `QueueItem`: everything needed to show and play it,
  /// including its queue context.
  final String itemJson;
  const QueueSnapshotData({
    required this.position,
    required this.queueItemId,
    required this.kind,
    required this.itemJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['position'] = Variable<int>(position);
    map['queue_item_id'] = Variable<String>(queueItemId);
    map['kind'] = Variable<String>(kind);
    map['item_json'] = Variable<String>(itemJson);
    return map;
  }

  QueueSnapshotCompanion toCompanion(bool nullToAbsent) {
    return QueueSnapshotCompanion(
      position: Value(position),
      queueItemId: Value(queueItemId),
      kind: Value(kind),
      itemJson: Value(itemJson),
    );
  }

  factory QueueSnapshotData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueSnapshotData(
      position: serializer.fromJson<int>(json['position']),
      queueItemId: serializer.fromJson<String>(json['queueItemId']),
      kind: serializer.fromJson<String>(json['kind']),
      itemJson: serializer.fromJson<String>(json['itemJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'position': serializer.toJson<int>(position),
      'queueItemId': serializer.toJson<String>(queueItemId),
      'kind': serializer.toJson<String>(kind),
      'itemJson': serializer.toJson<String>(itemJson),
    };
  }

  QueueSnapshotData copyWith({
    int? position,
    String? queueItemId,
    String? kind,
    String? itemJson,
  }) => QueueSnapshotData(
    position: position ?? this.position,
    queueItemId: queueItemId ?? this.queueItemId,
    kind: kind ?? this.kind,
    itemJson: itemJson ?? this.itemJson,
  );
  QueueSnapshotData copyWithCompanion(QueueSnapshotCompanion data) {
    return QueueSnapshotData(
      position: data.position.present ? data.position.value : this.position,
      queueItemId: data.queueItemId.present
          ? data.queueItemId.value
          : this.queueItemId,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemJson: data.itemJson.present ? data.itemJson.value : this.itemJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueSnapshotData(')
          ..write('position: $position, ')
          ..write('queueItemId: $queueItemId, ')
          ..write('kind: $kind, ')
          ..write('itemJson: $itemJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(position, queueItemId, kind, itemJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueSnapshotData &&
          other.position == this.position &&
          other.queueItemId == this.queueItemId &&
          other.kind == this.kind &&
          other.itemJson == this.itemJson);
}

class QueueSnapshotCompanion extends UpdateCompanion<QueueSnapshotData> {
  final Value<int> position;
  final Value<String> queueItemId;
  final Value<String> kind;
  final Value<String> itemJson;
  const QueueSnapshotCompanion({
    this.position = const Value.absent(),
    this.queueItemId = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemJson = const Value.absent(),
  });
  QueueSnapshotCompanion.insert({
    this.position = const Value.absent(),
    required String queueItemId,
    required String kind,
    required String itemJson,
  }) : queueItemId = Value(queueItemId),
       kind = Value(kind),
       itemJson = Value(itemJson);
  static Insertable<QueueSnapshotData> custom({
    Expression<int>? position,
    Expression<String>? queueItemId,
    Expression<String>? kind,
    Expression<String>? itemJson,
  }) {
    return RawValuesInsertable({
      if (position != null) 'position': position,
      if (queueItemId != null) 'queue_item_id': queueItemId,
      if (kind != null) 'kind': kind,
      if (itemJson != null) 'item_json': itemJson,
    });
  }

  QueueSnapshotCompanion copyWith({
    Value<int>? position,
    Value<String>? queueItemId,
    Value<String>? kind,
    Value<String>? itemJson,
  }) {
    return QueueSnapshotCompanion(
      position: position ?? this.position,
      queueItemId: queueItemId ?? this.queueItemId,
      kind: kind ?? this.kind,
      itemJson: itemJson ?? this.itemJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (queueItemId.present) {
      map['queue_item_id'] = Variable<String>(queueItemId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (itemJson.present) {
      map['item_json'] = Variable<String>(itemJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueSnapshotCompanion(')
          ..write('position: $position, ')
          ..write('queueItemId: $queueItemId, ')
          ..write('kind: $kind, ')
          ..write('itemJson: $itemJson')
          ..write(')'))
        .toString();
  }
}

class $QueueMetaTable extends QueueMeta
    with TableInfo<$QueueMetaTable, QueueMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentQueueItemIdMeta =
      const VerificationMeta('currentQueueItemId');
  @override
  late final GeneratedColumn<String> currentQueueItemId =
      GeneratedColumn<String>(
        'current_queue_item_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shuffleOrderJsonMeta = const VerificationMeta(
    'shuffleOrderJson',
  );
  @override
  late final GeneratedColumn<String> shuffleOrderJson = GeneratedColumn<String>(
    'shuffle_order_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatModeMeta = const VerificationMeta(
    'repeatMode',
  );
  @override
  late final GeneratedColumn<String> repeatMode = GeneratedColumn<String>(
    'repeat_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('off'),
  );
  static const VerificationMeta _contextJsonMeta = const VerificationMeta(
    'contextJson',
  );
  @override
  late final GeneratedColumn<String> contextJson = GeneratedColumn<String>(
    'context_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentQueueItemId,
    positionMs,
    shuffleOrderJson,
    repeatMode,
    contextJson,
    revision,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueueMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_queue_item_id')) {
      context.handle(
        _currentQueueItemIdMeta,
        currentQueueItemId.isAcceptableOrUnknown(
          data['current_queue_item_id']!,
          _currentQueueItemIdMeta,
        ),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    }
    if (data.containsKey('shuffle_order_json')) {
      context.handle(
        _shuffleOrderJsonMeta,
        shuffleOrderJson.isAcceptableOrUnknown(
          data['shuffle_order_json']!,
          _shuffleOrderJsonMeta,
        ),
      );
    }
    if (data.containsKey('repeat_mode')) {
      context.handle(
        _repeatModeMeta,
        repeatMode.isAcceptableOrUnknown(data['repeat_mode']!, _repeatModeMeta),
      );
    }
    if (data.containsKey('context_json')) {
      context.handle(
        _contextJsonMeta,
        contextJson.isAcceptableOrUnknown(
          data['context_json']!,
          _contextJsonMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QueueMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentQueueItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_queue_item_id'],
      ),
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      shuffleOrderJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shuffle_order_json'],
      ),
      repeatMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_mode'],
      )!,
      contextJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_json'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QueueMetaTable createAlias(String alias) {
    return $QueueMetaTable(attachedDatabase, alias);
  }
}

class QueueMetaData extends DataClass implements Insertable<QueueMetaData> {
  /// Always 1: the table holds one row.
  final int id;

  /// The current item's `queueItemId`, if any.
  final String? currentQueueItemId;

  /// The playback position in the current item, in milliseconds.
  final int positionMs;

  /// The shuffle permutation as a JSON array of canonical indices; null
  /// means shuffle is off.
  final String? shuffleOrderJson;

  /// `off`, `all` or `one`.
  final String repeatMode;

  /// The serialized `QueueContext`, if any.
  final String? contextJson;

  /// Increases with every change to the queue.
  final int revision;

  /// When the queue last changed.
  final DateTime updatedAt;
  const QueueMetaData({
    required this.id,
    this.currentQueueItemId,
    required this.positionMs,
    this.shuffleOrderJson,
    required this.repeatMode,
    this.contextJson,
    required this.revision,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || currentQueueItemId != null) {
      map['current_queue_item_id'] = Variable<String>(currentQueueItemId);
    }
    map['position_ms'] = Variable<int>(positionMs);
    if (!nullToAbsent || shuffleOrderJson != null) {
      map['shuffle_order_json'] = Variable<String>(shuffleOrderJson);
    }
    map['repeat_mode'] = Variable<String>(repeatMode);
    if (!nullToAbsent || contextJson != null) {
      map['context_json'] = Variable<String>(contextJson);
    }
    map['revision'] = Variable<int>(revision);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QueueMetaCompanion toCompanion(bool nullToAbsent) {
    return QueueMetaCompanion(
      id: Value(id),
      currentQueueItemId: currentQueueItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentQueueItemId),
      positionMs: Value(positionMs),
      shuffleOrderJson: shuffleOrderJson == null && nullToAbsent
          ? const Value.absent()
          : Value(shuffleOrderJson),
      repeatMode: Value(repeatMode),
      contextJson: contextJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contextJson),
      revision: Value(revision),
      updatedAt: Value(updatedAt),
    );
  }

  factory QueueMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueMetaData(
      id: serializer.fromJson<int>(json['id']),
      currentQueueItemId: serializer.fromJson<String?>(
        json['currentQueueItemId'],
      ),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      shuffleOrderJson: serializer.fromJson<String?>(json['shuffleOrderJson']),
      repeatMode: serializer.fromJson<String>(json['repeatMode']),
      contextJson: serializer.fromJson<String?>(json['contextJson']),
      revision: serializer.fromJson<int>(json['revision']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentQueueItemId': serializer.toJson<String?>(currentQueueItemId),
      'positionMs': serializer.toJson<int>(positionMs),
      'shuffleOrderJson': serializer.toJson<String?>(shuffleOrderJson),
      'repeatMode': serializer.toJson<String>(repeatMode),
      'contextJson': serializer.toJson<String?>(contextJson),
      'revision': serializer.toJson<int>(revision),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QueueMetaData copyWith({
    int? id,
    Value<String?> currentQueueItemId = const Value.absent(),
    int? positionMs,
    Value<String?> shuffleOrderJson = const Value.absent(),
    String? repeatMode,
    Value<String?> contextJson = const Value.absent(),
    int? revision,
    DateTime? updatedAt,
  }) => QueueMetaData(
    id: id ?? this.id,
    currentQueueItemId: currentQueueItemId.present
        ? currentQueueItemId.value
        : this.currentQueueItemId,
    positionMs: positionMs ?? this.positionMs,
    shuffleOrderJson: shuffleOrderJson.present
        ? shuffleOrderJson.value
        : this.shuffleOrderJson,
    repeatMode: repeatMode ?? this.repeatMode,
    contextJson: contextJson.present ? contextJson.value : this.contextJson,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QueueMetaData copyWithCompanion(QueueMetaCompanion data) {
    return QueueMetaData(
      id: data.id.present ? data.id.value : this.id,
      currentQueueItemId: data.currentQueueItemId.present
          ? data.currentQueueItemId.value
          : this.currentQueueItemId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      shuffleOrderJson: data.shuffleOrderJson.present
          ? data.shuffleOrderJson.value
          : this.shuffleOrderJson,
      repeatMode: data.repeatMode.present
          ? data.repeatMode.value
          : this.repeatMode,
      contextJson: data.contextJson.present
          ? data.contextJson.value
          : this.contextJson,
      revision: data.revision.present ? data.revision.value : this.revision,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueMetaData(')
          ..write('id: $id, ')
          ..write('currentQueueItemId: $currentQueueItemId, ')
          ..write('positionMs: $positionMs, ')
          ..write('shuffleOrderJson: $shuffleOrderJson, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('contextJson: $contextJson, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currentQueueItemId,
    positionMs,
    shuffleOrderJson,
    repeatMode,
    contextJson,
    revision,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueMetaData &&
          other.id == this.id &&
          other.currentQueueItemId == this.currentQueueItemId &&
          other.positionMs == this.positionMs &&
          other.shuffleOrderJson == this.shuffleOrderJson &&
          other.repeatMode == this.repeatMode &&
          other.contextJson == this.contextJson &&
          other.revision == this.revision &&
          other.updatedAt == this.updatedAt);
}

class QueueMetaCompanion extends UpdateCompanion<QueueMetaData> {
  final Value<int> id;
  final Value<String?> currentQueueItemId;
  final Value<int> positionMs;
  final Value<String?> shuffleOrderJson;
  final Value<String> repeatMode;
  final Value<String?> contextJson;
  final Value<int> revision;
  final Value<DateTime> updatedAt;
  const QueueMetaCompanion({
    this.id = const Value.absent(),
    this.currentQueueItemId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.shuffleOrderJson = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.revision = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  QueueMetaCompanion.insert({
    this.id = const Value.absent(),
    this.currentQueueItemId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.shuffleOrderJson = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.contextJson = const Value.absent(),
    this.revision = const Value.absent(),
    required DateTime updatedAt,
  }) : updatedAt = Value(updatedAt);
  static Insertable<QueueMetaData> custom({
    Expression<int>? id,
    Expression<String>? currentQueueItemId,
    Expression<int>? positionMs,
    Expression<String>? shuffleOrderJson,
    Expression<String>? repeatMode,
    Expression<String>? contextJson,
    Expression<int>? revision,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentQueueItemId != null)
        'current_queue_item_id': currentQueueItemId,
      if (positionMs != null) 'position_ms': positionMs,
      if (shuffleOrderJson != null) 'shuffle_order_json': shuffleOrderJson,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (contextJson != null) 'context_json': contextJson,
      if (revision != null) 'revision': revision,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  QueueMetaCompanion copyWith({
    Value<int>? id,
    Value<String?>? currentQueueItemId,
    Value<int>? positionMs,
    Value<String?>? shuffleOrderJson,
    Value<String>? repeatMode,
    Value<String?>? contextJson,
    Value<int>? revision,
    Value<DateTime>? updatedAt,
  }) {
    return QueueMetaCompanion(
      id: id ?? this.id,
      currentQueueItemId: currentQueueItemId ?? this.currentQueueItemId,
      positionMs: positionMs ?? this.positionMs,
      shuffleOrderJson: shuffleOrderJson ?? this.shuffleOrderJson,
      repeatMode: repeatMode ?? this.repeatMode,
      contextJson: contextJson ?? this.contextJson,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentQueueItemId.present) {
      map['current_queue_item_id'] = Variable<String>(currentQueueItemId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (shuffleOrderJson.present) {
      map['shuffle_order_json'] = Variable<String>(shuffleOrderJson.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<String>(repeatMode.value);
    }
    if (contextJson.present) {
      map['context_json'] = Variable<String>(contextJson.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueMetaCompanion(')
          ..write('id: $id, ')
          ..write('currentQueueItemId: $currentQueueItemId, ')
          ..write('positionMs: $positionMs, ')
          ..write('shuffleOrderJson: $shuffleOrderJson, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('contextJson: $contextJson, ')
          ..write('revision: $revision, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DownloadCollectionsTable extends DownloadCollections
    with TableInfo<$DownloadCollectionsTable, DownloadCollection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
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
  static const VerificationMeta _metaJsonMeta = const VerificationMeta(
    'metaJson',
  );
  @override
  late final GeneratedColumn<String> metaJson = GeneratedColumn<String>(
    'meta_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blockedReasonMeta = const VerificationMeta(
    'blockedReason',
  );
  @override
  late final GeneratedColumn<String> blockedReason = GeneratedColumn<String>(
    'blocked_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _detailJsonMeta = const VerificationMeta(
    'detailJson',
  );
  @override
  late final GeneratedColumn<String> detailJson = GeneratedColumn<String>(
    'detail_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    kind,
    refId,
    title,
    metaJson,
    status,
    blockedReason,
    detailJson,
    quality,
    requestedAt,
    resolvedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadCollection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('meta_json')) {
      context.handle(
        _metaJsonMeta,
        metaJson.isAcceptableOrUnknown(data['meta_json']!, _metaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_metaJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('blocked_reason')) {
      context.handle(
        _blockedReasonMeta,
        blockedReason.isAcceptableOrUnknown(
          data['blocked_reason']!,
          _blockedReasonMeta,
        ),
      );
    }
    if (data.containsKey('detail_json')) {
      context.handle(
        _detailJsonMeta,
        detailJson.isAcceptableOrUnknown(data['detail_json']!, _detailJsonMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, refId};
  @override
  DownloadCollection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadCollection(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      metaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      blockedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocked_reason'],
      ),
      detailJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail_json'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      ),
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
    );
  }

  @override
  $DownloadCollectionsTable createAlias(String alias) {
    return $DownloadCollectionsTable(attachedDatabase, alias);
  }
}

class DownloadCollection extends DataClass
    implements Insertable<DownloadCollection> {
  /// `track`, `album`, `playlist` or `episode`.
  final String kind;

  /// The collection's reference: a track's `playbackId`, an album or
  /// playlist id, or `<podcastId>:<episodeId>` for an episode.
  final String refId;

  /// The title shown in the downloads list.
  final String title;

  /// Enough metadata (subtitle, artwork ref) to render the row offline.
  final String metaJson;

  /// A plain state name such as `resolving`, `ready` or `blocked`.
  final String status;

  /// Why the collection is blocked, such as `serverQuota` or
  /// `disabledByServer`.
  final String? blockedReason;

  /// Detail of the state as JSON, for example the byte values of a server
  /// quota refusal.
  final String? detailJson;

  /// The requested download quality, if one was chosen.
  final String? quality;

  /// When the user asked for the download.
  final DateTime requestedAt;

  /// When the server last resolved the collection's items.
  final DateTime? resolvedAt;
  const DownloadCollection({
    required this.kind,
    required this.refId,
    required this.title,
    required this.metaJson,
    required this.status,
    this.blockedReason,
    this.detailJson,
    this.quality,
    required this.requestedAt,
    this.resolvedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['ref_id'] = Variable<String>(refId);
    map['title'] = Variable<String>(title);
    map['meta_json'] = Variable<String>(metaJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || blockedReason != null) {
      map['blocked_reason'] = Variable<String>(blockedReason);
    }
    if (!nullToAbsent || detailJson != null) {
      map['detail_json'] = Variable<String>(detailJson);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<String>(quality);
    }
    map['requested_at'] = Variable<DateTime>(requestedAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    return map;
  }

  DownloadCollectionsCompanion toCompanion(bool nullToAbsent) {
    return DownloadCollectionsCompanion(
      kind: Value(kind),
      refId: Value(refId),
      title: Value(title),
      metaJson: Value(metaJson),
      status: Value(status),
      blockedReason: blockedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(blockedReason),
      detailJson: detailJson == null && nullToAbsent
          ? const Value.absent()
          : Value(detailJson),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      requestedAt: Value(requestedAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
    );
  }

  factory DownloadCollection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadCollection(
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<String>(json['refId']),
      title: serializer.fromJson<String>(json['title']),
      metaJson: serializer.fromJson<String>(json['metaJson']),
      status: serializer.fromJson<String>(json['status']),
      blockedReason: serializer.fromJson<String?>(json['blockedReason']),
      detailJson: serializer.fromJson<String?>(json['detailJson']),
      quality: serializer.fromJson<String?>(json['quality']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<String>(refId),
      'title': serializer.toJson<String>(title),
      'metaJson': serializer.toJson<String>(metaJson),
      'status': serializer.toJson<String>(status),
      'blockedReason': serializer.toJson<String?>(blockedReason),
      'detailJson': serializer.toJson<String?>(detailJson),
      'quality': serializer.toJson<String?>(quality),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
    };
  }

  DownloadCollection copyWith({
    String? kind,
    String? refId,
    String? title,
    String? metaJson,
    String? status,
    Value<String?> blockedReason = const Value.absent(),
    Value<String?> detailJson = const Value.absent(),
    Value<String?> quality = const Value.absent(),
    DateTime? requestedAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
  }) => DownloadCollection(
    kind: kind ?? this.kind,
    refId: refId ?? this.refId,
    title: title ?? this.title,
    metaJson: metaJson ?? this.metaJson,
    status: status ?? this.status,
    blockedReason: blockedReason.present
        ? blockedReason.value
        : this.blockedReason,
    detailJson: detailJson.present ? detailJson.value : this.detailJson,
    quality: quality.present ? quality.value : this.quality,
    requestedAt: requestedAt ?? this.requestedAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
  );
  DownloadCollection copyWithCompanion(DownloadCollectionsCompanion data) {
    return DownloadCollection(
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      title: data.title.present ? data.title.value : this.title,
      metaJson: data.metaJson.present ? data.metaJson.value : this.metaJson,
      status: data.status.present ? data.status.value : this.status,
      blockedReason: data.blockedReason.present
          ? data.blockedReason.value
          : this.blockedReason,
      detailJson: data.detailJson.present
          ? data.detailJson.value
          : this.detailJson,
      quality: data.quality.present ? data.quality.value : this.quality,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadCollection(')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('title: $title, ')
          ..write('metaJson: $metaJson, ')
          ..write('status: $status, ')
          ..write('blockedReason: $blockedReason, ')
          ..write('detailJson: $detailJson, ')
          ..write('quality: $quality, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('resolvedAt: $resolvedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    kind,
    refId,
    title,
    metaJson,
    status,
    blockedReason,
    detailJson,
    quality,
    requestedAt,
    resolvedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadCollection &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.title == this.title &&
          other.metaJson == this.metaJson &&
          other.status == this.status &&
          other.blockedReason == this.blockedReason &&
          other.detailJson == this.detailJson &&
          other.quality == this.quality &&
          other.requestedAt == this.requestedAt &&
          other.resolvedAt == this.resolvedAt);
}

class DownloadCollectionsCompanion extends UpdateCompanion<DownloadCollection> {
  final Value<String> kind;
  final Value<String> refId;
  final Value<String> title;
  final Value<String> metaJson;
  final Value<String> status;
  final Value<String?> blockedReason;
  final Value<String?> detailJson;
  final Value<String?> quality;
  final Value<DateTime> requestedAt;
  final Value<DateTime?> resolvedAt;
  final Value<int> rowid;
  const DownloadCollectionsCompanion({
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.title = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.status = const Value.absent(),
    this.blockedReason = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.quality = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadCollectionsCompanion.insert({
    required String kind,
    required String refId,
    required String title,
    required String metaJson,
    required String status,
    this.blockedReason = const Value.absent(),
    this.detailJson = const Value.absent(),
    this.quality = const Value.absent(),
    required DateTime requestedAt,
    this.resolvedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       refId = Value(refId),
       title = Value(title),
       metaJson = Value(metaJson),
       status = Value(status),
       requestedAt = Value(requestedAt);
  static Insertable<DownloadCollection> custom({
    Expression<String>? kind,
    Expression<String>? refId,
    Expression<String>? title,
    Expression<String>? metaJson,
    Expression<String>? status,
    Expression<String>? blockedReason,
    Expression<String>? detailJson,
    Expression<String>? quality,
    Expression<DateTime>? requestedAt,
    Expression<DateTime>? resolvedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (title != null) 'title': title,
      if (metaJson != null) 'meta_json': metaJson,
      if (status != null) 'status': status,
      if (blockedReason != null) 'blocked_reason': blockedReason,
      if (detailJson != null) 'detail_json': detailJson,
      if (quality != null) 'quality': quality,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadCollectionsCompanion copyWith({
    Value<String>? kind,
    Value<String>? refId,
    Value<String>? title,
    Value<String>? metaJson,
    Value<String>? status,
    Value<String?>? blockedReason,
    Value<String?>? detailJson,
    Value<String?>? quality,
    Value<DateTime>? requestedAt,
    Value<DateTime?>? resolvedAt,
    Value<int>? rowid,
  }) {
    return DownloadCollectionsCompanion(
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      title: title ?? this.title,
      metaJson: metaJson ?? this.metaJson,
      status: status ?? this.status,
      blockedReason: blockedReason ?? this.blockedReason,
      detailJson: detailJson ?? this.detailJson,
      quality: quality ?? this.quality,
      requestedAt: requestedAt ?? this.requestedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (metaJson.present) {
      map['meta_json'] = Variable<String>(metaJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (blockedReason.present) {
      map['blocked_reason'] = Variable<String>(blockedReason.value);
    }
    if (detailJson.present) {
      map['detail_json'] = Variable<String>(detailJson.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadCollectionsCompanion(')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('title: $title, ')
          ..write('metaJson: $metaJson, ')
          ..write('status: $status, ')
          ..write('blockedReason: $blockedReason, ')
          ..write('detailJson: $detailJson, ')
          ..write('quality: $quality, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadItemsTable extends DownloadItems
    with TableInfo<$DownloadItemsTable, DownloadItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<MediaType, String> mediaType =
      GeneratedColumn<String>(
        'media_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MediaType>($DownloadItemsTable.$convertermediaType);
  static const VerificationMeta _metaJsonMeta = const VerificationMeta(
    'metaJson',
  );
  @override
  late final GeneratedColumn<String> metaJson = GeneratedColumn<String>(
    'meta_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DownloadStatus>($DownloadItemsTable.$converterstatus);
  static const VerificationMeta _waitingForMeta = const VerificationMeta(
    'waitingFor',
  );
  @override
  late final GeneratedColumn<String> waitingFor = GeneratedColumn<String>(
    'waiting_for',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadUrlMeta = const VerificationMeta(
    'downloadUrl',
  );
  @override
  late final GeneratedColumn<String> downloadUrl = GeneratedColumn<String>(
    'download_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedBytesMeta = const VerificationMeta(
    'expectedBytes',
  );
  @override
  late final GeneratedColumn<int> expectedBytes = GeneratedColumn<int>(
    'expected_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receivedBytesMeta = const VerificationMeta(
    'receivedBytes',
  );
  @override
  late final GeneratedColumn<int> receivedBytes = GeneratedColumn<int>(
    'received_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverConfirmedMeta = const VerificationMeta(
    'serverConfirmed',
  );
  @override
  late final GeneratedColumn<bool> serverConfirmed = GeneratedColumn<bool>(
    'server_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("server_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  @override
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemKey,
    mediaType,
    metaJson,
    quality,
    status,
    waitingFor,
    taskId,
    downloadUrl,
    etag,
    expectedBytes,
    receivedBytes,
    sizeBytes,
    relativePath,
    failureCode,
    attempts,
    serverConfirmed,
    requestedAt,
    completedAt,
    lastPlayedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('meta_json')) {
      context.handle(
        _metaJsonMeta,
        metaJson.isAcceptableOrUnknown(data['meta_json']!, _metaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_metaJsonMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('waiting_for')) {
      context.handle(
        _waitingForMeta,
        waitingFor.isAcceptableOrUnknown(data['waiting_for']!, _waitingForMeta),
      );
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('download_url')) {
      context.handle(
        _downloadUrlMeta,
        downloadUrl.isAcceptableOrUnknown(
          data['download_url']!,
          _downloadUrlMeta,
        ),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('expected_bytes')) {
      context.handle(
        _expectedBytesMeta,
        expectedBytes.isAcceptableOrUnknown(
          data['expected_bytes']!,
          _expectedBytesMeta,
        ),
      );
    }
    if (data.containsKey('received_bytes')) {
      context.handle(
        _receivedBytesMeta,
        receivedBytes.isAcceptableOrUnknown(
          data['received_bytes']!,
          _receivedBytesMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('server_confirmed')) {
      context.handle(
        _serverConfirmedMeta,
        serverConfirmed.isAcceptableOrUnknown(
          data['server_confirmed']!,
          _serverConfirmedMeta,
        ),
      );
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemKey};
  @override
  DownloadItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadItem(
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      mediaType: $DownloadItemsTable.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      metaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta_json'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      ),
      status: $DownloadItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      waitingFor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}waiting_for'],
      ),
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      downloadUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_url'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      expectedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_bytes'],
      ),
      receivedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}received_bytes'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      ),
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      serverConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}server_confirmed'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
    );
  }

  @override
  $DownloadItemsTable createAlias(String alias) {
    return $DownloadItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MediaType, String, String> $convertermediaType =
      const EnumNameConverter<MediaType>(MediaType.values);
  static JsonTypeConverter2<DownloadStatus, String, String> $converterstatus =
      const EnumNameConverter<DownloadStatus>(DownloadStatus.values);
}

class DownloadItem extends DataClass implements Insertable<DownloadItem> {
  /// `t:<playbackId>` or `e:<podcastId>:<episodeId>`.
  final String itemKey;

  /// Whether the file is a track or an episode.
  final MediaType mediaType;

  /// Track or episode metadata: enough to render and play offline.
  final String metaJson;

  /// The quality as resolved by the server.
  final String? quality;

  /// The item's state.
  final DownloadStatus status;

  /// Why a queued or paused item is not running, such as `space` or
  /// `wifi`. Never a failure code.
  final String? waitingFor;

  /// The transfer task's id.
  final String? taskId;

  /// The URL the file is downloaded from.
  final String? downloadUrl;

  /// The server's ETag for the file.
  final String? etag;

  /// The size the server announced, in bytes.
  final int? expectedBytes;

  /// Bytes received so far.
  final int receivedBytes;

  /// The verified size on disk, in bytes.
  final int? sizeBytes;

  /// The file's path under `profiles/<id>/media`.
  final String? relativePath;

  /// A failure or unavailability code, including the server's `reason`.
  final String? failureCode;

  /// Transfer attempts since the last reset.
  final int attempts;

  /// Whether the server acknowledged the completed download.
  final bool serverConfirmed;

  /// When the item was first requested.
  final DateTime requestedAt;

  /// When the file was verified.
  final DateTime? completedAt;

  /// When the file was last played.
  final DateTime? lastPlayedAt;
  const DownloadItem({
    required this.itemKey,
    required this.mediaType,
    required this.metaJson,
    this.quality,
    required this.status,
    this.waitingFor,
    this.taskId,
    this.downloadUrl,
    this.etag,
    this.expectedBytes,
    required this.receivedBytes,
    this.sizeBytes,
    this.relativePath,
    this.failureCode,
    required this.attempts,
    required this.serverConfirmed,
    required this.requestedAt,
    this.completedAt,
    this.lastPlayedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_key'] = Variable<String>(itemKey);
    {
      map['media_type'] = Variable<String>(
        $DownloadItemsTable.$convertermediaType.toSql(mediaType),
      );
    }
    map['meta_json'] = Variable<String>(metaJson);
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<String>(quality);
    }
    {
      map['status'] = Variable<String>(
        $DownloadItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || waitingFor != null) {
      map['waiting_for'] = Variable<String>(waitingFor);
    }
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || downloadUrl != null) {
      map['download_url'] = Variable<String>(downloadUrl);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || expectedBytes != null) {
      map['expected_bytes'] = Variable<int>(expectedBytes);
    }
    map['received_bytes'] = Variable<int>(receivedBytes);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || relativePath != null) {
      map['relative_path'] = Variable<String>(relativePath);
    }
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    map['attempts'] = Variable<int>(attempts);
    map['server_confirmed'] = Variable<bool>(serverConfirmed);
    map['requested_at'] = Variable<DateTime>(requestedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    return map;
  }

  DownloadItemsCompanion toCompanion(bool nullToAbsent) {
    return DownloadItemsCompanion(
      itemKey: Value(itemKey),
      mediaType: Value(mediaType),
      metaJson: Value(metaJson),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      status: Value(status),
      waitingFor: waitingFor == null && nullToAbsent
          ? const Value.absent()
          : Value(waitingFor),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      downloadUrl: downloadUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadUrl),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      expectedBytes: expectedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedBytes),
      receivedBytes: Value(receivedBytes),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      relativePath: relativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePath),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      attempts: Value(attempts),
      serverConfirmed: Value(serverConfirmed),
      requestedAt: Value(requestedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
    );
  }

  factory DownloadItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadItem(
      itemKey: serializer.fromJson<String>(json['itemKey']),
      mediaType: $DownloadItemsTable.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['mediaType']),
      ),
      metaJson: serializer.fromJson<String>(json['metaJson']),
      quality: serializer.fromJson<String?>(json['quality']),
      status: $DownloadItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      waitingFor: serializer.fromJson<String?>(json['waitingFor']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      downloadUrl: serializer.fromJson<String?>(json['downloadUrl']),
      etag: serializer.fromJson<String?>(json['etag']),
      expectedBytes: serializer.fromJson<int?>(json['expectedBytes']),
      receivedBytes: serializer.fromJson<int>(json['receivedBytes']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      relativePath: serializer.fromJson<String?>(json['relativePath']),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      attempts: serializer.fromJson<int>(json['attempts']),
      serverConfirmed: serializer.fromJson<bool>(json['serverConfirmed']),
      requestedAt: serializer.fromJson<DateTime>(json['requestedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemKey': serializer.toJson<String>(itemKey),
      'mediaType': serializer.toJson<String>(
        $DownloadItemsTable.$convertermediaType.toJson(mediaType),
      ),
      'metaJson': serializer.toJson<String>(metaJson),
      'quality': serializer.toJson<String?>(quality),
      'status': serializer.toJson<String>(
        $DownloadItemsTable.$converterstatus.toJson(status),
      ),
      'waitingFor': serializer.toJson<String?>(waitingFor),
      'taskId': serializer.toJson<String?>(taskId),
      'downloadUrl': serializer.toJson<String?>(downloadUrl),
      'etag': serializer.toJson<String?>(etag),
      'expectedBytes': serializer.toJson<int?>(expectedBytes),
      'receivedBytes': serializer.toJson<int>(receivedBytes),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'relativePath': serializer.toJson<String?>(relativePath),
      'failureCode': serializer.toJson<String?>(failureCode),
      'attempts': serializer.toJson<int>(attempts),
      'serverConfirmed': serializer.toJson<bool>(serverConfirmed),
      'requestedAt': serializer.toJson<DateTime>(requestedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
    };
  }

  DownloadItem copyWith({
    String? itemKey,
    MediaType? mediaType,
    String? metaJson,
    Value<String?> quality = const Value.absent(),
    DownloadStatus? status,
    Value<String?> waitingFor = const Value.absent(),
    Value<String?> taskId = const Value.absent(),
    Value<String?> downloadUrl = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    Value<int?> expectedBytes = const Value.absent(),
    int? receivedBytes,
    Value<int?> sizeBytes = const Value.absent(),
    Value<String?> relativePath = const Value.absent(),
    Value<String?> failureCode = const Value.absent(),
    int? attempts,
    bool? serverConfirmed,
    DateTime? requestedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<DateTime?> lastPlayedAt = const Value.absent(),
  }) => DownloadItem(
    itemKey: itemKey ?? this.itemKey,
    mediaType: mediaType ?? this.mediaType,
    metaJson: metaJson ?? this.metaJson,
    quality: quality.present ? quality.value : this.quality,
    status: status ?? this.status,
    waitingFor: waitingFor.present ? waitingFor.value : this.waitingFor,
    taskId: taskId.present ? taskId.value : this.taskId,
    downloadUrl: downloadUrl.present ? downloadUrl.value : this.downloadUrl,
    etag: etag.present ? etag.value : this.etag,
    expectedBytes: expectedBytes.present
        ? expectedBytes.value
        : this.expectedBytes,
    receivedBytes: receivedBytes ?? this.receivedBytes,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    relativePath: relativePath.present ? relativePath.value : this.relativePath,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    attempts: attempts ?? this.attempts,
    serverConfirmed: serverConfirmed ?? this.serverConfirmed,
    requestedAt: requestedAt ?? this.requestedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
  );
  DownloadItem copyWithCompanion(DownloadItemsCompanion data) {
    return DownloadItem(
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      metaJson: data.metaJson.present ? data.metaJson.value : this.metaJson,
      quality: data.quality.present ? data.quality.value : this.quality,
      status: data.status.present ? data.status.value : this.status,
      waitingFor: data.waitingFor.present
          ? data.waitingFor.value
          : this.waitingFor,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      downloadUrl: data.downloadUrl.present
          ? data.downloadUrl.value
          : this.downloadUrl,
      etag: data.etag.present ? data.etag.value : this.etag,
      expectedBytes: data.expectedBytes.present
          ? data.expectedBytes.value
          : this.expectedBytes,
      receivedBytes: data.receivedBytes.present
          ? data.receivedBytes.value
          : this.receivedBytes,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      serverConfirmed: data.serverConfirmed.present
          ? data.serverConfirmed.value
          : this.serverConfirmed,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadItem(')
          ..write('itemKey: $itemKey, ')
          ..write('mediaType: $mediaType, ')
          ..write('metaJson: $metaJson, ')
          ..write('quality: $quality, ')
          ..write('status: $status, ')
          ..write('waitingFor: $waitingFor, ')
          ..write('taskId: $taskId, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('etag: $etag, ')
          ..write('expectedBytes: $expectedBytes, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('relativePath: $relativePath, ')
          ..write('failureCode: $failureCode, ')
          ..write('attempts: $attempts, ')
          ..write('serverConfirmed: $serverConfirmed, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    itemKey,
    mediaType,
    metaJson,
    quality,
    status,
    waitingFor,
    taskId,
    downloadUrl,
    etag,
    expectedBytes,
    receivedBytes,
    sizeBytes,
    relativePath,
    failureCode,
    attempts,
    serverConfirmed,
    requestedAt,
    completedAt,
    lastPlayedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadItem &&
          other.itemKey == this.itemKey &&
          other.mediaType == this.mediaType &&
          other.metaJson == this.metaJson &&
          other.quality == this.quality &&
          other.status == this.status &&
          other.waitingFor == this.waitingFor &&
          other.taskId == this.taskId &&
          other.downloadUrl == this.downloadUrl &&
          other.etag == this.etag &&
          other.expectedBytes == this.expectedBytes &&
          other.receivedBytes == this.receivedBytes &&
          other.sizeBytes == this.sizeBytes &&
          other.relativePath == this.relativePath &&
          other.failureCode == this.failureCode &&
          other.attempts == this.attempts &&
          other.serverConfirmed == this.serverConfirmed &&
          other.requestedAt == this.requestedAt &&
          other.completedAt == this.completedAt &&
          other.lastPlayedAt == this.lastPlayedAt);
}

class DownloadItemsCompanion extends UpdateCompanion<DownloadItem> {
  final Value<String> itemKey;
  final Value<MediaType> mediaType;
  final Value<String> metaJson;
  final Value<String?> quality;
  final Value<DownloadStatus> status;
  final Value<String?> waitingFor;
  final Value<String?> taskId;
  final Value<String?> downloadUrl;
  final Value<String?> etag;
  final Value<int?> expectedBytes;
  final Value<int> receivedBytes;
  final Value<int?> sizeBytes;
  final Value<String?> relativePath;
  final Value<String?> failureCode;
  final Value<int> attempts;
  final Value<bool> serverConfirmed;
  final Value<DateTime> requestedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> rowid;
  const DownloadItemsCompanion({
    this.itemKey = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.quality = const Value.absent(),
    this.status = const Value.absent(),
    this.waitingFor = const Value.absent(),
    this.taskId = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.etag = const Value.absent(),
    this.expectedBytes = const Value.absent(),
    this.receivedBytes = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.serverConfirmed = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadItemsCompanion.insert({
    required String itemKey,
    required MediaType mediaType,
    required String metaJson,
    this.quality = const Value.absent(),
    required DownloadStatus status,
    this.waitingFor = const Value.absent(),
    this.taskId = const Value.absent(),
    this.downloadUrl = const Value.absent(),
    this.etag = const Value.absent(),
    this.expectedBytes = const Value.absent(),
    this.receivedBytes = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.serverConfirmed = const Value.absent(),
    required DateTime requestedAt,
    this.completedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemKey = Value(itemKey),
       mediaType = Value(mediaType),
       metaJson = Value(metaJson),
       status = Value(status),
       requestedAt = Value(requestedAt);
  static Insertable<DownloadItem> custom({
    Expression<String>? itemKey,
    Expression<String>? mediaType,
    Expression<String>? metaJson,
    Expression<String>? quality,
    Expression<String>? status,
    Expression<String>? waitingFor,
    Expression<String>? taskId,
    Expression<String>? downloadUrl,
    Expression<String>? etag,
    Expression<int>? expectedBytes,
    Expression<int>? receivedBytes,
    Expression<int>? sizeBytes,
    Expression<String>? relativePath,
    Expression<String>? failureCode,
    Expression<int>? attempts,
    Expression<bool>? serverConfirmed,
    Expression<DateTime>? requestedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemKey != null) 'item_key': itemKey,
      if (mediaType != null) 'media_type': mediaType,
      if (metaJson != null) 'meta_json': metaJson,
      if (quality != null) 'quality': quality,
      if (status != null) 'status': status,
      if (waitingFor != null) 'waiting_for': waitingFor,
      if (taskId != null) 'task_id': taskId,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (etag != null) 'etag': etag,
      if (expectedBytes != null) 'expected_bytes': expectedBytes,
      if (receivedBytes != null) 'received_bytes': receivedBytes,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (relativePath != null) 'relative_path': relativePath,
      if (failureCode != null) 'failure_code': failureCode,
      if (attempts != null) 'attempts': attempts,
      if (serverConfirmed != null) 'server_confirmed': serverConfirmed,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadItemsCompanion copyWith({
    Value<String>? itemKey,
    Value<MediaType>? mediaType,
    Value<String>? metaJson,
    Value<String?>? quality,
    Value<DownloadStatus>? status,
    Value<String?>? waitingFor,
    Value<String?>? taskId,
    Value<String?>? downloadUrl,
    Value<String?>? etag,
    Value<int?>? expectedBytes,
    Value<int>? receivedBytes,
    Value<int?>? sizeBytes,
    Value<String?>? relativePath,
    Value<String?>? failureCode,
    Value<int>? attempts,
    Value<bool>? serverConfirmed,
    Value<DateTime>? requestedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? rowid,
  }) {
    return DownloadItemsCompanion(
      itemKey: itemKey ?? this.itemKey,
      mediaType: mediaType ?? this.mediaType,
      metaJson: metaJson ?? this.metaJson,
      quality: quality ?? this.quality,
      status: status ?? this.status,
      waitingFor: waitingFor ?? this.waitingFor,
      taskId: taskId ?? this.taskId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      etag: etag ?? this.etag,
      expectedBytes: expectedBytes ?? this.expectedBytes,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      relativePath: relativePath ?? this.relativePath,
      failureCode: failureCode ?? this.failureCode,
      attempts: attempts ?? this.attempts,
      serverConfirmed: serverConfirmed ?? this.serverConfirmed,
      requestedAt: requestedAt ?? this.requestedAt,
      completedAt: completedAt ?? this.completedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        $DownloadItemsTable.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (metaJson.present) {
      map['meta_json'] = Variable<String>(metaJson.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $DownloadItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (waitingFor.present) {
      map['waiting_for'] = Variable<String>(waitingFor.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (downloadUrl.present) {
      map['download_url'] = Variable<String>(downloadUrl.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (expectedBytes.present) {
      map['expected_bytes'] = Variable<int>(expectedBytes.value);
    }
    if (receivedBytes.present) {
      map['received_bytes'] = Variable<int>(receivedBytes.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (serverConfirmed.present) {
      map['server_confirmed'] = Variable<bool>(serverConfirmed.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadItemsCompanion(')
          ..write('itemKey: $itemKey, ')
          ..write('mediaType: $mediaType, ')
          ..write('metaJson: $metaJson, ')
          ..write('quality: $quality, ')
          ..write('status: $status, ')
          ..write('waitingFor: $waitingFor, ')
          ..write('taskId: $taskId, ')
          ..write('downloadUrl: $downloadUrl, ')
          ..write('etag: $etag, ')
          ..write('expectedBytes: $expectedBytes, ')
          ..write('receivedBytes: $receivedBytes, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('relativePath: $relativePath, ')
          ..write('failureCode: $failureCode, ')
          ..write('attempts: $attempts, ')
          ..write('serverConfirmed: $serverConfirmed, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadMembershipTable extends DownloadMembership
    with TableInfo<$DownloadMembershipTable, DownloadMembershipData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadMembershipTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES download_items (item_key) ON DELETE CASCADE',
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
  List<GeneratedColumn> get $columns => [kind, refId, itemKey, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_membership';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadMembershipData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, refId, itemKey};
  @override
  DownloadMembershipData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadMembershipData(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $DownloadMembershipTable createAlias(String alias) {
    return $DownloadMembershipTable(attachedDatabase, alias);
  }
}

class DownloadMembershipData extends DataClass
    implements Insertable<DownloadMembershipData> {
  /// The collection's kind.
  final String kind;

  /// The collection's reference.
  final String refId;

  /// The item's key.
  final String itemKey;

  /// The item's order inside the collection.
  final int position;
  const DownloadMembershipData({
    required this.kind,
    required this.refId,
    required this.itemKey,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['ref_id'] = Variable<String>(refId);
    map['item_key'] = Variable<String>(itemKey);
    map['position'] = Variable<int>(position);
    return map;
  }

  DownloadMembershipCompanion toCompanion(bool nullToAbsent) {
    return DownloadMembershipCompanion(
      kind: Value(kind),
      refId: Value(refId),
      itemKey: Value(itemKey),
      position: Value(position),
    );
  }

  factory DownloadMembershipData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadMembershipData(
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<String>(json['refId']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<String>(refId),
      'itemKey': serializer.toJson<String>(itemKey),
      'position': serializer.toJson<int>(position),
    };
  }

  DownloadMembershipData copyWith({
    String? kind,
    String? refId,
    String? itemKey,
    int? position,
  }) => DownloadMembershipData(
    kind: kind ?? this.kind,
    refId: refId ?? this.refId,
    itemKey: itemKey ?? this.itemKey,
    position: position ?? this.position,
  );
  DownloadMembershipData copyWithCompanion(DownloadMembershipCompanion data) {
    return DownloadMembershipData(
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadMembershipData(')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('itemKey: $itemKey, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, refId, itemKey, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadMembershipData &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.itemKey == this.itemKey &&
          other.position == this.position);
}

class DownloadMembershipCompanion
    extends UpdateCompanion<DownloadMembershipData> {
  final Value<String> kind;
  final Value<String> refId;
  final Value<String> itemKey;
  final Value<int> position;
  final Value<int> rowid;
  const DownloadMembershipCompanion({
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadMembershipCompanion.insert({
    required String kind,
    required String refId,
    required String itemKey,
    required int position,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       refId = Value(refId),
       itemKey = Value(itemKey),
       position = Value(position);
  static Insertable<DownloadMembershipData> custom({
    Expression<String>? kind,
    Expression<String>? refId,
    Expression<String>? itemKey,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (itemKey != null) 'item_key': itemKey,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadMembershipCompanion copyWith({
    Value<String>? kind,
    Value<String>? refId,
    Value<String>? itemKey,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return DownloadMembershipCompanion(
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      itemKey: itemKey ?? this.itemKey,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadMembershipCompanion(')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('itemKey: $itemKey, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    opType,
    entityKey,
    payloadJson,
    createdAt,
    attempts,
    nextAttemptAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('entity_key')) {
      context.handle(
        _entityKeyMeta,
        entityKey.isAcceptableOrUnknown(data['entity_key']!, _entityKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      entityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  /// Insertion order; never reused.
  final int seq;

  /// The operation's type.
  final String opType;

  /// The coalescing key, for example `pref:<playbackId>`.
  final String entityKey;

  /// The operation's payload as JSON.
  final String payloadJson;

  /// When the operation was recorded.
  final DateTime createdAt;

  /// Delivery attempts so far.
  final int attempts;

  /// When the next attempt may run, if it is delayed.
  final DateTime? nextAttemptAt;

  /// The last delivery error.
  final String? lastError;
  const OutboxData({
    required this.seq,
    required this.opType,
    required this.entityKey,
    required this.payloadJson,
    required this.createdAt,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['op_type'] = Variable<String>(opType);
    map['entity_key'] = Variable<String>(entityKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      seq: Value(seq),
      opType: Value(opType),
      entityKey: Value(entityKey),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      seq: serializer.fromJson<int>(json['seq']),
      opType: serializer.fromJson<String>(json['opType']),
      entityKey: serializer.fromJson<String>(json['entityKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'opType': serializer.toJson<String>(opType),
      'entityKey': serializer.toJson<String>(entityKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  OutboxData copyWith({
    int? seq,
    String? opType,
    String? entityKey,
    String? payloadJson,
    DateTime? createdAt,
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => OutboxData(
    seq: seq ?? this.seq,
    opType: opType ?? this.opType,
    entityKey: entityKey ?? this.entityKey,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      seq: data.seq.present ? data.seq.value : this.seq,
      opType: data.opType.present ? data.opType.value : this.opType,
      entityKey: data.entityKey.present ? data.entityKey.value : this.entityKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('seq: $seq, ')
          ..write('opType: $opType, ')
          ..write('entityKey: $entityKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    opType,
    entityKey,
    payloadJson,
    createdAt,
    attempts,
    nextAttemptAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.seq == this.seq &&
          other.opType == this.opType &&
          other.entityKey == this.entityKey &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> seq;
  final Value<String> opType;
  final Value<String> entityKey;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  const OutboxCompanion({
    this.seq = const Value.absent(),
    this.opType = const Value.absent(),
    this.entityKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String opType,
    required String entityKey,
    required String payloadJson,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
  }) : opType = Value(opType),
       entityKey = Value(entityKey),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<int>? seq,
    Expression<String>? opType,
    Expression<String>? entityKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (opType != null) 'op_type': opType,
      if (entityKey != null) 'entity_key': entityKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? opType,
    Value<String>? entityKey,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
  }) {
    return OutboxCompanion(
      seq: seq ?? this.seq,
      opType: opType ?? this.opType,
      entityKey: entityKey ?? this.entityKey,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (entityKey.present) {
      map['entity_key'] = Variable<String>(entityKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('opType: $opType, ')
          ..write('entityKey: $entityKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

class $PlaySessionsTable extends PlaySessions
    with TableInfo<$PlaySessionsTable, PlaySession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _queueItemIdMeta = const VerificationMeta(
    'queueItemId',
  );
  @override
  late final GeneratedColumn<String> queueItemId = GeneratedColumn<String>(
    'queue_item_id',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metaJsonMeta = const VerificationMeta(
    'metaJson',
  );
  @override
  late final GeneratedColumn<String> metaJson = GeneratedColumn<String>(
    'meta_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listenedMsMeta = const VerificationMeta(
    'listenedMs',
  );
  @override
  late final GeneratedColumn<int> listenedMs = GeneratedColumn<int>(
    'listened_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    queueItemId,
    playbackId,
    metaJson,
    playedAt,
    listenedMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaySession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('queue_item_id')) {
      context.handle(
        _queueItemIdMeta,
        queueItemId.isAcceptableOrUnknown(
          data['queue_item_id']!,
          _queueItemIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queueItemIdMeta);
    }
    if (data.containsKey('playback_id')) {
      context.handle(
        _playbackIdMeta,
        playbackId.isAcceptableOrUnknown(data['playback_id']!, _playbackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playbackIdMeta);
    }
    if (data.containsKey('meta_json')) {
      context.handle(
        _metaJsonMeta,
        metaJson.isAcceptableOrUnknown(data['meta_json']!, _metaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_metaJsonMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('listened_ms')) {
      context.handle(
        _listenedMsMeta,
        listenedMs.isAcceptableOrUnknown(data['listened_ms']!, _listenedMsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  PlaySession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaySession(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      queueItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}queue_item_id'],
      )!,
      playbackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playback_id'],
      )!,
      metaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meta_json'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      listenedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listened_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PlaySessionsTable createAlias(String alias) {
    return $PlaySessionsTable(attachedDatabase, alias);
  }
}

class PlaySession extends DataClass implements Insertable<PlaySession> {
  /// The session's id, a client-generated UUID.
  final String sessionId;

  /// The queue entry being played.
  final String queueItemId;

  /// The played item's `playbackId`, stored verbatim.
  final String playbackId;

  /// The serialized `TrackMeta`.
  final String metaJson;

  /// The instant the play started.
  final DateTime playedAt;

  /// How long the user has listened, in milliseconds.
  final int listenedMs;

  /// When the row last changed.
  final DateTime updatedAt;
  const PlaySession({
    required this.sessionId,
    required this.queueItemId,
    required this.playbackId,
    required this.metaJson,
    required this.playedAt,
    required this.listenedMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['queue_item_id'] = Variable<String>(queueItemId);
    map['playback_id'] = Variable<String>(playbackId);
    map['meta_json'] = Variable<String>(metaJson);
    map['played_at'] = Variable<DateTime>(playedAt);
    map['listened_ms'] = Variable<int>(listenedMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return PlaySessionsCompanion(
      sessionId: Value(sessionId),
      queueItemId: Value(queueItemId),
      playbackId: Value(playbackId),
      metaJson: Value(metaJson),
      playedAt: Value(playedAt),
      listenedMs: Value(listenedMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaySession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaySession(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      queueItemId: serializer.fromJson<String>(json['queueItemId']),
      playbackId: serializer.fromJson<String>(json['playbackId']),
      metaJson: serializer.fromJson<String>(json['metaJson']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      listenedMs: serializer.fromJson<int>(json['listenedMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'queueItemId': serializer.toJson<String>(queueItemId),
      'playbackId': serializer.toJson<String>(playbackId),
      'metaJson': serializer.toJson<String>(metaJson),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'listenedMs': serializer.toJson<int>(listenedMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaySession copyWith({
    String? sessionId,
    String? queueItemId,
    String? playbackId,
    String? metaJson,
    DateTime? playedAt,
    int? listenedMs,
    DateTime? updatedAt,
  }) => PlaySession(
    sessionId: sessionId ?? this.sessionId,
    queueItemId: queueItemId ?? this.queueItemId,
    playbackId: playbackId ?? this.playbackId,
    metaJson: metaJson ?? this.metaJson,
    playedAt: playedAt ?? this.playedAt,
    listenedMs: listenedMs ?? this.listenedMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaySession copyWithCompanion(PlaySessionsCompanion data) {
    return PlaySession(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      queueItemId: data.queueItemId.present
          ? data.queueItemId.value
          : this.queueItemId,
      playbackId: data.playbackId.present
          ? data.playbackId.value
          : this.playbackId,
      metaJson: data.metaJson.present ? data.metaJson.value : this.metaJson,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      listenedMs: data.listenedMs.present
          ? data.listenedMs.value
          : this.listenedMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaySession(')
          ..write('sessionId: $sessionId, ')
          ..write('queueItemId: $queueItemId, ')
          ..write('playbackId: $playbackId, ')
          ..write('metaJson: $metaJson, ')
          ..write('playedAt: $playedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    queueItemId,
    playbackId,
    metaJson,
    playedAt,
    listenedMs,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySession &&
          other.sessionId == this.sessionId &&
          other.queueItemId == this.queueItemId &&
          other.playbackId == this.playbackId &&
          other.metaJson == this.metaJson &&
          other.playedAt == this.playedAt &&
          other.listenedMs == this.listenedMs &&
          other.updatedAt == this.updatedAt);
}

class PlaySessionsCompanion extends UpdateCompanion<PlaySession> {
  final Value<String> sessionId;
  final Value<String> queueItemId;
  final Value<String> playbackId;
  final Value<String> metaJson;
  final Value<DateTime> playedAt;
  final Value<int> listenedMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaySessionsCompanion({
    this.sessionId = const Value.absent(),
    this.queueItemId = const Value.absent(),
    this.playbackId = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.listenedMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaySessionsCompanion.insert({
    required String sessionId,
    required String queueItemId,
    required String playbackId,
    required String metaJson,
    required DateTime playedAt,
    this.listenedMs = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       queueItemId = Value(queueItemId),
       playbackId = Value(playbackId),
       metaJson = Value(metaJson),
       playedAt = Value(playedAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaySession> custom({
    Expression<String>? sessionId,
    Expression<String>? queueItemId,
    Expression<String>? playbackId,
    Expression<String>? metaJson,
    Expression<DateTime>? playedAt,
    Expression<int>? listenedMs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (queueItemId != null) 'queue_item_id': queueItemId,
      if (playbackId != null) 'playback_id': playbackId,
      if (metaJson != null) 'meta_json': metaJson,
      if (playedAt != null) 'played_at': playedAt,
      if (listenedMs != null) 'listened_ms': listenedMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaySessionsCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? queueItemId,
    Value<String>? playbackId,
    Value<String>? metaJson,
    Value<DateTime>? playedAt,
    Value<int>? listenedMs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaySessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      queueItemId: queueItemId ?? this.queueItemId,
      playbackId: playbackId ?? this.playbackId,
      metaJson: metaJson ?? this.metaJson,
      playedAt: playedAt ?? this.playedAt,
      listenedMs: listenedMs ?? this.listenedMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (queueItemId.present) {
      map['queue_item_id'] = Variable<String>(queueItemId.value);
    }
    if (playbackId.present) {
      map['playback_id'] = Variable<String>(playbackId.value);
    }
    if (metaJson.present) {
      map['meta_json'] = Variable<String>(metaJson.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (listenedMs.present) {
      map['listened_ms'] = Variable<int>(listenedMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('queueItemId: $queueItemId, ')
          ..write('playbackId: $playbackId, ')
          ..write('metaJson: $metaJson, ')
          ..write('playedAt: $playedAt, ')
          ..write('listenedMs: $listenedMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory
    with TableInfo<$SearchHistoryTable, SearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE NOCASE',
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(
        _queryMeta,
        query.isAcceptableOrUnknown(data['query']!, _queryMeta),
      );
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query};
  @override
  SearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryData(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryData extends DataClass
    implements Insertable<SearchHistoryData> {
  /// The search text, compared case-insensitively.
  final String query;

  /// When the query was last used.
  final DateTime lastUsedAt;
  const SearchHistoryData({required this.query, required this.lastUsedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(
      query: Value(query),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory SearchHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryData(
      query: serializer.fromJson<String>(json['query']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  SearchHistoryData copyWith({String? query, DateTime? lastUsedAt}) =>
      SearchHistoryData(
        query: query ?? this.query,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );
  SearchHistoryData copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryData(
      query: data.query.present ? data.query.value : this.query,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryData(')
          ..write('query: $query, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryData &&
          other.query == this.query &&
          other.lastUsedAt == this.lastUsedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryData> {
  final Value<String> query;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const SearchHistoryCompanion({
    this.query = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchHistoryCompanion.insert({
    required String query,
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<SearchHistoryData> custom({
    Expression<String>? query,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchHistoryCompanion copyWith({
    Value<String>? query,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return SearchHistoryCompanion(
      query: query ?? this.query,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('query: $query, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$StateDatabase extends GeneratedDatabase {
  _$StateDatabase(QueryExecutor e) : super(e);
  $StateDatabaseManager get managers => $StateDatabaseManager(this);
  late final $DeviceSettingsTable deviceSettings = $DeviceSettingsTable(this);
  late final $QueueSnapshotTable queueSnapshot = $QueueSnapshotTable(this);
  late final $QueueMetaTable queueMeta = $QueueMetaTable(this);
  late final $DownloadCollectionsTable downloadCollections =
      $DownloadCollectionsTable(this);
  late final $DownloadItemsTable downloadItems = $DownloadItemsTable(this);
  late final $DownloadMembershipTable downloadMembership =
      $DownloadMembershipTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  late final Index downloadItemsStatus = Index(
    'download_items_status',
    'CREATE INDEX download_items_status ON download_items (status)',
  );
  late final Index downloadMembershipItemKey = Index(
    'download_membership_item_key',
    'CREATE INDEX download_membership_item_key ON download_membership (item_key)',
  );
  late final Index outboxEntityKey = Index(
    'outbox_entity_key',
    'CREATE INDEX outbox_entity_key ON outbox (entity_key)',
  );
  late final Index outboxNextAttemptAt = Index(
    'outbox_next_attempt_at',
    'CREATE INDEX outbox_next_attempt_at ON outbox (next_attempt_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    deviceSettings,
    queueSnapshot,
    queueMeta,
    downloadCollections,
    downloadItems,
    downloadMembership,
    outbox,
    playSessions,
    searchHistory,
    downloadItemsStatus,
    downloadMembershipItemKey,
    outboxEntityKey,
    outboxNextAttemptAt,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'download_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('download_membership', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$DeviceSettingsTableCreateCompanionBuilder =
    DeviceSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$DeviceSettingsTableUpdateCompanionBuilder =
    DeviceSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$DeviceSettingsTableFilterComposer
    extends Composer<_$StateDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableFilterComposer({
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

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceSettingsTableOrderingComposer
    extends Composer<_$StateDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceSettingsTableAnnotationComposer
    extends Composer<_$StateDatabase, $DeviceSettingsTable> {
  $$DeviceSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$DeviceSettingsTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $DeviceSettingsTable,
          DeviceSetting,
          $$DeviceSettingsTableFilterComposer,
          $$DeviceSettingsTableOrderingComposer,
          $$DeviceSettingsTableAnnotationComposer,
          $$DeviceSettingsTableCreateCompanionBuilder,
          $$DeviceSettingsTableUpdateCompanionBuilder,
          (
            DeviceSetting,
            BaseReferences<
              _$StateDatabase,
              $DeviceSettingsTable,
              DeviceSetting
            >,
          ),
          DeviceSetting,
          PrefetchHooks Function()
        > {
  $$DeviceSettingsTableTableManager(
    _$StateDatabase db,
    $DeviceSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => DeviceSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => DeviceSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DeviceSettingsTable, DeviceSetting>(table),
                  BaseReferences<
                    _$StateDatabase,
                    $DeviceSettingsTable,
                    DeviceSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $DeviceSettingsTable,
      DeviceSetting,
      $$DeviceSettingsTableFilterComposer,
      $$DeviceSettingsTableOrderingComposer,
      $$DeviceSettingsTableAnnotationComposer,
      $$DeviceSettingsTableCreateCompanionBuilder,
      $$DeviceSettingsTableUpdateCompanionBuilder,
      (
        DeviceSetting,
        BaseReferences<_$StateDatabase, $DeviceSettingsTable, DeviceSetting>,
      ),
      DeviceSetting,
      PrefetchHooks Function()
    >;
typedef $$QueueSnapshotTableCreateCompanionBuilder =
    QueueSnapshotCompanion Function({
      Value<int> position,
      required String queueItemId,
      required String kind,
      required String itemJson,
    });
typedef $$QueueSnapshotTableUpdateCompanionBuilder =
    QueueSnapshotCompanion Function({
      Value<int> position,
      Value<String> queueItemId,
      Value<String> kind,
      Value<String> itemJson,
    });

class $$QueueSnapshotTableFilterComposer
    extends Composer<_$StateDatabase, $QueueSnapshotTable> {
  $$QueueSnapshotTableFilterComposer({
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

  ColumnFilters<String> get queueItemId => $composableBuilder(
    column: $table.queueItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemJson => $composableBuilder(
    column: $table.itemJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueSnapshotTableOrderingComposer
    extends Composer<_$StateDatabase, $QueueSnapshotTable> {
  $$QueueSnapshotTableOrderingComposer({
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

  ColumnOrderings<String> get queueItemId => $composableBuilder(
    column: $table.queueItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemJson => $composableBuilder(
    column: $table.itemJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueSnapshotTableAnnotationComposer
    extends Composer<_$StateDatabase, $QueueSnapshotTable> {
  $$QueueSnapshotTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get queueItemId => $composableBuilder(
    column: $table.queueItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get itemJson =>
      $composableBuilder(column: $table.itemJson, builder: (column) => column);
}

class $$QueueSnapshotTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $QueueSnapshotTable,
          QueueSnapshotData,
          $$QueueSnapshotTableFilterComposer,
          $$QueueSnapshotTableOrderingComposer,
          $$QueueSnapshotTableAnnotationComposer,
          $$QueueSnapshotTableCreateCompanionBuilder,
          $$QueueSnapshotTableUpdateCompanionBuilder,
          (
            QueueSnapshotData,
            BaseReferences<
              _$StateDatabase,
              $QueueSnapshotTable,
              QueueSnapshotData
            >,
          ),
          QueueSnapshotData,
          PrefetchHooks Function()
        > {
  $$QueueSnapshotTableTableManager(
    _$StateDatabase db,
    $QueueSnapshotTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueSnapshotTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueSnapshotTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueSnapshotTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> position = const Value.absent(),
                Value<String> queueItemId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> itemJson = const Value.absent(),
              }) => QueueSnapshotCompanion(
                position: position,
                queueItemId: queueItemId,
                kind: kind,
                itemJson: itemJson,
              ),
          createCompanionCallback:
              ({
                Value<int> position = const Value.absent(),
                required String queueItemId,
                required String kind,
                required String itemJson,
              }) => QueueSnapshotCompanion.insert(
                position: position,
                queueItemId: queueItemId,
                kind: kind,
                itemJson: itemJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueueSnapshotTable, QueueSnapshotData>(table),
                  BaseReferences<
                    _$StateDatabase,
                    $QueueSnapshotTable,
                    QueueSnapshotData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueSnapshotTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $QueueSnapshotTable,
      QueueSnapshotData,
      $$QueueSnapshotTableFilterComposer,
      $$QueueSnapshotTableOrderingComposer,
      $$QueueSnapshotTableAnnotationComposer,
      $$QueueSnapshotTableCreateCompanionBuilder,
      $$QueueSnapshotTableUpdateCompanionBuilder,
      (
        QueueSnapshotData,
        BaseReferences<_$StateDatabase, $QueueSnapshotTable, QueueSnapshotData>,
      ),
      QueueSnapshotData,
      PrefetchHooks Function()
    >;
typedef $$QueueMetaTableCreateCompanionBuilder = QueueMetaCompanion Function({
  Value<int> id,
  Value<String?> currentQueueItemId,
  Value<int> positionMs,
  Value<String?> shuffleOrderJson,
  Value<String> repeatMode,
  Value<String?> contextJson,
  Value<int> revision,
  required DateTime updatedAt,
});
typedef $$QueueMetaTableUpdateCompanionBuilder = QueueMetaCompanion Function({
  Value<int> id,
  Value<String?> currentQueueItemId,
  Value<int> positionMs,
  Value<String?> shuffleOrderJson,
  Value<String> repeatMode,
  Value<String?> contextJson,
  Value<int> revision,
  Value<DateTime> updatedAt,
});

class $$QueueMetaTableFilterComposer
    extends Composer<_$StateDatabase, $QueueMetaTable> {
  $$QueueMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentQueueItemId => $composableBuilder(
    column: $table.currentQueueItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shuffleOrderJson => $composableBuilder(
    column: $table.shuffleOrderJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueueMetaTableOrderingComposer
    extends Composer<_$StateDatabase, $QueueMetaTable> {
  $$QueueMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentQueueItemId => $composableBuilder(
    column: $table.currentQueueItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shuffleOrderJson => $composableBuilder(
    column: $table.shuffleOrderJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueueMetaTableAnnotationComposer
    extends Composer<_$StateDatabase, $QueueMetaTable> {
  $$QueueMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentQueueItemId => $composableBuilder(
    column: $table.currentQueueItemId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shuffleOrderJson => $composableBuilder(
    column: $table.shuffleOrderJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatMode => $composableBuilder(
    column: $table.repeatMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextJson => $composableBuilder(
    column: $table.contextJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QueueMetaTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $QueueMetaTable,
          QueueMetaData,
          $$QueueMetaTableFilterComposer,
          $$QueueMetaTableOrderingComposer,
          $$QueueMetaTableAnnotationComposer,
          $$QueueMetaTableCreateCompanionBuilder,
          $$QueueMetaTableUpdateCompanionBuilder,
          (
            QueueMetaData,
            BaseReferences<_$StateDatabase, $QueueMetaTable, QueueMetaData>,
          ),
          QueueMetaData,
          PrefetchHooks Function()
        > {
  $$QueueMetaTableTableManager(_$StateDatabase db, $QueueMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentQueueItemId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<String?> shuffleOrderJson = const Value.absent(),
                Value<String> repeatMode = const Value.absent(),
                Value<String?> contextJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => QueueMetaCompanion(
                id: id,
                currentQueueItemId: currentQueueItemId,
                positionMs: positionMs,
                shuffleOrderJson: shuffleOrderJson,
                repeatMode: repeatMode,
                contextJson: contextJson,
                revision: revision,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> currentQueueItemId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<String?> shuffleOrderJson = const Value.absent(),
                Value<String> repeatMode = const Value.absent(),
                Value<String?> contextJson = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required DateTime updatedAt,
              }) => QueueMetaCompanion.insert(
                id: id,
                currentQueueItemId: currentQueueItemId,
                positionMs: positionMs,
                shuffleOrderJson: shuffleOrderJson,
                repeatMode: repeatMode,
                contextJson: contextJson,
                revision: revision,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QueueMetaTable, QueueMetaData>(table),
                  BaseReferences<
                    _$StateDatabase,
                    $QueueMetaTable,
                    QueueMetaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueueMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $QueueMetaTable,
      QueueMetaData,
      $$QueueMetaTableFilterComposer,
      $$QueueMetaTableOrderingComposer,
      $$QueueMetaTableAnnotationComposer,
      $$QueueMetaTableCreateCompanionBuilder,
      $$QueueMetaTableUpdateCompanionBuilder,
      (
        QueueMetaData,
        BaseReferences<_$StateDatabase, $QueueMetaTable, QueueMetaData>,
      ),
      QueueMetaData,
      PrefetchHooks Function()
    >;
typedef $$DownloadCollectionsTableCreateCompanionBuilder =
    DownloadCollectionsCompanion Function({
      required String kind,
      required String refId,
      required String title,
      required String metaJson,
      required String status,
      Value<String?> blockedReason,
      Value<String?> detailJson,
      Value<String?> quality,
      required DateTime requestedAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });
typedef $$DownloadCollectionsTableUpdateCompanionBuilder =
    DownloadCollectionsCompanion Function({
      Value<String> kind,
      Value<String> refId,
      Value<String> title,
      Value<String> metaJson,
      Value<String> status,
      Value<String?> blockedReason,
      Value<String?> detailJson,
      Value<String?> quality,
      Value<DateTime> requestedAt,
      Value<DateTime?> resolvedAt,
      Value<int> rowid,
    });

class $$DownloadCollectionsTableFilterComposer
    extends Composer<_$StateDatabase, $DownloadCollectionsTable> {
  $$DownloadCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metaJson => $composableBuilder(
    column: $table.metaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockedReason => $composableBuilder(
    column: $table.blockedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadCollectionsTableOrderingComposer
    extends Composer<_$StateDatabase, $DownloadCollectionsTable> {
  $$DownloadCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metaJson => $composableBuilder(
    column: $table.metaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockedReason => $composableBuilder(
    column: $table.blockedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadCollectionsTableAnnotationComposer
    extends Composer<_$StateDatabase, $DownloadCollectionsTable> {
  $$DownloadCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get metaJson =>
      $composableBuilder(column: $table.metaJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get blockedReason => $composableBuilder(
    column: $table.blockedReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get detailJson => $composableBuilder(
    column: $table.detailJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );
}

class $$DownloadCollectionsTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $DownloadCollectionsTable,
          DownloadCollection,
          $$DownloadCollectionsTableFilterComposer,
          $$DownloadCollectionsTableOrderingComposer,
          $$DownloadCollectionsTableAnnotationComposer,
          $$DownloadCollectionsTableCreateCompanionBuilder,
          $$DownloadCollectionsTableUpdateCompanionBuilder,
          (
            DownloadCollection,
            BaseReferences<
              _$StateDatabase,
              $DownloadCollectionsTable,
              DownloadCollection
            >,
          ),
          DownloadCollection,
          PrefetchHooks Function()
        > {
  $$DownloadCollectionsTableTableManager(
    _$StateDatabase db,
    $DownloadCollectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadCollectionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DownloadCollectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> metaJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> blockedReason = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadCollectionsCompanion(
                kind: kind,
                refId: refId,
                title: title,
                metaJson: metaJson,
                status: status,
                blockedReason: blockedReason,
                detailJson: detailJson,
                quality: quality,
                requestedAt: requestedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String refId,
                required String title,
                required String metaJson,
                required String status,
                Value<String?> blockedReason = const Value.absent(),
                Value<String?> detailJson = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                required DateTime requestedAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadCollectionsCompanion.insert(
                kind: kind,
                refId: refId,
                title: title,
                metaJson: metaJson,
                status: status,
                blockedReason: blockedReason,
                detailJson: detailJson,
                quality: quality,
                requestedAt: requestedAt,
                resolvedAt: resolvedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadCollectionsTable, DownloadCollection>(
                    table,
                  ),
                  BaseReferences<
                    _$StateDatabase,
                    $DownloadCollectionsTable,
                    DownloadCollection
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadCollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $DownloadCollectionsTable,
      DownloadCollection,
      $$DownloadCollectionsTableFilterComposer,
      $$DownloadCollectionsTableOrderingComposer,
      $$DownloadCollectionsTableAnnotationComposer,
      $$DownloadCollectionsTableCreateCompanionBuilder,
      $$DownloadCollectionsTableUpdateCompanionBuilder,
      (
        DownloadCollection,
        BaseReferences<
          _$StateDatabase,
          $DownloadCollectionsTable,
          DownloadCollection
        >,
      ),
      DownloadCollection,
      PrefetchHooks Function()
    >;
typedef $$DownloadItemsTableCreateCompanionBuilder =
    DownloadItemsCompanion Function({
      required String itemKey,
      required MediaType mediaType,
      required String metaJson,
      Value<String?> quality,
      required DownloadStatus status,
      Value<String?> waitingFor,
      Value<String?> taskId,
      Value<String?> downloadUrl,
      Value<String?> etag,
      Value<int?> expectedBytes,
      Value<int> receivedBytes,
      Value<int?> sizeBytes,
      Value<String?> relativePath,
      Value<String?> failureCode,
      Value<int> attempts,
      Value<bool> serverConfirmed,
      required DateTime requestedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> rowid,
    });
typedef $$DownloadItemsTableUpdateCompanionBuilder =
    DownloadItemsCompanion Function({
      Value<String> itemKey,
      Value<MediaType> mediaType,
      Value<String> metaJson,
      Value<String?> quality,
      Value<DownloadStatus> status,
      Value<String?> waitingFor,
      Value<String?> taskId,
      Value<String?> downloadUrl,
      Value<String?> etag,
      Value<int?> expectedBytes,
      Value<int> receivedBytes,
      Value<int?> sizeBytes,
      Value<String?> relativePath,
      Value<String?> failureCode,
      Value<int> attempts,
      Value<bool> serverConfirmed,
      Value<DateTime> requestedAt,
      Value<DateTime?> completedAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> rowid,
    });

final class $$DownloadItemsTableReferences
    extends BaseReferences<_$StateDatabase, $DownloadItemsTable, DownloadItem> {
  $$DownloadItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $DownloadMembershipTable,
    List<DownloadMembershipData>
  >
  _downloadMembershipRefsTable(_$StateDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.downloadMembership,
        aliasName: 'download_items__item_key__download_membership__item_key',
      );

  $$DownloadMembershipTableProcessedTableManager get downloadMembershipRefs {
    final manager =
        $$DownloadMembershipTableTableManager(
          $_db,
          $_db.downloadMembership,
        ).filter(
          (f) => f.itemKey.itemKey.sqlEquals($_itemColumn<String>('item_key')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _downloadMembershipRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DownloadItemsTableFilterComposer
    extends Composer<_$StateDatabase, $DownloadItemsTable> {
  $$DownloadItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MediaType, MediaType, String> get mediaType =>
      $composableBuilder(
        column: $table.mediaType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get metaJson => $composableBuilder(
    column: $table.metaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadStatus, DownloadStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get waitingFor => $composableBuilder(
    column: $table.waitingFor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedBytes => $composableBuilder(
    column: $table.expectedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get serverConfirmed => $composableBuilder(
    column: $table.serverConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> downloadMembershipRefs(
    Expression<bool> Function($$DownloadMembershipTableFilterComposer f) f,
  ) {
    final $$DownloadMembershipTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemKey,
      referencedTable: $db.downloadMembership,
      getReferencedColumn: (t) => t.itemKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadMembershipTableFilterComposer(
            $db: $db,
            $table: $db.downloadMembership,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DownloadItemsTableOrderingComposer
    extends Composer<_$StateDatabase, $DownloadItemsTable> {
  $$DownloadItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metaJson => $composableBuilder(
    column: $table.metaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get waitingFor => $composableBuilder(
    column: $table.waitingFor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedBytes => $composableBuilder(
    column: $table.expectedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get serverConfirmed => $composableBuilder(
    column: $table.serverConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadItemsTableAnnotationComposer
    extends Composer<_$StateDatabase, $DownloadItemsTable> {
  $$DownloadItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<MediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get metaJson =>
      $composableBuilder(column: $table.metaJson, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get waitingFor => $composableBuilder(
    column: $table.waitingFor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<String> get downloadUrl => $composableBuilder(
    column: $table.downloadUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<int> get expectedBytes => $composableBuilder(
    column: $table.expectedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get receivedBytes => $composableBuilder(
    column: $table.receivedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<bool> get serverConfirmed => $composableBuilder(
    column: $table.serverConfirmed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  Expression<T> downloadMembershipRefs<T extends Object>(
    Expression<T> Function($$DownloadMembershipTableAnnotationComposer a) f,
  ) {
    final $$DownloadMembershipTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.itemKey,
          referencedTable: $db.downloadMembership,
          getReferencedColumn: (t) => t.itemKey,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DownloadMembershipTableAnnotationComposer(
                $db: $db,
                $table: $db.downloadMembership,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$DownloadItemsTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $DownloadItemsTable,
          DownloadItem,
          $$DownloadItemsTableFilterComposer,
          $$DownloadItemsTableOrderingComposer,
          $$DownloadItemsTableAnnotationComposer,
          $$DownloadItemsTableCreateCompanionBuilder,
          $$DownloadItemsTableUpdateCompanionBuilder,
          (DownloadItem, $$DownloadItemsTableReferences),
          DownloadItem,
          PrefetchHooks Function({bool downloadMembershipRefs})
        > {
  $$DownloadItemsTableTableManager(
    _$StateDatabase db,
    $DownloadItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemKey = const Value.absent(),
                Value<MediaType> mediaType = const Value.absent(),
                Value<String> metaJson = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<DownloadStatus> status = const Value.absent(),
                Value<String?> waitingFor = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> downloadUrl = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int?> expectedBytes = const Value.absent(),
                Value<int> receivedBytes = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> serverConfirmed = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadItemsCompanion(
                itemKey: itemKey,
                mediaType: mediaType,
                metaJson: metaJson,
                quality: quality,
                status: status,
                waitingFor: waitingFor,
                taskId: taskId,
                downloadUrl: downloadUrl,
                etag: etag,
                expectedBytes: expectedBytes,
                receivedBytes: receivedBytes,
                sizeBytes: sizeBytes,
                relativePath: relativePath,
                failureCode: failureCode,
                attempts: attempts,
                serverConfirmed: serverConfirmed,
                requestedAt: requestedAt,
                completedAt: completedAt,
                lastPlayedAt: lastPlayedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemKey,
                required MediaType mediaType,
                required String metaJson,
                Value<String?> quality = const Value.absent(),
                required DownloadStatus status,
                Value<String?> waitingFor = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> downloadUrl = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int?> expectedBytes = const Value.absent(),
                Value<int> receivedBytes = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> relativePath = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> serverConfirmed = const Value.absent(),
                required DateTime requestedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadItemsCompanion.insert(
                itemKey: itemKey,
                mediaType: mediaType,
                metaJson: metaJson,
                quality: quality,
                status: status,
                waitingFor: waitingFor,
                taskId: taskId,
                downloadUrl: downloadUrl,
                etag: etag,
                expectedBytes: expectedBytes,
                receivedBytes: receivedBytes,
                sizeBytes: sizeBytes,
                relativePath: relativePath,
                failureCode: failureCode,
                attempts: attempts,
                serverConfirmed: serverConfirmed,
                requestedAt: requestedAt,
                completedAt: completedAt,
                lastPlayedAt: lastPlayedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadItemsTable, DownloadItem>(table),
                  $$DownloadItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({downloadMembershipRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (downloadMembershipRefs) db.downloadMembership,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (downloadMembershipRefs)
                    await $_getPrefetchedDataByColumns<
                      DownloadItem,
                      $DownloadItemsTable,
                      DownloadMembershipData,
                      $DownloadMembershipTable
                    >(
                      currentTable: table,
                      referencedTable: $$DownloadItemsTableReferences
                          ._downloadMembershipRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DownloadItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).downloadMembershipRefs,
                      currentColumn: 'item_key',
                      referencedColumn: 'item_key',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DownloadItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $DownloadItemsTable,
      DownloadItem,
      $$DownloadItemsTableFilterComposer,
      $$DownloadItemsTableOrderingComposer,
      $$DownloadItemsTableAnnotationComposer,
      $$DownloadItemsTableCreateCompanionBuilder,
      $$DownloadItemsTableUpdateCompanionBuilder,
      (DownloadItem, $$DownloadItemsTableReferences),
      DownloadItem,
      PrefetchHooks Function({bool downloadMembershipRefs})
    >;
typedef $$DownloadMembershipTableCreateCompanionBuilder =
    DownloadMembershipCompanion Function({
      required String kind,
      required String refId,
      required String itemKey,
      required int position,
      Value<int> rowid,
    });
typedef $$DownloadMembershipTableUpdateCompanionBuilder =
    DownloadMembershipCompanion Function({
      Value<String> kind,
      Value<String> refId,
      Value<String> itemKey,
      Value<int> position,
      Value<int> rowid,
    });

final class $$DownloadMembershipTableReferences
    extends
        BaseReferences<
          _$StateDatabase,
          $DownloadMembershipTable,
          DownloadMembershipData
        > {
  $$DownloadMembershipTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DownloadItemsTable _itemKeyTable(_$StateDatabase db) => db
      .downloadItems
      .createAlias('download_membership__item_key__download_items__item_key');

  $$DownloadItemsTableProcessedTableManager get itemKey {
    final $_column = $_itemColumn<String>('item_key')!;

    final manager = $$DownloadItemsTableTableManager(
      $_db,
      $_db.downloadItems,
    ).filter((f) => f.itemKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DownloadMembershipTableFilterComposer
    extends Composer<_$StateDatabase, $DownloadMembershipTable> {
  $$DownloadMembershipTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$DownloadItemsTableFilterComposer get itemKey {
    final $$DownloadItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemKey,
      referencedTable: $db.downloadItems,
      getReferencedColumn: (t) => t.itemKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadItemsTableFilterComposer(
            $db: $db,
            $table: $db.downloadItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadMembershipTableOrderingComposer
    extends Composer<_$StateDatabase, $DownloadMembershipTable> {
  $$DownloadMembershipTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$DownloadItemsTableOrderingComposer get itemKey {
    final $$DownloadItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemKey,
      referencedTable: $db.downloadItems,
      getReferencedColumn: (t) => t.itemKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadItemsTableOrderingComposer(
            $db: $db,
            $table: $db.downloadItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadMembershipTableAnnotationComposer
    extends Composer<_$StateDatabase, $DownloadMembershipTable> {
  $$DownloadMembershipTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$DownloadItemsTableAnnotationComposer get itemKey {
    final $$DownloadItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemKey,
      referencedTable: $db.downloadItems,
      getReferencedColumn: (t) => t.itemKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadMembershipTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $DownloadMembershipTable,
          DownloadMembershipData,
          $$DownloadMembershipTableFilterComposer,
          $$DownloadMembershipTableOrderingComposer,
          $$DownloadMembershipTableAnnotationComposer,
          $$DownloadMembershipTableCreateCompanionBuilder,
          $$DownloadMembershipTableUpdateCompanionBuilder,
          (DownloadMembershipData, $$DownloadMembershipTableReferences),
          DownloadMembershipData,
          PrefetchHooks Function({bool itemKey})
        > {
  $$DownloadMembershipTableTableManager(
    _$StateDatabase db,
    $DownloadMembershipTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadMembershipTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadMembershipTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadMembershipTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadMembershipCompanion(
                kind: kind,
                refId: refId,
                itemKey: itemKey,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String refId,
                required String itemKey,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => DownloadMembershipCompanion.insert(
                kind: kind,
                refId: refId,
                itemKey: itemKey,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadMembershipTable, DownloadMembershipData>(
                    table,
                  ),
                  $$DownloadMembershipTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemKey = false}) {
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
                    if (itemKey) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemKey,
                        referencedTable: $$DownloadMembershipTableReferences
                            ._itemKeyTable(db),
                        referencedColumn: $$DownloadMembershipTableReferences
                            ._itemKeyTable(db)
                            .itemKey,
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

typedef $$DownloadMembershipTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $DownloadMembershipTable,
      DownloadMembershipData,
      $$DownloadMembershipTableFilterComposer,
      $$DownloadMembershipTableOrderingComposer,
      $$DownloadMembershipTableAnnotationComposer,
      $$DownloadMembershipTableCreateCompanionBuilder,
      $$DownloadMembershipTableUpdateCompanionBuilder,
      (DownloadMembershipData, $$DownloadMembershipTableReferences),
      DownloadMembershipData,
      PrefetchHooks Function({bool itemKey})
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  required String opType,
  required String entityKey,
  required String payloadJson,
  required DateTime createdAt,
  Value<int> attempts,
  Value<DateTime?> nextAttemptAt,
  Value<String?> lastError,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> seq,
  Value<String> opType,
  Value<String> entityKey,
  Value<String> payloadJson,
  Value<DateTime> createdAt,
  Value<int> attempts,
  Value<DateTime?> nextAttemptAt,
  Value<String?> lastError,
});

class $$OutboxTableFilterComposer
    extends Composer<_$StateDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$StateDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$StateDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get entityKey =>
      $composableBuilder(column: $table.entityKey, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (
            OutboxData,
            BaseReferences<_$StateDatabase, $OutboxTable, OutboxData>,
          ),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$StateDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String> entityKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxCompanion(
                seq: seq,
                opType: opType,
                entityKey: entityKey,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String opType,
                required String entityKey,
                required String payloadJson,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
              }) => OutboxCompanion.insert(
                seq: seq,
                opType: opType,
                entityKey: entityKey,
                payloadJson: payloadJson,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$StateDatabase, $OutboxTable, OutboxData>(
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

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$StateDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$PlaySessionsTableCreateCompanionBuilder =
    PlaySessionsCompanion Function({
      required String sessionId,
      required String queueItemId,
      required String playbackId,
      required String metaJson,
      required DateTime playedAt,
      Value<int> listenedMs,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaySessionsTableUpdateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<String> sessionId,
      Value<String> queueItemId,
      Value<String> playbackId,
      Value<String> metaJson,
      Value<DateTime> playedAt,
      Value<int> listenedMs,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PlaySessionsTableFilterComposer
    extends Composer<_$StateDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get queueItemId => $composableBuilder(
    column: $table.queueItemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playbackId => $composableBuilder(
    column: $table.playbackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metaJson => $composableBuilder(
    column: $table.metaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlaySessionsTableOrderingComposer
    extends Composer<_$StateDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get queueItemId => $composableBuilder(
    column: $table.queueItemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playbackId => $composableBuilder(
    column: $table.playbackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metaJson => $composableBuilder(
    column: $table.metaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaySessionsTableAnnotationComposer
    extends Composer<_$StateDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get queueItemId => $composableBuilder(
    column: $table.queueItemId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playbackId => $composableBuilder(
    column: $table.playbackId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metaJson =>
      $composableBuilder(column: $table.metaJson, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get listenedMs => $composableBuilder(
    column: $table.listenedMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlaySessionsTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $PlaySessionsTable,
          PlaySession,
          $$PlaySessionsTableFilterComposer,
          $$PlaySessionsTableOrderingComposer,
          $$PlaySessionsTableAnnotationComposer,
          $$PlaySessionsTableCreateCompanionBuilder,
          $$PlaySessionsTableUpdateCompanionBuilder,
          (
            PlaySession,
            BaseReferences<_$StateDatabase, $PlaySessionsTable, PlaySession>,
          ),
          PlaySession,
          PrefetchHooks Function()
        > {
  $$PlaySessionsTableTableManager(_$StateDatabase db, $PlaySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> queueItemId = const Value.absent(),
                Value<String> playbackId = const Value.absent(),
                Value<String> metaJson = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> listenedMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaySessionsCompanion(
                sessionId: sessionId,
                queueItemId: queueItemId,
                playbackId: playbackId,
                metaJson: metaJson,
                playedAt: playedAt,
                listenedMs: listenedMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String queueItemId,
                required String playbackId,
                required String metaJson,
                required DateTime playedAt,
                Value<int> listenedMs = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaySessionsCompanion.insert(
                sessionId: sessionId,
                queueItemId: queueItemId,
                playbackId: playbackId,
                metaJson: metaJson,
                playedAt: playedAt,
                listenedMs: listenedMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaySessionsTable, PlaySession>(table),
                  BaseReferences<
                    _$StateDatabase,
                    $PlaySessionsTable,
                    PlaySession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $PlaySessionsTable,
      PlaySession,
      $$PlaySessionsTableFilterComposer,
      $$PlaySessionsTableOrderingComposer,
      $$PlaySessionsTableAnnotationComposer,
      $$PlaySessionsTableCreateCompanionBuilder,
      $$PlaySessionsTableUpdateCompanionBuilder,
      (
        PlaySession,
        BaseReferences<_$StateDatabase, $PlaySessionsTable, PlaySession>,
      ),
      PlaySession,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder =
    SearchHistoryCompanion Function({
      required String query,
      required DateTime lastUsedAt,
      Value<int> rowid,
    });
typedef $$SearchHistoryTableUpdateCompanionBuilder =
    SearchHistoryCompanion Function({
      Value<String> query,
      Value<DateTime> lastUsedAt,
      Value<int> rowid,
    });

class $$SearchHistoryTableFilterComposer
    extends Composer<_$StateDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchHistoryTableOrderingComposer
    extends Composer<_$StateDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchHistoryTableAnnotationComposer
    extends Composer<_$StateDatabase, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$StateDatabase,
          $SearchHistoryTable,
          SearchHistoryData,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (
            SearchHistoryData,
            BaseReferences<
              _$StateDatabase,
              $SearchHistoryTable,
              SearchHistoryData
            >,
          ),
          SearchHistoryData,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(
    _$StateDatabase db,
    $SearchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryCompanion(
                query: query,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchHistoryCompanion.insert(
                query: query,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchHistoryTable, SearchHistoryData>(table),
                  BaseReferences<
                    _$StateDatabase,
                    $SearchHistoryTable,
                    SearchHistoryData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$StateDatabase,
      $SearchHistoryTable,
      SearchHistoryData,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (
        SearchHistoryData,
        BaseReferences<_$StateDatabase, $SearchHistoryTable, SearchHistoryData>,
      ),
      SearchHistoryData,
      PrefetchHooks Function()
    >;

class $StateDatabaseManager {
  final _$StateDatabase _db;
  $StateDatabaseManager(this._db);
  $$DeviceSettingsTableTableManager get deviceSettings =>
      $$DeviceSettingsTableTableManager(_db, _db.deviceSettings);
  $$QueueSnapshotTableTableManager get queueSnapshot =>
      $$QueueSnapshotTableTableManager(_db, _db.queueSnapshot);
  $$QueueMetaTableTableManager get queueMeta =>
      $$QueueMetaTableTableManager(_db, _db.queueMeta);
  $$DownloadCollectionsTableTableManager get downloadCollections =>
      $$DownloadCollectionsTableTableManager(_db, _db.downloadCollections);
  $$DownloadItemsTableTableManager get downloadItems =>
      $$DownloadItemsTableTableManager(_db, _db.downloadItems);
  $$DownloadMembershipTableTableManager get downloadMembership =>
      $$DownloadMembershipTableTableManager(_db, _db.downloadMembership);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$PlaySessionsTableTableManager get playSessions =>
      $$PlaySessionsTableTableManager(_db, _db.playSessions);
  $$SearchHistoryTableTableManager get searchHistory =>
      $$SearchHistoryTableTableManager(_db, _db.searchHistory);
}
