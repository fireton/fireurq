unit furqFiler;

{ $Id: furqFiler.pas,v 1.1 2017/06/28 18:42:16 Антон Exp $ }

interface

uses
 d2dUtils;

type
 TFURQFiler = class(Td2dFiler)
 public
  function ReadVarValue: Variant;
  procedure WriteVarValue(aValue: Variant);
 end;

implementation
uses
 Variants;

const
 cStrValue = 1;
 cNumValue = 2;

function TFURQFiler.ReadVarValue: Variant;
var
 l_Type: Byte;
begin
 f_Stream.ReadBuffer(l_Type, 1);
 case l_Type of
  cStrValue: Result := ReadString;
  cNumValue: Result := ReadDouble;
 end;
end;

procedure TFURQFiler.WriteVarValue(aValue: Variant);
var
 l_Type: Byte;
 l_Str: string;
 l_Num: Double;
begin
 if VarType(aValue) = varString then
 begin
  l_Type := cStrValue;
  f_Stream.WriteBuffer(l_Type, 1);
  l_Str := aValue;
  WriteString(l_Str);
 end
 else
 begin
  l_Type := cNumValue;
  f_Stream.WriteBuffer(l_Type, 1);
  l_Num := aValue;
  WriteDouble(l_Num);
 end;
end;

end.