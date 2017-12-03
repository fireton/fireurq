unit f2Interpreter;

interface
uses
 furqBase,
 furqExprEval,
 f2Context,
 f2Decorators;

const
 cMaxDecorParams = 6;

type
 Tf2DecorParams = record
  rCount: Integer;
  rData : array[1..cMaxDecorParams] of Variant;
 end;

 Tf2DecorHandleProc = procedure(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams) of object;

type
 Tf2Interpreter = class(TFURQInterpreter)
 private
  procedure DH_Col(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
  procedure DH_Mov(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
  procedure DH_Rot(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
  procedure DH_Scl(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
  procedure DH_Scr(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
  procedure ParseDecorParams(aLexer: TfurqLexer; var theParams: Tf2DecorParams);
  procedure HandleDecorPrim(const aOperand: string; aProc: Tf2DecorHandleProc);
  procedure HandleDecorAdd(const aOperand: string);
  procedure HandleDecorMov(const aOperand: string);
  procedure HandleDecorCol(const aOperand: string);
  procedure HandleDecorDel(const aOperand: string);
  procedure HandleDecorRot(const aOperand: string);
  procedure HandleDecorScl(const aOperand: string);
  procedure HandleDecorScr(const aOperand: string);
  procedure HandleFadeMusic(const aOperand: string);
  procedure HandleImage(aArgs: string);
  procedure HandleVoice(aOperand: string);
  procedure HandleClsl;
  procedure HandleFPrint(const aOperand: string);
  procedure HandleFPrintLn(const aOperand: string);
  procedure HandleNewFile(const aOperand: string);
  procedure HangleGssKill;
  procedure OutTextToFile(const aText: string);
  function ParseDecorOperand(const aOperand: string; var theDName: string; var theDParams: Tf2DecorParams): Boolean;
  function pm_GetContext: Tf2Context;
 protected
  procedure CheckParamCount(aCount, aMin, aMax: Integer);
  function HandleExtraOps(const aOperator, aOperand: string): Boolean; override;
  property Context: Tf2Context read pm_GetContext;
 end;

implementation
uses
 Variants,
 SysUtils,
 Classes,
 d2dTypes,
 furqTypes,

 f2Types,
 f2DecorScript,

 JclStrings,
 Math,
 JclStringLists, furqContext;

const
 cDecorID: array[Tf2DecorType] of string = ('', 'TEXT', 'RECT', 'IMAGE', 'ANIMATION', 'GIF', 'CLICKAREA', 'IMGBUTTON', 'TEXTBUTTON');
 sDecorBadSyntax       = 'Ошибка в операторе';
 sDecorParamsTooMany   = 'Слишком много параметров';
 sDecorParamsTooFew    = 'Слишком мало параметров';
 sDecorNotImplemented  = 'Декоратор этого типа не реализован';
 sDecorInvalidName     = 'Ошибка в имени декоратора';
 sDecorNotFound        = 'Декоратор %s не определен';
 sDecorWrongType       = 'Неверный тип декоратора';
 sWrongParams          = 'Ошибка в параметрах';

 cMaskedIdentSet = cIdentMidSet + ['*', '?'];

procedure Tf2Interpreter.CheckParamCount(aCount, aMin, aMax: Integer);
begin
 if (aCount < aMin) then
  raise EFURQRunTimeError.Create(sDecorParamsTooFew);
 if (aCount > aMax) then
  raise EFURQRunTimeError.Create(sDecorParamsTooMany);
end;

procedure Tf2Interpreter.DH_Col(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
var
 l_CDec: Tf2ColoredDecorator;
 l_TDec: Tf2TextDecorator;
 l_Time: Single;
begin
 if aDecor is Tf2ColoredDecorator then
 begin
  l_CDec := aDecor as Tf2ColoredDecorator;
  if l_CDec is Tf2TextDecorator then
  begin
   CheckParamCount(aParams.rCount, 1, 4);
   l_TDec := l_CDec as Tf2TextDecorator;
  end
  else
   CheckParamCount(aParams.rCount, 1, 2);

  if (aParams.rCount = 1) or ((aParams.rCount = 2) and (aParams.rData[2] <= 0)) then
   l_CDec.Color := CorrectColor(aParams.rData[1])
  else

  if (aParams.rCount = 2) then
   l_CDec.BlendColor(CorrectColor(aParams.rData[1]), aParams.rData[2]/1000)
  else

  if (aParams.rCount = 3) or ((aParams.rCount = 4) and (aParams.rData[4] <= 0)) then
  begin
   l_TDec.Color      := CorrectColor(aParams.rData[1]);
   l_TDec.LinkColor  := CorrectColor(aParams.rData[2]);
   l_TDec.LinkHColor := CorrectColor(aParams.rData[3]);
  end
  else

  if (aParams.rCount = 4) then
  begin
   l_Time := aParams.rData[4]/1000;
   l_TDec.BlendColor(CorrectColor(aParams.rData[1]), l_Time);
   l_TDec.BlendLinkColors(CorrectColor(aParams.rData[2]), CorrectColor(aParams.rData[3]), l_Time);
  end;
 end
 else
  raise EFURQRunTimeError.Create(sDecorWrongType);
end;

procedure Tf2Interpreter.DH_Mov(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
begin
 CheckParamCount(aParams.rCount, 2, 3);
 if (aParams.rCount < 3) or (aParams.rData[3] <= 0) then
 begin
  aDecor.PosX := aParams.rData[1];
  aDecor.PosY := aParams.rData[2];
 end
 else
  aDecor.BlendPosition(aParams.rData[1], aParams.rData[2], aParams.rData[3]/1000);
end;

procedure Tf2Interpreter.DH_Rot(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
begin
 if not (aDecor is Tf2GraphicDecorator) then
  raise EFURQRunTimeError.Create(sDecorWrongType);
 CheckParamCount(aParams.rCount, 1, 2);
 if (aParams.rCount < 2) or (aParams.rData[2] <= 0) then
  Tf2GraphicDecorator(aDecor).Angle := Tf2GraphicDecorator(aDecor).Angle + aParams.rData[1]
 else
  Tf2GraphicDecorator(aDecor).BlendAngle(aParams.rData[1], aParams.rData[2]/1000);
end;

procedure Tf2Interpreter.DH_Scl(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
begin
 if not (aDecor is Tf2GraphicDecorator) then
  raise EFURQRunTimeError.Create(sDecorWrongType);
 CheckParamCount(aParams.rCount, 1, 2);
 if (aParams.rCount < 2) or (aParams.rData[2] <= 0) then
  Tf2GraphicDecorator(aDecor).Scale := aParams.rData[1]
 else
  Tf2GraphicDecorator(aDecor).BlendScale(aParams.rData[1], aParams.rData[2]/1000);
end;

procedure Tf2Interpreter.DH_Scr(const aDecor: Tf2BaseDecorator; const aParams: Tf2DecorParams);
begin
 CheckParamCount(aParams.rCount, 1, 1);
 aDecor.Script := CompileDSOperators(aParams.rData[1]);
end;

procedure Tf2Interpreter.HandleClsl;
begin
 Context.DropLinks;
end;

procedure Tf2Interpreter.ParseDecorParams(aLexer: TfurqLexer; var theParams: Tf2DecorParams);
var
 l_StartPos: Integer;
 l_Str: string;
  l_Eval: TfurqExprEvaluator;
begin
 theParams.rCount := 0;
 l_StartPos := aLexer.TokenEnd;
 repeat
  aLexer.NextToken;
  if aLexer.Token in [etEOF, etComma] then
  begin
   Inc(theParams.rCount);
   if theParams.rCount > cMaxDecorParams then
    raise EFURQRunTimeError.Create(sDecorParamsTooMany);
   l_Str := Copy(aLexer.Source, l_StartPos, aLexer.TokenStart - l_StartPos);
   l_Eval := TfurqExprEvaluator.Create(f_CurContext);
   try
    l_Eval.Source := l_Str;
    theParams.rData[theParams.rCount] := l_Eval.ResultValue;
    l_StartPos := aLexer.TokenEnd;
   finally
    l_Eval.Free;
   end;
  end;
 until aLexer.Token = etEOF;
end;

procedure Tf2Interpreter.HandleDecorAdd(const aOperand: string);
var
 I: Integer;
 l_SpecifiedColors: array [1..3] of Td2dColor;
 l_Lexer: TfurqLexer;
 l_DName: string;
 l_BCount: Integer;
 l_Caption: string;
 l_StartPos: Integer;
 l_CCount: Integer;
 l_X, l_Y, l_Z: Single;
 l_CurDType, l_DType: Tf2DecorType;
 l_DParams: Tf2DecorParams;
 l_FontName: string;
 l_Color: Td2dColor;
 l_ColorsSpecified: Integer;
 l_FontIsSpecified: Boolean;
 l_Frame: string;
 l_Handler: string;
 l_Left: Integer;
 l_Top: Integer;
 l_Width: Integer;
 l_Height: Integer;
 l_LinkColor: Td2dColor;
 l_LinkHColor: Td2dColor;
 l_TexName: string;

 procedure RaiseError;
 begin
  raise EFURQRunTimeError.Create(sDecorBadSyntax);
 end;

 procedure GetCoordParam;
 var
  l_Str: string;
  l_Value: Single;
  l_Eval: TfurqExprEvaluator;
 begin
  l_Str := Copy(aOperand, l_StartPos, l_Lexer.TokenStart - l_StartPos);
  l_Eval := TfurqExprEvaluator.Create(f_CurContext);
  try
   l_Eval.Source := l_Str;
   l_Value := EnsureReal(l_Eval.ResultValue);
   Inc(l_CCount);
   case l_CCount of
    1: l_X := l_Value;
    2: l_Y := l_Value;
    3: l_Z := l_Value;
   else
    RaiseError;
   end;
   l_StartPos := l_Lexer.TokenEnd;
  finally
   l_Eval.Free;
  end;
 end;

begin
 NotAvailableWhileMenuBuild;
 l_Lexer := TfurqLexer.Create;
 try
  l_Lexer.AllowSpacesInIdent := False;
  l_Lexer.Source := aOperand;
  // это должно быть имя декоратора
  if l_Lexer.Token <> etIdentifier then
   RaiseError;
  l_DName := l_Lexer.TokenValue;
  l_DName := AnsiLowerCase(l_DName);
  l_Lexer.NextToken;
  // теперь - открывающая скобка
  if l_Lexer.Token <> etLBrasket then
   RaiseError;
  l_BCount := 1;
  l_CCount := 0;
  l_X := 0; l_Y := 0; l_Z := 0;
  l_StartPos := l_Lexer.TokenEnd;
  repeat
   l_Lexer.NextToken;
   case l_Lexer.Token of
    etEOF : RaiseError;
    etLBrasket: Inc(l_BCount);
    etRBrasket:
     begin
      Dec(l_BCount);
      if l_BCount = 0 then
       GetCoordParam;
     end;
    etComma: GetCoordParam;
   end;
  until (l_BCount = 0);
  if l_CCount < 2 then
   RaiseError;
  // теперь определяем тип декоратора
  l_Lexer.NextToken;
  if l_Lexer.Token <> etIdentifier then
   RaiseError;
  l_DType := dtInvalid;
  for l_CurDType := dtText to High(Tf2DecorType) do
   if AnsiSameText(l_Lexer.TokenValue, cDecorID[l_CurDType]) then
   begin
    l_DType := l_CurDType;
    Break;
   end;
  if l_DType = dtInvalid then
   RaiseError;

  ParseDecorParams(l_Lexer, l_DParams);
  // начинаем разбирать параметры и создавать собственно декораторы
  case l_DType of
   dtText:
   begin
    if l_DParams.rCount < 1 then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    l_Color := Tf2Context(f_CurContext).TextColor;
    l_LinkColor := Tf2Context(f_CurContext).LinkColor;
    l_LinkHColor := Tf2Context(f_CurContext).LinkHColor;
    l_FontName := c_Sysfont;
    { TODO : Доделать параметры цвета для ссылок }

    if l_DParams.rCount > 1 then
    begin
     l_FontIsSpecified := False;
     l_ColorsSpecified := 0;
     for I := 2 to l_DParams.rCount do
     begin
      if VarIsNumeric(l_DParams.rData[I]) then
      begin
       Inc(l_ColorsSpecified);
       if l_ColorsSpecified > 3 then
        RaiseError;
       l_SpecifiedColors[l_ColorsSpecified] := CorrectColor(l_DParams.rData[I]);
      end
      else
      begin
       if not l_FontIsSpecified then
       begin
        l_FontName := EnsureString(l_DParams.rData[I]);
        l_FontIsSpecified := True;
       end
       else
        RaiseError;
      end;
     end;
     if l_ColorsSpecified > 0 then
      l_Color := l_SpecifiedColors[1];
     if l_ColorsSpecified > 1 then
      l_LinkColor := l_SpecifiedColors[2];
     if l_ColorsSpecified > 2 then
      l_LinkHColor := l_SpecifiedColors[3];
    end;
    Context.AddTextDecorator(l_DName, l_X, l_Y, l_Z, l_Color, l_LinkColor, l_LinkHColor,
         l_FontName, EnsureString(l_DParams.rData[1]));
   end;

   dtRectangle:
   begin
    if l_DParams.rCount < 2 then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    if l_DParams.rCount < 3 then
     l_Color := Tf2Context(f_CurContext).TextColor
    else
     l_Color := CorrectColor(l_DParams.rData[3]);
    Context.AddRectDecorator(l_DName, l_X, l_Y, l_Z, l_Color, l_DParams.rData[1], l_DParams.rData[2]);
   end;

   dtPicture, dtAnimation:
   begin
    if ((l_DType = dtPicture) and (l_DParams.rCount < 1)) or
       ((l_DType = dtAnimation) and (l_DParams.rCount < 6)) then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    if l_DParams.rCount < 2 then
     l_Left := 0
    else
     l_Left := l_DParams.rData[2];
    if l_DParams.rCount < 3 then
     l_Top := 0
    else
     l_Top := l_DParams.rData[3];
    if l_DParams.rCount < 4 then
     l_Width := 0
    else
     l_Width := l_DParams.rData[4];
    if l_DParams.rCount < 5 then
     l_Height := 0
    else
     l_Height := l_DParams.rData[5];
    if l_DType = dtPicture then
     Context.AddPictureDecorator(l_DName, l_X, l_Y, l_Z, EnsureString(l_DParams.rData[1]), l_Left, l_Top, l_Width, l_Height)
    else
     Context.AddAnimationDecorator(l_DName, l_X, l_Y, l_Z, EnsureString(l_DParams.rData[1]), l_Left, l_Top, l_Width, l_Height, l_DParams.rData[6]);
   end;

   dtGIF:
   begin
    if l_DParams.rCount = 0 then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    Context.AddGIFDecorator(l_DName, l_X, l_Y, l_Z, EnsureString(l_DParams.rData[1]));
   end;

   dtClickArea:
   begin
    if l_DParams.rCount < 3 then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    Context.AddClickAreaDecorator(l_DName, l_X, l_Y, l_Z, l_DParams.rData[1], l_DParams.rData[2], EnsureString(l_DParams.rData[3]));
   end;

   dtImgButton:
   begin
    if l_DParams.rCount < 2 then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    l_TexName := EnsureString(l_DParams.rData[1]);
    if (l_DParams.rCount > 2) then
     if (l_DParams.rCount < 6) then
      raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    if l_DParams.rCount = 2 then
    begin
     l_Top := 0;
     l_Left := 0;
     l_Width := 0;
     l_Height := 0;
     l_Handler := EnsureString(l_DParams.rData[2]);
    end
    else
    begin
     l_Left := l_DParams.rData[2];
     l_Top  := l_DParams.rData[3];
     l_Width := l_DParams.rData[4];
     l_Height := l_DParams.rData[5];
     l_Handler := EnsureString(l_DParams.rData[6]);
    end;
    Context.AddImageButtonDecorator(l_DName, l_X, l_Y, l_Z, l_TexName, l_Left, l_Top, l_Width, l_Height, l_Handler);
   end;

   dtTextButton:
   begin
    if l_DParams.rCount < 2 then
     raise EFURQRunTimeError.Create(sDecorParamsTooFew);
    if l_DParams.rCount = 2 then
    begin
     l_Caption := EnsureString(l_DParams.rData[1]);
     l_Handler := EnsureString(l_DParams.rData[2]);
     l_Frame := '';
    end
    else
    begin
     l_Frame := EnsureString(l_DParams.rData[1]);
     l_Caption := EnsureString(l_DParams.rData[2]);
     l_Handler := EnsureString(l_DParams.rData[3]);
    end;
    Context.AddTextButtonDecorator(l_DName, l_X, l_Y, l_Z, l_Frame, l_Caption, l_Handler);
   end;

  else
   raise EFURQRunTimeError.Create(sDecorNotImplemented);
  end;
 finally
  l_Lexer.Free;
 end;
end;

procedure Tf2Interpreter.HandleDecorMov(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 HandleDecorPrim(aOperand, DH_Mov);
end;

procedure Tf2Interpreter.HandleDecorCol(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 HandleDecorPrim(aOperand, DH_Col);
end;

procedure Tf2Interpreter.HandleDecorDel(const aOperand: string);
var
 l_Lexer: TfurqLexer;
 l_Idx: Integer;
 l_DName: string;
 I: Integer;
begin
 NotAvailableWhileMenuBuild;
 if Trim(aOperand) = '' then
 begin
  Context.Decorators.Clear;
  Exit;
 end;
 l_Lexer := TfurqLexer.Create;
 try
  l_Lexer.AllowSpacesInIdent := False;
  l_Lexer.SetSourceCustom(aOperand, cMaskedIdentSet);
  while True do
  begin
   if l_Lexer.Token <> etCustom then
    raise EFURQRunTimeError.Create(sDecorInvalidName);
   l_DName := AnsiLowerCase(l_Lexer.TokenValue);
   if StrContainsChars(l_DName, ['?','*'], False) then
   begin
    for I := Context.Decorators.Count - 1 downto 0 do
     if StrMatches(l_DName, Context.Decorators.Strings[I]) then
      Context.Decorators.Delete(I);
   end
   else
   begin
    l_Idx := Context.Decorators.IndexOf(l_DName);
    if l_Idx > -1 then
     Context.Decorators.Delete(l_Idx)
    else
     raise EFURQRunTimeError.CreateFmt(sDecorNotFound, [l_Lexer.TokenValue]);
   end;
   l_Lexer.NextToken;
   case l_Lexer.Token of
    etComma: l_Lexer.NextToken(cMaskedIdentSet);
    etEOF  : Break;
   else
    raise EFURQRunTimeError.Create(sDecorBadSyntax);
   end;
  end;
 finally
  l_Lexer.Free;
 end;
end;

procedure Tf2Interpreter.HandleDecorPrim(const aOperand: string; aProc: Tf2DecorHandleProc);
var
 l_DName: string;
 l_DParams: Tf2DecorParams;
 l_Decor: Tf2BaseDecorator;
 l_Found: Boolean;
 I: Integer;
begin
 ParseDecorOperand(aOperand, l_DName, l_DParams);
 l_DName := AnsiLowerCase(l_DName);
 if StrContainsChars(l_DName, ['?','*'], False) then
 begin
  l_Found := False;
  for I := 0 to Context.Decorators.Count - 1 do
   if StrMatches(l_DName, Context.Decorators.Strings[I]) then
   begin
    l_Found := True;
    aProc(Context.Decorators.Decorators[I], l_DParams);
   end;
  if not l_Found then
   raise EFURQRunTimeError.CreateFmt(sDecorNotFound, [l_DName]);
 end
 else
 begin
  l_Decor := Tf2Context(f_CurContext).GetDecorator(l_DName);
  if l_Decor = nil then
   raise EFURQRunTimeError.CreateFmt(sDecorNotFound, [l_DName]);
  aProc(l_Decor, l_DParams);
 end;
end;

procedure Tf2Interpreter.HandleDecorRot(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 HandleDecorPrim(aOperand, DH_Rot);
end;

procedure Tf2Interpreter.HandleDecorScl(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 HandleDecorPrim(aOperand, DH_Scl);
end;

procedure Tf2Interpreter.HandleDecorScr(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 HandleDecorPrim(aOperand, DH_Scr);
end;

function Tf2Interpreter.HandleExtraOps(const aOperator, aOperand: string): Boolean;
begin
 Result := True;
 if (aOperator = 'IMAGE') then
  HandleImage(aOperand)
 else
 if (aOperator = 'DECORADD') then
  HandleDecorAdd(aOperand)
 else 
 if (aOperator = 'DECORMOV') then
  HandleDecorMov(aOperand) 
 else
 if (aOperator = 'DECORCOL') then
  HandleDecorCol(aOperand) 
 else
 if (aOperator = 'DECORDEL') then
  HandleDecorDel(aOperand) 
 else
 if (aOperator = 'DECORROT') then
  HandleDecorRot(aOperand)
 else
 if (aOperator = 'DECORSCL') then
  HandleDecorScl(aOperand)
 else
 if (aOperator = 'DECORSCR') then
  HandleDecorScr(aOperand)
 else
 if (aOperator = 'FADEMUSIC') then
  HandleFadeMusic(aOperand)
 else 
 if (aOperator = 'VOICE') then
  HandleVoice(aOperand)
 else
 if (aOperator = 'CLSL') then
  HandleClsl
 else
 if (aOperator = 'NEWFILE') then
  HandleNewFile(aOperand)
 else
 if (aOperator = 'FPRINT') or (aOperator = 'FP') then
  HandleFPrint(aOperand)
 else
 if (aOperator = 'FPRINTLN') or (aOperator = 'FPLN') then
  HandleFPrintLn(aOperand)
 else
 if (aOperator = 'GSSKILL') then
  HangleGssKill
 else
  Result := False;
end;

procedure Tf2Interpreter.HandleFadeMusic(const aOperand: string);
var
 l_Eval : TfurqExprEvaluator;
 l_Pos  : Integer;
 l_Sub  : string;
 l_Volume: Byte;
 l_Fade: Longword;
begin
 NotAvailableWhileMenuBuild;
 l_Pos := Pos(',', aOperand);
 if l_Pos > 0 then
 begin
  l_Eval := TfurqExprEvaluator.Create(f_CurContext);
  try
   l_Sub := Copy(aOperand, 1, l_Pos - 1);
   l_Eval.Source := l_Sub;
   l_Volume := EnsureRange(l_Eval.ResultValue, 0, 255);
   l_Sub := Copy(aOperand, l_Pos+1, MaxInt);
   l_Eval.Source := l_Sub;
   l_Fade := EnsureRange(l_Eval.ResultValue, 0, MaxInt);
   Context.FadeMusic(l_Volume, l_Fade);
  finally
   FreeAndNil(l_Eval);
  end;
 end
 else
  raise EFURQRunTimeError.Create(sWrongParams);
end;

procedure Tf2Interpreter.HandleFPrint(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 OutTextToFile(aOperand);
end;

procedure Tf2Interpreter.HandleFPrintLn(const aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 OutTextToFile(aOperand + #13#10);
end;

procedure Tf2Interpreter.HandleImage(aArgs: string);
var
 l_Filename: string;
 l_Params  : array [1..4] of Integer;
 l_PCount: Integer;
 l_Lex: TfurqLexer;
 l_LastParPos: Integer;
 l_ParStr: string;
begin
 NotAvailableWhileMenuBuild;
 FillChar(l_Params, SizeOf(l_Params), 0);
 aArgs := Trim(aArgs);
 l_Filename := '';
 l_PCount := 0;
 l_Lex := TfurqLexer.Create;
 try
  l_Lex.Source := aArgs;
  while True do
  begin
   case l_Lex.Token of
    etComma:
     begin
      if l_Filename = '' then
      begin
       l_Filename := Trim(Copy(aArgs, 1, l_Lex.TokenStart-1));
       l_LastParPos := l_Lex.TokenStart + 1;
      end
      else
      begin
       Inc(l_PCount);
       if l_PCount > 4 then
        Break;
       l_ParStr := Copy(aArgs, l_LastParPos, l_Lex.TokenStart-l_LastParPos);
       l_Params[l_PCount] := StrToIntDef(l_ParStr, 0);
       l_LastParPos := l_Lex.TokenStart + 1;
      end;
     end;
    etEOF:
     begin
      if l_Filename = '' then
       l_Filename := aArgs
      else
      begin
       Inc(l_PCount);
       if l_PCount > 4 then
        Break;
       l_ParStr := Copy(aArgs, l_LastParPos, MaxInt);
       l_Params[l_PCount] := StrToIntDef(l_ParStr, 0);
      end;
      Break;
     end;
   end;
   l_Lex.NextToken;
  end;
 finally
  l_Lex.Free;
 end;

 Tf2Context(f_CurContext).OutPicture(l_Filename, l_Params[1], l_Params[2], l_Params[3], l_Params[4]);
end;

procedure Tf2Interpreter.HandleNewFile(const aOperand: string);
var
 l_FN: string;
begin
 NotAvailableWhileMenuBuild;
 l_FN := Trim(AnsiLowerCase(aOperand));
 if l_FN <> '' then
 begin
  Context.Variables[c_fp_filename] := l_FN;
  DeleteFile(Context.FpFilename);
 end;
end;

procedure Tf2Interpreter.HandleVoice(aOperand: string);
begin
 NotAvailableWhileMenuBuild;
 aOperand := Trim(AnsiLowerCase(aOperand));
 if aOperand = 'stop' then
  Context.VoiceStop
 else
  Context.VoicePlay(aOperand); 
end;

procedure Tf2Interpreter.HangleGssKill;
begin
 // TODO -cMM: Tf2Interpreter.HangleGssKill default body inserted
 Context.KillSettingsStorage;
end;

procedure Tf2Interpreter.OutTextToFile(const aText: string);
var
 l_F: TFileStream;
 l_Mode: Word;
begin
 if Context.FpFilename = '' then
  raise EFURQRunTimeError.Create('Не определён файл для вывода!');
 if aText = '' then
  Exit;
 if FileExists(Context.FpFilename) then
  l_Mode := fmOpenReadWrite
 else
  l_Mode := fmCreate;
 try
  l_F := TFileStream.Create(Context.FpFilename, l_Mode);
  try
   l_F.Seek(0, soFromEnd);
   l_F.Write(aText[1], Length(aText));
  finally
   l_F.Free;
  end;
 except
  raise EFURQRunTimeError.CreateFmt('Не удалось записать в файл %s', [Context.FpFilename]);
 end;
end;

function Tf2Interpreter.ParseDecorOperand(const aOperand: string; var theDName: string; var theDParams:
    Tf2DecorParams): Boolean;
var
 l_Lexer: TfurqLexer;
begin
 Result := False;
 l_Lexer := TfurqLexer.Create;
 try
  l_Lexer.AllowSpacesInIdent := False;
  l_Lexer.SetSourceCustom(aOperand, cMaskedIdentSet);
  if l_Lexer.Token <> etCustom then
   raise EFURQRunTimeError.Create(sDecorInvalidName);
  theDName := l_Lexer.TokenValue;
  ParseDecorParams(l_Lexer, theDParams);
 finally
  l_Lexer.Free;
 end;
end;

function Tf2Interpreter.pm_GetContext: Tf2Context;
begin
 Result := Tf2Context(f_CurContext);
end;

end.