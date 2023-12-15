

program EPROMPROGRAMMER ;

USES DOS, CRT, Eprom1   ;  { Include Eprom Types Data loader and Editor }

{-----------------------------------------------------------}
{ EPROM.PAS                             T.J. van Dyk        }
{ Eprom Programmer                                          }
{-----------------------------------------------------------}
{ INCLUDE FILES : Eprom1.pas : Eprom Hardware data loader   }
{-----------------------------------------------------------}
{ DATA FILES    : Eprom.dat  : Data file for eprom1.pas     }
{-----------------------------------------------------------}

TYPE
     DummyPtr    = ^LONGINT                       ;

     DumpRecType =  RECORD                          { Header for dumpfile }
                      FileId    : str10           ; { = EpromData1        }
                      EpromName : Str10           ; { Code 2716           }
                      EpromSize : WORD            ; { 2k-64k              }
                      EpromType : INTEGER         ; { Record 1-12         }
                      DataSize  : WORD            ; { Size of Dump        }
                      DataStart : WORD            ; { Start Address       }
                      CheckSum  : LONGINT         ; { Dump Total          }
                      LastByte  : BYTE            ; { Top byte 65535      }
                    END                           ;


CONST
     AllOn  : BitSet = [D0..D7]            ; { Set with all bits ON }


VAR
     {-------------------------------}
     { Eprom Data : Main Record      }
     {-------------------------------}
     DumpRec        : DumpRecType    ;
     OK             : BOOLEAN        ;
     CheckSum       : LONGINT     ;
     DumpOption     : INTEGER     ; { Hex or decimal dump display }
     FreeEnd,
     HeapEnd,
     HeapStart      : REAL    ;
     AddrSizeStr    : Str10   ;  { Current size of Eprom Data      }
     AddrStartStr   : Str10   ;  { Current pointer to Eprom Start  }
     AddrEndStr     : Str10   ;  { Current pointer to Eprom End    }

{-------------------------------------}
{ Clear Buffer (fill with FillChar)   }
{-------------------------------------}
PROCEDURE ClearEprom ( CStart, CEnd : WORD ; FillChar : BYTE ) ;

VAR i : WORD ;

BEGIN
  IF CEnd > BufferEnd THEN CEnd := BufferEnd                ;
  IF CStart < BufferStart THEN CStart := BufferStart        ;
  FOR i := CStart TO CEnd DO EpromData^[i] := FillChar      ;
END ;

{---------------------------------------------}
{ Get address range to read-write-display     }
{---------------------------------------------}
PROCEDURE GetAddr (VAR StartStr,  EndStr  : Str10 ;
                   VAR StartAddr, EndAddr : WORD  ;
                       Option : BYTE ) ;

VAR
  AStr                       : Str20   ;
  HexDec, i, E, n    : INTEGER ;

BEGIN
    HexDec := 0 ;
    EndStr   := ' ' ;

    IF Option < 5 THEN MakeWindow (900,2,9,Brown,Cyan,1) ;

   REPEAT

    E := 0                      ;
    IF Option < 5 THEN CLRSCR   ;

    CASE Option OF 0, 3 : BEGIN WRITE (' READ  : Enter ')       ;
                                AStr := '(Buffer)'        ; END ;
                   1, 4 : BEGIN WRITE (' WRITE : Enter ')       ;
                                AStr := '(Eprom)'         ; END ;
                      2 : BEGIN WRITE (' LOAD  : Enter ')       ;
                                AStr := '(New)'           ; END ;
    END                                                         ;
    CASE Option OF 0, 1 :
                   WRITE ( 'SOURCE start and end addresses.', NL,
                 ' [ H 000F 00FF ] hex [ D 15 255 ] decimal', NL, NL, '   ');
                2, 3, 4 :
                   WRITE ('TARGET ', AStr, ' start address.',NL,
                 ' [ H 000F ] hex [ D 15 ] decimal'         , NL, NL, '   ');
    END                                                                     ;
    READLN  (AStr) ;
    IF ( Option IN [ 2..4 ] ) THEN AStr := AStr + ' ' ;

    FOR i:=1 TO LENGTH(AStr) DO AStr[i] := UPCASE (AStr[i])  ;

    IF AStr[1] = 'H' THEN HexDec := 1                        ;
    IF AStr[1] = 'D' THEN HexDec := 2                        ;
    IF HexDec <> 0 THEN DELETE (AStr, 1, 2) ELSE HexDec := 2 ;

    i := 1 ;
    WHILE (AStr[i]<>' ') DO BEGIN StartStr[i] := AStr[i] ;
                                  INC (i)                ;
                            END                          ;

    StartStr[0] := CHR (i-1) ;
    n := LENGTH(StartStr)    ;
    INC (i)                  ;

    IF ( Option < 2) OR (Option = 5) THEN
    BEGIN
       WHILE i <= LENGTH (AStr) DO BEGIN        { IF Option < 2 }
                                     EndStr[i-n-1] := AStr[i]   ;
                                     INC (i)                    ;
                                   END                          ;
       EndStr[0] := CHR (i-2-n)                                 ;
    END                                                         ;

    IF HexDec = 1 THEN  { Convert Hex String to Integer }
    BEGIN
       StartAddr := HexToDec (StartStr)                  ;
       IF ( Option IN [0,1,5] ) THEN EndAddr := HexToDec (EndStr)   ;
    END                                                  ;

    IF HexDec = 2 THEN  { Convert Decimal String To Integer }
    BEGIN
      VAL (StartStr, StartAddr, E)    ;
      StartStr := DecToHex (StartAddr)    ;
      IF ( Option IN [0,1,5] ) THEN
      BEGIN
        VAL (EndStr  , EndAddr  , E)  ;    { E = pos of error }
        EndStr := DecToHex (EndAddr)    ;
      END ;
    END ;
    {------------------------------------}
    { Check addresses in range for Eprom }
    {------------------------------------}
    IF E > 0 THEN WRITELN ('Numeric Error..') ;

    IF (StartAddr >= EndAddr) AND ( Option IN [0,1,5] ) THEN
    BEGIN
      WRITELN ( 'Wrong Addresses entered..') ;
      DELAY (1000)   ;
      E := 1         ;
    END              ;

    IF (EndAddr>Eproms[EpromType].Size.Total) AND (Option IN [0,1,5]) THEN
     BEGIN
      WRITELN ( 'End Address is larger than EPROM Type...') ;
      DELAY (1000) ;
      E := 2       ;
    END            ;

  UNTIL E = 0 ;

END ;

{-----------------------------------}
{ Read the selected eprom data      }
{-----------------------------------}
PROCEDURE ReadEprom (VAR EpromType : INTEGER) ;

VAR
  i, n                       : WORD    ;
  Readbyte                   : BYTE    ;

