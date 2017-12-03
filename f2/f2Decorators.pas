unit f2Decorators;

interface
uses
 Classes,
 d2dTypes,
 d2dInterfaces,
 d2dClasses,
 d2dUtils,
 d2dSprite,
 d2dStaticText,
 d2dGUIButtons,
 d2dGUITypes,

 furqTypes,
 furqContext,

 f2Types,
 f2DecorScript,
 f2FontPool,

 JclStringLists;


type
 Tf2DecoratorList = class;
 Tf2SingleTargetProcessor = class;

 If2ActionDecorator = interface
  ['{7A023A01-BE35-4FF8-BDBC-2D3A8A85AA8F}']
  procedure ProcessEvent(var theEvent: Td2dInputEvent);
  function GetActionsData(const anID: string): IFURQActionData;
  function pm_GetAllowed: Boolean;
  function pm_GetEnabled: Boolean;
  function pm_GetMenuAlign: Td2dAlign;
  procedure pm_SetAllowed(const Value: Boolean);
  procedure pm_SetEnabled(const Value: Boolean);
  procedure pm_SetMenuAlign(const Value: Td2dAlign);
  property Allowed: Boolean read pm_GetAllowed write pm_SetAllowed;
  property Enabled: Boolean read pm_GetEnabled write pm_SetEnabled;
  property MenuAlign: Td2dAlign read pm_GetMenuAlign write pm_SetMenuAlign;
 end;

 If2TargetProvider = interface
  ['{78E5369F-2D34-4C9E-B4D3-14F74940DA61}']
  function GetTargetProcessor: Tf2SingleTargetProcessor;
 end;

 Tf2SingleTargetProcessor = class(Td2dProtoObject)
 private
  f_ActionData: IFURQActionData;
  f_ActionID: string;
  f_Context: TFURQContext;
  f_OnAction: Tf2OnActionProc;
  f_Target: string;
 public
  constructor Create(const aContext: TFURQContext);
  constructor Load(aFiler: Td2dFiler; aContext: TFURQContext);
  function GetActionsData(anID: string): IFURQActionData;
  procedure ExecuteAction(const aRect: Td2dRect; const aMenuAlign: Td2dAlign);
  procedure pm_SetTarget(const aTarget: string);
  procedure Save(aFiler: Td2dFiler);
  property Target: string read f_Target write pm_SetTarget;
  property OnAction: Tf2OnActionProc read f_OnAction write f_OnAction;
 end;

 Tf2BaseDecorator = class(Td2dProtoObject)
 private
  f_PositionBlender: Td2dPositionBlender;
  f_PosX: Single;
  f_PosY: Single;
  f_PosZ: Single;
  f_Script: IInterfaceList;
  f_ScriptDelay: Single;
  f_ScriptPos: Integer;
  f_ToDie: Boolean;
  f_Visible: Boolean;
  procedure ExecuteNextScriptOp;
  procedure pm_SetPosX(const Value: Single);
  procedure pm_SetPosY(const Value: Single);
  procedure pm_SetPosZ(const Value: Single);
  procedure pm_SetScript(const Value: IInterfaceList);
  procedure ProcessScript(const aDelta: Single);
    procedure UpdatePositionBlending(const aDelta: Single);
 protected
  f_List: Tf2DecoratorList;
  procedure Cleanup; override;
  procedure ClearPositionBlender;
  procedure DoExecuteScriptOperator(const aOp: If2DSOperator); virtual;
  procedure DoRender; virtual; abstract;
  procedure DoSetPosX(const Value: Single); virtual;
  procedure DoSetPosY(const Value: Single); virtual;
  function pm_GetDecoratorType: Tf2DecorType; virtual;
  function pm_GetHeight: Single; virtual; abstract;
  function pm_GetWidth: Single; virtual; abstract;
  property ScriptDelay: Single read f_ScriptDelay write f_ScriptDelay;
 public
  procedure BlendPosition(const aTargetX, aTargetY: Single; const aTime: Single);
  constructor Create(const aPosX, aPosY, aPosZ: Single);
  constructor Load(aFiler: Td2dFiler);
  procedure Render;
  procedure Save(aFiler: Td2dFiler); virtual;
  procedure Update(const aDelta: Single); virtual;
  function AsActionDecorator: If2ActionDecorator; virtual;
  property DecoratorType: Tf2DecorType read pm_GetDecoratorType;
  property Height: Single read pm_GetHeight;
  property PosX: Single read f_PosX write pm_SetPosX;
  property PosY: Single read f_PosY write pm_SetPosY;
  property PosZ: Single read f_PosZ write pm_SetPosZ;
  property Script: IInterfaceList read f_Script write pm_SetScript;
  property ToDie: Boolean read f_ToDie;
  property Visible: Boolean read f_Visible write f_Visible;
  property Width: Single read pm_GetWidth;
 end;

 Tf2DecoratorList = class(TStringList)
 private
  procedure ClearObjects;
  function pm_GetDecorators(Index: Integer): Tf2BaseDecorator;
 public
  constructor Create;
  destructor Destroy; override;
  procedure AddDecorator(const aName: string; const aDecorator: Tf2BaseDecorator);
  procedure Clear; override;
  procedure Delete(Index: Integer); override;
  procedure Load(aFiler: Td2dFiler; aContext: TFURQContext);
  procedure Save(aFiler: Td2dFiler);
  procedure Sort; override;
  procedure Update(aDelta: Single);
  property Decorators[Index: Integer]: Tf2BaseDecorator read pm_GetDecorators;
 end;

 Tf2ColoredDecorator = class(Tf2BaseDecorator)
 private
  f_Color: Td2dColor;
  f_ColorBlender: Td2dColorBlender;
  procedure pm_SetColor(const Value: Td2dColor);
  procedure UpdateColorBlending(const aDelta: Single);
 protected
  procedure Cleanup; override;
  procedure ClearColorBlender;
  procedure DoExecuteScriptOperator(const aOp: If2DSOperator); override;
  procedure DoSetColor(aColor: Td2dColor); virtual;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; const aColor: Td2dColor);
  constructor Load(aFiler: Td2dFiler);
  procedure BlendColor(const aTargetColor: Td2dColor; const aTime: Single);
  procedure Save(aFiler: Td2dFiler); override;
  procedure Update(const aDelta: Single); override;
  property Color: Td2dColor read f_Color write pm_SetColor;
 end;

 Tf2TextDecorator = class(Tf2ColoredDecorator, If2ActionDecorator)
 private
  f_Actions: IJclStringList;
  f_Allowed: Boolean;
  f_Context: TFURQContext;
  f_FontName: string;
  f_LinkColorBlender: Td2dColorBlender;
  f_LinkHColorBlender: Td2dColorBlender;
  f_LinksEnabled: Boolean;
  f_MenuAlign: Td2dAlign;
  f_OnAction: Tf2OnActionProc;
  f_StaticText: Td2dStaticText;
  f_Text: string;
  function pm_GetAlign: Td2dTextAlignType;
  function pm_GetFont: Id2dFont;
  function pm_GetLineSpacing: Single;
  function pm_GetLinkColor: Td2dColor;
  function pm_GetLinkHColor: Td2dColor;
  function pm_GetParaSpacing: Single;
  function pm_GetText: string;
  procedure pm_SetAlign(const Value: Td2dTextAlignType);
  procedure pm_SetFont(const Value: Id2dFont);
  procedure pm_SetLineSpacing(const Value: Single);
  procedure pm_SetLinkColor(const Value: Td2dColor);
  procedure pm_SetLinkHColor(const Value: Td2dColor);
  procedure pm_SetParaSpacing(const Value: Single);
  procedure pm_SetText(const Value: string);
  procedure pm_SetWidth(const Value: Single);
 private // If2ActionDecorator
  procedure ProcessEvent(var theEvent: Td2dInputEvent);
  function GetActionsData(const anID: string): IFURQActionData;
  function pm_GetAllowed: Boolean;
  function pm_GetLinksEnabled: Boolean;
  function pm_GetMenuAlign: Td2dAlign;
  procedure pm_SetAllowed(const Value: Boolean);
  procedure pm_SetLinksEnabled(const Value: Boolean);
  procedure pm_SetMenuAlign(const Value: Td2dAlign);
  procedure UpdateLinksState;
  function If2ActionDecorator.pm_GetEnabled = pm_GetLinksEnabled;
  procedure If2ActionDecorator.pm_SetEnabled = pm_SetLinksEnabled;
 protected
  procedure Cleanup; override;
  procedure DoExecuteScriptOperator(const aOp: If2DSOperator); override;
  procedure DoRender; override;
  procedure DoSetColor(aColor: Td2dColor); override;
  function pm_GetHeight: Single; override;
  function pm_GetWidth: Single; override;
  procedure DoSetPosX(const Value: Single); override;
  procedure DoSetPosY(const Value: Single); override;
  function pm_GetDecoratorType: Tf2DecorType; override;
 public
  constructor Create(const aContext: TFURQContext;
                     const aPosX, aPosY, aPosZ: Single;
                     const aColor: Td2dColor;
                     const aLinkColor, aLinkHColor: Td2dColor;
                     const aText: string;
                     const aFontName: string;
                           aFontPool: Tf2FontPool);
  constructor Load(aFiler: Td2dFiler; aContext: TFURQContext);
  function AsActionDecorator: If2ActionDecorator; override;
  procedure BlendLinkColors(const aTargetLinkColor, aTargetLinkHColor: Td2dColor; const aTime: Single);
  procedure Save(aFiler: Td2dFiler); override;
  procedure Update(const aDelta: Single); override;
  procedure _ClickHandler(const aSender: TObject; const aRect: Td2dRect; const aTarget: string);
  property Align: Td2dTextAlignType read pm_GetAlign write pm_SetAlign;
  property Allowed: Boolean read pm_GetAllowed write pm_SetAllowed;
  property Context: TFURQContext read f_Context write f_Context;
  property Font: Id2dFont read pm_GetFont write pm_SetFont;
  property LineSpacing: Single read pm_GetLineSpacing write pm_SetLineSpacing;
  property LinkColor: Td2dColor read pm_GetLinkColor write pm_SetLinkColor;
  property LinkHColor: Td2dColor read pm_GetLinkHColor write pm_SetLinkHColor;
  property LinksEnabled: Boolean read pm_GetLinksEnabled write pm_SetLinksEnabled;
  property MenuAlign: Td2dAlign read pm_GetMenuAlign write pm_SetMenuAlign;
  property ParaSpacing: Single read pm_GetParaSpacing write pm_SetParaSpacing;
  property Text: string read pm_GetText write pm_SetText;
  property Width: Single read pm_GetWidth write pm_SetWidth;
  property OnAction: Tf2OnActionProc read f_OnAction write f_OnAction;
 end;

 Tf2GraphicDecorator = class(Tf2ColoredDecorator)
 private
  f_Angle: Single;
  f_HotX: Integer;
  f_HotY: Integer;
  f_RotationBlender: Td2dSimpleBlender;
  f_ScaleBlender   : Td2dSimpleBlender;
  f_RotSpeed: Single;
  f_Scale: Single;
  procedure pm_SetAngle(const Value: Single);
  procedure pm_SetRotSpeed(const Value: Single);
  procedure pm_SetScale(const Value: Single);
 protected
  f_AngleRad: Single;
  procedure Cleanup; override;
  procedure ClearRotationBlender;
  procedure ClearScaleBlender;
  procedure pm_SetHotX(const aHotX: Integer); virtual;
  procedure pm_SetHotY(const aHotY: Integer); virtual;
  procedure SetAnglePrim(aAngle: Single);
  procedure DoExecuteScriptOperator(const aOp: If2DSOperator); override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; const aColor: Td2dColor);
  constructor Load(aFiler: Td2dFiler);
  procedure BlendAngle(const aDelta: Single; aTime: Single);
  procedure BlendScale(const aTargetScale: Single; aTime: Single);
  procedure Save(aFiler: Td2dFiler); override;
  procedure Update(const aDelta: Single); override;
  property Angle: Single read f_Angle write pm_SetAngle;
  property HotX: Integer read f_HotX write pm_SetHotX;
  property HotY: Integer read f_HotY write pm_SetHotY;
  property RotSpeed: Single read f_RotSpeed write pm_SetRotSpeed;
  property Scale: Single read f_Scale write pm_SetScale;
 end;

 Tf2BasicSpriteDecorator = class(Tf2GraphicDecorator)
 private
  f_FlipX: Boolean;
  f_FlipY: Boolean;
  procedure pm_SetFlipX(const Value: Boolean);
  procedure pm_SetFlipY(const Value: Boolean);
 protected
  f_Sprite: Td2dSprite;
  procedure ApplyFlips;
  procedure Cleanup; override;
  procedure DoRender; override;
  procedure DoSetColor(aColor: Td2dColor); override;
  function pm_GetHeight: Single; override;
  function pm_GetWidth: Single; override;
  procedure pm_SetHotX(const aHotX: Integer); override;
  procedure pm_SetHotY(const aHotY: Integer); override;
 public
  constructor Load(aFiler: Td2dFiler);
  procedure Save(aFiler: Td2dFiler); override;
  property FlipX: Boolean read f_FlipX write pm_SetFlipX;
  property FlipY: Boolean read f_FlipY write pm_SetFlipY;

 end;

 Tf2RectangleDecorator = class(Tf2BasicSpriteDecorator)
 protected
  function pm_GetDecoratorType: Tf2DecorType; override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; aWidth, aHeight: Integer; const aColor: Td2dColor);
  constructor Load(aFiler: Td2dFiler);
  procedure Save(aFiler: Td2dFiler); override;
 end;

 Tf2SpriteInitDataRec = record
  rTX     : Integer;
  rTY     : Integer;
  rWidth  : Integer;
  rHeight : Integer;
 end;

 Tf2SpriteDecorator = class(Tf2BasicSpriteDecorator)
 private
  f_TexName: string;
  f_InitRec: Tf2SpriteInitDataRec;
 protected
  function pm_GetDecoratorType: Tf2DecorType; override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; aTexName: string;
                     aTX, aTY, aWidth, aHeight: Integer);
  constructor Load(aFiler: Td2dFiler);
  procedure Save(aFiler: Td2dFiler); override;
 end;

 Tf2AnimationDecorator = class(Tf2BasicSpriteDecorator)
 private
  f_AniType: Integer;
  f_InitRec: Tf2SpriteInitDataRec;
  f_TexName: string;
  function pm_GetAniType: Integer;
  function pm_GetCurFrame: Integer;
  function pm_GetSpeed: Single;
  procedure pm_SetAniType(Value: Integer);
  procedure pm_SetCurFrame(const Value: Integer);
  procedure pm_SetSpeed(const Value: Single);
 protected
  function pm_GetDecoratorType: Tf2DecorType; override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; aTexName: string; const aTX, aTY, aWidth, aHeight, aFrames:
      Integer);
  constructor Load(aFiler: Td2dFiler);
  procedure Save(aFiler: Td2dFiler); override;
  procedure Update(const aDelta: Single); override;
  property AniType: Integer read pm_GetAniType write pm_SetAniType;
  property CurFrame: Integer read pm_GetCurFrame write pm_SetCurFrame;
  property Speed: Single read pm_GetSpeed write pm_SetSpeed;
 end;

 Tf2GIFDecorator = class(Tf2BasicSpriteDecorator)
 private
  f_GIFName: string;
  function pm_GetAniSpeed: Integer;
  function pm_GetFrame: Integer;
  procedure pm_SetAniSpeed(const Value: Integer);
  procedure pm_SetFrame(const Value: Integer);
 protected
  function pm_GetDecoratorType: Tf2DecorType; override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; aGIFName: string);
  constructor Load(aFiler: Td2dFiler);
  procedure Save(aFiler: Td2dFiler); override;
  procedure Update(const aDelta: Single); override;
  property AniSpeed: Integer read pm_GetAniSpeed write pm_SetAniSpeed;
  property Frame: Integer read pm_GetFrame write pm_SetFrame;
 end;

 Tf2ClickAreaDecorator = class(Tf2BaseDecorator, If2ActionDecorator, If2TargetProvider)
 private
  f_Allowed: Boolean;
  f_Enabled: Boolean;
  f_Width: Single;
  f_Height: Single;
  f_MenuAlign: Td2dAlign;
  f_Rect: Td2dRect;
  f_TargetProcessor: Tf2SingleTargetProcessor;
  function pm_GetAllowed: Boolean;
  function pm_GetEnabled: Boolean;
  function pm_GetMenuAlign: Td2dAlign;
  procedure pm_SetAllowed(const Value: Boolean);
  procedure pm_SetEnabled(const Value: Boolean);
  procedure pm_SetWidth(const Value: Single);
  procedure pm_SetHeight(const Value: Single);
  procedure pm_SetMenuAlign(const Value: Td2dAlign);
  procedure RecalcRect;
 protected
  procedure DoRender; override;
  procedure DoSetPosX(const Value: Single); override;
  procedure DoSetPosY(const Value: Single); override;
  function pm_GetDecoratorType: Tf2DecorType; override;
  function pm_GetWidth: Single; override;
  function pm_GetHeight: Single; override;
  procedure Cleanup; override;
  // If2ActionDecorator
  procedure ProcessEvent(var theEvent: Td2dInputEvent);
  function GetActionsData(const anID: string): IFURQActionData;
  // If2TargetProvider
  function GetTargetProcessor: Tf2SingleTargetProcessor;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext; const aWidth, aHeight: Single);
  constructor Load(aFiler: Td2dFiler; aContext: TFURQContext);
  function AsActionDecorator: If2ActionDecorator; override;
  procedure Save(aFiler: Td2dFiler); override;
  property Allowed: Boolean read pm_GetAllowed write pm_SetAllowed;
  property Enabled: Boolean read pm_GetEnabled write pm_SetEnabled;
  property Width: Single read pm_GetWidth write pm_SetWidth;
  property Height: Single read pm_GetHeight write pm_SetHeight;
  property MenuAlign: Td2dAlign read pm_GetMenuAlign write pm_SetMenuAlign;
  property TargetProcessor: Tf2SingleTargetProcessor read f_TargetProcessor;
 end;

 Tf2CustomButtonDecorator = class(Tf2BaseDecorator, If2ActionDecorator, If2TargetProvider)
 private
  f_Allowed: Boolean;
  f_Enabled: Boolean;
  f_MenuAlign: Td2dAlign;
  f_TargetProcessor: Tf2SingleTargetProcessor;
  function pm_GetAllowed: Boolean;
  function pm_GetEnabled: Boolean;
  function pm_GetMenuAlign: Td2dAlign;
  procedure pm_SetAllowed(const Value: Boolean);
  procedure pm_SetEnabled(const Value: Boolean);
  procedure pm_SetMenuAlign(const Value: Td2dAlign);
  procedure UpdateButtonState;
 protected
  f_Button: Td2dCustomButton;
  procedure Cleanup; override;
  procedure ClickHandler(aSender: TObject);
  procedure DoRender; override;
  procedure DoSetPosX(const Value: Single); override;
  procedure DoSetPosY(const Value: Single); override;
  procedure LoadButton(const aFiler: Td2dFiler; const aContext: TFURQContext); virtual; abstract;
  procedure SaveButton(const aFiler: Td2dFiler); virtual; abstract;
  function pm_GetHeight: Single; override;
  function pm_GetWidth: Single; override;
  // If2ActionDecorator
  procedure ProcessEvent(var theEvent: Td2dInputEvent);
  function GetActionsData(const anID: string): IFURQActionData;
  // If2TargetProvider
  function GetTargetProcessor: Tf2SingleTargetProcessor;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext);
  constructor Load(const aFiler: Td2dFiler; aContext: TFURQContext);
  function AsActionDecorator: If2ActionDecorator; override;
  procedure Save(aFiler: Td2dFiler); override;
  procedure Update(const aDelta: Single); override;
  property Allowed: Boolean read pm_GetAllowed write pm_SetAllowed;
  property Enabled: Boolean read pm_GetEnabled write pm_SetEnabled;
  property MenuAlign: Td2dAlign read pm_GetMenuAlign write pm_SetMenuAlign;
  property TargetProcessor: Tf2SingleTargetProcessor read f_TargetProcessor;
 end;

 Tf2ImageButtonDecorator = class(Tf2CustomButtonDecorator)
 private
  f_TextureName: string;
  f_TexX: Integer;
  f_TexY: Integer;
 protected
  procedure LoadButton(const aFiler: Td2dFiler; const aContext: TFURQContext); override;
  function pm_GetDecoratorType: Tf2DecorType; override;
  procedure SaveButton(const aFiler: Td2dFiler); override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext; const aTexName: string; aTx, aTy,
   aWidth, aHeight: Integer);
 end;

 Tf2TextButtonDecorator = class(Tf2CustomButtonDecorator)
 private
  f_TextFrame: string;
  function pm_GetText: string;
  function pm_GetTextAlign: Td2dTextAlignType;
  procedure pm_SetText(const Value: string);
  procedure pm_SetTextAlign(const Value: Td2dTextAlignType);
  procedure pm_SetWidth(const Value: Single);
 protected
  procedure LoadButton(const aFiler: Td2dFiler; const aContext: TFURQContext); override;
  function pm_GetDecoratorType: Tf2DecorType; override;
  function pm_GetWidth: Single; override;
  procedure SaveButton(const aFiler: Td2dFiler); override;
 public
  constructor Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext; const aTextFrame, aText: string);
  property Text: string read pm_GetText write pm_SetText;
  property TextAlign: Td2dTextAlignType read pm_GetTextAlign write pm_SetTextAlign;
  property Width: Single read pm_GetWidth write pm_SetWidth;
 end;

