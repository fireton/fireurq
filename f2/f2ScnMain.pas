unit f2ScnMain;

interface
uses
 Clipbrd,
 Contnrs,

 d2dTypes,
 d2dInterfaces,
 d2dApplication,
 d2dSprite,

 d2dGUI,
 d2dGUITypes,
 d2dGUIButtons,
 d2dGUIMenus,

 f2Application,
 f2TextPane,
 f2Context,

 f2Scene,
 f2ScnSaveLoad,

 f2Interpreter,
 furqContext,
 furqBase,
 f2SaveLoadManager;

type
 Tf2WaitState = (wsNone, wsTimer, wsAnykey, wsScroll);
 Tf2MenuActionCallerID = (ciLink, ciTextButton, ciDecorator);

 Tf2Clipboard = class(TClipboard)
 public
  procedure PutTextAsUnicode(const aStr: string);
 end;

 Tf2MainScene = class(Tf2Scene)
 private
  f_BFrame: Id2dFramedButtonView;
  f_BGColor: Td2dColor;
  f_Clipboard: Tf2Clipboard;
  f_Code: TFURQCode;
  f_Interpreter: Tf2Interpreter;
  f_CurFilename: string;
  f_GUI: Td2dGUI;
  f_InvBtn: Td2dBitButton;
  f_InvMenu: Td2dMenu;
  f_LogFileName: string;
  f_MenuFont: Id2dFont;
  f_mi_Exit: Td2dMenuItem;
  f_mi_Load: Td2dMenuItem;
  f_mi_Mute: Td2dMenuItem;
  f_mi_Log : Td2dMenuItem;
  //f_mi_OpenQuest: Td2dMenuItem;
  f_mi_Restart: Td2dMenuItem;
  f_PauseTime: Double;
  f_SysBtn: Td2dBitButton;
  f_SysMenu: Td2dMenu;
  f_SysTextFont: Id2dFont;
  f_ButtonsFont: Id2dFont;
  f_InvMenuAlign: Td2dAlign;
  f_SkinDecorList: TObjectList;
  f_InvMenuEnabled: Boolean;
  f_InvMenuX: Single;
  f_InvMenuY: Single;
  f_mi_Reload: Td2dMenuItem;
  f_SaveLoadManager: Tf2SaveLoadManager;
  f_SaveLoadScene: Tf2SaveLoadScene;
  f_SysMenuAlign: Td2dAlign;
  f_SysMenuEnabled: Boolean;
  f_SysMenuX: Single;
  f_SysMenuY: Single;
  f_Txt: Tf2TextPane;
  f_WaitSprites: array[Tf2WaitState] of Td2dSprite;
  f_WaitState: Tf2WaitState;
  f_WSAlpha: Single;
  f_WSAlphaDir: Integer;
  f_WSWaitTimer: Single;
  f_ActionMenu: Td2dMenu;
  f_KeepMenuActions: Boolean;
  f_MenuActionCaller: string;
  f_MenuActionCallerID: Tf2MenuActionCallerID;
  f_SavePath: AnsiString;
  procedure ActionMessage(aMsg: string);
  procedure BuildMenuFromAction(const aActionID: string; aRoot: Td2dMenuItem);
  procedure ButtonActionHandler(aButtonIdx: Integer);
  procedure CheckWaitState;
  procedure ClearInventory;
  procedure ClearTextPane;
  procedure CopyToClipboard;
  procedure DoDebugReload;
  procedure DoEnd;
  function  OpenCodeFileProc(const aFilename: string): string;
  procedure DoOpenQuest;
  procedure DoPause;
  procedure DoSysBtnClick(aSender: TObject);
  procedure DoInvBtnClick(aSender: TObject);
  function GetLogFilename: string;
  procedure HandleInput;
  procedure HandleInputKey;
  procedure InputFinishHandler(aSender: TObject);
  procedure InvDisable;
  procedure InvEnable;
  procedure TextPaneStateChangeHandler(aSender: TObject);
  procedure InvMenuHandler(aSender: TObject);
  procedure ActionMenuClickHandler(aSender: TObject);
  procedure DecoratorActionHandler(const anID: string; const aRect: Td2dRect; const aMenuAlign: Td2dAlign);
  procedure DoLoadSavedGame;
  procedure DoQuit;
  procedure LinkClickHandler(const aSender: TObject; const aRect: Td2dRect; const aTarget: string);
  procedure InvPopup;
  procedure SysPopup;
  procedure LoadButtonsAndActions;
  procedure LoadGame;
  procedure LoadMenuOnItem(aRoot: Td2dMenuItem; aItemName: string);
  procedure LogAddTextHandler(const aSender: TObject; const aText: string; aColor: Td2dColor; aParaType: Td2dTextAlignType);
  procedure miaRestart(aSender: TObject);
  procedure miaLoad(aSender: TObject);
  procedure miaExit(aSender: TObject);
  //procedure miaOpenQuest(aSender: TObject);
  procedure miaMute(aSender: TObject);
  procedure miaLog(aSender: TObject);
  procedure NextTurn;
  procedure OpenInvMenu;
  procedure OpenSysMenu;
  procedure pm_SetInvMenuEnabled(const Value: Boolean);
  procedure pm_SetSysMenuEnabled(const Value: Boolean);
  procedure pm_SetWaitState(const Value: Tf2WaitState);
  procedure ReloadInventory;
  procedure SaveGame;
  procedure StartOver(aNeedClearTextPane: Boolean = True);
  procedure RunTimeErrorHandler(const aErrorMessage: string; aLine: Integer);
  procedure PopupActionMenu(const aActionID: string; aRect: Td2dRect; aAlign: Td2dAlign);
  procedure StartLogging(aDisplay: Boolean = True);
  procedure StopLogging;
 protected
  procedure BeforeStoppingChild; override;
  procedure DoLoad; override;
  procedure DoUnload; override;
  procedure DoFrame(aDelta: Single); override;
  procedure DoRender; override;
  procedure DoProcessEvent(var theEvent: Td2dInputEvent); override;
  property InvMenuEnabled: Boolean read f_InvMenuEnabled write pm_SetInvMenuEnabled;
  property SysMenuEnabled: Boolean read f_SysMenuEnabled write pm_SetSysMenuEnabled;
  property WaitState: Tf2WaitState read f_WaitState write pm_SetWaitState;
 public
  procedure LoadSavegameNames;
  procedure miaReload(aSender: TObject);
  procedure OutError(aMsg: string);
 end;

implementation
uses
 Windows,
 ShlObj,
 Classes,
 SysUtils,
 StrUtils,

 JclStringLists,
 SimpleXML,
 MD5,

 d2dCore,
 d2dUtils,
 d2dGUIUtils,

 furqTypes,
 furqLoader,

 f2Types,
 f2FontLoad,
 f2Utils,
 f2Skins,
 f2Decorators;

const

// START resource string wizard section
 SVarCurrentLoc = 'current_loc';
 SLog = '.%.3d.log';
 SInv = 'inv';
 SPhantom = ' //phantom';
 SVarGametitle = 'gametitle';
 SUsePrfix = 'use_';
 SHideSuffix = '_hide';
 SVarHidePauseIndicator = 'hide_pause_indicator';
 SVarHideAnykeyIndicator = 'hide_anykey_indicator';
 SVarHideMoreIndicator = 'hide_more_indicator';
 SVarIsSyskey = 'is_syskey';
 SStartLog = 'Начать запись лога';
 SStopLog  = 'Остановить запись лога';

// END resource string wizard section

 cVersion = '1.0.2';

 cWaitSpriteAlphaSpeed = 30;
 cWaitSpriteAlphaMin   = 10.0;
 cWaitSpriteAlphaMax   = 50.0;
 cTimeBeforeWaitSprite = 2.0;

