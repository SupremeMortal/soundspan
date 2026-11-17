// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

/// Listen Together: what the player and the shell show of the group this
/// device is in (doc 08, Listen Together; doc 09, Queue). The screen
/// itself, `ui/listen_together_screen.dart`, is imported by the router
/// alone, deferred on the web.
library;

export 'ui/listen_together_player.dart'
    show
        ListenTogetherNoticeListener,
        ListenTogetherQueueHeader,
        groupCommandErrorMessage;
export 'ui/listen_together_view_model.dart'
    show
        attachedListenTogetherProvider,
        inListenTogetherGroupProvider,
        isGroupCommandPending,
        isPlayPauseCommand;
