program Eus;
//{$codepage UTF8}
{$mode ObjFPC}{$H+}
uses Classes, SysUtils, FileUtil, IniFiles
  {$ifdef MsWindows}, Windows{$endif}, iniparser;

type
    ConsoleColor =
    {$ifdef MsWindows}
    (
    cfBlack = 0, cfBlue = 1, cfGreen = 2, cfCyan = 3,
    cfRed = 4, cfMagenta = 5, cfYellow = 6, cfLightGrey = 7,
    cfDarkGrey = 8, cfLightBlue = 9, cfLightGreen = 10,
    cfLightCyan = 11, cfLightRed = 12, cfLightMagenta = 13,
    cfLightYellow = 14, cfWhite = 15, cfNone = 200
    );
    ConsoleBgColor =
    (
    cbBlack = 10, cbBlue = 11, cbGreen = 12, cbCyan = 13,
    cbRed = 14, cbMagenta = 15, cbYellow = 16, cbLightGrey = 17,
    cbDarkGrey = 18, cbLightBlue = 19, cbLightGreen = 20,
    cbLightCyan = 21, cbLightRed = 22, cbLightMagenta = 23,
    cbLightYellow = 24, cbWhite = 25, cbNone = 200
    );
    {$else}
    (
    cfBlack = 30, cfBlue = 34, cfGreen = 32, cfCyan = 36,
    cfRed = 31, cfMagenta = 35, cfYellow = 33, cfLightGrey = 37,
    cfDarkGrey = 90, cfLightBlue = 94, cfLightGreen = 92,
    cfLightCyan = 96, cfLightRed = 91, cfLightMagenta = 95,
    cfLightYellow = 93, cfWhite = 97, cfNone = 200
    );
    ConsoleBgColor =
    (
    cbBlack = 40, cbBlue = 44, cbGreen = 42, cbCyan = 46,
    cbRed = 41, cbMagenta = 45, cbYellow = 43, cbLightGrey = 47,
    cbDarkGrey = 100, cbLightBlue = 104, cbLightGreen = 102,
    cbLightCyan = 106, cbLightRed = 101, cbLightMagenta = 105,
    cbLightYellow = 103, cbWhite = 107, cbNone = 200
    );
    {$endif}
    StringArray = array of String;
    StringCollector = array of StringArray;

    //LangIDS//
    TArrayOfString =  array of String;
    TIniRowNames = array of String;
    TIniSectionNames = TIniRowNames;
    TIniRowValue = Array[0..11] of String;
    TIniRowValues = Array of TIniRowValue;
    TIniSectionValue = Record
      Names: TIniRowNames;
      Values: TIniRowValues;
    end;
    TIniRows = TIniSectionValue;

    TIniSectionValues = Array of TIniSectionValue;
    TIniStructure = Record
      SectionsNames: TIniSectionNames;
      SectionsValues: TIniSectionValues;
      Rows: TIniRows
    end;

    TIniString = String;
    TIniTranslation = record
      English,
      Italian,
      French,
      German,
      Spanish,
      Czech,
      Hungarian,
      Polish,
      Russian,
      TRC,
      Slovak,
      Ukrainian,
      ErrOrComenntary: TIniString;
      Raw: TIniString;
      Mass: array [0..12] of TIniString;
    end;
    {$ifdef MsWindows}
    TCLIOpts = WORD;
    {$else}
    TCLIOpts = record
      TextColor: ConsoleColor;
      BackgroundColor: ConsoleBgColor;
    end;
    {$endif}

    ///LangIDS//

const
{$ifndef MsWindows}
ESC_CHAR = Char(27);
AEC_START = ESC_CHAR + '[';
CSI = AEC_START;
AEC_RESET = ESC_CHAR + '[0m';
{$endif}

LangIDS:array[0..11] of String = ('[English]', '[Italian]', '[French]',
'[German]', '[Spanish]', '[Czech]', '[Hungarian]', '[Polish]',
'[Russian]', '[TRC]', '[Slovak]', '[Ukrainian]');

G3IniErrors:array[0..5] of String = (
  'Відсутній розгалужувальний символ (;)',
  'Комірку перекладу не  було закрито за допомогою розгалужувального символа (;)',
  'Синтаксична помилкка: комірка містить текст після завершального символу (;)',
  'Комірка перекладу містить більше мов, аніж доступно',
  'Синтаксична помилка: комірка містить розгалужуючий символ (;)',
  'Комірці перекладу бракує 1ї або більше мов'
  );
