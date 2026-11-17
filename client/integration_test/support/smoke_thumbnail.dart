// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// A thumbnail file for the media controls smoke test: `smokeThumbnail()`
/// writes a small PNG and returns its `file://` URI, or null on the web,
/// which has no files.
library;

export 'smoke_thumbnail_web.dart'
    if (dart.library.io) 'smoke_thumbnail_io.dart';
