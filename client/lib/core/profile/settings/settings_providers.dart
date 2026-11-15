// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/core/profile/settings/settings_repository.dart';

/// The [SettingsRepository] of the profile scope.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>(
      (ref) => SettingsRepository(ref.watch(soundspanApiProvider).rest.session),
      dependencies: [soundspanApiProvider],
    );
