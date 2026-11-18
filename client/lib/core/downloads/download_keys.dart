// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:path/path.dart' as p;
import 'package:soundspan/platform/paths/paths.dart';

/// The key of one downloaded file: the `itemKey` of `download_items`
/// (doc 05).
@immutable
sealed class DownloadItemKey {
  const new();

  /// Decodes a stored `itemKey`.
  ///
  /// Throws a [FormatException] when [encoded] is not `t:<playbackId>` or
  /// `e:<podcastId>:<episodeId>` with non-empty parts.
  factory decode(String encoded) {
    if (encoded.startsWith('t:') && encoded.length > 2) {
      return TrackItemKey(encoded.substring(2));
    }
    if (encoded.startsWith('e:')) {
      final rest = encoded.substring(2);
      final colon = rest.indexOf(':');
      if (colon > 0 && colon < rest.length - 1) {
        return EpisodeItemKey(
          podcastId: rest.substring(0, colon),
          episodeId: rest.substring(colon + 1),
        );
      }
    }
    throw FormatException('not a download item key', encoded);
  }

  /// The stored form.
  String encode();

  @override
  String toString() => encode();
}

/// A downloaded track, keyed by its opaque `playbackId`, which is carried
/// verbatim and never inspected.
final class TrackItemKey extends DownloadItemKey {
  /// Creates the key of the track [playbackId].
  const new(this.playbackId);

  /// The track's playback id.
  final String playbackId;

  @override
  String encode() => 't:$playbackId';

  @override
  bool operator ==(Object other) =>
      other is TrackItemKey && other.playbackId == playbackId;

  @override
  int get hashCode => playbackId.hashCode;
}

/// A downloaded podcast episode.
final class EpisodeItemKey extends DownloadItemKey {
  /// Creates the key of episode [episodeId] of podcast [podcastId].
  const new({required this.podcastId, required this.episodeId});

  /// The podcast's id.
  final String podcastId;

  /// The episode's id.
  final String episodeId;

  @override
  String encode() => 'e:$podcastId:$episodeId';

  @override
  bool operator ==(Object other) =>
      other is EpisodeItemKey &&
      other.podcastId == podcastId &&
      other.episodeId == episodeId;

  @override
  int get hashCode => Object.hash(podcastId, episodeId);
}

/// The lower-case hex SHA-1 of [key]'s stored form.
///
/// It is both the transfer task id and the file name of the item (doc 05,
/// Files on Disk), so re-enqueueing an item is idempotent.
String itemKeyHash(DownloadItemKey key) =>
    sha1.convert(utf8.encode(key.encode())).toString();

/// The file extension for a response `Content-Type` (doc 05, Files on
/// Disk): `bin` for anything not in the table.
String extensionForContentType(String? contentType) {
  final mime = contentType?.split(';').first.trim().toLowerCase();
  return switch (mime) {
    'audio/mpeg' => 'mp3',
    'audio/flac' => 'flac',
    'audio/mp4' => 'm4a',
    'audio/ogg' => 'ogg',
    'audio/webm' => 'webm',
    _ => 'bin',
  };
}

/// Where a profile's downloaded files live, by item hash:
/// `media/<hash[0:2]>/<hash>.<ext>` under the profile directory.
@immutable
final class DownloadPaths {
  /// Creates the download paths of [profile].
  const new(this.profile);

  /// The profile's directories.
  final ProfilePaths profile;

  /// The transfer-in-progress file, relative to the profile directory.
  String relativePartFile(String hash) => _relative(hash, 'part');

  /// The verified file, relative to the profile directory, with the
  /// extension of [contentType].
  String relativeFinalFile(String hash, String? contentType) =>
      _relative(hash, extensionForContentType(contentType));

  /// The absolute path of [relativePartFile].
  String partFile(String hash) => resolve(relativePartFile(hash));

  /// The absolute path of [relativeFinalFile].
  String finalFile(String hash, String? contentType) =>
      resolve(relativeFinalFile(hash, contentType));

  /// The absolute path of [relativePath], a path relative to the profile
  /// directory.
  String resolve(String relativePath) =>
      p.join(profile.supportRoot, relativePath);

  static String _relative(String hash, String extension) =>
      p.join('media', hash.substring(0, 2), '$hash.$extension');
}
