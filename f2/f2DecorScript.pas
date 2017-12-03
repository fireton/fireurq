unit f2DecorScript;

interface
uses
 Classes,
 d2dUtils;

type
 Tf2DSOperatorType = (otMove, otColor, otRotate, otRotateSpeed, otScale, otPause, otRestart, otDelete);

 If2DSParameter = interface
  ['{2C80B9E2-0C5B-445C-AD71-B05264EFEF88}']
  function GetValue: Double;
  procedure Save(const aFiler: Td2dFiler);
 end;

 If2DSOperator = interface
  ['{EFD68E7C-BBAB-461F-AE13-78C74BBC742A}']
  function pm_GetIsAsync: Boolean;
  function pm_GetIsRelative: Boolean;
  function pm_GetOpType: Tf2DSOperatorType;
  function pm_GetParamCount: Integer;
  function pm_GetParams(Index: Integer): If2DSParameter;
  procedure Save(const aFiler: Td2dFiler);
  property IsAsync: Boolean read pm_GetIsAsync;
  property IsRelative: Boolean read pm_GetIsRelative;
  property OpType: Tf2DSOperatorType read pm_GetOpType;
  property ParamCount: Integer read pm_GetParamCount;
  property Params[Index: Integer]: If2DSParameter read pm_GetParams;
 end;

 Tf2DSParamPrim = class(TInterfacedObject, If2DSParameter)
 protected
  function GetValue: Double; virtual; abstract;
  procedure Save(const aFiler: Td2dFiler); virtual; abstract;
 end;

 Tf2SimpleParam = class(Tf2DSParamPrim)
 private
  f_Value: Double;
 protected
  function GetValue: Double; override;
  procedure Save(const aFiler: Td2dFiler); override;
 public
  constructor Create(const aValue: Double);
  constructor Load(const aFiler: Td2dFiler);
 end;

 Tf2RandomParam = class(Tf2DSParamPrim)
 private
  f_Min: Double;
  f_Max: Double;
 protected
  function GetValue: Double; override;
  procedure Save(const aFiler: Td2dFiler); override;
 public
  constructor Create(const aMin, aMax: Double);
  constructor Load(const aFiler: Td2dFiler);
 end;

 Tf2DSOperator = class(TInterfacedObject, If2DSOperator)
 private
  f_IsAsync: Boolean;
  f_IsRelative: Boolean;
  f_OpType: Tf2DSOperatorType;
  f_ParamList: IInterfaceList;
 private
  function pm_GetIsAsync: Boolean;
  function pm_GetIsRelative: Boolean;
  function pm_GetOpType: Tf2DSOperatorType;
  function pm_GetParamCount: Integer;
  function pm_GetParams(Index: Integer): If2DSParameter;
 public
  constructor Create(const aOpType: Tf2DSOperatorType; const aIsRelative: Boolean = False; const aIsAsync: Boolean =
      False);
  constructor Load(const aFiler: Td2dFiler);
  procedure AddParam(const aParam: If2DSParameter);
  procedure Save(const aFiler: Td2dFiler);
  property IsAsync: Boolean read pm_GetIsAsync write f_IsAsync;
  property IsRelative: Boolean read pm_GetIsRelative;
  property OpType: Tf2DSOperatorType read pm_GetOpType;
  property ParamCount: Integer read pm_GetParamCount;
  property Params[Index: Integer]: If2DSParameter read pm_GetParams;
 end;

function CompileDSOperators(const aSource: string): IInterfaceList;

procedure SaveDSOperators(const aList: IInterfaceList; const aFiler: Td2dFiler);
function  LoadDSOperators(const aFiler: Td2dFiler): IInterfaceList;

implementation
uses
 SysUtils,

 furqTypes,
 furqExprEval;

const
 sDSCommandExpectedError  = '[DS] Ожидалась команда (позиция %d)';
 sDSUnknownCommandError   = '[DS] Неизвестная команда, "%s"';
 sDSParameterError        = '[DS] Ошибка в параметре (позиция %d)';
 sDSParametersNumberError = '[DS] Неверное число параметров (позиция %d)';
 sDSMinMaxError           = '[DS] Минимальное значение должно быть меньше максимального (позиция %d)';

 ptSimple = 1;
 ptRandom = 2;

