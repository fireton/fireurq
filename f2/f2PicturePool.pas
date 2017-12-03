unit f2PicturePool;

interface

uses
 d2dInterfaces,
 d2dClasses;

type
 Tf2PicturePool = class(Td2dProtoObject, Id2dPictureProvider)
 private
  function Id2dPictureProvider.GetByID = GetPicture;
  function GetPicture(const aPictureName: string): Id2dPicture;
 public
  class function Make: Id2dPictureProvider;
 end;

implementation

uses
 Types,
 JclStringLists,
 StrUtils,
 SysUtils,

 d2dTypes,
 d2dCore,
 d2dSimplePicture;

function CutByColon(const aStr: string): IJclStringList;
var
 l_StartPos, l_EndPos: Integer;
 l_Str: AnsiString;
begin
 Result := JclStringList;
 if aStr = '' then
  Exit;
 l_StartPos := 1;
 while True do
 begin
  l_EndPos := PosEx(':', aStr, l_StartPos);
  if l_EndPos > 0 then
  begin
   l_Str := Copy(aStr, l_StartPos, l_EndPos-l_StartPos);
   Result.Add(l_Str);
   l_StartPos := l_EndPos+1;
  end
  else
  begin
   l_Str := Copy(aStr, l_StartPos, MaxInt);
   if l_Str <> '' then
    Result.Add(l_Str);
   Break;
  end;
 end;
end;


function Tf2PicturePool.GetPicture(const aPictureName: string): Id2dPicture;
var
 l_Params: IJclStringList;
 l_X, l_Y, l_W, l_H: Integer;
 l_Color: Longword;
 l_Tex: Id2dTexture;
 l_PicSize: TPoint;
begin
 l_Params := CutByColon(aPictureName);
 Assert(l_Params.Count = 6);
 l_Tex := gD2DE.Texture_Load(l_Params[0], False, True, False, @l_PicSize);
 if l_Tex <> nil then
 begin
  l_X := StrToIntDef(l_Params[1], 0);
  l_Y := StrToIntDef(l_Params[2], 0);
  l_W := StrToIntDef(l_Params[3], 0);
  l_H := StrToIntDef(l_Params[4], 0);
  l_Color := ((StrToIntDef(l_Params[5], $FF) and $FF) shl 24) or $FFFFFF;
  if l_W = 0 then
   l_W := l_PicSize.X - l_X;
  if l_H = 0 then
   l_H := l_PicSize.Y - l_Y;
  if (l_W < 0) or (l_H < 0) then
   Exit;
  Result := Td2dSimplePicture.Make(aPictureName, l_Tex, l_X, l_Y, l_W, l_H, l_Color);
 end;
end;

class function Tf2PicturePool.Make: Id2dPictureProvider;
var
 l_PP: Tf2PicturePool;
begin
 l_PP := Tf2PicturePool.Create;
 try
  Result := l_PP;
 finally
  FreeAndNil(l_PP);
 end;
end;

end.