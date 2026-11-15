// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/features/search/data/search_history_store.dart';

import '../../helpers/fake_clock.dart';

void main() {
  late StateDatabase db;
  late FakeClock clock;
  late SearchHistoryStore store;

  setUp(() {
    db = StateDatabase(NativeDatabase.memory());
    clock = FakeClock();
    store = SearchHistoryStore(db, clock);
  });
  tearDown(() => db.close());

  Future<void> recordAll(Iterable<String> queries) async {
    for (final query in queries) {
      await store.record(query);
      clock.advance(const Duration(seconds: 1));
    }
  }

  test('newest first', () async {
    await recordAll(['miles', 'coltrane', 'monk']);
    expect(await store.watchRecent().first, ['monk', 'coltrane', 'miles']);
  });

  test('recording an existing query in another case moves it to the top and '
      'keeps one row', () async {
    await recordAll(['Miles Davis', 'coltrane', 'miles davis']);
    expect(await store.watchRecent().first, ['Miles Davis', 'coltrane']);
  });

  test('the 21st query evicts the oldest', () async {
    await recordAll([for (var i = 0; i < 21; i++) 'q$i']);
    final recent = await store.watchRecent().first;
    expect(recent, hasLength(20));
    expect(recent.first, 'q20');
    expect(recent, isNot(contains('q0')));
    expect(recent.last, 'q1');
  });

  test('remove and clear', () async {
    await recordAll(['miles', 'coltrane', 'monk']);
    await store.remove('COLTRANE');
    expect(await store.watchRecent().first, ['monk', 'miles']);
    await store.clear();
    expect(await store.watchRecent().first, isEmpty);
  });

  test('blank queries are not recorded', () async {
    await recordAll(['', '   ', '  miles  ']);
    expect(await store.watchRecent().first, ['miles']);
  });
}
