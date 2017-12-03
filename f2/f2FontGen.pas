unit f2FontGen;

interface

uses
 GDIPOBJ,
 JclContainerIntf,
 JclArrayLists,
 SimpleXML,

 d2dTypes;

type
 IfgLetter = interface(IInterface)
 ['{49932CB5-AE23-46E9-AD3E-F96C039E1A00}']
  function pm_GetAdvance: Integer;
  function pm_GetBitmap: TGPBitmap;
  function pm_GetCharCode: Byte;
  function pm_GetShiftX: Integer;
  function pm_GetShiftY: Integer;
  function pm_GetSquare: Integer;
  function pm_GetTexX: Integer;
  function pm_GetTexY: Integer;
  procedure pm_SetTexX(const Value: Integer);
  procedure pm_SetTexY(const Value: Integer);
  property Advance: Integer read pm_GetAdvance;
  property Bitmap: TGPBitmap read pm_GetBitmap;
  property CharCode: Byte read pm_GetCharCode;
  property ShiftX: Integer read pm_GetShiftX;
  property ShiftY: Integer read pm_GetShiftY;
  property Square: Integer read pm_GetSquare;
  property TexX: Integer read pm_GetTexX write pm_SetTexX;
  property TexY: Integer read pm_GetTexY write pm_SetTexY;
 end;


 TfgLetter = class(TInterfacedObject, IfgLetter)
 private
  f_Advance: Integer;
  f_Bitmap: TGPBitmap;
  f_CharCode: Byte;
  f_ShiftX: Integer;
  f_ShiftY: Integer;
  f_TexX: Integer;
  f_TexY: Integer;
  function pm_GetAdvance: Integer;
  function pm_GetBitmap: TGPBitmap;
  function pm_GetCharCode: Byte;
  function pm_GetShiftX: Integer;
  function pm_GetShiftY: Integer;
  function pm_GetTexX: Integer;
  function pm_GetTexY: Integer;
  procedure pm_SetTexX(const Value: Integer);
  procedure pm_SetTexY(const Value: Integer);
  function pm_GetSquare: Integer;
 public
  destructor Destroy; override;
  property Advance: Integer read pm_GetAdvance write f_Advance;
  property ShiftX: Integer read pm_GetShiftX write f_ShiftX;
  property ShiftY: Integer read pm_GetShiftY write f_ShiftY;
  property Bitmap: TGPBitmap read pm_GetBitmap write f_Bitmap;
  property CharCode: Byte read pm_GetCharCode write f_CharCode;
  property TexX: Integer read pm_GetTexX write pm_SetTexX;
  property TexY: Integer read pm_GetTexY write pm_SetTexY;
 end;
                                         
 TfgFont = class
 private
  f_Letters: IJclIntfCollection;
  f_LineHeight: Integer;
  f_Name: string;
  f_Size: Integer;
  f_SpaceAdvance: Integer;
  f_TexHeight: Integer;
  f_Texture: TGPBitmap;
  f_TexWidth: Integer;
  function ArrangeToTexture: Boolean;
  procedure BuildFontTexture;
  procedure ClearLetters;
  function GetTotalSquare: Integer;
  procedure pm_SetTexture(const Value: TGPBitmap);
  property Texture: TGPBitmap read f_Texture write pm_SetTexture;
 public
  constructor Create;
  destructor Destroy; override;
  procedure Build(const aTTF_FName: string; aSize: Integer; aFontMem: Pointer = nil; aFontMemSize: Longword = 0; aGamma:
      Double = 1.2; aWeight: Double = 0.0; aBGColor: Td2dColor = $808080);
  procedure Save(const aFilename: string);
  function GetXML: IXmlDocument;
  property Name: string read f_Name write f_Name;
  property Size: Integer read f_Size write f_Size;
 end;

implementation

