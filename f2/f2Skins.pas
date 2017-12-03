unit f2Skins;

interface
uses
 SimpleXML,
 JclStringLists,

 d2dTypes,
 d2dInterfaces,
 //d2dFont,
 d2dGUIButtons,

 f2Types;

type
 Tf2Skin = class(TObject)
 private
  f_XML: IXmlDocument;
  f_ScreenHeight: Integer;
  f_ScreenWidth: Integer;
  f_FullScreen: Boolean;
  f_TexList: IJclStringList;  // textures
  f_FntList: IJclStringList;  // fonts
  f_BFList : IJclStringList;  // button frames
  f_IsFromPack: Boolean;
  f_ResPath: string;
  procedure LoadScreenPropetries;
  function pm_GetTextures(aName: string): Id2dTexture;
  function pm_GetFonts(aName: string): Id2dFont;
  function pm_GetFrames(aName: string): Id2dFramedButtonView;
 public
  constructor Create(aFileName: string; aFromPack: Boolean = False);
  procedure LoadResources;
  property ScreenHeight: Integer read f_ScreenHeight write f_ScreenHeight;
  property ScreenWidth: Integer read f_ScreenWidth write f_ScreenWidth;
  property FullScreen: Boolean read f_FullScreen write f_FullScreen;
  property Textures[aName: string]: Id2dTexture read pm_GetTextures;
  property Fonts[aName: string]: Id2dFont read pm_GetFonts;
  property Frames[aName: string]: Id2dFramedButtonView read pm_GetFrames;
  property XML: IXmlDocument read f_XML;
 end;

implementation
uses
 Classes,
 SysUtils,

 d2dCore,
 d2dGUITypes,

 f2FontLoad
 ;

constructor Tf2Skin.Create(aFileName: string; aFromPack: Boolean = False);
var
 l_Stream: TStream;
begin
 inherited Create;
 l_Stream := gD2DE.Resource_CreateStream(aFileName, aFromPack);
 try
  f_XML := LoadXmlDocument(l_Stream);
 finally
  FreeAndNil(l_Stream);
 end;
 if (f_XML = nil) or (f_XML.DocumentElement = nil) then
  Fail;
 f_TexList := JclStringList;
 f_FntList := JclStringList;
 f_BFList  := JclStringList;
 f_BFList.CaseSensitive := False;
 f_ResPath := ExtractFilePath(aFileName);
 f_IsFromPack := aFromPack;
 LoadScreenPropetries;
end;

procedure Tf2Skin.LoadResources;
var
 l_ResRoot: IxmlNode;
 l_Node: IxmlNode;
 l_List: IXmlNodeList;
 I: Integer;
 l_Tex : Id2dTexture;
 l_Name : string;
 l_FName: string;
 l_Idx: Integer;
 l_Font: Id2dFont;
 l_TempName: string;
 l_TexX: Integer;
 l_TexY: Integer;
 l_Width: Integer;
 l_Height: Integer;
 l_LeftW: Integer;
 l_MidW: Integer;
 l_Frame: Id2dFramedButtonView;
