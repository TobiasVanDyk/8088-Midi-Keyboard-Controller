UNIT Eprom1 ;

INTERFACE

USES DOS, CRT ;

{-------------------------------------------}
{ Unit Eprom1.PAS Eprom1.TPU                }
{-------------------------------------------}
TYPE
     ArrPtr      = ^HeapArr                       ; { Array on Heap }
     HeapArr     = ARRAY [0..65534] OF BYTE       ; { Hex FFFE Size }
     TopPtr      = ^TopArr                        ; { Last Byte in here }
     TopArr      = ARRAY [0..15] OF BYTE          ; { TopArr[0] = FFFF  }
     Arr    = ARRAY [0..7] OF BYTE               ;
     Str10 = STRING [10] ;
     Str20 = STRING [20] ;
     Bit    = ( D0, D1, D2, D3, D4, D5, D6, D7 ) ;
     BitSet = SET OF Bit                         ;
     Str80 = STRING [80] ;
     FileType = (Sys, Active) ;

CONST
    Power2 : Arr = (1,2,4,8,16,32,64,128) ; { Convert Bits 0-7 to a value }
    MaxEprom = 12 ;
    FileName = 'EPROM.DAT' ;
    HexDigit : ARRAY [0..15] OF CHAR = '0123456789ABCDEF'; { Hex Digits   }
    LPT0   = $03BC                        ; { Printer Port 0  }
    LPT1   = $0378                        ; { Printer Port 1  }
    LPT2   = $0278                        ; { Printer Port 2  }
    Base   : INTEGER = $0278              ; { Default is LPT2 }
    ErrorFlag : INTEGER = 0               ; { General purpose }
    NL       = #13#10      ;

TYPE
     {--------------------------------------}
     { Eprom Descriptive Data               }
     {--------------------------------------}
     IdDataType  =
     RECORD
       Number       : str10                 ;  { Eprom Number : 2716,2764A }
       Equivalent   : ARRAY [1..5] OF str10 ;  { Any equivalents           }
       Manufacturer : str20                 ;  { Original Manufacturer     }
       Date         : str10                 ;  { Date released             }
       Subtype      : ARRAY [1..5] OF str10 ;  { Subtypes : 2764A, 2716-35 }
       Description  : str80                 ;  { Short description         }
     END                                    ;
     {--------------------------------------}
     { Eprom Size Data                      }
     {--------------------------------------}
     SizeType =
     RECORD
       Total        : LONGINT               ;  { Total Size in bytes }
       Pages        : BYTE                  ;  { 0=flat 1-16 Paged   }
       PageSize     : LONGINT               ;  { Size of each page   }
     END                                    ;
     {--------------------------------------}
     { Eprom Pinout Data                    }
     {--------------------------------------}
     PinsType =
     RECORD
       Total        : BYTE                  ;  { Total number : 24,28,32,40 }
       Name         : ARRAY [1..32] OF str10;  { Name[24] = Vcc for 2716    }
     END                                    ;
     {--------------------------------------}
     { Eprom Programming Data               }
     {--------------------------------------}
     ProgType =
     RECORD
       Voltage      : REAL                  ;
       Pulse        : RECORD
                        Duration : Byte     ;
                        Direction: Byte     ;   { 101 H->L->H 010 L->H->L }
                      END                   ;
       { PinLevel [18] = 101 : Pulse H -> L -> H during program    }
       { PinLevel [18] = 010 : Pulse L -> H -> L during Program    }
       { PinLevel [18] = 5 : Pin 18 = Dxx (Data)    during Program }
       { PinLevel [18] = 4 : Pin 18 = Axx (Address) during Program }
       { PinLevel [18] = 3 : Pin 18 = Vpp during Program           }
       { PinLevel [18] = 2 : Pin 18 = Vcc during Program           }
       { PinLevel [18] = 1 : Pin 18 = V+  during Program           }
       { PinLevel [18] = 0 : Pin 18 = GND during Program           }
       PinLevel     : ARRAY [1..32] OF BYTE ;
       { 11011 : Pulse H -> L -> H during program    }
       { 00100 : Pulse L -> H -> L during Program    }
       Seq          : ARRAY [1..5] OF Byte  ;
     END                                    ;
     {--------------------------------------}
     { Eprom Read Data                      }
     {--------------------------------------}
     VerifyType =
     RECORD
       { PinLevel [18] = 1 : Pin 18 = V+  during Read }
       { PinLevel [18] = 0 : Pin 18 = GND during Read }
       PinLevel     : ARRAY [1..32] OF BYTE ;
       { 18,20,21 : Set up Pin18,then Pin20, then Pin21 }
       Seq          : ARRAY [1..5] OF BYTE  ;
     END                                    ;
     {--------------------------------------}
     { Eprom Switches Data                  }
     {--------------------------------------}
     SwitchesType =
     RECORD
           Name     : ARRAY [1..7] OF Str10 ;
           Code     : ARRAY [1..7] OF CHAR  ;
           Position : ARRAY [1..7] OF CHAR  ;
           Connect  : ARRAY [1..7] OF Str10 ;
     END                                    ;
     {--------------------------------------}
     { Main Eprom Data (File) Record        }
     {--------------------------------------}
     EpromRecord = RECORD
                   CASE RecKind : FileType OF
                        Sys     : ( NumEproms : INTEGER )    ;
                        Active  : ( IdData    : IdDataType   ;
                                    Size      : SizeType     ;
                                    Pins      : PinsType     ;
                                    Prog      : ProgType     ;
                                    Verify    : VerifyType   ;
                                    Switches  : SwitchesType );
                   END ;
