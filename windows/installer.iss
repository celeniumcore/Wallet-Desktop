; Celenium Wallet - Windows Installer (Inno Setup 6)
; Builds a Binance-style setup.exe from Flutter Windows Release output.
;
; Prereqs (on Windows host / CI):
;   - flutter build windows --release
;   - Inno Setup 6 installed (ISCC.exe)
;
; Build:
;   ISCC.exe windows\installer.iss

#define MyAppName "Celenium Wallet"
#define MyAppVersion "1.0.3"
#define MyAppPublisher "Celenium Labs"
#define MyAppURL "https://celenium.web.id"
#define MyAppExeName "celenium_wallet.exe"
#define MyAppId "{{A9F4B2E1-7C3D-4A8E-9F12-6D5C8B4A1E20}"
; Harus identik dengan SetCurrentProcessExplicitAppUserModelID di runner/main.cpp
#define MyAppUserModelID "Celenium.Wallet"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Per-user install into %LOCALAPPDATA%\Programs: no UAC prompt, no admin rights needed.
PrivilegesRequired=lowest
OutputDir=..\installer-out
OutputBaseFilename=Celenium-Wallet-Setup-{#MyAppVersion}
SetupIconFile=runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoProductName={#MyAppName}
VersionInfoVersion=1.0.3.4
VersionInfoCopyright=Copyright (C) 2026 Celenium Labs. All rights reserved.
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "indonesian"; MessagesFile: "compiler:Languages\Indonesian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Logo lama yang tidak dipakai lagi — dibersihkan saat upgrade
Type: files; Name: "{app}\data\flutter_assets\assets\cen_logo.png"
Type: files; Name: "{app}\data\flutter_assets\assets\cen_logo_temp.jpg"
Type: files; Name: "{app}\data\flutter_assets\assets\user_logo.jpg"
Type: filesandordirs; Name: "{app}\data\flutter_assets\assets\icons"

[Files]
; Flutter Windows release bundle
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Comment: "Dompet CEN (Celenium)"; AppUserModelID: "{#MyAppUserModelID}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"; IconFilename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Comment: "Dompet CEN (Celenium)"; AppUserModelID: "{#MyAppUserModelID}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
