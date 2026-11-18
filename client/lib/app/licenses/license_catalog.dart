// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/licenses/license_registration.dart';

/// Where the licences screen reads its licences from.
abstract interface class LicenseSource {
  /// Every registered licence entry.
  Stream<LicenseEntry> licenses();

  /// The titles of the bundled fonts and native libraries, in manifest
  /// order.
  Future<List<String>> bundledTitles();
}

/// The [LicenseRegistry] and the notice manifest of [bundle].
///
/// The framework parses the packages' licences off the UI thread where the
/// platform allows (an isolate everywhere but the web).
class RegistryLicenseSource implements LicenseSource {
  /// Creates a source over the registry and [bundle].
  const new(this.bundle);

  /// The bundle holding the notice manifest.
  final AssetBundle bundle;

  @override
  Stream<LicenseEntry> licenses() => LicenseRegistry.licenses;

  @override
  Future<List<String>> bundledTitles() async => [
    for (final notice in await loadBundledNotices(bundle)) notice.title,
  ];
}

/// A package or bundled component with its distinct licences.
@immutable
class LicensedPackage {
  /// Creates the package [name] with its [licenses].
  const new(this.name, this.licenses);

  /// The package or component name.
  final String name;

  /// Its licences, without repeated texts.
  final List<LicenseEntry> licenses;
}

/// The licences screen's three groups.
@immutable
class LicenseCatalog {
  /// Creates a catalog.
  const new({required this.app, required this.bundled, required this.packages});

  /// The client's own licence, or null when it is not registered.
  final LicensedPackage? app;

  /// The bundled fonts and native libraries, in manifest order.
  final List<LicensedPackage> bundled;

  /// Every other package, alphabetical.
  final List<LicensedPackage> packages;
}

/// Groups the licences of [source] by package into a [LicenseCatalog].
///
/// An entry naming several packages counts for each of them. A licence text
/// that a package already has is not repeated (the framework registers the
/// root package's `LICENSE` too).
Future<LicenseCatalog> collectLicenseCatalog(LicenseSource source) async {
  final titles = await source.bundledTitles();
  final grouped = <String, List<LicenseEntry>>{};
  final seen = <String, Set<String>>{};
  await for (final entry in source.licenses()) {
    final text = entry is LicenseEntryWithLineBreaks ? entry.text : null;
    for (final package in entry.packages) {
      if (text != null && !seen.putIfAbsent(package, () => {}).add(text)) {
        continue;
      }
      grouped.putIfAbsent(package, () => []).add(entry);
    }
  }
  LicensedPackage? take(String name) {
    final licenses = grouped.remove(name);
    return licenses == null ? null : LicensedPackage(name, licenses);
  }

  final app = take(soundspanLicenseTitle);
  final bundled = [for (final title in titles) ?take(title)];
  final packages =
      [
        for (final MapEntry(:key, :value) in grouped.entries)
          LicensedPackage(key, value),
      ]..sort((a, b) {
        final folded = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return folded != 0 ? folded : a.name.compareTo(b.name);
      });
  return LicenseCatalog(app: app, bundled: bundled, packages: packages);
}

/// The [LicenseSource] of the licences screen.
final Provider<LicenseSource> licenseSourceProvider = Provider<LicenseSource>(
  (ref) => RegistryLicenseSource(rootBundle),
);

/// The grouped licences, collected while the licences screen is shown. A
/// failure is not retried until the screen asks again.
final FutureProvider<LicenseCatalog> licenseCatalogProvider =
    FutureProvider.autoDispose<LicenseCatalog>(
      (ref) => collectLicenseCatalog(ref.watch(licenseSourceProvider)),
      retry: (_, _) => null,
    );
