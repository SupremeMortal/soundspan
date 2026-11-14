# 09. UI and Design System

Status: design phase.

The client is Material 3 underneath with a soundspan theme on top. It should read as the same product as the web UI: near-black surfaces, one blue accent, Montserrat, square album art, round artist art, a white play button in the transport.

The web UI it is derived from: dark theme only. Brand blue `#3b82f6`, play accent `#60a5fa`, body font Montserrat, wordmark font Turret Road ExtraBold. The logo exists only as raster files.

## Colour Tokens

Tokens are a `ThemeExtension<SoundspanColors>`. Widgets read `context.colors.surfaceRaised`, never a literal. `tool/check_imports.dart` rejects `Color(0x…)` and `Colors.` outside `lib/app/theme/`.

The dark values are the web UI's (`frontend/app/globals.css`, `@theme` block). The web UI has no light theme, so the light values are defined here.

| Token | Dark | Light | Use |
|---|---|---|---|
| `ground` | `#000000` | `#F5F5F5` | Window background behind panels |
| `surface` | `#0A0A0A` | `#FFFFFF` | Content area, sheets |
| `surfaceRaised` | `#0F0F0F` | `#FAFAFA` | Sidebar, navigation bar, player bar |
| `surfaceOverlay` | `#141414` | `#FFFFFF` | Menus, dialogs (with elevation shadow in light) |
| `surfaceHover` | `#1A1A1A` | `#F0F0F0` | Hovered rows and cards; search field fill |
| `surfaceActive` | `#1C1C1C` | `#E8E8E8` | Pressed, selected row |
| `surfaceHighlight` | `#282828` | `#E5E5E5` | Artwork placeholder, skeletons |
| `line` | `#262626` | `#E5E5E5` | Dividers, card outlines |
| `lineStrong` | `#333333` | `#D4D4D4` | Input outlines, focus-adjacent borders |
| `content` | `#FFFFFF` | `#0A0A0A` | Titles |
| `contentBody` | `#E5E5E5` | `#262626` | Body text |
| `contentSecondary` | `#A3A3A3` | `#525252` | Subtitles, metadata |
| `contentMuted` | `#8A8A8A` | `#666666` | Captions, timestamps |
| `contentDisabled` | `#676767` | `#858585` | Disabled text and icons |
| `brand` | `#3B82F6` | `#2563EB` | Focus ring, links, selected indicators, progress |
| `accent` | `#60A5FA` | `#2563EB` | Primary action fill (Play, Sign in) |
| `onAccent` | `#000000` | `#FFFFFF` | Text and icons on `accent` |
| `transport` | `#FFFFFF` | `#0A0A0A` | Play/pause circle in the player |
| `onTransport` | `#000000` | `#FFFFFF` | Icon on the play/pause circle |
| `positive` | `#22C55E` | `#15803D` | Downloaded, connected, shuffle/repeat on |
| `warning` | `#F59E0B` | `#B45309` | Expiring link, degraded sync |
| `danger` | `#EF4444` | `#B91C1C` | Errors, destructive actions |
| `scrim` | `#000000` 60 % | `#000000` 40 % | Behind sheets and dialogs |

Contrast: every text token meets 4.5:1 on every surface token it is used on, in both themes. The web's muted grey `#737373` does not reach 4.5:1 on `#0A0A0A`, so `contentMuted` is lightened to `#8A8A8A` in dark. A test computes the WCAG ratio for each allowed text-on-surface pair and fails below 4.5 (3.0 for `contentDisabled`, which marks non-interactive text). The web's disabled grey `#525252` (and a light `#A3A3A3`) stays under 3.0:1 on the surfaces, so `contentDisabled` is `#676767` in dark and `#858585` in light: the closest greys that reach 3.0:1 on every surface it is allowed on.

The allowed pairs are defined once as data (`requiredContrastPairs` in `lib/app/theme/contrast.dart`) and checked for all four variants (dark, light and both high-contrast):

