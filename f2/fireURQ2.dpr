program fireURQ2;
{$R *.RES}
uses
  Windows,
  Classes,
  SysUtils,
  f2Application,
  f2Utils;

var
 App: Tf2Application;
 l_QuestToOpen: string;
 l_DebugMode: Boolean;
 l_LogToFile: Boolean;

const
 cEmbeddedTag = 'QSTE'; 

procedure ParseParams;
var
 I: Integer;
 l_Str: string;
 J: Integer;
begin
 l_QuestToOpen := '';
 l_DebugMode := False;
 l_LogToFile := False;
 for I := 1 to ParamCount do
 begin
  l_Str := ParamStr(I);
  if (l_Str[1]='-') and (Length(l_Str) >= 2) then
  begin
   for J := 2 to Length(l_Str) do
   case l_Str[J] of
    'l','L': l_LogToFile := True;
    'd','D': l_DebugMode := True;
   end;
  end
  else
   if l_QuestToOpen = '' then
    l_QuestToOpen := l_Str; 
 end;
end;

function CheckEmbedded: string;
var
 l_FS : TFileStream;
 l_Tag: array[1..4] of Char;
begin
 Result := '';
 l_FS := TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyWrite);
 try
  l_FS.Seek(-8, soFromEnd);
  l_FS.Read(l_Tag, 4);
  if l_Tag = cEmbeddedTag then
   Result := ParamStr(0);
 finally
  l_FS.Free;
 end;
end;

begin
 ParseParams;
 if l_QuestToOpen = '' then
 begin
  l_QuestToOpen := CheckEmbedded;
  if l_QuestToOpen = '' then
   l_QuestToOpen := OpenFileDlg(0, 'Выберите файл квеста', 'Файлы квестов'#0'*.qst;*.qs1;*.qs2;*.qsz'#0#0);
 end;

 if (l_QuestToOpen <> '') and not FileExists(l_QuestToOpen) then
 begin
  MessageBox(0, 'Файл квеста не найден', 'Файл не найден', MB_OK+MB_ICONERROR);
  l_QuestToOpen := '';
 end;

 if (l_QuestToOpen <> '') then
 begin
  App := Tf2Application.Create(l_QuestToOpen, l_LogToFile, l_DebugMode);
  if Assigned(App) then
  try
   App.Run;
  finally
   App.Free;
  end;
 end;
end.
