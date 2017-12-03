unit furqContext;

interface

uses
 Classes,
 Math,
 MD5,
 JclStringLists,
 d2dClasses,
 d2dUtils,
 furqTypes,
 furqFiler
 ;

type
 TFURQCodeLoadProc = function (const aFilename: string): string of object;
 IFURQCodePoint = interface
  ['{CE84C50E-929A-4E0A-B20F-4BCFB5F82086}']
  function pm_GetLineNo: Integer;
  function pm_GetSrcFile: Integer;
  property LineNo: Integer read pm_GetLineNo;
  property SrcFile: Integer read pm_GetSrcFile;
 end;

 TFURQCodePoint = class(TInterfacedObject, IFURQCodePoint)
 private
  f_File   : Integer;
  f_LineNo : Integer;
  function pm_GetLineNo: Integer;
  function pm_GetSrcFile: Integer;
 public
  constructor Create(aFile, aLineNo: Integer);
 end;
 // код, исходник квеста
 TFURQCode = class
 private
  f_ActionList: IJclStringList;
  f_Labels : IJclStringList;
  f_Source : IJclStringList;
  f_Files  : IJclStringList;
  f_SourceHash: TMD5Digest;
  procedure CalcSourceHash;
  function pm_GetLocCountVarName(Index: Integer): string;
 public
  constructor Create;
  destructor Destroy; override;
  procedure Load(const aFilename: string; aLoadProc: TFURQCodeLoadProc);
  function GetSourcePointStr(aLineNo: Integer): string;
  property ActionList: IJclStringList read f_ActionList;
  property Labels: IJclStringList read f_Labels;
  property LocCountVarName[Index: Integer]: string read pm_GetLocCountVarName;
  property Source: IJclStringList read f_Source;
  property SourceHash: TMD5Digest read f_SourceHash;
 end;

type
 // Одиночный оператор, на них распарсивается строка исходного кода
 TFURQOperator = class
 private
  f_Next: TFURQOperator;
  f_Source: string;
 protected
  f_OperatorType: Byte;
 public
  constructor Create(const aSource: string);
  destructor Destroy; override;
  procedure Load(const aFiler: TFURQFiler); virtual;
  procedure Save(const aFiler: TFURQFiler); virtual;
  property Next: TFURQOperator read f_Next write f_Next;
  property Source: string read f_Source;
 end;

type
 // точка выполнения (для реализации стека)
 TFURQExecutionPoint = class
 private
  f_CurOp: TFURQOperator;
  f_Line: Integer;
  f_Operators: TFURQOperator;
  f_Prev: TFURQExecutionPoint;
 public
  constructor Create(aPrev: TFURQExecutionPoint);
  destructor Destroy; override;
  procedure ClearOperators;
  procedure DropPrev;
  procedure Load(const aFiler: TFURQFiler);
  procedure Save(const aFiler: TFURQFiler);
  property CurOp: TFURQOperator read f_CurOp write f_CurOp;
  property Line: Integer read f_Line write f_Line;
  property Operators: TFURQOperator read f_Operators write f_Operators;
  property Prev: TFURQExecutionPoint read f_Prev;
 end;

type
 // данные кнопки
 IFURQActionData = interface
 ['{6C665DAF-91A6-4B76-8E17-3A990580B3CD}']
  function pm_GetModifier: TFURQActionModifier;
  function pm_GetLabelIdx: Integer;
  function pm_GetParams: IJclStringList;
  procedure Save(const aFiler: Td2dFiler);
  property Modifier: TFURQActionModifier read pm_GetModifier;
  property LabelIdx: Integer read pm_GetLabelIdx;
  property Params: IJclStringList read pm_GetParams;
 end;


 TFURQActionData = class(TInterfacedObject, IFURQActionData)
 private
  f_LabelIdx : Integer;
  f_Params   : IJclStringList;
  f_Modifier : TFURQActionModifier;
  function pm_GetModifier: TFURQActionModifier;
  function pm_GetLabelIdx: Integer;
  function pm_GetParams: IJclStringList;
  procedure Save(const aFiler: Td2dFiler);
 public
  constructor Create(aIdx: Integer; aParams: IJclStringList; aModifier: TFURQActionModifier = amNone);
  constructor Load(const aFiler: Td2dFiler);
  destructor Destroy; override;
 end;

const
 cMaxStateParams = 3; 