var
   op, isFail: Byte;
   ParamS: String;
  cwd, err,
    IniFInN, IniFCInN, IniFOutN, key, val, val_orig, sec: String;
  IniFIn, IniFCIn: TIniFile;
  NumOk, NumTot, NumErr: Integer;
  KeyNs, Dirs, Errors, LangValues: TStrings;
  CLIOpts, OrigCLIOpts: TCLIOpts;
  {$ifdef MsWindows}
  CLI_SBI: TConsoleScreenBufferInfo;
  StdOut: HANDLE;
  {$endif}
  IniFOut: TStrings;

  OutputLogFile, OutputTo: String;
  OutputLog: TStrings;
  DisallowConsoleOutput: Boolean = False;
  toReport: Boolean;


  procedure TextColor(Color: ConsoleColor);
  begin
  {$ifdef MsWindows}
  CLIOpts := (CLIOpts and $F0) or (Byte(Color) and $0F);
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  CLIOpts.TextColor := Color;
  Write( CSI, Byte(Color), 'm');
  {$endif}
  end;

procedure BackgroundColor(const Color: ConsoleBgColor);
begin
  {$IFDEF MSWINDOWS}
  CLIOpts := (CLIOpts and $0F) or Word((Byte(Color) shl 4) and $F0);
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$ELSE}
  CLIOpts.BackgroundColor:=Color;
  Write(CSI, Byte(Color), 'm');
  {$ENDIF}
end;

procedure CLIColors(const TextColor: ConsoleColor; BgColor: ConsoleBgColor);
begin
  {$IFDEF MSWINDOWS}
  CLIOpts := (CLIOpts and $F0) or (Byte(TextColor) and $0F);
  CLIOpts := (CLIOpts and $0F) or Word((Byte(BgColor) shl 4) and $F0);
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$ELSE}
  CLIOpts.TextColor := TextColor;
  CLIOpts.BackgroundColor := BgColor;
  Write(CSI, 0, ';', Byte(TextColor), ';', Byte(BgColor), 'm');
  {$ENDIF}
end;

procedure CLIStdColors();
begin
     {$ifdef MsWindows}
     CLIOpts := OrigCLIOpts;
     SetConsoleTextAttribute(StdOut, CLIOpts);
     {$else}
     CLIOpts.TextColor:=OrigCLIOpts.TextColor;
     CLIOpts.BackgroundColor:=OrigCLIOpts.BackgroundColor;
     Write( AEC_RESET );
     if Byte(CLIOpts.TextColor) <> 200 then
        TextColor(CLIOpts.TextColor);

     if Byte(CLIOpts.BackgroundColor) <> 200 then
        BackgroundColor(CLIOpts.BackgroundColor);

     {$endif}
end;

procedure WriteCol(const st: String;Color: ConsoleColor);
var CLIOptsBackup: TCLIOpts;
begin
  CLIOptsBackup := CLIOpts;
  TextColor(Color);
  Write(PChar(st));
  CLIOpts := CLIOptsBackup;
  {$ifdef MsWindows}
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  Write( AEC_RESET );
  {$endif}
end;

procedure WriteLnCol(const st: String;Color: ConsoleColor);
var CLIOptsBackup: TCLIOpts;
begin
  CLIOptsBackup := CLIOpts;
  TextColor(Color);
  WriteLn(PChar(st));
  CLIOpts := CLIOptsBackup;
  {$ifdef MsWindows}
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  Write( AEC_RESET );
  {$endif}
end;

function ConsoleTitle(_ATitle: PUtf8Char): {$ifdef MsWindows}WINBOOL{$else}Boolean{$endif};
begin
  {$ifdef MsWindows}
  Result := SetConsoleTitleW(PWideChar(WideString(Utf8String(_ATitle))));
  {$else}
  {$endif}
end;

procedure WriteCol(const st: String;Color: ConsoleBgColor); overload;
var CLIOptsBackup: TCLIOpts;
begin
  CLIOptsBackup := CLIOpts;
  BackgroundColor(Color);
  Write(PChar(st));
  CLIOpts := CLIOptsBackup;
  {$ifdef MsWindows}
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  Write( AEC_RESET );
  {$endif}
end;

procedure WriteLnCol(const st: String;Color: ConsoleBgColor); overload;
var CLIOptsBackup: TCLIOpts;
begin
  CLIOptsBackup := CLIOpts;
  BackgroundColor(Color);
  WriteLn(PChar(st));
  CLIOpts := CLIOptsBackup;
  {$ifdef MsWindows}
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  CLIStdColors();
  {$endif}
end;

procedure WriteCol(const st: String;Color: ConsoleColor; BGColor: ConsoleBgColor); overload;
var CLIOptsBackup: TCLIOpts;
begin
  CLIOptsBackup := CLIOpts;
  CLIColors(Color, BGColor);
  Write(PChar(st));
  CLIOpts := CLIOptsBackup;
  {$ifdef MsWindows}
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  Write( AEC_RESET );
  {$endif}
