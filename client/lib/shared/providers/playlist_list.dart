// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The user's playlist list, shared by the Library's Playlists tab and the
/// expanded sidebar so both read one [PagedSource] (doc 09, Library; Shell
/// by Window Class).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The paged source of the user's playlists, opened while anything reads
/// it and disposed after, also when its last reader left while the
/// repository was opening.
final FutureProvider<PagedSource<PlaylistSummary>> playlistListSourceProvider =
    FutureProvider.autoDispose<PagedSource<PlaylistSummary>>(
      (ref) async {
        final repository = await ref.watch(playlistRepositoryProvider.future);
        final source = repository.playlists();
        // The last reader may have left while the repository was opening.
        if (!ref.mounted) {
          source.dispose();
          return source;
        }
        ref.onDispose(source.dispose);
        source.ensureVisible(0, 0);
        return source;
      },
      retry: _noRetry,
      dependencies: [playlistRepositoryProvider],
    );

/// Every state of [playlistListSourceProvider].
final StreamProvider<PagedSnapshot<PlaylistSummary>> playlistListProvider =
    StreamProvider.autoDispose<PagedSnapshot<PlaylistSummary>>(
      (ref) async* {
        yield* (await ref.watch(playlistListSourceProvider.future)).watch();
      },
      retry: _noRetry,
      dependencies: [playlistListSourceProvider],
    );

/// Reads are not retried: the source keeps loaded items and reports its
/// errors in the snapshot.
Duration? _noRetry(int retryCount, Object error) => null;
