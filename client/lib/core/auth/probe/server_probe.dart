// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:soundspan/core/auth/probe/probe_failure.dart';
import 'package:soundspan/core/auth/server_address.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan_api/soundspan_api.dart';

/// The two anonymous session calls the probe makes once `/api/health`
/// answered.
abstract interface class ProbeSession {
  /// `GET /api/auth/config`.
  Future<AuthConfig> authConfig();

  /// `GET /api/onboarding/status`.
  Future<OnboardingStatus> onboardingStatus();

  /// Releases the connection.
  void close();
}

/// Creates the [ProbeSession] for a server's base URL.
typedef ProbeSessionFactory = ProbeSession Function(Uri baseUrl);

/// The default [ProbeSessionFactory]: the generated session client of a
/// [SoundspanApi.anonymous] with 10 s connect and receive timeouts.
ProbeSession anonymousProbeSession(Uri baseUrl) => _AnonymousProbeSession(
  SoundspanApi.anonymous(baseUrl, receiveTimeout: const Duration(seconds: 10)),
);

class _AnonymousProbeSession implements ProbeSession {
  new(this._api);

  final SoundspanApi _api;

  @override
  Future<AuthConfig> authConfig() =>
      _api.send((rest) => rest.session.getAuthConfig());

  @override
  Future<OnboardingStatus> onboardingStatus() =>
      _api.send((rest) => rest.session.getOnboardingStatus());

  @override
  void close() => _api.close();
}

/// What a probe found at a server that answered as soundspan.
class ProbeResult {
  /// Creates a result.
  const new({
    required this.baseUrl,
    required this.requestedBaseUrl,
    required this.localLoginEnabled,
    required this.oidcEnabled,
    required this.isCleartext,
    required this.isPrivateHost,
    this.oidcProviderName,
    this.healthVersion,
    this.linkCode,
  });

  /// The base URL after redirects; requests go here.
  final Uri baseUrl;

  /// The candidate the probe started from.
  final Uri requestedBaseUrl;

  /// Whether redirects moved [baseUrl] away from [requestedBaseUrl].
  bool get baseChanged => baseUrl != requestedBaseUrl;

  /// Whether password sign-in is offered.
  final bool localLoginEnabled;

  /// Whether OIDC sign-in is offered.
  final bool oidcEnabled;

  /// The OIDC provider's display name, as the server gives it.
  final String? oidcProviderName;

  /// The health body's `version`; null when absent or `unknown`.
  final String? healthVersion;

  /// The device-link code of the address, when it came from a link.
  final String? linkCode;

  /// Whether [baseUrl] is plain `http`.
  final bool isCleartext;

  /// Whether [baseUrl]'s host is private ([ServerAddress.isPrivateHost]).
  final bool isPrivateHost;
}

/// Why a probe failed, and where.
class ProbeFailure {
  /// Creates a failure.
  const new({
    required this.failureClass,
    required this.candidate,
    this.status,
    this.linkCode,
  });

  /// The classification.
  final ProbeFailureClass failureClass;

  /// The candidate base URL that failed.
  final Uri candidate;

  /// The HTTP status of the failing response, when one arrived.
  final int? status;

  /// The device-link code of the address, when it came from a link.
  final String? linkCode;
}

/// A step of a probe run.
sealed class ProbeState {
  const new();
}

/// Requesting `/api/health` of [candidate].
final class ProbeResolving extends ProbeState {
  /// Creates the state.
  const new(this.candidate);

  /// The candidate being tried.
  final Uri candidate;
}

/// The server at [candidate] is starting or draining; the probe retries
/// every 3 s for [secondsLeft] more seconds.
final class ProbeStarting extends ProbeState {
  /// Creates the state.
  const new(this.candidate, this.secondsLeft);

  /// The candidate being tried.
  final Uri candidate;

  /// Seconds until the probe gives up with
  /// [ProbeFailureClass.serverError].
  final int secondsLeft;
}

