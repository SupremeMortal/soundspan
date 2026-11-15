// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan_api/soundspan_api.dart';

/// Why a server probe failed: the rows of the Failure Classification table
/// of doc 04, plus [redirectRefused].
enum ProbeFailureClass {
  /// The host name did not resolve.
  dns,

  /// Nothing is listening at that address and port.
  refused,

  /// The server did not answer.
  timeout,

  /// The server's certificate is not trusted by this device.
  tls,

  /// Something in front of the server requires its own login (401 or 403).
  blockedByProxy,

  /// The address answered, but not as a soundspan server.
  notSoundspan,

  /// A 5xx without a health body, or a server still starting after 30 s.
  serverError,

  /// Web only: no response, which the browser does not tell apart from a
  /// CORS rejection.
  corsOrNetwork,

  /// A redirect the probe will not follow: a fourth hop, a scheme other than
  /// `http` or `https`, or a downgrade from `https` to `http`.
  redirectRefused,
}

/// Classifies the outcome of one `GET /api/health`.
///
/// Give [transport] when no response arrived, or [status] and whether the
/// body was a health body ([hasHealthBody]: a JSON object with a string
/// `status`). Returns null when the signal is not a failure: a 200 or a 503
/// with a health body.
ProbeFailureClass? classifyProbeFailure({
  required bool hasHealthBody,
  required bool isWeb,
  TransportFailure? transport,
  int? status,
}) {
  if (status == null) {
    if (transport == null) {
      throw ArgumentError('either transport or status is required');
    }
    if (isWeb) return ProbeFailureClass.corsOrNetwork;
    return switch (transport) {
      TransportFailure.hostLookup => ProbeFailureClass.dns,
      TransportFailure.connectionRefused => ProbeFailureClass.refused,
      TransportFailure.tls => ProbeFailureClass.tls,
      TransportFailure.timeout ||
      TransportFailure.connection => ProbeFailureClass.timeout,
    };
  }
  if (hasHealthBody && (status == 200 || status == 503)) return null;
  if (status == 401 || status == 403) return ProbeFailureClass.blockedByProxy;
  if (status >= 500) return ProbeFailureClass.serverError;
  return ProbeFailureClass.notSoundspan;
}
