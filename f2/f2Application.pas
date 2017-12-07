unit f2Application;

interface
uses
 d2dTypes,
 d2dInterfaces,
 d2dApplication,
 d2dGUIButtons,

 f2Skins,
 f2SettingsStorage;

type
 Tf2Application = class(Td2dApplication)
 private
  f_DebugMode: Boolean;
  f_DefaultButtonView: Id2dFramedButtonView;
  f_DefaultTextFont: Id2dFont;
  f_DefaultMenuFont: Id2dFont;
  f_DefaultTexture: Id2dTexture;
  f_IsFromExe: Boolean;
  f_IsFromPack: Boolean;
  f_LogToFile: Boolean;
  f_QuestFileName: string;
  f_QuestToOpen: string;
  f_SavePath: AnsiString;
  f_SettingsStorage: Tf2SettingsStorage;
  f_Skin: Tf2Skin;
  function pm_GetDefaultButtonView: Id2dFramedButtonView;
  function pm_GetDefaultTextFont: Id2dFont;
  function pm_GetDefaultMenuFont: Id2dFont;
  function pm_GetDefaultTexture: Id2dTexture;
  function pm_GetSavePath: AnsiString;
  function pm_GetSettingsStorage: Tf2SettingsStorage;
 protected
  function Init: Boolean; override;
  procedure LoadGlobalResources; override;
  procedure UnloadGlobalResources; override;
 public
  constructor Create(aQuest: string; aLogToFile, aDebugMode: Boolean);
  property DebugMode: Boolean read f_DebugMode write f_DebugMode;
  property DefaultButtonView: Id2dFramedButtonView read pm_GetDefaultButtonView;
  property DefaultTextFont: Id2dFont read pm_GetDefaultTextFont;
  property DefaultMenuFont: Id2dFont read pm_GetDefaultMenuFont;
  property DefaultTexture: Id2dTexture read pm_GetDefaultTexture;
  property IsFromExe: Boolean read f_IsFromExe write f_IsFromExe;
  property IsFromPack: Boolean read f_IsFromPack write f_IsFromPack;
  property LogToFile: Boolean read f_LogToFile write f_LogToFile;
  property QuestFileName: string read f_QuestFileName;
  property QuestToOpen: string read f_QuestToOpen;
  property SavePath: AnsiString read pm_GetSavePath;
  property SettingsStorage: Tf2SettingsStorage read pm_GetSettingsStorage;
  property Skin: Tf2Skin read f_Skin write f_Skin;
 end;

implementation
uses
 Windows,
 ShlObj,
 Classes,
 MD5,
 d2dCore,
 d2dGUITypes,
 d2dUtils,
 f2ScnSplash,
 f2ScnMain,
 f2Utils,
 f2FontLoad,
 SysUtils
 ;

const
 SFileMaskMain  = 'main.qst;main.qs1;main.qs2';
 SFileMaskGame  = 'game.qst;game.qs1;game.qs2';
 SFileMaskAny   = '*.qst;*.qs1;*.qs2';
 SErrQSZError = 'Ошибка формата QSZ';

 SFurqTexturePng  = 'furq_texture.png';
 SDefaultTextFont = 'serif'; //'georgia.ttf';
 SDefaultMenuFont = 'sans[16,0.8,0.2]';

 c_s_DefaultPackName = 'fireurq.pak';
 c_s_DefaultSkinName = 'furq_default_skin.xml';

procedure OutError(const aMsg: string);
begin
 gD2DE.System_Log(aMsg);
 MessageBox(gD2DE.WHandle, PAnsiChar(aMsg), 'FireURQ: ОШИБКА', MB_OK + MB_ICONERROR);
end;


constructor Tf2Application.Create(aQuest: string; aLogToFile, aDebugMode: Boolean);
var
 l_Dir: string;
 l_Path: array[0..MAX_PATH] of Char;
begin
 inherited Create(800, 600, True, 'FireURQ');
 gD2DE.FixedFPS := 120;
 l_Dir := ExtractFilePath(ParamStr(0));
 if not IsDirWritable(l_Dir) then
 begin
  if SHGetSpecialFolderPath(0, @l_Path, CSIDL_APPDATA, True) then
  begin
   l_Dir := IncludeTrailingPathDelimiter(l_Path) + 'FireURQ';
   ForceDirectories(l_Dir);
  end;
 end;
 gD2DE.LogFileName := IncludeTrailingPathDelimiter(l_Dir) + ChangeFileExt(ExtractFileName(ParamStr(0)), '.log');
 f_QuestFileName := aQuest;
 f_LogToFile := aLogToFile;
 f_DebugMode := aDebugMode;
end;

function Tf2Application.Init: Boolean;
var
 l_Ext: string;
 //l_ZipOffset: Longint;
 l_FS       : TStream;
 l_FullScreen: Boolean;
 l_QName: string;
 l_SPath: string;
