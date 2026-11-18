# 10. Platform Integration

Status: design phase.

What each target needs beyond shared Dart code. Identifier everywhere: `io.soundspan.app`. Display name: `soundspan`. URL scheme: `soundspan`.

## Android

**Gradle:** `minSdk 26`, `compileSdk 37` (required by `flutter_local_notifications` and `androidx.core`), `targetSdk` at the Flutter default for the pinned SDK, core library desugaring (`desugar_jdk_libs` 2.1.4, required by `flutter_local_notifications`), Java 17, R8 on in release, `abiFilters` arm64-v8a, armeabi-v7a, x86_64. Universal APK and AAB. `lint { checkReleaseBuilds = false }`: Android Lint's release check (`lintVitalRelease`) crashes inside lint itself on plugin sources with the pinned toolchain, so release builds do not run it.

**`AndroidManifest.xml`:**

| Entry | Why |
|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Network |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Playback service |
| `FOREGROUND_SERVICE_DATA_SYNC`; `<service android:name="androidx.work.impl.foreground.SystemForegroundService" android:foregroundServiceType="dataSync">` | Large download batches run as WorkManager's foreground service (`background_downloader`) |
| `POST_NOTIFICATIONS` | Requested at first playback or download; playback works without it |
| `WAKE_LOCK` | `audio_service` |
| `CAMERA` | QR scanner; requested when the scanner opens; `<uses-feature android:required="false">` |
| `MainActivity` extends `AudioServiceActivity`, `launchMode="singleTask"` | `audio_service` |
| `<service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true">` with the `MediaBrowserService` intent filter | Playback, Bluetooth, Android Auto |
| `<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true">` with the `MEDIA_BUTTON` intent filter | Headset buttons; restarts playback from a media button after the process is killed |
| Intent filter `VIEW` / `BROWSABLE` / scheme `soundspan` | Deep links |
| `android:networkSecurityConfig="@xml/network_security_config"` | Cleartext policy |
| `android:dataExtractionRules`, `android:fullBackupContent` | Exclude `profiles/*/media`, databases, and secure storage from backup |
| `<meta-data android:name="com.google.android.gms.car.application" android:resource="@xml/automotive_app_desc">` | Android Auto (M2) |
| `<provider android:name="androidx.core.content.FileProvider" android:authorities="${applicationId}.artwork" android:exported="false" android:grantUriPermissions="true">` with `@xml/artwork_paths` | Android Auto Downloads artwork |

**Cleartext HTTP.** Android's network security config cannot be changed at run time and cannot express "private IP ranges only". The config therefore permits cleartext globally, and the rule "http only for LAN hosts, or after an explicit warning" is enforced in Dart by `ServerAddress` and `BaseUrlGuard` ([04](04-auth-and-server-profiles.md)). ExoPlayer follows the same config, so LAN `http://` servers can stream. User-installed certificate authorities are trusted (`<certificates src="user"/>`), which is how self-hosters with a private CA make their server trusted, in line with the design's "CA the user has installed system-wide".

**Playback service.** `audio_service` config: `androidNotificationChannelId: 'io.soundspan.app.playback'`, `androidNotificationOngoing: true`, `androidStopForegroundOnPause: true`, notification icon `drawable/ic_stat_soundspan` (monochrome). Compact actions: previous, play/pause, next; a custom Like action in the expanded view. The Like drawables `ic_action_like` and `ic_action_liked` are vector drawables; `res/raw/keep.xml` keeps them and the notification icon from the resource shrinker, since only Dart names them.

**Notification permission.** On Android 13 or later the first playback of a session asks for `POST_NOTIFICATIONS` through `LocalNotifications.requestPermission()` (`NotificationPermissionPrompt`, `lib/core/playback/notification_permission.dart`), once per device: the `device_settings` key `notifications.asked` records that it was asked, and it is never asked again automatically. Playback starts whatever the answer. The API level comes from `MainActivity` over the `io.soundspan.app/device_info` method channel (`androidSdkVersion()` of the device-info seam).

**Backup rules.** `res/xml/data_extraction_rules.xml` (`<cloud-backup>` and `<device-transfer>`) and `res/xml/backup_rules.xml` exclude `profiles/` and `app.db` (with its `-wal`, `-shm` and `-journal` files) in the `file` domain, which is the app-support directory on Android, and the `FlutterSecureStorage.xml` shared preferences. The profile databases and downloads live under `profiles/`; the cache directory is never backed up. `tool/check_platform_config.dart` checks these files with `--android-res`, every row of the manifest table above, `automotive_app_desc.xml`, and that `android:usesCleartextTraffic="false"` is absent; CI runs it on the merged manifest of the built APK (`tool/ci/check_apk_manifest.sh`).

