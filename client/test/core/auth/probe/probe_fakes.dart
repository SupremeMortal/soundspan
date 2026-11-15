// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:fake_async/fake_async.dart';
import 'package:soundspan/core/auth/probe/server_probe.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// One scripted answer of a [FakeProbeClient]: a response or a transport
/// failure.
typedef ProbeAnswer = ProbeResponse Function(Uri uri);

/// A 200 with [json] as its body.
ProbeAnswer ok(Map<String, Object?> json) => reply(200, json);

/// A response with [status] and an optional JSON body.
ProbeAnswer reply(int status, [Map<String, Object?>? json]) =>
    (uri) => ProbeResponse(uri: uri, status: status, json: json);

/// A redirect with [status] to [location].
ProbeAnswer redirect(int status, String location) =>
    (uri) => ProbeResponse(
      uri: uri,
      status: status,
      location: uri.resolve(location),
    );

/// No response, for [kind].
ProbeAnswer refused(TransportFailure kind) =>
    (_) => throw ProbeTransportException(kind);

/// A [Clock] that reads the fake time of a `FakeAsync`.
class FakeAsyncClock implements Clock {
  /// Creates a clock over a `FakeAsync`.
  new(this._async);

  final FakeAsync _async;
  static final DateTime _start = DateTime.utc(2025);

  @override
  DateTime now() => _start.add(_async.elapsed);
}

/// A [ProbeClient] that answers each URL from a script, in order; the last
/// answer of a URL repeats.
class FakeProbeClient implements ProbeClient {
  /// Creates a client over [script], keyed by absolute URL.
  new(this.script);

  /// The answers per URL.
  final Map<String, List<ProbeAnswer>> script;

  /// The URLs requested, in order.
  final List<String> requested = [];

  /// The fake time of each request, measured from the first.
  final List<Duration> times = [];

  final Map<String, int> _served = {};
  DateTime? _first;

  /// Whether [close] was called.
  bool closed = false;

  /// The clock [times] are read from; without one they are all zero.
  Clock? timeSource;

  @override
  Future<ProbeResponse> get(Uri absolute) async {
    final key = absolute.toString();
    requested.add(key);
    final now = timeSource?.now() ?? DateTime.utc(2025);
    final first = _first ??= now;
    times.add(now.difference(first));
    final answers = script[key];
    if (answers == null) throw StateError('unscripted request $key');
    final index = _served[key] ?? 0;
    _served[key] = index + 1;
    return answers[index < answers.length ? index : answers.length - 1](
      absolute,
    );
  }

  @override
  void close() => closed = true;
}

/// Creates [ProbeSession]s with fixed answers and records their bases.
class FakeProbeSessions {
  /// Creates sessions answering [config] and [hasAccount], or throwing
  /// [configError] or [onboardingError].
  new({
    this.config = const AuthConfig(
      localLoginEnabled: true,
      oidcEnabled: false,
      oidcProviderName: '',
    ),
    this.hasAccount = true,
    this.configError,
    this.onboardingError,
  });

  /// The `/auth/config` answer.
  final AuthConfig config;

  /// The `/onboarding/status` `hasAccount`.
  final bool hasAccount;

  /// Thrown by `/auth/config` when set.
  final ApiException? configError;

  /// Thrown by `/onboarding/status` when set.
  final ApiException? onboardingError;

  /// The base URL of each session created.
  final List<Uri> bases = [];

  /// How many sessions were closed.
  int closed = 0;

  /// A [ProbeSessionFactory].
  ProbeSession call(Uri baseUrl) {
    bases.add(baseUrl);
    return _FakeProbeSession(this);
  }
}

class _FakeProbeSession implements ProbeSession {
  new(this._owner);

  final FakeProbeSessions _owner;

  @override
  Future<AuthConfig> authConfig() async {
    final error = _owner.configError;
    if (error != null) throw error;
    return _owner.config;
  }

  @override
  Future<OnboardingStatus> onboardingStatus() async {
    final error = _owner.onboardingError;
    if (error != null) throw error;
    return OnboardingStatus(
      hasAccount: _owner.hasAccount,
      needsOnboarding: !_owner.hasAccount,
    );
  }

  @override
  void close() => _owner.closed++;
}
