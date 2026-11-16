// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The audio output of the native device engine harness (doc 06).
library;

/// mpv's `ao` for the device harness on [operatingSystem]
/// (`Platform.operatingSystem`), or null for the production configuration.
///
/// - Windows: `'null'`, mpv's timing-accurate null output. A hosted Windows
///   runner has no audio endpoint, and a virtual sound card cannot be
///   installed on it unattended.
/// - Linux: `'pulse'`, the PulseAudio null sink the CI job starts. With the
///   production configuration mpv tries its PipeWire output first; on the
///   runner that output's thread loop hangs in `pw_thread_loop_stop()` even
///   when no PipeWire daemon runs, blocking the app's main isolate.
String? deviceAudioOutput({required String operatingSystem}) =>
    switch (operatingSystem) {
      'windows' => 'null',
      'linux' => 'pulse',
      _ => null,
    };