implementation

uses
 SysUtils,
 d2dCore,
 d2dGIF,

 furqBase,
 f2Context,
 f2LinkParser, d2dGUI;

const
 cPi180 = Pi / 180;

procedure Tf2BaseDecorator.BlendPosition(const aTargetX, aTargetY: Single; const aTime: Single);
begin
 if f_PositionBlender <> nil then
  FreeAndNil(f_PositionBlender);
 f_PositionBlender := Td2dPositionBlender.Create(aTime, D2DPoint(f_PosX, f_PosY), D2DPoint(aTargetX, aTargetY));
 f_PositionBlender.Run; 
end;

constructor Tf2BaseDecorator.Create(const aPosX, aPosY, aPosZ: Single);
begin
 inherited Create;
 f_PosX := aPosX;
 f_PosY := aPosY;
 f_PosZ := aPosZ;
 f_Visible := True;
end;

constructor Tf2BaseDecorator.Load(aFiler: Td2dFiler);
begin
 inherited Create;
 with aFiler do
 begin
  f_PosX := ReadSingle;
  f_PosY := ReadSingle;
  f_PosZ := ReadSingle;
  f_Visible := ReadBoolean;
  if ReadBoolean then
   f_PositionBlender := Td2dPositionBlender.Load(aFiler);
  if ReadBoolean then
  begin
   f_ScriptDelay := ReadSingle;
   f_ScriptPos := ReadInteger;
   f_Script := LoadDSOperators(aFiler);
  end;
 end;