function AttributesExists(const aNode: IXmlNode; aAttrNames: array of string): Boolean;
var
 I: Integer;
begin
 Result := False;
 for I := Low(aAttrNames) to High(aAttrNames) do
  if not aNode.AttrExists(aAttrNames[I]) then
   Exit;
 Result := True;  
end;

procedure Tf2MainScene.ActionMenuClickHandler(aSender: TObject);
var
 l_MI: Td2dMenuItem;
 l_ActionID: string;
 l_ActionStr: string;
 l_Hidevar: Real;
begin
 l_MI := Td2dMenuItem(aSender);
 l_ActionID := l_MI.Tag;
 if l_ActionID <> '' then
 begin
  Context.StateResult := Format('b:%s',[l_ActionID]);
  Context.Variables['last_btn_caption'] := l_MI.Caption;
  f_Txt.ClearButtons;
  if f_MenuActionCallerID in [ciLink, ciTextButton] then
  begin
   case f_MenuActionCallerID of
    ciLink       : l_HideVar := EnsureReal(Context.Variables[c_HideLinkEchoVar]);
    ciTextButton : l_HideVar := EnsureReal(Context.Variables[c_HideBtnEchoVar]);
   end;
   if (l_HideVar = 0.0) and (Context.ActionIsFinal(l_ActionID) or (EnsureReal(Context.Variables[c_HideLocalActionEchoVar]) = 0.0))  then
   begin
    l_ActionStr := '';
    while l_MI.Caption <> '' do
    begin
     if l_ActionStr = '' then
      l_ActionStr := l_MI.Caption
     else
      l_ActionStr := l_MI.Caption + ' -> ' + l_ActionStr;
     l_MI := l_MI.Parent;
    end;
    l_ActionStr := f_MenuActionCaller + ' -> ' + l_ActionStr;
    ActionMessage(l_ActionStr);
   end;
  end;
  NextTurn;
 end;
end;

