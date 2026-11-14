import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
  ];

  /// The application name, shown as the window and task-switcher title and on the start screen.
  ///
  /// In en, this message translates to:
  /// **'soundspan'**
  String get appTitle;

  /// The window or browser tab title: the current screen's name followed by the application name.
  ///
  /// In en, this message translates to:
  /// **'{screen} · soundspan'**
  String windowTitle(String screen);

  /// Navigation destination and screen name: the home screen.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Navigation destination and screen name: the search screen.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Navigation destination and screen name: the user's library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Navigation destination and screen name: podcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get navPodcasts;

  /// Accessibility label of the group holding the main navigation destinations.
  ///
  /// In en, this message translates to:
  /// **'Main navigation'**
  String get navMainLabel;

  /// Screen name: entering the address of a server to add.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get screenConnect;

  /// Screen name: the app is contacting the server the user entered.
  ///
  /// In en, this message translates to:
  /// **'Checking server'**
  String get screenConnectProbe;

  /// Screen name: signing in to a server.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get screenSignIn;

  /// Screen name: the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get screenSettings;

  /// Screen name: the settings page listing the user's servers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get screenSettingsServers;

  /// Screen name: the playback settings page.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get screenSettingsPlayback;

  /// Screen name: the storage settings page.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get screenSettingsStorage;

  /// Screen name: the appearance settings page.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get screenSettingsAppearance;

  /// Screen name: the about page.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get screenSettingsAbout;

  /// Screen name: the detail screen of one album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get screenAlbum;

  /// Screen name: the detail screen of one artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get screenArtist;

  /// Screen name: the detail screen of one playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get screenPlaylist;

  /// Top bar button: go back in the current navigation destination.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get shellBack;

  /// Top bar button: re-open the screen most recently left with Back.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get shellForward;

  /// Placeholder and accessibility label of the search field in the top bar.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get shellSearchHint;

  /// Tooltip and accessibility label of the avatar button that opens the account menu with the server switcher.
  ///
  /// In en, this message translates to:
  /// **'Account and servers'**
  String get shellAccountMenu;

  /// Heading of the server list in the account menu.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get shellMenuServers;

  /// Accessibility label of the mark next to the server the app is showing, in the account menu and in the Servers settings.
  ///
  /// In en, this message translates to:
  /// **'Current server'**
  String get shellMenuCurrentServer;

  /// Account menu entry: add another server.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get shellMenuAddServer;

  /// Account menu entry: open the settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shellMenuSettings;

  /// Heading of the theme choice in the Appearance settings.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeTitle;

  /// Theme choice: follow the device’s light or dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// Theme choice: always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// Theme choice: always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// Heading of the language choice in the Appearance settings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// Language choice: use the device’s language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// The name of this language written in this language, shown in the language choice.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageName;

  /// Servers settings action: add another server.
  ///
  /// In en, this message translates to:
  /// **'Add server'**
  String get settingsServersAdd;

  /// Servers settings action: make this server the one the app shows.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get settingsServersSwitch;

  /// Servers settings action: change the name shown for this server.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get settingsServersRename;

  /// Servers settings action, shown to administrators: open the server’s administration page in the browser.
  ///
  /// In en, this message translates to:
  /// **'Open server admin'**
  String get settingsServersOpenAdmin;

  /// State of a server profile: signed in.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get settingsServersStateActive;

  /// State of a server profile: signed out; its data is kept.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get settingsServersStateSignedOut;

  /// The user name and server host of a server profile.
  ///
  /// In en, this message translates to:
  /// **'{username} on {host}'**
  String settingsServersAccount(String username, String host);

  /// The server version seen when the app last checked.
  ///
  /// In en, this message translates to:
  /// **'Server version {version}'**
  String settingsServersVersion(String version);

  /// Shown instead of the server version before the app has checked it.
  ///
  /// In en, this message translates to:
  /// **'Server version not known yet'**
  String get settingsServersVersionUnknown;

  /// Title of the dialog that renames a server.
  ///
  /// In en, this message translates to:
  /// **'Rename server'**
  String get settingsServersRenameTitle;

  /// Label of the name field in the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsServersRenameLabel;

  /// Rename dialog button: store the new name.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsServersRenameSave;

  /// Dialog button: close without changing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Title of the screen shown when this server’s data on the device was written by a newer app version.
  ///
  /// In en, this message translates to:
  /// **'This data was written by a newer version of the app'**
  String get localDataTooNewTitle;

  /// Explanation on the screen shown when this server’s data on the device was written by a newer app version.
  ///
  /// In en, this message translates to:
  /// **'Update the app to keep using this data, reset this server’s local data, or switch to another server.'**
  String get localDataTooNewBody;

  /// Button: delete this server’s data on the device and start fresh, after a confirmation.
  ///
  /// In en, this message translates to:
  /// **'Reset this server’s local data'**
  String get localDataTooNewReset;

  /// Button: open the server list to show another server.
  ///
  /// In en, this message translates to:
  /// **'Switch server'**
  String get localDataTooNewSwitch;

  /// Title of the confirmation before this server’s data on the device is deleted.
  ///
  /// In en, this message translates to:
  /// **'Reset local data?'**
  String get localDataTooNewConfirmTitle;

  /// Body of the confirmation before this server’s data on the device is deleted.
  ///
  /// In en, this message translates to:
  /// **'The queue, pending changes and downloads of this server are deleted from this device. Your library on the server is not changed.'**
  String get localDataTooNewConfirmBody;

  /// Confirmation button: delete this server’s data on the device.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get localDataTooNewConfirmReset;

  /// One-time notice on the web when the browser offers no lasting storage, for example in private browsing.
  ///
  /// In en, this message translates to:
  /// **'This browser is not keeping data, so nothing will be remembered after this page is closed.'**
  String get storageVolatileNotice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return AppLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
