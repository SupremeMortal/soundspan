// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/check_imports.dart';

const _header =
    '// SPDX-License-Identifier: GPL-3.0-or-later WITH '
    'LicenseRef-soundspan-store-exception\n\n';

late Directory _root;

/// Writes [files] (path relative to the client root -> source) into a fresh
/// temporary client root and returns the violations [checkImports] reports.
///
/// Every source gets the SPDX header unless [header] is false.
List<Violation> _check(Map<String, String> files, {bool header = true}) {
  for (final entry in files.entries) {
    File(p.join(_root.path, entry.key))
      ..createSync(recursive: true)
      ..writeAsStringSync('${header ? _header : ''}${entry.value}\n');
  }
  return checkImports(_root);
}

/// The `rule path` pairs of [violations], for compact assertions.
List<String> _ids(List<Violation> violations) => [
  for (final v in violations) '${v.rule} ${v.path}',
];

void main() {
  setUp(() => _root = Directory.systemTemp.createTempSync('check_imports'));
  tearDown(() => _root.deleteSync(recursive: true));

  group('platform-imports', () {
    test('dart:io in lib/core fails', () {
      expect(_ids(_check({'lib/core/x.dart': "import 'dart:io';"})), [
        'platform-imports lib/core/x.dart',
      ]);
    });

    test('dart:js_interop and package:web outside platform fail', () {
      expect(
        _ids(
          _check({
            'lib/shared/a.dart': "import 'dart:js_interop';",
            'lib/shared/b.dart': "import 'package:web/web.dart';",
          }),
        ),
        [
          'platform-imports lib/shared/a.dart',
          'platform-imports lib/shared/b.dart',
        ],
      );
    });

    test('dart:io under lib/platform and packages passes', () {
      expect(
        _check({
          'lib/platform/paths/paths_io.dart': "import 'dart:io';",
          'packages/soundspan_api/lib/a.dart': "import 'dart:io';",
        }),
        isEmpty,
      );
    });
  });

  group('playback-packages', () {
    test('just_audio in the playback controller fails', () {
      expect(
        _ids(
          _check({
            'lib/core/playback/playback_controller.dart':
                "import 'package:just_audio/just_audio.dart';",
          }),
        ),
        ['playback-packages lib/core/playback/playback_controller.dart'],
      );
    });

    test('just_audio and media_kit under engines pass', () {
      expect(
        _check({
          'lib/core/playback/engines/a.dart':
              "import 'package:just_audio/just_audio.dart';",
          'lib/core/playback/engines/b.dart':
              "import 'package:media_kit/media_kit.dart';",
        }),
        isEmpty,
      );
    });
  });

  group('dio-boundary', () {
    test('dio in a feature data layer fails', () {
      expect(
        _ids(
          _check({
            'lib/features/home/data/x.dart': "import 'package:dio/dio.dart';",
          }),
        ),
        ['dio-boundary lib/features/home/data/x.dart'],
      );
    });

    test('dio in core/downloads and the API package passes', () {
      expect(
        _check({
          'lib/core/downloads/x.dart': "import 'package:dio/dio.dart';",
          'packages/soundspan_api/lib/x.dart': "import 'package:dio/dio.dart';",
        }),
        isEmpty,
      );
    });
  });

  group('feature-isolation', () {
    test('importing another feature by relative path fails', () {
      expect(
        _ids(
          _check({
            'lib/features/album/ui/a.dart': "import '../../artist/ui/b.dart';",
            'lib/features/artist/ui/b.dart': '',
          }),
        ),
        ['feature-isolation lib/features/album/ui/a.dart'],
      );
    });

    test('importing another feature by package uri fails, exports too', () {
      expect(
        _ids(
          _check({
            'lib/features/album/ui/a.dart':
                "import 'package:soundspan/features/artist/ui/b.dart';",
            'lib/features/album/album.dart':
                "export 'package:soundspan/features/artist/data/c.dart';",
          }),
        ),
        [
          'feature-isolation lib/features/album/album.dart',
          'feature-isolation lib/features/album/ui/a.dart',
        ],
      );
    });

    test("importing the other feature's barrel passes", () {
      expect(
        _check({
          'lib/features/album/ui/a.dart':
              "import 'package:soundspan/features/artist/artist.dart';",
          'lib/features/album/ui/c.dart': "import '../../artist/artist.dart';",
          'lib/features/album/ui/d.dart': "import '../domain/album.dart';",
        }),
        isEmpty,
      );
    });
  });

  group('pure-domain', () {
    test('flutter in a domain file fails', () {
      expect(
        _ids(
          _check({
            'lib/features/home/domain/x.dart':
                "import 'package:flutter/widgets.dart';",
          }),
        ),
        ['pure-domain lib/features/home/domain/x.dart'],
      );
    });

    test('dart:ui, drift and dio in a domain file fail', () {
      expect(
        _ids(
          _check({
            'lib/features/home/domain/a.dart': "import 'dart:ui';",
            'lib/features/home/domain/b.dart':
                "import 'package:drift/drift.dart';",
            'lib/core/downloads/domain/c.dart':
                "import 'package:dio/dio.dart';",
          }),
        ),
        [
          'pure-domain lib/core/downloads/domain/c.dart',
          'pure-domain lib/features/home/domain/a.dart',
          'pure-domain lib/features/home/domain/b.dart',
        ],
      );
    });

    test('collection in a domain file passes', () {
      expect(
        _check({
          'lib/features/home/domain/x.dart':
              "import 'package:collection/collection.dart';",
        }),
        isEmpty,
      );
    });
  });

  group('ui-no-data', () {
    test('ui importing data fails', () {
      expect(
        _ids(
          _check({
            'lib/features/home/ui/x.dart': "import '../data/repo.dart';",
          }),
        ),
        ['ui-no-data lib/features/home/ui/x.dart'],
      );
    });

    test('ui importing domain passes', () {
      expect(
        _check({
          'lib/features/home/ui/x.dart': "import '../domain/entity.dart';",
        }),
        isEmpty,
      );
    });
  });

  group('core-direction', () {
    test('storage importing auth fails', () {
      expect(
        _ids(
          _check({
            'lib/core/storage/x.dart':
                "import 'package:soundspan/core/auth/y.dart';",
          }),
        ),
        ['core-direction lib/core/storage/x.dart'],
      );
    });

    test('siblings at the same level may not import each other', () {
      expect(
        _ids(_check({'lib/core/sync/x.dart': "import '../downloads/y.dart';"})),
        ['core-direction lib/core/sync/x.dart'],
      );
    });

    test('playback importing downloads and sync passes', () {
      expect(
        _check({
          'lib/core/playback/x.dart': "import '../downloads/y.dart';",
          'lib/core/playback/z.dart': "import '../sync/y.dart';",
          'lib/core/auth/a.dart': "import '../storage/b.dart';",
          'lib/core/profile/a.dart': "import '../auth/b.dart';",
        }),
        isEmpty,
      );
    });

    test('core importing a feature fails', () {
      expect(
        _ids(
          _check({
            'lib/core/auth/x.dart':
                "import 'package:soundspan/features/home/home.dart';",
          }),
        ),
        ['core-direction lib/core/auth/x.dart'],
      );
    });

    test('unnamed core directories: anyone may import them', () {
      expect(
        _check({
          'lib/core/storage/x.dart': "import '../logging/app_logger.dart';",
          'lib/core/logging/a.dart': "import '../storage/b.dart';",
          'lib/core/logging/c.dart': "import '../connectivity/d.dart';",
        }),
        isEmpty,
      );
    });

    test('unnamed core directories may not import named ones but storage', () {
      expect(
        _ids(
          _check({'lib/core/logging/x.dart': "import '../auth/session.dart';"}),
        ),
        ['core-direction lib/core/logging/x.dart'],
      );
    });
  });

  group('source-agnostic', () {
    test('a field named tidalTrackId fails', () {
      expect(
        _ids(_check({'lib/core/x.dart': 'class T { String? tidalTrackId; }'})),
        ['source-agnostic lib/core/x.dart'],
      );
    });

    test('streamSource and youtubeVideoId in the API package fail', () {
      expect(
        _ids(
          _check({
            'packages/soundspan_api/lib/a.dart': 'const streamSource = 1;',
            'packages/soundspan_api/lib/b.dart':
                'void f(String youtubeVideoId) {}',
          }),
        ),
        [
          'source-agnostic packages/soundspan_api/lib/a.dart',
          'source-agnostic packages/soundspan_api/lib/b.dart',
        ],
      );
    });

    test('a string inspection on a playback id fails', () {
      expect(
        _ids(
          _check({
            'lib/core/x.dart': "bool f(dynamic track) => track.playbackId.value.startsWith('t.');",
            'lib/core/y.dart': 'Object g(String playbackID) => playbackID[0];',
          }),
        ),
        ['source-agnostic lib/core/x.dart', 'source-agnostic lib/core/y.dart'],
      );
    });

    test('comparing, hashing and interpolating a playback id passes', () {
      expect(
        _check({
          'lib/core/x.dart': r'''
bool f(dynamic a, dynamic b) => a.playbackId == b.playbackId;
int h(dynamic a) => a.playbackId.hashCode;
String s(dynamic a) => 'id ${a.playbackId}';
bool c(List<String> ids, String playbackId) => ids.contains(playbackId);
''',
        }),
        isEmpty,
      );
    });
  });

  group('colour-literal', () {
    test('Color(...) and Colors.red in a shared widget fail', () {
      expect(
        _ids(
          _check({
            'lib/shared/widgets/x.dart': '''
const a = Color(0xFF000000);
final b = Colors.red;
final c = Color.fromARGB(255, 0, 0, 0);
''',
          }),
        ),
        [
          'colour-literal lib/shared/widgets/x.dart',
          'colour-literal lib/shared/widgets/x.dart',
          'colour-literal lib/shared/widgets/x.dart',
        ],
      );
    });

    test('colour literals under lib/app/theme pass', () {
      expect(
        _check({
          'lib/app/theme/tokens.dart': '''
const a = Color(0xFF000000);
final b = Colors.red;
''',
        }),
        isEmpty,
      );
    });

    test('Colors.transparent passes anywhere', () {
      expect(
        _check({'lib/shared/widgets/x.dart': 'final a = Colors.transparent;'}),
        isEmpty,
      );
    });
  });

  group('clock', () {
    test('DateTime.now() in core/sync fails', () {
      expect(
        _ids(_check({'lib/core/sync/x.dart': 'final t = DateTime.now();'})),
        ['clock lib/core/sync/x.dart'],
      );
    });

    test('DateTime.now() under lib/platform passes', () {
      expect(
        _check({
          'lib/platform/clock/system_clock.dart': 'final t = DateTime.now();',
        }),
        isEmpty,
      );
    });
  });

  group('spdx', () {
    test('a file without the header fails', () {
      expect(
        _ids(
          _check({
            'lib/a.dart': 'const a = 1;',
            'test/a_test.dart': 'void main() {}',
            'packages/soundspan_api/test/b_test.dart': 'void main() {}',
          }, header: false),
        ),
        [
          'spdx lib/a.dart',
          'spdx packages/soundspan_api/test/b_test.dart',
          'spdx test/a_test.dart',
        ],
      );
    });

    test('generated files without the header pass', () {
      expect(
        _check({
          'lib/a.g.dart': 'const a = 1;',
          'lib/b.freezed.dart': 'const b = 1;',
          'lib/app/l10n/generated/c.dart': 'const c = 1;',
        }, header: false),
        isEmpty,
      );
    });
  });

  test('generated files and spikes/ are skipped by every rule', () {
    expect(
      _check({
        'lib/core/x.g.dart': "import 'dart:io';",
        'packages/soundspan_api/lib/src/generated/a.dart':
            'const streamSource = 1;',
        'spikes/s1/lib/a.dart': "import 'dart:io';",
      }),
      isEmpty,
    );
  });

  test('violations carry the line number and are sorted by path and line', () {
    final violations = _check({
      'lib/b.dart': "import 'dart:io';\nfinal t = DateTime.now();",
      'lib/a.dart': "import 'dart:io';",
    });
    expect(
      [for (final v in violations) '${v.path}:${v.line} ${v.rule}'],
      [
        'lib/a.dart:3 platform-imports',
        'lib/b.dart:3 platform-imports',
        'lib/b.dart:4 clock',
      ],
    );
  });

  test('the real client tree has no violations', () {
    final client = Directory(p.normalize(p.join(Directory.current.path)));
    expect([for (final v in checkImports(client)) v.toString()], isEmpty);
  });
}