type
 // Контекст. Хранит состояние квеста и все его переменные.
 TFURQContext = class(Td2dProtoObject)
 private
  f_Actions    : IJclStringList;
  f_MenuActions: IJclStringList;
  f_Buttons: IJclStringList;
  f_Code: TFURQCode;
  f_Inventory: IJclStringList;
  f_NumFormatString: string;
  f_Stack: TFURQExecutionPoint;
  f_BackupStack : TFURQExecutionPoint;
  f_State: TFURQContextState;
  f_BackupState: TFURQContextState;
  f_IsMenuBuild: Boolean;
  f_Menu: IJclStringList;
  f_StateParam: array[1..cMaxStateParams] of string;
  f_StateResult: string;
  f_Variables: IJclStringList;
  function ButtonIdxByID(anActionID: string): Integer;
  function pm_GetStateParam(aIndex: Integer): string;
  function pm_GetVariables(aName: string): Variant;
  procedure pm_SetStateParam(aIndex: Integer; const Value: string);
  procedure pm_SetVariables(aName: string; const Value: Variant);
  procedure SaveButtons(const aFiler: TFURQFiler);
  procedure LoadButtons(const aFiler: TFURQFiler);
  procedure SaveActions(const aFiler: TFURQFiler);
  procedure LoadActions(const aFiler: TFURQFiler);
 protected
  procedure Cleanup; override;
  function DoActionFinal(const anActionData: IFURQActionData): Boolean; virtual;
  procedure DoLoadData(aFiler: TFURQFiler); virtual;
  procedure DoSaveData(aFiler: TFURQFiler); virtual;
  function GetVirtualVariable(const aName: string): Variant; virtual;
  procedure InitSysVariables; virtual;
  function IsSystemOrVirtualVariable(aVarName: string): Boolean; virtual;
  function pm_GetActionsData(anID: string): IFURQActionData; virtual;
  procedure SetSysVariables(aName: string; const Value: Variant); virtual;
  function SetVirtualVariables(const aName: string; const aValue: Variant): Boolean; virtual;
 public
  constructor Create(aCode: TFURQCode);
  function ActionIsFinal(const aActionID: string): Boolean;
  function ActionIsMenu(const aActionID: string): Boolean;
  function AddAction(const aData: IFURQActionData; const aActionList: IJclStringList = nil): string;
  procedure AddButton(const aLabel: string; const aParams: IJclStringList; const aText: string; aModifier:
      TFURQActionModifier);
  procedure AddToInventory(aName: string; anAmount: Double);
  function DoAction(const anActionData: IFURQActionData): Boolean; 
  procedure ClearButtons; virtual;
  procedure ClearText; virtual;
  procedure ClearInventory;
  procedure ClearStack;
  procedure ClearVariables;
  procedure ClearStateParams;
  function DeleteVariable(aVarName: string): Boolean;
  procedure ExecuteProc(aLabelIdx: Integer);
  procedure ExecuteProcAtLine(aLineNo: Integer);
  procedure ForgetProcs;
  function FormatNumber(aNumber: Extended): string;
  function GetInventoryString(aIndex: Integer): string;
  procedure IncLocationCount(const aLabelIdx: Integer);
  function IsVariableExists(const aVarName: string): Boolean;
  procedure JumpToLabelIdx(aIndex: Integer);
  procedure JumpToLine(aLineNo: Integer);
  procedure LoadFromFile(aFilename: string; aIgnoreHash: Boolean = False);
  procedure LoadFromStream(aStream: TStream; aIgnoreHash: Boolean = False);
  procedure MusicPlay(const aFilename: string; aFadeTime: Integer); virtual;
  procedure MusicStop(aFadeTime: Integer); virtual;
  procedure OutText(const aStr: string); virtual; abstract;
  procedure Restart; virtual;
  procedure ReturnFromProc;
  procedure SaveToFile(const aFilename, aLocation: string; const aDescription: string = '');
  procedure SaveToStream(aLocation: string; aStream: TStream; const aDescription: string = '');
  procedure SoundPlay(const aFilename: string; aVolume: Integer; aLooped: Boolean); virtual;
  procedure SoundStop(const aFilename: string); virtual;
  procedure StartMenuBuild(aKeepMenuActions: Boolean);
  procedure EndMenuBuild;
  function SystemProc(aProcName: string; aParams: IJclStringList): Boolean; virtual;
  property ActionsData[anID: string]: IFURQActionData read pm_GetActionsData;
  property Buttons: IJclStringList read f_Buttons;
  property Menu: IJclStringList read f_Menu;
  property Code: TFURQCode read f_Code;
  property Inventory: IJclStringList read f_Inventory;
  property IsMenuBuild: Boolean read f_IsMenuBuild;
  property Stack: TFURQExecutionPoint read f_Stack;
  property State: TFURQContextState read f_State write f_State;
  property StateParam[aIndex: Integer]: string read pm_GetStateParam write pm_SetStateParam;
  property StateResult: string read f_StateResult write f_StateResult;
  property Variables[aName: string]: Variant read pm_GetVariables write pm_SetVariables;
 end;

 TFURQCondition = class(TFURQOperator)
 private
  f_ThenOp: TFURQOperator;
  f_ElseOp: TFURQOperator;
 public
  constructor Create(const aCondition: string; aThenOp, aElseOp: TFURQOperator);
  destructor Destroy; override;
  procedure Load(const aFiler: TFURQFiler); override;
  procedure Save(const aFiler: TFURQFiler); override;
  property ThenOp: TFURQOperator read f_ThenOp;
  property ElseOp: TFURQOperator read f_ElseOp;
 end;

 TFURQWinContext = class(TFURQContext)
 private
  f_Filename: string;
  f_TextBuffer: string;
 protected
  procedure InitSysVariables; override;
 public
  constructor Create(aCode: TFURQCode; aFilename: string);
  procedure ClearTextBuffer;
  procedure OutText(const aStr: string);
  procedure Restart; override;
  property TextBuffer: string read f_TextBuffer;
 end;

const
 sDefaultActName = 'Осмотреть';
 sDefaultActTag  = '_defact_';
 sVarSaveSuccess = 'save_success';

function FURQReadSaveInfo(const aFileName: string; out theDescription: string; out theDateTime: TDateTime): Boolean;

function ActionDataHash(const aData: IFURQActionData): string;

implementation
uses
 Windows,
 mmSystem,
 SysUtils,
 StrUtils,
 Variants,

 furqUtils
 ;

const

// START resource string wizard section
 c_sUsePrefix = 'use_';
 c_sInclude = '%include ';
 c_sEnd = 'end';
 c_sCountPrefix = 'count_';
 c_sIdispPrefix = 'idisp_';
 c_sInvPrefix = 'inv_';
 c_sFp_prec = 'fp_prec';
 c_s_result = '_result';
 // math
 c_s_sin    = '_sin';
 c_s_cos    = '_cos';
 c_s_tan    = '_tan';
 c_s_arcsin = '_arcsin';
 c_s_arccos = '_arccos';
 c_s_arctan = '_arctan';
 c_s_sqrt   = '_sqrt';
 c_s_power  = '_power';

 c_s_int = '_int';
 c_s_tohex = '_tohex';
 c_s_trim = '_trim';
 c_s_scopy = '_scopy';
 c_sInvname = 'invname';
 c_sGametitle = 'gametitle';
 c_sTimeVar = 'time';

// END resource string wizard section

 sCorruptedSaveFile  = 'Файл сохранения испорчен';
 sBadVersionSaveFile = 'Файл сохранения от другой версии игры';

 otOperator  = 1;
 otCondition = 2;

function ActionDataHash(const aData: IFURQActionData): string;
var
 I: Integer;
 l_Source: string;
 l_MD5   : TMD5Digest;
begin
 Result := '';
 if aData <> nil then
 begin
  case aData.Modifier of
   amNone     : l_Source := '0-';
   amNonFinal : l_Source := '1-';
   amMenu     : l_Source := '2-';
  end;
  l_Source := l_Source + IntToStr(aData.LabelIdx);
  if aData.Params <> nil then
  begin
   for I := 0 to aData.Params.LastIndex do
    l_Source := l_Source + '-' + aData.Params[I];
  end;
  l_MD5 := MD5String(l_Source);
  Result := MD5DigestToStr(l_MD5);
 end;
end;

function FURQReadSaveInfo(const aFileName: string; out theDescription: string; out theDateTime: TDateTime): Boolean;
var
 l_FS : TFileStream;
 l_R  : TFURQFiler;
 l_Signature : string;
