unit furqBase;

interface

uses
 Windows,
 Classes,

 JclStringLists,

 furqTypes,
 furqContext
 ;

type
 // Собственно интерпретатор. Обрабатывает контекст и устанавливает его в различные состояния.
 TFURQInterpreter = class
 private
  f_OnError: TfurqOnErrorHandler;
  function DoAction(anActionData: IFURQActionData): Boolean;
  procedure HandleAnykey(aParams: string);
  procedure HandleBtn(aArgs: string);
  procedure HandleCls(aParams: TFURQClsTypeSet = [clText, clButtons]);
  procedure HandleEnd;
  procedure HandleForgetProcs;
  procedure HandleInput(aName: string);
  procedure HandleInstr(aOperand: string);
  procedure HandleInv(aOperand: string);
  procedure HandleInvKill(aName: string);
  procedure HandlePause(aInterval: string);
  procedure HandlePerKill;
  procedure HandlePrint(const aString: string);
  procedure HandlePrintLn(const aString: string);
  procedure HandleProc(aLabel: string);
  procedure InvMenuJump(aLabelIdx: Integer);
  procedure ParseAssigment(aString: string; var theVarName, theExpression: string);
  function pm_GetCurLine: string;
  function pm_GetEOF: Boolean;
  function pm_GetLine: Integer;
  procedure pm_SetLine(const Value: Integer);
  function UnfoldSubst(const aString: string): string;
  function ValidVarName(aVarName: string): Boolean;
  procedure CheckVarName(aVarname: string);
  function DoActionById(anActionID: string): Boolean;
  procedure HandleGoto(aLocation: string);
  procedure HandleLoad(const aParams: string);
  procedure HandleMusic(aFilename: string);
  procedure HandlePlay(aFilename: string);
  procedure HandleSave(aParams: string);
  procedure HandleQuit;
  procedure HandleTokens(aExpression: string);
 protected
  f_CurContext: TFURQContext;
  procedure ApplyParams(aLabelIdx: Integer; aParams: IJclStringList);
  procedure EvaluateParams(aParams: IJclStringList);
  procedure ExecuteNextCommand;
  function HandleExtraOps(const aOperator, aOperand: string): Boolean; virtual;
  procedure IncLine;
  procedure NotAvailableWhileMenuBuild;
  procedure NotAvailableInEvents;
  procedure ParseOperators;
  property Line: Integer read pm_GetLine write pm_SetLine;
 public
  procedure Execute(aContext: TFURQContext);
  procedure BuildMenu(aContext: TFURQContext; const aActionID: string; aKeepMenuActions: Boolean = False);
  property CurLine: string read pm_GetCurLine;
  property EOF: Boolean read pm_GetEOF;
  property OnError: TfurqOnErrorHandler read f_OnError write f_OnError;
 end;

function ParseLocAndParams(const aStr: string; var theLoc: string; var Params: IJclStringList; var theModifier:
    TFURQActionModifier): Integer;

implementation
uses
 Variants,
 SysUtils,
 StrUtils,
 JclStrings,

 furqExprEval;

const
 sSubstNotClosed           = 'Подстановка не закрыта';
 sIncorrectVarName         = 'Недопустимое имя переменной: "%s"';
 sIncorrectOperator        = 'Неизвестный оператор: "%s"';
 sNoLocationFound          = 'Переход на несуществующую метку: %s';
 sIfWithoutThen            = 'IF без THEN';
 sNoInputVariable          = 'Не указана переменная для INPUT';
 sIncorrectPauseInterval   = 'Некорректный интервал в PAUSE';
 sFileNotFound             = 'Файл не найден: %s';
 sBadLocationSyntax        = 'Ошибка в описании целевой локации';
 sInvalidLocationForParams = 'Локация с именем "%s" не может быть использована для передачи параметров';
 sWrongParams              = 'Ошибка в параметрах';

 cDOSURQCountVar = 'dosurq_count';

 cMaxParams = 50;

function ParseLocAndParams(const aStr: string; var theLoc: string; var Params: IJclStringList; var theModifier: TFURQActionModifier): Integer;
var
 l_BLevel: Integer;
 l_Lex: TfurqLexer;
 l_ParStart: Integer;
 l_HasPar  : Boolean;

 procedure AddParam(aEndPos: Integer);
 var
  l_ParStr: string;
 begin
  l_ParStr := Copy(aStr, l_ParStart, aEndPos - l_ParStart);
  Params.Add(l_ParStr);
 end;

