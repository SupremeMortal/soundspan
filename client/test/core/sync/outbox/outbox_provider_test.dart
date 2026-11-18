// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:soundspan/bootstrap.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/sync/outbox/outbox.dart';
import 'package:soundspan/core/sync/outbox/outbox_handler.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';

import '../../profile/profile_harness.dart';

void main() {
  test('the outbox is per profile, counts its ops and starts after the '
      'first frame', () async {
    expect(postFirstFrameTasks, contains(startOutbox));
    final harness = await ProfileHarness.create();
    final runtime = harness.root.read(profileRuntimeProvider);
    addTearDown(runtime.dispose);

    await runtime.switchTo(harness.a);
    final a = runtime.container!;
    await startOutbox(harness.root);
    await pumpEventQueue();
    final outbox = a.read(outboxProvider);
    expect(a.read(outboxHandlerRegistryProvider)[PlayOp.type], isNotNull);
    expect(await outbox.watchCount().first, 0);

    await runtime.switchTo(harness.b);
    final b = runtime.container!.read(outboxProvider);
    expect(b, isNot(same(outbox)));
    expect(await b.watchPending().first, isEmpty);
  });
}
