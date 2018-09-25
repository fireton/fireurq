unit f2Context;

interface
uses
 Classes,

 jclStringLists,

 d2dTypes,
 d2dInterfaces,
 d2dGUITypes,
 d2dFormattedText,
 d2dGUIButtons,

 f2Types,
 furqContext,
 furqFiler,
 f2SettingsStorage,
 f2TextPane,
 f2Decorators,
 f2FontPool,
 f2PicturePool,
 f2Skins;

type
 Tf2Context = class(TFURQContext, Id2dTextAddingTool)
 private
  f_BtnMenuAlign: Td2dAlign;
  f_CurrentMusic: AnsiString;
  f_Decorators : Tf2DecoratorList;
  f_DefTPLeft  : Single;
  f_DefTPTop   : Single;
  f_DefTPWidth : Single;
  f_DefTPHeight: Single;
  f_DefBtnAlign: Td2dTextAlignType;
  f_DefBtnTxtAlign: Td2dTextAlignType;
  f_DefButtonFrame: Id2dFramedButtonView;
  f_DefMenuVisualStyle: Td2dMenuVisualStyle;
  f_EchoColor: Td2dColor;
  f_Filename: string;
  f_TextAlign: Td2dTextAlignType;
  f_TextColor: Td2dColor;
  f_TextFont: Id2dFont;
  f_TextPane: Tf2TextPane;
  f_FontPool: Tf2FontPool;
  f_FpFilename: string;
  f_LinkColor: Td2dColor;
  f_LinkHColor: Td2dColor;
  f_LinkMenuAlign: Td2dAlign;
  f_LocationText: string;
  f_VoiceFilename: string;
  f_MenuVisualStyle: Td2dMenuVisualStyle;
  f_MenuFont       : Id2dFont;
  f_OnDecoratorAction: Tf2OnActionProc;
  f_Path: string;
  f_PicturePool: Id2dPictureProvider;
  f_Skin: Tf2Skin;
  f_SettingsStorage: Tf2SettingsStorage;
  function ParseDecorVar(const aVarName: string; var theDName, theDVarName:
      string): Boolean;
  // Id2dTextAddingTool
  procedure AddText(const aText: string);
  procedure AddLink(const aText, aTarget: string);
  procedure CheckIfNumber(const Value: Variant);
  function pm_GetActionsData(anID: string): IFURQActionData; override;
 protected
  procedure Cleanup; override;
  procedure DoLoadData(aFiler: TFURQFiler); override;
  procedure DoSaveData(aFiler: TFURQFiler); override;
  procedure InitSysVariables; override;
  procedure SetSysVariables(aName: string; const Value: Variant); override;
  function GetVirtualVariable(const aName: string): Variant; override;
  function IsSystemOrVirtualVariable(aVarName: string): Boolean; override;
  function SetVirtualVariables(const aName: string; const aValue: Variant):
      Boolean; override;
 public
  constructor Create(aCode: TFURQCode; aFilename: string; aFont, aMenuFont: Id2dFont; aMenuVisualStyle:
   Td2dMenuVisualStyle; aTextPane: Tf2TextPane; aSkin: Tf2Skin; const aDefButtonFrame: Id2dFramedButtonView;
   const aPath: string);
  procedure AddTextDecorator(const aName: string;
                             const aX, aY, aZ: Single;
                             const aColor, aLinkColor, aLinkHColor: Td2dColor;
                             const aFont: string;
                             const aText: string);
  procedure AddRectDecorator(const aName: string; const aX, aY, aZ: Single; const aColor: Td2dColor; const aWidth,
      aHeight: Integer);
  procedure AddPictureDecorator(const aName: string; const aX, aY, aZ: Single;
      const aFilename: string; aLeft, aTop, aWidth, aHeight: Integer);
  procedure AddAnimationDecorator(const aName: string; const aX, aY, aZ: Single;
      const aFilename: string; aLeft, aTop, aWidth, aHeight, aFrames: Integer);
  procedure AddGIFDecorator(const aName: string; const aX, aY, aZ: Single; const
      aFilename: string);
  procedure AddClickAreaDecorator(const aName: string; const aX, aY, aZ: Single; const aWidth, aHeight: Integer; const aTarget: string);
  procedure AddImageButtonDecorator(const aName: string; const aX, aY, aZ: Single; const aFilename: string; aLeft, aTop,
   aWidth, aHeight: Integer; const aTarget: string);
  procedure AddTextButtonDecorator(const aName: string; const aX, aY, aZ: Single; const aFrameName, aText, aTarget:
   string);
  procedure AllowActionDecorators(aSwitch: Boolean);
  function DoActionFinal(const anActionData: IFURQActionData): Boolean; override;
  procedure ClearButtons; override;
  procedure ClearText; override;
  procedure DropLinks;
  procedure FadeMusic(const aVolume: Byte; const aFadeTime: Longword);
  function GetButtonFrame(const aName: string): Id2dFramedButtonView;
  function GetDecorator(const aDName: string): Tf2BaseDecorator;
  function GetMouseDecorator: Tf2BaseDecorator;
  procedure KillSettingsStorage;
  procedure MusicPlay(const aFilename: string; aFadeTime: Integer); override;
  procedure MusicStop(aFadeTime: Integer); override;
  procedure OutPicture(const aFilename: string; aX, aY, aWidth, aHeight: Integer);
  procedure OutText(const aStr: string); override;
  procedure Restart; override;
  procedure SoundPlay(const aFilename: string; aVolume: Integer; aLooped: Boolean); override;
  procedure SoundStop(const aFilename: string); override;
  function SystemProc(aProcName: string; aParams: IJclStringList): Boolean; override;
  procedure VoicePlay(const aFilename: string);
  procedure VoiceStop;
  property Decorators: Tf2DecoratorList read f_Decorators;
  property EchoColor: Td2dColor read f_EchoColor;
  property LinkColor: Td2dColor read f_LinkColor write f_LinkColor;
  property LinkHColor: Td2dColor read f_LinkHColor write f_LinkHColor;
  property LocationText: string read f_LocationText;
  property MenuFont: Id2dFont read f_MenuFont;
  property MenuVisualStyle: Td2dMenuVisualStyle read f_MenuVisualStyle;
  property OnDecoratorAction: Tf2OnActionProc read f_OnDecoratorAction write f_OnDecoratorAction;
  property BtnMenuAlign: Td2dAlign read f_BtnMenuAlign;
  property FontPool: Tf2FontPool read f_FontPool;
  property FpFilename: string read f_FpFilename;
  property LinkMenuAlign: Td2dAlign read f_LinkMenuAlign;
  property SettingsStorage: Tf2SettingsStorage read f_SettingsStorage write f_SettingsStorage;
  property Skin: Tf2Skin read f_Skin;
  property TextAlign: Td2dTextAlignType read f_TextAlign write f_TextAlign;
  property TextColor: Td2dColor read f_TextColor write f_TextColor;
  property TextFont: Id2dFont read f_TextFont write f_TextFont;
 end;

