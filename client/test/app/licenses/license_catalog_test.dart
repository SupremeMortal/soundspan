// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/licenses/license_catalog.dart';

class _Source implements LicenseSource {
  const new(this.entries, this.titles);

  final List<LicenseEntry> entries;
  final List<String> titles;

  @override
  Stream<LicenseEntry> licenses() => Stream.fromIterable(entries);

  @override
  Future<List<String>> bundledTitles() async => titles;
}

LicenseEntry _entry(List<String> packages, String text) =>
    LicenseEntryWithLineBreaks(packages, text);

void main() {
  test('groups the app, the bundled components and the packages', () async {
    final catalog = await collectLicenseCatalog(
      _Source(
        [
          _entry(['zeta'], 'Z'),
          _entry(['soundspan'], 'GPL'),
          _entry(['mpv'], 'LGPL'),
          _entry(['Alpha', 'beta'], 'shared'),
          _entry(['Montserrat'], 'OFL'),
          _entry(['beta'], 'B'),
        ],
        ['Montserrat', 'mpv', 'FFmpeg'],
      ),
    );
    expect(catalog.app?.name, 'soundspan');
    expect([for (final p in catalog.bundled) p.name], ['Montserrat', 'mpv']);
    expect(
      [for (final p in catalog.packages) p.name],
      ['Alpha', 'beta', 'zeta'],
    );
    expect(catalog.packages[1].licenses, hasLength(2));
  });

  test('a repeated licence text of a package is listed once', () async {
    final catalog = await collectLicenseCatalog(
      _Source([
        _entry(['soundspan'], 'GPL'),
        _entry(['soundspan'], 'GPL'),
        _entry(['soundspan'], 'other'),
      ], const []),
    );
    expect(catalog.app?.licenses, hasLength(2));
  });

  test('without the app licence the catalog has no app entry', () async {
    final catalog = await collectLicenseCatalog(
      _Source(
        [
          _entry(['path'], 'BSD'),
        ],
        const ['mpv'],
      ),
    );
    expect(catalog.app, isNull);
    expect(catalog.bundled, isEmpty);
    expect(catalog.packages.single.name, 'path');
  });
}
