unit furqWinMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, JvSplit, JvMemo, JvExStdCtrls, JvExExtCtrls,
  JvExtComponent, ExtCtrls, XPMan, Menus, StdActns, ActnList, furqBase, furqContext,
  Buttons, JclStringLists, MMSystem;

type
  TMainForm = class(TForm)
    pnlInput: TPanel;
    edtInput: TEdit;
    Panel2: TPanel;
    JvxSplitter1: TJvxSplitter;
    memTextOut: TJvMemo;
    JvxSplitter2: TJvxSplitter;
    lbButtons: TListBox;
    XPManifest1: TXPManifest;
    dlgOpenQuest: TOpenDialog;
    ActionList1: TActionList;
    actOpenQuest: TAction;
    actFileExit: TFileExit;
    MainMenu: TMainMenu;
    Afq1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    pnlInventory: TPanel;
    lbInventory: TListBox;
    Panel1: TPanel;
    btnAction: TSpeedButton;
    SaveDlg: TSaveDialog;
    N3: TMenuItem;
    actLoadSaved: TAction;
    N4: TMenuItem;
    LoadDlg: TOpenDialog;
    btnEnter: TButton;
    PauseTimer: TTimer;
    G1: TMenuItem;
    miAbout: TMenuItem;
    actStartOver: TAction;
    N5: TMenuItem;
    procedure FormDestroy(Sender: TObject);
    procedure actOpenQuestExecute(Sender: TObject);
    procedure lbButtonsMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure memTextOutMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure lbButtonsClick(Sender: TObject);
    procedure lbInventoryClick(Sender: TObject);
    procedure btnActionClick(Sender: TObject);
    procedure btnActionMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure lbButtonsDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure actLoadSavedExecute(Sender: TObject);
    procedure actStartOverExecute(Sender: TObject);
    procedure btnEnterClick(Sender: TObject);
    procedure memTextOutKeyPress(Sender: TObject; var Key: Char);
    procedure miAboutClick(Sender: TObject);
    procedure PauseTimerTimer(Sender: TObject);
  private
    f_Code: TFURQCode;
    f_Interpreter: TFURQInterpreter;
    f_Context    : TFURQWinContext;
    f_CurFilename: string;
    f_InvItem: Integer;
    f_InvMenus: IJclStringList;
    f_MusicIsPlaying: Boolean;
    procedure ActionsHandler(aSender: TObject);
    procedure ClearMenus;
    procedure ClearScreen;
    procedure ContinuePlayingMusic;
    procedure DoCls;
    procedure DoMusic;
    procedure DoPause;
    procedure DoSound;
    procedure FlushText;
    function GetMenuOnItem(const aItem: string): TPopupMenu;
    procedure HandleInput;
    procedure HandleInputKey;
    procedure InputkeyMode;
    procedure InputMode;
    procedure LoadButtonsAndActions;
    procedure NextTurn;
    procedure NormalMode;
    procedure OpenQuest(aFilename: string);
    procedure PlayMusic(aFilename: string);
    procedure SaveGame;
    procedure StartOver;
    procedure StartTimer(aInterval: Integer);
    procedure StopMusic;
    procedure StopTimer;
  protected
    procedure MMMCINOTIFY_Message(var Message: TMessage); message MM_MCINOTIFY;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses
 furqTypes,
 furqAbout,
 furqLoader;

{$R *.dfm}

procedure TMainForm.ActionsHandler(aSender: TObject);
var
 l_MI: TMenuItem;
begin
 l_MI := TMenuItem(aSender);
 f_Context.StateResult := Format('m:%d,%d',[f_InvItem+1, l_MI.Tag]);
 f_Context.OutText(cCaretReturn);
 NextTurn;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
 FreeAndNil(f_Context);
 FreeAndNil(f_Code);
 FreeAndNil(f_Interpreter);
 ClearMenus;
 StopMusic;
end;

procedure TMainForm.actOpenQuestExecute(Sender: TObject);
begin
 if dlgOpenQuest.Execute then
  OpenQuest(dlgOpenQuest.Filename);
end;

procedure TMainForm.ClearMenus;
var
 I: Integer;
begin
 for I := 0 to f_InvMenus.LastIndex do
  f_InvMenus.Objects[I].Free;
 f_InvMenus.Clear; 