VAR
     {----------------------------------------------------------------------}
     { Printer Ports : Union-overlay of SET and BYTE                        }
     {----------------------------------------------------------------------}
     {------------------------}      {--------------------------------------}
     { DataPort = Base        }      {OUTPUT PORT                           }
     {------------------------}      {Bit Name Num Colour   Line            }
     Data   :                        {D0 Data0  2  black    4040 addr clock }
     RECORD                          {D1 Data1  3  brown    4040 reset (H)  }
       Addr              : INTEGER ; {D2 Data2  4  white    4094 ser data-in}
       CASE BOOLEAN OF               {D3 Data3  5  gray     4094 clock      }
         TRUE  : (Number : Byte  ) ; {D4 Data4  6  pink     4094 enable (H) }
         FALSE : (PPort  : BitSet) ; {D5 Data5  7  seagreen 4021 ser clock  }
       END                         ; {D6 Data6  8  blue     4021 par-serial }
                                     {D7 Data7  9  orange   CNY17 Vpp ON (H)}
     {------------------------}      {--------------------------------------}
     { ControlPort = Base + 2 }      {OUTPUT PORT                           }
     {------------------------}      {Bit Name      Num Colour Line         }
     Control:                        {D0 Strobe      1* purple Eprom PGM    }
     RECORD                          {D1 Autofeed   14  --                  }
       Addr              : INTEGER ; {D2 Initialise 16* yellow Message LED  }
       CASE BOOLEAN OF               {D3 Select Inp 17  --                  }
         TRUE  : (Number : Byte  ) ; {D4 IRQ7enable --  --                  }
         FALSE : (PPort  : BitSet) ; {D5 --           * Strobe is inverted  }
       END                         ; {D6 --             Initialise is normal}
                                     {D7 --                                 }
     {------------------------}      {--------------------------------------}
     { StatusPort = Base + 1  }      {INPUT PORT                            }
     {------------------------}      {Bit Name    Num Colour Line           }
     Status :                        {D0 --                                 }
     RECORD                          {D1 --         * All inputs inverted   }
       Addr              : INTEGER ; {D2 --                                 }
       CASE BOOLEAN OF               {D3 Error     15 green  Eprom Pin18    }
         TRUE  : (Number : Byte  ) ; {D4 Selected  13 --                    }
         FALSE : (PPort  : BitSet) ; {D5 Paper Out 12 --                    }
       END                         ; {D6 ACK       10 --                    }
                                     {D7 BUSY      11 red    4021 Serial Out}
                                     {--------------------------------------}
     AddressSize    : WORD    ;  { Current size of Eprom Data      }
     AddressStart   : WORD    ;  { Current pointer to Eprom Start  }
     AddressEnd     : WORD    ;  { Current pointer to Eprom End    }

     BufferSize     : WORD    ;  { Current filled size of Buffer   }
     BufferStart    : WORD    ;  { Current Start of Buffer Pointer }
     BufferEnd      : WORD    ;  { Current End of Buffer Pointer   }

     BuffSizeStr    : Str10   ;  { Current filled size of Buffer   }
     BuffStartStr   : Str10   ;  { Current Start of Buffer Pointer }
     BuffEndStr     : Str10   ;  { Current End of Buffer Pointer   }

     EpromData      : ArrPtr  ;  { Points to 64k-1 byte array      }
     EpromDataTop   : TopPtr  ;  { Points to 16 byte array         }
     Eproms         : ARRAY [0..MaxEprom] OF EpromRecord        ;
     EpromNum       : 0..MaxEprom ;  { Range of Record Numbers  }
     Choice         : CHAR        ;  { generic char-buffer      }
     EpromType      : INTEGER     ;  { = EpromRec Number 1-12   }
     EpromInfoRead  : INTEGER     ;  { 1 if records read once   }
     ReadWrite      : INTEGER     ;  { Change Flag : Select, Read, Write }
                                     {             = 2 Do Read and Write }
                                     {             = 1 Do Write not Read }
                                     {             = 0 Do Read not Write }

PROCEDURE MakeWindow (Size,X,Y,Front,Back,Style : INTEGER) ;
PROCEDURE DisplayEpromData (StartAddr,EndAddr : WORD; DumpOption :INTEGER);
PROCEDURE ZeroRecords ;
PROCEDURE WriteEproms ;
PROCEDURE ReadEproms  ;
PROCEDURE AddRecords ( EditAdd : INTEGER )    ;
FUNCTION  CheckSelect : BOOLEAN               ;
PROCEDURE CheckRead                           ;
PROCEDURE ListRecords (Option : INTEGER)      ;
PROCEDURE DoEpromData                         ;
PROCEDURE ShowPins ;
PROCEDURE InitialisePort (EpromType : INTEGER)          ;
PROCEDURE SetVpp ( OnOff : BYTE )                       ;
PROCEDURE SendPulse ( Width : BYTE ; Direction : BYTE ) ;
PROCEDURE Write4094 (WriteByte : BYTE)                  ;
FUNCTION  Read4021 : BYTE                               ;
PROCEDURE Reset4040                                     ;
PROCEDURE Clock4040 (StartAddr : WORD)                  ;
FUNCTION  HexToDec (HexStr : str10) : WORD      ;
FUNCTION  DecToHex (VAR Number : WORD ) : str10 ;
PROCEDURE ReplaceEprom         ;
FUNCTION  SwitchSetting (Option: INTEGER) : BOOLEAN ;
PROCEDURE SetupEpromForRead  (EpromType : INTEGER)  ;
PROCEDURE SetupEpromForWrite (EpromType : INTEGER; Direction : BYTE) ;
PROCEDURE DumpStart (VAR DumpEnd: BOOLEAN;
                         S1,S2,S3,S4,S5 : STRING; Option : INTEGER ) ;

IMPLEMENTATION

{----------------------------------------------------------}
{ Display a Window                                         }
{ Input : Size   = Height * Width ( always in a 1:3 Ratio) }
{                  Size between 12 (2*6) to 1200 (20*60)   }
{         X,Y    = X and Y position of Top Left Corner     }
{         Front  = Foreground Color ( 0 - 15 )             }
{         Back   = Background Color ( 0 - 7 )              }
{         Style  = 0 No Shadow  1 Black  8 Gray Shadow     }
{-------------------------------------------------------------------------}
{ Colors :                                                                }
{ 0  black       1  blue      2 green       3  cyan          4 red        }
{ 5  magenta     6  brown     7  lightgray  8  darkgray      9 lightblue  }
{ 10 lightgreen  11 lightcyan 12 lightred   13 lightmagenta 14 yellow     }
{ 15 white       16 blink                                                 }
{-------------------------------------------------------------------------}
PROCEDURE MakeWindow (Size,X,Y,Front,Back,Style : INTEGER) ;

VAR
    Top,Bottom,Left,Right : INTEGER ;
    XX, YY                : INTEGER ;

BEGIN
YY     := Size DIV 3          ; { Horizontal length }
YY     := TRUNC (SQRT(YY))    ;
XX     := Size DIV YY         ; { Vertical Height   }
Top    := Y                   ;
Left   := X                   ;
Bottom := Y + YY              ;
Right  := X + XX              ;

{------------------------------------}
{ Make shadow window                 }
{------------------------------------}
IF (Style>0) THEN BEGIN
                TEXTBACKGROUND ( Style-1 )  ; { 1-1=0 Black 8-1=7 Gray }
                WINDOW ( Left+2, Top+1, Right+2, Bottom+1 ) ;
                CLRSCR                                      ;
              END                                           ;
{------------------------------------}
{ Make window                        }
{------------------------------------}
TEXTCOLOR   ( Front )  ;
TEXTBACKGROUND ( Back )   ;
WINDOW ( Left, Top, Right, Bottom ) ;
CLRSCR                              ;
GOTOXY (1,1)                        ;

END ;
{------------------}
{ End Dumps        }
{------------------}
PROCEDURE DumpStop (S8,S6,S9 : STRING ) ;

BEGIN
    WRITE (S8,NL)        ;
    WRITE (S6,NL)        ;
    WRITE (S9   )        ;

    GOTOXY (2, 24) ; TEXTCOLOR (White) ;
    WRITE  ('Page',#$18#$19,' EndHome Arrow',#$18#$19,
            ' Edit-Enter Exit-ESC BlankFF-SPC ')     ;
END ;
{--------------------}
{ Start Dumps        }
{--------------------}
PROCEDURE DumpStart (VAR DumpEnd: BOOLEAN;
                         S1,S2,S3,S4,S5 : STRING; Option : INTEGER ) ;
