// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/downloads/download_quota.dart';

const int _mb = 1024 * 1024;
const int _gb = 1024 * _mb;

void main() {
  group('evaluateQuota', () {
    final cases =
        <
          ({
            String name,
            int committed,
            List<int?> items,
            int limit,
            int? free,
            int fitCount,
            int needed,
            int available,
          })
        >[
          (
            name: 'everything fits',
            committed: 100 * _mb,
            items: [10 * _mb, 20 * _mb, 30 * _mb],
            limit: 1 * _gb,
            free: 10 * _gb,
            fitCount: 3,
            needed: 60 * _mb,
            available: 924 * _mb,
          ),
          (
            name: 'the limit cuts after N items',
            committed: 900 * _mb,
            items: [50 * _mb, 50 * _mb, 50 * _mb, 10 * _mb],
            limit: 1000 * _mb,
            free: 10 * _gb,
            fitCount: 2,
            needed: 160 * _mb,
            available: 100 * _mb,
          ),
          (
            name: 'free space minus the reserve is the tighter bound',
            committed: 0,
            items: [100 * _mb, 100 * _mb, 100 * _mb],
            limit: 20 * _gb,
            free: 750 * _mb,
            fitCount: 2,
            needed: 300 * _mb,
            available: 250 * _mb,
          ),
          (
            name: 'unknown sizes count as 8 MB',
            committed: 0,
            items: [null, null, null],
            limit: 20 * _mb,
            free: null,
            fitCount: 2,
            needed: 24 * _mb,
            available: 20 * _mb,
          ),
          (
            name: 'unknown free space drops the disk bound',
            committed: 0,
            items: [5 * _gb, 5 * _gb],
            limit: 20 * _gb,
            free: null,
            fitCount: 2,
            needed: 10 * _gb,
            available: 20 * _gb,
          ),
          (
            name: 'over the limit already: nothing fits, nothing is available',
            committed: 2 * _gb,
            items: [1 * _mb],
            limit: 1 * _gb,
            free: 10 * _gb,
            fitCount: 0,
            needed: 1 * _mb,
            available: 0,
          ),
          (
            name: 'the cut is a prefix: a later small item does not jump ahead',
            committed: 0,
            items: [10 * _mb, 100 * _mb, 1 * _mb],
            limit: 50 * _mb,
            free: null,
            fitCount: 1,
            needed: 111 * _mb,
            available: 50 * _mb,
          ),
        ];
    for (final c in cases) {
      test(c.name, () {
        final decision = evaluateQuota(
          committedBytes: c.committed,
          newItemBytes: c.items,
          deviceLimitBytes: c.limit,
          freeDiskBytes: c.free,
        );
        expect(decision.fitCount, c.fitCount);
        expect(decision.neededBytes, c.needed);
        expect(decision.availableBytes, c.available);
        expect(decision.fitsAll, c.fitCount == c.items.length);
      });
    }
  });

  group('defaultDeviceLimitBytes', () {
    test('a quarter of free space when that is below 20 GB', () {
      expect(defaultDeviceLimitBytes(40 * _gb), 10 * _gb);
    });
    test('20 GB when a quarter of free space is more', () {
      expect(defaultDeviceLimitBytes(200 * _gb), 20 * _gb);
    });
    test('20 GB when free space is unknown', () {
      expect(defaultDeviceLimitBytes(null), 20 * _gb);
    });
  });
}
