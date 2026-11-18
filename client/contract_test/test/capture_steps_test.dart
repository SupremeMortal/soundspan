// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../tool/src/capture_steps.dart';

/// The operationIds of the committed client-surface spec.
Set<String> _specOperationIds() {
  final spec = jsonDecode(
    File('../packages/soundspan_api/openapi/soundspan-client.json')
        .readAsStringSync(),
  ) as Map<String, Object?>;
  final ids = <String>{};
  for (final path in (spec['paths']! as Map<String, Object?>).values) {
    for (final operation in (path! as Map<String, Object?>).values) {
      if (operation is Map<String, Object?> &&
          operation['operationId'] is String) {
        ids.add(operation['operationId']! as String);
      }
    }
  }
  return ids;
}

void main() {
  test('every step names an operationId of the committed spec', () {
    final ids = _specOperationIds();
    expect(ids, isNotEmpty);
    final unknown = [
      for (final step in captureSteps)
        if (!ids.contains(step.operationId)) step.operationId,
    ];
    expect(unknown, isEmpty);
  });

  test('step output file names are unique', () {
    final names = captureSteps.map((step) => step.fileName).toList();
    expect(names.toSet(), hasLength(names.length));
  });

  test('login is captured as both of its response shapes', () {
    final names = captureSteps.map((step) => step.fileName);
    expect(names, containsAll(['login.json', 'login.requires2FA.json']));
  });

  test('the device-link key is verified before it revokes itself', () {
    final names = captureSteps.map((step) => step.fileName).toList();
    final verify = names.indexOf('verifyDeviceLink.json');
    final revoke = names.indexOf('revokeCurrentApiKey.json');
    expect(verify, isNonNegative, reason: 'verifyDeviceLink is not captured');
    expect(revoke, greaterThan(verify));
  });
}