uses
 Windows,
 Classes,
 ActiveX,
 SysUtils,

 GDIPAPI, GDIPUTIL,

 agg_basics ,
 agg_rendering_buffer ,
 agg_color ,
 agg_pixfmt ,
 agg_pixfmt_rgba ,
 agg_renderer_base ,


 agg_renderer_scanline ,
 agg_renderer_primitives ,
 agg_rasterizer_scanline_aa ,
 agg_scanline ,
 agg_scanline_u ,
 agg_scanline_p ,
 agg_scanline_bin ,
 agg_render_scanlines ,

 agg_trans_affine ,
 agg_curves ,
 agg_conv_curve ,
 agg_conv_contour ,
 agg_gamma_lut ,
 agg_gamma_functions ,
 agg_font_freetype ,
 agg_font_freetype_lib,
 agg_font_cache_manager,

 JclAlgorithms;

const
 cMaxTextureDim = 2048;

type
 TPlaceArea = class
 private
  f_Children: array[1..2] of TPlaceArea;
  f_Height: Integer;
  f_PosX: Integer;
  f_PosY: Integer;
  f_Width: Integer;
  function pm_GetChildren(Index: Integer): TPlaceArea;
  function pm_GetIsOccupied: Boolean;
  function pm_GetSquare: Integer;
 public
  constructor Create(const aPosX, aPosY, aWidth, aHeight: Integer);
  destructor Destroy; override;
  procedure FreeChildren;
  function Place(const aLetter: IfgLetter): Boolean;
  property Children[Index: Integer]: TPlaceArea read pm_GetChildren;
  property Height: Integer read f_Height write f_Height;
  property IsOccupied: Boolean read pm_GetIsOccupied;
  property PosX: Integer read f_PosX write f_PosX;
  property PosY: Integer read f_PosY write f_PosY;
  property Square: Integer read pm_GetSquare;
  property Width: Integer read f_Width write f_Width;
 end;

function CompareLetters(const Obj1, Obj2: IInterface): Integer;
var
 l_L1, l_L2: IfgLetter;
begin
 l_L1 := Obj1 as IfgLetter;
 l_L2 := Obj2 as IfgLetter;
 if l_L1.Square > l_L2.Square then
  Result := -1
 else
  if l_L1.Square < l_L2.Square then
   Result := 1
  else
   Result := 0;
end;

function Max(const A, B: Integer): Integer;
begin
 if A > B then
  Result := A
 else
  Result := B;
end;

function CompareLetters2(const Obj1, Obj2: IInterface): Integer;
var
 l_L1, l_L2: IfgLetter;
 D1, D2 : Integer;
begin
 l_L1 := Obj1 as IfgLetter;
 l_L2 := Obj2 as IfgLetter;
 D1 := Max(l_L1.Bitmap.GetWidth, l_L1.Bitmap.GetHeight);
 D2 := Max(l_L2.Bitmap.GetWidth, l_L2.Bitmap.GetHeight);
 if D1 > D2 then
  Result := -1
 else
  if D1 < D2 then
   Result := 1
  else
   Result := 0;
end;

constructor TfgFont.Create;
begin
 inherited;
 f_Letters := TJclIntfArrayList.Create;
end;

destructor TfgFont.Destroy;
begin
 ClearLetters;
 FreeAndNil(f_Texture);
 inherited;
end;

function TfgFont.ArrangeToTexture: Boolean;
var
 l_ApproxSquare: Integer;
 

 procedure IncTexture;
 begin
  if f_TexHeight = f_TexWidth then
   f_TexHeight := f_TexWidth shl 1
  else
   f_TexWidth := f_TexHeight;
 end;

 function TryToPlace: Boolean;
 var
  l_Iter: IJclIntfIterator;
  l_Letter: IfgLetter;
  l_PlaceArea: TPlaceArea;
 begin
  l_PlaceArea := TPlaceArea.Create(1, 1, f_TexWidth - 2, f_TexHeight - 2);
  try
   l_Iter := f_Letters.First;
   repeat
    l_Letter := l_Iter.Next as IfgLetter;
    Result := l_PlaceArea.Place(l_Letter);
    if not Result then
     Break;
   until not l_Iter.HasNext;
  finally
   FreeAndNil(l_PlaceArea);
  end;
 end;

