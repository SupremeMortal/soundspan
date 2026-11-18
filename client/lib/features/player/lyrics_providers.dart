// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The profile-scoped [LyricsRepository] and the lyrics of the current
/// track, provided outside `data/` because `ui/` may not import it.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/api_provider.dart';
import 'package:soundspan/features/player/data/cached_lyrics_repository.dart';
import 'package:soundspan/features/player/domain/lyrics.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/cache.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// The profile's [LyricsRepository], over the generated `PlaybackClient`.
final FutureProvider<LyricsRepository> lyricsRepositoryProvider =
    FutureProvider<LyricsRepository>(
      (ref) async => CachedLyricsRepository(
        ref.watch(soundspanApiProvider).rest.playback,
        await ref.watch(cacheStoreProvider.future),
        ref.watch(swrProvider),
        ref.watch(clockProvider),
      ),
      dependencies: [soundspanApiProvider, cacheStoreProvider, swrProvider],
    );

/// The lyrics of the current track, from [LyricsRepository.lyrics]; null
/// while nothing plays or the current item is an episode. It is not
/// retried on error.
final StreamProvider<Cached<Lyrics>?> currentLyricsProvider =
    StreamProvider.autoDispose<Cached<Lyrics>?>(
      (ref) async* {
        final track = ref.watch(playbackControllerProvider.exists)
            ? ref.watch(
                playbackStateProvider.select(
                  (snapshot) => switch (snapshot.value?.current) {
                    TrackQueueItem(:final track) => track,
                    _ => null,
                  },
                ),
              )
            : null;
        if (track == null) {
          yield null;
          return;
        }
        final repository = await ref.watch(lyricsRepositoryProvider.future);
        yield* repository.lyrics(track);
      },
      retry: (_, _) => null,
      dependencies: [
        playbackControllerProvider,
        playbackStateProvider,
        lyricsRepositoryProvider,
      ],
    );