end;

procedure TMainForm.FlushText;
begin
 if f_Context.TextBuffer <> '' then
 begin
  memTextOut.Lines.Text := memTextOut.Lines.Text + f_Context.TextBuffer;
  SendMessage(memTextOut.Handle, EM_LINESCROLL, SB_LINEDOWN, MaxInt);
  f_Context.ClearTextBuffer;
 end;
end;

procedure TMainForm.lbButtonsMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
 l_ItemIdx: Integer;
 l_LB: TListBox;
begin
 l_LB := TListBox(Sender);
 l_ItemIdx := l_LB.ItemAtPos(Point(X, Y), True);
 if l_ItemIdx <> -1 then
  l_LB.ItemIndex := l_ItemIdx;
 if l_LB = lbInventory then
  lbButtons.ClearSelection
 else
  lbInventory.ClearSelection;
end;

procedure TMainForm.memTextOutMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
 lbButtons.ClearSelection;
 lbInventory.ClearSelection;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
 l_Bitmap: TBitmap;
begin
 f_Interpreter := TFURQInterpreter.Create;
 f_InvMenus := JclStringList;
 f_InvMenus.CaseSensitive := False;
 l_Bitmap := TBitmap.Create;
 try
  l_Bitmap.Width := 1;
  l_Bitmap.Height := 1;
  l_Bitmap.PixelFormat := pf4bit;
  l_Bitmap.Canvas.Pixels[0,0] := clBlack;//memTextOut.Color;
  memTextOut.Caret.Bitmap := l_Bitmap;
 finally
  l_Bitmap.Free;
 end;
 Randomize;
 if ParamCount > 0 then
  OpenQuest(ParamStr(1));
end;

function TMainForm.GetMenuOnItem(const aItem: string): TPopupMenu;
var
 l_AIdx: Integer;
 l_MIdx: Integer;
 l_AList: IJclStringList;
 I: Integer;
 l_MI: TMenuItem;
begin
 Result := nil;
 l_AIdx := f_Context.Code.ActionList.IndexOf(aItem);
 if l_AIdx < 0 then
  Exit;

 l_MIdx := f_InvMenus.IndexOf(aItem);

 if l_MIdx < 0 then
 begin
  Result := TPopupMenu.Create(Self);
  l_AList := f_Context.Code.ActionList.Lists[l_AIdx];
  for I := 0 to l_AList.LastIndex do
  begin
   l_MI := TMenuItem.Create(Result);
   l_MI.Caption := l_AList.Strings[I];
   l_MI.Tag := I+1;
   l_MI.OnClick := ActionsHandler;
   Result.Items.Add(l_MI);
  end;
  f_InvMenus.AddObject(aItem, Result);
 end
 else
  Result := TPopupMenu(f_InvMenus.Objects[l_MIdx]);
end;

procedure TMainForm.LoadButtonsAndActions;
var
 l_Idx: Integer;
 l_GTitle: string;
begin
 NormalMode;
 lbButtons.Items.Clear;
 lbButtons.Items.AddStrings(f_Context.Buttons);

 l_GTitle := EnsureString(f_Context.Variables['gametitle']);
 if l_GTitle <> '' then
  Caption := l_GTitle + ' - fireURQ'
 else
  Caption := 'fireURQ';
 btnAction.Caption := f_Context.Variables['invname'];
 l_Idx := f_Context.Code.ActionList.IndexOf('inv');
 btnAction.Enabled := l_Idx <> -1;

 lbInventory.Items.Clear;
 for l_Idx := 0 to f_Context.Inventory.LastIndex do
  lbInventory.Items.Add(f_Context.GetInventoryString(l_Idx));
end;

procedure TMainForm.NextTurn;
begin
 StopTimer;
 NormalMode;
 f_Interpreter.Execute(f_Context);
 FlushText;
 LoadButtonsAndActions;
 case f_Context.State of
 // csEnd     : LoadButtonsAndActions;
  csSave    : SaveGame;
  csInput   : HandleInput;
  csInputKey: HandleInputKey;
  csPause   : DoPause;
  csCls     : DoCls;
  csMIDI    : DoMusic;
  csSound   : DoSound;
 end;
end;

