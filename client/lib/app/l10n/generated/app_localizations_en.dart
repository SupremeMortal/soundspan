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
  String get trackNotPlayable => 'Not playable';

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
  String get trackNotPlayable => '[Ñöţ þļåýåbļé one two]';

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
}
