unit f2ScnSaveLoad;

interface

uses
 d2dTypes,
 d2dInterfaces,
 d2dApplication,
 d2dGUI,
 d2dUtils,
 d2dFont,

 f2Application,
 f2Scene,
 f2SaveLoadManager, 
 f2Context;

type
 Tf2SaveLoadMode = (slmSave, slmLoad);

 Tf2SaveLoadScene = class(Tf2Scene)
 private
  f_BGColor: Td2dColor;
  f_CaptionColor: Td2dColor;
  f_CaptionFont: Id2dFont;
  f_GUI: Td2dGUI;
  f_Captions : array[0..cMaxSlotsNum] of string;
  f_DT : array[0..cMaxSlotsNum] of TDateTime;
  f_CaptionX: Integer;
  f_CaptionY: Integer;
  f_Mode: Tf2SaveLoadMode;
  f_Selected: Integer;
  function pm_GetCaptions(aIndex: Integer): string;
  procedure pm_SetCaptions(aIndex: Integer; const Value: string);
  procedure ButtonClickHandler(aSender: TObject);
  procedure DoBack(aSender: TObject);
  function pm_GetDT(Index: Integer): TDateTime;
  procedure pm_SetDT(Index: Integer; const Value: TDateTime);
 protected
  procedure DoFrame(aDelta: Single); override;
  procedure DoLoad; override;
  procedure DoProcessEvent(var theEvent: Td2dInputEvent); override;
  procedure DoRender; override;
  procedure DoUnload; override;
 public
  property Captions[aIndex: Integer]: string read pm_GetCaptions write pm_SetCaptions;
  property DT[Index: Integer]: TDateTime read pm_GetDT write pm_SetDT;
  property Mode: Tf2SaveLoadMode read f_Mode write f_Mode;
  property Selected: Integer read f_Selected;
 end;

implementation

uses
 SimpleXML,
 d2dCore,
 f2FontLoad, f2Skins, d2dGUIButtons,

 SysUtils, f2Decorators;

// START resource string wizard section
resourcestring
 c_sSaveload = 'saveload';
 c_sBgcolor = 'bgcolor';
 c_sCaptioncolor = 'captioncolor';
 c_sCaptionfont = 'captionfont';
 c_sButtons = 'buttons';
 c_sFrame = 'frame';
 c_sBackButton = 'backbutton';

// END resource string wizard section

const
 c_Captions : array [Tf2SaveLoadMode] of string = ('Сохранение игры', 'Загрузка игры');


procedure Tf2SaveLoadScene.ButtonClickHandler(aSender: TObject);
begin
 f_Selected := Td2dControl(aSender).Tag;
 StopAsChild;
end;

procedure Tf2SaveLoadScene.DoBack(aSender: TObject);
begin
 StopAsChild;
end;

procedure Tf2SaveLoadScene.DoFrame(aDelta: Single);
var
 l_MouseDecorator: Tf2BaseDecorator;
begin
 l_MouseDecorator := Context.GetMouseDecorator;
 gD2DE.HideMouse := l_MouseDecorator <> nil;
 if l_MouseDecorator <> nil then
 begin
  l_MouseDecorator.PosX := gD2DE.MouseX;
  l_MouseDecorator.PosY := gD2DE.MouseY;
 end;
 f_GUI.FrameFunc(aDelta);
end;

procedure Tf2SaveLoadScene.DoLoad;
var
 I: Integer;
 l_BackButton: Td2dBitButton;
 l_ButtonHeight: Integer;
 l_Frame: Id2dFramedButtonView;
 l_Root: IXmlNode;
 l_Node: IXmlNode;
 l_Buttons: array[0..cMaxSlotsNum] of Td2dFramedTextButton;
 l_ButtonsNum: Integer;
 l_ButtonX: Integer;
 l_ButtonY: Integer;
 l_Caption: string;
 l_MaxWidth: Single;
 l_CaptionGap, l_ButtonsGap: Integer;
 l_DTS: string;
 l_FullHeight: Integer;
 l_MaxAllowedWidth: Integer;
 l_Size: Td2dPoint;
