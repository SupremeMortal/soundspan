// SPDX-License-Identifier: GPL-3.0-or-later WITH LicenseRef-soundspan-store-exception

import 'package:soundspan/platform/audio_session/audio_session_gateway.dart';

/// The web [AudioSessionGateway]: the browser has no audio focus.
AudioSessionGateway createAudioSessionGateway() =>
    const NoopAudioSessionGateway();
