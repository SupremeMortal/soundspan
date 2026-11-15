// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:soundspan/app/l10n/generated/app_localizations.dart';
import 'package:soundspan/app/router/routes.dart';
import 'package:soundspan/features/discover/domain/discovery_artist.dart';
import 'package:soundspan/shared/widgets/artwork.dart';
import 'package:soundspan/shared/widgets/media_card.dart';

/// The round [MediaCard] of a recommended or popular [artist].
///
/// An artist with a library id opens its artist page; one without opens
/// Search for its name, which shows library and catalogue results. The card
/// has no play button.
class DiscoveryArtistCard extends StatelessWidget {
  /// Creates the card of [artist].
  const new(this.artist, {super.key});

  /// The artist.
  final DiscoveryArtist artist;

  @override
  Widget build(BuildContext context) => MediaCard(
    title: artist.name,
    subtitle: AppLocalizations.of(context).discoverCardArtist,
    artworkRef: artist.artworkRef,
    shape: ArtworkShape.circle,
    onTap: () => _open(context),
  );

  void _open(BuildContext context) {
    if (artist.libraryArtistId case final id?) {
      DetailNavigation.openArtist(context, id);
      return;
    }
    GoRouter.of(context).go(
      Uri(
        path: RoutePaths.search,
        queryParameters: {'q': artist.name},
      ).toString(),
    );
  }
}