procedure Tf2MainScene.ActionMessage(aMsg: string);
begin
 f_Txt.AddText(Format(#13#10'[%s]'#13#10#13#10, [aMsg]), f_SysTextFont, Context.EchoColor, ptLeftAligned);
end;

procedure Tf2MainScene.BeforeStoppingChild;
begin
 try
  case f_SaveLoadScene.Mode of
   slmSave :
    begin
     if f_SaveLoadScene.Selected > 0 then
      Context.StateResult := f_SaveLoadManager.SaveName[f_SaveLoadScene.Selected]
     else
      Context.StateResult := '';
     NextTurn;
    end;
   slmLoad :
    try
     if f_SaveLoadScene.Selected >= 0 then
     begin
      f_SaveLoadManager.LoadGame(Context, f_SaveLoadScene.Selected, F2App.DebugMode);
      NextTurn;
     end
     else
      if Context.State = csLoad then
       NextTurn;
    except
     on E: EFURQRunTimeError do
      begin
       if Context.State = csLoad then
       begin
        OutError(E.Message);
        NextTurn;
       end
       else
        raise;
      end;
    else
     raise;
    end;
  end;
 except
  on E: Exception do
  begin
   f_Txt.ClearButtons;
   OutError(E.Message);
   LoadButtonsAndActions;
  end; 
 end;
end;

procedure Tf2MainScene.BuildMenuFromAction(const aActionID: string; aRoot: Td2dMenuItem);
var
 I: Integer;
 l_Action: string;
 l_MI: Td2dMenuItem;
begin
 f_Interpreter.BuildMenu(Context, aActionID, f_KeepMenuActions);
 f_KeepMenuActions := True;
 if Context.Menu.Count > 0 then
 begin
  for I := 0 to Context.Menu.Count - 1 do
  begin
   l_MI := Td2dMenuItem.Create(Context.Menu[I]);
   l_Action := Context.Menu.Variants[I];
   if l_Action <> '' then
   begin
    l_MI.OnClick := ActionMenuClickHandler;
    l_MI.Tag := l_Action;
   end
   else
    l_MI.Enabled := False;
   aRoot.AddChild(l_MI)
  end;
  for I := 0 to aRoot.ChildrenCount-1 do
  begin
   l_MI := aRoot.Children[I];
   l_Action := l_MI.Tag;
   if Context.ActionIsMenu(l_Action) then
    BuildMenuFromAction(l_Action, l_MI);
  end;
 end;
end;

procedure Tf2MainScene.ButtonActionHandler(aButtonIdx: Integer);
var
 l_ActionID: string;
 l_ButtonCaption: string;
begin
 Dec(aButtonIdx);
 l_ActionID := Context.Buttons.Variants[aButtonIdx];
 if l_ActionID <> '' then
 begin
  l_ButtonCaption := Context.Buttons[aButtonIdx];
  if Context.ActionIsMenu(l_ActionID) then
  begin
   f_MenuActionCaller := l_ButtonCaption;
   f_MenuActionCallerID := ciTextButton;
   PopupActionMenu(l_ActionID, f_Txt.ButtonScreenRect[aButtonIdx+1], Context.BtnMenuAlign);
  end
  else
  begin
   Context.StateResult := Format('b:%s',[l_ActionID]);
   Context.Variables['last_btn_caption'] := l_ButtonCaption;
   f_Txt.ClearButtons;
   if (EnsureReal(Context.Variables[c_HideBtnEchoVar]) = 0.0) and
      (Context.ActionIsFinal(l_ActionID) or (EnsureReal(Context.Variables[c_HideLocalActionEchoVar]) = 0.0))  then
    ActionMessage(Context.Buttons[aButtonIdx]);
   NextTurn;
  end;
 end;
end;

procedure Tf2MainScene.CheckWaitState;
begin
 case f_Txt.State of
  tpsIdle:
   if Assigned(Context) then
   begin
    case Context.State of
     csInputKey: WaitState := wsAnykey;
     csPause   : WaitState := wsTimer;
    else
     WaitState := wsNone; 
    end;
   end
   else
    WaitState := wsNone;
  tpsMore:
   WaitState := wsScroll;
  else
   WaitState := wsNone;
 end;
end;

procedure Tf2MainScene.ClearInventory;
begin
 InvDisable;
 f_InvMenu.Root.ClearChildren;
end;

procedure Tf2MainScene.ClearTextPane;
begin
 f_Txt.ClearAll;
 f_Txt.FixMorePosition;
end;

procedure Tf2MainScene.CopyToClipboard;
begin
 f_Clipboard.PutTextAsUnicode(Context.LocationText);
end;

procedure Tf2MainScene.DecoratorActionHandler(const anID: string; const aRect: Td2dRect; const aMenuAlign: Td2dAlign);
begin
 if anID <> '' then
 begin
  if Context.ActionIsMenu(anID) then
  begin
   f_MenuActionCallerID := ciDecorator;
   PopupActionMenu(anID, aRect, aMenuAlign);
  end
  else
  begin
   Context.StateResult := Format('b:%s',[anID]);
   f_Txt.ClearButtons;
   NextTurn;
  end;
 end;
end;

const
 cTempSaveName = '$$FURQ_DEBUG$$';

procedure Tf2MainScene.DoDebugReload;
begin
 if F2App.IsFromPack then
 begin
  OutError('Ctrl+R не поддерживается в QSZ');
  Exit;
 end;
 Context.SaveToFile(cTempSaveName, Context.Variables[SVarCurrentLoc]);
 DoOpenQuest;
 Context.LoadFromFile(cTempSaveName, True);
 DeleteFile(cTempSaveName);
 NextTurn;
end;

procedure Tf2MainScene.DoEnd;
begin
 f_Txt.ButtonsEnabled := False;  // запрещаем кнопки...
 LoadButtonsAndActions;
 f_Txt.ScrollToBottom;
 f_Txt.ButtonsEnabled := True; // разрешаем кнопки ПОСЛЕ того, как скроллирование началось
 // а иначе MakeFocusedVisible перебивает ScrollToBottom
 // Не супер решение, но пусть пока так...
 gD2DE.Input_TouchMousePos;
 //f_Txt.CheckFocusedButton;
end;

procedure Tf2MainScene.DoInvBtnClick(aSender: TObject);
begin
 InvPopup;
end;

function CompareDecorSprites(Item1, Item2: Pointer): Integer;
var
 l_DS1: Tf2DecorationSprite absolute Item1;
 l_DS2: Tf2DecorationSprite absolute Item2;
begin
 if l_DS1.Z > l_DS2.Z then
  Result := -1
 else
  if l_DS1.Z < l_DS2.Z then
   Result := 1
  else
   Result := 0;  
end;

procedure Tf2MainScene.DoLoad;
var
 l_Dir: string;
 l_Root: IxmlNode;
 l_Node: IxmlNode;
 l_Left, l_Top, l_Width, l_Height: Integer;
 l_MenuVisualStyle : Td2dMenuVisualStyle;
 l_List: IXmlNodeList;
 I: Integer;
 l_Decor: Tf2DecorationSprite;
 l_DefTextFont: Id2dFont;
 l_DefMenuFont: Id2dFont;

 function LoadIcon(const aNode: IXmlNode; const aName: string): Td2dSprite;
 var
  l_Tex: Id2dTexture;
  l_SNode: IXmlNode;
  l_TX, l_TY, l_W, l_H: Integer;
 begin
  Result := nil;
  l_SNode := aNode.SelectSingleNode(aName);
  if l_SNode <> nil then
  begin
   l_Tex := F2App.Skin.Textures[l_SNode.GetAttr('tex')];
   if l_Tex <> nil then
   begin
    l_TX := l_SNode.GetIntAttr('tx');
    l_TY := l_SNode.GetIntAttr('ty');
    l_W := l_SNode.GetIntAttr('width');
    l_H := l_SNode.GetIntAttr('height');
    if (l_H > 0) and (l_W > 0) then
     Result := Td2dSprite.Create(l_Tex, l_TX, l_TY, l_W, l_H);
   end;
  end;
 end;

 function LoadDecorationSprite(const aNode: IXmlNode): Tf2DecorationSprite;
 var
  l_Tex: Id2dTexture;
  l_TX, l_TY, l_W, l_H: Integer;
  l_X, l_Y: Single;
 begin
  Result := nil;
  if (aNode.AttrExists('posx')) and (aNode.AttrExists('posy')) then
  begin
   l_Tex := F2App.Skin.Textures[aNode.GetAttr('tex')];
   if l_Tex <> nil then
   begin
    l_TX := aNode.GetIntAttr('tx');
    l_TY := aNode.GetIntAttr('ty');
    l_W := aNode.GetIntAttr('width');
    if l_W = 0 then
     l_W := l_Tex.SrcPicWidth;
    l_H := aNode.GetIntAttr('height');
    if l_H = 0 then
     l_H := l_Tex.SrcPicHeight;
    l_X := aNode.GetIntAttr('posx');
    l_Y := aNode.GetIntAttr('posy');
    if (l_H > 0) and (l_W > 0) then
    begin
     Result := Tf2DecorationSprite.Create(l_Tex, l_TX, l_TY, l_W, l_H, l_X, l_Y);
     Result.FlipX := aNode.GetBoolAttr('flipx');
     Result.FlipY := aNode.GetBoolAttr('flipy');
     if aNode.AttrExists('posz') then
      Result.Z := aNode.GetIntAttr('posz');
    end; 
   end;
  end;
 end;

 procedure LoadMenuData(const aNode: IXmlNode; const aName: string; var theX, theY: Single; var theAlign: Td2dAlign);
 var
  l_MNode: IXmlNode;
  l_DStr : string;
 begin
  l_MNode := aNode.SelectSingleNode(aName);
  if l_MNode <> nil then
  begin
   theX := l_MNode.GetIntAttr('posx');
   theY := l_MNode.GetIntAttr('posy');
   l_DStr := l_MNode.GetAttr('datum');
   theAlign := D2DStrToAlign(l_DStr);
  end;
 end;

 procedure InitMenuPosByButton(aButton: Td2dCustomButton; var theX, theY: Single; var theAlign: Td2dAlign);
 var
  l_MidX, l_MidY: Single;
 begin
  if aButton <> nil then
  begin
   l_MidX := aButton.X + aButton.Width/2;
   l_MidY := aButton.Y + aButton.Height/2;
   if l_MidX > gD2DE.ScreenWidth/2 then
   begin
    theX := aButton.X + aButton.Width;
    if l_MidY > gD2DE.ScreenHeight/2 then
    begin
     theY := aButton.Y - 2;
     theAlign := alBottomRight;
    end
    else
    begin
     theY := aButton.Y + aButton.Height + 2;
     theAlign := alTopRight;
    end;
   end
   else
   begin
    theX := aButton.X;
    if l_MidY > gD2DE.ScreenHeight/2 then
    begin
     theY := aButton.Y - 2;
     theAlign := alBottomLeft;
    end
    else
    begin
     theY := aButton.Y + aButton.Height + 2;
     theAlign := alTopLeft;
    end;
   end;
  end;
 end;

 function LoadAlign(const aNode: IXmlNode; const aName: string): Td2dTextAlignType;
 var
  l_Num: Integer;
 begin
  if aNode <> nil then
  begin
   l_Num := aNode.GetIntAttr(aName);
   Result := IntToAlign(l_Num);
  end;
 end;

begin
 f_Interpreter := Tf2Interpreter.Create;

 f_BGColor := 0;
 l_MenuVisualStyle := cDefaultMenuVisualStyle;

 f_SysMenuX := 5;
 f_SysMenuY := 5;
 f_SysMenuAlign := alTopLeft;

 f_InvMenuX := gD2DE.ScreenWidth - 5;
 f_InvMenuY := 5;
 f_InvMenuAlign := alTopRight;

 l_Root := F2App.Skin.XML.DocumentElement.SelectSingleNode('main');
 if l_Root <> nil then
 begin
  f_BGColor := Td2dColor(l_Root.GetHexAttr('bgcolor'));

  l_Node := l_Root.SelectSingleNode('textpane');
  if l_Node <> nil then
  begin
   if l_Node.AttrExists('font') then
    f_SysTextFont := F2App.Skin.Fonts[l_Node.GetAttr('font')];
   if f_SysTextFont = nil then
    f_SysTextFont := F2App.DefaultTextFont;

   if l_Node.AttrExists('bframe') then
    f_BFrame := F2App.Skin.Frames[l_Node.GetAttr('bframe')];
   if f_BFrame = nil then
    f_BFrame := F2App.DefaultButtonView;
    
   l_Left := l_Node.GetIntAttr('left', 20);
   l_Top  := l_Node.GetIntAttr('top', 10);
   l_Width  := l_Node.GetIntAttr('width', gD2DE.ScreenWidth - 20 - l_Left);
   l_Height := l_Node.GetIntAttr('height', gD2DE.ScreenHeight - 10 - l_Top);
   f_Txt := Tf2TextPane.Create(l_Left, l_Top, l_Width, l_Height, f_BFrame);
   f_Txt.ButtonAlign := LoadAlign(l_Node, 'btnalign');
   f_Txt.ButtonTextAlign := LoadAlign(l_Node, 'btntxtalign');
  end;

  l_Node := l_Root.SelectSingleNode('menus');
  if l_Node <> nil then
  begin
   if l_Node.AttrExists('font') then
    f_MenuFont := F2App.Skin.Fonts[l_Node.GetAttr('font')];
   if f_MenuFont = nil then
    f_MenuFont := F2App.DefaultMenuFont;
   with l_MenuVisualStyle do
   begin
    rBGColor        := Td2dColor(l_Node.GetHexAttr('bgcolor', $FFFFFFFF));
    rBorderColor    := Td2dColor(l_Node.GetHexAttr('bordercolor', $FFA0A0A0));
    rTextColor      := Td2dColor(l_Node.GetHexAttr('textcolor', $FF000000));
    rHIndent        := l_Node.GetIntAttr('hindent', 0);
    rVIndent        := l_Node.GetIntAttr('vindent', 0);
    rSelectionColor := Td2dColor(l_Node.GetHexAttr('selectioncolor', $FF0000A0));
    rSelectedColor  := Td2dColor(l_Node.GetHexAttr('selectedcolor', $FFFFFFFF));
    rDisabledColor  := Td2dColor(l_Node.GetHexAttr('disabledcolor', $FFC0C0C0));
   end;

   f_SysBtn := LoadButton(l_Node, 'sysbutton');
   f_InvBtn := LoadButton(l_Node, 'invbutton');
   InitMenuPosByButton(f_SysBtn, f_SysMenuX, f_SysMenuY, f_SysMenuAlign);
   InitMenuPosByButton(f_InvBtn, f_InvMenuX, f_InvMenuY, f_InvMenuAlign);

   LoadMenuData(l_Node, 'sysmenu', f_SysMenuX, f_SysMenuY, f_SysMenuAlign);
   LoadMenuData(l_Node, 'invmenu', f_InvMenuX, f_InvMenuY, f_InvMenuAlign);
  end;

  l_Node := l_Root.SelectSingleNode('icons');
  if l_Node <> nil then
  begin
   f_WaitSprites[wsTimer]  := LoadIcon(l_Node, 'timer');
   f_WaitSprites[wsAnykey] := LoadIcon(l_Node, 'anykey');
   f_WaitSprites[wsScroll] := LoadIcon(l_Node, 'scroll');
  end;

  f_SkinDecorList := TObjectList.Create(True);
  l_Node := l_Root.SelectSingleNode('decorations');
  if l_Node <> nil then
  begin
   l_List := l_Node.SelectNodes('image');
   for I := 0 to l_List.Count - 1 do
   begin
    l_Decor := LoadDecorationSprite(l_List[I]);
    if l_Decor <> nil then
     f_SkinDecorList.Add(l_Decor);
   end;
   f_SkinDecorList.Sort(CompareDecorSprites); // sorting by z
  end;
 end;

 if f_SysTextFont = nil then
  f_SysTextFont := F2App.DefaultTextFont;
 if f_MenuFont = nil then
  f_MenuFont := F2App.DefaultMenuFont;
 if f_BFrame = nil then
  f_BFrame := F2App.DefaultButtonView;

 //f_HLine := Td2dSprite.Create(l_Tex, 0, 47, 566, 17);
 f_GUI := Td2dGUI.Create;
 f_GUI.BringFocusedToFront := False;

 //f_SysBtn := Td2dBitButton.Create(0, 0, l_Tex, 0, 0, 106, 46);
 if f_SysBtn <> nil then
 begin
  f_SysBtn.CanBeFocused := False;
  f_SysBtn.OnClick := DoSysBtnClick;
  f_GUI.AddControl(f_SysBtn);
 end;

 //f_InvBtn := Td2dBitButton.Create(671, 0, l_Tex, 424, 0, 130, 46);
 if f_InvBtn <> nil then
 begin
  f_InvBtn.CanBeFocused := False;
  f_InvBtn.OnClick := DoInvBtnClick;
  f_GUI.AddControl(f_InvBtn);
 end;

 SysMenuEnabled := True;
 InvMenuEnabled := False;

 if f_Txt = nil then
  f_Txt := Tf2TextPane.Create(20, 10, gD2DE.ScreenWidth - 40, gD2DE.ScreenHeight - 20, f_BFrame);

 f_Txt.OnButtonAction := ButtonActionHandler;
 f_Txt.OnEndInput := InputFinishHandler;
 f_Txt.OnStateChange := TextPaneStateChangeHandler;
 f_Txt.OnLinkClick := LinkClickHandler;

 //f_Txt.AddText('FireURQ '+cVersion, $FFFFEC23, ptLeftAligned);

 {
 f_mi_OpenQuest := Td2dMenuItem.Create('Открыть квест');
 f_mi_OpenQuest.OnClick := miaOpenQuest;
 }
 f_mi_Restart   := Td2dMenuItem.Create('Начать игру заново');
 f_mi_Restart.OnClick := miaRestart;
 f_mi_Restart.Enabled := False;

 f_mi_Load      := Td2dMenuItem.Create('Загрузить сохранение');
 f_mi_Load.OnClick := miaLoad;
 f_mi_Load.Enabled := False;

 f_mi_Log := Td2dMenuItem.Create(SStartLog);
 f_mi_Log.OnClick := miaLog;

 f_mi_Mute := Td2dMenuItem.Create('Играть без звука');
 f_mi_Mute.Checkable := True;
 f_mi_Mute.OnClick := miaMute;

 f_mi_Exit      := Td2dMenuItem.Create('Выход');
 f_mi_Exit.OnClick := miaExit;

 if F2App.DebugMode then
 begin
  f_mi_Reload := Td2dMenuItem.Create('Перезагрузить QST-файл');
  f_mi_Reload.OnClick := miaReload;
  f_SysMenu := Td2dMenu.Create(f_MenuFont, [f_mi_Reload, f_mi_Restart, f_mi_Load, D2DMenuDash, f_mi_Log, f_mi_Mute, D2DMenuDash, f_mi_Exit]);
 end
 else
  f_SysMenu     := Td2dMenu.Create(f_MenuFont, [f_mi_Restart, f_mi_Load, D2DMenuDash, f_mi_Log, f_mi_Mute, D2DMenuDash, f_mi_Exit]);
 f_InvMenu      := Td2dMenu.Create(f_MenuFont);
 f_SysMenu.VisulalStyle := l_MenuVisualStyle;
 f_InvMenu.VisulalStyle := l_MenuVisualStyle;
 f_ActionMenu := Td2dMenu.Create(f_MenuFont);
 f_ActionMenu.VisulalStyle := l_MenuVisualStyle;

 f_GUI.AddControl(f_Txt);
 f_GUI.AddControl(f_SysMenu);
 f_GUI.AddControl(f_InvMenu);
 f_GUI.AddControl(f_ActionMenu);

 f_GUI.SendToBack(f_Txt);

 gD2DE.HideMouse := False;

 if f_WaitSprites[wsTimer] = nil then
  f_WaitSprites[wsTimer]  := Td2dSprite.Create(F2App.DefaultTexture,  744, 47, 33, 33);
 if f_WaitSprites[wsAnykey] = nil then
  f_WaitSprites[wsAnykey] := Td2dSprite.Create(F2App.DefaultTexture, 782, 47, 33, 33);
 if f_WaitSprites[wsScroll] = nil then
  f_WaitSprites[wsScroll] := Td2dSprite.Create(F2App.DefaultTexture, 820, 47, 33, 33);

 f_Interpreter.OnError := RuntimeErrorHandler;

 if F2App.LogToFile then
  StartLogging(False);

 f_Clipboard := Tf2Clipboard.Create;

 f_SaveLoadManager := Tf2SaveLoadManager.Create;

 f_SaveLoadScene := Tf2SaveLoadScene.Create(F2App); 

 DoOpenQuest;
 NextTurn;
end;

function Tf2MainScene.OpenCodeFileProc(const aFilename: string): string;
var
 l_Ext    : string;
 l_FS     : TStream;
begin
 l_Ext := AnsiLowerCase(ExtractFileExt(aFilename));
 l_FS := gD2DE.Resource_CreateStream(aFilename, F2App.IsFromPack);
 if l_FS <> nil then
 begin
  try
   if l_Ext = '.qs2' then // do not localize
    Result := FURQLoadQS2(l_FS)
   else
    if l_Ext = '.qs1' then // do not localize
     Result := FURQLoadQS1(l_FS)
    else
     Result := FURQLoadQST(l_FS);
  finally
   FreeAndNil(l_FS);
  end;
 end
 else
  OutError(Format('Файл %s не найден', [ExtractFileName(aFilename)]));
end;

procedure Tf2MainScene.DoOpenQuest;
var
 l_Path: array[0..MAX_PATH] of Char;
begin
 ClearTextPane;
 if f_Code <> nil then
  FreeAndNil(f_Code);
 f_Code := TFURQCode.Create;
 f_Code.Load(F2App.QuestToOpen, OpenCodeFileProc);
 f_CurFilename := ExtractFileName(F2App.QuestFileName);
 f_SavePath := ExtractFilePath(F2App.QuestFileName);
 if not IsDirWritable(f_SavePath) then
 begin
  if SHGetSpecialFolderPath(0, @l_Path, CSIDL_APPDATA, True) then
  begin
   f_SavePath := IncludeTrailingPathDelimiter(l_Path) + 'FireURQ\' + ChangeFileExt(f_CurFilename, '_') +
      MD5DigestToStr(f_Code.SourceHash);
   ForceDirectories(f_SavePath);
  end;
 end;
 f_SaveLoadManager.SavePath := f_SavePath;
 StartOver(False);
end;

procedure Tf2MainScene.DoPause;
begin
 f_PauseTime := StrToFloatDef(Context.StateParam[1], 1000)/1000;
 DoEnd;
end;

procedure Tf2MainScene.DoSysBtnClick(aSender: TObject);
begin
 SysPopup;
end;

procedure Tf2MainScene.DoUnload;
var
 l_WS: Tf2WaitState;
begin
 f_GUI.Free;
 FreeAndNil(f_SkinDecorList);
 f_SysTextFont := nil;
 f_MenuFont := nil;
 f_BFrame := nil;
 f_Interpreter.Free;
 for l_WS := Low(Tf2WaitState) to High(Tf2WaitState) do
  FreeAndNil(f_WaitSprites[l_WS]);
 FreeAndNil(f_Clipboard);
 FreeAndNil(f_SaveLoadManager);
 FreeAndNil(f_SaveLoadScene);
end;

procedure Tf2MainScene.DoFrame(aDelta: Single);
var
 l_MouseDecorator: Tf2BaseDecorator;
begin
 Context.Decorators.Update(aDelta);

 l_MouseDecorator := Context.GetMouseDecorator;
 gD2DE.HideMouse := l_MouseDecorator <> nil;
 if l_MouseDecorator <> nil then
 begin
  l_MouseDecorator.PosX := gD2DE.MouseX;
  l_MouseDecorator.PosY := gD2DE.MouseY;
 end;

 f_GUI.FrameFunc(aDelta);
 if (f_Txt.State = tpsIdle) and (f_PauseTime > 0) then
 begin
  f_PauseTime := f_PauseTime - aDelta;
  if f_PauseTime <= 0 then
  begin
   f_PauseTime := 0;
   if Context.State = csInputKey then
    Context.StateResult := '0'
   else
    Context.StateResult := '';
   NextTurn;
  end;
 end;
 if f_WaitSprites[f_WaitState] <> nil then
 begin
  if f_WSWaitTimer <= 0 then
  begin
   f_WSAlpha := f_WSAlpha + f_WSAlphaDir * cWaitSpriteAlphaSpeed * aDelta;
   if f_WSAlpha < cWaitSpriteAlphaMin then
   begin
    f_WSAlphaDir := 1;
    f_WSAlpha := cWaitSpriteAlphaMin;
   end;
   if f_WSAlpha > cWaitSpriteAlphaMax then
   begin
    f_WSAlphaDir := -1;
    f_WSAlpha := cWaitSpriteAlphaMax;
   end;
  end
  else
   f_WSWaitTimer := f_WSWaitTimer - aDelta;
 end;
end;

procedure Tf2MainScene.DoLoadSavedGame;
var
 l_Filename: string;
begin
 //OutError('Это такая тестовая строка текста');
 //Exit;
 if f_SaveLoadManager.IsOnlyAutoSaveExists then
 begin
  f_SaveLoadManager.LoadGame(Context, 0, F2App.DebugMode);
  NextTurn;
 end
 else
 begin
  LoadSavegameNames;
  f_SaveLoadScene.Mode := slmLoad;
  f_SaveLoadScene.Context := Context;
  StartChild(f_SaveLoadScene);
 end;
end;

function Tf2MainScene.GetLogFilename: string;
var
 l_Num: Integer;
begin
 l_Num := 0;
 repeat
  Result := ChangeFileExt(F2App.QuestToOpen, Format(SLog, [l_Num]));
  Inc(l_Num);
 until not FileExists(Result); 
end;

procedure Tf2MainScene.HandleInput;
begin
 InvDisable;
 f_Txt.StartInput(Context.TextFont, Context.TextColor, Context.TextAlign);
 f_Txt.ScrollToBottom;
end;

procedure Tf2MainScene.HandleInputKey;
begin
 InvDisable;
 if Context.StateParam[2] <> '' then
  f_PauseTime := StrToFloatDef(Context.StateParam[2], 1000)/1000;
 f_Txt.ScrollToBottom;
end;

procedure Tf2MainScene.InputFinishHandler(aSender: TObject);
begin
 Context.StateResult := f_Txt.InputResult;
 NextTurn;
end;

procedure Tf2MainScene.InvDisable;
begin
 f_InvMenu.Close(True);
 InvMenuEnabled := False;
end;

procedure Tf2MainScene.InvEnable;
begin
 InvMenuEnabled := (EnsureReal(Context.Variables[cVarInventoryEnabled]) <> 0) and (f_InvMenu.Root.ChildrenCount > 0);
end;

procedure Tf2MainScene.TextPaneStateChangeHandler(aSender: TObject);
begin
 CheckWaitState;
end;

procedure Tf2MainScene.InvMenuHandler(aSender: TObject);
var
 l_MI: Td2dMenuItem;
 l_Num: Integer;

 procedure Echo(const aStr: string);
 begin
  if EnsureReal(Context.Variables[c_HideInvEchoVar]) = 0.0 then
   ActionMessage(aStr);
 end;

begin
 l_MI := Td2dMenuItem(aSender);
 l_Num := l_MI.Tag;
 Context.StateResult := Format('i:%d',[l_Num]);
 f_Txt.ClearButtons;

 if l_MI.Parent = f_InvMenu.Root then
  Echo(l_MI.Caption)
 else
  Echo(Format('%s -> %s', [l_MI.Parent.Caption, l_MI.Caption]));
 NextTurn;
end;

procedure Tf2MainScene.InvPopup;
begin
 f_InvMenu.Popup(f_InvMenuX, f_InvMenuY, f_InvMenuAlign);
end;

procedure Tf2MainScene.SysPopup;
begin
 f_mi_Load.Enabled := f_SaveLoadManager.IsAnySaveExists;
 f_SysMenu.Popup(f_SysMenuX, f_SysMenuY, f_SysMenuAlign);
end;

procedure Tf2MainScene.LoadButtonsAndActions;
var
 I: Integer;
 l_Caption: string;
begin
 ReloadInventory;
 f_Txt.ClearButtons;
 for I := 0 to Context.Buttons.Count-1 do
 begin
  l_Caption := Context.Buttons[I];
  if Context.Buttons.Variants[I] = '' then
   l_Caption := l_Caption + SPhantom;
  f_Txt.AddButton(l_Caption);
 end;
 gD2DE.WindowTitle := Context.Variables[SVarGametitle]
end;

procedure Tf2MainScene.LoadMenuOnItem(aRoot: Td2dMenuItem; aItemName: string);
var
 l_ActName: string;
 l_IsDef: Boolean;
 I: Integer;
 l_MI: Td2dMenuItem;
 l_HideVariable: string;
 l_NamePrefix: string;
 l_CurUseItem: string;
begin
 l_NamePrefix := aItemName + '_';
 for I := 0 to Context.Code.ActionList.Count - 1 do
 begin
  l_CurUseItem := Context.Code.ActionList[I];
  if AnsiStartsText(l_NamePrefix, l_CurUseItem) or AnsiSameText(aItemName, l_CurUseItem) then
  begin
   l_HideVariable := SUsePrfix + l_CurUseItem + SHideSuffix;
   if Context.Variables[l_HideVariable] = 0 then
   begin
    l_ActName := Trim(Copy(l_CurUseItem, Length(l_NamePrefix)+1, MaxInt));
    l_IsDef := l_ActName = '';
    if l_IsDef then
     l_ActName := sDefaultActName;
    l_MI := Td2dMenuItem.Create(l_ActName);
    l_MI.Tag := Context.Code.ActionList.Variants[I];
    l_MI.OnClick := InvMenuHandler;
    aRoot.AddChild(l_MI);
   end;
  end;
 end;
end;

procedure Tf2MainScene.LogAddTextHandler(const aSender: TObject; const aText: string; aColor: Td2dColor; aParaType:
    Td2dTextAlignType);
var
 l_F: TFileStream;
 l_Mode: Word;
begin
 if aText = '' then
  Exit;
 if FileExists(f_LogFileName) then
  l_Mode := fmOpenReadWrite
 else
  l_Mode := fmCreate;
 l_F := TFileStream.Create(f_LogFileName, l_Mode);
 try
  l_F.Seek(0, soFromEnd);
  l_F.Write(aText[1], Length(aText));
 finally
  l_F.Free;
 end;
end;

procedure Tf2MainScene.miaExit(aSender: TObject);
begin
 DoQuit;
end;

{
procedure Tf2MainScene.miaOpenQuest(aSender: TObject);
var
 l_Filename: string;
begin
 try
  l_Filename := OpenFileDlg(gD2DE.WHandle, 'Выберите файл квеста', 'Файлы квестов'#0'*.qst;*.qs1;*.qs2;*.qsz'#0#0);
  if l_Filename <> '' then
   DoOpenQuest(l_Filename);
 except
  on E: Exception do
   f_Txt.AddText(#13#10+E.Message+#13#10, $FFFF0000, ptLeftAligned);
 end;
end;
}

procedure Tf2MainScene.miaRestart(aSender: TObject);
begin
 StartOver;
 NextTurn;
end;

procedure Tf2MainScene.miaLoad(aSender: TObject);
begin
 DoLoadSavedGame;
end;

{
procedure Tf2MainScene.miaOpenQuest(aSender: TObject);
var
 l_Filename: string;
begin
 try
  l_Filename := OpenFileDlg(gD2DE.WHandle, 'Выберите файл квеста', 'Файлы квестов'#0'*.qst;*.qs1;*.qs2;*.qsz'#0#0);
  if l_Filename <> '' then
   DoOpenQuest(l_Filename);
 except
  on E: Exception do
   f_Txt.AddText(#13#10+E.Message+#13#10, $FFFF0000, ptLeftAligned);
 end;
end;
}

procedure Tf2MainScene.miaMute(aSender: TObject);
begin
 gD2DE.SoundMute := f_mi_Mute.Checked;
end;

procedure Tf2MainScene.NextTurn;
var
 l_ActionsAllowed: Boolean;
begin
 f_Txt.ClearButtons;
 f_Txt.FixMorePosition;
 f_ActionMenu.Close;
 f_PauseTime := 0;
 f_Interpreter.Execute(Context);
 CheckWaitState;
 l_ActionsAllowed := not (Context.State in [csInput, csInputKey]);
 f_Txt.LinksAllowed := l_ActionsAllowed;
 Context.AllowActionDecorators(l_ActionsAllowed);
 case Context.State of
  csEnd     : DoEnd;
  csSave    : SaveGame;
  csInput   : HandleInput;
  csInputKey: HandleInputKey;
  csPause   : DoPause;
  csLoad    : LoadGame;
  csQuit    : DoQuit;
 end;
end;

procedure Tf2MainScene.OpenInvMenu;
begin
 if InvMenuEnabled then
 begin
  if f_InvBtn <> nil then
   f_InvBtn.Click
  else
   InvPopup;
 end;
end;

procedure Tf2MainScene.OpenSysMenu;
begin
 if SysMenuEnabled then
 begin
  if f_SysBtn <> nil then
   f_SysBtn.Click
  else
   SysPopup;
 end;
end;

procedure Tf2MainScene.OutError(aMsg: string);
begin
 gD2DE.System_Log('ОШИБКА: '+aMsg);
 f_Txt.AddText(#13#10+aMsg+#13#10#13#10, f_SysTextFont, $FFFF0000, ptLeftAligned);
end;

procedure Tf2MainScene.pm_SetInvMenuEnabled(const Value: Boolean);
begin
 f_InvMenuEnabled := Value;
 if f_InvBtn <> nil then
  f_InvBtn.Enabled := f_InvMenuEnabled;
end;

procedure Tf2MainScene.pm_SetSysMenuEnabled(const Value: Boolean);
begin
 f_SysMenuEnabled := Value;
 if f_SysBtn <> nil then
  f_SysBtn.Enabled := f_SysMenuEnabled;
end;

procedure Tf2MainScene.pm_SetWaitState(const Value: Tf2WaitState);
begin
 if Value <> f_WaitState then
 begin
  case Value of
   wsTimer:
    if Context.Variables[SVarHidePauseIndicator] > 0 then
    begin
     f_WaitState := wsNone;
     Exit;
    end;
   wsAnykey:
    if Context.Variables[SVarHideAnykeyIndicator] > 0 then
    begin
     f_WaitState := wsNone;
     Exit;
    end;
   wsScroll:
    if Context.Variables[SVarHideMoreIndicator] > 0 then
    begin
     f_WaitState := wsNone;
     Exit;
    end;
  end;
  f_WaitState := Value;
  f_WSAlpha := cWaitSpriteAlphaMin;
  f_WSAlphaDir := 1;
  f_WSWaitTimer := cTimeBeforeWaitSprite;
 end;
end;

const
 cNonProcessedKeys: set of Byte = [D2DK_SHIFT, D2DK_CTRL, D2DK_ALT, D2DK_CAPSLOCK, D2DK_NUMLOCK, D2DK_SCROLLLOCK];

procedure Tf2MainScene.DoProcessEvent(var theEvent: Td2dInputEvent);
var
 l_AD: If2ActionDecorator;
 l_Decor: Tf2BaseDecorator;
 l_Idx: Integer;
 l_MouseDecorator: Tf2BaseDecorator;
 l_TopCtrl: Td2dControl;
begin
 try
  if (f_Txt.State = tpsIdle) and (theEvent.EventType = INPUT_KEYDOWN) then
  begin
   if (theEvent.KeyCode = D2DK_C) and (theEvent.Flags and D2DINP_CTRL <> 0) then
   begin
    CopyToClipboard;
    Processed(theEvent);
   end
   else
   if (Context.State = csInputKey) then
   begin
    if (theEvent.KeyChar = 0) and not (theEvent.KeyCode in cNonProcessedKeys) then
    begin
     theEvent.KeyChar := theEvent.KeyScan;
     Context.Variables[SVarIsSyskey] := 1.0;
    end
    else
     Context.Variables[SVarIsSyskey] := 0.0;
    if theEvent.KeyChar <> 0 then
    begin
     Context.StateResult := IntToStr(theEvent.KeyChar);
     NextTurn;
    end;
    Processed(theEvent);
   end;
   if F2App.DebugMode and (theEvent.KeyCode = D2DK_R)
      and (theEvent.Flags and D2DINP_CTRL <> 0) then
    DoDebugReload;
  end;

  if (theEvent.EventType = INPUT_KEYDOWN) then
  begin
   if (theEvent.KeyCode = D2DK_ENTER) and (theEvent.Flags and D2DINP_ALT > 0) then
   begin
    gD2DE.Windowed := not gD2DE.Windowed;
    Processed(theEvent);
   end;
  end;

  // Это чтоб менюшки отрабатывали раньше декораторов
  l_TopCtrl := f_GUI.TopmostVisible;
  if (l_TopCtrl <> nil) and (l_TopCtrl is Td2dMenu) then
   l_TopCtrl.ProcessEvent(theEvent);

  l_MouseDecorator := Context.GetMouseDecorator;

  l_Idx := Context.Decorators.Count-1;

  while (l_Idx >= 0) and (Context.Decorators.Decorators[l_Idx].PosZ < 0) do
  begin
   l_Decor := Context.Decorators.Decorators[l_Idx];
   if l_Decor <> l_MouseDecorator then
   begin
    l_AD := l_Decor.AsActionDecorator;
    if (l_AD <> nil) and l_Decor.Visible then
    begin
     l_AD.ProcessEvent(theEvent);
     if IsProcessed(theEvent) then
      Break;
    end;
   end;
   Dec(l_Idx);
  end;

  if not IsProcessed(theEvent) then
   f_GUI.ProcessEvent(theEvent);

  if not IsProcessed(theEvent) then
  begin
   // потому как всё могло поменяться во время обработки гуя
   if l_Idx > Context.Decorators.Count-1 then
    l_Idx := Context.Decorators.Count-1;

   while (l_Idx >= 0) do
   begin
    l_Decor := Context.Decorators.Decorators[l_Idx];
    if l_Decor <> l_MouseDecorator then
    begin
     l_AD := l_Decor.AsActionDecorator;
     if (l_AD <> nil) and l_Decor.Visible then
      l_AD.ProcessEvent(theEvent);
    end;
    Dec(l_Idx);
   end;
  end;


  if (theEvent.EventType = INPUT_KEYDOWN) then
  begin
   if (theEvent.KeyCode = D2DK_I) and (not f_InvMenu.Visible) and InvMenuEnabled then
   begin
    OpenInvMenu;
    Processed(theEvent);
   end;
   if (theEvent.KeyCode = D2DK_ESCAPE) and (not f_SysMenu.Visible) and SysMenuEnabled then
   begin
    OpenSysMenu;
    Processed(theEvent);
   end;
  end;

  if (theEvent.EventType = INPUT_MBUTTONDOWN) and (Context.State = csInputKey) and (f_Txt.State = tpsIdle) then
  begin
   case theEvent.KeyCode of
    D2DK_LBUTTON : Context.StateResult := '256';
    D2DK_RBUTTON : Context.StateResult := '257';
    D2DK_MBUTTON : Context.StateResult := '258';
   end;
   Processed(theEvent);
   NextTurn;
  end;
  
 except
  on E: Exception do
   OutError(E.Message);
 end;
end;

procedure Tf2MainScene.DoQuit;
begin
 Application.Finished := True;
end;

procedure Tf2MainScene.ReloadInventory;
var
 l_Idx: Integer;
 l_MI: Td2dMenuItem;
 l_InvIsOpen: Boolean;

begin
 l_InvIsOpen := f_InvMenu.Visible;
 ClearInventory;
 LoadMenuOnItem(f_InvMenu.Root, SInv);
 //ReplaceDefActName(f_InvMenu.Root);
 for l_Idx := 0 to Context.Inventory.LastIndex do
 begin
  l_MI := Td2dMenuItem.Create(Context.GetInventoryString(l_Idx));
  LoadMenuOnItem(l_MI, Context.Inventory.Strings[l_Idx]);
  if (l_MI.ChildrenCount = 1) and (l_MI.Children[0].Caption = sDefaultActName) then
  begin
   l_MI.OnClick := l_MI.Children[0].OnClick;
   l_MI.Tag := l_MI.Children[0].Tag;
   l_MI.ClearChildren;
  end;
  f_InvMenu.Root.AddChild(l_MI);
 end;
 InvEnable;
 if InvMenuEnabled and l_InvIsOpen then
  InvPopup;
end;

procedure Tf2MainScene.DoRender;
var
 l_Color: Td2dColor;
 l_DIdx: Integer;
 l_TopCtrl: Td2dControl;
 I: Integer;
 l_MouseDecorator: Tf2BaseDecorator;
 l_Decorator: Tf2BaseDecorator;
 l_SkinDecorator: Tf2DecorationSprite;
 l_DSIdx: Integer;

 function l_GetDecorator(IsBeforeZero: Boolean): Tf2BaseDecorator;
 begin
  if l_DIdx < Context.Decorators.Count then
  begin
   Result := Context.Decorators.Decorators[l_DIdx];
   if IsBeforeZero and (Result.PosZ < 0) then
    Result := nil;
  end
  else
   Result := nil;
 end;

 function l_GetSkinDecorator(IsBeforeZero: Boolean): Tf2DecorationSprite;
 begin
  if f_SkinDecorList <> nil then
  begin
   if l_DSIdx < f_SkinDecorList.Count then
   begin
    Result := Tf2DecorationSprite(f_SkinDecorList.Items[l_DSIdx]);
    if IsBeforeZero and (Result.Z < 0) then
     Result := nil;
   end
   else
    Result := nil;
  end
  else
   Result := nil;
 end;

 procedure l_CheckIfMouseDecorator(IsBeforeZero: Boolean);
 begin
  if (l_Decorator <> nil) and (l_Decorator = l_MouseDecorator) then
  begin
   Inc(l_DIdx);
   l_Decorator := l_GetDecorator(IsBeforeZero);
  end;
 end;

 procedure l_UseDecorator(IsBeforeZero: Boolean);
 begin
  l_Decorator.Render;
  Inc(l_DIdx);
  l_Decorator := l_GetDecorator(IsBeforeZero);
  l_CheckIfMouseDecorator(IsBeforeZero);
 end;

 procedure l_UseSkinDecorator(IsBeforeZero: Boolean);
 begin
  l_SkinDecorator.Render;
  Inc(l_DSIdx);
  l_SkinDecorator := l_GetSkinDecorator(IsBeforeZero);
 end;

 procedure l_RenderDecorators(IsBeforeZero: Boolean);
 begin
  l_Decorator := l_GetDecorator(IsBeforeZero);
  l_CheckIfMouseDecorator(IsBeforeZero);
  l_SkinDecorator := l_GetSkinDecorator(IsBeforeZero);
  while (l_Decorator <> nil) or (l_SkinDecorator <> nil) do
  begin
   if (l_Decorator <> nil) then
   begin
    if l_SkinDecorator <> nil then
    begin
     if l_Decorator.PosZ > l_SkinDecorator.Z then
      l_UseDecorator(IsBeforeZero)
     else
      l_UseSkinDecorator(IsBeforeZero);
    end
    else
     l_UseDecorator(IsBeforeZero);
   end
   else
    l_UseSkinDecorator(IsBeforeZero);
  end;
 end;

begin
 gD2DE.Gfx_Clear(f_BGColor);
 l_DIdx := 0; // индекс игровых декораторов
 l_DSIdx := 0; // индекс скиновых декораторов

 l_MouseDecorator := Context.GetMouseDecorator;

 gD2DE.HideMouse := l_MouseDecorator <> nil;

 l_RenderDecorators(True);

 //f_HLine.Render(105, 29);
 f_GUI.Render;
 if (f_WaitSprites[f_WaitState] <> nil) and (f_WSWaitTimer <= 0) then
 begin
  l_Color := (Trunc(f_WSAlpha) shl 24) or $FFFFFF;
  f_WaitSprites[f_WaitState].SetColor(l_Color);
  f_WaitSprites[f_WaitState].Render(f_Txt.X+f_Txt.Width-33, f_Txt.Y+f_Txt.Height-33);
 end;

 l_RenderDecorators(False);

 // Это чтоб менюшки таки прорисовывались поверх декораторов
 l_TopCtrl := f_GUI.TopmostVisible;
 if (l_TopCtrl <> nil) and (l_TopCtrl is Td2dMenu) then
  l_TopCtrl.Render;

 if (l_MouseDecorator <> nil) and (not HasRunningChild) then // кастомный мышиный курсор и мы не в сцене сохранения/загрузки
  l_MouseDecorator.Render; // мышиный курсор всегда рисуется поверх всего

 {
 f_SysTextFont.Color := $FFFFFFFF;
 f_SysTextFont.Render(5, 550, Format('%d fps', [gD2DE.FPS]));
 }
end;

procedure Tf2MainScene.LinkClickHandler(const aSender: TObject; const aRect: Td2dRect; const aTarget: string);
var
 l_LinkText: string;
begin
 if aTarget <> '' then
 begin
  l_LinkText := f_Txt.GetHighlightedLinkText;
  if Context.ActionIsMenu(aTarget) then
  begin
   f_MenuActionCaller := l_LinkText;
   f_MenuActionCallerID := ciLink;
   PopupActionMenu(aTarget, aRect, Context.LinkMenuAlign);
  end
  else
  begin
   Context.StateResult := Format('b:%s',[aTarget]);
   Context.Variables['last_btn_caption'] := l_LinkText;
   f_Txt.ClearButtons;
   if (EnsureReal(Context.Variables[c_HideLinkEchoVar]) = 0.0) and
      (Context.ActionIsFinal(aTarget) or (EnsureReal(Context.Variables[c_HideLocalActionEchoVar]) = 0.0))  then
    ActionMessage(l_LinkText);
   NextTurn;
  end;
 end;
end;

procedure Tf2MainScene.LoadGame;
begin
 with Context do
 begin
  if StateParam[1] <> '' then
  begin
   try
    f_SaveLoadManager.LoadGame(Context, StrToInt(StateParam[1]), F2App.DebugMode);
   except
    on E: EFURQRunTimeError do
     OutError(E.Message);
   else
    raise;
   end;
   NextTurn;
  end
  else
   DoLoadSavedGame;
 end;
end;

procedure Tf2MainScene.LoadSavegameNames;
var
 I: Integer;
 l_Caption: string;
 l_DT : TDateTime;
begin
 f_SaveLoadManager.SetSaveBase(Context);
 for I := 0 to cMaxSlotsNum do
 begin
  f_SaveLoadManager.GetSaveInfo(I, l_Caption, l_DT);
  f_SaveLoadScene.Captions[I] := l_Caption;
  f_SaveLoadScene.DT[I] := l_DT;
 end;
end;

procedure Tf2MainScene.miaLog(aSender: TObject);
begin
 if Assigned(f_Txt.OnAddText) then
  StopLogging
 else
  StartLogging;
end;

procedure Tf2MainScene.miaReload(aSender: TObject);
begin
 DoDebugReload;
end;

procedure Tf2MainScene.PopupActionMenu(const aActionID: string; aRect: Td2dRect; aAlign: Td2dAlign);
begin
 f_ActionMenu.Root.ClearChildren;
 f_KeepMenuActions := False;
 BuildMenuFromAction(aActionID, f_ActionMenu.Root);
 if f_ActionMenu.Root.ChildrenCount > 0 then
 begin
  f_ActionMenu.Font := Context.MenuFont;
  f_ActionMenu.VisulalStyle := Context.MenuVisualStyle;
  f_ActionMenu.Popup(aRect, aAlign);
 end;
end;

procedure Tf2MainScene.RunTimeErrorHandler(const aErrorMessage: string; aLine: Integer);
var
 l_ErrMsg: string;
begin
 l_ErrMsg := Format('ОШИБКА: "%s" в %s', [aErrorMessage, f_Code.GetSourcePointStr(aLine-1)]);
 gD2DE.System_Log(l_ErrMsg);
 if F2App.DebugMode then
  f_Txt.AddText(Format(#13#10'%s'#13#10#13#10, [l_ErrMsg]),
                f_SysTextFont, $FFFF4800, ptLeftAligned);
end;

procedure Tf2MainScene.SaveGame;
var
 l_SlotNo: Integer;
begin
 with Context do
 begin
  f_SaveLoadManager.SetSaveBase(Context);
  if StateParam[2] = '' then  // если нам не предоставили описание...
  begin
   StateResult := f_SaveLoadManager.SaveName[0]; // это "старый" автосейв
   StateParam[2] := f_SaveLoadManager.GetAutoDesc(0);
   if EnsureReal(Context.Variables[c_HideSaveEchoVar]) = 0.0 then
    ActionMessage('Сохранение в '+Context.StateResult);
   NextTurn;
  end
  else
   if StateParam[3] <> '' then // если нам указали и описание, и слот - записываем туда без вопросов
   begin
    l_SlotNo := StrToIntDef(StateParam[3], 0);
    if (l_SlotNo < 0) or (l_SlotNo > cMaxSlotsNum) then
     l_SlotNo := 0;
    StateResult := f_SaveLoadManager.SaveName[l_SlotNo];
    NextTurn;
   end
   else
   begin
    LoadSavegameNames;
    f_SaveLoadScene.Mode := slmSave;
    f_SaveLoadScene.Context := Context;
    StartChild(f_SaveLoadScene);
   end;
 end;
end;

procedure Tf2MainScene.StartLogging(aDisplay: Boolean = True);
var
 l_Name: string;
begin
 f_LogFileName := GetLogFilename;
 f_mi_Log.Caption := SStopLog;
 if aDisplay then
 begin
  l_Name := ExtractFileName(f_LogFileName);
  f_Txt.ClearButtons;
  ActionMessage('Запись лога в файл '+l_Name);
  LoadButtonsAndActions;
  f_Txt.ScrollToBottom;
 end;
 f_Txt.OnAddText := LogAddTextHandler;
end;

procedure Tf2MainScene.StartOver(aNeedClearTextPane: Boolean = True);
begin
 FreeAndNil(f_Context);
 Context := Tf2Context.Create(f_Code, f_CurFilename, f_SysTextFont, f_MenuFont, f_SysMenu.VisulalStyle, f_Txt, F2App.Skin, f_BFrame, f_SavePath);
 Context.OnDecoratorAction := DecoratorActionHandler;
 //f_mi_OpenQuest.Enabled := True;
 f_mi_Restart.Enabled := True;
 f_mi_Load.Enabled := True;
 gD2DE.Music_Stop;
 gD2DE.Snd_FreeAll;
 gD2DE.Texture_ClearCache;
 ClearInventory;
 if aNeedClearTextPane then
  ClearTextPane;
end;

procedure Tf2MainScene.StopLogging;
begin
 f_Txt.OnAddText := nil;
 f_mi_Log.Caption := SStartLog;
 f_Txt.ClearButtons;
 ActionMessage('Запись лога остановлена');
 LoadButtonsAndActions;
 f_Txt.ScrollToBottom;
end;

procedure Tf2Clipboard.PutTextAsUnicode(const aStr: string);
var
 l_WStr: WideString;
begin
 l_WStr := aStr + #0;
 SetBuffer(CF_UNICODETEXT, PWideChar(l_WStr)^, Length(l_WStr)*2);
end;

end.

