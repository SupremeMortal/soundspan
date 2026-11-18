// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/device_link_sign_in.dart';
import 'package:soundspan/core/auth/password_sign_in.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/features/connect/connect.dart';
import 'package:soundspan/features/connect/ui/device_link_panel.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/platform/device_info/device_info.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/widgets/code_cells.dart';
import 'package:soundspan_api/soundspan_api.dart';

import '../../core/auth/password_sign_in_fakes.dart';
import '../../core/logging/recording_sink.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/guidelines.dart';
import '../../helpers/in_memory_secret_store.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_root.dart';
import 'connect_harness.dart';
import 'ui/device_link_fakes.dart';

const _base = 'https://music.example.com';

/// A secret store whose writes fail as on Linux without a Secret Service.
class _UnavailableSecretStore extends InMemorySecretStore {
  @override
  Future<void> write(String key, String value) async =>
      throw const SecretStoreUnavailable('no provider');
}

/// What [_pumpSignIn] built.
class _SignIn {
  new(this.root, this.client, this.clock, this.link);

  final TestRoot root;
  final FakeLoginClient client;
  final FakeClock clock;
  final FakeDeviceLinkSignIn link;

  String get location => locationOf(root);
}

Finder _field(String label) => find.widgetWithText(TextField, label);

Finder get _username => _field('User name or email');
Finder get _password => _field('Password');
Finder get _code => find.byKey(const ValueKey('sign-in-code'));

FilledButton _button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

Future<_SignIn> _pumpSignIn(
  WidgetTester tester, {
  StoredProfile stored = StoredProfile.none,
  ProbeResult? result,
  bool localLoginEnabled = true,
  InMemorySecretStore? secrets,
  ProbeState? probed,
  Size size = TestSizes.compact,
  PlatformCapabilities capabilities = PlatformCapabilities.android,
  FakeDeviceLinkSignIn? link,
}) async {
  final client = FakeLoginClient();
  final clock = FakeClock();
  link ??= FakeDeviceLinkSignIn();
  final root = await tester.pumpSoundspanApp(
    stored: stored,
    size: size,
    secrets: secrets,
    clock: clock,
    overrides: [
      passwordSignInProvider.overrideWithValue(PasswordSignIn(client.factory)),
      deviceLinkSignInProvider.overrideWithValue(link),
      platformCapabilitiesProvider.overrideWithValue(capabilities),
      deviceInfoProvider.overrideWithValue(
        const DeviceInfo(osLabel: 'Android', isMobile: true),
      ),
      if (probed != null)
        probeControllerProvider.overrideWith(
          () => InstantProbeController(probed),
        ),
    ],
  );
  // A profile activated by the sign-in lives in this test's fake-async
  // zone, so it is closed here, before the root is disposed outside it.
  addTearDown(() async {
    final done = root.container.read(profileRuntimeProvider).switchTo(null);
    await _drive(tester);
    await done;
  });
  if (stored == StoredProfile.none) {
    root.container
        .read(routerProvider)
        .go(
          RoutePaths.signIn,
          extra: result ?? _result(localLoginEnabled: localLoginEnabled),
        );
  }
  await tester.pumpAndSettle();
  return _SignIn(root, client, clock, link);
}

ProbeResult _result({
  bool localLoginEnabled = true,
  bool oidcEnabled = false,
  String? oidcProviderName,
  String? linkCode,
}) {
  final url = Uri.parse(_base);
  return ProbeResult(
    baseUrl: url,
    requestedBaseUrl: url,
    localLoginEnabled: localLoginEnabled,
    oidcEnabled: oidcEnabled,
    oidcProviderName: oidcProviderName,
    linkCode: linkCode,
    isCleartext: false,
    isPrivateHost: false,
  );
}

Future<void> _enterCredentials(WidgetTester tester) async {
  await tester.enterText(_username, 'ada');
  await tester.enterText(_password, 'secret');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
  await _drive(tester);
}