begin
 Result := False;
 QuickSort(f_Letters as IJclIntfList, 0, f_Letters.Size-1, @CompareLetters2);
 l_ApproxSquare := GetTotalSquare;
 f_TexWidth := 64;
 f_TexHeight := 64;
 while (l_ApproxSquare > (f_TexWidth-2) * (f_TexHeight-2)) and (f_TexWidth < cMaxTextureDim) do
  IncTexture;
 if f_TexWidth <= cMaxTextureDim then
 begin
  while (not Result) and (f_TexHeight <= cMaxTextureDim) do
  begin
   Result := TryToPlace;
   if not Result then
    IncTexture;
  end;
 end;
end;

procedure TfgFont.Build(const aTTF_FName: string; aSize: Integer; aFontMem: Pointer = nil; aFontMemSize: Longword = 0;
    aGamma: Double = 1.2; aWeight: Double = 0.0; aBGColor: Td2dColor = $808080);
var
 l_AdvanceX: Double;
 l_feng : font_engine_freetype_int32;
 l_fman : font_cache_manager;
 l_gren : glyph_rendering;

 l_R, l_G, l_B, l_A: Byte;
 l_col, l_bgcol  : aggclr;
 l_rbuf : rendering_buffer;
 l_pixf : pixel_formats;
 l_renb : renderer_base;
 l_ren : renderer_scanline_aa_solid;
 l_ras : rasterizer_scanline_aa;
 l_sl  : scanline_u8;
 l_gm_pw : gamma_power;
 l_glyph : glyph_cache_ptr;

 l_curves  : conv_curve;
 l_contour : conv_contour;

 l_RawBitmap: TGPBitmap;
 l_BD: TBitmapData;
 l_RBSize: Integer;
 l_ClipX, l_ClipY, l_ClipW, l_ClipH : Integer;
 l_CharCode: Word;
 l_C: AnsiChar;
 l_IsUnicode: Boolean;
 l_Letter: TfgLetter;
 l_LetterLineHeight: Integer;
 l_ShiftX: Integer;
 l_ShiftY: Integer;
 //l_PNGGUID: TGUID;
