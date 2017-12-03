unit f2Types;

interface
uses
 d2dTypes,
 d2dInterfaces,
 d2dClasses,
 d2dSprite,
 d2dFont,
 d2dGUITypes,
 JclStringLists;

type
 Tf2DecorType = (dtInvalid, dtText, dtRectangle, dtPicture, dtAnimation, dtGIF, dtClickArea, dtImgButton, dtTextButton);

const
 c_Gametitle = 'gametitle';
 c_StyleDosTextcolor = 'Style_dos_textcolor';
 c_Textalign = 'textalign';
 c_MusicLooped = 'music_looped';
 c_Textfont = 'textfont';
 c_Sysfont = '_sysfont';
 c_SysMenuFont = '_sysmenufont';
 c_Textcolor = 'textcolor';
 c_EchoColor = 'echocolor';
 c_LinkColor   = 'linkcolor';
 c_LinkHColor  = 'linkhcolor';
 c_MusicVolume = 'music_volume';
 c_VoiceVolume = 'voice_volume';
 c_TextPaneLeft   = 'textpane_left';
 c_TextPaneTop    = 'textpane_top';
 c_TextPaneWidth  = 'textpane_width';
 c_TextPaneHeight = 'textpane_height';
 c_MouseX         = 'mouse_x';
 c_MouseY         = 'mouse_y';
 c_fp_filename    = 'fp_filename';

 c_HideSaveEchoVar        = 'hide_save_echo';
 c_HideBtnEchoVar         = 'hide_btn_echo';
 c_HideInvEchoVar         = 'hide_inv_echo';
 c_HideLinkEchoVar        = 'hide_link_echo';
 c_HideLocalActionEchoVar = 'hide_local_echo';

 c_MenuFontVar           = 'menu_textfont';
 c_MenuBGColorVar        = 'menu_bgcolor';
 c_MenuBorderColorVar    = 'menu_bordercolor';
 c_MenuTextColorVar      = 'menu_textcolor';
 c_MenuHIndentVar        = 'menu_hindent';
 c_MenuVIndentVar        = 'menu_vindent';
 c_MenuSelectionColorVar = 'menu_selectioncolor';
 c_MenuSelectedColorVar  = 'menu_seltextcolor';
 c_MenuDisabledColorVar  = 'menu_disabledcolor';

 c_BtnAlign    = 'btnalign';
 c_BtnTxtAlign = 'btntxtalign';

 c_LineSpacing = 'linespacing';
 c_ParaSpacing = 'paraspacing';

 c_NumButtons = 'numbuttons';

 c_BMenuAlign = 'bmenualign';
 c_LMenuAlign = 'lmenualign';

 c_FullScreen = 'fullscreen';

 c_SaveNameBase = 'savenamebase';

type 
 Tf2DecorationSprite = class(Td2dSprite)
 private
  f_X: Single;
  f_Y: Single;
  f_Z: Single;
 public
  constructor Create(aTex: Id2dTexture; aTexX, aTexY: Integer; aWidth, aHeight: Integer; aX, aY: Single);
  procedure Render; reintroduce;
  property X: Single read f_X write f_X;
  property Y: Single read f_Y write f_Y;
 published
  property Z: Single read f_Z write f_Z;
 end;

type
 Tf2OnActionProc = procedure (const anID: string; const aRect: Td2dRect; const aMenuAlign: Td2dAlign) of object;

function CorrectColor(const aColor: Td2dColor): Td2dColor;

function Hex2ColorDef(aHex: string; const aDefault: Td2dColor): Td2dColor;

function IntToAlign(const aNum: Integer): Td2dTextAlignType;
function AlignToInt(const aAlign: Td2dTextAlignType): Integer;

implementation
uses
 SysUtils,
 d2dCore,

 f2FontLoad;

function CorrectColor(const aColor: Td2dColor): Td2dColor;
begin
 if (aColor and $FF000000) = 0 then
  Result := $FF000000 or aColor
 else
  Result := aColor;
end;

function AlignToInt(const aAlign: Td2dTextAlignType): Integer;
begin
 Result := Ord(aAlign) + 1;
end;

function IntToAlign(const aNum: Integer): Td2dTextAlignType;
begin
 case aNum of
  2: Result := ptRightAligned;
  3: Result := ptCentered;
 else
  Result := ptLeftAligned;
 end;
end;

function Hex2ColorDef(aHex: string; const aDefault: Td2dColor): Td2dColor;
begin
 if UpperCase(Copy(aHex, 1, 2)) = '0X' then
 begin
  Delete(aHex, 1, 1);
  aHex[1] := '$';
 end;
 Result := StrToInt64Def(aHex, aDefault);
end;

constructor Tf2DecorationSprite.Create(aTex: Id2dTexture; aTexX, aTexY: Integer; aWidth, aHeight: Integer; aX, aY:
    Single);
begin
 inherited Create(aTex, aTexX, aTexY, aWidth, aHeight);
 f_X := aX;
 f_Y := aY;
 f_Z := 3.4e38;
end;

procedure Tf2DecorationSprite.Render;
begin
 inherited Render(f_X, f_Y);
end;


end.