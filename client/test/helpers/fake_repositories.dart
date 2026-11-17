// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncData;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/likes.dart';
import 'package:soundspan/shared/providers/repositories.dart';
import 'package:soundspan_api/soundspan_api.dart' show ApiException, NotFound;

import 'fake_clock.dart';

/// A [PagedSource] over an in-memory list for screen tests.
///
/// The total is known at once; a page loads after [pageDelay] (no delay
/// loads it in a microtask) when [ensureVisible] asks for it, following the
/// page rule of the real source. A page in [failingPages] fails with
/// [failure] instead. Every requested page is recorded in [requestedPages].
class FakePagedSource<T> implements PagedSource<T> {
  /// A list of [items], or of [total] items built by [itemBuilder].
  new({
    List<T> items = const [],
    int? total,
    T Function(int index)? itemBuilder,
    this.pageSize = listPageSize,
    this.pageDelay = Duration.zero,
    Set<int>? failingPages,
    this.failure = const NotFound(),
  }) : _itemAt = itemBuilder ?? ((index) => items[index]),
       total = total ?? items.length,
       failingPages = failingPages ?? {};

  @override
  final int pageSize;

  /// The number of items.
  final int total;

  /// How long a page takes to load.
  final Duration pageDelay;

  /// The pages that fail to load.
  final Set<int> failingPages;

  /// The error a failing page sets as `refreshError`.
  final ApiException failure;

  /// The pages requested, in order.
  final List<int> requestedPages = [];

  /// How many times [refresh] was called.
  int refreshCount = 0;

  /// Whether [dispose] was called.
  bool disposed = false;

  final T Function(int index) _itemAt;
  final StreamController<PagedSnapshot<T>> _changes =
      StreamController<PagedSnapshot<T>>.broadcast();
  final Map<int, T> _items = {};
  final Set<int> _requested = {};
  int _inflight = 0;
  ApiException? _error;
  (int, int) _visible = (0, 0);

  PagedSnapshot<T> get _snapshot => PagedSnapshot(
    total: total,
    items: Map.of(_items),
    refreshing: _inflight > 0,
    refreshError: _error,
  );