begin
 if FileExists(aTTF_FName) or (aFontMem <> nil) then
 begin
  ClearLetters;
  l_RBSize := aSize*4;
  l_RawBitmap := TGPBitmap.Create(l_RBSize, l_RBSize, PixelFormat32bppARGB);
  try
    l_feng.Construct;
    l_fman.Construct(@l_feng);
    l_curves.Construct(l_fman.path_adaptor);
    l_contour.Construct(@l_curves);
    l_contour.width_(-aWeight * aSize * 0.05);

    l_gren := glyph_ren_outline;

    if l_feng.load_font(PAnsiChar(aTTF_FName), 0, l_gren, aFontMem, aFontMemSize) then
    begin
     f_Name := Format('%s %s', [l_feng.m_cur_face^.family_name, l_feng.m_cur_face^.style_name]);
     f_Size := aSize;
     l_feng.hinting_(true);
     l_feng.height_(aSize);
     l_feng.width_(aSize);

     // сохраняем данные о пробеле
     l_glyph := l_fman.glyph(32);

     f_SpaceAdvance := Round(l_glyph.advance_x);

     {$IFDEF TEX_DEBUG_BLUE}
     l_col.ConstrInt(0, 0, 155);
     {$ELSE}
     l_col.ConstrInt(255, 255, 255);
     {$ENDIF}
     
     //l_col.ConstrInt(255,255,255,0);

     //l_bgcol.ConstrInt(255, 255, 255, 0);
     Color2ARGB(aBGColor, l_A, l_R, l_G, l_B);
     l_bgcol.ConstrInt(l_R, l_G, l_B, 0);
     //l_bgcol.ConstrInt(0, 0, 0, 255);
     //l_col.ConstrInt(0,0,0,255);]

     l_C := 'Ж';
     MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, @l_C, 1, @l_CharCode, 1);
     l_glyph := l_fman.glyph(l_CharCode);

     l_IsUnicode := l_glyph.glyph_index > 0;

     f_LineHeight := 0;
     for l_C := #33 to #255 do
     begin
      if l_IsUnicode then
       MultiByteToWideChar(CP_ACP, MB_PRECOMPOSED, @l_C, 1, @l_CharCode, 1)
      else
       l_CharCode := Ord(l_C); 
      l_glyph := l_fman.glyph(l_CharCode);
      if l_glyph <> nil then
      begin
       if l_RawBitmap.LockBits(MakeRect(0, 0, l_RBSize, l_RBSize), ImageLockModeRead or ImageLockModeWrite,
          PixelFormat32bppARGB, l_BD) = Ok then
       try
        l_rbuf.Construct;
        l_rbuf.attach(l_BD.Scan0, l_RBSize, l_RBSize, - l_RBSize * 4);
        pixfmt_bgra32(l_pixf, @l_rbuf);

        l_renb.Construct(@l_pixf);

        l_renb.clear(@l_bgcol);

        l_ren.Construct(@l_renb);

        l_ras.Construct;
        l_sl.Construct;

        l_gm_pw.Construct(aGamma);
        l_ras.gamma(@l_gm_pw);
        l_fman.init_embedded_adaptors(l_glyph, aSize, aSize);
        l_ren.color_(@l_col);

        l_ras.reset;

        if Abs(aWeight) <= 0.01 then
        // For the sake of efficiency skip the
        // contour converter if the weight is about zero.
         l_ras.add_path(@l_curves )
        else
         l_ras.add_path(@l_contour );

        l_ren.color_(@l_col);

        render_scanlines(@l_ras, @l_sl, @l_ren);

        //render_scanlines(l_fman.gray8_adaptor, l_fman.gray8_scanline, @l_ren);

        l_ClipX := l_ras._min_x - 1;
        l_ClipY := l_RBSize - l_ras._max_y - 1;

        l_ClipW := l_ras._max_x - l_ras._min_x + 2;
        l_ClipH := l_ras._max_y - l_ras._min_y + 2;
        l_ShiftX := l_ras._min_x - f_Size;
        l_ShiftY := (f_Size - l_ClipH) - (l_ras._min_y - f_Size);
        l_LetterLineHeight := l_ClipH + l_ShiftY;
        if f_LineHeight < l_LetterLineHeight then
         f_LineHeight := l_LetterLineHeight;
        l_AdvanceX := l_glyph.advance_x;
        l_ras.Destruct;
        l_sl.Destruct;
        l_rbuf.Destruct;
       finally
        l_RawBitmap.UnlockBits(l_BD);
       end;
       if (l_ClipX >= 0) and (l_ClipY >= 0) then
       begin
        l_Letter := TfgLetter.Create;
        with l_Letter do
        begin
         Bitmap := l_RawBitmap.Clone(l_ClipX, l_ClipY, l_ClipW, l_ClipH, PixelFormat32bppARGB);
         {
         if l_C = #65 then
         begin
          GetEncoderClsid('image/png', l_PNGGUID);
          Bitmap.Save('A.png', l_PNGGUID);
         end;
         }
         Advance := Trunc(l_AdvanceX + 0.5);
         ShiftX := l_ShiftX;
         ShiftY := l_ShiftY;
         CharCode := Byte(l_C);
        end;
        if l_Letter.Bitmap <> nil then
         f_Letters.Add(l_Letter);
       end; // if (l_ClipX >= 0) or (l_ClipY >= 0) then
      end; // if l_glyph <> nil then
     end;
    end;

    {
    l_ras.move_to_d(10, 10);
    l_ras.line_to_d(76, 23);
    l_ras.line_to_d(33.5, 64.22);

    l_col.ConstrInt(4, 6, 200);
    l_ren.color_(@l_col);
    }

    l_contour.Destruct;
    l_curves.Destruct;
    l_feng.Destruct;
    l_fman.Destruct;

   //Result := l_RawBitmap.Clone(l_ClipX, l_ClipY, l_ClipW, l_ClipH, PixelFormat32bppARGB);
   //Result := l_RawBitmap.Clone(0, 0, 10, 10, PixelFormat32bppARGB);
   //Result.SetPixel(10, 10, $FFFF0000);
  finally
   FreeAndNil(l_RawBitmap);
  end;
 end;