BEGIN
    DumpEnd := FALSE ;
    CLRSCR  ;

    TEXTCOLOR (Yellow) ;
    WRITE (S1, NL, S2, NL, S3, NL, S4, NL, S5 ) ;

    TEXTCOLOR (White)  ;

    GOTOXY (16, 2) ;
    IF Option = 3 THEN WRITE (BufferStart) ELSE WRITE (BuffStartStr) ;
    GOTOXY (26, 2) ;
    IF Option = 3 THEN WRITE (BufferEnd  ) ELSE WRITE (BuffEndStr) ;
    GOTOXY (37, 2) ;
    IF Option = 3 THEN WRITE (BufferSize ) ELSE WRITE (BuffSizeStr)  ;
    GOTOXY (51, 2) ; WRITE (Eproms [EpromType].IdData.Number)  ;

    GOTOXY ( 1, 6 )    ;
    TEXTCOLOR (Yellow) ;
END ;
{------------------------------------------------}
{ 16x16 = 256 byte decimal dump                  }
{------------------------------------------------}
PROCEDURE DecDump ( DumpFirst, DumpLast : WORD; BlankFF : BOOLEAN) ;

VAR
  AddrStr , ByteStr : Str10   ;
  AddrNum , ByteNum : WORD    ;
  Row, Col          : INTEGER ;
  DumpEnd           : BOOLEAN ;

CONST
S1='ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿';
S2='³Buffer: Start       End       Size       Eprom :         Decimal Dump   ³';
S3='ÃÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S4='³Address³OOO OO1 OO2 OO3 OO4 OO5 OO6 OO7  OO8 OO9 O10 O11 O12 O13 O14 O15³';
S5='ÃÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S7='³       ³                                                                ³';
S8='ÃÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S9='ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ';
S6='³                                                                        ³';
  {'..AAAAA..DDD.DDD.DDD.DDD.DDD.DDD.DDD.DDD..DDD.DDD.DDD.DDD.DDD.DDD.DDD.DDD '}
  {'1234567890.........20........30........40........50........60........70.. '}
  {'..2......10...............................43...............60............ '}
BEGIN
    DumpStart (DumpEnd,S1,S2,S3,S4,S5, 3)  ;

    FOR Row := 0 TO 15 DO
    BEGIN
      IF Row = 8 THEN WRITE (S7, NL)    ;
      AddrNum := DumpFirst + (Row)*16   ;
      WRITE ('³ ', AddrNum:5, ' ³' )    ;
      TEXTCOLOR (White)                 ;
      FOR Col := 0 TO 15 DO
      BEGIN
        IF ( AddrNum + Col > DumpLast ) THEN DumpEnd := TRUE  ;
        ByteNum := EpromData^ [ AddrNum + Col ]               ;
        STR (ByteNum:3, ByteStr)                              ;
        IF (BlankFF) AND (ByteNum=$FF) THEN ByteStr := '***'  ;
        IF NOT DumpEnd THEN WRITE ( ByteStr:3 )
                       ELSE WRITE ( '...' )                   ;
        IF Col < 15 THEN WRITE (' ')                          ;
        IF Col = 7  THEN WRITE (' ')                          ;
      END ;
      TEXTCOLOR (Yellow) ;
      WRITE ('³', NL)    ;
    END                  ;

    DumpStop (S8,S6,S9)  ;
END ;
{---------------------------------------------------}
{ 1024 byte ASCII Dump                              }
{---------------------------------------------------}
PROCEDURE AsciiDump ( DumpFirst, DumpLast : WORD ) ;

VAR
  AddrStr           : Str10   ;
  AddrNum , ByteNum : WORD    ;
  Row, Col          : INTEGER ;
  DumpEnd           : BOOLEAN ;

CONST
S1='ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿';
S2='³Buffer: Start       End       Size       Eprom :         ASCII Dump     ³';
S3='ÃÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S4='³Address³O123456789ABCDEF.......78.......O123456789ABCDEF.......78.......³';
S5='ÃÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S7='³       ³                                                                ³';
S8='ÃÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S9='ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ';
S6='³                                                                        ³';
  {'...HHHH..1234567890..........1234567890..........1234567890..........1234.'}
  {'1234.....10........20........30........40........50........60........70.73..'}
  {'...3.....10......................34........................60...............'}
BEGIN

    DumpStart (DumpEnd,S1,S2,S3,S4,S5, 2) ;

    FOR Row := 0 TO 15 DO
    BEGIN
      IF Row = 8 THEN WRITE (S7, NL)     ;
      AddrNum := DumpFirst + (Row)*64    ;
      AddrStr := DecToHex ( AddrNum )    ;
      WRITE ('³  ', AddrStr:4, ' ³' )    ;
      TEXTCOLOR (White)                  ;
      FOR Col := 0 TO 63 DO
      BEGIN
        ByteNum := EpromData^ [ AddrNum + Col ]                         ;
        IF ( AddrNum + Col > DumpLast ) THEN DumpEnd := TRUE            ;
        IF  NOT DumpEnd THEN
            IF ( ByteNum IN [ 07,08,10,13 ] ) THEN WRITE ('.')
                                              ELSE WRITE ( CHR(ByteNum) )
                        ELSE WRITE ('-')                                ;
      END ;
      TEXTCOLOR (Yellow) ;
      WRITE ('³', NL)    ;
    END                  ;

    DumpStop (S8,S6,S9)  ;
END ;
{------------------------------}
{ HexDump 16 x 16 = 256 bytes  }
{------------------------------}
PROCEDURE HexDump ( DumpFirst, DumpLast : WORD; BlankFF : BOOLEAN) ;

VAR
  AddrStr , ByteStr : Str10   ;
  AddrNum , ByteNum : WORD    ;
  Row, Col          : INTEGER ;
  DumpEnd           : BOOLEAN ;

CONST
S1='ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿';
S2='³Buffer: Start       End       Size       Eprom :        ³ ³  ASCII Dump    ³';
S3='ÃÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S4='³Address³OO-O1 O2-O3 O4-O5 O6-O7  O8-O9 OA-OB OC-OD OE-OF³ ³O123456789ABCDEF³';
S5='ÃÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S7='³       ³                                                ³ ³                ³';
S8='ÃÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´ ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´';
S9='ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ';

S6='³                                                        ³ ³                ³';
  {'...HHHH..BB.BB.BB.BB.BB.BB.BB.BB..BB.BB.BB.BB.BB.BB.BB.BB...0123456789ABCDEF '}
  {'1234567890.........20........30........40........50........60........70.....'}
  {'...3.....10......................34........................60...............'}