end;

procedure Tf2BaseDecorator.Cleanup;
begin
 ClearPositionBlender;
 inherited;
end;

function Tf2BaseDecorator.AsActionDecorator: If2ActionDecorator;
begin
 Result := nil;
end;

procedure Tf2BaseDecorator.UpdatePositionBlending(const aDelta: Single);
begin
 if f_PositionBlender <> nil then
 begin
  f_PositionBlender.Update(aDelta);
  DoSetPosX(Int(f_PositionBlender.Current.X));
  DoSetPosY(Int(f_PositionBlender.Current.Y));
  if not f_PositionBlender.IsRunning then
    FreeAndNil(f_PositionBlender);
 end;
end;

procedure Tf2BaseDecorator.ClearPositionBlender;
begin
 if f_PositionBlender <> nil then
  FreeAndNil(f_PositionBlender);
end;

procedure Tf2BaseDecorator.DoExecuteScriptOperator(const aOp: If2DSOperator);
var
 l_X, l_Y: Single;
 l_Time : Single;
begin
 case aOp.OpType of
  otMove:
   begin
    l_X := aOp.Params[0].GetValue;
    l_Y := aOp.Params[1].GetValue;
    if aOp.IsRelative then
    begin
     l_X := l_X + PosX;
     l_Y := l_Y + PosY;
    end;
    if aOp.ParamCount = 3 then
    begin
     l_Time := aOp.Params[2].GetValue/1000;
     BlendPosition(l_X, l_Y, l_Time);
     if not aOp.IsAsync then
      ScriptDelay := l_Time;
    end
    else
    begin
     PosX := l_X;
     PosY := l_Y;
    end;
   end;

  otPause:
   ScriptDelay := aOp.Params[0].GetValue/1000;
   
  otRestart:
   f_ScriptPos := -1; // потому что потом будет Inc, а нам нужен 0

  otDelete:
   f_ToDie := True;  
 end;
end;

procedure Tf2BaseDecorator.DoSetPosX(const Value: Single);
begin
 f_PosX := Value;
end;

procedure Tf2BaseDecorator.DoSetPosY(const Value: Single);
begin
 f_PosY := Value;
end;

procedure Tf2BaseDecorator.ExecuteNextScriptOp;
var
 l_Op: If2DSOperator;
begin
 while True do
 begin
  l_Op := f_Script[f_ScriptPos] as If2DSOperator;
  DoExecuteScriptOperator(l_Op);
  Inc(f_ScriptPos);
  if f_ScriptPos >= f_Script.Count then
  begin
   f_Script := nil;
   Exit;
  end;
  if (not l_Op.IsAsync) or f_ToDie then
   Break;
 end;
end;

function Tf2BaseDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtInvalid;
end;

procedure Tf2BaseDecorator.pm_SetPosX(const Value: Single);
begin
 ClearPositionBlender;
 DoSetPosX(Value);
end;

procedure Tf2BaseDecorator.pm_SetPosY(const Value: Single);
begin
 ClearPositionBlender;
 DoSetPosY(Value);
end;

procedure Tf2BaseDecorator.pm_SetPosZ(const Value: Single);
begin
 f_PosZ := Value;
 if f_List <> nil then
  f_List.Sort;
end;

procedure Tf2BaseDecorator.pm_SetScript(const Value: IInterfaceList);
begin
 f_Script := Value;
 f_ScriptDelay := 0;
 f_ScriptPos := 0;
 if f_Script <> nil then
  ExecuteNextScriptOp;
end;

procedure Tf2BaseDecorator.ProcessScript(const aDelta: Single);
begin
 if f_Script <> nil then
 begin
  f_ScriptDelay := f_ScriptDelay - aDelta;
  if f_ScriptDelay <= 0 then
  begin
   f_ScriptDelay := 0;
   ExecuteNextScriptOp;
  end;
 end;
end;

procedure Tf2BaseDecorator.Render;
begin
 if f_Visible then
  DoRender;
end;

procedure Tf2BaseDecorator.Save(aFiler: Td2dFiler);
var
 l_NotNil: Boolean;
begin
 with aFiler do
 begin
  WriteSingle(f_PosX);
  WriteSingle(f_PosY);
  WriteSingle(f_PosZ);
  WriteBoolean(f_Visible);

  l_NotNil := f_PositionBlender <> nil;
  WriteBoolean(l_NotNil);
  if l_NotNil then
   f_PositionBlender.Save(aFiler);

  l_NotNil := f_Script <> nil;
  WriteBoolean(l_NotNil);
  if l_NotNil then
  begin
   WriteSingle(f_ScriptDelay);
   WriteInteger(f_ScriptPos);
   SaveDSOperators(f_Script, aFiler);
  end;
 end;
end;

procedure Tf2BaseDecorator.Update(const aDelta: Single);
begin
 UpdatePositionBlending(aDelta);
 ProcessScript(aDelta);
end;

constructor Tf2DecoratorList.Create;
begin
 inherited;
 CaseSensitive := False;
end;

destructor Tf2DecoratorList.Destroy;
begin
 ClearObjects;
 inherited Destroy;
end;

procedure Tf2DecoratorList.AddDecorator(const aName: string; const aDecorator: Tf2BaseDecorator);
var
 l_Idx: Integer;
begin
 l_Idx := IndexOf(aName);
 if l_Idx <> -1 then
 begin
  Objects[l_Idx].Free;
  Objects[l_Idx] := aDecorator;
 end
 else
  AddObject(aName, aDecorator);
 aDecorator.f_List := Self;
 Sort;
end;

procedure Tf2DecoratorList.Clear;
begin
 ClearObjects;
 inherited Clear;
end;

procedure Tf2DecoratorList.ClearObjects;
var
 I: Integer;
begin
 for I := 0 to Pred(Count) do
  if Objects[I] <> nil then
   Objects[I].Free;
end;

procedure Tf2DecoratorList.Delete(Index: Integer);
begin
 if Objects[Index] <> nil then
   Objects[Index].Free;
 inherited Delete(Index);
end;

function Tf2DecoratorList.pm_GetDecorators(Index: Integer): Tf2BaseDecorator;
begin
 Result := Tf2BaseDecorator(Objects[Index]);
end;

function CompareDecorators(List: TStringList; Index1, Index2: Integer): Integer;
var
 l_D1, l_D2: Tf2BaseDecorator;
begin
 l_D1 := Tf2DecoratorList(List).Decorators[Index1];
 l_D2 := Tf2DecoratorList(List).Decorators[Index2];
 if l_D1.PosZ > l_D2.PosZ then
  Result := -1
 else
  if l_D1.PosZ < l_D2.PosZ then
   Result := 1
  else
   Result := 0;
end;

procedure Tf2DecoratorList.Load(aFiler: Td2dFiler; aContext: TFURQContext);
var
 I, l_N: Integer;
 l_Name: string;
 l_Type: Tf2DecorType;
 l_Decor: Tf2BaseDecorator;
begin
 Clear;
 l_N := aFiler.ReadInteger;
 for I := 1 to l_N do
 begin
  l_Name := aFiler.ReadString;
  l_Type := Tf2DecorType(aFiler.ReadInteger);
  case l_Type of
   dtText       : l_Decor := Tf2TextDecorator.Load(aFiler, aContext);
   dtRectangle  : l_Decor := Tf2RectangleDecorator.Load(aFiler);
   dtPicture    : l_Decor := Tf2SpriteDecorator.Load(aFiler);
   dtAnimation  : l_Decor := Tf2AnimationDecorator.Load(aFiler);
   dtGIF        : l_Decor := Tf2GIFDecorator.Load(aFiler);
   dtClickArea  : l_Decor := Tf2ClickAreaDecorator.Load(aFiler, aContext);
   dtImgButton  : l_Decor := Tf2ImageButtonDecorator.Load(aFiler, aContext);
   dtTextButton : l_Decor := Tf2TextButtonDecorator.Load(aFiler, aContext);
  else
   l_Decor := nil;
  end;
  if l_Decor <> nil then
   AddDecorator(l_Name, l_Decor);
 end;
