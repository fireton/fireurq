unit f2Utils;

interface

uses
 Windows;

function OpenFileDlg(aHandle: HWND; aTitle: PChar; aFilter: PChar): string;
function SaveFileDlg(aHandle: HWND; aTitle: PChar; aFilter: PChar; aDefExt: PChar): string;

function IsDirWritable(const aDir: AnsiString): Boolean;

implementation
uses
 SysUtils,
 CommDlg;

function OpenFileDlg(aHandle: HWND; aTitle: PChar; aFilter: PChar): string;
const
 cBufSize = 10240;
var
 l_OFN: TOpenFilename;
 l_Buf: string;
begin
 Result := '';
 SetLength(l_Buf, cBufSize);
 l_Buf[1] := #0;
 FillChar(l_OFN, SizeOf(TOpenFilename), 0);
 l_OFN.lStructSize := SizeOf(TOpenFilename);
 l_OFN.hWndOwner := aHandle;
 l_OFN.lpstrFilter := aFilter;
 l_OFN.lpstrFile := PChar(@l_Buf[1]);
 l_OFN.nMaxFile := cBufSize;
 l_OFN.lpstrTitle := aTitle;
 l_OFN.Flags := OFN_ENABLESIZING or OFN_FILEMUSTEXIST or OFN_LONGNAMES;
 if GetOpenFileName(l_OFN) then
 begin
  SetLength(l_Buf, Pos(#0, l_Buf)-1);
  Result := l_Buf;
 end;
end;

function SaveFileDlg(aHandle: HWND; aTitle: PChar; aFilter: PChar; aDefExt: PChar): string;
const
 cBufSize = 10240;
var
 l_OFN: TOpenFilename;
 l_Buf: string;
begin
 Result := '';
 SetLength(l_Buf, cBufSize);
 l_Buf[1] := #0;
 FillChar(l_OFN, SizeOf(TOpenFilename), 0);
 l_OFN.lStructSize := SizeOf(TOpenFilename);
 l_OFN.hWndOwner := aHandle;
 l_OFN.lpstrFilter := aFilter;
 l_OFN.lpstrFile := PChar(@l_Buf[1]);
 l_OFN.nMaxFile := cBufSize;
 l_OFN.lpstrTitle := aTitle;
 l_OFN.lpstrDefExt := aDefExt;
 l_OFN.Flags := OFN_ENABLESIZING or OFN_LONGNAMES or OFN_OVERWRITEPROMPT;
 if GetOpenFileName(l_OFN) then
 begin
  SetLength(l_Buf, Pos(#0, l_Buf)-1);
  Result := l_Buf;
 end;
end;

function IsDirWritable(const aDir: AnsiString): Boolean;
var
 l_F: TextFile;
 l_FN: AnsiString;
begin
 {$I-}
 l_FN := IncludeTrailingPathDelimiter(aDir) + '$furqch$.$$$';
 AssignFile(l_F, l_FN);
 Rewrite(l_F);
 try
  Result := (IOResult = 0);
  if Result then
  begin
   Writeln(l_F, 'write test');
   Result := (IOResult = 0);
  end;
 finally
  CloseFile(l_F);
 end;
 DeleteFile(l_FN);
 {$I+}
end;

end.