begin
 theDescription := '';
 theDateTime := 0;
 Result := False;
 if FileExists(aFileName) then
 begin
  l_FS := TFileStream.Create(aFilename, fmOpenRead);
  try
   l_R := TFURQFiler.Create(l_FS);
   try
    l_Signature := l_R.ReadString;
    if l_Signature = cSaveFileSignature then
    begin
     theDescription := l_R.ReadString; // описание сохранёнки
     theDateTime    := l_R.ReadDouble; // дата и время
     Result := True;
    end;
   finally
    l_R.Free;
   end;
  finally
   l_FS.Free;
  end;
 end;
end;

procedure SaveOperators(const aFirstOp: TFURQOperator; const aFiler: TFURQFiler); //записывает ЦЕПОЧКУ операторов (с учётом Next)
var
 l_Op: TFURQOperator;
begin
 if aFirstOp <> nil then
 begin
  aFiler.WriteBoolean(True);
  l_Op := aFirstOp;
  while l_Op <> nil do
  begin
   l_Op.Save(aFiler);
   l_Op := l_Op.Next;
   aFiler.WriteBoolean(l_Op <> nil);
  end;
 end
 else
  aFiler.WriteBoolean(False);
end;

function LoadOperators(const aFiler: TFURQFiler): TFURQOperator; // фабрика, загружает ЦЕПОЧКУ операторов
 function LoadOne: TFURQOperator;
 var
  l_Type: Byte;
 begin
  l_Type := aFiler.ReadByte;
  case l_Type of
   otOperator  : Result := TFURQOperator.Create('');
   otCondition : Result := TFURQCondition.Create('', nil, nil);
  else
   raise EFURQRunTimeError.Create(sCorruptedSaveFile);
  end;
  Result.Load(aFiler);
 end;

var
 l_Op: TFURQOperator;
begin
 if aFiler.ReadBoolean then
 begin
  Result := LoadOne;
  l_Op := Result;
  while aFiler.ReadBoolean do
  begin
   l_Op.Next := LoadOne;
   l_Op := l_Op.Next;
  end;
 end
 else
  Result := nil;
end;

constructor TFURQCode.Create;
begin
 inherited;
 f_Source := JclStringList;
 f_Files  := JclStringList;
 f_Files.CaseSensitive := False;
 f_Labels := JclStringList;
 //f_Labels.Sorted := True;
 f_Labels.Duplicates := dupIgnore;
 f_Labels.CaseSensitive := False;
 f_ActionList := JclStringList;
 f_ActionList.CaseSensitive := False;
end;

destructor TFURQCode.Destroy;
begin
 f_Source := nil;
 f_Files  := nil;
 f_Labels := nil;
 f_ActionList := nil;
 inherited;
end;

procedure TFURQCode.CalcSourceHash;
var
 I: Integer;
 l_MD5C : TMD5Context;
 l_Str: string;
begin
 MD5Init(l_MD5C);
 for I := 0 to f_Source.LastIndex do
 begin
  l_Str := f_Source[I];
  if l_Str <> '' then
   MD5Update(l_MD5C, MD5.PByteArray(@l_Str[1]), Length(l_Str));
 end;
 MD5Final(f_SourceHash, l_MD5C);
end;

function TFURQCode.GetSourcePointStr(aLineNo: Integer): string;
var
 l_CP: IFURQCodePoint;
begin
 l_CP := f_Source.Interfaces[aLineNo] as IFURQCodePoint;
 if l_CP <> nil then
  Result := Format('%s строка %d', [f_Files[l_CP.SrcFile], l_CP.LineNo])
 else
  Result := ''; 
end;

