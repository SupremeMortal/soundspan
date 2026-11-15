// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/active_profile.dart';
import 'package:soundspan/core/auth/password_sign_in.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/features/connect/ui/address_screen.dart';
import 'package:soundspan/features/connect/ui/connect_layout.dart';
import 'package:soundspan/features/connect/ui/probe_controller.dart';
import 'package:soundspan/features/connect/ui/sign_in_controller.dart';
import 'package:soundspan/shared/clock.dart';

/// `/connect/sign-in`: password sign-in with the two-factor step (doc 04,
/// Sign-In and Password).
///
/// The form follows the [ProbeResult]: where local login is off, the screen
/// says so and offers another server. Without a result but with
/// [profileId] (a signed-out profile sent here by the router guard), the
/// screen probes that profile's server itself and prefills its user name; a
/// failed probe goes to `/connect/probe`.
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [result], or for the signed-out [profileId].
  const new({this.result, this.profileId, super.key});

  /// What the probe found, when the user came from it.
  final ProbeResult? result;

  /// The signed-out profile to sign in again, from `?profile=`.
  final String? profileId;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  ProbeResult? _result;
  SignInController? _form;
  String? _prefill;
  ProbeController? _probe;

  /// The base URL being probed for the signed-out profile.
  String? _probing;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    final result = widget.result;
    if (result != null) {
      _show(result);
    } else {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_reprobe()),
      );
    }
  }

  /// Probes the signed-out profile's server; without one, starts over at
  /// `/connect`.
  Future<void> _reprobe() async {
    final id = widget.profileId;
    final profile = id == null
        ? null
        : await ref.read(profileRepositoryProvider).byId(id);
    if (!mounted) return;
    if (profile == null) {
      GoRouter.of(context).go(RoutePaths.connect);
      return;
    }
    final base = profile.baseUrl.toString();
    setState(() {
      _prefill = profile.username;
      _probing = base;
    });
    final probe = ref.read(probeControllerProvider.notifier);
    _probe = probe;
    probe.start(ServerAddress.parse(base));
  }

  void _onProbe(ProbeState? state) {
    if (_probe == null || _result != null || state == null) return;
    switch (state) {
      case ProbeReady(:final result):
        setState(() => _show(result));
      case ProbeNeedsSetup(:final result):
        _toProbe(result.baseUrl);
      case ProbeFailed(:final failure):
        _toProbe(failure.candidate);
      case ProbeResolving() || ProbeStarting():
        break;
    }
  }

  void _show(ProbeResult result) {
    _result = result;
    if (!result.localLoginEnabled) return;
    _form = SignInController(
      signIn: ref.read(passwordSignInProvider),
      profiles: ref.read(profileRepositoryProvider),
      runtime: ref.read(profileRuntimeProvider),
      clock: ref.read(clockProvider),
      baseUrl: result.baseUrl,
      username: _prefill,
    );
  }

  /// Probes [baseUrl] again on `/connect/probe`.
  void _toProbe(Uri baseUrl) {
    final input = baseUrl.toString();
    GoRouter.of(context).go(
      RoutePaths.probe,
      extra: ProbeRequest(input: input, address: ServerAddress.parse(input)),
    );
  }

  Future<void> _submit() async {
    final form = _form;
    final result = _result;
    if (form == null || result == null) return;
    final outcome = await form.submit();
    if (!mounted) return;
    switch (outcome) {
      case SignInOutcome.signedIn:
        GoRouter.of(context).go(RoutePaths.home);
      case SignInOutcome.reprobe:
        _toProbe(result.baseUrl);
      case null:
        break;
    }
  }

  @override
  void dispose() {
    _probe?.cancel();
    _form?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(probeControllerProvider, (_, next) => _onProbe(next.value));
    final l10n = AppLocalizations.of(context);
    final result = _result;
    final form = _form;
    return ConnectLayout(
      screen: l10n.screenSignIn,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: l10n.connectSignInBack,
        onPressed: () => GoRouter.of(context).go(RoutePaths.connect),
      ),
      children: switch ((result, form)) {
        (null, _) => [
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: Spacing.x24),
          if (_probing case final String base)
            _Message(l10n.connectProbeResolving(base)),
        ],
        (final ProbeResult _, null) => [
          _Message(l10n.connectSignInNoPassword),
          const SizedBox(height: Spacing.x24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(Sizes.touchTarget),
            ),
            onPressed: () => GoRouter.of(context).go(RoutePaths.connect),
            child: Text(l10n.connectSignInBack),
          ),
        ],
        (final ProbeResult result, final SignInController form) => [
          ListenableBuilder(
            listenable: form,
            builder: (context, _) => _FormBody(
              form: form,
              server: result.baseUrl.toString(),
              obscured: _obscured,
              onToggleObscured: () => setState(() => _obscured = !_obscured),
              onSubmit: () => unawaited(_submit()),
            ),
          ),
        ],
      },
    );
  }
}