begin
 l_Lex := TfurqLexer.Create;
 try
  l_BLevel := 0;
  theLoc := '';
  l_HasPar := False;
  Result := -1;
  l_Lex.Source := aStr;
  while True do
  begin
   case l_Lex.Token of
    etLBrasket:
     begin
      if l_BLevel = 0 then
      begin
       if l_HasPar then // уже открывали скобку первого уровня!
        raise EFURQRunTimeError.Create(sBadLocationSyntax);
       theLoc := Trim(Copy(aStr, 1, l_Lex.TokenStart-1));
       l_ParStart := l_Lex.TokenEnd;
       l_HasPar := True;
      end;
      Inc(l_BLevel);
     end;

    etRBrasket:
     begin
      Dec(l_BLevel);
      if l_BLevel = 0 then
      begin
       AddParam(l_Lex.TokenStart);
      end;
     end;

    etComma:
     begin
      if l_BLevel = 0 then // запятая вне параметров заканчивает разбор
      begin
       if not l_HasPar then
        theLoc := Trim(Copy(aStr, 1, l_Lex.TokenStart-1));
       Result := l_Lex.TokenEnd; // это для btn - чтобы знать, откуда считать название кнопки
       Break;
      end;

      if l_BLevel = 1 then // еще один параметр
      begin
       AddParam(l_Lex.TokenStart);
       l_ParStart := l_Lex.TokenEnd;
      end
      else // запятая встретилась где-то внутри вложенных скобок == незакрытая скобка в выражении
       raise EFURQRunTimeError.Create(sBadLocationSyntax);
     end;

    etEOF:
     begin
      if l_BLevel = 0 then
      begin
       if not l_HasPar then
        theLoc := Trim(aStr);
       Break;
      end
      else // осталась незакрытая скобка!
       raise EFURQRunTimeError.Create(sBadLocationSyntax);
     end;
   end;
   l_Lex.NextToken;
  end;
  if theLoc <> '' then
   case theLoc[1] of
     '!' :
       begin
        theModifier := amNonFinal;
        Delete(theLoc, 1, 1);
       end;
     '%' :
       begin
        theModifier := amMenu;
        Delete(theLoc, 1, 1);
       end;
   else
    theModifier := amNone;
   end;
 finally
  FreeAndNil(l_Lex);
 end;
end;

procedure TFURQInterpreter.ApplyParams(aLabelIdx: Integer; aParams: IJclStringList);
var
 I: Integer;
 l_Loc: string;
 l_VarName: string;

 function VarName(l_Idx: Integer): string;
 begin
  Result := Format('%s_%d', [l_Loc, l_Idx]);
 end;

begin
 l_Loc := f_CurContext.Code.Labels.Strings[aLabelIdx];
 for I := 1 to cMaxParams do
 begin
  l_VarName := VarName(I);
  if not f_CurContext.DeleteVariable(l_VarName) then
   Break;
 end;
 if (aParams <> nil) and (aParams.Count > 0) then
 begin
  if not ValidVarName(l_Loc) then
   raise EFURQRunTimeError.CreateFmt(sInvalidLocationForParams, [l_Loc]);
  EvaluateParams(aParams);
  for I := 0 to Pred(aParams.Count) do
   f_CurContext.Variables[VarName(I+1)] := aParams.Variants[I];
 end;
end;

procedure TFURQInterpreter.BuildMenu(aContext: TFURQContext; const aActionID: string; aKeepMenuActions: Boolean = False);
begin
 aContext.StartMenuBuild(aKeepMenuActions);
 try
  aContext.State := csEnd; // это чтобы не уйти дальше по стеку как по csPause
  aContext.StateResult := Format('b:%s', [aActionID]);
  Execute(aContext);
 finally
  aContext.EndMenuBuild;
 end;
end;

function TFURQInterpreter.DoAction(anActionData: IFURQActionData): Boolean;
begin
 Result := False;
 if anActionData <> nil then
 begin
  if anActionData.LabelIdx > -1 then
  begin
   ApplyParams(anActionData.LabelIdx, anActionData.Params);
   Result := f_CurContext.DoAction(anActionData);
  end;
 end;
end;

procedure TFURQInterpreter.Execute(aContext: TFURQContext);
var
 l_Str: string;
 l_Pos: Integer;
 l_LabelIdx: Integer;
begin
 try
  f_CurContext := aContext;
  // обрабатываем ответ от пользователя
  case f_CurContext.State of
   csEnd, csPause:
    if f_CurContext.StateResult <> '' then
    begin
     if AnsiStartsText('b:', f_CurContext.StateResult) then
     begin
      if not DoActionById(Copy(f_CurContext.StateResult, 3, MaxInt)) then
       Exit;
     end
     else
      if AnsiStartsText('i:', f_CurContext.StateResult) then
      begin
       l_Str := Copy(f_CurContext.StateResult, 3, MaxInt);
       l_LabelIdx := StrToIntDef(l_Str, -1);
       InvMenuJump(l_LabelIdx);
      end;
    end;
   csSave:
    with f_CurContext do
     if StateResult <> '' then
      SaveToFile(StateResult, StateParam[1], StateParam[2]);
   csInput:
    with f_CurContext do
    begin
     if VarType(Variables[StateParam[1]]) = varString then
      Variables[StateParam[1]] := StateResult
     else
      Variables[StateParam[1]] := StrToFloatDef(StateResult, 0.0);
    end;
   csInputKey:
    with f_CurContext do
    begin
     if StateParam[1] <> '' then
      Variables[StateParam[1]] := StrToInt(StateResult);
    end;
  end;
 except
  // обработка ошибок времени исполнения
  on E: Exception do
   if Assigned(f_OnError) then
    f_OnError(E.Message, Line);
 end;

 // выполняем код дальше
 with f_CurContext do
 begin
  ClearStateParams;
  StateResult := '';
  State := csRun;
 end;

 while f_CurContext.State = csRun do
 begin
  try
   if f_CurContext.Stack.CurOp = nil then
    ParseOperators;
   ExecuteNextCommand;
  except
   // обработка ошибок времени исполнения
   on E: Exception do
    if Assigned(f_OnError) then
     f_OnError(E.Message, Line);
  end;
 end;
end;

