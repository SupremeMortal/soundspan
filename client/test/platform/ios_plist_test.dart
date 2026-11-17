// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

/// The value of a property-list element: a dictionary, an array, a string,
/// a boolean or an integer.
Object? _value(XmlElement element) => switch (element.name.local) {
  'dict' => _dict(element),
  'array' => [for (final child in element.childElements) _value(child)],
  'string' => element.innerText,
  'true' => true,
  'false' => false,
  'integer' => int.parse(element.innerText),
  final other => throw FormatException('unsupported plist element $other'),
};

Map<String, Object?> _dict(XmlElement dict) {
  final children = dict.childElements.toList();
  return {
    for (var i = 0; i < children.length; i += 2)
      children[i].innerText: _value(children[i + 1]),
  };
}

Map<String, Object?> _plist(String path) {
  final root = XmlDocument.parse(File(path).readAsStringSync()).rootElement;
  return _dict(root.childElements.single);
}

void main() {
  final info = _plist('ios/Runner/Info.plist');

  test('the only background mode is audio: URLSession background transfers '
      'need neither fetch nor processing', () {
    expect(info['UIBackgroundModes'], ['audio']);
  });

  test('downloads use the background session io.soundspan.app.downloads', () {
    expect(
      info['SoundspanDownloadSessionIdentifier'],
      'io.soundspan.app.downloads',
    );
  });
}