end;

procedure Tf2DecoratorList.Save(aFiler: Td2dFiler);
var
 I: Integer;
 l_Type: Tf2DecorType;
begin
 aFiler.WriteInteger(Count);
 for I := 0 to Pred(Count) do
 begin
  aFiler.WriteString(Strings[I]);
  l_Type := Decorators[I].DecoratorType;
  Assert(l_Type <> dtInvalid, 'Запись неизвестного типа декоратора!');
  aFiler.WriteInteger(Integer(l_Type));
  Decorators[I].Save(aFiler);
 end;
end;

procedure Tf2DecoratorList.Sort;
begin
 CustomSort(CompareDecorators);
end;

procedure Tf2DecoratorList.Update(aDelta: Single);
var
 I: Integer;
begin
 I := 0;
 while I < Count do
 begin
  Decorators[I].Update(aDelta);
  if Decorators[I].ToDie then
   Delete(I)
  else
   Inc(I); 
 end;
end;

constructor Tf2TextDecorator.Create(const aContext: TFURQContext;
                                    const aPosX, aPosY, aPosZ: Single;
                                    const aColor: Td2dColor;
                                    const aLinkColor, aLinkHColor: Td2dColor;
                                    const aText: string;
                                    const aFontName: string;
                                          aFontPool: Tf2FontPool);
var
 l_Font: Id2dFont;
begin
 inherited Create(aPosX, aPosY, aPosZ, aColor);
 f_Context := aContext;
 f_FontName := aFontName;
 l_Font := aFontPool.GetFont(f_FontName);
 if l_Font = nil then
  l_Font := aFontPool.SysTextFont;
 f_StaticText := Td2dStaticText.Create(l_Font, f_Color);
 f_StaticText.LinkColor := aLinkColor;
 f_StaticText.LinkHColor := aLinkHColor;
 f_StaticText.X := PosX;
 f_StaticText.Y := PosY;
 f_StaticText.OnLinkClick := _ClickHandler;
 f_Actions := JclStringList;
 f_Allowed := True;
 f_LinksEnabled := True;
 f_MenuAlign := alBottomLeft;
 Text := aText; 
end;

constructor Tf2TextDecorator.Load(aFiler: Td2dFiler; aContext: TFURQContext);
var
 l_Font: Id2dFont;
 l_Text: string;
begin
 inherited Load(aFiler);
 f_Context := aContext;
 f_Actions := JclStringList;
 f_FontName := aFiler.ReadString;
 l_Font := Tf2Context(f_Context).FontPool.GetFont(f_FontName);
 if l_Font = nil then
  l_Font := Tf2Context(f_Context).FontPool.SysTextFont;
 l_Text := aFiler.ReadString;
 f_StaticText := Td2dStaticText.Create(l_Font, f_Color);
 f_StaticText.X := PosX;
 f_StaticText.Y := PosY;
 f_StaticText.Align := Td2dTextAlignType(aFiler.ReadInteger);
 f_StaticText.AutoWidth := aFiler.ReadBoolean;
 if not f_StaticText.AutoWidth then
  f_StaticText.Width := aFiler.ReadSingle;
 f_StaticText.LinkColor := aFiler.ReadColor;
 f_StaticText.LinkHColor := aFiler.ReadColor;
 f_LinksEnabled := aFiler.ReadBoolean;
 f_MenuAlign := Td2dAlign(aFiler.ReadByte);
 f_StaticText.OnLinkClick := _ClickHandler;
 UpdateLinksState;
 if aFiler.ReadBoolean then
  f_LinkColorBlender := Td2dColorBlender.Load(aFiler);
 if aFiler.ReadBoolean then
  f_LinkHColorBlender := Td2dColorBlender.Load(aFiler);
 Text := l_Text;
 OnAction := Tf2Context(aContext).OnDecoratorAction; 
end;

procedure Tf2TextDecorator.Cleanup;
begin
 FreeAndNil(f_StaticText);
 FreeAndNil(f_LinkColorBlender);
 FreeAndNil(f_LinkHColorBlender);
 inherited;
end;

function Tf2TextDecorator.AsActionDecorator: If2ActionDecorator;
begin
 Result := Self;
end;

procedure Tf2TextDecorator.BlendLinkColors(const aTargetLinkColor, aTargetLinkHColor: Td2dColor; const aTime: Single);
begin
 if f_LinkColorBlender <> nil then
  FreeAndNil(f_LinkColorBlender);
 f_LinkColorBlender := Td2dColorBlender.Create(aTime, LinkColor, aTargetLinkColor);
 if f_LinkHColorBlender <> nil then
  FreeAndNil(f_LinkHColorBlender);
 f_LinkHColorBlender := Td2dColorBlender.Create(aTime, LinkHColor, aTargetLinkHColor);
 f_LinkColorBlender.Run;
 f_LinkHColorBlender.Run;
end;

procedure Tf2TextDecorator.DoExecuteScriptOperator(const aOp: If2DSOperator);
var
 l_Time: Single;
begin
 if (aOp.OpType = otColor) then
 begin
  if (aOp.ParamCount = 1) or ((aOp.ParamCount = 2) and (aOp.Params[1].GetValue <= 0)) then
   Color := CorrectColor(Trunc(aOp.Params[0].GetValue))
  else
  if (aOp.ParamCount = 2) then
  begin
   l_Time := aOp.Params[1].GetValue/1000;
   BlendColor(CorrectColor(Trunc(aOp.Params[0].GetValue)), l_Time);
   if not aOp.IsAsync then
    ScriptDelay := l_Time;
  end
  else
  if (aOp.ParamCount = 3) or ((aOp.ParamCount = 4) and (aOp.Params[3].GetValue <= 0)) then
  begin
   Color      := CorrectColor(Trunc(aOp.Params[0].GetValue));
   LinkColor  := CorrectColor(Trunc(aOp.Params[1].GetValue));
   LinkHColor := CorrectColor(Trunc(aOp.Params[2].GetValue));
  end
  else
  begin
   l_Time := aOp.Params[3].GetValue/1000;
   BlendColor(CorrectColor(Trunc(aOp.Params[0].GetValue)), l_Time);
   BlendLinkColors(CorrectColor(Trunc(aOp.Params[1].GetValue)), CorrectColor(Trunc(aOp.Params[2].GetValue)), l_Time);
   if not aOp.IsAsync then
    ScriptDelay := l_Time;
  end;
 end
 else
  inherited DoExecuteScriptOperator(aOp);
end;

procedure Tf2TextDecorator.DoRender;
begin
 f_StaticText.Render;
end;

procedure Tf2TextDecorator.DoSetColor(aColor: Td2dColor);
begin
 inherited DoSetColor(aColor);
 if f_StaticText.TextColor <> aColor then
 begin
  f_StaticText.TextColor := aColor;
  if (f_StaticText.LinkColor and $FF000000) <> (aColor and $FF000000) then
   f_StaticText.LinkColor := (aColor and $FF000000) or (f_StaticText.LinkColor and $00FFFFFF);
  if (f_StaticText.LinkHColor and $FF000000) <> (aColor and $FF000000) then
   f_StaticText.LinkHColor := (aColor and $FF000000) or (f_StaticText.LinkHColor and $00FFFFFF);
 end;
end;

function Tf2TextDecorator.GetActionsData(const anID: string): IFURQActionData;
var
 l_Idx: Integer;
begin
 Result := nil;
 l_Idx := f_Actions.IndexOf(anID);
 if l_Idx >= 0 then
  Result := f_Actions.Interfaces[l_Idx] as IFURQActionData;
end;

function Tf2TextDecorator.pm_GetAlign: Td2dTextAlignType;
begin
 Result := f_StaticText.Align;
end;

function Tf2TextDecorator.pm_GetFont: Id2dFont;
begin
 Result := f_StaticText.Font;
end;

function Tf2TextDecorator.pm_GetHeight: Single;
begin
 Result := f_StaticText.Height;
end;

function Tf2TextDecorator.pm_GetLineSpacing: Single;
begin
 Result := f_StaticText.LineSpacing;
end;

function Tf2TextDecorator.pm_GetLinkColor: Td2dColor;
begin
 Result := f_StaticText.LinkColor;
end;

function Tf2TextDecorator.pm_GetLinkHColor: Td2dColor;
begin
 Result := f_StaticText.LinkHColor;
end;

function Tf2TextDecorator.pm_GetParaSpacing: Single;
begin
 Result := f_StaticText.ParaSpacing;
end;

function Tf2TextDecorator.pm_GetText: string;
begin
 Result := f_Text;
end;

function Tf2TextDecorator.pm_GetWidth: Single;
begin
 Result := f_StaticText.Width;
end;

procedure Tf2TextDecorator.pm_SetAlign(const Value: Td2dTextAlignType);
begin
 f_StaticText.Align := Value;
end;

procedure Tf2TextDecorator.pm_SetFont(const Value: Id2dFont);
begin
 f_StaticText.Font := Value;
end;

procedure Tf2TextDecorator.pm_SetLineSpacing(const Value: Single);
begin
 f_StaticText.LineSpacing := Value;
end;

procedure Tf2TextDecorator.pm_SetLinkColor(const Value: Td2dColor);
begin
 f_StaticText.LinkColor := (Value and $FFFFFF) or (f_Color and $FF000000);
end;

procedure Tf2TextDecorator.pm_SetLinkHColor(const Value: Td2dColor);
begin
 f_StaticText.LinkHColor := (Value and $FFFFFF) or (f_Color and $FF000000);;
end;

procedure Tf2TextDecorator.pm_SetParaSpacing(const Value: Single);
begin
 f_StaticText.ParaSpacing := Value;
end;

procedure Tf2TextDecorator.DoSetPosX(const Value: Single);
begin
 inherited DoSetPosX(Value);
 f_StaticText.X := PosX;
end;

procedure Tf2TextDecorator.DoSetPosY(const Value: Single);
begin
 inherited DoSetPosY(Value);
 f_StaticText.Y := PosY;