procedure TFURQInterpreter.ExecuteNextCommand;
var
 l_OpText: string;
 l_Pos: Integer;
 l_Op: string;
 l_IsOperator: Boolean;
 l_Operand: string;
 l_VarName: string;
 l_Eval: TfurqExprEvaluator;
 l_Cond: TFURQCondition;
 l_DoNext: Boolean;
 l_ResVal: Variant;

 procedure JumpToNext;
 begin
  with f_CurContext.Stack do
   if CurOp <> nil then
    CurOp := CurOp.Next;
 end;

begin
 if f_CurContext.State <> csRun then
  Exit;
 l_DoNext := True;
 try
  if f_CurContext.Stack.CurOp is TFURQCondition then
  begin
   l_Cond := f_CurContext.Stack.CurOp as TFURQCondition;
   l_Eval := TfurqExprEvaluator.Create(f_CurContext);
   try
    l_Eval.Source := UnfoldSubst(l_Cond.Source);
    if EnsureReal(l_Eval.ResultValue) <> 0.0 then
     f_CurContext.Stack.CurOp := l_Cond.ThenOp
    else
     f_CurContext.Stack.CurOp := l_Cond.ElseOp;
   finally
    FreeAndNil(l_Eval);
   end;
   l_DoNext := False;
   Exit; // уходим на следующую итерацию
  end;
  l_OpText := f_CurContext.Stack.CurOp.Source;
  l_OpText := TrimLeft(UnfoldSubst(TrimLeft(l_OpText))); // Второй TrimLeft - на случай, если в подстановках был пробел слева... [mutagen]

  if l_OpText <> '' then // может получиться, что после разворачивания подстановок будет пустая строка
  begin
   // есть шанс, что это оператор!
   l_Pos := Pos(' ', l_OpText);
   if l_Pos = 0 then
   begin
    l_Op := AnsiUpperCase(l_OpText);
    l_Operand := '';
   end
   else
   begin
    if l_OpText[l_Pos-1] in ['+', '-'] then
     Dec(l_Pos); // для случая, когда "INV+" или "INV-" написаны слитно. По-хорошему, надо вообще-то парсить...
    l_Op := AnsiUpperCase(Copy(l_OpText, 1, l_Pos-1));
    if l_OpText[l_Pos] = ' ' then // если пробел, то пропускаем его
     l_Operand := Copy(l_OpText, l_Pos+1, MaxInt)
    else
     l_Operand := Copy(l_OpText, l_Pos, MaxInt); // если нет, то оставляем (опять же, для inv+, inv-)
   end;

   l_IsOperator := True;
   if (l_Op = 'P') or (l_Op = 'PRINT') then
    HandlePrint(l_Operand)
   else
   if (l_Op = 'PLN') or (l_Op = 'PRINTLN') then
    HandlePrintLn(l_Operand)
   else
   if (l_Op = 'PROC') then
   begin
    JumpToNext;
    l_DoNext := False;
    HandleProc(l_Operand)
   end
   else
   if (l_Op = 'END') then
   begin
    l_DoNext := False;
    HandleEnd
   end
   else
   if (l_Op = 'BTN') then
    HandleBtn(l_Operand)
   else
   if (l_Op = 'INV') then
    HandleInv(l_Operand)
   else
   if (l_Op = 'SAVE') then
    HandleSave(l_Operand)
   else
   if (l_Op = 'LOAD') then
    HandleLoad(l_Operand)
   else
   if (l_Op = 'GOTO') then
    HandleGoto(l_Operand)
   else
   if (l_Op = 'INVKILL') then
    HandleInvKill(l_Operand)
   else
   if (l_Op = 'PERKILL') then
    HandlePerKill
   else
   if (l_Op = 'INPUT') then
    HandleInput(l_Operand)
   else
   if (l_Op = 'PAUSE') then
    HandlePause(l_Operand)
   else
   if (l_Op = 'FORGET_PROCS') then
    HandleForgetProcs
   else
   if (l_Op = 'CLS') then
    HandleCls
   else
   if (l_Op = 'CLST') then
    HandleCls([clText])
   else
   if (l_Op = 'CLSB') then
    HandleCls([clButtons])
   else
   if (l_Op = 'INSTR') then
    HandleInstr(l_Operand)
   else
   if (l_Op = 'ANYKEY') then
    HandleAnykey(l_Operand)
   else
   if (l_Op = 'TOKENS') then
    HandleTokens(l_Operand)
   else
   if (l_Op = 'MUSIC') then
    HandleMusic(l_Operand)
   else
   if (l_Op = 'PLAY') then
    HandlePlay(l_Operand)
   else
   if (l_Op = 'QUIT') then
    HandleQuit
   else
    l_IsOperator := HandleExtraOps(l_Op, l_Operand); // какие-то другие операторы (у наследников)

   if not l_IsOperator then // это не оператор... может, выражение?
   begin
    ParseAssigment(l_OpText, l_VarName, l_Operand);
    l_Eval := TfurqExprEvaluator.Create(f_CurContext);
    try
     l_Eval.Source := l_Operand;
     l_ResVal := l_Eval.ResultValue;
     f_CurContext.Variables[l_VarName] := l_ResVal;
     // обработка особых переменных
     if AnsiSameText('music', l_Varname) then
     begin
      if VarType(l_ResVal) = varString then
       HandleMusic(EnsureString(l_ResVal))
      else
       HandleMusic(f_CurContext.FormatNumber(EnsureReal(l_ResVal)));
     end;
    finally
     FreeAndNil(l_Eval);
    end;
   end;
  end;
 finally
  if l_DoNext then
   JumpToNext;
 end;