BEGIN
    DumpStart (DumpEnd,S1,S2,S3,S4,S5, 1) ;

    FOR Row := 0 TO 15 DO
    BEGIN
      IF Row = 8 THEN WRITE (S7, NL)     ;
      AddrNum := DumpFirst + (Row)*16  ;
      AddrStr := DecToHex ( AddrNum )    ;
      WRITE ('³  ', AddrStr:4, ' ³' )    ;
      FOR Col := 0 TO 15 DO
      BEGIN
        IF ( AddrNum + Col > DumpLast ) THEN DumpEnd := TRUE ;
        ByteNum := EpromData^ [ AddrNum + Col ]               ;
        ByteStr := DecToHex ( ByteNum )                       ;
        DELETE (ByteStr, 1, 2)                                ;
        IF (BlankFF) AND (ByteNum=$FF) THEN ByteStr := '**'   ;
        IF NOT DumpEnd THEN WRITE ( ByteStr:2 )
                       ELSE WRITE ( '..' )                    ;
        IF Col < 15 THEN WRITE (' ')                          ;
        IF Col = 7  THEN WRITE (' ')                          ;
      END ;
      WRITE ('³ ³')         ;
      DumpEnd := FALSE ;
      TEXTCOLOR (White)     ;
      FOR Col := 0 TO 15 DO
      BEGIN
        ByteNum := EpromData^ [ AddrNum + Col ]                         ;
        IF ( AddrNum + Col > DumpLast ) THEN DumpEnd := TRUE            ;
        IF  NOT DumpEnd THEN
            IF ( ByteNum IN [ 07,08,10,13 ] ) THEN WRITE ('.')
                                              ELSE WRITE ( CHR(ByteNum) )
                        ELSE WRITE ('-')                                ;
      END ;
      TEXTCOLOR (Yellow) ;
      WRITE ('³', NL)    ;
    END                  ;

    DumpStop (S8,S6,S9) ;
END ;
{-----------------------------------------}
{ Display the Contents of EpromData [i]   }
{-----------------------------------------}
PROCEDURE DisplayEpromData (StartAddr,EndAddr : WORD; DumpOption :INTEGER);

CONST
    PosX: ARRAY [0..15] OF BYTE =
          (10,13,16,19,22,25,28,31, 35,38,41,44,47,50,53,56) ;
    PosY: ARRAY [0..15] OF BYTE =
          (06,07,08,09,10,11,12,13, 15,16,17,18,19,20,21,22) ;
    PosA: ARRAY [0..15] OF BYTE =
          (61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76) ;
VAR
  DumpSize                   : INTEGER ;
  i                          : LONGINT ;
  n, k                       : INTEGER ;
  Readbyte, PageNum          : BYTE    ;
  Key1, Key2                 : CHAR    ;
  EditMode, BlankFF          : BOOLEAN ;
  PosXY : ARRAY [0..256,0..1] OF BYTE  ; { 256 Hex Area Position XY }
  PosAY : ARRAY [0..256,0..1] OF BYTE  ; { ASCII Area Position XY   }
{---------------------------------------}
PROCEDURE DumpEdit (StartAddr : WORD; BlankFF : BOOLEAN) ;

VAR
  KeyB             : CHAR      ;
  xy, c, m         : INTEGER   ;
  HexStr           : Str10     ;
  Number           : BYTE      ;

