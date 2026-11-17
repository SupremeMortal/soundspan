// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/app/media_browse_source_impl.dart';
import 'package:soundspan/core/playback/media_controls/artwork_pinner.dart';
import 'package:soundspan/core/playback/media_controls/audio_service_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls.dart';
import 'package:soundspan/core/playback/media_controls/media_controls_binder.dart';
import 'package:soundspan/core/playback/playback_providers.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/profile_runtime.dart';
import 'package:soundspan/core/sync/sync_providers.dart';
import 'package:soundspan/platform/artwork_store/artwork_store.dart';
import 'package:soundspan/platform/media_controls/media_controls_factory.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/providers/images.dart';
import 'package:soundspan_api/soundspan_api.dart' show ImageUrls;

/// The localized name of the Android playback notification channel.
/// Bootstrap overrides it; it throws until then.
final Provider<String> mediaControlsChannelNameProvider = Provider<String>(
  (ref) => throw UnimplementedError(
    'mediaControlsChannelNameProvider is set by bootstrap',
  ),
);

/// The localized label of the Like action of the Android playback
/// notification, by whether the item shown is liked. Bootstrap overrides
/// it; it throws until then.
final Provider<LikeLabel> mediaControlsLikeLabelProvider = Provider<LikeLabel>(
  (ref) => throw UnimplementedError(
    'mediaControlsLikeLabelProvider is set by bootstrap',
  ),
);

/// The localized titles of the Android Auto browse root. Bootstrap
/// overrides it; it throws until then.
final Provider<BrowseTitles> mediaControlsBrowseTitlesProvider =
    Provider<BrowseTitles>(
      (ref) => throw UnimplementedError(
        'mediaControlsBrowseTitlesProvider is set by bootstrap',
      ),
    );

/// The platform's [MediaControls], built by the media controls seam
/// (`audio_service` on Android, iOS, macOS, Linux and the web; none on
/// Windows). The channel name is read when they are initialised, the
/// Android Auto root titles each time the root is listed.
final Provider<MediaControls> mediaControlsProvider = Provider<MediaControls>(
  (ref) => createMediaControls(
    channelName: () => ref.read(mediaControlsChannelNameProvider),
    clock: ref.watch(clockProvider),
    likeLabel: (liked) => ref.read(mediaControlsLikeLabelProvider)(liked),
    browseTitles: () => ref.read(mediaControlsBrowseTitlesProvider)(),
  ),
);

/// The one [MediaCommandHandler] the [mediaControlsProvider] is initialised
/// with; it forwards to the active profile's binder.
final Provider<MediaControlsHost> mediaControlsHostProvider =
    Provider<MediaControlsHost>(
      (ref) => MediaControlsHost(ref.watch(mediaControlsProvider)),
    );

/// The [ArtworkPinner] of the profile scope: covers of the profile's server
/// with the session's current credentials, fetched through its image cache
/// and written under its `art/` directory.
final Provider<ArtworkPinner> artworkPinnerProvider = Provider<ArtworkPinner>(
  (ref) {
    final manager = ref.watch(imageCacheManagerProvider);
    final session = ref.watch(sessionControllerProvider);
    return ArtworkPinner(
      urls: ImageUrls(ref.watch(apiConfigProvider).baseUrl),
      credentials: () => session.current,
      fetch: (fetch) async {
        final file = await manager.getSingleFile(
          fetch.url.toString(),
          key: fetch.cacheKey,
          headers: fetch.headers,
        );
        return await file.readAsBytes();
      },
      store: ref.watch(artworkStoreProvider),
      artDirectory: ref.watch(profileContextProvider).paths?.art,
      isWeb: kIsWeb,
    );
  },
  dependencies: [
    imageCacheManagerProvider,
    sessionControllerProvider,
    apiConfigProvider,
    profileContextProvider,
  ],
);

/// After the first frame (doc 02, Bootstrap Sequence, step 8): initialises
/// the OS media surface once, then renders the active profile's
/// playback controller on it, rebinding whenever the active profile
/// changes; Android Auto browses that profile's library. With no active
/// profile the surface shows [MediaSessionState.empty].
Future<void> startMediaControls(ProviderContainer root) async {
  final host = root.read(mediaControlsHostProvider);
  await root.read(mediaControlsProvider).init(host);
  final runtime = root.read(profileRuntimeProvider);
  final clock = root.read(clockProvider);
  ProviderContainer? bound;
  var first = true;
  void onState() {
    final container = runtime.container;
    final active = runtime.state.value is ProfileRuntimeActive
        ? container
        : null;
    if (!first && identical(active, bound)) return;
    first = false;
    bound = active;
    unawaited(
      host.bind(
        active == null
            ? null
            : MediaControlsBinder(
                controller: active.read(playbackControllerProvider),
                controls: root.read(mediaControlsProvider),
                // Read at the first pin, so start-up opens no image cache.
                pin: (ref) => active.read(artworkPinnerProvider).pin(ref),
                clock: clock,
                like: (track, {required liked}) => active
                    .read(preferenceRepositoryProvider)
                    .setTrackLiked(track, liked: liked),
                browseSource: active.read(mediaBrowseSourceProvider),
              ),
      ),
    );
  }

  runtime.state.addListener(onState);
  onState();
}