procedure TFURQCode.Load(const aFilename: string; aLoadProc: TFURQCodeLoadProc);
var
 l_BasePath: string;

 procedure DeleteComments(const aList: IJclStringList);
 var
  I     : Integer;
  l_OpenPos, l_ClosePos: Cardinal;
  l_Pos, l_Pos2 : Cardinal;
  l_Str: string;
  l_IsInComment : Boolean;
 begin
  // удаляем комментарии вида /* ... */
  l_IsInComment := False;
  for I := 0 to aList.Count - 1 do
  begin
   l_Str := aList[I];
   if l_IsInComment then
   begin
    l_Pos := Pos('*/', l_Str);
    if l_Pos > 0 then
    begin
     Delete(l_Str, 1, l_Pos+1);
     l_Str := '_' + l_Str;
     l_IsInComment := False;
    end
    else
    begin
     aList[I] := '_';
     Continue;
    end;
   end;

   while true do
   begin
    l_Pos := Pos('/*', l_Str);
    if l_Pos > 0 then
    begin
     l_Pos2 := PosEx('*/', l_Str, l_Pos+2);
     if l_Pos2 > 0 then
     begin
      Delete(l_Str, l_Pos, l_Pos2 - l_Pos + 2);
      Continue;
     end
     else
     begin
      Delete(l_Str, l_Pos, MaxInt);
      l_IsInComment := True;
      Break;
     end;
    end
    else
     Break;
   end;
   aList[I] := l_Str;
  end;

  // отрезаем комментарии, начинающиеся с ";"
  for I := 0 to Pred(aList.Count) do
  begin
   l_Pos := Pos(';', aList[I]);
   if l_Pos > 0 then
    aList[I] := Copy(aList[I], 1, l_Pos-1);
  end;
 end;

 procedure TrimLines;
 var
  I, J : Integer;
  l_Str: string;
  l_Len: Integer;
 begin
  for I := 0 to Pred(f_Source.Count) do
  begin
   l_Str := AnsiReplaceStr(f_Source[I], #9, '    ');
   l_Len := Length(l_Str);
   for J := 1 to l_Len do
    if l_Str[J] < #32 then l_Str[J] := #32;
   f_Source[I] := TrimLeft(l_Str);
  end;
 end;

 procedure ParseLocations; // ищем локации (метки)
 var
  I: Integer;
  l_Str: string;
  l_Idx: Integer;
 begin
  for I := 0 to Pred(f_Source.Count) do
  begin
   l_Str := f_Source[I];
   if AnsiStartsStr(':', l_Str) then
   begin
    Delete(l_Str, 1, 1);
    l_Str := Trim(l_Str);
    if f_Labels.IndexOf(l_Str) = -1 then  // чтобы работала только первая метка из одинаковых
    begin
     l_Idx := f_Labels.Add(l_Str);
     f_Labels.Variants[l_Idx] := I;
    end;
   end;
  end;
 end;

 procedure FillActions; // ищем доступные действия
 var
  I: Integer;
  l_Name, l_ActionName: string;
  l_Pos: Integer;
  l_Label: string;
  l_Idx: Integer;
  l_ActIdx: Integer;
 begin
  for I := 0 to f_Labels.LastIndex do
  begin
   l_Label := f_Labels[I];
   if AnsiStartsText(c_sUsePrefix, l_Label) then
   begin
    l_Name := Copy(l_Label, 5, MaxInt);
    l_ActIdx := f_ActionList.Add(l_Name);
    f_ActionList.Variants[l_ActIdx] := l_Label;
   end;
  end;
 end;

 procedure IndexActionLabels;
 var
  I : Integer;
 begin
  for I := 0 to f_ActionList.LastIndex do
   f_ActionList.Variants[I] := f_Labels.IndexOf(f_ActionList.Variants[I]);
 end;

 procedure LoadSingleFile(const aOneFilename: string);
 var
  I: Integer;
  l_Buf: IJclStringList;
  l_Includes: IJclStringList;
  l_CodePoint: IFURQCodePoint;
  l_File: string;
  l_FileID: string;
  l_Idx: Integer;
  l_MainIdx: Integer;
  l_Str: string;
  l_Path: string;
 begin
  l_FileID := ExtractRelativePath(l_BasePath, aOneFilename);
  if f_Files.IndexOf(l_FileID) < 0 then
  begin
   l_Buf := JclStringList;
   l_Includes := JclStringList;
   l_Path := ExtractFilePath(aOneFilename);
   l_Buf.Text := aLoadProc(aOneFileName);
   DeleteComments(l_Buf);
   l_Idx := f_Files.Add(l_FileID);
   for I := 0 to Pred(l_Buf.Count) do
   begin
    l_Str := Trim(l_Buf[I]);
    if AnsiStartsText(c_sInclude, l_Str) then
    begin
     l_File := Trim(Copy(l_Str, 10, MaxInt));
     l_Includes.Add(l_File);
     l_Buf[I] := '';
    end;
   end;
   for I := 0 to Pred(l_Buf.Count) do
   begin
    l_MainIdx := f_Source.Add(l_Buf[I]);
    l_CodePoint := TFURQCodePoint.Create(l_Idx, I+1);
    f_Source.Interfaces[l_MainIdx] := l_CodePoint;
   end;
   l_MainIdx := f_Source.Add(c_sEnd);
   l_CodePoint := TFURQCodePoint.Create(l_Idx, l_Buf.Count+1);
   f_Source.Interfaces[l_MainIdx] := l_CodePoint;
   for I := 0 to Pred(l_Includes.Count) do
    LoadSingleFile(l_Path + l_Includes[I]);
  end;
 end;

begin
 f_Source.Clear;
 f_Labels.Clear;
 f_Files.Clear;
 f_Labels.Sorted := False; // чтобы не сортировать принудительно действия инвентаря
 f_ActionList.Clear;
 l_BasePath := ExtractFilePath(aFilename);
 LoadSingleFile(aFilename);
 TrimLines;
 ParseLocations;
 FillActions;
 f_Labels.Sorted := True;
 IndexActionLabels;
 CalcSourceHash;
end;

function TFURQCode.pm_GetLocCountVarName(Index: Integer): string;
begin
 Result := c_sCountPrefix+Labels[Index];
end;

constructor TFURQOperator.Create(const aSource: string);
begin
 inherited Create;
 f_OperatorType := otOperator;
 f_Source := aSource;
end;

destructor TFURQOperator.Destroy;
begin
 FreeAndNil(f_Next);
 inherited;
end;

procedure TFURQOperator.Load(const aFiler: TFURQFiler);
begin
 // f_OperatorType не читаем, он читается фабрикой
 f_Source := aFiler.ReadString;
end;

procedure TFURQOperator.Save(const aFiler: TFURQFiler);
begin
 aFiler.WriteByte(f_OperatorType);
 aFiler.WriteString(f_Source);
end;

constructor TFURQExecutionPoint.Create(aPrev: TFURQExecutionPoint);
begin
 inherited Create;
 f_Prev := aPrev;
end;

destructor TFURQExecutionPoint.Destroy;
begin
 ClearOperators;
 inherited;
end;

procedure TFURQExecutionPoint.ClearOperators;
begin
 FreeAndNil(f_Operators);
 f_CurOp := nil;
end;

procedure TFURQExecutionPoint.DropPrev;
begin
 if f_Prev <> nil then
 begin
  f_Prev.DropPrev;
  FreeAndNil(f_Prev);
 end;
end;

procedure TFURQExecutionPoint.Load(const aFiler: TFURQFiler);
begin
 DropPrev;
 FreeAndNil(f_Operators);
 f_Line := aFiler.ReadInteger;
 f_CurOp := LoadOperators(aFiler);
 f_Operators := f_CurOp; // строка полностью никому не нужна
 if aFiler.ReadBoolean then // есть стек
 begin
  f_Prev := TFURQExecutionPoint.Create(nil);
  f_Prev.Load(aFiler);
 end;
end;

procedure TFURQExecutionPoint.Save(const aFiler: TFURQFiler);
var
 l_HasPrev: Boolean;
begin
 aFiler.WriteInteger(f_Line);
 SaveOperators(CurOp, aFiler);
 l_HasPrev := f_Prev <> nil;
 aFiler.WriteBoolean(l_HasPrev);
 if l_HasPrev then
  f_Prev.Save(aFiler);
end;

constructor TFURQContext.Create(aCode: TFURQCode);
begin
 inherited Create;
 f_Code := aCode;
 f_Actions := JclStringList;
 f_Actions.Sorted := True;
 f_Actions.Duplicates := dupIgnore;
 f_MenuActions := JclStringList;
 f_MenuActions.Sorted := True;
 f_MenuActions.Duplicates := DUPIGNORE;
 f_Menu := JclStringList;
 f_Buttons := JclStringList;
 f_Variables := JclStringList;
 f_Variables.Sorted := True;
 f_Variables.CaseSensitive := False;
 f_Inventory := JclStringList;
 f_Inventory.CaseSensitive := False;
 Restart;
end;

procedure TFURQContext.Cleanup;
begin
 ClearStack;
 FreeAndNil(f_Stack);
 inherited;
end;

function TFURQContext.ActionIsFinal(const aActionID: string): Boolean;
var
 l_Data: IFURQActionData;
begin
 Result := True;
 l_Data := ActionsData[aActionID];
 if l_Data <> nil then
  Result := l_Data.Modifier = amNone;
end;

function TFURQContext.ActionIsMenu(const aActionID: string): Boolean;
var
 l_Data: IFURQActionData;
begin
 Result := False;
 l_Data := ActionsData[aActionID];
 if l_Data <> nil then
  Result := l_Data.Modifier = amMenu;
end;

function TFURQContext.AddAction(const aData: IFURQActionData; const aActionList: IJclStringList = nil): string;
var
 l_Idx: Integer;
 l_ID : string;
 l_CurActions: IJclStringList;
begin
 l_ID := ActionDataHash(aData);
 Result := l_ID;
 if IsMenuBuild then
  l_CurActions := f_MenuActions
 else
  if aActionList = nil then
   l_CurActions := f_Actions
  else
   l_CurActions := aActionList;
 l_Idx := l_CurActions.IndexOf(l_ID);
 if l_Idx < 0 then
 begin
  l_Idx := l_CurActions.Add(l_ID);
  l_CurActions.Interfaces[l_Idx] := aData;
 end;
end;

procedure TFURQContext.AddButton(const aLabel: string; const aParams: IJclStringList; const aText: string; aModifier: TFURQActionModifier);
var
 l_LIdx, l_Idx: Integer;
 l_BData: IFURQActionData;
 l_NewAID: string;
 l_CurButtons: IJclStringList;
begin
 l_LIdx := f_Code.Labels.IndexOf(aLabel);
 if (l_LIdx = -1) then
 begin
  if (not IsMenuBuild) and (EnsureReal(Variables[cVarHidePhantoms]) <> 0) then
   Exit;
  l_NewAID := '';
 end
 else
 begin
  l_BData := TFURQActionData.Create(l_LIdx, aParams, aModifier);
  l_NewAID := AddAction(l_BData);
 end;
 if IsMenuBuild then
  l_CurButtons := f_Menu
 else
  l_CurButtons := f_Buttons;
 l_Idx := l_CurButtons.Add(aText);
 l_CurButtons.Variants[l_Idx] := l_NewAID;
end;

procedure TFURQContext.AddToInventory(aName: string; anAmount: Double);
var
 l_Idx: Integer;
begin
 l_Idx := f_Inventory.IndexOf(aName);
 if l_Idx < 0 then
 begin
  if anAmount <= 0 then
   Exit;
  l_Idx := f_Inventory.Add(aName);
 end;
 f_Inventory.Variants[l_Idx] := f_Inventory.Variants[l_Idx] + anAmount;
 if f_Inventory.Variants[l_Idx] <= 0.0 then
  f_Inventory.Delete(l_Idx);
end;

function TFURQContext.ButtonIdxByID(anActionID: string): Integer;
var
 I: Integer;
begin
 Result := -1;
 for I := 0 to f_Buttons.LastIndex do
  if f_Buttons.Variants[I] = anActionID then
  begin
   Result := I;
   Break;
  end;
end;

function TFURQContext.DoAction(const anActionData: IFURQActionData): Boolean;
begin
 Result := False;
 if anActionData <> nil then
 begin
  if anActionData.LabelIdx > -1 then
  begin
   if anActionData.Modifier = amNone then
    Result := DoActionFinal(anActionData)
   else
   begin
    if State = csPause then
     ExecuteProc(anActionData.LabelIdx)
    else
     JumpToLabelIdx(anActionData.LabelIdx);
    Result := True; 
   end;
  end;
 end;
end;

procedure TFURQContext.ClearButtons;
begin
 f_Buttons.Clear;
end;

procedure TFURQContext.ClearText;
begin
 // does nothing in base class
end;

procedure TFURQContext.ClearInventory;
begin
 f_Inventory.Clear;
end;

procedure TFURQContext.ClearStack;
var
 l_TempEP: TFURQExecutionPoint;
begin
 if f_Stack = nil then
  f_Stack := TFURQExecutionPoint.Create(nil)
 else
 begin
  f_Stack.DropPrev;
  f_Stack.ClearOperators;
 end;
end;

procedure TFURQContext.ClearStateParams;
var
 I: Integer;
begin
 for I := 1 to cMaxStateParams do
  f_StateParam[I] := '';
end;

procedure TFURQContext.ClearVariables;
begin
 f_Variables.Clear;
 InitSysVariables;
end;

function TFURQContext.DeleteVariable(aVarName: string): Boolean;
var
 l_Idx: Integer;
begin
 l_Idx := f_Variables.IndexOf(aVarName);
 Result := l_Idx >= 0;
 if Result then
  f_Variables.Delete(l_Idx);
end;

function TFURQContext.DoActionFinal(const anActionData: IFURQActionData): Boolean;
var
 l_CommonStr: string;
 l_Idx: Integer;
begin
 Result := False;
 try
  IncLocationCount(anActionData.LabelIdx);
  JumpToLabelIdx(anActionData.LabelIdx);
  // current_loc и previous_loc
  Variables[cVarPreviousLoc] := Variables[cVarCurrentLoc];
  Variables[cVarCurrentLoc] := Code.Labels[anActionData.LabelIdx];

  // обрабатываем common-локацию
  if  Variables[cVarCommon] <> 0 then
   l_CommonStr := cLocCommonPrefix + FormatNumber(EnsureReal(Variables[cVarCommon]))
  else
   l_CommonStr := cLocCommon;
  l_Idx := Code.Labels.IndexOf(l_CommonStr);
  if l_Idx <> -1 then
   ExecuteProc(l_Idx);
  Result := True;
 finally
  ClearButtons;
  f_Actions.Clear;
  f_MenuActions.Clear;
  f_Menu.Clear;
 end;
end;

procedure TFURQContext.DoLoadData(aFiler: TFURQFiler);
var
 l_Num: Integer;
 I: Integer;
 l_Name: string;
 l_Value: Variant;
begin
 l_Num := aFiler.ReadInteger;
 for I := 1 to l_Num do
 begin
  l_Name := aFiler.ReadString;
  l_Value := aFiler.ReadVarValue;
  Variables[l_Name] := l_Value;
 end;

 l_Num := aFiler.ReadInteger;
 for I := 1 to l_Num do
 begin
  l_Name := aFiler.ReadString;
  l_Value := aFiler.ReadDouble;
  AddToInventory(l_Name, l_Value);
 end;
 f_Stack.Load(aFiler);
 LoadActions(aFiler);
 LoadButtons(aFiler);
end;

procedure TFURQContext.DoSaveData(aFiler: TFURQFiler);
var
 I: Integer;
begin
 aFiler.WriteInteger(f_Variables.Count);
 for I := 0 to f_Variables.LastIndex do
 begin
  aFiler.WriteString(f_Variables[I]);
  aFiler.WriteVarValue(f_Variables.Variants[I]);
 end;
 aFiler.WriteInteger(f_Inventory.Count);
 for I := 0 to f_Inventory.LastIndex do
 begin
  aFiler.WriteString(f_Inventory[I]);
  aFiler.WriteDouble(f_Inventory.Variants[I]);
 end;
 f_Stack.Save(aFiler);
 SaveActions(aFiler);
 SaveButtons(aFiler);
end;

procedure TFURQContext.ExecuteProc(aLabelIdx: Integer);
begin
 ExecuteProcAtLine(f_Code.Labels.Variants[aLabelIdx]);
end;

procedure TFURQContext.ExecuteProcAtLine(aLineNo: Integer);
begin
 f_Stack := TFURQExecutionPoint.Create(f_Stack);
 JumpToLine(aLineNo);
end;

procedure TFURQContext.ForgetProcs;
begin
 f_Stack.DropPrev;
end;

function TFURQContext.FormatNumber(aNumber: Extended): string;
var
 l_Tmp: Word;
const
 cMaxDisp = 10000000000;
 cExpForm = '##.E-';
begin
 l_Tmp := Get8087CW;
 Set8087CW($1372);
 if (aNumber >= -cMaxDisp) and (aNumber <= cMaxDisp) then
  Result := FormatFloat(f_NumFormatString, aNumber)
 else
  Result := FormatFloat(cExpForm, aNumber);
 Set8087CW(l_Tmp);
end;

function TFURQContext.GetInventoryString(aIndex: Integer): string;
var
 l_DispVarName: string;
begin
 with f_Inventory do
 begin
  l_DispVarName := c_sIdispPrefix + Strings[aIndex];
  if IsVariableExists(l_DispVarName) and (EnsureString(Variables[l_DispVarName]) <> '') then
   Result := EnsureString(Variables[l_DispVarName])
  else
   Result := Strings[aIndex];
  if Variants[aIndex] <> 1.0 then
   Result := Result + ' (' + FormatNumber(Variants[aIndex]) + ')';
 end;
end;

function TFURQContext.GetVirtualVariable(const aName: string): Variant;
var
 l_InvName: string;
 l_Idx: Integer;
begin
 if AnsiStartsText(c_sInvPrefix, aName) then
 begin
  l_InvName := Copy(aName, 5, MaxInt);
  l_Idx := f_Inventory.IndexOf(l_InvName);
  if l_Idx = -1 then
   Result := 0
  else
   Result := f_Inventory.Variants[l_Idx];
 end
 else
 if AnsiSameText(c_sTimeVar, aName) then
  Result := EnsureReal(timeGetTime())
 else
  Result := Null;
end;

procedure TFURQContext.IncLocationCount(const aLabelIdx: Integer);
var
 l_CountName: string;
begin
 l_CountName := Code.LocCountVarName[aLabelIdx];
 Variables[l_CountName] := Variables[l_CountName] + 1;
end;

procedure TFURQContext.InitSysVariables;
begin
 Variables[cVarPrecision] := cDefaultPrecision;
 Variables[cVarTokenDelim] := ' ,!.?"';
 Variables[cVarPi] := Pi;
 Variables[cVarInventoryEnabled] := 1;
end;

function TFURQContext.IsSystemOrVirtualVariable(aVarName: string): Boolean;
begin
 Result := AnsiStartsText(c_sInvPrefix, aVarName) or AnsiStartsText(c_sCountPrefix, aVarName) or
           AnsiSameText(c_sTimeVar, aVarName);
end;

function TFURQContext.IsVariableExists(const aVarName: string): Boolean;
begin
 Result := IsSystemOrVirtualVariable(aVarName) or (f_Variables.IndexOf(aVarName) <> -1);
end;

procedure TFURQContext.JumpToLabelIdx(aIndex: Integer);
begin
 JumpToLine(f_Code.Labels.Variants[aIndex]);
end;

procedure TFURQContext.JumpToLine(aLineNo: Integer);
begin
 Stack.ClearOperators;
 Stack.Line := aLineNo;
end;

procedure TFURQContext.LoadFromFile(aFilename: string; aIgnoreHash: Boolean = False);
var
 l_FS: TFileStream;
begin
 l_FS := TFileStream.Create(aFilename, fmOpenRead);
 try
  LoadFromStream(l_FS, aIgnoreHash);
 finally
  l_FS.Free;
 end;
end;

procedure TFURQContext.LoadFromStream(aStream: TStream; aIgnoreHash: Boolean = False);
var
 l_R : TFURQFiler;
 l_Signature : string;
 l_Location  : string;
 I    : Integer;
 l_Hash: TMD5Digest;
begin
 l_R := TFURQFiler.Create(aStream);
 try
  l_Signature := l_R.ReadString;
  if l_Signature <> cSaveFileSignature then
   raise EFURQRunTimeError.Create(sCorruptedSaveFile);
  l_R.ReadString; // описание сохранёнки
  l_R.ReadDouble; // дата и время -- это всё не нужно при загрузке
  l_R.Stream.ReadBuffer(l_Hash, SizeOf(TMD5Digest));
  if (not aIgnoreHash) and (not MD5DigestCompare(l_Hash, f_Code.SourceHash)) then
   raise EFURQRunTimeError.Create(sBadVersionSaveFile);
  Restart;
  l_Location := l_R.ReadString;
  DoLoadData(l_R);
 finally
  l_R.Free;
 end;
 if l_Location <> '' then
 begin
  ForgetProcs;
  ClearText;
  ClearButtons;
  f_Actions.Clear;
  I := f_Code.Labels.IndexOf(l_Location);
  if I = -1 then
   JumpToLine(0) // если локация не найдена, то переходим на начало
  else
   JumpToLabelIdx(I);
 end;
end;

procedure TFURQContext.MusicPlay(const aFilename: string; aFadeTime: Integer);
begin
 // does nothing in base class
end;

procedure TFURQContext.MusicStop(aFadeTime: Integer);
begin
 // does nothing in base class
end;

function TFURQContext.pm_GetActionsData(anID: string): IFURQActionData;
var
 l_Idx: Integer;
begin
 Result := nil;
 l_Idx := f_Actions.IndexOf(anID);
 if l_Idx >= 0 then
  Result := f_Actions.Interfaces[l_Idx] as IFURQActionData
 else
 begin
  l_Idx := f_MenuActions.IndexOf(anID);
  if l_Idx >= 0 then
   Result := f_MenuActions.Interfaces[l_Idx] as IFURQActionData;
 end;
end;

function TFURQContext.pm_GetStateParam(aIndex: Integer): string;
begin
 Result := f_StateParam[aIndex];
end;

function TFURQContext.pm_GetVariables(aName: string): Variant;
var
 l_Idx: Integer;
begin
 // виртуальные переменные
 Result := GetVirtualVariable(aName);
 if Result <> Null then
  Exit;

 l_Idx := f_Variables.IndexOf(aName);
 if l_Idx < 0 then
  Result := 0.0
 else
  Result := f_Variables.Variants[l_Idx];
end;

procedure TFURQContext.pm_SetStateParam(aIndex: Integer; const Value: string);
begin
 f_StateParam[aIndex] := Value;
end;

procedure TFURQContext.pm_SetVariables(aName: string; const Value: Variant);
var
 l_Idx: Integer;
begin
 // виртуальные переменные
 if SetVirtualVariables(aName, Value) then
  Exit;

 l_Idx := f_Variables.IndexOf(aName);
 if l_Idx < 0 then
  l_Idx := f_Variables.Add(aName);
 f_Variables.Variants[l_Idx] := Value;

 SetSysVariables(aName, Value);
end;

procedure TFURQContext.Restart;
begin
 ClearStack;
 ClearButtons;
 ClearVariables;
 ClearInventory;
 f_Stack.Line := 0;
 f_State := csUndefined;
end;

procedure TFURQContext.ReturnFromProc;
var
 l_Prev: TFURQExecutionPoint;
begin
 l_Prev := f_Stack.Prev;
 Assert(l_Prev <> nil, 'Неожиданная попытка вернуться из процедуры');
 FreeAndNil(f_Stack);
 f_Stack := l_Prev;
end;

procedure TFURQContext.SaveToFile(const aFilename, aLocation: string; const aDescription: string = '');
var
 l_FS: TFileStream;
begin
 try
  l_FS := TFileStream.Create(aFilename, fmCreate);
  try
   SaveToStream(aLocation, l_FS, aDescription);
  finally
   FreeAndNil(l_FS);
  end;
  Variables[sVarSaveSuccess] := 1;
 except
  Variables[sVarSaveSuccess] := 0;
 end;
end;

procedure TFURQContext.SaveToStream(aLocation: string; aStream: TStream; const aDescription: string = '');
var
 l_W   : TFURQFiler;
 l_Hash: TMD5Digest;
begin
 l_W := TFURQFiler.Create(aStream);
 try
  l_W.WriteString(cSaveFileSignature);
  l_W.WriteString(aDescription);
  l_W.WriteDouble(Now);
  l_Hash := Code.SourceHash;
  l_W.Stream.WriteBuffer(l_Hash, SizeOf(TMD5Digest));
  l_W.WriteString(aLocation);
  DoSaveData(l_W);
 finally
  FreeAndNil(l_W);
 end;
end;

procedure TFURQContext.SetSysVariables(aName: string; const Value: Variant);
var
 l_Rnd: Integer;
begin
 // спецобработка (системные переменные)
 if AnsiSameText(aName, c_sFp_prec) then
 begin
  l_Rnd := Round(EnsureReal(Value));
  if l_Rnd <= 0 then
   f_NumFormatString := '0'
  else
   f_NumFormatString := '0.'+StringOfChar('#', l_Rnd);
 end;
end;

function TFURQContext.SetVirtualVariables(const aName: string; const aValue: Variant): Boolean;
var
 l_InvName: string;
begin
 Result := False;
 if AnsiStartsText(c_sInvPrefix, aName) then
 begin
  l_InvName := Copy(aName, 5, MaxInt);
  f_Inventory.KeyVariant[l_InvName] := EnsureReal(aValue);
  Result := True;
 end;
 if AnsiSameText(c_sTimeVar, aName) then
  Result := True; // в переменную time писать не получится
end;

procedure TFURQContext.SoundPlay(const aFilename: string; aVolume: Integer; aLooped: Boolean);
begin
 // does nothing in base class
end;

procedure TFURQContext.SoundStop(const aFilename: string);
begin
 // does nothing in base class
end;

procedure TFURQContext.StartMenuBuild(aKeepMenuActions: Boolean);
begin
 Assert(not f_IsMenuBuild, 'Menu build already started!');
 f_IsMenuBuild := True;
 f_BackupStack := f_Stack;
 f_Stack := TFURQExecutionPoint.Create(nil);
 f_BackupState := f_State;
 f_Menu.Clear;
 if not aKeepMenuActions then
  f_MenuActions.Clear;
end;

procedure TFURQContext.EndMenuBuild;
begin
 Assert(f_IsMenuBuild, 'Menu build not started!');
 FreeAndNil(f_Stack);
 f_Stack := f_BackupStack;
 f_BackupStack := nil;
 f_State := f_BackupState;
 f_IsMenuBuild := False;
end;

procedure TFURQContext.LoadActions(const aFiler: TFURQFiler);
var
 l_Count, I, l_Idx: Integer;
 l_Data: IFURQActionData;
 l_Hash: string;
begin
 f_Actions.Clear;
 l_Count := aFiler.ReadInteger;
 for I := 1 to l_Count do
 begin
  l_Data := TFURQActionData.Load(aFiler);
  l_Hash := ActionDataHash(l_Data);
  l_Idx := f_Actions.Add(l_Hash);
  f_Actions.Interfaces[l_Idx] := l_Data;
 end;
end;

procedure TFURQContext.SaveButtons(const aFiler: TFURQFiler);
var
 I: Integer;
begin
 aFiler.WriteInteger(f_Buttons.Count);
 for I := 0 to f_Buttons.Count-1 do
 begin
  aFiler.WriteString(f_Buttons[I]);
  aFiler.WriteString(f_Buttons.Variants[I]);
 end;
end;

procedure TFURQContext.LoadButtons(const aFiler: TFURQFiler);
var
 l_Count: Integer;
 I: Integer;
 l_Idx: Integer;
begin
 f_Buttons.Clear;
 l_Count := aFiler.ReadInteger;
 for I := 1 to l_Count do
 begin
  l_Idx := f_Buttons.Add(aFiler.ReadString);
  f_Buttons.Variants[l_Idx] := aFiler.ReadString;
 end;
end;

procedure TFURQContext.SaveActions(const aFiler: TFURQFiler);
var
 I: Integer;
begin
 aFiler.WriteInteger(f_Actions.Count);
 for I := 0 to f_Actions.Count-1 do
  (f_Actions.Interfaces[I] as IFURQActionData).Save(aFiler);
end;

function TFURQContext.SystemProc(aProcName: string; aParams: IJclStringList): Boolean;
var
 l_Prec: string;
 l_Int: Int64;
 l_Len: Integer;
 l_Pos: Integer;
 l_Power: Real;
begin
 Result := False;
 if AnsiSameText(aProcName, c_s_sin) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := Sin(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_cos) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := Cos(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_tan) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := Tan(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_arcsin) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := ArcSin(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_arccos) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := ArcCos(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_arctan) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := ArcTan(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_sqrt) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := Sqrt(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_power) and (aParams.Count > 0) then
 begin
  if aParams.Count > 1 then
   l_Power := aParams.Variants[1]
  else
   l_Power := 2.0;
  Variables[c_s_result] := Power(aParams.Variants[0], l_Power);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_int) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := Int(aParams.Variants[0]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_tohex) and (aParams.Count > 0) then
 begin
  if aParams.Count > 1 then
   l_Prec := '.'+IntToStr(aParams.Variants[1])
  else
   l_Prec := '';
  l_Int := aParams.Variants[0];
  Variables[c_s_result] := Format('%'+l_Prec+'x', [l_Int]);
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_trim) and (aParams.Count > 0) then
 begin
  Variables[c_s_result] := Trim(EnsureString(aParams.Variants[0]));
  Result := True;
 end

 else

 if AnsiSameText(aProcName, c_s_scopy) and (aParams.Count > 1) then
 begin
  if aParams.Count > 2 then
   l_Len := aParams.Variants[2]
  else
   l_Len := MaxInt;
  l_Pos := aParams.Variants[1];
  Variables[c_s_result] := Copy(EnsureString(aParams.Variants[0]), l_Pos, l_Len);
  Result := True;
 end;
