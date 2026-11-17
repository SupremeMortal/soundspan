// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const String _android = 'http://schemas.android.com/apk/res/android';

String? _attr(XmlElement element, String name) =>
    element.getAttribute(name, namespaceUri: _android);

void main() {
  test('the artwork FileProvider is declared, not exported, and grants '
      'URI permissions', () {
    final manifest = XmlDocument.parse(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
    );
    final providers = manifest
        .findAllElements('provider')
        .where((e) => _attr(e, 'name') == 'androidx.core.content.FileProvider')
        .toList();

    expect(providers, hasLength(1));
    final provider = providers.single;
    expect(_attr(provider, 'authorities'), r'${applicationId}.artwork');
    expect(_attr(provider, 'exported'), 'false');
    expect(_attr(provider, 'grantUriPermissions'), 'true');
    final meta = provider.findElements('meta-data').single;
    expect(_attr(meta, 'name'), 'android.support.FILE_PROVIDER_PATHS');
    expect(_attr(meta, 'resource'), '@xml/artwork_paths');
  });

  test('artwork_paths.xml exposes only the profiles tree, as art', () {
    final paths = XmlDocument.parse(
      File('android/app/src/main/res/xml/artwork_paths.xml').readAsStringSync(),
    ).rootElement;

    expect(paths.name.local, 'paths');
    final entries = paths.childElements.toList();
    expect(entries, hasLength(1));
    expect(entries.single.name.local, 'files-path');
    expect(entries.single.getAttribute('name'), 'art');
    expect(entries.single.getAttribute('path'), 'profiles/');
  });
}
