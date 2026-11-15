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

  /// Screen name: the list of the licences of the app, its bundled fonts and libraries, and the packages it uses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get screenLicenses;

  /// Row in Settings → About that opens the open-source licences screen.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get settingsAboutLicenses;

  /// Section heading on the licences screen: the fonts and native libraries shipped inside the app.
  ///
  /// In en, this message translates to:
  /// **'Fonts and bundled libraries'**
  String get licensesSectionBundled;

  /// Section heading on the licences screen: the software packages the app is built with.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get licensesSectionPackages;

  /// Under a package name on the licences screen: how many licences apply to it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 licence} other{{count} licences}}'**
  String licensesCount(int count);

  /// Accessibility label of the progress indicator while the licences are collected.
  ///
  /// In en, this message translates to:
  /// **'Loading licences'**
  String get licensesLoading;

  /// Shown on the licences screen when collecting the licences failed.
  ///
  /// In en, this message translates to:
  /// **'The licences could not be loaded.'**
  String get licensesLoadFailed;

  /// Button on the licences screen that collects the licences again after a failure.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get licensesRetry;

  /// Label of the text field where the user types the address of their soundspan server.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get connectAddressLabel;

  /// Example addresses shown in the empty server address field.
  ///
  /// In en, this message translates to:
  /// **'music.example.com or 192.168.1.20:3030'**
  String get connectAddressHint;

  /// Primary button that checks the server address the user typed.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectAddressSubmit;

  /// Tooltip of the back control on the address screen, shown when a server is already set up.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get connectAddressBack;

  /// Shown under the address field when it was submitted empty.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of your soundspan server.'**
  String get connectAddressEmpty;

  /// Shown under the address field when the address names another scheme, such as ftp://.
  ///
  /// In en, this message translates to:
  /// **'Use an address that starts with http:// or https://.'**
  String get connectAddressUnsupportedScheme;

  /// Shown under the address field when the address cannot be used.
  ///
  /// In en, this message translates to:
  /// **'That is not a server address. Check it and try again.'**
  String get connectAddressInvalid;

  /// Title of the dialog shown before connecting to a public server over plain http.
  ///
  /// In en, this message translates to:
  /// **'Connection not encrypted'**
  String get connectCleartextTitle;

  /// Body of the dialog shown before connecting to a public server over plain http, on platforms that allow it.
  ///
  /// In en, this message translates to:
  /// **'{address} uses http, so your password and music travel unencrypted and can be read on the way. Use https if the server offers it.'**
  String connectCleartextBody(String address);

  /// Body of the dialog shown when the user enters a public plain-http address on a platform that blocks such connections.
  ///
  /// In en, this message translates to:
  /// **'{address} uses http. This device blocks unencrypted connections to public servers, so use the server’s https address.'**
  String connectCleartextBlockedBody(String address);

  /// Dialog button that closes the unencrypted-connection warning without connecting.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectCleartextCancel;

  /// Dialog button that connects to a public server over plain http despite the warning.
  ///
  /// In en, this message translates to:
  /// **'Connect anyway'**
  String get connectCleartextConnectAnyway;

  /// Shown while the app contacts the server.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {address}'**
  String connectProbeResolving(String address);

  /// Shown when the server answered that it is still starting up.
  ///
  /// In en, this message translates to:
  /// **'The server is starting'**
  String get connectProbeStarting;

  /// Countdown to the next attempt while the server is starting.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Trying again in 1 second} other{Trying again in {seconds} seconds}}'**
  String connectProbeStartingRetry(int seconds);

  /// Button that stops contacting the server and returns to the address screen.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get connectProbeCancel;

  /// Shown when the server moved the app to another address, which is the one that will be used.
  ///
  /// In en, this message translates to:
  /// **'Using {address}'**
  String connectProbeUsing(String address);

  /// Shown on the result of a successful check of a server reached without encryption.
  ///
  /// In en, this message translates to:
  /// **'Connected to {address}'**
  String connectProbeConnected(String address);

  /// Warning chip on a server reached over plain http on the local network.
  ///
  /// In en, this message translates to:
  /// **'Not encrypted'**
  String get connectProbeNotEncrypted;

  /// Button that continues to sign-in after the server was found.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get connectProbeContinue;

  /// Button that returns to the address screen with the typed address kept.
  ///
  /// In en, this message translates to:
  /// **'Edit address'**
  String get connectProbeEditAddress;

  /// Button that contacts the server again.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get connectProbeTryAgain;

  /// The address the app tried, shown on a failure.
  ///
  /// In en, this message translates to:
  /// **'Address tried: {address}'**
  String connectProbeTried(String address);

  /// Shown when the server has no account yet and must be set up in its web interface.
  ///
  /// In en, this message translates to:
  /// **'This server has not been set up yet. Open it in a browser, create the first account there, then try again.'**
  String get connectProbeNeedsSetup;

  /// Button that opens the server’s web interface in the system browser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get connectProbeOpenInBrowser;

  /// Failure: the server’s host name could not be found.
  ///
  /// In en, this message translates to:
  /// **'Address not found'**
  String get connectProbeDns;

  /// Failure: the connection was refused.
  ///
  /// In en, this message translates to:
  /// **'Nothing is listening at that address and port'**
  String get connectProbeRefused;

  /// Failure: the server did not answer in time.
  ///
  /// In en, this message translates to:
  /// **'The server did not answer'**
  String get connectProbeTimeout;

  /// Failure: the secure connection failed because the certificate is not trusted.
  ///
  /// In en, this message translates to:
  /// **'The server’s certificate is not trusted by this device'**
  String get connectProbeTls;

  /// Failure: a proxy or gateway in front of the server asked for its own login.
  ///
  /// In en, this message translates to:
  /// **'Something in front of the server requires its own login'**
  String get connectProbeBlockedByProxy;

  /// Failure: the address answered, but not as a soundspan server.
  ///
  /// In en, this message translates to:
  /// **'That address is not a soundspan server (check the path)'**
  String get connectProbeNotSoundspan;

  /// Failure: the server answered with an error.
  ///
  /// In en, this message translates to:
  /// **'The server reported an error'**
  String get connectProbeServerError;

  /// Failure: the server redirected too often, to another scheme, or from https to http.
  ///
  /// In en, this message translates to:
  /// **'The server redirected to an address this app will not follow'**
  String get connectProbeRedirectRefused;

  /// Failure in the browser app: the server is unreachable or does not allow this app’s origin. ALLOWED_ORIGINS is a setting name and is not translated.
  ///
  /// In en, this message translates to:
  /// **'The server could not be reached. If it is running, it must allow this app’s address: add the address below to the server’s ALLOWED_ORIGINS setting, restart it and try again.'**
  String get connectProbeCorsOrNetwork;

  /// Shown instead of sign-in, or instead of the app, when the server is older than the oldest version this app supports.
  ///
  /// In en, this message translates to:
  /// **'This app needs soundspan {minServer} or newer. This server runs {version}.'**
  String connectServerTooOld(String minServer, String version);

  /// Button that asks the signed-in server for its version again.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get connectServerTooOldCheckAgain;

  /// Button that opens the list of servers, to use another one.
  ///
  /// In en, this message translates to:
  /// **'Switch server'**
  String get connectServerTooOldSwitchServer;

  /// Label of the read-only field showing the web app’s origin.
  ///
  /// In en, this message translates to:
  /// **'This app’s address'**
  String get connectProbeOrigin;

  /// Button that copies the web app’s origin to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get connectProbeCopyOrigin;

  /// Tooltip and accessibility label of the play button shown over a hovered or focused album, artist or playlist card.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get mediaCardPlay;

  /// Button in the header of a horizontal row of cards on Home: opens the whole section.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get shelfShowAll;

  /// Arrow button in the header of a horizontal row of cards: scrolls the row back by one visible width.
  ///
  /// In en, this message translates to:
  /// **'Scroll back'**
  String get shelfScrollBack;

  /// Arrow button in the header of a horizontal row of cards: scrolls the row forward by one visible width.
  ///
  /// In en, this message translates to:
  /// **'Scroll forward'**
  String get shelfScrollForward;

  /// Heading of the sign-in form; names the server.
  ///
  /// In en, this message translates to:
  /// **'Sign in to {server}'**
  String connectSignInHeading(String server);

  /// Back control of the sign-in screen; returns to the address screen.
  ///
  /// In en, this message translates to:
  /// **'Use a different server'**
  String get connectSignInBack;

  /// Label of the user name field on the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'User name or email'**
  String get connectSignInUsername;

  /// Label of the password field on the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get connectSignInPassword;

  /// Tooltip of the control that reveals the typed password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get connectSignInShowPassword;

  /// Tooltip of the control that hides the typed password again.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get connectSignInHidePassword;

  /// Button that submits the user name and password.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get connectSignInSubmit;

  /// Inline error when the server rejected the user name or password.
  ///
  /// In en, this message translates to:
  /// **'The user name or password is not correct'**
  String get connectSignInInvalidCredentials;

  /// Instruction on the two-factor step in authenticator mode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your authenticator app.'**
  String get connectSignInAuthenticatorPrompt;

  /// Instruction on the two-factor step in recovery-code mode.
  ///
  /// In en, this message translates to:
  /// **'Enter one of your 8-character recovery codes.'**
  String get connectSignInRecoveryPrompt;

  /// Label of the code field in authenticator mode.
  ///
  /// In en, this message translates to:
  /// **'Authenticator code'**
  String get connectSignInAuthenticatorCode;

  /// Label of the code field in recovery-code mode.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get connectSignInRecoveryCode;

  /// Button that switches the two-factor step to recovery codes.
  ///
  /// In en, this message translates to:
  /// **'Use a recovery code instead'**
  String get connectSignInUseRecovery;

  /// Button that switches the two-factor step back to authenticator codes.
  ///
  /// In en, this message translates to:
  /// **'Use an authenticator code instead'**
  String get connectSignInUseAuthenticator;

  /// Button that submits the two-factor code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get connectSignInVerify;

  /// Button that leaves the two-factor step and returns to the user name and password.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get connectSignInStartOver;

  /// Inline error when the server rejected the two-factor or recovery code.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct'**
  String get connectSignInInvalidCode;

  /// Shown after too many sign-in attempts, counting down until the next one is allowed.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{Too many attempts. Try again in 1 second.} other{Too many attempts. Try again in {seconds} seconds.}}'**
  String connectSignInRateLimited(int seconds);

  /// Inline error when the sign-in request failed for any other reason.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check the connection and try again.'**
  String get connectSignInFailed;

  /// Button that sends the failed sign-in again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get connectSignInRetry;

  /// Error when the device cannot store the sign-in securely; nothing was saved.
  ///
  /// In en, this message translates to:
  /// **'This device has no secure storage service, so the sign-in cannot be kept. On Linux, install and start a Secret Service provider such as GNOME Keyring or KWallet.'**
  String get connectSignInSecureStorage;

  /// Shown instead of the form when the server has password sign-in turned off.
  ///
  /// In en, this message translates to:
  /// **'This server does not offer password sign-in.'**
  String get connectSignInNoPassword;

  /// Hours part of a track's length as read by a screen reader, e.g. the '1 hour' of '1 hour 2 minutes 3 seconds'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String trackRowDurationHours(int count);

  /// Minutes part of a track's length as read by a screen reader, e.g. the '3 minutes' of '3 minutes 41 seconds'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String trackRowDurationMinutes(int count);

  /// Seconds part of a track's length as read by a screen reader, e.g. the '41 seconds' of '3 minutes 41 seconds'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String trackRowDurationSeconds(int count);

  /// Shown in place of a screen's content when the server could not be reached and nothing is cached.
  ///
  /// In en, this message translates to:
  /// **'You’re offline'**
  String get errorViewOffline;

  /// Shown in place of a screen's content when the server has turned off the feature the screen needs.
  ///
  /// In en, this message translates to:
  /// **'Not available on this server'**
  String get errorViewFeatureDisabled;

  /// Shown in place of a screen's content when the server refused the request because too many were sent.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, try again shortly'**
  String get errorViewRateLimited;

  /// Shown in place of a screen's content when the server, or a service it relies on, failed.
  ///
  /// In en, this message translates to:
  /// **'The server ran into a problem'**
  String get errorViewServerProblem;

  /// Shown in place of an album, artist, playlist or other item that no longer exists on the server.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available'**
  String get errorViewNotFound;

  /// Shown in place of a screen's content when loading failed for any other reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorViewGeneric;

  /// Button under a loading error: tries to load the screen again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get errorViewRetry;

  /// Tooltip and accessibility label of the close button of an inline notice at the top of a screen.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get appBannerDismiss;

  /// Library tab that lists the user's playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get libraryTabPlaylists;

  /// Library tab that lists the artists in the user's library.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryTabArtists;

  /// Library tab that lists the albums in the user's library.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryTabAlbums;

  /// Library tab that lists the songs in the user's library.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get libraryTabSongs;

  /// Tooltip and accessibility label of the button above a library list that opens the choice of sort order.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get librarySort;

  /// Sort order of a library list: by name, A to Z.
  ///
  /// In en, this message translates to:
  /// **'Name (A-Z)'**
  String get librarySortNameAsc;

  /// Sort order of a library list: by name, Z to A.
  ///
  /// In en, this message translates to:
  /// **'Name (Z-A)'**
  String get librarySortNameDesc;

  /// Sort order of the albums list: newest release year first.
  ///
  /// In en, this message translates to:
  /// **'Year (newest)'**
  String get librarySortYearNewest;

  /// Sort order of the artists list: artists with the most tracks first.
  ///
  /// In en, this message translates to:
  /// **'Most tracks'**
  String get librarySortMostTracks;

  /// Filter chip above a library list: shows everything in the library, wherever it lives.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryOriginAll;

  /// Filter chip above a library list: shows only what lives in this server's own music folder.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get libraryOriginLocal;

  /// Filter chip above a library list: shows only what lives on connected peer servers.
  ///
  /// In en, this message translates to:
  /// **'Peers'**
  String get libraryOriginPeers;

  /// Filter chip above a library list: shows only what lives in connected streaming services.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get libraryOriginRemote;

  /// Tooltip and accessibility label of the button above a library list that loads the list again from the server.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get libraryRefresh;

  /// Short message shown at the bottom of the screen when a library list could not be loaded again; the list already shown stays.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t refresh the list'**
  String get libraryRefreshFailed;

  /// Shown in place of the albums list when the library holds no albums.
  ///
  /// In en, this message translates to:
  /// **'No albums yet'**
  String get libraryAlbumsEmpty;

  /// Shown in place of the artists list when the library holds no artists.
  ///
  /// In en, this message translates to:
  /// **'No artists yet'**
  String get libraryArtistsEmpty;

  /// Second line of an artist card in the library grid, under the artist's name.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get libraryArtistCardSubtitle;

  /// Greeting at the top of Home before 12:00 local time.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorning;

  /// Greeting at the top of Home from 12:00 to 17:59 local time.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoon;

  /// Greeting at the top of Home from 18:00 local time.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEvening;

  /// Title of the Home row of artists and podcasts the user listened to recently.
  ///
  /// In en, this message translates to:
  /// **'Continue Listening'**
  String get homeShelfContinueListening;

  /// Title of the Home row of artists recently added to the library.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get homeShelfRecentlyAdded;

  /// Title of the Home row with Liked Songs and the mixes generated for the user.
  ///
  /// In en, this message translates to:
  /// **'Made For You'**
  String get homeShelfMadeForYou;

  /// Title of the Home row of the user's playlists.
  ///
  /// In en, this message translates to:
  /// **'Your Playlists'**
  String get homeShelfYourPlaylists;

  /// Title of the Home row of podcasts popular in the podcast directory.
  ///
  /// In en, this message translates to:
  /// **'Popular Podcasts'**
  String get homeShelfPopularPodcasts;

  /// Title of the card that opens the tracks the user liked.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get homeLikedSongs;

  /// Second line of the Liked Songs card: what kind of item it is.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get homeLikedSongsSubtitle;

  /// Second line of a card of an artist on Home: what kind of item it is.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get homeCardArtist;

  /// Second line of a card of a podcast on Home when the podcast has no author.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get homeCardPodcast;

  /// Notice at the top of Home when the server runs a version newer than the newest one this app was tested against.
  ///
  /// In en, this message translates to:
  /// **'This server is newer than this app was tested with'**
  String get homeNoticeNewerThanTested;

  /// Notice at the top of Home when the server did not say which version it runs.
  ///
  /// In en, this message translates to:
  /// **'This server’s version could not be read'**
  String get homeNoticeVersionUnknown;

  /// Shown on Home in place of the rows when every row loaded and none has anything in it.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get homeEmptyLibrary;

  /// Second line of a playlist card on Home: how many songs the playlist has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String homePlaylistSongs(int count);
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
