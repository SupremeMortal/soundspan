// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  @override
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userDisplayNameMeta = const VerificationMeta(
    'userDisplayName',
  );
  @override
  late final GeneratedColumn<String> userDisplayName = GeneratedColumn<String>(
    'user_display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AuthKind, String> authKind =
      GeneratedColumn<String>(
        'auth_kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AuthKind>($ProfilesTable.$converterauthKind);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialCreatedAtMeta =
      const VerificationMeta('credentialCreatedAt');
  @override
  late final GeneratedColumn<DateTime> credentialCreatedAt =
      GeneratedColumn<DateTime>(
        'credential_created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _credentialExpiresAtMeta =
      const VerificationMeta('credentialExpiresAt');
  @override
  late final GeneratedColumn<DateTime> credentialExpiresAt =
      GeneratedColumn<DateTime>(
        'credential_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<String> serverVersion = GeneratedColumn<String>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _featuresMeta = const VerificationMeta(
    'features',
  );
  @override
  late final GeneratedColumn<String> features = GeneratedColumn<String>(
    'features',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _featuresFetchedAtMeta = const VerificationMeta(
    'featuresFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> featuresFetchedAt =
      GeneratedColumn<DateTime>(
        'features_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<ProfileState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProfileState>($ProfilesTable.$converterstate);
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
  List<GeneratedColumn> get $columns => [
    id,
    baseUrl,
    displayName,
    userId,
    username,
    userDisplayName,
    role,
    authKind,
    deviceId,
    credentialCreatedAt,
    credentialExpiresAt,
    serverVersion,
    features,
    featuresFetchedAt,
    state,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('user_display_name')) {
      context.handle(
        _userDisplayNameMeta,
        userDisplayName.isAcceptableOrUnknown(
          data['user_display_name']!,
          _userDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('credential_created_at')) {
      context.handle(
        _credentialCreatedAtMeta,
        credentialCreatedAt.isAcceptableOrUnknown(
          data['credential_created_at']!,
          _credentialCreatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialCreatedAtMeta);
    }
    if (data.containsKey('credential_expires_at')) {
      context.handle(
        _credentialExpiresAtMeta,
        credentialExpiresAt.isAcceptableOrUnknown(
          data['credential_expires_at']!,
          _credentialExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    if (data.containsKey('features')) {
      context.handle(
        _featuresMeta,
        features.isAcceptableOrUnknown(data['features']!, _featuresMeta),
      );
    }
    if (data.containsKey('features_fetched_at')) {
      context.handle(
        _featuresFetchedAtMeta,
        featuresFetchedAt.isAcceptableOrUnknown(
          data['features_fetched_at']!,
          _featuresFetchedAtMeta,
        ),
      );
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {baseUrl, userId},
  ];
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      userDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_display_name'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      authKind: $ProfilesTable.$converterauthKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}auth_kind'],
        )!,
      ),
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      credentialCreatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}credential_created_at'],
      )!,
      credentialExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}credential_expires_at'],
      ),
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_version'],
      ),
      features: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}features'],
      ),
      featuresFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}features_fetched_at'],
      ),
      state: $ProfilesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AuthKind, String, String> $converterauthKind =
      const EnumNameConverter<AuthKind>(AuthKind.values);
  static JsonTypeConverter2<ProfileState, String, String> $converterstate =
      const EnumNameConverter<ProfileState>(ProfileState.values);
}

class Profile extends DataClass implements Insertable<Profile> {
  /// The profile id, a client-generated UUID.
  final String id;

  /// The server's base URL, including any reverse-proxy path prefix.
  final String baseUrl;

  /// The name the user gave the server.
  final String displayName;

  /// The server's id of the signed-in user.
  final String userId;

  /// The signed-in user's username.
  final String username;

  /// The signed-in user's display name, if they have one.
  final String? userDisplayName;

  /// The signed-in user's role on the server.
  final String role;

  /// How the credential was obtained.
  final AuthKind authKind;

  /// The playback device id this client sends to the server.
  final String deviceId;

  /// When the credential was issued.
  final DateTime credentialCreatedAt;

  /// When the credential expires, if it does.
  final DateTime? credentialExpiresAt;

  /// The server version seen at the last capability refresh.
  final String? serverVersion;

  /// The server's feature flags, JSON-encoded.
  final String? features;

  /// When [features] was fetched.
  final DateTime? featuresFetchedAt;

