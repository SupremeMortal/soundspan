// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Offline mode in the Library (doc 07, Reachability and Offline Mode): the
/// "Downloaded only" filter, what it lists, and which tracks have a file
/// on this device.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/connectivity/reachability.dart';
import 'package:soundspan/core/downloads/download_keys.dart';
import 'package:soundspan/core/downloads/downloaded_library.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/core/profile/profile_providers.dart';
import 'package:soundspan/core/profile/reachability_binding.dart';
import 'package:soundspan/core/storage/state/enums.dart';
import 'package:soundspan/features/downloads/ui/download_providers.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// Whether the Library's "Downloaded only" filter is on: true whenever the
/// state becomes offline (anything but [Reachability.online]) and false
/// whenever it returns to online. The user may toggle it in either state;
/// the choice lasts until the next such change and is not persisted.
class DownloadedOnlyNotifier extends Notifier<bool> {
  @override
  bool build() {
    final reachability = ref.watch(reachabilityProvider);
    var offline = !reachability.isOnline;
    final subscription = reachability.changes.listen((next) {
      final nowOffline = next != Reachability.online;
      if (nowOffline == offline) return;
      offline = nowOffline;
      state = nowOffline;
    });
    ref.onDispose(() => unawaited(subscription.cancel()));
    return offline;
  }

  /// Turns the filter off when on and on when off, until the next
  /// reachability change.
  void toggle() => state = !state;
}

/// The profile's "Downloaded only" filter.
final NotifierProvider<DownloadedOnlyNotifier, bool> downloadedOnlyProvider =
    NotifierProvider<DownloadedOnlyNotifier, bool>(
      DownloadedOnlyNotifier.new,
      dependencies: [profileContextProvider],
    );

/// Whether the state is anything but [Reachability.online].
final Provider<bool> isOfflineProvider = Provider.autoDispose<bool>((ref) {
  final state =
      ref.watch(reachabilityStateProvider).value ??
      ref.watch(reachabilityProvider).current;
  return state != Reachability.online;
});

/// Whether the Library filters by downloads now: the filter is on and the
/// platform downloads.
final Provider<bool> showDownloadedOnlyProvider = Provider.autoDispose<bool>(
  (ref) =>
      ref.watch(downloadsAvailableProvider) &&
      ref.watch(downloadedOnlyProvider),
  dependencies: [downloadedOnlyProvider],
);

/// Whether the "Downloaded only" chip is offered: never where the platform
/// does not download; always while offline; online only while the profile
/// has at least one download collection.
final Provider<bool> downloadedOnlyChipVisibleProvider =
    Provider.autoDispose<bool>((ref) {
      if (!ref.watch(downloadsAvailableProvider)) return false;
      if (ref.watch(isOfflineProvider)) return true;
      return ref.watch(hasDownloadCollectionsProvider).value ?? false;
    }, dependencies: [hasDownloadCollectionsProvider]);

/// Whether the profile has at least one download collection, read from
/// `state.db` without starting the download machinery.
final StreamProvider<bool> hasDownloadCollectionsProvider =
    StreamProvider.autoDispose<bool>(
      (ref) => ref.watch(downloadedLibraryProvider).watchHasCollections(),
      dependencies: [downloadedLibraryProvider],
      retry: _noRetry,
    );

/// Whether the track [playbackId] is disabled as "Not available offline":
/// only while offline, on a platform that downloads, when the track has no
/// completed file. Online nothing is disabled by this rule.
bool watchUnavailableOffline(WidgetRef ref, PlaybackId? playbackId) {
  if (playbackId == null) return false;
  if (!ref.watch(isOfflineProvider)) return false;
  if (!ref.watch(downloadsAvailableProvider)) return false;
  final key = TrackItemKey(playbackId.value);
  return ref.watch(
    itemDownloadStatesProvider.select(
      (states) => states.value?[key]?.status != DownloadStatus.completed,
    ),
  );
}

