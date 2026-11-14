// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_disposer.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/profile_scope.dart';

import 'profile_harness.dart';

/// Records the profile id each time it builds.
class _Probe extends ConsumerWidget {
  const new(this.builds);

  final List<String> builds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(profileContextProvider).profile.id;
    builds.add(id);
    return Text(id, textDirection: TextDirection.ltr);
  }
}

void main() {
  Future<(ProfileHarness, ProfileRuntime, List<String>)> pumpScope(
    WidgetTester tester, {
    bool reduceMotion = false,
  }) async {
    late ProfileHarness h;
    late ProfileRuntime runtime;
    await tester.runAsync(() async {
      h = await ProfileHarness.create();
      runtime = h.root.read(profileRuntimeProvider);
      await runtime.switchTo(h.a);
    });
    addTearDown(() => tester.runAsync(runtime.dispose));
    final builds = <String>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.root,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: ProfileScope(child: _Probe(builds)),
        ),
      ),
    );
    return (h, runtime, builds);
  }

  testWidgets("descendants read B's context after a switch", (tester) async {
    final (h, runtime, builds) = await pumpScope(tester);
    expect(find.text(h.a), findsOneWidget);

    await tester.runAsync(() => runtime.switchTo(h.b));
    await tester.pumpAndSettle();

    expect(find.text(h.b), findsOneWidget);
    expect(find.text(h.a), findsNothing);
  });

  testWidgets('no descendant of A builds during or after the switch', (
    tester,
  ) async {
    final (h, runtime, builds) = await pumpScope(tester);
    expect(builds, [h.a]);

    // Hold the switch open in A's closers to look at a frame during it.
    final gate = Completer<void>();
    runtime.container!
        .read(profileDisposerProvider)
        .register(() => gate.future);
    late Future<void> switching;
    await tester.runAsync(() async {
      switching = runtime.switchTo(h.b);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    expect(runtime.state.value, ProfileRuntimeState.switching);
    await tester.pump();
    expect(find.text(h.a), findsNothing);
    gate.complete();
    await tester.runAsync(() => switching);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(builds.first, h.a);
    expect(builds.skip(1), everyElement(h.b));
    expect(builds.skip(1), isNotEmpty);
  });

  testWidgets('the new profile fades in over 150 ms', (tester) async {
    final (h, runtime, _) = await pumpScope(tester);
    await tester.runAsync(() => runtime.switchTo(h.b));
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: find.text(h.b), matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, lessThan(1));
    await tester.pump(const Duration(milliseconds: 150));
    expect(fade.opacity.value, 1);
  });

  testWidgets('reduced motion skips the cross-fade', (tester) async {
    final (h, runtime, _) = await pumpScope(tester, reduceMotion: true);
    await tester.runAsync(() => runtime.switchTo(h.b));
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: find.text(h.b), matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('without an active profile nothing is built', (tester) async {
    final (h, runtime, builds) = await pumpScope(tester);
    await tester.runAsync(() => runtime.switchTo(null));
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
    expect(builds, [h.a]);
  });
}
