// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The artwork content URI seam (doc 10, Android Auto; doc 07, Android Auto
/// and Offline).
///
/// Android Auto loads browse artwork from another process, so a pinned
/// cover under `profiles/<id>/art/` is handed to it as a `content://` URI
/// of the app's `FileProvider` (authority `<applicationId>.artwork`,
/// `res/xml/artwork_paths.xml`). `createArtworkContentUri` returns, on
/// Android, one that answers such URIs for pinned files and grants the
/// car hosts read access; elsewhere, one that answers none.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

export 'artwork_content_uri_web.dart'
    if (dart.library.io) 'artwork_content_uri_io.dart'
    show createArtworkContentUri;

/// The `FileProvider` authority of the release application id.
const String artworkAuthority = 'io.soundspan.app.artwork';

/// The `name` of the provider's one path, which is `profiles/` of the app
/// support directory.
const String _pathName = 'art';

final RegExp _pinnedName = RegExp(r'^[0-9a-f]{40}\.img$');

/// Answers the content URI of a pinned cover.
abstract interface class ArtworkContentUri {
  /// The content URI of the pinned file of cover [ref], readable by the
  /// car hosts; null when the file is not pinned or there is no provider.
  Uri? forArtRef(String ref);
}

/// An [ArtworkContentUri] that answers none: platforms without the
/// provider, and profiles without files.
final class NoArtworkContentUri implements ArtworkContentUri {
  /// Creates it.
  const new();

  @override
  Uri? forArtRef(String ref) => null;
}

/// The content URI of the pinned cover [ref] of profile [profileId] under
/// [authority]: `content://<authority>/art/<profileId>/art/<sha1(ref)>.img`.
///
/// The provider's path `art` is the `profiles/` directory, so the rest of
/// the URI path is the file's path below it.
Uri artworkContentUri({
  required String authority,
  required String profileId,
  required String ref,
}) => Uri(
  scheme: 'content',
  host: authority,
  pathSegments: [_pathName, profileId, 'art', artworkFileNameOf(ref)],
);

/// The file [uri] names, relative to the app support directory
/// (`profiles/<id>/art/<sha1>.img`); null for a URI that is not a content
/// URI of a pinned cover, such as one whose path leaves a profile's `art/`.
String? artFileFor(Uri uri) {
  if (uri.scheme != 'content') return null;
  final segments = uri.pathSegments;
  if (segments.length != 4 ||
      segments[0] != _pathName ||
      segments[2] != 'art' ||
      !_pinnedName.hasMatch(segments[3])) {
    return null;
  }
  final profileId = segments[1];
  if (profileId.isEmpty ||
      profileId == '.' ||
      profileId == '..' ||
      profileId.contains(r'\')) {
    return null;
  }
  return 'profiles/$profileId/art/${segments[3]}';
}

/// The file name of the pinned cover [ref]: the lower-case hex SHA-1 of the
/// ref with `.img`, as `DownloadArtwork` writes it.
String artworkFileNameOf(String ref) => '${sha1.convert(utf8.encode(ref))}.img';
