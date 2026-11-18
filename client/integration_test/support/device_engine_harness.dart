// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The device engine harness: `DeviceEngineSetup.start()` prepares the tone
/// server (in-process natively, a separate process on the web) and
/// `setup.harness()` makes one harness per test.
library;

export 'device_engine_harness_web.dart'
    if (dart.library.io) 'device_engine_harness_io.dart';
