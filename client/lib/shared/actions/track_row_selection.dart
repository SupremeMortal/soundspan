// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/shell/shortcuts/shortcut_intents.dart';
import 'package:soundspan/shared/actions/app_menu_commands.dart';
import 'package:soundspan/shared/actions/track_actions.dart';
import 'package:soundspan/shared/dnd/drag_payload.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/widgets/track_row.dart';
import 'package:soundspan/shared/widgets/track_selection.dart';

/// What a [TrackRow] of a selectable list takes from its
/// [SelectionController] (doc 09, Desktop Interaction: Selection).
class TrackRowSelection {
  /// Creates the wiring of one row.
  const new({
    required this.selected,
    required this.onSelect,
    required this.focusNode,
    required this.rowActions,
    required this.onMenu,
    required this.dragPayload,
  });

  /// [TrackRow.dragPayload]: the playable tracks of the selection when the
  /// row is part of it, of the row alone otherwise; null when the row
  /// itself is not playable.
  final DragPayload? dragPayload;

  /// [TrackRow.selected].
  final bool selected;

  /// [TrackRow.onSelect].
  final ValueChanged<SelectGesture> onSelect;

  /// [TrackRow.focusNode].
  final FocusNode focusNode;

  /// [TrackRow.rowActions]: Enter plays, Shift+Enter plays next and Delete
  /// removes from an owned playlist, each over the selection when the row
  /// is part of it.
  final Map<Type, Action<Intent>> rowActions;

  /// [TrackRow.onMenu]: the menu of the selection when the row is part of
  /// it ([trackSelectionActions]), of the row alone otherwise.
  final void Function(Offset? position) onMenu;
}

/// Builds the row at [index] of a list whose selection is [selection],
/// rebuilt when the selection changes. [scopeOf] answers the menu scope of
/// an item; [play] plays the row alone, as its tap does.
Widget selectableTrackRow<T>(
  WidgetRef ref, {
  required SelectionController<T> selection,
  required int index,
  required TrackActionScope Function(T item) scopeOf,
  required VoidCallback play,
  required Widget Function(TrackRowSelection wiring) builder,
}) => ListenableBuilder(
  listenable: selection,
  builder: (context, _) {
    final item = selection.items[index];
    List<TrackActionScope> targets() => [
      for (final target in selection.targetsFor(index)) scopeOf(target),
    ];
    MenuCommands commands() => AppMenuCommands(context, ref);
    final ownScope = scopeOf(item);
    final selected = selection.isSelected(item);
    return builder(
      TrackRowSelection(
        dragPayload: !ownScope.playable
            ? null
            : TracksPayload(selected ? _playable(targets()) : [ownScope.track]),
        selected: selected,
        onSelect: (gesture) => selection.select(index, gesture),
        focusNode: selection.focusNodeFor(item),
        onMenu: (position) => unawaited(
          openTrackSelectionMenu(context, ref, targets(), position: position),
        ),
        rowActions: {
          PlayRowIntent: _RowAction<PlayRowIntent>(() {
            final scopes = targets();
            if (scopes.length == 1) return play();
            final tracks = _playable(scopes);
            if (tracks.isEmpty) return;
            unawaited(commands().playTracks(tracks, 0, scopes.first.context));
          }),
          PlayRowNextIntent: _RowAction<PlayRowNextIntent>(
            enabled: () => _playable(targets()).isNotEmpty,
            () => unawaited(commands().playNext(_playable(targets()))),
          ),
          RemoveRowIntent: _RowAction<RemoveRowIntent>(
            enabled: () => targets().every((s) => s.ownedPlaylist != null),
            () {
              final rows = [for (final s in targets()) s.ownedPlaylist!];
              selection.clear();
              unawaited(removeRows(commands(), rows));
            },
          ),
        },
      ),
    );
  },
);

List<Track> _playable(List<TrackActionScope> scopes) => [
  for (final scope in scopes)
    if (scope.playable) scope.track,
];

class _RowAction<T extends Intent> extends Action<T> {
  new(this._invoke, {this._enabled});

  final void Function() _invoke;
  final bool Function()? _enabled;

  @override
  bool isEnabled(T intent) => _enabled?.call() ?? true;

  @override
  Object? invoke(T intent) {
    _invoke();
    return null;
  }
}
