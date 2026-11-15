// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The hook through which a `FeatureDisabled` response asks for an immediate
/// capability refresh (doc 04, Capability Discovery and Version Gate).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks the active profile's capability refresher to run now.
///
/// The default does nothing; each profile container overrides it with its
/// capability refresher's `refreshNow`. `ErrorView` calls it once for each
/// `FeatureDisabled` it shows.
final Provider<void Function()> capabilityRefreshProvider =
    Provider<void Function()>((ref) => () {}, dependencies: const []);