end;

procedure TFURQInterpreter.HandleAnykey(aParams: string);
var
 l_List: IJclStringList;
begin
 NotAvailableWhileMenuBuild;
 l_List := ParseAndEvalToArray(f_CurContext, aParams, [2]);
 if l_List.Count > 0 then
 begin
  CheckVarName(l_List.Strings[0]);
  f_CurContext.StateParam[1] := l_List.Strings[0];
  if l_List.Count > 1 then
   f_CurContext.StateParam[2] := IntToStr(l_List.Variants[1]);
 end;
 f_CurContext.State := csInputKey;
end;

procedure TFURQInterpreter.HandleBtn(aArgs: string);
var
 l_Pos: Integer;
 l_Loc: string;
 l_Txt: string;
 l_Params: IJclStringList;
 l_AM: TFURQActionModifier;
begin
 l_Params := JclStringList;
 l_Pos := ParseLocAndParams(aArgs, l_Loc, l_Params, l_AM);
 if l_Loc <> '' then
 begin
  if l_Pos > 0 then
   l_Txt := Trim(Copy(aArgs, l_Pos, MaxInt))
  else
   l_Txt := '';
  if l_Txt = '' then
   l_Txt := l_Loc;
  f_CurContext.AddButton(l_Loc, l_Params, l_Txt, l_AM); // фантомы обрабатываются в контексте
 end
 else
  raise EFURQRunTimeError.Create(sBadLocationSyntax);
end;

procedure TFURQInterpreter.HandleCls(aParams: TFURQClsTypeSet = [clText, clButtons]);
begin
 NotAvailableWhileMenuBuild;
 if clText in aParams then
  f_CurContext.ClearText;
 if clButtons in aParams then
  f_CurContext.ClearButtons; 
end;

procedure TFURQInterpreter.HandleEnd;
begin
 if f_CurContext.Stack.Prev <> nil then
  f_CurContext.ReturnFromProc
 else
  f_CurContext.State := csEnd;
end;

procedure TFURQInterpreter.HandleForgetProcs;
begin
 f_CurContext.ForgetProcs;
end;

procedure TFURQInterpreter.HandleGoto(aLocation: string);
var
 l_Label : string;
 l_Params: IJclStringList;
 l_LabelIdx: Integer;
 l_AM: TFURQActionModifier;
begin
 l_Params := JclStringList;
 if ParseLocAndParams(aLocation, l_Label, l_Params, l_AM) <> -1 then
  raise EFURQRunTimeError.Create(sBadLocationSyntax);
 if l_AM <> amNone then
  raise EFURQRunTimeError.Create(sBadLocationSyntax);
 l_LabelIdx := f_CurContext.Code.Labels.IndexOf(l_Label);
 if l_LabelIdx <> -1 then
 begin
  ApplyParams(l_LabelIdx, l_Params);
  f_CurContext.JumpToLabelIdx(l_LabelIdx);
  if EnsureReal(f_CurContext.Variables[cDOSURQCountVar]) <> 0 then
   f_CurContext.IncLocationCount(l_LabelIdx);
 end
 else
  raise EFURQRunTimeError.CreateFmt(sNoLocationFound, [aLocation]);
end;

procedure TFURQInterpreter.CheckVarName(aVarname: string);
begin
 if not ValidVarName(aVarname) then
  raise EFURQRunTimeError.CreateFmt(sIncorrectVarName, [aVarname]);
end;

function TFURQInterpreter.DoActionById(anActionID: string): Boolean;
var
 l_AData: IFURQActionData;
begin
 Result := False;
 l_AData := f_CurContext.ActionsData[anActionID];
 if l_AData <> nil then
  Result := DoAction(l_AData);
end;

procedure TFURQInterpreter.EvaluateParams(aParams: IJclStringList);
var
 l_Eval: TfurqExprEvaluator;
 I: Integer;
begin
 l_Eval := TfurqExprEvaluator.Create(f_CurContext);
 try
  for I := 0 to Pred(aParams.Count) do
  begin
   l_Eval.Source := aParams[I];
   aParams.Variants[I] := l_Eval.ResultValue;
  end;
 finally
  FreeAndNil(l_Eval);
 end;
end;

function TFURQInterpreter.HandleExtraOps(const aOperator, aOperand: string): Boolean;
begin
 // Этот метод перекрывается у наследников, чтобы реализовать дополнительные операторы
 Result := False;
end;

procedure TFURQInterpreter.HandleInput(aName: string);
begin
 NotAvailableWhileMenuBuild;
 aName := Trim(aName);
 if aName = '' then
  raise EFURQRunTimeError.Create(sNoInputVariable);
 CheckVarName(aName);
 f_CurContext.StateParam[1] := aName;
 f_CurContext.State := csInput;
end;

procedure TFURQInterpreter.HandleInstr(aOperand: string);
var
 l_VarName, l_Value: string;
begin
 ParseAssigment(aOperand, l_VarName, l_Value);
 f_CurContext.Variables[l_VarName] := l_Value;
end;

procedure TFURQInterpreter.HandleInv(aOperand: string);
var
 l_Pos: Integer;
 l_Item: string;
 l_Amount: Double;
 l_Eval: TfurqExprEvaluator;
