// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:audio_service_mpris/mpris.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';

/// The MPRIS player interface.
const String _player = 'org.mpris.MediaPlayer2.Player';

/// The Volume property's value in [response].
double _volumeIn(DBusMethodResponse response) =>
    ((response as DBusMethodSuccessResponse).values.single as DBusVariant).value
        .asDouble();

void main() {
  // The vendored `audio_service_mpris` (third_party/) is patched so that the
  // MPRIS Volume is the player's own, which desktop media widgets read and
  // set.
  test('Volume reports the volume shown, clamped to 0.0–1.0', () async {
    final mpris = OrgMprisMediaPlayer2(identity: 'soundspan');
    expect(_volumeIn(await mpris.getProperty(_player, 'Volume')), 1);

    mpris.volume = 0.3;
    expect(_volumeIn(await mpris.getProperty(_player, 'Volume')), 0.3);

    mpris.volume = 1.5;
    expect(mpris.volume, 1);
    mpris.volume = -1;
    expect(mpris.volume, 0);
    mpris.volume = double.nan;
    expect(mpris.volume, 0);
  });

  test('setting Volume asks for the clamped value and leaves the volume '
      'shown to the player', () async {
    final mpris = OrgMprisMediaPlayer2(identity: 'soundspan');
    final asked = <double>[];
    mpris.volumeStream.listen(asked.add);

    final set = await mpris.setProperty(
      _player,
      'Volume',
      const DBusDouble(0.4),
    );
    await mpris.setProperty(_player, 'Volume', const DBusDouble(-0.2));
    await mpris.setProperty(_player, 'Volume', const DBusDouble(1.2));
    await pumpEventQueue();

    expect(set, isA<DBusMethodSuccessResponse>());
    expect(asked, [0.4, 0, 1]);
    expect(mpris.volume, 1);
  });
}
