// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/core/auth/password_sign_in.dart';
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/auth/profile_repository.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/platform/secrets/secrets.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The step of the password sign-in form.
enum SignInStep {
  /// User name and password.
  password,

  /// The second-factor code.
  code,
}

/// The kind of second-factor code the code step takes.
enum SignInCodeKind {
  /// A 6-digit code from an authenticator app.
  authenticator(r'^[0-9]{6}$', 6),

  /// An 8-character hexadecimal recovery code.
  recovery(r'^[0-9a-fA-F]{8}$', 8);

  new(this._pattern, this.length);

  final String _pattern;

  /// How many characters a code of this kind has.
  final int length;

  /// Whether [code] has this kind's shape.
  bool accepts(String code) => RegExp(_pattern).hasMatch(code);

  /// What the code field lets through: the kind's characters, at most
  /// [length] of them.
  List<TextInputFormatter> get formatters => [
    FilteringTextInputFormatter.allow(
      RegExp(this == authenticator ? '[0-9]' : '[0-9a-fA-F]'),
    ),
    LengthLimitingTextInputFormatter(length),
  ];
}

/// The inline error of the sign-in form.
enum SignInError {
  /// 401 on the first step.
  invalidCredentials,

  /// 401 on the code step.
  invalidCode,

  /// The server could not be reached or failed; Retry submits again.
  failed,

  /// The device cannot store the credential; nothing was saved.
  secureStorageUnavailable,
}

/// Where the screen goes after a submit.
enum SignInOutcome {
  /// Signed in and the profile is active: open `/home`.
  signedIn,

  /// The server no longer offers password sign-in: probe it again.
  reprobe,
}

/// Holds the password sign-in form of one server (doc 04, Password).
///
/// The password exists only here: it is cleared on success, on [dispose]
/// (leaving the screen) and [passwordLifetime] after it was entered, which
/// also returns the code step to the first step. It is never logged or
/// stored.
class SignInController extends ChangeNotifier {
  /// Creates the form for [_baseUrl], with [username] prefilled.
  new({
    required this._signIn,
    required this._profiles,
    required this._runtime,
    required this._clock,
    required this._baseUrl,
    String? username,
  }) : username = TextEditingController(text: username) {
    this.username.addListener(notifyListeners);
    password.addListener(notifyListeners);
    code.addListener(notifyListeners);
  }

  /// How long the password is kept after it was entered.
  static const passwordLifetime = Duration(minutes: 5);

  static final AppLogger _log = AppLogger.scope('SignIn');

  final PasswordSignIn _signIn;
  final ProfileRepository _profiles;
  final ProfileRuntime _runtime;
  final Clock _clock;
  final Uri _baseUrl;

  /// The user name field.
  final TextEditingController username;

  /// The password field.
  final TextEditingController password = TextEditingController();

  /// The code field of the code step.
  final TextEditingController code = TextEditingController();

  SignInStep _step = SignInStep.password;
  SignInCodeKind _codeKind = SignInCodeKind.authenticator;
  SignInError? _error;
  bool _busy = false;
  String? _submittedUsername;
  String? _submittedPassword;
  DateTime? _passwordEnteredAt;
  DateTime? _retryAt;
  Timer? _ticker;
  bool _disposed = false;

  /// The current step.
  SignInStep get step => _step;

  /// The kind of code the code step takes.
  SignInCodeKind get codeKind => _codeKind;

  /// The inline error, if any.
  SignInError? get error => _error;

  /// Whether a submit is running.
  bool get busy => _busy;

  /// Whole seconds until the server accepts another attempt; zero when it
  /// does.
  int get retryInSeconds {
    final retryAt = _retryAt;
    if (retryAt == null) return 0;
    final left = retryAt.difference(_clock.now()).inMilliseconds;
    return left <= 0 ? 0 : (left + 999) ~/ 1000;
  }

  /// Whether the current step can be submitted.
  bool get canSubmit {
    if (_busy || retryInSeconds > 0) return false;
    return switch (_step) {
      SignInStep.password =>
        username.text.trim().isNotEmpty && password.text.isNotEmpty,
      SignInStep.code => _codeKind.accepts(code.text),
    };
  }

