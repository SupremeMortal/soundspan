// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/app/licenses/license_registration.dart';

/// Joins the paragraphs of every registered entry, per title.
Future<Map<String, String>> _registeredTexts() async {
  final texts = <String, StringBuffer>{};
  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs.map((p) => p.text).join('\n');
    for (final package in entry.packages) {
      texts.putIfAbsent(package, StringBuffer.new).writeln(text);
    }
  }
  return {
    for (final MapEntry(:key, :value) in texts.entries)
      key: value.toString().replaceAll(RegExp(r'\s+'), ' '),
  };
}

/// An asset bundle that counts the keys it was asked for.
class _CountingBundle extends CachingAssetBundle {
  final List<String> requested = [];

  @override
  Future<ByteData> load(String key) {
    requested.add(key);
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(LicenseRegistry.reset);
  tearDown(LicenseRegistry.reset);

  test('registers soundspan and every bundled notice', () async {
    registerBundledLicenses(rootBundle);
    final texts = await _registeredTexts();
    expect(
      texts.keys,
      containsAll([
        'soundspan',
        'Montserrat',
        'Turret Road',
        'mpv',
        'FFmpeg',
        'AndroidX Media3',
        'SQLite',
      ]),
    );
    expect(texts['soundspan'], contains('GNU GENERAL PUBLIC LICENSE'));
    expect(
      texts['soundspan'],
      contains('ADDITIONAL PERMISSION UNDER GNU GPL VERSION 3 SECTION 7'),
    );
    expect(texts['soundspan'], contains('through an application store'));
    expect(texts['mpv'], contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(
      texts['mpv'],
      contains('You may replace the bundled libmpv with any compatible build'),
    );
    expect(texts['FFmpeg'], contains('GNU LESSER GENERAL PUBLIC LICENSE'));
    expect(texts['AndroidX Media3'], contains('Apache License'));
    expect(texts['SQLite'], contains('public domain'));
  });

  test('every index.json entry yields non-empty text', () async {
    registerBundledLicenses(rootBundle);
    final texts = await _registeredTexts();
    final notices = await loadBundledNotices(rootBundle);
    expect(notices, isNotEmpty);
    for (final notice in notices) {
      expect(texts[notice.title]?.trim(), isNotEmpty, reason: notice.title);
    }
  });

  test('nothing is read until the licences are listened to', () async {
    final bundle = _CountingBundle();
    registerBundledLicenses(bundle);
    expect(bundle.requested, isEmpty);
    await LicenseRegistry.licenses.toList();
    expect(
      bundle.requested,
      containsAll([soundspanLicenseAsset, bundledNoticesIndexAsset]),
    );
  });

  test('every file under assets/licenses/ is listed in index.json', () {
    final dir = Directory('assets/licenses');
    final index = jsonDecode(
      File(p.join(dir.path, 'index.json')).readAsStringSync(),
    ) as List<Object?>;
    final listed = {
      for (final entry in index.cast<Map<String, Object?>>())
        entry['file']! as String,
    };
    final files = [
      for (final file in dir.listSync(recursive: true).whereType<File>())
        p.relative(file.path, from: dir.path).replaceAll(r'\', '/'),
    ]..remove('index.json');
    expect(files, isNotEmpty);
    expect(listed, containsAll(files));
  });
}
