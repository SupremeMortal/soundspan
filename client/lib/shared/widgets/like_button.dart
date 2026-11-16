// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/theme/extensions.dart';

/// The heart of a track (doc 09, Components): an outlined heart in
/// `contentSecondary`, filled in `brand` when [liked].
///
/// Its tooltip and accessibility label are "Like", or "Remove like" when
/// [liked], and screen readers hear it as a toggle in that state. A null
/// [onToggle] disables it.
class LikeButton extends StatelessWidget {
  /// Creates the heart of a track that is [liked] or not.
  const new({required this.liked, required this.onToggle, super.key});

  /// Whether the track is liked.
  final bool liked;

  /// Called on a tap; null disables the button.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final label = liked ? l10n.likeButtonRemove : l10n.likeButtonLike;
    return MergeSemantics(
      child: Semantics(
        toggled: liked,
        label: label,
        child: IconButton(
          onPressed: onToggle,
          tooltip: label,
          icon: Icon(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: onToggle == null
                ? null
                : liked
                ? colors.brand
                : colors.contentSecondary,
          ),
        ),
      ),
    );
  }
}