**Android Auto (M2).** `SoundspanAudioHandler.getChildren` serves the browse tree:

```
root
├── Recent        recently listened (cache)
├── Playlists     playlists → tracks
├── Albums        albums (first 200, alphabetical) → tracks
└── Downloads     download collections → tracks        (works offline)
```

The tree is `BrowseTree` (`lib/core/playback/media_controls/browse/`), pure Dart over the `MediaBrowseSource` seam; `MediaBrowseSourceImpl` (`lib/app/media_browse_source_impl.dart`, profile scope) reads it through the cached repositories, so lists loaded before are served offline. Recent lists the top tracks of the Continue Listening artists in order, up to 50, because `GET /library/recently-listened` returns artists and podcasts, not tracks. Albums are the first 200 by name. The root titles are localized and passed in by the handler.

Media ids are client-defined, never `playbackId`s: `root`, `recent`, `playlists`, `albums`, `playlist/<id>`, `album/<id>` are browsable; `recent/tracks/<index>`, `playlist/<id>/<index>`, `album/<id>/<index>` and `search/<query>/<index>` are playable and replace the queue with the whole parent list from `<index>`. `<id>` and `<query>` are percent-encoded; unplayable tracks are left out and `<index>` counts the list without them. An unknown or malformed id lists nothing and plays nothing. `playFromSearch` with an empty query plays Recent from the start; otherwise the library tracks `GET /search` finds, from the first. `search` returns the playable result items. Only Downloads items carry artwork.

**Downloads root (M3).** `downloads` lists, in request order, each download collection with at least one completed item, read from `DownloadStore` alone (no repository, cache or API call), so it works with no network: `downloads/<kind>/<refId>` (`kind` is `album`, `playlist`, `track` or `episode`; `<refId>` percent-encoded) is browsable and lists the completed tracks in membership order as `downloads/<kind>/<refId>/<index>`, built from each item's `metaJson`; a song collection is listed directly as its playable `downloads/track/<refId>/0`, and an episode collection (`<refId>` is `<podcastId>:<episodeId>`) as its playable `downloads/episode/<refId>/0`, built from the item's `EpisodeDownloadMeta`. The subtitle is the kind ("Album", "Playlist", "Song", "Podcast episode") and the completed count. A playable id replaces the queue with the collection's completed tracks (context album, playlist or single) from `<index>`; an episode id replaces it with that episode alone as an episode queue item, the way the podcast screens play one. They resolve to the local files through `SourceResolver`. The tree reads them through `DownloadsBrowse` (`DownloadStore` plus `ArtworkContentUri`), given to the binder on platforms that download.

**Artwork content URIs.** `ArtworkContentUri` (`lib/platform/artwork_content_uri/`) answers `content://<applicationId>.artwork/art/<profileId>/art/<sha1(ref)>.img` for a cover pinned in the profile's `art/`, and null when the file does not exist (the item is sent without artwork) or off Android. `res/xml/artwork_paths.xml` exposes only `profiles/` of the app support directory, under the name `art`, so the URI path after `art/` is the file's path below `profiles/`; `artFileFor` maps a URI back and rejects anything but a `<sha1>.img` file directly in a profile's `art/`. Each URI answered is granted read access (`Context.grantUriPermission`) to the Android Auto host `com.google.android.projection.gearhead` and the Android Automotive media centre `com.android.car.media`, by `ArtworkGrants` over the `io.soundspan.app/artwork` method channel `MainActivity` registers; in a process Android Auto started before any activity the channel is missing and the item is sent without the grant. `res/xml/automotive_app_desc.xml` declares `<uses name="media"/>`. Android Auto lists media apps only when installed from Play or with "Unknown sources" enabled in Auto's developer settings; the manual matrix uses the Desktop Head Unit.

**Downloads notification.** `DownloadNotifier` (`lib/platform/download_notifier/`) applies the plan of `planFor` (`lib/core/downloads/download_notification_policy.dart`) to the profile's group `p:<profileId>`: one group notification titled "Downloading N items" (plural ARB message, no track or source names) whose progress is the finished tasks over all tasks, "Downloads finished" when done, and foreground mode (`Config.runInForeground`) while the batch's estimated remaining bytes exceed 50 MB (an item of unknown size counts 8 MB). The plugin posts it on its own channel, `background_downloader`, which it creates with low importance; `res/values/download_notification.xml` names that channel "Downloads" and aliases the plugin's notification drawables to `ic_stat_soundspan`. The scheduler applies the plan before it grants slots. The first time a download starts on Android 13 or later, `POST_NOTIFICATIONS` is requested through `LocalNotifications.requestPermission()`; the answer is stored in the `device_settings` key `downloads.notificationsAsked` and downloads never ask again. Downloads run whatever the answer. Desktop shows no download notification.

