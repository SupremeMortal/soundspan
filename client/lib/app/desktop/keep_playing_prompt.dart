// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/desktop/desktop_controller.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';

/// Asks "Keep playing in the background?" with Quit and Keep playing;
/// null when dismissed.
Future<KeepPlayingAnswer?> showKeepPlayingDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<KeepPlayingAnswer>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(l10n.closeKeepPlayingTitle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(KeepPlayingAnswer.quit),
          child: Text(l10n.closeQuit),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialog).pop(KeepPlayingAnswer.keepPlaying),
          child: Text(l10n.closeKeepPlaying),
        ),
      ],
    ),
  );
}

/// Lets the [DesktopController] ask whether to keep playing when the
/// window is closed with no tray (doc 10, Linux): the question opens on
/// the router's navigator. Wraps the app's content; nothing happens off
/// desktop platforms.
class KeepPlayingPrompt extends ConsumerStatefulWidget {
  /// Creates the prompt around [child].
  const new({required this.child, super.key});

  /// The app's content.
  final Widget child;

  @override
  ConsumerState<KeepPlayingPrompt> createState() => _KeepPlayingPromptState();
}

class _KeepPlayingPromptState extends ConsumerState<KeepPlayingPrompt> {
  DesktopController? _desktop;

  @override
  void initState() {
    super.initState();
    _desktop = ref.read(desktopControllerProvider)?..askKeepPlaying = _ask;
  }

  @override
  void dispose() {
    if (_desktop?.askKeepPlaying == _ask) _desktop?.askKeepPlaying = null;
    super.dispose();
  }

  Future<KeepPlayingAnswer?> _ask() async {
    final navigator = ref.read(routerProvider).routerDelegate.navigatorKey;
    final context = navigator.currentContext;
    if (context == null || !context.mounted) return null;
    return await showKeepPlayingDialog(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