begin
 NotAvailableWhileMenuBuild;
 l_Pos := Pos(',', aOperand);
 if l_Pos = 0 then
 begin
  if aOperand[1] in ['-', '+'] then
  begin
   if aOperand[1] = '-' then
    l_Amount := -1.0
   else
    l_Amount := 1.0;
   Delete(aOperand, 1, 1);
  end
  else
   l_Amount := 1.0;

  l_Item := Trim(aOperand)
 end
 else
 begin
  l_Eval := TfurqExprEvaluator.Create(f_CurContext);
  try
   l_Eval.Source := Trim(Copy(aOperand, 1, l_Pos-1));
   l_Amount := EnsureReal(l_Eval.ResultValue);
  finally
   FreeAndNil(l_Eval);
  end;
  l_Item := Trim(Copy(aOperand, l_Pos+1, MaxInt));
 end;
 f_CurContext.AddToInventory(l_Item, l_Amount);
end;

procedure TFURQInterpreter.HandleInvKill(aName: string);
var
 l_Idx: Integer;
begin
 NotAvailableWhileMenuBuild;
 aName := Trim(aName);
 if aName = '' then
  f_CurContext.ClearInventory
 else
 begin
  l_Idx := f_CurContext.Inventory.IndexOf(aName);
  if l_Idx <> -1 then
   f_CurContext.Inventory.Delete(l_Idx);
 end;
end;

procedure TFURQInterpreter.HandleLoad(const aParams: string);
var
 l_Slot: Integer;
begin
 l_Slot := StrToIntDef(aParams, -1);
 if l_Slot > -1 then
  f_CurContext.StateParam[1] := IntToStr(l_Slot);
 f_CurContext.State := csLoad;
end;

procedure TFURQInterpreter.HandleMusic(aFilename: string);
var
 l_Params: TStringList;
 l_FadeTime: Integer;
begin
 NotAvailableWhileMenuBuild;
 aFilename := Trim(aFilename);
 l_Params := TStringList.Create;
 try
  StrTokenToStrings(aFilename, ',', l_Params);
  TrimStrings(l_Params, False);
  if l_Params.Count = 0 then
   Exit;
  if l_Params.Count > 1 then
   l_FadeTime := StrToIntDef(l_Params[1], 0)
  else
   l_FadeTime := 0;
  if AnsiSameText(l_Params[0], 'stop') or (l_Params[0] = '0') then
   f_CurContext.MusicStop(l_FadeTime)
  else
  begin
   if StrIsDigit(l_Params[0]) then
    l_Params[0] := l_Params[0]+'.mid';
   f_CurContext.MusicPlay(l_Params[0], l_FadeTime);
  end;
 finally
  l_Params.Free;
 end;
end;

procedure TFURQInterpreter.HandlePause(aInterval: string);
var
 l_Eval: TfurqExprEvaluator;
 l_Interval: Double;
begin
 NotAvailableWhileMenuBuild;
 aInterval := Trim(aInterval);
 if aInterval = '' then
  aInterval := '1000';
 l_Eval := TfurqExprEvaluator.Create(f_CurContext);
 try
  l_Eval.Source := aInterval;
  l_Interval := l_Eval.ResultValue;
  f_CurContext.StateParam[1] := Format('%f', [l_Interval]);
  f_CurContext.State := csPause;
 finally
  l_Eval.Free;
 end;
end;

procedure TFURQInterpreter.HandlePerKill;
begin
 f_CurContext.ClearVariables;
end;

procedure TFURQInterpreter.HandlePlay(aFilename: string);
var
 l_Params: TStringList;
 l_Modifier: string;
 l_IsLooped: Boolean;
 l_IsStopped: Boolean;
 l_Volume   : Integer;
begin
 NotAvailableWhileMenuBuild;
 aFilename := Trim(aFilename);
 l_Params := TStringList.Create;
 try
  StrTokenToStrings(aFilename, ',', l_Params);
  TrimStrings(l_Params, False);
  if l_Params.Count = 0 then
   Exit;

  if AnsiLowerCase(l_Params[0]) = 'stop' then
  begin
   f_CurContext.SoundStop('');
   Exit;
  end;

  l_Modifier  := AnsiLowerCase(Copy(l_Params[0], 1, 5));
  l_IsLooped  := l_Modifier = 'loop ';
  l_IsStopped := l_Modifier = 'stop ';
  if l_IsLooped or l_IsStopped then
   l_Params[0] := Trim(Copy(l_Params[0], 6, MaxInt));
  if StrIsDigit(l_Params[0]) then
   l_Params[0] := l_Params[0]+'.wav';

  if l_Params.Count > 1 then
  begin
   l_Volume := StrToIntDef(l_Params[1], 255);
   if l_Volume > 255 then
    l_Volume := 255
   else
    if l_Volume < 0 then
     l_Volume := 0;
  end
  else
   l_Volume := 255;

  if l_IsStopped then
   f_CurContext.SoundStop(l_Params[0])
  else
   f_CurContext.SoundPlay(l_Params[0], l_Volume, l_IsLooped);
 finally
  l_Params.Free;
 end;
end;

procedure TFURQInterpreter.HandlePrint(const aString: string);
begin
 NotAvailableWhileMenuBuild;
 f_CurContext.OutText(aString);
end;

procedure TFURQInterpreter.HandlePrintLn(const aString: string);
begin
 NotAvailableWhileMenuBuild;
 HandlePrint(aString);
 f_CurContext.OutText(cCaretReturn);
end;

