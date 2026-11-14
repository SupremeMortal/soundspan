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