begin
 Result := False;
 l_SPath := ExtractFilePath(ParamStr(0)) + c_s_DefaultPackName;
 if not FileExists(l_SPath) then
 begin
  OutError(Format('Не найдены ресурсы (файл %s). Что-то явно не так.', [c_s_DefaultPackName]));
  Exit;
 end;
 D2AttachZipPack(l_SPath);
 if not FileExists(f_QuestFileName) then
 begin
  OutError(Format('Файл %s не найден.', [f_QuestFileName]));
  Exit;
 end;
 l_Ext := AnsiLowerCase(ExtractFileExt(f_QuestFileName));
 if (l_Ext = '.qsz') {or (l_Ext = '.exe')} then // do not localize
 begin
  //l_ZipOffset := 0;
  {
  if (l_Ext = '.exe') then // do not localize
  begin
   l_FS := TFileStream.Create(f_QuestFileName, fmOpenRead or fmShareDenyWrite);
   try
    l_FS.Seek(-4, soFromEnd);
    l_FS.ReadBuffer(l_ZipOffset, 4);
    f_IsFromExe := True;
   finally
    l_FS.Free;
   end;
  end;
  }
  if D2AttachZipPack(f_QuestFileName{, l_ZipOffset}) then
  begin
   l_QName := gD2DE.Resource_FindInPacks(SFileMaskMain);
   if l_QName = '' then
   begin
    l_QName := gD2DE.Resource_FindInPacks(SFileMaskGame);
    if l_QName = '' then
     l_QName := gD2DE.Resource_FindInPacks(SFileMaskAny);
   end;
   if l_QName <> '' then
   begin
    f_QuestToOpen := l_QName;
    f_IsFromPack := True;
   end
   else
   begin
    gD2DE.Resource_RemovePack(f_QuestFileName);
    OutError(SErrQSZError);
    Exit;
   end;
  end
  else
  begin
   OutError('Файл '+f_QuestFileName+' испорчен');
   Exit;
  end;
 end
 else
  f_QuestToOpen := QuestFileName;
 SetCurrentDir(ExtractFilePath(QuestFileName));
 f_Skin := nil;
 if gD2DE.Resource_Exists('skin.xml', IsFromPack) then
 begin
  f_Skin := Tf2Skin.Create('skin.xml', IsFromPack);
  if f_Skin = nil then
   OutError('Ошибка: skin.xml пуст или испорчен.');
 end;
 if Skin = nil then
 begin
  if not gD2DE.Resource_Exists(c_s_DefaultSkinName) then
  begin
   OutError('Скин по-умолчанию не найден. Как это могло произойти?');
   Exit;
  end;
  f_Skin := Tf2Skin.Create(c_s_DefaultSkinName);
 end;
 if SettingsStorage.IsVarExists('fullscreen') then
  l_FullScreen := SettingsStorage['fullscreen'] <> 0
 else
  l_FullScreen := Skin.FullScreen;
 gD2DE.ScreenWidth  := Skin.ScreenWidth;
 gD2DE.ScreenHeight := Skin.ScreenHeight;
 gD2DE.Windowed := not l_FullScreen;
 AddScene('splash', Tf2SplashScene.Create(Self));
 AddScene('main', Tf2MainScene.Create(Self));
 CurrentScene := 'splash';
 //CurrentScene := 'main';
 Result := True;
end;

procedure Tf2Application.LoadGlobalResources;
begin
 Skin.LoadResources;
end;

function Tf2Application.pm_GetDefaultButtonView: Id2dFramedButtonView;
begin
 if f_DefaultButtonView = nil then
 begin
  f_DefaultButtonView := Td2dFramedButtonView.Create(DefaultTexture, 567, 47, 44, 44, 20, 4, DefaultTextFont);
  with f_DefaultButtonView do
  begin
   StateColor[bsNormal] := $FFA0A0A0;
   StateColor[bsFocused] := $FFA0A0FF;
   StateColor[bsDisabled] := $FF606060;
   StateColor[bsPressed] := $FFFFFFFF;
  end;
 end;
 Result := f_DefaultButtonView;
end;

function Tf2Application.pm_GetDefaultTextFont: Id2dFont;
begin
 if f_DefaultTextFont = nil then
  f_DefaultTextFont := f2LoadFont(SDefaultTextFont);
 Result := f_DefaultTextFont;
end;

function Tf2Application.pm_GetDefaultMenuFont: Id2dFont;
begin
 if f_DefaultMenuFont = nil then
  f_DefaultMenuFont := f2LoadFont(SDefaultMenuFont);
 Result := f_DefaultMenuFont;
end;

function Tf2Application.pm_GetDefaultTexture: Id2dTexture;
begin
 if f_DefaultTexture = nil then
 begin
  f_DefaultTexture := gD2DE.Texture_Load(SFurqTexturePng);
 end;
 Result := f_DefaultTexture;
end;

function Tf2Application.pm_GetSavePath: AnsiString;
var
 l_FileName: AnsiString;
 l_Path: array[0..MAX_PATH] of Char;
begin
 if f_SavePath = '' then
 begin
  f_SavePath := ExtractFilePath(QuestFileName);
  if not IsDirWritable(f_SavePath) then
  begin
   if SHGetSpecialFolderPath(0, @l_Path, CSIDL_APPDATA, True) then
   begin
    l_FileName := ExtractFileName(QuestFileName);
    f_SavePath := IncludeTrailingPathDelimiter(l_Path) + 'FireURQ\' + ChangeFileExt(l_Filename, '_') +
       MD5DigestToStr(MD5File(QuestFileName));
    ForceDirectories(f_SavePath);
   end;
  end;
 end;
 Result := f_SavePath;
end;

function Tf2Application.pm_GetSettingsStorage: Tf2SettingsStorage;
var
 l_FileName: AnsiString;
begin
 if f_SettingsStorage = nil then
 begin
  l_FileName := ExtractFileName(QuestFileName);
  f_SettingsStorage := Tf2SettingsStorage.Create(IncludeTrailingPathDelimiter(SavePath) + ChangeFileExt(l_Filename, '.gss'));
 end;
 Result := f_SettingsStorage;
end;

procedure Tf2Application.UnloadGlobalResources;
begin
 f_DefaultButtonView := nil;
 f_DefaultTextFont := nil;
 f_DefaultMenuFont := nil;
 FreeAndNil(f_Skin);
 FreeAndNil(f_SettingsStorage);
end;



end.
