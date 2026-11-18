// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/artwork_content_uri/artwork_content_uri.dart';

/// The web's [ArtworkContentUri]: no files, no provider.
ArtworkContentUri createArtworkContentUri({
  required String profileId,
  required String artDirectory,
}) => const NoArtworkContentUri();