end;

procedure TfgFont.BuildFontTexture;
var
 l_Gr: TGPGraphics;
 l_Iter: IJclIntfIterator;
 l_Letter: IfgLetter;
begin
 Texture := TGPBitmap.Create(f_TexWidth, f_TexHeight, PixelFormat32bppARGB);
 l_Gr := TGPGraphics.Create(Texture);
 try
  l_Iter := f_Letters.First;
  repeat
   l_Letter := l_Iter.Next as IfgLetter;
   l_Gr.DrawImage(l_Letter.Bitmap, l_Letter.TexX, l_Letter.TexY);
  until not l_Iter.HasNext;
 finally
  FreeAndNil(l_Gr);
 end;
end;

procedure TfgFont.ClearLetters;
begin
 f_Letters.Clear;
end;

function TfgFont.GetTotalSquare: Integer;
var
 l_Letter: IfgLetter;
 l_Iter: IJclIntfIterator;
begin
 Result := 0;
 if not f_Letters.IsEmpty then
 begin
  l_Iter := f_Letters.First;
  repeat
   l_Letter := l_Iter.Next as IfgLetter;
   Result := Result + (l_Letter.Bitmap.GetWidth * l_Letter.Bitmap.GetHeight);
  until not l_Iter.HasNext;
 end;
end;

procedure TfgFont.pm_SetTexture(const Value: TGPBitmap);
begin
 FreeAndNil(f_Texture);
 f_Texture := Value;
end;

procedure TfgFont.Save(const aFilename: string);
var
 l_XML: IXmlDocument;
begin
 l_XML := GetXML;
 if l_XML <> nil then
  l_XML.Save(aFilename);
end;

function TfgFont.GetXML: IXmlDocument;
var
 l_Adapter: IStream;
 l_PNGGUID: TGUID;
 l_Status: TStatus;
 l_CurSection, l_CurItem: IXmlElement;
 l_Iter: IJclIntfIterator;
 l_Letter: IfgLetter;
 l_MemStream: TMemoryStream;
 l_PNGData: string;
begin
 Result := nil;
 if ArrangeToTexture then
 begin
  BuildFontTexture;
  Result := CreateXmlDocument('bitmapfont');

  l_CurSection := Result.DocumentElement.AppendElement('properties');
  l_CurSection.SetAttr('name', f_Name);
  l_CurSection.SetIntAttr('size', f_Size);
  l_CurSection.SetIntAttr('lineheight', f_LineHeight);
  l_CurSection.SetIntAttr('space', f_SpaceAdvance);

  l_CurSection := Result.DocumentElement.AppendElement('letters');
  l_Iter := f_Letters.First;
  repeat
   l_CurItem := l_CurSection.AppendElement('letter');
   l_Letter := l_Iter.Next as IfgLetter;
   l_CurItem.SetIntAttr('code', l_Letter.CharCode);
   l_CurItem.SetIntAttr('tx', l_Letter.TexX);
   l_CurItem.SetIntAttr('ty', l_Letter.TexY);
   l_CurItem.SetIntAttr('w', l_Letter.Bitmap.GetWidth);
   l_CurItem.SetIntAttr('h', l_Letter.Bitmap.GetHeight);
   l_CurItem.SetIntAttr('sx', l_Letter.ShiftX);
   l_CurItem.SetIntAttr('sy', l_Letter.ShiftY);
   l_CurItem.SetIntAttr('adv', l_Letter.Advance);
  until not l_Iter.HasNext;
  l_CurSection := Result.DocumentElement.AppendElement('png');

  l_MemStream := TMemoryStream.Create;
  try
   l_Adapter := TStreamAdapter.Create(l_MemStream);
   try
    if (GetEncoderClsid('image/png', l_PNGGUID) > -1) then
    begin
    {$IFDEF TEX_DEBUG}
     l_Status := f_Texture.Save(Format('%s_%d.png', [f_Name, f_Size]), l_PNGGUID);
    {$ENDIF}
     l_Status := f_Texture.Save(l_Adapter, l_PNGGUID);
    end;
    l_PNGData := BinToBase64(l_MemStream.Memory^, l_MemStream.Size, 0);
    l_CurSection.Text := l_PngData;
   finally
    l_Adapter := nil;
   end;
  finally
   FreeAndNil(l_MemStream);
  end;
  {$IFDEF XML_DEBUG}
  Result.Save(Format('%s_%d.xml', [f_Name, f_Size]));
  {$ENDIF}
 end;
