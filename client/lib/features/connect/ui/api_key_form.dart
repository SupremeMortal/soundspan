// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/core/auth/api_key_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/server_admission.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/server_admission_gate.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/widgets/error_view.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// Signs in to the server at [baseUrl] with an API key pasted from the web
/// UI (doc 04, Pasted API Key).
///
/// One obscured field with a show/hide toggle and a Paste button that
/// reads the clipboard, a Sign in button, and the sentence that the key's
/// expiry is not known to the app. A malformed or rejected key is shown
/// under the field; a 429 disables Sign in and counts down on the [Clock].
/// The field has autocorrect, suggestions and autofill off, and is cleared
/// on success and when the form leaves the screen. The signed-in profile
/// goes to [onSignedIn].
class ApiKeyForm extends ConsumerStatefulWidget {
  /// Creates the form for the server at [baseUrl].
  const new({required this.baseUrl, required this.onSignedIn, super.key});

  /// The server to sign in to.
  final Uri baseUrl;

  /// Called with the stored profile once the key is accepted.
  final Future<void> Function(Profile profile) onSignedIn;

  @override
  ConsumerState<ApiKeyForm> createState() => _ApiKeyFormState();
}

class _ApiKeyFormState extends ConsumerState<ApiKeyForm> {
  static final AppLogger _log = AppLogger.scope('ApiKey');

  final TextEditingController _key = TextEditingController();
  bool _obscured = true;
  bool _busy = false;
  Object? _failure;
  DateTime? _retryAt;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _key.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _key
      ..removeListener(_onChanged)
      ..clear()
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  int get _retryInSeconds {
    final retryAt = _retryAt;
    if (retryAt == null) return 0;
    final left = retryAt.difference(ref.read(clockProvider).now());
    return left <= Duration.zero ? 0 : (left.inMilliseconds + 999) ~/ 1000;
  }

  bool get _canSubmit =>
      !_busy && _key.text.trim().isNotEmpty && _retryInSeconds == 0;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!mounted || text == null) return;
    _key.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final profile = await ref
          .read(apiKeySignInProvider)
          .submit(baseUrl: widget.baseUrl, apiKey: _key.text);
      _key.clear();
      if (!mounted) return;
      await widget.onSignedIn(profile);
    } on ApiKeyRateLimited catch (error) {
      _retryAt = ref.read(clockProvider).now().add(error.retryAfter);
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } on ApiKeyFailure catch (error) {
      _failure = error;
    } on ServerTooOld catch (error) {
      _failure = error;
    } on SecretStoreUnavailable catch (error) {
      _log.warning('No secure storage for the API key', const {}, error);
      _failure = error;
    } on ApiException catch (error) {
      _failure = error;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _tick() {
    if (!mounted) return;
    if (_retryInSeconds == 0) {
      _ticker?.cancel();
      _ticker = null;
      _retryAt = null;
    }
    setState(() {});
  }

  String? _message(AppLocalizations l10n) {
    final wait = _retryInSeconds;
    if (wait > 0) return l10n.connectSignInRateLimited(wait);
    return switch (_failure) {
      ApiKeyMalformed() => l10n.connectApiKeyMalformed,
      ApiKeyRejected() => l10n.connectApiKeyRejected,
      ServerTooOld(:final minServer, :final serverVersion) =>
        l10n.connectServerTooOld(minServer, serverVersion),
      SecretStoreUnavailable() => l10n.connectSignInSecureStorage,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = _failure;
    final message = _message(l10n);
    final secondary = context.typography.body.copyWith(
      color: context.colors.contentSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.connectApiKeyHeading,
            textAlign: TextAlign.center,
            style: context.typography.subtitle.copyWith(
              color: context.colors.content,
            ),
          ),
        ),
        const SizedBox(height: Spacing.x24),
        TextField(
          controller: _key,
          enabled: !_busy,
          obscureText: _obscured,
          autocorrect: false,
          enableSuggestions: false,
          enableIMEPersonalizedLearning: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          autofillHints: null,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.go,
          style: context.typography.mono.copyWith(
            color: context.colors.content,
          ),
          onSubmitted: (_) => unawaited(_submit()),
          decoration: InputDecoration(
            labelText: l10n.connectApiKeyField,
            suffixIcon: IconButton(
              icon: Icon(
                _obscured
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              tooltip: _obscured
                  ? l10n.connectApiKeyShow
                  : l10n.connectApiKeyHide,
              onPressed: () => setState(() => _obscured = !_obscured),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: Spacing.x12),
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: context.typography.body.copyWith(
                color: context.colors.danger,
              ),
            ),
          ),
        ],
        const SizedBox(height: Spacing.x8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(Sizes.touchTarget, Sizes.touchTarget),
            ),
            onPressed: _busy ? null : () => unawaited(_paste()),
            icon: const Icon(Icons.content_paste_rounded),
            label: Text(l10n.connectApiKeyPaste),
          ),
        ),
        if (failure is ApiException) ...[
          const SizedBox(height: Spacing.x12),
          ErrorView(error: failure, onRetry: () => unawaited(_submit())),
        ],
        const SizedBox(height: Spacing.x16),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(Sizes.touchTarget),
          ),
          onPressed: _canSubmit ? () => unawaited(_submit()) : null,
          child: Text(l10n.connectSignInSubmit),
        ),
        const SizedBox(height: Spacing.x16),
        Text(
          l10n.connectApiKeyExpiryUnknown,
          textAlign: TextAlign.center,
          style: secondary,
        ),
      ],
    );
  }
}