**Battery.** No exemption from battery optimisation is requested; a media-playback foreground service is not subject to background limits while playing.

## iOS

**Deployment target 15.0.** Swift Package Manager for plugins where supported, CocoaPods otherwise.

**`Info.plist`:**

| Key | Value / why |
|---|---|
| `UIBackgroundModes` | `audio`; `fetch` and `processing` are not needed (`URLSession` background transfers do not require them) |
| `CFBundleURLTypes` | Scheme `soundspan` |
| `NSCameraUsageDescription` | "Scan a soundspan link code." |
| `NSLocalNetworkUsageDescription` | "Connect to a soundspan server on your network." Shown by iOS the first time a LAN address is contacted |
| `NSAppTransportSecurity` | `NSAllowsLocalNetworking = true` (LAN `http://` and the player's loopback proxy). For a user-confirmed public `http://` server ATS still blocks the connection; the confirmation dialog on iOS says so and offers no override. |
| `ITSAppUsesNonExemptEncryption` | `false` (only OS-provided TLS) |
| `UIApplicationSupportsIndirectInputEvents`, `UISupportsDocumentBrowser = false` | Defaults |
| `LSApplicationQueriesSchemes` | none |

**Audio session:** category `.playback`, mode `.default` (music) or `.spokenAudio` (episodes), set through `audio_session`. Remote command centre and Now Playing info through `audio_service`. Route picker: `AVRoutePickerView` wrapped in a platform view (`io.soundspan.app/route_picker`, registered in `AppDelegate.swift`, tints from the creation parameters) on the now-playing screen; `lib/platform/route_picker/` returns an empty box on every other platform.

**Downloads:** background `URLSession` identifier `io.soundspan.app.downloads`, the `Info.plist` key `SoundspanDownloadSessionIdentifier`, which `AppDelegate` sets as `background_downloader`'s `UrlSessionDelegate.sessionIdentifier` before the session is created; `application(_:handleEventsForBackgroundURLSession:completionHandler:)` is overridden in `AppDelegate` and passed through `FlutterAppDelegate` to the plugin.

**Files:** `profiles/*/media` gets `isExcludedFromBackup`: before a profile's first download in a process, the downloader calls `excludeFromBackup(path)` on the `io.soundspan.app/backup` method channel, which `AppDelegate` (and on macOS `MainFlutterWindow`) answers by creating the directory and setting the flag. Secure storage accessibility `first_unlock_this_device`.

**App Store notes:** privacy manifest (`PrivacyInfo.xcprivacy`, in the Runner target's resources) declaring no tracking, no tracking domains, no collected data types, and the required-reason APIs used by plugins: file timestamps (`C617.1`), user defaults (`CA92.1`), disk space (`E174.1`, `85F4.1`). App Privacy answers: no data collected (the app sends no crash reports or analytics). The review build needs a reachable demo server and account, which R-01 provides.

## macOS

**Deployment target 12.0** (the minimum of the pinned Flutter SDK). **Universal binary. Hardened runtime.**

Entitlements (release):

| Entitlement | Why |
|---|---|
| `com.apple.security.app-sandbox` | Required for the App Store; kept on for direct distribution too |
| `com.apple.security.network.client` | Outgoing connections |
| `com.apple.security.network.server` | The player's loopback proxy listens on localhost |
| `com.apple.security.device.camera` | QR scanner |
| `keychain-access-groups` | Secure storage (`$(AppIdentifierPrefix)io.soundspan.app`) |

`DebugProfile.entitlements` (debug and profile builds) has the first four and `com.apple.security.cs.allow-jit`, which the Dart VM needs; it leaves out `keychain-access-groups`, which needs a provisioning profile that the ad-hoc signed debug builds of the device tests do not have. Hardened runtime is on for the Release configuration.

`Info.plist`: URL scheme, `NSCameraUsageDescription`, `NSLocalNetworkUsageDescription`, `NSAppTransportSecurity` as on iOS, `LSMinimumSystemVersion`, `LSApplicationCategoryType = public.app-category.music`.

Window: closing the window hides it and playback continues (standard macOS behaviour); a click on the Dock icon shows it again; Cmd+Q quits. There is no tray icon. Media keys and the Now Playing menu-bar item come from `audio_service`. Menu bar: a `PlatformMenuBar` with the application menu (About, Settings… as Cmd+,, Quit as Cmd+Q), Playback (Play/Pause, Next, Previous, Shuffle, Repeat), View (Queue, Lyrics), and Window (Minimise, Zoom) menus mirroring the shortcut table in [09](09-ui-and-design-system.md). Each item invokes the intent of its shortcut and shows its keys, except the keys limited to outside text fields (Space, Cmd+arrows), which a menu key equivalent would take from a text field; items whose action has no target are disabled.

Distribution: `.app` in a `.dmg`, Developer ID signed and notarised (`notarytool`), stapled. Homebrew cask after the first signed release.

Unsigned builds: `macos/packaging/make_dmg.sh <app> <version> <output dir>` checks that the executable is universal, re-signs the app ad hoc, inside out (dylibs and frameworks, then helper bundles and the app), with the hardened runtime, and packs it with an `/Applications` symlink into a compressed, read-only image (`hdiutil create -volname soundspan -format UDZO`): `soundspan-<version>-macos-universal-unsigned.dmg`. The app and helpers are signed with `macos/Runner/AdHoc.entitlements`: the release entitlements without `keychain-access-groups`. That entitlement is restricted and needs a provisioning profile; an ad-hoc signature has no team identifier, and macOS kills (SIGKILL, no output) an ad-hoc signed app that carries it as soon as it starts. Without it, secure storage in the unsigned builds uses the app's default keychain access, so credentials may not persist between launches. A fourth argument to `make_dmg.sh` names other entitlements. macOS opens the image's app only after the user approves it in System Settings → Privacy & Security → Open Anyway.

## Windows

**Minimum Windows 10 1809. x64; arm64 when the pinned Flutter supports it as a release target.**

| Item | Detail |
|---|---|
| Audio | `media_kit` with `media_kit_libs_windows_audio` (bundles libmpv DLLs) |
| Media controls | SMTC through `SmtcControls` and the in-repo C++/WinRT plugin `client/packages/soundspan_smtc`. Requires an app user model id (`SetCurrentProcessExplicitAppUserModelID("io.soundspan.app")` in `main.cpp`) so the flyout shows the app name and icon |
| Secrets | Credential Manager via `flutter_secure_storage` |
| Notifications | Toasts through `flutter_local_notifications` with app name `soundspan`, app user model id `io.soundspan.app` and the fixed toast activator GUID `4bf43cb4-9830-433a-b7be-8872cc40d022` |
| URL scheme | MSIX: `<uap:Protocol Name="soundspan">` in the manifest. Inno Setup installer: registry keys under `HKCU\Software\Classes\soundspan` |
| Single instance | A named mutex in `main.cpp`; a second launch forwards its command line (deep link) to the first instance through `WM_COPYDATA` and exits |
| Tray | `tray_manager`; close-to-tray default on |
| Thumbnail toolbar | Out of scope for v1 |
| Runtime | The MSVC runtime DLLs are shipped app-local in the installer |

Packaging, both unsigned and built by `build-windows` in `client-build.yml` ([11](11-testing-and-ci.md)); code signing is deferred:

- **Inno Setup** (`client/windows/packaging/soundspan.iss`): `soundspan-<version>-windows-x64-unsigned-setup.exe`, a per-user install with no elevation (`PrivilegesRequired=lowest`) into `{localappdata}\Programs\soundspan`, with a fixed `AppId` GUID, `AppVersion` from `/DAppVersion=`, a Start-menu shortcut carrying the app user model id `io.soundspan.app`, an optional desktop shortcut and an uninstaller. It installs the whole `Release` directory with the app-local `msvcp140.dll`, `vcruntime140.dll` and `vcruntime140_1.dll`, and writes `HKCU\Software\Classes\soundspan` (default `URL:soundspan`, an empty `URL Protocol`, `shell\open\command` = `"<install dir>\soundspan.exe" "%1"`), which the uninstaller removes. Unsigned, it triggers SmartScreen; the release notes say so.
- **MSIX** (the `msix` dev dependency and `msix_config` in `client/pubspec.yaml`): `soundspan-<version>-windows-x64-unsigned.msix`, identity `io.soundspan.app`, display and publisher display name `soundspan`, the placeholder publisher `CN=soundspan-unsigned`, the logo from `windows/msix_assets/Square310x310Logo.png`, capabilities `internetClient` and `privateNetworkClientServer`, the `soundspan` protocol, x64, version `<version>.0`. Unsigned, it installs only where unsigned packages are allowed; the release notes point users to the setup program. It is the base for winget and an optional Store listing once it is signed.

## Linux

**Baseline GTK 3.24, glibc of Ubuntu 22.04. x64; arm64 built when a runner is available.**

| Item | Detail |
|---|---|
| Audio | `media_kit` → libmpv. See packaging below |
| Media controls | MPRIS via `audio_service_mpris`, bus name `org.mpris.MediaPlayer2.soundspan.instance<pid>` and identity `soundspan` (the package derives both from the channel id and name of the `audio_service` config, which are `soundspan` on Linux); desktop media keys and shell widgets use it, and its `Volume` is the app's user volume, which a widget's volume slider sets |
| Secrets | libsecret (Secret Service: GNOME Keyring, KWallet). When no provider answers, the app refuses to store credentials and the connect screen explains what to install; there is no unencrypted fallback |
| URL scheme | `.desktop` file `MimeType=x-scheme-handler/soundspan;` and `Exec=soundspan %u` |
| Single instance | `GApplication` with `G_APPLICATION_HANDLES_OPEN`; a second launch delivers its URI to the first |
| Tray | `tray_manager`, which exports a StatusNotifierItem over D-Bus itself (no `libayatana-appindicator` at build or run time). The tray is used only when a StatusNotifier watcher on the session bus reports a registered host (`IsStatusNotifierHostRegistered`). The lookup runs in bootstrap step 5, before the first frame, so it waits at most 2 seconds for the session bus; a bus that fails or does not answer counts as no host. GNOME without the AppIndicator extension has none, so "close to tray" is then disabled and closing the window asks whether to keep playing ("Keep playing" minimises the window, "Quit" quits) |
| Wayland and X11 | Both through GTK; no X11-only calls |
| QR scan | Not offered; manual code entry |
| Application id | `io.soundspan.app` (desktop file name, icon name, `GApplication` id, Wayland app id) |

**libmpv per package format:**

| Format | libmpv |
|---|---|
| Flatpak | Built from source as modules of the manifest on runtime `org.freedesktop.Platform` 26.08: libass 0.17.5 and libplacebo 7.360.1 (both required by mpv), then mpv 0.41.0 as the shared library `libmpv.so.2` alone (no player binary, no scripting, PulseAudio and PipeWire audio outputs, no video outputs). FFmpeg is the runtime's own (FFmpeg 8, whose decoders cover FLAC, MP3, AAC, Opus and Vorbis, the server's stream formats), so no FFmpeg extension is added; `org.freedesktop.Platform.ffmpeg-full` ends with runtime 24.08, and its successor `org.freedesktop.Platform.codecs-extra` installs with the runtime by itself. Finish-args: `--share=network`, `--socket=wayland`, `--socket=fallback-x11`, `--socket=pulseaudio`, `--device=dri`, `--talk-name=org.freedesktop.secrets`, `--own-name=org.mpris.MediaPlayer2.soundspan.*` (the MPRIS name carries an `.instance<pid>` suffix), `--talk-name=org.kde.StatusNotifierWatcher`, `--own-name=org.kde.*` (the tray icon's name is `org.kde.StatusNotifierItem-<pid>-<n>`, fixed by `tray_manager`'s cnativeapi; without it the bus proxy refuses the name and the icon disappears; Flatpak accepts a wildcard only as a whole trailing `.*` element, so `org.kde.StatusNotifierItem-*` is rejected at `build-finish` and `org.kde.*` is the narrowest grant that covers the name), `--env=XCURSOR_PATH=/run/host/user-share/icons:/run/host/share/icons` (the runtime ships no cursor themes and the default Xcursor path misses the host's under `/run/host`, so without it only the fallback arrow loads and the pointer cursor never shows); no filesystem access |
| AppImage | The `libmpv.so.2` or `libmpv.so.1` of the build system and its non-base dependencies copied into the AppDir by `linuxdeploy`, together with the dependencies of libmpv that linuxdeploy's excludelist leaves to the host but a system without audio packages lacks (`libasound.so.2`, `libjack.so.0`, `libusb-1.0.so.0`); the GL, EGL and GLES libraries (`libGL`, `libEGL`, `libGLESv2`, `libgbm`) stay with the host, as for every AppImage, since the Flutter engine opens the host's `libEGL.so.1` and `libGLESv2.so.2` at run time; media_kit opens libmpv by name with `dlopen`, so `AppRun` points it at the bundled file through `LIBMPV_LIBRARY_PATH`. Checked with `ldd` in CI on a clean container |
| `.deb` | `Depends: libmpv2 | libmpv1, libgtk-3-0, libsecret-1-0, libegl1, libgles2` (the Flutter engine opens `libEGL.so.1` and `libGLESv2.so.2` at run time, so `ldd` does not show them); media_kit tries `libmpv.so`, `libmpv.so.2`, then `libmpv.so.1`, so one package serves Ubuntu 22.04 (libmpv1) and 24.04 (libmpv2) |

**Packages** (`client/linux/packaging/`). Each installs the desktop file `io.soundspan.app.desktop`, the hicolor icons (PNG sizes and the scalable SVG) and the AppStream metainfo `io.soundspan.app.metainfo.xml` (id, name, summary, `GPL-3.0-or-later` project licence, `CC0-1.0` metadata licence, the repository as homepage, a `<launchable>` for the desktop file, and a `<releases>` entry the scripts fill with the build version and date), all under the id `io.soundspan.app`, through `common.sh`; the binary is started as `soundspan`.

| Package | Script | Layout |
|---|---|---|
| `soundspan-<version>-linux-amd64.deb` | `deb/build_deb.sh <bundle dir> <version> <out dir>`, `dpkg-deb --build --root-owner-group` | The Flutter bundle under `/usr/lib/soundspan/`, a symlink `/usr/bin/soundspan`, the desktop file under `/usr/share/applications/`, icons under `/usr/share/icons/hicolor/`, metainfo under `/usr/share/metainfo/`, the client licence as `/usr/share/doc/soundspan/copyright`. `control`: `Package: soundspan`, `Architecture: amd64`, `Section: sound`, the soundspan project as maintainer, the `Depends` above |
| `soundspan-<version>-linux-x64.AppImage` | `appimage/build_appimage.sh <bundle dir> <version> <out dir>`, with linuxdeploy `1-alpha-20251107-1`, linuxdeploy-plugin-gtk at commit `3b67a1d` and the AppImage type 2 runtime `20251108`, each downloaded and checked against a pinned SHA-256 | The Flutter bundle under `usr/bin/` (the executable finds `lib/libapp.so` and `data/` beside itself), its shared libraries, libmpv and GTK under `usr/lib/`, a custom `AppRun` behind the GTK plugin's hook |
| `soundspan-<version>-linux-x64.flatpak` | `flatpak/build_flatpak.sh <bundle tarball> <version> <out dir>`: builds a copy of the manifest `flatpak/io.soundspan.app.yml` whose `soundspan` source is the local tarball (its path and computed SHA-256) and whose version is `<version>`, leaving the committed manifest untouched, with `flatpak-builder --user --force-clean --install-deps-from=flathub --repo=<repo>`, then `flatpak build-bundle` with Flathub as the runtime repository | `app-id: io.soundspan.app`, `command: soundspan`, runtime and SDK `org.freedesktop.Platform` / `org.freedesktop.Sdk` 26.08, the finish-args above. Modules `libass`, `libplacebo`, `mpv` (libraries under `/app/lib`), then `soundspan`: the Flutter bundle from the release tarball `soundspan-<version>-linux-x64-unsigned.tar.gz` under `/app/lib/soundspan/`, the symlink `/app/bin/soundspan`, and the desktop file, icons and metainfo through `common.sh`. Headers, pkg-config files and static libraries are removed |

Flathub builds must work offline from declared sources. The manifest takes the prebuilt Flutter bundle from the tagged GitHub release (the common pattern for Flutter apps on Flathub) plus source modules for mpv. Every source is pinned: the archives (libass, the release tarball) by URL and SHA-256, libplacebo and mpv as git sources by tag and commit, because libplacebo's release archives leave out the submodules (jinja, markupsafe, fast_float) its build needs and mpv publishes no release archive of its own. The committed manifest names the release tarball of the version in `client/pubspec.yaml`; its SHA-256 is set from the release's `SHA256SUMS` when the manifest is submitted to Flathub.

## Window Title Bar

On Windows, Linux and macOS the app draws its own title bar ([09](09-ui-and-design-system.md#shell-by-window-class)): the window buttons sit in the top bar instead of under a separate system title bar. The setting "Use system title bar" (`window.useSystemTitleBar`, Settings → Desktop, Windows and Linux, off by default) restores the system's title bar from the next launch; it is also the way out on window managers that handle client-side decorations badly, such as some tiling ones. `WindowStateController.start` calls `DesktopShell.initTitleBar` with the stored choice before the window is shown.

| Platform | Title bar |
|---|---|
| Linux | The runner (`linux/runner/my_application.cc`) reads the choice before the window is realized from the key file `$XDG_CONFIG_HOME/io.soundspan.app/window.ini` (`[TitleBar] UseSystemTitleBar`; the environment variable `SOUNDSPAN_SYSTEM_TITLEBAR=1` or `0` overrides it). With the app's title bar it gives the window an empty, never-shown title bar widget (`gtk_window_set_titlebar`), so GTK draws the frame itself (client-side decorations: shadow, rounded corners and resize margins on every edge) and the window manager draws no title bar. The button layout is GTK's `gtk-decoration-layout` (`WindowButtonLayout.parse`): Plasma keeps it in step with System Settings → Window Decorations → Titlebar Buttons through kde-gtk-config, GNOME with its `button-layout` key, and inside Flatpak GTK reads it through the settings portal. Buttons before the colon go to the leading end, before the wordmark, the others to the trailing end; entries other than `minimize`, `maximize` and `close` are ignored, and an empty value gives minimise, maximise and close at the trailing end. A change applies at once (`notify::gtk-decoration-layout`) |
| Windows | `window_manager`'s hidden title bar style, with the drawn Windows-style buttons at the trailing end. Snap Layouts on hover over maximise are not offered |
| macOS | `window_manager`'s hidden title bar style with the traffic lights kept visible; the content runs under the title bar |

The runner's channel `io.soundspan.app/window` (Linux) carries `getTitleBar` (whether the runner hid the system title bar, and the current layout), `setUseSystemTitleBar` (writes the key file) and, from the runner, `layoutChanged`. Dragging (`startDragging`, which on Wayland becomes `xdg_toplevel.move`), maximise and restore, minimise, the window menu (`showSystemMenu`: `gdk_window_show_window_menu` on Linux, opened while the right button is still down, as Wayland requires) and the maximised, fullscreen and focused state come from `window_manager` on every platform. The drawn close button calls `DesktopShell.close`, which emits a close request exactly as the system's close button does.

## Update Notice

Windows, macOS and Linux builds tell the user when a newer client release exists; Android, iOS and web builds never check, because the store or the host updates them. The check runs only when the platform has `PlatformCapabilities.hasUpdateNotice`, the build names a release repository (`BuildConfig.releaseRepository`, which `client-build.yml` sets to the repository it builds from with `--dart-define=RELEASE_REPOSITORY`), the channel is `stable`, and the app setting `update.check` ("Check for new versions" in Settings → Desktop, on by default) is on; otherwise no request is made. `UpdateChecker` (`lib/core/update/`) runs after the shell's first frame and at most once every 24 hours (`update.lastCheckedAt`): through the `ReleaseFeed` seam (`lib/platform/release_feed/`) it sends `GET https://api.github.com/repos/<repository>/releases?per_page=30` without credentials, with `User-Agent: soundspan-client` and a 10-second timeout, the only request the client makes to a host other than the user's server. Of the releases that are not drafts and are tagged `client-v<semver>`, pre-releases included, the highest is compared with the running version (build number ignored); when it is higher and its page is on `github.com` under `/<repository>/releases/`, an `AppBanner` at the top of the shell content says "soundspan <version> is available" with "View release", which opens the page in the browser, and a dismiss button that hides it until a higher version appears (`update.dismissedVersion`). Settings → About shows the same release whether or not it was dismissed, and "Check now" checks at once. A failed check (offline, timeout, an answer other than 200, malformed JSON) is logged at `fine`, keeps what the last check found and still counts as the day's check. Downloading and installing updates (`auto_updater`, spike S7) waits for signed builds.

## Web

| Item | Detail |
|---|---|
| Renderer | Flutter's default for the pinned SDK (CanvasKit; skwasm when the browser supports it without cross-origin isolation) |
| Base href | Build with `--base-href /app/` for same-origin hosting behind the server's reverse proxy; `/` for a separate origin |
| Database | drift WASM (`sqlite3.wasm`, `drift_worker.js` in `web/`) |
| Auth | JWT only; tokens in memory and `sessionStorage` |
| Streams and images | `?token=` query |
| Service worker | Flutter's default asset caching only. No offline app shell claims, no media caching |
| Media Session | Through `audio_service` |
| Headers | The static host must send `Cache-Control: no-cache` for `index.html`, `flutter_bootstrap.js`, and long-lived caching for hashed assets. No COOP/COEP. The container's rule: a file whose name has a dot-separated segment of 8 or more hexadecimal characters (`x.0123456789abcdef.js`) gets `public, max-age=31536000, immutable`; every other file, `index.html`, `flutter_bootstrap.js`, `flutter_service_worker.js`, `main.dart.js`, `version.json` and `manifest.json` included, gets `no-cache` with an `ETag`, because Flutter's default output is not content-hashed and revalidation is the safe default. Every response also carries the CSP below, `X-Content-Type-Options: nosniff` and `Referrer-Policy: no-referrer` |
| CSP (recommended in the container's nginx config) | `default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; connect-src *; img-src * blob: data:; media-src *; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:` — `connect-src *` because the server address is chosen at run time |
| Container | `client/docker/web/`: `nginx:alpine` pinned by digest, serving a prebuilt `--base-href /app/` bundle from `/usr/share/nginx/html/app/` on port 8080 (it does not build Flutter). `/` is a 302 and `/app` a 301 to `/app/`; `/healthz` answers 200 `ok` and is the `HEALTHCHECK`; under `/app/` a path that matches no file serves `index.html` (path URL strategy); `server_tokens off`; gzip for text, JavaScript, JSON and wasm; `.wasm` is `application/wasm`. `USER 101`, but it runs as any UID in group 0, also with a read-only root filesystem plus a tmpfs on `/tmp`: the pid file and nginx's temp directories are under `/tmp` and logs go to stdout and stderr. The base image's entrypoint is bypassed, so no environment variable is read. `client-build.yml` saves it as `soundspan-<version>-web-image.tar.gz` and smoke-tests it; `client-release.yml` pushes it as `ghcr.io/<owner>/<repository>-client-web:<version>` ([11](11-testing-and-ci.md)) |
| OIDC | Web offers password sign-in only. The server's OIDC callback always hands its one-time exchange code to the web UI's `/login` page (`OIDC_WEB_BASE_URL` + `/login?ssoCode=…`), which redeems it at once, and `/api/auth/oidc/exchange` also requires the `httpOnly` flow-binding cookie. A Flutter build on the same origin never receives the code, so it cannot obtain its own tokens through existing endpoints |

## Deep Links Summary

| Target | Registration | Delivery |
|---|---|---|
| Android | Manifest intent filter | `app_links` |
| iOS, macOS | `CFBundleURLTypes` | `app_links` |
| Windows | MSIX protocol / registry | The launch's command line (Dart entry-point arguments); a later launch's command line through single-instance forwarding (`WM_COPYDATA` → the `io.soundspan.app/single_instance` channel) |
| Linux | `.desktop` MimeType (`linux/packaging/io.soundspan.app.desktop`) | The launch's command line (Dart entry-point arguments); a later launch through `GApplication` open → the `io.soundspan.app/single_instance` channel |
| Web | — | Query parameters on load: `?link=<code>&server=<url>` |

All routes go through one `DeepLinkRouter` (`lib/app/router/deep_link_router.dart`) that validates the URI (scheme, known host segment, parameter shapes) before touching navigation. Unknown links are ignored and logged with their scheme and host only. On Windows and Linux the `DeepLinks` seam reads `soundspan:` arguments itself instead of going through `app_links`: the single-instance runners already forward a later launch's arguments to Dart, so no `app_links` native setup is needed there. Flutter's own deep-link route handling is off (`flutter_deeplinking_enabled` meta-data on `MainActivity`, `FlutterDeepLinkingEnabled` false in the iOS `Info.plist`), so a link reaches navigation only through `DeepLinkRouter`. `tool/check_platform_config.dart` (run in `client-analyze`) fails when the Android intent filter, either `CFBundleURLTypes`, or the `.desktop` scheme handler is missing, and when a camera entry of the QR scanner is missing: the Android `CAMERA` permission and `android.hardware.camera` feature with `required="false"`, `NSCameraUsageDescription` in either `Info.plist`, or `com.apple.security.device.camera` in either macOS `.entitlements` file.

## Icons and Splash

Generated by `tool/gen_icons.dart` from the vector masters redrawn from the raster logo: [`assets/soundspan-mark.svg`](assets/soundspan-mark.svg) for colour icons and [`assets/soundspan-mark-mono.svg`](assets/soundspan-mark-mono.svg) for single-colour ones. Both are copied to `client/assets/brand/` by the scaffold task.

The mark is seven vertical capsules and two end dots on a 512 grid, symmetric about the centre: capsule width 44, centres 57 apart, heights 246, 195, 140, and 92 from the middle outward, dot radius 14; fills `#1e40af`, `#245fc1`, `#2c7dd3`, `#309de6`, and `#3abcf6` from the middle outward; a 4-unit `#00020a` outline as in the raster. The single-colour version has no outline.

Outputs:

- Android adaptive icon (foreground, background `#0A0A0A`, monochrome layer for themed icons).
- iOS and macOS app icon sets; iOS launch screen: `#0A0A0A` with the centred mark.
- Windows `.ico` (16–256), MSIX tiles.
- Linux hicolor PNGs 16–512 and scalable SVG.
- Web favicon and manifest icons.
- Tray icons and the Android notification icon, from the single-colour master: template images (light and dark) at 16, 22, 24, 32.
