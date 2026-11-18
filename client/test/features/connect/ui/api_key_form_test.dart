// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/api_key_sign_in.dart';
import 'package:soundspan/core/auth/password_sign_in.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/features/connect/ui/api_key_form.dart';
import 'package:soundspan/features/connect/ui/device_link_panel.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/url_opener/url_opener.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../../core/auth/password_sign_in_fakes.dart';
import '../../../helpers/fake_clock.dart';
import '../../../helpers/guidelines.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_root.dart';
import '../connect_harness.dart';
import 'api_key_fakes.dart';
import 'device_link_fakes.dart';

const _pasted = 'pasted-key-0123456789abcdef';
const _expiry =
    'This key’s expiry date is not known to the app. You will be asked to '
    'sign in again when the server stops accepting it.';
const _useApiKey = 'Use an API key';

Finder get _field => find.widgetWithText(TextField, 'API key');

Finder get _signIn => find.widgetWithText(FilledButton, 'Sign in');

TextField _textField(WidgetTester tester) => tester.widget<TextField>(_field);

/// What [_pumpForm] built.
class _Form {
  new(this.signIn, this.clock, this.signedIn);

  final FakeApiKeySignIn signIn;
  final FakeClock clock;
  final List<Object> signedIn;
}

Future<_Form> _pumpForm(
  WidgetTester tester, {
  Size size = TestSizes.compact,
  ThemeMode theme = ThemeMode.dark,
}) async {
  final signIn = FakeApiKeySignIn();
  final clock = FakeClock();
  final signedIn = <Object>[];
  await tester.pumpApp(
    Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ApiKeyForm(
          baseUrl: Uri.parse(linkBase),
          onSignedIn: (profile) async => signedIn.add(profile),
        ),
      ),
    ),
    size: size,
    theme: theme,
    clock: clock,
    overrides: [apiKeySignInProvider.overrideWithValue(signIn)],
  );
  await tester.pump();
  return _Form(signIn, clock, signedIn);
}

Future<void> _enterAndSubmit(
  WidgetTester tester, [
  String key = _pasted,
]) async {
  await tester.enterText(_field, key);
  await tester.pump();
  await tester.tap(_signIn);
  await tester.pump();
  await tester.pump();
}

/// Answers `Clipboard.getData` with [text].
void _mockClipboard(WidgetTester tester, String? text) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => call.method == 'Clipboard.getData'
        ? (text == null ? null : <String, Object?>{'text': text})
        : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
}

Future<void> _meetsGuidelines(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await expectMeetsGuidelines(tester);
}

ProbeResult _result({bool localLoginEnabled = true, bool oidcEnabled = false}) {
  final url = Uri.parse(linkBase);
  return ProbeResult(
    baseUrl: url,
    requestedBaseUrl: url,
    localLoginEnabled: localLoginEnabled,
    oidcEnabled: oidcEnabled,
    isCleartext: false,
    isPrivateHost: false,
  );
}

/// What [_pumpScreen] built.
class _Screen {
  new(this.root, this.opener);

  final TestRoot root;
  final RecordingUrlOpener opener;
}

Future<_Screen> _pumpScreen(
  WidgetTester tester,
  ProbeResult result, {
  PlatformCapabilities capabilities = PlatformCapabilities.android,
}) async {
  final opener = RecordingUrlOpener();
  final root = await tester.pumpSoundspanApp(
    clock: FakeClock(),
    overrides: [
      passwordSignInProvider.overrideWithValue(
        PasswordSignIn(FakeLoginClient().factory),
      ),
      deviceLinkSignInProvider.overrideWithValue(FakeDeviceLinkSignIn()),
      apiKeySignInProvider.overrideWithValue(FakeApiKeySignIn()),
      platformCapabilitiesProvider.overrideWithValue(capabilities),
      deviceInfoProvider.overrideWithValue(
        const DeviceInfo(osLabel: 'Android', isMobile: true),
      ),
      urlOpenerProvider.overrideWithValue(opener),
    ],
  );
  addTearDown(() async {
    final done = root.container.read(profileRuntimeProvider).switchTo(null);
    await tester.pumpAndSettle();
    await done;
  });
  root.container.read(routerProvider).go(RoutePaths.signIn, extra: result);
  await tester.pumpAndSettle();
  return _Screen(root, opener);
}