end;

constructor TFURQCondition.Create(const aCondition: string; aThenOp, aElseOp: TFURQOperator);
begin
 inherited Create(aCondition);
 f_OperatorType := otCondition;
 f_ThenOp := aThenOp;
 f_ElseOp := aElseOp;
end;

destructor TFURQCondition.Destroy;
begin
 FreeAndNil(f_ThenOp);
 FreeAndNil(f_ElseOp);
 inherited;
end;

procedure TFURQCondition.Load(const aFiler: TFURQFiler);
begin
 inherited Load(aFiler);
 FreeAndNil(f_ThenOp);
 FreeAndNil(f_ElseOp);
 f_ThenOp := LoadOperators(aFiler);
 if aFiler.ReadBoolean then
  f_ElseOp := LoadOperators(aFiler);
end;

procedure TFURQCondition.Save(const aFiler: TFURQFiler);
var
 l_HasElse: Boolean;
begin
 inherited;
 SaveOperators(ThenOp, aFiler);
 l_HasElse := ElseOp <> nil;
 aFiler.WriteBoolean(l_HasElse);
 if l_HasElse then
  SaveOperators(ElseOp, aFiler);
end;

constructor TFURQWinContext.Create(aCode: TFURQCode; aFilename: string);
begin
 inherited Create(aCode);
 f_Filename := aFilename;
 Restart;
