unit f2TextPane;

interface

uses
 d2dTypes,
 d2dFont,
 d2dFormattedText,
 d2dGUITypes,
 d2dGUI,
 d2dGUITextPane,
 d2dGUIButtons
 ;

type
 Tf2ButtonSlice = class(Td2dCustomSlice)
 private
  f_Align: Td2dTextAlignType;
  f_Frame  : Id2dFramedButtonView;
  f_Caption: string;
  f_DispCaption: string;
  f_Height: Single;
  f_State: Td2dButtonState;
  f_BWidth: Integer;
  function pm_GetFrameHeight: Single;
  function pm_GetRect: Td2dRect;
  procedure pm_SetBWidth(const Value: Integer);
 protected
  function pm_GetHeight: Single; override;
  function pm_GetWidth: Single; override;
  procedure DoDraw(X, Y: Single); override;
 public
  constructor Create(aFrame: Id2dFramedButtonView; aCaption: string; aAlign: Td2dTextAlignType);
  function IsInButton(aX, aY: Single): Boolean;
  property Align: Td2dTextAlignType read f_Align;
  property Caption: string read f_Caption;
  property State: Td2dButtonState read f_State write f_State;
  property BWidth: Integer read f_BWidth write pm_SetBWidth;
  property FrameHeight: Single read pm_GetFrameHeight;
  property Rect: Td2dRect read pm_GetRect;
 end;

 Tf2ButtonActionEvent = procedure(aButtonIdx: Integer) of object; 

 Tf2TextPane = class(Td2dTextPane)
 private
  f_ButtonAlign: Td2dTextAlignType;
  f_ButtonCount: Integer;
  f_ButtonsEnabled: Boolean;
  f_ButtonTextAlign: Td2dTextAlignType;
  f_FirstButtonPara: Integer;
  f_FocusedButton: Integer;
  f_Frame: Id2dFramedButtonView;
  f_OnButtonAction: Tf2ButtonActionEvent;
  f_MaxButtonWidth: Integer;
  f_NumberedButtons: Boolean;
  procedure CheckFocusedButton(var theEvent: Td2dInputEvent);
  procedure DoButtonAction; overload;
  procedure DoButtonAction(aButtonNo: Integer); overload;
  function GetButtonAtMouse: Integer;
  procedure MakeSureFocusedIsVisible;
  function pm_GetButtonCaption(Index: Integer): string;
  function pm_GetButtonScreenRect(Index: Integer): Td2dRect;
  function pm_GetButtonSlice(aButtonIndex: Integer): Tf2ButtonSlice;
  procedure pm_SetButtonsEnabled(const Value: Boolean);
  procedure pm_SetFocusedButton(const Value: Integer);
  procedure RealignButtons;
  procedure UpdateButtonsState;
 protected
  procedure pm_SetState(const Value: Td2dTextPaneState); override;
  procedure Scroll(aDelta: Single); override;
  property ButtonSlice[Index: Integer]: Tf2ButtonSlice read pm_GetButtonSlice;
 public
  constructor Create(aX, aY, aWidth, aHeight: Single; aFrame: Id2dFramedButtonView);
  procedure AddButton(aCaption: string);
  procedure ClearAll; override;
  procedure ClearButtons;
  procedure ProcessEvent(var theEvent: Td2dInputEvent); override;
  property ButtonAlign: Td2dTextAlignType read f_ButtonAlign write f_ButtonAlign;
  property ButtonCaption[Index: Integer]: string read pm_GetButtonCaption;
  property ButtonCount: Integer read f_ButtonCount;
  property ButtonScreenRect[Index: Integer]: Td2dRect read pm_GetButtonScreenRect;
  property ButtonsEnabled: Boolean read f_ButtonsEnabled write pm_SetButtonsEnabled;
  property ButtonTextAlign: Td2dTextAlignType read f_ButtonTextAlign write f_ButtonTextAlign;
  property FocusedButton: Integer read f_FocusedButton write pm_SetFocusedButton;
  property NumberedButtons: Boolean read f_NumberedButtons write f_NumberedButtons;
  property OnButtonAction: Tf2ButtonActionEvent read f_OnButtonAction write f_OnButtonAction;
 end;

implementation
uses
 SysUtils,

 d2dCore,
 d2dUtils;

constructor Tf2ButtonSlice.Create(aFrame  : Id2dFramedButtonView;
                                  aCaption: string;
                                  aAlign  : Td2dTextAlignType);
begin
 inherited Create;
 f_Frame := aFrame;
 f_Caption := aCaption;
 f_DispCaption := f_Caption;
 f_BWidth := f_Frame.CalcWidth(f_Caption);
 f_Frame.CorrectWidth(f_BWidth);
 f_Height := f_Frame.Height;
 f_State := bsNormal;
 f_Align := aAlign;
end;

procedure Tf2ButtonSlice.DoDraw(X, Y: Single);
begin
 f_Frame.Render(X, Y, f_DispCaption, f_State, f_BWidth, f_Align);
