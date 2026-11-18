// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundspan/core/profile/profile_context.dart';
import 'package:soundspan/shared/domain/domain.dart';

/// Holds the sort and filter choice of one library list. The choice lives
/// as long as the profile container and is not persisted.
class LibraryQueryNotifier<Q> extends Notifier<Q> {
  /// Starts at [_initial].
  new(this._initial);

  final Q _initial;

  @override
  Q build() => _initial;

  /// The current choice.
  Q get query => state;

  set query(Q next) => state = next;
}

/// The query of the Albums tab; the server's defaults until the user
/// chooses.
final NotifierProvider<LibraryQueryNotifier<AlbumQuery>, AlbumQuery>
albumQueryProvider =
    NotifierProvider<LibraryQueryNotifier<AlbumQuery>, AlbumQuery>(
      () => LibraryQueryNotifier(const AlbumQuery()),
      dependencies: [profileContextProvider],
    );

/// The query of the Artists tab; the server's defaults until the user
/// chooses.
final NotifierProvider<LibraryQueryNotifier<ArtistQuery>, ArtistQuery>
artistQueryProvider =
    NotifierProvider<LibraryQueryNotifier<ArtistQuery>, ArtistQuery>(
      () => LibraryQueryNotifier(const ArtistQuery()),
      dependencies: [profileContextProvider],
    );

/// The query of the Songs tab; the server's defaults until the user
/// chooses.
final NotifierProvider<LibraryQueryNotifier<TrackQuery>, TrackQuery>
trackQueryProvider =
    NotifierProvider<LibraryQueryNotifier<TrackQuery>, TrackQuery>(
      () => LibraryQueryNotifier(const TrackQuery()),
      dependencies: [profileContextProvider],
    );
