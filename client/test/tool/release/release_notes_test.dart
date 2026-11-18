// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/app/build_config.dart';

import '../../../tool/release/release_notes.dart';

const _changelog = '''
# Changelog

## [Unreleased]

### Added

- A server feature that is not a client change.

### Client

- First unreleased client change.
- Second unreleased client change
  that wraps onto a second line.
  - with a nested point.

## [2.6.1] - 2026-08-26

### Fixed

- A server fix.

### Client

- An older client change.

## [2.6.0] - 2026-08-20

### Changed

- Another server change.
''';

String _notes({String changelog = _changelog, String? previous}) =>
    releaseNotes(
      changelog: changelog,
      previousChangelog: previous,
      version: '0.2.0',
      repository: 'owner/soundspan',
    );

void main() {
  group('clientBullets', () {
    test('collects Client bullets from every release heading in order', () {
      const multiLine =
          '- Second unreleased client change\n'
          '  that wraps onto a second line.\n'
          '  - with a nested point.';

      expect(clientBullets(_changelog), [
        '- First unreleased client change.',
        multiLine,
        '- An older client change.',
      ]);
    });

    test('ignores bullets under Added and other subsections', () {
      final bullets = clientBullets(_changelog).join('\n');

      expect(bullets, isNot(contains('server')));
    });

    test('is empty without a Client subsection', () {
      expect(clientBullets('## [1.0.0]\n\n### Added\n\n- Server.\n'), isEmpty);
    });
  });

  group('releaseNotes', () {
    test('lists every Client bullet without a previous changelog', () {
      final notes = _notes();

      expect(notes, contains('- First unreleased client change.\n'));
      expect(
        notes,
        contains(
          '- Second unreleased client change\n'
          '  that wraps onto a second line.\n'
          '  - with a nested point.\n',
        ),
      );
      expect(notes, contains('- An older client change.\n'));
      expect(
        notes.indexOf('First unreleased'),
        lessThan(notes.indexOf('An older client change')),
      );
    });

    test('leaves out bullets that the previous changelog has', () {
      const previous = '''
## [2.6.1] - 2026-08-26

### Client

- An older client change.
- First unreleased client change.
''';

      final notes = _notes(previous: previous);

      expect(notes, isNot(contains('An older client change')));
      expect(notes, isNot(contains('First unreleased client change')));
      expect(notes, contains('Second unreleased client change'));
    });

    test('a bullet edited since the previous tag counts as new', () {
      const previous = '''
### Client

- First unreleased client change, before an edit.
- An older client change.
''';

      final notes = _notes(previous: previous);

      expect(notes, contains('- First unreleased client change.\n'));
      expect(notes, isNot(contains('An older client change')));
    });

    test('says so when there are no user-visible client changes', () {
      final notes = _notes(previous: _changelog);

      expect(notes, contains('No user-visible client changes.\n'));
      expect(notes, isNot(contains('- First unreleased')));
    });

    test('states that the builds are unsigned test builds', () {
      final notes = _notes();

      expect(notes, contains('unsigned test builds'));
      expect(notes, contains('SmartScreen'));
      expect(notes, contains('macOS'));
      expect(
        notes,
        contains('System Settings → Privacy & Security → Open Anyway'),
      );
      expect(notes, contains('debug'));
      expect(notes, contains('uninstall'));
      expect(notes, contains('no iOS build'));
    });

    test('says the MSIX is unsigned and points to the setup program', () {
      final notes = _notes();

      expect(
        notes,
        contains(
          'The Windows MSIX package is unsigned and installs only where '
          'unsigned packages are allowed; most users should use the Windows '
          'setup program.',
        ),
      );
    });

    test('shows the server range from BuildConfig', () {
      expect(
        _notes(),
        contains(
          'Works with soundspan server `${BuildConfig.minServer}` to '
          '`${BuildConfig.maxTestedServer}`',
        ),
      );
    });

    test('ends with a Verify downloads line naming SHA256SUMS', () {
      final notes = _notes();
      final verify = notes.indexOf('Verify downloads');

      expect(verify, greaterThan(notes.indexOf('Changes')));
      expect(notes.substring(verify), contains('SHA256SUMS'));
      expect(notes.substring(verify), contains('owner/soundspan'));
      expect(notes, endsWith('\n'));
      expect(notes, isNot(endsWith('\n\n')));
    });

    test('is stable across runs', () {
      expect(_notes(), _notes());
      expect(_notes(previous: _changelog), _notes(previous: _changelog));
    });
  });
}