end;

function Tf2ButtonSlice.IsInButton(aX, aY: Single): Boolean;
begin
 Result := D2DIsPointInRect(aX, aY, Rect);
end;

function Tf2ButtonSlice.pm_GetFrameHeight: Single;
begin
 Result := f_Frame.Height;
end;

function Tf2ButtonSlice.pm_GetHeight: Single;
begin
 Result := f_Height;
end;

function Tf2ButtonSlice.pm_GetRect: Td2dRect;
begin
 Result := D2DRect(AbsLeft, AbsTop, AbsLeft + Width, AbsTop + Height);
end;

function Tf2ButtonSlice.pm_GetWidth: Single;
begin
 Result := f_BWidth;
end;

procedure Tf2ButtonSlice.pm_SetBWidth(const Value: Integer);
begin
 f_BWidth := Value;
 f_DispCaption := f_Frame.CorrectCaption(f_Caption, f_BWidth);
end;

constructor Tf2TextPane.Create(aX, aY, aWidth, aHeight: Single;
                               aFrame: Id2dFramedButtonView);
begin
 inherited Create(aX, aY, aWidth, aHeight);
 f_Frame := aFrame;
 f_FirstButtonPara := -1;
 f_ButtonAlign := ptLeftAligned;
 f_ButtonTextAlign := ptLeftAligned;
end;

procedure Tf2TextPane.AddButton(aCaption: string);
var
 l_BS: Tf2ButtonSlice;
 I: Integer;
begin
 if f_FirstButtonPara < 0 then
  f_FirstButtonPara := ParaCount;
 Inc(f_ButtonCount);
 if f_NumberedButtons and (f_ButtonCount < 10) then
  aCaption := Format('%d. %s', [f_ButtonCount, aCaption]);
 l_BS := Tf2ButtonSlice.Create(f_Frame, aCaption, f_ButtonTextAlign);
 if l_BS.BWidth > Width then
  l_BS.BWidth := Trunc(Width);
 AddPara(l_BS);
 if f_ButtonCount = 1 then
 begin
  ButtonSlice[1].State := bsFocused;
  f_FocusedButton := 1;
  f_MaxButtonWidth := ButtonSlice[1].BWidth;
 end
 else
 begin
  if ButtonSlice[ButtonCount].BWidth > f_MaxButtonWidth then
  begin
   f_MaxButtonWidth := ButtonSlice[ButtonCount].BWidth;
   for I := 1 to ButtonCount do
    ButtonSlice[I].BWidth := f_MaxButtonWidth;
  end
  else
   ButtonSlice[ButtonCount].BWidth := f_MaxButtonWidth;
 end;
 //DocRoot.RecalcHeight;
 RealignButtons;
 gD2DE.Input_TouchMousePos;
 //CheckFocusedButton;
end;

procedure Tf2TextPane.CheckFocusedButton(var theEvent: Td2dInputEvent);
var
 l_Button: Integer;
begin
 l_Button := GetButtonAtMouse;
 if (l_Button > 0) and not IsMouseMoveMasked(theEvent) then
 begin
  FocusedButton := l_Button;
  MaskMouseMove(theEvent);
 end;
end;

procedure Tf2TextPane.ClearAll;
begin
 ClearButtons;
 inherited ClearAll;
end;

procedure Tf2TextPane.ClearButtons;
begin
 if f_ButtonCount > 0 then
 begin
  ClearFromPara(f_FirstButtonPara);
  f_FirstButtonPara := -1;
  f_ButtonCount := 0;
  f_FocusedButton := 0;
  f_MaxButtonWidth := 0;
 end;
 //DocRoot.RecalcHeight;
end;

procedure Tf2TextPane.DoButtonAction;
begin
 if Assigned(f_OnButtonAction) then
  f_OnButtonAction(FocusedButton);
end;

procedure Tf2TextPane.DoButtonAction(aButtonNo: Integer);
begin
 if Assigned(f_OnButtonAction) and (aButtonNo > 0) and (aButtonNo <= f_ButtonCount) then
  f_OnButtonAction(aButtonNo);
end;

function Tf2TextPane.GetButtonAtMouse: Integer;
var
 l_InX: Single;
 l_InY: Single;
 I: Integer;
begin
 Result := 0;
 if IsMouseInControl then
 begin
  l_InX := gD2DE.MouseX - X;
  l_InY := gD2DE.MouseY - Y + ScrollShift;
  for I := 1 to ButtonCount do
   if IsSliceVisible(ButtonSlice[I]) then
    if ButtonSlice[I].IsInButton(l_InX, l_InY) then
    begin
     Result := I;
     Break;
    end;
 end;
end;

procedure Tf2TextPane.MakeSureFocusedIsVisible;
var
 l_ButtonPara: Td2dCustomSlice;
