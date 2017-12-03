unit f2FontPool;

interface

uses
  d2dClasses,
  d2dInterfaces,
  JclStringLists;

type
 Tf2FontPool = class(Td2dProtoObject, Id2dFontProvider)
 private
  f_Fonts: IJclStringList;
  f_SysMenuFont: Id2dFont;
  f_SysTextFont: Id2dFont;
 public
  constructor Create(const aSysFont, aSysMenuFont: Id2dFont);
  function GetFont(const aFontName: string): Id2dFont;
  function Id2dFontProvider.GetByID = GetFont;
  procedure Clear;
  property SysMenuFont: Id2dFont read f_SysMenuFont;
  property SysTextFont: Id2dFont read f_SysTextFont;
 end;

implementation
uses
 SysUtils,

 f2Types,
 f2FontLoad;

constructor Tf2FontPool.Create(const aSysFont, aSysMenuFont: Id2dFont);
begin
 inherited Create;
 f_SysTextFont := aSysFont;
 f_SysMenuFont := aSysMenuFont;
end;

procedure Tf2FontPool.Clear;
begin
 if f_Fonts <> nil then
  f_Fonts.Clear;
end;

function Tf2FontPool.GetFont(const aFontName: string): Id2dFont;
var
 l_Idx: Integer;
begin
 if AnsiSameText(aFontName, c_Sysfont) then
  Result := f_SysTextFont
 else
 if AnsiSameText(aFontName, c_SysMenuFont) then
  Result := f_SysMenuFont
 else
 begin
  if f_Fonts = nil then
  begin
   f_Fonts := JclStringList;
   f_Fonts.Sorted := True;
   f_Fonts.CaseSensitive := False;
  end;
  l_Idx := f_Fonts.IndexOf(aFontName);
  if l_Idx >= 0 then
   Result := f_Fonts.Interfaces[l_Idx] as Id2dFont
  else
  begin
   Result := f2LoadFont(aFontName);
   if Result <> nil then
   begin
    l_Idx := f_Fonts.Add(aFontName);
    f_Fonts.Interfaces[l_Idx] := Result;
   end
   else
    Result := f_SysTextFont;
  end;
 end;
end;

end.