  @override
  Stream<PagedSnapshot<T>> watch() => Stream.multi((listener) {
    listener.add(_snapshot);
    final subscription = _changes.stream.listen(
      listener.add,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  @override
  void ensureVisible(int first, int last) {
    if (disposed) return;
    _visible = (first, last);
    final lastPage = math.max(first, last) ~/ pageSize + 1;
    for (var page = first ~/ pageSize; page <= lastPage; page++) {
      if (page * pageSize >= total && page > 0) break;
      if (_requested.add(page)) unawaited(_load(page));
    }
  }

  @override
  Future<void> refresh() async {
    refreshCount++;
    final (first, last) = _visible;
    await Future.wait([
      for (var page = first ~/ pageSize; page <= last ~/ pageSize; page++)
        _load(page),
    ]);
  }

  @override
  void dispose() {
    disposed = true;
    unawaited(_changes.close());
  }

  Future<void> _load(int page) async {
    requestedPages.add(page);
    _inflight++;
    _emit();
    await Future<void>.delayed(pageDelay);
    _inflight--;
    if (disposed) return;
    if (failingPages.contains(page)) {
      _requested.remove(page);
      _error = failure;
    } else {
      _error = null;
      final end = math.min(total, (page + 1) * pageSize);
      for (var index = page * pageSize; index < end; index++) {
        _items[index] = _itemAt(index);
      }
    }
    _emit();
  }

  void _emit() {
    if (!disposed) _changes.add(_snapshot);
  }
}

/// Counts calls by name and answers seeded values as fresh [Cached] reads.
mixin _FakeReads {
  /// When every seeded value was fetched.
  DateTime fetchedAt = FakeClock.defaultStart;

  /// Errors by method name: a read of that method errors with it, a
  /// refresh throws it.
  final Map<String, Exception> errors = {};

  /// Refresh errors by method name: a read of that method answers its
  /// seeded value as cached but failed to refresh with this error.
  final Map<String, ApiException> refreshErrors = {};

  /// Refresh calls by method name, such as `refreshAlbum`.
  final Map<String, int> refreshCalls = {};

  /// Read calls by method name, such as `album`.
  final Map<String, int> readCalls = {};

  Stream<Cached<V>> _read<V>(String method, V? value) {
    readCalls.update(method, (n) => n + 1, ifAbsent: () => 1);
    if (errors[method] case final error?) return Stream.error(error);
    if (value == null) return Stream.error(const NotFound());
    return Stream.value(
      Cached(
        value: value,
        fetchedAt: fetchedAt,
        refreshError: refreshErrors[method],
      ),
    );
  }

  /// How many times [method] was read.
  int readCount(String method) => readCalls[method] ?? 0;

  Future<void> _refresh(String method) async {
    refreshCalls.update(method, (n) => n + 1, ifAbsent: () => 1);
    if (errors[method] case final error?) throw error;
  }

  /// How many times [method] was refreshed.
  int refreshCount(String method) => refreshCalls[method] ?? 0;
}

/// An in-memory [LibraryRepository].
///
/// Details come from [albumDetails] and [artistDetails]; a missing one errors
/// with [NotFound]. Each paged call answers a new [FakePagedSource] over the
/// seeded list and records its query.
class FakeLibraryRepository with _FakeReads implements LibraryRepository {
  /// Album details by id.
  final Map<String, AlbumDetail> albumDetails = {};

  /// Artist details by id.
  final Map<String, ArtistDetail> artistDetails = {};

  /// The albums every [albums] call lists.
  List<Album> albumList = [];

  /// The artists every [artists] call lists.
  List<Artist> artistList = [];

  /// The tracks every [tracks] call lists.
  List<Track> trackList = [];

  /// The liked tracks.
  List<Track> likedList = [];

  /// How long each page of a paged source takes to load.
  Duration pageDelay = Duration.zero;

  /// The queries of the paged calls, in order.
  final List<Object> queries = [];

  /// The paged sources handed out, in order.
  final List<FakePagedSource<Object>> sources = [];

  @override
  Stream<Cached<AlbumDetail>> album(String id) =>
      _read('album', albumDetails[id]);

  @override
  Future<void> refreshAlbum(String id) => _refresh('refreshAlbum');

  @override
  Stream<Cached<ArtistDetail>> artist(String id) =>
      _read('artist', artistDetails[id]);

  @override
  Future<void> refreshArtist(String id) => _refresh('refreshArtist');

  @override
  PagedSource<Album> albums(AlbumQuery query) =>
      _source(query, albumList, gridPageSize);

  @override
  PagedSource<Artist> artists(ArtistQuery query) =>
      _source(query, artistList, gridPageSize);

  @override
  PagedSource<Track> tracks(TrackQuery query) =>
      _source(query, trackList, listPageSize);

  @override
  PagedSource<Track> likedTracks() => _source('liked', likedList, listPageSize);

  /// The tracks every [shuffledTracks] call answers, in the server's order.
  List<Track> shuffledList = [];

  @override
  Future<List<Track>> shuffledTracks() async {
    readCalls.update('shuffledTracks', (n) => n + 1, ifAbsent: () => 1);
    if (errors['shuffledTracks'] case final error?) throw error;
    return shuffledList;
  }

  FakePagedSource<T> _source<T extends Object>(
    Object query,
    List<T> items,
    int pageSize,
  ) {
    queries.add(query);
    final source = FakePagedSource<T>(
      items: items,
      pageSize: pageSize,
      pageDelay: pageDelay,
    );
    sources.add(source);
    return source;
  }
}

/// An in-memory [PlaylistRepository]; a missing detail errors with
/// [NotFound].
class FakePlaylistRepository with _FakeReads implements PlaylistRepository {
  /// Playlist details by id.
  final Map<String, PlaylistDetail> playlistDetails = {};

  /// The playlists every [playlists] call lists.
  List<PlaylistSummary> playlistList = [];

  /// The pages of [playlistList] that fail to load.
  Set<int> failingPages = {};

  /// The error a failing page of [playlistList] reports.
  ApiException failure = const NotFound();

  /// The paged sources handed out, in order.
  final List<FakePagedSource<PlaylistSummary>> sources = [];

  @override
  Stream<Cached<PlaylistDetail>> playlist(String id) =>
      _read('playlist', playlistDetails[id]);

  @override
  Future<void> refreshPlaylist(String id) => _refresh('refreshPlaylist');

  @override
  PagedSource<PlaylistSummary> playlists() {
    final source = FakePagedSource(
      items: playlistList,
      failingPages: {...failingPages},
      failure: failure,
    );
    sources.add(source);
    return source;
  }

  /// Every edit, in order, as `op id [argument]` strings.
  final List<String> edits = [];

  /// The id [create] answers next.
  String createdId = 'tmp_new';

  /// When set, [create] waits for it before answering.
  Completer<void>? createGate;

  @override
  Future<String> create(String name) async {
    edits.add('create $name');
    await createGate?.future;
    return createdId;
  }

  @override
  Future<void> rename(String id, String name) async =>
      edits.add('rename $id $name');

  @override
  Future<void> delete(String id) async => edits.add('delete $id');

  @override
  Future<int> addTracks(String id, List<Track> tracks) async {
    final playable = [for (final track in tracks) ?track.playbackId?.value];
    edits.add('add $id ${playable.join(',')}');
    return playable.length;
  }

  @override
  Future<void> removeItem(String id, PlaylistItem item) async =>
      edits.add('remove $id ${item.id}');

  @override
  Future<void> reorder(String id, List<PlaybackId> order) async =>
      edits.add('reorder $id ${[for (final p in order) p.value].join(',')}');

  /// Emits on [resolvedIds]; tests add the ids the server gave.
  final StreamController<PlaylistIdResolved> resolved =
      StreamController<PlaylistIdResolved>.broadcast();

  @override
  Stream<PlaylistIdResolved> get resolvedIds => resolved.stream;
}

/// An in-memory [HomeRepository]; every shelf is empty until seeded.
class FakeHomeRepository with _FakeReads implements HomeRepository {
  /// Continue Listening.
  List<RecentItem> recent = [];

  /// Recently added artists.
  List<Artist> added = [];

  /// The mixes.
  List<MixSummary> mixList = [];

  /// Popular podcasts.
  List<PodcastSummary> podcasts = [];

  @override
  Stream<Cached<List<RecentItem>>> recentlyListened() =>
      _read('recentlyListened', recent);

  @override
  Future<void> refreshRecentlyListened() => _refresh('refreshRecentlyListened');

  @override
  Stream<Cached<List<Artist>>> recentlyAdded() => _read('recentlyAdded', added);

  @override
  Future<void> refreshRecentlyAdded() => _refresh('refreshRecentlyAdded');

  @override
  Stream<Cached<List<MixSummary>>> mixes() => _read('mixes', mixList);

  @override
  Future<void> refreshMixes() => _refresh('refreshMixes');

  @override
  Stream<Cached<List<PodcastSummary>>> topPodcasts() =>
      _read('topPodcasts', podcasts);

  @override
  Future<void> refreshTopPodcasts() => _refresh('refreshTopPodcasts');
}

/// An in-memory [SearchRepository]: [results] by query, empty results for
/// any other query. Every search is recorded in [searches].
///
/// A search over a scope in [scopeErrors] errors with that error; a search
/// of a query in [delays] answers after that delay.
class FakeSearchRepository with _FakeReads implements SearchRepository {
  /// Results by query text.
  final Map<String, SearchResults> results = {};

  /// The searches, in order.
  final List<(String, SearchScope)> searches = [];

  /// Errors by scope.
  final Map<SearchScope, Exception> scopeErrors = {};

  /// Answer delays by query text.
  final Map<String, Duration> delays = {};

  @override
  Stream<Cached<SearchResults>> search(String query, SearchScope scope) {
    searches.add((query, scope));
    final read = switch (scopeErrors[scope]) {
      final error? => Stream<Cached<SearchResults>>.error(error),
      null => _read('search', results[query] ?? const SearchResults()),
    };
    final delay = delays[query];
    if (delay == null) return read;
    return Stream.fromFuture(Future<void>.delayed(delay))
        .asyncExpand((_) => read);
  }

  @override
  Future<void> refreshSearch(String query, SearchScope scope) =>
      _refresh('refreshSearch');
}

/// One fake of each repository, and the provider overrides that supply
/// them.
class FakeRepositories {
  /// The fakes; new empty ones unless given.
  new({
    FakeLibraryRepository? library,
    FakePlaylistRepository? playlists,
    FakeHomeRepository? home,
    FakeSearchRepository? search,
  }) : library = library ?? FakeLibraryRepository(),
       playlists = playlists ?? FakePlaylistRepository(),
       home = home ?? FakeHomeRepository(),
       search = search ?? FakeSearchRepository();

  /// The library fake.
  final FakeLibraryRepository library;

  /// The playlist fake.
  final FakePlaylistRepository playlists;

  /// The home fake.
  final FakeHomeRepository home;

  /// The search fake.
  final FakeSearchRepository search;

  /// The like command fake.
  final FakeTrackLikes likes = FakeTrackLikes();

  /// Overrides of the four repository providers and the like command with
  /// these fakes.
  List<Override> get overrides => [
    libraryRepositoryProvider.overrideWithValue(AsyncData(library)),
    playlistRepositoryProvider.overrideWithValue(AsyncData(playlists)),
    homeRepositoryProvider.overrideWithValue(AsyncData(home)),
    searchRepositoryProvider.overrideWithValue(AsyncData(search)),
    trackLikesProvider.overrideWithValue(likes),
  ];
}

/// A [TrackLikes] that records each toggle; read it back from a screen
/// test's container through `trackLikesProvider`.
class FakeTrackLikes implements TrackLikes {
  /// The tracks toggled, in order: each one is one outbox op.
  final List<Track> toggled = [];

  @override
  Future<void> toggleLike(Track track) async => toggled.add(track);
}
