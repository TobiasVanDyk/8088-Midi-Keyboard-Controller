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
WRITELN ('                �������������Ŀ ��������������Ŀ                    ');
WRITELN ('      Vpp A15  Ĵ 1  (-2) 28P ���      (+2) 28 ��  V+               ');
WRITELN ('          A12  Ĵ 2  (-1)              (+1) 27 ��  WElo PGM  A14    ');
WRITELN ('          A07  Ĵ 3  (1)------� �------(24) 26 ��  CShi V+   A13    ');
WRITELN ('          A06  Ĵ 4  (2)  24P ���      (23) 25 ��  A08              ');
WRITELN ('          A05  Ĵ 5  (3)               (22) 24 ��  A09              ');
WRITELN ('          A04  Ĵ 6  (4)               (21) 23 ��  A11  WElo A12 Vpp');
WRITELN ('          A03  Ĵ 7  (5)               (20) 22 ��  OElo PGM  Vpp V+ ');
WRITELN ('          A02  Ĵ 8  (6)               (19) 21 ��  A10              ');
WRITELN ('          A01  Ĵ 9  (7)               (18) 20 ��  CSlo PGM  GND    ');
WRITELN ('          A00  Ĵ 10 (8)               (17) 19 ��  D07              ');
WRITELN ('          D00  Ĵ 11 (9)               (16) 18 ��  D06              ');
WRITELN ('          D01  Ĵ 12 (10)              (15) 17 ��  D05              ');
WRITELN ('          D02  Ĵ 13 (11)              (14) 16 ��  D04              ');
WRITELN ('          GND  Ĵ 14 (12)              (13) 15 ��  D03              ');
WRITELN ('                ��������������������������������                    ');
WRITELN ;

NextPage ;

WRITELN (NL, NL, NL ) ;
WRITELN (' PAGE 2   SWITCHES : (Refer to 24 PIN numbers)                      ');
WRITELN ;
WRITELN ('    ���������������������������������������������������������������Ŀ');
WRITELN ('    �[D] PIN 26 (24)�[E] PIN 1 (-2) �[F] PIN 22 (20)�[G] PIN 23 (21)�');
WRITELN ('    �               �               �               �               �');
WRITELN ('    �   A13   V+    �   Vpp   A15   �  Read   Vpp   �   Vpp   A11   �');
WRITELN ('    �     �   �     �     �   �     �     �   �     �     �   �     �');
WRITELN ('    ���������������������������������������������������������������Ĵ');
WRITELN ('    �[A] PIN 27 (+1)�[B]  PIN 20 (18)      �[C]     Vpp             �');
WRITELN ('    �               �                      �                        �');
WRITELN ('    �  PGM   A14    �   PGM    V+   GND    �   12   21  25   VOLT   �');
WRITELN ('    �    �   �      �     �    �    �      �    �   �   �           �');
WRITELN ('    �����������������������������������������������������������������');
WRITELN ;

NextPage ;

WRITELN (NL, NL, NL ) ;
WRITELN ('        ��������������������������������������������������������������Ŀ ');
WRITELN ('        � PIN  � 2716 � 2532 � 2732 � 2564 � 2764 � 27128� 27256� 27512� ');
WRITELN ('        ��������������������������������������������������������������Ĵ ');
WRITELN ('        � -2   � NC   � NC   � NC   � Vpp  � Vpp  � Vpp  � Vpp  � A15  � ');
WRITELN ('        ��������������������������������������������������������������Ĵ ');
WRITELN ('        � +1   � NC   � NC   � NC   �      � PGM  � PGM  � A14  � A14  � ');
WRITELN ('        �      �      �      �      �      � Ŀ�� � Ŀ�� �      �      � ');
WRITELN ('        �      �      �      �      �      �  ��  �  ��  �      �      � ');
WRITELN ('        ��������������������������������������������������������������Ĵ ');
WRITELN ('        � 20   � V+   �PGM �ڳ Vpp  �PGM �ڳ V+   � V+   � V+   � Vpp  � ');
WRITELN ('        �      �      �Read�ٳ      �Read�ٳ      �      �      �      � ');
WRITELN ('        ��������������������������������������������������������������Ĵ ');
WRITELN ('        � 18   � PGM  � GND  � PGM  � GND  � GND  � GND  � PGM  � PGM  � ');
WRITELN ('        �      �  ڿ  � V+   � Ŀ�� � V+   �      �      � Ŀ�� � Ŀ�� � ');
WRITELN ('        �      � ���� �      �  ��  �      �      �      �  ��  �  ��  � ');
WRITELN ('        ��������������������������������������������������������������Ĵ ');
WRITELN ('        � 21   � Vpp  � Vpp  � A11  � A12  � A11  � A11  � A11  � A11  � ');
WRITELN ('        ��������������������������������������������������������������Ĵ ');
WRITELN ('        � 24   � V+   � V+   � V+   � V+   � V+   � A13  � A13  � A13  � ');
WRITELN ('        �      �      �      �      �      �      �      �      �      � ');
WRITELN ('        ���������������������������������������������������������������� ');

NextPage ;

TEXTCOLOR (White)  ;

END ;

