// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';
import 'package:test/test.dart';

void main() {
  group('OffsetPage', () {
    test('with a total, hasMore compares offset plus items to it', () {
      const middle = OffsetPage<int>(
        items: [1, 2, 3],
        offset: 3,
        limit: 3,
        total: 9,
      );
      expect(middle.hasMore, isTrue);
      expect(middle.nextOffset, 6);

      const last = OffsetPage<int>(
        items: [7, 8, 9],
        offset: 6,
        limit: 3,
        total: 9,
      );
      expect(last.hasMore, isFalse);
      expect(last.nextOffset, 9);
    });

    test('with a total, a short last page has no more', () {
      const page = OffsetPage<int>(
        items: [1, 2],
        offset: 0,
        limit: 3,
        total: 2,
      );
      expect(page.hasMore, isFalse);
    });

    test('without a total, a full page has more and a short one does not', () {
      const full = OffsetPage<int>(items: [1, 2, 3], offset: 0, limit: 3);
      expect(full.hasMore, isTrue);
      expect(full.nextOffset, 3);

      const short = OffsetPage<int>(items: [4], offset: 3, limit: 3);
      expect(short.hasMore, isFalse);
      expect(short.nextOffset, 4);
    });

    test('an empty page has no more and keeps its offset', () {
      const withTotal = OffsetPage<int>(
        items: [],
        offset: 0,
        limit: 60,
        total: 0,
      );
      expect(withTotal.hasMore, isFalse);
      expect(withTotal.nextOffset, 0);

      const withoutTotal = OffsetPage<int>(items: [], offset: 60, limit: 60);
      expect(withoutTotal.hasMore, isFalse);
      expect(withoutTotal.nextOffset, 60);
    });

    test('carries the next cursor', () {
      const page = OffsetPage<int>(
        items: [1],
        offset: 0,
        limit: 1,
        total: 5,
        nextCursor: 'c1',
      );
      expect(page.nextCursor, 'c1');
    });
  });

  group('KeysetPage', () {
    test('holds items, cursor, hasMore and total as given', () {
      const page = KeysetPage<String, int>(
        items: ['a', 'b'],
        nextCursor: 42,
        hasMore: true,
        total: 10,
      );
      expect(page.items, ['a', 'b']);
      expect(page.nextCursor, 42);
      expect(page.hasMore, isTrue);
      expect(page.total, 10);
    });

    test('an empty last page has no cursor and no more', () {
      const page = KeysetPage<String, int>(items: [], hasMore: false);
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
      expect(page.hasMore, isFalse);
      expect(page.total, isNull);
    });
  });
}
