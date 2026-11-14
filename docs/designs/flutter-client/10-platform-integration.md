# 10. Platform Integration

Status: design phase.

What each target needs beyond shared Dart code. Identifier everywhere: `io.soundspan.app`. Display name: `soundspan`. URL scheme: `soundspan`.

## Android

**Gradle:** `minSdk 26`, `compileSdk 37` (required by `flutter_local_notifications` and `androidx.core`), `targetSdk` at the Flutter default for the pinned SDK, core library desugaring (`desugar_jdk_libs` 2.1.4, required by `flutter_local_notifications`), Java 17, R8 on in release, `abiFilters` arm64-v8a, armeabi-v7a, x86_64. Universal APK and AAB.

**`AndroidManifest.xml`:**

| Entry | Why |
|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Network |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Playback service |
| `FOREGROUND_SERVICE_DATA_SYNC` | Large download batches |
| `POST_NOTIFICATIONS` | Requested at first playback or download; playback works without it |
| `WAKE_LOCK` | `audio_service` |
| `CAMERA` | QR scanner; requested when the scanner opens; `<uses-feature android:required="false">` |
| `MainActivity` extends `AudioServiceActivity`, `launchMode="singleTask"` | `audio_service` |
| `<service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true">` with the `MediaBrowserService` intent filter | Playback, Bluetooth, Android Auto |
| `<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver">` | Headset buttons |
| Intent filter `VIEW` / `BROWSABLE` / scheme `soundspan` | Deep links |
| `android:networkSecurityConfig="@xml/network_security_config"` | Cleartext policy |
| `android:dataExtractionRules`, `android:fullBackupContent` | Exclude `profiles/*/media`, databases, and secure storage from backup |
| `<meta-data android:name="com.google.android.gms.car.application" android:resource="@xml/automotive_app_desc">` | Android Auto (M2) |

**Cleartext HTTP.** Android's network security config cannot be changed at run time and cannot express "private IP ranges only". The config therefore permits cleartext globally, and the rule "http only for LAN hosts, or after an explicit warning" is enforced in Dart by `ServerAddress` and `BaseUrlGuard` ([04](04-auth-and-server-profiles.md)). ExoPlayer follows the same config, so LAN `http://` servers can stream. User-installed certificate authorities are trusted (`<certificates src="user"/>`), which is how self-hosters with a private CA make their server trusted, in line with the design's "CA the user has installed system-wide".

**Playback service.** `audio_service` config: `androidNotificationChannelId: 'io.soundspan.app.playback'`, `androidNotificationOngoing: true`, `androidStopForegroundOnPause: true`, notification icon `drawable/ic_stat_soundspan` (monochrome). Compact actions: previous, play/pause, next; a custom Like action in the expanded view.

**Android Auto (M2).** `SoundspanAudioHandler.getChildren` serves the browse tree:

```
root
├── Recent        recently listened (cache)
├── Playlists     playlists → tracks
├── Albums        albums (first 200, alphabetical) → tracks
└── Downloads     download collections → tracks        (works offline)
```

`playFromMediaId` resolves ids of the form `<kind>/<id>[/<index>]` (client-defined, not `playbackId`s). `search` maps to `GET /search` for voice queries. Artwork is served through a `FileProvider` `content://` URI. Android Auto lists media apps only when installed from Play or with "Unknown sources" enabled in Auto's developer settings; the manual matrix uses the Desktop Head Unit.

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

**Audio session:** category `.playback`, mode `.default` (music) or `.spokenAudio` (episodes), set through `audio_session`. Remote command centre and Now Playing info through `audio_service`. Route picker: `AVRoutePickerView` wrapped in a platform view on the now-playing screen.

**Downloads:** background `URLSession` identifier `io.soundspan.app.downloads`; `application(_:handleEventsForBackgroundURLSession:completionHandler:)` forwarded by the plugin.

**Files:** `profiles/*/media` gets `isExcludedFromBackup`. Secure storage accessibility `first_unlock_this_device`.

**App Store notes:** privacy manifest (`PrivacyInfo.xcprivacy`) declaring no tracking and the required-reason APIs used by plugins (file timestamps, user defaults, disk space). App Privacy answers: no data collected (the app sends no crash reports or analytics). The review build needs a reachable demo server and account, which R-01 provides.

## macOS

**Deployment target 12.0** (the minimum of the pinned Flutter SDK). **Universal binary. Hardened runtime.**

Entitlements (release):

| Entitlement | Why |
|---|---|
| `com.apple.security.app-sandbox` | Required for the App Store; kept on for direct distribution too |
| `com.apple.security.network.client` | Outgoing connections |
| `com.apple.security.network.server` | The player's loopback proxy listens on localhost |
| `com.apple.security.device.camera` | QR scanner |
| `keychain-access-groups` | Secure storage |

`Info.plist`: URL scheme, `NSCameraUsageDescription`, `NSLocalNetworkUsageDescription`, `NSAppTransportSecurity` as on iOS, `LSMinimumSystemVersion`, `LSApplicationCategoryType = public.app-category.music`.

Window: closing the window hides it and playback continues (standard macOS behaviour); Cmd+Q quits. Media keys and the Now Playing menu-bar item come from `audio_service`. Menu bar: a `PlatformMenuBar` with Playback (Play/Pause, Next, Previous, Shuffle, Repeat), View (Queue, Lyrics), and Window menus mirroring the shortcut table in [09](09-ui-and-design-system.md).

