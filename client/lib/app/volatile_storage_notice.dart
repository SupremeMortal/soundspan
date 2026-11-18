// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/core/storage/providers.dart';

/// Shows a snackbar once per page load when the `DatabaseOpener` reports
/// volatile storage (web private browsing): nothing will be remembered
/// (doc 05, Web Storage).
class VolatileStorageNotice extends ConsumerStatefulWidget {
  /// Creates the notice around [child], below the app's
  /// [ScaffoldMessenger].
  const new({required this.child, super.key});

  /// The app's content.
  final Widget child;

  @override
  ConsumerState<VolatileStorageNotice> createState() =>
      _VolatileStorageNoticeState();
}

class _VolatileStorageNoticeState extends ConsumerState<VolatileStorageNotice> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(databaseOpenerProvider).isVolatile) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).storageVolatileNotice),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
