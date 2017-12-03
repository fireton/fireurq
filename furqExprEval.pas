unit furqExprEval;

interface
uses
 Variants,
 furqTypes,
 furqContext,

 JclStringLists;

type
 TfurqToken = (
  // сущности языка
  etIdentifier, etNumber, etString,

  // действия (арифметические и логические)
  etPlus, etMinus, etDivide, etMultiply,
  etAnd, etOr, etNot,

  // операции сравнения
  etEqual, etNotEqual, etLesser, etLesserOrEqual, etGreater, etGreaterOrEqual, etSimular,

  // структурные токены
  etIF, etThen, etElse,

  // служебные
  etLBrasket, etRBrasket, etAmpersand, etComma, etSymbol, etEOF,

  // особый пользовательский токен
  etCustom
 );

 TfurqLexer = class(TObject)
 private
  f_AllowSpacesInIdent: Boolean;
  f_DetectStrings: Boolean;
  f_Pos: Integer;
  f_Source: string;
  f_Token: TfurqToken;
  f_TokenEnd: Integer;
  f_TokenStart: Integer;
  f_TokenValue: Variant;
  function pm_GetCurChar: Char;
  procedure pm_SetSource(const Value: string);
 protected
  property CurChar: Char read pm_GetCurChar;
 public
  constructor Create;
  procedure NextToken(aCustomCharset: TCharSet = []);
  procedure Reset;
  procedure SetSourceCustom(const aSource: string; aCustomCharset: TCharset);
  property AllowSpacesInIdent: Boolean read f_AllowSpacesInIdent write f_AllowSpacesInIdent;
  property DetectStrings: Boolean read f_DetectStrings write f_DetectStrings;
  property Source: string read f_Source write pm_SetSource;
  property Token: TfurqToken read f_Token;
  property TokenEnd: Integer read f_TokenEnd;
  property TokenStart: Integer read f_TokenStart;
  property TokenValue: Variant read f_TokenValue;
 end;

 IfurqEvalNode = interface(IInterface)
 ['{CA576088-5564-4C13-9333-578C10741583}']
  function Evaluate: Variant;
 end;

 TfurqEvalNode = class(TInterfacedObject, IfurqEvalNode)
 public
  function Evaluate: Variant; virtual; abstract;
 end;

 TfurqUnaryEvalNode = class(TfurqEvalNode)
 protected
  f_Value: IfurqEvalNode;
 public
  constructor Create(aValue: IfurqEvalNode);
  destructor Destroy; override;
 end;

 TfurqBinaryEvalNode = class(TfurqEvalNode)
 protected
  f_First: IfurqEvalNode;
  f_Second: IfurqEvalNode;
 public
  constructor Create(aFirst, aSecond: IfurqEvalNode);
  destructor Destroy; override;
 end;

 TfurqConstEvalNode = class(TfurqEvalNode)
 private
  f_Value: Variant;
 public
  constructor Create(const aValue: Variant);
  function Evaluate: Variant; override;
 end;

 TfurqNegateEvalNode = class(TfurqUnaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqNotEvalNode = class(TfurqUnaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqSummaEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqSubtractEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqMultiplyEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqDivideEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqOrEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqAndEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqExprEvaluator = class(TObject)
 private
  f_Context: TfurqContext;
  f_Expression: IfurqEvalNode;
  f_Lexer: TfurqLexer;
  function CompileFactor: TfurqEvalNode;
  function CompileLevel0(const aSkip: Boolean): TfurqEvalNode;
  function CompileLevel1(const aSkip: Boolean): TfurqEvalNode;
  function CompileLevel2(const aSkip: Boolean): TfurqEvalNode;
  function CompileLevel3(const aSkip: Boolean): TfurqEvalNode;
  function CompileLevel4(const aSkip: Boolean): TfurqEvalNode;
  function CompileLevel5(const aSkip: Boolean): TfurqEvalNode;
  procedure CompileSource;
  function GetIdentifierValue(aIdentName: string): Variant;
  function GetInventoryAmount(aName: string; anAmount: Extended): Extended;
  function pm_GetResultValue: Variant;
  function pm_GetSource: string;
  procedure pm_SetSource(const Value: string);
 public
  constructor Create(aContext: TFURQContext);
  destructor Destroy; override;
  property ResultValue: Variant read pm_GetResultValue;
  property Source: string read pm_GetSource write pm_SetSource;
 end;

 TfurqEqualEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqLesserEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqLesserOrEqualEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqGreaterEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqGreaterOrEqualEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 TfurqNotEqualEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

 EFURQExpressionError = class(EFURQRunTimeError);

 TfurqSimularEvalNode = class(TfurqBinaryEvalNode)
 public
  function Evaluate: Variant; override;
 end;

type
 TEvalSet = set of Byte;

function ParseAndEvalToArray(const aContext: TFURQContext; const aSource: string; aToEval: TEvalSet): IJclStringList;

implementation
uses
 Windows,
 SysUtils,
 StrUtils,
 JclStrings
 ;

type
 TKeywordRec = record
  rWord: string;
  rToken: TfurqToken;
 end;

const
 ki_And  = 1;
 ki_Or   = 2;
 ki_Not  = 3;
 ki_IF   = 4;
 ki_THEN = 5;
 ki_ELSE = 6;

 cMaxKeywordIdx = ki_ELSE;

 cKeywordArray: array [ki_And..cMaxKeywordIdx] of TKeywordRec = (
  (rWord: 'and'; rToken: etAnd),
  (rWord: 'or'; rToken: etOr),
  (rWord: 'not'; rToken: etNot),
  (rWord: 'if';   rToken: etIF),
  (rWord: 'then'; rToken: etThen),
  (rWord: 'else'; rToken: etElse)
 );

const
 sOpenParenthis = 'незакрытая скобка';
 sFactorNeeded  = 'ожидается константа или переменная';
 sSyntaxError   = 'неверный ситаксис';

const
 cWhitespaces = [#1..#32];
 cMaxIdentifierLen = 1024;

// Функция поднятия ошибки
procedure RaiseExprError(const aTxt: string);
begin
 raise EFURQExpressionError.CreateFmt('Ошибка в выражении: %s', [aTxt]);
end;

function ParseAndEvalToArray(const aContext: TFURQContext; const aSource: string; aToEval: TEvalSet): IJclStringList;
var
 l_Lex: TfurqLexer;
 l_Eval: TfurqExprEvaluator;
 l_StartPos: Integer;
 l_ParamNo: Byte;

 procedure GetNextParam;
 var
  l_Idx: Integer;
  l_Param: string;
 begin
  l_Param := Trim(Copy(aSource, l_StartPos, l_Lex.TokenStart - l_StartPos));
  l_Idx := Result.Add(l_Param);
  if (l_Param <> '') and (l_ParamNo in aToEval) then
  begin
   try
    l_Eval.Source := l_Param;
    Result.Variants[l_Idx] := l_Eval.ResultValue;
   except
    Result.Variants[l_Idx] := Null;
   end;
  end;
  l_StartPos := l_Lex.TokenEnd;
  Inc(l_ParamNo);
 end;

begin
 Result := JclStringList;
 l_ParamNo := 1;
 l_Eval := TfurqExprEvaluator.Create(aContext);
 try
  l_Lex := TfurqLexer.Create;
  try
   l_Lex.Source := aSource;
   l_StartPos := 1;
   while True do
   begin
    case l_Lex.Token of
     etComma: GetNextParam;
     etEOF  :
      begin
       GetNextParam;
       Break;
      end;
    end;
    l_Lex.NextToken;
   end;
  finally
   FreeAndNil(l_Lex);
  end;
 finally
  FreeAndNil(l_Eval);
 end;
end;

constructor TfurqLexer.Create;
begin
 inherited;
 f_DetectStrings := True;
 f_AllowSpacesInIdent := True;
end;

procedure TfurqLexer.NextToken(aCustomCharset: TCharSet = []);
var
 l_SSPos : Integer;
 l_SubStr: string;

 procedure LoadFromSet(aSet: TCharSet);
 begin
  while (CurChar in aSet) do
  begin
   Inc(l_SSPos);
   l_SubStr[l_SSPos] := CurChar;
   Inc(f_Pos);
   if (l_SSPos = cMaxIdentifierLen) then
    Break;
  end;
 end;

 function IsKeyword(const aStr: string): Boolean;
 var
  I: Integer;
  l_Str: string;
 begin
  Result := False;
  l_Str := LowerCase(aStr);
  for I := 1 to cMaxKeywordIdx do
   if l_Str = cKeywordArray[I].rWord then
   begin
    Result := True;
    Exit;
   end;
 end;

 procedure LoadIdent; // идентификаторы могут содержать пробелы и не должны путаться с ключевыми словами
 var
  l_LastIdStartPos: Integer;
  l_NextIdent: string;
  l_AdditionalPart: string;
 begin
  LoadFromSet(cIdentMidSet);
  SetLength(l_SubStr, l_SSPos);
  if IsKeyword(l_SubStr) then
   Exit;
  l_AdditionalPart := '';
  try
   while True do
   begin
    if (CurChar = ' ') and f_AllowSpacesInIdent then
    begin
     l_LastIdStartPos := f_Pos;
     while CurChar = ' ' do
     begin
      l_AdditionalPart := l_AdditionalPart + CurChar;
      Inc(f_Pos);
     end;
     if CurChar in cIdentStartSet then
     begin
      l_NextIdent := CurChar;
      Inc(f_Pos);
      while CurChar in cIdentMidSet do
      begin
       l_NextIdent := l_NextIdent + CurChar;
       Inc(f_Pos);
      end;
      if IsKeyword(l_NextIdent) then
      begin
       f_Pos := l_LastIdStartPos;
       Exit;
      end;
      l_AdditionalPart := l_AdditionalPart + l_NextIdent;
     end;
    end
    else
     Break;
   end;
  finally
   if l_AdditionalPart <> '' then
    l_SubStr := Trim(l_SubStr + l_AdditionalPart);
  end;
 end;

 procedure SetToken(aToken: TfurqToken);
 begin
  f_TokenStart := f_Pos;
  f_Token := aToken;
  Inc(f_Pos);
  f_TokenEnd := f_Pos;
 end;

 procedure SetTokenEnd(aToken: TfurqToken);
 begin
  f_Token := aToken;
  Inc(f_Pos);
  f_TokenEnd := f_Pos;
 end;

 procedure GetRegularToken;
 var
  I : Integer;
  l_Value: Longword;
  l_SubStrLow: string;
  l_QuoteChar: Char;
 begin
  f_Token := etSymbol;
  f_TokenValue := Unassigned;

  case CurChar of
   #0:
    begin
     f_Token := etEOF;
     f_TokenStart := f_Pos;
     f_TokenEnd := f_Pos;
     f_TokenValue := Unassigned;
    end;

   'a'..'z','A'..'Z','А'..'Я','а'..'я','_', 'Ё', 'ё':
    begin
     f_TokenStart := f_Pos;
     SetLength(l_SubStr, cMaxIdentifierLen);
     l_SubStr[1] := CurChar;
     l_SSPos := 1;
     Inc(f_Pos);
     LoadIdent;
     l_SubStrLow := LowerCase(l_SubStr);
     for I := 1 to cMaxKeywordIdx do
      if l_SubStrLow = cKeywordArray[I].rWord then
      begin
       f_Token := cKeywordArray[I].rToken;
       Break;
      end;
     if f_Token = etSymbol then
     begin
      f_Token := etIdentifier;
      f_TokenValue := l_SubStr;
     end;
     f_TokenEnd := f_Pos;
    end;

   '0'..'9':
    begin
     f_TokenStart := f_Pos;
     SetLength(l_SubStr, cMaxIdentifierLen);
     l_SubStr[1] := CurChar;
     l_SSPos := 1;
     Inc(f_Pos);
     LoadFromSet(['0'..'9']);
     if (UpCase(CurChar) = 'X') and (l_SSPos = 1) and (l_SubStr[1] = '0') then // это hex-значение
     begin
      l_SSPos := 0;
      Inc(f_Pos);
      LoadFromSet(['0'..'9', 'a'..'f', 'A'..'F']);
      SetLength(l_SubStr, l_SSPos);
      l_SubStr := '$'+l_SubStr;
      f_Token := etNumber;
      l_Value := StrToInt64Def(l_SubStr, 0);
      f_TokenValue := l_Value;
      f_TokenValue := VarAsType(f_TokenValue, varDouble);
     end
     else
     begin
      if CurChar = '.' then // у числа есть дробная часть
      begin
       Inc(l_SSPos);
       l_SubStr[l_SSPos] := CurChar;
       Inc(f_Pos);
       LoadFromSet(['0'..'9']);
      end;
      SetLength(l_SubStr, l_SSPos);
      f_Token := etNumber;
      f_TokenValue := StrToFloatDef(l_SubStr, 0.0);
     end;
     f_TokenEnd := f_Pos;
    end;

   '"', '''':
    begin
     if DetectStrings then
     begin
      l_QuoteChar := CurChar;
      f_TokenStart := f_Pos;
      l_SubStr := '';
      Inc(f_Pos);
      while not (CurChar in [l_QuoteChar, #0]) do
      begin
       l_SubStr := l_SubStr + CurChar;
       Inc(f_Pos);
      end;

      if CurChar <> #0 then
      begin
       Inc(f_Pos);
       f_Token := etString;
       f_TokenValue := l_SubStr;
      end
      else
       f_Token := etEOF;
      f_TokenEnd := f_Pos;
     end
     else
      SetToken(etSymbol);
    end;

   '*': SetToken(etMultiply);
   '/': SetToken(etDivide);
   '+': SetToken(etPlus);
   '-': SetToken(etMinus);
   '(': SetToken(etLBrasket);
   ')': SetToken(etRBrasket);
   '&': SetToken(etAmpersand);
   ',': SetToken(etComma);
   '<':
    begin
     f_TokenStart := f_Pos;
     Inc(f_Pos);
     case CurChar of
      '=': SetTokenEnd(etLesserOrEqual);
      '>': SetTokenEnd(etNotEqual);
      else
      begin
       f_Token := etLesser;
       f_TokenEnd := f_Pos;
      end;
     end;
    end;
   '>':
    begin
     f_TokenStart := f_Pos;
     Inc(f_Pos);
     if CurChar = '=' then
      SetTokenEnd(etGreaterOrEqual)
     else
     begin
      f_Token := etGreater;
      f_TokenEnd := f_Pos;
     end;
    end;
   '=':
    begin
     f_TokenStart := f_Pos;
     Inc(f_Pos);
     if CurChar = '=' then
      SetTokenEnd(etSimular)
     else
     begin
      f_Token := etEqual;
      f_TokenEnd := f_Pos;
     end;
    end;
   else
    SetToken(etSymbol);
  end;
 end;

 procedure GetCustomToken;
 begin
  if CurChar in aCustomCharset then
  begin
   f_TokenStart := f_Pos;
   SetLength(l_SubStr, cMaxIdentifierLen);
   l_SubStr[1] := CurChar;
   l_SSPos := 1;
   Inc(f_Pos);
   LoadFromSet(aCustomCharset);
   SetLength(l_SubStr, l_SSPos);
   f_Token := etCustom;
   f_TokenValue := l_SubStr;
   f_TokenEnd := f_Pos;
  end
  else
   GetRegularToken;
 end;

begin
 while CurChar in cWhitespaces do
  Inc(f_Pos);
 if aCustomCharset <> [] then
  GetCustomToken
 else
  GetRegularToken;
end;

function TfurqLexer.pm_GetCurChar: Char;
begin
 if f_Pos <= Length(f_Source) then
  Result := f_Source[f_Pos]
 else
  Result := #0;
end;

procedure TfurqLexer.pm_SetSource(const Value: string);
begin
 f_Source := Value;
 Reset;
end;

procedure TfurqLexer.Reset;
begin
 f_Pos := 1;
 NextToken;
end;

procedure TfurqLexer.SetSourceCustom(const aSource: string; aCustomCharset: TCharset);
begin
 f_Source := aSource;
 f_Pos := 1;
 NextToken(aCustomCharset);
end;

constructor TfurqUnaryEvalNode.Create(aValue: IfurqEvalNode);
begin
 inherited Create;
 f_Value := aValue;
end;

destructor TfurqUnaryEvalNode.Destroy;
begin
 f_Value := nil;
 inherited;
end;

constructor TfurqBinaryEvalNode.Create(aFirst, aSecond: IfurqEvalNode);
begin
 inherited Create;
 f_First := aFirst;
 f_Second := aSecond;                 
end;

destructor TfurqBinaryEvalNode.Destroy;
begin
 f_First := nil;
 f_Second := nil;
 inherited;
end;

constructor TfurqConstEvalNode.Create(const aValue: Variant);
begin
 inherited Create;
 f_Value := aValue;
end;

function TfurqConstEvalNode.Evaluate: Variant;
begin
 Result := f_Value;
end;

function TfurqNegateEvalNode.Evaluate: Variant;
begin
 Result := - EnsureReal(f_Value.Evaluate);
end;

function TfurqNotEvalNode.Evaluate: Variant;
var
 l_Val: Extended;
begin
 l_Val := EnsureReal(f_Value.Evaluate);
 if l_Val <> 0 then
  Result := 0.0
 else
  Result := 1.0;
end;

function TfurqSummaEvalNode.Evaluate: Variant;
var
 l_V1, l_V2: Variant;
begin
 l_V1 := f_First.Evaluate;
 l_V2 := f_Second.Evaluate;
 if (VarType(l_V1) = varString) and (VarType(l_V2) = varString) then
  Result := EnsureString(l_V1) + EnsureString(l_V2)
 else
  Result := EnsureReal(l_V1) + EnsureReal(l_V2);
end;

function TfurqSubtractEvalNode.Evaluate: Variant;
begin
 Result := EnsureReal(f_First.Evaluate) - EnsureReal(f_Second.Evaluate);
end;

function TfurqMultiplyEvalNode.Evaluate: Variant;
begin
 Result := EnsureReal(f_First.Evaluate) * EnsureReal(f_Second.Evaluate);
end;

function TfurqDivideEvalNode.Evaluate: Variant;
begin
 Result := EnsureReal(f_First.Evaluate) / EnsureReal(f_Second.Evaluate);
end;

function TfurqOrEvalNode.Evaluate: Variant;
var
 l_V1, l_V2: Extended;
begin
 l_V1 := EnsureReal(f_First.Evaluate);
 l_V2 := EnsureReal(f_Second.Evaluate);
 if (l_V1 <> 0.0) or (l_V2 <> 0.0) then
  Result := 1.0
 else
  Result := 0.0;
end;

function TfurqAndEvalNode.Evaluate: Variant;
var
 l_V1, l_V2: Extended;
begin
 l_V1 := EnsureReal(f_First.Evaluate);
 l_V2 := EnsureReal(f_Second.Evaluate);
 if (l_V1 <> 0.0) and (l_V2 <> 0.0) then
  Result := 1.0
 else
  Result := 0.0;
end;

constructor TfurqExprEvaluator.Create(aContext: TFURQContext);
begin
 inherited Create;
 f_Context := aContext;
 f_Lexer := TfurqLexer.Create;
end;

destructor TfurqExprEvaluator.Destroy;
begin
 FreeAndNil(f_Lexer);
 f_Expression := nil;
 inherited;
end;

function TfurqExprEvaluator.CompileFactor: TfurqEvalNode;
var
 l_NeedDoNext: Boolean;
 l_Val: Extended;
begin
 Result := nil;
 l_NeedDoNext := True;
 // наивысший приоритет - константы, переменные и скобки
 case f_Lexer.Token of
  etIdentifier       : Result := TfurqConstEvalNode.Create(GetIdentifierValue(f_Lexer.f_TokenValue));
  etNumber, etString :
   begin
    if f_Lexer.Token = etNumber then
    begin
     l_Val := f_Lexer.f_TokenValue;
     f_Lexer.NextToken;
     if f_Lexer.Token = etIdentifier then // это попытка опросить инвентарь
     begin
      Result := TfurqConstEvalNode.Create(GetInventoryAmount(f_Lexer.TokenValue, l_Val));
     end
     else // не, это просто число
     begin
      Result := TfurqConstEvalNode.Create(l_Val);
      l_NeedDoNext := False; // мы уже переместились на шаг вперед
     end;
    end
    else
     Result := TfurqConstEvalNode.Create(f_Lexer.f_TokenValue);
   end;
  etLBrasket :
   begin
    Result := CompileLevel0(True);
    if f_Lexer.Token <> etRBrasket then
     RaiseExprError(sOpenParenthis);
   end;
 else
  RaiseExprError(sFactorNeeded);
 end;
 if l_NeedDoNext then
  f_Lexer.NextToken;
end;

function TfurqExprEvaluator.CompileLevel0(const aSkip: Boolean): TfurqEvalNode;
begin
 // уровень низшего приоритета, OR
 Result := CompileLevel1(aSkip);

 while True do
 begin
  case f_Lexer.Token of
   etOr  : Result := TfurqOrEvalNode.Create(Result, CompileLevel1(True));
  else
   Break;
  end;
 end;
end;

function TfurqExprEvaluator.CompileLevel1(const aSkip: Boolean): TfurqEvalNode;
begin
 // уровень  низкого приоритета, AND
 Result := CompileLevel2(aSkip);

 while True do
 begin
  case f_Lexer.Token of
   etAnd : Result := TfurqAndEvalNode.Create(Result, CompileLevel2(True));
  else
   Break;
  end;
 end;
end;

function TfurqExprEvaluator.CompileLevel2(const aSkip: Boolean): TfurqEvalNode;
begin
 // уровень низкого приоритета, операции сравнения
 Result := CompileLevel3(aSkip);

 while True do
 begin
  case f_Lexer.Token of
   etEqual           : Result := TfurqEqualEvalNode.Create(Result, CompileLevel3(True));
   etNotEqual        : Result := TfurqNotEqualEvalNode.Create(Result, CompileLevel3(True));
   etSimular         : Result := TfurqSimularEvalNode.Create(Result, CompileLevel3(True));
   etGreater         : Result := TfurqGreaterEvalNode.Create(Result, CompileLevel3(True));
   etLesser          : Result := TfurqLesserEvalNode.Create(Result, CompileLevel3(True));
   etGreaterOrEqual  : Result := TfurqGreaterOrEqualEvalNode.Create(Result, CompileLevel3(True));
   etLesserOrEqual   : Result := TfurqLesserOrEqualEvalNode.Create(Result, CompileLevel3(True));
  else
   Break;
  end;
 end;
end;

function TfurqExprEvaluator.CompileLevel3(const aSkip: Boolean): TfurqEvalNode;
begin
 // уровень низкого приоритета, сложение и вычитание
 Result := CompileLevel4(aSkip);

 while True do
 begin
  case f_Lexer.Token of
   etPlus            : Result := TfurqSummaEvalNode.Create(Result, CompileLevel4(True));
   etMinus           : Result := TfurqSubtractEvalNode.Create(Result, CompileLevel4(True));
  else
   Break;
  end;
 end;
end;

function TfurqExprEvaluator.CompileLevel4(const aSkip: Boolean): TfurqEvalNode;
begin
 // уровень среднего приоритета, умножение и деление
 Result := CompileLevel5(aSkip);

 while True do
 begin
  case f_Lexer.Token of
   etMultiply : Result := TfurqMultiplyEvalNode.Create(Result, CompileLevel5(True));
   etDivide   : Result := TfurqDivideEvalNode.Create(Result, CompileLevel5(True));
  else
   Break;
  end;
 end;
end;

function TfurqExprEvaluator.CompileLevel5(const aSkip: Boolean): TfurqEvalNode;
begin
 // уровень высокого приоритета, унарные операции
 if aSkip then
  f_Lexer.NextToken;

 case f_Lexer.Token of
  etPlus       : Result := CompileLevel5(True); // унарный плюс - нифига не значит
  etMinus      : Result := TfurqNegateEvalNode.Create(CompileLevel5(True)); // унарный минус
  etNot        : Result := TfurqNotEvalNode.Create(CompileLevel5(True)); // операция NOT
 else
  Result := CompileFactor;
 end;
end;

procedure TfurqExprEvaluator.CompileSource;
begin
 f_Expression := nil;
 try
  f_Expression := CompileLevel0(False);
 except
  f_Expression := nil;
  raise;
 end;
end;

function TfurqExprEvaluator.GetIdentifierValue(aIdentName: string): Variant;
var
 l_Temp: string;
 l_Range: Integer;
begin
 if AnsiStartsText('rnd', aIdentName) then // кажется, это запрос случайного числа
 begin
  l_Temp := Copy(aIdentName, 4, MaxInt);
  if l_Temp <> '' then
  begin
   l_Range := StrToIntDef(l_Temp, 0);
   if l_Range > 0 then // это рандом с диапазоном
   begin
    Result := Random(l_Range) + 1;
    Exit;
   end;
  end
  else
  begin
   Result := Random; // ага, от 0 до 1
   Exit;
  end;
 end;
 
 if f_Context.IsVariableExists(aIdentName) then
  Result := f_Context.Variables[aIdentName]
 else
 begin
  if f_Context.Inventory.IndexOf(aIdentName) <> -1 then
   Result := 1
  else
   Result := 0; 
 end;
end;

function TfurqExprEvaluator.GetInventoryAmount(aName: string; anAmount: Extended): Extended;
var
 l_Idx: Integer;
begin
 Result := 0.0;
 l_Idx := f_Context.Inventory.IndexOf(aName);
 if (l_Idx >= 0) and (f_Context.Inventory.Variants[l_Idx] >= anAmount) then
  Result := 1.0;
end;

function TfurqExprEvaluator.pm_GetResultValue: Variant;
begin
 if f_Expression <> nil then
  Result := f_Expression.Evaluate
 else
  Result := Unassigned; 
end;

function TfurqExprEvaluator.pm_GetSource: string;
begin
 Result := f_Lexer.Source;
end;

procedure TfurqExprEvaluator.pm_SetSource(const Value: string);
begin
 if f_Lexer.Source <> Value then
 begin
  f_Lexer.Source := Value;
  CompileSource;
 end;
end;

function TfurqEqualEvalNode.Evaluate: Variant;
var
 l_V1, l_V2: Variant;
begin
 l_V1 := f_First.Evaluate;
 l_V2 := f_Second.Evaluate;
 if VarType(l_V1) = varString then
 begin
  if EnsureString(l_V1) = EnsureString(l_V2) then
   Result := 1.0
  else
   Result := 0.0;
 end
 else
  if EnsureReal(l_V1) = EnsureReal(l_V2) then
   Result := 1.0
  else
   Result := 0.0;
end;

function TfurqLesserEvalNode.Evaluate: Variant;
begin
 if EnsureReal(f_First.Evaluate) < EnsureReal(f_Second.Evaluate) then
  Result := 1.0
 else
  Result := 0.0; 
end;

function TfurqLesserOrEqualEvalNode.Evaluate: Variant;
begin
 if EnsureReal(f_First.Evaluate) <= EnsureReal(f_Second.Evaluate) then
  Result := 1.0
 else
  Result := 0.0; 
end;

function TfurqGreaterEvalNode.Evaluate: Variant;
begin
 if EnsureReal(f_First.Evaluate) > EnsureReal(f_Second.Evaluate) then
  Result := 1.0
 else
  Result := 0.0; 
end;

function TfurqGreaterOrEqualEvalNode.Evaluate: Variant;
begin
 if EnsureReal(f_First.Evaluate) >= EnsureReal(f_Second.Evaluate) then
  Result := 1.0
 else
  Result := 0.0; 
end;

function TfurqNotEqualEvalNode.Evaluate: Variant;
var
 l_V1, l_V2: Variant;
begin
 l_V1 := f_First.Evaluate;
 l_V2 := f_Second.Evaluate;
 if VarType(l_V1) = varString then
 begin
  if EnsureString(l_V1) <> EnsureString(l_V2) then
   Result := 1.0
  else
   Result := 0.0;
 end
 else
  if EnsureReal(l_V1) <> EnsureReal(l_V2) then
   Result := 1.0
  else
   Result := 0.0;
end;

function TfurqSimularEvalNode.Evaluate: Variant;
var
 l_S1, l_S2: string;
begin
 l_S1 := AnsiUpperCase(EnsureString(f_First.Evaluate));
 l_S2 := AnsiUpperCase(EnsureString(f_Second.Evaluate));
 if l_S2 <> '' then
 begin
  if StrMatches(l_S2, l_S1) then
   Result := 1.0
  else
   Result := 0.0;
 end
 else
  if l_S1 = '' then // если поисковая строка пустая, то сравниваем с пустой строкой
   Result := 1.0
  else
   Result := 0.0;
end;

end.