procedure TFURQInterpreter.HandleProc(aLabel: string);
var
 l_Loc: string;
 l_Idx: Integer;
 l_Params: IJclStringList;
 l_AM: TFURQActionModifier;
begin
 l_Params := JclStringList;
 if ParseLocAndParams(aLabel, l_Loc, l_Params, l_AM) <> -1 then
  raise EFURQRunTimeError.Create(sBadLocationSyntax);
 if l_AM <> amNone then
  raise EFURQRunTimeError.Create(sBadLocationSyntax);
 l_Idx := f_CurContext.Code.Labels.IndexOf(l_Loc);
 if l_Idx >= 0 then
 begin
  ApplyParams(l_Idx, l_Params);
  f_CurContext.ExecuteProc(l_Idx);
  if EnsureReal(f_CurContext.Variables[cDOSURQCountVar]) <> 0 then
   f_CurContext.IncLocationCount(l_Idx);
 end
 else
 begin
  EvaluateParams(l_Params);
  if not f_CurContext.SystemProc(l_Loc, l_Params) then
   raise EFURQRunTimeError.CreateFmt(sNoLocationFound, [l_Loc]);
 end;
end;

procedure TFURQInterpreter.HandleQuit;
begin
 NotAvailableWhileMenuBuild;
 f_CurContext.ForgetProcs;
 f_CurContext.ClearButtons;
 f_CurContext.ClearInventory;
 f_CurContext.ClearVariables;
 f_CurContext.State := csQuit;
end;

procedure TFURQInterpreter.HandleSave(aParams: string);
var
 l_Int: Integer;
 l_ParaList: IJclStringList;
 l_Param: string;
 l_ParamValue: Variant;
 l_CurParamIdx: Integer;
 l_Fixed: Boolean;
 l_HaveParam: Boolean;

 procedure l_NextParam;
 begin
  Inc(l_CurParamIdx);
  if l_CurParamIdx < l_ParaList.Count then
  begin
   l_Param := l_ParaList.Strings[l_CurParamIdx];
   l_ParamValue := l_ParaList.Variants[l_CurParamIdx];
   if l_Param = '' then
    raise EFURQRunTimeError.Create(sWrongParams);
   l_HaveParam := True; 
  end
  else
   l_HaveParam := False;
 end;

begin
 NotAvailableWhileMenuBuild;
 if aParams = '' then
  aParams := '"Автосохранение",0';
 l_ParaList := ParseAndEvalToArray(f_CurContext, aParams, [1, 2, 3]);

 with f_CurContext do
 begin
  l_CurParamIdx := -1;
  l_Fixed := False;
  l_NextParam;

  if l_HaveParam then
  begin
   if f_CurContext.Code.Labels.IndexOf(l_Param) >= 0 then
   begin
    l_Fixed := True; // мы определились с первым параметром
    StateParam[1] := l_Param;
    l_NextParam;
   end;
  end;

  if l_HaveParam then
  begin
   if VarType(l_ParamValue) = varString then
   begin
    StateParam[2] := l_ParamValue;
    l_NextParam;
    l_Fixed := True;
   end
   else
    if l_Fixed then
     raise EFURQRunTimeError.Create(sWrongParams);
  end;

  if l_HaveParam then
  begin
   if VarType(l_ParamValue) <> varString then
    StateParam[3] := l_ParamValue
   else
    raise EFURQRunTimeError.Create(sWrongParams);
  end;
  State := csSave;
 end; // with
end;


procedure TFURQInterpreter.HandleTokens(aExpression: string);
var
 l_Delim: string;
 l_Str: string;
 l_Num: Integer;
 I: Integer;
 l_SubStr: string;
 l_CurNum: Integer;
 l_Eval: TfurqExprEvaluator;

 procedure AddSubstrToTokens;
 begin
  if l_SubStr <> '' then
  begin
   Inc(l_CurNum);
   f_CurContext.Variables['token'+IntToStr(l_CurNum)] := l_SubStr;
   l_SubStr := '';
  end;
 end;

begin
 l_Eval := TfurqExprEvaluator.Create(f_CurContext);
 try
  l_Eval.Source := Trim(aExpression);
  l_Str := EnsureString(l_Eval.ResultValue);
 finally
  l_Eval.Free;
 end;

 if l_Str = '' then
 begin
  f_CurContext.Variables['tokens_num'] := 0.0;
  Exit;
 end;

 l_Delim := EnsureString(f_CurContext.Variables['tokens_delim']);
 l_Num := Length(l_Str);
 if AnsiSameText(l_Delim, 'char') then
 begin
  for I := 1 to l_Num do
  begin
   l_SubStr := l_Str[I];
   f_CurContext.Variables['token'+IntToStr(I)] := l_SubStr;
  end;
  f_CurContext.Variables['tokens_num'] := VarAsType(l_Num, varDouble);
 end
 else
 begin
  l_CurNum := 0;
  l_SubStr := '';
  for I := 1 to l_Num do
  begin
   if Pos(l_Str[I], l_Delim) > 0 then
    AddSubstrToTokens
   else
    l_Substr := l_SubStr + l_Str[I];
  end;
  AddSubstrToTokens;
  f_CurContext.Variables['tokens_num'] := VarAsType(l_CurNum, varDouble);
 end;
end;

procedure TFURQInterpreter.IncLine;
begin
 Line := Line + 1;
end;

procedure TFURQInterpreter.InvMenuJump(aLabelIdx: Integer);
var
 l_AData: IFURQActionData;
