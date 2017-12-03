unit f2ScnSplash;

interface

uses
 d2dTypes,
 d2dInterfaces,
 d2dSprite,
 d2dApplication,
 f2Application,
 f2Scene;

type
 Tf2SplashScene = class(Tf2Scene)
 private
  f_Logo: Td2dSprite;
  f_CurCol: Single;
  f_Pause: Single;
  f_Speed: Integer;
  f_Version: string;
  f_VFont: Id2dFont;
  f_VX: Integer;
  f_VY: Integer;
  f_BGColor: Td2dColor;
  f_LogoX, f_LogoY: Integer;
 protected
  procedure DoLoad; override;
  procedure DoUnload; override;
  procedure DoFrame(aDelta: Single); override;
  procedure DoRender; override;
 end;

implementation
uses
 SysUtils,
 JclFileUtils,
 SimpleXML,

 d2dCore,

 f2Skins,
 f2FontLoad;

procedure Tf2SplashScene.DoLoad;
var
 l_VI : TJclFileVersionInfo;
 l_Size: Td2dPoint;
 l_Root, l_Node: IxmlNode;
 l_VColor: Td2dColor;
 l_Tex   : Id2dTexture;
 l_TexX, l_TexY, l_Width, l_Height: Integer;
 l_IsCustomLogo: Boolean;
begin
 l_IsCustomLogo := False;
 l_VColor := $FFEE9A00;

 l_Root := F2App.Skin.XML.DocumentElement.SelectSingleNode('splash');
 if l_Root <> nil then
 begin
  f_BGColor := Td2dColor(l_Root.GetHexAttr('bgcolor'));
  l_VColor := Td2dColor(l_Root.GetHexAttr('vcolor', $FFEE9A00));
  l_Node := l_Root.SelectSingleNode('logo');
  if l_Node <> nil then
  begin
   l_Tex := F2App.Skin.Textures[l_Node.GetAttr('tex')];
   if l_Tex <> nil then
   begin
    l_TexX := l_Node.GetIntAttr('tx');
    l_TexY := l_Node.GetIntAttr('ty');
    l_Width := l_Node.GetIntAttr('width');
    l_Height := l_Node.GetIntAttr('height');
    if (l_Width > 0) and (l_Height > 0) then
    begin
     f_Logo := Td2dSprite.Create(l_Tex, l_TexX, l_TexY, l_Width, l_Height);
     l_IsCustomLogo := True;
    end;
   end;
  end;
 end;

 if f_Logo = nil then
  f_Logo := Td2dSprite.Create(F2App.DefaultTexture, 0, 67, 411, 200);

 f_LogoX := (gD2DE.ScreenWidth div 2) - Round(f_Logo.Width/2);
 f_LogoY := (gD2DE.ScreenHeight div 2) - Round(f_Logo.Height/2);
 f_Logo.BlendMode := BLEND_COLORADD;
 f_CurCol := 255;
 f_Speed := 1200;

 f_VFont := f2LoadFont('sans[12]'{,1.2,0.4]'});
 f_VFont.Color := l_VColor;
 l_VI := TJclFileVersionInfo.Create(ParamStr(0));
 try
  if l_IsCustomLogo then
   f_Version := 'FireURQ ' + l_VI.ProductVersion
  else
   f_Version := l_VI.ProductVersion;
 finally
  l_VI.Free;
 end;
 f_VFont.CalcSize(f_Version, l_Size);
 f_VX := gD2DE.ScreenWidth - Round(l_Size.X) - 3;
 f_VY := gD2DE.ScreenHeight - Round(l_Size.Y) - 3;
end;

procedure Tf2SplashScene.DoUnload;
begin
 f_Logo.Free;
end;

procedure Tf2SplashScene.DoFrame(aDelta: Single);
var
 l_Fract: Byte;
begin
 if f_Pause > 0 then
 begin
  f_Pause := f_Pause - aDelta;
  Exit;
 end;

 f_CurCol := f_CurCol - aDelta * f_Speed;
 if f_CurCol < 0 then
  f_CurCol := 0;
 l_Fract := Trunc(f_CurCol);

 if f_Logo.BlendMode = BLEND_COLORADD then
 begin
  f_Logo.SetColor(ARGB($FF, l_Fract, l_Fract, l_Fract));
  if l_Fract = 0 then
  begin
   f_Logo.BlendMode := BLEND_DEFAULT;
   f_Logo.SetColor($FFFFFFFF);
   f_CurCol := 255;
   f_Pause := 1;
   f_Speed := 300;
  end;
 end
 else
 begin
  f_Logo.SetColor(ARGB(l_Fract, 255, 255, 255));
  if l_Fract = 0 then
   Application.CurrentScene := 'main';
 end;
end;

procedure Tf2SplashScene.DoRender;
begin
 gD2DE.Gfx_Clear(f_BGColor);
 f_Logo.Render(f_LogoX, f_LogoY);
 if not F2App.IsFromExe then
  f_VFont.Render(f_VX, f_VY, f_Version);
end;

end.
