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

  /// Screen name: scanning the QR code from the web UI's device page with the camera.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get screenConnectScan;

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

  /// Name of the Android notification channel of the playback notification, shown in the system's notification settings for the app.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playbackNotificationChannelName;

  /// Title of the Android Auto browse folder listing recently listened tracks.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get androidAutoRecent;

  /// Title of the Android Auto browse folder listing the user's playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get androidAutoPlaylists;

  /// Title of the Android Auto browse folder listing the library's albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get androidAutoAlbums;

  /// Title of the Android Auto browse folder listing what is downloaded to this device; it works with no connection.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get androidAutoDownloads;

  /// Subtitle of a downloaded album, playlist, song or episode in the Android Auto Downloads folder: its kind and how many of its tracks are downloaded.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {completed}'**
  String androidAutoDownloadsSubtitle(String kind, int completed);

  /// Title of the system notification shown while downloads run on Android: how many items the current batch holds. It never names a track or a source.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Downloading 1 item} other{Downloading {count} items}}'**
  String downloadsNotificationTitle(int count);

  /// Text of the system notification on Android once every download of the batch has finished.
  ///
  /// In en, this message translates to:
  /// **'Downloads finished'**
  String get downloadsNotificationFinished;

  /// Kind of a downloaded podcast episode, in the Android Auto Downloads folder.
  ///
  /// In en, this message translates to:
  /// **'Podcast episode'**
  String get androidAutoKindEpisode;

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

  /// Screen name: the detail screen of one generated mix of Made For You.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get screenMix;

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

  /// Top bar button tooltip: show or hide the Activity panel listing who is online.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get shellActivity;

  /// Account menu entry: open the Activity sheet listing who is online.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get shellMenuActivity;

  /// Heading of the Activity panel and sheet, which list who is online.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// Activity section heading: users of the server the app is signed in to.
  ///
  /// In en, this message translates to:
  /// **'On this server'**
  String get activityOnThisServer;

  /// Activity section heading: users of other servers this server is connected to.
  ///
  /// In en, this message translates to:
  /// **'On connected servers'**
  String get activityOnConnectedServers;

  /// Activity row status: the user is playing music.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get activityStatusPlaying;

  /// Activity row status: the user has paused playback.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get activityStatusPaused;

  /// Activity row status: the user is online but not playing.
  ///
  /// In en, this message translates to:
  /// **'Idle'**
  String get activityStatusIdle;

  /// Activity row status of a user of a connected server.
  ///
  /// In en, this message translates to:
  /// **'{status} on {server}'**
  String activityPeerStatus(String status, String server);

  /// Activity row second line: the track the user plays and its artist.
  ///
  /// In en, this message translates to:
  /// **'{title} · {artist}'**
  String activityTrack(String title, String artist);

  /// Activity empty state: no other user is online.
  ///
  /// In en, this message translates to:
  /// **'Nobody else is online'**
  String get activityEmpty;

  /// Screen reader label of an Activity row: the user plays a track.
  ///
  /// In en, this message translates to:
  /// **'{name}, playing {title} by {artist}'**
  String activityRowPlaying(String name, String title, String artist);

  /// Screen reader label of an Activity row: the user paused a track.
  ///
  /// In en, this message translates to:
  /// **'{name}, paused on {title} by {artist}'**
  String activityRowPaused(String name, String title, String artist);

  /// Screen reader label of an Activity row without a track; status is the row status text.
  ///
  /// In en, this message translates to:
  /// **'{name}, {status}'**
  String activityRowStatus(String name, String status);

  /// Screen reader label of an Activity row of a connected server: the row label and the server name.
  ///
  /// In en, this message translates to:
  /// **'{label}, on {server}'**
  String activityRowPeer(String label, String server);

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

  /// Playback settings row: the stream quality used on Wi-Fi and other connections that are not mobile data.
  ///
  /// In en, this message translates to:
  /// **'Quality on Wi-Fi'**
  String get settingsPlaybackQualityWifi;

  /// Playback settings row: the stream quality used on a mobile data connection.
  ///
  /// In en, this message translates to:
  /// **'Quality on mobile data'**
  String get settingsPlaybackQualityCellular;

  /// Playback settings row on devices without mobile data: the stream quality on every connection.
  ///
  /// In en, this message translates to:
  /// **'Streaming quality'**
  String get settingsPlaybackQualitySingle;

  /// Caption under the quality rows: the playing item is not reloaded.
  ///
  /// In en, this message translates to:
  /// **'Quality changes apply from the next item that starts.'**
  String get settingsPlaybackQualityCaption;

  /// Stream quality choice: use the quality saved on the server.
  ///
  /// In en, this message translates to:
  /// **'Server default'**
  String get settingsPlaybackQualityServerDefault;

  /// Caption of the Server default quality choice.
  ///
  /// In en, this message translates to:
  /// **'The quality saved on the server applies.'**
  String get settingsPlaybackQualityServerDefaultCaption;

  /// Stream quality choice: the original file, not transcoded.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get settingsPlaybackQualityOriginal;

  /// Stream quality choice: high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get settingsPlaybackQualityHigh;

  /// Stream quality choice: medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsPlaybackQualityMedium;

  /// Stream quality choice: low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get settingsPlaybackQualityLow;

  /// Playback settings row: the loudness levelling mode, saved on the server.
  ///
  /// In en, this message translates to:
  /// **'Volume levelling'**
  String get settingsPlaybackLevelling;

  /// Volume levelling choice: no levelling.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsPlaybackLevellingOff;

  /// Volume levelling choice: each track is levelled on its own.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get settingsPlaybackLevellingTrack;

  /// Volume levelling choice: tracks are levelled on their album's loudness.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get settingsPlaybackLevellingAlbum;

  /// Volume levelling choice: album levelling while an album plays, track levelling otherwise.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsPlaybackLevellingAuto;

  /// Volume levelling value the server holds that this app does not know.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get settingsPlaybackLevellingUnknown;

  /// Tooltip of the disabled volume levelling row while the server cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Available when the server can be reached'**
  String get settingsPlaybackLevellingOffline;

  /// Snackbar when saving the volume levelling mode failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t change volume levelling'**
  String get settingsPlaybackLevellingFailed;

  /// Playback settings row: how far the skip buttons move in an episode.
  ///
  /// In en, this message translates to:
  /// **'Skip interval (podcasts)'**
  String get settingsPlaybackSkipInterval;

  /// Playback settings row: the speed episodes play at.
  ///
  /// In en, this message translates to:
  /// **'Default speed (podcasts)'**
  String get settingsPlaybackSpeed;

  /// A skip interval choice or value, in seconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds, plural, =1{1 second} other{{seconds} seconds}}'**
  String settingsPlaybackSkipSeconds(int seconds);

  /// A playback speed choice or value, such as 1.25×.
  ///
  /// In en, this message translates to:
  /// **'{speed}×'**
  String settingsPlaybackSpeedValue(double speed);

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

  /// When the API key of a device-linked server profile expires.
  ///
  /// In en, this message translates to:
  /// **'Link expires {date}'**
  String settingsServersLinkExpires(DateTime date);

  /// Shown for a server profile signed in with an API key whose expiry date is not known.
  ///
  /// In en, this message translates to:
  /// **'Link expiry unknown'**
  String get settingsServersLinkExpiryUnknown;

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

  /// Servers settings action: sign out of this server; its downloads and cached data stay on this device.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsServersSignOut;

  /// Servers settings action: sign out and delete everything stored for this server on this device.
  ///
  /// In en, this message translates to:
  /// **'Remove this server'**
  String get settingsServersRemove;

  /// Title of the dialog that confirms signing out of a server.
  ///
  /// In en, this message translates to:
  /// **'Sign out of {server}?'**
  String settingsServersSignOutTitle(String server);

  /// Body of the sign-out dialog.
  ///
  /// In en, this message translates to:
  /// **'Downloads, cached data and changes not yet sent stay on this device. Sign in again to use this server.'**
  String get settingsServersSignOutBody;

  /// Sign-out dialog checkbox: delete this server's downloaded music from this device too; with how many items and how much space they take.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Also remove downloads (1 item, {size})} other{Also remove downloads ({count} items, {size})}}'**
  String settingsServersSignOutRemoveDownloads(int count, String size);

  /// Title of the dialog that confirms removing a server.
  ///
  /// In en, this message translates to:
  /// **'Remove {server}?'**
  String settingsServersRemoveTitle(String server);

  /// Body of the dialog that confirms removing a server.
  ///
  /// In en, this message translates to:
  /// **'This signs out and deletes everything this app stores for {server} on this device, downloads included.'**
  String settingsServersRemoveBody(String server);

  /// Remove-server dialog: how many changes made on this device would be lost.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has not been sent to the server and will be lost.} other{{count} changes have not been sent to the server and will be lost.}}'**
  String settingsServersRemovePending(int count);

  /// Remove-server dialog: shown when this server has downloaded music on this device.
  ///
  /// In en, this message translates to:
  /// **'Downloads on this device for this server will be deleted.'**
  String get settingsServersRemoveDownloads;

  /// Remove-server dialog button: remove the server.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsServersRemoveConfirm;

  /// Remove-server dialog button when changes have not been sent: remove the server and lose them.
  ///
  /// In en, this message translates to:
  /// **'Remove anyway'**
  String get settingsServersRemoveAnyway;

  /// Shown in the sign-out dialog while the app signs out.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsServersSigningOut;

  /// Shown in the remove-server dialog while the app removes the server.
  ///
  /// In en, this message translates to:
  /// **'Removing…'**
  String get settingsServersRemoving;

  /// Shown in the sign-out and remove-server dialogs when the device's secure storage failed.
  ///
  /// In en, this message translates to:
  /// **'The sign-in details on this device could not be deleted. Try again.'**
  String get settingsServersExitFailed;

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

  /// Row in Settings → About: how many changes made on this device have not reached the server yet.
  ///
  /// In en, this message translates to:
  /// **'Pending changes: {count}'**
  String settingsAboutPendingChanges(int count);

  /// Row title in Settings → About; the row shows the app's version below it.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersion;

  /// The app's version and build number under the Version row in Settings → About.
  ///
  /// In en, this message translates to:
  /// **'{version} ({build})'**
  String settingsAboutVersionValue(String version, String build);

  /// The app's version, build number and release channel (for example dev) under the Version row in Settings → About, on builds that are not stable releases.
  ///
  /// In en, this message translates to:
  /// **'{version} ({build}) · {channel}'**
  String settingsAboutVersionWithChannel(
    String version,
    String build,
    String channel,
  );

  /// Row in Settings → About that saves or shares this device's diagnostic logs, to attach to a bug report.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get settingsAboutExportLogs;

  /// Snackbar after the logs were saved, shared or downloaded.
  ///
  /// In en, this message translates to:
  /// **'Logs exported'**
  String get settingsAboutExportLogsDone;

  /// Snackbar when Export logs found no logs on this device.
  ///
  /// In en, this message translates to:
  /// **'No logs to export'**
  String get settingsAboutExportLogsNothing;

  /// Snackbar when Export logs failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t export logs'**
  String get settingsAboutExportLogsFailed;

  /// Snackbar: changes made on this device were discarded because the track or playlist they apply to was deleted on the server.
  ///
  /// In en, this message translates to:
  /// **'Some changes couldn’t be saved because the item no longer exists'**
  String get outboxItemsGoneMessage;

  /// Snackbar: a change made on this device was discarded because the same item was changed on another device first.
  ///
  /// In en, this message translates to:
  /// **'A change couldn’t be saved because it was changed elsewhere'**
  String get outboxConflictMessage;

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

  /// Notice at the top of Home and Library when the device has no network connection.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Showing what’s saved on this device.'**
  String get offlineBannerNoNetwork;

  /// Notice at the top of Home and Library when the network is up but the server does not answer.
  ///
  /// In en, this message translates to:
  /// **'Can’t reach the server. Showing what’s saved on this device.'**
  String get offlineBannerServerUnreachable;

  /// Notice at the top of Home and Library when the user turned offline mode on.
  ///
  /// In en, this message translates to:
  /// **'Offline mode is on.'**
  String get offlineBannerForced;

  /// Button of the server-unreachable notice that asks the server again at once.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get offlineBannerRetry;

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

  /// Shown in the empty detail pane of the two-pane layout of a tablet in landscape until an item of the list beside it is selected.
  ///
  /// In en, this message translates to:
  /// **'Select an item'**
  String get twoPaneSelectItem;

  /// Shown in place of the artists list when the library holds no artists.
  ///
  /// In en, this message translates to:
  /// **'No artists yet'**
  String get libraryArtistsEmpty;

  /// Shown in place of the songs list when the library holds no tracks.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get librarySongsEmpty;

  /// Name of the pinned row at the top of the playlist list in the Library and the sidebar; it opens the tracks the user liked.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get libraryLikedSongs;

  /// Second line of a playlist row in the Library: how many songs the playlist holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String libraryPlaylistTrackCount(int count);

  /// One line under Liked Songs in the Library's playlist list when the user has no playlists yet.
  ///
  /// In en, this message translates to:
  /// **'Playlists you create appear here'**
  String get libraryPlaylistsEmptyHint;

  /// Accessibility label of the list of playlists in the sidebar, under the main destinations.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get sidebarPlaylistsLabel;

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

  /// Banner at the top of Home when this device's link (its API key) expires within 14 days; 1 means today.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{This device’s link expires today} other{This device’s link expires in {days} days}}'**
  String homeLinkExpiring(int days);

  /// Banner at the top of Home when this device's link (its API key) has expired.
  ///
  /// In en, this message translates to:
  /// **'This device’s link has expired'**
  String get homeLinkExpired;

  /// Action of the link-expiry banner: link this device again with a new code.
  ///
  /// In en, this message translates to:
  /// **'Link again'**
  String get homeLinkAgain;

  /// Title of the local notification warning that this device's link (its API key) expires soon.
  ///
  /// In en, this message translates to:
  /// **'This device’s link expires soon'**
  String get keyExpiryNotificationTitle;

  /// Body of the local notification warning that this device's link expires; 1 means today.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{It expires today. Tap to link it again.} other{It expires in {days} days. Tap to link it again.}}'**
  String keyExpiryNotificationBody(int days);

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

  /// Total running time of an album or playlist under an hour, in a detail page's metadata line, e.g. '45 min'.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String detailDurationMinutes(int minutes);

  /// Total running time of an album or playlist from an hour, in a detail page's metadata line, e.g. '1 hr 5 min'.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr {minutes} min'**
  String detailDurationHours(int hours, int minutes);

  /// Number of songs in an album or playlist, in a detail page's metadata line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String detailSongCount(int count);

  /// Snackbar when an album or playlist page could not be refreshed and the saved copy stays on screen.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t refresh. Showing saved content.'**
  String get detailRefreshFailed;

  /// Tooltip, accessibility label and track-row action of the heart button of a track that is not liked.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get likeButtonLike;

  /// Tooltip, accessibility label and track-row action of the heart button of a liked track.
  ///
  /// In en, this message translates to:
  /// **'Remove like'**
  String get likeButtonRemove;

  /// Tooltip and accessibility reason of a track row that cannot be played.
  ///
  /// In en, this message translates to:
  /// **'Not playable'**
  String get trackNotPlayable;

  /// Accessibility hint of a track row: activating it plays the track within its list.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get trackRowPlayHint;

  /// Read last in the accessibility label of the track row that is the current queue item while it plays.
  ///
  /// In en, this message translates to:
  /// **'playing'**
  String get trackRowPlaying;

  /// Read last in the accessibility label of the track row that is the current queue item while it is paused.
  ///
  /// In en, this message translates to:
  /// **'paused'**
  String get trackRowPaused;

  /// Snackbar after playing or queueing more songs than the queue holds; count is the most it holds (5,000).
  ///
  /// In en, this message translates to:
  /// **'Only the first {count} songs were queued'**
  String playQueueTruncated(int count);

  /// Button above the Library Songs list that plays the whole library in a random order.
  ///
  /// In en, this message translates to:
  /// **'Shuffle all'**
  String get librarySongsShuffleAll;

  /// Type label above the title of an album page.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumOverline;

  /// Group header over the tracks of one disc of a multi-disc album.
  ///
  /// In en, this message translates to:
  /// **'Disc {number}'**
  String albumDisc(int number);

  /// Title of the shelf of the artist's other albums on an album page.
  ///
  /// In en, this message translates to:
  /// **'More by this artist'**
  String get albumMoreByArtist;

  /// Type label above the title of a playlist page.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistOverline;

  /// Metadata on a playlist page: the playlist is visible to other users.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get playlistPublic;

  /// Title of the page listing the tracks the user liked.
  ///
  /// In en, this message translates to:
  /// **'Liked Songs'**
  String get playlistLikedTitle;

  /// Shown on a playlist page when the playlist has no songs.
  ///
  /// In en, this message translates to:
  /// **'This playlist has no songs yet'**
  String get playlistEmpty;

  /// Button in the Library's Playlists tab and the sidebar that creates a playlist, and the title of the dialog that names it.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistNew;

  /// Title of the dialog that renames a playlist.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get playlistRenameTitle;

  /// Label of the playlist name field in the create and rename dialogs.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get playlistNameLabel;

  /// Confirm button of the dialog that creates a playlist.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get playlistCreate;

  /// Confirm button of the dialog that renames a playlist.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get playlistRename;

  /// Button that closes a playlist dialog without changing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get playlistCancel;

  /// Title of the dialog confirming that a playlist is deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String playlistDeleteTitle(String name);

  /// Body of the dialog confirming that a playlist is deleted.
  ///
  /// In en, this message translates to:
  /// **'The playlist is removed from your library. The songs in it stay.'**
  String get playlistDeleteBody;

  /// Destructive confirm button of the dialog that deletes a playlist.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get playlistDelete;

  /// Title of the sheet or dialog that picks the playlist to add songs to.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get playlistAddToTitle;

  /// Snackbar after songs were added to a playlist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 song to {name}} other{Added {count} songs to {name}}}'**
  String playlistAdded(int count, String name);

  /// Label of the chip that follows the pointer while several tracks are dragged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String dragTrackCount(int count);

  /// Tooltip and screen-reader label of the drag handle that moves a song within a playlist.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get playlistReorderHandle;

  /// Type label above the name on an artist page.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistOverline;

  /// Title of the section of an artist page listing the artist's most played songs.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get artistPopular;

  /// Button under the Popular title of an artist page: lists more of the artist's most played songs.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get artistShowMore;

  /// Button on an artist page that collapses the expanded Popular list or biography again.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get artistShowLess;

  /// Title of the shelf of an artist's albums on an artist page.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get artistAlbums;

  /// Title of the shelf of an artist's singles and EPs on an artist page.
  ///
  /// In en, this message translates to:
  /// **'Singles and EPs'**
  String get artistSinglesAndEps;

  /// Title of the shelf of artists similar to this one on an artist page.
  ///
  /// In en, this message translates to:
  /// **'Similar Artists'**
  String get artistSimilar;

  /// Second line of a similar-artist card on an artist page.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artistCardSubtitle;

  /// Title of the biography section of an artist page.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get artistAbout;

  /// Button under the collapsed biography of an artist page: shows the whole text in place.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get artistReadMore;

  /// Placeholder and accessibility label of the field on the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Songs, artists, albums or podcasts'**
  String get searchFieldHint;

  /// Tooltip and accessibility label of the button that empties the field on the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// Filter chip on the Search screen: results from everywhere.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchScopeAll;

  /// Filter chip on the Search screen: only results from the user's library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get searchScopeLibrary;

  /// Filter chip on the Search screen: only results from outside the user's library.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get searchScopeDiscover;

  /// Filter chip on the Search screen: only podcasts.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get searchScopePodcasts;

  /// Heading of the list of the user's recent searches, shown on the Search screen while the field is empty.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentTitle;

  /// Button next to the recent searches heading: forgets every recent search.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchRecentClearAll;

  /// Tooltip and accessibility label of the button that forgets one recent search.
  ///
  /// In en, this message translates to:
  /// **'Remove {query}'**
  String searchRecentRemove(String query);

  /// Shown on the Search screen while the field is empty and there are no recent searches.
  ///
  /// In en, this message translates to:
  /// **'Search for songs, artists, albums and podcasts'**
  String get searchPrompt;

  /// Shown on the Search screen when nothing matches the query.
  ///
  /// In en, this message translates to:
  /// **'No results for “{query}”'**
  String searchNoResults(String query);

  /// Heading of the large card of the best match on the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Top result'**
  String get searchTopResult;

  /// Heading of the songs section of the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get searchSectionSongs;

  /// Heading of the artists section of the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchSectionArtists;

  /// Heading of the albums section of the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchSectionAlbums;

  /// Heading of the section of the user's playlists on the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get searchSectionPlaylists;

  /// Heading of the podcasts section of the Search screen.
  ///
  /// In en, this message translates to:
  /// **'Podcasts'**
  String get searchSectionPodcasts;

  /// Button in a section header of the Search screen: shows every result of that section in place.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get searchShowAll;

  /// Button in an expanded section header of the Search screen: shows the first results only again.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get searchShowLess;

  /// Tooltip and spoken reason of a song row on the Search screen that cannot be played.
  ///
  /// In en, this message translates to:
  /// **'Not playable'**
  String get searchNotPlayable;

  /// Second line of an artist card on the Search screen: what kind of item it is.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get searchKindArtist;

  /// Second line of the top result card on the Search screen when it is a song with no artist name.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get searchKindSong;

  /// Second line of a podcast card on the Search screen when the podcast has no author.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get searchKindPodcast;

  /// Second line of a playlist card on the Search screen: how many songs the playlist has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String searchPlaylistSongs(int count);

  /// Screen-reader label of the six cells a device-link code is typed into.
  ///
  /// In en, this message translates to:
  /// **'Link code, 6 characters'**
  String get codeCellsLabel;

  /// Shown under the device-link code cells when a character that cannot be in a code was typed.
  ///
  /// In en, this message translates to:
  /// **'Codes have no I, O, 0 or 1'**
  String get codeCellsHint;

  /// First of three steps to get a device-link code from the web UI.
  ///
  /// In en, this message translates to:
  /// **'Open soundspan in a browser'**
  String get connectDeviceLinkStep1;

  /// Second of three steps to get a device-link code from the web UI; 'Settings' and 'Link Device' are the web UI's names.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings → Link Device'**
  String get connectDeviceLinkStep2;

  /// Third of three steps to get a device-link code from the web UI; 'Generate Code' is the web UI's button.
  ///
  /// In en, this message translates to:
  /// **'Select Generate Code and enter it below'**
  String get connectDeviceLinkStep3;

  /// Label of the field naming this device on the server when it is linked with a code.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get connectDeviceLinkDeviceName;

  /// Button that links this device with the entered code.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get connectDeviceLinkSubmit;

  /// Button on the address screen and the device-link panel that opens the camera to scan the QR code from the web UI's device page.
  ///
  /// In en, this message translates to:
  /// **'Scan QR code'**
  String get connectScanQrCode;

  /// Instruction under the camera preview of the QR scanner.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the QR code on the Link Device page of the web UI.'**
  String get connectScanHint;

  /// Shown for three seconds under the camera preview when the scanned QR code is neither a soundspan link nor a server address.
  ///
  /// In en, this message translates to:
  /// **'That is not a soundspan code'**
  String get connectScanRejected;

  /// Shown instead of the camera preview when the user denied the camera permission.
  ///
  /// In en, this message translates to:
  /// **'soundspan cannot use the camera to scan the code.'**
  String get connectScanPermissionDenied;

  /// Tells the user how to allow the camera after denying it; there is no link to the settings.
  ///
  /// In en, this message translates to:
  /// **'To scan, allow camera access for soundspan in your system settings.'**
  String get connectScanAllowCamera;

  /// Shown instead of the camera preview when the device has no usable camera.
  ///
  /// In en, this message translates to:
  /// **'No camera available'**
  String get connectScanNoCamera;

  /// Button on the QR scanner's fallback screen that returns to typing the device-link code.
  ///
  /// In en, this message translates to:
  /// **'Enter the code instead'**
  String get connectScanEnterCode;

  /// Inline error when the server knows no such device-link code.
  ///
  /// In en, this message translates to:
  /// **'That code does not exist. Generate a new code in the web UI.'**
  String get connectDeviceLinkInvalidCode;

  /// Inline error when the device-link code was used before.
  ///
  /// In en, this message translates to:
  /// **'That code has already been used. Generate a new code in the web UI.'**
  String get connectDeviceLinkCodeUsed;

  /// Inline error when the device-link code is too old.
  ///
  /// In en, this message translates to:
  /// **'That code has expired. Generate a new code in the web UI.'**
  String get connectDeviceLinkCodeExpired;

  /// Inline error when the server turned the device-link code down without saying why.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept the code. Generate a new code in the web UI.'**
  String get connectDeviceLinkRejected;

  /// Secondary action on the password sign-in screen that shows the device-link panel instead.
  ///
  /// In en, this message translates to:
  /// **'Link with a code'**
  String get connectSignInLinkWithCode;

  /// Secondary action on the device-link panel that goes back to the password form.
  ///
  /// In en, this message translates to:
  /// **'Sign in with a password'**
  String get connectSignInUsePassword;

  /// Note on the password sign-in screen of a server that also offers single sign-on.
  ///
  /// In en, this message translates to:
  /// **'Single sign-on users: link this device with a code.'**
  String get connectSignInSsoNote;

  /// Heading of the device-link panel.
  ///
  /// In en, this message translates to:
  /// **'Link this device'**
  String get connectLinkThisDevice;

  /// Heading of the device-link panel on a server that offers only single sign-on, naming its provider.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider}'**
  String connectSignInWithProvider(String provider);

  /// Window title part and route name of a podcast page.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get screenPodcast;

  /// Title of the grid of the podcasts the user is subscribed to on the Podcasts screen.
  ///
  /// In en, this message translates to:
  /// **'Your podcasts'**
  String get podcastsYourPodcasts;

  /// Title of the shelf of popular podcasts from the directory on the Podcasts screen.
  ///
  /// In en, this message translates to:
  /// **'Top podcasts'**
  String get podcastsTopPodcasts;

  /// Shown on the Podcasts screen when the user is subscribed to no podcast.
  ///
  /// In en, this message translates to:
  /// **'You haven’t subscribed to any podcasts yet'**
  String get podcastsEmpty;

  /// Type label above the title on a podcast page.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get podcastsOverline;

  /// Part of the metadata line of a podcast page: how many episodes the podcast has.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String podcastsEpisodeCount(int count);

  /// Button that subscribes the user to a podcast, on a podcast page and in the dialog of a top podcast.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get podcastsSubscribe;

  /// Button on a podcast page that unsubscribes the user from the podcast, and the confirming action of its dialog.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get podcastsUnsubscribe;

  /// Title of the dialog confirming that the user wants to unsubscribe from a podcast.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe from {title}?'**
  String podcastsUnsubscribeTitle(String title);

  /// Body of the dialog confirming that the user wants to unsubscribe from a podcast.
  ///
  /// In en, this message translates to:
  /// **'The podcast leaves your podcasts. You can subscribe again later.'**
  String get podcastsUnsubscribeBody;

  /// Dismisses a Podcasts dialog without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get podcastsCancel;

  /// Tooltip of the disabled Subscribe or Unsubscribe button while the server is not reachable.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions can be changed only while the server is reachable'**
  String get podcastsOfflineTooltip;

  /// Snackbar shown when subscribing to a podcast failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t subscribe. Try again.'**
  String get podcastsSubscribeFailed;

  /// Snackbar shown when unsubscribing from a podcast failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t unsubscribe. Try again.'**
  String get podcastsUnsubscribeFailed;

  /// Button under the collapsed description of a podcast page: shows the whole description.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get podcastsShowMore;

  /// Button under the expanded description of a podcast page: collapses it to three lines again.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get podcastsShowLess;

  /// Label next to the check of an episode the user finished.
  ///
  /// In en, this message translates to:
  /// **'Played'**
  String get podcastsEpisodePlayed;

  /// An episode's length as a screen reader says it, in whole minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String podcastsEpisodeMinutes(int count);

  /// How much of a started episode is left, as a screen reader says it, in whole minutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute left} other{{count} minutes left}}'**
  String podcastsEpisodeMinutesLeft(int count);

  /// Last part of the screen-reader label of an episode the user finished, e.g. the 'played' of 'Title, Mar 12, 2026, 42 minutes, played'.
  ///
  /// In en, this message translates to:
  /// **'played'**
  String get podcastsEpisodePlayedSpoken;

  /// Sidebar item, Home card and screen name of Explore, the page of recommendations and new music.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get navExplore;

  /// Title of the Home row and the Explore section of artists similar to the ones the user plays most.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get discoverRecommendedForYou;

  /// Title of the Home row and the Explore section of artists popular right now.
  ///
  /// In en, this message translates to:
  /// **'Popular Artists'**
  String get discoverPopularArtists;

  /// Second line of a card of a recommended or popular artist: what kind of item it is.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get discoverCardArtist;

  /// Title of the Explore section of this week's discovery playlist.
  ///
  /// In en, this message translates to:
  /// **'This week’s discoveries'**
  String get exploreThisWeek;

  /// Button of the Explore discovery section that plays its tracks in order.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get explorePlay;

  /// Button of the Explore discovery section that plays its tracks in random order.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get exploreShuffle;

  /// Button under the first tracks of the Explore discovery section that shows every track.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get exploreShowAll;

  /// Shown on Explore when every section is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to explore yet'**
  String get exploreEmpty;

  /// Second line of the Explore card at the end of Home on phones and tablets.
  ///
  /// In en, this message translates to:
  /// **'Find new artists and music'**
  String get homeExploreCard;

  /// Title of the Explore section of radio stations, one per genre of the user's library.
  ///
  /// In en, this message translates to:
  /// **'Radio by genre'**
  String get exploreRadioByGenre;

  /// Title of the Explore section of radio stations, one per decade of the user's library.
  ///
  /// In en, this message translates to:
  /// **'Radio by decade'**
  String get exploreRadioByDecade;

  /// Button under the first genre stations of Explore that shows every genre station.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get exploreRadioShowAll;

  /// Name of a decade radio station, from the decade's first year, such as 1990s.
  ///
  /// In en, this message translates to:
  /// **'{decade}s'**
  String exploreRadioDecade(String decade);

  /// Caption of a radio station tile: how many library tracks the station draws from.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String exploreRadioTrackCount(int count);

  /// Screen-reader label of a radio station tile on Explore.
  ///
  /// In en, this message translates to:
  /// **'{station}, {tracks}, radio station'**
  String exploreRadioStationSemantics(String station, String tracks);

  /// Snackbar when a radio station returned no playable tracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks for this station'**
  String get exploreRadioNoTracks;

  /// Snackbar when starting a radio station failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start the station'**
  String get exploreRadioFailed;

  /// Action of the snackbar shown when starting a radio station failed; starts it again.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get exploreRadioRetry;

  /// Tooltip and screen-reader reason of a radio station tile that cannot start because the server is not reachable.
  ///
  /// In en, this message translates to:
  /// **'Not available offline'**
  String get exploreRadioOffline;

  /// Queue header and now-playing overline while the queue plays a radio station.
  ///
  /// In en, this message translates to:
  /// **'Radio · {station}'**
  String queueContextRadio(String station);

  /// Secondary action on the sign-in screen that shows the form for signing in with an API key copied from the web UI.
  ///
  /// In en, this message translates to:
  /// **'Use an API key'**
  String get connectSignInUseApiKey;

  /// Heading of the form that signs in with an API key pasted from the web UI.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an API key'**
  String get connectApiKeyHeading;

  /// Label of the field the API key is pasted into.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get connectApiKeyField;

  /// Tooltip of the button that reveals the pasted API key.
  ///
  /// In en, this message translates to:
  /// **'Show API key'**
  String get connectApiKeyShow;

  /// Tooltip of the button that hides the pasted API key again.
  ///
  /// In en, this message translates to:
  /// **'Hide API key'**
  String get connectApiKeyHide;

  /// Button that fills the API key field from the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get connectApiKeyPaste;

  /// Note under the API key form: the app cannot tell when a pasted key expires.
  ///
  /// In en, this message translates to:
  /// **'This key’s expiry date is not known to the app. You will be asked to sign in again when the server stops accepting it.'**
  String get connectApiKeyExpiryUnknown;

  /// Inline error: the pasted text is empty, too long or has characters an API key cannot have.
  ///
  /// In en, this message translates to:
  /// **'This is not an API key. Copy the whole key from the web UI and paste it here.'**
  String get connectApiKeyMalformed;

  /// Inline error: the server answered the API key with 401 or 403.
  ///
  /// In en, this message translates to:
  /// **'The server did not accept this key. It may have expired or been revoked.'**
  String get connectApiKeyRejected;

  /// Shown in the browser app when the server offers neither password sign-in nor single sign-on, leaving only API keys, which the browser app cannot use.
  ///
  /// In en, this message translates to:
  /// **'This server offers no sign-in method this app can use in a browser.'**
  String get connectSignInNoBrowserMethod;

  /// Shown on a greyed-out track of a downloaded album or playlist when the server administrator turned offline downloads off.
  ///
  /// In en, this message translates to:
  /// **'Downloads are turned off on this server'**
  String get downloadUnavailableDisabled;

  /// Shown on a greyed-out track of a downloaded album or playlist that the server no longer has.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get downloadUnavailableGone;

  /// Shown on a greyed-out track of a downloaded album or playlist that this account cannot stream, so cannot download.
  ///
  /// In en, this message translates to:
  /// **'Not available for your account'**
  String get downloadUnavailableAccount;

  /// Tooltip and screen-reader label of the player's play button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// Tooltip and screen-reader label of the player's pause button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// Tooltip and screen-reader label of the player's button that moves back in an episode by the skip interval.
  ///
  /// In en, this message translates to:
  /// **'Skip back {seconds} seconds'**
  String playerSkipBack(int seconds);

  /// Tooltip and screen-reader label of the player's button that moves forward in an episode by the skip interval.
  ///
  /// In en, this message translates to:
  /// **'Skip forward {seconds} seconds'**
  String playerSkipForward(int seconds);

  /// Tooltip and screen-reader label of the player's episode speed menu button.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playerSpeed;

  /// An episode playback speed on the player's speed button and in its menu, such as 1.25×.
  ///
  /// In en, this message translates to:
  /// **'{speed}×'**
  String playerSpeedValue(double speed);

  /// Tooltip and screen-reader label of the player's button that skips to the next item.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// Tooltip and screen-reader label of the player's button that goes back to the previous item or the start of this one.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrevious;

  /// Tooltip and screen-reader label of the player's shuffle toggle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get playerShuffle;

  /// Tooltip and screen-reader label of the player's repeat button while repeat is off; a tap repeats the queue.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get playerRepeatOff;

  /// Tooltip and screen-reader label of the player's repeat button while the whole queue repeats; a tap repeats the current item.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get playerRepeatAll;

  /// Tooltip and screen-reader label of the player's repeat button while the current item repeats; a tap turns repeat off.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get playerRepeatOne;

  /// Screen-reader label of the player's volume slider.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get playerVolume;

  /// Screen-reader label of the seek bar that shows and changes the position in the playing item.
  ///
  /// In en, this message translates to:
  /// **'Seek'**
  String get playerSeek;

  /// Screen-reader value of the seek bar: the position and the length of the playing item, each as m:ss or h:mm:ss, e.g. 1:05 of 3:41.
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String playerSeekValue(String position, String duration);

  /// Label at the top of the now-playing screen, shown in upper case.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlayingOverline;

  /// Tooltip of the button that closes the now-playing screen.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get nowPlayingClose;

  /// Tooltip of the button that shows the play queue, on the now-playing screen and on the player bar.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get nowPlayingQueue;

  /// Accessibility label of the system audio output picker (AirPlay) on the now-playing screen.
  ///
  /// In en, this message translates to:
  /// **'Audio output'**
  String get nowPlayingAudioOutput;

  /// Tooltip of the player bar button that shows large artwork of the playing item over the content area.
  ///
  /// In en, this message translates to:
  /// **'Show now playing'**
  String get nowPlayingExpand;

  /// Tooltip of the player bar button that hides the large artwork of the playing item.
  ///
  /// In en, this message translates to:
  /// **'Hide now playing'**
  String get nowPlayingCollapse;

  /// Title of the lyrics panel and sheet, and tooltip of the button that shows the lyrics, on the now-playing screen and on the player bar.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyricsTitle;

  /// Shown in the lyrics view when the server has no lyrics for the current track.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found'**
  String get lyricsNone;

  /// Screen-reader hint of a synced lyrics line: activating it moves playback to the time the line starts.
  ///
  /// In en, this message translates to:
  /// **'Seek to {time}'**
  String lyricsSeekHint(String time);

  /// Screen-reader label of a synced lyrics line without words (an instrumental gap), drawn as a ♪ marker.
  ///
  /// In en, this message translates to:
  /// **'Instrumental'**
  String get lyricsInstrumental;

  /// Button shown over the synced lyrics after the user scrolls them by hand; it makes the lyrics follow the current line again.
  ///
  /// In en, this message translates to:
  /// **'Resume auto-scroll'**
  String get lyricsResumeAutoScroll;

  /// Title of the play queue panel and sheet.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// Header of the queue section holding the playing entry.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get queueNowPlaying;

  /// Header of the queue section listing the entries that play after the current one.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get queueNextUp;

  /// Action that empties the play queue.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get queueClear;

  /// Sentence shown when the play queue is empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is queued'**
  String get queueEmpty;

  /// Tooltip and screen-reader action of the button that removes an entry from the play queue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get queueRemove;

  /// Screen-reader action that moves a queue entry one place earlier.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get queueMoveUp;

  /// Screen-reader action that moves a queue entry one place later.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get queueMoveDown;

  /// Tooltip of the handle that reorders a queue entry by dragging.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get queueReorderHandle;

  /// Quality badge of the playing stream with a bit depth: codec, bit depth and sample rate in kilohertz, e.g. FLAC · 24/96 kHz.
  ///
  /// In en, this message translates to:
  /// **'{codec} · {bitDepth}/{sampleRate} kHz'**
  String qualityBadgeSampleRate(
    String codec,
    String bitDepth,
    String sampleRate,
  );

  /// Quality badge of the playing stream without a bit depth: codec and bit rate in kilobits per second, e.g. AAC · 256 kbps.
  ///
  /// In en, this message translates to:
  /// **'{codec} · {bitrate} kbps'**
  String qualityBadgeBitrate(String codec, String bitrate);

  /// Quality badge of an item playing from a file downloaded to this device, when no download quality was stored.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get qualityBadgeDownloaded;

  /// Quality badge of an item playing from a file downloaded to this device: the word Downloaded and the quality it was downloaded at, one of the stream quality choices (Original, High, Medium, Low).
  ///
  /// In en, this message translates to:
  /// **'Downloaded · {quality}'**
  String qualityBadgeDownloadedQuality(String quality);

  /// Menu entry that replaces the queue with the list and plays this item.
  ///
  /// In en, this message translates to:
  /// **'Play now'**
  String get menuPlayNow;

  /// Menu entry that inserts the item after the current queue item.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get menuPlayNext;

  /// Menu entry and track-row accessibility action that appends the item to the queue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get menuAddToQueue;

  /// Menu entry that opens the playlist picker to add the item's songs.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist…'**
  String get menuAddToPlaylist;

  /// Menu entry of a track inside a playlist the user owns that removes it from that playlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from this playlist'**
  String get menuRemoveFromPlaylist;

  /// Menu entry that opens the track's album page.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get menuGoToAlbum;

  /// Menu entry that opens the artist page.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get menuGoToArtist;

  /// Menu entry that copies a soundspan:// link to the item to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get menuShareLink;

  /// Snackbar after Share link copied a link to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get menuLinkCopied;

  /// Menu entry of a playlist the user owns that renames it.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get menuRename;

  /// Menu entry of a playlist the user owns that deletes it, after a confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get menuDelete;

  /// Tooltip, accessibility label and track-row accessibility action of the button that opens an item's menu.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get menuMoreOptions;

  /// Label of the Play button of an album, artist or playlist page.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actionPlay;

  /// Tooltip and accessibility label of the Shuffle button of an album, artist or playlist page.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get actionShuffle;

  /// Tooltip and accessibility label of the Add to playlist button of an album or playlist page.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get actionAddToPlaylist;

  /// Title of the Desktop settings section, which lists the keyboard shortcuts.
  ///
  /// In en, this message translates to:
  /// **'Desktop'**
  String get screenSettingsDesktop;

  /// Heading of the list of keyboard shortcuts in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Keyboard shortcuts'**
  String get settingsShortcutsTitle;

  /// What the Space shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Play or pause'**
  String get shortcutPlayPause;

  /// What the next-track shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get shortcutNext;

  /// What the previous-track shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get shortcutPrevious;

  /// What the seek-forward shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Seek forward {seconds} seconds'**
  String shortcutSeekForward(int seconds);

  /// What the seek-back shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Seek back {seconds} seconds'**
  String shortcutSeekBack(int seconds);

  /// What the volume-up shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Volume up'**
  String get shortcutVolumeUp;

  /// What the volume-down shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Volume down'**
  String get shortcutVolumeDown;

  /// What the shuffle shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on or off'**
  String get shortcutShuffle;

  /// What the repeat shortcut does (off, all, one), as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Change repeat'**
  String get shortcutRepeat;

  /// What the like shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Like or remove like of the current track'**
  String get shortcutLike;

  /// What the search shortcut does (focus the search field), as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get shortcutSearch;

  /// What a navigation shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Go to {destination}'**
  String shortcutGoTo(String destination);

  /// What the queue shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the queue'**
  String get shortcutQueue;

  /// What Enter on a track row does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Play the selected tracks'**
  String get shortcutPlayRow;

  /// What Shift+Enter on a track row does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Play the selected tracks next'**
  String get shortcutPlayRowNext;

  /// What Delete on a row of a playlist the user owns does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Remove the selected tracks from the playlist'**
  String get shortcutRemoveRow;

  /// What the Menu key and Shift+F10 do, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Open the menu of the focused item'**
  String get shortcutMenu;

  /// What the refresh shortcut does, as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get shortcutRefresh;

  /// What F6 does (move focus to the next area of the window), as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Next area'**
  String get shortcutNextArea;

  /// What Shift+F6 does (move focus to the previous area of the window), as listed in Settings → Desktop.
  ///
  /// In en, this message translates to:
  /// **'Previous area'**
  String get shortcutPreviousArea;

  /// Name of the Control key in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Ctrl'**
  String get keyCtrl;

  /// Name of the Command key in a shortcut on macOS.
  ///
  /// In en, this message translates to:
  /// **'Cmd'**
  String get keyCmd;

  /// Name of the Shift key in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get keyShift;

  /// Name of the Alt key in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Alt'**
  String get keyAlt;

  /// Name of the Option key in a shortcut on macOS.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get keyOption;

  /// Name of the space bar in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get keySpace;

  /// Name of the Enter key in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get keyEnter;

  /// Name of the Delete key in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get keyDelete;

  /// Name of the Menu (context menu) key in a shortcut.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get keyMenu;

  /// The mouse's back button, listed beside the Back shortcut.
  ///
  /// In en, this message translates to:
  /// **'Mouse back button'**
  String get keyMouseBack;

  /// The mouse's forward button, listed beside the Forward shortcut.
  ///
  /// In en, this message translates to:
  /// **'Mouse forward button'**
  String get keyMouseForward;

  /// Storage settings: heading of the download settings.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsStorageDownloads;

  /// Storage settings: row choosing the audio quality of downloads.
  ///
  /// In en, this message translates to:
  /// **'Download quality'**
  String get settingsStorageDownloadQuality;

  /// Storage settings: caption under the download quality row; items already downloaded keep their quality.
  ///
  /// In en, this message translates to:
  /// **'The quality applies to new downloads.'**
  String get settingsStorageDownloadQualityCaption;

  /// Storage settings: switch that keeps downloads from running on mobile data.
  ///
  /// In en, this message translates to:
  /// **'Download on Wi-Fi only'**
  String get settingsStorageWifiOnly;

  /// Storage settings: title of the slider setting the most space downloads may use on this device.
  ///
  /// In en, this message translates to:
  /// **'Device limit'**
  String get settingsStorageDeviceLimit;

  /// Storage settings: the device limit step that sets no limit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get settingsStorageNoLimit;

  /// Storage settings: the space downloads use against the device limit.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} used'**
  String settingsStorageDeviceLimitUsage(String used, String limit);

  /// Storage settings: the space downloads use when the device limit is off.
  ///
  /// In en, this message translates to:
  /// **'{used} used, no limit'**
  String settingsStorageDeviceLimitUsageUnlimited(String used);

  /// Storage settings: destructive action deleting every download of this server on this device.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloads'**
  String get settingsStorageRemoveAll;

  /// Title of the dialog confirming that every download is removed.
  ///
  /// In en, this message translates to:
  /// **'Remove all downloads?'**
  String get settingsStorageRemoveAllTitle;

  /// Body of the dialog confirming that every download is removed.
  ///
  /// In en, this message translates to:
  /// **'This frees {size} on this device. You can download them again later.'**
  String settingsStorageRemoveAllBody(String size);

  /// Confirm button of the dialog removing every download.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get settingsStorageRemoveAllConfirm;

  /// Storage settings: heading of the space this server’s data uses on the device.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsStorageThisDevice;

  /// Storage settings: usage row of the downloaded tracks and episodes.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get settingsStorageUsageDownloads;

  /// Storage settings: the number of downloaded tracks and episodes, under the Downloads usage row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String settingsStorageUsageDownloadCount(int count);

  /// Storage settings: usage row of the saved artwork images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get settingsStorageUsageImages;

  /// Storage settings: usage row of the app’s databases for this server.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get settingsStorageUsageDatabase;

  /// Storage settings: usage row of the free space left on the device.
  ///
  /// In en, this message translates to:
  /// **'Free space'**
  String get settingsStorageUsageFree;

  /// Storage settings: heading of the server’s download storage figures.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get settingsStorageServer;

  /// Storage settings: the space the user’s downloads take on the server against the server’s limit.
  ///
  /// In en, this message translates to:
  /// **'Used on the server: {used} of {limit}'**
  String settingsStorageServerUsed(String used, String limit);

  /// Storage settings: the part of the server figure that this device downloaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{From this device: {size}, 1 track} other{From this device: {size}, {count} tracks}}'**
  String settingsStorageServerDevice(int count, String size);

  /// Storage settings: caption under the server figures, which are read-only here.
  ///
  /// In en, this message translates to:
  /// **'The server limit is changed in the server’s settings.'**
  String get settingsStorageServerCaption;

  /// Storage settings: heading of the cache actions.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get settingsStorageCache;

  /// Storage settings: action deleting saved images and browsing data.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsStorageClearCache;

  /// Storage settings: caption under the Clear cache action.
  ///
  /// In en, this message translates to:
  /// **'Saved images and browsing data are fetched again when needed. Downloads stay.'**
  String get settingsStorageClearCacheCaption;

  /// Title of the dialog confirming that the cache is cleared.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get settingsStorageClearCacheTitle;

  /// Body of the dialog confirming that the cache is cleared.
  ///
  /// In en, this message translates to:
  /// **'Saved images and browsing data are deleted. Downloads and playback are not affected.'**
  String get settingsStorageClearCacheBody;

  /// Confirm button of the dialog clearing the cache.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsStorageClearCacheConfirm;

  /// Cancel button of the storage settings dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsStorageCancel;

  /// Screen-reader label of the download glyph of an item waiting to download.
  ///
  /// In en, this message translates to:
  /// **'Waiting to download'**
  String get downloadGlyphQueued;

  /// Screen-reader label of the download glyph of an item being downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloading, {percent} percent'**
  String downloadGlyphRunning(int percent);

  /// Screen-reader label of the download glyph of an item being downloaded whose size is not known.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadGlyphRunningUnknown;

  /// Screen-reader label of the download glyph of a downloaded item.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadGlyphCompleted;

  /// Screen-reader label of the download glyph of an item whose download failed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadGlyphFailed;

  /// Screen-reader label of the download glyph of an item the server will not let this device download.
  ///
  /// In en, this message translates to:
  /// **'Not available for download'**
  String get downloadGlyphUnavailable;

  /// Appended to a track row’s screen-reader label when the track is downloaded, as in 'Title, Artist, 3 minutes, downloaded'.
  ///
  /// In en, this message translates to:
  /// **'downloaded'**
  String get trackRowDownloaded;

  /// Menu entry and action-bar button that keeps a track, album or playlist on this device.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get menuDownload;

  /// Menu entry and action-bar button that deletes a downloaded track, album or playlist from this device.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get menuRemoveDownload;

  /// Menu entry that tries a failed download again.
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get menuRetryDownload;

  /// Menu entry on a downloaded album or playlist that asks the server for changes to it now, so the download follows them.
  ///
  /// In en, this message translates to:
  /// **'Check for changes'**
  String get menuCheckForChanges;

  /// Title of the dialog confirming that a download is removed.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get downloadRemoveTitle;

  /// Body of the dialog confirming that a download is removed.
  ///
  /// In en, this message translates to:
  /// **'Its files are deleted from this device. You can download it again later.'**
  String get downloadRemoveBody;

  /// Confirm button of the dialog removing a download.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get downloadRemoveConfirm;

  /// Cancel button of the download dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadCancel;

  /// Button that closes a download sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get downloadClose;

  /// Title of the sheet shown when the server refused a download because the user’s download limit there is reached.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on the server'**
  String get downloadServerQuotaTitle;

  /// Body of the sheet shown when the server’s download limit is reached.
  ///
  /// In en, this message translates to:
  /// **'Remove downloads to free up space, or raise the download limit in the server’s settings.'**
  String get downloadServerQuotaBody;

  /// A byte value on a download sheet: what the download needs.
  ///
  /// In en, this message translates to:
  /// **'Needed: {size}'**
  String downloadSizeNeeded(String size);

  /// A byte value on a download sheet: what is already used.
  ///
  /// In en, this message translates to:
  /// **'Used: {size}'**
  String downloadSizeUsed(String size);

  /// A byte value on a download sheet: the limit.
  ///
  /// In en, this message translates to:
  /// **'Limit: {size}'**
  String downloadSizeLimit(String size);

  /// A byte value on a download sheet: the room left on this device.
  ///
  /// In en, this message translates to:
  /// **'Available: {size}'**
  String downloadSizeAvailable(String size);

  /// Action of the server-limit sheet that opens the Downloads tab.
  ///
  /// In en, this message translates to:
  /// **'Manage downloads'**
  String get downloadManage;

  /// Title of the sheet shown when a download does not fit in the device limit.
  ///
  /// In en, this message translates to:
  /// **'{size} more needed on this device'**
  String downloadShortfallTitle(String size);

  /// Action that raises the device download limit so the whole download fits.
  ///
  /// In en, this message translates to:
  /// **'Raise limit'**
  String get downloadRaiseLimit;

  /// Action that keeps the device limit and downloads what fits in it.
  ///
  /// In en, this message translates to:
  /// **'Download what fits'**
  String get downloadWhatFits;

  /// Shown instead of raising the device limit when free disk space, not the limit, is what stops the download.
  ///
  /// In en, this message translates to:
  /// **'There isn’t enough free space on this device. Free up space, then try again.'**
  String get downloadRaiseLimitDiskFull;

  /// Title of the sheet listing the tracks of an album or playlist that cannot be downloaded.
  ///
  /// In en, this message translates to:
  /// **'Some tracks can’t be downloaded'**
  String get downloadUnavailableTitle;

  /// Shown on a greyed-out track of a downloaded album or playlist for a reason this app does not know.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get downloadUnavailableOther;

  /// Library tab listing what is downloaded on this device.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get libraryTabDownloads;

  /// Storage summary at the top of the Downloads tab: the number of downloaded items and their size.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No items} =1{1 item} other{{count} items}} · {size}'**
  String downloadsSummary(int count, String size);

  /// Shown in the Downloads tab header while items are downloading.
  ///
  /// In en, this message translates to:
  /// **'{count} in progress'**
  String downloadsInProgressCount(int count);

  /// Filter chip of the Downloads tab showing only collections still downloading.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get downloadsFilterInProgress;

  /// Downloads tab button pausing every download.
  ///
  /// In en, this message translates to:
  /// **'Pause all'**
  String get downloadsPauseAll;

  /// Downloads tab button resuming every paused download.
  ///
  /// In en, this message translates to:
  /// **'Resume all'**
  String get downloadsResumeAll;

  /// Empty state of the Downloads tab.
  ///
  /// In en, this message translates to:
  /// **'Nothing downloaded yet. Choose Download on an album, a playlist or a song to keep it on this device.'**
  String get downloadsEmpty;

  /// Shown on a Downloads tab row that waits for the server to be reachable.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get downloadsWaitingForConnection;

  /// Shown on a Downloads tab row whose album or playlist was deleted on the server; the downloaded files stay on this device.
  ///
  /// In en, this message translates to:
  /// **'No longer on the server'**
  String get downloadsSourceGone;

  /// Kind of a downloaded collection, on a Downloads tab row.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get downloadsKindAlbum;

  /// Kind of a downloaded collection, on a Downloads tab row.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get downloadsKindPlaylist;

  /// Kind of a downloaded collection, on a Downloads tab row.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get downloadsKindTrack;

  /// Subtitle of a Downloads tab row: its kind and how many of its items are downloaded.
  ///
  /// In en, this message translates to:
  /// **'{kind} · {completed} of {total}'**
  String downloadsItemsProgress(String kind, int completed, int total);

  /// Downloads tab row menu entry pausing its download.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get downloadsPause;

  /// Downloads tab row menu entry resuming its download.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get downloadsResume;

  /// Avatar menu entry, sidebar item and screen name of Listen Together, where users play music in sync with others.
  ///
  /// In en, this message translates to:
  /// **'Listen Together'**
  String get listenTogetherTitle;

  /// Label of the Listen Together entry in the avatar menu and the sidebar while the user is in a group.
  ///
  /// In en, this message translates to:
  /// **'In a group'**
  String get listenTogetherInGroup;

  /// Listen Together lobby heading above the group the user is a member of.
  ///
  /// In en, this message translates to:
  /// **'Your groups'**
  String get listenTogetherYourGroups;

  /// Listen Together lobby heading above the public groups anyone can join.
  ///
  /// In en, this message translates to:
  /// **'Public groups'**
  String get listenTogetherPublicGroups;

  /// Listen Together lobby when there is no group to show.
  ///
  /// In en, this message translates to:
  /// **'Listen with others in sync'**
  String get listenTogetherEmpty;

  /// Listen Together action that opens the form to create a group.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get listenTogetherCreate;

  /// Listen Together action that opens the field to join a group by its code.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get listenTogetherJoinWithCode;

  /// Button on a Listen Together group row, or in the join form, that joins the group.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get listenTogetherJoin;

  /// Second line of a Listen Together group row: the host's name and how many members the group has.
  ///
  /// In en, this message translates to:
  /// **'{host} · {count, plural, =1{1 member} other{{count} members}}'**
  String listenTogetherGroupRowDetails(String host, int count);

  /// Label of the group name field of the create group form.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get listenTogetherNameLabel;

  /// Error under the group name field when the name is longer than 80 characters.
  ///
  /// In en, this message translates to:
  /// **'Use at most 80 characters'**
  String get listenTogetherNameTooLong;

  /// Visibility choice: the group is joined by its code only.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get listenTogetherPrivate;

  /// Visibility choice: the group is listed for everyone on the server.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get listenTogetherPublic;

  /// Switch of the create group form: the group starts with the music queued on this device.
  ///
  /// In en, this message translates to:
  /// **'Start with my current queue'**
  String get listenTogetherStartWithQueue;

  /// Button of the create group form that creates the group.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get listenTogetherCreateSubmit;

  /// Cancel button of the Listen Together forms and dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get listenTogetherCancel;

  /// Label of the field that takes the code of the group to join.
  ///
  /// In en, this message translates to:
  /// **'Group code'**
  String get listenTogetherCodeLabel;

  /// Error of the join form when no group has the code entered.
  ///
  /// In en, this message translates to:
  /// **'No group with that code'**
  String get listenTogetherNoGroupWithCode;

  /// Visibility line in the header of a Listen Together group.
  ///
  /// In en, this message translates to:
  /// **'Public group'**
  String get listenTogetherPublicGroup;

  /// Visibility line in the header of a Listen Together group.
  ///
  /// In en, this message translates to:
  /// **'Private group'**
  String get listenTogetherPrivateGroup;

  /// Line in the header of a Listen Together group naming its host.
  ///
  /// In en, this message translates to:
  /// **'Hosted by {name}'**
  String listenTogetherHostedBy(String name);

  /// Shown in the header of a Listen Together group while the connection to the server is being restored.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get listenTogetherReconnecting;

  /// Button that copies the group's join code.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get listenTogetherCopyCode;

  /// Announced after the group's join code was copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get listenTogetherCopied;

  /// Heading of the member list of a Listen Together group.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get listenTogetherMembers;

  /// Label next to the member who hosts the group.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get listenTogetherHost;

  /// Heading above the group's current track.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get listenTogetherNowPlaying;

  /// Action of a Listen Together group that shows the group's queue.
  ///
  /// In en, this message translates to:
  /// **'Open queue'**
  String get listenTogetherOpenQueue;

  /// Action that leaves the Listen Together group.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get listenTogetherLeave;

  /// Action, for the host only, that ends the Listen Together group for every member.
  ///
  /// In en, this message translates to:
  /// **'End group for everyone'**
  String get listenTogetherEnd;

  /// Title of the dialog confirming the host ends the group.
  ///
  /// In en, this message translates to:
  /// **'End the group?'**
  String get listenTogetherEndTitle;

  /// Body of the dialog confirming the host ends the group.
  ///
  /// In en, this message translates to:
  /// **'Everyone leaves the group and playback stops for them.'**
  String get listenTogetherEndBody;

  /// Confirm button of the dialog that ends the group.
  ///
  /// In en, this message translates to:
  /// **'End group'**
  String get listenTogetherEndConfirm;

  /// Shown on Listen Together after the host ended the group.
  ///
  /// In en, this message translates to:
  /// **'The host ended the group'**
  String get listenTogetherEndedByHost;

  /// Shown on Listen Together after this user was removed from the group.
  ///
  /// In en, this message translates to:
  /// **'You were removed from the group'**
  String get listenTogetherRemoved;

  /// Header of the queue while in a Listen Together group: the group's name and how many members it has.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count} listening'**
  String listenTogetherQueueHeader(String name, int count);

  /// Tooltip and hint of playback controls that are disabled because only the group's host controls playback.
  ///
  /// In en, this message translates to:
  /// **'The host controls playback'**
  String get listenTogetherHostControls;

  /// Shown when a playback command sent to the group got no answer in time.
  ///
  /// In en, this message translates to:
  /// **'The server didn’t respond'**
  String get listenTogetherNoResponse;

  /// Shown when the server refused a playback command sent to the group without saying why.
  ///
  /// In en, this message translates to:
  /// **'The group didn’t accept that'**
  String get listenTogetherCommandRejected;

  /// Shown when a playback control the group does not have was used.
  ///
  /// In en, this message translates to:
  /// **'Not available while in a group'**
  String get listenTogetherNotInGroup;

  /// Shown when episodes or tracks that cannot be shared were left out of what was added to the group's queue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item can’t be shared with the group} other{{count} items can’t be shared with the group}}'**
  String listenTogetherNotShareable(int count);

  /// Title of the dialog confirming Play replaces the queue of the Listen Together group.
  ///
  /// In en, this message translates to:
  /// **'Replace the group’s queue?'**
  String get listenTogetherReplaceTitle;

  /// Body of the dialog confirming Play replaces the queue of the Listen Together group.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the group hears this next.'**
  String get listenTogetherReplaceBody;

  /// Confirm button of the dialog that replaces the group's queue.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get listenTogetherReplaceConfirm;

  /// Small label above the title of a generated mix's page, naming what the page shows.
  ///
  /// In en, this message translates to:
  /// **'Mix'**
  String get mixOverline;

  /// Shown on a generated mix's page when the mix has no tracks.
  ///
  /// In en, this message translates to:
  /// **'This mix has no tracks right now'**
  String get mixEmpty;

  /// Shown in place of a generated mix's page when the server has generated mixes turned off.
  ///
  /// In en, this message translates to:
  /// **'Not available on this server'**
  String get mixNotAvailable;

  /// Button on a generated mix's page that saves its tracks as a new playlist of the user.
  ///
  /// In en, this message translates to:
  /// **'Save as playlist'**
  String get actionSaveAsPlaylist;

  /// Title of the dialog that names the playlist a generated mix is saved as.
  ///
  /// In en, this message translates to:
  /// **'Save as playlist'**
  String get mixSaveTitle;

  /// Confirm button of the dialog that saves a generated mix as a playlist.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mixSaveConfirm;

  /// Snackbar after a generated mix was saved as a new playlist.
  ///
  /// In en, this message translates to:
  /// **'Saved to your playlists'**
  String get mixSaved;

  /// Snackbar action opening the playlist a generated mix was just saved as.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get mixSavedOpen;

  /// Filter chip above a library list: shows only what is downloaded to this device.
  ///
  /// In en, this message translates to:
  /// **'Downloaded only'**
  String get libraryDownloadedOnly;

  /// Tooltip and accessibility reason of a track row that has no downloaded file while the app is offline.
  ///
  /// In en, this message translates to:
  /// **'Not available offline'**
  String get trackNotAvailableOffline;

  /// Action of the offline notice in the Library while offline mode is on: turns offline mode off.
  ///
  /// In en, this message translates to:
  /// **'Go online'**
  String get offlineBannerGoOnline;

  /// Switch in the account menu: when on, the app does not contact the server and shows only what is on this device.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get shellMenuOfflineMode;

  /// Label above search results while offline: the results come from what is saved on this device.
  ///
  /// In en, this message translates to:
  /// **'Results from this device'**
  String get searchResultsFromDevice;

  /// The desktop window title while a track plays: its title and artist, followed by the application name.
  ///
  /// In en, this message translates to:
  /// **'{title} — {artist} · soundspan'**
  String windowTitleNowPlaying(String title, String artist);

  /// Tray menu entry that resumes playback.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get trayPlay;

  /// Tray menu entry that pauses playback.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get trayPause;

  /// Tray menu entry that shows the app's window.
  ///
  /// In en, this message translates to:
  /// **'Show window'**
  String get trayShowWindow;

  /// Tray menu entry that quits the app.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get trayQuit;

  /// Disabled tray menu entry naming the current track and its artist.
  ///
  /// In en, this message translates to:
  /// **'{title} — {artist}'**
  String trayNowPlaying(String title, String artist);

  /// Switch in Settings → Desktop: closing the window hides it to the system tray and playback continues.
  ///
  /// In en, this message translates to:
  /// **'Close to tray'**
  String get settingsCloseToTray;

  /// Explanation under the disabled Close to tray switch when the desktop has no system tray.
  ///
  /// In en, this message translates to:
  /// **'No system tray was found'**
  String get settingsCloseToTrayUnavailable;

  /// Question asked when the window is closed while something plays and the desktop has no system tray.
  ///
  /// In en, this message translates to:
  /// **'Keep playing in the background?'**
  String get closeKeepPlayingTitle;

  /// Answer to the close question: minimises the window and keeps playing.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get closeKeepPlaying;

  /// Answer to the close question: quits the app.
  ///
  /// In en, this message translates to:
  /// **'Quit'**
  String get closeQuit;

  /// macOS application menu item that opens Settings.
  ///
  /// In en, this message translates to:
  /// **'Settings…'**
  String get menuSettings;

  /// macOS application menu item that quits the app.
  ///
  /// In en, this message translates to:
  /// **'Quit soundspan'**
  String get menuQuit;

  /// macOS menu bar menu with the playback commands.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get menuPlayback;

  /// macOS menu bar menu that shows the queue and the lyrics.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// macOS menu bar menu with the window commands.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// macOS Playback menu item that plays or pauses.
  ///
  /// In en, this message translates to:
  /// **'Play/Pause'**
  String get menuPlayPause;

  /// macOS Playback menu item that skips to the next item.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get menuNext;

  /// macOS Playback menu item that goes to the previous item.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get menuPrevious;

  /// macOS Playback menu item that turns shuffle on or off.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get menuShuffle;

  /// macOS Playback menu item that changes the repeat mode.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get menuRepeat;

  /// macOS View menu item that shows or hides the queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get menuQueue;

  /// macOS View menu item that shows or hides the lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get menuLyrics;

  /// Sidebar item and title of the Vibe screen, which finds tracks by how they sound.
  ///
  /// In en, this message translates to:
  /// **'Vibe'**
  String get navVibe;

  /// Subtitle of the Vibe card at the end of Home.
  ///
  /// In en, this message translates to:
  /// **'Tracks that sound like what you play'**
  String get homeVibeCard;

  /// Track menu entry that plays tracks that sound like the chosen one.
  ///
  /// In en, this message translates to:
  /// **'Start radio'**
  String get menuStartRadio;

  /// Snackbar when Start radio found no tracks that sound like the chosen one.
  ///
  /// In en, this message translates to:
  /// **'No similar tracks found'**
  String get vibeNoSimilar;

  /// Hint of the Vibe search field, which finds tracks by a description.
  ///
  /// In en, this message translates to:
  /// **'Describe a sound or a mood'**
  String get vibeSearchHint;

  /// Screen reader label of the Vibe search field.
  ///
  /// In en, this message translates to:
  /// **'Search by description'**
  String get vibeSearchLabel;

  /// Tooltip of the button that empties the Vibe search field.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get vibeSearchClear;

  /// Button that plays every track listed on the Vibe screen.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get vibePlayAll;

  /// Title of the Vibe section listing tracks that sound like the current track.
  ///
  /// In en, this message translates to:
  /// **'Similar to what’s playing'**
  String get vibeSimilarTitle;

  /// Shown when a Vibe search found no tracks.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get vibeNoMatches;

  /// Empty state of the Vibe screen while nothing with similar tracks is playing.
  ///
  /// In en, this message translates to:
  /// **'Play a track to see others that sound like it here.'**
  String get vibeExplain;

  /// Shown when the server cannot search by description at the moment.
  ///
  /// In en, this message translates to:
  /// **'Vibe search is unavailable right now'**
  String get vibeSearchUnavailable;
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
