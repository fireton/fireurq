[Files]
Source: ..\exe\fireURQ2.exe; DestDir: {app}
Source: versions.htm; DestDir: {app}
Source: ..\exe\D3DX81ab.dll; DestDir: {app}
Source: ..\exe\fireurq.pak; DestDir: {app}
Source: ..\exe\freetype.dll; DestDir: {app}
Source: ..\exe\bass.dll; DestDir: {app}
Source: ..\exe\d3dx8d.dll; DestDir: {app}

[Setup]
MinVersion=0,6.0.6000
AppName=FireURQ
AppVersion=2.2.4 "Veta"
AppPublisher=Fireton
AppPublisherURL=http://ifwiki.ru/FireURQ
DefaultDirName={pf}\FireURQ
InternalCompressLevel=ultra
OutputDir=D:\TON\Delphi Projects\FireURQ\f2\deploy
OutputBaseFilename=fireurq_setup
AppID={{74D742D0-FD9A-4D44-A06C-A77865D6676C}
DefaultGroupName=FireURQ
ChangesAssociations=true
SolidCompression=true
VersionInfoProductName=FireURQ
VersionInfoProductVersion=2.2.4
UninstallDisplayIcon={app}\fireURQ2.exe
AppCopyright=© 2009-2017 Fireton
VersionInfoVersion=2.2.4
VersionInfoCompany=Fireton
Compression=lzma2/ultra
DisableWelcomePage=no
DisableDirPage=no
SetupIconFile=D:\TON\Delphi Projects\FireURQ\f2\deploy\setup_icon.ico

[LangOptions]
LanguageName=Russian
LanguageID=$0419

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Icons]
Name: {group}\FireURQ; Filename: {app}\fireURQ2.exe; Languages: 
Name: {group}\Удалить FireURQ; Filename: {uninstallexe}
Name: {group}\История версий; Filename: {app}\versions.htm; Languages: 
Name: {commondesktop}\FireURQ; Filename: {app}\fireURQ2.exe; WorkingDir: {app}; Tasks: " desktopicon"
[CustomMessages]
CreateDesktopIcon=Создать иконку на рабочем столе
[Tasks]
Name: desktopicon; Description: Создать иконку на рабочем столе
Name: fileassotiation; Description: Связать файлы квестов с FireURQ
[Registry]
Root: HKCR; Subkey: .qst; ValueType: string; ValueData: URQGameFile; Flags: uninsdeletevalue; Tasks: " fileassotiation"
Root: HKCR; Subkey: .qs1; ValueType: string; ValueData: URQGameFile; Flags: uninsdeletevalue; Tasks: " fileassotiation"
Root: HKCR; Subkey: .qs2; ValueType: string; ValueData: URQGameFile; Flags: uninsdeletevalue; Tasks: " fileassotiation"
Root: HKCR; Subkey: .qsz; ValueType: string; ValueData: URQGameFile; Flags: uninsdeletevalue; Tasks: " fileassotiation"
Root: HKCR; Subkey: URQGameFile\shell\open\command; ValueType: string; ValueData: """{app}\fireURQ2.exe"" ""%1"""; Tasks: " fileassotiation"; Languages: 
Root: HKCR; Subkey: URQGameFile; ValueType: string; ValueData: Файл игры в формате URQ; Flags: uninsdeletekey; Tasks: " fileassotiation"
Root: HKCR; Subkey: URQGameFile\shell\debug; ValueType: string; ValueData: Запустить в режиме отладки; Tasks: " fileassotiation"; Languages: 
Root: HKCR; Subkey: URQGameFile\shell\debug\command; ValueType: string; ValueData: """{app}\fireURQ2.exe"" ""-d"" ""%1"""; Tasks: " fileassotiation"; Languages: 
[UninstallDelete]
Name: {app}\*.log; Type: files
Name: {app}\fonted\*.log; Type: files

[InstallDelete]
Type: files; Name: "{app}\FireURQ.html"
Type: files; Name: "{app}\fireurq.chm"
Type: filesandordirs; Name: "{app}\fonted"
Type: files; Name: "{app}\qsz2exe.exe"
Type: files; Name: "{app}\fireurq.exe"

[Messages]
russian.AboutSetupNote=