/// Lets a sign-in finish: storing the profile and activating it needs real
/// asynchronous work between frames.
Future<void> _drive(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Future<void> _toCodeStep(WidgetTester tester, _SignIn signIn) async {
  signIn.client.answer = (_) async => twoFactorChallenge();
  await _enterCredentials(tester);
  expect(_code, findsOne);
}

Future<List<Profile>> _profiles(WidgetTester tester, TestRoot root) async =>
    (await tester.runAsync(
      () => root.database.select(root.database.profiles).get(),
    ))!.map(profileFromRow).toList();

/// Checks the screen guidelines with nothing focused: the contrast check
/// samples a focused field's text cursor and its label's focus colour as if
/// they were text.
Future<void> _meetsGuidelines(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await expectMeetsGuidelines(tester);
}

void main() {
  group("doc 04's Password block", () {
    testWidgets('200 signs in, stores the profile and opens /home', (
      tester,
    ) async {
      final signIn = await _pumpSignIn(tester);
      await _enterCredentials(tester);
      expect(signIn.location, RoutePaths.home);
      final profile = (await _profiles(tester, signIn.root)).single;

      expect(profile.baseUrl, Uri.parse(_base));
      expect(profile.userId, 'user-1');
      expect(profile.username, 'ada');
      expect(profile.userDisplayName, 'Ada');
      expect(profile.role, 'user');
      expect(profile.authKind, AuthKind.password);
      expect(profile.state, ProfileState.active);
      expect(profile.credentialExpiresAt, isNull);
      expect(
        signIn.root.container.read(profileRuntimeProvider).state.value,
        ProfileRuntimeActive(profile.id),
      );
      final secrets =
          (await tester.runAsync(
                () => signIn.root.container
                    .read(profileRepositoryProvider)
                    .readCredentials(profile.id),
              ))!
              as JwtCredentials;
      expect(secrets.accessToken, 'access-1');
      expect(secrets.refreshToken, 'refresh-1');
    });

    testWidgets('requires2FA shows the code step', (tester) async {
      final signIn = await _pumpSignIn(tester);
      await _toCodeStep(tester, signIn);
      expect(find.text('Authenticator code'), findsOne);
      expect(_password, findsNothing);
      expect(signIn.location, RoutePaths.signIn);
    });

    testWidgets('401 shows the inline error and keeps the user name', (
      tester,
    ) async {
      final signIn = await _pumpSignIn(tester);
      signIn.client.answer = (_) async =>
          throw const Unauthenticated(status: 401);
      await _enterCredentials(tester);
      expect(find.text('The user name or password is not correct'), findsOne);
      expect(tester.widget<TextField>(_username).controller!.text, 'ada');
      expect(signIn.location, RoutePaths.signIn);
    });

    testWidgets('403 re-runs the probe', (tester) async {
      final signIn = await _pumpSignIn(
        tester,
        probed: ProbeNeedsSetup(_result()),
      );
      signIn.client.answer = (_) async => throw const Forbidden(status: 403);
      await _enterCredentials(tester);
      expect(signIn.location, RoutePaths.probe);
      expect(find.byType(ProbeScreen), findsOne);
      expect(_password, findsNothing);
    });

    testWidgets('429 shows a countdown from Retry-After and re-enables at '
        'zero', (tester) async {
      final signIn = await _pumpSignIn(tester);
      signIn.client.answer = (_) async => throw const RateLimited(
        status: 429,
        retryAfter: Duration(seconds: 30),
      );
      await _enterCredentials(tester);
      expect(
        find.text('Too many attempts. Try again in 30 seconds.'),
        findsOne,
      );
      expect(_button(tester, 'Sign in').onPressed, isNull);

      signIn.clock.advance(const Duration(seconds: 29));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Too many attempts. Try again in 1 second.'), findsOne);
      expect(_button(tester, 'Sign in').onPressed, isNull);

      signIn.clock.advance(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Too many attempts'), findsNothing);
      expect(_button(tester, 'Sign in').onPressed, isNotNull);
    });

    testWidgets('code step 200 signs in', (tester) async {
      final signIn = await _pumpSignIn(tester);
      await _toCodeStep(tester, signIn);
      signIn.client.answer = (_) async => tokenResponse();
      await tester.enterText(_code, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
      await _drive(tester);

      expect(signIn.location, RoutePaths.home);
      final last = signIn.client.requests.last;
      expect(last.username, 'ada');
      expect(last.password, 'secret');
      expect(last.token, '123456');
      expect(await _profiles(tester, signIn.root), hasLength(1));
    });

    testWidgets('code step 401 stays on the code step', (tester) async {
      final signIn = await _pumpSignIn(tester);
      await _toCodeStep(tester, signIn);
      signIn.client.answer = (_) async =>
          throw const Unauthenticated(status: 401);
      await tester.enterText(_code, '123456');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
      await _drive(tester);

      expect(find.text('That code is not correct'), findsOne);
      expect(_code, findsOne);
      expect(signIn.location, RoutePaths.signIn);
    });

    testWidgets('a failure shows the generic message and Retry submits '
        'again', (tester) async {
      final signIn = await _pumpSignIn(tester);
      signIn.client.answer = (_) async => throw const Offline();
      await _enterCredentials(tester);
      expect(
        find.text('Could not sign in. Check the connection and try again.'),
        findsOne,
      );
      signIn.client.answer = (_) async => tokenResponse();
      await tester.tap(find.widgetWithText(TextButton, 'Retry'));
      await _drive(tester);
      expect(signIn.location, RoutePaths.home);
    });
  });

  testWidgets('authenticator mode accepts 6 digits only; recovery mode '
      'accepts 8 hex characters only', (tester) async {
    final signIn = await _pumpSignIn(tester);
    await _toCodeStep(tester, signIn);
    Future<bool> accepts(String text) async {
      await tester.enterText(_code, text);
      await tester.pump();
      return _button(tester, 'Verify').onPressed != null;
    }

    expect(await accepts('12345'), isFalse);
    expect(await accepts('12a456'), isFalse);
    expect(await accepts('123456'), isTrue);
    expect(await accepts('1234567'), isTrue, reason: 'cut to 6 digits');
    expect(tester.widget<TextField>(_code).controller!.text, '123456');

    await tester.tap(find.text('Use a recovery code instead'));
    await tester.pump();
    expect(find.text('Recovery code'), findsOne);
    expect(await accepts('123456'), isFalse);
    expect(await accepts('abcd12'), isFalse);
    expect(await accepts('abcdeg12'), isFalse);
    expect(await accepts('ABCDEF12'), isTrue);
    expect(await accepts('abcdef12'), isTrue);

    await tester.tap(find.text('Use an authenticator code instead'));
    await tester.pump();
    expect(find.text('Authenticator code'), findsOne);
    expect(await accepts('abcdef12'), isFalse);
  });

  testWidgets('local login disabled on web shows the no-password message and '
      'no form', (tester) async {
    final signIn = await _pumpSignIn(
      tester,
      result: _result(localLoginEnabled: false, oidcEnabled: true),
      capabilities: PlatformCapabilities.web,
    );
    expect(find.text('This server does not offer password sign-in.'), findsOne);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Use a different server'));
    await _drive(tester);
    expect(signIn.location, RoutePaths.connect);
  });

  testWidgets('the password is cleared after 5 minutes and the code step '
      'returns to the first step', (tester) async {
    final signIn = await _pumpSignIn(tester);
    await _toCodeStep(tester, signIn);

    signIn.clock.advance(const Duration(minutes: 4, seconds: 58));
    await tester.pump(const Duration(seconds: 1));
    expect(_code, findsOne);

    signIn.clock.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(_code, findsNothing);
    expect(tester.widget<TextField>(_password).controller!.text, isEmpty);
    expect(tester.widget<TextField>(_username).controller!.text, 'ada');
    expect(find.text('secret'), findsNothing);
  });

  testWidgets('leaving the screen clears the password', (tester) async {
    final signIn = await _pumpSignIn(tester);
    await _toCodeStep(tester, signIn);
    signIn.root.container.read(routerProvider).go(RoutePaths.connect);
    await _drive(tester);
    signIn.root.container
        .read(routerProvider)
        .go(RoutePaths.signIn, extra: _result());
    await _drive(tester);

    expect(_code, findsNothing);
    expect(tester.widget<TextField>(_password).controller!.text, isEmpty);
    expect(find.text('secret'), findsNothing);
  });

  testWidgets('the profile row and the logs contain no password or token', (
    tester,
  ) async {
    final sink = RecordingSink();
    AppLogging.configure(sinks: [sink], releaseMode: false);
    addTearDown(AppLogging.reset);
    final signIn = await _pumpSignIn(tester);
    await _toCodeStep(tester, signIn);
    signIn.client.answer = (_) async => tokenResponse();
    await tester.enterText(_code, '123456');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
    await _drive(tester);
    expect(signIn.location, RoutePaths.home);

    final rows = (await tester.runAsync(
      () => signIn.root.database.select(signIn.root.database.profiles).get(),
    ))!;
    final logs = sink.entries.map((e) => jsonEncode(e.toJson())).join('\n');
    for (final text in [rows.single.toString(), logs]) {
      for (final secret in ['secret', 'access-1', 'refresh-1', '123456']) {
        expect(text, isNot(contains(secret)));
      }
    }
  });

  testWidgets('SecretStoreUnavailable shows the secure-storage message and '
      'stores nothing', (tester) async {
    final secrets = _UnavailableSecretStore();
    final signIn = await _pumpSignIn(tester, secrets: secrets);
    await _enterCredentials(tester);

    expect(find.textContaining('no secure storage service'), findsOne);
    expect(find.textContaining('GNOME Keyring or KWallet'), findsOne);
    expect(signIn.location, RoutePaths.signIn);
    expect(await _profiles(tester, signIn.root), isEmpty);
    expect(secrets.values, isEmpty);
  });

  testWidgets('a signed-out profile is probed, the user name is prefilled, '
      'and signing in reactivates the same profile id', (tester) async {
    final signIn = await _pumpSignIn(
      tester,
      stored: StoredProfile.signedOut,
      probed: ProbeReady(_result()),
    );
    final id = signIn.root.profileId!;
    expect(
      signIn.location,
      Uri(path: RoutePaths.signIn, queryParameters: {'profile': id}).toString(),
    );
    expect(tester.widget<TextField>(_username).controller!.text, 'ada');

    signIn.client.answer = (_) async =>
        tokenResponse(access: 'access-2', refresh: 'refresh-2');
    await tester.enterText(_password, 'secret');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await _drive(tester);

    expect(signIn.location, RoutePaths.home);
    expect(signIn.client.baseUrls.last, Uri.parse(_base));
    final profile = (await _profiles(tester, signIn.root)).single;
    expect(profile.id, id);
    expect(profile.state, ProfileState.active);
    final stored =
        (await tester.runAsync(
              () => signIn.root.container
                  .read(profileRepositoryProvider)
                  .readCredentials(id),
            ))!
            as JwtCredentials;
    expect(stored.accessToken, 'access-2');
    expect(
      signIn.root.container.read(profileRuntimeProvider).state.value,
      ProfileRuntimeActive(id),
    );
  });

  testWidgets('a signed-out profile whose probe fails goes to the probe '
      'screen', (tester) async {
    final signIn = await _pumpSignIn(
      tester,
      stored: StoredProfile.signedOut,
      probed: ProbeNeedsSetup(_result()),
    );
    expect(signIn.location, RoutePaths.probe);
  });

  group('guidelines', () {
    Future<void> check(WidgetTester tester, Size size) async {
      final signIn = await _pumpSignIn(tester, size: size);
      await _meetsGuidelines(tester);
      signIn.client.answer = (_) async =>
          throw const Unauthenticated(status: 401);
      await _enterCredentials(tester);
      expect(find.text('The user name or password is not correct'), findsOne);
      // The obscured password's small bullets sample as grey: check the
      // error state with the field empty.
      await tester.enterText(_password, '');
      await _meetsGuidelines(tester);
      await _toCodeStep(tester, signIn);
      await _meetsGuidelines(tester);
    }

    for (final size in [TestSizes.compact, TestSizes.expanded]) {
      for (final brightness in Brightness.values) {
        testWidgets('${size.width.toInt()} ${brightness.name}', (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await check(tester, size);
        });
      }
    }

    testWidgets('text scale 2.0 does not overflow', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final signIn = await _pumpSignIn(tester);
      expect(tester.takeException(), isNull);
      signIn.client.answer = (_) async => throw const Offline();
      await _enterCredentials(tester);
      expect(tester.takeException(), isNull);
      await _toCodeStep(tester, signIn);
      expect(tester.takeException(), isNull);
    });
  });

  group("doc 04's Sign-In table", () {
    const linkWithCode = 'Link with a code';
    const ssoNote = 'Single sign-on users: link this device with a code.';
    final panel = find.byType(DeviceLinkPanel);

    testWidgets('local login only: the password form with "Link with a '
        'code", which swaps in the panel and back', (tester) async {
      await _pumpSignIn(tester);
      expect(_password, findsOne);
      expect(panel, findsNothing);
      expect(find.text(ssoNote), findsNothing);

      await tester.tap(find.text(linkWithCode));
      await tester.pumpAndSettle();
      expect(panel, findsOne);
      expect(find.text('Link this device'), findsOne);
      expect(_password, findsNothing);

      await tester.tap(find.text('Sign in with a password'));
      await tester.pumpAndSettle();
      expect(_password, findsOne);
      expect(panel, findsNothing);
    });

    testWidgets('both enabled: the same, plus the single sign-on note', (
      tester,
    ) async {
      await _pumpSignIn(tester, result: _result(oidcEnabled: true));
      expect(_password, findsOne);
      expect(find.text(linkWithCode), findsOne);
      expect(find.text(ssoNote), findsOne);
      await _meetsGuidelines(tester);
    });

    testWidgets('single sign-on only: the panel is the primary content, '
        'titled after the provider', (tester) async {
      await _pumpSignIn(
        tester,
        result: _result(
          localLoginEnabled: false,
          oidcEnabled: true,
          oidcProviderName: 'Authentik',
        ),
      );
      expect(find.text('Sign in with Authentik'), findsOne);
      expect(panel, findsOne);
      expect(_password, findsNothing);
      expect(find.text(linkWithCode), findsNothing);
      // The panel's guidelines are checked in device_link_panel_test.dart:
      // in this light root the pixel sampling of the prefilled device name
      // reads the antialiased glyph edges, not the `content` token.
    });

    testWidgets('single sign-on only without a provider name is titled '
        '"Link this device"', (tester) async {
      await _pumpSignIn(
        tester,
        result: _result(
          localLoginEnabled: false,
          oidcEnabled: true,
          oidcProviderName: '',
        ),
      );
      expect(find.text('Link this device'), findsOne);
      expect(panel, findsOne);
    });

    testWidgets('linking signs in and opens /home as a password sign-in '
        'does', (tester) async {
      final signIn = await _pumpSignIn(
        tester,
        result: _result(localLoginEnabled: false, oidcEnabled: true),
      );
      final profile = (await tester.runAsync(
        () => signIn.root.container
            .read(profileRepositoryProvider)
            .upsertSignedIn(
              baseUrl: Uri.parse(_base),
              userId: 'user-1',
              username: 'ada',
              userDisplayName: 'Ada',
              role: 'user',
              authKind: AuthKind.deviceLink,
              credentials: const ApiKeyCredentials(apiKey: 'key-1'),
              credentialCreatedAt: DateTime.utc(2026),
            ),
      ))!;
      signIn.link.answer = () async => profile;

      await tester.enterText(
        find.descendant(
          of: find.byType(CodeCells),
          matching: find.byType(EditableText),
        ),
        'abc234',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Link'));
      await _drive(tester);

      expect(
        signIn.link.calls.single.deviceName,
        'Android phone (soundspan '
        'Android)',
      );
      expect(signIn.location, RoutePaths.home);
      expect(
        signIn.root.container.read(profileRuntimeProvider).state.value,
        ProfileRuntimeActive(profile.id),
      );
    });

    testWidgets('a result with a link code opens the panel and submits it '
        'once', (tester) async {
      final link = FakeDeviceLinkSignIn()
        ..answer = () async => throw const DeviceLinkFailure.codeUsed();
      final signIn = await _pumpSignIn(
        tester,
        result: _result(linkCode: 'ABC234'),
        link: link,
      );
      await _drive(tester);
      expect(find.textContaining('already been used'), findsOne);
      expect(panel, findsOne);
      expect(signIn.link.calls.single.code.value, 'ABC234');
    });

    for (final result in [
      _result(),
      _result(oidcEnabled: true),
      _result(localLoginEnabled: false, oidcEnabled: true),
      _result(linkCode: 'ABC234'),
    ]) {
      testWidgets('on web no device-link entry point exists '
          '(local ${result.localLoginEnabled}, oidc ${result.oidcEnabled}, '
          'code ${result.linkCode})', (tester) async {
        final signIn = await _pumpSignIn(
          tester,
          result: result,
          capabilities: PlatformCapabilities.web,
        );
        expect(panel, findsNothing);
        expect(find.byType(CodeCells), findsNothing);
        expect(find.text(linkWithCode), findsNothing);
        expect(find.text(ssoNote), findsNothing);
        expect(signIn.link.calls, isEmpty);
        if (!result.localLoginEnabled) {
          expect(
            find.text('This server does not offer password sign-in.'),
            findsOne,
          );
        }
      });
    }
  });
}
