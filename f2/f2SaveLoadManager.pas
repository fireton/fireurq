unit f2SaveLoadManager;

interface
uses
 furqContext;

const
 cMaxSlotsNum = 7;

type
 Tf2SaveLoadManager = class
 private
  f_SaveNameBase: string;
  f_SavePath: string;
  f_SaveNames: array [0..cMaxSlotsNum] of string;
  function GetSaveExt(aIdx: Integer): string;
  function pm_GetIsAnySaveExists: Boolean;
  function pm_GetIsOnlyAutoSaveExists: Boolean;
  function pm_GetSaveName(aIndex: Integer): string;
  procedure pm_SetSaveNameBase(const Value: string);
  procedure pm_SetSavePath(const Value: string);
  procedure RebuildSaveNames;
 public
  function GetAutoDesc(aSlotNum: Integer = 0): string;
  procedure GetSaveInfo(aIndex: Integer; out theCaption: string; out theDateTime: TDateTime);
  procedure LoadGame(aContext: TFURQContext; aSlotNum: Integer = 0; aIgnoreHash: Boolean = False);
  procedure SaveGame(aContext: TFURQContext; const aLocation: string; aDesc: string = ''; aSlotNum: Integer = 0);
  procedure SetSaveBase(const aContext: TFURQContext);
  property SavePath: string read f_SavePath write pm_SetSavePath;
  property IsAnySaveExists: Boolean read pm_GetIsAnySaveExists;
  property IsOnlyAutoSaveExists: Boolean read pm_GetIsOnlyAutoSaveExists;
  property SaveName[aIndex: Integer]: string read pm_GetSaveName;
  property SaveNameBase: string read f_SaveNameBase write pm_SetSaveNameBase;
 end;

implementation
uses
 SysUtils,
 f2Types;

function Tf2SaveLoadManager.GetAutoDesc(aSlotNum: Integer = 0): string;
begin
 if aSlotNum = 0 then
  Result := 'Автосохранение'
 else
  Result := 'Сохранение';
end;

function Tf2SaveLoadManager.GetSaveExt(aIdx: Integer): string;
begin
 if aIdx = 0 then
  Result := '.sav'
 else
  Result := Format('.s%.2d', [aIdx]);
end;

procedure Tf2SaveLoadManager.LoadGame(aContext: TFURQContext; aSlotNum: Integer = 0; aIgnoreHash: Boolean = False);
begin
 SetSaveBase(aContext);
 if FileExists(SaveName[aSlotNum]) then
  aContext.LoadFromFile(SaveName[aSlotNum], aIgnoreHash);
end;

function Tf2SaveLoadManager.pm_GetIsAnySaveExists: Boolean;
var
 I: Integer;
begin
 Result := False;
 for I := 0 to cMaxSlotsNum do
  if FileExists(f_SaveNames[I]) then
  begin
   Result := True;
   Break;
  end;
end;

function Tf2SaveLoadManager.pm_GetIsOnlyAutoSaveExists: Boolean;
var
 I: Integer;
begin
 Result := False;
 if not FileExists(SaveName[0]) then
  Exit;
 for I := 1 to cMaxSlotsNum do
  if FileExists(SaveName[I]) then
   Exit;
 Result := True;   
end;

procedure Tf2SaveLoadManager.GetSaveInfo(aIndex: Integer; out theCaption: string; out theDateTime: TDateTime);
begin
 theCaption := '';
 theDateTime := 0;
 if FileExists(f_SaveNames[aIndex]) then
  FURQReadSaveInfo(f_SaveNames[aIndex], theCaption, theDateTime);
  {
  begin
   DateTimeToString(l_DTS, 'd mmm yyyy, hh:nn:ss', l_DateTime);
   Result := Format('%s (%s)', [l_Desc, l_DTS]);
  end
  else
   Result := '';
 end
 else
  Result := '';}
end;

function Tf2SaveLoadManager.pm_GetSaveName(aIndex: Integer): string;
begin
 Result := f_SaveNames[aIndex];
end;

procedure Tf2SaveLoadManager.pm_SetSaveNameBase(const Value: string);
begin
 if f_SaveNameBase <> Value then
 begin
  f_SaveNameBase := Value;
  RebuildSaveNames;
 end; 
end;

procedure Tf2SaveLoadManager.pm_SetSavePath(const Value: string);
var
 I: Integer;
begin
 f_SavePath := IncludeTrailingPathDelimiter(Value);
 RebuildSaveNames;
end;

procedure Tf2SaveLoadManager.RebuildSaveNames;
var
 I: Integer;
begin
 for I := 0 to cMaxSlotsNum do
  f_SaveNames[I] := f_SavePath + f_SaveNameBase + GetSaveExt(I);
end;

procedure Tf2SaveLoadManager.SaveGame(aContext: TFURQContext; const aLocation: string; aDesc: string = ''; aSlotNum: Integer = 0);
begin
 SetSaveBase(aContext);
 if aDesc = '' then
  if aSlotNum = 0 then
   aDesc := 'Автосохранение'
  else
   aDesc := 'Сохранение';
 aContext.SaveToFile(SaveName[aSlotNum], aLocation, aDesc);
end;

procedure Tf2SaveLoadManager.SetSaveBase(const aContext: TFURQContext);
begin
 SaveNameBase := aContext.Variables[c_SaveNameBase];
end;

end.