Distribution: `.app` in a `.dmg`, Developer ID signed and notarised (`notarytool`), stapled. Homebrew cask after the first signed release.

## Windows

**Minimum Windows 10 1809. x64; arm64 when the pinned Flutter supports it as a release target.**

| Item | Detail |
|---|---|
| Audio | `media_kit` with `media_kit_libs_windows_audio` (bundles libmpv DLLs) |
| Media controls | SMTC through `SmtcControls`. Requires an app user model id (`SetCurrentProcessExplicitAppUserModelID("io.soundspan.app")` in `main.cpp`) so the flyout shows the app name and icon |
| Secrets | Credential Manager via `flutter_secure_storage` |
| URL scheme | MSIX: `<uap:Protocol Name="soundspan">` in the manifest. Inno Setup installer: registry keys under `HKCU\Software\Classes\soundspan` |
| Single instance | A named mutex in `main.cpp`; a second launch forwards its command line (deep link) to the first instance through `WM_COPYDATA` and exits |
| Tray | `tray_manager`; close-to-tray default on |
| Thumbnail toolbar | Out of scope for v1 |
| Runtime | The MSVC runtime DLLs are shipped app-local in the installer |

Packaging: MSIX (for winget and optional Store) and an Inno Setup `.exe` (per-user install, no admin). Unsigned builds trigger SmartScreen; release notes say so. Code signing is deferred.

## Linux

**Baseline GTK 3.24, glibc of Ubuntu 22.04. x64; arm64 built when a runner is available.**

| Item | Detail |
|---|---|
| Audio | `media_kit` → libmpv. See packaging below |
| Media controls | MPRIS via `audio_service_mpris`, bus name `org.mpris.MediaPlayer2.soundspan`; desktop media keys and shell widgets use it |
| Secrets | libsecret (Secret Service: GNOME Keyring, KWallet). When no provider answers, the app refuses to store credentials and the connect screen explains what to install; there is no unencrypted fallback |
| URL scheme | `.desktop` file `MimeType=x-scheme-handler/soundspan;` and `Exec=soundspan %u` |
| Single instance | `GApplication` with `G_APPLICATION_HANDLES_OPEN`; a second launch delivers its URI to the first |
| Tray | `tray_manager` (StatusNotifierItem/AppIndicator). GNOME without the AppIndicator extension has no tray; "close to tray" is then disabled and closing the window asks whether to keep playing |
| Wayland and X11 | Both through GTK; no X11-only calls |
| QR scan | Not offered; manual code entry |
| Application id | `io.soundspan.app` (desktop file name, icon name, `GApplication` id, Wayland app id) |

**libmpv per package format:**

| Format | libmpv |
|---|---|
| Flatpak | Built as a module in the manifest (mpv with its ffmpeg dependency from the runtime's codecs extension), or the `org.freedesktop.Platform.ffmpeg-full` extension plus an mpv module. Finish-args: `--share=network`, `--socket=wayland`, `--socket=fallback-x11`, `--socket=pulseaudio`, `--device=dri`, `--talk-name=org.freedesktop.secrets`, `--own-name=org.mpris.MediaPlayer2.soundspan`, `--talk-name=org.kde.StatusNotifierWatcher` |
| AppImage | `libmpv.so.2` and its non-base dependencies copied into the AppDir by `linuxdeploy`; checked with `ldd` in CI on a clean container |
| `.deb` | `Depends: libmpv2 | libmpv1, libgtk-3-0, libsecret-1-0` |

Flathub builds must work offline from declared sources. The manifest takes the prebuilt Flutter bundle from the tagged GitHub release (the common pattern for Flutter apps on Flathub) plus source modules for mpv.

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
| Headers | The static host must send `Cache-Control: no-cache` for `index.html`, `flutter_bootstrap.js`, and long-lived caching for hashed assets. No COOP/COEP |
| CSP (recommended in the container's nginx config) | `default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; connect-src *; img-src * blob: data:; media-src *; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:` — `connect-src *` because the server address is chosen at run time |
| Container | `nginx:alpine`-based image serving the bundle, running as an arbitrary UID in group 0 like the other images |
| OIDC | Web offers password sign-in only. The server's OIDC callback always hands its one-time exchange code to the web UI's `/login` page (`OIDC_WEB_BASE_URL` + `/login?ssoCode=…`), which redeems it at once, and `/api/auth/oidc/exchange` also requires the `httpOnly` flow-binding cookie. A Flutter build on the same origin never receives the code, so it cannot obtain its own tokens through existing endpoints |

## Deep Links Summary

| Target | Registration | Delivery |
|---|---|---|
| Android | Manifest intent filter | `app_links` |
| iOS, macOS | `CFBundleURLTypes` | `app_links` |
| Windows | MSIX protocol / registry | Command line → single-instance forwarding → `app_links` |
| Linux | `.desktop` MimeType | `GApplication` open → `app_links` |
| Web | — | Query parameters on load: `?link=<code>&server=<url>` |

All routes go through one `DeepLinkRouter` that validates the URI (scheme, known host segment, parameter shapes) before touching navigation. Unknown links are ignored and logged.

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
