// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

/// A 1×1 PNG.
const String _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// Writes a small PNG to a new temporary directory and returns its
/// `file://` URI.
Future<Uri?> smokeThumbnail() async {
  final dir = await Directory.systemTemp.createTemp('soundspan_smoke');
  final file = File('${dir.path}${Platform.pathSeparator}now-playing.png');
  await file.writeAsBytes(base64Decode(_png));
  return file.uri;
}