begin
 l_ButtonPara := GetPara(f_FirstButtonPara + f_FocusedButton - 1);
 if l_ButtonPara.Top < ScrollShift then
  ScrollTo(l_ButtonPara.Top, ScrollSpeed)
 else
  if l_ButtonPara.Top + l_ButtonPara.Height > ScrollShift + Height then
   ScrollTo(l_ButtonPara.Top + l_ButtonPara.Height - Height, ScrollSpeed);
end;

function Tf2TextPane.pm_GetButtonCaption(Index: Integer): string;
begin
 Result := ButtonSlice[Index].Caption;
end;

function Tf2TextPane.pm_GetButtonScreenRect(Index: Integer): Td2dRect;
begin
 Result := D2DMoveRect(ButtonSlice[Index].Rect, X, Y - ScrollShift);
end;

function Tf2TextPane.pm_GetButtonSlice(aButtonIndex: Integer): Tf2ButtonSlice;
begin
 Result := Tf2ButtonSlice(GetPara(f_FirstButtonPara + aButtonIndex - 1));
end;

procedure Tf2TextPane.pm_SetButtonsEnabled(const Value: Boolean);
var
 I: Integer;
begin
 if Value <> f_ButtonsEnabled then
 begin
  f_ButtonsEnabled := Value;
  if f_ButtonsEnabled then
  begin
   for I := 1 to ButtonCount do
    if I = FocusedButton then
     ButtonSlice[I].State := bsFocused
    else
     ButtonSlice[I].State := bsNormal;
  end
  else
   for I := 1 to ButtonCount do
    ButtonSlice[I].State := bsDisabled;
 end;
end;

procedure Tf2TextPane.pm_SetFocusedButton(const Value: Integer);
begin
 if not f_ButtonsEnabled then
  Exit;
 if f_FocusedButton > 0 then
  ButtonSlice[f_FocusedButton].State := bsNormal;
 f_FocusedButton := Value;
 ButtonSlice[f_FocusedButton].State := bsFocused;
 MakeSureFocusedIsVisible;
end;

procedure Tf2TextPane.pm_SetState(const Value: Td2dTextPaneState);
begin
 inherited;
 UpdateButtonsState;
end;

procedure Tf2TextPane.ProcessEvent(var theEvent: Td2dInputEvent);
var
 l_Button: Integer;
begin
 inherited;
 if IsProcessed(theEvent) then
  Exit;
 if (State = tpsIdle) and (ButtonCount > 0) then
 begin
  if (theEvent.EventType = INPUT_KEYDOWN) then
  begin
   if (theEvent.KeyCode = D2DK_DOWN) and (FocusedButton < ButtonCount) then
   begin
    FocusedButton := FocusedButton + 1;
    Processed(theEvent);
   end;
   if (theEvent.KeyCode = D2DK_UP) and (FocusedButton > 1) then
   begin
    FocusedButton := FocusedButton - 1;
    Processed(theEvent);
   end;
   if (theEvent.KeyCode in [D2DK_ENTER, D2DK_SPACE]) then
   begin
    DoButtonAction;
    Processed(theEvent);
   end;
   if f_NumberedButtons and (theEvent.KeyCode in [D2DK_1..D2DK_9]) then
   begin
    DoButtonAction(theEvent.KeyCode - D2DK_1 + 1);
    Processed(theEvent);
   end;
   if f_NumberedButtons and (theEvent.KeyCode in [D2DK_NUMPAD1..D2DK_NUMPAD9]) then
   begin
    DoButtonAction(theEvent.KeyCode - D2DK_NUMPAD1 + 1);
    Processed(theEvent);
   end;
  end;
  if (theEvent.EventType = INPUT_MOUSEMOVE) then
   CheckFocusedButton(theEvent);
  if (theEvent.EventType = INPUT_MBUTTONDOWN) and (theEvent.KeyCode = D2DK_LBUTTON) then
  begin
   l_Button := GetButtonAtMouse;
   if l_Button > 0 then
   begin
    DoButtonAction;
    Processed(theEvent);
   end;
  end;
 end;
end;

procedure Tf2TextPane.RealignButtons;
var
 I: Integer;
 l_BS: Tf2ButtonSlice;
 l_Left: Single;
begin
 if f_ButtonCount > 0 then
 begin
  case f_ButtonAlign of
   ptLeftAligned  : l_Left := 0;
   ptRightAligned : l_Left := Self.Width - f_MaxButtonWidth;
   ptCentered     :
    if Self.Width = f_MaxButtonWidth then
     l_Left := 0
    else
     l_Left := Round((Self.Width - f_MaxButtonWidth) / 2);
  end;
  for I := 1 to f_ButtonCount do
   ButtonSlice[I].Left := l_Left;
 end;
end;

procedure Tf2TextPane.Scroll(aDelta: Single);
begin
 inherited Scroll(aDelta);
 gD2DE.Input_TouchMousePos;
 //CheckFocusedButton;
end;

procedure Tf2TextPane.UpdateButtonsState;
begin
 ButtonsEnabled := State = tpsIdle;
end;

end.