end;

procedure WriteLnCol(const st: String;Color: ConsoleColor; BGColor: ConsoleBgColor); overload;
var CLIOptsBackup: TCLIOpts;
begin
  CLIOptsBackup := CLIOpts;
  CLIColors(Color, BGColor);
  WriteLn(PChar(st));
  CLIOpts := CLIOptsBackup;
  {$ifdef MsWindows}
  SetConsoleTextAttribute(StdOut, CLIOpts);
  {$else}
  Write( AEC_RESET );
  {$endif}
end;

procedure WriteCol(const st: String; BGColor: ConsoleBgColor; Color: ConsoleColor); overload;
begin
  WriteCol(st, Color, BgColor);
end;

procedure WriteLnCol(const st: String; BGColor: ConsoleBgColor; Color: ConsoleColor); overload;
begin
  WriteLnCol(st, Color, BgColor);
end;

  ///-------------------------------------------------//
  function InArray(AArray: Array of String; AKey:String): Boolean;
  var Ist: SizeInt;
  begin
       Result := False;
       for Ist:=0 to Length(AArray)-1 do
         if AArray[Ist].Equals(AKey) then
         begin
             Result:=True;
             Exit;
         end;
  end;

  function InArray(AArray: Array of Boolean; AKey:Boolean): Boolean; overload;
  var Ist: SizeInt;
  begin
       Result := False;
       for Ist:=0 to Length(AArray)-1 do
         if AArray[Ist] = AKey then
         begin
             Result:=True;
             Exit;
         end;
  end;

  function InArray(AArray: Array of Byte; AKey:Byte): Boolean; overload;
  var Ist: SizeInt;
  begin
       Result := False;
       for Ist:=0 to Length(AArray)-1 do
         if AArray[Ist] = AKey then
         begin
             Result:=True;
             Exit;
         end;
  end;

  function InArray(AArray: Array of SizeInt; AKey:SizeInt): Boolean; overload;
  var Ist: SizeInt;
  begin
       Result := False;
       for Ist:=0 to Length(AArray)-1 do
         if AArray[Ist] = AKey then
         begin
             Result:=True;
             Exit;
         end;
  end;

{$ifdef MsWindows}
  function InArray(AArray: Array of Integer; AKey:Integer): Boolean; overload;
  var Ist: SizeInt;
  begin
       Result := False;
       for Ist:=0 to Length(AArray)-1 do
         if AArray[Ist] = AKey then
         begin
             Result:=True;
             Exit;
         end;
  end;
{$endif}

  ///-------------------------------------------------//
  function G3StringToArr(const str:String; var AList: TStrings; errstr:string): Byte;
  var I, EndCCount, StrEnd: Integer;
      EndC: Boolean;
      resultstr: String;

  begin
    Result := 0;
    AList.Clear;
    resultstr:='';
    EndC := True;
    EndCCount := 0;
    StrEnd := Length(str)-1;

    for I:=0 to StrEnd do
    begin
         if Ord(str.Chars[I]) = 59 then       //Char ;
         begin
            Inc(EndCCount);
            if EndC then
            begin
               if resultstr.Length = 0 then
                  resultstr := LangIDS[AList.Count];

               AList.Add(resultstr);
               EndC := False;
            end
            else
            begin
               EndC := True;
               resultstr := '';
            end;

         end
         else
         begin
             resultstr := resultstr + str.Chars[I];
             if (I < StrEnd-1) AND (NOT EndC) then
             begin
                errstr := G3IniErrors[2];
                Exit(1);
             end;
         end;
    end;

    errstr := '';
    if EndCCount = 0 then
    begin
       errstr := G3IniErrors[0];
       Result := 2;
       if AList.Count-1 > Length(LangIDS) then
          errstr := G3IniErrors[3];
    end
    else
    if EndCCount mod 2 = 0 then
    begin
       errstr := G3IniErrors[1];
       Result := 1;
    end;


  end;
function G3StringToArr2(const str:String; var AList: TArrayOfString; errstr:string): Byte;
var I, EndCCount, StrEnd: Integer;
    EndC: Boolean;
    resultstr: String;

