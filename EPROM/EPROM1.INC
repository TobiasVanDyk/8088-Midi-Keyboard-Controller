{--------------------------------}
{ Initialise all records to zero }
{--------------------------------}
PROCEDURE ZeroRecords ;

VAR
    n , i : INTEGER ;
    NStr  : string[10] ;

BEGIN
    NStr := ' ' ;
    GOTOXY (2, (WHEREY) ) ; WRITE (' INITIALISING.......') ;

    FOR n := 1 TO MaxEprom DO
        BEGIN
          Eproms[4].IdData.Number := 'Clear' ;
          FOR i:=1 TO 5 DO Eproms[n].IdData.Equivalent[i] := NStr ;
          Eproms[n].IdData.Manufacturer := NStr ;
          Eproms[n].IdData.Date := NStr ;
          FOR i:=1 TO 5 DO Eproms[n].IdData.SubType[i] := NStr ;
          Eproms[n].IdData.Description := NStr ;

          Eproms[4].Size.Total := 65535 ;
          Eproms[n].Size.Pages := 0 ;
          Eproms[n].Size.PageSize := 0 ;

          Eproms[4].Pins.Total := 24 ;
          FOR i := 1 TO 32 DO Eproms[n].Pins.Name[i] := NStr ;

          Eproms[4].Prog.Voltage := 12.5 ;
          Eproms[4].Prog.Pulse.Duration := 50 ;
          Eproms[4].Prog.Pulse.Direction := 0 ;
          FOR i := 1 TO 32 DO Eproms[4].Prog.PinLevel[i] := 0 ;
          FOR i := 1 TO 5 DO Eproms[4].Prog.Seq[i] := 0 ;

          FOR i := 1 TO 32 DO Eproms[4].Verify.Pinlevel[i] := 0 ;
          FOR i := 1 TO 5 DO Eproms[4].Verify.Seq[i] := 0 ;

          FOR i := 1 TO 7 DO Eproms[4].Switches.Name[i] := ' ' ;
          FOR i := 1 TO 7 DO Eproms[4].Switches.Code[i] := ' ' ;
          FOR i := 1 TO 7 DO Eproms[4].Switches.Position[i] := ' ' ;
          FOR i := 1 TO 7 DO Eproms[4].Switches.Connect[i] := ' ' ;
        END ;
 END ;
{---------------------}
{ Write data to File  }
{---------------------}
PROCEDURE WriteEproms ;

VAR
    EpromFile : FILE OF EpromRecord ;
    i         : INTEGER             ;

BEGIN
    WITH Eproms[0] DO
         BEGIN
           RecKind   := Sys      ;
           NumEproms := EpromNum ;
         END ;
    ASSIGN  (EpromFile, FileName) ;
    REWRITE (EpromFile)          ;
    GOTOXY (2, (WHEREY) + 1 ) ;
    WRITE (' Writing ', EpromNum, ' Records...') ;
    FOR i := 0 TO EpromNum DO
                             WRITE (EpromFile, Eproms[i]) ;
                             CLOSE (EpromFile) ;
                           END ;
{--------------------}
{ Read Data from File}
{--------------------}
PROCEDURE ReadEproms ;

VAR
    EpromFile : FILE OF EpromRecord ;
    i         : INTEGER             ;

BEGIN
    ASSIGN (EpromFile, FileName) ;

{$I-}
    RESET (EpromFile) ;
{$I+}
    IF IORESULT <> 0 THEN
       BEGIN
         WRITELN (' New File....') ;
         EpromNum := 0
       END ELSE
       BEGIN
         READ (EpromFile, Eproms [0] ) ;
         EpromNum := Eproms[0].NumEproms ;
         GOTOXY ( 2, (WHEREY) + 1 ) ;
         WRITE (' Reading ', EpromNum, ' Records.....' ) ;
         FOR i := 1 TO EpromNum DO
                       READ ( EpromFile, Eproms[i] ) ;
                       CLOSE (EpromFile ) ;
                       END ;
      END ;
{---------------------------------------------}
{ Add new records      EditAdd = 0            }
{ Edit existing Record EditAdd = 1            }
{---------------------------------------------}
PROCEDURE AddRecords ( EditAdd : INTEGER ) ;