| Foreground | Backgrounds | Minimum |
|---|---|---|
| `content`, `contentBody`, `contentSecondary` | `ground`, `surface`, `surfaceRaised`, `surfaceOverlay`, `surfaceHover`, `surfaceActive`, `surfaceHighlight` | 4.5 |
| `contentMuted` | the same except `surfaceHighlight` | 4.5 |
| `contentDisabled` | the same except `surfaceHighlight` | 3.0 |
| `brand`, `positive`, `warning`, `danger` (as text) | `ground`, `surface`, `surfaceRaised`, `surfaceOverlay` | 4.5 |
| `onAccent` | `accent` | 4.5 |
| `onTransport` | `transport` | 4.5 |

Material mapping (`ColorScheme`): `primary = accent`, `onPrimary = onAccent`, `secondary = brand`, `surface = surface`, `onSurface = contentBody`, `surfaceContainer = surfaceRaised`, `surfaceContainerHigh = surfaceOverlay`, `outline = lineStrong`, `outlineVariant = line`, `error = danger`. Roles the mapping above does not name: `onSecondary = onAccent`, `onError` black in dark and white in light, `scrim = scrim`, `surfaceContainerLow = surface`, `surfaceContainerLowest = ground`, `surfaceContainerHighest = surfaceHover`. Stock Material widgets therefore pick up soundspan colours without per-widget styling.

**Theme mode:** `system` (default), `dark`, `light`, in `Settings → Appearance`. The palette is fixed; Android dynamic colour is not used. When the OS requests high contrast, `line` and `lineStrong` step one shade stronger and `contentSecondary` becomes `contentBody`: `line` takes the normal `lineStrong` value (`#333333` dark, `#D4D4D4` light), `lineStrong` becomes `#404040` (dark) or `#A3A3A3` (light), and `contentSecondary` is `#E5E5E5` (dark) or `#262626` (light). Every other token is unchanged. `SoundspanTheme` exposes the four variants for `MaterialApp.theme`, `darkTheme`, `highContrastTheme` and `highContrastDarkTheme`.

**Dynamic backdrops:** album, artist, and playlist headers and the now-playing screen tint their background from the artwork, as the web UI does. The tint is computed off the UI thread from a 64-pixel copy of the cover (`ColorScheme.fromImageProvider`), cached per artwork ref in `cache.db`, and always composited under a scrim that keeps title contrast at 4.5:1. In light theme the tint is mixed 12 % into `surface`; in dark 35 % into `ground`, fading to `surface`.

## Typography

Montserrat variable font (SIL Open Font License), bundled as an asset; no runtime font download. Tabular figures are enabled for times and counts.

| Style | Size / line height | Weight | Use |
|---|---|---|---|
| `display` | 36 / 40 | 700 | Detail-page titles on expanded |
| `headline` | 28 / 34 | 700 | Page titles; detail titles on compact (24 / 30) |
| `title` | 20 / 26 | 700 | Section headers; now-playing track title |
| `subtitle` | 16 / 22 | 600 | Dialog titles, list group headers |
| `body` | 14 / 20 | 500 | Row titles, body text |
| `bodySmall` | 13 / 18 | 400 | Row subtitles, descriptions |
| `caption` | 12 / 16 | 500 | Metadata, timestamps, badges |
| `overline` | 11 / 14 | 700, +0.08 em, upper case | "NOW PLAYING", column headers |
| `mono` | 22 / 28 | 700, platform monospace | Device-link code cells |

Styles are a `ThemeExtension<SoundspanTypography>` read as `context.typography.body`, and carry no colour. Because Montserrat is a variable font, each style sets both `fontWeight` and the matching `wght` font variation. `mono` uses the family `monospace` with the fallbacks Menlo, Consolas, Roboto Mono and DejaVu Sans Mono. `TextStyle.tabular` adds tabular figures.

