// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The names on the D-Bus session bus: `sessionBusNames()` lists them on
/// Linux and returns null elsewhere.
library;

export 'session_bus_names_web.dart'
    if (dart.library.io) 'session_bus_names_io.dart';
