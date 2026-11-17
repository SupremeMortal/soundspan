// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const String _android = 'http://schemas.android.com/apk/res/android';

String? _attr(XmlElement element, String name) =>
    element.getAttribute(name, namespaceUri: _android);

XmlDocument _xml(String path) =>
    XmlDocument.parse(File(path).readAsStringSync());

const String _res = 'android/app/src/main/res';

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

  test('large download batches may run as a dataSync foreground service', () {
    final manifest = _xml('android/app/src/main/AndroidManifest.xml');
    final permissions = [
      for (final e in manifest.findAllElements('uses-permission'))
        _attr(e, 'name'),
    ];
    expect(permissions, contains('android.permission.FOREGROUND_SERVICE'));
    expect(
      permissions,
      contains('android.permission.FOREGROUND_SERVICE_DATA_SYNC'),
    );
    expect(permissions, contains('android.permission.POST_NOTIFICATIONS'));

    final services = manifest
        .findAllElements('service')
        .where(
          (e) =>
              _attr(e, 'name') ==
              'androidx.work.impl.foreground.SystemForegroundService',
        )
        .toList();
    expect(services, hasLength(1));
    expect(_attr(services.single, 'foregroundServiceType'), 'dataSync');
  });

  test('the downloads notification uses the Downloads channel name and the '
      'app notification icon', () {
    final values = _xml('$_res/values/download_notification.xml').rootElement;
    final strings = {
      for (final e in values.findElements('string'))
        e.getAttribute('name'): e.innerText,
    };
    expect(strings['bg_downloader_notification_channel_name'], 'Downloads');
    final drawables = {
      for (final e in values.findElements('drawable'))
        e.getAttribute('name'): e.innerText,
    };
    for (final name in [
      'outline_file_download_24',
      'outline_download_done_24',
      'outline_error_outline_24',
    ]) {
      expect(drawables[name], '@drawable/ic_stat_soundspan', reason: name);
    }
    expect(
      File('$_res/drawable-mdpi/ic_stat_soundspan.png').existsSync(),
      isTrue,
    );
  });

  test('neither backup rule set carries the profiles, and so not their '
      'downloaded media', () {
    bool excludesProfiles(XmlElement rules) => rules
        .findElements('exclude')
        .any(
          (e) =>
              e.getAttribute('domain') == 'file' &&
              e.getAttribute('path') == 'profiles/',
        );

    final extraction = _xml('$_res/xml/data_extraction_rules.xml').rootElement;
    expect(excludesProfiles(extraction.getElement('cloud-backup')!), isTrue);
    expect(excludesProfiles(extraction.getElement('device-transfer')!), isTrue);
    expect(
      excludesProfiles(_xml('$_res/xml/backup_rules.xml').rootElement),
      isTrue,
    );

    final application = _xml('android/app/src/main/AndroidManifest.xml')
        .findAllElements('application')
        .single;
    expect(
      _attr(application, 'dataExtractionRules'),
      '@xml/data_extraction_rules',
    );
    expect(_attr(application, 'fullBackupContent'), '@xml/backup_rules');
  });
}