procedure TMainForm.StartOver;
begin
 FreeAndNil(f_Context);
 f_Context := TFURQWinContext.Create(f_Code, f_CurFilename);
 actLoadSaved.Enabled := True;
 actStartOver.Enabled := True;
 lbButtons.Items.Clear;
 StopMusic;
 NormalMode;
 memTextOut.Clear;
 lbButtons.Clear;
 lbInventory.Clear;
 NextTurn;
end;

procedure TMainForm.lbButtonsClick(Sender: TObject);
var
 l_ItemIdx: Integer;
begin
 l_ItemIdx := lbButtons.ItemAtPos(lbButtons.ScreenToClient(Mouse.CursorPos), True);
 if l_ItemIdx <> -1 then
 begin
  // на фантомные кнопки не реагируем вообще
  if TFURQButtonData(f_Context.Buttons.Objects[l_ItemIdx]).LabelIdx < 0 then
   Exit;
  f_Context.StateResult := 'b:' + IntToStr(l_ItemIdx);
  ClearScreen;
  NextTurn;
 end;
end;

procedure TMainForm.lbInventoryClick(Sender: TObject);
var
 l_Menu: TPopupMenu;
 l_Rect: TRect;
 l_Point: TPoint;
begin
f_InvItem := lbInventory.ItemAtPos(lbInventory.ScreenToClient(Mouse.CursorPos), True);
 if f_InvItem <> -1 then
 begin
  l_Menu := GetMenuOnItem(f_Context.Inventory[f_InvItem]);
  if l_Menu <> nil then
  begin
   l_Rect := lbInventory.ItemRect(f_InvItem);
   l_Point.X := l_Rect.Left;
   l_Point.Y := l_Rect.Bottom;
   l_Point := lbInventory.ClientToScreen(l_Point);
   l_Menu.Popup(l_Point.X, l_Point.Y);
  end;
 end;
end;

procedure TMainForm.btnActionClick(Sender: TObject);
var
 l_Menu: TPopupMenu;
 l_Point: TPoint;
begin
 l_Menu := GetMenuOnItem('inv');
 l_Point.X := 0;
 l_Point.Y := btnAction.Height;
 l_Point := btnAction.ClientToScreen(l_Point);
 f_InvItem := -1;
 l_Menu.Popup(l_Point.X, l_Point.Y);
end;

procedure TMainForm.btnActionMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
 lbInventory.ClearSelection;
end;

procedure TMainForm.lbButtonsDrawItem(Control: TWinControl; Index: Integer;
  Rect: TRect; State: TOwnerDrawState);
begin
 with lbButtons.Canvas do
 begin
  FillRect(Rect);
  if odDisabled in State then
   Font.Color := clGrayText
  else
   if TFURQButtonData(f_Context.Buttons.Objects[Index]).LabelIdx = -1 then
    Font.Color := clRed;
  if Index >= 0 then
   TextOut(Rect.Left + 2, Rect.Top+2, lbButtons.Items[Index]);
 end;
end;

procedure TMainForm.SaveGame;
begin
 if SaveDlg.Execute then
  f_Context.StateResult := SaveDlg.FileName;
 NextTurn;
end;

procedure TMainForm.actLoadSavedExecute(Sender: TObject);
begin
 if LoadDlg.Execute then
 begin
  f_Context.LoadFromFile(LoadDlg.Filename);
  ClearScreen;
  lbButtons.Clear;
  lbInventory.Clear;
  NextTurn;
 end;
end;

