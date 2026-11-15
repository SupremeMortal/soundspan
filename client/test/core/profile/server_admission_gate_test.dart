// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/core/profile/version.dart';
import 'package:soundspan/core/profile/version_gate.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/fake_clock.dart';
import '../auth/device_link_fakes.dart';

void main() {
  late FakeDeviceLinkServer server;
  late FakeClock clock;
  late SoundspanApi api;
  late VersionGateAdmission admission;

  setUp(() {
    server = FakeDeviceLinkServer();
    clock = FakeClock();
    api = server.api(
      ApiConfig(baseUrl: Uri.parse('https://music.example'), userAgent: 't'),
      issuedKey,
    );
    admission = VersionGateAdmission(
      VersionGate(Version.tryParse('2.6.0')!, Version.tryParse('2.9.0')!),
      clock,
    );
  });
  tearDown(() => api.close());

  test('a supported server gives its version and features', () async {
    final snapshot = await admission.check(api);

    expect(snapshot.serverVersion, '2.6.1');
    expect(snapshot.features, containsPair('discovery', true));
    expect(snapshot.fetchedAt, clock.now());
  });

  test('a server below the minimum throws ServerTooOld', () async {
    server.setVersion('2.5.0');

    await expectLater(
      admission.check(api),
      throwsA(
        isA<ServerTooOld>()
            .having((e) => e.serverVersion, 'serverVersion', '2.5.0')
            .having((e) => e.minServer, 'minServer', '2.6.0'),
      ),
    );
  });

  test('an unknown version is admitted', () async {
    server.setVersion('unknown');

    final snapshot = await admission.check(api);

    expect(snapshot.serverVersion, isNull);
    expect(snapshot.fetchedAt, isNotNull);
  });

  test(
    'features that cannot be read leave the snapshot without them',
    () async {
      server.answers['GET /api/system/features'] = error(403, 'nope');

      final snapshot = await admission.check(api);

      expect(snapshot.serverVersion, '2.6.1');
      expect(snapshot.features, isNull);
      expect(snapshot.fetchedAt, isNull);
    },
  );
}