Material `TextTheme` mapping: `displaySmall = display`, `headlineMedium = headline`, `titleLarge = title`, `titleMedium = subtitle`, `bodyLarge = body`, `bodyMedium = body`, `bodySmall = bodySmall`, `labelLarge = body` at weight 600, `labelMedium = caption`, `labelSmall = overline`. The theme's default family is Montserrat, so the roles the mapping does not name use it too.

- Text scaling follows the OS setting up to 2.0×. Row heights are min-heights, grids reflow, and the player bar wraps its metadata to two lines before truncating.
- **Wordmark:** the logo mark plus "soundspan" in Turret Road ExtraBold, lower case, as in the web UI. `Wordmark` is the only widget that uses the Turret Road family.
- Locales whose script Montserrat lacks fall back to the platform font through `fontFamilyFallback`.

## Shape, Spacing, Motion

| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 24, 32, 48 |
| Page gutter | 16 (compact), 24 (medium), 32 (expanded) |
| Radius: artwork, cards, rows | 6 |
| Radius: panels, sheets, dialogs, now-playing artwork | 12 |
| Radius: buttons, chips, search field | Full pill |
| Artist images, avatars | Circle |
| Minimum touch target | 48 × 48 (touch), 32 × 32 (pointer, with 4 px spacing) |
| Row height | 56 (track row with thumbnail), 48 (album track row without) |
| Motion | 150 ms standard, 250 ms for sheets and route changes; `Curves.easeOutCubic`; all animation off when the OS asks for reduced motion |

Elevation is expressed by surface colour in dark and by a soft shadow (0 2 12, 8 % black) in light. No gradients on controls.

## Icons

Material Symbols (Rounded, weight 500), bundled with Flutter's icon font so they tree-shake. The web UI uses Lucide; the two sets are close enough in stroke style that screens look related, and Material Symbols has the media glyphs the player needs. Custom glyphs (logo mark, equaliser bars for "now playing") are SVG assets.

## Components

Shared widgets in `lib/shared/widgets/`. Each has a golden test at three widths and both themes.

| Component | Notes |
|---|---|
| `Artwork` | Square or circle; requests the snapped server size for its layout size × DPR; placeholder is `surfaceHighlight` with a music-note glyph; cross-fades in 150 ms |
| `MediaCard` | Artwork, title (1 line), subtitle (1 line). Hover or focus shows a 40 px `accent` play button at the bottom right of the artwork. Used in carousels and grids |
| `Shelf` | Section header (`title`) with an optional "Show all", and a horizontal list of `MediaCard`s. Arrow buttons on pointer devices; snap scrolling on touch |
| `TrackRow` | Index or thumbnail, title + artist, optional album column, download state glyph, duration, like, overflow. The playing row shows animated equaliser bars in `brand` and a `brand`-coloured title. Disabled (not playable or not available offline) rows render at 40 % opacity with a reason in the tooltip and semantics label |
| `ActionBar` | Detail-page actions: Play (pill, `accent`), Shuffle, Download, Like, Add to playlist, overflow |
| `PlayerBar` | Expanded layout. Left: artwork 56, title, artist, quality badge. Centre: shuffle, previous, play/pause (48 px `transport` circle), next, repeat, with the seek bar and times beneath. Right: like, lyrics, queue, volume, expand |
| `MiniPlayer` | Compact and medium. 2 px progress line on top; artwork 44, title, artist, like, play/pause, next. Tap or swipe up opens now playing |
| `SeekBar` | 4 px track, `brand` fill, thumb on hover/drag/focus. Buffered range in `lineStrong`. Keyboard: arrows ±5 s. Semantics: slider with "m:ss of m:ss" |
| `QualityBadge` | One neutral style: `surfaceActive` fill, `contentSecondary` text, e.g. "FLAC · 24/96 kHz", "AAC · 256 kbps", "Downloaded". Never coloured or labelled by source |
| `DownloadGlyph` | States: none, queued (outlined arrow), running (determinate ring), completed (filled check, `positive`), failed (`danger`), unavailable (struck through) |
| `Banner` | Inline, full width: offline, link expiring, server newer than tested |
| `EmptyState`, `ErrorView` | Icon, one sentence, one action |
| `ContextMenu` | One menu definition per entity rendered as a bottom sheet on touch and a popup at the pointer on desktop |
| `CodeCells` | Six cells for the device-link code |

