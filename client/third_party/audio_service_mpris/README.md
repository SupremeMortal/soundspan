# audio_service_mpris (vendored)

[`audio_service_mpris`](https://pub.dev/packages/audio_service_mpris) 0.2.1
(MIT, see `LICENSE`), the MPRIS platform of `audio_service` on Linux, copied
from pub.dev with one patch, marked `soundspan patch` in the source:

- `lib/mpris.dart`: `org.mpris.MediaPlayer2.Player.Volume` reports the
  volume the player shows (`OrgMprisMediaPlayer2.volume`, clamped to
  0.0–1.0) and emits `PropertiesChanged` when it changes, instead of a
  constant 1.0. A client setting it sends the clamped value on
  `volumeStream`, which the plugin forwards as the `dbusVolume` custom
  action; the value shown changes only when the player shows it.
- `lib/audio_service_mpris.dart`: `AudioServiceMpris.showVolume` shows the
  player's volume once the service is configured.

Desktop media widgets (the Plasma Media Player applet, GNOME extensions)
read and set the volume through this property. The client shows its user
volume there and applies the volume they set
(`lib/core/playback/media_controls/`).

The copy is excluded from the client's analyzer; its tests live in the
client (`test/core/playback/media_controls/mpris_volume_test.dart`).
