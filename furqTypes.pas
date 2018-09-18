unit furqTypes;

interface
uses
 SysUtils;

const
 //chEOL = #0;
 chTAB = #9;

type
 TCharSet = set of Char;

 // виды состояний контекста
 TFURQContextState = (
  csRun,      // выполнение кода
  csEnd,      // ждем нажатия кнопки-действия (если их список непустой) или квест завершен
  csInput,    // ждем ввода числа/строки
  csInputKey, // ждем нажатия клавиши
  csQuit,     // немедленный выход из программы

  //csCls,      // надо очистить экран
  //csSound,    // требуется проиграть звук
  //csMusic,    // требуется проиграть музыку

  csPause,    // ждем некоторое время
  csSave,     // требуется сохранение игры
  //csUpdate    // требуется обновление GUI
  csLoad,     // требуется загрузка сохраненной игры
  //csError     // произошла ошибка при выполнении
  csUndefined // неопределённое состояние (до запуска игры, например)
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

 cIdentStartSet = ['a'..'z','A'..'Z','А'..'Я','а'..'я','_', 'Ё', 'ё'];
 cIdentMidSet   = ['a'..'z','A'..'Z','А'..'Я','а'..'я','_', 'Ё', 'ё', '0'..'9'];

 cCaretReturn = #13#10;

 // Keywords
 kwdPln     = 'PLN';
 kwdPrintLn = 'PRINTLN';
 kwdPrint   = 'PRINT';
 kwdP       = 'P';


 // DefaultValues
 cDefaultPrecision = 2;
 cDefaultInvName   = 'Действия';

 // Системные переменные
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

 //Другое
 cSaveFileSignature = 'FURQSF';
 cBufSize = 102400;  // 100 Кб


// Функции преобразования значений не как надо, а как принято в URQL
function EnsureReal(const aValue: Variant): Extended;
function EnsureString(const aValue: Variant): string;


implementation
uses
 Variants;

// Функции преобразования значений не как надо, а как принято в URQL
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
