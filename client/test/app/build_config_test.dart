// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/build_config.dart';

List<int> _parts(String version) =>
    version.split('.').map(int.parse).toList(growable: false);

void main() {
  group('BuildConfig', () {
    test('channel is dev without a define', () {
      expect(BuildConfig.channel, 'dev');
    });

    test('server versions are three-part version strings', () {
      final versionPattern = RegExp(r'^\d+\.\d+\.\d+$');
      expect(BuildConfig.minServer, matches(versionPattern));
      expect(BuildConfig.maxTestedServer, matches(versionPattern));
    });

    test('minServer is not greater than maxTestedServer', () {
      final min = _parts(BuildConfig.minServer);
      final max = _parts(BuildConfig.maxTestedServer);
      var comparison = 0;
      for (var i = 0; i < 3 && comparison == 0; i++) {
        comparison = min[i].compareTo(max[i]);
      }
      expect(comparison, lessThanOrEqualTo(0));
    });
  });
}
