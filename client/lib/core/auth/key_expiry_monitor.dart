// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show immutable;
import 'package:soundspan/core/auth/profile.dart';
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/storage/state/device_settings_dao.dart';
import 'package:soundspan/platform/notifications/local_notifications.dart';
import 'package:soundspan/shared/clock.dart';

/// How close a profile's API key is to expiring (doc 04, API-Key Expiry).
@immutable
sealed class KeyExpiryState {
  const new();

  /// The key expires in [days] days, 1 to [KeyExpiryMonitor.warnDays].
  const factory expiring(int days) = KeyExpiring;

  /// No warning: a password profile, an unknown expiry, or more than
  /// [KeyExpiryMonitor.warnDays] days left.
  static const KeyExpiryState none = KeyExpiryNone();

  /// The key has expired.
  static const KeyExpiryState expired = KeyExpired();
}

/// No warning.
final class KeyExpiryNone extends KeyExpiryState {
  /// The state.
  const new();

  @override
  String toString() => 'KeyExpiryState.none';
}

/// The key expires in [days] days.
final class KeyExpiring extends KeyExpiryState {
  /// Creates the state for [days] days left.
  const new(this.days);

  /// Whole days left, rounded up; 1 means today.
  final int days;

  @override
  bool operator ==(Object other) => other is KeyExpiring && other.days == days;

  @override
  int get hashCode => Object.hash(KeyExpiring, days);

  @override
  String toString() => 'KeyExpiryState.expiring($days)';
}

/// The key has expired.
final class KeyExpired extends KeyExpiryState {
  /// The state.
  const new();

  @override
  String toString() => 'KeyExpiryState.expired';
}

/// The title and body of the expiry notification for [days] days left.
typedef KeyExpiryNotificationText = ({String title, String body}) Function(
  int days,
);

/// The `device_settings` key recording the last expiry notification:
/// `{ credentialCreatedAt, threshold }`.
const String keyExpiryNotifiedKey = 'keyExpiry.notified';

/// The notification payload that opens the re-link flow of [profileId].
String relinkPayload(String profileId) => 'relink:$profileId';

/// The profile id in a [relinkPayload], or null for another payload.
String? profileIdOfRelinkPayload(String payload) =>
    payload.startsWith('relink:') && payload.length > 'relink:'.length
    ? payload.substring('relink:'.length)
    : null;

/// Watches a device-linked profile's key expiry (doc 04, API-Key Expiry):
/// reports a [KeyExpiryState] and shows one local notification when 14, 3
/// and 1 days are left.
///
/// It evaluates when it starts, on every profile it is given (a re-link
/// changes the dates), every `interval` (24 hours) and on [evaluate], which the
/// profile scope calls when the app returns to the foreground. The
/// notified threshold is kept per credential in the profile's
/// `device_settings`, so a restart does not notify twice and a new key
/// starts over. Permission is asked for when a notification is due; when
/// it is refused, the banner is the only warning.
class KeyExpiryMonitor {
  /// Creates the monitor of the profiles on [profile].
  new({
    required Stream<Profile?> profile,
    required this._settings,
    required this._notifications,
    required this._clock,
    required this._text,
    this._interval = const Duration(hours: 24),
  }) : _profiles = profile;

  /// Days before expiry at which the warning starts.
  static const warnDays = 14;

  /// Days left at which a notification is shown, highest first.
  static const thresholds = [14, 3, 1];

  static final AppLogger _log = AppLogger.scope('KeyExpiry');

  final Stream<Profile?> _profiles;
  final DeviceSettingsDao _settings;
  final LocalNotifications _notifications;
  final Clock _clock;
  final KeyExpiryNotificationText _text;
  final Duration _interval;
  final StreamController<KeyExpiryState> _states =
      StreamController<KeyExpiryState>.broadcast();
  StreamSubscription<Profile?>? _subscription;
  Timer? _timer;
  Profile? _profile;
  KeyExpiryState _current = KeyExpiryState.none;
  Future<void> _tail = Future<void>.value();
  bool _disposed = false;

  /// The latest state.
  KeyExpiryState get current => _current;

  /// Every change of [current].
  Stream<KeyExpiryState> get states => _states.stream;

  /// Evaluates [initial], then follows the profile stream and the timer.
  /// Later calls do nothing.
  Future<void> start(Profile? initial) async {
    if (_subscription != null || _disposed) return;
    _profile = initial;
    _subscription = _profiles.listen((profile) {
      _profile = profile;
      unawaited(evaluate());
    });
    _timer = Timer.periodic(_interval, (_) => unawaited(evaluate()));
    await evaluate();
  }

  /// Computes the state now and shows a notification when one is due.
  /// Calls run one after another.
  Future<void> evaluate() {
    return _tail = _tail
        .then((_) => _evaluate())
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace st) {
            _log.warning('Key expiry check failed', const {}, error, st);
          },
        );
  }

  /// [KeyExpiryState] of [profile] at [now].
  static KeyExpiryState stateOf(Profile? profile, DateTime now) {
    final expiresAt = profile?.credentialExpiresAt;
    if (profile == null ||
        profile.authKind == AuthKind.password ||
        expiresAt == null) {
      return KeyExpiryState.none;
    }
    final left = expiresAt.difference(now).inMicroseconds;
    const day = Duration.microsecondsPerDay;
    final days = left <= 0 ? -(-left ~/ day) : (left + day - 1) ~/ day;
    if (days > warnDays) return KeyExpiryState.none;
    if (days <= 0) return KeyExpiryState.expired;
    return KeyExpiryState.expiring(days);
  }

  Future<void> _evaluate() async {
    if (_disposed) return;
    final profile = _profile;
    final state = stateOf(profile, _clock.now());
    if (state != _current) {
      _current = state;
      if (!_states.isClosed) _states.add(state);
    }
    if (profile == null || state is! KeyExpiring) return;
    final threshold = thresholds.lastWhere((t) => state.days <= t);
    final created = profile.credentialCreatedAt.toUtc().toIso8601String();
    final notified = switch (await _settings.read(keyExpiryNotifiedKey)) {
      {'credentialCreatedAt': final String at, 'threshold': final int t}
          when at == created =>
        t,
      _ => null,
    };
    if (notified != null && notified <= threshold) return;
    await _settings.write(keyExpiryNotifiedKey, {
      'credentialCreatedAt': created,
      'threshold': threshold,
    });
    if (_disposed || !await _notifications.requestPermission()) return;
    final text = _text(state.days);
    await _notifications.show(
      id: _notificationId,
      channel: accountNotificationChannel,
      title: text.title,
      body: text.body,
      payload: relinkPayload(profile.id),
    );
    _log.info('Key expiry notified', {
      'profileId': profile.id,
      'threshold': threshold,
    });
  }

  /// One notification per app: a later one replaces an earlier one.
  static const _notificationId = 1401;

  /// Stops the timer and the profile stream and closes [states].
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    unawaited(_states.close());
  }
}