end;

function Tf2TextDecorator.pm_GetAllowed: Boolean;
begin
 Result := f_Allowed;
end;

function Tf2TextDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtText;
end;

function Tf2TextDecorator.pm_GetLinksEnabled: Boolean;
begin
 Result := f_LinksEnabled;
end;

function Tf2TextDecorator.pm_GetMenuAlign: Td2dAlign;
begin
 Result := f_MenuAlign;
end;

procedure Tf2TextDecorator.pm_SetAllowed(const Value: Boolean);
begin
 f_Allowed := Value;
 UpdateLinksState;
end;

procedure Tf2TextDecorator.pm_SetLinksEnabled(const Value: Boolean);
begin
 f_LinksEnabled := Value;
 UpdateLinksState;
end;

procedure Tf2TextDecorator.pm_SetMenuAlign(const Value: Td2dAlign);
begin
 f_MenuAlign := Value;
end;

procedure Tf2TextDecorator.pm_SetText(const Value: string);
begin
 f_Actions.Clear;
 f_StaticText.StartText;
 try
  OutTextWithLinks(Value, f_StaticText, f_Context, f_Actions);
 finally
  f_StaticText.EndText;
 end;
 f_Text := Value;
end;

procedure Tf2TextDecorator.pm_SetWidth(const Value: Single);
begin
 if Value = 0 then
  f_StaticText.AutoWidth := True
 else
 begin
  f_StaticText.AutoWidth := False;
  f_StaticText.Width := Value;
 end;
end;

procedure Tf2TextDecorator.ProcessEvent(var theEvent: Td2dInputEvent);
begin
 f_StaticText.ProcessEvent(theEvent);
end;

procedure Tf2TextDecorator.Save(aFiler: Td2dFiler);
var
 l_NotNil: Boolean;
begin
 inherited Save(aFiler);
 aFiler.WriteString(f_FontName);
 aFiler.WriteString(Text);
 aFiler.WriteInteger(Ord(Align));
 aFiler.WriteBoolean(f_StaticText.AutoWidth);
 if not f_StaticText.AutoWidth then
  aFiler.WriteSingle(Width);
 aFiler.WriteColor(LinkColor);
 aFiler.WriteColor(LinkHColor);
 aFiler.WriteBoolean(f_LinksEnabled);
 aFiler.WriteByte(Ord(f_MenuAlign));
 l_NotNil := f_LinkColorBlender <> nil;
 aFiler.WriteBoolean(l_NotNil);
 if l_NotNil then
  f_LinkColorBlender.Save(aFiler);
 l_NotNil := f_LinkHColorBlender <> nil;
 aFiler.WriteBoolean(l_NotNil);
 if l_NotNil then
  f_LinkHColorBlender.Save(aFiler);
end;

procedure Tf2TextDecorator.Update(const aDelta: Single);
begin
 if f_LinkColorBlender <> nil then
 begin
  f_LinkColorBlender.Update(aDelta);
  LinkColor := f_LinkColorBlender.Current;
  if not f_LinkColorBlender.IsRunning then
   FreeAndNil(f_LinkColorBlender);
 end;
 if f_LinkHColorBlender <> nil then
 begin
  f_LinkHColorBlender.Update(aDelta);
  LinkHColor := f_LinkHColorBlender.Current;
  if not f_LinkHColorBlender.IsRunning then
   FreeAndNil(f_LinkHColorBlender);
 end;
 inherited;
end;

procedure Tf2TextDecorator.UpdateLinksState;
begin
 f_StaticText.LinksEnabled := f_Allowed and f_LinksEnabled;
end;

procedure Tf2TextDecorator._ClickHandler(const aSender: TObject; const aRect: Td2dRect; const aTarget: string);
begin
 if Assigned(f_OnAction) then
  f_OnAction(aTarget, aRect, f_MenuAlign);
end;

constructor Tf2GraphicDecorator.Create(const aPosX, aPosY, aPosZ: Single; const aColor: Td2dColor);
begin
 inherited;
 f_Scale := 1.0;
end;

constructor Tf2GraphicDecorator.Load(aFiler: Td2dFiler);
begin
 inherited Load(aFiler);
 with aFiler do
 begin
  f_Angle := ReadSingle;
  f_AngleRad := ReadSingle;
  f_HotX := ReadInteger;
  f_HotY := ReadInteger;
  f_Scale := ReadSingle;
  if ReadBoolean then
   f_RotationBlender := Td2dSimpleBlender.Load(aFiler)
  else
   f_RotSpeed := ReadSingle;
  if ReadBoolean then
   f_ScaleBlender := Td2dSimpleBlender.Load(aFiler)
 end;
end;

procedure Tf2GraphicDecorator.Cleanup;
begin
 ClearRotationBlender;
 inherited;
end;

procedure Tf2GraphicDecorator.BlendAngle(const aDelta: Single; aTime: Single);
begin
 ClearRotationBlender;
 f_RotSpeed := 0;
 f_RotationBlender := Td2dSimpleBlender.Create(aTime, Angle, Angle + aDelta);
 f_RotationBlender.Run;
end;

procedure Tf2GraphicDecorator.BlendScale(const aTargetScale: Single; aTime: Single);
begin
 ClearScaleBlender;
 f_ScaleBlender := Td2dSimpleBlender.Create(aTime, Scale, aTargetScale);
 f_ScaleBlender.Run;
end;

procedure Tf2GraphicDecorator.ClearRotationBlender;
begin
 if f_RotationBlender <> nil then
  FreeAndNil(f_RotationBlender);
end;

procedure Tf2GraphicDecorator.ClearScaleBlender;
begin
 if f_ScaleBlender <> nil then
  FreeAndNil(f_ScaleBlender);
end;

procedure Tf2GraphicDecorator.DoExecuteScriptOperator(const aOp: If2DSOperator);
var
 l_Time: Single;
 l_Value: Single;
begin
 case aOp.OpType of
  otRotate:
   begin
    l_Value := aOp.Params[0].GetValue;
    if not aOp.IsRelative then
     Angle := l_Value
    else
    begin
     if aOp.ParamCount = 2 then
     begin
      l_Time := aOp.Params[1].GetValue/1000;
      BlendAngle(l_Value, l_Time);
      if not aOp.IsAsync then
       ScriptDelay := l_Time;
     end
     else
      Angle := Angle + l_Value;
    end;
   end;

  otScale:
   begin
    l_Value := aOp.Params[0].GetValue;
    if aOp.ParamCount = 2 then
    begin
     l_Time := aOp.Params[1].GetValue/1000;
     BlendScale(l_Value, l_Time);
     if not aOp.IsAsync then
      ScriptDelay := l_Time;
    end
    else
     Scale := l_Value;
   end;

  otRotateSpeed: RotSpeed := aOp.Params[0].GetValue;

 else
  inherited DoExecuteScriptOperator(aOp);
 end;
end;

procedure Tf2GraphicDecorator.pm_SetAngle(const Value: Single);
begin
 f_RotSpeed := 0;
 ClearRotationBlender;
 SetAnglePrim(Value);
end;

procedure Tf2GraphicDecorator.pm_SetHotX(const aHotX: Integer);
begin
 f_HotX := aHotX;
end;

procedure Tf2GraphicDecorator.pm_SetHotY(const aHotY: Integer);
begin
 f_HotY := aHotY;
end;

procedure Tf2GraphicDecorator.pm_SetRotSpeed(const Value: Single);
begin
 ClearRotationBlender;
 f_RotSpeed := Value;
end;

procedure Tf2GraphicDecorator.pm_SetScale(const Value: Single);
begin
 ClearScaleBlender;
 f_Scale := Value;
end;

procedure Tf2GraphicDecorator.Save(aFiler: Td2dFiler);
var
 l_NotNil: Boolean;
begin
 inherited Save(aFiler);
 with aFiler do
 begin
  WriteSingle(f_Angle);
  WriteSingle(f_AngleRad);
  WriteInteger(f_HotX);
  WriteInteger(f_HotY);
  WriteSingle(f_Scale);
  l_NotNil := f_RotationBlender <> nil;
  WriteBoolean(l_NotNil);
  if l_NotNil then
   f_RotationBlender.Save(aFiler)
  else
   WriteSingle(f_RotSpeed);
  l_NotNil := f_ScaleBlender <> nil;
  WriteBoolean(l_NotNil);
  if l_NotNil then
   f_ScaleBlender.Save(aFiler);
 end;
end;

procedure Tf2GraphicDecorator.SetAnglePrim(aAngle: Single);
begin
 f_Angle := aAngle;
 if (f_Angle >= 360) or (f_Angle <= -360) then
  f_Angle := f_Angle - Int(f_Angle/360) * 360;
 if f_Angle < 0 then
  f_Angle := 360 + f_Angle;
 f_AngleRad := f_Angle * cPi180;
end;

procedure Tf2GraphicDecorator.Update(const aDelta: Single);
begin
 if f_RotSpeed <> 0 then
  SetAnglePrim(Angle + f_RotSpeed * aDelta);
 if f_RotationBlender <> nil then
 begin
  f_RotationBlender.Update(aDelta);
  SetAnglePrim(f_RotationBlender.Current);
  if not f_RotationBlender.IsRunning then
   ClearRotationBlender;
 end;
 if f_ScaleBlender <> nil then
 begin
  f_ScaleBlender.Update(aDelta);
  f_Scale := f_ScaleBlender.Current;
  if not f_ScaleBlender.IsRunning then
   ClearScaleBlender;
 end;
 inherited Update(aDelta);
end;

constructor Tf2BasicSpriteDecorator.Load(aFiler: Td2dFiler);
begin
 inherited Load(aFiler);
 f_FlipX := aFiler.ReadBoolean;
 f_FlipY := aFiler.ReadBoolean;
end;

procedure Tf2BasicSpriteDecorator.ApplyFlips;
begin
 // это нужно для Load в наследниках, потому что данные о флипах
 // загружаются раньше, чем создаётся сам спрайт
 f_Sprite.FlipX := f_FlipX;
 f_Sprite.FlipY := f_FlipY;
end;

procedure Tf2BasicSpriteDecorator.Cleanup;
begin
 f_Sprite.Free;
end;

procedure Tf2BasicSpriteDecorator.DoRender;
begin
 f_Sprite.RenderEx(f_PosX, f_PosY, f_AngleRad, f_Scale);
