// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/license_audit.dart';

const _mit = '''
MIT License

Copyright (c) 2020 Someone

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
''';

const _bsd2 = '''
Copyright (c) 2020 Someone. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
''';

const _bsd3 = '''
Copyright 2014, the Dart project authors.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of Google LLC nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
''';

const _apache = '''
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
''';

const _mpl = '''
Mozilla Public License Version 2.0
==================================

1. Definitions
--------------
''';

const _isc = '''
ISC License

Copyright (c) 2020 Someone

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.
''';

const _zlib = '''
Copyright (c) 2020 Someone

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
''';

const _gpl3 = '''
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
''';

const _gpl2 = '''
                    GNU GENERAL PUBLIC LICENSE
                       Version 2, June 1991
''';

const _agpl3 = '''
                    GNU AFFERO GENERAL PUBLIC LICENSE
                       Version 3, 19 November 2007
''';

const _lgpl21 = '''
                  GNU LESSER GENERAL PUBLIC LICENSE
                       Version 2.1, February 1999
''';

const _lgpl3 = '''
                   GNU LESSER GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

  This version of the GNU Lesser General Public License incorporates
the terms and conditions of version 3 of the GNU General Public
License, supplemented by the additional permissions listed below.
''';

/// A package in the fake client root.
class _Pkg {
  const new(this.name, {this.license, this.deps = const []});

  final String name;

  /// Licence file text; `null` writes no licence file.
  final String? license;
  final List<String> deps;
}

late Directory _root;

/// Builds a fake client root: the app depends on [deps] (dev: [devDeps]),
/// `packages/soundspan_api` depends on [apiDeps], and every package of
/// [packages] lives under `pub/<name>/`.
void _writeTree({
  List<String> deps = const [],
  List<String> devDeps = const [],
  List<String> apiDeps = const [],
  List<_Pkg> packages = const [],
  String? overrides,
}) {
  String pubspec(
    String name,
    List<String> deps, [
    List<String> dev = const [],
  ]) {
    final b = StringBuffer('name: $name\n')
      ..writeln('dependencies:')
      ..writeln('  flutter: { sdk: flutter }');
    for (final d in deps) {
      b.writeln('  $d: ^1.0.0');
    }
    b.writeln('dev_dependencies:');
    for (final d in dev) {
      b.writeln('  $d: ^1.0.0');
    }
    return b.toString();
  }

  void write(String path, String text) => File(p.join(_root.path, path))
    ..createSync(recursive: true)
    ..writeAsStringSync(text);

  write('pubspec.yaml', pubspec('soundspan', deps, devDeps));
  write(
    'packages/soundspan_api/pubspec.yaml',
    pubspec('soundspan_api', apiDeps),
  );
  final config = <Map<String, Object>>[
    {'name': 'soundspan', 'rootUri': '../', 'packageUri': 'lib/'},
    {
      'name': 'soundspan_api',
      'rootUri': '../packages/soundspan_api',
      'packageUri': 'lib/',
    },
  ];
  for (final pkg in packages) {
    write('pub/${pkg.name}/pubspec.yaml', pubspec(pkg.name, pkg.deps));
    if (pkg.license != null) write('pub/${pkg.name}/LICENSE', pkg.license!);
    config.add({
      'name': pkg.name,
      'rootUri': p.toUri(p.join(_root.path, 'pub', pkg.name)).toString(),
      'packageUri': 'lib/',
    });
  }
  write(
    '.dart_tool/package_config.json',
    jsonEncode({'configVersion': 2, 'packages': config}),
  );
  if (overrides != null) write('tool/license_overrides.yaml', overrides);
}

Future<List<String>> _subjects() async => [
  for (final f in await auditLicenses(_root)) f.subject,
];

