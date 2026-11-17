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

**Dynamic backdrops:** album, artist, and playlist headers and the now-playing screen tint their background from the artwork, as the web UI does. The tint is computed off the UI thread from a 64-pixel copy of the cover (its pixels are quantised in a background isolate, and the most populous group weighted by chroma wins; `ColorScheme.fromImageProvider` quantises on the UI isolate, so it is not used), cached per artwork ref in `cache.db` (`blobs`, key `tint:<artworkRef>`), and always composited under a scrim that keeps title contrast at 4.5:1. With no cover or no tint yet the backdrop is plain `surface`; the tint fades in over 250 ms. In light theme the tint is mixed 12 % into `surface`; in dark 35 % into `ground`, fading to `surface`.

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

Material Symbols (Rounded, weight 500), bundled with Flutter's icon font so they tree-shake. The web UI uses Lucide; the two sets are close enough in stroke style that screens look related, and Material Symbols has the media glyphs the player needs. The logo mark is an SVG asset; the "now playing" equaliser bars (`EqualiserBars`) are painted in code so they can move.

## Components

Shared widgets in `lib/shared/widgets/`. Each has a golden test at three widths and both themes.

| Component | Notes |
|---|---|
| `Artwork` | Square or circle; requests the snapped server size for its layout size × DPR; placeholder is `surfaceHighlight` with a music-note glyph; cross-fades in 150 ms |
| `MediaCard` | Artwork, title (1 line), subtitle (1 line). Hover or focus shows a 40 px `accent` play button at the bottom right of the artwork. Used in carousels and grids |
| `Shelf` | Section header (`title`) with an optional "Show all", and a horizontal list of `MediaCard`s. Arrow buttons on pointer devices; snap scrolling on touch |
| `TrackRow` | Index or thumbnail, title + artist, optional album column, download state glyph, like (`LikeButton`: an outlined heart in `contentSecondary`, filled in `brand` when liked, "Like" / "Remove like"; left out for a track without `playbackId`; a disliked track shows not liked), duration, overflow. The playing row shows animated equaliser bars in `brand` and a `brand`-coloured title. Disabled (not playable or not available offline) rows render at 40 % opacity with a reason in the tooltip and semantics label |
| `ActionBar` | Detail-page actions: Play (pill, `accent`), Shuffle, Download, Like (albums), Add to playlist (albums and playlists), overflow (the entity menu). A button whose action cannot work is left out; the bar wraps rather than overflows. Download (`CollectionDownloadButton`, albums and playlists, where the platform downloads) pins the collection with a `CollectionSnapshot` of the loaded detail; once pinned it shows the collection glyph and its action is "Remove download", behind a confirmation |
| `PlayerBar` | Expanded layout. Left: artwork 56, title, artist, quality badge. Centre: shuffle, previous, play/pause (48 px `transport` circle), next, repeat, with the seek bar and times beneath. Right: like, lyrics, queue, volume, expand |
| `MiniPlayer` | Compact and medium. 2 px progress line on top; artwork 44, title, artist, like, play/pause, next. Tap or swipe up opens now playing: a vertical drag upward of more than 24 px, or an upward fling faster than 300 px/s, from anywhere on it (a drag that starts on a button included). Horizontal swipes do nothing (no swipe-to-skip) |
| `SeekBar` | 4 px track, `brand` fill, thumb on hover/drag/focus. Buffered range in `lineStrong`. Keyboard: arrows ±5 s. Semantics: slider with "m:ss of m:ss" |
| `QualityBadge` | One neutral style: `surfaceActive` fill, `contentSecondary` text, e.g. "FLAC · 24/96 kHz", "AAC · 256 kbps", "Downloaded". Never coloured or labelled by source |
| `DownloadGlyph` | A pure widget over `DownloadGlyphState`: none (no space), queued, paused or waiting (outlined arrow, `contentSecondary`, "Waiting to download"), running (determinate ring in `brand`, "Downloading, N percent"; indeterminate when the size is unknown), completed (filled check, `positive`, "Downloaded"), failed (`danger`, "Download failed"), unavailable (struck-through arrow, `contentDisabled`, "Not available for download"). The mapping from item and collection states is `lib/features/downloads/ui/download_glyph_mapper.dart`: a collection is running with its byte ratio while any item is active, failed when nothing is active and an item failed or the server blocked it, completed when every available item is. A track row's glyph watches its own item through a `select` and retries when a failed glyph is tapped; nothing is shown where `PlatformCapabilities.canDownload` is false |
| `AppBanner` | Inline, full width: offline, link expiring, server newer than tested or version unknown. A live region, announced when it appears. Named `AppBanner` because Flutter already has a `Banner` |
| `EmptyState`, `ErrorView` | Icon, one sentence, one action |
| `ContextMenu` | One menu definition per entity rendered as a bottom sheet (radius 12, `surfaceOverlay`) on touch and a popup at the pointer (`surfaceOverlay` with a `line` hairline) with pointer input; destructive entries in `danger`. Input mode follows [02](02-architecture.md#adaptive-layout), never the window width |
| `CodeCells` | Six cells for the device-link code |

### Track Actions (one definition, every surface)

Play now, Play next, Add to queue, Add to playlist…, Like / Remove like, Download / Remove download (Retry download before Remove download when the download failed; hidden without a `playbackId` or where the platform does not download; Remove download confirms), Remove from this playlist (inside a playlist the user owns), Go to album, Go to artist, Start radio (M4, when available), Share link (copies `soundspan://…`; the link scheme has no track route, so a track shares its album's link). Items are hidden, not disabled, when the capability is absent on this platform or server, or when the action cannot work: the queue and playlist entries need a playable track, Like needs a `playbackId`, and Go to album and Go to artist are left out on that album's or artist's own page.

The definitions live in `lib/shared/actions/track_actions.dart` (`trackActions`, `albumActions`, `playlistActions`, `artistActions`) as plain entry lists whose effects go through one `MenuCommands` interface, so every feature reaches them and a test reads them without a widget. Album menu: Play now, Play next, Add to queue, Add to playlist…, Like / Remove like, Go to artist, Share link. Playlist menu: Play now, Play next, Add to queue, Share link, and for the owner Rename and Delete. Artist menu: Share link. Track rows open the track menu from their overflow button, a long press and a secondary click, and expose "Add to queue" and "More options" as custom semantics actions; cards open the album or playlist menu from a long press or a secondary click.

## Shell by Window Class

**Compact (< 600).** Content; `MiniPlayer` when a queue exists; `NavigationBar` with Home, Search, Library, Podcasts. The avatar in each tab's app bar opens a sheet: server switcher, Listen Together (M4), Activity (M4), Settings. Now playing is a full-screen route with a drag-down dismiss: the screen follows a downward drag that starts on its drag handle, header or artwork, or the overscroll of a list in it that is already at its top; released past 25 % of the height or faster than 700 px/s it pops, otherwise it springs back in 250 ms. With reduced motion the screen does not follow the finger and the same thresholds decide. The system back gesture and Escape pop it too.

**Medium (600–1023).** `NavigationRail` (same four destinations, avatar at the bottom, opening the same menu as a popup), content, `MiniPlayer` across the bottom. Library (Playlists, Artists and Albums tabs) and Podcasts use a two-pane list–detail layout in landscape (list 360 px, a 1 px `line` divider, detail fills); Songs and Downloads stay single-pane. The detail is the detail route itself (`/album/:id`, `/artist/:id`, `/playlist/:id` inside the branch, `/podcasts/:id`), drawn in the pane without a transition and laid out for the pane's own window class. With nothing open the pane shows an `EmptyState` ("Select an item"); the open item's row or card uses `surfaceActive`. Selecting another item replaces the open detail; Back closes the detail first, then leaves the tab. In portrait an open detail is a full page over the list, and rotating back restores the panes with the same selection. Now playing is full screen with artwork left and queue/lyrics right in landscape.

**Expanded (≥ 1024).** Top bar (logo, back/forward, search field, activity toggle, avatar menu as a popup); Back pops the current destination's stack and Forward re-opens the location Back last left in that destination, until a new navigation there, pushing it onto the destination's detail stack when a detail is showing so Back walks the same stack again; sidebar 256 px (Home, Search, Library, Podcasts, then the playlist list with Liked Songs pinned and a create button); content; optional right panel 360 px (Queue, Lyrics or Activity, one at a time: choosing one replaces the other); `PlayerBar` 96 px across the bottom (taller at large text scales). The player bar and the mini player take no space while the queue is empty. Panels are separated by 8 px of `ground`, with 12 px radius, as in the web shell. The sidebar collapses to a 72 px rail below 1200 px when the right panel is open.

Differences from the web shell, on purpose: Search is a navigation destination on compact (the web has a search field in a top bar and a hamburger drawer); Queue and Lyrics have buttons on the player bar; Audiobooks is absent; Explore and Listen Together appear in M4 as a Home entry and sidebar items on every server, and Vibe when the server enables it.

## Screens

Each screen lists its data source (repository method → endpoints in [03](03-api-layer.md)) and states. All lists are lazily built slivers.

### Connect (M0, M2)

Described in [04](04-auth-and-server-profiles.md). Layout: centred column, max width 420, logo and wordmark on top. Address step → probe result → sign-in. On expanded the column sits in a card on `ground`. The device-link panel shows the three steps ("Open soundspan in a browser → Settings → Link Device → Generate Code"), `CodeCells`, and "Scan QR code" where a camera exists.

### Home (M0; M4 additions)

Greeting (`headline`), then shelves in this order, each hidden when empty or disabled: Continue Listening (`/library/recently-listened`), Recently Added (`/library/recently-added`), Made For You (Liked Songs + `/mixes`; `autoPlaylists`), Your Playlists, Popular Podcasts (`/podcasts/discover/top`). M4 adds Recommended For You and Popular Artists (`discovery`) and the Explore entry, shown on every server. Explore holds this week's discoveries and the two artist sections (`discovery`, left out without a request when off), then "Radio by genre" and "Radio by decade" (no gate): wrapping grids of station tiles, pills on compact and 160 px cards wider, with the station name and its track count. Genres are ordered by track count with the first 12 before "Show all"; decades are newest first; an empty list hides its section, and with every section empty Explore shows "Nothing to explore yet". A tile asks `GET /library/radio` for a fresh selection of 50 tracks (genre and decade lists are cached for 10 minutes, stations never) and replaces the queue with the playable ones under a `radio` queue context titled with the station name, which the queue header and the now-playing overline show as "Radio · Rock". The tile shows progress meanwhile and further taps are ignored; an empty selection or a failure shows a snackbar, the failure with Retry. While the server is not reachable the tiles are disabled ("Not available offline"). Banners (offline, link expiring) sit above the greeting. Pull to refresh on touch; F5 or Ctrl+Shift+R on desktop (Ctrl+R cycles repeat).

### Search (M0)

- Field with a clear button; 300 ms debounce; recent searches (from `state.db`) when empty.
- Filter chips: All, Library, Discover, Podcasts.
- Results: Top result card, then Songs, Artists, Albums, Playlists, Podcasts, each showing up to 5 with "Show all". Library results come from `GET /search`; catalogue results from `GET /search/discover` and the `remoteTracks` / `remoteAlbums` keys. They are merged into the same sections in the order the server returned them. No source badges.
- Top result: the first artist whose name equals the query without case, else the first song, else the first album, else the first artist; it is not repeated in its section. An item in both searches appears once (tracks by `playbackId`, albums and artists by id). Playlists are the user's own playlists whose name contains the query, because neither search endpoint returns playlists.
- The query lives in the route (`/search?q=`). On expanded windows the top bar's field is the search field: while Search is selected it updates the route with the same 300 ms debounce.
- Recent searches: the last 20 per profile, recorded when the field is submitted or a result is opened.
- Offline: local results only, labelled.

### Library (M0; Downloads tab M3)

Tabs: Playlists, Artists, Albums, Songs, Downloads. A sort menu (exactly the server's `sortBy` values of the list; no choice sends no parameter, the server's default) and filter chips (All, Local, Peers, Remote map to the server's `origin` parameter and are shown only when `federation` is on, since whether remote items exist cannot be known without an extra request; labels are about where content lives in the user's library, which is not a playback source decision) sit above the list and stay in place while it scrolls. Sort and filter last as long as the profile is active and are not persisted; changing either opens a new list and returns to the top. Each tab keeps its scroll position while the Library is open.

- **Artists, Albums:** grid. Columns from available width at a 160 px minimum tile with 16 px spacing, `clamp(floor((width + 16) / (160 + 16)), 2, 8)` (2 on a phone, up to 8 on a wide desktop); the grid spans the content width less the page gutter minus the card padding, so artwork lines up with the gutter as in shelves. Tiles have a fixed height (square artwork and two text lines). Page size 60. Pull-to-refresh on touch and a refresh button with a mouse refetch the visible pages.
- **Songs:** `TrackRow` list with a sticky "Shuffle all" header; page size 100; alphabetical fast-scroll thumb on touch.
- **Fast scroll** (`FastScrollThumb`; Songs, Albums and Artists with more than 200 items, touch input only: with a mouse connected the platform scrollbar is used): a 48 px thumb on the trailing edge, shown while the list scrolls and for 1.5 s after. Dragging it scrolls proportionally through the whole extent. While dragging, a bubble shows the upper-cased first character of the first visible item's title when the order is by name (the server's default for all three lists) and that item is loaded, and "n / total" otherwise. Pages are requested only for the position where the thumb rests for 150 ms or is released. The thumb is excluded from the semantics tree; screen-reader users scroll the list itself.
- **Playlists:** list with mosaic artwork (first four covers), Liked Songs pinned, then "New playlist", which names the playlist in a dialog, creates it and opens it. The expanded sidebar has the same "New playlist" row after Liked Songs.
- **Downloads** (`/library/downloads`, only where `PlatformCapabilities.canDownload`; the location shows Playlists elsewhere): a header with the downloaded item count and size, "N in progress", the "In progress" filter chip (collections with queued, running or paused items) and "Pause all" / "Resume all" (Resume all once every active item is paused by the user); then the collections in request order: cover (the pinned file of `DownloadArtwork` when there is one, so the tab renders offline, otherwise `Artwork`), title, kind and "X of Y" (or "Waiting for connection", the block's title, or "No longer on the server" for an album or playlist deleted on the server), the collection glyph (tap retries a failure), total size, a 2 px progress bar while active, and an overflow menu (Retry download, Pause, Resume, Check for changes on albums and playlists, Remove download). Tapping a row opens the album, the playlist or a single track's album; a blocked row opens its sheet. Empty: "Nothing downloaded yet" with one sentence on how to download.
- **Download sheets** (`lib/features/downloads/ui/download_sheets.dart`), shown after a pin and from a blocked row: the server's limit ("Not enough space on the server", needed, used and limit, the sentence to remove downloads or raise the limit in the server's settings, "Manage downloads" opening the Downloads tab; no browser link), downloads turned off on the server, the device limit ("N more needed on this device", needed and available, "Raise limit", refused with an explanation when free disk space is the bound, and "Download what fits"), and the tracks that cannot be downloaded, greyed out with their reason. No text names a source.
- Paging: `PagedSource<T>` requests the page containing the first visible index plus one ahead; unloaded rows render as skeletons of fixed height so scroll extent is stable for 10,000-track libraries.

### Album, Artist, Playlist (M0 browse; actions M1)

Header: artwork (140 compact, 192 medium, 232 expanded), overline type label, title, metadata line, `ActionBar`. The header collapses into the app bar on scroll.

- **Album:** tracks grouped by disc, rows without thumbnails (index, title, artist when it differs from the album artist, duration). "More by this artist" shelf.
- **Artist:** round artwork; Popular (top 5, expandable to 10), Albums, Singles and EPs, Similar Artists; biography collapsed to 3 lines.
- **Playlist:** rows with thumbnails and an album column on expanded; owner can rename, reorder (drag handle on touch, drag on desktop), remove, and delete. Touch means Android and iOS. The name dialog disables its confirm action while the trimmed name is empty; delete confirms in `danger`; "Add to playlist" picks from the user's own playlists and "New playlist" in a bottom sheet on touch and a dialog otherwise, and confirms "Added N to <name>". A playlist opened under its temporary id stays on screen when the server assigns its id, and the location takes the new id. Items the server marks `playback.isPlayable == false` are disabled with the server's `message`.
- **Mix** (`/mix/:mixId`, `autoPlaylists`): opened from a Made For You card. The playlist header with the mosaic of the first four covers, the "Mix" overline, the description and "N songs · duration"; `ActionBar` with Play, Shuffle, Save as playlist and an overflow of Play next and Add to queue, and no Download or Like. Rows as on a playlist, queued with the `mix` context. Save as playlist asks for a name prefilled with the mix name (the create-playlist dialog), then enqueues one `playlistCreate` and one `playlistAdd` per playable track in mix order under the temporary id, so it works offline; a snackbar "Saved to your playlists" offers Open. It is disabled while no track is playable. With `autoPlaylists` off the route shows "Not available on this server" without a request; a `FeatureDisabled` answer shows the same and refreshes the capabilities.

### Now Playing, Queue, Lyrics (M1)

- **Compact:** drag handle and "NOW PLAYING" overline; artwork (max 360, radius 12); title, artist (tappable), like; `SeekBar` with elapsed and remaining; transport (shuffle, previous, play/pause 64 px, next, repeat); a row with quality badge, output (the iOS system picker, 48 × 48, labelled "Audio output", where `PlatformCapabilities.hasSystemRoutePicker` is true; Android has no output control), queue, lyrics. Queue and Lyrics open as sheets over the same screen.
- **Expanded:** now playing is the right panel plus the player bar; an "expand" control shows a large-artwork overlay over the content area with lyrics beside it.
- **Queue:** "Now playing", "Next up" (reorderable, swipe or button to remove), "Clear". In a Listen Together group the header shows the group and member count.
- **Lyrics:** synced lyrics scroll with the current line in `content` at `title` size, other lines in `contentSecondary`; tapping a line seeks. Plain lyrics scroll freely. "No lyrics found" otherwise. LRC parsing (`[mm:ss.xx]`) is a pure function with tests.
- Episodes replace shuffle, previous, next and repeat with skip-back, skip-forward (labelled with the interval, "Skip back 15 seconds") and a speed menu (0.5×–3×) on the player bar and now playing; the mini player shows skip-forward in place of next.

### Podcasts (M1)

Subscribed grid (the Library grid's columns); Top Podcasts shelf, hidden when empty or failed. A top podcast the user already follows opens its detail; any other opens a dialog (artwork, title, author, Subscribe) and a successful subscribe opens the new podcast's detail. Detail with the album header (overline "Podcast", author and episode count), a Subscribe / Unsubscribe pill (Unsubscribe confirms, then returns to `/podcasts`; both disabled with a tooltip while the server is not reachable, a failure shows a snackbar), the description collapsed to three lines, and an episode list of fixed-height rows (title, date, duration, progress bar, download glyph, played check), each one merged semantics node ("Title, Mar 12, 2026, 42 minutes, played" or "…, 18 minutes left"). Episode row tap plays from the saved position.

### Settings (M0 onward)

| Section | Items |
|---|---|
| Servers | Profile list, add, switch, sign out, remove; per-server: version, link expiry, "Open server admin" (shown to admin users) |
| Playback | Quality on Wi-Fi / mobile data (one "Streaming quality" row where `PlatformCapabilities.hasMobileData` is false), applied from the next resolved source; volume levelling mode (server setting `loudnessMode`: shown at once and posted, restored with a snackbar on failure, disabled with a tooltip while the server is not reachable, a skeleton until a value is known); skip interval (5, 10, 15, 30, 45 or 60 s) and default speed (0.5×–3×) for podcasts, the speed applied at once to a playing episode. Each row opens a single-choice list: a sheet on touch, a menu on pointer |
| Storage | In order: **Downloads** (where the platform can download): download quality (a choice list as on Playback, captioned that it applies to new downloads), Wi-Fi only switch, device limit slider with the usage against the limit, "Remove all downloads" in the danger colour; **This device** (where the profile has files): a usage bar and rows for Downloads (with the item count), Images, Database and free space when known; **Server** (where the platform can download, online, and the statistics request succeeded): "Used on the server: X of Y", "From this device: Z" and the caption that the server limit is changed in the server's settings; **Cache**: "Clear cache". Both destructive actions confirm in a dialog first; remove states the size it frees. Sizes use `formatBytes` (`lib/shared/util/byte_format.dart`: binary units, one decimal, the locale's number format). Details in [07](07-offline-and-downloads.md#storage-accounting-and-quota) |
| Appearance | Theme mode, language |
| Desktop | Listed on desktop platforms and the web: the keyboard shortcuts, one line per binding with the key names of the platform (Cmd and Option on macOS); close to tray, start minimised, global media keys |
| About | Version, licences (`LicenseRegistry`, including the bundled fonts), export logs, pending changes count |

The client has no admin or acquisition actions. "Open server admin" opens `<server address>/admin` in the browser and is the only link of its kind; content screens show no delete, server-side download (acquisition) or request actions; keeping music on this device (Downloads) is not one of them. Account security, integrations, and API-key management are reached from that web page.

## Desktop Interaction

| Shortcut (Cmd on macOS for Ctrl) | Action |
|---|---|
| Space | Play / pause (when no text field has focus) |
| Ctrl+Right / Ctrl+Left | Next / previous |
| Shift+Right / Shift+Left | Seek ±10 s, clamped to the item |
| Ctrl+Up / Ctrl+Down | Volume ±5 %, clamped to 0–100 % |
| Ctrl+S / Ctrl+R | Shuffle / cycle repeat |
| Ctrl+L | Like current track (nothing for an episode) |
| Ctrl+K or / | Focus search (opening Search when its field is not on screen); `/` only when no text field has focus |
| Ctrl+1 … Ctrl+4 | Home, Search, Library, Podcasts |
| Ctrl+Q (Ctrl on macOS too) | Toggle the queue panel (expanded); open or close the queue sheet (compact, medium) |
| Alt+Left / Alt+Right, mouse back/forward | Navigate back / forward |
| Ctrl+, | Settings |
| Enter on a row | Play; Shift+Enter: play next (the selection when there is one) |
| Delete on a selected playlist row | Remove from playlist (owner only) |
| Menu key / Shift+F10 | Open the menu of the focused row or card |
| F5 / Ctrl+Shift+R | Refresh current screen |
| F6 / Shift+F6 | Next / previous focus group |

Implemented with `Shortcuts`/`Actions` at the shell so they are discoverable to assistive technology, and listed in `Settings → Desktop`. One data table, `shortcutBindings` (`lib/app/shell/shortcuts/`: intent, key combinations, label), drives both. The shortcuts are active on desktop platforms and on the web at every window class. A shortcut whose action has no target (Space with an empty queue, Back at a branch root, Ctrl+L on an episode) does nothing and leaves the key to the widgets above; arrows, Space, Enter, Delete and `/` are left to a focused text field. The queue toggle is Ctrl+Q on macOS too, because Cmd+Q quits the app ([10](10-platform-integration.md)). Refresh calls the shown screen's own refresh, the one its pull to refresh runs. A focus anchor in the shell takes focus back when it falls above the shell, so keys keep reaching the shortcuts after navigation.

- **Selection:** in track lists, with a mouse, a click selects one row, Ctrl+click toggles a row, Shift+click selects from the anchor to the clicked row, and a double click plays; touch input keeps tap-to-play. With a row focused, Ctrl+A selects every loaded row, Escape clears the selection, Up and Down move the focused row and Shift+Up and Shift+Down extend the selection. Selected rows are drawn in `surfaceActive` and read as selected. One `SelectionController<T>` per list (`lib/shared/widgets/track_selection.dart`) holds the selection and the rows' focus nodes. The menu, Enter, Shift+Enter, Delete and drag act on the whole selection when the target row is part of it, otherwise on that row alone. The menu of several tracks (`trackSelectionActions`) has Play now, Play next, Add to queue and Add to playlist… over the playable tracks, and Remove from this playlist when every row sits in one playlist the user owns; Like, Download, Go to and Share are left out.
- **Drag and drop:** in-app only (`Draggable`/`DragTarget`, no OS-level drag), started with a mouse or trackpad and never by touch, where a long press opens the menu. Sources (`lib/shared/dnd/`): track rows carry their selection or the row alone (rows without a `playbackId` are not draggable and are left out of a multi-row payload); album cards and the album page's header artwork carry the album. A `surfaceOverlay` chip beside the pointer shows the title, or the count ("5 tracks") for several tracks. Targets: a sidebar playlist the user owns adds the tracks (an album resolved to its tracks first) and confirms with "Added N to name"; while a payload hovers it, the row is drawn in `surfaceActive` with a 2 px `brand` outline. Liked Songs and other users' playlists accept nothing and show no highlight. The queue panel inserts at the "Next up" gap nearest the pointer, marked by a 2 px `brand` insertion line, directly after the current item when dropped on "Now playing" or above it, and as a new, paused queue when the queue is empty; it scrolls while the pointer is within 48 px of its top or bottom edge. Dropped tracks are queued with the `single` context, an album's tracks with `album`. A drag released outside any target changes nothing. Drag and drop adds nothing the menus lack, so it has no semantics action; the chip and the line are left out of the semantics tree.
- **Context menus:** right-click, and the Menu key / Shift+F10, which open the menu of the focused row or card below its start.
- **Window:** minimum size 480 × 600; bounds and maximised state persisted, as the frame (title bar included), and restored before the window is shown; on Linux a window manager's title bar cannot be measured on a hidden window, so `DesktopShell` re-applies bounds requested while hidden once the shown window measures its decorations, and the restored frame matches the saved one within 2 px; title "Track — Artist · soundspan" while playing.
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
- `tool/gen_pseudo_locale.dart` writes `app_en_XA.arb` from `app_en.arb` (run by `tool/gen.sh`): literal text is accented with Latin-1 and Latin Extended-A letters the bundled font renders, each message and each plural or select branch is padded with words to at least 40 % longer, and the message is wrapped in `[` `]`; placeholders, selectors, `#` and quote escapes are copied unchanged. `en_XA` is a development aid: it is a supported locale and in the Appearance language list only when `BuildConfig.channel` is `dev`.
- No Arabic ARB ships, because an untranslated locale must not appear in the language list. Right to left is tested by pumping with locale `ar`: the framework's localizations and text direction are Arabic and the app's messages fall back to English (`pumpApp`).
- The app and `pumpApp` pass one list, `appLocalizationsDelegates` (`lib/app/l10n/app_locales.dart`): `AppLocalizations.delegate` followed by `material_ui`'s `GlobalMaterialLocalizations.delegates` (Material, Cupertino and Widgets). The generated `AppLocalizations.localizationsDelegates` is not used: its `flutter_localizations` delegates provide a `MaterialLocalizations` type that `material_ui` widgets do not look up, so any language other than English would fail. Adding a language stays a new ARB file with no code changes.
- `l10n.yaml` sets `required-resource-attributes: true`: every message in `app_en.arb` has a `description`.
- Server-provided text (error `message`s, playlist names) is shown as received.

## Accessibility

- Every icon-only control has a tooltip and a semantics label. `TrackRow` exposes one merged node: "Title, Artist, 3 minutes 41 seconds, downloaded", with custom actions for like, queue, and menu.
- Focus order follows reading order; the shell defines `FocusTraversalGroup`s for sidebar, content, right panel, and player bar; F6 cycles between them on desktop.
- Visible focus ring: 2 px `brand`, 2 px offset, on every focusable in both themes.
- Now-playing changes are announced politely (`SemanticsService.announce`) when the screen reader is on.
- `SeekBar` and volume are sliders with increase/decrease actions.
- Golden tests run at text scale 1.0 and 2.0 for the shell and rows. The widget-test helper runs Flutter's `meetsGuideline` checks (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) on every screen.
- Manual screen-reader passes (TalkBack, VoiceOver on iOS and macOS, Narrator, Orca) are an M5 exit criterion with a written script.
