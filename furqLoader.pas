unit furqLoader;

interface
uses
 Classes,
 SysUtils
 ;

function FURQLoadQS1(aStream: TStream): string;

function FURQLoadQS2(aStream: TStream): string;

function FURQLoadQST(aStream: TStream): string;

type
 EFURQLoadError = class(Exception);

implementation
uses
 //JclMath,
 furqDecoders;

type
 TQS2Header = packed record
  rSignature: array[0..3] of Char;
  rVersion  : Longword;
  rLength   : Longword;
  rCRC32    : Longword;
 end;

const
 sUnexpectedEndOfStream = 'Неожиданный конец данных';
 sCorruptedData         = 'Испорченные данные';

function FURQLoadQS2(aStream: TStream): string;
var
 l_B: Byte;
 l_Header: TQS2Header;
 l_BFLength: Longword;
 l_P1, l_P2: Pointer;
 l_Mod: Integer;              
 l_CRC: Longword;
begin
 Result := '';
 // ищем нулевой байт (там вначале заглушка)
 l_B := 255;
 while (l_B <> 0) do
 begin
  if aStream.Read(l_B, 1) <> 1 then
   raise EFURQLoadError.Create(sUnexpectedEndOfStream);
 end;
 // читаем заголовок
 if aStream.Read(l_Header, SizeOf(TQS2Header)) <> SizeOf(TQS2Header) then
   raise EFURQLoadError.Create(sUnexpectedEndOfStream);
 // проверяем сигнатуру
 if PChar(@l_Header) <> 'QS2' then
  raise EFURQLoadError.Create(sCorruptedData);
 l_BFLength := l_Header.rLength;
 l_Mod := l_Header.rLength mod 8;
 if l_Mod <> 0 then
 l_BFLength := l_BFLength + 8 - l_Mod;
 // читаем данные и расшифровываем
 l_P1 := GetMemory(l_BFLength);
 l_P2 := GetMemory(l_BFLength);
 try
  if aStream.Read(l_P1^, l_BFLength) <> l_BFLength then
    raise EFURQLoadError.Create(sUnexpectedEndOfStream);
  BFDecode(l_P1, l_BFLength, l_P2);
  QS2Decode(l_P2, l_Header.rLength, l_P1);
  { TODO : Проверка CRC32 }
  l_CRC := Crc32(l_P1, l_Header.rLength);
  if l_CRC <> l_Header.rCRC32 then
   raise EFURQLoadError.Create(sCorruptedData);
  SetLength(Result, l_Header.rLength);
  Move(l_P1^, Result[1], l_Header.rLength);
 finally
  FreeMemory(l_P1);
  FreeMemory(l_P2);
 end;
end;

function FURQLoadQS1(aStream: TStream): string;
begin
 Result := FURQLoadQST(aStream);
 QS1Decode(Pointer(Result), Length(Result));
end;

function FURQLoadQST(aStream: TStream): string;
var
 l_Len: Cardinal;
begin
 Result := '';
 l_Len := aStream.Size - aStream.Position;
 SetLength(Result, l_Len);
 aStream.Read(Pointer(Result)^, l_Len);
end;



end.