/// A soundspan server with an account answered.
final class ProbeReady extends ProbeState {
  /// Creates the state.
  const new(this.result);

  /// What the probe found.
  final ProbeResult result;
}

/// A soundspan server answered, but nobody has set it up yet.
final class ProbeNeedsSetup extends ProbeState {
  /// Creates the state.
  const new(this.result);

  /// What the probe found.
  final ProbeResult result;
}

/// Every candidate failed; [failure] is the one to report.
final class ProbeFailed extends ProbeState {
  /// Creates the state.
  const new(this.failure);

  /// The reported failure.
  final ProbeFailure failure;
}

/// Finds out whether a soundspan server answers at a [ServerAddress]: the
/// Probe of doc 04.
class ServerProbe {
  /// Creates a probe. `client` creates the [ProbeClient] of one run, which
  /// the run closes; `session` creates the anonymous session client of the
  /// server found.
  new({
    required this._client,
    required this._session,
    required this._clock,
    required this._isWeb,
  });

  final ProbeClient Function() _client;
  final ProbeSessionFactory _session;
  final Clock _clock;
  final bool _isWeb;

  /// How many redirects are followed.
  static const maxRedirects = 3;

  /// The interval between attempts while the server is starting.
  static const startingRetry = Duration(seconds: 3);

  /// How long a starting server is waited for.
  static const startingLimit = Duration(seconds: 30);

  static const _healthPath = '/api/health';
  static const _redirects = {301, 302, 307, 308};

  /// Tries each candidate of [address] in order and ends with
  /// [ProbeReady], [ProbeNeedsSetup] or [ProbeFailed].
  ///
  /// Cancelling the subscription stops the run, including pending retries.
  Stream<ProbeState> run(ServerAddress address) {
    late final _Run run;
    final controller = StreamController<ProbeState>(
      onListen: () => unawaited(run.drive()),
      onCancel: () => run.cancel(),
    );
    run = _Run(this, address, controller);
    return controller.stream;
  }
}

/// The outcome of one candidate: a final state, or a failure to keep.
typedef _Outcome = ({ProbeState? done, ProbeFailure? failure});

class _Run {
  new(this._probe, this._address, this._out);

