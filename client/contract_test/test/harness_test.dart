// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@Tags(['contract'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('the health operation of an anonymous api reports the server as '
      'started', () async {
    final api = anonymousApi(ContractCredentials.load());

    final health = await api.send((rest) => rest.session.getHealth());

    expect(health.startupComplete, isTrue);
    expect(health.draining, isFalse);
  });

  test('credentials.json has every field the seed writes', () {
    final json = jsonDecode(
      File(credentialsPath).readAsStringSync(),
    ) as Map<String, Object?>;

    expect(
      json.keys,
      containsAll(<String>[
        'baseUrl',
        'admin',
        'listener',
        'twofa',
        'totpSecret',
        'playlistId',
        'unavailablePlaybackId',
      ]),
    );
    final credentials = ContractCredentials.fromJson(json);
    for (final account in [
      credentials.admin,
      credentials.listener,
      credentials.twofa,
    ]) {
      expect(account.username, isNotEmpty);
      expect(account.password, isNotEmpty);
    }
    expect(credentials.baseUrl.isAbsolute, isTrue);
    expect(credentials.totpSecret, isNotEmpty);
    expect(credentials.playlistId, isNotEmpty);
    expect(credentials.unavailablePlaybackId, anyOf(isNull, isA<String>()));
  });
}
