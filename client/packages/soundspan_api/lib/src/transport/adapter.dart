// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The platform HTTP adapter: `IOHttpClientAdapter` on native targets,
/// `BrowserHttpClientAdapter` on the web.
library;

export 'adapter_io.dart' if (dart.library.js_interop) 'adapter_web.dart';
