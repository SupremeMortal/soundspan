; Per-user Inno Setup installer of the Windows release build (doc 10,
; Windows). Unsigned; installs without elevation.
;
; Usage, from client/ after `flutter build windows --release` and the
; app-local MSVC runtime copied into the Release directory:
;   iscc /DAppVersion=<version> /O<output dir> windows\packaging\soundspan.iss
; Output: soundspan-<version>-windows-x64-unsigned-setup.exe

#ifndef AppVersion
  #error Pass the version with /DAppVersion=<version>
#endif
#ifndef ReleaseDir
  #define ReleaseDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
; Fixed for the life of the app: Windows identifies the installation by it.
AppId={{1288BCBB-1D3D-49DA-AE49-03B6B70F313B}
AppName=soundspan
AppVersion={#AppVersion}
AppVerName=soundspan {#AppVersion}
AppPublisher=soundspan
VersionInfoVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\soundspan
DefaultGroupName=soundspan
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputBaseFilename=soundspan-{#AppVersion}-windows-x64-unsigned-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\soundspan.exe
UninstallDisplayName=soundspan
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The whole Release directory, and the app-local MSVC runtime DLLs named
; one by one, so the build fails when one is missing.
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Excludes: "msvcp140.dll,vcruntime140.dll,vcruntime140_1.dll"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#ReleaseDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#ReleaseDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; The app user model id matches SetCurrentProcessExplicitAppUserModelID in
; main.cpp, so the taskbar, toasts and the SMTC flyout show this shortcut's
; name and icon.
Name: "{autoprograms}\soundspan"; Filename: "{app}\soundspan.exe"; AppUserModelID: "io.soundspan.app"
Name: "{autodesktop}\soundspan"; Filename: "{app}\soundspan.exe"; AppUserModelID: "io.soundspan.app"; Tasks: desktopicon

[Registry]
; soundspan:// links (doc 10, Deep Links Summary).
Root: HKCU; Subkey: "Software\Classes\soundspan"; ValueType: string; ValueName: ""; ValueData: "URL:soundspan"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\soundspan"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\soundspan\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\soundspan.exe"" ""%1"""

[Run]
Filename: "{app}\soundspan.exe"; Description: "{cm:LaunchProgram,soundspan}"; Flags: nowait postinstall skipifsilent
