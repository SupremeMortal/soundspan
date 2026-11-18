// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:drift/drift.dart' hide DatabaseOpener;
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/secret_keys.dart';
import 'package:soundspan/core/storage/app/app_database.dart' as db;
import 'package:soundspan/core/storage/app/app_settings_store.dart';
import 'package:soundspan/platform/database_opener/database_opener.dart';
import 'package:soundspan/platform/paths/paths.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/util/uuid.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The only code that reads or writes the `profiles` table and a profile's
/// secrets (doc 04, Profile Record and Secret Storage).
class ProfileRepository {
  /// Creates the repository. [newId] generates profile and device ids; it
  /// defaults to [Uuid.v4].
  new(
    this._db,
    this._secrets,
    this._paths,
    this._opener,
    this._clock, {
    String Function()? newId,
  }) : _newId = newId ?? Uuid.v4;

  final db.AppDatabase _db;
  final SecretStore _secrets;
  final AppPaths _paths;
  final DatabaseOpener _opener;
  final Clock _clock;
  final String Function() _newId;

  db.$ProfilesTable get _table => _db.profiles;

  SimpleSelectStatement<db.$ProfilesTable, db.Profile> _byId(String id) =>
      _db.select(_table)..where((t) => t.id.equals(id));

  /// Every profile, most recently used first, now and after every change.
  Stream<List<Profile>> watchAll() =>
      (_db.select(_table)..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]))
          .watch()
          .map((rows) => rows.map(profileFromRow).toList());

  /// The profile [id], or null when there is none.
  Future<Profile?> byId(String id) async {
    final row = await _byId(id).getSingleOrNull();
    return row == null ? null : profileFromRow(row);
  }

  /// Records a successful sign-in and returns the profile.
  ///
  /// A new `(baseUrl, userId)` pair creates a profile with new ids and
  /// [displayName] (default: the host of [baseUrl]). An existing pair keeps
  /// its id, device id and display name, takes the new user and credential
  /// fields, and becomes active. Either way [credentials] are stored and the
  /// profile becomes the most recently used.
  ///
  /// Throws an [ArgumentError] when [baseUrl] ends with a slash or has a
  /// query or fragment.
  Future<Profile> upsertSignedIn({
    required Uri baseUrl,
    required String userId,
    required String username,
    required String role,
    required AuthKind authKind,
    required Credentials credentials,
    required DateTime credentialCreatedAt,
    String? displayName,
    String? userDisplayName,
    DateTime? credentialExpiresAt,
  }) async {
    if (baseUrl.path.endsWith('/') || baseUrl.hasQuery || baseUrl.hasFragment) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'must not end with a slash or have a query or fragment',
      );
    }
    final url = baseUrl.toString();
    final existing =
        await (_db.select(_table)
              ..where((t) => t.baseUrl.equals(url) & t.userId.equals(userId)))
            .getSingleOrNull();
    final id = existing?.id ?? _newId();
    await writeCredentials(id, credentials);

    final now = _clock.now();
    final common = db.ProfilesCompanion(
      username: Value(username),
      userDisplayName: Value(userDisplayName),
      role: Value(role),
      authKind: Value(authKind),
      credentialCreatedAt: Value(credentialCreatedAt.toUtc()),
      credentialExpiresAt: Value(credentialExpiresAt?.toUtc()),
      state: const Value(ProfileState.active),
      lastUsedAt: Value(now),
    );
    if (existing != null) {
      await _byIdUpdate(id).write(common);
    } else {
      await _db
          .into(_table)
          .insert(
            common.copyWith(
              id: Value(id),
              baseUrl: Value(url),
              userId: Value(userId),
              displayName: Value(_nonEmpty(displayName) ?? _hostOf(baseUrl)),
              deviceId: Value(_newId()),
            ),
          );
    }
    return (await byId(id))!;
  }

  /// The stored credential of profile [id]: an API key when one is stored,
  /// else a JWT session when both tokens are stored, else null.
  Future<Credentials?> readCredentials(String id) async {
    final apiKey = await _secrets.read(SecretKeys.apiKey(id));
    if (apiKey != null) return ApiKeyCredentials(apiKey: apiKey);
    final refresh = await _secrets.read(SecretKeys.refresh(id));
    final access = await _secrets.read(SecretKeys.access(id));
    if (refresh != null && access != null) {
      return JwtCredentials(accessToken: access, refreshToken: refresh);
    }
    return null;
  }

  /// Stores [credentials] for profile [id] and removes keys of the other
  /// kind. A JWT session writes the refresh token before the access token.
  Future<void> writeCredentials(String id, Credentials credentials) async {
    switch (credentials) {
      case JwtCredentials(:final refreshToken, :final accessToken):
        await _secrets.write(SecretKeys.refresh(id), refreshToken);
        await _secrets.write(SecretKeys.access(id), accessToken);
        await _secrets.delete(SecretKeys.apiKey(id));
      case ApiKeyCredentials(:final apiKey):
        await _secrets.write(SecretKeys.apiKey(id), apiKey);
        await _secrets.delete(SecretKeys.refresh(id));
        await _secrets.delete(SecretKeys.access(id));
    }
  }

  /// Deletes the three secret keys of profile [id].
  Future<void> deleteCredentials(String id) async {
    for (final key in SecretKeys.all(id)) {
      await _secrets.delete(key);
    }
  }

  /// Sets whether profile [id] is signed in.
  Future<void> setState(String id, ProfileState state) =>
      _byIdUpdate(id).write(db.ProfilesCompanion(state: Value(state)));

  /// Marks profile [id] as used now.
  Future<void> touchLastUsed(String id) =>
      _byIdUpdate(id)
          .write(db.ProfilesCompanion(lastUsedAt: Value(_clock.now())));

  /// Renames profile [id] to [displayName], trimmed; an empty name restores
  /// the host of its base URL.
  Future<void> rename(String id, String displayName) async {
    final row = await _byId(id).getSingleOrNull();
    if (row == null) return;
    final name = _nonEmpty(displayName) ?? _hostOf(Uri.parse(row.baseUrl));
    await _byIdUpdate(id).write(db.ProfilesCompanion(displayName: Value(name)));
  }

  /// Stores what the last capability refresh of profile [id] saw.
  Future<void> updateServerInfo(
    String id, {
    String? serverVersion,
    Map<String, Object?>? features,
    DateTime? featuresFetchedAt,
  }) => _byIdUpdate(id).write(
    db.ProfilesCompanion(
      serverVersion: Value(serverVersion),
      features: Value(features == null ? null : jsonEncode(features)),
      featuresFetchedAt: Value(featuresFetchedAt?.toUtc()),
    ),
  );

  /// Stores when the credential of profile [id] expires; null for never or
  /// unknown.
  Future<void> updateCredentialExpiry(String id, DateTime? expiresAt) =>
      _byIdUpdate(id).write(
        db.ProfilesCompanion(credentialExpiresAt: Value(expiresAt?.toUtc())),
      );

  /// Deletes profile [id]: its secret keys, then its data (directory trees
  /// and the state and cache databases), then its row.
  ///
  /// Throws a [StateError] when [id] is the active profile. A failing step
  /// stops the sequence and keeps the row, so the delete can be repeated.
  Future<void> delete(String id) async {
    final active = await AppSettingsStore(_db)
        .read(AppSettingKeys.activeProfileId);
    if (active == id) {
      throw StateError('Profile $id is active; deactivate it first');
    }
    await deleteCredentials(id);
    await _paths.deleteProfileTree(id);
    await _opener.delete(StateDatabaseTarget(id));
    await _opener.delete(CacheDatabaseTarget(id));
    await _byIdDelete(id).go();
  }

  UpdateStatement<db.$ProfilesTable, db.Profile> _byIdUpdate(String id) =>
      _db.update(_table)..where((t) => t.id.equals(id));

  DeleteStatement<db.$ProfilesTable, db.Profile> _byIdDelete(String id) =>
      _db.delete(_table)..where((t) => t.id.equals(id));
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _hostOf(Uri baseUrl) => baseUrl.host;

