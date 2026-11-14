// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter/foundation.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';

/// The capabilities of the operating system the app runs on.
PlatformCapabilities currentPlatformCapabilities() =>
    PlatformCapabilities.forTarget(defaultTargetPlatform);