end;

procedure Tf2BasicSpriteDecorator.DoSetColor(aColor: Td2dColor);
begin
 inherited;
 f_Sprite.SetColor(aColor);
end;

function Tf2BasicSpriteDecorator.pm_GetHeight: Single;
begin
 Result := f_Sprite.Height;
end;

function Tf2BasicSpriteDecorator.pm_GetWidth: Single;
begin
 Result := f_Sprite.Width;
end;

procedure Tf2BasicSpriteDecorator.pm_SetFlipX(const Value: Boolean);
begin
 f_FlipX := Value;
 f_Sprite.FlipX := Value;
end;

procedure Tf2BasicSpriteDecorator.pm_SetFlipY(const Value: Boolean);
begin
 f_FlipY := Value;
 f_Sprite.FlipY := Value;
end;

procedure Tf2BasicSpriteDecorator.pm_SetHotX(const aHotX: Integer);
begin
 inherited pm_SetHotX(aHotX);
 f_Sprite.HotX := f_HotX;
end;

procedure Tf2BasicSpriteDecorator.pm_SetHotY(const aHotY: Integer);
begin
 inherited pm_SetHotY(aHotY);
 f_Sprite.HotY := f_HotY;
end;

procedure Tf2BasicSpriteDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 aFiler.WriteBoolean(FlipX);
 aFiler.WriteBoolean(FlipY);
end;

constructor Tf2RectangleDecorator.Create(const aPosX, aPosY, aPosZ: Single;
    aWidth, aHeight: Integer; const aColor: Td2dColor);
begin
 inherited Create(aPosX, aPosY, aPosZ, aColor);
 f_Sprite := Td2dRectangle.Create(aWidth, aHeight, aColor);
end;

constructor Tf2RectangleDecorator.Load(aFiler: Td2dFiler);
var
 l_W, l_H: Integer;
begin
 inherited Load(aFiler);
 l_W := aFiler.ReadInteger;
 l_H := aFiler.ReadInteger;
 f_Sprite := Td2dRectangle.Create(l_W, l_H, f_Color);
 f_Sprite.HotX := f_HotX;
 f_Sprite.HotY := f_HotY;
 f_Sprite.SetColor(f_Color);
end;

function Tf2RectangleDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtRectangle;
end;

procedure Tf2RectangleDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 aFiler.WriteInteger(Trunc(f_Sprite.Width));
 aFiler.WriteInteger(Trunc(f_Sprite.Height));
end;

constructor Tf2SpriteDecorator.Create(const aPosX, aPosY, aPosZ: Single; aTexName: string;
                                      aTX, aTY, aWidth, aHeight: Integer);
var
 l_Tex: Id2dTexture;
begin
 inherited Create(aPosX, aPosY, aPosZ, $FFFFFFFF);
 f_TexName := aTexName;
 l_Tex := gD2DE.Texture_Load(aTexName);
 if l_Tex <> nil then
 begin
  if (aWidth = 0) then
   aWidth := gD2DE.Texture_GetWidth(l_Tex) - aTX;
  if (aHeight = 0) then
   aHeight := gD2DE.Texture_GetHeight(l_Tex) - aTY;
  if (aWidth < 1) or (aHeight < 1) then
  begin
   aWidth := 0;
   aHeight := 0;
  end;
 end;
 with f_InitRec do
 begin
  rTX := aTX;
  rTY := aTY;
  rWidth := aWidth;
  rHeight:= aHeight;
 end;
 f_Sprite := Td2dSprite.Create(l_Tex, aTX, aTY, aWidth, aHeight);
end;

constructor Tf2SpriteDecorator.Load(aFiler: Td2dFiler);
var
 l_Tex: Id2dTexture;
begin
 inherited Load(aFiler);
 f_TexName := aFiler.ReadString;
 aFiler.Stream.ReadBuffer(f_InitRec, SizeOf(Tf2SpriteInitDataRec));
 l_Tex := gD2DE.Texture_Load(f_TexName);
 with f_InitRec do
  f_Sprite := Td2dSprite.Create(l_Tex, rTX, rTY, rWidth, rHeight);
 f_Sprite.HotX := f_HotX;
 f_Sprite.HotY := f_HotY;
 f_Sprite.SetColor(f_Color);
 ApplyFlips;
end;

function Tf2SpriteDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtPicture;
end;

procedure Tf2SpriteDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 aFiler.WriteString(f_TexName);
 aFiler.Stream.WriteBuffer(f_InitRec, SizeOf(Tf2SpriteInitDataRec));
end;

constructor Tf2AnimationDecorator.Create(const aPosX, aPosY, aPosZ: Single; aTexName: string;
                                         const aTX, aTY, aWidth, aHeight, aFrames: Integer);
var
 l_Tex: Id2dTexture;
begin
 inherited Create(aPosX, aPosY, aPosZ, $FFFFFFFF);
 f_TexName := aTexName;
 l_Tex := gD2DE.Texture_Load(aTexName);
 f_Sprite := Td2dTimedAnimation.Create(l_Tex, aFrames, aTX, aTY, aWidth, aHeight);
 with f_InitRec do
 begin
  rTX := aTX;
  rTY := aTY;
  rWidth := aWidth;
  rHeight:= aHeight;
 end;
 AniType := 1;
 Speed := 250;
end;

constructor Tf2AnimationDecorator.Load(aFiler: Td2dFiler);
var
 l_Tex: Id2dTexture;
 l_Frames: Integer;
begin
 inherited Load(aFiler);
 f_TexName := aFiler.ReadString;
 aFiler.Stream.ReadBuffer(f_InitRec, SizeOf(Tf2SpriteInitDataRec));
 l_Tex := gD2DE.Texture_Load(f_TexName);
 l_Frames := aFiler.ReadInteger;
 with f_InitRec do
  f_Sprite := Td2dTimedAnimation.Create(l_Tex, l_Frames, rTX, rTY, rWidth, rHeight);
 AniType := aFiler.ReadInteger;
 Td2dTimedAnimation(f_Sprite).CurFrame := aFiler.ReadInteger;
 Speed := aFiler.ReadSingle;
 f_Sprite.SetColor(f_Color);
 Td2dTimedAnimation(f_Sprite).TimeSinceLastFrame := aFiler.ReadDouble;
 f_Sprite.HotX := f_HotX;
 f_Sprite.HotY := f_HotY;
 f_Sprite.SetColor(f_Color);
 ApplyFlips;
end;

function Tf2AnimationDecorator.pm_GetAniType: Integer;
begin
 Result := f_AniType;
end;

function Tf2AnimationDecorator.pm_GetCurFrame: Integer;
begin
 Result := Td2dTimedAnimation(f_Sprite).CurFrame;
end;

function Tf2AnimationDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtAnimation;
end;

function Tf2AnimationDecorator.pm_GetSpeed: Single;
begin
 if Td2dTimedAnimation(f_Sprite).Playing then
 begin
  Result := Int(Td2dTimedAnimation(f_Sprite).Speed * 1000);
  if Td2dTimedAnimation(f_Sprite).Reverse then
   Result := -Result;
 end
 else
  Result := 0;
end;

procedure Tf2AnimationDecorator.pm_SetAniType(Value: Integer);
begin
 if Value < 0 then Value := 0;
 if Value > 2 then Value := 2;    
 case Value of
  0:
  begin
   Td2dTimedAnimation(f_Sprite).Looped := False;
  end;

  1:
  begin
   Td2dTimedAnimation(f_Sprite).Looped := True;
   Td2dTimedAnimation(f_Sprite).LoopType := lt_OverAgain;
  end;

  2:
  begin
   Td2dTimedAnimation(f_Sprite).Looped := True;
   Td2dTimedAnimation(f_Sprite).LoopType := lt_PingPong;
  end;
 end;
 f_AniType := Value;
end;

procedure Tf2AnimationDecorator.pm_SetCurFrame(const Value: Integer);
begin
 Td2dTimedAnimation(f_Sprite).Stop;
 Td2dTimedAnimation(f_Sprite).CurFrame := Value;
end;

procedure Tf2AnimationDecorator.pm_SetSpeed(const Value: Single);
begin
 if Value = 0.0 then
  Td2dTimedAnimation(f_Sprite).Stop
 else
 begin
  Td2dTimedAnimation(f_Sprite).Speed := Abs(Value)/1000;
  Td2dTimedAnimation(f_Sprite).Reverse := (Value < 0);
  Td2dTimedAnimation(f_Sprite).Resume;
 end; 
end;

procedure Tf2AnimationDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 aFiler.WriteString(f_TexName);
 aFiler.Stream.WriteBuffer(f_InitRec, SizeOf(Tf2SpriteInitDataRec));
 aFiler.WriteInteger(Td2dTimedAnimation(f_Sprite).FramesCount);
 aFiler.WriteInteger(f_AniType);
 aFiler.WriteInteger(CurFrame);
 aFiler.WriteSingle(Speed);
 aFiler.WriteDouble(Td2dTimedAnimation(f_Sprite).TimeSinceLastFrame);
end;

procedure Tf2AnimationDecorator.Update(const aDelta: Single);
begin
 Td2dTimedAnimation(f_Sprite).Update(aDelta);
 inherited Update(aDelta);
end;

constructor Tf2GIFDecorator.Create(const aPosX, aPosY, aPosZ: Single; aGIFName: string);
begin
 inherited Create(aPosX, aPosY, aPosZ, $FFFFFFFF);
 f_GIFName := aGIFName;
 f_Sprite := Td2dGIFSprite.Create(aGIFName);
end;

constructor Tf2GIFDecorator.Load(aFiler: Td2dFiler);
var
 l_Frame: Integer;
begin
 inherited Load(aFiler);
 f_GIFName := aFiler.ReadString;
 f_Sprite := Td2dGIFSprite.Create(f_GIFName);
 Td2dGIFSprite(f_Sprite).Stop; // для более точного восстановления кадра и скорости анимации
 try
  AniSpeed := aFiler.ReadInteger;
  l_Frame := aFiler.ReadInteger;
  Td2dGIFSprite(f_Sprite).Frame := l_Frame;
 finally
  Td2dGIFSprite(f_Sprite).Start;
 end;
 f_Sprite.HotX := f_HotX;
 f_Sprite.HotY := f_HotY;
 f_Sprite.SetColor(f_Color);
 ApplyFlips;