### Track Actions (one definition, every surface)

Play now, Play next, Add to queue, Add to playlist…, Like / Remove like, Download / Remove download, Go to album, Go to artist, Start radio (M4, when available), Share link (copies `soundspan://…`). Items are hidden, not disabled, when the capability is absent on this platform or server.

## Shell by Window Class

**Compact (< 600).** Content; `MiniPlayer` when a queue exists; `NavigationBar` with Home, Search, Library, Podcasts. The avatar in each tab's app bar opens a sheet: server switcher, Listen Together (M4), Activity (M4), Settings. Now playing is a full-screen route with a drag-down dismiss.

**Medium (600–1023).** `NavigationRail` (same four destinations, avatar at the bottom), content, `MiniPlayer` across the bottom. Library and Podcasts use a two-pane list–detail layout in landscape (list 360 px, detail fills). Now playing is full screen with artwork left and queue/lyrics right in landscape.

**Expanded (≥ 1024).** Top bar (logo, back/forward, search field, activity toggle, avatar menu); sidebar 256 px (Home, Search, Library, Podcasts, then the playlist list with Liked Songs pinned and a create button); content; optional right panel 360 px (Queue or Lyrics); `PlayerBar` 96 px across the bottom. Panels are separated by 8 px of `ground`, with 12 px radius, as in the web shell. The sidebar collapses to a 72 px rail below 1200 px when the right panel is open.

Differences from the web shell, on purpose: Search is a navigation destination on compact (the web has a search field in a top bar and a hamburger drawer); Queue and Lyrics have buttons on the player bar; Audiobooks is absent; Explore, Vibe, and Listen Together appear in M4 as a Home section and sidebar items when the server enables them.

## Screens

Each screen lists its data source (repository method → endpoints in [03](03-api-layer.md)) and states. All lists are lazily built slivers.

### Connect (M0, M2)

Described in [04](04-auth-and-server-profiles.md). Layout: centred column, max width 420, logo and wordmark on top. Address step → probe result → sign-in. On expanded the column sits in a card on `ground`. The device-link panel shows the three steps ("Open soundspan in a browser → Settings → Link Device → Generate Code"), `CodeCells`, and "Scan QR code" where a camera exists.

### Home (M0; M4 additions)

Greeting (`headline`), then shelves in this order, each hidden when empty or disabled: Continue Listening (`/library/recently-listened`), Recently Added (`/library/recently-added`), Made For You (Liked Songs + `/mixes`; `autoPlaylists`), Your Playlists, Popular Podcasts (`/podcasts/discover/top`). M4 adds Recommended For You and Popular Artists (`discovery`) and the Explore entry. Banners (offline, link expiring) sit above the greeting. Pull to refresh on touch; F5 / Ctrl+R on desktop.

### Search (M0)

- Field with a clear button; 300 ms debounce; recent searches (from `state.db`) when empty.
- Filter chips: All, Library, Discover, Podcasts.
- Results: Top result card, then Songs, Artists, Albums, Playlists, Podcasts, each showing up to 5 with "Show all". Library results come from `GET /search`; catalogue results from `GET /search/discover` and the `remoteTracks` / `remoteAlbums` keys. They are merged into the same sections in the order the server returned them. No source badges.
- Offline: local results only, labelled.

### Library (M0; Downloads tab M3)

Tabs: Playlists, Artists, Albums, Songs, Downloads. A sort menu and filter chips (All, Local, Peers, Remote map to the server's `origin` parameter and are shown only when `federation` is on or remote items exist; labels are about where content lives in the user's library, which is not a playback source decision).

