unit iniparser;
{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, FileUtil;

type
  G3ArrayTUnknown = array of RawByteString;

  TIniEncoding = (iecUTF8);
  TIniSection = record
   Name: RawByteString;
   Keys: G3ArrayTUnknown;
   Values: G3ArrayTUnknown;
  end;
  TIniSections = array of TIniSection;
  TIniData = record
    Name: RawByteString;
    Sections: TIniSections;
    Encoding: TIniEncoding;
    end;



implementation
function ValueOfKey(var AOf:TIniSection;Const Key:RawByteString;Out _Result:RawByteString;
  Const CPUThreadId:Byte=0; CPUThreads:Byte=1): Cardinal;
var
   I, Len: SizeInt;
begin
  Len := Length(AOf.Keys);
  if Len = 0 then
      Exit(1);

  I := CPUThreadId;
  while I < Len-1 do
  begin
    if AOf.Keys[I] = Key then
        begin
           _Result := AOf.Values[I];
           Exit(0);
        end;
    If (I + CPUThreads-1 > Len) And ((I+1)<Len) then
        I := I + 1
    else
        I := I + CPUThreads;
  end;

  Exit(1)
end;

function IdOfKey(var AOf:TIniSection; Const Key:RawByteString; Out _Result:SizeInt;
  Const CPUThreadId:Byte=0; CPUThreads:Byte=1): Cardinal;
var
   I, Len: SizeInt;
begin
  Len := Length(AOf.Keys);
  if Len = 0 then
      Exit(1);

  I := CPUThreadId;
  while I < Len-1 do
  begin
    if AOf.Keys[I] = Key then
        begin
           _Result := I;
           Exit(0);
        end;
    If (I + CPUThreads-1 > Len) And ((I+1)<Len) then
        I := I + 1
    else
        I := I + CPUThreads;
  end;

  Exit(1);
end;

procedure AmnesiacParseIni(AIniString: RawByteString; var AIni:TIniData; const Period:Byte=0);
begin

end;

function ParseG3String(AStr:RawByteString; EndChar:PChar=';'): String;
{ Convert special char symbols into their final form and replace other operators
  with respective result
}
(*AStr - input INI string*)
(*EndChar - special op char, that symbolizes the end of string*)
var
   I: SizeInt;
begin
  (* Parse RawByteStr
  for I:=0 to Length(AStr.Chars)-1 do
  begin

  end
  *)

end;

function ParseG3Array(AStr:RawByteString; Separator:PChar=';;'; EndChar:PChar=';'): G3ArrayTUnknown;
var
   I: SizeInt; {Never use a Byte, such short range won't do it}
begin
  SetLength(Result,0); {Initialize}



end;

end.