/// The form of the current step.
class _FormBody extends StatelessWidget {
  const new({
    required this.form,
    required this.server,
    required this.obscured,
    required this.onToggleObscured,
    required this.onSubmit,
  });

  final SignInController form;
  final String server;
  final bool obscured;
  final VoidCallback onToggleObscured;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = form.step == SignInStep.code;
    final kind = form.codeKind;
    final recovery = kind == SignInCodeKind.recovery;
    final error = form.error;
    final wait = form.retryInSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Message(
          code
              ? (recovery
                    ? l10n.connectSignInRecoveryPrompt
                    : l10n.connectSignInAuthenticatorPrompt)
              : l10n.connectSignInHeading(server),
        ),
        const SizedBox(height: Spacing.x24),
        if (code)
          TextField(
            key: const ValueKey('sign-in-code'),
            controller: form.code,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: recovery
                ? TextInputType.visiblePassword
                : TextInputType.number,
            inputFormatters: kind.formatters,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            style: context.typography.mono,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: recovery
                  ? l10n.connectSignInRecoveryCode
                  : l10n.connectSignInAuthenticatorCode,
            ),
          )
        else
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: form.username,
                  autofocus: form.username.text.isEmpty,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.connectSignInUsername,
                  ),
                ),
                const SizedBox(height: Spacing.x16),
                TextField(
                  controller: form.password,
                  autofocus: form.username.text.isNotEmpty,
                  obscureText: obscured,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => onSubmit(),
                  decoration: InputDecoration(
                    labelText: l10n.connectSignInPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscured
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      tooltip: obscured
                          ? l10n.connectSignInShowPassword
                          : l10n.connectSignInHidePassword,
                      onPressed: onToggleObscured,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: Spacing.x12),
          _ErrorText(_errorMessage(l10n, error)),
        ],
        if (wait > 0) ...[
          const SizedBox(height: Spacing.x12),
          _ErrorText(l10n.connectSignInRateLimited(wait)),
        ],
        const SizedBox(height: Spacing.x24),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(Sizes.touchTarget),
          ),
          onPressed: form.canSubmit ? onSubmit : null,
          child: Text(
            code ? l10n.connectSignInVerify : l10n.connectSignInSubmit,
          ),
        ),
        if (error == SignInError.failed) ...[
          const SizedBox(height: Spacing.x8),
          _secondary(l10n.connectSignInRetry, form.canSubmit ? onSubmit : null),
        ],
        if (code) ...[
          const SizedBox(height: Spacing.x8),
          _secondary(
            recovery
                ? l10n.connectSignInUseAuthenticator
                : l10n.connectSignInUseRecovery,
            () => form.setCodeKind(
              recovery ? SignInCodeKind.authenticator : SignInCodeKind.recovery,
            ),
          ),
          _secondary(l10n.connectSignInStartOver, form.startOver),
        ],
      ],
    );
  }

  static String _errorMessage(AppLocalizations l10n, SignInError error) =>
      switch (error) {
        SignInError.invalidCredentials => l10n.connectSignInInvalidCredentials,
        SignInError.invalidCode => l10n.connectSignInInvalidCode,
        SignInError.failed => l10n.connectSignInFailed,
        SignInError.secureStorageUnavailable => l10n.connectSignInSecureStorage,
      };

  static Widget _secondary(String label, VoidCallback? onPressed) => TextButton(
    style: TextButton.styleFrom(
      minimumSize: const Size.fromHeight(Sizes.touchTarget),
    ),
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
  );
}

/// The screen's message, announced when it changes.
class _Message extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.typography.subtitle.copyWith(
        color: context.colors.content,
      ),
    ),
  );
}

/// An inline error, announced when it appears.
class _ErrorText extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: context.typography.body.copyWith(color: context.colors.danger),
    ),
  );
}