implementation
uses
 Types,
 SysUtils,
 StrUtils,
 Variants,
 Math,

 d2dCore,
 d2dGUI,
 d2dGUIUtils,

 furqTypes,
 furqBase,
 furqUtils,

 f2DecorScript,
 f2LinkParser
 ;

const
// START resource string wizard section
 cs_COLOR = 'COLOR';
 cs_HIDE = 'HIDE';
 cs_SCRIPT = 'SCRIPT';
 cs_TEXT = 'TEXT';
 cs_WIDTH = 'WIDTH';
 cs_HEIGHT = 'HEIGHT';
 cs_ALIGN = 'ALIGN';
 cs_LINESPACING = 'LINESPACING';
 cs_PARASPACING = 'PARASPACING';
 cs_LINKCOLOR   = 'LINKCOLOR';
 cs_LINKHCOLOR  = 'LINKHCOLOR';
 cs_HOTX = 'HOTX';
 cs_HOTY = 'HOTY';
 cs_ANGLE = 'ANGLE';
 cs_ROTSPEED = 'ROTSPEED';
 cs_SCALE = 'SCALE';
 cs_FRAME = 'FRAME';
 cs_ANISPEED = 'ANISPEED';
 cs_ANITYPE = 'ANITYPE';
 cs_TARGET  = 'TARGET';
 cs_ENABLED = 'ENABLED';
 cs_MENUALIGN = 'MENUALIGN';
 cs_FLIPX   = 'FLIPX';
 cs_FLIPY   = 'FLIPY';
 cs_Decor_ = 'decor_';
 cs_GSS_   = 'gss_';
 cs_IMG = '[IMG]';
 cs__color = '_color';
 cs__result = '_result';

 cs_MouseDecoratorVarName = 'mousecursor';

// END resource string wizard section

 
 cDOSColors: array[0..15] of Td2dColor =
   ($FF000000, $FF000080, $FF008000, $FF008080, $FF800000, $FF800080, $FF808000, $FFC0C0C0,
    $FF808080, $FF0000FF, $FF00FF00, $FF00FFFF, $FFFF0000, $FFFF00FF, $FFFFFF00, $FFFFFFFF);

 cNotFoundError     = 'файл %s не найден';
 cNoGIFinImageError = '%s: используйте тип декоратора GIF, а не IMAGE';
 cNotImageError     = 'файл %s не является изображением';
 cNotANumberValue   = 'значение не является числом';

const
 c_BadLinkColor  = $FFB52929;
 c_BadLinkHColor = $FFFF3A3A;

procedure VariantToAlign(const Value: Variant; var theAlign: Td2dTextAlignType);
var
 l_Tmp: Integer;
begin
 l_Tmp := Trunc(Value);
 case l_Tmp of
  1: theAlign := ptLeftAligned;
  2: theAlign := ptRightAligned;
  3: theAlign := ptCentered;
 end;
end;


constructor Tf2Context.Create(aCode: TFURQCode; aFilename: string; aFont, aMenuFont: Id2dFont; aMenuVisualStyle: Td2dMenuVisualStyle; aTextPane: Tf2TextPane; aSkin: Tf2Skin; const aDefButtonFrame: Id2dFramedButtonView; const aPath: string);
begin
 f_Filename := aFilename;
 f_TextPane := aTextPane;

 f_DefTPLeft   := f_TextPane.X;
 f_DefTPTop    := f_TextPane.Y;
 f_DefTPWidth  := f_TextPane.Width;
 f_DefTPHeight := f_TextPane.Height;

 f_DefBtnAlign := f_TextPane.ButtonAlign;
 f_DefBtnTxtAlign := f_TextPane.ButtonTextAlign;

 f_Decorators := Tf2DecoratorList.Create;
 f_FontPool := Tf2FontPool.Create(aFont, aMenuFont);
 f_PicturePool := Tf2PicturePool.Make;
 f_DefMenuVisualStyle := aMenuVisualStyle;

 f_Skin := aSkin;
 f_DefButtonFrame := aDefButtonFrame;

 f_Path := aPath;
 inherited Create(aCode);
end;

procedure Tf2Context.Cleanup;
begin
 FreeAndNil(f_Decorators);
 FreeAndNil(f_FontPool);
 inherited;
end;

procedure Tf2Context.AddAnimationDecorator(const aName: string; const aX, aY, aZ: Single;
                                           const aFilename: string; aLeft, aTop, aWidth, aHeight, aFrames: Integer);
var
 l_Tex: Id2dTexture;
 l_Decor: Tf2AnimationDecorator;
begin
 l_Tex := gD2DE.Texture_Load(aFilename);
 if l_Tex <> nil then
 begin
  if (aWidth < 1) or (aHeight < 1) then
   Exit;
  l_Decor := Tf2AnimationDecorator.Create(aX, aY, aZ, aFilename, aLeft, aTop, aWidth, aHeight, aFrames);
  Decorators.AddDecorator(aName, l_Decor);
 end
 else
  raise EFURQRunTimeError.CreateFmt(cNotFoundError, [aFilename]);