BEGIN
    {----------------------}
    { Check Eprom Selected }
    {----------------------}
    IF NOT (CheckSelect) THEN EXIT ;

    MakeWindow (900,2,2,Black,Cyan,1) ;   { Display a window }

    CLRSCR                              ;

    WRITELN ( ' EPROM DUMP  : Eprom Type [ ',
                Eproms[EpromType].IdData.Number,' ] Size [ ',
                Eproms [EpromType].Size.Total,' ]',NL) ;

    GetAddr ( AddrStartStr, AddrEndStr, AddressStart, AddressEnd, 0 ) ;
    AddressSize := AddressEnd - AddressStart                ;
    BufferSize  := AddressSize                              ;
    AddrSizeStr := DecToHex (AddressSize)                   ;
    BuffSizeStr := AddrSizeStr                              ;

    GetAddr (BuffStartStr, BuffStartStr, BufferStart, BufferEnd, 3 ) ;
    BufferEnd   := BufferStart + BufferSize                 ;
    BuffEndStr  := DecToHex ( BufferEnd )                   ;

    GOTOXY ( 1,7 )                                           ;
    WRITE  ( '  SOURCE  [ Eprom ] Addresses : ', NL,
             '  Start     : ' ,AddressStart:5,' ( Hex ',AddrStartStr,' )',NL,
             '  End       : ' ,AddressEnd:5  ,' ( Hex ',AddrEndStr  ,' )',NL,
             '  Dump Size : ' ,AddressSize:5 ,' ( Hex ',AddrSizeStr ,' )' ) ;

    GOTOXY (1,11) ;
    WRITE  ( '  TARGET  [ Buffer ] Addresses : ', NL,
             '  Start     : ', BufferStart:5,' ( Hex ',BuffStartStr,' )',NL,
             '  End       : ', BufferEnd:5  ,' ( Hex ',BuffEndStr  ,' )',NL,
             '  DumpSize  : ', BufferSize:5, ' ( Hex ',BuffSizeStr ,' )',NL,
             '  Continue ... ' )  ;

    Choice := READKEY             ;
  {-----------------------}
  { Set-up Eprom for Read }
  {-----------------------}

  IF ReadWrite <> 1 THEN               ;  { Was here flag is true }
  BEGIN
    ReadWrite := 1                     ;  { Was here flag is true }
    SetupEpromForRead (EpromType)      ;
  END                                  ;

  {----------------------------------}
  { Clock 4040-4024 to Start Address }
  {----------------------------------}
  Reset4040                                         ;
  IF AddressStart > 0 THEN Clock4040 (AddressStart) ;
  {------------------------}
  { Read Byte              }
  {------------------------}
  CheckSum := 0            ; { Zero CheckSum }
  WRITE ( ' Reading... ')  ;

  n := BufferStart                        ;
  FOR i := AddressStart TO AddressEnd DO
  BEGIN
    ReadByte := Read4021                  ;
    IF (n < $FFFF) THEN EpromData^   [ n ]     := ReadByte
                   ELSE EpromDataTop^[n-$FFFF] := ReadByte ;
    CheckSum := CheckSum + ReadByte       ;
    WRITE ( i:5, #8#8#8#8#8 )             ;
    Clock4040 (1)                         ;
    INC ( n )                             ;
  END ;

  WRITE (NL,'  Checksum is : ', CheckSum ,' .... ') ; READLN   ;

END ;
{-----------------------------------}
{ Write the selected eprom data     }
{-----------------------------------}
PROCEDURE WriteEprom (VAR EpromType : INTEGER) ;

VAR
  i                           : WORD    ;
  Writebyte, Width, Direction : BYTE    ;

BEGIN
    {----------------------}
    { Check Eprom Selected }
    {----------------------}
    IF NOT (CheckSelect) THEN EXIT ;

    MakeWindow (900,2,2,Black,Cyan,1) ;   { Display a window }

    CLRSCR                                 ;

    WRITELN ( ' PROGRAM MODE : Eprom Type [ ',
                Eproms[EpromType].IdData.Number,' ] Size [ ',
                Eproms [EpromType].Size.Total,' ]',NL) ;

    GetAddr (BuffStartStr, BuffEndStr, BufferStart, BufferEnd, 1 ) ;
    BufferSize  := BufferEnd - BufferStart                         ;
    BuffSizeStr := DecToHex (BufferSize)                           ;
    AddressSize := BufferSize                                      ;
    AddrSizeStr := BuffSizeStr                                     ;

    GetAddr (AddrStartStr, AddrEndStr, AddressStart, AddressEnd, 4 ) ;
    AddressEnd  := AddressStart + AddressSize                ;
    AddrEndStr := DecToHex ( AddressEnd )                    ;

    GOTOXY (1,7) ;
    WRITE  ( '  SOURCE  [ Buffer ] Addresses : ', NL,
             '  Start     : ', BufferStart:5,' ( Hex ',BuffStartStr,' )',NL,
             '  End       : ', BufferEnd:5  ,' ( Hex ',BuffEndStr  ,' )',NL,
             '  DumpSize  : ', BufferSize:5 ,' ( Hex ',BuffSizeStr ,' )' ) ;

    GOTOXY ( 1,11)                                           ;
    WRITE  ( '  TARGET  [ Eprom ] Addresses : ', NL,
             '  Start     : ' ,AddressStart:5,' ( Hex ',AddrStartStr,' )',NL,
             '  End       : ' ,AddressEnd:5  ,' ( Hex ',AddrEndStr  ,' )',NL,
             '  Dump Size : ' ,AddressSize:5 , '( Hex ',AddrSizeStr ,' )',NL,
             '  Continue .... ' )         ;

    Choice := READKEY             ;
  {-----------------------}
  { Set-up Eprom for Write}
  {-----------------------}
  Width     := Eproms [EpromType].Prog.Pulse.Duration  ;
  Direction := Eproms [EpromType].Prog.Pulse.Direction ;

  IF ReadWrite <> 0 THEN                      ; { Previous was write as well}
  BEGIN
    ReadWrite := 0                            ; { Was here flag             }
    SetupEpromForWrite (EpromType, Direction) ;
  END                                         ;

  {----------------------------------}
  { Clock 4040-4024 to Start Address }
  {----------------------------------}
  Reset4040                                         ;
  IF AddressStart > 0 THEN Clock4040 (AddressStart) ;
  {------------------------}
  { Write Byte             }
  {------------------------}


if epromtype <> 4 then SetVpp (1) ; { Enable Vpp }

  DELAY (100); { Vpp Settling Time }

  CheckSum := 0            ; { Zero CheckSum }
  WRITE ( ' Writing... ')  ;

  FOR i := BufferStart TO BufferEnd DO
  BEGIN
    IF (i < $FFFF) THEN WriteByte := EpromData^ [i]
                   ELSE WriteByte := EpromDataTop^[i-$FFFF] ;
    Write4094 ( WriteByte )            ;
    SendPulse ( Width, Direction )     ;
    CheckSum := CheckSum + WriteByte   ;
    WRITE ( i:5, #8#8#8#8#8 )          ;
    Clock4040 (1)                      ;
  END ;

if epromtype <> 4 then SetVpp (0) ; { Disable Vpp }

  WRITE (NL,'  Checksum is : ', CheckSum ,' .... ') ; READLN   ;

END ;
{-----------------------------------}
{ Individual Bytes Editor           }
{-----------------------------------}
PROCEDURE DoEdit  ;

TYPE
   ModeType = ( Hex, DispA, DispV ) ;

VAR
  Edit                             : RECORD
                                     CASE BOOLEAN OF
                                          TRUE  :(Mode: SET OF ModeType) ;
                                          FALSE :(Num : BYTE)            ;
                                     END     ;
  ModeVar                          : ModeType;
  Address                          : LONGINT ;
  Value                            : WORD    ;
  AStr, ByteStr, AddrStr           : Str10   ;
  L, i, k, Flag                    : INTEGER ;

BEGIN

  WINDOW (52,15,72,21)  ;           { Display a window }
  TEXTBACKGROUND (Cyan) ; TEXTCOLOR (Black) ; CLRSCR ;
  Flag := 0             ;

  Edit.Mode := []; {Empty Set : Start with no option => decimal entry mode }

  REPEAT

    IF ( Flag<>5 ) AND ( L>1 ) THEN Address := Address+1 ;
    Value     := EpromData^[Address] ;
    k         := 0 ;
    Flag      := 0 ;
    AStr      := '';

   IF ( DispA IN Edit.Mode) THEN             { Display Address Mode SET }
   BEGIN
     IF ( Hex IN Edit.Mode ) THEN AddrStr:=DecToHex ( WORD (Address) )
                             ELSE STR (Address, AddrStr)             ;
     WRITE ( AddrStr:5,' ') ;
   END ELSE WRITE (' ')     ;          { If Display address mode not on }


   IF ( DispV IN Edit.Mode ) THEN               { Display next value ON }
   BEGIN
     GOTOXY (16, (WHEREY) )        ;
     TEXTCOLOR (Red)               ;
     IF NOT ( Hex IN Edit.Mode ) THEN WRITE ( Value:3 )
        ELSE BEGIN
               ByteStr := DecToHex ( Value ) ;
               DELETE ( ByteStr, 1, 2 )      ;
               WRITE  ( ByteStr:2     )      ;
             END                             ;
     IF ( DispA IN Edit.Mode ) THEN GOTOXY ( 9, (WHEREY) )
                               ELSE GOTOXY ( 4, (WHEREY) ) ;
     TEXTCOLOR (Edit.Num AND 1)                            ;
   END ;


   READLN ( AStr ) ;   L := LENGTH (AStr)      ;
   AStr [1] := UPCASE ( AStr[1] )              ;

   IF ( L=1 ) AND ( AStr[1] IN ['0'..'9','A'..'F'] ) THEN
   BEGIN
     L := 2             ;
     AStr := '0' + AStr ;
   END                  ;
   GOTOXY (1, (WHEREY-1) ) ; CLREOL         ;

   CASE L OF 0 : BEGIN   { Returnpress + DispVal On = Keep displayed value }
                   L := 3      ;
                   ByteStr := DecToHex ( Value )   ;
                   DELETE (ByteStr, 1, 2)          ;
                   AddrStr := DecToHex (WORD ( Address ) ) ;
                 END                               ;

         2..10 : BEGIN

                   IF NOT (DispA IN Edit.Mode) THEN
                   BEGIN
                     FOR i:= 1 TO L DO IF AStr[i] = ' ' THEN k := i ;
                     AddrStr := COPY (AStr, 1, k-1 )                ;
                   END                                              ;
                   ByteStr := COPY ( AStr, k+1, L-k )  ;

                   IF NOT (Hex IN Edit.Mode ) THEN
                   BEGIN
                     VAL (ByteStr, Value,   Flag) ;
                     VAL (AddrStr, Address, Flag) ;
                   END ELSE BEGIN
                              Value := LO ( HexToDec (ByteStr) )      ;
                              Address := WORD ( HexToDec (AddrStr) )  ;
                            END                                       ;

                  IF ( Value>255 ) OR ( Address<BufferStart )
                  OR ( Address>BufferEnd ) THEN  Flag := 3  ;

             END ;  { Case = L 2..10 }

        1  : BEGIN
                  Flag := 4 ;
                  CASE AStr[1] OF
                   'H' : Edit.Mode := Edit.Mode + [Hex] ;   { Hex Mode      }
                   'T' : Edit.Mode := Edit.Mode - [Hex] ;   { Decimal Mode  }
                   'R' : Edit.Num  := Edit.Num XOR 2    ;   { Display Addr  }
                   'X' : EXIT                           ;   { Exit to Edit  }
                   'V' : Edit.Num  := Edit.Num XOR 4    ;   { Display value }
                  END                                   ;
                  TEXTCOLOR (Edit.Num AND 1 ) ;
                  IF ( AStr[1] <> 'R' ) THEN INC ( Flag ) ;
             END  ;                                         { Case L 0..1 }

     END ; { Case L }

    IF (Flag = 0) THEN
    BEGIN
      EpromData^[ Address ] := Value ;
      IF ( Hex IN Edit.Mode ) THEN WRITELN( AddrStr:5, '  ', ByteStr:2 )
                              ELSE WRITELN( Address:5, ' ',  Value:3   ) ;
    END ;


 UNTIL L = 0 ;   { Never Loop }

END ;
{-----------------------------}
{ Help                        }
{-----------------------------}
{$I Eprom.inc}
{-----------------------------------}
{ Eprom Data Editor                 }
{-----------------------------------}
PROCEDURE Edit ;

CONST
S1='ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿';
S2='³          B U F F E R  E D I T O R             ³ Options Editor 2 :  ³';
S3='³ Options                           Page Size   ³                     ³';
S4='³     [1] Hex Dump - Editor 1       256         ³ [V] Show next value ³';
S5='³     [2] Decimal Dump              256         ³ [T] [H] Dec-Hex     ³';
S6='³     [3] Ascii Dump                1024        ³ [R] Next Address    ³';
S7='³     [E] Editor 2                  1-7         ³ [Enter] Skip        ³';
S8='³     [R] Range Change                          ³ [X] Exit            ³';
S9='³     [B] Block Move   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
SA='³     [C] Clear Block  ³ Buffer Decimal  Hex  ³ ³ Addr Val  Existing  ³';
SB='³     [M] Main Menu    ³ Start    65536 0FFF  ³ ³                     ³';
SC='³     [S] CheckSum     ³   End                ³ ³                     ³';
SD='³     [X] Exit to DOS  ³  Size                ³ ³                     ³';
SE='³                      ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ³                     ³';
SF='³ Select  [1] - [X] :                           ³                     ³';
SG='³                                               ³                     ³';
SH='³                                               ³                     ³';
SI='ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ';

BS  = #08#10                       ; {BS+LF}
Sp6 = '      '                     ;
Sp  = ' '                          ;
Sp4 = '    '                       ;
CL  = Sp6+Sp6+Sp6+Sp6+Sp6+Sp6+Sp6  ;

VAR
  i                   : INTEGER    ;
  N                   : LONGINT    ;
  M, X, k             : WORD       ;
  NStr, MStr          : STRING[4]  ;
  BFrom, BTo, BSize   : WORD       ;
  CChar               : BYTE       ;
  Y                   : CHAR       ;

PROCEDURE ClearL (Y : WORD) ;
BEGIN
  GOTOXY (3,Y)  ; WRITE (CL) ; GOTOXY (3,15) ;
END              ;

BEGIN

WINDOW ( 1,1,80,25) ; TEXTBACKGROUND (Blue) ; CLRSCR ;

REPEAT

  CLRSCR             ; WINDOW ( 3, 5, 74, 22 )  ;   { Display a window }
  TEXTCOLOR (Yellow) ; TEXTBACKGROUND ( Brown ) ;   CLRSCR ;
  WRITE (S1,NL,S2,NL,S3,NL,S4,NL,S5,NL,S6,NL,S7,NL,S8,NL,S9,NL,SA,NL,
         SB,NL,SC,NL,SD,NL,SE,NL,SF,NL,SG,NL,SH,NL,SI) ;

  TEXTCOLOR (White) ;
  GOTOXY (8, 4)     ;
  WRITE ('1',BS,'2',BS,'3',BS,'E',BS,'R',BS,'B',BS,'C',BS,'M',BS,'S',BS,'X');

  IF NOT (BufferEnd > BufferStart) THEN
  BEGIN
     GOTOXY (3, 15) ; WRITE ( 'Editor-Buffer Nil Size ....') ;
     GOTOXY (3, 16) ; WRITE ( '[Enter] Default ( 0 - 64k )') ;
     GOTOXY (3, 17) ; WRITE ( '[ESC]   MainMenu         : ') ;
    IF READKEY <> #13 THEN EXIT ;
    BufferStart := 0     ; BuffStartStr := '0'        ;
    BufferEnd   := $FFFF ; BuffEndStr   := 'FFFF'     ;
    BufferSize  := $FFFF ; BuffSizeStr  := BuffEndStr ;
  END ;

  GOTOXY (35,11) ; WRITE (  BufferStart:5,' ',BuffStartStr:4 ) ;
  GOTOXY (35,12) ; WRITE (  BufferEnd:5,  ' ',BuffEndStr:4   ) ;
  GOTOXY (35,13) ; WRITE (  BufferSize:5, ' ',BuffSizeStr:4  ) ;

  ClearL(15)     ; WRITE ('Select [1]-[6] or [B]-[X] : ' ) ;

  Choice := UPCASE ( READKEY ) ;

  CASE Choice OF
       '1'..'3' : BEGIN
                    DumpOption := ORD(Choice)-48 ; { DumpOption = 1,2,3,4,5 }
                    DisplayEpromData (BufferStart, BufferEnd, DumpOption) ;
                  END                                                 ;
       'R'      : BEGIN
                    GOTOXY (3,15) ; WRITE
                    ('New [START] [END] addresses : ')    ;
                    GetAddr (BuffStartStr, BuffEndStr,
                             BufferStart, BufferEnd, 5 )  ;
                    BufferSize := BufferEnd - BufferStart ;
                    BuffSizeStr := DecToHex (BufferSize)  ;
                    ClearL (15)                           ;
                  END ;
       'B'      : BEGIN
                    GOTOXY (3,15) ; WRITE
                    ('Move [From] [To] [Size] : ') ;
                    READLN (BFrom, BTo, BSize )                          ;

                    IF BFrom < BTo THEN FOR n := BSize-1 DOWNTO 0 DO
                       EpromData^[BTo+n] := EpromData^[BFrom+n]          ;
                    IF BFrom > BTo THEN FOR n := 0 TO BSize-1 DO
                       EpromData^[BTo+n] := EpromData^[BFrom+n]          ;
                    ClearL (15)                                          ;
                  END ;
       'C'      : BEGIN
                    GOTOXY (3,15) ; WRITE
                    ('Clear [From] [To] [Char (0-255)] : ')              ;
                    READLN (BFrom, BTo, CChar )                          ;
                    ClearEprom (BFrom, BTo, CChar)                       ;
                    ClearL (15)                                          ;
                  END ;
       'S'      : BEGIN
                    GOTOXY (3,15) ; WRITE
                    ('Calculate Checksum [From] [To] : ')                ;
                    READLN (BFrom, BTo )                                 ;
                    N := 0 ; MStr := '0000' ; M := 0                     ;
                    FOR k := BFrom TO BTo DO
                                            N := N + EpromData^[k]       ;
                    IF N > $FFFF THEN BEGIN M := N DIV 65536             ;
                                            X := N MOD 65536             ;
                                            MStr := DecToHex (M)         ;
                                            NStr := DecToHex (X) ; END
                                 ELSE BEGIN X := N                       ;
                                            NStr := DecToHex (X) ; END   ;
                    GOTOXY (3, 15) ; WRITE
                    ('Checksum : Hex ', MStr, Sp, NStr, '  Dec ', N, Sp4);
                    Y := READKEY                                         ;
                    ClearL (15)                                          ;
                  END ;
       'E'      : BEGIN
                    DoEdit  ;
                  END  ;
       'X'      : BEGIN
                    GOTOXY (3,15)                      ;
                    WRITE ('Are you sure ? [Y][N] : ') ;
                    Y := UPCASE(READKEY)               ;
                    IF Y = 'Y' THEN HALT(0)            ;
                    ClearL (15)                        ;
                  END                                  ;
   END          ;

 UNTIL Choice = 'M' ;

END ;
{-----------------------------------}
{ File Services                     }
{-----------------------------------}
PROCEDURE OpenFiles (VAR FileName : FILE; T : BYTE ) ;

VAR
  FileN : String ;
  S     : Str10  ;

BEGIN
  IF (T=0) OR (T=2) THEN
  BEGIN
    IF T=0 THEN S := 'Load' ELSE S := 'Conversion'         ;
    WRITE   (NL, ' Filename for ',S,' : '); READLN (FileN) ;
    ASSIGN  (  FileName, FileN )                           ;
    {$I-}
    RESET   (  FileName, 1 )                           ; { Blocksize=1 byte }
    {$I+}
    IF IORESULT <> 0 THEN BEGIN
                            WRITE (NL, ' File not found ...') ;
                            DELAY (1000)                      ;
                          END                                 ;
  END                               ;
  IF T=1 THEN
  BEGIN
    WRITE   (NL, ' FileName for save : ') ; READLN (FileN) ;
    ASSIGN  (  FileName, FileN )          ;
    REWRITE (  FileName, 1 )              ; { 1 Parameter=Blockread 1 byte }
  END                                     ;
END ;
{----------------------------------------------------------------}
PROCEDURE SaveFile (VAR FileName : FILE ;
                    VAR DataStart, DataSize : WORD ; Option : BYTE ) ;

VAR
    BytesWritten, n : INTEGER ;

BEGIN
  { ------------------- Make Header          }
  IF Option=0 THEN

     BEGIN
       DumpRec.DataSize  := DataSize  ;
       DumpRec.DataStart := DataStart ;
       DumpRec.CheckSum  := CheckSum  ;
       DumpRec.LastByte  := EpromDataTop^ [0]   ;
       DumpRec.FileId    := 'EPROMDATA1'        ;
       DumpRec.EpromName := Eproms [EpromType].IdData.Number ;
       DumpRec.EpromSize := Eproms [EpromType].Size.Total    ;
       DumpRec.EpromType := EpromType           ;
       { -------------------- Write Header        }
       REPEAT

         { First record 35 bytes list the dump and file parameters   }
         BLOCKWRITE (FileName, DumpRec, SIZEOF (DumpRec) , n ) ;
         { -------------------- Write Data                           }
         BLOCKWRITE (FileName, EpromData^, DataSize+1 , BytesWritten ) ;

       UNTIL BytesWritten > 0 ;

       WRITE (NL,' DataSize saved : ', BytesWritten , ' bytes...' ); READLN ;
     END ; { Option = 0 }

  IF Option = 1 THEN { Conversion to Headerless Binary Image }

     BEGIN

       REPEAT
         { -------------------- Write Data Only                            }
         BLOCKWRITE (FileName, EpromData^, DataSize+1 , BytesWritten )     ;
       UNTIL BytesWritten > 0 ;

       WRITE (NL,' Binary Image Saved: (Size: ', BytesWritten,')' )  ;
       READLN ;
     END ; { Option = 1 }

  CLOSE ( FileName ) ;

END ;
{----------------------------------------------------------------}
PROCEDURE LoadFile ( VAR FileName : FILE ;
                     VAR DataStart, DataSize: WORD ; Option : BYTE ) ;

VAR
    BytesRead, n : INTEGER ;
    Str1         : Str10   ;
    FSize        : LONGINT ;

BEGIN

  BytesRead := 0 ;

  REPEAT

    IF Option <> 2 THEN
       BEGIN
         BLOCKREAD (FileName, DumpRec, SIZEOF (DumpRec) , n ) ;
         { ------------------- Read part of the 33 byte Header  }
         DataSize  := DumpRec.DataSize   ;           { BufferStart }
         DataStart := DumpRec.DataStart  ;           { BufferSize  }
         EpromDataTop^ [0] := DumpRec.LastByte     ;
       END ;

    IF Option = 0 THEN
       BEGIN
         CLRSCR ;
         WRITE (NL,NL,' Source (File) Start address is         : ',DataStart,
                   NL,' Change Target Start Address (Y)es (N)o : '        ) ;
         Choice := UPCASE (READKEY) ;
         WRITELN           ;
         IF Choice = 'Y' THEN
         BEGIN
           GetAddr ( BuffStartStr, Str1, BufferStart, BufferEnd, 2 ) ;
           BufferSize  := DataSize    ;
           DataStart   := BufferStart ;
         END ;

         BuffStartStr:= DecToHex  ( DataStart )   ;
         BufferEnd   := DataStart + DataSize      ;
         BuffEndStr  := DecToHex ( BufferEnd  )   ;
         BuffSizeStr := DecToHex ( DataSize )     ;

       END   ; { Option = 0 }

       IF Option = 2 THEN { Load BIN File }

       BEGIN
         FSize := FILESIZE ( FileName ) ;

         DataSize  := FSize-1 ;
         DataStart := 0       ;

         BufferEnd   := DataSize                  ;
         BufferStart := 0                         ;
         BufferSize  := DataSize                  ;
         BuffStartStr:= DecToHex  ( DataStart )   ;
         BuffEndStr  := DecToHex ( BufferEnd  )   ;
         BuffSizeStr := DecToHex ( DataSize )     ;

       END                 ;

  { ------------------- Read Data read from the file     }

    IF (Option=0) OR (Option=2) THEN
       BLOCKREAD (FileName, EpromData^[DataStart] , DataSize+1, BytesRead ) ;
    IF Option = 1 THEN
       BLOCKREAD (FileName, EpromData^[DataStart] , 3, BytesRead )          ;

  UNTIL BytesRead > 0 ;

  IF (Option=0) OR (Option=2) THEN
      BEGIN
        WRITE (' Data Size loaded : ',BytesRead,' bytes...');
        READLN ;
      END      ;

  CLOSE ( FileName ) ;

END ;
{----------------------------}
PROCEDURE FileList ;             { Directory List }

VAR
  n, p       : BYTE      ;
  TotalSize  : LONGINT   ;
  SearchFile : SEARCHREC ;
  FileStr    : Str20     ;
  FileName   : FILE      ;
  StartAddr  : WORD      ;
  SizeAddr   : WORD      ;
  Path       : PATHSTR   ;
  Dir        : DIRSTR    ;
  Name       : NAMESTR   ;
  Ext        : EXTSTR    ;

BEGIN
  n         := 1 ;
  p         := 0 ;
  TotalSize := 0 ;

  CLRSCR ;
  WRITE  (NL, ' Search pattern [Default *.DMP] : ' ) ;
  READLN (      FileStr ) ;
  IF FileStr = '' THEN FileStr := '*.DMP'            ;  { Default }

  WRITE
  (NL, ' Num Filename.Ext   Size    EpromID DmpSize  B0  B1  B3 '  ) ;
  {    ' ### NNNNNNNN.EEE.SSSSSS.NNNNNNNNNN...SSSSS.BBB.BBB.BBB '  }

  MakeWindow (940,7,6,White,Brown,1) ;   { Display a window }
  CLRSCR                              ;

  FINDFIRST ( FileStr, 0, SearchFile ) ;        { Find 1st File  }
  FSPLIT ( SearchFile.Name, Dir, Name, Ext ) ;  { Split PathName }


  WHILE DOSERROR = 0 DO
  BEGIN
    WRITE (n:4, ' ', Name:8, Ext:4, ' ', SearchFile.Size:6 ) ;
    TotalSize := TotalSize + SearchFile.Size ;

    IF Ext = '.DMP' THEN BEGIN
                           ASSIGN  (  FileName, SearchFile.Name )    ;
                           RESET   (  FileName, 1 )          ;
                           LoadFile ( FileName,
                                      StartAddr,
                                      SizeAddr, 1 ) ;
                           WRITE (' ',DumpRec.EpromName:10,'   ',
                                      DumpRec.DataSize:5,  ' ' ) ;
                           WRITE (EpromData^[DumpRec.DataStart]:3  ,' ',
                                  EpromData^[DumpRec.DataStart+1]:3,' ',
                                  EpromData^[DumpRec.DataStart+2]:3  ) ;
                         END                             ;
    WRITELN ;

    IF p = 16 THEN BEGIN
                     p := 0            ;
                     Choice := READKEY ;
                   END                 ;

    FINDNEXT ( SearchFile ) ;
    FSPLIT ( SearchFile.Name, Dir, Name, Ext )      ;  { Split PathName }
    INC (n)                                         ;
    INC (p)                                         ;
  END ;

  WRITE (' List Size   :  ', TotalSize:8, ' '           ) ;
  WRITE (' Disk Free : ',    DISKFREE(0):8, ' bytes..' ) ;
  READLN ;
  CLRSCR ;
END ;
{----------------------------}
{----------------------------}
PROCEDURE ConvertFile ;
VAR
  n           : INTEGER ;
  FileName    : FILE    ;

BEGIN
  MakeWindow (800,7,2,Brown,Cyan,1) ;   { Display a window }
  CLRSCR ;
  WRITE  (NL,' FILE FORMAT CONVERSION :           [*.EXT] ', NL,NL,

             ' [1]  Buffer -> INTEL               [*.INT] ', NL,
             ' [2]  Buffer -> ASCII HEX DUMP      [*.ASC] ', NL,
             ' [3]  Buffer -> Binary (Headerless) [*.BIN] ', NL,NL,

             ' [4]  *.INT  -> Buffer '  ,NL,
             ' [5]  *.ASC  -> Buffer '  ,NL,
             ' [6]  *.BIN  -> Buffer '  ,NL,NL,

             ' Select destination format : ' ) ;

      Choice := READKEY ;
      Choice := UPCASE (Choice) ;
      CASE Choice OF
                  '1' : BEGIN
                            ;
                        END ;
                  '2' : BEGIN
                            ;
                        END ;
                  '3' : BEGIN
                          OpenFiles ( FileName, 1 )                        ;
                          SaveFile (FileName, BufferStart, BufferSize, 1 ) ;
                            ;
                        END ;
                  '4' : BEGIN
                            ;
                        END ;
                  '5' : BEGIN
                            ;
                        END ;
                  '6' : BEGIN
                          OpenFiles ( FileName, 2 )                        ;
                          LoadFile (FileName, BufferStart, BufferSize, 2 ) ;
                             ;
                        END  ;
             'X', 'Q' : EXIT ;
      END                          ; { Case }

END ;

{-------------------------------------------}
PROCEDURE DoFile ;

VAR
    FileName                : FILE    ;
    n                       : WORD    ;

BEGIN

  MakeWindow (940,7,1,White,Brown,1) ;   { Display a window }

  REPEAT
    CLRSCR ;
    WRITELN (' FILE SERVICES ') ;
    WRITELN ;
    WRITELN (' Number of Stored Eprom Types is : ', EpromNum) ;
    WRITELN ;
    WRITE   (' (S)ave Read-Write Buffer ',    NL,
             ' (L)oad Read-Write Buffer '    ,NL,
             ' (C)onversion of File Format ', NL,
             ' (F)ile List  ',   NL,
             ' (D)elete File',   NL,
             ' (R)ename File',   NL,
             ' (Q)uit to Dos',   NL,
             ' (M)ain Menu  ',   NL,NL,
             ' Select Option :') ;
    Choice := READKEY ;
    Choice := UPCASE (Choice) ;
    CASE Choice OF
                'S' : BEGIN
                         OpenFiles ( FileName , 1 ) ;
                         SaveFile (FileName,
                                   BufferStart,
                                   BufferSize, 0   )     ;
                       END                               ;
                 'L' : BEGIN
                         OpenFiles ( FileName , 0 ) ;
                         LoadFile (FileName,
                                   BufferStart,
                                   BufferSize, 0 ) ;
                       END                          ;
                 'F' : BEGIN
                         FileList    ;
                       END           ;
                 'D' :            ;
                 'C' : ConvertFile ;
                 'R' :            ;
            'X', 'Q' : EXIT       ;
    END ; { Case }

  UNTIL Choice = 'M' ;

END ;
{------------------------}
{ Printer Routines       }
{------------------------}
PROCEDURE DoPrint ;

CONST
S2=' Buffer: Start       End       Size       Eprom :         ';
S3='----------------------------------------------------------';
S4=' Address OO-O1 O2-O3 O4-O5 O6-O7  O8-O9 OA-OB OC-OD OE-OF ';
S5='----------------------------------------------------------';
  {'...HHHH..BB.BB.BB.BB.BB.BB.BB.BB..BB.BB.BB.BB.BB.BB.BB.BB '}
  {'1234567890.........20........30........40........50.......'}
  {'...3.....10......................34.......................'}

VAR
  AddrStr , ByteStr : Str10   ;
  AddrNum , ByteNum : WORD    ;
  Row, Col          : INTEGER ;
  DumpEnd           : BOOLEAN ;
  Ch                : CHAR    ;

BEGIN
  WINDOW (9,6,37,17)            ;
  TEXTBACKGROUND (Cyan)         ;
  CLRSCR                        ;
  WRITE(' PRINT :                    ', NL  ) ;
  WRITE(' (Current Buffer Range)     ', NL  ) ;
  WRITE(' [H] Hex Dump               ', NL  ) ;
  WRITE(' [D] Decimal Dump           ', NL  ) ;
  WRITE(' Select Option :  ',           NL  ) ;
  Ch := UPCASE (READKEY)                      ;
  IF Ch='H' THEN
(*
  BEGIN

    DumpStart (DumpEnd,S1,S2,S3,S4,S5, 1) ;

    FOR Row := 0 TO 15*2 DO
    BEGIN
      IF (Row IN [8,16,24,32]) THEN WRITE (S7, NL)     ;
      AddrNum := DumpFirst + (Row)*16  ;
      AddrStr := DecToHex ( AddrNum )    ;
      WRITE ('   ', AddrStr:4, '  ' )    ;
      FOR Col := 0 TO 15 DO
      BEGIN
        IF ( AddrNum + Col > DumpLast ) THEN DumpEnd := TRUE ;
        ByteNum := EpromData^ [ AddrNum + Col ]               ;
        ByteStr := DecToHex ( ByteNum )                       ;
        DELETE (ByteStr, 1, 2)                                ;
        IF NOT DumpEnd THEN WRITE ( ByteStr:2 )
                       ELSE WRITE ( '..' )                    ;
        IF Col < 15 THEN WRITE (' ')                          ;
        IF Col = 7  THEN WRITE (' ')                          ;
      END ;
      WRITE ('   ')         ;
      WRITE (' ', NL)    ;

    END                  ;

    DumpStop (S8,S6,S9) ;
*)
;
END ;
{-----------------------}
{ Verify eprom + buffer }
{-----------------------}
PROCEDURE Verify (Option : INTEGER) ;

VAR
  n, i, k, m     : WORD       ;
  CheckSumBuffer ,
  CheckSumEprom  : LONGINT    ;
  ReadByte       : BYTE       ;
  X              : RECORD
                     AddrEprom  : ARRAY [0..7] OF WORD ;
                     ValEprom   : ARRAY [0..7] OF BYTE ;
                     AddrBuffer : ARRAY [0..7] OF WORD ;
                     ValBuffer  : ARRAY [0..7] OF BYTE ;
                   END      ;

BEGIN {1}
  SetupEpromForRead (EpromType) ;
  Reset4040                     ;
  IF (AddressStart>0) THEN Clock4040 (AddressStart) ;
  k := 0                   ; { Verify Errors } { Eprom Non-Blank  }
  m := 0                   ;                   { Buffer Non-Blank }
  CheckSumBuffer := 0      ;
  CheckSumEprom  := 0      ;
  n := BufferStart         ;
  {-------------------------------------}
  { Verify                              }
  {-------------------------------------}
  IF Option = 0 THEN
  BEGIN {2}
    TEXTCOLOR (Blue) ; GOTOXY (3,17) ; WRITE ('Bytes Compared : ') ;
    FOR i := AddressStart TO AddressEnd DO
    BEGIN {3}
      ReadByte := Read4021                  ;
      IF EpromData^[n] <> ReadByte THEN
      BEGIN {4}
        IF k<8 THEN
               BEGIN {5}
                 X.AddrEprom [k] := i             ;
                 X.AddrBuffer[k] := n             ;
                 X.ValEprom  [k] := ReadByte      ;
                 X.ValBuffer [k] := EpromData^[n] ;
               END {5}                                 ;
        INC (k)                                        ;
      END {4}                                          ;
      WRITE ( i:5, #8#8#8#8#8 )             ;
      Clock4040 (1)                         ;
      INC ( n )                             ;
    END {3}                                 ;

    GOTOXY (3,18) ; WRITE ('Verify Errors  : ', k:5 ,NL ) ;
    IF k>0 THEN
    BEGIN {6}
      WINDOW (9,6,37,17)            ;
      TEXTBACKGROUND (Cyan)         ;
      CLRSCR                        ;
      WRITE('     ³  BUFFER  ³  EPROM    ', NL  ) ;
      WRITE('     ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ', NL  ) ;
      WRITE(' NUM ³ Addr Val ³ Addr Val  ', NL  ) ;
      WRITE('ÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ'    ) ;
           {'  NN.³AAAAA.BBB.³AAAAA.BBB' }
      IF k > 7 THEN k := 7 ;
      FOR i := 0 TO k-1 DO
      BEGIN {7}
        WRITE (NL, '  ',i:2, ' ³' ,X.AddrBuffer[i]:5,
                             ' '  ,X.ValBuffer[i]:3 ,
                             ' ³' ,X.AddrEprom[i]:5 ,
                             ' '  ,X.ValEprom[i]:3    ) ;
      END {7}   ;
    END {6}     ;
    WRITE (' ') ;
  END {2}       ;
  {-------------------------------------}
  { CheckBlank                          }
  {-------------------------------------}
  IF (Option = 1) OR (Option = 2) THEN
  BEGIN {2}
    FOR i := AddressStart TO AddressEnd DO
    BEGIN {3}
      ReadByte := Read4021                        ;
      CheckSumEprom := CheckSumEprom + ReadByte   ;
      IF ReadByte <> $FF THEN
      BEGIN {4}
        IF k<8 THEN
               BEGIN {5}
                 X.AddrEprom [k] := i             ;
                 X.ValEprom  [k] := ReadByte      ;
               END  {5}                                ;
        INC (k)                                 ;
      END  {4}                                  ;
      WRITE ( i:5, #8#8#8#8#8 )             ;
      Clock4040 (1)                         ;
    END  {3}                                ;

    FOR i := BufferStart TO BufferEnd DO
    BEGIN {6}
      CheckSumBuffer := CheckSumBuffer + EpromData^[i]  ;
      IF EpromData^[i] <> $FF THEN
      BEGIN {7}
        IF m<8 THEN
               BEGIN {8}
                 X.AddrBuffer [m] := i                  ;
                 X.ValBuffer  [m] := EpromData^[i]      ;
               END  {8}                                 ;
        INC (m)                                 ;
      END  {7}                                  ;
      WRITE ( i:5, #8#8#8#8#8 )             ;
      Clock4040 (1)                         ;
    END  {6}                                ;

    TEXTCOLOR (Blue) ; GOTOXY (3,17) ;
    IF Option = 2 THEN
    BEGIN
      WRITE ( 'Eprom CheckSum  : ', CheckSumEprom:7      ) ; GOTOXY (3,18) ;
      WRITE ( 'Buffer CheckSum : ', CheckSumBuffer:7, ' ') ;
    END ;
    IF Option = 1 THEN
    BEGIN
      WRITE ( 'Eprom  non-FF bytes:', k:5      ) ; GOTOXY (3,18) ;
      WRITE ( 'Buffer non-FF bytes:', m:5 ,' ' ) ;
    END ;
    IF ( (k + m) > 0 ) AND (Option = 1) THEN
    BEGIN {9}
      WINDOW (9,6,37,17)            ;
      TEXTBACKGROUND (Cyan)         ;
      CLRSCR                        ;
      WRITE('     ³  BUFFER  ³  EPROM    ', NL  ) ;
      WRITE('     ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ', NL  ) ;
      WRITE(' NUM ³ Addr Val ³ Addr Val  ', NL  ) ;
      WRITE('ÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄ'    ) ;
           {'  NN.³AAAAA.BBB.³AAAAA.BBB' }
      IF m > 7 THEN m := 7 ;
      FOR i := 0 TO m-1 DO
      BEGIN {10}
        WRITE (NL, '  ',i:2, ' ³' ,X.AddrBuffer[i]:5,
                             ' '  ,X.ValBuffer[i]:3, ' ³') ;
      END   {10}                                             ;

      IF k > 7 THEN k := 7 ;
      FOR i := 0 TO k-1 DO
      BEGIN {11}
        GOTOXY (18,5+i)                                                 ;
        WRITE ( X.AddrEprom[i]:5 , ' '  ,X.ValEprom[i]:3    ) ;
      END   {11}                                                        ;
    END  {9}                ;
  END   {2}                 ;
  READLN                    ;

END {1}                     ;
{------------------------}
{ Search                 }
{------------------------}
PROCEDURE Search ;

VAR
  AStr       : Str10   ;
  n,Col,k,i  : WORD    ;
  Ch         : CHAR    ;
  Sequence   : ARRAY [0..8] OF BYTE ;
  Found      : BOOLEAN              ;

BEGIN
      WINDOW (9,6,37,17)            ;
      TEXTBACKGROUND (Cyan)         ;
      CLRSCR                        ;
      WRITE(' Enter hex search sequence: ', NL  ) ;
      WRITE(' [Enter: end] [Esc: quit]   ', NL  ) ;
      WRITE('ÚÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄÂÄÄ¿   ', NL  ) ;
      WRITE('³  ³  ³  ³  ³  ³  ³  ³  ³   ', NL  ) ;
      WRITE('ÀÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÁÄÄÙ   ', NL  ) ;
      WRITE(' 00 01 02 03 04 05 06 07    ', NL  ) ;
      WRITE('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿   ', NL  ) ;
      WRITE('³                       ³   ', NL  ) ;
      WRITE('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ   ', NL  ) ;
      Col := 2           ;
      n := 1             ;
      AStr[0] := CHR (2) ;
      GOTOXY (2,4)       ;
      TEXTCOLOR (White)  ; TEXTBACKGROUND (Red) ;
      REPEAT
        Ch := UPCASE (READKEY) ;
        IF Ch = #27 THEN EXIT  ;
        IF (Ch IN ['0'..'9','A'..'F']) THEN
        BEGIN
          WRITE (Ch)             ;
          AStr[1] := Ch          ;
          Ch := UPCASE (READKEY) ;
          IF Ch = #27 THEN EXIT  ;              { ESC Exit }
          IF (Ch IN ['0'..'9','A'..'F'] ) THEN
          BEGIN
            WRITE (Ch)     ;
            AStr[2] := Ch  ;
            Col := Col+3   ;
            Sequence[n] := HexToDec (AStr) ;
            GOTOXY (Col-3, 8)              ;
            WRITE (CHR (Sequence[n]) )     ;
            n := n + 1                     ;
            GOTOXY (Col,4) ;
          END                              ;
        END                                ;

      UNTIL (Ch=#13) OR (n=9)     ;
      Sequence [0] := n-1                  ;  { Length of sequence }

      n := 0                   ;
      k := 1                   ;
      Found := FALSE           ;
      TEXTCOLOR (Black) ; TEXTBACKGROUND (Cyan) ;
      GOTOXY (1, 9) ;

      FOR i := BufferStart TO BufferEnd DO
      BEGIN
          IF EpromData^[i] = Sequence [1] THEN
          BEGIN
              Found := TRUE ;
              WHILE (k < Sequence [0]) AND (Found=TRUE) DO
              BEGIN
                  IF EpromData^[i+k] = Sequence [k+1] THEN k := k+1
                     ELSE Found := FALSE ;
              END ;
              IF Found THEN BEGIN
                              AStr := DecToHex (i) ;
                              WRITE (NL,
                              'Found at : ', i:5, ' (',AStr:4,' hex)' ) ;
                            END ;
          END    ;
          k := 1 ;
      END      ;

      IF NOT Found THEN WRITE (NL, 'Sequence not Found...') ;

      Ch := READKEY ;

END ;
{------------------------}
{ Miscellaneous Services }
{------------------------}
PROCEDURE Miscellaneous ;

CONST
  S1  = 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿' ; { Length }
  S2  = '³ E p r o m   P r o g r a m m e r   :   U T I L I T I E S  ³' ;
  S3  = 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
  S4  = '³ 1 : Change Eprom-addr.Range ³  S T A T U S               ³' ;
  S5  = '³ 2 : Change Buffer Range     ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
  S6  = '³ 3 : Verify : Eprom - Buffer ³ Eprom  Number:             ³' ;
  S7  = '³ 4 : Check Blank (FF) Block  ³ Record Number:             ³' ;
  S8  = '³ 5 : Run Checksum            ³ Total  Size  :       bytes ³' ;
  S9  = '³ 6 : Search (Byte Sequence)  ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
  S10 = '³ 7 : Communications Test     ³ Current Eprom Address :    ³' ;
  S11 = '³ X : Exit to Dos             ³ Start :                    ³' ;
  S12 = '³ M : Return to Main Menu     ³ End   :                    ³' ;
  S13 = '³ H : Help                    ³ Size  :              bytes ³' ;
  S14 = '³                             ³ Current Buffer Address  :  ³' ;
  S15 = '³ (Current Buffer+Range used. ³ Start :                    ³' ;
  S16 = 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ End   :                    ³' ;
  S17 = '³                             ³ Size  :              bytes ³' ;
  S18 = '³                             ³         Decimal Hex        ³' ;
  S19 = 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ' ; { = 42   }
  LF  = #10#8 ; { LF + BS }

VAR
  n, i, k, m     : WORD       ;
  Answer, Util   : CHAR       ;
  ErrorNum       : INTEGER    ;
  SequenceStr    : Str80      ;
  ValStr         : Str10      ;
  ReadByte       : BYTE       ;

  CheckSeqBuffer : ARRAY [0..16] OF WORD ;
  CheckSeqEprom  : ARRAY [0..16] OF WORD ;
  SequenceBytes  : ARRAY [0..16] OF BYTE ;

BEGIN

   TEXTBACKGROUND ( Blue ) ;
   WINDOW (1,1,80,25)      ;
   CLRSCR                  ;

   REPEAT

     MakeWindow (1080,8,3,Yellow,Brown,1) ;   { Display a window }

     WRITE
     ( S1 ,NL,S2 ,NL,S3 ,NL,S4 ,NL,S5 ,NL,S6 ,NL,S7 ,NL,S8 ,NL,S9 ,NL,S10,NL,
       S11,NL,S12,NL,S13,NL,S14,NL,S15,NL,S16,NL,S17,NL,S18,NL,S19 ) ;

     GOTOXY (48,6) ; TEXTCOLOR (Black) ;
     IF EpromType > 0 THEN WITH Eproms[EpromType] DO
        BEGIN
          WRITE ( IdData.Number)                ; GOTOXY (48,7 ) ;
          WRITE ( EpromType )                   ; GOTOXY (48,8 ) ;
          WRITE ( Size.Total   )                ;

          GOTOXY (41,11) ; WRITE ( AddressStart )      ;
          GOTOXY (49,11) ; WRITE ( AddrStartStr )      ;
          GOTOXY (41,12) ; WRITE ( AddressEnd )        ;
          GOTOXY (49,12) ; WRITE ( AddrEndStr )        ;
          GOTOXY (41,13) ; WRITE ( AddressSize )       ;
          GOTOXY (49,13) ; WRITE ( AddrSizeStr )       ;

          GOTOXY (41,15) ; WRITE ( BufferStart )       ;
          GOTOXY (49,15) ; WRITE ( BuffStartStr )      ;
          GOTOXY (41,16) ; WRITE ( BufferEnd )         ;
          GOTOXY (49,16) ; WRITE ( BuffEndStr )        ;
          GOTOXY (41,17) ; WRITE ( BufferSize )        ;
          GOTOXY (49,17) ; WRITE ( BuffSizeStr )       ;
        END                                            ;
     IF EpromType = 0 THEN WRITE ( 'Unknown' )         ;

   GOTOXY (3,4) ; TEXTCOLOR (White) ;
   WRITE ( '1',LF,'2',LF,'3',LF,'4',LF,'5',LF,'6',LF,'7',LF,'X',LF,
           'M',LF,'H') ;
   GOTOXY (3,17) ; WRITE ('Enter Choice : ' ) ;

   TEXTCOLOR (Black) ;

    Util := UPCASE ( READKEY ) ;

    CASE Util OF
        '1' : BEGIN
                    GOTOXY (3,17) ; WRITE
                    ('Eprom [START END] addresses:')  ;
                    GOTOXY (3,18)                             ;
                    GetAddr (AddrStartStr, AddrEndStr,
                             AddressStart, AddressEnd, 5 )    ;
                    AddressSize := AddressEnd - AddressStart  ;
                    AddrSizeStr := DecToHex (AddressSize)     ;
              END ;
        '2' : BEGIN
                    GOTOXY (3,17) ; WRITE
                    ('Buffer [START END] addresses:') ;
                    GOTOXY (3,18)                             ;
                    GetAddr (BuffStartStr, BuffEndStr,
                             BufferStart, BufferEnd, 5 )  ;
                    BufferSize := BufferEnd - BufferStart ;
                    BuffSizeStr := DecToHex (BufferSize)  ;
              END ;
        '3' : Verify (0) ;

        '4' : Verify (1) ;

        '5' : Verify (2) ;

        'X' : EXIT       ;

        '7' : InitialisePort (EpromType) ;

        '6' : Search ;
        END ;

  UNTIL Util = 'M' ;

END ;  { Miscellaneous }
{-----------------------------------}
{ Main Menu                         }
{-----------------------------------}
PROCEDURE MainMenu                  ;

CONST
  S1  = 'ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿' ; { Length }
  S2  = '³ E P R O M  P R O G R A M M E R   :   M a i n  M e n u    ³' ;
  S3  = 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
  S4  = '³ R : Read-Dump Eprom         ³  S T A T U S               ³' ;
  S5  = '³ W : Write-Program Eprom     ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
  S6  = '³ S : Select Eprom            ³ Eprom  Number:             ³' ;
  S7  = '³ I : Eprom Information       ³ Record Number:             ³' ;
  S8  = '³ C : Configuration           ³ Total  Size  :       bytes ³' ;
  S9  = '³ F : File Services           ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
  S10 = '³ E : Editor : Buffer         ³ Current Eprom Address :    ³' ;
  S11 = '³ H : Help                    ³ Start :                    ³' ;
  S12 = '³ Z : Resocket Eprom          ³ End   :                    ³' ;
  S13 = '³ P : Print Buffer            ³ Size  :              bytes ³' ;
  S14 = '³ M : Miscellaneous Services  ³ Current Buffer Address  :  ³' ;
  S15 = '³ X : Exit to Dos             ³ Start :                    ³' ;
  S16 = 'ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ End   :                    ³' ;
  S17 = '³                             ³ Size  :              bytes ³' ;
  S18 = '³                             ³         Decimal Hex        ³' ;
  S19 = 'ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ' ; { = 42   }
  LF  = #10#8 ; { LF + BS }

VAR
  Aword : WORD    ;

BEGIN

 REPEAT

   TEXTBACKGROUND ( Blue ) ;
   WINDOW (1,1,80,25)      ;
   CLRSCR                  ;

   MakeWindow (1080,8,3,Yellow,Brown,1) ;   { Display a window }

   WRITE
   ( S1 ,NL,S2 ,NL,S3 ,NL,S4 ,NL,S5 ,NL,S6 ,NL,S7 ,NL,S8 ,NL,S9 ,NL,S10,NL,
     S11,NL,S12,NL,S13,NL,S14,NL,S15,NL,S16,NL,S17,NL,S18,NL,S19 ) ;

   GOTOXY (48,6) ; TEXTCOLOR (Black) ;
   IF EpromType > 0 THEN WITH Eproms[EpromType] DO
      BEGIN
        WRITE ( IdData.Number)                ; GOTOXY (48,7 ) ;
        WRITE ( EpromType )                   ; GOTOXY (48,8 ) ;
        WRITE ( Size.Total   )                ;

        GOTOXY (41,11)  ; WRITE ( AddressStart )      ;
        GOTOXY (49,11)  ; WRITE ( AddrStartStr )      ;
        GOTOXY (41,12)  ; WRITE ( AddressEnd )        ;
        GOTOXY (49,12)  ; WRITE ( AddrEndStr )        ;
        GOTOXY (41,13)  ; WRITE ( AddressSize )       ;
        GOTOXY (49,13)  ; WRITE ( AddrSizeStr )       ;

        GOTOXY (41,15)  ; WRITE ( BufferStart )       ;
        GOTOXY (49,15)  ; WRITE ( BuffStartStr )      ;
        GOTOXY (41,16)  ; WRITE ( BufferEnd )         ;
        GOTOXY (49,16)  ; WRITE ( BuffEndStr )        ;
        GOTOXY (41,17)  ; WRITE ( BufferSize )        ;
        GOTOXY (49,17)  ; WRITE ( BuffSizeStr )       ;
      END                                             ;
   IF EpromType = 0 THEN WRITE ( 'Unknown' )          ;


   GOTOXY (3,4) ; TEXTCOLOR (White) ;
   WRITE ( 'R',LF,'W',LF,'S',LF,'I',LF,'C',LF,'F',LF,'E',LF,'H',LF,
           'Z',LF,'P',LF,'M',LF,'X',LF,LF,' Enter Choice : ' ) ;

   TEXTCOLOR (Black) ;

    Choice := UPCASE (READKEY)    ;
    CASE Choice OF
                 'S' : BEGIN        { Select Eprom Type 1 - 12 }
                         ListRecords (1)                              ;
                         IF SwitchSetting(0) THEN
                             SetupEpromForRead (EpromType)            ;
                       END                                            ;
                 'H' : BEGIN                  { Help                  }
                         DoHelp                                       ;
                       END                                            ;

                 'R' : BEGIN        { Read-Dump EPROM Contents }

                         ReadEprom (EpromType)                 ;
                       END                                     ;
                 'W' : BEGIN        { Program EPROM Contents   }
                         WriteEprom (EpromType)                ;
                       END                                     ;
                 'I' : BEGIN        { Eprom Information        }
                         DoEpromData                           ;
                       END                                     ;
                 'X' : BEGIN        { Exit to DOS              }
                         DISPOSE (EpromData)                   ;
                         DISPOSE (EpromDataTop)                ;
                         Exit                                  ;
                       END                                     ;
                 'E' : BEGIN        { Editor                   }
                         Edit                                  ;
                       END                                     ;
                 'F' : BEGIN        { File Services            }
                         DoFile                                ;
                       END                                     ;
                 'Z' : BEGIN        { Replace Eprom in Socket  }
                         ReplaceEprom                          ;
                       END                                     ;
                 'P' : BEGIN        { Replace Eprom in Socket  }
                         DoPrint                               ;
                       END                                     ;
                 'M' : BEGIN        { Replace Eprom in Socket  }
                         Miscellaneous                         ;
                       END                                     ;
                 ELSE  BEGIN        { Invalid Choice           }
                         WRITELN ('Invalid')                   ;
                         DELAY (500)                           ;
                       END                                     ;
     END                                                       ;

  UNTIL Choice = 'Q'                                           ;

END ;

{-------------------------------}
{ Memory Detection              }
{-------------------------------}
FUNCTION FindMem ( MemPtr : DummyPtr ; TypeStr : str20 ) : REAL ;

VAR
  R1,R2,R3 : REAL ;

BEGIN
  R1 := SEG (MemPtr^) ;
  R1 := R1*16         ;
  R2 := OFS (MemPtr^) ;
  R3 := R1+R2         ;
  FindMem := R3       ;

  WRITELN ( TypeStr, R3:6:0 ) ;

END ;

{-----------------}
{ MAIN            }
{-----------------}

BEGIN

  ReadWrite     := 2   ;  { Change Flag = 2,1,0 }
  EpromType     := 0   ;
  Choice        := ' ' ;
  EpromInfoRead := 0   ;
  AddressStart  := 0   ;
  AddressEnd    := 0   ;
  AddressSize   := 0   ;
  BufferStart   := 0   ;
  BufferEnd     := 0   ;
  BufferSize    := 0   ;
  BuffStartStr  := ' ' ;
  BuffEndStr    := ' ' ;
  BuffSizeStr   := ' ' ;
  AddrStartStr  := ' ' ;
  AddrEndStr    := ' ' ;
  AddrSizeStr   := ' ' ;
  DumpOption    := 4   ; { Default }
  Eproms[0].IdData.Number := '**** ' ;
  Eproms[0].Size.Total    := $FFFE   ;
  {------------------------------}
  { Allocate Heap Usage          }
  {------------------------------}
  CLRSCR ;

  NEW (EpromData)    ; { Allocate space for 0-65534 Array }
  NEW (EpromDataTop) ; { Allocate space for last (top) byte }

  MakeWindow (500,15,2,Black,LightGray,1) ;   { Display a window }
  CLRSCR ;
  {---------------------------------------------------------}
  FreeEnd   := FindMem (FreeList, '  Free Memory End   : ' ) ;
  HeapEnd   := FindMem (HeapPtr , '  Heap Memory End   : ' ) ;
  HeapStart := FindMem (HeapOrg , '  Heap Memory Start : ' ) ;


  WRITELN (NL,'  Available Memory : ', (FreeEnd-HeapEnd):6:0,  ' bytes. ' );
  WRITE   (   '  Heap Memory used : ', (HeapEnd-HeapStart):6:0,' bytes...');

  Choice := READKEY  ;
  {--------------------------}

  ZeroRecords ;

  Data.PPort    := [] ;                   { Empty set D0-D7 = clear    }
  Control.PPort := [] ;                   { Same if Data.Number := 0   }
  Data.PPort    := Data.PPort - [D4]    ; { D4=0 READ State }
  PORT [Base]   := Data.Number          ;
  Control.PPort := Control.PPort + [D0] ; { D0=0 PGM ON                }
  Control.PPort := Control.PPort + [D2] ; { D2=1 MSG OFF               }
  PORT [Base+2] := Control.Number       ;

  MainMenu                              ;

END.