void _writeFont(String file, {String? licence}) {
  File(p.join(_root.path, 'assets', 'fonts', file))
    ..createSync(recursive: true)
    ..writeAsBytesSync([0, 1, 0, 0]);
  if (licence != null) {
    final family = file.split('-').first.split('.').first;
    File(p.join(_root.path, 'assets', 'licenses', 'fonts', '$family.txt'))
      ..createSync(recursive: true)
      ..writeAsStringSync(licence);
  }
}

void main() {
  setUp(() => _root = Directory.systemTemp.createTempSync('license_audit'));
  tearDown(() => _root.deleteSync(recursive: true));

  group('allowed licences', () {
    const texts = {
      'MIT': _mit,
      'BSD-2-Clause': _bsd2,
      'BSD-3-Clause': _bsd3,
      'Apache-2.0': _apache,
      'MPL-2.0': _mpl,
      'ISC': _isc,
      'Zlib': _zlib,
    };
    for (final MapEntry(key: id, value: text) in texts.entries) {
      test('a dependency with the $id text passes', () async {
        _writeTree(
          deps: ['a'],
          packages: [_Pkg('a', license: text)],
        );
        final audited = <String, List<String>>{};
        final findings = await auditLicenses(
          _root,
          onAudited: (pkg, ids) => audited[pkg] = ids,
        );
        expect(findings, isEmpty);
        expect(audited, {
          'a': [id],
        });
      });
    }
  });

  group('GPL family', () {
    for (final MapEntry(key: id, value: text) in {
      'GPL-2.0': _gpl2,
      'GPL-3.0': _gpl3,
      'AGPL-3.0': _agpl3,
    }.entries) {
      test('a dependency with the $id text fails', () async {
        _writeTree(
          deps: ['a'],
          packages: [_Pkg('a', license: text)],
        );
        final findings = await auditLicenses(_root);
        expect(findings.map((f) => f.subject), ['a']);
        expect(findings.single.reason, contains(id));
      });
    }

    test('a GPL-3.0 dependency still fails with an override', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a', license: _gpl3)],
        overrides: '''
- package: a
  license: MIT
  reason: test
- package: a
  linking: dynamic
  reason: test
''',
      );
      expect(await _subjects(), contains('a'));
    });

    test('a file with MIT and GPL-3.0 texts yields both and fails', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a', license: '$_mit\n$_gpl3')],
      );
      final audited = <String, List<String>>{};
      final findings = await auditLicenses(
        _root,
        onAudited: (pkg, ids) => audited[pkg] = ids,
      );
      expect(audited['a'], unorderedEquals(['MIT', 'GPL-3.0']));
      expect(findings.map((f) => f.subject), ['a']);
    });
  });

  group('LGPL', () {
    for (final MapEntry(key: id, value: text) in {
      'LGPL-2.1': _lgpl21,
      'LGPL-3.0': _lgpl3,
    }.entries) {
      test('$id fails without an override', () async {
        _writeTree(
          deps: ['a'],
          packages: [_Pkg('a', license: text)],
        );
        final findings = await auditLicenses(_root);
        expect(findings.map((f) => f.subject), ['a']);
        expect(findings.single.reason, contains(id));
      });

      test('$id passes with linking: dynamic', () async {
        _writeTree(
          deps: ['a'],
          packages: [_Pkg('a', license: text)],
          overrides: '''
- package: a
  linking: dynamic
  reason: libmpv is loaded as a shared library
''',
        );
        expect(await _subjects(), isEmpty);
      });
    }

    test('LGPL-3.0 text is not also classified as GPL-3.0', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a', license: _lgpl3)],
      );
      final audited = <String, List<String>>{};
      await auditLicenses(_root, onAudited: (pkg, ids) => audited[pkg] = ids);
      expect(audited['a'], ['LGPL-3.0']);
    });
  });

  group('missing or unknown licence', () {
    test('a dependency with no licence file fails', () async {
      _writeTree(deps: ['a'], packages: [const _Pkg('a')]);
      expect(await _subjects(), ['a']);
    });

    test('an unrecognised text fails', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a', license: 'All rights reserved.')],
      );
      expect(await _subjects(), ['a']);
    });

    test('passes with an override naming an allowed licence', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a')],
        overrides: '''
- package: a
  license: BSD-3-Clause
  reason: licence stated in the README
''',
      );
      expect(await _subjects(), isEmpty);
    });

    test('fails with an override naming GPL-3.0', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a')],
        overrides: '''
- package: a
  license: GPL-3.0
  reason: test
''',
      );
      expect(await _subjects(), ['a']);
    });
  });

  group('audited set', () {
    test('a dev-only dependency with a GPL text is not reported', () async {
      _writeTree(
        devDeps: ['d'],
        packages: [const _Pkg('d', license: _gpl3)],
      );
      expect(await _subjects(), isEmpty);
    });

    test(
      'a transitive dependency of a non-dev dependency is audited',
      () async {
        _writeTree(
          deps: ['a'],
          packages: [
            const _Pkg('a', license: _mit, deps: ['b']),
            const _Pkg('b', license: _gpl3),
          ],
        );
        expect(await _subjects(), ['b']);
      },
    );

    test('a dependency of packages/soundspan_api only is audited', () async {
      _writeTree(
        apiDeps: ['c'],
        packages: [const _Pkg('c', license: _gpl3)],
      );
      expect(await _subjects(), ['c']);
    });

    test(
      'an override for a package not in the audited set is a finding',
      () async {
        _writeTree(
          deps: ['a'],
          packages: [const _Pkg('a', license: _mit)],
          overrides: '''
- package: gone
  license: MIT
  reason: removed dependency
''',
        );
        expect(await _subjects(), ['gone']);
      },
    );

    test('a missing package_config.json is a finding', () async {
      _writeTree(
        deps: ['a'],
        packages: [const _Pkg('a', license: _mit)],
      );
      File(p.join(_root.path, '.dart_tool', 'package_config.json'))
          .deleteSync();
      final findings = await auditLicenses(_root);
      expect(findings, hasLength(1));
      expect(findings.single.reason, contains('pub get'));
    });
  });

  group('font gate', () {
    setUp(_writeTree);

    test('a font without its licence text fails', () async {
      _writeFont('Montserrat-VariableFont_wght.ttf');
      expect(await _subjects(), [
        'assets/fonts/Montserrat-VariableFont_wght.ttf',
      ]);
    });

    test('a font with an empty licence text fails', () async {
      _writeFont('TurretRoad-ExtraBold.ttf', licence: '');
      expect(await _subjects(), ['assets/fonts/TurretRoad-ExtraBold.ttf']);
    });

    test('a font with its licence text passes', () async {
      _writeFont('TurretRoad-ExtraBold.ttf', licence: 'SIL Open Font License');
      _writeFont('Montserrat-VariableFont_wght.ttf', licence: 'SIL OFL 1.1');
      expect(await _subjects(), isEmpty);
    });

    test('a non-font file beside the fonts needs no licence text', () async {
      _writeFont('TurretRoad-ExtraBold.ttf', licence: 'SIL Open Font License');
      File(p.join(_root.path, 'assets', 'fonts', 'README.md'))
        ..createSync(recursive: true)
        ..writeAsStringSync('# Bundled fonts');
      expect(await _subjects(), isEmpty);
    });

    test('every font file extension is audited', () async {
      for (final ext in ['otf', 'ttc', 'woff', 'woff2', 'TTF']) {
        _writeFont('Family$ext-Regular.$ext');
      }
      expect(await _subjects(), hasLength(5));
    });

    test('no assets/fonts/ passes', () async {
      expect(await _subjects(), isEmpty);
    });
  });

  test('the real client/ tree has no findings', () async {
    final findings = await auditLicenses(Directory.current);
    expect(findings.map((f) => '${f.subject}: ${f.reason}'), isEmpty);
  });
}
