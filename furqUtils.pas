unit furqUtils;

interface

function NewFUID: string;

implementation
uses
 Windows,
 SysUtils;

function NewFUID: string;
var
 l_FUID: Int64;
 l_Rnd : Integer;
begin
 l_FUID := GetTickCount;
 l_Rnd := Random(MaxInt);
 l_FUID := l_FUID xor l_Rnd;
 Result := IntToHex(l_FUID, 8);
end;

end.