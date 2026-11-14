// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The persistent log sink seam.
///
/// `createPersistentLogSink({String? directory})` returns a rolling file sink
/// in `directory` (`<appSupport>/logs`, required) on native targets and an
/// in-memory ring of the last 500 entries on web (`directory` is ignored).
library;

export 'log_sink_web.dart' if (dart.library.io) 'log_sink_io.dart';
