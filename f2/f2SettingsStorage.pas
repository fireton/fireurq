unit f2SettingsStorage;

{ $Id: f2SettingsStorage.pas,v 1.1 2017/06/28 18:42:15 Антон Exp $ }

interface
uses
 d2dClasses,
 JclStringLists;

type
 Tf2SettingsStorage = class(Td2dProtoObject)
 private
  f_Data: IJclStringList;
  f_DataFN: AnsiString;
  procedure LoadDataFile;
  function pm_GetData(aName: AnsiString): Variant;
  procedure pm_SetData(aName: AnsiString; const Value: Variant);
  procedure SaveDataFile;
  property Data[aName: AnsiString]: Variant read pm_GetData write pm_SetData; default;
 protected
  procedure Cleanup; override;
 public
  constructor Create(const aDataFN: AnsiString);
  procedure Clear;
 end;

implementation
uses
 Classes,
 SysUtils,
 furqFiler, d2dUtils;

const
 cSSSignature = 'FURQSS';
 cSSVersion   = 1;

constructor Tf2SettingsStorage.Create(const aDataFN: AnsiString);
begin
 inherited Create;
 f_DataFN := aDataFN;
 f_Data := JclStringList;
 f_Data.Sorted := True;
 if FileExists(f_DataFN) then
  LoadDataFile;
end;

procedure Tf2SettingsStorage.Cleanup;
begin
 f_Data := nil;
 inherited;
end;

procedure Tf2SettingsStorage.Clear;
begin
 f_Data.Clear;
 DeleteFile(f_DataFN);
end;

procedure Tf2SettingsStorage.LoadDataFile;
var
 I: Integer;
 l_Count: Integer;
 l_Filer: TFURQFiler;
 l_FS: TFileStream;
 l_Idx: Integer;
begin
 f_Data.Clear;
 l_FS := TFileStream.Create(f_DataFN, fmOpenRead);
 try
  l_Filer := TFURQFiler.Create(l_FS);
  try
   if (l_Filer.ReadString <> cSSSignature) or (l_Filer.ReadByte <> cSSVersion) then
    Exit;
   l_Count := l_Filer.ReadInteger;
   for I := 1 to l_Count do
   begin
    l_Idx := f_Data.Add(l_Filer.ReadString);
    f_Data.Variants[l_Idx] := l_Filer.ReadVarValue;
   end;
  finally
   FreeAndNil(l_Filer);
  end;
 finally
  FreeAndNil(l_FS);
 end;
end;

function Tf2SettingsStorage.pm_GetData(aName: AnsiString): Variant;
var
 l_Idx: Integer;
begin
 l_Idx := f_Data.IndexOf(aName);
 if l_Idx < 0 then
  Result := 0.0
 else
  Result := f_Data.Variants[l_Idx];
end;

procedure Tf2SettingsStorage.pm_SetData(aName: AnsiString; const Value: Variant);
var
 l_Idx: Integer;
begin
 l_Idx := f_Data.IndexOf(aName);
 if l_Idx < 0 then
  l_Idx := f_Data.Add(aName);
 f_Data.Variants[l_Idx] := Value;
 SaveDataFile;
end;

procedure Tf2SettingsStorage.SaveDataFile;
var
 I: Integer;
 l_FS: TFileStream;
 l_Filer: TFURQFiler;
begin
 l_FS := TFileStream.Create(f_DataFN, fmCreate);
 try
  l_Filer := TFURQFiler.Create(l_FS);
  try
   l_Filer.WriteString(cSSSignature);
   l_Filer.WriteByte(cSSVersion);
   l_Filer.WriteInteger(f_Data.Count);
   for I := 0 to f_Data.LastIndex do
   begin
    l_Filer.WriteString(f_Data.Strings[I]);
    l_Filer.WriteVarValue(f_Data.Variants[I]);
   end;
  finally
   FreeAndNil(l_Filer);
  end;
 finally
  FreeAndNil(l_FS);
 end;
end;

end.