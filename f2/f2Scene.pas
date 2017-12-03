unit f2Scene;

interface

uses
 SimpleXML,

 d2dTypes,
 d2dInterfaces,
 d2dApplication,
 d2dGUI,
 d2dGUIButtons,
 d2dUtils,
 d2dFont,

 f2Application,
 f2Context;

type
 Tf2Scene = class(Td2dScene)
 private
  function pm_GetF2App: Tf2Application;
 protected
  f_Context: Tf2Context;
  property F2App: Tf2Application read pm_GetF2App;
  function LoadButton(const aNode: IXmlNode; const aName: string): Td2dBitButton;
 public
  property Context: Tf2Context read f_Context write f_Context;
 end;

implementation

function Tf2Scene.pm_GetF2App: Tf2Application;
begin
 Result := Tf2Application(Application);
end;

function Tf2Scene.LoadButton(const aNode: IXmlNode; const aName: string): Td2dBitButton;
var
 l_Tex: Id2dTexture;
 l_BNode: IxmlNode;
 l_TX, l_TY, l_W, l_H, l_PosX, l_PosY: Integer;
begin
 Result := nil;
 l_BNode := aNode.SelectSingleNode(aName);
 if l_BNode <> nil then
 begin
  l_Tex := F2App.Skin.Textures[l_BNode.GetAttr('tex')];
  if l_Tex <> nil then
  begin
   l_TX := l_BNode.GetIntAttr('tx');
   l_TY := l_BNode.GetIntAttr('ty');
   l_W := l_BNode.GetIntAttr('width');
   l_H := l_BNode.GetIntAttr('height');
   l_PosX := l_BNode.GetIntAttr('posx');
   l_PosY := l_BNode.GetIntAttr('posy');
   if (l_H > 0) and (l_W > 0) then
    Result := Td2dBitButton.Create(l_PosX, l_PosY, l_Tex, l_TX, l_TY, l_W, l_H);
  end;
 end;
end;


end.