end;

function Tf2GIFDecorator.pm_GetAniSpeed: Integer;
begin
 Result := Td2dGIFSprite(f_Sprite).AniSpeed;
end;

function Tf2GIFDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtGIF;
end;

function Tf2GIFDecorator.pm_GetFrame: Integer;
begin
 Result := Td2dGIFSprite(f_Sprite).Frame;
end;

procedure Tf2GIFDecorator.pm_SetAniSpeed(const Value: Integer);
begin
 Td2dGIFSprite(f_Sprite).AniSpeed := Value;
end;

procedure Tf2GIFDecorator.pm_SetFrame(const Value: Integer);
begin
 Td2dGIFSprite(f_Sprite).Frame := Value;
 Td2dGIFSprite(f_Sprite).AniSpeed := 0;
end;

procedure Tf2GIFDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 aFiler.WriteString(f_GIFName);
 aFiler.WriteInteger(AniSpeed);
 aFiler.WriteInteger(Frame);
end;

procedure Tf2GIFDecorator.Update(const aDelta: Single);
begin
 Td2dGIFSprite(f_Sprite).Update(aDelta);
 inherited Update(aDelta);
end;

constructor Tf2ColoredDecorator.Create(const aPosX, aPosY, aPosZ: Single; const aColor: Td2dColor);
begin
 inherited Create(aPosX, aPosY, aPosZ);
 f_Color := aColor;
end;

constructor Tf2ColoredDecorator.Load(aFiler: Td2dFiler);
begin
 inherited Load(aFiler);
 with aFiler do
 begin
  f_Color := ReadColor;
  if ReadBoolean then
   f_ColorBlender := Td2dColorBlender.Load(aFiler);
 end;
end;

procedure Tf2ColoredDecorator.BlendColor(const aTargetColor: Td2dColor; const aTime: Single);
begin
 if f_ColorBlender <> nil then
  FreeAndNil(f_ColorBlender);
 f_ColorBlender := Td2dColorBlender.Create(aTime, f_Color, aTargetColor);
 f_ColorBlender.Run;
end;

procedure Tf2ColoredDecorator.Cleanup;
begin
 ClearColorBlender;
 inherited;
end;

procedure Tf2ColoredDecorator.ClearColorBlender;
begin
 if f_ColorBlender <> nil then
  FreeAndNil(f_ColorBlender);
end;

procedure Tf2ColoredDecorator.DoExecuteScriptOperator(const aOp: If2DSOperator);
var
 l_Color: Td2dColor;
 l_A, l_R, l_G, l_B: Integer;
 l_Time : Single;

 function CorrectColorPart(const aReal: Double): Integer;
 begin
  Result := Trunc(aReal) mod 256;
  if Result < 0 then
   Result := 0;
 end;

begin
 case aOp.OpType of
  otColor:
   begin
    l_Time := 0;
    if aOp.ParamCount <= 2 then
    begin
     l_Color := CorrectColor(Trunc(aOp.Params[0].GetValue));
     if aOp.ParamCount = 2 then
      l_Time := aOp.Params[1].GetValue/1000;
    end
    else
    begin
     l_A := CorrectColorPart(aOp.Params[0].GetValue);
     l_R := CorrectColorPart(aOp.Params[1].GetValue);
     l_G := CorrectColorPart(aOp.Params[2].GetValue);
     l_B := CorrectColorPart(aOp.Params[3].GetValue);
     l_Color := ARGB(l_A, l_R, l_G, l_B);
     if aOp.ParamCount = 5 then
      l_Time := aOp.Params[4].GetValue/1000;
    end;
    if l_Time = 0 then
     Color := l_Color
    else
    begin
     BlendColor(l_Color, l_Time);
     if not aOp.IsAsync then
      ScriptDelay := l_Time;
    end;
   end;
  else // case
   inherited DoExecuteScriptOperator(aOp);
 end;
end;

procedure Tf2ColoredDecorator.DoSetColor(aColor: Td2dColor);
begin
 f_Color := aColor;
end;

procedure Tf2ColoredDecorator.pm_SetColor(const Value: Td2dColor);
begin
 ClearColorBlender;
 DoSetColor(Value);
end;

procedure Tf2ColoredDecorator.Save(aFiler: Td2dFiler);
var
 l_NotNil: Boolean;
begin
 inherited Save(aFiler);
 with aFiler do
 begin
  WriteColor(f_Color);
  l_NotNil := f_ColorBlender <> nil;
  WriteBoolean(l_NotNil);
  if l_NotNil then
   f_ColorBlender.Save(aFiler);
 end;
end;

procedure Tf2ColoredDecorator.Update(const aDelta: Single);
begin
 UpdateColorBlending(aDelta);
 inherited;
end;

procedure Tf2ColoredDecorator.UpdateColorBlending(const aDelta: Single);
begin
 if f_ColorBlender <> nil then
 begin
  f_ColorBlender.Update(aDelta);
  DoSetColor(f_ColorBlender.Current);
  if not f_ColorBlender.IsRunning then
   FreeAndNil(f_ColorBlender);
 end;
end;

constructor Tf2ClickAreaDecorator.Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext; const aWidth, aHeight: Single);
begin
 inherited Create(aPosX, aPosY, aPosZ);
 f_TargetProcessor := Tf2SingleTargetProcessor.Create(aContext);
 Width := aWidth;
 Height := aHeight;
 f_Enabled := True;
 f_Allowed := True;
 f_MenuAlign := alTopLeft;
end;

constructor Tf2ClickAreaDecorator.Load(aFiler: Td2dFiler; aContext: TFURQContext);
begin
 inherited Load(aFiler);
 f_TargetProcessor := Tf2SingleTargetProcessor.Load(aFiler, aContext);
 f_Width  := aFiler.ReadSingle;
 f_Height := aFiler.ReadSingle;
 f_Enabled := aFiler.ReadBoolean;
 f_MenuAlign := Td2dAlign(aFiler.ReadByte);
 f_Allowed := True;
 RecalcRect;
end;

function Tf2ClickAreaDecorator.AsActionDecorator: If2ActionDecorator;
begin
 Result := Self;
end;

procedure Tf2ClickAreaDecorator.Cleanup;
begin
 FreeAndNil(f_TargetProcessor);
 inherited;
end;

procedure Tf2ClickAreaDecorator.DoRender;
begin
 // пусто
 //D2DRenderRect(f_Rect, $FFFF0000);
end;

procedure Tf2ClickAreaDecorator.DoSetPosX(const Value: Single);
begin
 inherited;
 RecalcRect;
 gD2DE.Input_TouchMousePos;
end;

procedure Tf2ClickAreaDecorator.DoSetPosY(const Value: Single);
begin
 inherited;
 RecalcRect;
 gD2DE.Input_TouchMousePos;
end;

function Tf2ClickAreaDecorator.GetActionsData(const anID: string): IFURQActionData;
begin
 Result := f_TargetProcessor.GetActionsData(anID);
end;

function Tf2ClickAreaDecorator.GetTargetProcessor: Tf2SingleTargetProcessor;
begin
 Result := f_TargetProcessor;
end;

function Tf2ClickAreaDecorator.pm_GetAllowed: Boolean;
begin
 Result := f_Allowed;
end;

function Tf2ClickAreaDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtClickArea;
end;

function Tf2ClickAreaDecorator.pm_GetEnabled: Boolean;
begin
 Result := f_Enabled;
end;

function Tf2ClickAreaDecorator.pm_GetWidth: Single;
begin
 Result := f_Width;
end;

function Tf2ClickAreaDecorator.pm_GetHeight: Single;
begin
 Result := f_Height;
end;

function Tf2ClickAreaDecorator.pm_GetMenuAlign: Td2dAlign;
begin
 Result := f_MenuAlign;
end;

procedure Tf2ClickAreaDecorator.pm_SetAllowed(const Value: Boolean);
begin
 f_Allowed := Value;
end;

procedure Tf2ClickAreaDecorator.pm_SetEnabled(const Value: Boolean);
begin
 f_Enabled := Value;
end;

procedure Tf2ClickAreaDecorator.pm_SetWidth(const Value: Single);
begin
 f_Width := Value;
 RecalcRect;
end;

procedure Tf2ClickAreaDecorator.pm_SetHeight(const Value: Single);
begin
 f_Height := Value;
 RecalcRect;
end;

procedure Tf2ClickAreaDecorator.pm_SetMenuAlign(const Value: Td2dAlign);
begin
 f_MenuAlign := Value;
end;

procedure Tf2ClickAreaDecorator.ProcessEvent(var theEvent: Td2dInputEvent);
begin
 if f_Allowed and f_Enabled then
 begin
  if D2DIsPointInRect(gD2DE.MouseX, gD2DE.MouseY, f_Rect) then
  begin
   if (theEvent.EventType = INPUT_MBUTTONDOWN) and (theEvent.KeyCode = D2DK_LBUTTON) then
   begin
    f_TargetProcessor.ExecuteAction(f_Rect, f_MenuAlign);
    Processed(theEvent);
   end
   else
   if (theEvent.EventType = INPUT_MOUSEMOVE) and not IsMouseMoveMasked(theEvent) then
    MaskMouseMove(theEvent);
  end;
 end;
end;

procedure Tf2ClickAreaDecorator.RecalcRect;
begin
 f_Rect := D2DRect(PosX, PosY, PosX + Width, PosY + Height);
end;

procedure Tf2ClickAreaDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 f_TargetProcessor.Save(aFiler);
 aFiler.WriteSingle(f_Width);
 aFiler.WriteSingle(f_Height);
 aFiler.WriteBoolean(f_Enabled);
 aFiler.WriteByte(Ord(f_MenuAlign));
end;

constructor Tf2SingleTargetProcessor.Create(const aContext: TFURQContext);
begin
 inherited Create;
 f_Context := aContext;
end;

constructor Tf2SingleTargetProcessor.Load(aFiler: Td2dFiler; aContext: TFURQContext);
begin
 inherited Create;
 f_Context := aContext;
 OnAction := Tf2Context(f_Context).OnDecoratorAction;
 Target := aFiler.ReadString;
end;

