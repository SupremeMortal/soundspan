// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The licence title of the client itself.
const String soundspanLicenseTitle = 'soundspan';

/// The asset holding the client's licence: `client/LICENSE`, bundled as is.
const String soundspanLicenseAsset = 'LICENSE';

/// The notice manifest: one entry per file under `assets/licenses/`.
const String bundledNoticesIndexAsset = 'assets/licenses/index.json';

/// A notice file for a font or native library the app bundles, as listed in
/// [bundledNoticesIndexAsset].
@immutable
class BundledNotice {
  /// Creates a notice entry.
  const new({
    required this.title,
    required this.file,
    required this.spdx,
    required this.platforms,
  });

  /// Reads one manifest entry.
  factory fromJson(Map<String, Object?> json) => BundledNotice(
    title: json['title']! as String,
    file: json['file']! as String,
    spdx: json['spdx']! as String,
    platforms: [
      for (final platform in json['platforms']! as List<Object?>)
        platform! as String,
    ],
  );

  /// The name shown in the licences list.
  final String title;

  /// The notice's path relative to `assets/licenses/`.
  final String file;

  /// The SPDX licence expression of the component.
  final String spdx;

  /// The targets whose builds ship the component.
  final List<String> platforms;

  /// The asset key of the notice text.
  String get asset => 'assets/licenses/$file';
}

/// Reads the notice manifest from [bundle], in its order.
Future<List<BundledNotice>> loadBundledNotices(AssetBundle bundle) async {
  final json = jsonDecode(
    await bundle.loadString(bundledNoticesIndexAsset),
  ) as List<Object?>;
  return [
    for (final entry in json)
      BundledNotice.fromJson(entry! as Map<String, Object?>),
  ];
}

/// Adds the client's licence and every bundled notice to the
/// [LicenseRegistry] (design doc, Licensing).
///
/// One collector yields a [LicenseEntryWithLineBreaks] titled
/// [soundspanLicenseTitle] with the text of `client/LICENSE`, then one per
/// [loadBundledNotices] entry under its title. Nothing is read from [bundle]
/// until the registry's licences are listened to.
void registerBundledLicenses(AssetBundle bundle) {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      soundspanLicenseTitle,
    ], await bundle.loadString(soundspanLicenseAsset));
    for (final notice in await loadBundledNotices(bundle)) {
      yield LicenseEntryWithLineBreaks([
        notice.title,
      ], await bundle.loadString(notice.asset));
    }
  });
}
