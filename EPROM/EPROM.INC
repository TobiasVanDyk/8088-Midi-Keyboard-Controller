{ Eprom.inc }

PROCEDURE DoHelp ;

VAR
  Y : CHAR ;

PROCEDURE NextPage                     ;
BEGIN
  REPEAT Y := READKEY ; UNTIL Y <> #00 ;
  CLRSCR                               ;
END                                    ;

BEGIN

TEXTCOLOR (White)  ;
WINDOW (1,1,80,25) ; { Normal }
CLRSCR  ;

WRITELN (NL, NL, NL ) ;
WRITELN (' PAGE 1            Common Pin Designations :                        ');
WRITELN ;
WRITELN ('                зддддддддддддд© здддддддддддддд©                    ');
WRITELN ('      Vpp A15  д╢ 1  (-2) 28P юды      (+2) 28 цд  V+               ');
WRITELN ('          A12  д╢ 2  (-1)              (+1) 27 цд  WElo PGM  A14    ');
WRITELN ('          A07  д╢ 3  (1)------© з------(24) 26 цд  CShi V+   A13    ');
WRITELN ('          A06  д╢ 4  (2)  24P юды      (23) 25 цд  A08              ');
WRITELN ('          A05  д╢ 5  (3)               (22) 24 цд  A09              ');
WRITELN ('          A04  д╢ 6  (4)               (21) 23 цд  A11  WElo A12 Vpp');
WRITELN ('          A03  д╢ 7  (5)               (20) 22 цд  OElo PGM  Vpp V+ ');
WRITELN ('          A02  д╢ 8  (6)               (19) 21 цд  A10              ');
WRITELN ('          A01  д╢ 9  (7)               (18) 20 цд  CSlo PGM  GND    ');
WRITELN ('          A00  д╢ 10 (8)               (17) 19 цд  D07              ');
WRITELN ('          D00  д╢ 11 (9)               (16) 18 цд  D06              ');
WRITELN ('          D01  д╢ 12 (10)              (15) 17 цд  D05              ');
WRITELN ('          D02  д╢ 13 (11)              (14) 16 цд  D04              ');
WRITELN ('          GND  д╢ 14 (12)              (13) 15 цд  D03              ');
WRITELN ('                юдддддддддддддддддддддддддддддды                    ');
WRITELN ;

NextPage ;

WRITELN (NL, NL, NL ) ;
WRITELN (' PAGE 2   SWITCHES : (Refer to 24 PIN numbers)                      ');
WRITELN ;
WRITELN ('    здддддддддддддддбдддддддддддддддбдддддддддддддддбддддддддддддддд©');
WRITELN ('    Ё[D] PIN 26 (24)Ё[E] PIN 1 (-2) Ё[F] PIN 22 (20)Ё[G] PIN 23 (21)Ё');
WRITELN ('    Ё               Ё               Ё               Ё               Ё');
WRITELN ('    Ё   A13   V+    Ё   Vpp   A15   Ё  Read   Vpp   Ё   Vpp   A11   Ё');
WRITELN ('    Ё     э   э     Ё     э   э     Ё     э   э     Ё     э   э     Ё');
WRITELN ('    цдддддддддддддддедддддддддддддддаддддддбддддддддаддддддддддддддд╢');
WRITELN ('    Ё[A] PIN 27 (+1)Ё[B]  PIN 20 (18)      Ё[C]     Vpp             Ё');
WRITELN ('    Ё               Ё                      Ё                        Ё');
WRITELN ('    Ё  PGM   A14    Ё   PGM    V+   GND    Ё   12   21  25   VOLT   Ё');
WRITELN ('    Ё    э   э      Ё     э    э    э      Ё    э   э   э           Ё');
WRITELN ('    юдддддддддддддддаддддддддддддддддддддддадддддддддддддддддддддддды');
WRITELN ;

NextPage ;

WRITELN (NL, NL, NL ) ;
WRITELN ('        зддддддбддддддбддддддбддддддбддддддбддддддбддддддбддддддбдддддд© ');
WRITELN ('        Ё PIN  Ё 2716 Ё 2532 Ё 2732 Ё 2564 Ё 2764 Ё 27128Ё 27256Ё 27512Ё ');
WRITELN ('        цддддддеддддддеддддддеддддддеддддддеддддддеддддддеддддддедддддд╢ ');
WRITELN ('        Ё -2   Ё NC   Ё NC   Ё NC   Ё Vpp  Ё Vpp  Ё Vpp  Ё Vpp  Ё A15  Ё ');
WRITELN ('        цддддддеддддддеддддддеддддддеддддддеддддддеддддддеддддддедддддд╢ ');
WRITELN ('        Ё +1   Ё NC   Ё NC   Ё NC   Ё      Ё PGM  Ё PGM  Ё A14  Ё A14  Ё ');
WRITELN ('        Ё      Ё      Ё      Ё      Ё      Ё д©зд Ё д©зд Ё      Ё      Ё ');
WRITELN ('        Ё      Ё      Ё      Ё      Ё      Ё  юы  Ё  юы  Ё      Ё      Ё ');
WRITELN ('        цддддддеддддддеддддддеддддддеддддддеддддддеддддддеддддддедддддд╢ ');
WRITELN ('        Ё 20   Ё V+   ЁPGM ©зЁ Vpp  ЁPGM ©зЁ V+   Ё V+   Ё V+   Ё Vpp  Ё ');
WRITELN ('        Ё      Ё      ЁReadюыЁ      ЁReadюыЁ      Ё      Ё      Ё      Ё ');
WRITELN ('        цддддддеддддддеддддддеддддддеддддддеддддддеддддддеддддддедддддд╢ ');
WRITELN ('        Ё 18   Ё PGM  Ё GND  Ё PGM  Ё GND  Ё GND  Ё GND  Ё PGM  Ё PGM  Ё ');
WRITELN ('        Ё      Ё  з©  Ё V+   Ё д©зд Ё V+   Ё      Ё      Ё д©зд Ё д©зд Ё ');
WRITELN ('        Ё      Ё дыюд Ё      Ё  юы  Ё      Ё      Ё      Ё  юы  Ё  юы  Ё ');
WRITELN ('        цддддддеддддддеддддддеддддддеддддддеддддддеддддддеддддддедддддд╢ ');
WRITELN ('        Ё 21   Ё Vpp  Ё Vpp  Ё A11  Ё A12  Ё A11  Ё A11  Ё A11  Ё A11  Ё ');
WRITELN ('        цддддддеддддддеддддддеддддддеддддддеддддддеддддддеддддддедддддд╢ ');
WRITELN ('        Ё 24   Ё V+   Ё V+   Ё V+   Ё V+   Ё V+   Ё A13  Ё A13  Ё A13  Ё ');
WRITELN ('        Ё      Ё      Ё      Ё      Ё      Ё      Ё      Ё      Ё      Ё ');
WRITELN ('        юддддддаддддддаддддддаддддддаддддддаддддддаддддддаддддддадддддды ');

NextPage ;

TEXTCOLOR (White)  ;

END ;

