// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The dialogs of playlist editing (doc 09, Album, Artist, Playlist): name,
/// delete and the add-to-playlist picker, and the "New playlist" flow the
/// Library and the sidebar share.
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/app/theme/dimens.dart';
import 'package:soundspan/app/theme/extensions.dart';
import 'package:soundspan/app/theme/typography.dart';
import 'package:soundspan/shared/domain/domain.dart';
import 'package:soundspan/shared/providers/playlist_list.dart';
import 'package:soundspan/shared/providers/repositories.dart';

/// Whether the platform is a touch platform (Android, iOS), where pickers
/// open as bottom sheets rather than dialogs and rows are dragged by a
/// handle.
bool isTouchPlatform(BuildContext context) => switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS => true,
  _ => false,
};

/// The dialog that names a playlist: [title], a name field holding
/// [initialName], Cancel and [confirmLabel]. The confirm action is disabled
/// while the trimmed name is empty. Pops the trimmed name, or null.
class PlaylistNameDialog extends StatefulWidget {
  /// Creates the dialog.
  const new({
    required this.title,
    required this.confirmLabel,
    this.initialName = '',
    super.key,
  });

  /// The dialog title.
  final String title;

  /// The label of the confirm action.
  final String confirmLabel;

  /// The name the field starts with.
  final String initialName;

  /// The key of the name field.
  static const Key fieldKey = Key('playlist.nameField');

  /// The key of the confirm action.
  static const Key confirmKey = Key('playlist.nameConfirm');

  /// Shows the dialog for creating a playlist; answers the name or null.
  static Future<String?> showCreate(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => PlaylistNameDialog(
        title: l10n.playlistNew,
        confirmLabel: l10n.playlistCreate,
      ),
    );
  }

  /// Shows the dialog for renaming the playlist [name]; answers the new
  /// name or null.
  static Future<String?> showRename(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) => PlaylistNameDialog(
        title: l10n.playlistRenameTitle,
        confirmLabel: l10n.playlistRename,
        initialName: name,
      ),
    );
  }

  @override
  State<PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<PlaylistNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: PlaylistNameDialog.fieldKey,
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(labelText: l10n.playlistNameLabel),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.playlistCancel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            key: PlaylistNameDialog.confirmKey,
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(widget.confirmLabel),
          ),
        ),
      ],
    );
  }
}

/// The dialog confirming that the playlist [name] is deleted; the confirm
/// action is drawn in `danger`. Pops true when confirmed.
class DeletePlaylistDialog extends StatelessWidget {
  /// Creates the dialog.
  const new({required this.name, super.key});

  /// The playlist name.
  final String name;

  /// The key of the confirm action.
  static const Key confirmKey = Key('playlist.deleteConfirm');

  /// Shows the dialog; answers whether the user confirmed.
  static Future<bool> show(BuildContext context, String name) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => DeletePlaylistDialog(name: name),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return AlertDialog(
      title: Text(l10n.playlistDeleteTitle(name)),
      content: Text(l10n.playlistDeleteBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.playlistCancel),
        ),
        FilledButton(
          key: confirmKey,
          style: FilledButton.styleFrom(
            backgroundColor: colors.danger,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.playlistDelete),
        ),
      ],
    );
  }
}

/// The picker of the playlist to add songs to: "New playlist", then the
/// user's own playlists. A bottom sheet on touch platforms and a dialog
/// otherwise. Choosing "New playlist" names and creates one first. Pops
/// the chosen playlist's id, or null.
class AddToPlaylistPicker extends ConsumerWidget {
  /// Creates the picker's content.
  const new({super.key});

  /// The key of the "New playlist" row.
  static const Key newKey = Key('playlist.picker.new');

  /// Shows the picker; answers the chosen playlist's id and name, or null.
  static Future<PlaylistSummary?> show(BuildContext context) {
    if (isTouchPlatform(context)) {
      return showModalBottomSheet<PlaylistSummary>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => const AddToPlaylistPicker(),
      );
    }
    return showDialog<PlaylistSummary>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
          child: const AddToPlaylistPicker(),
        ),
      ),
    );
  }

  Future<void> _createNew(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final name = await PlaylistNameDialog.showCreate(context);
    if (name == null) return;
    final repository = await ref.read(playlistRepositoryProvider.future);
    final id = await repository.create(name);
    navigator.pop(
      PlaylistSummary(
        id: id,
        name: name,
        trackCount: 0,
        isOwner: true,
        isPublic: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final typography = context.typography;
    final snapshot = ref.watch(playlistListProvider).value;
    final own = [
      if (snapshot != null)
        for (var i = 0; i < (snapshot.total ?? snapshot.loadedCount); i++)
          if (snapshot.itemAt(i) case final playlist? when playlist.isOwner)
            playlist,
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.x24,
              Spacing.x16,
              Spacing.x24,
              Spacing.x8,
            ),
            child: Text(
              l10n.playlistAddToTitle,
              style: typography.title.copyWith(color: colors.content),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: Spacing.x16),
              children: [
                ListTile(
                  key: newKey,
                  leading: const Icon(Icons.add_rounded),
                  title: Text(l10n.playlistNew),
                  onTap: () => unawaited(_createNew(context, ref)),
                ),
                for (final playlist in own)
                  ListTile(
                    title: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l10n.libraryPlaylistTrackCount(playlist.trackCount),
                    ),
                    onTap: () => Navigator.of(context).pop(playlist),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Asks for a name, creates the playlist and opens it: the "New playlist"
/// action of the Library's Playlists tab and the sidebar.
Future<void> createPlaylistAndOpen(BuildContext context, WidgetRef ref) async {
  final name = await PlaylistNameDialog.showCreate(context);
  if (name == null || !context.mounted) return;
  final repository = await ref.read(playlistRepositoryProvider.future);
  final id = await repository.create(name);
  if (!context.mounted) return;
  DetailNavigation.openPlaylist(context, id);
}

/// Asks for a playlist with [AddToPlaylistPicker], adds [tracks] to it and
/// confirms with "Added N to `name`". Answers how many were added, or null
/// when no playlist was chosen.
Future<int?> addTracksToPlaylist(
  BuildContext context,
  WidgetRef ref,
  List<Track> tracks,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  final playlist = await AddToPlaylistPicker.show(context);
  if (playlist == null) return null;
  final repository = await ref.read(playlistRepositoryProvider.future);
  final added = await repository.addTracks(playlist.id, tracks);
  messenger?.showSnackBar(
    SnackBar(content: Text(l10n.playlistAdded(added, playlist.name))),
  );
  return added;
}
