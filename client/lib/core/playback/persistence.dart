// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/core/playback/playback_snapshot.dart';
import 'package:soundspan/core/playback/queue/queue_state.dart';
import 'package:soundspan/core/storage/state/queue_dao.dart';
import 'package:soundspan/core/storage/state/state_database.dart';
import 'package:soundspan/shared/clock.dart';
import 'package:soundspan/shared/domain/queue_item.dart';

final AppLogger _log = AppLogger.scope('QueuePersistence');

/// Creates a one-shot timer; [Timer.new] outside tests.
typedef PersistenceTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

/// A queue read back from `state.db` and where its current item stopped.
typedef RestoredQueue = ({QueueState queue, Duration position});

/// Keeps this device's queue and position in `state.db` (doc 06, Local
/// Queue Persistence).
///
/// It follows the controller's snapshots: a structural change (a new
/// `QueueState.revision`) is written after [structureDelay] without
/// another one, in one transaction; the position every [positionInterval]
/// while playing, and at once on pause, on stop and when the current item
/// changes. Nothing is written while [follow]'s `isRemote` is true.
class QueuePersistence {
  /// Creates the persistence over [_dao], stamping rows with [_clock].
  new({
    required this._dao,
    required this._clock,
    this._createTimer = Timer.new,
  });

  /// How long the queue must stay unchanged before it is written.
  static const Duration structureDelay = Duration(milliseconds: 500);

  /// How often the position is written while playing.
  static const Duration positionInterval = Duration(seconds: 5);

  final QueueDao _dao;
  final Clock _clock;
  final PersistenceTimerFactory _createTimer;

  StreamSubscription<PlaybackSnapshot>? _subscription;
  bool Function() _isRemote = _never;
  PlaybackSnapshot? _latest;
  int? _revision;
  String? _currentId;
  bool _playing = false;
  bool _structurePending = false;
  Timer? _structureTimer;
  Timer? _positionTimer;
  Future<void> _writes = Future<void>.value();
  bool _disposed = false;

  static bool _never() => false;

  /// Reads the stored queue: null when none is stored. A stored queue that
  /// does not decode, whose current entry is missing or whose shuffle order
  /// is not a permutation is deleted and null is returned.
  Future<RestoredQueue?> load() async {
    final stored = await _dao.read();
    if (stored == null || stored.items.isEmpty) return null;
    try {
      return _decode(stored);
    } on Object catch (error, stackTrace) {
      _log.warning(
        'The stored queue is invalid and was discarded',
        const {},
        error,
        stackTrace,
      );
      await _dao.clear();
      return null;
    }
  }

  /// Follows [snapshots] from now on, the first one being the state already
  /// stored; [isRemote] tells whether a remote driver owns the queue.
  void follow(
    Stream<PlaybackSnapshot> snapshots, {
    required bool Function() isRemote,
  }) {
    _isRemote = isRemote;
    _subscription = snapshots.listen(_onSnapshot);
  }