begin
 l_AData := TFURQActionData.Create(aLabelIdx, nil, amNonFinal);
 DoAction(l_AData);
end;

procedure TFURQInterpreter.NotAvailableWhileMenuBuild;
begin
 if f_CurContext.ExecutionMode = emMenuBuild then
  raise EFURQRunTimeError.Create('Оператор нельзя использовать при построении меню!');
end;

procedure TFURQInterpreter.NotAvailableInEvents;
begin
 if f_CurContext.ExecutionMode = emEvent then
  raise EFURQRunTimeError.Create('Оператор нельзя использовать в событиях!');
end;

procedure TFURQInterpreter.ParseAssigment(aString: string; var theVarName, theExpression: string);
var
 l_Pos: Integer;
begin
 l_Pos := Pos('=', aString);
 if l_Pos > 0 then
 begin
  theVarName := Trim(Copy(aString, 1, l_Pos-1));
  CheckVarName(theVarName);
  theExpression := Trim(Copy(aString, l_Pos+1, MaxInt))
 end
 else
  raise EFURQExpressionError.CreateFmt(sIncorrectOperator, [aString]);
end;

procedure TFURQInterpreter.ParseOperators;
var
 l_SrcLine: string;
 
procedure GetSrcLine;
var
 l_Str: string;

 procedure SkipBlanks;
 begin
  while (not EOF) and (Trim(CurLine)='') do
   IncLine;
 end;

begin
 l_SrcLine := '';
 while not EOF do
 begin
  // пропускаем пустые строки
  SkipBlanks;
  if not EOF then
  begin
   l_Str := TrimLeft(CurLine);
   if l_SrcLine = '' then // это новая строка
   begin
    if AnsiStartsStr(':', l_Str) then // кажись, это метка. уходим на следующую строку...
    begin
     IncLine;
     Continue;
    end;
    if AnsiStartsStr('_', l_Str) then
    begin
     Delete(l_Str, 1, 1); // возможно, это просто артефакт от удалёния комментариев /* */
     // и надо проверить, что после удаления этой фигни не осталась пустая строка...
     if Trim(l_Str) = '' then
     begin
      IncLine;
      SkipBlanks;
      Continue;
     end;
    end;
    l_SrcLine := l_Str;
    IncLine;
   end
   else // это, возможно, дополнение предыдущей строки
   begin
    if not AnsiStartsStr('_', l_Str) then
     Break; // не, это какая-то другая строка. Ее будем смотреть потом.
    Delete(l_Str, 1, 1); // удалям символ подчеркивания
    l_SrcLine := l_SrcLine + l_Str; // и цепляем к результату то, что осталось
    IncLine;
   end;
  end;
 end;
end;

function ParseStringToOps(const aSrc: string): TFURQOperator;
var
 l_ResOp : TFURQOperator;
 l_Op    : TFURQOperator;
 l_Lexer : TfurqLexer;
 l_IFCount: Integer;
 l_Cond  : string;
 l_Then  : string;
 l_Else  : string;
 l_Start : Integer;
 l_IsFirstTokenInOperator: Boolean;
 l_IFDetected: Boolean;

 function GetSubstrBeforeToken: string;
 begin
  Result := Copy(aSrc, l_Start, l_Lexer.TokenStart-l_Start);
  l_Start := l_Lexer.TokenEnd;
 end;

 function GetSubstrAfterToken: string;
 begin
  Result := Copy(aSrc, l_Start, l_Lexer.TokenEnd-l_Start);
  l_Start := l_Lexer.TokenEnd;
 end;

 procedure AddOp(aOp: TFURQOperator);
 begin
  if l_ResOp = nil then
  begin
   l_Op := aOp;
   l_ResOp := aOp;
  end
  else
  begin
   l_Op.Next := aOp;
   l_Op := l_Op.Next;
  end;
 end;

 procedure AddOpStr(const aOpSrc: string);
 var
  l_OpSrc: string;
 begin
  l_OpSrc := TrimLeft(aOpSrc);
  if l_OpSrc <> '' then
   AddOp(TFURQOperator.Create(l_OpSrc));
 end;

begin
 Result := nil;
 if aSrc = '' then
  Exit;
 l_ResOp := nil;

 l_Lexer := TfurqLexer.Create;
 try
  l_Lexer.DetectStrings := False; // а иначе кавычки разбивают нафиг все
  l_Lexer.Source := aSrc;
  l_IFCount := 0;
  l_Start := 1;
  l_IsFirstTokenInOperator := True;
  l_IFDetected := False;
  while True do
  begin
   case l_Lexer.Token of
    etIF:
     begin
      if l_IsFirstTokenInOperator then
      begin
       if (l_IFCount = 0) then
       begin
        l_Cond := '';
        l_Then := '';
        l_Else := '';
        l_Start := l_Lexer.TokenEnd;
        l_IFDetected := True;
       end;
       Inc(l_IFCount);
      end;
     end;

    etThen:
     if l_IFDetected then
     begin
      if l_IFCount = 1 then
       l_Cond := GetSubstrBeforeToken;
      l_IsFirstTokenInOperator := True;
     end;

    etElse:
     if l_IFDetected then
     begin
      if l_IFCount = 1 then
      begin
       l_Then  := GetSubstrBeforeToken;
       l_Else  := Copy(aSrc, l_Lexer.TokenEnd, MaxInt);
       if l_Cond = '' then
        raise EFURQRunTimeError.Create(sIfWithoutThen);
       AddOp(TFURQCondition.Create(l_Cond, ParseStringToOps(l_Then), ParseStringToOps(l_Else)));
       Break;
      end;
      Dec(l_IFCount);
      l_IsFirstTokenInOperator := True;
     end;

    etAmpersand:
     begin
      if not l_IFDetected then
       AddOpStr(GetSubstrBeforeToken);
      l_IsFirstTokenInOperator := True;
     end;

    etEOF:
     begin
      if l_IFDetected then
      begin
       l_Then := GetSubstrAfterToken;
       if l_Cond = '' then
        raise EFURQRunTimeError.Create(sIfWithoutThen);
       AddOp(TFURQCondition.Create(l_Cond, ParseStringToOps(l_Then), nil));
      end
      else
       AddOpStr(GetSubstrAfterToken);
      Break;
     end;
    else
     l_IsFirstTokenInOperator := False;
   end; // case

   l_Lexer.NextToken;
  end;
 finally
  FreeAndNil(l_Lexer);
 end;

 Result := l_ResOp;
