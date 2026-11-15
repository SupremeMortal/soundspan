// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/auth/device_link_code.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/features/connect/ui/device_link_panel.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/shared/widgets/code_cells.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../../helpers/fake_clock.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import 'device_link_fakes.dart';

const _defaultName = 'studio (soundspan Linux)';
const _generate = 'Generate a new code in the web UI.';

/// What [_pump] built.
class _Panel {
  new(this.signIn, this.clock, this.linked);

  final FakeDeviceLinkSignIn signIn;
  final FakeClock clock;
  final List<Profile> linked;
}

Future<_Panel> _pump(
  WidgetTester tester, {
  String? initialCode,
  Size size = TestSizes.compact,
}) async {
  final signIn = FakeDeviceLinkSignIn();
  final clock = FakeClock();
  final linked = <Profile>[];
  await tester.pumpApp(
    Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DeviceLinkPanel(
          baseUrl: Uri.parse(linkBase),
          initialCode: initialCode,
          onLinked: (profile) async => linked.add(profile),
        ),
      ),
    ),
    size: size,
    clock: clock,
    overrides: [
      deviceLinkSignInProvider.overrideWithValue(signIn),
      deviceInfoProvider.overrideWithValue(
        const DeviceInfo(osLabel: 'Linux', isMobile: false, hostName: 'studio'),
      ),
    ],
  );
  await tester.pump();
  return _Panel(signIn, clock, linked);
}

Finder get _link => find.widgetWithText(FilledButton, 'Link');

bool _linkEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(_link).onPressed != null;

