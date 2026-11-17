// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The state behind the Vibe screen: one search per description and one
/// list of similar tracks per library id, never cached and never retried
/// on their own.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:soundspan/features/vibe/vibe_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// How long the search waits after the last keystroke.
const Duration vibeSearchDebounce = Duration(milliseconds: 400);

/// How long the similar section waits after the current track changes.
const Duration vibeSeedDebounce = Duration(seconds: 1);

Duration? _noRetry(int _, Object _) => null;

/// The tracks matching a trimmed description.
final FutureProviderFamily<List<Track>, String> vibeSearchResultsProvider =
    FutureProvider.autoDispose.family<List<Track>, String>(
      (ref, query) => ref.watch(vibeRepositoryProvider).search(query),
      retry: _noRetry,
      dependencies: [vibeRepositoryProvider],
    );

/// The tracks similar to a library track.
final FutureProviderFamily<List<Track>, String> vibeSimilarProvider =
    FutureProvider.autoDispose.family<List<Track>, String>(
      (ref, libraryId) => ref.watch(vibeRepositoryProvider).similar(libraryId),
      retry: _noRetry,
      dependencies: [vibeRepositoryProvider],
    );
