// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/platform/secrets/secrets_io.dart';

const _channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> stored;
  late List<MethodCall> calls;
  PlatformException? failure;

  setUp(() {
    stored = {};
    calls = [];
    failure = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          if (failure != null) throw failure!;
          final args = (call.arguments as Map).cast<String, Object?>();
          final key = args['key'] as String?;
          switch (call.method) {
            case 'write':
              stored[key!] = args['value']! as String;
              return null;
            case 'read':
              return stored[key];
            case 'delete':
              stored.remove(key);
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Map<String, Object?> optionsOf(MethodCall call) =>
      ((call.arguments as Map)['options'] as Map).cast<String, Object?>();

  test('write then read returns the value', () async {
    final SecretStore store = IoSecretStore();
    await store.write('p/a/refresh', 'r1');
    expect(await store.read('p/a/refresh'), 'r1');
  });

  test('read of a missing key is null', () async {
    expect(await IoSecretStore().read('p/a/access'), isNull);
  });

  test('delete removes the value', () async {
    final store = IoSecretStore();
    await store.write('p/a/apikey', 'k');
    await store.delete('p/a/apikey');
    expect(await store.read('p/a/apikey'), isNull);
  });

  test('deleting a missing key succeeds', () async {
    await expectLater(IoSecretStore().delete('p/missing/refresh'), completes);
  });

  test('a PlatformException on write surfaces as SecretStoreUnavailable', () {
    failure = PlatformException(code: 'no_provider', message: 'no service');
    expect(
      IoSecretStore().write('p/a/refresh', 'r1'),
      throwsA(isA<SecretStoreUnavailable>()),
    );
  });

  test('a PlatformException on read or delete surfaces as '
      'SecretStoreUnavailable', () {
    failure = PlatformException(code: 'no_provider');
    final store = IoSecretStore();
    expect(store.read('k'), throwsA(isA<SecretStoreUnavailable>()));
    expect(store.delete('k'), throwsA(isA<SecretStoreUnavailable>()));
  });

  test('Android uses the default custom-cipher storage, which replaces '
      'encryptedSharedPreferences', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await IoSecretStore().write('k', 'v');
    final options = optionsOf(calls.single);
    expect(options['storageCipherAlgorithm'], 'AES_GCM_NoPadding');
    expect(
      options['keyCipherAlgorithm'],
      'RSA_ECB_OAEPwithSHA_256andMGF1Padding',
    );
    expect(options['enforceBiometrics'], 'false');
  });

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    test('$platform uses first_unlock_this_device', () async {
      debugDefaultTargetPlatformOverride = platform;
      await IoSecretStore().write('k', 'v');
      final options = optionsOf(calls.single);
      expect(options['accessibility'], 'first_unlock_this_device');
      expect(options['synchronizable'], 'false');
    });
  }
}