procedure SaveDSParameters(const aParams: IInterfaceList; const aFiler: Td2dFiler);
var
 I: Integer;
begin
 aFiler.WriteInteger(aParams.Count);
 for I := 0 to aParams.Count - 1 do
  (aParams.Items[I] as If2DSParameter).Save(aFiler);
end;

function LoadDSParameters(const aFiler: Td2dFiler): IInterfaceList;
var
 I, l_Count: Integer;
 l_Param: If2DSParameter;
 l_Type : Byte;
begin
 Result := TInterfaceList.Create;
 l_Count := aFiler.ReadInteger;
 for I := 1 to l_Count do
 begin
  l_Type := aFiler.ReadByte;
  case l_Type of
   ptSimple: l_Param := Tf2SimpleParam.Load(aFiler);
   ptRandom: l_Param := Tf2RandomParam.Load(aFiler);
  end;
  Result.Add(l_Param);
 end;
end;

procedure SaveDSOperators(const aList: IInterfaceList; const aFiler: Td2dFiler);
var
 I: Integer;
begin
 aFiler.WriteInteger(aList.Count);
 for I := 0 to aList.Count - 1 do
  (aList.Items[I] as If2DSOperator).Save(aFiler);
end;

function  LoadDSOperators(const aFiler: Td2dFiler): IInterfaceList;
var
 I, l_Count: Integer;
 l_Op: If2DSOperator;
begin
 Result := TInterfaceList.Create;
 l_Count := aFiler.ReadInteger;
 for I := 1 to l_Count do
 begin
  l_Op := Tf2DSOperator.Load(aFiler);
  Result.Add(l_Op);
 end;
end;

function CompileDSOperators(const aSource: string): IInterfaceList;
var
 l_Lexer: TfurqLexer;
 l_IsRelative: Boolean;
 l_IsAsync : Boolean;
 l_OpType: Tf2DSOperatorType;
 l_Cmd : string;
 l_OpObj: Tf2DSOperator;
 l_OpI  : If2DSOperator;
 l_Param : If2DSParameter;
 l_Min, l_Max: Double;

 procedure AssertToken(aToken: TfurqToken);
 begin
  if l_Lexer.Token <> aToken then
   raise EFURQRunTimeError.CreateFmt(sDSParameterError, [l_Lexer.TokenStart]);
 end;

 procedure AssertParamNumber(const aNumbers: array of integer);
 var
  I: Integer;
 begin
  for I := Low(aNumbers) to High(aNumbers) do
   if l_OpObj.ParamCount = aNumbers[I] then
    Exit;
  raise EFURQRunTimeError.CreateFmt(sDSParametersNumberError, [l_Lexer.TokenStart]);
 end;

 function LexNumber: Double;
 begin
  if l_Lexer.Token = etMinus then
  begin
   l_Lexer.NextToken;
   AssertToken(etNumber);
   Result := -l_Lexer.TokenValue;
  end
  else
  begin
   AssertToken(etNumber);
   Result := l_Lexer.TokenValue;
  end;
 end;