end;

procedure TFURQWinContext.ClearTextBuffer;
begin
 f_TextBuffer := '';
end;

procedure TFURQWinContext.InitSysVariables;
begin
 inherited;
 Variables[c_sInvname] := String(cDefaultInvName);
 Variables[c_sGametitle] := f_Filename;
end;

procedure TFURQWinContext.OutText(const aStr: string);
begin
 f_TextBuffer := f_TextBuffer + aStr;
end;

procedure TFURQWinContext.Restart;
begin
 inherited;
 ClearTextBuffer;
end;

constructor TFURQActionData.Create(aIdx: Integer; aParams: IJclStringList; aModifier: TFURQActionModifier = amNone);
begin
 inherited Create;
 f_LabelIdx := aIdx;
 f_Params := aParams;
 f_Modifier := aModifier;
end;

constructor TFURQActionData.Load(const aFiler: Td2dFiler);
var
 I, l_Count: Integer;
begin
 inherited Create;
 f_LabelIdx := aFiler.ReadInteger;
 f_Modifier := TFURQActionModifier(aFiler.ReadByte);
 f_Params := JclStringList;
 l_Count := aFiler.ReadInteger;
 for I := 1 to l_Count do
  f_Params.Add(aFiler.ReadString);
end;

destructor TFURQActionData.Destroy;
begin
 f_Params := nil;
 inherited;
end;

function TFURQActionData.pm_GetModifier: TFURQActionModifier;
begin
 Result := f_Modifier;
end;

function TFURQActionData.pm_GetLabelIdx: Integer;
begin
 Result := f_LabelIdx;
end;

function TFURQActionData.pm_GetParams: IJclStringList;
begin
 Result := f_Params;
end;

procedure TFURQActionData.Save(const aFiler: Td2dFiler);
var
 I: Integer;
begin
 aFiler.WriteInteger(f_LabelIdx);
 aFiler.WriteByte(Ord(f_Modifier));
 aFiler.WriteInteger(f_Params.Count);
 for I := 0 to f_Params.Count-1 do
  aFiler.WriteString(f_Params[I]);
end;

constructor TFURQCodePoint.Create(aFile, aLineNo: Integer);
begin
 inherited Create;
 f_File := aFile;
 f_LineNo := aLineNo;
end;

function TFURQCodePoint.pm_GetLineNo: Integer;
begin
 Result := f_LineNo;
end;

function TFURQCodePoint.pm_GetSrcFile: Integer;
begin
 Result := f_File;
end;

end.

