[Setup]
AppName=Athlos
AppVersion=1.0.0
AppPublisher=Athlos
DefaultDirName={autopf}\Athlos
DefaultGroupName=Athlos
OutputDir=..\build
OutputBaseFilename=InstaladorAthlos
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\workspace.exe
 
[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
 
[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"
 
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion
 
[Icons]
Name: "{group}\Athlos"; Filename: "{app}\workspace.exe"
Name: "{autodesktop}\Athlos"; Filename: "{app}\workspace.exe"; Tasks: desktopicon
 
[Run]
Filename: "{app}\workspace.exe"; Description: "Ejecutar Athlos"; Flags: nowait postinstall skipifsilent