- **Artists, Albums:** grid. Columns from available width at a 160 px minimum tile (2 on a phone, up to 8 on a wide desktop). Page size 60.
- **Songs:** `TrackRow` list with a sticky "Shuffle all" header; page size 100; alphabetical fast-scroll thumb on touch.
- **Playlists:** list with mosaic artwork (first four covers), Liked Songs pinned, "New playlist".
- **Downloads:** collections with progress, total size, and a storage summary; filter "In progress".
- Paging: `PagedSource<T>` requests the page containing the first visible index plus one ahead; unloaded rows render as skeletons of fixed height so scroll extent is stable for 10,000-track libraries.

### Album, Artist, Playlist (M0 browse; actions M1)

Header: artwork (140 compact, 192 medium, 232 expanded), overline type label, title, metadata line, `ActionBar`. The header collapses into the app bar on scroll.

- **Album:** tracks grouped by disc, rows without thumbnails (index, title, artist when it differs from the album artist, duration). "More by this artist" shelf.
- **Artist:** round artwork; Popular (top 5, expandable to 10), Albums, Singles and EPs, Similar Artists; biography collapsed to 3 lines.
- **Playlist:** rows with thumbnails and an album column on expanded; owner can rename, reorder (drag handle on touch, drag on desktop), remove, and delete. Items the server marks `playback.isPlayable == false` are disabled with the server's `message`.

### Now Playing, Queue, Lyrics (M1)

- **Compact:** drag handle and "NOW PLAYING" overline; artwork (max 360, radius 12); title, artist (tappable), like; `SeekBar` with elapsed and remaining; transport (shuffle, previous, play/pause 64 px, next, repeat); a row with quality badge, output (Android, iOS system picker), queue, lyrics. Queue and Lyrics open as sheets over the same screen.
- **Expanded:** now playing is the right panel plus the player bar; an "expand" control shows a large-artwork overlay over the content area with lyrics beside it.
- **Queue:** "Now playing", "Next up" (reorderable, swipe or button to remove), "Clear". In a Listen Together group the header shows the group and member count.
- **Lyrics:** synced lyrics scroll with the current line in `content` at `title` size, other lines in `contentSecondary`; tapping a line seeks. Plain lyrics scroll freely. "No lyrics found" otherwise. LRC parsing (`[mm:ss.xx]`) is a pure function with tests.
- Episodes replace shuffle/repeat with skip-back, skip-forward, and speed.

### Podcasts (M1)

Subscribed grid; Top Podcasts shelf; detail with header, Subscribe, and an episode list (title, date, duration, progress bar, download glyph, played check). Episode row tap plays from the saved position.

### Settings (M0 onward)

| Section | Items |
|---|---|
| Servers | Profile list, add, switch, sign out, remove; per-server: version, link expiry, "Open server admin" (shown to admin users) |
| Playback | Quality on Wi-Fi / mobile data; volume levelling mode (server setting `loudnessMode`); skip interval and default speed for podcasts |
| Storage | Download quality, Wi-Fi only, device limit, usage breakdown, clear cache, remove downloads |
| Appearance | Theme mode, language |
| Desktop | Close to tray, start minimised, global media keys |
| About | Version, licences (`LicenseRegistry`, including the bundled fonts), export logs, pending changes count |

The client has no admin or acquisition actions. "Open server admin" opens `<server address>/admin` in the browser and is the only link of its kind; content screens show no delete, download, or request actions. Account security, integrations, and API-key management are reached from that web page.

## Desktop Interaction

| Shortcut (Cmd on macOS for Ctrl) | Action |
|---|---|
| Space | Play / pause (when no text field has focus) |
| Ctrl+Right / Ctrl+Left | Next / previous |
| Shift+Right / Shift+Left | Seek ±10 s |
| Ctrl+Up / Ctrl+Down | Volume ±5 % |
| Ctrl+S / Ctrl+R | Shuffle / cycle repeat |
| Ctrl+L | Like current track |
| Ctrl+K or / | Focus search |
| Ctrl+1 … Ctrl+4 | Home, Search, Library, Podcasts |
| Ctrl+Q (panel) | Toggle queue panel |
| Alt+Left / Alt+Right, mouse back/forward | Navigate back / forward |
| Ctrl+, | Settings |
| Enter on a row | Play; Shift+Enter: play next |
| Delete on a selected playlist row | Remove from playlist |
| F5 / Ctrl+Shift+R | Refresh current screen |

