unit f2FontLoad;

interface
uses
 d2dInterfaces;

function f2LoadFont(const aFontName: string; aFromPack: Boolean = False): Id2dFont;

implementation
uses
 Classes,
 SysUtils,
 Windows,
 SHFolder,
 SimpleXML,

 d2dCore,
 d2dTypes,
 d2dFont,

 f2Types,
 f2FontGen;

const
 c_DefaultSize    = 19;
 c_DefaultGamma   = 0.6;
 c_DefaultWeight  = 0.4;
 c_DefaultBGColor = $626262;

type
 Tf2DefFontRecord = record
  rName        : string;
  rFontFileName: string;
 end;

const
 c_DefaultFonts : array [1..10] of Tf2DefFontRecord = ((rName: 'serif';             rFontFileName: 'ptserif.ttf'),
                                                       (rName: 'serif-bold';        rFontFileName: 'ptserifb.ttf'),
                                                       (rName: 'serif-italic';      rFontFileName: 'ptserifi.ttf'),
                                                       (rName: 'serif-italic-bold'; rFontFileName: 'ptserifbi.ttf'),
                                                       (rName: 'serif-bold-italic'; rFontFileName: 'ptserifbi.ttf'),
                                                       (rName: 'sans';              rFontFileName: 'ptsans.ttf'),
                                                       (rName: 'sans-bold';         rFontFileName: 'ptsansb.ttf'),
                                                       (rName: 'sans-italic';       rFontFileName: 'ptsansi.ttf'),
                                                       (rName: 'sans-italic-bold';  rFontFileName: 'ptsansbi.ttf'),
                                                       (rName: 'sans-bold-italic';  rFontFileName: 'ptsansbi.ttf'));

function GetFontsFolder: string;
const
 SHGFP_TYPE_CURRENT = 0;
 CSIDL_FONTS = $0014;
var
  path: array [0..MAX_PATH] of char;
begin
 if SUCCEEDED(SHGetFolderPath(0, CSIDL_FONTS, 0,SHGFP_TYPE_CURRENT,@path[0])) then
  Result := path
 else
  Result := '';
end;

function DefaultSubstitudes(const aFN: string): string;
var
 I: Integer;
begin
 Result := aFN;
 for I := 1 to 10 do
 begin
  if AnsiSameText(aFN, c_DefaultFonts[I].rName) then
  begin
   Result := c_DefaultFonts[I].rFontFileName;
   Break;
  end;
 end;
end;


// fonts can be:
// .fnt (HGE fonts), .bmf (Bitmap Fonts), .ttf (True Type fonts with params)

// times.ttf[18,1.1,0.8,0xFF0000]

function f2LoadFont(const aFontName: string; aFromPack: Boolean = False): Id2dFont;
var
 l_Ext: string;
 l_Pos: Integer;
 l_Params: string;
 l_FN: string;
 l_MS: TMemoryStream;
 l_FMem: Pointer;
 l_FMemSize: Longword;
 l_FontGamma: Double;
 l_FontSize: Integer;
 l_FontWeight: Double;
 l_FontBGColor: Td2dColor;
 l_FromFontsFolder: Boolean;
 l_OneParam: string;
 l_XML: IXmlDocument;
 l_FG: TfgFont;

 function GetParam: Boolean;
 var
  l_Pos: Integer;
 begin
  Result := False;
  l_OneParam := '';
  if l_Params = '' then
   Exit;
  l_Pos := Pos(',', l_Params);
  if l_Pos > 0 then
  begin
   l_OneParam := Trim(Copy(l_Params, 1, l_Pos-1));
   Delete(l_Params, 1, l_Pos);
  end
  else
  begin
   l_OneParam := Trim(l_Params);
   l_Params := '';
  end;
  Result := (l_OneParam <> '');
 end;

begin
 Result := nil;
 l_FMem := nil;
 l_FN := aFontName;
 l_Pos := Pos('[', l_FN);
 if l_Pos > 0 then
 begin
  l_Params := Trim(Copy(l_FN, l_Pos, MaxInt));
  Delete(l_FN, l_Pos, MaxInt);
  l_FN := Trim(l_FN);
 end
 else
  l_Params := '';

 l_FN := DefaultSubstitudes(l_FN);

 l_Ext := ExtractFileExt(l_FN);
 if AnsiSameText(l_Ext, '.fnt') then
 begin
  if gD2DE.Resource_Exists(l_FN, aFromPack) then
   Result := Td2dHGEFont.Create(l_FN, aFromPack);
 end
 else
 if AnsiSameText(l_Ext, '.bmf') then
 begin
  if gD2DE.Resource_Exists(l_FN, aFromPack) then
   Result := Td2dBMFont.Create(l_FN, aFromPack);
 end
 else
 if AnsiSameText(l_Ext, '.ttf') then
 begin
  l_FromFontsFolder := False;
  try
   l_FMem := gD2DE.Resource_Load(l_FN, @l_FMemSize, aFromPack, True);
   {
   if (l_FMem = nil) and (Pos('\', l_FN) = 0) and (Pos('/', l_FN) = 0) then
   begin
    l_FN := GetFontsFolder + '\' + l_FN;
    if FileExists(l_FN) then
    begin
     l_MS := TMemoryStream.Create;
     l_MS.LoadFromFile(l_FN);
     l_FMem := l_MS.Memory;
     l_FMemSize := l_MS.Size;
     l_FromFontsFolder := True;
    end;
   end;
   }
   if l_FMem <> nil then
   begin
    l_FontSize    := c_DefaultSize;
    l_FontGamma   := c_DefaultGamma;
    l_FontWeight  := c_DefaultWeight;
    l_FontBGColor := c_DefaultBGColor;
    if l_Params <> '' then
    begin
     if l_Params[1] = '[' then
     begin
      Delete(l_Params, 1, 1);
      if l_Params[Length(l_Params)] = ']' then
      begin
       Delete(l_Params, Length(l_Params), 1);
       if GetParam then
        l_FontSize := StrToIntDef(l_OneParam, c_DefaultSize);
       if GetParam then
        l_FontGamma := StrToFloatDef(l_OneParam, c_DefaultGamma);
       if GetParam then
        l_FontWeight := StrToFloatDef(l_OneParam, c_DefaultWeight);
       if GetParam then
        l_FontBGColor := Hex2ColorDef(l_OneParam, c_DefaultBGColor);
      end;
     end;
    end;
    l_FG := TfgFont.Create;
    try
     l_FG.Build(''{l_FN}, l_FontSize, l_FMem, l_FMemSize, l_FontGamma, l_FontWeight, l_FontBGColor);
     l_XML := l_FG.GetXML;
     Result := Td2dBMFont.CreateFromXML(l_XML);
    finally
     FreeAndNil(l_FG);
    end;
   end;
   if Result <> nil then
    Result.ID := aFontName;
  finally
   if l_FromFontsFolder then
    FreeAndNil(l_MS)
   else
    gD2DE.Resource_Free(l_FMem);
  end;
 end;
end;

end.