begin
 l_ResRoot := f_XML.DocumentElement.SelectSingleNode('resources');
 if l_ResRoot <> nil then
 begin
  l_List := l_ResRoot.SelectNodes('texture');
  for I := 0 to l_List.Count - 1  do
  begin
   l_Node := l_List.Item[I];
   l_Name  := l_Node.GetAttr('name');
   l_FName := l_Node.GetAttr('file');
   if (l_Name <> '') and (l_FName <> '') then
   begin
    l_FName := f_ResPath + l_FName;
    l_Tex := gD2DE.Texture_Load(l_FName, f_IsFromPack);
    if l_Tex <> nil then
    begin
     l_Idx := f_TexList.Add(l_Name);
     f_TexList.Interfaces[l_Idx] := l_Tex;
    end;
   end;
  end;

  l_List := l_ResRoot.SelectNodes('font');
  for I := 0 to l_List.Count - 1  do
  begin
   l_Node := l_List.Item[I];
   l_Name  := l_Node.GetAttr('name');
   l_FName := l_Node.GetAttr('file');
   if (l_Name <> '') and (l_FName <> '') then
   begin
    l_FName := f_ResPath + l_FName;
    l_Font := f2LoadFont(l_FName, f_IsFromPack);
    if l_Font <> nil then
    begin
     l_Idx := f_FntList.Add(l_Name);
     f_FntList.Interfaces[l_Idx] := l_Font;
    end;
   end;
  end;

  l_List := l_ResRoot.SelectNodes('buttonframe');
  for I := 0 to l_List.Count - 1  do
  begin
   l_Node := l_List.Item[I];
   l_Name  := l_Node.GetAttr('name');
   if l_Name <> '' then
   begin
    l_Idx := f_TexList.IndexOf(l_Node.GetAttr('tex'));
    if l_Idx >= 0 then
    begin
     l_Tex := f_TexList.Interfaces[l_Idx] as Id2dTexture;
     l_Idx := f_FntList.IndexOf(l_Node.GetAttr('font'));
     if l_Idx >= 0 then
     begin
      l_Font := f_FntList.Interfaces[l_Idx] as Id2dFont;
      l_TexX := l_Node.GetIntAttr('texx');
      l_TexY := l_Node.GetIntAttr('texy');
      l_Width  := l_Node.GetIntAttr('width');
      l_Height := l_Node.GetIntAttr('height');
      l_LeftW := l_Node.GetIntAttr('leftw');
      l_MidW  := l_Node.GetIntAttr('midw');
      if (l_Width > 0) and (l_Height > 0) and (l_LeftW > 0) and (l_MidW > 0) then
      begin
       l_Frame := Td2dFramedButtonView.Create(l_Tex, l_TexX, l_TexY, l_Width, l_Height, l_LeftW, l_MidW, l_Font);
       with l_Frame do
       begin
        StateColor[bsNormal]   := Td2dColor(l_Node.GetHexAttr('cnormal',   $FFA0A0A0));
        StateColor[bsFocused]  := Td2dColor(l_Node.GetHexAttr('cfocused',  $FFA0A0FF));
        StateColor[bsDisabled] := Td2dColor(l_Node.GetHexAttr('cdisabled', $FF606060));
        StateColor[bsPressed]  := Td2dColor(l_Node.GetHexAttr('cpressed',  $FFFFFFFF));
       end;
       l_Idx := f_BFList.Add(l_Name);
       f_BFList.Interfaces[l_Idx] := l_Frame;
      end;
     end;
    end;
   end;
  end;

 end;
end;

procedure Tf2Skin.LoadScreenPropetries;
var
 l_Node: IXmlNode;
begin
 l_Node := f_XML.DocumentElement.SelectSingleNode('screen');
 if l_Node <> nil then
 begin
  f_ScreenWidth  := l_Node.GetIntAttr('width', 800);
  f_ScreenHeight := l_Node.GetIntAttr('height', 600);
  f_FullScreen := l_Node.GetBoolAttr('fullscreen', False);
 end
 else
 begin
  f_ScreenWidth := 800;
  f_ScreenHeight := 600;
  f_FullScreen := False;
 end;
end;

function Tf2Skin.pm_GetTextures(aName: string): Id2dTexture;
var
 l_Idx: Integer;
begin
 l_Idx := f_TexList.IndexOf(aName);
 if l_Idx >= 0 then
  Result := f_TexList.Interfaces[l_Idx] as Id2dTexture
 else
  Result := nil; 
end;

function Tf2Skin.pm_GetFonts(aName: string): Id2dFont;
var
 l_Idx: Integer;
begin
 l_Idx := f_FntList.IndexOf(aName);
 if l_Idx >= 0 then
  Result := f_FntList.Interfaces[l_Idx] as Id2dFont
 else
  Result := nil; 
end;

function Tf2Skin.pm_GetFrames(aName: string): Id2dFramedButtonView;
var
 l_Idx: Integer;
begin
 l_Idx := f_BFList.IndexOf(aName);
 if l_Idx >= 0 then
  Result := f_BFList.Interfaces[l_Idx] as Id2dFramedButtonView
 else
  Result := nil; 
end;

end.