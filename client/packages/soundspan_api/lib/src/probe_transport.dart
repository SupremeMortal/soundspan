// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Maps a probe's transport error to a `TransportFailure`: from the
/// `dart:io` error types on native targets, always `connection` on the web.
library;

export 'probe_transport_io.dart'
    if (dart.library.js_interop) 'probe_transport_web.dart';