VAR
  FieldNum, RecNum, i : INTEGER ;

BEGIN

 FieldNum := 0 ;

 MakeWindow (1346,2,2,Yellow,Blue,1) ; { Display a window }
 CLRSCR ;
 TEXTBACKGROUND (cyan) ; WRITELN ;
 WRITE  ('                                                                ');
 GOTOXY (1,1) ; TEXTCOLOR (Black) ;
 WRITELN(NL,'            LIST OF EPROM DATA-RECORD FIELDS '                );
 TEXTBACKGROUND (blue) ; TEXTCOLOR (yellow) ;
 WRITELN('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
 WRITELN(' 1:Number                           17:Read set-up              ');
 WRITELN(' 2:Equivalents                      18:Read Sequence            ');
 WRITELN(' 3:Manufacturer                                                 ');
 WRITELN(' 4:Release Date                                                 ');
 WRITELN(' 5:SubTypes                                                     ');
 WRITELN(' 6:Description                                                  ');
 WRITELN(' 7:Total Size          bytes   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
 WRITELN(' 8:Pages Size                  ³ SWITCHES :                    ³');
 WRITELN(' 9:Page Number                 ³                               ³');
 WRITELN('10:Total Pins                  ³ 19:Name                       ³');
 WRITELN('11:Pin Description             ³ 20:Code                       ³');
 WRITELN('12:Program Voltage        Vpp  ³ 21:Pos. Code                  ³');
 WRITELN('13:Prog Pulse Width       mS   ³ 22:Pos. Name                  ³');
 WRITELN('14:Prog Pulse Level            ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ');
 WRITELN('15:Prog level Setup                                             ');
 WRITELN('16:Prog Sequence                                                ');
 WRITELN('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
 TEXTCOLOR (Black) ; TEXTBACKGROUND (Cyan) ;

 WRITE (#13) ; CLREOL ;
 WRITE ('   Enter (new) record number to edit [0 Quit] : ') ;
 READLN (RecNum) ; IF RecNum = 0 THEN EXIT  ;
 EpromInfoRead := 0                         ; { Reset so next time = read }

 IF EpromNum <= RecNum THEN 
 BEGIN
   EpromNum := RecNum ; { Add 1 to record number }
 END ;
 IF Eproms [RecNum].Pins.Total = 0 THEN Eproms [RecNum].Pins.Total := 1 ;
 IF EpromNum = MaxEprom THEN WRITE ( 'Records all filled..' )
    ELSE REPEAT
         WITH Eproms [RecNum] DO
         BEGIN
               GOTOXY (17,4) ;
               IF FieldNum<>1 THEN WRITE (IdData.Number:5)
                  ELSE BEGIN WRITE ('     ') ; GOTOXY (17,4) ;
                             READLN (IdData.Number) ; END    ;
               GOTOXY (17,5) ;
               IF FieldNum<>2 THEN WRITE (IdData.Equivalent[1]:10)
                  ELSE BEGIN WRITE ('          ') ; GOTOXY (17,5) ;
                             READLN (IdData.Equivalent[1]) ; END     ;
               GOTOXY (17,6) ;
               IF FieldNum<>3 THEN WRITE (IdData.Manufacturer)
                  ELSE BEGIN WRITE ('                    ') ; GOTOXY (17,6);
                             READLN (IdData.Manufacturer)   ; END          ;
               GOTOXY (17,7) ;
               IF FieldNum<>4 THEN WRITE (IdData.Date:10)
                  ELSE BEGIN WRITE ('          ') ; GOTOXY (17,7) ;
                             READLN (IdData.Date) ; END           ;
               GOTOXY (17,8) ;
               IF FieldNum<>5 THEN WRITE (IdData.SubType[1]:11)
                  ELSE BEGIN WRITE ('           ') ; GOTOXY (17,8) ;
                             READLN (IdData.SubType[1]) ; END     ;
               GOTOXY (28,8) ;
               IF FieldNum<>5 THEN WRITE (IdData.SubType[2]:10)
                  ELSE BEGIN WRITE ('          ') ; GOTOXY (28,8) ;
                             READLN (IdData.SubType[2]) ; END     ;
               GOTOXY (17,9) ;
               IF FieldNum<>6 THEN WRITE (IdData.Description)
                  ELSE BEGIN WRITE ('                                     ');
                             GOTOXY (17,9); READLN (IdData.Description); END;
               {$I-}
               GOTOXY (17,10) ;
               IF FieldNum<>7 THEN WRITE (Size.Total:6)
                  ELSE BEGIN WRITE ('      ') ; GOTOXY (17,10) ;
                             READLN (Size.Total) ;
                             IF (IORESULT<>0) OR (Size.Total>65535) THEN
                             Size.Total := 0 ; END         ;

               GOTOXY (17,11);
               IF FieldNum<>8 THEN WRITE (Size.PageSize:6)
                  ELSE BEGIN WRITE ('      ') ; GOTOXY (17,11) ;
                             READLN (Size.PageSize) ;
                             IF (IORESULT<>0) OR (Size.PageSize>65535) THEN
                             Size.PageSize := 0  ; END ;
               GOTOXY (17,12);
               IF FieldNum<>9 THEN WRITE (Size.Pages:2)
                  ELSE BEGIN WRITE ('  ') ; GOTOXY (17,12) ;
                             READLN (Size.Pages) ;
                             IF (IORESULT<>0) OR (Size.Pages>8) THEN
                             Size.Pages := 0    ; END ;
               GOTOXY (20,13);
               IF FieldNum<>10 THEN WRITE (Pins.Total:3)
                  ELSE BEGIN WRITE ('   ') ; GOTOXY (21,13) ;
                             READLN (Pins.Total) ;
                             IF (IORESULT<>0) OR (Pins.Total>32) THEN
                             Pins.Total := 1 ; END ;
               {$I+}

               FOR i := 1 TO Pins.Total DO
                   BEGIN
                     GOTOXY (20,14);
                     IF FieldNum<>11 THEN WRITE (i,' ',Pins.Name[i]:7)
                     ELSE BEGIN WRITE (i,'          ') ; GOTOXY (23,14) ;
                                READLN (Pins.Name[i]) ; END     ;
                   END ;
               {$I-}
               GOTOXY (21,15);
               IF FieldNum<>12 THEN WRITE (Prog.Voltage:2:1)
                  ELSE BEGIN WRITE ('    ') ; GOTOXY (21,15) ;
                             READLN (Prog.Voltage) ;
                             IF (IORESULT<>0) OR (Prog.Voltage>25.0) THEN
                             Prog.Voltage := 0.0 ; END ;
               GOTOXY (21,16);
               IF FieldNum<>13 THEN WRITE (Prog.Pulse.Duration:3)
                  ELSE BEGIN WRITE ('   ') ; GOTOXY (21,16) ;
                             READLN (Prog.Pulse.Duration) ;
                             IF (IORESULT<>0)OR(Prog.Pulse.Duration>100) THEN
                             Prog.Pulse.Duration := 1 ; END ;
               GOTOXY (21,17);
               IF FieldNum<>14 THEN WRITE (Prog.Pulse.Direction:2)
                  ELSE BEGIN WRITE ('  ') ; GOTOXY (21,17) ;
                             READLN (Prog.Pulse.Direction) ;
                             IF (IORESULT<>0)OR(Prog.Pulse.Direction>1) THEN
                             Prog.Pulse.Direction := 0 ; END ;

               FOR i := 1 TO Pins.Total DO
                   BEGIN
                     GOTOXY (21,18);
                     IF FieldNum<>15 THEN WRITE (i,' ',Prog.Pinlevel[i]:2)
                     ELSE BEGIN WRITE (i,'     ') ; GOTOXY (24,18) ;
                                READLN (Prog.PinLevel[i]) ;
                             IF (IORESULT<>0)OR(Prog.PinLevel[i]>7) THEN
                             Prog.PinLevel[i] := 0 ; END ;
                    END ;

               GOTOXY (21,19);
               IF FieldNum<>16 THEN WRITE (Prog.Seq[1]:2)
                  ELSE BEGIN WRITE ('  ') ; GOTOXY (21,19) ;
                             READLN (Prog.Seq[1]) ;
                             IF (IORESULT<>0)OR(Prog.Seq[1]>1) THEN
                             Prog.Seq[1] := 0 ; END ;

               FOR i := 1 TO Pins.Total DO
                   BEGIN
                     GOTOXY (54,4) ;
                     IF FieldNum<>17 THEN WRITE (i,' ',Verify.PinLevel[i]:2)
                     ELSE BEGIN WRITE (i,'    ') ; GOTOXY (57,4) ;
                                READLN (Verify.PinLevel[i]) ;
                             IF (IORESULT<>0)OR(Verify.PinLevel[i]>5) THEN
                             Verify.PinLevel[i] := 0 ; END ;
                    END ;

               GOTOXY (54,5) ;
               IF FieldNum<>18 THEN WRITE (Verify.Seq[1]:2)
                  ELSE BEGIN WRITE ('  ') ; GOTOXY (54,5) ;
                             READLN (Verify.Seq[1]) ;
                             IF (IORESULT<>0)OR(Verify.Seq[1]>1) THEN
                             Verify.Seq[1] := 0 ; END ;

               FOR i := 1 TO 7 DO
                   BEGIN
                     GOTOXY (47,13);
                     If FieldNum<>19 THEN WRITE (i,' ',Switches.Name[i])
                     ELSE BEGIN WRITE (i,'         ') ; GOTOXY (49,13) ;
                                READLN (Switches.Name[i]) ; END ;
                   END ;

               FOR i := 1 TO 7 DO
                   BEGIN
                     GOTOXY (47,14);
                     IF FieldNum<>20 THEN WRITE (i,' ',Switches.Code[i]:2)
                     ELSE BEGIN WRITE (i,'    ') ; GOTOXY (49,14) ;
                                READLN (Switches.Code[i]) ;
                                Switches.Code[i] := UPCASE (Switches.Code[i]);
                                IF (IORESULT <> 0) OR
                                NOT ( Switches.Code[i] IN  ['A'..'G'] ) THEN
                                Switches.Code[i] := ' ' ;  END ;
                   END ;

               FOR i := 1 TO 7 DO
                   BEGIN
                     GOTOXY (47,15);
                     IF FieldNum<>21 THEN WRITE(i,' ',Switches.Position[i]:2)
                     ELSE BEGIN WRITE (i,'    ') ; GOTOXY (49,15) ;
                                READLN (Switches.Position[i]) ;
                                IF (IORESULT <> 0) OR NOT
                                ( Switches.Position[i] IN ['a'..'c','x'] )
                                THEN Switches.Position[i] := ' ' ; END ;
                   END ;
                   {$I+}

               FOR i := 1 TO 7 DO
                   BEGIN
                     GOTOXY (47,16);
                     IF FieldNum<>22 THEN WRITE(i,' ',Switches.Connect[i]:10)
                     ELSE BEGIN WRITE (i,'            ') ; GOTOXY (49,16) ;
                                READLN (Switches.Connect[i]) ; END ;
                   END ;

        END ; { With }

           IF EditAdd = 1 THEN
              BEGIN
                GOTOXY (1,21) ; CLREOL ;
                WRITE (' Fieldnumber to edit [ 1-22 ] [ 0 Quit ] : ');
                {$I-}
                READLN (FieldNum) ;
                {$I+}
                IF NOT ( FieldNum IN [ 0..22 ] ) THEN FieldNum := 1 ;
                IF IORESULT<>0 THEN FieldNum := 1                    ;
              END ;
           IF EditAdd = 0 THEN
              BEGIN
                FieldNum := FieldNum + 1 ;
                IF FieldNum > 22 THEN FieldNum := 0 ; { Exit }
              END ;

       UNTIL FieldNum = 0  ;
       TEXTBACKGROUND (Blue) ; TEXTCOLOR (Yellow) ;

END ;

