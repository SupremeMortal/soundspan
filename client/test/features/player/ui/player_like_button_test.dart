// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/sync/data/confirmed_track_preferences.dart';
import 'package:soundspan/features/player/player.dart';
import 'package:soundspan/features/player/ui/player_like_button.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';
import 'player_rig.dart';

void main() {
  late FakeTrackLikes likes;
  late ConfirmedTrackPreferences confirmed;

  setUp(() {
    likes = FakeTrackLikes();
    confirmed = ConfirmedTrackPreferences();
  });

  Future<PlayerRig> pumpMini(
    WidgetTester tester, {
    List<QueueItem>? items,
  }) async {
    final rig = PlayerRig();
    await tester.pumpApp(
      const Align(alignment: Alignment.bottomCenter, child: MiniPlayer()),
      overrides: [
        ...rig.overrides,
        trackLikesProvider.overrideWithValue(likes),
        confirmedTrackPreferencesProvider.overrideWithValue(confirmed),
      ],
    );
    await rig.start(tester, items: items);
    return rig;
  }

  testWidgets('the playing track has a heart that likes it', (tester) async {
    final rig = await pumpMini(tester);

    expect(find.byTooltip('Like'), findsOneWidget);
    await tester.tap(find.byTooltip('Like'));
    await rig.settle(tester);

    expect(likes.toggled.single.playbackId, const PlaybackId('pb-a'));
    expect(likes.toggled.single.isLiked, isFalse);
    await rig.close(tester);
  });

  testWidgets('a confirmed like fills the heart and the next tap removes it', (
    tester,
  ) async {
    final rig = await pumpMini(tester);

    confirmed.record('pb-a', Preference.liked);
    await rig.settle(tester);

    expect(find.byTooltip('Remove like'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove like'));
    await rig.settle(tester);
    expect(likes.toggled.single.isLiked, isTrue);
    await rig.close(tester);
  });

  testWidgets('an episode has no heart', (tester) async {
    final rig = await pumpMini(tester, items: [playerEpisode('a')]);

    expect(find.byKey(PlayerLikeButton.likeKey), findsNothing);
    await rig.close(tester);
  });

  test('confirmed preferences are watched per track', () async {
    final values = <Preference?>[];
    final sub = confirmed.watch('pb-a').listen(values.add);
    confirmed
      ..record('pb-b', Preference.liked)
      ..record('pb-a', Preference.liked)
      ..record('pb-a', Preference.liked)
      ..record('pb-a', Preference.neutral);
    await Future<void>.delayed(Duration.zero);

    expect(values, [null, Preference.liked, Preference.neutral]);
    await sub.cancel();
    await confirmed.dispose();
  });
}
