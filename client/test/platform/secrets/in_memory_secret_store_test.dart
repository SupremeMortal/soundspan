// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/platform/secrets/secrets.dart';

import '../../helpers/in_memory_secret_store.dart';
import '../../helpers/pump_app.dart';

void main() {
  test('read, write, delete round trip', () async {
    final SecretStore store = InMemorySecretStore();
    expect(await store.read('p/a/refresh'), isNull);

    await store.write('p/a/refresh', 'r1');
    expect(await store.read('p/a/refresh'), 'r1');

    await store.write('p/a/refresh', 'r2');
    expect(await store.read('p/a/refresh'), 'r2');

    await store.delete('p/a/refresh');
    expect(await store.read('p/a/refresh'), isNull);
    await store.delete('p/a/refresh');
  });

  test('secretStoreProvider throws until it is overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(() => container.read(secretStoreProvider), throwsA(anything));
  });

  testWidgets('pumpApp provides an InMemorySecretStore', (tester) async {
    final container = await tester.pumpApp(const SizedBox());
    expect(container.read(secretStoreProvider), isA<InMemorySecretStore>());
  });
}
