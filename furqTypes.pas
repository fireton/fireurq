unit furqTypes;

interface
uses
 SysUtils;

const
 //chEOL = #0;
 chTAB = #9;

type
 TCharSet = set of Char;

 // ���� ��������� ���������
 TFURQContextState = (
  csRun,      // ���������� ����
  csEnd,      // ���� ������� ������-�������� (���� �� ������ ��������) ��� ����� ��������
  csInput,    // ���� ����� �����/������
  csInputKey, // ���� ������� �������
  csQuit,     // ����������� ����� �� ���������

  //csCls,      // ���� �������� �����
  //csSound,    // ��������� ��������� ����
  //csMusic,    // ��������� ��������� ������

  csPause,    // ���� ��������� �����
  csSave,     // ��������� ���������� ����
  //csUpdate    // ��������� ���������� GUI
  csLoad,     // ��������� �������� ����������� ����
  //csError     // ��������� ������ ��� ����������
  csUndefined // ������������� ��������� (�� ������� ����, ��������)
 );

 TFURQContextExecutionMode = (
  emNormal,
  emMenuBuild,
  emEvent
 );

 TFURQClsType = (clText, clButtons);
 TFURQClsTypeSet = set of TFURQClsType;

 TFURQActionModifier = (amNone, amNonFinal, amMenu);

 EFURQRunTimeError = class(Exception);

type
 TfurqOnErrorHandler = procedure (const aErrorMessage: string; aLine: Integer) of object;


const
 cWhiteSpaces   : TCharSet = [' ', chTAB, #0];
 cWordSeparators: TCharSet = [' ', chTAB, '&', #0];

 cIdentStartSet = ['a'..'z','A'..'Z','�'..'�','�'..'�','_', '�', '�'];
 cIdentMidSet   = ['a'..'z','A'..'Z','�'..'�','�'..'�','_', '�', '�', '0'..'9'];

 cCaretReturn = #13#10;

 // Keywords
 kwdPln     = 'PLN';
 kwdPrintLn = 'PRINTLN';
 kwdPrint   = 'PRINT';
 kwdP       = 'P';


 // DefaultValues
 cDefaultPrecision = 2;
 cDefaultInvName   = '��������';

 // ��������� ����������
 cVarHidePhantoms     = 'hide_phantoms';
 cVarCurrentLoc       = 'current_loc';
 cVarPreviousLoc      = 'previous_loc';
 cVarCommon           = 'common';
 cVarPrecision        = 'fp_prec';
 cVarTokenDelim       = 'tokens_delim';
 cVarPi               = 'pi';
 cVarInventoryEnabled = 'inventory_enabled';

 cLocCommonPrefix = 'common_';
 cLocCommon       = 'common'; 

 //������
 cSaveFileSignature = 'FURQSF';
 cBufSize = 102400;  // 100 ��


// ������� �������������� �������� �� ��� ����, � ��� ������� � URQL
function EnsureReal(const aValue: Variant): Extended;
function EnsureString(const aValue: Variant): string;


implementation
uses
 Variants;

// ������� �������������� �������� �� ��� ����, � ��� ������� � URQL
function EnsureReal(const aValue: Variant): Extended;
var
 l_Str: string;
begin
 if VarType(aValue) = varString then
 begin
  l_Str := aValue;
  Result := Length(l_Str);
 end
 else
  Result := aValue;
end;

function EnsureString(const aValue: Variant): string;
begin
 if VarType(aValue) <> varString then
  Result := ''
 else
  Result := aValue; 
end;

end.