Finder get _name => find.widgetWithText(TextField, 'Device name');

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(
    find.descendant(
      of: find.byType(CodeCells),
      matching: find.byType(EditableText),
    ),
    code,
  );
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(_link);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('shows the three steps, the cells, the prefilled device name '
      'and a Link button enabled once six cells are filled', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Open soundspan in a browser'), findsOne);
    expect(find.textContaining('Settings → Link Device'), findsOne);
    expect(find.textContaining('Generate Code'), findsOne);
    expect(find.byType(CodeCells), findsOne);
    expect(tester.widget<TextField>(_name).controller!.text, _defaultName);
    expect(_linkEnabled(tester), isFalse);

    await _enterCode(tester, 'abc23');
    expect(_linkEnabled(tester), isFalse);
    await _enterCode(tester, 'abc234');
    expect(_linkEnabled(tester), isTrue);
  });

  testWidgets('Link submits the code at the base URL and hands the profile '
      'on', (tester) async {
    final panel = await _pump(tester);
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    final call = panel.signIn.calls.single;
    expect(call.baseUrl, Uri.parse(linkBase));
    expect(call.code, DeviceLinkCode.tryParse('ABC234'));
    expect(call.deviceName, _defaultName);
    expect(panel.linked, [linkedProfile]);
  });

  testWidgets('an edited device name is what submit receives', (tester) async {
    final panel = await _pump(tester);
    await tester.enterText(_name, '  Kitchen   tablet ');
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    expect(panel.signIn.calls.single.deviceName, 'Kitchen tablet');
  });

  testWidgets('an emptied device name falls back to the default', (
    tester,
  ) async {
    final panel = await _pump(tester);
    await tester.enterText(_name, '   ');
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    expect(panel.signIn.calls.single.deviceName, _defaultName);
  });

  for (final (failure, sentence) in [
    (const DeviceLinkFailure.invalidCode(), 'That code does not exist.'),
    (const DeviceLinkFailure.codeUsed(), 'That code has already been used.'),
    (const DeviceLinkFailure.codeExpired(), 'That code has expired.'),
  ]) {
    testWidgets('$failure renders its sentence and the way to a new code', (
      tester,
    ) async {
      final panel = await _pump(tester);
      panel.signIn.answer = () async => throw failure;
      await _enterCode(tester, 'abc234');
      await _submit(tester);

      expect(find.text('$sentence $_generate'), findsOne);
      expect(panel.linked, isEmpty);
      expect(_linkEnabled(tester), isTrue);
    });
  }

  testWidgets("rejected shows the server's message", (tester) async {
    final panel = await _pump(tester);
    panel.signIn.answer = () async =>
        throw const DeviceLinkFailure.rejected('Device name is too long');
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    expect(find.text('Device name is too long'), findsOne);
  });

  testWidgets('rejected without a message says the code was not accepted', (
    tester,
  ) async {
    final panel = await _pump(tester);
    panel.signIn.answer = () async =>
        throw const DeviceLinkFailure.rejected(null);
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    expect(find.textContaining('did not accept the code'), findsOne);
  });

  testWidgets('rateLimited(30 s) disables Link and counts down with the clock '
      'until it re-enables the button at zero', (tester) async {
    final panel = await _pump(tester);
    panel.signIn.answer = () async =>
        throw const DeviceLinkFailure.rateLimited(Duration(seconds: 30));
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    expect(find.text('Too many attempts. Try again in 30 seconds.'), findsOne);
    expect(_linkEnabled(tester), isFalse);

    panel.clock.advance(const Duration(seconds: 29));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Too many attempts. Try again in 1 second.'), findsOne);
    expect(_linkEnabled(tester), isFalse);

    panel.clock.advance(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Too many attempts'), findsNothing);
    expect(_linkEnabled(tester), isTrue);
  });

  testWidgets('any other ApiException goes through ErrorView, whose Retry '
      'submits again', (tester) async {
    final panel = await _pump(tester);
    panel.signIn.answer = () async => throw const ServerError(status: 500);
    await _enterCode(tester, 'abc234');
    await _submit(tester);

    expect(find.byType(ErrorView), findsOne);
    expect(find.text('The server ran into a problem'), findsOne);

    panel.signIn.answer = () async => linkedProfile;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(panel.signIn.calls, hasLength(2));
    expect(panel.linked, [linkedProfile]);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('a prefilled code submits once after the panel is shown', (
    tester,
  ) async {
    final panel = await _pump(tester, initialCode: 'abc234');

    expect(panel.signIn.calls.single.code.value, 'ABC234');
    expect(panel.linked, [linkedProfile]);
  });

  testWidgets('a prefilled code is not submitted again after a failure', (
    tester,
  ) async {
    final signIn = FakeDeviceLinkSignIn()
      ..answer = () async => throw const DeviceLinkFailure.codeExpired();
    await tester.pumpApp(
      Scaffold(
        body: DeviceLinkPanel(
          baseUrl: Uri.parse(linkBase),
          initialCode: 'abc234',
          onLinked: (_) async {},
        ),
      ),
      overrides: [deviceLinkSignInProvider.overrideWithValue(signIn)],
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(signIn.calls, hasLength(1));
    expect(find.textContaining('That code has expired.'), findsOne);
  });

  testWidgets('a prefilled invalid code is not submitted', (tester) async {
    final panel = await _pump(tester, initialCode: 'abc');
    expect(panel.signIn.calls, isEmpty);
  });

  testWidgets('the Link button is disabled while a submit is in flight', (
    tester,
  ) async {
    final panel = await _pump(tester);
    final pending = Completer<Profile>();
    panel.signIn.answer = () => pending.future;
    await _enterCode(tester, 'abc234');
    await _submit(tester);
    expect(_linkEnabled(tester), isFalse);

    pending.complete(linkedProfile);
    await tester.pump();
    expect(panel.linked, [linkedProfile]);
  });

  for (final size in [TestSizes.compact, TestSizes.expanded]) {
    testWidgets('meets the guidelines at ${size.width.toInt()}', (
      tester,
    ) async {
      final panel = await _pump(tester, size: size);
      panel.signIn.answer = () async =>
          throw const DeviceLinkFailure.codeExpired();
      await _enterCode(tester, 'abc234');
      await _submit(tester);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await expectMeetsGuidelines(tester);
    });
  }
}