  /// Whether the profile is signed in.
  final ProfileState state;

  /// When the profile was last the active one.
  final DateTime lastUsedAt;
  const Profile({
    required this.id,
    required this.baseUrl,
    required this.displayName,
    required this.userId,
    required this.username,
    this.userDisplayName,
    required this.role,
    required this.authKind,
    required this.deviceId,
    required this.credentialCreatedAt,
    this.credentialExpiresAt,
    this.serverVersion,
    this.features,
    this.featuresFetchedAt,
    required this.state,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['base_url'] = Variable<String>(baseUrl);
    map['display_name'] = Variable<String>(displayName);
    map['user_id'] = Variable<String>(userId);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || userDisplayName != null) {
      map['user_display_name'] = Variable<String>(userDisplayName);
    }
    map['role'] = Variable<String>(role);
    {
      map['auth_kind'] = Variable<String>(
        $ProfilesTable.$converterauthKind.toSql(authKind),
      );
    }
    map['device_id'] = Variable<String>(deviceId);
    map['credential_created_at'] = Variable<DateTime>(credentialCreatedAt);
    if (!nullToAbsent || credentialExpiresAt != null) {
      map['credential_expires_at'] = Variable<DateTime>(credentialExpiresAt);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<String>(serverVersion);
    }
    if (!nullToAbsent || features != null) {
      map['features'] = Variable<String>(features);
    }
    if (!nullToAbsent || featuresFetchedAt != null) {
      map['features_fetched_at'] = Variable<DateTime>(featuresFetchedAt);
    }
    {
      map['state'] = Variable<String>(
        $ProfilesTable.$converterstate.toSql(state),
      );
    }
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      baseUrl: Value(baseUrl),
      displayName: Value(displayName),
      userId: Value(userId),
      username: Value(username),
      userDisplayName: userDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(userDisplayName),
      role: Value(role),
      authKind: Value(authKind),
      deviceId: Value(deviceId),
      credentialCreatedAt: Value(credentialCreatedAt),
      credentialExpiresAt: credentialExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialExpiresAt),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      features: features == null && nullToAbsent
          ? const Value.absent()
          : Value(features),
      featuresFetchedAt: featuresFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(featuresFetchedAt),
      state: Value(state),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      baseUrl: serializer.fromJson<String>(json['baseUrl']),
      displayName: serializer.fromJson<String>(json['displayName']),
      userId: serializer.fromJson<String>(json['userId']),
      username: serializer.fromJson<String>(json['username']),
      userDisplayName: serializer.fromJson<String?>(json['userDisplayName']),
      role: serializer.fromJson<String>(json['role']),
      authKind: $ProfilesTable.$converterauthKind.fromJson(
        serializer.fromJson<String>(json['authKind']),
      ),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      credentialCreatedAt: serializer.fromJson<DateTime>(
        json['credentialCreatedAt'],
      ),
      credentialExpiresAt: serializer.fromJson<DateTime?>(
        json['credentialExpiresAt'],
      ),
      serverVersion: serializer.fromJson<String?>(json['serverVersion']),
      features: serializer.fromJson<String?>(json['features']),
      featuresFetchedAt: serializer.fromJson<DateTime?>(
        json['featuresFetchedAt'],
      ),
      state: $ProfilesTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'baseUrl': serializer.toJson<String>(baseUrl),
      'displayName': serializer.toJson<String>(displayName),
      'userId': serializer.toJson<String>(userId),
      'username': serializer.toJson<String>(username),
      'userDisplayName': serializer.toJson<String?>(userDisplayName),
      'role': serializer.toJson<String>(role),
      'authKind': serializer.toJson<String>(
        $ProfilesTable.$converterauthKind.toJson(authKind),
      ),
      'deviceId': serializer.toJson<String>(deviceId),
      'credentialCreatedAt': serializer.toJson<DateTime>(credentialCreatedAt),
      'credentialExpiresAt': serializer.toJson<DateTime?>(credentialExpiresAt),
      'serverVersion': serializer.toJson<String?>(serverVersion),
      'features': serializer.toJson<String?>(features),
      'featuresFetchedAt': serializer.toJson<DateTime?>(featuresFetchedAt),
      'state': serializer.toJson<String>(
        $ProfilesTable.$converterstate.toJson(state),
      ),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  Profile copyWith({
    String? id,
    String? baseUrl,
    String? displayName,
    String? userId,
    String? username,
    Value<String?> userDisplayName = const Value.absent(),
    String? role,
    AuthKind? authKind,
    String? deviceId,
    DateTime? credentialCreatedAt,
    Value<DateTime?> credentialExpiresAt = const Value.absent(),
    Value<String?> serverVersion = const Value.absent(),
    Value<String?> features = const Value.absent(),
    Value<DateTime?> featuresFetchedAt = const Value.absent(),
    ProfileState? state,
    DateTime? lastUsedAt,
  }) => Profile(
    id: id ?? this.id,
    baseUrl: baseUrl ?? this.baseUrl,
    displayName: displayName ?? this.displayName,
    userId: userId ?? this.userId,
    username: username ?? this.username,
    userDisplayName: userDisplayName.present
        ? userDisplayName.value
        : this.userDisplayName,
    role: role ?? this.role,
    authKind: authKind ?? this.authKind,
    deviceId: deviceId ?? this.deviceId,
    credentialCreatedAt: credentialCreatedAt ?? this.credentialCreatedAt,
    credentialExpiresAt: credentialExpiresAt.present
        ? credentialExpiresAt.value
        : this.credentialExpiresAt,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
    features: features.present ? features.value : this.features,
    featuresFetchedAt: featuresFetchedAt.present
        ? featuresFetchedAt.value
        : this.featuresFetchedAt,
    state: state ?? this.state,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      userDisplayName: data.userDisplayName.present
          ? data.userDisplayName.value
          : this.userDisplayName,
      role: data.role.present ? data.role.value : this.role,
      authKind: data.authKind.present ? data.authKind.value : this.authKind,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      credentialCreatedAt: data.credentialCreatedAt.present
          ? data.credentialCreatedAt.value
          : this.credentialCreatedAt,
      credentialExpiresAt: data.credentialExpiresAt.present
          ? data.credentialExpiresAt.value
          : this.credentialExpiresAt,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      features: data.features.present ? data.features.value : this.features,
      featuresFetchedAt: data.featuresFetchedAt.present
          ? data.featuresFetchedAt.value
          : this.featuresFetchedAt,
      state: data.state.present ? data.state.value : this.state,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('displayName: $displayName, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('userDisplayName: $userDisplayName, ')
          ..write('role: $role, ')
          ..write('authKind: $authKind, ')
          ..write('deviceId: $deviceId, ')
          ..write('credentialCreatedAt: $credentialCreatedAt, ')
          ..write('credentialExpiresAt: $credentialExpiresAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('features: $features, ')
          ..write('featuresFetchedAt: $featuresFetchedAt, ')
          ..write('state: $state, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseUrl,
    displayName,
    userId,
    username,
    userDisplayName,
    role,
    authKind,
    deviceId,
    credentialCreatedAt,
    credentialExpiresAt,
    serverVersion,
    features,
    featuresFetchedAt,
    state,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.baseUrl == this.baseUrl &&
          other.displayName == this.displayName &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.userDisplayName == this.userDisplayName &&
          other.role == this.role &&
          other.authKind == this.authKind &&
          other.deviceId == this.deviceId &&
          other.credentialCreatedAt == this.credentialCreatedAt &&
          other.credentialExpiresAt == this.credentialExpiresAt &&
          other.serverVersion == this.serverVersion &&
          other.features == this.features &&
          other.featuresFetchedAt == this.featuresFetchedAt &&
          other.state == this.state &&
          other.lastUsedAt == this.lastUsedAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> baseUrl;
  final Value<String> displayName;
  final Value<String> userId;
  final Value<String> username;
  final Value<String?> userDisplayName;
  final Value<String> role;
  final Value<AuthKind> authKind;
  final Value<String> deviceId;
  final Value<DateTime> credentialCreatedAt;
  final Value<DateTime?> credentialExpiresAt;
  final Value<String?> serverVersion;
  final Value<String?> features;
  final Value<DateTime?> featuresFetchedAt;
  final Value<ProfileState> state;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.displayName = const Value.absent(),
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.userDisplayName = const Value.absent(),
    this.role = const Value.absent(),
    this.authKind = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.credentialCreatedAt = const Value.absent(),
    this.credentialExpiresAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.features = const Value.absent(),
    this.featuresFetchedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String baseUrl,
    required String displayName,
    required String userId,
    required String username,
    this.userDisplayName = const Value.absent(),
    required String role,
    required AuthKind authKind,
    required String deviceId,
    required DateTime credentialCreatedAt,
    this.credentialExpiresAt = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.features = const Value.absent(),
    this.featuresFetchedAt = const Value.absent(),
    required ProfileState state,
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       baseUrl = Value(baseUrl),
       displayName = Value(displayName),
       userId = Value(userId),
       username = Value(username),
       role = Value(role),
       authKind = Value(authKind),
       deviceId = Value(deviceId),
       credentialCreatedAt = Value(credentialCreatedAt),
       state = Value(state),
       lastUsedAt = Value(lastUsedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? baseUrl,
    Expression<String>? displayName,
    Expression<String>? userId,
    Expression<String>? username,
    Expression<String>? userDisplayName,
    Expression<String>? role,
    Expression<String>? authKind,
    Expression<String>? deviceId,
    Expression<DateTime>? credentialCreatedAt,
    Expression<DateTime>? credentialExpiresAt,
    Expression<String>? serverVersion,
    Expression<String>? features,
    Expression<DateTime>? featuresFetchedAt,
    Expression<String>? state,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseUrl != null) 'base_url': baseUrl,
      if (displayName != null) 'display_name': displayName,
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (userDisplayName != null) 'user_display_name': userDisplayName,
      if (role != null) 'role': role,
      if (authKind != null) 'auth_kind': authKind,
      if (deviceId != null) 'device_id': deviceId,
      if (credentialCreatedAt != null)
        'credential_created_at': credentialCreatedAt,
      if (credentialExpiresAt != null)
        'credential_expires_at': credentialExpiresAt,
      if (serverVersion != null) 'server_version': serverVersion,
      if (features != null) 'features': features,
      if (featuresFetchedAt != null) 'features_fetched_at': featuresFetchedAt,
      if (state != null) 'state': state,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? baseUrl,
    Value<String>? displayName,
    Value<String>? userId,
    Value<String>? username,
    Value<String?>? userDisplayName,
    Value<String>? role,
    Value<AuthKind>? authKind,
    Value<String>? deviceId,
    Value<DateTime>? credentialCreatedAt,
    Value<DateTime?>? credentialExpiresAt,
    Value<String?>? serverVersion,
    Value<String?>? features,
    Value<DateTime?>? featuresFetchedAt,
    Value<ProfileState>? state,
    Value<DateTime>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      displayName: displayName ?? this.displayName,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      role: role ?? this.role,
      authKind: authKind ?? this.authKind,
      deviceId: deviceId ?? this.deviceId,
      credentialCreatedAt: credentialCreatedAt ?? this.credentialCreatedAt,
      credentialExpiresAt: credentialExpiresAt ?? this.credentialExpiresAt,
      serverVersion: serverVersion ?? this.serverVersion,
      features: features ?? this.features,
      featuresFetchedAt: featuresFetchedAt ?? this.featuresFetchedAt,
      state: state ?? this.state,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (userDisplayName.present) {
      map['user_display_name'] = Variable<String>(userDisplayName.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (authKind.present) {
      map['auth_kind'] = Variable<String>(
        $ProfilesTable.$converterauthKind.toSql(authKind.value),
      );
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (credentialCreatedAt.present) {
      map['credential_created_at'] = Variable<DateTime>(
        credentialCreatedAt.value,
      );
    }
    if (credentialExpiresAt.present) {
      map['credential_expires_at'] = Variable<DateTime>(
        credentialExpiresAt.value,
      );
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<String>(serverVersion.value);
    }
    if (features.present) {
      map['features'] = Variable<String>(features.value);
    }
    if (featuresFetchedAt.present) {
      map['features_fetched_at'] = Variable<DateTime>(featuresFetchedAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $ProfilesTable.$converterstate.toSql(state.value),
      );
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
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('displayName: $displayName, ')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('userDisplayName: $userDisplayName, ')
          ..write('role: $role, ')
          ..write('authKind: $authKind, ')
          ..write('deviceId: $deviceId, ')
          ..write('credentialCreatedAt: $credentialCreatedAt, ')
          ..write('credentialExpiresAt: $credentialExpiresAt, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('features: $features, ')
          ..write('featuresFetchedAt: $featuresFetchedAt, ')
          ..write('state: $state, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
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
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
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
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  /// The setting's key.
  final String key;

  /// The setting's value, JSON-encoded.
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
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

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
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
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
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

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
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
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles, appSettings];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  required String id,
  required String baseUrl,
  required String displayName,
  required String userId,
  required String username,
  Value<String?> userDisplayName,
  required String role,
  required AuthKind authKind,
  required String deviceId,
  required DateTime credentialCreatedAt,
  Value<DateTime?> credentialExpiresAt,
  Value<String?> serverVersion,
  Value<String?> features,
  Value<DateTime?> featuresFetchedAt,
  required ProfileState state,
  required DateTime lastUsedAt,
  Value<int> rowid,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<String> id,
  Value<String> baseUrl,
  Value<String> displayName,
  Value<String> userId,
  Value<String> username,
  Value<String?> userDisplayName,
  Value<String> role,
  Value<AuthKind> authKind,
  Value<String> deviceId,
  Value<DateTime> credentialCreatedAt,
  Value<DateTime?> credentialExpiresAt,
  Value<String?> serverVersion,
  Value<String?> features,
  Value<DateTime?> featuresFetchedAt,
  Value<ProfileState> state,
  Value<DateTime> lastUsedAt,
  Value<int> rowid,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
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

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userDisplayName => $composableBuilder(
    column: $table.userDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AuthKind, AuthKind, String> get authKind =>
      $composableBuilder(
        column: $table.authKind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get credentialCreatedAt => $composableBuilder(
    column: $table.credentialCreatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get credentialExpiresAt => $composableBuilder(
    column: $table.credentialExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get features => $composableBuilder(
    column: $table.features,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get featuresFetchedAt => $composableBuilder(
    column: $table.featuresFetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProfileState, ProfileState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
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

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userDisplayName => $composableBuilder(
    column: $table.userDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authKind => $composableBuilder(
    column: $table.authKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get credentialCreatedAt => $composableBuilder(
    column: $table.credentialCreatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get credentialExpiresAt => $composableBuilder(
    column: $table.credentialExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get features => $composableBuilder(
    column: $table.features,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get featuresFetchedAt => $composableBuilder(
    column: $table.featuresFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get userDisplayName => $composableBuilder(
    column: $table.userDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AuthKind, String> get authKind =>
      $composableBuilder(column: $table.authKind, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get credentialCreatedAt => $composableBuilder(
    column: $table.credentialCreatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get credentialExpiresAt => $composableBuilder(
    column: $table.credentialExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get features =>
      $composableBuilder(column: $table.features, builder: (column) => column);

  GeneratedColumn<DateTime> get featuresFetchedAt => $composableBuilder(
    column: $table.featuresFetchedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ProfileState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> userDisplayName = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<AuthKind> authKind = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime> credentialCreatedAt = const Value.absent(),
                Value<DateTime?> credentialExpiresAt = const Value.absent(),
                Value<String?> serverVersion = const Value.absent(),
                Value<String?> features = const Value.absent(),
                Value<DateTime?> featuresFetchedAt = const Value.absent(),
                Value<ProfileState> state = const Value.absent(),
                Value<DateTime> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                baseUrl: baseUrl,
                displayName: displayName,
                userId: userId,
                username: username,
                userDisplayName: userDisplayName,
                role: role,
                authKind: authKind,
                deviceId: deviceId,
                credentialCreatedAt: credentialCreatedAt,
                credentialExpiresAt: credentialExpiresAt,
                serverVersion: serverVersion,
                features: features,
                featuresFetchedAt: featuresFetchedAt,
                state: state,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String baseUrl,
                required String displayName,
                required String userId,
                required String username,
                Value<String?> userDisplayName = const Value.absent(),
                required String role,
                required AuthKind authKind,
                required String deviceId,
                required DateTime credentialCreatedAt,
                Value<DateTime?> credentialExpiresAt = const Value.absent(),
                Value<String?> serverVersion = const Value.absent(),
                Value<String?> features = const Value.absent(),
                Value<DateTime?> featuresFetchedAt = const Value.absent(),
                required ProfileState state,
                required DateTime lastUsedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                baseUrl: baseUrl,
                displayName: displayName,
                userId: userId,
                username: username,
                userDisplayName: userDisplayName,
                role: role,
                authKind: authKind,
                deviceId: deviceId,
                credentialCreatedAt: credentialCreatedAt,
                credentialExpiresAt: credentialExpiresAt,
                serverVersion: serverVersion,
                features: features,
                featuresFetchedAt: featuresFetchedAt,
                state: state,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, Profile>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, Profile>(
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

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
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

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
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

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
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

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>(
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

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