begin
  Result := 0;
  SetLength(AList,0);
  resultstr:='';
  EndC := True;
  EndCCount := 0;
  StrEnd := Length(str)-1;

  for I:=0 to StrEnd do
  begin
       if Ord(str.Chars[I]) = 59 then       //Char ;
       begin
          Inc(EndCCount);
          if EndC then
          begin
             if resultstr.Length = 0 then
                resultstr := LangIDS[Length(AList)];
             SetLength(AList,Length(AList)+1);
             AList[Length(Alist)-1] := resultstr;
             EndC := False;
          end
          else
          begin
             EndC := True;
             resultstr := '';
          end;

       end
       else
       begin
           resultstr := resultstr + str.Chars[I];
           if (I < StrEnd-1) AND (NOT EndC) then
           begin
              errstr := G3IniErrors[2];
              Exit(1);
           end;
       end;
  end;

  errstr := '';
  if EndCCount = 0 then
  begin
     errstr := G3IniErrors[0];
     Result := 2;
     if Length(AList)-1 > Length(LangIDS) then
        errstr := G3IniErrors[3];
  end
  else
  if EndCCount mod 2 = 0 then
  begin
     errstr := G3IniErrors[1];
     Result := 1;
  end;
end;
  function G3ArrToString(const AList:TStrings; var str, errstr:String): Byte;
  var I: Integer;
      tempstr: String;
  begin
    str := '';
    Result := 0; //Exit(0) by default

    for I:=0 to AList.Count-1 do
    begin
        tempstr := AList.Strings[I];
        if I > Length(LangIDS)-1 then
        begin
           errstr := G3IniErrors[3];
           Result := 2;
        end
        else
        if tempstr.Length = 0 then
        begin
             Result := 2;
             errstr := G3IniErrors[5];
             tempstr := LangIDS[I];
        end;

        if tempstr.Contains(';') then
        begin
           errstr := G3IniErrors[4];
            Exit(1);
        end;



        str := str + tempstr + ';';
        if I < AList.Count-1 then
           str := str + ';';
    end;
  end;

  function G3IniDetermineLanguage(const str: String): Byte;
  var StrEnd, I, I2: SizeInt;
      x: String;
      LangIdTable: array of Boolean;
      LangIdMultiPhrases: array of String;
  begin
    LangIdMultiPhrases := [];
    StrEnd := str.Length-1;
    LangIdTable := [];

    for I:=0 to Length(LangIDS)-1 do
    begin
        SetLength(LangIdTable, I+1);
        LangIdTable[I] := True;
    end;

    for I:=0 to StrEnd do
    begin
        for I2:=0 to Length(LangIdMultiPhrases)-1 do
        begin
            if NOT LangIdMultiPhrases[I2].Contains(str.Chars[I]) then
               LangIdTable[I2] := False;
        end;
    end;
  end;

  ///-------------------------------------------------///
procedure GoCheckOut();
const
     NumErrArr:array[0..1] of PUtf8Char=('Частково','Невдача');
     NumErrArrCol:array[0..1] of ConsoleColor = (cfLightYellow,cfLightRed);
