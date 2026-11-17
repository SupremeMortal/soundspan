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
  String get androidAutoRecent => 'Recent';

  @override
  String get androidAutoPlaylists => 'Playlists';

  @override
  String get androidAutoAlbums => 'Albums';

  @override
  String get androidAutoDownloads => 'Downloads';

  @override
  String androidAutoDownloadsSubtitle(String kind, int completed) {
    return '$kind · $completed';
  }

  @override
  String downloadsNotificationTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Downloading $count items',
      one: 'Downloading 1 item',
    );
    return '$_temp0';
  }

  @override
  String get downloadsNotificationFinished => 'Downloads finished';

  @override
  String get androidAutoKindEpisode => 'Podcast episode';

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
  String get screenMix => 'Mix';

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
  String get shellActivity => 'Activity';

  @override
  String get shellMenuActivity => 'Activity';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityOnThisServer => 'On this server';

  @override
  String get activityOnConnectedServers => 'On connected servers';

  @override
  String get activityStatusPlaying => 'Playing';

  @override
  String get activityStatusPaused => 'Paused';

  @override
  String get activityStatusIdle => 'Idle';

  @override
  String activityPeerStatus(String status, String server) {
    return '$status on $server';
  }

  @override
  String activityTrack(String title, String artist) {
    return '$title · $artist';
  }

  @override
  String get activityEmpty => 'Nobody else is online';

  @override
  String activityRowPlaying(String name, String title, String artist) {
    return '$name, playing $title by $artist';
  }

  @override
  String activityRowPaused(String name, String title, String artist) {
    return '$name, paused on $title by $artist';
  }

  @override
  String activityRowStatus(String name, String status) {
    return '$name, $status';
  }

  @override
  String activityRowPeer(String label, String server) {
    return '$label, on $server';
  }

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
  String get settingsPlaybackQualityWifi => 'Quality on Wi-Fi';

  @override
  String get settingsPlaybackQualityCellular => 'Quality on mobile data';

  @override
  String get settingsPlaybackQualitySingle => 'Streaming quality';

  @override
  String get settingsPlaybackQualityCaption =>
      'Quality changes apply from the next item that starts.';

  @override
  String get settingsPlaybackQualityServerDefault => 'Server default';

  @override
  String get settingsPlaybackQualityServerDefaultCaption =>
      'The quality saved on the server applies.';

  @override
  String get settingsPlaybackQualityOriginal => 'Original';

  @override
  String get settingsPlaybackQualityHigh => 'High';

  @override
  String get settingsPlaybackQualityMedium => 'Medium';

  @override
  String get settingsPlaybackQualityLow => 'Low';

  @override
  String get settingsPlaybackLevelling => 'Volume levelling';

  @override
  String get settingsPlaybackLevellingOff => 'Off';

  @override
  String get settingsPlaybackLevellingTrack => 'Track';

  @override
  String get settingsPlaybackLevellingAlbum => 'Album';

  @override
  String get settingsPlaybackLevellingAuto => 'Automatic';

  @override
  String get settingsPlaybackLevellingUnknown => 'Unknown';

  @override
  String get settingsPlaybackLevellingOffline =>
      'Available when the server can be reached';

  @override
  String get settingsPlaybackLevellingFailed =>
      'Couldn’t change volume levelling';

  @override
  String get settingsPlaybackSkipInterval => 'Skip interval (podcasts)';

  @override
  String get settingsPlaybackSpeed => 'Default speed (podcasts)';

  @override
  String settingsPlaybackSkipSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds seconds',
      one: '1 second',
    );
    return '$_temp0';
  }

  @override
  String settingsPlaybackSpeedValue(double speed) {
    final intl.NumberFormat speedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String speedString = speedNumberFormat.format(speed);

    return '$speedString×';
  }

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
  String get settingsServersSignOut => 'Sign out';

  @override
  String get settingsServersRemove => 'Remove this server';

  @override
  String settingsServersSignOutTitle(String server) {
    return 'Sign out of $server?';
  }

  @override
  String get settingsServersSignOutBody =>
      'Downloads, cached data and changes not yet sent stay on this device. Sign in again to use this server.';

  @override
  String settingsServersSignOutRemoveDownloads(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Also remove downloads ($count items, $size)',
      one: 'Also remove downloads (1 item, $size)',
    );
    return '$_temp0';
  }

  @override
  String settingsServersRemoveTitle(String server) {
    return 'Remove $server?';
  }

  @override
  String settingsServersRemoveBody(String server) {
    return 'This signs out and deletes everything this app stores for $server on this device, downloads included.';
  }

  @override
  String settingsServersRemovePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count changes have not been sent to the server and will be lost.',
      one: '1 change has not been sent to the server and will be lost.',
    );
    return '$_temp0';
  }

  @override
  String get settingsServersRemoveDownloads =>
      'Downloads on this device for this server will be deleted.';

  @override
  String get settingsServersRemoveConfirm => 'Remove';

  @override
  String get settingsServersRemoveAnyway => 'Remove anyway';

  @override
  String get settingsServersSigningOut => 'Signing out…';

  @override
  String get settingsServersRemoving => 'Removing…';

  @override
  String get settingsServersExitFailed =>
      'The sign-in details on this device could not be deleted. Try again.';

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
  String get twoPaneSelectItem => 'Select an item';

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
  String dragTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
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
  String get homeExploreCard => 'Find new artists and music';

  @override
  String get exploreRadioByGenre => 'Radio by genre';

  @override
  String get exploreRadioByDecade => 'Radio by decade';

  @override
  String get exploreRadioShowAll => 'Show all';

  @override
  String exploreRadioDecade(String decade) {
    return '${decade}s';
  }

  @override
  String exploreRadioTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String exploreRadioStationSemantics(String station, String tracks) {
    return '$station, $tracks, radio station';
  }

  @override
  String get exploreRadioNoTracks => 'No tracks for this station';

  @override
  String get exploreRadioFailed => 'Couldn’t start the station';

  @override
  String get exploreRadioRetry => 'Retry';

  @override
  String get exploreRadioOffline => 'Not available offline';

  @override
  String queueContextRadio(String station) {
    return 'Radio · $station';
  }

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
  String playerSkipBack(int seconds) {
    return 'Skip back $seconds seconds';
  }

  @override
  String playerSkipForward(int seconds) {
    return 'Skip forward $seconds seconds';
  }

  @override
  String get playerSpeed => 'Playback speed';

  @override
  String playerSpeedValue(double speed) {
    final intl.NumberFormat speedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String speedString = speedNumberFormat.format(speed);

    return '$speedString×';
  }

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
  String get nowPlayingAudioOutput => 'Audio output';

  @override
  String get nowPlayingExpand => 'Show now playing';

  @override
  String get nowPlayingCollapse => 'Hide now playing';

  @override
  String get lyricsTitle => 'Lyrics';

  @override
  String get lyricsNone => 'No lyrics found';

  @override
  String lyricsSeekHint(String time) {
    return 'Seek to $time';
  }

  @override
  String get lyricsInstrumental => 'Instrumental';

  @override
  String get lyricsResumeAutoScroll => 'Resume auto-scroll';

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

  @override
  String get qualityBadgeDownloaded => 'Downloaded';

  @override
  String qualityBadgeDownloadedQuality(String quality) {
    return 'Downloaded · $quality';
  }

  @override
  String get menuPlayNow => 'Play now';

  @override
  String get menuPlayNext => 'Play next';

  @override
  String get menuAddToQueue => 'Add to queue';

  @override
  String get menuAddToPlaylist => 'Add to playlist…';

  @override
  String get menuRemoveFromPlaylist => 'Remove from this playlist';

  @override
  String get menuGoToAlbum => 'Go to album';

  @override
  String get menuGoToArtist => 'Go to artist';

  @override
  String get menuShareLink => 'Share link';

  @override
  String get menuLinkCopied => 'Link copied';

  @override
  String get menuRename => 'Rename';

  @override
  String get menuDelete => 'Delete';

  @override
  String get menuMoreOptions => 'More options';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionShuffle => 'Shuffle';

  @override
  String get actionAddToPlaylist => 'Add to playlist';

  @override
  String get screenSettingsDesktop => 'Desktop';

  @override
  String get settingsShortcutsTitle => 'Keyboard shortcuts';

  @override
  String get shortcutPlayPause => 'Play or pause';

  @override
  String get shortcutNext => 'Next track';

  @override
  String get shortcutPrevious => 'Previous track';

  @override
  String shortcutSeekForward(int seconds) {
    return 'Seek forward $seconds seconds';
  }

  @override
  String shortcutSeekBack(int seconds) {
    return 'Seek back $seconds seconds';
  }

  @override
  String get shortcutVolumeUp => 'Volume up';

  @override
  String get shortcutVolumeDown => 'Volume down';

  @override
  String get shortcutShuffle => 'Shuffle on or off';

  @override
  String get shortcutRepeat => 'Change repeat';

  @override
  String get shortcutLike => 'Like or remove like of the current track';

  @override
  String get shortcutSearch => 'Search';

  @override
  String shortcutGoTo(String destination) {
    return 'Go to $destination';
  }

  @override
  String get shortcutQueue => 'Show or hide the queue';

  @override
  String get shortcutPlayRow => 'Play the selected tracks';

  @override
  String get shortcutPlayRowNext => 'Play the selected tracks next';

  @override
  String get shortcutRemoveRow =>
      'Remove the selected tracks from the playlist';

  @override
  String get shortcutMenu => 'Open the menu of the focused item';

  @override
  String get shortcutRefresh => 'Refresh';

  @override
  String get shortcutNextArea => 'Next area';

  @override
  String get shortcutPreviousArea => 'Previous area';

  @override
  String get keyCtrl => 'Ctrl';

  @override
  String get keyCmd => 'Cmd';

  @override
  String get keyShift => 'Shift';

  @override
  String get keyAlt => 'Alt';

  @override
  String get keyOption => 'Option';

  @override
  String get keySpace => 'Space';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyDelete => 'Delete';

  @override
  String get keyMenu => 'Menu';

  @override
  String get keyMouseBack => 'Mouse back button';

  @override
  String get keyMouseForward => 'Mouse forward button';

  @override
  String get settingsStorageDownloads => 'Downloads';

  @override
  String get settingsStorageDownloadQuality => 'Download quality';

  @override
  String get settingsStorageDownloadQualityCaption =>
      'The quality applies to new downloads.';

  @override
  String get settingsStorageWifiOnly => 'Download on Wi-Fi only';

  @override
  String get settingsStorageDeviceLimit => 'Device limit';

  @override
  String get settingsStorageNoLimit => 'No limit';

  @override
  String settingsStorageDeviceLimitUsage(String used, String limit) {
    return '$used of $limit used';
  }

  @override
  String settingsStorageDeviceLimitUsageUnlimited(String used) {
    return '$used used, no limit';
  }

  @override
  String get settingsStorageRemoveAll => 'Remove all downloads';

  @override
  String get settingsStorageRemoveAllTitle => 'Remove all downloads?';

  @override
  String settingsStorageRemoveAllBody(String size) {
    return 'This frees $size on this device. You can download them again later.';
  }

  @override
  String get settingsStorageRemoveAllConfirm => 'Remove';

  @override
  String get settingsStorageThisDevice => 'This device';

  @override
  String get settingsStorageUsageDownloads => 'Downloads';

  @override
  String settingsStorageUsageDownloadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorageUsageImages => 'Images';

  @override
  String get settingsStorageUsageDatabase => 'Database';

  @override
  String get settingsStorageUsageFree => 'Free space';

  @override
  String get settingsStorageServer => 'Server';

  @override
  String settingsStorageServerUsed(String used, String limit) {
    return 'Used on the server: $used of $limit';
  }

  @override
  String settingsStorageServerDevice(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'From this device: $size, $count tracks',
      one: 'From this device: $size, 1 track',
    );
    return '$_temp0';
  }

  @override
  String get settingsStorageServerCaption =>
      'The server limit is changed in the server’s settings.';

  @override
  String get settingsStorageCache => 'Cache';

  @override
  String get settingsStorageClearCache => 'Clear cache';

  @override
  String get settingsStorageClearCacheCaption =>
      'Saved images and browsing data are fetched again when needed. Downloads stay.';

  @override
  String get settingsStorageClearCacheTitle => 'Clear cache?';

  @override
  String get settingsStorageClearCacheBody =>
      'Saved images and browsing data are deleted. Downloads and playback are not affected.';

  @override
  String get settingsStorageClearCacheConfirm => 'Clear';

  @override
  String get settingsStorageCancel => 'Cancel';

  @override
  String get downloadGlyphQueued => 'Waiting to download';

  @override
  String downloadGlyphRunning(int percent) {
    return 'Downloading, $percent percent';
  }

  @override
  String get downloadGlyphRunningUnknown => 'Downloading';

  @override
  String get downloadGlyphCompleted => 'Downloaded';

  @override
  String get downloadGlyphFailed => 'Download failed';

  @override
  String get downloadGlyphUnavailable => 'Not available for download';

  @override
  String get trackRowDownloaded => 'downloaded';

  @override
  String get menuDownload => 'Download';

  @override
  String get menuRemoveDownload => 'Remove download';

  @override
  String get menuRetryDownload => 'Retry download';

  @override
  String get menuCheckForChanges => 'Check for changes';

  @override
  String get downloadRemoveTitle => 'Remove download?';

  @override
  String get downloadRemoveBody =>
      'Its files are deleted from this device. You can download it again later.';

  @override
  String get downloadRemoveConfirm => 'Remove';

  @override
  String get downloadCancel => 'Cancel';

  @override
  String get downloadClose => 'Close';

  @override
  String get downloadServerQuotaTitle => 'Not enough space on the server';

  @override
  String get downloadServerQuotaBody =>
      'Remove downloads to free up space, or raise the download limit in the server’s settings.';

  @override
  String downloadSizeNeeded(String size) {
    return 'Needed: $size';
  }

  @override
  String downloadSizeUsed(String size) {
    return 'Used: $size';
  }

  @override
  String downloadSizeLimit(String size) {
    return 'Limit: $size';
  }

  @override
  String downloadSizeAvailable(String size) {
    return 'Available: $size';
  }

  @override
  String get downloadManage => 'Manage downloads';

  @override
  String downloadShortfallTitle(String size) {
    return '$size more needed on this device';
  }

  @override
  String get downloadRaiseLimit => 'Raise limit';

  @override
  String get downloadWhatFits => 'Download what fits';

  @override
  String get downloadRaiseLimitDiskFull =>
      'There isn’t enough free space on this device. Free up space, then try again.';

  @override
  String get downloadUnavailableTitle => 'Some tracks can’t be downloaded';

  @override
  String get downloadUnavailableOther => 'Not available';

  @override
  String get libraryTabDownloads => 'Downloads';

  @override
  String downloadsSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0 · $size';
  }

  @override
  String downloadsInProgressCount(int count) {
    return '$count in progress';
  }

  @override
  String get downloadsFilterInProgress => 'In progress';

  @override
  String get downloadsPauseAll => 'Pause all';

  @override
  String get downloadsResumeAll => 'Resume all';

  @override
  String get downloadsEmpty =>
      'Nothing downloaded yet. Choose Download on an album, a playlist or a song to keep it on this device.';

  @override
  String get downloadsWaitingForConnection => 'Waiting for connection';

  @override
  String get downloadsSourceGone => 'No longer on the server';

  @override
  String get downloadsKindAlbum => 'Album';

  @override
  String get downloadsKindPlaylist => 'Playlist';

  @override
  String get downloadsKindTrack => 'Song';

  @override
  String get downloadsKindEpisode => 'Episode';

  @override
  String downloadsEpisodeSubtitle(String podcast) {
    return 'Episode · $podcast';
  }

  @override
  String downloadsItemsProgress(String kind, int completed, int total) {
    return '$kind · $completed of $total';
  }

  @override
  String get downloadsPause => 'Pause';

  @override
  String get downloadsResume => 'Resume';

  @override
  String get listenTogetherTitle => 'Listen Together';

  @override
  String get listenTogetherInGroup => 'In a group';

  @override
  String get listenTogetherYourGroups => 'Your groups';

  @override
  String get listenTogetherPublicGroups => 'Public groups';

  @override
  String get listenTogetherEmpty => 'Listen with others in sync';

  @override
  String get listenTogetherCreate => 'Create group';

  @override
  String get listenTogetherJoinWithCode => 'Join with a code';

  @override
  String get listenTogetherJoin => 'Join';

  @override
  String listenTogetherGroupRowDetails(String host, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$host · $_temp0';
  }

  @override
  String get listenTogetherNameLabel => 'Name (optional)';

  @override
  String get listenTogetherNameTooLong => 'Use at most 80 characters';

  @override
  String get listenTogetherPrivate => 'Private';

  @override
  String get listenTogetherPublic => 'Public';

  @override
  String get listenTogetherStartWithQueue => 'Start with my current queue';

  @override
  String get listenTogetherCreateSubmit => 'Create';

  @override
  String get listenTogetherCancel => 'Cancel';

  @override
  String get listenTogetherCodeLabel => 'Group code';

  @override
  String get listenTogetherNoGroupWithCode => 'No group with that code';

  @override
  String get listenTogetherPublicGroup => 'Public group';

  @override
  String get listenTogetherPrivateGroup => 'Private group';

  @override
  String listenTogetherHostedBy(String name) {
    return 'Hosted by $name';
  }

  @override
  String get listenTogetherReconnecting => 'Reconnecting…';

  @override
  String get listenTogetherCopyCode => 'Copy code';

  @override
  String get listenTogetherCopied => 'Copied';

  @override
  String get listenTogetherMembers => 'Members';

  @override
  String get listenTogetherHost => 'Host';

  @override
  String get listenTogetherNowPlaying => 'Now playing';

  @override
  String get listenTogetherOpenQueue => 'Open queue';

  @override
  String get listenTogetherLeave => 'Leave group';

  @override
  String get listenTogetherEnd => 'End group for everyone';

  @override
  String get listenTogetherEndTitle => 'End the group?';

  @override
  String get listenTogetherEndBody =>
      'Everyone leaves the group and playback stops for them.';

  @override
  String get listenTogetherEndConfirm => 'End group';

  @override
  String get listenTogetherEndedByHost => 'The host ended the group';

  @override
  String get listenTogetherRemoved => 'You were removed from the group';

  @override
  String listenTogetherQueueHeader(String name, int count) {
    return '$name · $count listening';
  }

  @override
  String get listenTogetherHostControls => 'The host controls playback';

  @override
  String get listenTogetherNoResponse => 'The server didn’t respond';

  @override
  String get listenTogetherCommandRejected => 'The group didn’t accept that';

  @override
  String get listenTogetherNotInGroup => 'Not available while in a group';

  @override
  String listenTogetherNotShareable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items can’t be shared with the group',
      one: '1 item can’t be shared with the group',
    );
    return '$_temp0';
  }

  @override
  String get listenTogetherReplaceTitle => 'Replace the group’s queue?';

  @override
  String get listenTogetherReplaceBody =>
      'Everyone in the group hears this next.';

  @override
  String get listenTogetherReplaceConfirm => 'Replace';

  @override
  String get mixOverline => 'Mix';

  @override
  String get mixEmpty => 'This mix has no tracks right now';

  @override
  String get mixNotAvailable => 'Not available on this server';

  @override
  String get actionSaveAsPlaylist => 'Save as playlist';

  @override
  String get mixSaveTitle => 'Save as playlist';

  @override
  String get mixSaveConfirm => 'Save';

  @override
  String get mixSaved => 'Saved to your playlists';

  @override
  String get mixSavedOpen => 'Open';

  @override
  String get libraryDownloadedOnly => 'Downloaded only';

  @override
  String get trackNotAvailableOffline => 'Not available offline';

  @override
  String get offlineBannerGoOnline => 'Go online';

  @override
  String get shellMenuOfflineMode => 'Offline mode';

  @override
  String get searchResultsFromDevice => 'Results from this device';

  @override
  String windowTitleNowPlaying(String title, String artist) {
    return '$title — $artist · soundspan';
  }

  @override
  String get trayPlay => 'Play';

  @override
  String get trayPause => 'Pause';

  @override
  String get trayShowWindow => 'Show window';

  @override
  String get trayQuit => 'Quit';

  @override
  String trayNowPlaying(String title, String artist) {
    return '$title — $artist';
  }

  @override
  String get settingsCloseToTray => 'Close to tray';

  @override
  String get settingsCloseToTrayUnavailable => 'No system tray was found';

  @override
  String get settingsUpdateCheck => 'Check for new versions';

  @override
  String get settingsUpdateCheckCaption =>
      'Asks GitHub for the list of soundspan releases once a day.';

  @override
  String updateBannerMessage(String version) {
    return 'soundspan $version is available';
  }

  @override
  String get updateViewRelease => 'View release';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get settingsAboutCheckNow => 'Check now';

  @override
  String get closeKeepPlayingTitle => 'Keep playing in the background?';

  @override
  String get closeKeepPlaying => 'Keep playing';

  @override
  String get closeQuit => 'Quit';

  @override
  String get menuSettings => 'Settings…';

  @override
  String get menuQuit => 'Quit soundspan';

  @override
  String get menuPlayback => 'Playback';

  @override
  String get menuView => 'View';

  @override
  String get menuWindow => 'Window';

  @override
  String get menuPlayPause => 'Play/Pause';

  @override
  String get menuNext => 'Next';

  @override
  String get menuPrevious => 'Previous';

  @override
  String get menuShuffle => 'Shuffle';

  @override
  String get menuRepeat => 'Repeat';

  @override
  String get menuQueue => 'Queue';

  @override
  String get menuLyrics => 'Lyrics';

  @override
  String get navVibe => 'Vibe';

  @override
  String get homeVibeCard => 'Tracks that sound like what you play';

  @override
  String get menuStartRadio => 'Start radio';

  @override
  String get vibeNoSimilar => 'No similar tracks found';

  @override
  String get vibeSearchHint => 'Describe a sound or a mood';

  @override
  String get vibeSearchLabel => 'Search by description';

  @override
  String get vibeSearchClear => 'Clear';

  @override
  String get vibePlayAll => 'Play all';

  @override
  String get vibeSimilarTitle => 'Similar to what’s playing';

  @override
  String get vibeNoMatches => 'No matches';

  @override
  String get vibeExplain =>
      'Play a track to see others that sound like it here.';

  @override
  String get vibeSearchUnavailable => 'Vibe search is unavailable right now';
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
  String get androidAutoRecent => '[Ŕéçéñţ one]';

  @override
  String get androidAutoPlaylists => '[Þļåýļîšţš one]';

  @override
  String get androidAutoAlbums => '[Åļbûmš one]';

  @override
  String get androidAutoDownloads => '[Ðöŵñļöåðš one]';

  @override
  String androidAutoDownloadsSubtitle(String kind, int completed) {
    return '[$kind · $completed one]';
  }

  @override
  String downloadsNotificationTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ðöŵñļöåðîñĝ $count îţémš one two',
      one: 'Ðöŵñļöåðîñĝ 1 îţém one two',
    );
    return '[$_temp0]';
  }

  @override
  String get downloadsNotificationFinished => '[Ðöŵñļöåðš fîñîšĥéð one two]';

  @override
  String get androidAutoKindEpisode => '[Þöðçåšţ éþîšöðé one two]';

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
  String get screenMix => '[Mîx one]';

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
  String get shellActivity => '[Åçţîvîţý one]';

  @override
  String get shellMenuActivity => '[Åçţîvîţý one]';

  @override
  String get activityTitle => '[Åçţîvîţý one]';

  @override
  String get activityOnThisServer => '[Öñ ţĥîš šéŕvéŕ one two]';

  @override
  String get activityOnConnectedServers => '[Öñ çöññéçţéð šéŕvéŕš one two]';

  @override
  String get activityStatusPlaying => '[Þļåýîñĝ one]';

  @override
  String get activityStatusPaused => '[Þåûšéð one]';

  @override
  String get activityStatusIdle => '[Îðļé one]';

  @override
  String activityPeerStatus(String status, String server) {
    return '[$status öñ $server one]';
  }

  @override
  String activityTrack(String title, String artist) {
    return '[$title · $artist one]';
  }

  @override
  String get activityEmpty => '[Ñöböðý éļšé îš öñļîñé one two three]';

  @override
  String activityRowPlaying(String name, String title, String artist) {
    return '[$name, þļåýîñĝ $title bý $artist one two]';
  }

  @override
  String activityRowPaused(String name, String title, String artist) {
    return '[$name, þåûšéð öñ $title bý $artist one two]';
  }

  @override
  String activityRowStatus(String name, String status) {
    return '[$name, $status one]';
  }

  @override
  String activityRowPeer(String label, String server) {
    return '[$label, öñ $server one]';
  }

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
  String get settingsPlaybackQualityWifi => '[Qûåļîţý öñ Ŵî-Fî one two]';

  @override
  String get settingsPlaybackQualityCellular =>
      '[Qûåļîţý öñ möbîļé ðåţå one two three]';

  @override
  String get settingsPlaybackQualitySingle => '[Šţŕéåmîñĝ qûåļîţý one two]';

  @override
  String get settingsPlaybackQualityCaption =>
      '[Qûåļîţý çĥåñĝéš åþþļý fŕöm ţĥé ñéxţ îţém ţĥåţ šţåŕţš. one two three four five]';

  @override
  String get settingsPlaybackQualityServerDefault => '[Šéŕvéŕ ðéfåûļţ one two]';

  @override
  String get settingsPlaybackQualityServerDefaultCaption =>
      '[Ţĥé qûåļîţý šåvéð öñ ţĥé šéŕvéŕ åþþļîéš. one two three four]';

  @override
  String get settingsPlaybackQualityOriginal => '[Öŕîĝîñåļ one]';

  @override
  String get settingsPlaybackQualityHigh => '[Ĥîĝĥ one]';

  @override
  String get settingsPlaybackQualityMedium => '[Méðîûm one]';

  @override
  String get settingsPlaybackQualityLow => '[Ļöŵ one]';

  @override
  String get settingsPlaybackLevelling => '[Vöļûmé ļévéļļîñĝ one two]';

  @override
  String get settingsPlaybackLevellingOff => '[Öff one]';

  @override
  String get settingsPlaybackLevellingTrack => '[Ţŕåçķ one]';

  @override
  String get settingsPlaybackLevellingAlbum => '[Åļbûm one]';

  @override
  String get settingsPlaybackLevellingAuto => '[Åûţömåţîç one]';

  @override
  String get settingsPlaybackLevellingUnknown => '[Ûñķñöŵñ one]';

  @override
  String get settingsPlaybackLevellingOffline =>
      '[Åvåîļåbļé ŵĥéñ ţĥé šéŕvéŕ çåñ bé ŕéåçĥéð one two three four]';

  @override
  String get settingsPlaybackLevellingFailed =>
      '[Çöûļðñ’ţ çĥåñĝé vöļûmé ļévéļļîñĝ one two three]';

  @override
  String get settingsPlaybackSkipInterval =>
      '[Šķîþ îñţéŕvåļ (þöðçåšţš) one two three]';

  @override
  String get settingsPlaybackSpeed =>
      '[Ðéfåûļţ šþééð (þöðçåšţš) one two three]';

  @override
  String settingsPlaybackSkipSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds šéçöñðš one',
      one: '1 šéçöñð one',
    );
    return '[$_temp0]';
  }

  @override
  String settingsPlaybackSpeedValue(double speed) {
    final intl.NumberFormat speedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String speedString = speedNumberFormat.format(speed);

    return '[$speedString× one]';
  }

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
  String get settingsServersSignOut => '[Šîĝñ öûţ one]';

  @override
  String get settingsServersRemove => '[Ŕémövé ţĥîš šéŕvéŕ one two]';

  @override
  String settingsServersSignOutTitle(String server) {
    return '[Šîĝñ öûţ öf $server? one two]';
  }

  @override
  String get settingsServersSignOutBody =>
      '[Ðöŵñļöåðš, çåçĥéð ðåţå åñð çĥåñĝéš ñöţ ýéţ šéñţ šţåý öñ ţĥîš ðévîçé. Šîĝñ îñ åĝåîñ ţö ûšé ţĥîš šéŕvéŕ. one two three four five six seven eight nine]';

  @override
  String settingsServersSignOutRemoveDownloads(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Åļšö ŕémövé ðöŵñļöåðš ($count îţémš, $size) one two three',
      one: 'Åļšö ŕémövé ðöŵñļöåðš (1 îţém, $size) one two three',
    );
    return '[$_temp0]';
  }

  @override
  String settingsServersRemoveTitle(String server) {
    return '[Ŕémövé $server? one]';
  }

  @override
  String settingsServersRemoveBody(String server) {
    return '[Ţĥîš šîĝñš öûţ åñð ðéļéţéš évéŕýţĥîñĝ ţĥîš åþþ šţöŕéš föŕ $server öñ ţĥîš ðévîçé, ðöŵñļöåðš îñçļûðéð. one two three four five six seven eight]';
  }

  @override
  String settingsServersRemovePending(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count çĥåñĝéš ĥåvé ñöţ bééñ šéñţ ţö ţĥé šéŕvéŕ åñð ŵîļļ bé ļöšţ. one two three four five',
      one: '1 çĥåñĝé ĥåš ñöţ bééñ šéñţ ţö ţĥé šéŕvéŕ åñð ŵîļļ bé ļöšţ. one two three four five',
    );
    return '[$_temp0]';
  }

  @override
  String get settingsServersRemoveDownloads =>
      '[Ðöŵñļöåðš öñ ţĥîš ðévîçé föŕ ţĥîš šéŕvéŕ ŵîļļ bé ðéļéţéð. one two three four five]';

  @override
  String get settingsServersRemoveConfirm => '[Ŕémövé one]';

  @override
  String get settingsServersRemoveAnyway => '[Ŕémövé åñýŵåý one two]';

  @override
  String get settingsServersSigningOut => '[Šîĝñîñĝ öûţ… one two]';

  @override
  String get settingsServersRemoving => '[Ŕémövîñĝ… one]';

  @override
  String get settingsServersExitFailed =>
      '[Ţĥé šîĝñ-îñ ðéţåîļš öñ ţĥîš ðévîçé çöûļð ñöţ bé ðéļéţéð. Ţŕý åĝåîñ. one two three four five six]';

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
  String get twoPaneSelectItem => '[Šéļéçţ åñ îţém one two]';

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
  String dragTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåçķš one',
      one: '1 ţŕåçķ one',
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
  String get homeExploreCard => '[Fîñð ñéŵ åŕţîšţš åñð mûšîç one two three]';

  @override
  String get exploreRadioByGenre => '[Ŕåðîö bý ĝéñŕé one two]';

  @override
  String get exploreRadioByDecade => '[Ŕåðîö bý ðéçåðé one two]';

  @override
  String get exploreRadioShowAll => '[Šĥöŵ åļļ one]';

  @override
  String exploreRadioDecade(String decade) {
    return '[$decadeš one]';
  }

  @override
  String exploreRadioTrackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ţŕåçķš one',
      one: '1 ţŕåçķ one',
    );
    return '[$_temp0]';
  }

  @override
  String exploreRadioStationSemantics(String station, String tracks) {
    return '[$station, $tracks, ŕåðîö šţåţîöñ one two]';
  }

  @override
  String get exploreRadioNoTracks =>
      '[Ñö ţŕåçķš föŕ ţĥîš šţåţîöñ one two three]';

  @override
  String get exploreRadioFailed => '[Çöûļðñ’ţ šţåŕţ ţĥé šţåţîöñ one two three]';

  @override
  String get exploreRadioRetry => '[Ŕéţŕý one]';

  @override
  String get exploreRadioOffline => '[Ñöţ åvåîļåbļé öffļîñé one two three]';

  @override
  String queueContextRadio(String station) {
    return '[Ŕåðîö · $station one]';
  }

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
  String playerSkipBack(int seconds) {
    return '[Šķîþ båçķ $seconds šéçöñðš one two]';
  }

  @override
  String playerSkipForward(int seconds) {
    return '[Šķîþ föŕŵåŕð $seconds šéçöñðš one two three]';
  }

  @override
  String get playerSpeed => '[Þļåýbåçķ šþééð one two]';

  @override
  String playerSpeedValue(double speed) {
    final intl.NumberFormat speedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String speedString = speedNumberFormat.format(speed);

    return '[$speedString× one]';
  }

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
  String get nowPlayingAudioOutput => '[Åûðîö öûţþûţ one two]';

  @override
  String get nowPlayingExpand => '[Šĥöŵ ñöŵ þļåýîñĝ one two]';

  @override
  String get nowPlayingCollapse => '[Ĥîðé ñöŵ þļåýîñĝ one two]';

  @override
  String get lyricsTitle => '[Ļýŕîçš one]';

  @override
  String get lyricsNone => '[Ñö ļýŕîçš föûñð one two]';

  @override
  String lyricsSeekHint(String time) {
    return '[Šééķ ţö $time one]';
  }

  @override
  String get lyricsInstrumental => '[Îñšţŕûméñţåļ one two]';

  @override
  String get lyricsResumeAutoScroll => '[Ŕéšûmé åûţö-šçŕöļļ one two]';

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

  @override
  String get qualityBadgeDownloaded => '[Ðöŵñļöåðéð one]';

  @override
  String qualityBadgeDownloadedQuality(String quality) {
    return '[Ðöŵñļöåðéð · $quality one two]';
  }

  @override
  String get menuPlayNow => '[Þļåý ñöŵ one]';

  @override
  String get menuPlayNext => '[Þļåý ñéxţ one]';

  @override
  String get menuAddToQueue => '[Åðð ţö qûéûé one two]';

  @override
  String get menuAddToPlaylist => '[Åðð ţö þļåýļîšţ… one two]';

  @override
  String get menuRemoveFromPlaylist =>
      '[Ŕémövé fŕöm ţĥîš þļåýļîšţ one two three]';

  @override
  String get menuGoToAlbum => '[Ĝö ţö åļbûm one two]';

  @override
  String get menuGoToArtist => '[Ĝö ţö åŕţîšţ one two]';

  @override
  String get menuShareLink => '[Šĥåŕé ļîñķ one]';

  @override
  String get menuLinkCopied => '[Ļîñķ çöþîéð one two]';

  @override
  String get menuRename => '[Ŕéñåmé one]';

  @override
  String get menuDelete => '[Ðéļéţé one]';

  @override
  String get menuMoreOptions => '[Möŕé öþţîöñš one two]';

  @override
  String get actionPlay => '[Þļåý one]';

  @override
  String get actionShuffle => '[Šĥûffļé one]';

  @override
  String get actionAddToPlaylist => '[Åðð ţö þļåýļîšţ one two]';

  @override
  String get screenSettingsDesktop => '[Ðéšķţöþ one]';

  @override
  String get settingsShortcutsTitle => '[Ķéýböåŕð šĥöŕţçûţš one two]';

  @override
  String get shortcutPlayPause => '[Þļåý öŕ þåûšé one two]';

  @override
  String get shortcutNext => '[Ñéxţ ţŕåçķ one]';

  @override
  String get shortcutPrevious => '[Þŕévîöûš ţŕåçķ one two]';

  @override
  String shortcutSeekForward(int seconds) {
    return '[Šééķ föŕŵåŕð $seconds šéçöñðš one two three]';
  }

  @override
  String shortcutSeekBack(int seconds) {
    return '[Šééķ båçķ $seconds šéçöñðš one two]';
  }

  @override
  String get shortcutVolumeUp => '[Vöļûmé ûþ one]';

  @override
  String get shortcutVolumeDown => '[Vöļûmé ðöŵñ one two]';

  @override
  String get shortcutShuffle => '[Šĥûffļé öñ öŕ öff one two]';

  @override
  String get shortcutRepeat => '[Çĥåñĝé ŕéþéåţ one two]';

  @override
  String get shortcutLike =>
      '[Ļîķé öŕ ŕémövé ļîķé öf ţĥé çûŕŕéñţ ţŕåçķ one two three four]';

  @override
  String get shortcutSearch => '[Šéåŕçĥ one]';

  @override
  String shortcutGoTo(String destination) {
    return '[Ĝö ţö $destination one]';
  }

  @override
  String get shortcutQueue => '[Šĥöŵ öŕ ĥîðé ţĥé qûéûé one two three]';

  @override
  String get shortcutPlayRow => '[Þļåý ţĥé šéļéçţéð ţŕåçķš one two three]';

  @override
  String get shortcutPlayRowNext =>
      '[Þļåý ţĥé šéļéçţéð ţŕåçķš ñéxţ one two three]';

  @override
  String get shortcutRemoveRow =>
      '[Ŕémövé ţĥé šéļéçţéð ţŕåçķš fŕöm ţĥé þļåýļîšţ one two three four]';

  @override
  String get shortcutMenu =>
      '[Öþéñ ţĥé méñû öf ţĥé föçûšéð îţém one two three]';

  @override
  String get shortcutRefresh => '[Ŕéfŕéšĥ one]';

  @override
  String get shortcutNextArea => '[Ñéxţ åŕéå one]';

  @override
  String get shortcutPreviousArea => '[Þŕévîöûš åŕéå one two]';

  @override
  String get keyCtrl => '[Çţŕļ one]';

  @override
  String get keyCmd => '[Çmð one]';

  @override
  String get keyShift => '[Šĥîfţ one]';

  @override
  String get keyAlt => '[Åļţ one]';

  @override
  String get keyOption => '[Öþţîöñ one]';

  @override
  String get keySpace => '[Šþåçé one]';

  @override
  String get keyEnter => '[Éñţéŕ one]';

  @override
  String get keyDelete => '[Ðéļéţé one]';

  @override
  String get keyMenu => '[Méñû one]';

  @override
  String get keyMouseBack => '[Möûšé båçķ bûţţöñ one two]';

  @override
  String get keyMouseForward => '[Möûšé föŕŵåŕð bûţţöñ one two]';

  @override
  String get settingsStorageDownloads => '[Ðöŵñļöåðš one]';

  @override
  String get settingsStorageDownloadQuality => '[Ðöŵñļöåð qûåļîţý one two]';

  @override
  String get settingsStorageDownloadQualityCaption =>
      '[Ţĥé qûåļîţý åþþļîéš ţö ñéŵ ðöŵñļöåðš. one two three four]';

  @override
  String get settingsStorageWifiOnly =>
      '[Ðöŵñļöåð öñ Ŵî-Fî öñļý one two three]';

  @override
  String get settingsStorageDeviceLimit => '[Ðévîçé ļîmîţ one two]';

  @override
  String get settingsStorageNoLimit => '[Ñö ļîmîţ one]';

  @override
  String settingsStorageDeviceLimitUsage(String used, String limit) {
    return '[$used öf $limit ûšéð one]';
  }

  @override
  String settingsStorageDeviceLimitUsageUnlimited(String used) {
    return '[$used ûšéð, ñö ļîmîţ one two]';
  }

  @override
  String get settingsStorageRemoveAll => '[Ŕémövé åļļ ðöŵñļöåðš one two]';

  @override
  String get settingsStorageRemoveAllTitle =>
      '[Ŕémövé åļļ ðöŵñļöåðš? one two three]';

  @override
  String settingsStorageRemoveAllBody(String size) {
    return '[Ţĥîš fŕééš $size öñ ţĥîš ðévîçé. Ýöû çåñ ðöŵñļöåð ţĥém åĝåîñ ļåţéŕ. one two three four five six]';
  }

  @override
  String get settingsStorageRemoveAllConfirm => '[Ŕémövé one]';

  @override
  String get settingsStorageThisDevice => '[Ţĥîš ðévîçé one two]';

  @override
  String get settingsStorageUsageDownloads => '[Ðöŵñļöåðš one]';

  @override
  String settingsStorageUsageDownloadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count îţémš one',
      one: '1 îţém one',
    );
    return '[$_temp0]';
  }

  @override
  String get settingsStorageUsageImages => '[Îmåĝéš one]';

  @override
  String get settingsStorageUsageDatabase => '[Ðåţåbåšé one]';

  @override
  String get settingsStorageUsageFree => '[Fŕéé šþåçé one]';

  @override
  String get settingsStorageServer => '[Šéŕvéŕ one]';

  @override
  String settingsStorageServerUsed(String used, String limit) {
    return '[Ûšéð öñ ţĥé šéŕvéŕ: $used öf $limit one two three]';
  }

  @override
  String settingsStorageServerDevice(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Fŕöm ţĥîš ðévîçé: $size, $count ţŕåçķš one two three',
      one: 'Fŕöm ţĥîš ðévîçé: $size, 1 ţŕåçķ one two three',
    );
    return '[$_temp0]';
  }

  @override
  String get settingsStorageServerCaption =>
      '[Ţĥé šéŕvéŕ ļîmîţ îš çĥåñĝéð îñ ţĥé šéŕvéŕ’š šéţţîñĝš. one two three four five]';

  @override
  String get settingsStorageCache => '[Çåçĥé one]';

  @override
  String get settingsStorageClearCache => '[Çļéåŕ çåçĥé one two]';

  @override
  String get settingsStorageClearCacheCaption =>
      '[Šåvéð îmåĝéš åñð bŕöŵšîñĝ ðåţå åŕé féţçĥéð åĝåîñ ŵĥéñ ñééðéð. Ðöŵñļöåðš šţåý. one two three four five six seven]';

  @override
  String get settingsStorageClearCacheTitle => '[Çļéåŕ çåçĥé? one two]';

  @override
  String get settingsStorageClearCacheBody =>
      '[Šåvéð îmåĝéš åñð bŕöŵšîñĝ ðåţå åŕé ðéļéţéð. Ðöŵñļöåðš åñð þļåýbåçķ åŕé ñöţ åfféçţéð. one two three four five six seven]';

  @override
  String get settingsStorageClearCacheConfirm => '[Çļéåŕ one]';

  @override
  String get settingsStorageCancel => '[Çåñçéļ one]';

  @override
  String get downloadGlyphQueued => '[Ŵåîţîñĝ ţö ðöŵñļöåð one two]';

  @override
  String downloadGlyphRunning(int percent) {
    return '[Ðöŵñļöåðîñĝ, $percent þéŕçéñţ one two three]';
  }

  @override
  String get downloadGlyphRunningUnknown => '[Ðöŵñļöåðîñĝ one two]';

  @override
  String get downloadGlyphCompleted => '[Ðöŵñļöåðéð one]';

  @override
  String get downloadGlyphFailed => '[Ðöŵñļöåð fåîļéð one two]';

  @override
  String get downloadGlyphUnavailable =>
      '[Ñöţ åvåîļåbļé föŕ ðöŵñļöåð one two three]';

  @override
  String get trackRowDownloaded => '[ðöŵñļöåðéð one]';

  @override
  String get menuDownload => '[Ðöŵñļöåð one]';

  @override
  String get menuRemoveDownload => '[Ŕémövé ðöŵñļöåð one two]';

  @override
  String get menuRetryDownload => '[Ŕéţŕý ðöŵñļöåð one two]';

  @override
  String get menuCheckForChanges => '[Çĥéçķ föŕ çĥåñĝéš one two]';

  @override
  String get downloadRemoveTitle => '[Ŕémövé ðöŵñļöåð? one two]';

  @override
  String get downloadRemoveBody =>
      '[Îţš fîļéš åŕé ðéļéţéð fŕöm ţĥîš ðévîçé. Ýöû çåñ ðöŵñļöåð îţ åĝåîñ ļåţéŕ. one two three four five six seven]';

  @override
  String get downloadRemoveConfirm => '[Ŕémövé one]';

  @override
  String get downloadCancel => '[Çåñçéļ one]';

  @override
  String get downloadClose => '[Çļöšé one]';

  @override
  String get downloadServerQuotaTitle =>
      '[Ñöţ éñöûĝĥ šþåçé öñ ţĥé šéŕvéŕ one two three]';

  @override
  String get downloadServerQuotaBody =>
      '[Ŕémövé ðöŵñļöåðš ţö fŕéé ûþ šþåçé, öŕ ŕåîšé ţĥé ðöŵñļöåð ļîmîţ îñ ţĥé šéŕvéŕ’š šéţţîñĝš. one two three four five six seven eight]';

  @override
  String downloadSizeNeeded(String size) {
    return '[Ñééðéð: $size one]';
  }

  @override
  String downloadSizeUsed(String size) {
    return '[Ûšéð: $size one]';
  }

  @override
  String downloadSizeLimit(String size) {
    return '[Ļîmîţ: $size one]';
  }

  @override
  String downloadSizeAvailable(String size) {
    return '[Åvåîļåbļé: $size one two]';
  }

  @override
  String get downloadManage => '[Måñåĝé ðöŵñļöåðš one two]';

  @override
  String downloadShortfallTitle(String size) {
    return '[$size möŕé ñééðéð öñ ţĥîš ðévîçé one two three]';
  }

  @override
  String get downloadRaiseLimit => '[Ŕåîšé ļîmîţ one two]';

  @override
  String get downloadWhatFits => '[Ðöŵñļöåð ŵĥåţ fîţš one two]';

  @override
  String get downloadRaiseLimitDiskFull =>
      '[Ţĥéŕé îšñ’ţ éñöûĝĥ fŕéé šþåçé öñ ţĥîš ðévîçé. Fŕéé ûþ šþåçé, ţĥéñ ţŕý åĝåîñ. one two three four five six seven]';

  @override
  String get downloadUnavailableTitle =>
      '[Šömé ţŕåçķš çåñ’ţ bé ðöŵñļöåðéð one two three]';

  @override
  String get downloadUnavailableOther => '[Ñöţ åvåîļåbļé one two]';

  @override
  String get libraryTabDownloads => '[Ðöŵñļöåðš one]';

  @override
  String downloadsSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count îţémš one',
      one: '1 îţém one',
      zero: 'Ñö îţémš one',
    );
    return '[$_temp0 · $size one]';
  }

  @override
  String downloadsInProgressCount(int count) {
    return '[$count îñ þŕöĝŕéšš one two]';
  }

  @override
  String get downloadsFilterInProgress => '[Îñ þŕöĝŕéšš one two]';

  @override
  String get downloadsPauseAll => '[Þåûšé åļļ one]';

  @override
  String get downloadsResumeAll => '[Ŕéšûmé åļļ one]';

  @override
  String get downloadsEmpty =>
      '[Ñöţĥîñĝ ðöŵñļöåðéð ýéţ. Çĥööšé Ðöŵñļöåð öñ åñ åļbûm, å þļåýļîšţ öŕ å šöñĝ ţö ķééþ îţ öñ ţĥîš ðévîçé. one two three four five six seven eight]';

  @override
  String get downloadsWaitingForConnection =>
      '[Ŵåîţîñĝ föŕ çöññéçţîöñ one two three]';

  @override
  String get downloadsSourceGone => '[Ñö ļöñĝéŕ öñ ţĥé šéŕvéŕ one two three]';

  @override
  String get downloadsKindAlbum => '[Åļbûm one]';

  @override
  String get downloadsKindPlaylist => '[Þļåýļîšţ one]';

  @override
  String get downloadsKindTrack => '[Šöñĝ one]';

  @override
  String get downloadsKindEpisode => '[Éþîšöðé one]';

  @override
  String downloadsEpisodeSubtitle(String podcast) {
    return '[Éþîšöðé · $podcast one]';
  }

  @override
  String downloadsItemsProgress(String kind, int completed, int total) {
    return '[$kind · $completed öf $total one]';
  }

  @override
  String get downloadsPause => '[Þåûšé one]';

  @override
  String get downloadsResume => '[Ŕéšûmé one]';

  @override
  String get listenTogetherTitle => '[Ļîšţéñ Ţöĝéţĥéŕ one two]';

  @override
  String get listenTogetherInGroup => '[Îñ å ĝŕöûþ one]';

  @override
  String get listenTogetherYourGroups => '[Ýöûŕ ĝŕöûþš one two]';

  @override
  String get listenTogetherPublicGroups => '[Þûbļîç ĝŕöûþš one two]';

  @override
  String get listenTogetherEmpty =>
      '[Ļîšţéñ ŵîţĥ öţĥéŕš îñ šýñç one two three]';

  @override
  String get listenTogetherCreate => '[Çŕéåţé ĝŕöûþ one two]';

  @override
  String get listenTogetherJoinWithCode => '[Ĵöîñ ŵîţĥ å çöðé one two]';

  @override
  String get listenTogetherJoin => '[Ĵöîñ one]';

  @override
  String listenTogetherGroupRowDetails(String host, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mémbéŕš one',
      one: '1 mémbéŕ one',
    );
    return '[$host · $_temp0 one]';
  }

  @override
  String get listenTogetherNameLabel => '[Ñåmé (öþţîöñåļ) one two]';

  @override
  String get listenTogetherNameTooLong =>
      '[Ûšé åţ möšţ 80 çĥåŕåçţéŕš one two three]';

  @override
  String get listenTogetherPrivate => '[Þŕîvåţé one]';

  @override
  String get listenTogetherPublic => '[Þûbļîç one]';

  @override
  String get listenTogetherStartWithQueue =>
      '[Šţåŕţ ŵîţĥ mý çûŕŕéñţ qûéûé one two three]';

  @override
  String get listenTogetherCreateSubmit => '[Çŕéåţé one]';

  @override
  String get listenTogetherCancel => '[Çåñçéļ one]';

  @override
  String get listenTogetherCodeLabel => '[Ĝŕöûþ çöðé one]';

  @override
  String get listenTogetherNoGroupWithCode =>
      '[Ñö ĝŕöûþ ŵîţĥ ţĥåţ çöðé one two three]';

  @override
  String get listenTogetherPublicGroup => '[Þûbļîç ĝŕöûþ one two]';

  @override
  String get listenTogetherPrivateGroup => '[Þŕîvåţé ĝŕöûþ one two]';

  @override
  String listenTogetherHostedBy(String name) {
    return '[Ĥöšţéð bý $name one]';
  }

  @override
  String get listenTogetherReconnecting => '[Ŕéçöññéçţîñĝ… one two]';

  @override
  String get listenTogetherCopyCode => '[Çöþý çöðé one]';

  @override
  String get listenTogetherCopied => '[Çöþîéð one]';

  @override
  String get listenTogetherMembers => '[Mémbéŕš one]';

  @override
  String get listenTogetherHost => '[Ĥöšţ one]';

  @override
  String get listenTogetherNowPlaying => '[Ñöŵ þļåýîñĝ one two]';

  @override
  String get listenTogetherOpenQueue => '[Öþéñ qûéûé one]';

  @override
  String get listenTogetherLeave => '[Ļéåvé ĝŕöûþ one two]';

  @override
  String get listenTogetherEnd => '[Éñð ĝŕöûþ föŕ évéŕýöñé one two three]';

  @override
  String get listenTogetherEndTitle => '[Éñð ţĥé ĝŕöûþ? one two]';

  @override
  String get listenTogetherEndBody =>
      '[Évéŕýöñé ļéåvéš ţĥé ĝŕöûþ åñð þļåýbåçķ šţöþš föŕ ţĥém. one two three four five]';

  @override
  String get listenTogetherEndConfirm => '[Éñð ĝŕöûþ one]';

  @override
  String get listenTogetherEndedByHost =>
      '[Ţĥé ĥöšţ éñðéð ţĥé ĝŕöûþ one two three]';

  @override
  String get listenTogetherRemoved =>
      '[Ýöû ŵéŕé ŕémövéð fŕöm ţĥé ĝŕöûþ one two three]';

  @override
  String listenTogetherQueueHeader(String name, int count) {
    return '[$name · $count ļîšţéñîñĝ one two]';
  }

  @override
  String get listenTogetherHostControls =>
      '[Ţĥé ĥöšţ çöñţŕöļš þļåýbåçķ one two three]';

  @override
  String get listenTogetherNoResponse =>
      '[Ţĥé šéŕvéŕ ðîðñ’ţ ŕéšþöñð one two three]';

  @override
  String get listenTogetherCommandRejected =>
      '[Ţĥé ĝŕöûþ ðîðñ’ţ åççéþţ ţĥåţ one two three]';

  @override
  String get listenTogetherNotInGroup =>
      '[Ñöţ åvåîļåbļé ŵĥîļé îñ å ĝŕöûþ one two three]';

  @override
  String listenTogetherNotShareable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count îţémš çåñ’ţ bé šĥåŕéð ŵîţĥ ţĥé ĝŕöûþ one two three four',
      one: '1 îţém çåñ’ţ bé šĥåŕéð ŵîţĥ ţĥé ĝŕöûþ one two three four',
    );
    return '[$_temp0]';
  }

  @override
  String get listenTogetherReplaceTitle =>
      '[Ŕéþļåçé ţĥé ĝŕöûþ’š qûéûé? one two three]';

  @override
  String get listenTogetherReplaceBody =>
      '[Évéŕýöñé îñ ţĥé ĝŕöûþ ĥéåŕš ţĥîš ñéxţ. one two three four]';

  @override
  String get listenTogetherReplaceConfirm => '[Ŕéþļåçé one]';

  @override
  String get mixOverline => '[Mîx one]';

  @override
  String get mixEmpty => '[Ţĥîš mîx ĥåš ñö ţŕåçķš ŕîĝĥţ ñöŵ one two three]';

  @override
  String get mixNotAvailable => '[Ñöţ åvåîļåbļé öñ ţĥîš šéŕvéŕ one two three]';

  @override
  String get actionSaveAsPlaylist => '[Šåvé åš þļåýļîšţ one two]';

  @override
  String get mixSaveTitle => '[Šåvé åš þļåýļîšţ one two]';

  @override
  String get mixSaveConfirm => '[Šåvé one]';

  @override
  String get mixSaved => '[Šåvéð ţö ýöûŕ þļåýļîšţš one two three]';

  @override
  String get mixSavedOpen => '[Öþéñ one]';

  @override
  String get libraryDownloadedOnly => '[Ðöŵñļöåðéð öñļý one two]';

  @override
  String get trackNotAvailableOffline =>
      '[Ñöţ åvåîļåbļé öffļîñé one two three]';

  @override
  String get offlineBannerGoOnline => '[Ĝö öñļîñé one]';

  @override
  String get shellMenuOfflineMode => '[Öffļîñé möðé one two]';

  @override
  String get searchResultsFromDevice =>
      '[Ŕéšûļţš fŕöm ţĥîš ðévîçé one two three]';

  @override
  String windowTitleNowPlaying(String title, String artist) {
    return '[$title — $artist · šöûñðšþåñ one two]';
  }

  @override
  String get trayPlay => '[Þļåý one]';

  @override
  String get trayPause => '[Þåûšé one]';

  @override
  String get trayShowWindow => '[Šĥöŵ ŵîñðöŵ one two]';

  @override
  String get trayQuit => '[Qûîţ one]';

  @override
  String trayNowPlaying(String title, String artist) {
    return '[$title — $artist one]';
  }

  @override
  String get settingsCloseToTray => '[Çļöšé ţö ţŕåý one two]';

  @override
  String get settingsCloseToTrayUnavailable =>
      '[Ñö šýšţém ţŕåý ŵåš föûñð one two three]';

  @override
  String get settingsUpdateCheck => '[Çĥéçķ föŕ ñéŵ véŕšîöñš one two three]';

  @override
  String get settingsUpdateCheckCaption =>
      '[Åšķš ĜîţĤûb föŕ ţĥé ļîšţ öf šöûñðšþåñ ŕéļéåšéš öñçé å ðåý. one two three four five]';

  @override
  String updateBannerMessage(String version) {
    return '[šöûñðšþåñ $version îš åvåîļåbļé one two three]';
  }

  @override
  String get updateViewRelease => '[Vîéŵ ŕéļéåšé one two]';

  @override
  String settingsAboutUpdateAvailable(String version) {
    return '[Véŕšîöñ $version îš åvåîļåbļé one two three]';
  }

  @override
  String get settingsAboutCheckNow => '[Çĥéçķ ñöŵ one]';

  @override
  String get closeKeepPlayingTitle =>
      '[Ķééþ þļåýîñĝ îñ ţĥé båçķĝŕöûñð? one two three]';

  @override
  String get closeKeepPlaying => '[Ķééþ þļåýîñĝ one two]';

  @override
  String get closeQuit => '[Qûîţ one]';

  @override
  String get menuSettings => '[Šéţţîñĝš… one]';

  @override
  String get menuQuit => '[Qûîţ šöûñðšþåñ one two]';

  @override
  String get menuPlayback => '[Þļåýbåçķ one]';

  @override
  String get menuView => '[Vîéŵ one]';

  @override
  String get menuWindow => '[Ŵîñðöŵ one]';

  @override
  String get menuPlayPause => '[Þļåý/Þåûšé one]';

  @override
  String get menuNext => '[Ñéxţ one]';

  @override
  String get menuPrevious => '[Þŕévîöûš one]';

  @override
  String get menuShuffle => '[Šĥûffļé one]';

  @override
  String get menuRepeat => '[Ŕéþéåţ one]';

  @override
  String get menuQueue => '[Qûéûé one]';

  @override
  String get menuLyrics => '[Ļýŕîçš one]';

  @override
  String get navVibe => '[Vîbé one]';

  @override
  String get homeVibeCard =>
      '[Ţŕåçķš ţĥåţ šöûñð ļîķé ŵĥåţ ýöû þļåý one two three four]';

  @override
  String get menuStartRadio => '[Šţåŕţ ŕåðîö one two]';

  @override
  String get vibeNoSimilar => '[Ñö šîmîļåŕ ţŕåçķš föûñð one two three]';

  @override
  String get vibeSearchHint => '[Ðéšçŕîbé å šöûñð öŕ å mööð one two three]';

  @override
  String get vibeSearchLabel => '[Šéåŕçĥ bý ðéšçŕîþţîöñ one two three]';

  @override
  String get vibeSearchClear => '[Çļéåŕ one]';

  @override
  String get vibePlayAll => '[Þļåý åļļ one]';

  @override
  String get vibeSimilarTitle => '[Šîmîļåŕ ţö ŵĥåţ’š þļåýîñĝ one two three]';

  @override
  String get vibeNoMatches => '[Ñö måţçĥéš one]';

  @override
  String get vibeExplain =>
      '[Þļåý å ţŕåçķ ţö šéé öţĥéŕš ţĥåţ šöûñð ļîķé îţ ĥéŕé. one two three four five]';

  @override
  String get vibeSearchUnavailable =>
      '[Vîbé šéåŕçĥ îš ûñåvåîļåbļé ŕîĝĥţ ñöŵ one two three four]';
}