procedure Tf2SingleTargetProcessor.ExecuteAction(const aRect: Td2dRect; const aMenuAlign: Td2dAlign);
begin
 if Assigned(f_OnAction) and (f_ActionID <> '') then
  f_OnAction(f_ActionID, aRect, aMenuAlign);
end;

function Tf2SingleTargetProcessor.GetActionsData(anID: string): IFURQActionData;
begin
 if anID = f_ActionID then
  Result := f_ActionData
 else
  Result := nil;
end;

procedure Tf2SingleTargetProcessor.pm_SetTarget(const aTarget: string);
var
 l_AM: TFURQActionModifier;
 l_LIdx: Integer;
 l_Loc: string;
 l_Params: IJclStringList;
begin
 f_Target := aTarget;
 l_Params := JclStringList;
 ParseLocAndParams(aTarget, l_Loc, l_Params, l_AM);
 l_LIdx := f_Context.Code.Labels.IndexOf(l_Loc);
 if l_LIdx <> -1 then
 begin
  f_ActionData := TFURQActionData.Create(l_LIdx, l_Params, l_AM);
  f_ActionID := ActionDataHash(f_ActionData);
 end
 else
 begin
  f_ActionID := '';
  f_ActionData := nil;
 end;  
end;

procedure Tf2SingleTargetProcessor.Save(aFiler: Td2dFiler);
begin
 aFiler.WriteString(Target);
end;

constructor Tf2CustomButtonDecorator.Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext);
begin
 inherited Create(aPosX, aPosY, aPosZ);
 f_TargetProcessor := Tf2SingleTargetProcessor.Create(aContext);
 f_Allowed := True;
 f_Enabled := True;
 f_MenuAlign := alTopLeft;
end;

constructor Tf2CustomButtonDecorator.Load(const aFiler: Td2dFiler; aContext: TFURQContext);
begin
 inherited Load(aFiler);
 f_TargetProcessor := Tf2SingleTargetProcessor.Load(aFiler, aContext);
 f_Enabled := aFiler.ReadBoolean;
 f_MenuAlign := Td2dAlign(aFiler.ReadByte);
 LoadButton(aFiler, aContext);
 f_Button.OnClick := ClickHandler;
 f_Allowed := True;
 UpdateButtonState;
end;

function Tf2CustomButtonDecorator.AsActionDecorator: If2ActionDecorator;
begin
 Result := Self;
end;

procedure Tf2CustomButtonDecorator.Cleanup;
begin
 FreeAndNil(f_Button);
 FreeAndNil(f_TargetProcessor);
 inherited;
end;

procedure Tf2CustomButtonDecorator.ClickHandler(aSender: TObject);
var
 l_Rect: Td2dRect;
begin
 l_Rect := D2DRect(f_Button.X, f_Button.Y, f_Button.X + f_Button.Width, f_Button.Y + f_Button.Height);
 f_TargetProcessor.ExecuteAction(l_Rect, f_MenuAlign);
end;

procedure Tf2CustomButtonDecorator.DoRender;
begin
 f_Button.Render;
end;

procedure Tf2CustomButtonDecorator.DoSetPosX(const Value: Single);
begin
 inherited DoSetPosX(Value);
 f_Button.X := Value;
 gD2DE.Input_TouchMousePos;
end;

procedure Tf2CustomButtonDecorator.DoSetPosY(const Value: Single);
begin
 inherited DoSetPosY(Value);
 f_Button.Y := Value;
 gD2DE.Input_TouchMousePos;
end;

function Tf2CustomButtonDecorator.GetActionsData(const anID: string): IFURQActionData;
begin
 Result := f_TargetProcessor.GetActionsData(anID);
end;

function Tf2CustomButtonDecorator.GetTargetProcessor: Tf2SingleTargetProcessor;
begin
 Result := f_TargetProcessor;
end;

function Tf2CustomButtonDecorator.pm_GetAllowed: Boolean;
begin
 Result := f_Allowed;
end;

function Tf2CustomButtonDecorator.pm_GetEnabled: Boolean;
begin
 Result := (f_Button <> nil) and (f_Button.Enabled);
end;

function Tf2CustomButtonDecorator.pm_GetHeight: Single;
begin
 Result := f_Button.Height;
end;

function Tf2CustomButtonDecorator.pm_GetMenuAlign: Td2dAlign;
begin
 Result := f_MenuAlign;
end;

function Tf2CustomButtonDecorator.pm_GetWidth: Single;
begin
 Result := f_Button.Width;
end;

procedure Tf2CustomButtonDecorator.pm_SetAllowed(const Value: Boolean);
begin
 f_Allowed := Value;
 UpdateButtonState;
end;

procedure Tf2CustomButtonDecorator.pm_SetEnabled(const Value: Boolean);
begin
 f_Enabled := Value;
 UpdateButtonState;
end;

procedure Tf2CustomButtonDecorator.pm_SetMenuAlign(const Value: Td2dAlign);
begin
 f_MenuAlign := Value;
end;

procedure Tf2CustomButtonDecorator.ProcessEvent(var theEvent: Td2dInputEvent);
begin
 f_Button.ProcessEvent(theEvent);
end;

procedure Tf2CustomButtonDecorator.Save(aFiler: Td2dFiler);
begin
 inherited Save(aFiler);
 f_TargetProcessor.Save(aFiler);
 aFiler.WriteBoolean(f_Enabled);
 aFiler.WriteByte(Ord(f_MenuAlign));
 SaveButton(aFiler);
end;

procedure Tf2CustomButtonDecorator.Update(const aDelta: Single);
begin
 inherited Update(aDelta);
 f_Button.FrameFunc(aDelta);
end;

procedure Tf2CustomButtonDecorator.UpdateButtonState;
begin
 if f_Button <> nil then
  f_Button.Enabled := f_Enabled and f_Allowed;
end;

constructor Tf2ImageButtonDecorator.Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext; const
 aTexName: string; aTx, aTy, aWidth, aHeight: Integer);
var
 l_Tex: Id2dTexture;
begin
 inherited Create(aPosX, aPosY, aPosZ, aContext);
 l_Tex := gD2DE.Texture_Load(aTexName);
 if l_Tex = nil then
  raise EFURQRunTimeError.CreateFmt('Ошибка открытия файла %s', [aTexName]);
 f_TextureName := aTexName;
 f_TexX := aTx;
 f_TexY := aTy;
 f_Button := Td2dBitButton.Create(aPosX, aPosY, l_Tex, aTx, aTy, aWidth, aHeight);
 f_Button.OnClick := ClickHandler;
end;

procedure Tf2ImageButtonDecorator.LoadButton(const aFiler: Td2dFiler; const aContext: TFURQContext);
var
 l_Width, l_Height: Integer;
 l_Tex: Id2dTexture;
begin
 f_TextureName := aFiler.ReadString;
 f_TexX := aFiler.ReadInteger;
 f_TexY := aFiler.ReadInteger;
 l_Width := aFiler.ReadInteger;
 l_Height := aFiler.ReadInteger;
 l_Tex := gD2DE.Texture_Load(f_TextureName);
 if l_Tex = nil then
  raise EFURQRunTimeError.CreateFmt('Ошибка открытия файла %s (при загрузке декоратора)', [f_TextureName]);
 f_Button := Td2dBitButton.Create(PosX, PosY, l_Tex, f_TexX, f_TexY, l_Width, l_Height);
end;

function Tf2ImageButtonDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtImgButton;
end;

procedure Tf2ImageButtonDecorator.SaveButton(const aFiler: Td2dFiler);
begin
 aFiler.WriteString(f_TextureName);
 aFiler.WriteInteger(f_TexX);
 aFiler.WriteInteger(f_TexY);
 aFiler.WriteInteger(Trunc(f_Button.Width));
 aFiler.WriteInteger(Trunc(f_Button.Height));
end;

constructor Tf2TextButtonDecorator.Create(const aPosX, aPosY, aPosZ: Single; const aContext: TFURQContext;
    const aTextFrame, aText: string);
var
 l_Frame: Id2dFramedButtonView;
begin
 inherited Create(aPosX, aPosY, aPosZ, aContext);
 f_TextFrame := aTextFrame;
 l_Frame := Tf2Context(aContext).GetButtonFrame(aTextFrame);
 if l_Frame = nil then
  raise EFURQRunTimeError.Create('Невозможно создать текстовую кнопку-декоратор');
 f_Button := Td2dFramedTextButton.Create(aPosX, aPosY, l_Frame, aText);
 f_Button.OnClick := ClickHandler;
end;

procedure Tf2TextButtonDecorator.LoadButton(const aFiler: Td2dFiler; const aContext: TFURQContext);
var
 l_Text: string;
 l_Frame: Id2dFramedButtonView;
begin
 f_TextFrame := aFiler.ReadString;
 l_Text := aFiler.ReadString;
 l_Frame := Tf2Context(aContext).GetButtonFrame(f_TextFrame);
 f_Button := Td2dFramedTextButton.Create(PosX, PosY, l_Frame, l_Text); 
end;

function Tf2TextButtonDecorator.pm_GetDecoratorType: Tf2DecorType;
begin
 Result := dtTextButton;
end;

function Tf2TextButtonDecorator.pm_GetText: string;
begin
 Result := Td2dFramedTextButton(f_Button).Caption;
end;

function Tf2TextButtonDecorator.pm_GetTextAlign: Td2dTextAlignType;
begin
 Result := Td2dFramedTextButton(f_Button).TextAlign;
end;

function Tf2TextButtonDecorator.pm_GetWidth: Single;
begin
 // TODO -cMM: Tf2TextButtonDecorator.pm_GetWidth default body inserted
 Result := inherited pm_GetWidth;
end;

procedure Tf2TextButtonDecorator.pm_SetText(const Value: string);
begin
 Td2dFramedTextButton(f_Button).Caption := Value;
end;

procedure Tf2TextButtonDecorator.pm_SetTextAlign(const Value: Td2dTextAlignType);
begin
 Td2dFramedTextButton(f_Button).TextAlign := Value;
end;

procedure Tf2TextButtonDecorator.pm_SetWidth(const Value: Single);
begin
 if Value = 0 then
  Td2dFramedTextButton(f_Button).AutoSize := True
 else
  f_Button.Width := Value;
end;

procedure Tf2TextButtonDecorator.SaveButton(const aFiler: Td2dFiler);
begin
 aFiler.WriteString(f_TextFrame);
 aFiler.WriteString(Text);
end;

end.
