// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/app/app_database.dart';
import 'package:soundspan/core/storage/app/profile_enums.dart';

ProfilesCompanion _profile({
  String id = 'p1',
  String baseUrl = 'https://music.example',
  String userId = 'u1',
  AuthKind authKind = AuthKind.password,
  ProfileState state = ProfileState.active,
}) => ProfilesCompanion.insert(
  id: id,
  baseUrl: baseUrl,
  displayName: 'Home',
  userId: userId,
  username: 'ada',
  role: 'admin',
  authKind: authKind,
  deviceId: 'device-1',
  credentialCreatedAt: DateTime.utc(2025, 1, 2, 3, 4, 5, 678),
  state: state,
  lastUsedAt: DateTime.utc(2025, 2),
);

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('a profile with every column is inserted and read back', () async {
    await db
        .into(db.profiles)
        .insert(
          _profile().copyWith(
            userDisplayName: const Value('Ada L.'),
            credentialExpiresAt: Value(DateTime.utc(2026)),
            serverVersion: const Value('1.2.3'),
            features: const Value('{"lyrics":true}'),
            featuresFetchedAt: Value(DateTime.utc(2025, 3)),
          ),
        );

    final row = await db.select(db.profiles).getSingle();
    expect(row.id, 'p1');
    expect(row.baseUrl, 'https://music.example');
    expect(row.displayName, 'Home');
    expect(row.userId, 'u1');
    expect(row.username, 'ada');
    expect(row.userDisplayName, 'Ada L.');
    expect(row.role, 'admin');
    expect(row.authKind, AuthKind.password);
    expect(row.deviceId, 'device-1');
    expect(row.credentialCreatedAt, DateTime.utc(2025, 1, 2, 3, 4, 5, 678));
    expect(row.credentialExpiresAt, DateTime.utc(2026));
    expect(row.serverVersion, '1.2.3');
    expect(row.features, '{"lyrics":true}');
    expect(row.featuresFetchedAt, DateTime.utc(2025, 3));
    expect(row.state, ProfileState.active);
    expect(row.lastUsedAt, DateTime.utc(2025, 2));
  });

  test('optional columns default to null', () async {
    await db.into(db.profiles).insert(_profile());
    final row = await db.select(db.profiles).getSingle();
    expect(row.userDisplayName, isNull);
    expect(row.credentialExpiresAt, isNull);
    expect(row.serverVersion, isNull);
    expect(row.features, isNull);
    expect(row.featuresFetchedAt, isNull);
  });

  test(
    'a second profile for the same baseUrl and userId is rejected',
    () async {
      await db.into(db.profiles).insert(_profile());
      await expectLater(
        db.into(db.profiles).insert(_profile(id: 'p2')),
        throwsA(isA<SqliteException>()),
      );
      // Same user on another server, or another user on the same server: fine.
      await db
          .into(db.profiles)
          .insert(_profile(id: 'p3', baseUrl: 'https://b'));
      await db.into(db.profiles).insert(_profile(id: 'p4', userId: 'u2'));
      expect(await db.select(db.profiles).get(), hasLength(3));
    },
  );

  test('AuthKind and ProfileState round-trip', () async {
    var n = 0;
    for (final kind in AuthKind.values) {
      for (final state in ProfileState.values) {
        n++;
        await db
            .into(db.profiles)
            .insert(
              _profile(id: 'p$n', userId: 'u$n', authKind: kind, state: state),
            );
        final row = await (db.select(
          db.profiles,
        )..where((t) => t.id.equals('p$n'))).getSingle();
        expect((row.authKind, row.state), (kind, state));
      }
    }
  });

  test('a DateTime round-trips to the millisecond in UTC', () async {
    final at = DateTime.utc(2025, 6, 7, 8, 9, 10, 123);
    await db
        .into(db.profiles)
        .insert(_profile().copyWith(lastUsedAt: Value(at)));
    final row = await db.select(db.profiles).getSingle();
    expect(row.lastUsedAt.isUtc, isTrue);
    expect(row.lastUsedAt, at);

    final stored = await db
        .customSelect('SELECT last_used_at FROM profiles')
        .getSingle();
    expect(stored.read<String>('last_used_at'), '2025-06-07T08:09:10.123Z');
  });

  test('foreign keys are enforced', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });
}