begin
 Result := nil;
 l_Lexer := TfurqLexer.Create;
 try
  l_Lexer.AllowSpacesInIdent := False;
  l_Lexer.Source := aSource;
  while l_Lexer.Token <> etEOF do
  begin
   l_IsRelative := False;
   l_IsAsync    := False;
   if l_Lexer.Token <> etIdentifier then
    raise EFURQRunTimeError.CreateFmt(sDSCommandExpectedError, [l_Lexer.TokenStart]);
   // пытаемся понять, что за команда
   l_Cmd := AnsiLowerCase(l_Lexer.TokenValue);
   if (Length(l_Cmd) > 4) or (Length(l_Cmd) < 2) then
    raise EFURQRunTimeError.CreateFmt(sDSUnknownCommandError, [l_Cmd]); // не бывает таких команд
   if (Length(l_Cmd) = 4) then
   begin
    if l_Cmd[4] = 'x' then
    begin
     l_IsAsync := True;
     SetLength(l_Cmd, 3);
    end
    else
     raise EFURQRunTimeError.CreateFmt(sDSUnknownCommandError, [l_Cmd]); // последней буквой может быть только "x"
   end;

   // начинаем опознание
   if l_Cmd = 'mov' then
    l_OpType := otMove
   else
   if l_Cmd = 'mvr' then
   begin
    l_OpType := otMove;
    l_IsRelative := True;
   end
   else
   if l_Cmd = 'rot' then
   begin
    l_OpType := otRotate;
    l_IsRelative := True;
   end
   else
   if l_Cmd = 'ang' then
   begin
    l_OpType := otRotate;
   end
   else
   if l_Cmd = 'col' then
    l_OpType := otColor
   else
   if l_Cmd = 'pau' then
    l_OpType := otPause
   else
   if l_Cmd = 'rsp' then
   begin
    l_OpType := otRotateSpeed;
    l_IsAsync := True;
   end
   else
   if l_Cmd = 'scl' then
   begin
    l_OpType := otScale;
    //l_IsAsync := True;
   end
   else
   if l_Cmd = 'rst' then
   begin
    l_OpType := otRestart;
    l_IsAsync := True;
   end
   else
   if l_Cmd = 'del' then
   begin
    l_OpType := otDelete;
    l_IsAsync := True;
   end
   else
    raise EFURQRunTimeError.CreateFmt(sDSUnknownCommandError, [l_Cmd]); // не бывает таких команд
   l_OpObj := Tf2DSOperator.Create(l_OpType, l_IsRelative, l_IsAsync);
   l_OpI := l_OpObj; // чтоб грохнулось в случае чего

   // начинаем парсить параметры
   while True do
   begin
    l_Lexer.NextToken;
    if l_Lexer.Token in [etDivide, etEOF] then
     Break;
    if (l_OpObj.ParamCount > 0) then
    begin
     AssertToken(etComma);
     l_Lexer.NextToken; // если это не первый параметр, то должна быть запятая
    end;
    if (l_Lexer.Token = etNumber) or (l_Lexer.Token = etMinus) then
    begin
     // это обычный параметр
     l_Param := Tf2SimpleParam.Create(LexNumber);
    end
    else
     if (l_Lexer.Token = etIdentifier) and (AnsiLowerCase(l_Lexer.TokenValue) = 'r') then
     begin
      // парсим случайный параметр
      l_Lexer.NextToken;
      AssertToken(etLBrasket);
      l_Lexer.NextToken;
      l_Min := LexNumber;
      l_Lexer.NextToken;
      AssertToken(etComma);
      l_Lexer.NextToken;
      l_Max := LexNumber;
      l_Lexer.NextToken;
      AssertToken(etRBrasket);
      if l_Min >= l_Max then
       raise EFURQRunTimeError.CreateFmt(sDSMinMaxError, [l_Lexer.TokenStart]);
      l_Param := Tf2RandomParam.Create(l_Min, l_Max);
     end
     else
      raise EFURQRunTimeError.CreateFmt(sDSParameterError, [l_Lexer.TokenStart]);
    l_OpObj.AddParam(l_Param);
   end;

   // контролируем число параметров
   case l_OpType of
    otMove        :
     begin
      AssertParamNumber([2,3]);
      if l_OpObj.ParamCount = 2 then  // если просто присваивается положение, то команда асинхронна (ждать её выполнения не надо)
       l_OpObj.IsAsync := True;       // иначе - надо (если не было "х" на конце команды)
     end;
    otColor       :
     begin
      AssertParamNumber([1, 2, 4, 5]);
      if (l_OpObj.ParamCount = 1) or (l_OpObj.ParamCount = 4) then
       l_OpObj.IsAsync := True;
     end;
    otRotate      :
     begin
      if not l_IsRelative then
       AssertParamNumber([1])
      else
       AssertParamNumber([1,2]);
      if l_OpObj.ParamCount = 1 then
       l_OpObj.IsAsync := True;
     end;
    otRotateSpeed : AssertParamNumber([1]);
    otScale       :
     begin
      AssertParamNumber([1,2]);
      if l_OpObj.ParamCount = 1 then
       l_OpObj.IsAsync := True;
     end;
    otPause       : AssertParamNumber([1]);
    otRestart,    
    otDelete      : AssertParamNumber([0]);
   end;

   // добавляем в список
   if Result = nil then
    Result := TInterfaceList.Create;
   Result.Add(l_OpI);
   l_OpI := nil;
   l_Lexer.NextToken;
  end;
 finally
  FreeAndNil(l_Lexer);
 end;
