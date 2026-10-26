[Setup]
AppId={{C8E28F10-539B-4D78-9B21-081B1E121021}
AppName=Edge Lobsense
AppVersion=2.0.0
AppPublisher=Lobsense
AppPublisherURL=https://lobsense.com
AppSupportURL=https://lobsense.com
AppUpdatesURL=https://lobsense.com
DefaultDirName={autopf}\Edge Lobsense
DefaultGroupName=Edge Lobsense
DisableProgramGroupPage=yes
OutputDir=build\installer
OutputBaseFilename=Edge_Lobsense_Setup_v2.0
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\windows\x64\runner\Release\lobsense_edge_app.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Edge Lobsense"; Filename: "{app}\lobsense_edge_app.exe"; IconFilename: "{app}\lobsense_edge_app.exe"
Name: "{autodesktop}\Edge Lobsense"; Filename: "{app}\lobsense_edge_app.exe"; IconFilename: "{app}\lobsense_edge_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\lobsense_edge_app.exe"; Description: "{cm:LaunchProgram,Edge Lobsense}"; Flags: nowait postinstall skipifsilent