/// Maps a `profiles` row to a [Profile].
Profile profileFromRow(db.Profile row) => Profile(
  id: row.id,
  baseUrl: Uri.parse(row.baseUrl),
  displayName: row.displayName,
  userId: row.userId,
  username: row.username,
  userDisplayName: row.userDisplayName,
  role: row.role,
  authKind: row.authKind,
  deviceId: row.deviceId,
  credentialCreatedAt: row.credentialCreatedAt.toUtc(),
  credentialExpiresAt: row.credentialExpiresAt?.toUtc(),
  serverVersion: row.serverVersion,
  features: switch (row.features) {
    final String json => switch (jsonDecode(json)) {
      final Map<String, Object?> map => map,
      _ => null,
    },
    null => null,
  },
  featuresFetchedAt: row.featuresFetchedAt?.toUtc(),
  state: row.state,
  lastUsedAt: row.lastUsedAt.toUtc(),
);

/// Maps a [Profile] to a `profiles` row.
db.Profile profileToRow(Profile profile) => db.Profile(
  id: profile.id,
  baseUrl: profile.baseUrl.toString(),
  displayName: profile.displayName,
  userId: profile.userId,
  username: profile.username,
  userDisplayName: profile.userDisplayName,
  role: profile.role,
  authKind: profile.authKind,
  deviceId: profile.deviceId,
  credentialCreatedAt: profile.credentialCreatedAt,
  credentialExpiresAt: profile.credentialExpiresAt,
  serverVersion: profile.serverVersion,
  features: profile.features == null ? null : jsonEncode(profile.features),
  featuresFetchedAt: profile.featuresFetchedAt,
  state: profile.state,
  lastUsedAt: profile.lastUsedAt,
);