begin
 l_Root := F2App.Skin.XML.DocumentElement.SelectSingleNode(c_sSaveload);
 if l_Root <> nil then
 begin
  f_BGColor := Td2dColor(l_Root.GetHexAttr(c_sBgcolor, $C0000000));
  f_CaptionColor := Td2dColor(l_Root.GetHexAttr(c_sCaptioncolor, $FFFFBB4F));
  if l_Root.AttrExists(c_sCaptionfont) then
   f_CaptionFont := F2App.Skin.Fonts[l_Root.GetAttr(c_sCaptionfont)];
  l_Node := l_Root.SelectSingleNode(c_sButtons);
  if l_Node <> nil then
   if l_Node.AttrExists(c_sFrame) then
    l_Frame := F2App.Skin.Frames[l_Node.GetAttr(c_sFrame)];
  l_BackButton := LoadButton(l_Root, c_sBackButton);
 end
 else
 begin
  f_BGColor := $C0000000;
  f_CaptionColor := $FFFFBB4F;
  l_BackButton := nil;
 end;
 if f_CaptionFont = nil then
  f_CaptionFont := F2App.DefaultTextFont;
 if l_Frame = nil then
  l_Frame := F2App.DefaultButtonView;

 f_GUI := Td2dGUI.Create;
 if l_BackButton = nil then
  l_BackButton := Td2dBitButton.Create(700, 55, F2App.DefaultTexture, 564, 97, 45, 45);
 with l_BackButton do
 begin
  CanBeFocused := False;
  OnClick := DoBack;
 end;
 f_GUI.AddControl(l_BackButton);
 l_MaxAllowedWidth := gD2DE.ScreenWidth - l_Frame.MinWidth;
 l_MaxWidth := 0;
 FillChar(l_Buttons, SizeOf(l_Buttons), 0);
 for I := 0 to cMaxSlotsNum do
 begin
  if (I = 0) and ((f_Captions[0] = '') or (f_Mode = slmSave)) then
   Continue;
  if f_Captions[I] = '' then
   l_Caption := ''
  else
  begin
   DateTimeToString(l_DTS, 'd mmm yyyy, hh:nn:ss', DT[I]);
   l_DTS := ' ('+l_DTS+')';
   l_Caption := l_Frame.CorrectCaptionEx(f_Captions[I], l_MaxAllowedWidth, l_DTS);
  end;
  l_Buttons[I] := Td2dFramedTextButton.Create(0, 0, l_Frame, l_Caption);
  if l_Buttons[I].Caption = '' then
  begin
   l_Buttons[I].Caption := '[пусто]';
   if f_Mode = slmLoad then
    l_Buttons[I].Enabled := False;
  end;
  l_Buttons[I].Tag := I;
  l_Buttons[I].OnClick := ButtonClickHandler;
  l_Buttons[I].AutoFocus := True;
  if l_MaxWidth < l_Buttons[I].Width then
   l_MaxWidth := l_Buttons[I].Width;
  f_GUI.AddControl(l_Buttons[I]);
 end;

 l_CaptionGap := Round(l_Buttons[1].Height / 2);
 l_ButtonsGap := Round(l_Buttons[1].Height / 7);

 f_CaptionFont.CalcSize(c_Captions[f_Mode], l_Size);
 f_CaptionX := Round((gD2DE.ScreenWidth - l_Size.X) / 2);

 l_FullHeight := Round(l_Size.Y) + l_CaptionGap;
 if l_Buttons[0] <> nil then
  l_ButtonsNum := cMaxSlotsNum + 1
 else
  l_ButtonsNum := cMaxSlotsNum;

 l_ButtonHeight := Round(l_Buttons[1].Height);
 l_FullHeight := l_FullHeight + (l_ButtonHeight * l_ButtonsNum) + (l_ButtonsGap * (l_ButtonsNum-1));

 f_CaptionY := (gD2DE.ScreenHeight - l_FullHeight) div 2;

 l_ButtonY := f_CaptionY + Round(l_Size.Y) + l_CaptionGap;
 l_ButtonX := (gD2DE.ScreenWidth - Round(l_MaxWidth)) div 2;

 for I := 0 to cMaxSlotsNum do
 begin
  if l_Buttons[I] = nil then
   Continue;
  with l_Buttons[I] do
  begin
   AutoSize := False;
   Width := l_MaxWidth;
   X := l_ButtonX;
   Y := l_ButtonY;
   l_ButtonY := l_ButtonY + l_ButtonHeight + l_ButtonsGap;
  end;
 end;
 f_Selected := -1;
end;

procedure Tf2SaveLoadScene.DoProcessEvent(var theEvent: Td2dInputEvent);
begin
 if theEvent.EventType = INPUT_KEYDOWN then
 begin
  if theEvent.KeyCode = D2DK_ESCAPE then
  begin
   DoBack(Self);
   Processed(theEvent);
  end;

  if theEvent.KeyCode = D2DK_DOWN then
  begin
   f_GUI.FocusNext;
   Processed(theEvent);
  end;

  if theEvent.KeyCode = D2DK_UP then
  begin
   f_GUI.FocusPrev;
   Processed(theEvent);
  end;
 end;
 f_GUI.ProcessEvent(theEvent);
end;

procedure Tf2SaveLoadScene.DoRender;
var
 l_MouseDecorator: Tf2BaseDecorator;
begin
 D2DRenderFilledRect(D2DRect(0, 0, gD2DE.ScreenWidth, gD2DE.ScreenHeight), f_BGColor);
 f_CaptionFont.Color := f_CaptionColor;
 f_CaptionFont.Render(f_CaptionX, f_CaptionY, c_Captions[f_Mode]);
 f_GUI.Render;
 l_MouseDecorator := Context.GetMouseDecorator;
 gD2DE.HideMouse := l_MouseDecorator <> nil;
 if l_MouseDecorator <> nil then
  l_MouseDecorator.Render;
end;

procedure Tf2SaveLoadScene.DoUnload;
begin
 FreeAndNil(f_GUI);
end;

function Tf2SaveLoadScene.pm_GetCaptions(aIndex: Integer): string;
begin
 Result := f_Captions[aIndex];
end;

function Tf2SaveLoadScene.pm_GetDT(Index: Integer): TDateTime;
begin
 Result := f_DT[Index];
end;

procedure Tf2SaveLoadScene.pm_SetCaptions(aIndex: Integer; const Value: string);
begin
 f_Captions[aIndex] := Value;
end;

procedure Tf2SaveLoadScene.pm_SetDT(Index: Integer; const Value: TDateTime);
begin
 f_DT[Index] := Value;
end;

end.