  /// Writes what is pending at once when the app goes to the background.
  void handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.detached:
        unawaited(flush());
      case AppLifecycleState.resumed ||
          AppLifecycleState.inactive ||
          AppLifecycleState.hidden:
        break;
    }
  }

  /// Writes the latest queue and position now, skipping the debounce.
  Future<void> flush() {
    if (_latest == null || _isRemote()) return _writes;
    return _writeNow(structure: _structurePending);
  }

  /// Flushes, then stops following. Safe to call more than once.
  Future<void> dispose() async {
    if (_disposed) return;
    await flush();
    _disposed = true;
    _structureTimer?.cancel();
    _positionTimer?.cancel();
    await _subscription?.cancel();
    await _writes;
  }

  void _onSnapshot(PlaybackSnapshot snapshot) {
    if (_disposed) return;
    final first = _latest == null;
    _latest = snapshot;
    final currentId = snapshot.current?.queueItemId;
    final revisionChanged = snapshot.queue.revision != _revision;
    final currentChanged = currentId != _currentId;
    final paused = _playing && !snapshot.playing;
    _revision = snapshot.queue.revision;
    _currentId = currentId;
    _playing = snapshot.playing;
    _followPosition(snapshot.playing);
    if (first || _isRemote()) return;

    if (revisionChanged && snapshot.queue.items.isEmpty) {
      _cancelStructure();
      unawaited(_enqueue(_dao.clear));
      return;
    }
    if (revisionChanged) {
      _structurePending = true;
      _structureTimer?.cancel();
      _structureTimer = _createTimer(structureDelay, () {
        _structureTimer = null;
        unawaited(_writeNow(structure: true));
      });
    }
    if (currentChanged) {
      // The engine may still report the previous item's position.
      unawaited(
        _writeNow(structure: _structurePending, position: Duration.zero),
      );
    } else if (paused) {
      unawaited(_writeNow(structure: _structurePending));
    }
  }

  /// Runs the position timer while [playing].
  void _followPosition(bool playing) {
    if (!playing) {
      _positionTimer?.cancel();
      _positionTimer = null;
      return;
    }
    if (_positionTimer != null) return;
    _positionTimer = _createTimer(positionInterval, () {
      _positionTimer = null;
      if (_disposed) return;
      if (!_isRemote()) unawaited(_writeNow(structure: false));
      _followPosition(_playing);
    });
  }

  void _cancelStructure() {
    _structurePending = false;
    _structureTimer?.cancel();
    _structureTimer = null;
  }

  /// Writes the meta row of the latest snapshot, with [position] instead of
  /// its position when given, and every item row too when [structure].
  Future<void> _writeNow({required bool structure, Duration? position}) {
    final snapshot = _latest;
    if (snapshot == null || _isRemote()) return _writes;
    if (structure) _cancelStructure();
    final queue = snapshot.queue;
    if (queue.items.isEmpty) return _enqueue(_dao.clear);
    final meta = _meta(snapshot, position ?? snapshot.position);
    if (!structure) return _enqueue(() => _dao.writeMeta(meta));
    final rows = [
      for (final (index, item) in queue.items.indexed)
        QueueSnapshotData(
          position: index,
          queueItemId: item.queueItemId,
          kind: switch (item) {
            TrackQueueItem() => 'track',
            EpisodeQueueItem() => 'episode',
          },
          itemJson: jsonEncode(item.toJson()),
        ),
    ];
    return _enqueue(() => _dao.replace(rows, meta));
  }

  Future<void> _enqueue(Future<void> Function() write) {
    return _writes = _writes
        .then((_) => write())
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) => _log.warning(
            'Writing the queue failed',
            const {},
            error,
            stackTrace,
          ),
        );
  }

  QueueMetaData _meta(PlaybackSnapshot snapshot, Duration position) {
    final queue = snapshot.queue;
    final shuffle = queue.shuffleOrder;
    final context = queue.context;
    return QueueMetaData(
      id: 1,
      currentQueueItemId: snapshot.current?.queueItemId,
      positionMs: position.inMilliseconds,
      shuffleOrderJson: shuffle == null ? null : jsonEncode(shuffle),
      repeatMode: queue.repeat.name,
      contextJson: context == null ? null : jsonEncode(context.toJson()),
      revision: queue.revision,
      updatedAt: _clock.now(),
    );
  }

  static RestoredQueue _decode(StoredQueue stored) {
    final items = <QueueItem>[];
    for (final (index, row) in stored.items.indexed) {
      final item = QueueItem.fromJson(
        jsonDecode(row.itemJson) as Map<String, Object?>,
      );
      if (row.position != index || item.queueItemId != row.queueItemId) {
        throw FormatException('Row $index does not match its item');
      }
      items.add(item);
    }
    final meta = stored.meta;
    final shuffleJson = meta.shuffleOrderJson;
    final shuffle = shuffleJson == null
        ? null
        : [for (final i in jsonDecode(shuffleJson) as List<Object?>) i! as int];
    if (shuffle != null &&
        (shuffle.length != items.length ||
            shuffle.toSet().length != items.length ||
            shuffle.any((i) => i < 0 || i >= items.length))) {
      throw const FormatException('The shuffle order is not a permutation');
    }
    final canonical = items.indexWhere(
      (item) => item.queueItemId == meta.currentQueueItemId,
    );
    if (canonical < 0) {
      throw const FormatException('The current entry is not in the queue');
    }
    final contextJson = meta.contextJson;
    final queue = QueueState(
      items: items,
      shuffleOrder: shuffle,
      cursor: shuffle == null ? canonical : shuffle.indexOf(canonical),
      repeat: RepeatMode.values.byName(meta.repeatMode),
      context: contextJson == null
          ? null
          : QueueContext.fromJson(
              jsonDecode(contextJson) as Map<String, Object?>,
            ),
    );
    return (queue: queue, position: Duration(milliseconds: meta.positionMs));
  }
}
