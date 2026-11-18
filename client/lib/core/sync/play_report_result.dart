// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The server's answer to a reported play (`POST /plays`, P8).
enum PlayReportResult {
  /// The play was recorded, or an identical earlier report already was.
  recorded,

  /// The play was too short to count (`{ recorded: false }`).
  notRecorded,
}
