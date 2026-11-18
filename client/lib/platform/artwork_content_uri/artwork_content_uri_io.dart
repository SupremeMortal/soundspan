// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:soundspan/core/logging/app_logger.dart';
import 'package:soundspan/platform/artwork_content_uri/artwork_content_uri.dart';

/// Grants the car hosts read access to a content URI.
typedef ArtworkUriGrant = void Function(Uri uri);

const MethodChannel _channel = MethodChannel('io.soundspan.app/artwork');

final AppLogger _log = AppLogger.scope('AndroidAuto');

/// The [ArtworkContentUri] of profile [profileId] whose covers are pinned in
/// [artDirectory]: on Android, content URIs of the app's provider, each
/// granted to the car hosts by `MainActivity`; elsewhere none.
ArtworkContentUri createArtworkContentUri({
  required String profileId,
  required String artDirectory,
}) => Platform.isAndroid
    ? FileArtworkContentUri(
        authority: artworkAuthority,
        profileId: profileId,
        artDirectory: artDirectory,
        grant: _grant,
      )
    : const NoArtworkContentUri();

/// Asks `MainActivity` to grant read access to [uri]; best effort, so a
/// process started by Android Auto before any activity serves the URI
/// without the grant.
void _grant(Uri uri) {
  unawaited(
    _channel.invokeMethod<void>('grant', uri.toString()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _log.fine('Artwork URI not granted', {'error': '$error'});
    }),
  );
}

/// Answers the content URI of a cover pinned in [_artDirectory], granted
/// through [_grant]; null while the file does not exist.
final class FileArtworkContentUri implements ArtworkContentUri {
  /// Creates it for profile [_profileId] under provider [_authority].
  new({
    required this._authority,
    required this._profileId,
    required this._artDirectory,
    required this._grant,
  });

  final String _authority;
  final String _profileId;
  final String _artDirectory;
  final ArtworkUriGrant _grant;

  @override
  Uri? forArtRef(String ref) {
    final file = File(p.join(_artDirectory, artworkFileNameOf(ref)));
    if (!file.existsSync()) return null;
    final uri = artworkContentUri(
      authority: _authority,
      profileId: _profileId,
      ref: ref,
    );
    _grant(uri);
    return uri;
  }
}
