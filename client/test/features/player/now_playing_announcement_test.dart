// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/features/player/player.dart';

import '../../helpers/pump_app.dart';
import 'ui/player_rig.dart';

void main() {
  /// The messages sent on the accessibility channel, recorded from now on.
  List<String> recordAnnouncements(WidgetTester tester) {
    final messages = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final event = message! as Map<Object?, Object?>;
        if (event['type'] == 'announce') {
          final data = event['data']! as Map<Object?, Object?>;
          messages.add(data['message']! as String);
          // Polite is the default and is left out of the event.
          expect(data.containsKey('assertiveness'), isFalse);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    return messages;
  }

  /// Pumps the announcer over [rig]'s controller. Semantics are on unless
  /// the test turns them off (`semanticsEnabled: false`).
  Future<List<String>> pump(WidgetTester tester, PlayerRig rig) async {
    final messages = recordAnnouncements(tester);
    await tester.pumpApp(
      const NowPlayingAnnouncer(child: SizedBox.shrink()),
      overrides: rig.overrides,
    );
    await rig.settle(tester);
    return messages;
  }

  testWidgets('announces the track a change while playing moves to', (
    tester,
  ) async {
    final rig = PlayerRig();
    final messages = await pump(tester, rig);
    await rig.start(tester);
    expect(messages, ['Now playing Song a by The Band a']);

    unawaited(rig.controller.next());
    await rig.settle(tester);

    expect(messages, [
      'Now playing Song a by The Band a',
      'Now playing Song b by The Band b',
    ]);
    await rig.close(tester);
  });

  testWidgets('announces an episode with its podcast', (tester) async {
    final rig = PlayerRig();
    final messages = await pump(tester, rig);
    await rig.start(tester, items: [playerEpisode('1')]);

    expect(messages, ['Episode 1, The Show']);
    await rig.close(tester);
  });

  testWidgets('is silent without a screen reader', (tester) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
    final rig = PlayerRig();
    final messages = await pump(tester, rig);
    await rig.start(tester);
    unawaited(rig.controller.next());
    await rig.settle(tester);

    expect(messages, isEmpty);
    await rig.close(tester);
  }, semanticsEnabled: false);

  testWidgets('is silent for the queue restored at start-up', (tester) async {
    final rig = PlayerRig();
    final messages = await pump(tester, rig);
    unawaited(
      rig.controller.restoreQueue(
        QueueState(items: [playerItem('a'), playerItem('b')], cursor: 0),
        position: Duration.zero,
      ),
    );
    await rig.settle(tester);
    unawaited(rig.controller.play());
    await rig.settle(tester);

    expect(messages, isEmpty);
    await rig.close(tester);
  });

  testWidgets('is silent for a change while paused', (tester) async {
    final rig = PlayerRig();
    final messages = await pump(tester, rig);
    await rig.start(tester, play: false);
    messages.clear();
    unawaited(rig.controller.next());
    await rig.settle(tester);

    expect(messages, isEmpty);
    await rig.close(tester);
  });

  testWidgets('announces the same queue entry once', (tester) async {
    final rig = PlayerRig();
    final messages = await pump(tester, rig);
    await rig.start(tester);
    unawaited(rig.controller.pause());
    await rig.settle(tester);
    unawaited(rig.controller.play());
    await rig.settle(tester);

    expect(messages, ['Now playing Song a by The Band a']);
    await rig.close(tester);
  });
}
