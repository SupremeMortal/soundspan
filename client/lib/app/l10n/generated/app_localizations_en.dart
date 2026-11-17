// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'soundspan';

  @override
  String windowTitle(String screen) {
    return '$screen · soundspan';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navPodcasts => 'Podcasts';

  @override
  String get navMainLabel => 'Main navigation';

  @override
  String get screenConnect => 'Add server';

  @override
  String get screenConnectScan => 'Scan QR code';

  @override
  String get screenConnectProbe => 'Checking server';

  @override
  String get screenSignIn => 'Sign in';

  @override
  String get screenSettings => 'Settings';

  @override
  String get screenSettingsServers => 'Servers';

  @override
  String get screenSettingsPlayback => 'Playback';

  @override
  String get playbackNotificationChannelName => 'Playback';

  @override
  String get screenSettingsStorage => 'Storage';

  @override
  String get screenSettingsAppearance => 'Appearance';

  @override
  String get screenSettingsAbout => 'About';

  @override
  String get screenAlbum => 'Album';

  @override
  String get screenArtist => 'Artist';

  @override
  String get screenPlaylist => 'Playlist';

  @override
  String get shellBack => 'Back';

  @override
  String get shellForward => 'Forward';

  @override
  String get shellSearchHint => 'Search';

  @override
  String get shellAccountMenu => 'Account and servers';

  @override
  String get shellMenuServers => 'Servers';

  @override
  String get shellMenuCurrentServer => 'Current server';

  @override
  String get shellMenuAddServer => 'Add server';

  @override
  String get shellMenuSettings => 'Settings';

  @override
  String get settingsThemeTitle => 'Theme';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLanguageName => 'English';

  @override
  String get settingsServersAdd => 'Add server';

  @override
  String get settingsServersSwitch => 'Switch';

  @override
  String get settingsServersRename => 'Rename';

  @override
  String get settingsServersOpenAdmin => 'Open server admin';

  @override
  String get settingsServersStateActive => 'Active';

  @override
  String get settingsServersStateSignedOut => 'Signed out';

  @override
  String settingsServersAccount(String username, String host) {
    return '$username on $host';
  }

  @override
  String settingsServersVersion(String version) {
    return 'Server version $version';
  }

  @override
  String get settingsServersVersionUnknown => 'Server version not known yet';

  @override
  String settingsServersLinkExpires(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Link expires $dateString';
  }

  @override
  String get settingsServersLinkExpiryUnknown => 'Link expiry unknown';

  @override
  String get settingsServersRenameTitle => 'Rename server';

  @override
  String get settingsServersRenameLabel => 'Name';

  @override
  String get settingsServersRenameSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get localDataTooNewTitle =>
      'This data was written by a newer version of the app';

  @override
  String get localDataTooNewBody =>
      'Update the app to keep using this data, reset this server’s local data, or switch to another server.';

  @override
  String get localDataTooNewReset => 'Reset this server’s local data';

  @override
  String get localDataTooNewSwitch => 'Switch server';

  @override
  String get localDataTooNewConfirmTitle => 'Reset local data?';

  @override
  String get localDataTooNewConfirmBody =>
      'The queue, pending changes and downloads of this server are deleted from this device. Your library on the server is not changed.';

  @override
  String get localDataTooNewConfirmReset => 'Reset';

  @override
  String get storageVolatileNotice =>
      'This browser is not keeping data, so nothing will be remembered after this page is closed.';

  @override
  String get screenLicenses => 'Open-source licences';

  @override
  String get settingsAboutLicenses => 'Licences';

  @override
  String settingsAboutPendingChanges(int count) {
    return 'Pending changes: $count';
  }

  @override
  String get settingsAboutVersion => 'Version';

  @override
  String settingsAboutVersionValue(String version, String build) {
    return '$version ($build)';
  }

  @override
  String settingsAboutVersionWithChannel(
    String version,
    String build,
    String channel,
  ) {
    return '$version ($build) · $channel';
  }

  @override
  String get settingsAboutExportLogs => 'Export logs';

  @override
  String get settingsAboutExportLogsDone => 'Logs exported';

  @override
  String get settingsAboutExportLogsNothing => 'No logs to export';

  @override
  String get settingsAboutExportLogsFailed => 'Couldn’t export logs';

  @override
  String get outboxItemsGoneMessage =>
      'Some changes couldn’t be saved because the item no longer exists';

  @override
  String get outboxConflictMessage =>
      'A change couldn’t be saved because it was changed elsewhere';

  @override
  String get licensesSectionBundled => 'Fonts and bundled libraries';

  @override
  String get licensesSectionPackages => 'Packages';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licences',
      one: '1 licence',
    );
    return '$_temp0';
  }

  @override
  String get licensesLoading => 'Loading licences';

  @override
  String get licensesLoadFailed => 'The licences could not be loaded.';

  @override
  String get licensesRetry => 'Try again';

  @override
  String get connectAddressLabel => 'Server address';

  @override
  String get connectAddressHint => 'music.example.com or 192.168.1.20:3030';

  @override
  String get connectAddressSubmit => 'Connect';

  @override
  String get connectAddressBack => 'Back';

  @override
  String get connectAddressEmpty =>
      'Enter the address of your soundspan server.';

  @override
  String get connectAddressUnsupportedScheme =>
      'Use an address that starts with http:// or https://.';

  @override
  String get connectAddressInvalid =>
      'That is not a server address. Check it and try again.';

  @override
  String get connectCleartextTitle => 'Connection not encrypted';

  @override
  String connectCleartextBody(String address) {
    return '$address uses http, so your password and music travel unencrypted and can be read on the way. Use https if the server offers it.';
  }

  @override
  String connectCleartextBlockedBody(String address) {
    return '$address uses http. This device blocks unencrypted connections to public servers, so use the server’s https address.';
  }

  @override
  String get connectCleartextCancel => 'Cancel';

  @override
  String get connectCleartextConnectAnyway => 'Connect anyway';

  @override
  String connectProbeResolving(String address) {
    return 'Connecting to $address';
  }

  @override
  String get connectProbeStarting => 'The server is starting';

  @override
  String connectProbeStartingRetry(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Trying again in $seconds seconds',
      one: 'Trying again in 1 second',
    );
    return '$_temp0';
  }

  @override
  String get connectProbeCancel => 'Cancel';

  @override
  String connectProbeUsing(String address) {
    return 'Using $address';
  }

  @override
  String connectProbeConnected(String address) {
    return 'Connected to $address';
  }

  @override
  String get connectProbeNotEncrypted => 'Not encrypted';

  @override
  String get connectProbeContinue => 'Continue';

  @override
  String get connectProbeEditAddress => 'Edit address';

  @override
  String get connectProbeTryAgain => 'Try again';

  @override
  String connectProbeTried(String address) {
    return 'Address tried: $address';
  }

  @override
  String get connectProbeNeedsSetup =>
      'This server has not been set up yet. Open it in a browser, create the first account there, then try again.';

  @override
  String get connectProbeOpenInBrowser => 'Open in browser';

  @override
  String get connectProbeDns => 'Address not found';

  @override
  String get connectProbeRefused =>
      'Nothing is listening at that address and port';

  @override
  String get connectProbeTimeout => 'The server did not answer';

  @override
  String get connectProbeTls =>
      'The server’s certificate is not trusted by this device';

  @override
  String get connectProbeBlockedByProxy =>
      'Something in front of the server requires its own login';

  @override
  String get connectProbeNotSoundspan =>
      'That address is not a soundspan server (check the path)';

  @override
  String get connectProbeServerError => 'The server reported an error';

  @override
  String get connectProbeRedirectRefused =>
      'The server redirected to an address this app will not follow';

  @override
  String get connectProbeCorsOrNetwork =>
      'The server could not be reached. If it is running, it must allow this app’s address: add the address below to the server’s ALLOWED_ORIGINS setting, restart it and try again.';

  @override
  String connectServerTooOld(String minServer, String version) {
    return 'This app needs soundspan $minServer or newer. This server runs $version.';
  }

  @override
  String get connectServerTooOldCheckAgain => 'Check again';

  @override
  String get connectServerTooOldSwitchServer => 'Switch server';

  @override
  String get connectProbeOrigin => 'This app’s address';

  @override
  String get connectProbeCopyOrigin => 'Copy';

  @override
  String get mediaCardPlay => 'Play';

  @override
  String get shelfShowAll => 'Show all';

  @override
  String get shelfScrollBack => 'Scroll back';

  @override
  String get shelfScrollForward => 'Scroll forward';

  @override
  String connectSignInHeading(String server) {
    return 'Sign in to $server';
  }

  @override
  String get connectSignInBack => 'Use a different server';

  @override
  String get connectSignInUsername => 'User name or email';

  @override
  String get connectSignInPassword => 'Password';

  @override
  String get connectSignInShowPassword => 'Show password';

  @override
  String get connectSignInHidePassword => 'Hide password';

  @override
  String get connectSignInSubmit => 'Sign in';

  @override
  String get connectSignInInvalidCredentials =>
      'The user name or password is not correct';

  @override
  String get connectSignInAuthenticatorPrompt =>
      'Enter the 6-digit code from your authenticator app.';

  @override
  String get connectSignInRecoveryPrompt =>
      'Enter one of your 8-character recovery codes.';

  @override
  String get connectSignInAuthenticatorCode => 'Authenticator code';

  @override
  String get connectSignInRecoveryCode => 'Recovery code';

  @override
  String get connectSignInUseRecovery => 'Use a recovery code instead';

  @override
  String get connectSignInUseAuthenticator =>
      'Use an authenticator code instead';

  @override
  String get connectSignInVerify => 'Verify';

  @override
  String get connectSignInStartOver => 'Start over';

  @override
  String get connectSignInInvalidCode => 'That code is not correct';

  @override
  String connectSignInRateLimited(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Too many attempts. Try again in $seconds seconds.',
      one: 'Too many attempts. Try again in 1 second.',
    );
    return '$_temp0';
  }

  @override
  String get connectSignInFailed =>
      'Could not sign in. Check the connection and try again.';

  @override
  String get connectSignInRetry => 'Retry';

  @override
  String get connectSignInSecureStorage =>
      'This device has no secure storage service, so the sign-in cannot be kept. On Linux, install and start a Secret Service provider such as GNOME Keyring or KWallet.';

  @override
  String get connectSignInNoPassword =>
      'This server does not offer password sign-in.';

  @override
  String trackRowDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String trackRowDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String trackRowDurationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String get errorViewOffline => 'You’re offline';

  @override
  String get errorViewFeatureDisabled => 'Not available on this server';

  @override
  String get errorViewRateLimited => 'Too many requests, try again shortly';

  @override
  String get errorViewServerProblem => 'The server ran into a problem';

  @override
  String get errorViewNotFound => 'This item is no longer available';

  @override
  String get errorViewGeneric => 'Something went wrong';

  @override
  String get errorViewRetry => 'Retry';

  @override
  String get appBannerDismiss => 'Dismiss';

  @override
  String get offlineBannerNoNetwork =>
      'You’re offline. Showing what’s saved on this device.';

  @override
  String get offlineBannerServerUnreachable =>
      'Can’t reach the server. Showing what’s saved on this device.';

  @override
  String get offlineBannerForced => 'Offline mode is on.';

  @override
  String get offlineBannerRetry => 'Retry';

  @override
  String get libraryTabPlaylists => 'Playlists';

  @override
  String get libraryTabArtists => 'Artists';

  @override
  String get libraryTabAlbums => 'Albums';

  @override
  String get libraryTabSongs => 'Songs';

  @override
  String get librarySort => 'Sort';

  @override
  String get librarySortNameAsc => 'Name (A-Z)';

  @override
  String get librarySortNameDesc => 'Name (Z-A)';

  @override
  String get librarySortYearNewest => 'Year (newest)';

  @override
  String get librarySortMostTracks => 'Most tracks';

  @override
  String get libraryOriginAll => 'All';

  @override
  String get libraryOriginLocal => 'Local';

  @override
  String get libraryOriginPeers => 'Peers';

  @override
  String get libraryOriginRemote => 'Remote';

  @override
  String get libraryRefresh => 'Refresh';

  @override
  String get libraryRefreshFailed => 'Couldn’t refresh the list';

  @override
  String get libraryAlbumsEmpty => 'No albums yet';

  @override
  String get libraryArtistsEmpty => 'No artists yet';

  @override
  String get librarySongsEmpty => 'No songs yet';

  @override
  String get libraryLikedSongs => 'Liked Songs';

  @override
  String libraryPlaylistTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get libraryPlaylistsEmptyHint => 'Playlists you create appear here';

  @override
  String get sidebarPlaylistsLabel => 'Playlists';

  @override
  String get libraryArtistCardSubtitle => 'Artist';

  @override
  String get homeGreetingMorning => 'Good morning';

  @override
  String get homeGreetingAfternoon => 'Good afternoon';

  @override
  String get homeGreetingEvening => 'Good evening';

  @override
  String get homeShelfContinueListening => 'Continue Listening';

  @override
  String get homeShelfRecentlyAdded => 'Recently Added';

  @override
  String get homeShelfMadeForYou => 'Made For You';

  @override
  String get homeShelfYourPlaylists => 'Your Playlists';

  @override
  String get homeShelfPopularPodcasts => 'Popular Podcasts';

  @override
  String get homeLikedSongs => 'Liked Songs';

  @override
  String get homeLikedSongsSubtitle => 'Playlist';

  @override
  String get homeCardArtist => 'Artist';

  @override
  String get homeCardPodcast => 'Podcast';

  @override
  String get homeNoticeNewerThanTested =>
      'This server is newer than this app was tested with';

  @override
  String get homeNoticeVersionUnknown =>
      'This server’s version could not be read';

  @override
  String homeLinkExpiring(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'This device’s link expires in $days days',
      one: 'This device’s link expires today',
    );
    return '$_temp0';
  }

  @override
  String get homeLinkExpired => 'This device’s link has expired';

  @override
  String get homeLinkAgain => 'Link again';

  @override
  String get keyExpiryNotificationTitle => 'This device’s link expires soon';

  @override
  String keyExpiryNotificationBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'It expires in $days days. Tap to link it again.',
      one: 'It expires today. Tap to link it again.',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyLibrary => 'Your library is empty';

  @override
  String homePlaylistSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String detailDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String detailDurationHours(int hours, int minutes) {
    return '$hours hr $minutes min';
  }

  @override
  String detailSongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get detailRefreshFailed => 'Couldn’t refresh. Showing saved content.';

  @override
  String get likeButtonLike => 'Like';

  @override
  String get likeButtonRemove => 'Remove like';

  @override
  String get trackNotPlayable => 'Not playable';

  @override
  String get trackRowPlayHint => 'Play';

  @override
  String get trackRowPlaying => 'playing';

  @override
  String get trackRowPaused => 'paused';

  @override
  String playQueueTruncated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Only the first $countString songs were queued';
  }

  @override
  String get librarySongsShuffleAll => 'Shuffle all';

  @override
  String get albumOverline => 'Album';

  @override
  String albumDisc(int number) {
    return 'Disc $number';
  }

  @override
  String get albumMoreByArtist => 'More by this artist';

  @override
  String get playlistOverline => 'Playlist';

  @override
  String get playlistPublic => 'Public';

  @override
  String get playlistLikedTitle => 'Liked Songs';

  @override
  String get playlistEmpty => 'This playlist has no songs yet';

  @override
  String get playlistNew => 'New playlist';

  @override
  String get playlistRenameTitle => 'Rename playlist';

  @override
  String get playlistNameLabel => 'Name';

  @override
  String get playlistCreate => 'Create';

  @override
  String get playlistRename => 'Rename';

  @override
  String get playlistCancel => 'Cancel';

  @override
  String playlistDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get playlistDeleteBody =>
      'The playlist is removed from your library. The songs in it stay.';

  @override
  String get playlistDelete => 'Delete';

  @override
  String get playlistAddToTitle => 'Add to playlist';

  @override
  String playlistAdded(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count songs to $name',
      one: 'Added 1 song to $name',
    );
    return '$_temp0';
  }

  @override
  String get playlistReorderHandle => 'Drag to reorder';

  @override
  String get artistOverline => 'Artist';

  @override
  String get artistPopular => 'Popular';

  @override
  String get artistShowMore => 'Show more';

  @override
  String get artistShowLess => 'Show less';

  @override
  String get artistAlbums => 'Albums';

  @override
  String get artistSinglesAndEps => 'Singles and EPs';

  @override
  String get artistSimilar => 'Similar Artists';

  @override
  String get artistCardSubtitle => 'Artist';

  @override
  String get artistAbout => 'About';

  @override
  String get artistReadMore => 'Read more';

  @override
  String get searchFieldHint => 'Songs, artists, albums or podcasts';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchScopeAll => 'All';

  @override
  String get searchScopeLibrary => 'Library';

  @override
  String get searchScopeDiscover => 'Discover';

  @override
  String get searchScopePodcasts => 'Podcasts';

  @override
  String get searchRecentTitle => 'Recent searches';

  @override
  String get searchRecentClearAll => 'Clear all';

  @override
  String searchRecentRemove(String query) {
    return 'Remove $query';
  }

  @override
  String get searchPrompt => 'Search for songs, artists, albums and podcasts';

  @override
  String searchNoResults(String query) {
    return 'No results for “$query”';
  }

  @override
  String get searchTopResult => 'Top result';

  @override
  String get searchSectionSongs => 'Songs';

  @override
  String get searchSectionArtists => 'Artists';

  @override
  String get searchSectionAlbums => 'Albums';

  @override
  String get searchSectionPlaylists => 'Playlists';

  @override
  String get searchSectionPodcasts => 'Podcasts';

  @override
  String get searchShowAll => 'Show all';

  @override
  String get searchShowLess => 'Show less';

  @override
  String get searchNotPlayable => 'Not playable';

  @override
  String get searchKindArtist => 'Artist';

  @override
  String get searchKindSong => 'Song';

  @override
  String get searchKindPodcast => 'Podcast';

  @override
  String searchPlaylistSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get codeCellsLabel => 'Link code, 6 characters';

  @override
  String get codeCellsHint => 'Codes have no I, O, 0 or 1';

  @override
  String get connectDeviceLinkStep1 => 'Open soundspan in a browser';

  @override
  String get connectDeviceLinkStep2 => 'Go to Settings → Link Device';

  @override
  String get connectDeviceLinkStep3 =>
      'Select Generate Code and enter it below';

  @override
  String get connectDeviceLinkDeviceName => 'Device name';

  @override
  String get connectDeviceLinkSubmit => 'Link';

  @override
  String get connectScanQrCode => 'Scan QR code';

  @override
  String get connectScanHint =>
      'Point the camera at the QR code on the Link Device page of the web UI.';

  @override
  String get connectScanRejected => 'That is not a soundspan code';

  @override
  String get connectScanPermissionDenied =>
      'soundspan cannot use the camera to scan the code.';

  @override
  String get connectScanAllowCamera =>
      'To scan, allow camera access for soundspan in your system settings.';

  @override
  String get connectScanNoCamera => 'No camera available';

  @override
  String get connectScanEnterCode => 'Enter the code instead';

  @override
  String get connectDeviceLinkInvalidCode =>
      'That code does not exist. Generate a new code in the web UI.';

  @override
  String get connectDeviceLinkCodeUsed =>
      'That code has already been used. Generate a new code in the web UI.';

  @override
  String get connectDeviceLinkCodeExpired =>
      'That code has expired. Generate a new code in the web UI.';

  @override
  String get connectDeviceLinkRejected =>
      'The server did not accept the code. Generate a new code in the web UI.';

  @override
  String get connectSignInLinkWithCode => 'Link with a code';

  @override
  String get connectSignInUsePassword => 'Sign in with a password';

  @override
  String get connectSignInSsoNote =>
      'Single sign-on users: link this device with a code.';

  @override
  String get connectLinkThisDevice => 'Link this device';

  @override
  String connectSignInWithProvider(String provider) {
    return 'Sign in with $provider';
  }

  @override
  String get screenPodcast => 'Podcast';

  @override
  String get podcastsYourPodcasts => 'Your podcasts';

  @override
  String get podcastsTopPodcasts => 'Top podcasts';

  @override
  String get podcastsEmpty => 'You haven’t subscribed to any podcasts yet';

  @override
  String get podcastsOverline => 'Podcast';

  @override
  String podcastsEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get podcastsSubscribe => 'Subscribe';

  @override
  String get podcastsUnsubscribe => 'Unsubscribe';

  @override
  String podcastsUnsubscribeTitle(String title) {
    return 'Unsubscribe from $title?';
  }

  @override
  String get podcastsUnsubscribeBody =>
      'The podcast leaves your podcasts. You can subscribe again later.';

  @override
  String get podcastsCancel => 'Cancel';

  @override
  String get podcastsOfflineTooltip =>
      'Subscriptions can be changed only while the server is reachable';

  @override
  String get podcastsSubscribeFailed => 'Couldn’t subscribe. Try again.';

  @override
  String get podcastsUnsubscribeFailed => 'Couldn’t unsubscribe. Try again.';

  @override
  String get podcastsShowMore => 'Show more';

  @override
  String get podcastsShowLess => 'Show less';

  @override
  String get podcastsEpisodePlayed => 'Played';

  @override
  String podcastsEpisodeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String podcastsEpisodeMinutesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes left',
      one: '1 minute left',
    );
    return '$_temp0';
  }

  @override
  String get podcastsEpisodePlayedSpoken => 'played';

  @override
  String get navExplore => 'Explore';

  @override
  String get discoverRecommendedForYou => 'Recommended For You';

  @override
  String get discoverPopularArtists => 'Popular Artists';

  @override
  String get discoverCardArtist => 'Artist';

  @override
  String get exploreThisWeek => 'This week’s discoveries';

  @override
  String get explorePlay => 'Play';

  @override
  String get exploreShuffle => 'Shuffle';

  @override
  String get exploreShowAll => 'Show all';

  @override
  String get exploreEmpty => 'Nothing to explore yet';

  @override
  String get exploreNotAvailable => 'Not available on this server';

  @override
  String get homeExploreCard => 'Find new artists and music';

  @override
  String get connectSignInUseApiKey => 'Use an API key';

  @override
  String get connectApiKeyHeading => 'Sign in with an API key';

  @override
  String get connectApiKeyField => 'API key';

  @override
  String get connectApiKeyShow => 'Show API key';

  @override
  String get connectApiKeyHide => 'Hide API key';

  @override
  String get connectApiKeyPaste => 'Paste';

  @override
  String get connectApiKeyExpiryUnknown =>
      'This key’s expiry date is not known to the app. You will be asked to sign in again when the server stops accepting it.';

  @override
  String get connectApiKeyMalformed =>
      'This is not an API key. Copy the whole key from the web UI and paste it here.';

  @override
  String get connectApiKeyRejected =>
      'The server did not accept this key. It may have expired or been revoked.';

  @override
  String get connectSignInNoBrowserMethod =>
      'This server offers no sign-in method this app can use in a browser.';

  @override
  String get downloadUnavailableDisabled =>
      'Downloads are turned off on this server';

  @override
  String get downloadUnavailableGone => 'No longer available';

  @override
  String get downloadUnavailableAccount => 'Not available for your account';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerShuffle => 'Shuffle';

  @override
  String get playerRepeatOff => 'Repeat';

  @override
  String get playerRepeatAll => 'Repeat all';

  @override
  String get playerRepeatOne => 'Repeat one';

  @override
  String get playerVolume => 'Volume';

  @override
  String get playerSeek => 'Seek';

  @override
  String playerSeekValue(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String get nowPlayingOverline => 'Now playing';

  @override
  String get nowPlayingClose => 'Close';

  @override
  String get nowPlayingQueue => 'Queue';

  @override
  String get nowPlayingExpand => 'Show now playing';

  @override
  String get nowPlayingCollapse => 'Hide now playing';

  @override
  String get queueTitle => 'Queue';

  @override
  String get queueNowPlaying => 'Now playing';

  @override
  String get queueNextUp => 'Next up';

  @override
  String get queueClear => 'Clear';

  @override
  String get queueEmpty => 'Nothing is queued';

  @override
  String get queueRemove => 'Remove from queue';

  @override
  String get queueMoveUp => 'Move up';

  @override
  String get queueMoveDown => 'Move down';

  @override
  String get queueReorderHandle => 'Drag to reorder';

  @override
  String qualityBadgeSampleRate(
    String codec,
    String bitDepth,
    String sampleRate,
  ) {
    return '$codec · $bitDepth/$sampleRate kHz';
  }

  @override
  String qualityBadgeBitrate(String codec, String bitrate) {
    return '$codec · $bitrate kbps';
  }
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get appTitle => '[šöûñðšþåñ one]';

  @override
  String windowTitle(String screen) {
    return '[$screen · šöûñðšþåñ one two]';
  }

  @override
  String get navHome => '[Ĥömé one]';

  @override
  String get navSearch => '[Šéåŕçĥ one]';

  @override
  String get navLibrary => '[Ļîbŕåŕý one]';

  @override
  String get navPodcasts => '[Þöðçåšţš one]';

  @override
  String get navMainLabel => '[Måîñ ñåvîĝåţîöñ one two]';

  @override
  String get screenConnect => '[Åðð šéŕvéŕ one]';

  @override
  String get screenConnectScan => '[Šçåñ QŔ çöðé one two]';

  @override
  String get screenConnectProbe => '[Çĥéçķîñĝ šéŕvéŕ one two]';

  @override
  String get screenSignIn => '[Šîĝñ îñ one]';

  @override
  String get screenSettings => '[Šéţţîñĝš one]';

  @override
  String get screenSettingsServers => '[Šéŕvéŕš one]';

  @override
  String get screenSettingsPlayback => '[Þļåýbåçķ one]';

  @override
  String get playbackNotificationChannelName => '[Þļåýbåçķ one]';

  @override
  String get screenSettingsStorage => '[Šţöŕåĝé one]';

  @override
  String get screenSettingsAppearance => '[Åþþéåŕåñçé one]';

  @override
  String get screenSettingsAbout => '[Åböûţ one]';

  @override
  String get screenAlbum => '[Åļbûm one]';

  @override
  String get screenArtist => '[Åŕţîšţ one]';

  @override
  String get screenPlaylist => '[Þļåýļîšţ one]';

  @override
  String get shellBack => '[Båçķ one]';

  @override
  String get shellForward => '[Föŕŵåŕð one]';

  @override
  String get shellSearchHint => '[Šéåŕçĥ one]';

  @override
  String get shellAccountMenu => '[Åççöûñţ åñð šéŕvéŕš one two]';

  @override
  String get shellMenuServers => '[Šéŕvéŕš one]';

  @override
  String get shellMenuCurrentServer => '[Çûŕŕéñţ šéŕvéŕ one two]';

  @override
  String get shellMenuAddServer => '[Åðð šéŕvéŕ one]';

  @override
  String get shellMenuSettings => '[Šéţţîñĝš one]';

  @override
  String get settingsThemeTitle => '[Ţĥémé one]';

  @override
  String get settingsThemeSystem => '[Šýšţém one]';

  @override
  String get settingsThemeDark => '[Ðåŕķ one]';

  @override
  String get settingsThemeLight => '[Ļîĝĥţ one]';

  @override
  String get settingsLanguageTitle => '[Ļåñĝûåĝé one]';

  @override
  String get settingsLanguageSystem => '[Šýšţém ðéfåûļţ one two]';

  @override
  String get settingsLanguageName => '[Éñĝļîšĥ one]';

  @override
  String get settingsServersAdd => '[Åðð šéŕvéŕ one]';

  @override
  String get settingsServersSwitch => '[Šŵîţçĥ one]';

  @override
  String get settingsServersRename => '[Ŕéñåmé one]';

  @override
  String get settingsServersOpenAdmin => '[Öþéñ šéŕvéŕ åðmîñ one two]';

  @override
  String get settingsServersStateActive => '[Åçţîvé one]';

  @override
  String get settingsServersStateSignedOut => '[Šîĝñéð öûţ one]';

  @override
  String settingsServersAccount(String username, String host) {
    return '[$username öñ $host one]';
  }

  @override
  String settingsServersVersion(String version) {
    return '[Šéŕvéŕ véŕšîöñ $version one two]';
  }

  @override
  String get settingsServersVersionUnknown =>
      '[Šéŕvéŕ véŕšîöñ ñöţ ķñöŵñ ýéţ one two three]';

  @override
  String settingsServersLinkExpires(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '[Ļîñķ éxþîŕéš $dateString one two]';
  }

  @override
  String get settingsServersLinkExpiryUnknown =>
      '[Ļîñķ éxþîŕý ûñķñöŵñ one two]';

  @override
  String get settingsServersRenameTitle => '[Ŕéñåmé šéŕvéŕ one two]';

  @override
  String get settingsServersRenameLabel => '[Ñåmé one]';

  @override
  String get settingsServersRenameSave => '[Šåvé one]';

  @override
  String get commonCancel => '[Çåñçéļ one]';

  @override
  String get localDataTooNewTitle =>
      '[Ţĥîš ðåţå ŵåš ŵŕîţţéñ bý å ñéŵéŕ véŕšîöñ öf ţĥé åþþ one two three four five]';

  @override
  String get localDataTooNewBody =>
      '[Ûþðåţé ţĥé åþþ ţö ķééþ ûšîñĝ ţĥîš ðåţå, ŕéšéţ ţĥîš šéŕvéŕ’š ļöçåļ ðåţå, öŕ šŵîţçĥ ţö åñöţĥéŕ šéŕvéŕ. one two three four five six seven eight]';

  @override
  String get localDataTooNewReset =>
      '[Ŕéšéţ ţĥîš šéŕvéŕ’š ļöçåļ ðåţå one two three]';

  @override
  String get localDataTooNewSwitch => '[Šŵîţçĥ šéŕvéŕ one two]';

  @override
  String get localDataTooNewConfirmTitle => '[Ŕéšéţ ļöçåļ ðåţå? one two]';

  @override
  String get localDataTooNewConfirmBody =>
      '[Ţĥé qûéûé, þéñðîñĝ çĥåñĝéš åñð ðöŵñļöåðš öf ţĥîš šéŕvéŕ åŕé ðéļéţéð fŕöm ţĥîš ðévîçé. Ýöûŕ ļîbŕåŕý öñ ţĥé šéŕvéŕ îš ñöţ çĥåñĝéð. one two three four five six seven eight nine ten one]';

  @override
  String get localDataTooNewConfirmReset => '[Ŕéšéţ one]';

  @override
  String get storageVolatileNotice =>
      '[Ţĥîš bŕöŵšéŕ îš ñöţ ķééþîñĝ ðåţå, šö ñöţĥîñĝ ŵîļļ bé ŕémémbéŕéð åfţéŕ ţĥîš þåĝé îš çļöšéð. one two three four five six seven eight]';

  @override
  String get screenLicenses => '[Öþéñ-šöûŕçé ļîçéñçéš one two]';

  @override
  String get settingsAboutLicenses => '[Ļîçéñçéš one]';

  @override
  String settingsAboutPendingChanges(int count) {
    return '[Þéñðîñĝ çĥåñĝéš: $count one two]';
  }

  @override
  String get settingsAboutVersion => '[Véŕšîöñ one]';

  @override
  String settingsAboutVersionValue(String version, String build) {
    return '[$version ($build) one]';
  }

  @override
  String settingsAboutVersionWithChannel(
    String version,
    String build,
    String channel,
  ) {
    return '[$version ($build) · $channel one]';
  }

  @override
  String get settingsAboutExportLogs => '[Éxþöŕţ ļöĝš one two]';

  @override
  String get settingsAboutExportLogsDone => '[Ļöĝš éxþöŕţéð one two]';

  @override
  String get settingsAboutExportLogsNothing => '[Ñö ļöĝš ţö éxþöŕţ one two]';

  @override
  String get settingsAboutExportLogsFailed => '[Çöûļðñ’ţ éxþöŕţ ļöĝš one two]';

  @override
  String get outboxItemsGoneMessage =>
      '[Šömé çĥåñĝéš çöûļðñ’ţ bé šåvéð béçåûšé ţĥé îţém ñö ļöñĝéŕ éxîšţš one two three four five six]';

  @override
  String get outboxConflictMessage =>
      '[Å çĥåñĝé çöûļðñ’ţ bé šåvéð béçåûšé îţ ŵåš çĥåñĝéð éļšéŵĥéŕé one two three four five]';

  @override
  String get licensesSectionBundled =>
      '[Föñţš åñð bûñðļéð ļîbŕåŕîéš one two three]';

  @override
  String get licensesSectionPackages => '[Þåçķåĝéš one]';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ļîçéñçéš one',
      one: '1 ļîçéñçé one',
    );
    return '[$_temp0]';
  }

  @override
  String get licensesLoading => '[Ļöåðîñĝ ļîçéñçéš one two]';

  @override
  String get licensesLoadFailed =>
      '[Ţĥé ļîçéñçéš çöûļð ñöţ bé ļöåðéð. one two three]';

  @override
  String get licensesRetry => '[Ţŕý åĝåîñ one]';

  @override
  String get connectAddressLabel => '[Šéŕvéŕ åððŕéšš one two]';

  @override
  String get connectAddressHint =>
      '[mûšîç.éxåmþļé.çöm öŕ 192.168.1.20:3030 one two three four]';

  @override
  String get connectAddressSubmit => '[Çöññéçţ one]';

  @override
  String get connectAddressBack => '[Båçķ one]';

  @override
  String get connectAddressEmpty =>
      '[Éñţéŕ ţĥé åððŕéšš öf ýöûŕ šöûñðšþåñ šéŕvéŕ. one two three four]';

  @override
  String get connectAddressUnsupportedScheme =>
      '[Ûšé åñ åððŕéšš ţĥåţ šţåŕţš ŵîţĥ ĥţţþ:// öŕ ĥţţþš://. one two three four five]';

  @override
  String get connectAddressInvalid =>
      '[Ţĥåţ îš ñöţ å šéŕvéŕ åððŕéšš. Çĥéçķ îţ åñð ţŕý åĝåîñ. one two three four five]';

  @override
  String get connectCleartextTitle =>
      '[Çöññéçţîöñ ñöţ éñçŕýþţéð one two three]';

  @override
  String connectCleartextBody(String address) {
    return '[$address ûšéš ĥţţþ, šö ýöûŕ þåššŵöŕð åñð mûšîç ţŕåvéļ ûñéñçŕýþţéð åñð çåñ bé ŕéåð öñ ţĥé ŵåý. Ûšé ĥţţþš îf ţĥé šéŕvéŕ öfféŕš îţ. one two three four five six seven eight nine ten]';
  }

  @override
  String connectCleartextBlockedBody(String address) {
    return '[$address ûšéš ĥţţþ. Ţĥîš ðévîçé bļöçķš ûñéñçŕýþţéð çöññéçţîöñš ţö þûbļîç šéŕvéŕš, šö ûšé ţĥé šéŕvéŕ’š ĥţţþš åððŕéšš. one two three four five six seven eight nine]';
  }

  @override
  String get connectCleartextCancel => '[Çåñçéļ one]';

  @override
  String get connectCleartextConnectAnyway => '[Çöññéçţ åñýŵåý one two]';

  @override
  String connectProbeResolving(String address) {
    return '[Çöññéçţîñĝ ţö $address one two]';
  }

  @override
  String get connectProbeStarting => '[Ţĥé šéŕvéŕ îš šţåŕţîñĝ one two three]';

  @override
  String connectProbeStartingRetry(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Ţŕýîñĝ åĝåîñ îñ $seconds šéçöñðš one two three',
      one: 'Ţŕýîñĝ åĝåîñ îñ 1 šéçöñð one two three',
    );
    return '[$_temp0]';
  }

  @override
  String get connectProbeCancel => '[Çåñçéļ one]';

  @override
  String connectProbeUsing(String address) {
    return '[Ûšîñĝ $address one]';
  }

  @override
  String connectProbeConnected(String address) {
    return '[Çöññéçţéð ţö $address one two]';
  }

  @override
  String get connectProbeNotEncrypted => '[Ñöţ éñçŕýþţéð one two]';

  @override
  String get connectProbeContinue => '[Çöñţîñûé one]';

  @override
  String get connectProbeEditAddress => '[Éðîţ åððŕéšš one two]';

  @override
  String get connectProbeTryAgain => '[Ţŕý åĝåîñ one]';

  @override
  String connectProbeTried(String address) {
    return '[Åððŕéšš ţŕîéð: $address one two]';
  }

  @override
  String get connectProbeNeedsSetup =>
      '[Ţĥîš šéŕvéŕ ĥåš ñöţ bééñ šéţ ûþ ýéţ. Öþéñ îţ îñ å bŕöŵšéŕ, çŕéåţé ţĥé fîŕšţ åççöûñţ ţĥéŕé, ţĥéñ ţŕý åĝåîñ. one two three four five six seven eight nine]';

  @override
  String get connectProbeOpenInBrowser => '[Öþéñ îñ bŕöŵšéŕ one two]';

  @override
  String get connectProbeDns => '[Åððŕéšš ñöţ föûñð one two]';

  @override
  String get connectProbeRefused =>
      '[Ñöţĥîñĝ îš ļîšţéñîñĝ åţ ţĥåţ åððŕéšš åñð þöŕţ one two three four]';

  @override
  String get connectProbeTimeout => '[Ţĥé šéŕvéŕ ðîð ñöţ åñšŵéŕ one two three]';

  @override
  String get connectProbeTls =>
      '[Ţĥé šéŕvéŕ’š çéŕţîfîçåţé îš ñöţ ţŕûšţéð bý ţĥîš ðévîçé one two three four five]';

  @override
  String get connectProbeBlockedByProxy =>
      '[Šöméţĥîñĝ îñ fŕöñţ öf ţĥé šéŕvéŕ ŕéqûîŕéš îţš öŵñ ļöĝîñ one two three four five]';

  @override
  String get connectProbeNotSoundspan =>
      '[Ţĥåţ åððŕéšš îš ñöţ å šöûñðšþåñ šéŕvéŕ (çĥéçķ ţĥé þåţĥ) one two three four five]';

  @override
  String get connectProbeServerError =>
      '[Ţĥé šéŕvéŕ ŕéþöŕţéð åñ éŕŕöŕ one two three]';

  @override
  String get connectProbeRedirectRefused =>
      '[Ţĥé šéŕvéŕ ŕéðîŕéçţéð ţö åñ åððŕéšš ţĥîš åþþ ŵîļļ ñöţ föļļöŵ one two three four five]';

  @override
  String get connectProbeCorsOrNetwork =>
      '[Ţĥé šéŕvéŕ çöûļð ñöţ bé ŕéåçĥéð. Îf îţ îš ŕûññîñĝ, îţ mûšţ åļļöŵ ţĥîš åþþ’š åððŕéšš: åðð ţĥé åððŕéšš béļöŵ ţö ţĥé šéŕvéŕ’š ÅĻĻÖŴÉÐ_ÖŔÎĜÎÑŠ šéţţîñĝ, ŕéšţåŕţ îţ åñð ţŕý åĝåîñ. one two three four five six seven eight nine ten one two three four five]';

  @override
  String connectServerTooOld(String minServer, String version) {
    return '[Ţĥîš åþþ ñééðš šöûñðšþåñ $minServer öŕ ñéŵéŕ. Ţĥîš šéŕvéŕ ŕûñš $version. one two three four five]';
  }

  @override
  String get connectServerTooOldCheckAgain => '[Çĥéçķ åĝåîñ one two]';

  @override
  String get connectServerTooOldSwitchServer => '[Šŵîţçĥ šéŕvéŕ one two]';

  @override
  String get connectProbeOrigin => '[Ţĥîš åþþ’š åððŕéšš one two]';

  @override
  String get connectProbeCopyOrigin => '[Çöþý one]';

  @override
  String get mediaCardPlay => '[Þļåý one]';

  @override
  String get shelfShowAll => '[Šĥöŵ åļļ one]';

  @override
  String get shelfScrollBack => '[Šçŕöļļ båçķ one two]';

  @override
  String get shelfScrollForward => '[Šçŕöļļ föŕŵåŕð one two]';

  @override
  String connectSignInHeading(String server) {
    return '[Šîĝñ îñ ţö $server one two]';
  }

  @override
  String get connectSignInBack => '[Ûšé å ðîfféŕéñţ šéŕvéŕ one two three]';

  @override
  String get connectSignInUsername => '[Ûšéŕ ñåmé öŕ émåîļ one two]';

  @override
  String get connectSignInPassword => '[Þåššŵöŕð one]';

  @override
  String get connectSignInShowPassword => '[Šĥöŵ þåššŵöŕð one two]';

  @override
  String get connectSignInHidePassword => '[Ĥîðé þåššŵöŕð one two]';

  @override
  String get connectSignInSubmit => '[Šîĝñ îñ one]';

  @override
  String get connectSignInInvalidCredentials =>
      '[Ţĥé ûšéŕ ñåmé öŕ þåššŵöŕð îš ñöţ çöŕŕéçţ one two three four]';

  @override
  String get connectSignInAuthenticatorPrompt =>
      '[Éñţéŕ ţĥé 6-ðîĝîţ çöðé fŕöm ýöûŕ åûţĥéñţîçåţöŕ åþþ. one two three four five]';

  @override
  String get connectSignInRecoveryPrompt =>
      '[Éñţéŕ öñé öf ýöûŕ 8-çĥåŕåçţéŕ ŕéçövéŕý çöðéš. one two three four]';

  @override
  String get connectSignInAuthenticatorCode => '[Åûţĥéñţîçåţöŕ çöðé one two]';

  @override
  String get connectSignInRecoveryCode => '[Ŕéçövéŕý çöðé one two]';

  @override
  String get connectSignInUseRecovery =>
      '[Ûšé å ŕéçövéŕý çöðé îñšţéåð one two three]';

  @override
  String get connectSignInUseAuthenticator =>
      '[Ûšé åñ åûţĥéñţîçåţöŕ çöðé îñšţéåð one two three]';

  @override
  String get connectSignInVerify => '[Véŕîfý one]';

  @override
  String get connectSignInStartOver => '[Šţåŕţ övéŕ one]';

  @override
  String get connectSignInInvalidCode =>
      '[Ţĥåţ çöðé îš ñöţ çöŕŕéçţ one two three]';

  @override
  String connectSignInRateLimited(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other:
          'Ţöö måñý åţţémþţš. Ţŕý åĝåîñ îñ $seconds šéçöñðš. one two three four',
      one: 'Ţöö måñý åţţémþţš. Ţŕý åĝåîñ îñ 1 šéçöñð. one two three four',
    );
    return '[$_temp0]';
  }

  @override
  String get connectSignInFailed =>
      '[Çöûļð ñöţ šîĝñ îñ. Çĥéçķ ţĥé çöññéçţîöñ åñð ţŕý åĝåîñ. one two three four five]';

  @override
  String get connectSignInRetry => '[Ŕéţŕý one]';

  @override
  String get connectSignInSecureStorage =>
      '[Ţĥîš ðévîçé ĥåš ñö šéçûŕé šţöŕåĝé šéŕvîçé, šö ţĥé šîĝñ-îñ çåññöţ bé ķéþţ. Öñ Ļîñûx, îñšţåļļ åñð šţåŕţ å Šéçŕéţ Šéŕvîçé þŕövîðéŕ šûçĥ åš ĜÑÖMÉ Ķéýŕîñĝ öŕ ĶŴåļļéţ. one two three four five six seven eight nine ten one two three four]';

  @override
  String get connectSignInNoPassword =>
      '[Ţĥîš šéŕvéŕ ðöéš ñöţ öfféŕ þåššŵöŕð šîĝñ-îñ. one two three four]';

  @override
  String trackRowDurationHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ĥöûŕš one',
      one: '1 ĥöûŕ one',
    );
    return '[$_temp0]';
  }

  @override
  String trackRowDurationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mîñûţéš one',
      one: '1 mîñûţé one',
    );
    return '[$_temp0]';
  }

  @override
  String trackRowDurationSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šéçöñðš one',
      one: '1 šéçöñð one',
    );
    return '[$_temp0]';
  }

  @override
  String get errorViewOffline => '[Ýöû’ŕé öffļîñé one two]';

  @override
  String get errorViewFeatureDisabled =>
      '[Ñöţ åvåîļåbļé öñ ţĥîš šéŕvéŕ one two three]';

  @override
  String get errorViewRateLimited =>
      '[Ţöö måñý ŕéqûéšţš, ţŕý åĝåîñ šĥöŕţļý one two three four]';

  @override
  String get errorViewServerProblem =>
      '[Ţĥé šéŕvéŕ ŕåñ îñţö å þŕöbļém one two three]';

  @override
  String get errorViewNotFound =>
      '[Ţĥîš îţém îš ñö ļöñĝéŕ åvåîļåbļé one two three]';

  @override
  String get errorViewGeneric => '[Šöméţĥîñĝ ŵéñţ ŵŕöñĝ one two]';

  @override
  String get errorViewRetry => '[Ŕéţŕý one]';

  @override
  String get appBannerDismiss => '[Ðîšmîšš one]';

  @override
  String get offlineBannerNoNetwork =>
      '[Ýöû’ŕé öffļîñé. Šĥöŵîñĝ ŵĥåţ’š šåvéð öñ ţĥîš ðévîçé. one two three four five]';

  @override
  String get offlineBannerServerUnreachable =>
      '[Çåñ’ţ ŕéåçĥ ţĥé šéŕvéŕ. Šĥöŵîñĝ ŵĥåţ’š šåvéð öñ ţĥîš ðévîçé. one two three four five]';

  @override
  String get offlineBannerForced => '[Öffļîñé möðé îš öñ. one two]';

  @override
  String get offlineBannerRetry => '[Ŕéţŕý one]';

  @override
  String get libraryTabPlaylists => '[Þļåýļîšţš one]';

  @override
  String get libraryTabArtists => '[Åŕţîšţš one]';

  @override
  String get libraryTabAlbums => '[Åļbûmš one]';

  @override
  String get libraryTabSongs => '[Šöñĝš one]';

  @override
  String get librarySort => '[Šöŕţ one]';

  @override
  String get librarySortNameAsc => '[Ñåmé (Å-Ž) one]';

  @override
  String get librarySortNameDesc => '[Ñåmé (Ž-Å) one]';

  @override
  String get librarySortYearNewest => '[Ýéåŕ (ñéŵéšţ) one two]';

  @override
  String get librarySortMostTracks => '[Möšţ ţŕåçķš one two]';

  @override
  String get libraryOriginAll => '[Åļļ one]';

  @override
  String get libraryOriginLocal => '[Ļöçåļ one]';

  @override
  String get libraryOriginPeers => '[Þééŕš one]';

  @override
  String get libraryOriginRemote => '[Ŕémöţé one]';

  @override
  String get libraryRefresh => '[Ŕéfŕéšĥ one]';

  @override
  String get libraryRefreshFailed =>
      '[Çöûļðñ’ţ ŕéfŕéšĥ ţĥé ļîšţ one two three]';

  @override
  String get libraryAlbumsEmpty => '[Ñö åļbûmš ýéţ one two]';

  @override
  String get libraryArtistsEmpty => '[Ñö åŕţîšţš ýéţ one two]';

  @override
  String get librarySongsEmpty => '[Ñö šöñĝš ýéţ one two]';

  @override
  String get libraryLikedSongs => '[Ļîķéð Šöñĝš one two]';

  @override
  String libraryPlaylistTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šöñĝš one',
      one: '1 šöñĝ one',
    );
    return '[$_temp0]';
  }

  @override
  String get libraryPlaylistsEmptyHint =>
      '[Þļåýļîšţš ýöû çŕéåţé åþþéåŕ ĥéŕé one two three]';

  @override
  String get sidebarPlaylistsLabel => '[Þļåýļîšţš one]';

  @override
  String get libraryArtistCardSubtitle => '[Åŕţîšţ one]';

  @override
  String get homeGreetingMorning => '[Ĝööð möŕñîñĝ one two]';

  @override
  String get homeGreetingAfternoon => '[Ĝööð åfţéŕñööñ one two]';

  @override
  String get homeGreetingEvening => '[Ĝööð évéñîñĝ one two]';

  @override
  String get homeShelfContinueListening => '[Çöñţîñûé Ļîšţéñîñĝ one two]';

  @override
  String get homeShelfRecentlyAdded => '[Ŕéçéñţļý Åððéð one two]';

  @override
  String get homeShelfMadeForYou => '[Måðé Föŕ Ýöû one two]';

  @override
  String get homeShelfYourPlaylists => '[Ýöûŕ Þļåýļîšţš one two]';

  @override
  String get homeShelfPopularPodcasts => '[Þöþûļåŕ Þöðçåšţš one two]';

  @override
  String get homeLikedSongs => '[Ļîķéð Šöñĝš one two]';

  @override
  String get homeLikedSongsSubtitle => '[Þļåýļîšţ one]';

  @override
  String get homeCardArtist => '[Åŕţîšţ one]';

  @override
  String get homeCardPodcast => '[Þöðçåšţ one]';

  @override
  String get homeNoticeNewerThanTested =>
      '[Ţĥîš šéŕvéŕ îš ñéŵéŕ ţĥåñ ţĥîš åþþ ŵåš ţéšţéð ŵîţĥ one two three four five]';

  @override
  String get homeNoticeVersionUnknown =>
      '[Ţĥîš šéŕvéŕ’š véŕšîöñ çöûļð ñöţ bé ŕéåð one two three four]';

  @override
  String homeLinkExpiring(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Ţĥîš ðévîçé’š ļîñķ éxþîŕéš îñ $days ðåýš one two three',
      one: 'Ţĥîš ðévîçé’š ļîñķ éxþîŕéš ţöðåý one two three',
    );
    return '[$_temp0]';
  }

  @override
  String get homeLinkExpired =>
      '[Ţĥîš ðévîçé’š ļîñķ ĥåš éxþîŕéð one two three]';

  @override
  String get homeLinkAgain => '[Ļîñķ åĝåîñ one]';

  @override
  String get keyExpiryNotificationTitle =>
      '[Ţĥîš ðévîçé’š ļîñķ éxþîŕéš šööñ one two three]';

  @override
  String keyExpiryNotificationBody(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'Îţ éxþîŕéš îñ $days ðåýš. Ţåþ ţö ļîñķ îţ åĝåîñ. one two three four',
      one: 'Îţ éxþîŕéš ţöðåý. Ţåþ ţö ļîñķ îţ åĝåîñ. one two three four',
    );
    return '[$_temp0]';
  }

  @override
  String get homeEmptyLibrary => '[Ýöûŕ ļîbŕåŕý îš émþţý one two three]';

  @override
  String homePlaylistSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šöñĝš one',
      one: '1 šöñĝ one',
    );
    return '[$_temp0]';
  }

  @override
  String detailDurationMinutes(int minutes) {
    return '[$minutes mîñ one]';
  }

  @override
  String detailDurationHours(int hours, int minutes) {
    return '[$hours ĥŕ $minutes mîñ one]';
  }

  @override
  String detailSongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šöñĝš one',
      one: '1 šöñĝ one',
    );
    return '[$_temp0]';
  }

  @override
  String get detailRefreshFailed =>
      '[Çöûļðñ’ţ ŕéfŕéšĥ. Šĥöŵîñĝ šåvéð çöñţéñţ. one two three four]';

  @override
  String get likeButtonLike => '[Ļîķé one]';

  @override
  String get likeButtonRemove => '[Ŕémövé ļîķé one two]';

  @override
  String get trackNotPlayable => '[Ñöţ þļåýåbļé one two]';

  @override
  String get trackRowPlayHint => '[Þļåý one]';

  @override
  String get trackRowPlaying => '[þļåýîñĝ one]';

  @override
  String get trackRowPaused => '[þåûšéð one]';

  @override
  String playQueueTruncated(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '[Öñļý ţĥé fîŕšţ $countString šöñĝš ŵéŕé qûéûéð one two three]';
  }

  @override
  String get librarySongsShuffleAll => '[Šĥûffļé åļļ one two]';

  @override
  String get albumOverline => '[Åļbûm one]';

  @override
  String albumDisc(int number) {
    return '[Ðîšç $number one]';
  }

  @override
  String get albumMoreByArtist => '[Möŕé bý ţĥîš åŕţîšţ one two]';

  @override
  String get playlistOverline => '[Þļåýļîšţ one]';

  @override
  String get playlistPublic => '[Þûbļîç one]';

  @override
  String get playlistLikedTitle => '[Ļîķéð Šöñĝš one two]';

  @override
  String get playlistEmpty => '[Ţĥîš þļåýļîšţ ĥåš ñö šöñĝš ýéţ one two three]';

  @override
  String get playlistNew => '[Ñéŵ þļåýļîšţ one two]';

  @override
  String get playlistRenameTitle => '[Ŕéñåmé þļåýļîšţ one two]';

  @override
  String get playlistNameLabel => '[Ñåmé one]';

  @override
  String get playlistCreate => '[Çŕéåţé one]';

  @override
  String get playlistRename => '[Ŕéñåmé one]';

  @override
  String get playlistCancel => '[Çåñçéļ one]';

  @override
  String playlistDeleteTitle(String name) {
    return '[Ðéļéţé $name? one]';
  }

  @override
  String get playlistDeleteBody =>
      '[Ţĥé þļåýļîšţ îš ŕémövéð fŕöm ýöûŕ ļîbŕåŕý. Ţĥé šöñĝš îñ îţ šţåý. one two three four five six]';

  @override
  String get playlistDelete => '[Ðéļéţé one]';

  @override
  String get playlistAddToTitle => '[Åðð ţö þļåýļîšţ one two]';

  @override
  String playlistAdded(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Åððéð $count šöñĝš ţö $name one two',
      one: 'Åððéð 1 šöñĝ ţö $name one two',
    );
    return '[$_temp0]';
  }

  @override
  String get playlistReorderHandle => '[Ðŕåĝ ţö ŕéöŕðéŕ one two]';

  @override
  String get artistOverline => '[Åŕţîšţ one]';

  @override
  String get artistPopular => '[Þöþûļåŕ one]';

  @override
  String get artistShowMore => '[Šĥöŵ möŕé one]';

  @override
  String get artistShowLess => '[Šĥöŵ ļéšš one]';

  @override
  String get artistAlbums => '[Åļbûmš one]';

  @override
  String get artistSinglesAndEps => '[Šîñĝļéš åñð ÉÞš one two]';

  @override
  String get artistSimilar => '[Šîmîļåŕ Åŕţîšţš one two]';

  @override
  String get artistCardSubtitle => '[Åŕţîšţ one]';

  @override
  String get artistAbout => '[Åböûţ one]';

  @override
  String get artistReadMore => '[Ŕéåð möŕé one]';

  @override
  String get searchFieldHint =>
      '[Šöñĝš, åŕţîšţš, åļbûmš öŕ þöðçåšţš one two three]';

  @override
  String get searchClear => '[Çļéåŕ šéåŕçĥ one two]';

  @override
  String get searchScopeAll => '[Åļļ one]';

  @override
  String get searchScopeLibrary => '[Ļîbŕåŕý one]';

  @override
  String get searchScopeDiscover => '[Ðîšçövéŕ one]';

  @override
  String get searchScopePodcasts => '[Þöðçåšţš one]';

  @override
  String get searchRecentTitle => '[Ŕéçéñţ šéåŕçĥéš one two]';

  @override
  String get searchRecentClearAll => '[Çļéåŕ åļļ one]';

  @override
  String searchRecentRemove(String query) {
    return '[Ŕémövé $query one]';
  }

  @override
  String get searchPrompt =>
      '[Šéåŕçĥ föŕ šöñĝš, åŕţîšţš, åļbûmš åñð þöðçåšţš one two three four]';

  @override
  String searchNoResults(String query) {
    return '[Ñö ŕéšûļţš föŕ “$query” one two]';
  }

  @override
  String get searchTopResult => '[Ţöþ ŕéšûļţ one]';

  @override
  String get searchSectionSongs => '[Šöñĝš one]';

  @override
  String get searchSectionArtists => '[Åŕţîšţš one]';

  @override
  String get searchSectionAlbums => '[Åļbûmš one]';

  @override
  String get searchSectionPlaylists => '[Þļåýļîšţš one]';

  @override
  String get searchSectionPodcasts => '[Þöðçåšţš one]';

  @override
  String get searchShowAll => '[Šĥöŵ åļļ one]';

  @override
  String get searchShowLess => '[Šĥöŵ ļéšš one]';

  @override
  String get searchNotPlayable => '[Ñöţ þļåýåbļé one two]';

  @override
  String get searchKindArtist => '[Åŕţîšţ one]';

  @override
  String get searchKindSong => '[Šöñĝ one]';

  @override
  String get searchKindPodcast => '[Þöðçåšţ one]';

  @override
  String searchPlaylistSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count šöñĝš one',
      one: '1 šöñĝ one',
    );
    return '[$_temp0]';
  }

  @override
  String get codeCellsLabel => '[Ļîñķ çöðé, 6 çĥåŕåçţéŕš one two three]';

  @override
  String get codeCellsHint => '[Çöðéš ĥåvé ñö Î, Ö, 0 öŕ 1 one two three]';

  @override
  String get connectDeviceLinkStep1 =>
      '[Öþéñ šöûñðšþåñ îñ å bŕöŵšéŕ one two three]';

  @override
  String get connectDeviceLinkStep2 =>
      '[Ĝö ţö Šéţţîñĝš → Ļîñķ Ðévîçé one two three]';

  @override
  String get connectDeviceLinkStep3 =>
      '[Šéļéçţ Ĝéñéŕåţé Çöðé åñð éñţéŕ îţ béļöŵ one two three four]';

  @override
  String get connectDeviceLinkDeviceName => '[Ðévîçé ñåmé one two]';

  @override
  String get connectDeviceLinkSubmit => '[Ļîñķ one]';

  @override
  String get connectScanQrCode => '[Šçåñ QŔ çöðé one two]';

  @override
  String get connectScanHint =>
      '[Þöîñţ ţĥé çåméŕå åţ ţĥé QŔ çöðé öñ ţĥé Ļîñķ Ðévîçé þåĝé öf ţĥé ŵéb ÛÎ. one two three four five six]';

  @override
  String get connectScanRejected =>
      '[Ţĥåţ îš ñöţ å šöûñðšþåñ çöðé one two three]';

  @override
  String get connectScanPermissionDenied =>
      '[šöûñðšþåñ çåññöţ ûšé ţĥé çåméŕå ţö šçåñ ţĥé çöðé. one two three four five]';

  @override
  String get connectScanAllowCamera =>
      '[Ţö šçåñ, åļļöŵ çåméŕå åççéšš föŕ šöûñðšþåñ îñ ýöûŕ šýšţém šéţţîñĝš. one two three four five six]';

  @override
  String get connectScanNoCamera => '[Ñö çåméŕå åvåîļåbļé one two]';

  @override
  String get connectScanEnterCode => '[Éñţéŕ ţĥé çöðé îñšţéåð one two three]';

  @override
  String get connectDeviceLinkInvalidCode =>
      '[Ţĥåţ çöðé ðöéš ñöţ éxîšţ. Ĝéñéŕåţé å ñéŵ çöðé îñ ţĥé ŵéb ÛÎ. one two three four five]';

  @override
  String get connectDeviceLinkCodeUsed =>
      '[Ţĥåţ çöðé ĥåš åļŕéåðý bééñ ûšéð. Ĝéñéŕåţé å ñéŵ çöðé îñ ţĥé ŵéb ÛÎ. one two three four five six]';

  @override
  String get connectDeviceLinkCodeExpired =>
      '[Ţĥåţ çöðé ĥåš éxþîŕéð. Ĝéñéŕåţé å ñéŵ çöðé îñ ţĥé ŵéb ÛÎ. one two three four five]';

  @override
  String get connectDeviceLinkRejected =>
      '[Ţĥé šéŕvéŕ ðîð ñöţ åççéþţ ţĥé çöðé. Ĝéñéŕåţé å ñéŵ çöðé îñ ţĥé ŵéb ÛÎ. one two three four five six]';

  @override
  String get connectSignInLinkWithCode => '[Ļîñķ ŵîţĥ å çöðé one two]';

  @override
  String get connectSignInUsePassword =>
      '[Šîĝñ îñ ŵîţĥ å þåššŵöŕð one two three]';

  @override
  String get connectSignInSsoNote =>
      '[Šîñĝļé šîĝñ-öñ ûšéŕš: ļîñķ ţĥîš ðévîçé ŵîţĥ å çöðé. one two three four five]';

  @override
  String get connectLinkThisDevice => '[Ļîñķ ţĥîš ðévîçé one two]';

  @override
  String connectSignInWithProvider(String provider) {
    return '[Šîĝñ îñ ŵîţĥ $provider one two]';
  }

  @override
  String get screenPodcast => '[Þöðçåšţ one]';

  @override
  String get podcastsYourPodcasts => '[Ýöûŕ þöðçåšţš one two]';

  @override
  String get podcastsTopPodcasts => '[Ţöþ þöðçåšţš one two]';

  @override
  String get podcastsEmpty =>
      '[Ýöû ĥåvéñ’ţ šûbšçŕîbéð ţö åñý þöðçåšţš ýéţ one two three four]';

  @override
  String get podcastsOverline => '[Þöðçåšţ one]';

  @override
  String podcastsEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éþîšöðéš one',
      one: '1 éþîšöðé one',
    );
    return '[$_temp0]';
  }

  @override
  String get podcastsSubscribe => '[Šûbšçŕîbé one]';

  @override
  String get podcastsUnsubscribe => '[Ûñšûbšçŕîbé one two]';

  @override
  String podcastsUnsubscribeTitle(String title) {
    return '[Ûñšûbšçŕîbé fŕöm $title? one two]';
  }

  @override
  String get podcastsUnsubscribeBody =>
      '[Ţĥé þöðçåšţ ļéåvéš ýöûŕ þöðçåšţš. Ýöû çåñ šûbšçŕîbé åĝåîñ ļåţéŕ. one two three four five six]';

  @override
  String get podcastsCancel => '[Çåñçéļ one]';

  @override
  String get podcastsOfflineTooltip =>
      '[Šûbšçŕîþţîöñš çåñ bé çĥåñĝéð öñļý ŵĥîļé ţĥé šéŕvéŕ îš ŕéåçĥåbļé one two three four five six]';

  @override
  String get podcastsSubscribeFailed =>
      '[Çöûļðñ’ţ šûbšçŕîbé. Ţŕý åĝåîñ. one two three]';

  @override
  String get podcastsUnsubscribeFailed =>
      '[Çöûļðñ’ţ ûñšûbšçŕîbé. Ţŕý åĝåîñ. one two three]';

  @override
  String get podcastsShowMore => '[Šĥöŵ möŕé one]';

  @override
  String get podcastsShowLess => '[Šĥöŵ ļéšš one]';

  @override
  String get podcastsEpisodePlayed => '[Þļåýéð one]';

  @override
  String podcastsEpisodeMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mîñûţéš one',
      one: '1 mîñûţé one',
    );
    return '[$_temp0]';
  }

  @override
  String podcastsEpisodeMinutesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mîñûţéš ļéfţ one two',
      one: '1 mîñûţé ļéfţ one two',
    );
    return '[$_temp0]';
  }

  @override
  String get podcastsEpisodePlayedSpoken => '[þļåýéð one]';

  @override
  String get navExplore => '[Éxþļöŕé one]';

  @override
  String get discoverRecommendedForYou => '[Ŕéçömméñðéð Föŕ Ýöû one two]';

  @override
  String get discoverPopularArtists => '[Þöþûļåŕ Åŕţîšţš one two]';

  @override
  String get discoverCardArtist => '[Åŕţîšţ one]';

  @override
  String get exploreThisWeek => '[Ţĥîš ŵééķ’š ðîšçövéŕîéš one two three]';

  @override
  String get explorePlay => '[Þļåý one]';

  @override
  String get exploreShuffle => '[Šĥûffļé one]';

  @override
  String get exploreShowAll => '[Šĥöŵ åļļ one]';

  @override
  String get exploreEmpty => '[Ñöţĥîñĝ ţö éxþļöŕé ýéţ one two three]';

  @override
  String get exploreNotAvailable =>
      '[Ñöţ åvåîļåbļé öñ ţĥîš šéŕvéŕ one two three]';

  @override
  String get homeExploreCard => '[Fîñð ñéŵ åŕţîšţš åñð mûšîç one two three]';

  @override
  String get connectSignInUseApiKey => '[Ûšé åñ ÅÞÎ ķéý one two]';

  @override
  String get connectApiKeyHeading => '[Šîĝñ îñ ŵîţĥ åñ ÅÞÎ ķéý one two three]';

  @override
  String get connectApiKeyField => '[ÅÞÎ ķéý one]';

  @override
  String get connectApiKeyShow => '[Šĥöŵ ÅÞÎ ķéý one two]';

  @override
  String get connectApiKeyHide => '[Ĥîðé ÅÞÎ ķéý one two]';

  @override
  String get connectApiKeyPaste => '[Þåšţé one]';

  @override
  String get connectApiKeyExpiryUnknown =>
      '[Ţĥîš ķéý’š éxþîŕý ðåţé îš ñöţ ķñöŵñ ţö ţĥé åþþ. Ýöû ŵîļļ bé åšķéð ţö šîĝñ îñ åĝåîñ ŵĥéñ ţĥé šéŕvéŕ šţöþš åççéþţîñĝ îţ. one two three four five six seven eight nine ten]';

  @override
  String get connectApiKeyMalformed =>
      '[Ţĥîš îš ñöţ åñ ÅÞÎ ķéý. Çöþý ţĥé ŵĥöļé ķéý fŕöm ţĥé ŵéb ÛÎ åñð þåšţé îţ ĥéŕé. one two three four five six seven]';

  @override
  String get connectApiKeyRejected =>
      '[Ţĥé šéŕvéŕ ðîð ñöţ åççéþţ ţĥîš ķéý. Îţ måý ĥåvé éxþîŕéð öŕ bééñ ŕévöķéð. one two three four five six seven]';

  @override
  String get connectSignInNoBrowserMethod =>
      '[Ţĥîš šéŕvéŕ öfféŕš ñö šîĝñ-îñ méţĥöð ţĥîš åþþ çåñ ûšé îñ å bŕöŵšéŕ. one two three four five six]';

  @override
  String get downloadUnavailableDisabled =>
      '[Ðöŵñļöåðš åŕé ţûŕñéð öff öñ ţĥîš šéŕvéŕ one two three four]';

  @override
  String get downloadUnavailableGone => '[Ñö ļöñĝéŕ åvåîļåbļé one two]';

  @override
  String get downloadUnavailableAccount =>
      '[Ñöţ åvåîļåbļé föŕ ýöûŕ åççöûñţ one two three]';

  @override
  String get playerPlay => '[Þļåý one]';

  @override
  String get playerPause => '[Þåûšé one]';

  @override
  String get playerNext => '[Ñéxţ one]';

  @override
  String get playerPrevious => '[Þŕévîöûš one]';

  @override
  String get playerShuffle => '[Šĥûffļé one]';

  @override
  String get playerRepeatOff => '[Ŕéþéåţ one]';

  @override
  String get playerRepeatAll => '[Ŕéþéåţ åļļ one]';

  @override
  String get playerRepeatOne => '[Ŕéþéåţ öñé one]';

  @override
  String get playerVolume => '[Vöļûmé one]';

  @override
  String get playerSeek => '[Šééķ one]';

  @override
  String playerSeekValue(String position, String duration) {
    return '[$position öf $duration one]';
  }

  @override
  String get nowPlayingOverline => '[Ñöŵ þļåýîñĝ one two]';

  @override
  String get nowPlayingClose => '[Çļöšé one]';

  @override
  String get nowPlayingQueue => '[Qûéûé one]';

  @override
  String get nowPlayingExpand => '[Šĥöŵ ñöŵ þļåýîñĝ one two]';

  @override
  String get nowPlayingCollapse => '[Ĥîðé ñöŵ þļåýîñĝ one two]';

  @override
  String get queueTitle => '[Qûéûé one]';

  @override
  String get queueNowPlaying => '[Ñöŵ þļåýîñĝ one two]';

  @override
  String get queueNextUp => '[Ñéxţ ûþ one]';

  @override
  String get queueClear => '[Çļéåŕ one]';

  @override
  String get queueEmpty => '[Ñöţĥîñĝ îš qûéûéð one two]';

  @override
  String get queueRemove => '[Ŕémövé fŕöm qûéûé one two]';

  @override
  String get queueMoveUp => '[Mövé ûþ one]';

  @override
  String get queueMoveDown => '[Mövé ðöŵñ one]';

  @override
  String get queueReorderHandle => '[Ðŕåĝ ţö ŕéöŕðéŕ one two]';

  @override
  String qualityBadgeSampleRate(
    String codec,
    String bitDepth,
    String sampleRate,
  ) {
    return '[$codec · $bitDepth/$sampleRate ķĤž one]';
  }

  @override
  String qualityBadgeBitrate(String codec, String bitrate) {
    return '[$codec · $bitrate ķbþš one]';
  }
}