begin
  if NumErr = 0 then
 begin
    if OutputLogFile <> '' then
       OutputLog.Add('[Вдалося!][Мод:'+ExtractFileName(cwd)+']: Усього '+IntToStr(NumTot));

    If toReport then
    begin
      Write('[');
      WriteCol('Вдалося!', cfGreen);
      WriteLn('][Мод:', ExtractFileName(cwd),']: Усього ', IntToStr(NumTot))
    end;
 end
 else
 begin
    isFail := ((NumErr >= NumTot) And (NumTot>0)).ToInteger;

    if toReport then
    begin
         WriteLn();
         Write('[');
         WriteCol(NumErrArr[isFail], NumErrArrCol[isFail]);
         Write(']');
    end;
       if NumOk = 0 then
       begin
          if OutputLogFile <> '' then
          begin
           OutputLog.Add('['+NumErrArr[isFail]+'][Мод:'+ExtractFileName(cwd) +']'
           +': Усього '+ IntToStr(NumTot)+', [0 вдало]');
           OutputLog.Add(''#10#13);
          end;

           If toReport then
            WriteLn('[Мод:', ExtractFileName(cwd),']: Усього ', IntToStr(NumTot),
        ', [0 вдало]');
       end
       else
       begin
           if OutputLogFile <> '' then
          begin
           OutputLog.Add('['+NumErrArr[isFail]+'][Мод:'+ExtractFileName(cwd)+']'
           +': Усього '+IntToStr(NumTot)+', ['+IntToStr(NumOk)+'вдало/невдало'+IntToStr(NumErr)+']');
           for err in Errors do begin OutputLog.Add(err);end;
           OutputLog.Add(''#10#13);
           end;

           if toReport then
           begin
            WriteLn('[Мод:', ExtractFileName(cwd),']: Усього ', IntToStr(NumTot),
        ', [', IntToStr(NumOk), 'вдало/невдало', IntToStr(NumErr),']');
            if OutputLogFile = '' then
           for err in Errors do begin WriteLn(); WriteCol(PUTF8Char(err), cfRed);end;

            WriteLn();
           end;

       end;
 end;
 end;

  procedure Golint();
  begin
    isFail := 0;
    for cwd in Dirs do
    begin
      Errors.Clear;
      IniFInN  := cwd + '\\stringtableMod.ini';
      if Not FileExists(IniFInN) then Continue;
      IniFIn := TIniFile.Create(IniFInN);
      IniFIn.ReadSection(sec, KeyNs);
      NumTot := KeyNs.Count;
      NumOk := 0;
      NumErr := 0;

      for key in KeyNs do
      begin
        val := IniFIn.ReadString(sec, key, '[ERRIOR!]');
        if val = '[ERRIOR!]' then
        begin
           Errors.Add('Відсутні дані в секції: [' + key + ']');
           Inc(NumErr);
        end
        else
        begin
           G3StringToArr(val,LangValues,err);
           if LangValues.Count <> 12 then
           begin
                Errors.Add('Довжина [' + key + ']: ' + IntToStr(LangValues.Count));
                Errors.Add(PChar(val));
                Inc(NumErr);
           end
           else
               Inc(NumOk);
        end;
      end;
      GoCheckOut();
    end;
    IniFIn.Free;
  end;

  procedure GoCombine();
  begin
    isFail := 0;
    IniFOut := TStringList.Create;
    for cwd in Dirs do
  begin
  IniFInN  := cwd + '\\stringtableMod_old.ini';
  IniFCInN := cwd + '\\stringtableMod_ua.ini';
  IniFOutN := cwd + '\\stringtableMod.ini';

  IniFIn := TIniFile.Create(IniFInN);
  IniFCIn := TIniFile.Create(IniFCInN);
  IniFOut.Clear;

  IniFIn.ReadSection(sec, KeyNs);
  NumTot := KeyNs.Count;
  NumOk := 0;
  NumErr := 0;

  for key in KeyNs do
  begin
       val      := IniFCIn.ReadString(sec, key, '[УКР]');
       val_orig := IniFIn.ReadString(sec, key, '[ERR!1!');
       if (val <> '[УКР]') AND (val_orig <> '[ERR!1!]') then
       begin
          NumOk := NumOk + 1;
       end
       else
       begin
          NumErr := NumErr + 1;
          if val <> '[УКР]' then
             err := '[Old] '
          else
              err := '[Ua] ';
          Errors.Add(err + key);
       end;
       if val_orig <> '[ERR!1!]' then
       begin
          if
            (val = 'en')
                 OR
            (val = 'EN')
                 OR
            (val = '[en]')
                 OR
            (val = '[ENG]')
                 OR
            (val = '[ang]')
                 OR
            (val = '[ANG]')
                 OR
            (val = 'ang')
                 OR
            (val = 'ANG')
                 or
            (val = 'eng')
                 or
            (val = 'ENG')
            then
                val := '[УКР]';
          if val <> '[УКР]' then
          begin
             G3StringToArr(val,LangValues,err);
             if LangValues.Count < 10 then
             begin
               // WriteLnCol('Довжина [' + key + ']: ' + IntToStr(LangValues.Count), cfLightYellow);
               // WriteLn(PChar(val));
             end;
          end;

          if val <> '[УКР]' then
             G3StringToArr(val, LangValues, err);
          if LangValues.Count > 11 then
             val := LangValues.Strings[11]
          else
              if LangValues.Count > 0 then
                 val := LangValues.Strings[0]
              else
              begin
                  G3StringToArr(val_orig, LangValues, err);
                  if LangValues.Count > 11 then
                     val := LangValues.Strings[11]
                  else
                     if LangValues.Count > 0 then
                        val := LangValues.Strings[0]
                     else
                         val := '[УКР]';
              end;

          IniFOut.Add(key + '=' + val_orig + ';SK;;' + val + ';');
       end;
  end;
      IniFIn.Free;
      IniFCIn.Free;
      IniFOut.SaveToFile(IniFOutN);
      GoCheckOut();
  end;

  IniFOut.Free;
  end;
(*
procedure GoCombine3();
var Files: TStrings;
    FinalINI: TIniStructure;
    LVals: TArrayOfString;
    IL: SizeInt;
    KVIn: Boolean;
begin
  isFail := 0;
  IniFOut := TStringList.Create;
  Files := TStringList.Create;

  for cwd in Dirs do
  begin
    FindAllFiles(Files,cwd,'',False);
    IniFOutN := cwd + '\\stringtableMod.ini';
    NumTot := 0;
    NumOk  := 0;
    NumErr := 0;
    IniFOut.Clear;
    for IniFInN in Files do
    begin
      IniFIn := TIniFile.Create(IniFInN);

      IniFIn.ReadSection(sec, KeyNs);
      for key in KeyNs do
      begin
        if not InArray(FinalINI.SectionsNames, key) then
        begin
          SetLength(FinalINI.SectionsNames, Length(FinalINI.SectionNames)+1)
          FinalINI.SectionsNames[Length(FinalINI.SectionsNames)-1] := key;
        end;

        val := IniFIn.ReadString(sec,key,'');
        SetLength(FinalINI.SectionsValues,  Length(FinalINI.SectionsValues)+1);
        if val.Trim.Equals('') then
        begin
          SetLength(FinalINI.SectionsValues[Length(FinalINI.SectionsValues)-1], Length(LangIDS));
          FinalINI.SectionsValues[Length(FinalINI.SectionsValues)-1] := LangIDS;
        end
        else
        begin
          G3StringToArr(val,LVals,err);
          SetLength(FinalINI.SectionsValues[Length(FinalINI.SectionsValues)-1], Length(LangIDS));
          for IL:=0 to Length(LangIDS)-1 do
          begin
            if IL+1 > Length(LVals) then
               FinalINI.SectionsValues[Length(FinalINI.SectionsValues)-1][IL] := LangIDS[IL];
            else
                FinalINI.SectionsValues[Length(FinalINI.SectionsValues)-1] := LVals[IL];
          end;
        end;

      end;
      iniFIn.Free;
    end;





for key in KeyNs do
begin
     val      := IniFCIn.ReadString(sec, key, '[УКР]');
     val_orig := IniFIn.ReadString(sec, key, '[ERR!1!');
     if (val <> '[УКР]') AND (val_orig <> '[ERR!1!]') then
     begin
        NumOk := NumOk + 1;
     end
     else
     begin
        NumErr := NumErr + 1;
        if val <> '[УКР]' then
           err := '[Old] '
        else
            err := '[Ua] ';
        Errors.Add(err + key);
     end;
     if val_orig <> '[ERR!1!]' then
     begin
        if
          (val = 'en')
               OR
          (val = 'EN')
               OR
          (val = '[en]')
               OR
          (val = '[ENG]')
               OR
          (val = '[ang]')
               OR
          (val = '[ANG]')
               OR
          (val = 'ang')
               OR
          (val = 'ANG')
               or
          (val = 'eng')
               or
          (val = 'ENG')
          then
              val := '[УКР]';
        if val <> '[УКР]' then
        begin
           G3StringToArr(val,LangValues,err);
           if LangValues.Count < 10 then
           begin
              WriteLnCol('Довжина [' + key + ']: ' + IntToStr(LangValues.Count), cfLightYellow);
              WriteLn(PChar(val));
           end;
        end;

        if val <> '[УКР]' then
           G3StringToArr(val, LangValues, err);
        if LangValues.Count > 11 then
           val := LangValues.Strings[11]
        else
            if LangValues.Count > 0 then
               val := LangValues.Strings[0]
            else
                val := '[УКР]';

        IniFOut.Add(key + '=' + val_orig + ';SK;;' + val + ';');
     end;
end;
    IniFIn.Free;
    IniFOut.SaveToFile(IniFOutN);
    GoCheckOut();
end;

IniFOut.Free;
end;
*)
  procedure G3WaitEnter();
  var Ic: Char;
  begin
       WriteLn();
       Write('Натисніть (ВВІД) для завершення...');
       Read(Ic);
  end;

  procedure GoAbout;
  begin
       WriteLn('Використання:');
       WriteLn(
        ParamStr(0).Split( DirectorySeparator )[ ParamStr(0).CountChar( DirectorySeparator ) ],
        ' [КОМАНДА] [ОПЦІЇ]'
        );
       WriteLn();
       WriteLn('[За замовчуванням засіб перевіряє і об'#39'єднує файли з піддиректорій у /input/ у кінцеві піддерикторії /output/]');
       WriteLn('  Ввідні файл(-и) зада(є/ю)ться опцією -вв');
       WriteLn('  Вивідні файл(-и) або директорія зада(ю/є)ться опцією -ви');
       WriteLn();
       WriteLn('-д, -допомога');
       WriteLn('  Докладна допомога'#10#13);
       WriteLnCol('Ядер доступно для обрахунку: '+GetCPUCount().ToString, cfYellow);
       WriteLn('DefaultSystemCP:', DefaultSystemCodePage,
       ' DefaultUnicodeCP:', DefaultUnicodeCodePage,
       ' DefaultFileSystemCP:', DefaultFileSystemCodePage,
       ' DefaultRTLFilesystemCP:', DefaultRTLFileSystemCodePage);
       WriteLn('Примітки:');
       WriteLnCol('Програма, на жаль, зараз не підтримує побитого кодування, тому невідповідність кодувань потрібно виправляти самотужки',
       cfLightRed);
       (*
Name	Description
DefaultSystemCodePage	Actual code page to use when CP_ACP is encountered
DefaultUnicodeCodePage	Code page for new Unicode strings
DefaultFileSystemCodePage	Codepage to use when sending strings to single-byte OS file system routines.
DefaultRTLFileSystemCodePage  *)
       G3WaitEnter();
  end;

  procedure GoHelp;
  begin
       WriteLn('==КОМАНДИ==');
       WriteLn('-c, -combine, -к, -з, -з'#39'єднати');
       WriteLn('    З'#39'єднати INI-файли перекладу у всіх підкаталогах.');
       WriteLn();
       WriteLn('-l, -л, -lint, -п, -перевірити');
       WriteLn('    Перевірити усі INI-файли у підкаталогах на наявність синт.помилок.');
       WriteLn();
       WriteLn('-c2, -к2, -з2');
       WriteLn('    Застосувати латку до файлу перекладу у всіх підкаталогах.');
       WriteLn();
       WriteLn('-v, -verbose, -version, -ver, -версія,-в');
       WriteLn('    Відобразити інформацію про версію та АП.');
       WriteLn();
       WriteLn('-h, -help, -д, -допомога');
       WriteLn('    Відобразити цю допомогу.');
       WriteLn();
       WriteLn('==ОПЦІЇ==');
       WriteLn('+o, +output, +в, +вивід [ДИРЕКТОРІЯ]/[ФАЙЛ]');
       WriteLn('    Задати вивід команди у директорію(в піддерикторії) або у єдний файл');
       WriteLn();
       WriteLn('-зв, -звіт, -log');
       WriteLn('    Відображати докладний звіт');
       WriteLn();
       WriteLn('+зв, +звіт, +log [ФАЙЛ]');
       WriteLn('    Виводити звіт у файл');
       G3WaitEnter();
  end;
  ///-------------------------------------------------///

procedure GoCombine2();
var FOut: TStrings;
begin
  isFail := 0;
  FOut := TStringList.Create;

  for cwd in Dirs do
begin
FOut.Clear;
FOut.Add('[' + sec + ']');
IniFInN  := cwd + '\\stringtableMod_ua.ini';
IniFCInN := cwd + '\\stringtableMod_patch.ini';
IniFOutN := cwd + '\\stringtableMod.ini';

IniFIn := TIniFile.Create(IniFInN);
IniFCIn := TIniFile.Create(IniFCInN);

IniFIn.ReadSection(sec, KeyNs);
NumTot := KeyNs.Count;
NumOk := 0;
NumErr := 0;

  for key in KeyNs do
  begin

       val_orig := IniFIn.ReadString(sec, key, '[ERR!1!');
       if (val_orig <> '[ERR!1!]') then
       begin
            Inc(NumOk);
       end
       else
       begin
            Inc(NumErr);
            Errors.Add('[Old] ' + key);
       end;
       if val_orig <> '[ERR!1!]' then
       begin

          G3StringToArr(val_orig,LangValues,err);
          if LangValues.Count < 12 then
          begin
             val      := IniFCIn.ReadString(sec, key, '[УКР]');
             if
              (val = 'en')
                   OR
              (val = 'EN')
                   OR
              (val = '[en]')
                   OR
              (val = '[ENG]')
                   OR
              (val = '[ang]')
                   OR
              (val = '[ANG]')
                   OR
              (val = 'ang')
                   OR
              (val = 'ANG')
                   or
              (val = 'eng')
                   or
              (val = 'ENG')
              then
                val := '[УКР]';
             FOut.Add(key + '=' + val_orig + ';SK;;' + val + '([ГУГОЛ]);');
          end
          else
              FOut.Add(key + '=' + val_orig);
       end;
  end;
    IniFIn.Free;
    IniFCIn.Free;
    FOut.SaveToFile(IniFOutN);
    GoCheckOut();
end;
FOut.Free;
IniFIn.Free;
IniFCIn.Free;
end;
  ///-------------------------------------------------///
var ParamIdent: SizeInt;
    PRX_Out: Byte = 0;
const NumErrArr:array[0..1] of PUtf8Char = ('Готовий.', 'Не готовий!');
      NumErrArrCol:array[0..1] of ConsoleColor = (cfGreen, cfLightRed);
begin
  {$ifdef MsWindows}
  SetConsoleOutputCP(65001);

  {if something goes wrong with the encoding, do the
  DefaultUnicodeCodePage:=65001;
  }

  CLI_SBI.wAttributes := 0; // FPC-LAZ: initialize
  FillChar(CLI_SBI, SizeOf(CLI_SBI), 0);
  StdOut := GetStdHandle(STD_OUTPUT_HANDLE);
  GetConsoleScreenBufferInfo(StdOut, CLI_SBI);
  OrigCLIOpts := CLI_SBI.wAttributes;
  CLIOpts := OrigCLIOpts;
  {$else}
  OrigCLIOpts.TextColor := cfNone;
  OrigCLIOpts.BackgroundColor := cbNone;
  CLIOpts := OrigCLIOpts;
  {$endif}

  ConsoleTitle('Euanosphere');
  LangValues := TStringList.Create;
  Dirs := TStringList.Create;
  KeyNs := TStringList.Create;
  Errors := TStringList.Create;
  OutputLog:= TStringList.Create;
  isFail := 2;
  OutputLogFile := '';

  cwd := GetCurrentDir() + '\\input';
  op := 4;

  if (ParamCount > 0) then begin
  for ParamIdent:=0 to ParamCount do
      begin
      ParamS := ParamStr(ParamIdent).ToLower;
      if ParamS.Equals('-c') Or ParamS.Equals('-к') Or Params.Equals('-з')
         Or ParamS.Equals('-combine')
         Or ParamS.Equals('-комбінувати')
         Or ParamS.Equals('-з'#39'єднати')then
         begin
              op := 1;
              continue;
         end;

      if ParamS.Equals('-l') Or ParamS.Equals('-л') Or ParamS.Equals('-п')
         Or ParamS.Equals('-lint')
         Or ParamS.Equals('-лінтер')
         Or ParamS.Equals('-перевірити')then
         begin
              op := 2;
              continue;
         end;

      if ParamS.Equals('-c2') Or ParamS.Equals('-к2') Or ParamS.Equals('-з2')then
      begin
         op := 3;
         continue;
      end;

      if ParamS.Equals('-в') Or ParamS.Equals('-версія') Or ParamS.Equals('-v')
         Or ParamS.Equals('-verbose') Or ParamS.Equals('-a')
         Or ParamS.Equals('-about')
         then
      begin
         op := 4;
         continue;
      end;

      if ParamS.Equals('-h') Or ParamS.Equals('-help')
         Or ParamS.Equals('-д') Or ParamS.Equals('-допомога') then
      begin
         op := 5;
         continue;
      end;

      if ParamS.Equals('-nco') Or
      ParamS.Equals('-noconsoleoutput') Or ParamS.Equals('-бкв') Or ParamS.Equals('-безвиводауконсоль')
      Or ParamS.Equals('-dco') Or ParamS.Equals('-disableconsoleoutput') Or ParamS.Equals('-вкв')
      Or ParamS.Equals('-вимкнутививідуконсоль') Or ParamS.Equals('-вимкнутиконсольнийвивід') then
      begin
           DisallowConsoleOutput := True;
           continue;
      end;

      if ParamS.Equals('-in') Or ParamS.Equals('-input')
         Or ParamS.Equals('-вв') Or ParamS.Equals('-ввід') then
      begin
          PRX_Out := 1;
          continue;
      end;

      if ParamS.Equals('-o') Or ParamS.Equals('-output')
         Or ParamS.Equals('-ви') Or ParamS.Equals('-вивід') then
      begin
          PRX_Out := 2;
          continue;
      end;

      if ParamS.Equals('+зв') Or ParamS.Equals('+звіт') or ParamS.Equals('+log') then
      begin
           PRX_Out := 3;
           continue;
      end;

      case PRX_Out of
         1:
                if FileExists( ExpandFileName(ParamStr(ParamIdent)) ) then
                   cwd := ExpandFileName(ParamStr(ParamIdent));
         2:
                OutputTo := ExpandFileName(ParamStr(ParamIdent));
                //TODO.TODO.TODO перенаправлення вивідного файлу для усіх команд!

         3:
                OutputLogFile:=ExpandFileName(ParamStr(ParamIdent));
         end;
       PRX_Out := 0;

     end;
  end;

  toReport := (Not DisallowConsoleOutput) Or (OutputLogFile = '');

  sec      := 'LocAdmin_Strings';

  FindAllDirectories(Dirs, cwd, False);
  if (Dirs.Count < 1) then
     op := 4;

  case op of
     1: GoCombine();
     2: GoLint();
     3: GoCombine2();
     4: GoAbout();
     5: GoHelp();
     else
       GoHelp();
     end;
  KeyNs.Free;
  Errors.Free;
  Dirs.Free;
  LangValues.Free;

    if op < 4 then begin
       if OutputLogFile <> '' then
       begin
          OutputLog.Add(''#10#13'Загальний стан проекту: '+NumErrArr[(isFail<1).ToInteger]);
          OutputLog.SaveToFile(OutputLogFile);
       end;

         Write('Загальний стан проекту: ');
         WriteCol(NumErrArr[(isFail<1).ToInteger], NumErrArrCol[(isFail<1).ToInteger]);
         WriteLn();
    end;
    OutputLog.Free;
end.

