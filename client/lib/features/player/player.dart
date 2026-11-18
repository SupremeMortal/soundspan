// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// The player: the player bar on expanded windows, the mini player on
/// compact and medium ones, the seek bar they share, now playing and the
/// queue and the lyrics (doc 09, Components; Now Playing, Queue, Lyrics).
library;

export 'domain/lrc.dart' show LyricLine, currentLineIndex, parseLrc;
export 'domain/lyrics.dart'
    show Lyrics, LyricsRepository, NoLyrics, PlainLyrics, SyncedLyrics;
export 'lyrics_providers.dart'
    show currentLyricsProvider, lyricsRepositoryProvider;
export 'ui/lyrics_view.dart'
    show LyricsPanel, LyricsSheet, LyricsView, showLyricsSheet;
export 'ui/mini_player.dart' show MiniPlayer;
export 'ui/now_playing_announcer.dart' show NowPlayingAnnouncer;
export 'ui/now_playing_overlay.dart' show NowPlayingOverlay, QueuePanel;
export 'ui/now_playing_screen.dart' show NowPlayingScreen, NowPlayingTitle;
export 'ui/player_bar.dart'
    show
        PlayPauseButton,
        PlayerBar,
        PlayerTransport,
        TransportButton,
        nextRepeatMode;
export 'ui/queue_sheet.dart' show QueueSheet, showQueueSheet;
export 'ui/queue_view.dart' show QueueView;
export 'ui/right_panel.dart'
    show
        NowPlayingOverlayNotifier,
        RightPanel,
        RightPanelNotifier,
        nowPlayingOverlayProvider,
        rightPanelProvider;
export 'ui/seek_bar.dart' show SeekBar;
export 'ui/volume_slider.dart' show VolumeSlider;
