// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';

void main() {
  final gate = VersionGate(
    Version.tryParse('1.4.0')!,
    Version.tryParse('1.6.0')!,
  );
  VersionGateResult evaluate(String text) =>
      gate.evaluate(Version.tryParse(text));

  test('below', () {
    expect(evaluate('1.3.9'), VersionGateResult.belowMin);
    expect(evaluate('1.4.0-rc.1'), VersionGateResult.belowMin);
  });

  test('in', () {
    for (final version in ['1.4.0', '1.5.2', '1.6.0']) {
      expect(evaluate(version), VersionGateResult.inRange, reason: version);
    }
  });

  test('above', () {
    for (final version in ['1.6.1', '2.0.0']) {
      expect(evaluate(version), VersionGateResult.aboveTested, reason: version);
    }
  });

  test('unknown', () {
    final result = gate.evaluate(null);
    expect(result, VersionGateResult.unknown);
    expect(result.blocks, isFalse);
    expect(VersionGateResult.inRange.blocks, isFalse);
    expect(VersionGateResult.belowMin.blocks, isTrue);
  });
}