end;

procedure Tf2Context.AddPictureDecorator(const aName: string; const aX, aY, aZ: Single;
                      const aFilename: string; aLeft, aTop, aWidth, aHeight:  Integer);
var
 l_Decor: Tf2SpriteDecorator;
 l_Tex : Id2dTexture;
begin
 if gD2DE.Resource_Exists(aFilename) then
 begin
  l_Tex := gD2DE.Texture_Load(aFilename);
  if l_Tex <> nil then
  begin
   l_Decor := Tf2SpriteDecorator.Create(aX, aY, aZ, aFilename, aLeft, aTop, aWidth, aHeight);
   Decorators.AddDecorator(aName, l_Decor);
  end
  else
   raise EFURQRunTimeError.CreateFmt(cNotImageError, [aFilename]);
 end
 else
  raise EFURQRunTimeError.CreateFmt(cNotFoundError, [aFilename]);
end;

procedure Tf2Context.AddGIFDecorator(const aName: string; const aX, aY, aZ: Single; const aFilename: string);
var
 l_Decor: Tf2GIFDecorator;
begin
 if gD2DE.Resource_Exists(aFilename) then
 begin
  l_Decor := Tf2GIFDecorator.Create(aX, aY, aZ, aFilename);
  Decorators.AddDecorator(aName, l_Decor);
 end
 else
  raise EFURQRunTimeError.CreateFmt(cNotFoundError, [aFilename]);
end;

procedure Tf2Context.AddLink(const aText, aTarget: string);
begin
 if aTarget <> '' then
  f_TextPane.AddLink(aText, aTarget, f_TextFont, f_TextColor, f_LinkColor, f_LinkHColor, f_TextAlign)
 else
  f_TextPane.AddLink(aText, aTarget, f_TextFont, f_TextColor, c_BadLinkColor, c_BadLinkHColor, f_TextAlign)
end;

procedure Tf2Context.AddTextDecorator(const aName: string;
                                      const aX, aY, aZ: Single;
                                      const aColor, aLinkColor, aLinkHColor: Td2dColor;
                                      const aFont: string;
                                      const aText: string);
var
 l_Font: string;
 l_Decor: Tf2TextDecorator;
 l_TmpStr: string;
