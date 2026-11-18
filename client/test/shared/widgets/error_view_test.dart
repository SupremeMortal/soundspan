// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/shared/providers/capability_refresh.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../helpers/guidelines.dart';
import '../../helpers/pump_app.dart';

void main() {
  const marker = 'SERVER-TEXT-MARKER';
  final retry = find.text('Retry');

  Future<int Function()> pump(
    WidgetTester tester,
    Object error, {
    VoidCallback? onRetry,
  }) async {
    var refreshes = 0;
    await tester.pumpApp(
      ErrorView(error: error, onRetry: onRetry ?? () {}),
      overrides: [
        capabilityRefreshProvider.overrideWithValue(() => refreshes++),
      ],
    );
    return () => refreshes;
  }

  testWidgets('Unauthenticated shows nothing', (tester) async {
    await pump(tester, const Unauthenticated(status: 401));

    expect(find.byType(Text), findsNothing);
    expect(retry, findsNothing);
  });

  testWidgets('Offline shows the offline empty state with Retry', (
    tester,
  ) async {
    var retries = 0;
    await pump(tester, const Offline(), onRetry: () => retries++);

    expect(find.text('You’re offline'), findsOneWidget);
    await tester.tap(retry);
    expect(retries, 1);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('FeatureDisabled shows not available, without Retry', (
    tester,
  ) async {
    await pump(tester, const FeatureDisabled(status: 404));

    expect(find.text('Not available on this server'), findsOneWidget);
    expect(retry, findsNothing);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('FeatureDisabled requests a capability refresh exactly once', (
    tester,
  ) async {
    final refreshes = await pump(tester, const FeatureDisabled(status: 404));
    await tester.pump();
    // A rebuild with an equal error does not ask again.
    await tester.pumpApp(
      ErrorView(error: const FeatureDisabled(status: 404), onRetry: () {}),
    );

    expect(refreshes(), 1);
  });

  testWidgets('RateLimited shows try again shortly, with Retry', (
    tester,
  ) async {
    var retries = 0;
    await pump(
      tester,
      const RateLimited(retryAfter: Duration(seconds: 1), status: 429),
      onRetry: () => retries++,
    );

    expect(find.text('Too many requests, try again shortly'), findsOneWidget);
    await tester.tap(retry);
    expect(retries, 1);
  });

  testWidgets('ServerError shows a server problem, with Retry', (tester) async {
    await pump(tester, const ServerError(status: 500));

    expect(find.text('The server ran into a problem'), findsOneWidget);
    expect(retry, findsOneWidget);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('Upstream shows a server problem, with Retry', (tester) async {
    await pump(tester, const Upstream(status: 502));

    expect(find.text('The server ran into a problem'), findsOneWidget);
    expect(retry, findsOneWidget);
  });

  testWidgets('NotFound shows no longer available, without Retry', (
    tester,
  ) async {
    await pump(tester, const NotFound(status: 404));

    expect(find.text('This item is no longer available'), findsOneWidget);
    expect(retry, findsNothing);
    await expectMeetsGuidelines(tester);
  });

  testWidgets('another ApiException shows the generic message, with Retry', (
    tester,
  ) async {
    await pump(tester, const Forbidden(status: 403));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(retry, findsOneWidget);
  });

  testWidgets('a non-API error shows the generic message, with Retry', (
    tester,
  ) async {
    await pump(tester, StateError(marker));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(retry, findsOneWidget);
    expect(find.textContaining(marker), findsNothing);
  });

  testWidgets('server text is never shown', (tester) async {
    const errors = <ApiException>[
      Offline(serverMessage: marker),
      FeatureDisabled(status: 404, serverMessage: marker),
      RateLimited(
        retryAfter: Duration(seconds: 1),
        status: 429,
        serverMessage: marker,
      ),
      ServerError(status: 500, serverMessage: marker),
      Upstream(status: 502, serverMessage: marker),
      NotFound(status: 404, serverMessage: marker),
      Forbidden(status: 403, code: marker, serverMessage: marker),
    ];
    for (final error in errors) {
      await pump(tester, error);
      expect(find.textContaining(marker), findsNothing, reason: '$error');
      expect(find.textContaining('status'), findsNothing, reason: '$error');
    }
  });

  testWidgets('no Retry button without onRetry', (tester) async {
    await tester.pumpApp(const ErrorView(error: ServerError(status: 500)));

    expect(find.text('The server ran into a problem'), findsOneWidget);
    expect(retry, findsNothing);
  });
}