procedure TMainForm.actStartOverExecute(Sender: TObject);
begin
 if MessageDlg('Вы уверены, что хотите начать игру сначала?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  StartOver;
end;

procedure TMainForm.ClearScreen;
begin
 memTextOut.Clear;
end;

procedure TMainForm.HandleInput;
begin
 InputMode;
end;

procedure TMainForm.InputMode;
begin
 lbButtons.Items.Clear;
 lbButtons.Enabled := False;
 lbInventory.Enabled := False;
 pnlInput.Visible := True;
 edtInput.Text := '';
 edtInput.SetFocus;
end;

procedure TMainForm.NormalMode;
begin
 lbButtons.Enabled := True;
 lbInventory.Enabled := True;
 pnlInput.Visible := False;
end;

procedure TMainForm.btnEnterClick(Sender: TObject);
begin
 f_Context.StateResult := edtInput.Text;
 NormalMode;
 NextTurn;
end;

procedure TMainForm.ContinuePlayingMusic;
begin
 f_MusicIsPlaying := mciSendString('play urqmusic from 0 notify', nil, 0, Handle) = 0;
end;

procedure TMainForm.DoCls;
 procedure _ClearButtons;
 begin
  f_Context.ClearButtons;
  lbButtons.Clear;
 end;

 procedure _ClearScreen;
 begin
  memTextOut.Clear;
 end;

begin
 with f_Context do
 begin
  if StateParam = 'B' then
   _ClearButtons
  else
  if StateParam = 'T' then
   _ClearScreen
  else
  begin
   _ClearButtons;
   _ClearScreen;
  end;
 end;
 Application.ProcessMessages;
 NextTurn;
end;

procedure TMainForm.DoMusic;
begin
 if f_Context.StateParam = '' then
  StopMusic
 else
  PlayMusic(f_Context.StateParam);
 NextTurn; 
end;

procedure TMainForm.DoPause;
var
 l_Interval: Integer;
begin
 l_Interval := Round(StrToFloatDef(f_Context.StateParam, 1000));
 LoadButtonsAndActions;
 StartTimer(l_Interval);
end;

procedure TMainForm.DoSound;
begin
 PlaySound(PChar(f_Context.StateParam), 0, SND_FILENAME or SND_ASYNC or SND_NODEFAULT);
 NextTurn;
end;

procedure TMainForm.HandleInputKey;
begin
 InputKeyMode;
end;

procedure TMainForm.InputkeyMode;
begin
 lbButtons.Enabled := False;
 lbInventory.Enabled := False;
 memTextOut.SetFocus;
end;

procedure TMainForm.memTextOutKeyPress(Sender: TObject; var Key: Char);
begin
 if (f_Context <> nil) and (f_Context.State = csInputKey) then
 begin
  f_Context.StateResult := Key;
  NextTurn;
 end;
end;

procedure TMainForm.miAboutClick(Sender: TObject);
begin
 with TAboutBox.Create(nil) do
 begin
  ShowModal;
  Free;
 end;
end;

procedure TMainForm.MMMCINOTIFY_Message(var Message: TMessage);
begin
 inherited;
 if Message.wParam = MCI_NOTIFY_SUCCESSFUL then
  ContinuePlayingMusic;
end;

procedure TMainForm.OpenQuest(aFilename: string);
var
 l_Ext    : string;
 l_Source : string;
 l_FS     : TFileStream;
begin
 if FileExists(aFilename) then
 begin
  if f_Code <> nil then
   FreeAndNil(f_Code);
  f_Code := TFURQCode.Create;
  l_Ext := AnsiLowerCase(ExtractFileExt(aFilename));
  l_FS := TFileStream.Create(aFilename, fmOpenRead);
  try
   if l_Ext = '.qs2' then
    l_Source := FURQLoadQS2(l_FS)
   else
    if l_Ext = '.qs1' then
     l_Source := FURQLoadQS1(l_FS)
    else
     l_Source := FURQLoadQST(l_FS);
  finally
   FreeAndNil(l_FS);
  end;
  f_Code.Load(l_Source);
  aFilename := ExpandFileName(aFileName);
  SetCurrentDir(ExtractFilePath(aFileName));
  f_CurFilename := ExtractFileName(aFileName);
  ClearMenus;
  StartOver;
 end;
end;

procedure TMainForm.StartTimer(aInterval: Integer);
begin
 PauseTimer.Interval := aInterval;
 PauseTimer.Enabled := True;
end;

procedure TMainForm.PauseTimerTimer(Sender: TObject);
begin
 PauseTimer.Enabled := False;
 NextTurn;
end;

procedure TMainForm.PlayMusic(aFilename: string);
var
 l_Str: string;
begin
 if f_MusicIsPlaying then
  StopMusic;
 l_Str := Format('open sequencer!%s alias urqmusic', [aFileName]);
 if mciSendString(PChar(l_Str), nil, 0, 0) = 0 then
  ContinuePlayingMusic;
end;

procedure TMainForm.StopMusic;
begin
 if f_MusicIsPlaying then
  mciSendString('close urqmusic', nil, 0, 0);
end;

procedure TMainForm.StopTimer;
begin
 PauseTimer.Enabled := False;
end;

end.
