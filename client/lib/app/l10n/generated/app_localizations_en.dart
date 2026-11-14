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
}
