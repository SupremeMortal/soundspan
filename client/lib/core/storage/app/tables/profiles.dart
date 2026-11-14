// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception
// Table definitions are read by drift_dev and never run.
// coverage:ignore-file

import 'package:drift/drift.dart';
import 'package:soundspan/core/storage/app/profile_enums.dart';

/// One server profile: a user signed in to one server (doc 05).
class Profiles extends Table {
  /// The profile id, a client-generated UUID.
  TextColumn get id => text()();

  /// The server's base URL, including any reverse-proxy path prefix.
  TextColumn get baseUrl => text()();

  /// The name the user gave the server.
  TextColumn get displayName => text()();

  /// The server's id of the signed-in user.
  TextColumn get userId => text()();

  /// The signed-in user's username.
  TextColumn get username => text()();

  /// The signed-in user's display name, if they have one.
  TextColumn get userDisplayName => text().nullable()();

  /// The signed-in user's role on the server.
  TextColumn get role => text()();

  /// How the credential was obtained.
  TextColumn get authKind => textEnum<AuthKind>()();

  /// The playback device id this client sends to the server.
  TextColumn get deviceId => text()();

  /// When the credential was issued.
  DateTimeColumn get credentialCreatedAt => dateTime()();

  /// When the credential expires, if it does.
  DateTimeColumn get credentialExpiresAt => dateTime().nullable()();

  /// The server version seen at the last capability refresh.
  TextColumn get serverVersion => text().nullable()();

  /// The server's feature flags, JSON-encoded.
  TextColumn get features => text().nullable()();

  /// When [features] was fetched.
  DateTimeColumn get featuresFetchedAt => dateTime().nullable()();

  /// Whether the profile is signed in.
  TextColumn get state => textEnum<ProfileState>()();

  /// When the profile was last the active one.
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {baseUrl, userId},
  ];
}