BEGIN

    TEXTCOLOR      (Red)   ;
    TEXTBACKGROUND (Green) ;
    xy := 0                ;
    GOTOXY (2, 24) ;
    WRITE  ('EDIT MODE: [Enter] [End-Home] [Up-Down-Left-RightArr]') ;

    REPEAT
      GOTOXY ( PosXY [xy,0], PosXY [xy,1] )  ;
      HexStr[1] := UPCASE (READKEY) ;
      CASE HexStr[1] OF
              #48..#57,
              #65..#70 : BEGIN
                            WRITE (HexStr[1])                        ;
                            REPEAT HexStr[2] := UPCASE (READKEY)     ;
                            UNTIL (HexStr[2] IN [#48..#57,#65..#70]) ;
                            WRITE (HexStr[2])                        ;
                            HexStr[0] := CHR (2)                     ;
                            Number := HexToDec (HexStr)              ;
                            IF (BlankFF) AND (Number=$FF) THEN
                                         WRITE (#8#8,'..')           ;
                            GOTOXY ( PosAY [xy,0] , PosAY [xy,1] )   ;
                            IF ( Number IN [ 07,08,10,13 ] ) THEN WRITE ('.')
                                 ELSE WRITE ( CHR(Number) )          ;
                            EpromData^[StartAddr + xy] := Number     ;
                            xy := xy+1                               ;
                         END                                         ;
              #00: BEGIN
                     KeyB := READKEY ;     { 2 code for special keys }
                     CASE KeyB OF
                                #71 : { Home        } xy := 0        ;
                                #79 : { End         } xy := 255      ;
                                #72 : { Up Arrow    } xy := xy - 16  ;
                                #80 : { Down Arrow  } xy := xy + 16  ;
                                #75 : { Left Arrow  } xy := xy - 1   ;
                                #77 : { Right Arrow } xy := xy + 1   ;
                      END          ; { Case KeyB                         }
                      IF xy <  0   THEN xy := 0   ;
                      IF xy >= 255 THEN xy := 255 ;
                   END   ; { Case HexStr[1] = #0 }
          #27,#13: BEGIN
                     TEXTCOLOR (Yellow)    ;
                     TEXTBACKGROUND (Blue) ;
                     Exit ;
                   END                 ;
          END    ;         { Case HexStr[1]      }

   UNTIL HexStr[1] = #27 ;

   END  ;

 { MAIN ----------------- Display EpromData }

   BEGIN
   { Display the results }

   EditMode := FALSE  ;
   BlankFF  := FALSE  ;

   CASE DumpOption OF   { Hex Decimal Dump 256 bytes, ASCII 1024 bytes }
                   1,2: DumpSize := 256  ;
                     3: DumpSize := 1024 ;
   END                                   ;

   FOR i := 0 TO 15 DO FOR n := 0 TO 15 DO
                      BEGIN
                        PosAY [i*16+n,0] := PosA [n] ;
                        PosAY [i*16+n,1] := PosY [i] ;
                        PosXY [i*16+n,0] := PosX [n] ;
                        PosXY [i*16+n,1] := PosY [i] ;
                      END                       ;

  WINDOW (1,1,80,25) ; { Normal }
  TEXTCOLOR (White) ; TEXTBACKGROUND (Blue) ;

  n := 0 ;
  i := StartAddr ;
  PageNum := 0     ;

  REPEAT

    IF DumpOption=1 THEN HexDump   ( i, EndAddr,BlankFF); { 16x16 HexDump   }
    IF DumpOption=2 THEN DecDump   ( i, EndAddr,BlankFF); { 16x16 DecDump   }
    IF DumpOption=3 THEN AsciiDump ( i, EndAddr        ); { 64x16 AsciiDump }

    GOTOXY (62-DumpOption, 24)                                  ;
    WRITE ('PAGE',PageNum:3, ' of ',(EndAddr DIV DumpSize):3 )  ;
    GOTOXY (62-DumpOption, 24)                                  ;

    {--------------------------------------}
    { Check for special keys, escape and E }
    {--------------------------------------}
    Key1 := READKEY ;

    CASE Key1 OF
              #27: { Escape } ;
              #32: { SPCbar } BlankFF := BlankFF XOR TRUE ;
              #00: BEGIN
                     Key2 := READKEY ;     { 2 code for special keys }
                     CASE Key2 OF
                                #73 : { PageUp    } i := i-DumpSize         ;
                                #81 : { Page Down } i := i+DumpSize         ;
                                #71 : { Home      } i := StartAddr          ;
                                #79 : { End       } i := EndAddr-DumpSize+1 ;
                                #72 : { Up Arrow  } i := i-1                ;
                                #80 : { Down Arrow} i := i+1                ;
                     END          ; { Case Key2                         }
                     IF i <  StartAddr THEN i := StartAddr          ;
                     IF i >= EndAddr   THEN i := EndAddr-DumpSize+1 ;
                   END   ; { Case Key1 = #0 }
              #13: BEGIN
                       EditMode := EditMode XOR TRUE  ;
                       IF EditMode THEN
                       BEGIN
                         DumpEdit (i, BlankFF)            ;
                         EditMode := FALSE                ;
                       END                                ;
                   END                                    ;
          END    ;         { Case Key1      }

    PageNum := (i DIV DumpSize) ;

  UNTIL key1 = #27 ; { ESC }
END ;
{---------------------}
{ Initialise Records  }
{---------------------}
{$I Eprom1.INC }
{-------------------------}
{ Check and Read          }
{-------------------------}
PROCEDURE CheckRead ;

BEGIN
    IF EpromInfoRead = 0 THEN  { Only read and zero once }
               BEGIN
                 ZeroRecords        ;
                 ReadEproms         ;
                 EpromInfoRead := 1 ;
               END                  ;
END ;
{-------------------------}
{ List all stored records }
{-------------------------}
PROCEDURE ListRecords (Option : INTEGER);

VAR
   Number        : INTEGER ;
   EpromSelected : INTEGER ;

BEGIN
    CheckRead    ;

    MakeWindow (800,26,2,White,Black,8) ; { Display a window }
    CLRSCR ;
    WRITELN (   '             LIST OF EPROM DATA ' )                ;
    WRITELN (   'ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ' ) ;
    WRITELN (   ' Record  Name  Description' )                   ;

    FOR Number := 1 TO EpromNum DO
        WITH Eproms [ Number ] DO
          WRITELN ('  ',  Number:2,
                   '    ',IdData.Number:5,'  ',IdData.Description) ;
          IF Option = 0 THEN
          BEGIN
            WRITE   (NL,' Any key to continue ....') ;
            Choice := READKEY ;
          END ;
          IF Option = 1 THEN
          BEGIN
            WRITE   (NL,' Select EpromType ( 1 - ',EpromNum,' ) : ') ;
            {$I-}
            READLN (EpromSelected) ; { Record Number }
            {$I+}
            IF (IORESULT = 0) AND (EpromSelected < MaxEprom) THEN
            BEGIN
               EpromType := EpromSelected ;
               ReadWrite := 2             ;
            END                           ;
          END ;
END ;

{-----------------------------------}
{ Information and Data Manipulation }
{-----------------------------------}
PROCEDURE DoEpromData ;

VAR
    Answer   : Str80   ;
    N        : INTEGER ;
{-------------------------------}
BEGIN
    CheckRead  ;

    REPEAT
         MakeWindow (400,2,2,White,Red,1) ;   { Display a window }
         CLRSCR ;
         WRITELN ('        EPROM DATA BASE') ;
         WRITELN ;
         WRITELN (' Number of Stored Eprom Types is : ', EpromNum) ;
         WRITELN ;
         WRITE   (' (A)dd',NL,
                  ' (E)dit',NL,
                  ' (L)ist',NL,
                  ' (P)in Information',NL,
                  ' (M)ain menu',NL,
                  ' (Q)uit',NL,NL,
                  ' Select Option :') ;
         Choice := UPCASE (READKEY) ;
         CASE Choice OF
             'A' : AddRecords (0)  ;
             'E' : AddRecords (1)  ;
             'L' : ListRecords (0) ;
             'P' : ShowPins        ;
             'Q' : HALT (0)        ;
         END ; { Case }

   UNTIL Choice = 'M' ;

   WriteEproms ;

 END ;
{---------------------------------}
{ Check Eprom Selected            }
{---------------------------------}
FUNCTION CheckSelect : BOOLEAN ;

BEGIN
  IF EpromType = 0 THEN
  BEGIN
    GOTOXY (2, WHEREY + 1 )           ;
    WRITE  (' Select eprom First ..') ;
    DELAY (800)                       ;
    CheckSelect := FALSE              ;
    EXIT                              ;
  END                                 ;
  CheckSelect := TRUE                 ;
END ;

{---------------------------------}
{ Show EPROM PINOUT               }
{---------------------------------}
PROCEDURE ShowPins ;

CONST
  PinArr: ARRAY [0..7] OF STRING [8] =
          ('GND','V+ ','Vcc','Vpp','Ax ','Dx ','PulseH','PulseL')  ;
  XArr  : ARRAY [1..6] OF INTEGER = (18, 20, 21, 24, 25, -1) ;

VAR
  i,p1,n,s1,k   : INTEGER ;

BEGIN

  IF NOT CheckSelect THEN EXIT ;

  MakeWindow (1580,2,2,Yellow,Brown,0) ;   { Display a window }
  CLRSCR ;
  WRITE(' EPROM PIN DATA :                                                  ',NL);
  WRITE('                                                                   ',NL);
  WRITE(' ÉÍÏÍÍÍÏÍËÍÏÍÍÍÏÍËÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍÍÍÏÍ» ',NL);
  WRITE(' º       º       º                                               º ',NL);
  WRITE(' º       º       º                                               º ',NL);
  WRITE(' È» 32   È» 28   È» 24                                           º ',NL);
  WRITE(' É¼ PIN  É¼ PIN  É¼ PIN                                          º ',NL);
  WRITE(' º       º       º                                               º ',NL);
  WRITE(' º       º       º                                               º ',NL);
  WRITE(' ÈÍÑÍÍÍÑÍÊÍÑÍÍÍÑÍÊÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍÍÍÑÍ¼ ',NL);
  WRITE('                                                                   ',NL);
  WRITE(' ÚÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ',NL);
  WRITE(' ³ MODE    ³ PIN NAME and NUMBER                                 ³ ',NL);
  WRITE(' ³         ÃÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ´ ',NL);
  WRITE(' ³         ³        ³        ³        ³        ³        ³        ³ ',NL);
  WRITE(' ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´ ',NL);
  WRITE(' ³ Read    ³        ³        ³        ³        ³        ³        ³ ',NL);
  WRITE(' ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´ ',NL);
  WRITE(' ³ Verify  ³        ³        ³        ³        ³        ³        ³ ',NL);
  WRITE(' ÃÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄ´ ',NL);
  WRITE(' ³ Program ³        ³        ³        ³        ³        ³        ³ ',NL);
  WRITE(' ÀÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÙ '   );

  {-------------------}
  { Add Text to IC    }
  {-------------------}
  p1 := 4 + (32-(Eproms[EpromType].Pins.Total))*2;{ Pin1 at Pos 4, 12, 20 }
  n := 0 ;
  s1 := Eproms[EpromType].Pins.Total DIV 2 ;

  GOTOXY (25,7); TEXTCOLOR (Black); WRITE (Eproms[EpromType].IdData.Number:7,
                  '  Size : ', Eproms[EpromType].Size.Total:5,' bytes   ' ) ;

  FOR i := 1 TO s1 DO
  BEGIN
    GOTOXY (p1 + n, 9 ); WRITE (i) ;
    GOTOXY (p1-1+n, 11); WRITE ( (Eproms[EpromType].Pins.Name[i]):3 ) ;
    GOTOXY (p1 + n, 4 ); WRITE (s1*2-i+1) ;
    GOTOXY (p1-1+n, 2 ); WRITE ( (Eproms[EpromType].Pins.Name[s1*2-i+1]):3);
   n := n + 4 ;
  END ;
  {-----------------------}
  { Add Text to the Table }
  {-----------------------}
  n := 0            ;
  s1 := s1-12       ;               { s1=0 24pin s1=2 28pin s1=4 32 pin }
  FOR i := 1 TO (4+s1) DO           { 1 to 4 24pin   1 to 6 28pin       }
  BEGIN
    k := Xarr[i]  ;                 { k = 18, 20, 21, 24, 25, -1        }
    GOTOXY (14+n, 15) ;
    WRITE (k+s1,' ',Eproms[EpromType].Pins.Name [k+s1] ) ;
    GOTOXY (14+n, 19) ;
    WRITE ( PinArr[ Eproms[EpromType].Verify.PinLevel[k+s1] ] ) ;
    GOTOXY (14+n, 21) ;
    WRITE ( PinArr[ Eproms[EpromType].Prog.PinLevel[k+s1] ] ) ;
    n := n + 9        ;
  END                 ;
  WRITELN ;
  READLN  ;
END ;
{-----------------------------------}
{ Convert Number to Hex String      }
{-----------------------------------}
FUNCTION DecToHex (VAR Number : WORD ) : str10 ;

BEGIN
  DecToHex[1] :=  HexDigit [ HI (Number) DIV 16 ] ;
  DecToHex[2] :=  HexDigit [ HI (Number) MOD 16 ] ;
  DecToHex[3] :=  HexDigit [ LO (Number) DIV 16 ] ;
  DecToHex[4] :=  HexDigit [ LO (Number) MOD 16 ] ;

  DecToHex[0] := CHR (4) ;  { Set Length = 4 chars }

END ;
{-----------------------------------}
{ Convert Hex String to Number      }
{-----------------------------------}
FUNCTION HexToDec ( HexStr : str10) : WORD ;

VAR
  Number                  : WORD    ;
  E                       : INTEGER ;

BEGIN
  HexStr := '$'+ HexStr               ;
  VAL (HexStr, Number, E)             ;
  IF E > 0 THEN Number := 0           ;
  HexToDec := Number                  ;
END ;
{-------------------------------------}
{ Initialise Parallel (Printer) Port  }
{-------------------------------------}
PROCEDURE InitialisePort (EpromType : INTEGER) ;

VAR
  i                     : INTEGER  ;
  SaveData, SaveControl : BYTE     ;
  Quit                  : CHAR     ;

BEGIN
  {----------------------------------------------------}
  { Set both the data and control port to all bits off }
  {----------------------------------------------------}
  SaveData      := Data.Number    ;
  SaveControl   := Control.Number ;

  Data.PPort    := [] ; { Empty set D0-D7 = clear  }
  Control.PPort := [] ; { Same if Data.Number := 0 }

  {---------------------------------} { Test LED's }
   MakeWindow (500,15,10,Black,LightGray,1) ;   { Display a window }
   CLRSCR ;
   WRITELN (NL,' Communication Test     ',NL) ;
   WRITELN (   '   ÚÄÄÄ¿                ') ;
   WRITELN (   '   ³ þ ³ Write          ') ;
   WRITELN (   '   ³ þ ³ Read           ') ;
   WRITELN (   '   ³ þ ³ Program        ') ;
   WRITELN (   '   ³ þ ³ Message        ') ;
   WRITELN (   '   ³ þ ³ Power          ') ;
   WRITELN (   '   ³LED³                ') ;
   WRITELN (   '   ÀÄÄÄÙ                ') ;
   WRITELN (NL,' Running..Press any key ') ;

  GOTOXY (6,8) ; TEXTCOLOR (Red ) ; WRITE (#219) ; { Switch on POWER LED }
  i := 0 ;
  REPEAT
    DELAY (120) ;
    GOTOXY (6,5) ; TEXTCOLOR (Black)  ; WRITE (#254) ; { READ LED OFF }
    Data.PPort   := Data.PPort + [D4] ; { D4=1 OE Eprom WRITE state }
    PORT [Base]  := Data.Number       ;
    GOTOXY (6,4) ; TEXTCOLOR (Red)    ; WRITE (#219) ; { WRITE LED ON }
    DELAY (120)  ;
    GOTOXY (6,4) ; TEXTCOLOR (Black)  ; WRITE (#254) ; { WRITE LED OFF }
    GOTOXY (6,5) ; TEXTCOLOR (Green)  ; WRITE (#219) ; { READ LED ON   }
    Data.PPort   := Data.PPort - [D4] ; { D4=0 READ State }
    PORT [Base]  := Data.Number       ;
    INC (i)                           ;
    IF KEYPRESSED THEN  i := 9        ;
  UNTIL (i > 7)                       ;
  IF    (i > 8) THEN Quit := READKEY  ;
  {-------------------------------------------------------------}
  { ControlPort at Base + 2 : D0 = Strobe    = PGM is inverted  }
  {                           D2 = Initialise = MSG is inverted }
  {-------------------------------------------------------------}
  TEXTCOLOR (Black); GOTOXY (2,12); WRITELN ('Program-Message Running..') ;
  i := 0 ;
  REPEAT
    DELAY (120)   ;
    Control.PPort := Control.PPort - [D2] ; { D2=0 MSG ON                }
    GOTOXY (6,7)  ; TEXTCOLOR (Yellow )   ; WRITE (#219) ; { MSG LED ON  }
    Control.PPort := Control.PPort + [D0] ; { D0=1 STROBE = PGM OFF      }
    PORT [Base+2] := Control.Number       ;
    GOTOXY (6,6)  ; TEXTCOLOR (Black)     ; WRITE (#254) ; { PGM LED OFF }
    DELAY (120)   ;
    GOTOXY (6,6)  ; TEXTCOLOR (Red)       ; WRITE (#219) ; { PGM LED ON  }
    GOTOXY (6,7)  ; TEXTCOLOR (Black)     ; WRITE (#254) ; { MSG LED OFF }
    Control.PPort := Control.PPort - [D0] ; { D0=0 PGM ON                }
    Control.PPort := Control.PPort + [D2] ; { D2=1 MSG OFF               }
    PORT [Base+2] := Control.Number       ;
    IF KEYPRESSED THEN i := 9             ;
    INC (i)                               ;
  UNTIL (i > 7)                           ;
  IF    (i > 8) THEN Quit := READKEY      ;

  GOTOXY (6,6)  ; TEXTCOLOR (Black)       ; WRITE (#254) ; { PGM LED OFF   }
  Control.PPort := Control.PPort + [D0]   ; { Control : D0=1 PGM OFF (inv) }
  PORT [Base+2] := Control.Number         ;

  DELAY (900)                    ;

  Data.Number    := SaveData              ; { Restore Entry Conditions }
  PORT [Base]    := Data.Number           ;
  Control.Number := SaveControl           ;
  PORT [Base+2]  := Control.Number        ;
                                            { End of Initialsation         }
END ;
{-----------------------------------}
{ Replace eprom in socket           }
{-----------------------------------}
PROCEDURE ReplaceEprom ;

VAR
  SaveData    : BYTE ;
  SaveControl : BYTE ;

BEGIN
  SaveData    := Data.Number    ; { Save Dataport Configuration    }
  SaveControl := Control.Number ; { Save Controlport configuration }

  Data.PPort    := []                        ; { All D0-D7 = 0 OFF   }
  Control.PPort := [D0,D1,D2,D3,D4,D5,D6,D7] ; { All Dx=1 => All OFF }

  PORT [Base]   := Data.Number    ;
  PORT [Base+2] := Control.Number ;

  CLRSCR ;
  WRITE (NL,NL,' (1) SWITCH OFF PROGRAMMER.       ',NL,
               ' (2) REPLACE EPROM.               ',NL,
               ' (3) PRESS ANY KEY.               ',NL,
               ' (4) SELECT (DIFFERENT) EPROMTYPE.',NL,
               ' (5) SWITCH ON PROGRAMMER.        ',NL) ;

  Choice := READKEY ;

  Data.Number    := SaveData    ;  { Old Config Back }
  Control.Number := SaveControl ;

  PORT [Base]   := Data.Number    ;
  PORT [Base+2] := Control.Number ;

END ;
{--------------------------------}
{ Enable Vpp = 1 Disable Vpp = 0 }
{--------------------------------}
PROCEDURE SetVpp ( OnOff : BYTE ) ;

BEGIN
  { Enable Vpp }
    IF OnOff = 1 THEN Data.PPort := Data.PPort + [D7] ; { Enable Vpp on D7  }
  { Disable Vpp }
    IF OnOff = 0 THEN Data.PPort := Data.PPort - [D7] ; { Disable Vpp on D7 }
    PORT [ Base ] := Data.Number                      ;
    IF OnOff = 1 THEN WRITE (' Vpp ENABLED .... ' )   ;
    IF OnOff = 0 THEN WRITE (' Vpp DISABLED ... ' )   ;
END                                                   ;

{-----------------------------}
{ Send Program Pulse to Eprom }
{-----------------------------}
PROCEDURE SendPulse ( Width : BYTE ; Direction : BYTE ) ;

BEGIN


  { Send Pulse  }

    IF Direction=1 THEN Control.PPort := Control.PPort - [D0]  { DO Strobe }
                   ELSE Control.PPort := Control.PPort + [D0]; { = PGM     }
    PORT [ Base + 2 ] := Control.Number                      ;

    DELAY ( Width )                                          ; { Pulsewidth}

    IF Direction=1 THEN Control.PPort := Control.PPort + [D0]  { DO Strobe }
                   ELSE Control.PPort := Control.PPort - [D0]; { = PGM     }
    PORT [ Base + 2 ] := Control.Number                      ;

END ;
{-------------------------}
{ Write a byte to 4094    }
{-------------------------}
PROCEDURE Write4094 (WriteByte : BYTE) ;

VAR
  i                  : INTEGER ;
  Mask,Temp          :  BYTE   ;

BEGIN

  { Send Byte to 4094 }

  FOR i := 0 TO 7 Do
  BEGIN
    { --------------------------------    Set up each bit in the byte      }
    Temp := WriteByte ;                 { Byte to write                    }
    Data.PPort := Data.PPort - [D2,D3]; { Clear D2,D3: 4094 clock+data = 0 }
    Mask := Power2 [i]                ; { 1,2,4,..128                      }
    Temp := Temp AND Mask             ; { Check Dx 1 or 0                  }
    IF Temp > 0 THEN                    { Set D2 = 1 if Temp = 1           }
    Data.PPort := Data.PPort + [D2]   ;
    PORT [ Base ] := Data.Number      ; { Send D2             }
    { --------------------------------             Clock 4094 }
    Data.PPort := Data.PPort + [D3]   ; { Set D3 : 4094 Clock }
    PORT [ Base ] := Data.Number      ;
    Data.PPort := Data.PPort - [D3]   ; { Clock Low           }
    PORT [ Base ] := Data.Number      ;
  END ;
END ;
{-------------------------}
{ Read a byte from 4021   }
{-------------------------}
FUNCTION Read4021 : BYTE ;

VAR
  n                  : INTEGER ;
  Bit,Mask,ReadByte  :  BYTE   ;

BEGIN

  { Load 4021 Parallel Port }

    Data.PPort := Data.PPort - [D5]   ; { Clear D5 : 4021 clock low  }
    PORT [ Base ] := Data.Number      ;
    Data.PPort := Data.PPort - [D6]   ; { Clear D6 : 4021 Par-Ser line }
    PORT [ Base ] := Data.Number      ;
    Data.PPort := Data.PPort + [D6]   ; { Set D6 : 4021 Par-Ser line }
    PORT [ Base ] := Data.Number      ;
    Data.PPort := Data.PPort - [D6]   ; { Clear D6 : 4021 Par-Ser line }
    PORT [ Base ] := Data.Number      ;

  { Clock the parallel data out }

    n        := 7 ;
    Mask     := 0 ;
    Bit      := 0 ;
    ReadByte := 0 ;

    REPEAT

      Bit := PORT [Base+1]            ;  { Read Base = 1 }

      Data.PPort := Data.PPort - [D5] ;  { Clear D5 : 4021 Clock L }
      PORT [Base] := Data.Number    ;

      Data.PPort := Data.PPort + [D5] ;  { Set D5 : 4021 Clock H }
      PORT [Base] := Data.Number    ;

      Data.PPort := Data.PPort - [D5] ;  { Clear D5 : 4021 Clock L }
      PORT [Base] := Data.Number    ;

      Bit := NOT Bit                  ;  { BUSY D7 StatusPort is inverted }
      Bit := Bit AND 128              ;  { Bit7 masked out 1000 0000 }

      IF Bit > 0 THEN Mask := 1 ELSE Mask := 0     ;
      ReadByte := ReadByte + ( Power2 [n] * Mask ) ;

      n := n - 1 ;

    UNTIL n < 0  ;   { Clocked all 8 bits out }

    Read4021 := ReadByte ;

END ;
{----------------------------------------}
{ Reset 4040-4024 to StartAddress = 0    }
{----------------------------------------}
PROCEDURE Reset4040  ;

BEGIN
    Data.PPort := Data.PPort + [D1]   ; { Set bit D1   }
    PORT [ Base ] := Data.Number      ;
    Data.PPort := Data.PPort - [D1]   ; { Clear bit D1 }
    PORT [ Base ] := Data.Number      ;
END ;

{----------------------------------------}
{ Clock 4040-4024 to StartAddress times  }
{----------------------------------------}
PROCEDURE Clock4040 (StartAddr : WORD) ;

VAR
  n : WORD ;

BEGIN
  { If StartAddr = 0 go right through }
  FOR n := 1 TO StartAddr DO
  BEGIN
    Data.PPort := Data.PPort + [D0]   ; { Set bit D0   }
    PORT [ Base ] := Data.Number      ;
    Data.PPort := Data.PPort - [D0]   ; { Clear bit D0 }
    PORT [ Base ] := Data.Number      ;
  END                                 ;
END                                   ;

  {--------------------------------}
  { Write required Switch Settings }
  {--------------------------------}
FUNCTION SwitchSetting (Option: INTEGER): BOOLEAN; {Option 0 READ 1 WRITE}

CONST
S1='ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿' ;
S2='³ Eprom Programmer Switch Configuration:                       ³' ;
S3='ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´' ;
S4='³ ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ ³' ;
S5='³ ³    Switch Diagram       ³³ Set  Switch Description       ³ ³' ;
S6='³ ³                         ³³                               ³ ³' ;
S7='³ ³                         ³³ A - a            -            ³ ³' ;
S8='³ ³                         ³³ B - b            -            ³ ³' ;
S9='³ ³ Ü Ü   Ü Ü   Ü Ü   Ü Ü   ³³ C - c            -            ³ ³' ;
SA='³ ³ a b   a b   a b   a b   ³³ D - d            -            ³ ³' ;
SB='³ ³                         ³³ E - e            -            ³ ³' ;
SC='³ ³                         ³³ F - f            -            ³ ³' ;
SD='³ ³ Ü Ü    Ü Ü Ü    Ü Ü Ü   ³³ G - g            -            ³ ³' ;
SE='³ ³ a b    a b c    a b c   ³³                               ³ ³' ;
SF='³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ³' ;
SG='³ [ Eprom:        Size:      ]                                 ³' ;
SH='ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ' ;



VAR
  i : INTEGER ;
  Key : CHAR  ;

PROCEDURE Diagram ;

CONST
  X : ARRAY [1..7] OF INTEGER = (5, 12,21, 5,11,17,23 ) ;
  Y : ARRAY [1..7] OF INTEGER = (12,12,12, 8, 8, 8, 8 ) ;
VAR
  n : INTEGER ;

  BEGIN
    WITH Eproms [EpromType].Switches DO
    BEGIN
      FOR n := 1 TO 7 DO
        IF Position[n] <> 'x' THEN
        BEGIN
          GOTOXY (X[n] + 2*(ORD(Position[n])-97), Y[n]);
          WRITE ('Û ',Code[n],#8#8#8#10,'Ü',#8#10,Position[n] ) ;
        END  ;
    END   ;
  END     ;

BEGIN
   WINDOW (1,1,80,25) ; TEXTBACKGROUND (Cyan) ; CLRSCR ;
   WINDOW (5,4, 69,21); TEXTCOLOR (Yellow); TEXTBACKGROUND (Blue);
   CLRSCR; WRITE  (S1,NL,S2,NL,S3,NL,S4,NL,S5,NL,S6,NL,S7,NL,S8,NL,S9,NL,
                   SA,NL,SB,NL,SC,NL,SD,NL,SE,NL,SF,NL,SG,NL,SH ) ;
   TEXTCOLOR (White) ;
   GOTOXY (42,2) ; IF Option=0 THEN WRITE ('Verify - Read Mode.  ') ;
                   IF Option=1 THEN WRITE ('Program - Write Mode.') ;

  Data.PPort    := []      ;  { All bits = 0 }
  Control.PPort := [D0,D2] ;  { D0,D2 = 1 -> D0,D2 = 0 }

  Diagram ;
  WITH Eproms [EpromType].Switches DO
  BEGIN
     FOR i := 1 TO 7 DO
     BEGIN
       GOTOXY (32, 6+i) ;
       WRITE   ( Code[i]:1 , ' - ', Position[i]:1, ' ',
                 Name[i]:10, ' - ', Connect[i]:10   ) ;
     END ;
   END   ;

  GOTOXY (11,16) ; WRITE (Eproms[EpromType].IdData.Number:7 )  ;
  GOTOXY (24,16) ; WRITE (Eproms[EpromType].Size.Total:5    )  ;
  GOTOXY (32,16) ; WRITE ('[Y] Proceed [N] Cancel : ') ;
  Key := UPCASE (READKEY) ;
  SwitchSetting := ( Key = 'Y' ) ;

END ;

{-------------------------}
{ Set Eprom up for Read   }
{-------------------------}

PROCEDURE SetupEpromForRead (EpromType : INTEGER) ;

VAR
  Pin18,Pin20,Pin21,PinPlus1,PinMinus2 : BYTE    ;
  i                                    : INTEGER ;

BEGIN

  {----------------------}
  { Read Verify.PinLevel }
  {----------------------}
  Pin18 := Eproms [EpromType].Verify.Pinlevel [18] ;
  IF Pin18 = 0 THEN Control.PPort := Control.PPort + [D0]  {D0 PGM Pin18}
               ELSE Control.PPort := Control.PPort - [D0] ;{D0=1 = OFF  }

  Pin20 := Eproms [EpromType].Verify.Pinlevel [20] ;
  IF Pin20 = 0 THEN Data.PPort := Data.PPort - [D4]  {D4 OE Pin20}
               ELSE Data.PPort := Data.PPort + [D4] ;{D4=1 = ON  }

  PORT [ Base ]   := Data.Number            ;
  PORT [ Base+2 ] := Control.Number         ;

END ;
{-------------------------}
{ Set Eprom up for Write  }
{-------------------------}
PROCEDURE SetupEpromForWrite (EpromType : INTEGER; Direction : BYTE) ;

VAR
  PinNum,Pin20 : BYTE    ;
  i                                    : INTEGER ;

BEGIN

  {----------------------}
  { Write Prog.PinLevel  }
  {----------------------}
  PinNum := (Eproms[EpromType].Pins.Total DIV 2) - 12 ; {Correct Pin 20, 22}
  IF Direction=1 THEN Control.PPort := Control.PPort + [D0]  {D0 PGM Pin18}
                 ELSE Control.PPort := Control.PPort - [D0] ;{D0=1 = OFF  }

  Pin20 := Eproms [EpromType].Prog.Pinlevel [20+PinNum] ;
  IF Pin20 = 0 THEN Data.PPort := Data.PPort - [D4]  {D4 OE Pin20}
               ELSE Data.PPort := Data.PPort + [D4] ;{D4=1 = ON  }

  PORT [ Base ]   := Data.Number            ;
  PORT [ Base+2 ] := Control.Number         ;

END ;
{-------------------------------------------}
BEGIN

END. { Unit Eprom1 }