Implemented with `Shortcuts`/`Actions` at the shell so they are discoverable to assistive technology, and listed in `Settings → Desktop`.

- **Selection:** click selects, Ctrl/Shift extend, in track lists on pointer devices. Context menu and drag act on the selection.
- **Drag and drop:** drag tracks or an album onto a sidebar playlist (add) or onto the queue panel (insert at the drop position).
- **Context menus:** right-click, and the Menu key / Shift+F10.
- **Window:** minimum size 480 × 600; bounds and maximised state persisted; title "Track — Artist · soundspan" while playing.
- **Tray** (Windows, Linux, macOS menu bar optional): Play/Pause, Next, Previous, current track (disabled label), Show window, Quit.

## Performance Rules

- `ListView.builder` / `SliverList` with `itemExtent` or `prototypeItem` for every long list.
- `const` constructors by default (lint). Rows take plain values, not providers; only the playing-state indicator watches the playback provider, through a `select` on "is this item current".
- Position updates repaint only the `SeekBar` (its own `RepaintBoundary` and listenable), never the player bar.
- Images decode at display size (`memCacheWidth`). Grids precache one screen ahead on idle.
- Shelves build lazily as they scroll into view.
- Budgets from the design document are checked by `integration_test/perf_scroll_test.dart` (frame timings on a 10,000-row list in profile mode) and by the manual memory run each release.

## Localization

- `flutter gen-l10n`; ARB files in `lib/app/l10n/`; `app_en.arb` is the template. `nullable-getter: false`, `use-escaping: true`.
- Message ids are `<feature><Thing>` (`libraryEmptyTitle`). Plurals and selects use ICU syntax. Durations and dates go through `intl` (`DateFormat.yMMMd(locale)`); track times use a fixed `m:ss` / `h:mm:ss` formatter.
- `tool/check_l10n.dart` fails on a string literal containing a letter passed to `Text(`, `SelectableText(`, `TextSpan(text:`, `tooltip:`, `label:`, `semanticLabel:`, `semanticsLabel:`, `hintText:`, `labelText:`, `helperText:`, `errorText:`, or `message:` under `lib/**/ui/` and `lib/shared/widgets/`. Letterless literals (`'·'`, `'0:00'`) and interpolation-only literals (`'$count'`) pass; there is no ignore comment.
- A pseudo-locale (`en-XA`, accented and 40 % longer, generated by the tool) and Arabic (`ar`, RTL) are run in golden tests for the shell, a track row, the player bar, and the now-playing screen.
- Server-provided text (error `message`s, playlist names) is shown as received.

## Accessibility

- Every icon-only control has a tooltip and a semantics label. `TrackRow` exposes one merged node: "Title, Artist, 3 minutes 41 seconds, downloaded", with custom actions for like, queue, and menu.
- Focus order follows reading order; the shell defines `FocusTraversalGroup`s for sidebar, content, right panel, and player bar; F6 cycles between them on desktop.
- Visible focus ring: 2 px `brand`, 2 px offset, on every focusable in both themes.
- Now-playing changes are announced politely (`SemanticsService.announce`) when the screen reader is on.
- `SeekBar` and volume are sliders with increase/decrease actions.
- Golden tests run at text scale 1.0 and 2.0 for the shell and rows. The widget-test helper runs Flutter's `meetsGuideline` checks (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) on every screen.
- Manual screen-reader passes (TalkBack, VoiceOver on iOS and macOS, Narrator, Orca) are an M5 exit criterion with a written script.
