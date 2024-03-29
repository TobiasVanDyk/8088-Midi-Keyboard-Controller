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
WRITELN ('                旼컴컴컴컴컴컴� 旼컴컴컴컴컴컴커                    ');
WRITELN ('      Vpp A15  캑 1  (-2) 28P 읕�      (+2) 28 쳐  V+               ');
WRITELN ('          A12  캑 2  (-1)              (+1) 27 쳐  WElo PGM  A14    ');
WRITELN ('          A07  캑 3  (1)------� �------(24) 26 쳐  CShi V+   A13    ');
WRITELN ('          A06  캑 4  (2)  24P 읕�      (23) 25 쳐  A08              ');
WRITELN ('          A05  캑 5  (3)               (22) 24 쳐  A09              ');
WRITELN ('          A04  캑 6  (4)               (21) 23 쳐  A11  WElo A12 Vpp');
WRITELN ('          A03  캑 7  (5)               (20) 22 쳐  OElo PGM  Vpp V+ ');
WRITELN ('          A02  캑 8  (6)               (19) 21 쳐  A10              ');
WRITELN ('          A01  캑 9  (7)               (18) 20 쳐  CSlo PGM  GND    ');
WRITELN ('          A00  캑 10 (8)               (17) 19 쳐  D07              ');
WRITELN ('          D00  캑 11 (9)               (16) 18 쳐  D06              ');
WRITELN ('          D01  캑 12 (10)              (15) 17 쳐  D05              ');
WRITELN ('          D02  캑 13 (11)              (14) 16 쳐  D04              ');
WRITELN ('          GND  캑 14 (12)              (13) 15 쳐  D03              ');
WRITELN ('                읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸                    ');
WRITELN ;

NextPage ;

WRITELN (NL, NL, NL ) ;
WRITELN (' PAGE 2   SWITCHES : (Refer to 24 PIN numbers)                      ');
WRITELN ;
WRITELN ('    旼컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴쩡컴컴컴컴컴컴컴�');
WRITELN ('    �[D] PIN 26 (24)�[E] PIN 1 (-2) �[F] PIN 22 (20)�[G] PIN 23 (21)�');
WRITELN ('    �               �               �               �               �');
WRITELN ('    �   A13   V+    �   Vpp   A15   �  Read   Vpp   �   Vpp   A11   �');
WRITELN ('    �     �   �     �     �   �     �     �   �     �     �   �     �');
WRITELN ('    쳐컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴좔컴컴컫컴컴컴컴좔컴컴컴컴컴컴컴�');
WRITELN ('    �[A] PIN 27 (+1)�[B]  PIN 20 (18)      �[C]     Vpp             �');
WRITELN ('    �               �                      �                        �');
WRITELN ('    �  PGM   A14    �   PGM    V+   GND    �   12   21  25   VOLT   �');
WRITELN ('    �    �   �      �     �    �    �      �    �   �   �           �');
WRITELN ('    읕컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴컴컨컴컴컴컴컴컴컴컴컴컴컴컴�');
WRITELN ;

NextPage ;

WRITELN (NL, NL, NL ) ;
WRITELN ('        旼컴컴컫컴컴컴쩡컴컴컫컴컴컴쩡컴컴컫컴컴컴쩡컴컴컫컴컴컴쩡컴컴커 ');
WRITELN ('        � PIN  � 2716 � 2532 � 2732 � 2564 � 2764 � 27128� 27256� 27512� ');
WRITELN ('        쳐컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴캑 ');
WRITELN ('        � -2   � NC   � NC   � NC   � Vpp  � Vpp  � Vpp  � Vpp  � A15  � ');
WRITELN ('        쳐컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴캑 ');
WRITELN ('        � +1   � NC   � NC   � NC   �      � PGM  � PGM  � A14  � A14  � ');
WRITELN ('        �      �      �      �      �      � 커旼 � 커旼 �      �      � ');
WRITELN ('        �      �      �      �      �      �  잎  �  잎  �      �      � ');
WRITELN ('        쳐컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴캑 ');
WRITELN ('        � 20   � V+   쿛GM 왯� Vpp  쿛GM 왯� V+   � V+   � V+   � Vpp  � ');
WRITELN ('        �      �      쿝ead잎�      쿝ead잎�      �      �      �      � ');
WRITELN ('        쳐컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴캑 ');
WRITELN ('        � 18   � PGM  � GND  � PGM  � GND  � GND  � GND  � PGM  � PGM  � ');
WRITELN ('        �      �  悶  � V+   � 커旼 � V+   �      �      � 커旼 � 커旼 � ');
WRITELN ('        �      � 켸읕 �      �  잎  �      �      �      �  잎  �  잎  � ');
WRITELN ('        쳐컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴캑 ');
WRITELN ('        � 21   � Vpp  � Vpp  � A11  � A12  � A11  � A11  � A11  � A11  � ');
WRITELN ('        쳐컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴컵컴컴컴탠컴컴캑 ');
WRITELN ('        � 24   � V+   � V+   � V+   � V+   � V+   � A13  � A13  � A13  � ');
WRITELN ('        �      �      �      �      �      �      �      �      �      � ');
WRITELN ('        읕컴컴컨컴컴컴좔컴컴컨컴컴컴좔컴컴컨컴컴컴좔컴컴컨컴컴컴좔컴컴켸 ');

NextPage ;

TEXTCOLOR (White)  ;

END ;