end;

destructor TfgLetter.Destroy;
begin
 FreeAndNil(f_Bitmap);
 inherited;
end;

function TfgLetter.pm_GetAdvance: Integer;
begin
 Result := f_Advance;
end;

function TfgLetter.pm_GetBitmap: TGPBitmap;
begin
 Result := f_Bitmap;
end;

function TfgLetter.pm_GetCharCode: Byte;
begin
 Result := f_CharCode;
end;

function TfgLetter.pm_GetShiftX: Integer;
begin
 Result := f_ShiftX;
end;

function TfgLetter.pm_GetShiftY: Integer;
begin
 Result := f_ShiftY;
end;

function TfgLetter.pm_GetSquare: Integer;
begin
 Result := f_Bitmap.GetWidth * f_Bitmap.GetHeight;
end;

function TfgLetter.pm_GetTexX: Integer;
begin
 Result := f_TexX;
end;

function TfgLetter.pm_GetTexY: Integer;
begin
 Result := f_TexY;
end;

procedure TfgLetter.pm_SetTexX(const Value: Integer);
begin
 f_TexX := Value;
end;

procedure TfgLetter.pm_SetTexY(const Value: Integer);
begin
 f_TexY := Value;
end;

constructor TPlaceArea.Create(const aPosX, aPosY, aWidth, aHeight: Integer);
begin
 inherited Create;
 f_PosX := aPosX;
 f_PosY := aPosY;
 f_Width := aWidth;
 f_Height := aHeight;
end;

destructor TPlaceArea.Destroy;
begin
 FreeChildren;
 inherited;
end;

procedure TPlaceArea.FreeChildren;
begin
 FreeAndNil(f_Children[1]);
 FreeAndNil(f_Children[2]);
end;

function TPlaceArea.Place(const aLetter: IfgLetter): Boolean;
var
 l_W, l_H: Integer;
 l_NewArea1, l_NewArea2: TPlaceArea;
begin
 Result := False;
 Assert(aLetter <> nil);
 l_W := aLetter.Bitmap.GetWidth + 2;
 l_H := aLetter.Bitmap.GetHeight + 2;
 Result := (l_W <= Width) and (l_H <= Height);
 if Result then
 begin
  if IsOccupied then
   Result := Children[1].Place(aLetter) or Children[2].Place(aLetter)
  else
  begin
   aLetter.TexX := PosX + 1;
   aLetter.TexY := PosY + 1;
   if (Width - l_W) < (Height - l_H) then
   begin
    l_NewArea1 := TPlaceArea.Create(PosX + l_W, PosY, Width - l_W, l_H);
    l_NewArea2 := TPlaceArea.Create(PosX, PosY + l_H, Width, Height - l_H);
   end
   else
   begin
    l_NewArea1 := TPlaceArea.Create(PosX, PosY + l_H, l_W, Height - l_H);
    l_NewArea2 := TPlaceArea.Create(PosX + l_W, PosY, Width - l_W, Height);
   end;

   f_Children[1] := l_NewArea1;
   f_Children[2] := l_NewArea2;
  end;
 end;
end;

function TPlaceArea.pm_GetChildren(Index: Integer): TPlaceArea;
begin
 Result := f_Children[Index];
end;

function TPlaceArea.pm_GetIsOccupied: Boolean;
begin
 Result := f_Children[1] <> nil;
end;

function TPlaceArea.pm_GetSquare: Integer;
begin
 Result := Width * Height;
end;

end.