end;


begin
 f_CurContext.Stack.ClearOperators;
 GetSrcLine;
 if l_SrcLine <> '' then
 begin
  f_CurContext.Stack.Operators := ParseStringToOps(l_SrcLine);
  f_CurContext.Stack.CurOp := f_CurContext.Stack.Operators;
 end
 else
  f_CurContext.State := csEnd;
end;

function TFURQInterpreter.pm_GetCurLine: string;
begin
 if not EOF then
  Result := f_CurContext.Code.Source[Line]
 else
  Result := '';
end;

function TFURQInterpreter.pm_GetEOF: Boolean;
begin
 Result := (Line >= f_CurContext.Code.Source.Count);
end;

function TFURQInterpreter.pm_GetLine: Integer;
begin
 Result := f_CurContext.Stack.Line;
end;

procedure TFURQInterpreter.pm_SetLine(const Value: Integer);
begin
 f_CurContext.Stack.Line := Value;
end;

const
 smNumber   = 1;
 smString   = 2;
 smCharCode = 3;

function TFURQInterpreter.UnfoldSubst(const aString: string): string;
var
 l_CurPos, l_TempPos: Integer;
 l_Subst: string;
 l_SubMode: Byte;
 C: Char;
 l_InCount: Integer;
 l_Eval: TfurqExprEvaluator;
 l_CharCode: Integer;

 function GetChar(aIndex: Integer): Char;
 begin
  if aIndex > Length(aString) then
   Result := #0
  else
   Result := aString[aIndex];
 end;

begin
 Result := '';
 l_Eval := nil;
 l_CurPos := 1;

 try
  while True do
  begin
   l_TempPos := PosEx('#', aString, l_CurPos);
   if l_TempPos > 0 then
   begin
    Result := Result + Copy(aString, l_CurPos, l_TempPos-l_CurPos);
    l_CurPos := l_TempPos + 1;
    case GetChar(l_CurPos) of
     '%':
      begin
       l_SubMode := smString;
       Inc(l_CurPos);
      end;
     '#':
      begin
       l_SubMode := smCharCode;
       Inc(l_CurPos);
      end;
    else
     l_SubMode := smNumber;
    end;
    // ищем закрывающую скобку
    l_Subst := '';
    l_InCount := 0;
    C := GetChar(l_CurPos);
    while C <> #0 do
    begin
     case C of
      '$' :
       begin
        if l_InCount = 0 then
         Break
        else
         Dec(l_InCount);
       end;
      '#': Inc(l_InCount);
     end;
     l_Subst := l_Subst + C;
     Inc(l_CurPos);
     C := GetChar(l_CurPos);
    end;
    if C = #0 then
     raise EFURQRunTimeError.Create(sSubstNotClosed);
    Inc(l_CurPos);

    l_Subst := UnfoldSubst(l_Subst);

    if (l_SubMode = smNumber) and (l_Subst = '') then
     Result := Result + ' '
    else
    if (l_SubMode = smNumber) and (l_Subst = '/') then
     Result := Result + #13#10
    else
    begin
     if l_Eval = nil then
      l_Eval := TfurqExprEvaluator.Create(f_CurContext);

     l_Eval.Source := l_Subst;
     case l_SubMode of
      smNumber  : Result := Result + f_CurContext.FormatNumber(EnsureReal(l_Eval.ResultValue));
      smString  : Result := Result + EnsureString(l_Eval.ResultValue);
      smCharCode:
       begin
        l_CharCode := Round(EnsureReal(l_Eval.ResultValue));
        l_CharCode := l_CharCode and $FF;
        Result := Result + Char(l_CharCode);
       end;
     end;
    end;
   end
   else
   begin
    Result := Result + Copy(aString, l_CurPos, MaxInt);
    Break;
   end;
  end;
 finally
  FreeAndNil(l_Eval);
 end;
end;

function TFURQInterpreter.ValidVarName(aVarName: string): Boolean;
var
 I: Integer;
begin
 Result := True;
 if aVarName <> '' then
 begin
  if aVarName[1] in cIdentStartSet then
  begin
   for I := 2 to Length(aVarName) do
    if (not (aVarName[I] in cIdentMidSet)) and (aVarName[I] <> ' ') then
    begin
     Result := False;
     Break;
    end;
  end
  else
   Result := False;
 end;
end;

initialization
 DecimalSeparator := '.';
end.
