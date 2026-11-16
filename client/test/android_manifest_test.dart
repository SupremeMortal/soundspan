// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

const String _android = 'http://schemas.android.com/apk/res/android';

String? _attr(XmlElement e, String name) =>
    e.getAttribute(name, namespaceUri: _android);

bool _filterHas(XmlElement e, String action) => e
    .findElements('intent-filter')
    .any(
      (f) => f.findElements('action').any((a) => _attr(a, 'name') == action),
    );

void main() {
  late XmlElement manifest;
  setUpAll(() {
    manifest = XmlDocument.parse(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
    ).rootElement;
  });

  test('the playback service permissions are requested', () {
    final permissions = {
      for (final e in manifest.findElements('uses-permission'))
        _attr(e, 'name'),
    };

    expect(
      permissions,
      containsAll([
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
        'android.permission.WAKE_LOCK',
      ]),
    );
  });

  test('MainActivity is a single task', () {
    final activity = manifest
        .findAllElements('activity')
        .singleWhere((e) => _attr(e, 'name') == '.MainActivity');

    expect(_attr(activity, 'launchMode'), 'singleTask');
  });

  test('the audio_service service plays media and is a media browser '
      'service', () {
    final service = manifest
        .findAllElements('service')
        .singleWhere(
          (e) => _attr(e, 'name') == 'com.ryanheise.audioservice.AudioService',
        );

    expect(_attr(service, 'foregroundServiceType'), 'mediaPlayback');
    expect(_attr(service, 'exported'), 'true');
    expect(
      _filterHas(service, 'android.media.browse.MediaBrowserService'),
      isTrue,
    );
  });

  test('the media button receiver takes media buttons', () {
    final receiver = manifest
        .findAllElements('receiver')
        .singleWhere(
          (e) =>
              _attr(e, 'name') ==
              'com.ryanheise.audioservice.MediaButtonReceiver',
        );

    expect(_attr(receiver, 'exported'), 'true');
    expect(_filterHas(receiver, 'android.intent.action.MEDIA_BUTTON'), isTrue);
  });
}
