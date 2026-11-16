// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/sync/data/sync_outbox_handlers.dart';
import 'package:soundspan/core/sync/outbox/outbox_op.dart';
import 'package:soundspan/shared/data/downloads/download_outbox.dart';
import 'package:soundspan/shared/data/playlist/playlist_outbox_handlers.dart';

/// Why the worker dropped an op without delivering it (doc 07, Worker).
enum OutboxDropReason {
  /// The target no longer exists on the server.
  notFound,

  /// The server refused the write because the entity changed elsewhere; the
  /// handler refetches it.
  conflict,

  /// The server rejected the request as malformed: a client bug.
  invalid,
}

/// Sends one kind of [OutboxOp] and applies its result to local data.
///
/// The worker calls [send]; on success it calls [onSuccess] with what [send]
/// returned, then deletes the op. When the op is dropped it calls
/// [onDropped]. Errors from [send] are `ApiException`s; anything [onSuccess]
/// or [onDropped] throws is logged and does not stop the pass.
abstract interface class OutboxHandler<T extends OutboxOp> {
  /// Delivers [op] to the server and answers the response, or null.
  Future<Object?> send(T op);

  /// Applies [response], the server's answer to [op], to the cache.
  Future<void> onSuccess(T op, Object? response);

  /// Undoes local effects of [op], which the server will never receive.
  Future<void> onDropped(T op, OutboxDropReason reason);
}

/// An [OutboxHandler] whose [onSuccess] and [onDropped] do nothing: it only
/// calls [_send].
final class SendOnlyOutboxHandler<T extends OutboxOp>
    implements OutboxHandler<T> {
  /// Creates a handler that delivers ops with [_send].
  const new(this._send);

  final Future<Object?> Function(T op) _send;

  @override
  Future<Object?> send(T op) => _send(op);

  @override
  Future<void> onSuccess(T op, Object? response) async {}

  @override
  Future<void> onDropped(T op, OutboxDropReason reason) async {}
}

/// One handler and the `opType` it delivers.
typedef OutboxHandlerEntry = ({String opType, OutboxHandler<OutboxOp> handler});

/// Builds an [OutboxHandlerEntry] for ops of type [T] stored as [opType].
OutboxHandlerEntry outboxHandlerEntry<T extends OutboxOp>(
  String opType,
  OutboxHandler<T> handler,
) => (opType: opType, handler: _Typed<T>(handler));

/// Adapts a handler of [T] to every [OutboxOp], so the registry can hold
/// handlers of different op types.
final class _Typed<T extends OutboxOp> implements OutboxHandler<OutboxOp> {
  const new(this._inner);

  final OutboxHandler<T> _inner;

  @override
  Future<Object?> send(OutboxOp op) => _inner.send(op as T);

  @override
  Future<void> onSuccess(OutboxOp op, Object? response) =>
      _inner.onSuccess(op as T, response);

  @override
  Future<void> onDropped(OutboxOp op, OutboxDropReason reason) =>
      _inner.onDropped(op as T, reason);
}

/// The handler of each `opType`. A later entry for the same `opType`
/// replaces an earlier one.
final class OutboxHandlerRegistry {
  /// Creates the registry from [entries].
  new(Iterable<OutboxHandlerEntry> entries)
    : _handlers = {for (final e in entries) e.opType: e.handler};

  final Map<String, OutboxHandler<OutboxOp>> _handlers;

  /// The handler of [opType], or null when none is registered.
  OutboxHandler<OutboxOp>? operator [](String opType) => _handlers[opType];
}

/// The profile's [OutboxHandlerRegistry]: the handlers each repository
/// contributes through its provider.
final Provider<OutboxHandlerRegistry> outboxHandlerRegistryProvider =
    Provider<OutboxHandlerRegistry>(
      (ref) => OutboxHandlerRegistry([
        ...ref.watch(syncOutboxHandlersProvider),
        ...ref.watch(playlistOutboxHandlersProvider),
        ...ref.watch(downloadOutboxHandlersProvider),
      ]),
      dependencies: [
        syncOutboxHandlersProvider,
        playlistOutboxHandlersProvider,
        downloadOutboxHandlersProvider,
      ],
    );