begin
 if aFont = '' then
  l_Font := c_Sysfont
 else
  l_Font := aFont;
 l_TmpStr := AnsiReplaceStr(aText, #9, '    '); 
 l_Decor := Tf2TextDecorator.Create(Self, aX, aY, aZ, aColor, aLinkColor, aLinkHColor, l_TmpStr, l_Font, f_FontPool);
 if l_Decor <> nil then
 begin
  l_Decor.OnAction := f_OnDecoratorAction;
  l_Decor.LineSpacing := f_TextPane.LineSpacing;
  l_Decor.ParaSpacing := f_TextPane.ParaSpacing;
  Decorators.AddDecorator(aName, l_Decor);
 end;
end;

procedure Tf2Context.AddRectDecorator(const aName: string; const aX, aY, aZ: Single; const aColor: Td2dColor; const
    aWidth, aHeight: Integer);
var
 l_Decor: Tf2RectangleDecorator;
begin
 l_Decor := Tf2RectangleDecorator.Create(aX, aY, aZ, aWidth, aHeight, aColor);
 Decorators.AddDecorator(aName, l_Decor);
end;

procedure Tf2Context.AddClickAreaDecorator(const aName: string; const aX, aY, aZ: Single; const aWidth, aHeight: Integer; const aTarget: string);
var
 l_Decor: Tf2ClickAreaDecorator;
begin
 l_Decor := Tf2ClickAreaDecorator.Create(aX, aY, aZ, Self, aWidth, aHeight);
 l_Decor.TargetProcessor.Target := aTarget;
 l_Decor.TargetProcessor.OnAction := OnDecoratorAction;
 Decorators.AddDecorator(aName, l_Decor);
end;

procedure Tf2Context.AddImageButtonDecorator(const aName: string; const aX, aY, aZ: Single; const aFilename: string;
 aLeft, aTop, aWidth, aHeight: Integer; const aTarget: string);
var
 l_Decor: Tf2ImageButtonDecorator;
 l_Tex : Id2dTexture;
begin
 if gD2DE.Resource_Exists(aFilename) then
 begin
  l_Tex := gD2DE.Texture_Load(aFilename);
  if l_Tex <> nil then
  begin
   if aWidth = 0 then
   begin
    aWidth  := gD2DE.Texture_GetWidth(l_Tex) div 4;
    aHeight := gD2DE.Texture_GetHeight(l_Tex);
   end;
   l_Decor := Tf2ImageButtonDecorator.Create(aX, aY, aZ, Self, aFilename, aLeft, aTop, aWidth, aHeight);
   l_Decor.TargetProcessor.Target := aTarget;
   l_Decor.TargetProcessor.OnAction := OnDecoratorAction;
   Decorators.AddDecorator(aName, l_Decor);
  end
  else
   raise EFURQRunTimeError.CreateFmt(cNotImageError, [aFilename]);
 end
 else
  raise EFURQRunTimeError.CreateFmt(cNotFoundError, [aFilename]);
end;

procedure Tf2Context.AddTextButtonDecorator(const aName: string; const aX, aY, aZ: Single; const aFrameName, aText,
 aTarget: string);
var
 l_Decor: Tf2TextButtonDecorator;
begin
 l_Decor := Tf2TextButtonDecorator.Create(aX, aY, aZ, Self, aFrameName, aText);
 l_Decor.TargetProcessor.Target := aTarget;
 l_Decor.TargetProcessor.OnAction := OnDecoratorAction;
 Decorators.AddDecorator(aName, l_Decor);
end;

procedure Tf2Context.AddText(const aText: string);
begin
 f_TextPane.AddText(aText, f_TextFont, f_TextColor, f_TextAlign);
end;

procedure Tf2Context.AllowActionDecorators(aSwitch: Boolean);
var
 l_AD: If2ActionDecorator;
 I : Integer;
begin
 for I := 0 to f_Decorators.Count-1 do
 begin
  l_AD := f_Decorators.Decorators[I].AsActionDecorator;
  if l_AD <> nil then
   l_AD.Allowed := aSwitch;
 end;
end;

procedure Tf2Context.CheckIfNumber(const Value: Variant);
begin
 if not VarIsNumeric(Value) then
  raise EFURQRunTimeError.Create(cNotANumberValue);
end;

function Tf2Context.DoActionFinal(const anActionData: IFURQActionData): Boolean;
begin
 Result := inherited DoActionFinal(anActionData);
 if Result then
 begin
  f_LocationText := '';
  f_TextPane.DropLinks;
  VoiceStop;
 end;
end;

procedure Tf2Context.ClearButtons;
begin
 inherited ClearButtons;
 f_TextPane.ClearButtons;
 f_TextPane.FixMorePosition;
end;

procedure Tf2Context.ClearText;
begin
 f_TextPane.ClearAll;
 f_TextPane.FixMorePosition;
 f_LocationText := '';
end;

procedure Tf2Context.DoLoadData(aFiler: TFURQFiler);
begin
 inherited DoLoadData(aFiler);
 Decorators.Load(aFiler, Self);
 f_TextPane.LoadText(aFiler, f_FontPool, f_PicturePool);
 f_BtnMenuAlign := Td2dAlign(aFiler.ReadByte);
 f_LinkMenuAlign := Td2dAlign(aFiler.ReadByte);
 if aFiler.ReadBoolean then // музыку надо включить
  MusicPlay(aFiler.ReadString, 0)
 else
  MusicStop(0); 
end;

procedure Tf2Context.DoSaveData(aFiler: TFURQFiler);
var
 l_IsMusic: Boolean;
begin
 inherited DoSaveData(aFiler);
 Decorators.Save(aFiler);
 f_TextPane.SaveText(aFiler);
 aFiler.WriteByte(Ord(f_BtnMenuAlign));
 aFiler.WriteByte(Ord(f_LinkMenuAlign));
 l_IsMusic := gD2DE.Music_IsPlaying and (f_CurrentMusic <> ''); // второе - если музыку выключили с угасанием (она звучит, но уже считается выключенной)
 aFiler.WriteBoolean(l_IsMusic);
 if l_IsMusic then
  aFiler.WriteString(f_CurrentMusic);
end;

procedure Tf2Context.DropLinks;
begin
 f_TextPane.DropLinks;
end;

procedure Tf2Context.FadeMusic(const aVolume: Byte; const aFadeTime: Longword);
begin
 gD2DE.Music_SetVolume(aVolume, aFadeTime);
end;

function Tf2Context.GetButtonFrame(const aName: string): Id2dFramedButtonView;
begin
 Result := f_Skin.Frames[aName];
 if Result = nil then
  Result := f_DefButtonFrame;
end;

function Tf2Context.GetDecorator(const aDName: string): Tf2BaseDecorator;
var
 l_Idx: Integer;
begin
 Result := nil;
 l_Idx := Decorators.IndexOf(aDName);
 if l_Idx <> -1 then
  Result := Decorators.Decorators[l_Idx];
end;

function Tf2Context.GetMouseDecorator: Tf2BaseDecorator;
var
 l_Str: string;
begin
 l_Str := EnsureString(Variables[cs_MouseDecoratorVarName]);
 if l_Str <> '' then
  Result := GetDecorator(l_Str)
 else
  Result := nil; 
end;

function Tf2Context.GetVirtualVariable(const aName: string): Variant;
var
 l_AD: If2ActionDecorator;
 l_DName, l_DVar: string;
 l_Decor: Tf2BaseDecorator;
 l_TP: If2TargetProvider;

 function BoolToVar(const aBool: Boolean): Variant;
 begin
  if aBool then
   Result := 1.0
  else
   Result := 0.0;
 end;

begin
 Result := inherited GetVirtualVariable(aName);
 if (Result = Null) then
 begin
  if ParseDecorVar(aName, l_DName, l_DVar) then
  begin
   l_Decor := GetDecorator(l_DName);
   if l_Decor <> nil then
   begin
    l_DVar := AnsiUpperCase(l_DVar);
    if (l_DVar = 'X') then
     Result := l_Decor.PosX
    else
    if (l_DVar = 'Y') then
     Result := l_Decor.PosY
    else
    if (l_DVar = 'Z') then
     Result := l_Decor.PosZ
    else
    if (l_DVar = cs_COLOR) and (l_Decor is Tf2ColoredDecorator) then
     Result := VarAsType(Tf2ColoredDecorator(l_Decor).Color, varDouble)
    else
    if (l_DVar = cs_HIDE) then
     Result := BoolToVar(l_Decor.Visible)
    else
    if l_DVar = cs_WIDTH then
     Result := l_Decor.Width
    else
    if l_DVar = cs_HEIGHT then
     Result := l_Decor.Height
    else
    if (l_DVar = cs_SCRIPT) then
     Result := '' // скрипт нигде не хранится, поэтому получить его от декоратора нельзя
    else
    if l_Decor is Tf2TextDecorator then
    begin
     if l_DVar = cs_TEXT then
      Result := Tf2TextDecorator(l_Decor).Text
     else
     if l_DVar = cs_ALIGN then
      Result := Integer(Tf2TextDecorator(l_Decor).Align)+1
     else
     if l_DVar = cs_LINESPACING then
      Result := Tf2TextDecorator(l_Decor).LineSpacing
     else
     if l_DVar = cs_PARASPACING then
      Result := Tf2TextDecorator(l_Decor).ParaSpacing
     else
     if l_DVar = cs_LINKCOLOR then
      Result := VarAsType(Tf2TextDecorator(l_Decor).LinkColor, varDouble)
     else
     if l_DVar = cs_LINKHCOLOR then
      Result := VarAsType(Tf2TextDecorator(l_Decor).LinkHColor, varDouble)
    end;

    if (Result = Null) and (l_Decor is Tf2GraphicDecorator) then
    begin
     if l_DVar = cs_HOTX then
      Result := Tf2GraphicDecorator(l_Decor).HotX
     else
     if l_DVar = cs_HOTY then
      Result := Tf2GraphicDecorator(l_Decor).HotY
     else
     if l_DVar = cs_ANGLE then
      Result := Tf2GraphicDecorator(l_Decor).Angle
     else
     if l_DVar = cs_ROTSPEED then
      Result := Tf2GraphicDecorator(l_Decor).RotSpeed
     else
     if l_DVar = cs_SCALE then
      Result := Tf2GraphicDecorator(l_Decor).Scale;
    end;

    if (Result = Null) and (l_Decor is Tf2BasicSpriteDecorator) then
    begin
     if l_DVar = cs_FLIPX then
      Result := BoolToVar(Tf2BasicSpriteDecorator(l_Decor).FlipX)
     else
     if l_DVar = cs_FLIPY then
      Result := BoolToVar(Tf2BasicSpriteDecorator(l_Decor).FlipY);
    end;

    if (Result = Null) and (l_Decor is Tf2AnimationDecorator) then
    begin
     if l_DVar = cs_FRAME then
      Result := Tf2AnimationDecorator(l_Decor).CurFrame
     else
     if l_DVar = cs_ANISPEED then
      Result := Tf2AnimationDecorator(l_Decor).Speed
     else
     if l_DVar = cs_ANITYPE then
      Result := Tf2AnimationDecorator(l_Decor).AniType;
    end;
    if (Result = Null) and (l_Decor is Tf2GIFDecorator) then
    begin
     if l_DVar = cs_FRAME then
      Result := Tf2GIFDecorator(l_Decor).Frame
     else
     if l_DVar = cs_ANISPEED then
      Result := Tf2GIFDecorator(l_Decor).AniSpeed;
    end;
    if (Result = Null) and Supports(l_Decor, If2TargetProvider, l_TP) then
    begin
     if l_DVar = cs_TARGET then
      Result := l_TP.GetTargetProcessor.Target;
    end;
    if (Result = Null) and (l_Decor is Tf2TextButtonDecorator) then
    begin
     if l_DVar = cs_TEXT then
      Result := Tf2TextButtonDecorator(l_Decor).Text
     else
     if l_DVar = cs_ALIGN then
      Result := AlignToInt(Tf2TextButtonDecorator(l_Decor).TextAlign);
    end;
   end;

   if (Result = Null) and (l_DVar = cs_ENABLED) then
   begin
    l_AD := l_Decor.AsActionDecorator;
    if l_AD <> nil then
     Result := BoolToVar(l_AD.Enabled);
   end;
   if (Result = Null) and (l_DVar = cs_MENUALIGN) then
   begin
    l_AD := l_Decor.AsActionDecorator;
    if l_AD <> nil then
     Result := D2DAlignToStr(l_AD.MenuAlign);
   end;
  end; // if ParseDecorVar(aName, l_DName, l_DVar)

  if Result = Null then
  begin
   if AnsiSameText(aName, c_MouseX) then
    Result := gD2DE.MouseX
   else
   if AnsiSameText(aName, c_MouseY) then
    Result := gD2DE.MouseY
   else
   if AnsiSameText(aName, c_BMenuAlign) then
    Result := D2DAlignToStr(f_BtnMenuAlign)
   else
   if AnsiSameText(aName, c_LMenuAlign) then
    Result := D2DAlignToStr(f_LinkMenuAlign)
  end;

  if (Result = Null) and AnsiSameText(aName, c_FullScreen) then
   Result := BoolToVar(not gD2DE.Windowed);

  if (Result = Null) and AnsiSameText(aName, c_IsMusic) then
   Result := BoolToVar(gD2DE.Music_IsPlaying);

  if (Result = Null) and AnsiStartsText(cs_GSS_, aName) then
  begin
   l_DName := Copy(aName, 5, MaxInt);
   Result := f_SettingsStorage[l_DName];
  end;
 end;
end;

procedure Tf2Context.InitSysVariables;
begin
 inherited;
 Variables[c_Gametitle] := f_Filename;
 Variables[c_StyleDosTextcolor] := 7;
 Variables[c_LinkColor] := $FF3d56c0;
 Variables[c_LinkHColor] := $FF6f89fc;
 Variables[c_EchoColor] := $FF505050;
 Variables[c_Textalign] := 1;
 Variables[c_MusicLooped] := 1;
 Variables[c_Textfont] := c_Sysfont;
 Variables[c_MusicVolume] := 255;

 Variables[c_TextPaneLeft]   := f_DefTPLeft;
 Variables[c_TextPaneTop]    := f_DefTPTop;
 Variables[c_TextPaneWidth]  := f_DefTPWidth;
 Variables[c_TextPaneHeight] := f_DefTPHeight;

 Variables[c_ParaSpacing] := 0;
 Variables[c_LineSpacing] := 0;

 Variables[c_BtnAlign]    := AlignToInt(f_DefBtnAlign);
 Variables[c_BtnTxtAlign] := AlignToInt(f_DefBtnTxtAlign);

 Variables[c_VoiceVolume] := 255;

 Variables[c_NumButtons] := 0;

 Variables[c_HideLocalActionEchoVar] := 1;

 Variables[c_MenuFontVar]           := c_SysMenuFont;
 Variables[c_MenuBGColorVar]        := f_DefMenuVisualStyle.rBGColor;
 Variables[c_MenuBorderColorVar]    := f_DefMenuVisualStyle.rBorderColor;
 Variables[c_MenuTextColorVar]      := f_DefMenuVisualStyle.rTextColor;
 Variables[c_MenuHIndentVar]        := f_DefMenuVisualStyle.rHIndent;
 Variables[c_MenuVIndentVar]        := f_DefMenuVisualStyle.rVIndent;
 Variables[c_MenuSelectionColorVar] := f_DefMenuVisualStyle.rSelectionColor;
 Variables[c_MenuSelectedColorVar]  := f_DefMenuVisualStyle.rSelectedColor;
 Variables[c_MenuDisabledColorVar]  := f_DefMenuVisualStyle.rDisabledColor;

 Variables[c_fp_filename] := '';

 Variables[c_SaveNameBase] := ChangeFileExt(ExtractFileName(f_Filename), '');
 {
 if gD2DE.Windowed then
  Variables[c_FullScreen] := 0.0
 else
  Variables[c_FullScreen] := 1.0;
 } 
end;

function Tf2Context.IsSystemOrVirtualVariable(aVarName: string): Boolean;
begin
 Result := inherited IsSystemOrVirtualVariable(aVarName) or AnsiStartsText(cs_Decor_, aVarName) or
  AnsiSameText(aVarName, c_MouseX) or AnsiSameText(aVarName, c_MouseY) or
  AnsiSameText(aVarName, c_BMenuAlign) or AnsiSameText(aVarName, c_LMenuAlign) or
  AnsiSameText(aVarName, c_FullScreen) or AnsiSameText(aVarName, c_SaveNameBase) or
  AnsiStartsText(cs_GSS_, aVarName) or
  AnsiSameText(aVarName, c_IsMusic);
end;

procedure Tf2Context.KillSettingsStorage;
begin
 f_SettingsStorage.Clear;
end;

procedure Tf2Context.MusicPlay(const aFilename: string; aFadeTime: Integer);
begin
 gD2DE.Music_Play(aFilename, Variables[c_MusicLooped] > 0, aFadeTime);
 f_CurrentMusic := aFilename;
end;

procedure Tf2Context.MusicStop(aFadeTime: Integer);
begin
 gD2DE.Music_Stop(aFadeTime);
 f_CurrentMusic := '';
end;

procedure Tf2Context.OutPicture(const aFilename: string; aX, aY, aWidth, aHeight: Integer);
var
 l_Str: string;
 l_Alpha: Integer;
 l_Picture: Id2dPicture;
begin
 l_Alpha := f_TextColor shr 24;
 l_Str := Format('%s:%d:%d:%d:%d:%d', [aFilename, aX, aY, aWidth, aHeight, l_Alpha]);
 l_Picture := f_PicturePool.GetByID(l_Str);
 if l_Picture <> nil then
 begin
  f_TextPane.AddPicture(l_Picture, f_TextAlign);
  f_LocationText := f_LocationText + cs_IMG;
 end;
end;

procedure Tf2Context.OutText(const aStr: string);
begin
 f_LocationText := f_LocationText +
   OutTextWithLinks(aStr, Self, Self);
end;

function Tf2Context.ParseDecorVar(const aVarName: string; var theDName,
    theDVarName: string): Boolean;
var
 l_VN: string;
 l_Pos: Integer;
 l_DN: string;
begin
 Result := False;
 if AnsiStartsText(cs_Decor_, aVarName) then
 begin
  l_VN := Copy(aVarName, 7, MaxInt);
  if Pos('_', l_VN) > 0 then
  begin
   l_Pos := Length(l_VN);
   while (l_VN[l_Pos] <> '_') do
    Dec(l_Pos);
   l_DN := Copy(l_VN, 1, l_Pos-1);
   Delete(l_VN, 1, l_Pos);
   if (l_DN <> '') and (l_VN <> '') then
   begin
    theDName := l_DN;
    theDVarName := l_VN;
    Result := True;
   end;
  end;
 end;
end;

function Tf2Context.pm_GetActionsData(anID: string): IFURQActionData;
var
 I: Integer;
 l_AC: If2ActionDecorator;
begin
 Result := inherited pm_GetActionsData(anID);
 if Result = nil then
 begin
  for I := 0 to f_Decorators.Count - 1 do
  begin
   l_AC := f_Decorators.Decorators[I].AsActionDecorator;
   if l_AC <> nil then
   begin
    Result := l_AC.GetActionsData(anID);
    if Result <> nil then
     Break;
   end;
  end;
 end;
end;

procedure Tf2Context.Restart;
begin
 inherited;
 f_BtnMenuAlign := alTopLeft;
 f_LinkMenuAlign := alBottomLeft;
 VoiceStop;
 f_FontPool.Clear;
end;

procedure Tf2Context.SetSysVariables(aName: string; const Value: Variant);
var
 l_Filename: string;
 l_Tmp: Int64;
begin
 inherited SetSysVariables(aName, Value);

 if AnsiSameText(aName, c_Textcolor) then
 begin
  CheckIfNumber(Value);
  f_TextColor := CorrectColor(Trunc(Value));
 end

 else

 if AnsiSameText(aName, c_LinkColor) then
 begin
  CheckIfNumber(Value);
  f_LinkColor := CorrectColor(Trunc(Value));
 end

 else

 if AnsiSameText(aName, c_LinkHColor) then
 begin
  CheckIfNumber(Value);
  f_LinkHColor := CorrectColor(Trunc(Value));
 end

 else

 if AnsiSameText(aName, c_EchoColor) then
 begin
  CheckIfNumber(Value);
  f_EchoColor := CorrectColor(Trunc(Value));
 end

 else

 if AnsiSameText(aName, c_StyleDosTextcolor) then
 begin
  l_Tmp := Value;
  l_Tmp := l_Tmp and $0F;
  Variables[c_Textcolor] := cDOSColors[l_Tmp];
 end

 else

 if AnsiSameText(aName, c_Textalign) then
 begin
  VariantToAlign(Value, f_TextAlign);
 end

 else

 if AnsiSameText(aName, c_Textfont) then
 begin
  f_TextFont := f_FontPool.GetFont(Value);
  if f_TextFont = nil then
   Variables[c_Textfont] := c_Sysfont;
 end

 else

 if AnsiSameText(aName, c_fp_filename) then
 begin
  l_Filename := EnsureString(Value);
  if l_Filename <> '' then
  begin
   l_Filename := ExtractFileName(l_Filename);
   l_Filename := ChangeFileExt(l_Filename, '.txt');
  end;
  if EnsureString(Variables[c_fp_filename]) <> l_Filename then
   Variables[c_fp_filename] := l_Filename
  else
  begin
   if l_Filename = '' then
    f_FpFilename := ''
   else
    f_FpFilename := f_Path + l_Filename;
  end;
 end

 else

 if AnsiSameText(aName, c_MusicVolume) then
 begin
  CheckIfNumber(Value);
  l_Tmp := Trunc(Value);
  if l_Tmp < 0 then
   l_Tmp := 0
  else
   if l_Tmp > 255 then
    l_Tmp := 255;
  gD2DE.MusicVolume := l_Tmp;
 end

 else

 if AnsiSameText(aName, c_TextPaneLeft) then
  f_TextPane.X := EnsureReal(Value)
 else
 if AnsiSameText(aName, c_TextPaneTop) then
  f_TextPane.Y := EnsureReal(Value)
 else
 if AnsiSameText(aName, c_TextPaneWidth) then
  f_TextPane.Width := EnsureReal(Value)
 else
 if AnsiSameText(aName, c_TextPaneHeight) then
  f_TextPane.Height := EnsureReal(Value)

 else

 if AnsiSameText(aName, c_BtnAlign) then
  f_TextPane.ButtonAlign := IntToAlign(Value)
 else
 if AnsiSameText(aName, c_BtnTxtAlign) then
  f_TextPane.ButtonTextAlign := IntToAlign(Value)

 else

 if AnsiSameText(aName, c_ParaSpacing) then
  f_TextPane.ParaSpacing := EnsureReal(Value)
 else
 if AnsiSameText(aName, c_LineSpacing) then
  f_TextPane.LineSpacing := EnsureReal(Value)

 else

 if AnsiSameText(aName, c_NumButtons) then
  f_TextPane.NumberedButtons := Value > 0
 else

 if AnsiSameText(aName, c_MenuFontVar) then
 begin
  f_MenuFont := f_FontPool.GetFont(Value);
  if f_MenuFont = nil then
   Variables[c_MenuFontVar] := c_SysMenuFont;
 end
 else
 if AnsiSameText(aName, c_MenuBGColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rBGColor := CorrectColor(Trunc(Value));
 end
 else
 if AnsiSameText(aName, c_MenuBorderColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rBorderColor := CorrectColor(Trunc(Value))
 end
 else
 if AnsiSameText(aName, c_MenuTextColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rTextColor := CorrectColor(Trunc(Value))
 end
 else
 if AnsiSameText(aName, c_MenuBGColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rBGColor := CorrectColor(Trunc(Value))
 end
 else
 if AnsiSameText(aName, c_MenuHIndentVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rHIndent := Value
 end
 else
 if AnsiSameText(aName, c_MenuVIndentVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rVIndent := Value
 end
 else
 if AnsiSameText(aName, c_MenuSelectionColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rSelectionColor := CorrectColor(Trunc(Value))
 end
 else
 if AnsiSameText(aName, c_MenuSelectedColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rSelectedColor := CorrectColor(Trunc(Value))
 end
 else
 if AnsiSameText(aName, c_MenuDisabledColorVar) then
 begin
  CheckIfNumber(Value);
  f_MenuVisualStyle.rDisabledColor := CorrectColor(Trunc(Value))
 end
end;

function Tf2Context.SetVirtualVariables(const aName: string; const aValue:
    Variant): Boolean;
var
 l_AD: If2ActionDecorator;
 l_DName: string;
 l_DVar: string;
 l_Decor: Tf2BaseDecorator;
 l_Align: Td2dTextAlignType;
 l_TP: If2TargetProvider;
begin
 Result := inherited SetVirtualVariables(aName, aValue);
 if not Result then
 begin
  if ParseDecorVar(aName, l_DName, l_DVar) then
  begin
   l_Decor := GetDecorator(l_DName);
   if l_Decor <> nil then
   begin
    Result := True;
    l_DVar := AnsiUpperCase(l_DVar);
    if (l_DVar = 'X') then
     l_Decor.PosX := EnsureReal(aValue)
    else
    if (l_DVar = 'Y') then
     l_Decor.PosY := EnsureReal(aValue)
    else
    if (l_DVar = 'Z') then
     l_Decor.PosZ := EnsureReal(aValue)
    else
    if (l_DVar = cs_COLOR) and (l_Decor is Tf2ColoredDecorator) then
     Tf2ColoredDecorator(l_Decor).Color := CorrectColor(aValue)
    else
    if (l_DVar = cs_HIDE) then
     l_Decor.Visible := aValue = 0
    else
    if (l_DVar = cs_SCRIPT) then
     l_Decor.Script := CompileDSOperators(aValue)
    else
     Result := False;

    if (not Result) and (l_Decor is Tf2TextDecorator) then
    begin
     Result := True;
     if l_DVar = cs_TEXT then
      Tf2TextDecorator(l_Decor).Text := EnsureString(aValue)
     else
     if l_DVar = cs_WIDTH then
      Tf2TextDecorator(l_Decor).Width := aValue
     else
     if l_DVar = cs_ALIGN then
     begin
      l_Align := Tf2TextDecorator(l_Decor).Align;
      VariantToAlign(aValue, l_Align);
      Tf2TextDecorator(l_Decor).Align := l_Align;
     end
     else
     if l_DVar = cs_LINESPACING then
      Tf2TextDecorator(l_Decor).LineSpacing := aValue
     else
     if l_DVar = cs_PARASPACING then
      Tf2TextDecorator(l_Decor).ParaSpacing := aValue
     else
     if l_DVar = cs_LINKCOLOR then
      Tf2TextDecorator(l_Decor).LinkColor := CorrectColor(aValue)
     else
     if l_DVar = cs_LINKHCOLOR then
      Tf2TextDecorator(l_Decor).LinkHColor := CorrectColor(aValue)
     else
      Result := False;
    end;

    if (not Result) and (l_Decor is Tf2GraphicDecorator) then
    begin
     Result := True;
     if l_DVar = cs_HOTX then
      Tf2GraphicDecorator(l_Decor).HotX := aValue
     else
     if l_DVar = cs_HOTY then
      Tf2GraphicDecorator(l_Decor).HotY := aValue
     else
     if l_DVar = cs_ANGLE then
      Tf2GraphicDecorator(l_Decor).Angle := aValue
     else
     if l_DVar = cs_ROTSPEED then
      Tf2GraphicDecorator(l_Decor).RotSpeed := aValue
     else
     if l_DVar = cs_SCALE then
      Tf2GraphicDecorator(l_Decor).Scale := aValue
     else
      Result := False;
    end;

    if (not Result) and (l_Decor is Tf2BasicSpriteDecorator) then
    begin
     Result := True;
     if l_DVar = cs_FLIPX then
      Tf2BasicSpriteDecorator(l_Decor).FlipX := (aValue <> 0.0)
     else
     if l_DVar = cs_FLIPY then
      Tf2BasicSpriteDecorator(l_Decor).FlipY := (aValue <> 0.0)
     else
      Result := False;
    end;

    if (not Result) and (l_Decor is Tf2AnimationDecorator) then
    begin
     Result := True;
     if l_DVar = cs_FRAME then
      Tf2AnimationDecorator(l_Decor).CurFrame := aValue
     else
     if l_DVar = cs_ANISPEED then
      Tf2AnimationDecorator(l_Decor).Speed := aValue
     else
     if l_DVar = cs_ANITYPE then
      Tf2AnimationDecorator(l_Decor).AniType := aValue
     else
      Result := False;
    end;

    if (not Result) and (l_Decor is Tf2GIFDecorator) then
    begin
     Result := True;
     if l_DVar = cs_FRAME then
      Tf2GIFDecorator(l_Decor).Frame := aValue
     else
     if l_DVar = cs_ANISPEED then
      Tf2GIFDecorator(l_Decor).AniSpeed := aValue
     else
      Result := False;
    end;

    if (not Result) and (l_Decor is Tf2TextButtonDecorator) then
    begin
     Result := True;
     if l_DVar = cs_TEXT then
      Tf2TextButtonDecorator(l_Decor).Text := aValue
     else
     if l_DVar = cs_WIDTH then
      Tf2TextButtonDecorator(l_Decor).Width := aValue
     else
     if l_DVar = cs_ALIGN then
      Tf2TextButtonDecorator(l_Decor).TextAlign := IntToAlign(aValue)
     else
      Result := False;
    end;

    if (not Result) and (l_DVar = cs_ENABLED) then
    begin
     Result := True;
     l_AD := l_Decor.AsActionDecorator;
     if l_AD <> nil then
      l_AD.Enabled := (aValue <> 0.0);
    end;

    if (not Result) and (l_DVar = cs_MENUALIGN) then
    begin
     Result := True;
     l_AD := l_Decor.AsActionDecorator;
     if l_AD <> nil then
      l_AD.MenuAlign := D2DStrToAlign(EnsureString(aValue));
    end;

    if (not Result) and Supports(l_Decor, If2TargetProvider, l_TP) then
    begin
     Result := True;
     if l_DVar = cs_TARGET then
      l_TP.GetTargetProcessor.Target := EnsureString(aValue)
     else
      Result := False;
    end;
   end;
  end;

  if (not Result) and AnsiSameText(aName, c_FullScreen) then
  begin
   gD2DE.Windowed := (aValue = 0);
   Result := True;
  end;

  if (not Result) and AnsiSameText(aName, c_BMenuAlign) then
  begin
   f_BtnMenuAlign := D2DStrToAlign(EnsureString(aValue));
   Result := True;
  end;
  if (not Result) and AnsiSameText(aName, c_LMenuAlign) then
  begin
   f_LinkMenuAlign := D2DStrToAlign(EnsureString(aValue));
   Result := True;
  end;

  if (not Result) and AnsiStartsText(cs_GSS_, aName) then
  begin
   l_DName := Copy(aName, 5, maxInt);
   if l_DName <> '' then
    f_SettingsStorage[l_DName] := aValue;
   Result := True; 
  end;

  if not Result then
   Result := AnsiSameText(aName, c_MouseX) or AnsiSameText(aName, c_MouseY);
 end;
end;

procedure Tf2Context.SoundPlay(const aFilename: string; aVolume: Integer; aLooped: Boolean);
begin
 gD2DE.Snd_PlaySample(aFilename, aVolume, aLooped);
end;

procedure Tf2Context.SoundStop(const aFilename: string);
begin
 if aFilename = '' then
  gD2DE.Snd_StopAll
 else
  gD2DE.Snd_StopSample(aFilename); 
end;

function Tf2Context.SystemProc(aProcName: string; aParams: IJclStringList): Boolean;
var
 I: Integer;
 l_Col : Variant;
begin
 if AnsiSameText(aProcName, cs__color) and (aParams.Count > 2) then
 begin
  for I := 0 to Pred(aParams.Count) do
   aParams.Variants[I] := aParams.Variants[I] mod 256;
  if aParams.Count = 3 then
   l_Col := ARGB($FF, aParams.Variants[0], aParams.Variants[1], aParams.Variants[2])
  else
   l_Col := ARGB(aParams.Variants[0], aParams.Variants[1], aParams.Variants[2], aParams.Variants[3]);
  Variables[cs__result] := VarAsType(l_Col, varDouble);
  Result := True;
 end;
 if not Result then
  Result := inherited SystemProc(aProcName, aParams);
end;

procedure Tf2Context.VoicePlay(const aFilename: string);
begin
 VoiceStop;
 f_VoiceFilename := aFilename;
 gD2DE.Snd_PlaySample(aFilename, Variables[c_VoiceVolume]);
end;

procedure Tf2Context.VoiceStop;
begin
 if f_VoiceFilename <> '' then
 begin
  gD2DE.Snd_FreeSample(f_VoiceFilename);
  f_VoiceFilename := '';
 end;
end;

end.


