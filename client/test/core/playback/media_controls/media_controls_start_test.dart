// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/playback/engines/fake_engine.dart';
import 'package:soundspan/core/playback/engines/player_engine_provider.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls_providers.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';

import '../../../helpers/fake_media_controls.dart';
import '../../profile/profile_harness.dart';
import '../queue/queue_test_items.dart';

void main() {
  Future<(ProfileHarness, FakeMediaControls, ProfileRuntime)> start() async {
    final controls = FakeMediaControls();
    final h = await ProfileHarness.create(
      overrides: [
        mediaControlsProvider.overrideWithValue(controls),
        playerEngineBuilderProvider.overrideWithValue(FakeEngine.new),
      ],
    );
    final runtime = h.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);
    return (h, controls, runtime);
  }

  test('after the first frame the controls are initialised once with the '
      'host', () async {
    expect(postFirstFrameTasks, contains(startMediaControls));
    final (h, controls, _) = await start();

    await startMediaControls(h.root);
    await pumpEventQueue();

    expect(controls.initCount, 1);
    expect(controls.handler, same(h.root.read(mediaControlsHostProvider)));
  });

  test('no active profile sends the empty state', () async {
    final (h, controls, _) = await start();

    await startMediaControls(h.root);
    await pumpEventQueue();

    expect(controls.updates, [MediaSessionState.empty]);
    expect(h.root.read(mediaControlsHostProvider).binder, isNull);
  });

  test('switching the active profile rebinds to its controller', () async {
    final (h, controls, runtime) = await start();
    await runtime.switchTo(h.a);
    await startMediaControls(h.root);
    await pumpEventQueue();
    final host = h.root.read(mediaControlsHostProvider);
    final first = host.binder;
    expect(first, isNotNull);
    final a = runtime.container!.read(playbackControllerProvider);

    await runtime.switchTo(h.b);
    await pumpEventQueue();

    expect(host.binder, isNot(same(first)));
    expect(host.binder, isNotNull);
    final b = runtime.container!.read(playbackControllerProvider);
    expect(b, isNot(same(a)));
    expect(controls.updates, contains(MediaSessionState.empty));

    await b.append(trackItems(['x']));
    await pumpEventQueue();
    expect(controls.last!.queueItemId, 'x');

    await runtime.switchTo(null);
    await pumpEventQueue();
    expect(host.binder, isNull);
    expect(controls.last, MediaSessionState.empty);
  });
}