void main() {
  group('the form', () {
    testWidgets('shows the field, Paste, Sign in and the expiry sentence; '
        'Sign in is enabled once the field has text', (tester) async {
      await _pumpForm(tester);

      expect(_field, findsOne);
      expect(find.widgetWithText(TextButton, 'Paste'), findsOne);
      expect(find.text(_expiry), findsOne);
      expect(tester.widget<FilledButton>(_signIn).onPressed, isNull);

      await tester.enterText(_field, _pasted);
      await tester.pump();
      expect(tester.widget<FilledButton>(_signIn).onPressed, isNotNull);
    });

    testWidgets('the field is obscured until toggled', (tester) async {
      await _pumpForm(tester);
      expect(_textField(tester).obscureText, isTrue);

      await tester.tap(find.byTooltip('Show API key'));
      await tester.pump();
      expect(_textField(tester).obscureText, isFalse);

      await tester.tap(find.byTooltip('Hide API key'));
      await tester.pump();
      expect(_textField(tester).obscureText, isTrue);
    });

    testWidgets('autocorrect, suggestions and autofill are off', (
      tester,
    ) async {
      await _pumpForm(tester);
      final field = _textField(tester);
      expect(field.autocorrect, isFalse);
      expect(field.enableSuggestions, isFalse);
      expect(field.enableIMEPersonalizedLearning, isFalse);
      expect(field.autofillHints, anyOf(isNull, isEmpty));
    });

    testWidgets('Paste fills the field from the clipboard', (tester) async {
      _mockClipboard(tester, '$_pasted\n');
      await _pumpForm(tester);

      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();

      expect(_textField(tester).controller!.text, '$_pasted\n');
    });

    testWidgets('Sign in submits the field to the base URL and hands the '
        'profile on; the field is empty afterwards', (tester) async {
      final form = await _pumpForm(tester);
      await _enterAndSubmit(tester);

      final call = form.signIn.calls.single;
      expect(call.baseUrl, Uri.parse(linkBase));
      expect(call.apiKey, _pasted);
      expect(form.signedIn, [keyProfile]);
      expect(_textField(tester).controller!.text, isEmpty);
    });

    for (final (failure, sentence) in [
      (
        const ApiKeyFailure.malformed(),
        'This is not an API key. Copy the whole key from the web UI and '
            'paste it here.',
      ),
      (
        const ApiKeyFailure.rejected(),
        'The server did not accept this key. It may have expired or been '
            'revoked.',
      ),
      (
        const ServerTooOld(serverVersion: '2.5.0', minServer: '2.6.0'),
        'This app needs soundspan 2.6.0 or newer. This server runs 2.5.0.',
      ),
    ]) {
      testWidgets('$failure renders inline', (tester) async {
        final form = await _pumpForm(tester);
        form.signIn.answer = () async => throw failure;
        await _enterAndSubmit(tester);

        expect(find.text(sentence), findsOne);
        expect(form.signedIn, isEmpty);
        expect(_textField(tester).controller!.text, _pasted);
      });
    }

    testWidgets('rateLimited counts down and re-enables Sign in', (
      tester,
    ) async {
      final form = await _pumpForm(tester);
      form.signIn.answer = () async =>
          throw const ApiKeyFailure.rateLimited(Duration(seconds: 2));
      await _enterAndSubmit(tester);

      expect(find.text('Too many attempts. Try again in 2 seconds.'), findsOne);
      expect(tester.widget<FilledButton>(_signIn).onPressed, isNull);

      form.clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Too many attempts. Try again in 1 second.'), findsOne);

      form.clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Too many attempts'), findsNothing);
      expect(tester.widget<FilledButton>(_signIn).onPressed, isNotNull);
    });

    testWidgets('another ApiException shows the error view', (tester) async {
      final form = await _pumpForm(tester);
      form.signIn.answer = () async => throw const Offline();
      await _enterAndSubmit(tester);

      expect(find.textContaining('Retry'), findsWidgets);
      expect(form.signedIn, isEmpty);
    });

    testWidgets('leaving the screen clears the field', (tester) async {
      await _pumpForm(tester);
      await tester.enterText(_field, _pasted);
      await tester.pump();
      final controller = _textField(tester).controller!;
      final cleared = <String>[];
      controller.addListener(() => cleared.add(controller.text));

      await tester.pumpWidget(const SizedBox());

      expect(cleared, ['']);
    });

    for (final size in [TestSizes.compact, TestSizes.expanded]) {
      for (final theme in [ThemeMode.dark, ThemeMode.light]) {
        testWidgets('meets the guidelines at ${size.width.toInt()} '
            '${theme.name}', (tester) async {
          final form = await _pumpForm(tester, size: size, theme: theme);
          await _meetsGuidelines(tester);
          form.signIn.answer = () async => throw const ApiKeyFailure.rejected();
          await _enterAndSubmit(tester);
          // The obscured key's small bullets sample as grey: check the
          // error state with the field empty.
          await tester.enterText(_field, '');
          await _meetsGuidelines(tester);
        });
      }
    }
  });

  group("doc 04's Sign-In table", () {
    final form = find.byType(ApiKeyForm);

    testWidgets('row 4 shows only the form', (tester) async {
      await _pumpScreen(tester, _result(localLoginEnabled: false));

      expect(form, findsOne);
      expect(find.byType(DeviceLinkPanel), findsNothing);
      expect(find.widgetWithText(TextField, 'Password'), findsNothing);
      expect(find.text(_useApiKey), findsNothing);
      expect(find.byType(TextField), findsOne);
    });

    for (final (row, result) in [
      (1, _result()),
      (2, _result(oidcEnabled: true)),
      (3, _result(localLoginEnabled: false, oidcEnabled: true)),
    ]) {
      testWidgets('row $row shows "Use an API key" as a secondary action that '
          'swaps in the form and back', (tester) async {
        await _pumpScreen(tester, result);
        expect(form, findsNothing);

        await tester.tap(find.widgetWithText(TextButton, _useApiKey));
        await tester.pumpAndSettle();
        expect(form, findsOne);
        expect(find.byType(DeviceLinkPanel), findsNothing);
        expect(find.widgetWithText(TextField, 'Password'), findsNothing);

        final back = result.localLoginEnabled
            ? 'Sign in with a password'
            : 'Link with a code';
        await tester.tap(find.widgetWithText(TextButton, back));
        await tester.pumpAndSettle();
        expect(form, findsNothing);
      });
    }

    testWidgets('the device-link panel also offers the form', (tester) async {
      await _pumpScreen(tester, _result());
      await tester.tap(find.text('Link with a code'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, _useApiKey));
      await tester.pumpAndSettle();
      expect(form, findsOne);
      expect(find.byType(DeviceLinkPanel), findsNothing);
    });

    for (final result in [
      _result(),
      _result(oidcEnabled: true),
      _result(localLoginEnabled: false, oidcEnabled: true),
      _result(localLoginEnabled: false),
    ]) {
      testWidgets('on web no API key entry point exists '
          '(local ${result.localLoginEnabled}, oidc ${result.oidcEnabled})', (
        tester,
      ) async {
        await _pumpScreen(
          tester,
          result,
          capabilities: PlatformCapabilities.web,
        );
        expect(form, findsNothing);
        expect(find.text(_useApiKey), findsNothing);
      });
    }

    testWidgets('row 4 on web says no method works in a browser and opens '
        'the server in the browser', (tester) async {
      final screen = await _pumpScreen(
        tester,
        _result(localLoginEnabled: false),
        capabilities: PlatformCapabilities.web,
      );

      expect(
        find.text(
          'This server offers no sign-in method this app can use in a '
          'browser.',
        ),
        findsOne,
      );
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Open in browser'));
      await tester.pump();
      expect(screen.opener.opened, [Uri.parse(linkBase)]);
    });

    testWidgets('row 4 meets the guidelines', (tester) async {
      await _pumpScreen(tester, _result(localLoginEnabled: false));
      await _meetsGuidelines(tester);
    });
  });
}
