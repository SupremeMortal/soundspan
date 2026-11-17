// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// What the download UI reads: whether this platform downloads at all, the
/// state of every item and of each collection, and the Downloads tab's
/// list (doc 07, Requesting a Download; doc 09, Library).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show FutureProviderFamily, StreamProviderFamily;
import 'package:soundspan/core/downloads/download_artwork.dart';
import 'package:soundspan/core/downloads/download_controller.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/offline_models.dart';
import 'package:soundspan/features/downloads/ui/download_glyph_mapper.dart';
import 'package:soundspan/platform/capabilities/capabilities.dart';
import 'package:soundspan/shared/domain/playback_id.dart';
import 'package:soundspan/shared/widgets/download_glyph.dart';

Duration? _noRetry(int _, Object _) => null;

/// Whether this platform downloads ([PlatformCapabilities.canDownload]);
/// every download glyph, action and the Downloads tab are hidden when not.
final Provider<bool> downloadsAvailableProvider = Provider<bool>(
  (ref) => ref.watch(platformCapabilitiesProvider).canDownload,
);

/// The download state of every item by its key; empty where the platform
/// does not download.
final StreamProvider<Map<DownloadItemKey, ItemDownloadState>>
itemDownloadStatesProvider =
    StreamProvider<Map<DownloadItemKey, ItemDownloadState>>(
      (ref) {
        if (!ref.watch(downloadsAvailableProvider)) {
          return Stream.value(const {});
        }
        return ref.watch(downloadControllerProvider).watchItems();
      },
      dependencies: [downloadControllerProvider],
      retry: _noRetry,
    );

/// The glyph of the track [playbackId], watched through a `select` so only
/// a change of that track's glyph rebuilds the caller.
DownloadGlyphState watchTrackGlyph(WidgetRef ref, PlaybackId playbackId) {
  final key = TrackItemKey(playbackId.value);
  return ref.watch(
    itemDownloadStatesProvider.select(
      (states) => glyphOfItem(states.value?[key]),
    ),
  );
}

/// The download state of one collection, null while it is not pinned or
/// where the platform does not download.
final StreamProviderFamily<
  CollectionDownloadState?,
  ({CollectionKind kind, String refId})
>
collectionDownloadStateProvider = StreamProvider.autoDispose
    .family<CollectionDownloadState?, ({CollectionKind kind, String refId})>(
      (ref, key) {
        if (!ref.watch(downloadsAvailableProvider)) {
          return Stream.value(null);
        }
        return ref
            .watch(downloadControllerProvider)
            .watchCollection(key.kind, key.refId);
      },
      dependencies: [downloadControllerProvider],
      retry: _noRetry,
    );

/// Every pinned track, album and playlist in request order, for the
/// Downloads tab.
final StreamProvider<List<DownloadCollectionEntry>>
downloadCollectionEntriesProvider =
    StreamProvider.autoDispose<List<DownloadCollectionEntry>>(
      (ref) {
        if (!ref.watch(downloadsAvailableProvider)) {
          return Stream.value(const []);
        }
        return ref.watch(downloadControllerProvider).watchCollectionEntries();
      },
      dependencies: [downloadControllerProvider],
      retry: _noRetry,
    );

/// The glyph a track's menu offers download entries for: null where the
/// platform does not download (the entries are hidden), else the track's
/// current glyph.
DownloadGlyphState? trackMenuGlyph(WidgetRef ref, PlaybackId? playbackId) {
  if (!ref.read(downloadsAvailableProvider)) return null;
  if (playbackId == null) return DownloadGlyphState.none;
  return glyphOfItem(
    ref.read(itemDownloadStatesProvider).value?[TrackItemKey(playbackId.value)],
  );
}

/// The absolute path of the pinned cover file of an artwork ref, or null when
/// none is pinned or the platform does not download.
final FutureProviderFamily<String?, String> downloadArtworkFileProvider =
    FutureProvider.autoDispose.family<String?, String>(
      (ref, artworkRef) async {
        if (!ref.watch(downloadsAvailableProvider)) return null;
        return await ref.watch(downloadArtworkProvider).fileFor(artworkRef);
      },
      dependencies: [downloadArtworkProvider],
      retry: _noRetry,
    );
