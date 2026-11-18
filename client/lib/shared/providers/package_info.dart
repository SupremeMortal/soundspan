// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's name, version and build number from the platform; tests
/// override it.
final FutureProvider<PackageInfo> packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());
