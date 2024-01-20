unit Eus.Types;
{$mode ObjFPC}{$H+}

interface

type

    {Strings}
    G3ArrayTUnknown = array of RawByteString;
    TStringArray = array of String;
    TAnsiStringArray = array of AnsiString;
    TWideStringArray = array of WideString;
    TRawByteStringArray = array of RawByteString;
    TUTF8StringArray = array of UTF8String;
    {Pointers needed for work with threads}
    TUnicodeStringArray = array of UnicodeString;
    TStringArrayP = array of PString;
    TAnsiStringArrayP = array of PAnsiString;
    TWideStringArrayP = array of PWideString;
    TRawByteStringArrayP = array of PRawByteString;
    TUTF8StringArrayP = array of PUTF8String;
    TUnicodeStringArrayP = array of PUnicodeString;
    PStringArray = ^TStringArray;
    PUTF8StringArray = ^TUTF8StringArray;
    PUnicodeStringArray = ^TUnicodeStringArray;
    PWideStringArray = ^TWideStringArray;
    PAnsiStringArray = ^TAnsiStringArray;
    PRawByteStringArray = ^TRawByteStringArray;
    TStringCollection = array of TStringArray;
    PStringCollection = ^TStringCollection;
    TStringCollectionP = array of PStringArray;
    PStringCollectionP = ^TStringCollectionP;

    {Colors}
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

    {SysAPI}
    {$ifdef MsWindows}
    TCLIOpts = WORD;
    {$else}
    TCLIOpts = record
      TextColor: ConsoleColor;
      BackgroundColor: ConsoleBgColor;
    end;
    {$endif}


implementation


end.