  /// Switches the code step to [kind] and empties the code field.
  void setCodeKind(SignInCodeKind kind) {
    if (kind == _codeKind) return;
    _codeKind = kind;
    _error = null;
    code.clear();
    notifyListeners();
  }

  /// Leaves the code step for the first step and forgets the password.
  void startOver() {
    _clearPassword();
    _error = null;
    notifyListeners();
  }

  /// Submits the current step; returns where the screen goes next, or null
  /// to stay.
  Future<SignInOutcome?> submit() async {
    if (!canSubmit) return null;
    if (_step == SignInStep.password) {
      _submittedUsername = username.text.trim();
      _submittedPassword = password.text;
      _passwordEnteredAt = _clock.now();
      _startTicker();
    }
    final user = _submittedUsername;
    final secret = _submittedPassword;
    if (user == null || secret == null) return null;
    _busy = true;
    _error = null;
    notifyListeners();
    final result = await _signIn.submit(
      baseUrl: _baseUrl,
      username: user,
      password: secret,
      code: _step == SignInStep.code ? code.text : null,
    );
    if (_disposed) return null;
    final outcome = switch (result) {
      SignInSignedIn() => await _store(result),
      SignInNeedsCode() => _toCodeStep(),
      SignInInvalidCredentials() => _fail(SignInError.invalidCredentials),
      SignInInvalidCode() => _fail(SignInError.invalidCode),
      SignInLocalLoginDisabled() => _reprobe(),
      SignInRateLimited(:final retryAfter) => _rateLimited(retryAfter),
      SignInFailed(:final error) => _failed(error),
    };
    if (_disposed) return outcome;
    _busy = false;
    notifyListeners();
    return outcome;
  }

  Future<SignInOutcome?> _store(SignInSignedIn result) async {
    final user = result.user;
    final Profile profile;
    try {
      profile = await _profiles.upsertSignedIn(
        baseUrl: _baseUrl,
        userId: user.id,
        username: user.username,
        userDisplayName: user.displayName,
        role: user.role.toJson(),
        authKind: AuthKind.password,
        credentials: result.credentials,
        credentialCreatedAt: _clock.now(),
      );
    } on SecretStoreUnavailable catch (error) {
      _log.warning('No secure storage for the sign-in', const {}, error);
      return _fail(SignInError.secureStorageUnavailable);
    }
    _clearPassword();
    await _runtime.switchTo(profile.id);
    _log.info('Signed in', {'profileId': profile.id});
    return SignInOutcome.signedIn;
  }

  SignInOutcome? _toCodeStep() {
    _step = SignInStep.code;
    code.clear();
    return null;
  }

  SignInOutcome? _fail(SignInError error) {
    _error = error;
    return null;
  }

  SignInOutcome _reprobe() {
    _clearPassword();
    return SignInOutcome.reprobe;
  }

  SignInOutcome? _rateLimited(Duration retryAfter) {
    _retryAt = _clock.now().add(retryAfter);
    _startTicker();
    return null;
  }

  SignInOutcome? _failed(ApiException error) {
    _log.warning('Sign-in failed', {'error': error.toString()});
    return _fail(SignInError.failed);
  }

  void _startTicker() =>
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());

  void _tick() {
    final now = _clock.now();
    var changed = false;
    final enteredAt = _passwordEnteredAt;
    if (enteredAt != null && now.difference(enteredAt) >= passwordLifetime) {
      _clearPassword();
      changed = true;
    }
    if (_retryAt != null) {
      if (retryInSeconds == 0) _retryAt = null;
      changed = true;
    }
    if (_passwordEnteredAt == null && _retryAt == null) {
      _ticker?.cancel();
      _ticker = null;
    }
    if (changed) notifyListeners();
  }

  /// Forgets the password everywhere it is held and returns to the first
  /// step.
  void _clearPassword() {
    _submittedPassword = null;
    _passwordEnteredAt = null;
    password.clear();
    code.clear();
    _step = SignInStep.password;
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _clearPassword();
    username.dispose();
    password.dispose();
    code.dispose();
    super.dispose();
  }
}
