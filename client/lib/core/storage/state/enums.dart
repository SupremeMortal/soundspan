// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// What a queue entry or a downloaded file plays (doc 05).
enum MediaType {
  /// A music track, identified by its `playbackId`.
  track,

  /// A podcast episode, identified by its podcast and episode ids.
  episode,
}

/// Where a `download_items` row is in the item state machine (doc 07).
///
/// "Confirmed" is the `serverConfirmed` flag on a [completed] row, and
/// "deleted" is the absence of a row.
enum DownloadStatus {
  /// Waiting for a scheduler slot or a constraint (see `waitingFor`).
  queued,

  /// The transfer is in progress.
  running,

  /// The transfer finished and the file is being checked.
  verifying,

  /// The file is on disk and verified.
  completed,

  /// Stopped by the user, by the Wi-Fi-only setting or by a full disk.
  paused,

  /// Failed in a way that is retried with backoff.
  failedRetryable,

  /// Failed in a way that is not retried.
  failedPermanent,

  /// The server cannot provide the file.
  unavailable,

  /// The file was completed but is no longer on disk.
  missing,

  /// The server revoked the item; the file and the row are being removed.
  revoked,
}
