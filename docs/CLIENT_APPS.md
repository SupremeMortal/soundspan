# soundspan Apps

The soundspan apps play music from your own soundspan server on phones, computers and in a browser. This guide covers installing them, connecting them to a server, signing in, listening offline, and fixing connection problems. Operators who want to host the browser version of the app read [Hosting the app's web build](REVERSE_PROXY_AND_TUNNELS.md#hosting-the-apps-web-build).

## What the apps are

One codebase builds the app for Android, iOS, Windows, macOS, Linux and the web. Each copy of the app connects to soundspan servers you choose; no server is built in.

The native apps do things the web UI cannot:

- **Background playback**: music keeps playing with the screen off or the window closed.
- **System media controls**: the lock screen, the notification shade, headset buttons, desktop media keys and the system media panel control playback.
- **Android Auto**: browse and play your library from the car's screen.
- **Downloads**: keep albums, playlists, songs and podcast episodes on the device and play them without a connection.

Some things stay in the web UI: server administration, requesting and acquiring music, account security (password, two-factor authentication, app passwords) and creating API keys. For an administrator, **Settings → Servers → Open server admin** opens the server's administration page in the browser.

| Platform | Minimum version | Download |
| --- | --- | --- |
| Android | Android 8.0 | APK |
| iOS | iOS 15 | None |
| Windows | Windows 10 version 1809, 64-bit (x64) | Setup program, MSIX package |
| macOS | macOS 12, Apple silicon or Intel | Disk image |
| Linux | A distribution of the Ubuntu 22.04 generation or later (GTK 3.24), 64-bit (x64) | `.deb`, AppImage, Flatpak bundle |
| Web | Current Chrome, Firefox, Safari or Edge | Hosted by your server's operator |

## Installing

Every app release is a pre-release on the project's [GitHub releases page](https://github.com/soundspan/soundspan/releases), tagged `client-v<version>`. The files are named after the version, for example `soundspan-<version>-linux-amd64.deb`. Each release also lists the range of soundspan server versions it works with.

The builds are unsigned, so every operating system asks you to confirm before it installs or opens them. The steps below say what to expect.

### Android

1. Download `soundspan-<version>-android-unsigned.apk` on the phone.
2. Open it. Android asks you to allow the browser or file manager to install unknown apps; allow it for that app, then select **Install**.

The APK is signed with a development key, not a release key. Before installing a later build that is signed with a release key, uninstall this one, which removes its downloads and sign-ins.

### iOS

There is no iOS download.

### Windows

- **Setup program** (recommended): `soundspan-<version>-windows-x64-unsigned-setup.exe` installs soundspan for your user only, without administrator rights, with a Start-menu shortcut and an uninstaller. Windows SmartScreen warns that the publisher is unknown: select **More info**, then **Run anyway**.
- **MSIX package**: `soundspan-<version>-windows-x64-unsigned.msix` is unsigned and installs only where Windows is set up to allow unsigned packages. Use the setup program unless you know you need the package.

### macOS

1. Download `soundspan-<version>-macos-universal-unsigned.dmg`, open it and drag **soundspan** into **Applications**.
2. Open soundspan once. macOS refuses to open it because it is not from an identified developer.
3. Open **System Settings → Privacy & Security**, find the message about soundspan and select **Open Anyway**, then confirm.

The same app is also published as `soundspan-<version>-macos-universal-unsigned.zip`.

### Linux

- **Debian and Ubuntu**: `soundspan-<version>-linux-amd64.deb`. Install it with `sudo apt install ./soundspan-<version>-linux-amd64.deb`, which also installs libmpv and the other libraries the app needs.
- **AppImage**: `soundspan-<version>-linux-x64.AppImage` runs on most distributions without installing. Make it executable with `chmod +x soundspan-<version>-linux-x64.AppImage`, then run it.
- **Flatpak**: `soundspan-<version>-linux-x64.flatpak`. Install it with `flatpak install --user soundspan-<version>-linux-x64.flatpak`. With the Flathub remote set up (`flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`), Flatpak installs the `org.freedesktop.Platform` runtime from it when it is missing.

Every Linux package installs the app as `io.soundspan.app` with a menu entry and icons, and starts it as `soundspan`.

### Verifying a download

Each release has a `SHA256SUMS` file listing the SHA-256 checksum of every file. Download it next to your file and check it:

- Linux: `sha256sum --check --ignore-missing SHA256SUMS`
- macOS: `shasum -a 256 <file>`, and compare the result with the file's line in `SHA256SUMS`
- Windows (PowerShell): `Get-FileHash <file> -Algorithm SHA256`, and compare the result with the file's line in `SHA256SUMS`

With the GitHub CLI you can also check that a file was built by the project's release workflow: `gh attestation verify <file> --repo soundspan/soundspan`.

## Connecting to a server

On first start the app asks for your server's address. Type it the way you reach the web UI; these forms all work:

- `music.example.com`
- `https://music.example.com`
- `https://example.com/soundspan` for a server published under a sub-path behind a reverse proxy. The path is kept and every request goes below it.
- `192.168.1.20:3030` for a server on your local network

Trailing slashes and a trailing `/api` are ignored.

**Encryption.** An address without a scheme is tried with `https://`. Only for local-network addresses (private IP ranges such as `192.168.x.x`, `10.x.x.x` and the `100.64.x.x` range of mesh VPNs, single-word host names, and names ending in `.local`, `.lan`, `.home.arpa` or `.internal`) does the app also try `http://`, and a server reached that way is marked **Not encrypted**. Typing `http://` for a public address shows a warning that your password and music would travel unencrypted, and asks you to confirm; on iOS and macOS the system blocks such connections, so the app asks for the `https://` address instead.

**Certificates.** The server's certificate must be trusted by the device: a certificate from a public authority such as Let's Encrypt, or one from your own certificate authority installed on the device. Self-signed certificates are not supported. The audio players of each platform make their own connections and accept only certificates the system trusts, so the app cannot make an exception for one server.

**What the app checks.** Before showing the sign-in screen, the app confirms that the address answers as a soundspan server, asks which sign-in methods the server offers, and checks that the server has been set up. If the server redirects to another address, the app shows **Using** with the address it will save; it never follows a redirect from `https://` to `http://`. A server that is starting is retried for up to 30 seconds. A server with no accounts yet shows a message asking you to open it in a browser and create the first account there.

After you sign in, the app reads the server's version and its enabled features. Features the server has turned off do not appear in the app. If the server is older than the app supports, the app says **This app needs soundspan `<version>` or newer** and does not sign in; update the server first.

## Signing in

The sign-in screen offers only the methods your server allows.

### Password

Sign in with your user name or email and password. If your account uses two-factor authentication, the app then asks for the 6-digit code from your authenticator app, or one of your 8-character recovery codes (**Use a recovery code instead**).

### Linking with a code

Linking signs the app in without typing your password. It is the way to sign in when your server uses single sign-on (the sign-in screen then reads **Sign in with** and the provider's name).

1. In a browser where you are signed in to soundspan, open the **Link Device** page at `<your server address>/device`.
2. Select **Generate Code**. The page shows a six-character code and a QR code, valid for 5 minutes.
3. In the app, select **Link with a code** and type the code, or select **Scan QR code** and point the camera at the QR code. Codes never contain the characters I, O, 0 or 1.

Scanning a QR code is available on Android, iOS and macOS; on Windows and Linux, type the code. Opening the QR code's `soundspan://link` address on a device where the app is installed does the same in one step: it adds the server and links the device. Because the QR code carries only the server's origin, the app asks for the path when your server runs under a sub-path.

A linked device signs in with an API key that the server issues for it. The key is valid for 90 days. From 14 days before it expires, the app shows **This device's link expires in N days** on Home with a **Link again** button, and a system notification (again at 3 days and on the last day). **Link again** walks through a fresh code for the same server, replaces the key, and revokes the old one. If the key expires anyway, the app keeps your downloads and data and asks you to link again. **Settings → Servers** shows **Link expires** with the date for every linked server.

### Pasting an API key

Select **Use an API key** and paste a key created under **Settings → API Keys** in the web UI. The app cannot tell when a pasted key expires, so it shows no expiry warning; it asks you to sign in again when the server stops accepting the key.

## Several servers

The app can hold any number of servers, and the same server more than once with different accounts. Each server has its own sign-in, cache and downloads; nothing is shared between them.

Manage them under **Settings → Servers**:

- **Add server** runs the connection steps for another server.
- **Switch** makes another server the one the app shows. Playback pauses when you switch.
- **Rename** changes the name shown for a server; it starts as the host name.
- **Sign out** signs this device out of the server; a linked device's key is revoked. Downloads, cached data and changes not yet sent stay on the device, so signing in again to the same account picks up where you left off. Tick **Also remove downloads** to delete the server's downloads as well.
- **Remove this server** signs out and deletes everything the app stores for that server, downloads included. If changes made offline have not reached the server yet, the dialog says how many would be lost and asks you to confirm with **Remove anyway**.

## Offline listening

The Android, iOS, Windows, macOS and Linux apps can download music; the web build cannot.

- **Downloading**: choose **Download** from the menu of a song, album, playlist or podcast episode. A downloaded album or playlist follows changes made to it on the server; **Check for changes** asks for them at once. The **Downloads** tab of the Library lists everything downloaded, with progress, **Pause all** and **Resume all**.
- **Where files are stored**: inside the app's own data folder, separately for each server, not in your music or downloads folder. Other apps cannot open them. Removing the app or the server deletes them.
- **Settings → Storage** sets the **Download quality**, **Download on Wi-Fi only** (on by default on phones and tablets), and the **Device limit**: the most space downloads may use on this device, which starts at the smaller of 20 GB and a quarter of the free space. A download that does not fit offers **Raise limit** or **Download what fits**. The page also shows how much space downloads use, the download limit the server sets for your account, and **Remove all downloads**.
- **When the administrator turns downloads off**: the server's administrator can disable offline downloads for everyone. Music already downloaded stays on the device and keeps playing; items that have not finished show **Downloads are turned off on this server**.
- **Playing offline**: without a connection the app shows what it has saved and plays downloaded music. **Offline mode** in the account menu keeps the app from contacting the server even when it could. Likes, playlist edits, podcast progress and plays made offline are kept on the device and sent, in order, when the server can be reached again. Plays are recorded at the time you listened.

## Car and system controls

**Android Auto.** soundspan appears in Android Auto with **Recent**, **Playlists**, **Albums** and **Downloads**; **Downloads** works without a connection. Voice search plays matching songs from your library. Android Auto shows only apps installed from a store unless you enable **Unknown sources** in Android Auto's developer settings (open Android Auto's settings, tap the version number repeatedly to unlock developer settings, then turn on **Unknown sources**).

**Phones.** On Android, playback shows a notification with previous, play/pause and next buttons and a like button in its expanded view; the same controls appear on the lock screen and work from headset and Bluetooth buttons. Android 13 and later ask for permission to show notifications the first time you play; playback works whatever you answer.

**Desktop.**

- Media keys and the system's media controls work on every desktop: the media flyout on Windows, the media controls in the macOS menu bar and Control Center, and MPRIS on Linux (desktop media keys and shell media widgets).
- On Windows and Linux, soundspan shows a tray icon with play/pause, the current track, **Show window** and **Quit**. Closing the window hides it to the tray and playback continues; turn this off with **Close to tray** in **Settings → Desktop**.
- On a Linux desktop without a system tray (GNOME without an AppIndicator extension, for example), **Close to tray** is unavailable, and closing the window while music plays asks whether to keep playing in the background.
- On macOS, closing the window keeps the app running and playing; click the Dock icon to show it again, and quit with Cmd+Q.

## Privacy

The apps contain no analytics and no crash reporting. They talk only to the servers you add, with one exception: the Windows, macOS and Linux apps ask GitHub once a day for the list of soundspan releases, to show a notice when a later version of the app is available. The request carries no account or server information. Turn it off with **Check for new versions** in **Settings → Desktop**. The Android, iOS and web apps never make this request.

**Settings → About → Export logs** saves or shares the app's diagnostic log, to attach to a bug report. Passwords, tokens and API keys are removed from it, and your server's address is replaced by `<server>`. Nothing is sent anywhere unless you share the file yourself.

## Troubleshooting

### Connecting

| The app says | What it means | What to do |
| --- | --- | --- |
| Address not found | The host name does not exist in DNS, as seen from this device. | Check the spelling. For a name that resolves only on your home network or VPN, connect to that network first. |
| Nothing is listening at that address and port | The host exists but refused the connection. | Check the port, and that the server or its reverse proxy is running and reachable from this device's network. |
| The server did not answer | The connection timed out. | Check that the device can reach the server's network (firewall, VPN, mobile data), then **Try again**. |
| The server's certificate is not trusted by this device | The TLS certificate is self-signed, expired, issued for another name, or from an authority the device does not trust. | Give the server a certificate from a public authority such as Let's Encrypt, or install your own certificate authority on the device. |
| Something in front of the server requires its own login | A proxy, single-sign-on gateway or access service in front of soundspan answered with its own login request. | Let the app's requests through to soundspan without that login, for example by exempting `/api/` and `/socket.io/`. |
| That address is not a soundspan server (check the path) | Something answered, but not as soundspan: a wrong path, or a reverse proxy routing to another service. | Check the address against the one you use for the web UI, including any sub-path. |
| The server reported an error | The server answered with an error, or kept answering that it is starting for more than 30 seconds. | Check the server's logs, then **Try again**. |
| The server redirected to an address this app will not follow | The server redirected more than three times, to something other than a web address, or from `https://` to `http://`. | Fix the redirect on the server or proxy, or enter the final address directly. |
| The server could not be reached. If it is running, it must allow this app's address… | Web build only. Either the server cannot be reached, or the browser blocked the request because the server does not allow the web app's origin. | Add the origin shown under **This app's address** to the server's `ALLOWED_ORIGINS` setting and restart the server, or host the web app on the server's own origin. |
| This app needs soundspan `<version>` or newer | The server runs a version older than this app supports. | Update the server. |
| This server has not been set up yet | The server has no accounts. | Open it in a browser, create the first account there, then try again. |

### Signing in and the desktop

| The app says | What it means | What to do |
| --- | --- | --- |
| This device has no secure storage service, so the sign-in cannot be kept | On Linux, no Secret Service provider answered. The app stores sign-ins only in the system keyring and never in a plain file. | Install and start GNOME Keyring or KWallet (with its Secret Service support), sign in to the desktop session again, and retry. |
| No system tray was found (under **Close to tray**) | The Linux desktop has no system tray host. | Install a tray extension, such as AppIndicator support on GNOME, or use the question shown when you close the window. |
| This server offers no sign-in method this app can use in a browser | Web build only. The server allows only single sign-on, which the web build cannot use. | Use a native app and link it with a code, or use the server's web UI. |