  final ServerProbe _probe;
  final ServerAddress _address;
  final StreamController<ProbeState> _out;
  late final ProbeClient _client = _probe._client();
  Timer? _timer;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    _timer?.cancel();
    _client.close();
  }

  void _emit(ProbeState state) {
    if (!_cancelled) _out.add(state);
  }

  Future<void> drive() async {
    final failures = <ProbeFailure>[];
    for (final candidate in _address.candidates) {
      _emit(ProbeResolving(candidate));
      final outcome = await _candidate(candidate);
      if (_cancelled) return;
      if (outcome.done != null) {
        _finish(outcome.done!);
        return;
      }
      failures.add(outcome.failure!);
    }
    final reported = failures.firstWhere(
      (f) => f.status != null,
      orElse: () => failures.first,
    );
    _finish(ProbeFailed(reported));
  }

  void _finish(ProbeState state) {
    if (_cancelled) return;
    _out.add(state);
    _client.close();
    unawaited(_out.close());
  }

  _Outcome _fail(Uri candidate, ProbeFailureClass failureClass, int? status) =>
      (
        done: null,
        failure: ProbeFailure(
          failureClass: failureClass,
          candidate: candidate,
          status: status,
          linkCode: _address.linkCode,
        ),
      );

  Future<_Outcome> _candidate(Uri candidate) async {
    DateTime? deadline;
    while (true) {
      final health = await _health(candidate);
      if (_cancelled || health.outcome != null) {
        return health.outcome ?? (done: null, failure: null);
      }
      final response = health.response!;
      final json = response.json;
      final hasHealthBody = json != null && json['status'] is String;
      final failureClass = classifyProbeFailure(
        status: response.status,
        hasHealthBody: hasHealthBody,
        isWeb: _probe._isWeb,
      );
      if (failureClass != null) {
        return _fail(candidate, failureClass, response.status);
      }
      final path = response.uri.path;
      if (!path.endsWith(ServerProbe._healthPath)) {
        return _fail(
          candidate,
          ProbeFailureClass.notSoundspan,
          response.status,
        );
      }
      if (response.status == 503) {
        final now = _probe._clock.now();
        final end = deadline ??= now.add(ServerProbe.startingLimit);
        final left = end.difference(now);
        if (left <= Duration.zero) {
          return _fail(candidate, ProbeFailureClass.serverError, 503);
        }
        _emit(ProbeStarting(candidate, left.inSeconds));
        await _sleep(ServerProbe.startingRetry);
        if (_cancelled) return (done: null, failure: null);
        continue;
      }
      final base = _baseOf(response.uri, path);
      return await _config(candidate, base, json);
    }
  }

  /// `GET /api/health` of [candidate], following redirects by hand.
  Future<({ProbeResponse? response, _Outcome? outcome})> _health(
    Uri candidate,
  ) async {
    var uri = Uri.parse('$candidate${ServerProbe._healthPath}');
    for (var hops = 0; ; hops++) {
      final ProbeResponse response;
      try {
        response = await _client.get(uri);
      } on ProbeTransportException catch (error) {
        final failureClass = classifyProbeFailure(
          transport: error.kind,
          hasHealthBody: false,
          isWeb: _probe._isWeb,
        );
        return (response: null, outcome: _fail(candidate, failureClass!, null));
      }
      final location = response.location;
      if (!ServerProbe._redirects.contains(response.status) ||
          location == null) {
        return (response: response, outcome: null);
      }
      final refused =
          hops >= ServerProbe.maxRedirects ||
          (location.scheme != 'http' && location.scheme != 'https') ||
          (uri.scheme == 'https' && location.scheme == 'http');
      if (refused) {
        return (
          response: null,
          outcome: _fail(
            candidate,
            ProbeFailureClass.redirectRefused,
            response.status,
          ),
        );
      }
      uri = location;
    }
  }

  /// [uri] without the `/api/health` suffix of [path], its query and its
  /// fragment.
  static Uri _baseOf(Uri uri, String path) => Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path.substring(0, path.length - ServerProbe._healthPath.length),
  );

  Future<_Outcome> _config(
    Uri candidate,
    Uri base,
    Map<String, Object?>? health,
  ) async {
    final session = _probe._session(base);
    final AuthConfig config;
    final OnboardingStatus onboarding;
    try {
      config = await session.authConfig();
      onboarding = await session.onboardingStatus();
    } on ApiException catch (error) {
      return _fail(candidate, _classifyApiError(error), error.status);
    } finally {
      session.close();
    }
    final version = health?['version'];
    final result = ProbeResult(
      baseUrl: base,
      requestedBaseUrl: candidate,
      localLoginEnabled: config.localLoginEnabled,
      oidcEnabled: config.oidcEnabled,
      oidcProviderName: config.oidcProviderName,
      healthVersion: version is String && version != 'unknown' ? version : null,
      linkCode: _address.linkCode,
      isCleartext: base.scheme == 'http',
      isPrivateHost: ServerAddress.isPrivateHost(base.host),
    );
    return (
      done: onboarding.hasAccount
          ? ProbeReady(result)
          : ProbeNeedsSetup(result),
      failure: null,
    );
  }

  ProbeFailureClass _classifyApiError(ApiException error) => switch (error) {
    Unauthenticated() || Forbidden() => ProbeFailureClass.blockedByProxy,
    ServerError() || Upstream() => ProbeFailureClass.serverError,
    Offline() =>
      _probe._isWeb
          ? ProbeFailureClass.corsOrNetwork
          : ProbeFailureClass.timeout,
    _ => ProbeFailureClass.notSoundspan,
  };

  Future<void> _sleep(Duration duration) {
    final done = Completer<void>();
    _timer = Timer(duration, done.complete);
    return done.future;
  }
}
