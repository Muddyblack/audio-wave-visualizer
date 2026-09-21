; Windows installer for the Audio Visualizer overlay scaffold (Inno Setup 6).
;
; Built by windows/build-installer.ps1 from PyInstaller's "dist\Audio
; Visualizer" folder (windows/audio-visualizer.spec), in
; .github/workflows/windows.yml — on every push, and for each release, which
; release.yml runs that workflow for.
;
; Per user: no admin rights, installed to %LOCALAPPDATA%\Programs\Audio
; Visualizer. NOTE: this installs and runs the SCAFFOLD (see docs/windows.md)
; — a window and a tray icon, not a working visualizer. Ship it anyway so the
; install/update/uninstall plumbing is exercised before the real overlay and
; audio capture land.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
; Never change the AppId: it is how Windows knows a new version is the same
; app and updates it in place. Also referenced by windows/package-manifests.py
; as PRODUCT_CODE (AppId + "_is1") — keep the two in step.
AppId={{808901FC-4752-4921-BA4E-D6883FFFE601}
AppName=Audio Visualizer
AppVersion={#AppVersion}
AppVerName=Audio Visualizer {#AppVersion}
AppPublisher=Muddyblack
AppPublisherURL=https://github.com/Muddyblack/audio-wave-visualizer
AppSupportURL=https://github.com/Muddyblack/audio-wave-visualizer/issues
DefaultDirName={autopf}\Audio Visualizer
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..
OutputBaseFilename=Audio-Visualizer-Setup-{#AppVersion}
SetupIconFile=..\dist\audio-visualizer.ico
UninstallDisplayIcon={app}\Audio Visualizer.exe
UninstallDisplayName=Audio Visualizer
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; The running app is stopped in [Code] instead of by the Restart Manager,
; which would ask the user about a tray app with no window to close.
CloseApplications=no

[Tasks]
; Offered on a first install only. On an update it would apply the choice
; remembered from that install, turning autostart back on for someone who had
; switched it off since; left out, the Run value stays as it is.
Name: "autostart"; Description: "Start Audio Visualizer when I sign in"; Check: not IsUpgrade
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\dist\Audio Visualizer\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; An update replaces the whole bundle: files a new PyInstaller build no
; longer has must not linger next to the ones it does.
Type: filesandordirs; Name: "{app}\_internal"

[Icons]
Name: "{autoprograms}\Audio Visualizer"; Filename: "{app}\Audio Visualizer.exe"
Name: "{autodesktop}\Audio Visualizer"; Filename: "{app}\Audio Visualizer.exe"; Tasks: desktopicon

[Registry]
; TODO: app.py has no "Start with Windows" switch yet (see its Settings menu
; item, currently disabled) — this Run value is only ever set here, by the
; installer's Task checkbox, until the app can write/read the same key.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Audio Visualizer"; ValueData: """{app}\Audio Visualizer.exe"""; Tasks: autostart
; Removed on uninstall whichever of the two turned it on.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: none; ValueName: "Audio Visualizer"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\Audio Visualizer.exe"; Description: "{cm:LaunchProgram,Audio Visualizer}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/F /IM ""Audio Visualizer.exe"""; Flags: runhidden; RunOnceId: "StopAudioVisualizer"

[Code]
var
  WasRunning: Boolean;

// An earlier install is there: its uninstaller is registered under AppId
// (with the doubled brace undone) plus "_is1". Keep the GUID in step with
// AppId above and with PRODUCT_CODE in windows/package-manifests.py.
function IsUpgrade: Boolean;
var
  Uninstaller: String;
begin
  Result := RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{808901FC-4752-4921-BA4E-D6883FFFE601}_is1', 'UninstallString', Uninstaller);
end;

// Stop a running copy before its files are replaced. taskkill exits 0 when it
// stopped something and 128 when nothing was running.
function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  ResultCode: Integer;
begin
  WasRunning := Exec(ExpandConstant('{sys}\taskkill.exe'), '/F /IM "Audio Visualizer.exe"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
  Result := '';
end;

// A silent update (/SILENT, winget) skips the [Run] entry's checkbox, which
// would leave the app stopped until the next sign-in: start it again when it
// was running before.
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if (CurStep = ssPostInstall) and WizardSilent and WasRunning then
    ExecAsOriginalUser(ExpandConstant('{app}\Audio Visualizer.exe'), '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
end;