/// The playback ids of the tracks with a file on this device while the
/// app is offline, on a platform that downloads; null otherwise (online,
/// or no downloads), when nothing restricts what can be queued.
Future<Set<PlaybackId>?> availableOffline(Ref ref) async {
  if (!ref.read(downloadsAvailableProvider)) return null;
  if (ref.read(reachabilityProvider).isOnline) return null;
  return await ref.read(downloadedLibraryProvider).downloadedPlaybackIds();
}

/// Turns forced offline mode [on] or off: writes `offline.forced` of the
/// profile in [container] (doc 05, `device_settings`), which the
/// reachability controller follows.
Future<void> setOfflineForced(
  ProviderContainer container, {
  required bool on,
}) => container.read(deviceSettingsDaoProvider).write(offlineForcedKey, on);

Duration? _noRetry(int _, Object _) => null;

/// What the Library lists with the filter on, by kind.
enum DownloadedList {
  /// Completed tracks, by title.
  tracks,

  /// Album collections and albums with a completed track.
  albums,

  /// Artists of completed tracks.
  artists,

  /// Playlist collections.
  playlists,
}

/// One list of the downloaded library; empty where the platform does not
/// download.
final StreamProviderFamily<List<Object>, DownloadedList>
downloadedListProvider = StreamProvider.autoDispose
    .family<List<Object>, DownloadedList>(
      (ref, list) {
        if (!ref.watch(downloadsAvailableProvider)) {
          return Stream.value(const []);
        }
        final library = ref.watch(downloadedLibraryProvider);
        return switch (list) {
          DownloadedList.tracks => library.watchTracks(),
          DownloadedList.albums => library.watchAlbums(),
          DownloadedList.artists => library.watchArtists(),
          DownloadedList.playlists => library.watchPlaylists(),
        };
      },
      dependencies: [downloadedLibraryProvider],
      retry: _noRetry,
    );

/// A [PagedSource] over the items of [list], all loaded at once, emitting
/// again whenever the list changes. The Library tabs use it with the
/// filter on, so the same views render downloaded content.
PagedSource<T> downloadedSource<T>(WidgetRef ref, DownloadedList list) {
  final source = _ListPagedSource<T>();
  final subscription = ref.listenManual(downloadedListProvider(list), (
    _,
    next,
  ) {
    if (next.value case final items?) source.set(items.cast<T>());
  }, fireImmediately: true);
  source.onDispose = subscription.close;
  return source;
}

final class _ListPagedSource<T> implements PagedSource<T> {
  final StreamController<PagedSnapshot<T>> _controller =
      StreamController<PagedSnapshot<T>>.broadcast();
  PagedSnapshot<T>? _latest;
  void Function()? onDispose;

  void set(List<T> items) {
    _latest = PagedSnapshot<T>(
      total: items.length,
      items: {for (final (index, item) in items.indexed) index: item},
    );
    if (!_controller.isClosed) _controller.add(_latest!);
  }

  @override
  int get pageSize => listPageSize;

  @override
  Stream<PagedSnapshot<T>> watch() async* {
    if (_latest case final latest?) yield latest;
    yield* _controller.stream;
  }

  @override
  void ensureVisible(int first, int last) {}

  @override
  Future<void> refresh() async {}

  @override
  void dispose() {
    onDispose?.call();
    unawaited(_controller.close());
  }
}

/// The "Downloaded only" filter chip of the Library's chip row, shown
/// while [downloadedOnlyChipVisibleProvider] is true.
class DownloadedOnlyChip extends ConsumerWidget {
  /// Creates the chip.
  const new({super.key});

  /// The key of the chip.
  static const Key chipKey = Key('library.downloadedOnly');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(downloadedOnlyChipVisibleProvider)) {
      return const SizedBox.shrink();
    }
    return FilterChip(
      key: chipKey,
      label: Text(AppLocalizations.of(context).libraryDownloadedOnly),
      selected: ref.watch(downloadedOnlyProvider),
      onSelected: (_) => ref.read(downloadedOnlyProvider.notifier).toggle(),
    );
  }
}
