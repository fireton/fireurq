unit f2LinkParser;

interface
uses
 jclStringLists,
 RegExpr,

 d2dTypes,
 d2dFont,
 d2dFormattedText,

 furqContext;

function OutTextWithLinks(const aStr: string;
        const aTAT: Id2dTextAddingTool;
        const aContext: TFURQContext;
        const aActions: IJclStringList = nil): string;

implementation
uses
 SysUtils,

 furqTypes,
 furqBase;

const
 gLinkRegEx: TRegExpr = nil;

function GetLinkRegEx: TRegExpr;
begin
 if gLinkRegEx = nil then
 begin
  gLinkRegEx := TRegExpr.Create;
  gLinkRegEx.Expression := '\[\[([^[\]]+?)\]\]';
 end;
 Result := gLinkRegEx;
end;

function OutTextWithLinks(const aStr: string;
        const aTAT: Id2dTextAddingTool;
        const aContext: TFURQContext;
        const aActions: IJclStringList = nil): string;
var
 l_Start: Integer;
 l_AData: IFURQActionData;
 l_Loc: string;
 l_Params: IJclStringList;
 l_AM: TFURQActionModifier;
 l_ActionID: string;
 l_LIdx: Integer;
 l_LinkTarget: string;
 l_LinkTxt: string;
 l_Pos: Integer;
 l_RE: TRegExpr;
 l_SubStr: string;
begin
 Result := '';
 l_RE := GetLinkRegEx;
 if l_RE.Exec(aStr) then
 begin
  l_Start := 1;
  repeat
   if l_RE.MatchPos[0] > l_Start then
   begin
    l_SubStr := Copy(aStr, l_Start, l_RE.MatchPos[0] - l_Start);
    aTAT.AddText(l_SubStr);
    Result := Result + l_SubStr;
   end;
   l_Pos := Pos('|', l_RE.Match[1]);
   if l_Pos = 0 then
   begin
    l_LinkTxt := l_RE.Match[1];
    l_LinkTarget := Trim(l_LinkTxt);
    if l_LinkTxt[1] in ['!', '%'] then
     Delete(l_LinkTxt, 1, 1); // удаляем модификаторы, если они присутствуют в упрощённой ссылке
   end
   else
   begin
    l_LinkTxt := Copy(l_RE.Match[1], 1, l_Pos-1);
    l_LinkTarget := Copy(l_RE.Match[1], l_Pos+1, MaxInt);
   end;
   l_Params := JclStringList;
   ParseLocAndParams(l_LinkTarget, l_Loc, l_Params, l_AM);
   l_LIdx := aContext.Code.Labels.IndexOf(l_Loc);
   if l_LIdx = -1 then
   begin
    aTAT.AddLink(l_LinkTxt, '');
    Result := Result + l_LinkTxt;
   end
   else
   begin
    l_AData := TFURQActionData.Create(l_LIdx, l_Params, l_AM);
    l_ActionID := aContext.AddAction(l_AData, aActions);
    aTAT.AddLink(l_LinkTxt, l_ActionID);
    Result := Result + l_LinkTxt;
   end;
   l_Start := l_RE.MatchPos[0] + l_RE.MatchLen[0];
  until not l_RE.ExecNext;
  if l_Start <= Length(aStr) then
  begin
   l_SubStr := Copy(aStr, l_Start, MaxInt);
   aTAT.AddText(l_SubStr);
   Result := Result + l_SubStr;
  end;
 end
 else
 begin
  aTAT.AddText(aStr);
  Result := aStr;
 end;
end;

initialization
 // nope
finalization
 FreeAndNil(gLinkRegEx);
end.