end;

constructor Tf2SimpleParam.Create(const aValue: Double);
begin
 inherited Create;
 f_Value := aValue;
end;

constructor Tf2SimpleParam.Load(const aFiler: Td2dFiler);
begin
 inherited Create;
 f_Value := aFiler.ReadDouble;
end;

function Tf2SimpleParam.GetValue: Double;
begin
 result := f_Value;
end;

procedure Tf2SimpleParam.Save(const aFiler: Td2dFiler);
begin
 aFiler.WriteByte(ptSimple);
 aFiler.WriteDouble(f_Value);
end;

constructor Tf2RandomParam.Create(const aMin, aMax: Double);
begin
 inherited Create;
 f_Min := aMin;
 f_Max := aMax;
end;

constructor Tf2RandomParam.Load(const aFiler: Td2dFiler);
begin
 inherited Create;
 f_Min := aFiler.ReadDouble;
 f_Max := aFiler.ReadDouble;
end;

function Tf2RandomParam.GetValue: Double;
begin
 Result := Random * (f_Max - f_Min) + f_Min;
end;

procedure Tf2RandomParam.Save(const aFiler: Td2dFiler);
begin
 aFiler.WriteByte(ptRandom);
 aFiler.WriteDouble(f_Min);
 aFiler.WriteDouble(f_Max);
end;

constructor Tf2DSOperator.Create(const aOpType    : Tf2DSOperatorType;
                                 const aIsRelative: Boolean = False;
                                 const aIsAsync   : Boolean = False);
begin
 inherited Create;
 f_OpType := aOpType;
 f_IsAsync := aIsAsync;
 f_IsRelative := aIsRelative;
 f_ParamList := TInterfaceList.Create;
end;

constructor Tf2DSOperator.Load(const aFiler: Td2dFiler);
begin
 inherited Create;
 with aFiler do
 begin
  f_OpType := Tf2DSOperatorType(ReadByte);
  f_IsAsync := ReadBoolean;
  f_IsRelative := ReadBoolean;
  f_ParamList := LoadDSParameters(aFiler);
 end;
end;

procedure Tf2DSOperator.AddParam(const aParam: If2DSParameter);
begin
 f_ParamList.Add(aParam)
end;

function Tf2DSOperator.pm_GetIsAsync: Boolean;
begin
 Result := f_IsAsync;
end;

function Tf2DSOperator.pm_GetIsRelative: Boolean;
begin
 Result := f_IsRelative;
end;

function Tf2DSOperator.pm_GetOpType: Tf2DSOperatorType;
begin
 Result := f_OpType;
end;

function Tf2DSOperator.pm_GetParamCount: Integer;
begin
 Result := f_ParamList.Count;
end;

function Tf2DSOperator.pm_GetParams(Index: Integer): If2DSParameter;
begin
 Result := f_ParamList[Index] as If2DSParameter;
end;

procedure Tf2DSOperator.Save(const aFiler: Td2dFiler);
begin
 with aFiler do
 begin
  WriteByte(Byte(f_OpType));
  WriteBoolean(IsAsync);
  WriteBoolean(IsRelative);
  SaveDSParameters(f_ParamList, aFiler);
 end; 
end;

end.
