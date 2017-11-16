program TheProject(input, output);
{The project of incredible power:
 all graphics routines written entirely
 by Gordon Keiser!  They may not be
 transmitted, copied, or rebroadcast
 without the express written consent
 of Gordon Keiser}
const
     TransName = 'TRANSACT.DAT';
     MasterName  = 'MASTER.DAT';

     {mouse button constants}
     None = 0;
     Left = 1;
     Right = 2;
     Both = 3;
     Middle = 4;
     All = 7;

     {Operation Type Constants}
     Paycheck = 0;
     DeptCode = 1;
     PayRate = 2;

     {Current screen type}
     Editor   = 1;
     Transact = 2;
     Apply    = 3;
     HelpScr = 4;


{The types of incredible power!}
type
   MyStringType = array [1..8] of char;

   TextType = record
       Txt : array [0..64] of char;
       Len : integer
   end;

   MasterType = record
       ENum : longint;
       EName : TextType;
       DeptCode : longint;
       PayRate : longint
    end;

    TransactType = record
       ENum : longint;
       OpCode : integer;
       Valu : longint
    end;

var
   abuse : byte;
   Maj, Min : byte;
   MoreTemp, Button, Temp, Temp2, x, y : integer;
   HeckFreezesOver : Boolean;
   MyText : TextType;

   Trans : TransactType;
   Mastr : MasterType;

   DirInfo : integer;

   MasterOffset,
   TransOffset : integer;

   TransFile : File of TransactType;
   MasterFile : File of MasterType;

   ValForOp,
   OperationCode,
   EmployeeName,
   DepartmentCode,
   EmployeeNum : TextType;

   CurrentScreen,
   OpType : integer;

   tmp : char;
   MouseEnabled : Boolean;

   Cursor : array [1..33] of word;

procedure PrevEdRecord ; forward;
procedure NextTransRecord ; forward;

{Sets video mode to whatever}
procedure SetVidMode(mode : byte);
begin
     asm
        mov ah, 0
        mov al, BYTE PTR [mode]
        int 10h
     end
end;

{This hides the mouse}
procedure HideMouse;
begin
     asm
     mov ax, 02h
     int 33h
     end
end;

{Shows the mouse cursor}
procedure ShowMouse;
begin
     asm
     mov ax, 01h
     int 33h
     end
end;

{clears the screen in 80x25 text mode}
procedure ClearScreenText;
begin
     asm
     push es
     mov ax, 0B800h
     mov es, ax

     xor di, di
     mov cx, 1600
     mov al, ' '
     mov ah, 0Fh
     rep stosw

     pop es
     end
end;

{Fills screen with black}
procedure ClearScreen;
begin
     asm
        push es
        mov ax, 0A000h
        mov es, ax

        xor di, di
        mov cx, 32000
        mov ax, 0
        rep stosw

        pop es
     end
end;

{Fast Horizontal Line procedure for Windowing}
procedure HLine(x1, x2, y : integer; col : byte);

begin
     asm
        push es
        mov ax, 0A000h
        mov es, ax

        mov ax, WORD PTR [x1]
        mov di, ax
        mov cl, 6
        mov bx, WORD PTR [y]
        shl bx, cl
        mov cl, 8
        mov dx, WORD PTR [y]
        shl dx, cl
        add di, bx
        add di, dx
        mov bx, WORD PTR [x2]
        cmp ax, bx
        jb @@NoFlip
        xchg ax, bx
@@NoFlip:
        sub bx, ax
        mov cx, bx
        mov al, BYTE PTR [col]
        rep stosb

        pop es
        end
end;

procedure VLine(x, y1, y2 : integer; col : byte);
begin
     asm
     push es
     mov ax, 0A000h
     mov es, ax

     mov di, WORD PTR [x]
     mov ax, WORD PTR [y1]
     mov bx, ax
     mov cl, 6
     shl bx, cl
     mov dx, ax
     mov cl, 8
     shl dx, cl
     add di, bx
     add di, dx

     mov bx, WORD PTR [y2]
     cmp ax, bx
     jbe @@NoFlipV
     xchg ax, bx

@@NoFlipV:
     sub bx, ax
     mov cx, bx
     mov al, BYTE PTR [col]

@@VLineLoop:
     stosb
     add di, 319
     loop @@VLineLoop

     pop es
     end
end;

{Sets a single PIXEL}
procedure PSet(x, y : integer; col : byte);
begin
     asm
     push es

     mov ax, 0A000h
     mov es, ax

     mov di, WORD PTR [x]
     mov ax, WORD PTR [y]
     mov bx, ax
     mov cl, 6
     shl ax, cl
     mov cl, 8
     shl bx, cl
     add di, ax
     add di, bx

     mov al, BYTE PTR [col]
     stosb

     pop es
     end
end;

{Prints a character from the standard ascii set to the screen}
procedure PutChar(x, y : integer; chr : char; col : byte);
var
   buff : array [1..64] of byte;

begin
     asm
     push es
     mov ax, 0F000h
     mov es, ax

     mov si, 0FA6Eh
     mov al, BYTE PTR [chr]

     xor ah, ah
     mov cl, 3
     shl ax, cl
     add si, ax

     mov cx, 8
     mov al, BYTE PTR [col]
     lea di, [buff]

@@NextByte:
     push cx

     xor bl, bl
     mov bh, 80h

     mov cx, 8
@@NextBit:
     mov ah, BYTE PTR es:[si]
     and ah, bh
     cmp ah, 0
     je @@BlankSpace

     mov BYTE PTR [di], al
     jmp @@DontClear

@@BlankSpace:
     mov BYTE PTR [di], 0

@@DontClear:
     inc di
     shr bh, 1
     loop @@NextBit

     inc si
     pop cx
     loop @@NextByte

     {end of decoding section}

     lea si, [buff]
     mov di, WORD PTR [x]
     mov ax, WORD PTR [y]
     mov bx, WORD PTR [y]
     mov cl, 6
     shl ax, cl
     mov cl, 8
     shl bx, cl
     add di, ax
     add di, bx

     mov cx, 8
     mov ax, 0A000h
     mov es, ax

@@PutNextRow:
     push cx

     mov cx, 8
@@PutNextByte:
     mov al, BYTE PTR [si]
     cmp al, 0
     je @@NoPut
     mov BYTE PTR es:[di], al
@@NoPut:
     inc si
     inc di
     loop @@PutNextByte

     add di, 312
     pop cx
     loop @@PutNextRow

     pop es
     end
end;

{Read one character from the keyboard w/ no echo}
procedure GetCharNoEcho(var c : char);
var
   tc : char;
begin
     asm
        mov ah, 00h
        int 16h

        mov BYTE PTR [tc], al
     end;
     c := tc
end;

{Allows the user to enter a string of up to MAXLEN length at the coords}
procedure AllowTextEntry(x, y : integer; var Msg : TextType; MaxLen : integer);
var
   mx, my,
   idx : integer;
   chrr : char;
   fini : boolean;
begin
   idx := Msg.Len;
   mx := x + (8 * idx);
   my := y;
   HideMouse;
   fini := false;
   repeat
         GetCharNoEcho(chrr);
         if (ord(chrr) = 8) then
           begin
            if (idx > 0) then
               begin
                    Msg.Txt[idx] := Chr(0);
                    idx := idx - 1;
                    Msg.Len := Msg.Len - 1;
                    mx := mx - 8;
                    PutChar(mx, my, Msg.Txt[idx], $F);
                    Msg.Txt[idx] := Chr(0);
               end
           end
         else if (ord(chrr) = $D) or (ord(chrr) = $A) then
          fini := true
         else if (idx < MaxLen) then
          begin
            Msg.Txt[idx] := chrr;
            Msg.Len := Msg.Len + 1;
            PutChar(mx, my, chrr, $10);
            mx := mx + 8;
            idx := idx + 1
          end
   until (fini) or (idx > (MaxLen - 1));
   ShowMouse
end;

{Puts a string at (x, y) ((uses PutChar))}
procedure PutString(x, y : integer; s : MyStringType; col : byte);
var
   curx,
   idx : integer;
begin
     curx := x;
     for idx := 1 to 8 do
         begin
              PutChar(curx, y, s[idx], col);
              curx := curx + 8
         end
end;

{ rectangle from (x1, y1) to (x2, y2) }
procedure Rectangle(x1, y1, x2, y2 : integer; col : byte; filled : boolean);
var
   cury : integer;
begin
     if filled then
        for cury := y1 to y2 do
            HLine(x1, x2, cury, col)
     else
        begin
             HLine(x1, x2, y1, col);
             HLine(x1, x2, y2, col);
             VLine(x1, y1, y2, col);
             VLine(x2, y1, y2+1, col)
        end
end;

{Make some blues high in the palette for title bar}
procedure BluePalette;
var
   idx,
   r, g, b : byte;

begin
     r := 0;
     g := 0;
     b := 63;
     for idx := 0 to 63 do
      begin
           asm
              mov dx, 03C6h
              mov al, 0FFh
              out dx, al

              mov dx, 03C8h
              mov al, BYTE PTR [idx]
              add al, 128
              out dx, al

              mov dx, 03C9h
              mov al, BYTE PTR [r]
              out dx, al
              mov al, BYTE PTR [g]
              out dx, al
              mov al, BYTE PTR [b]
              out dx, al
           end;
           b := b - 1
      end
end;

{Creates a Text Box for user input}
procedure TextBox(x, y, xcols, ycols : integer);
var
   nxc, nyc : integer;
begin
     nxc := xcols * 8;
     nyc := ycols * 8;

     Rectangle(x, y, x + nxc, y + nyc, $F, TRUE);
     HLine(x - 1, x + nxc + 1, y - 1, $10);
     HLine(x - 2, x + nxc + 2, y - 2, $8);
     VLine(x - 1, y - 1, y + nyc + 1, $10);
     VLine(x - 2, y - 2, y + nyc + 3, $8);

     HLine(x - 1, x + nxc + 1, y + nyc + 1, $7);
     HLine(x - 1, x + nxc + 1, y + nyc + 2, $F);
     VLine(x + nxc, y - 1, y + nyc + 2, $7);
     VLine(x + nxc+1, y - 1, y + nyc + 3, $F)
end;



procedure PutButton(x1, y1, x2, y2 : integer; s : MyStringType; Pressed : boolean);
var
   midx, midy : integer;
begin
     HideMouse;
     midx := ((x1 + x2) div 2) - (8 * 4) ;
     midy := ((y1 + y2) div 2) - 2;
     if Pressed then
      begin
           Rectangle(x1, y1, x2, y2, $8, TRUE);
           HLine(x1, x2, y1, $10);
           HLine(x1+1, x2-1, y1 + 1, $10);
           HLine(x1, x2+1, y2, $F);
           HLine(x1+1, x2, y2 - 1, $F);

           VLine(x1, y1, y2, $10);
           VLine(x1 + 1, y1 + 1, y2 - 1, $10);
           VLine(x2, y1, y2, $F);
           VLine(x2 - 1, y1 + 1, y2 - 1, $F);
           PutString(midx, midy, s, $10)
      end
     else
      begin
           Rectangle(x1, y1, x2, y2, $7, TRUE);
           HLine(x1, x2, y1, $F);
           HLine(x1+1, x2-1, y1 + 1, $F);
           HLine(x1, x2+1, y2, $8);
           HLine(x1+1, x2, y2 - 1, $8);

           VLine(x1, y1, y2, $F);
           VLine(x1 + 1, y1 + 1, y2 - 1, $F);
           VLine(x2, y1, y2, $8);
           VLine(x2 - 1, y1 + 1, y2 - 1, $8);

           PutString(midx, midy, s, $10)
      end;
      ShowMouse
end;

{Makes one of those fun little [X] buttons for a window}
procedure ExitButton(x, y : integer; Pressed : boolean);
begin
     HideMouse;
     if Pressed then
      begin
           Rectangle(x, y, x + 10, y + 9, $8, TRUE);
           HLine(x, x + 10, y, $10);
           HLine(x, x + 11, y + 9, $F);
           VLine(x, y, y + 9, $10);
           VLine(x + 10, y, y + 9, $F);
           PutChar(x + 2 , y + 1 , 'x', $10)
      end
     else
      begin
           Rectangle(x, y, x + 10, y + 9, $7, TRUE);
           HLine(x, x + 10, y, $F);
           HLine(x, x + 11, y + 9, $8);
           VLine(x, y, y + 9, $F);
           VLine(x + 10, y, y + 9, $8);
           PutChar(x + 2 , y + 1 , 'x', $10)
      end;
      ShowMouse
end;

{Shows help}
procedure HelpWindow;
var
   AString : array [1..32] of char;
   idx : integer;
   mx : integer;
   my : integer;

begin
     CurrentScreen := HelpScr;

     HideMouse;
     Rectangle(8, 16, 220, 195, $7, TRUE);
     PutString(16, 32, 'This pro', $10);
     PutString(80, 32, 'gram is ', $10);
     PutString(144, 32, 'very sim', $10);
     PutString(16, 41, 'ple and ', $10);
     PutString(80, 41, 'easy to ', $10);
     PutString(144, 41, 'use, but', $10);
     PutString(16, 50, 'if you s', $10);
     PutString(80, 50, 'till hav', $10);
     PutString(144, 50, 'e proble', $10);
     PutString(16, 59, 'ms, here', $10);
     PutString(80, 59, 'goes... ', $10);
     PutString(144, 59, 'All chan', $10);
     PutString(16, 68, 'ges to t', $10);
     PutString(80, 68, 'he data ', $10);
     PutString(144, 68, 'files ca', $10);
     PutString(16, 77, 'n be don', $10);
     PutString(80, 77, 'e by cli', $10);
     PutString(144, 77, 'cking th', $10);
     PutString(16, 86, 'e button', $10);
     PutString(80, 86, 'that mat', $10);
     PutString(144, 86, 'ches wha', $10);
     PutString(16, 95, 't you wa', $10);
     PutString(80, 95, 'nt to ed', $10);
     PutString(144, 95, 'it. Afte', $10);
     PutString(16, 104, 'r you ha', $10);
     PutString(80, 104, 've the u', $10);
     PutString(144, 104, 'ser and ', $10);
     PutString(16, 113, 'transact', $10);
     PutString(80, 113, ' data ed', $10);
     PutString(144, 113, 'ited to ', $10);
     PutString(16, 122, 'your app', $10);
     PutString(80, 122, 'roval, c', $10);
     PutString(144, 122, 'lick the', $10);
     PutString(16, 131, 'APPLY bu', $10);
     PutString(80, 131, 'tton to ', $10);
     PutString(144, 131, 'apply tr', $10);
     PutString(16, 140, 'ansact t', $10);
     PutString(80, 140, 'o the us', $10);
     PutString(144, 140, 'er info.', $10);
     PutString(16, 149, 'If you d', $10);
     PutString(80, 149, 'o not ha', $10);
     PutString(144, 149, 've a mou', $10);
     PutString(16, 158, 'se, use ', $10);
     PutString(80, 158, 'the shor', $10);
     PutString(144, 158, 'tcut key', $10);
     PutString(16, 167, 'in paren', $10);
     PutString(80, 167, 'thesis o', $10);
     PutString(144, 167, 'r the fi', $10);
     PutString(16, 175, 'rst lett', $10);
     PutString(80, 175, 'er of a ', $10);
     PutString(144, 175, 'command.', $10);


     ShowMouse
end;

{Applies the TRANSACT.DAT to the MASTER.DAT, reports any
 errors or unfound employee numbers}
procedure ApplyWindow;
var
   idx,
   CurErrLoc : integer;
   ca2,
   ca : MyStringType;
   s : string[8];
   Found : Boolean;

begin
     TransOffset := 0;
     MasterOffset := 0;

     CurrentScreen := Apply;

     Rectangle(8, 16, 220, 195, $7, TRUE);
     CurErrLoc := 16;
     PutString(16, CurErrLoc, 'Applying', $10);
     CurErrLoc := CurErrLoc + 9;

     Seek(TransFile, 0);
     Seek(MasterFile, 0);
     if not (eof(TransFile) or eof(MasterFile)) then
     repeat
           Seek(TransFile, TransOffset);
           Read(TransFile, Trans);
           repeat
                 Seek(MasterFile, MasterOffset);
                 Read(MasterFile, Mastr);
                 if (Trans.Enum = Mastr.Enum) then
                  begin
{Funky Marker 1}       if (Trans.OpCode = PayCheck) then
                        begin
                            for idx := 1 to 8 do
                                ca[idx] := Mastr.EName.Txt[idx - 1];
                            PutString(16, CurErrLoc, ca, $10);
                            for idx := 1 to 8 do
                                ca[idx] := Mastr.EName.Txt[idx + 7];
                            PutString(80, CurErrLoc, ca, $10);
                            for idx := 1 to 8 do
                                ca[idx] := Mastr.EName.Txt[idx + 15];
                            PutString(144, CurErrLoc, ca, $10);
                            CurErrLoc := CurErrLoc + 9;
                            PutString(16, CurErrLoc, 'Shall be', $10);
                            PutString(88, CurErrLoc, 'paid    ', $10);

                            for idx := 1 to 8 do
                                s[idx] := ' ';
                            Str(Mastr.PayRate, s);
                            for idx := 1 to 8 do
                                ca2[idx] := s[idx];
                            ca2[8] := '$';

                            PutString(144, CurErrLoc, ca2, $10);

                            CurErrLoc := CurErrLoc + 9
                        end
                       else if (Trans.OpCode = DeptCode) then
                        begin
                             Mastr.DeptCode := Trans.Valu;
                             Write(MasterFile, Mastr)
                        end
                       else if (Trans.OpCode = PayRate) then
                        begin
                             Mastr.PayRate := Trans.Valu;
                             Write(MasterFile, Mastr)
                        end;
                        Found := TRUE
                  end
                 else
                     Found := FALSE;
                 MasterOffset := MasterOffset + 1
           until eof(MasterFile) or (Trans.Enum = Mastr.ENum);

           if not (Found) then
            begin
                 PutString(16, CurErrLoc, 'Unfound ', $10);
                 PutString(80, CurErrLoc, 'record f', $10);
                 PutString(144, CurErrLoc, 'ound!   ', $10);
                 CurErrLoc := CurErrLoc + 9
            end;
           MasterOffset := 0;
           TransOffset := TransOFfset + 1
     until eof(TransFile);
     PutString(16, CurErrLoc, 'DONE!   ', $10)
end;
{Draws the window for the transact procedure}
procedure TransactWindow;
var
   tcs : MyStringType;
   ts : string[8];
   idx : integer;

begin
     CurrentScreen := Transact;

     HideMouse;

     Rectangle(8, 16, 220, 195, $7, TRUE);
     PutString(16, 32, 'Employee', $10);
     PutString(88, 32, '(N)o.   ', $10);
     TextBox(128, 32, 8, 1);
     PutString(16, 64, '(V)alue ', $10);
     TextBox(128, 64, 8, 1);

     PutButton(16, 128, 32, 140, '   <    ', FALSE);
     PutButton(176, 128, 192, 140, '    >   ', FALSE);
     PutButton(64, 128, 152, 148, ' (S)ave ',FALSE);

     Trans.OpCode := DeptCode;
     PutButton(64, 78, 152, 90, 'Dept Num', TRUE);
     PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
     PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE);

     PutString(32, 156, 'Record #', $10);
     PutString(104, 156, '0       ',$10);

     if not eof(TransFile) then
      begin
        Seek(TransFile, TransOffset);
        Read(TransFile, trans);
        for idx := 1 to 8 do
            ts[idx] := Chr(0);
        Str(trans.ENum, ts);
        for idx := 1 to 8 do
            tcs[idx] := ts[idx];
        PutString(128, 33, tcs, $10)
      end;
     TransOffset := 1;
     NextTransRecord;

     ShowMouse
end;

procedure EditorWindow;
begin
     CurrentScreen := Editor;

     HideMouse;
     Rectangle(8, 16, 220, 195, $7, TRUE);

     PutString(16, 32, 'Employee', $10);
     PutString(88, 32, '(N)o.   ', $10);
     TextBox(128, 32, 8, 1);
     PutString(16, 48, 'Employee', $10);
     PutString(88, 48, 'Na(m)e  ', $10);
     TextBox(16, 64, 24, 1);
     PutString(16, 80, 'Dept. (C', $10);
     PutString(80, 80, ')ode    ', $10);
     TextBox(128, 80, 8, 1);
     PutString(16, 96, 'Pay (R)a', $10);
     PutString(80, 96, 'te      ', $10);
     TextBox(128, 96, 8, 1);

     PutButton(16, 128, 32, 140, '   <    ', FALSE);
     PutButton(176, 128, 192, 140, '    >   ', FALSE);
     PutButton(64, 128, 152, 148, ' (S)ave ',FALSE);

     PutString(32, 156, 'Record #', $10);
     PutString(104, 156, '0       ',$10);

     MasterOffset := 1;
     PrevEdRecord;

     ShowMouse
end;
{Draws the main window}
procedure MainWindow;
var
   colr : byte;
   counter,
   xloc : integer;

begin
     Rectangle(0, 0, 320, 200, $7, TRUE);
     colr := 0;
     counter := 0;

     for xloc := 4 to 315 do
      begin
           VLine(xloc, 4, 16, colr + 128);
           counter := counter + 1;
           if (counter = 5) then
            begin
              counter := 0;
              colr := colr + 1
            end
      end;

     PutString(24, 6, 'The Proj', $F);
     PutString(88, 6, 'ect!    ', $F);
     ExitButton(304, 5, FALSE);

     PutButton(220, 30, 300, 50, ' (H)elp ', FALSE);
     PutButton(220, 80, 300, 100,  '(E)ditor', FALSE);
     PutButton(220, 110, 300, 130, 'Transact', FALSE);
     PutButton(220, 140, 300, 160, '(A)pply ', FALSE);
     PutButton(220, 170, 300, 190, ' E(x)it ', FALSE);

     HLine(0, 320, 0, $F);
     HLine(1, 319, 1, $F);
     VLine(0, 0, 200, $F);
     VLine(1, 1, 199, $F);
     HLine(0, 320, 200, $8);
     HLine(1, 319, 199, $8);
     VLine(319, 0, 200, $8);
     VLine(318, 1, 199, $8);
end;

{Detects/Initializes the mouse.}
function MouseDetect : boolean;
var
   poit : integer;

begin
     asm
     mov ax, 0
     int 33h

     mov WORD PTR [poit], ax

     end;

     if (poit = 0) then
        MouseDetect := FALSE
     else
         MouseDetect := TRUE
end;



{Returns mouse X, Y, and the buttons pressed}
procedure PollMouse(var x, y, Button : integer);
var
   xt, yt, ButtonT : integer;

begin
     asm

     mov ax, 03h
     int 33h

     mov WORD PTR [xt], cx
     mov WORD PTR [yt], dx

     push bx
     and bx, 2
     jnz @@RightPressed

     pop bx
     and bx, 1
     jnz @@LeftPressed

@@RightPressed:
@@LeftPressed:
     mov WORD PTR [ButtonT], bx

     end;
     x := xt;
     y := yt;
     Button := ButtonT
end;

{Sets screen ranges for the mouse}
procedure SetMouseRanges;
begin
     asm
     mov ax, 7
     mov cx, 0
     mov dx, 640
     int 33h

     mov ax, 8
     mov cx, 0
     mov dx, 200
     int 33h

     end
end;

{Loads and prints previous record}
procedure PrevTransRecord;
var
   s : string[8];
   ca : MyStringType;
   idx : integer;

begin
     TransOffset := TransOffset + 1;
     Seek(Transfile, TransOffset);

     if not eof(transfile) then
      begin
          Read(Transfile, Trans);


     for idx := 1 to 8 do
         s[idx] := Chr(0);


     Str(TransOffset, s);
     for idx := 1 to 8 do
         ca[idx] := s[idx];

     Rectangle(104, 156, 192, 164, $7, TRUE);
     PutString(104, 156, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         EmployeeNum.Txt[idx-1] := Chr(0)
      end;
      EmployeeNum.Txt[8] := Chr(0);

     Str(Trans.ENum, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         EmployeeNum.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            EmployeeNum.Len := idx - 1;
            idx := 8
          end
      end;

     Rectangle(128, 32, 192, 40, $F, TRUE);
     PutString(128, 33, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         ValForOp.Txt[idx-1] := Chr(0)
      end;
      ValForOp.Txt[8] := Chr(0);

     Str(Trans.Valu, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         ValForOp.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            ValForOp.Len := idx - 1;
            idx := 8
          end
      end;

     Val(ValForOp.Txt, Trans.Valu, MoreTemp);
     Val(EmployeeNum.Txt, Trans.Enum, MoreTemp);
     Rectangle(128, 64, 192, 72, $F, TRUE);
     PutString(128, 65, ca, $10);

     if Trans.OpCode = DeptCode then
      begin
               PutButton(64, 78, 152, 90, 'Dept Num', TRUE);
               PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE)
      end
     else if Trans.OpCode = PayCheck then
      begin
               PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
               PutButton(64, 92, 152, 104, 'Paycheck', TRUE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE)
      end
     else if Trans.OpCode = PayRate then
      begin
               PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
               PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', TRUE)

      end;

     end
     else
      begin
           for idx := 1 to 8 do
               s[idx] := Chr(0);

           for idx := 0 to 8 do
            begin
               EmployeeNum.Txt[idx] := Chr(0);
               ValForOp.Txt[idx] := Chr(0)
            end;

           EmployeeNum.Len := 0;
           ValForOp.Len := 0;



           Str(TransOffset, s);
           for idx := 1 to 8 do
               ca[idx] := s[idx];

           Rectangle(104, 156, 192, 164, $7, TRUE);
           PutString(104, 156, ca, $10);

           Rectangle(128, 64, 192, 72, $F, TRUE);
           Rectangle(128, 32, 192, 40, $F, TRUE)
      end
end;

{Loads and prints previous record}
procedure PrevEdRecord;
var
   s : string[8];
   ca : MyStringType;
   idx : integer;
begin
     if (MasterOffset > 0) then
        MasterOffset := MasterOffset - 1;

     Seek(Masterfile, MasterOffset);

     if (not eof(MasterFile)) then
      begin
          Read(Masterfile, Mastr);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         EmployeeNum.Txt[idx-1] := Chr(0)
      end;
     EmployeeNum.Txt[8] := Chr(0);

     Str(Mastr.ENum, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         EmployeeNum.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            EmployeeNum.Len := idx - 1;
            break
          end
      end;

     Rectangle(128, 32, 192, 40, $F, TRUE);
     PutString(128, 33, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         ValForOp.Txt[idx-1] := Chr(0);
         DepartmentCode.Txt[idx-1] := Chr(0)
      end;
      ValForOp.Txt[8] := Chr(0);
      DepartmentCode.Txt[8] := Chr(0);

     Str(Mastr.PayRate, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         ValForOp.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            ValForOp.Len := idx - 1;
            idx := 8
          end
      end;

     Val(ValForOp.Txt, Mastr.PayRate, MoreTemp);
     Val(EmployeeNum.Txt, Mastr.ENum, MoreTemp);


     Rectangle(128, 96, 192, 104, $F, TRUE);
     PutString(128, 97, ca, $10);

     for idx := 0 to 24 do
         EmployeeName.Txt[idx] := Mastr.EName.Txt[idx];
     EmployeeName.Len := Mastr.EName.Len;

     Rectangle(16, 64, 208, 72, $F, TRUE);
     for idx := 1 to 8 do
         ca[idx] := Mastr.EName.Txt[idx - 1];
     PutString(16, 65, ca, $10);
     for idx := 9 to 16 do
         ca[idx-8] := Mastr.EName.Txt[idx - 1];
     PutString(80, 65, ca, $10);
     for idx := 17 to 25 do
         ca[idx - 16] := Mastr.EName.Txt[idx - 1];
     PutString(144, 65, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         DepartmentCode.Txt[idx-1] := Chr(0)
      end;
     DepartmentCode.Txt[8] := Chr(0);

     Str(Mastr.DeptCode, s);

          for idx := 1 to 8 do
              begin
                   ca[idx] := s[idx];
                   DepartmentCode.Txt[idx-1] := s[idx];
              if (s[idx] = Chr(0)) then
                 begin
                      DepartmentCode.Len := idx - 1;
                      idx := 8
                 end
              end;

          Rectangle(128, 80, 192, 88, $F, TRUE);
          PutString(128, 81, ca, $10);


    end
   else

    begin
         ValForOp.Len := 0;
         EmployeeNum.Len := 0;
         DepartmentCode.Len := 0;
         EmployeeName.Len := 0;

     for idx := 0 to 8 do
      begin
           EmployeeNum.Txt[idx] := Chr(0);
           ValForOp.Txt[idx] := Chr(0);
           DepartmentCode.Txt[idx] := Chr(0)
      end

    end;
     for idx := 1 to 8 do
         s[idx] := Chr(0);
     Str(MasterOffset, s);
     for idx := 1 to 8 do
         ca[idx] := s[idx];
     Rectangle(104, 156, 192, 164, $7, TRUE);
     PutString(104, 156, ca, $10)

end;

{Loads and prints next record}
procedure NextTransRecord;
var
   s : string[8];
   ca : MyStringType;
   idx : integer;
begin
     if (TransOffset > 0) then
        TransOffset := TransOffset - 1;

     Seek(Transfile, TransOffset);

     if (not eof(TransFile)) then
      begin
          Read(Transfile, Trans);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         EmployeeNum.Txt[idx-1] := Chr(0)
      end;
     EmployeeNum.Txt[8] := Chr(0);

     Str(Trans.ENum, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         EmployeeNum.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            EmployeeNum.Len := idx - 1;
            break
          end
      end;

     Rectangle(128, 32, 192, 40, $F, TRUE);
     PutString(128, 33, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         ValForOp.Txt[idx-1] := Chr(0)
      end;
      ValForOp.Txt[8] := Chr(0);

     Str(Trans.Valu, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         ValForOp.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            ValForOp.Len := idx - 1;
            idx := 8
          end
      end;

     Val(ValForOp.Txt, Trans.Valu, MoreTemp);
     Val(EmployeeNum.Txt, Trans.Enum, MoreTemp);

     Rectangle(128, 64, 192, 72, $F, TRUE);
     PutString(128, 65, ca, $10);

     if Trans.OpCode = DeptCode then
      begin
               PutButton(64, 78, 152, 90, 'Dept Num', TRUE);
               PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE)
      end
     else if Trans.OpCode = PayCheck then
      begin
               PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
               PutButton(64, 92, 152, 104, 'Paycheck', TRUE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE)
      end
     else if Trans.OpCode = PayRate then
      begin
               PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
               PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', TRUE)

      end;


    end
   else
    begin
         ValForOp.Len := 0;
         EmployeeNum.Len := 0;

     for idx := 0 to 8 do
      begin
           EmployeeNum.Txt[idx] := Chr(0);
           ValForOp.Txt[idx] := Chr(0)
      end

    end;
     for idx := 1 to 8 do
         s[idx] := Chr(0);
     Str(TransOffset, s);
     for idx := 1 to 8 do
         ca[idx] := s[idx];
     Rectangle(104, 156, 192, 164, $7, TRUE);
     PutString(104, 156, ca, $10)

end;

{Loads and prints next record}
procedure NextEdRecord;
var
   s : string[8];
   ca : MyStringType;
   idx : integer;

begin
     MasterOffset := MasterOffset + 1;
     Seek(Masterfile, MasterOffset);

     if not eof(Masterfile) then
      begin
          Read(Masterfile, Mastr);


          for idx := 1 to 8 do
              s[idx] := Chr(0);


          Str(MasterOffset, s);
          for idx := 1 to 8 do
              ca[idx] := s[idx];

          Rectangle(104, 156, 192, 164, $7, TRUE);
          PutString(104, 156, ca, $10);

          for idx := 1 to 8 do
              begin
                   s[idx] := Chr(0);
                   ca[idx] := Chr(0);
                   EmployeeNum.Txt[idx-1] := Chr(0)
              end;
          EmployeeNum.Txt[8] := Chr(0);

          Str(Mastr.ENum, s);

          for idx := 1 to 8 do
              begin
                   ca[idx] := s[idx];
                   EmployeeNum.Txt[idx-1] := s[idx];
              if (s[idx] = Chr(0)) then
                 begin
                      EmployeeNum.Len := idx - 1;
                      idx := 8
                 end
              end;

          Rectangle(128, 32, 192, 40, $F, TRUE);
          PutString(128, 33, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         ValForOp.Txt[idx-1] := Chr(0);
         DepartmentCode.Txt[idx-1] := Chr(0)
      end;
      ValForOp.Txt[8] := Chr(0);
      DepartmentCode.Txt[8] := Chr(0);

     Str(Mastr.PayRate, s);

     for idx := 1 to 8 do
      begin
         ca[idx] := s[idx];
         ValForOp.Txt[idx-1] := s[idx];
         if (s[idx] = Chr(0)) then
          begin
            ValForOp.Len := idx - 1;
            idx := 8
          end
      end;

     Val(ValForOp.Txt, Mastr.PayRate, MoreTemp);
     Val(EmployeeNum.Txt, Mastr.Enum, MoreTemp);

     Rectangle(128, 96, 192, 104, $F, TRUE);
     PutString(128, 97, ca, $10);

     for idx := 0 to 24 do
         EmployeeName.Txt[idx] := Mastr.EName.Txt[idx];
     EmployeeName.Len := Mastr.EName.Len;

     Rectangle(16, 64, 208, 72, $F, TRUE);
     for idx := 1 to 8 do
         ca[idx] := Mastr.EName.Txt[idx - 1];
     PutString(16, 65, ca, $10);
     for idx := 9 to 16 do
         ca[idx-8] := Mastr.EName.Txt[idx - 1];
     PutString(80, 65, ca, $10);
     for idx := 17 to 24 do
         ca[idx - 16] := Mastr.EName.Txt[idx - 1];
     PutString(144, 65, ca, $10);

     for idx := 1 to 8 do
      begin
         s[idx] := Chr(0);
         ca[idx] := Chr(0);
         DepartmentCode.Txt[idx-1] := Chr(0)
      end;
     DepartmentCode.Txt[8] := Chr(0);


     Str(Mastr.DeptCode, s);

          for idx := 1 to 8 do
              begin
                   ca[idx] := s[idx];
                   DepartmentCode.Txt[idx-1] := s[idx];
              if (s[idx] = Chr(0)) then
                 begin
                      DepartmentCode.Len := idx - 1;
                      idx := 8
                 end
              end;

          Rectangle(128, 80, 192, 88, $F, TRUE);
          PutString(128, 81, ca, $10);


     end
     else
      begin
           for idx := 1 to 8 do
               s[idx] := Chr(0);

           for idx := 0 to 8 do
            begin
               EmployeeNum.Txt[idx] := Chr(0);
               ValForOp.Txt[idx] := Chr(0);
               DepartmentCode.Txt[idx] := Chr(0)
            end;

           EmployeeNum.Len := 0;
           ValForOp.Len := 0;
           DepartmentCode.Len := 0;
           EmployeeName.Len := 0;


           Str(MasterOffset, s);
           for idx := 1 to 8 do
               ca[idx] := s[idx];

           for idx := 0 to 23 do
               EmployeeName.Txt[idx] := ' ';

           Rectangle(104, 156, 192, 164, $7, TRUE);
           PutString(104, 156, ca, $10);

           Rectangle(16, 64, 208, 72, $F, TRUE);
           Rectangle(128, 80, 192, 88, $F, TRUE);
           Rectangle(128, 96, 192, 104, $F, TRUE);
           Rectangle(128, 32, 192, 40, $F, TRUE)
      end

end;

{prints Mouse Information if installed}
procedure MouseInfo;
begin
     MouseEnabled := FALSE;
     if MouseDetect then
      begin
        WriteLn('Mouse driver detected.');
        MouseEnabled := TRUE;
        SetMouseRanges
      end
     else
        WriteLn('No mouse driver installed.')
end;

{Save current Trans record}
procedure SaveCurTrans;
var
   s : string[8];
   ca : MyStringType;
   idx : integer;
begin
     Seek(TransFile, TransOffset);

     Val(EmployeeNum.Txt, Trans.ENum, MoreTemp);
     Val(ValForOp.Txt, Trans.Valu, MoreTemp);

     if eof(TransFile) then
      begin
          Write(TransFile, Trans);
          TransOffset := TransOffset + 1;

          for idx := 1 to 8 do
              s[idx] := Chr(0);

          Str(TransOffset, s);
          for idx := 1 to 8 do
              ca[idx] := s[idx];
          Rectangle(104, 156, 192, 164, $7, TRUE);
          PutString(104, 156, ca, $10);

          Rectangle(128, 32, 192, 40, $F, TRUE);
          Rectangle(128, 64, 192, 72, $F, TRUE);
          for idx := 1 to 8 do
           begin
                EmployeeNum.Txt[idx] := Chr(0);
                ValForOp.Txt[idx] := Chr(0)
           end;
          EmployeeNum.Len := 0;
          ValForOp.Len := 0;
      end
     else
      begin
               Write(TransFile, Trans);
      for idx := 0 to 8 do
           begin
                EmployeeNum.Txt[idx] := Chr(0);
                ValForOp.Txt[idx] := Chr(0)
           end;

          Rectangle(128, 32, 192, 40, $F, TRUE);
          Rectangle(128, 64, 192, 72, $F, TRUE);

          EmployeeNum.Len := 0;
          ValForOp.Len := 0;
          PrevTransRecord
      end
end;

{Save current Master record}
procedure SaveCurMaster;
var
   s : string[8];
   ca : MyStringType;
   idx : integer;
begin
     Seek(MasterFile, MasterOffset);

     Val(EmployeeNum.Txt, Mastr.ENum, MoreTemp);
     Val(ValForOp.Txt, Mastr.PayRate, MoreTemp);
     Val(DepartmentCode.Txt, Mastr.DeptCode, MoreTemp);
     for idx := 0 to 23 do
         Mastr.EName.Txt[idx] := EmployeeName.Txt[idx];

     Mastr.EName.Len := EmployeeName.Len;

     if eof(MasterFile) then
      begin
          Write(MasterFile, Mastr);
          MasterOffset := MasterOffset + 1;

          for idx := 1 to 8 do
              s[idx] := Chr(0);

          Str(MasterOffset, s);
          for idx := 1 to 8 do
              ca[idx] := s[idx];
          Rectangle(104, 156, 192, 164, $7, TRUE);
          PutString(104, 156, ca, $10);

          Rectangle(128, 32, 192, 40, $F, TRUE);
          Rectangle(16, 64, 208, 72, $F, TRUE);
          Rectangle(128, 80, 192, 88, $F, TRUE);
          Rectangle(128, 96, 192, 104, $F, TRUE);

          for idx := 1 to 8 do
           begin
                EmployeeNum.Txt[idx] := Chr(0);
                ValForOp.Txt[idx] := Chr(0);
                DepartMentCode.Txt[idx] := Chr(0)
           end;
          EmployeeNum.Len := 0;
          ValForOp.Len := 0;
          DepartmentCode.Len := 0;
          EmployeeName.Len := 0
      end
     else
      begin
               Write(MasterFile, Mastr);
      for idx := 0 to 8 do
           begin
                EmployeeNum.Txt[idx] := Chr(0);
                ValForOp.Txt[idx] := Chr(0);
                DepartmentCode.Txt[idx] := Chr(0)
           end;

          Rectangle(128, 32, 192, 40, $F, TRUE);
          Rectangle(16, 64, 208, 72, $F, TRUE);

          EmployeeNum.Len := 0;
          ValForOp.Len := 0;
          DepartmentCode.Len := 0;
          EmployeeNum.Len := 0;

          NextEdRecord
      end

end;

{Handles all mouse input and returns values
 when an action is required}
 { Returns:
    1 - Exit Program
    2 - Exit Using other Button
    3 - Switch to Editor screen
    4 - Switch to Transaction screen
    5 - Apply TRANSACT.DAT to MASTER.DAT
    6 - Help
    7 - Next Record
    8 - Prev Record
    9 - SAVE Current crap
 }
{----------------------------------------------------------------------------}
function MouseLoop : integer;
var
   x, y : integer;
   Button : integer;
begin
     if MouseEnabled then
     begin
     PollMouse(x, y, Button);
     x := x div 2;

     if (x < 314) and (y < 14) and (x > 303) and (y > 3) and (Button = Left) then
        begin
             ExitButton(304, 5, TRUE);
             MouseLoop := 1
        end
     else if (x < 301) and (y > 140) and (x > 219) and (y < 160) and (Button = Left) then
       begin
             PutButton(220, 140, 300, 160, '(A)pply ', TRUE);
             MouseLoop := 5
       end
     else if (x < 301) and (y < 191) and (x > 219) and (y > 169) and (Button = Left) then
        begin
             PutButton(220, 170, 300, 190, ' E(x)it ', TRUE);
             MouseLoop := 2
        end
     else if (x < 301) and (y < 130) and (x > 219) and (y > 110) and (Button = Left) and (CurrentScreen <> Transact) then
        begin
             PutButton(220, 110, 300, 130, 'Transact', TRUE);
             MouseLoop := 4
        end
     else if (x < 301) and (y > 80) and (x > 219) and (y < 100) and (Button = Left) and (CurrentScreen <> Editor) then
       begin
             PutButton(220, 80, 300, 100, '(E)ditor', TRUE);
             MouseLoop := 3
       end

     else if (x < 301) and (y < 50) and (x > 219) and (y > 30) and (Button = Left) and (CurrentScreen <> HelpScr) then
        begin
             PutButton(220, 30, 300, 50, ' (H)elp ',TRUE);
             MouseLoop := 6
        end
     else
        MouseLoop := 0
     end;

     if (CurrentScreen = Transact) then
        if (x > 128) and (y > 32) and (x < 192) and (y < 40) and (Button = Left) then
           begin
                AllowTextEntry(128, 33, EmployeeNum, 8);
                Val(EmployeeNum.Txt, Trans.ENum, MoreTemp)
           end
        else if (x > 128) and (y > 64) and (x < 192) and (y < 72) and (Button = Left) then
           begin
                  AllowTextEntry(128, 65, ValForOp, 8);
                  Val(ValForOp.Txt, Trans.Valu, MoreTemp)
           end
        else if (x > 15) and (y > 128) and (x < 33) and (y < 140) and (Button = Left) then
           begin
                PutButton(16, 128, 32, 140, '   <    ', TRUE);
                NextTransRecord;
                MouseLoop := 7
           end
        else if (x > 175) and (y > 128) and (x < 192) and (y < 140) and (Button = Left) then
           begin
                PutButton(176, 128, 192, 140, '    >   ', TRUE);
                PrevTransRecord;
                MouseLoop := 8
           end
        else if (x > 64) and (y > 128) and (x < 152) and (y < 148) and (Button = Left) then
           begin
                PutButton(64, 128, 152, 148, ' (S)ave ', TRUE);
                SaveCurTrans;
                MouseLoop := 9
           end
{     PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
     PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
     PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE);}
        else if (x > 64) and (y > 78) and (x < 152) and (y < 90) and (Button = Left) then
           begin
               PutButton(64, 78, 152, 90, 'Dept Num', TRUE);
               PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE);
               Trans.OpCode := DeptCode
           end
        else if (x > 64) and (y > 92) and (x < 152) and (y < 104) and (Button = Left) then
           begin
               PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
               PutButton(64, 92, 152, 104, 'Paycheck', TRUE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE);
               Trans.OpCode := PayCheck
           end
        else if (x > 64) and (y > 106) and (x < 152) and (y < 118) and (Button = Left) then
           begin
               PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
               PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
               PutButton(64, 106, 152, 118, 'Pay(r)at', TRUE);
               Trans.OpCode := PayRate
           end;


     if (CurrentScreen = Editor) then
        if (x > 15) and (y > 128) and (x < 33) and (y < 140) and (Button = Left) then
           begin
                PutButton(16, 128, 32, 140, '   <    ', TRUE);
                PrevEdRecord;
                MouseLoop := 7
           end
        else if (x > 175) and (y > 128) and (x < 192) and (y < 140) and (Button = Left) then
           begin
                PutButton(176, 128, 192, 140, '    >   ', TRUE);
                NextEdRecord;
                MouseLoop := 8
           end
        else if (x > 64) and (y > 128) and (x < 152) and (x < 148) and (Button = Left) then
           begin
                PutButton(64, 128, 152, 148, ' (S)ave ', TRUE);
                SaveCurMaster;
                MouseLoop := 9
           end
        else if (x > 128) and (y > 32) and (x < 192) and (y < 40) and (Button = Left) then
           begin
                AllowTextEntry(128, 33, EmployeeNum, 8);
                Val(EmployeeNum.Txt, Trans.ENum, MoreTemp)
           end
        else if (x > 128) and (y > 80) and (x < 192) and (y < 88) and (Button = Left) then
             AllowTextEntry(128, 81, DepartmentCode, 8)
        else if (x > 128) and (y > 96) and (x < 192) and (y < 104) and (Button = Left) then
             AllowTextEntry(128, 97, ValForOp, 8)
        else if (x > 16) and (y > 64) and (x < 208) and (y < 72) and (Button = Left) then
             AllowTextEntry(16, 65, EmployeeName, 24);

     {if (CurrentScreen = Apply) then}

end;

{Similar returns to mouse function,
for non-mouse users}
function PollKbd : integer;
var
   chr : char;
begin
     asm
     mov ah, 01h
     int 16h

     jz @@NoKeys

     mov ah, 0
     int 16h

     mov BYTE PTR [chr], al
     jmp @@OverClearKey
@@NoKeys:
     mov BYTE PTR [chr], 0
@@OverClearKey:
     end;

     if (chr = 'X') or (chr = 'x') then
        PollKbd := 1
     else if (chr = 'e') or (chr = 'E') then
        PollKbd := 3
     else if (chr = 't') or (chr = 'T') then
        PollKbd := 4
     else if (chr = 'a') or (chr = 'A') then
        PollKbd := 5
     else if (chr = 'h') or (chr = 'H') then
        PollKbd := 6
     else if ((chr = 'v') or (chr = 'V')) and (CurrentScreen = Transact) then
        PollKbd := 7
     else if ((chr = 'n') or (chr = 'N')) and (CurrentScreen = Transact) then
       PollKbd := 8
     else if ((chr = 's') or (chr = 'S')) and (CurrentScreen = Transact) then
        SaveCurTrans
     else if ((chr = 's') or (chr = 'S')) and (CurrentScreen = Editor) then
        SaveCurMaster
     else if ((chr = 'd') or (chr = 'D')) and (CurrentScreen = TransAct) then
      begin
           PutButton(64, 78, 152, 90, 'Dept Num', TRUE);
           PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
           PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE);
           Trans.OpCode := DeptCode
      end
     else if ((chr = 'p') or (chr = 'P')) and (CurrentScreen = TransAct) then
      begin
           PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
           PutButton(64, 92, 152, 104, 'Paycheck', TRUE);
           PutButton(64, 106, 152, 118, 'Pay(r)at', FALSE);
           Trans.OpCode := PayCheck
      end
     else if ((chr = 'r') or (chr = 'R')) and (CurrentScreen = TransAct) then
      begin
           PutButton(64, 78, 152, 90, 'Dept Num', FALSE);
           PutButton(64, 92, 152, 104, 'Paycheck', FALSE);
           PutButton(64, 106, 152, 118, 'Pay(r)at', TRUE);
           Trans.OpCode := PayRate
      end
     else if ((chr = ',') or (chr = '<')) and (CurrentScreen = TransAct) then
      NextTransRecord
     else if ((chr = '>') or (chr = '.')) and (CurrentScreen = TransAct) then
      PrevTransRecord

     else if ((chr = ',') or (chr = '<')) and (CurrentScreen = Editor) then
      PrevEdRecord
     else if ((chr = '>') or (chr = '.')) and (CurrentScreen = Editor) then
      NextEdRecord
     else if ((chr = 'n') or (chr = 'N')) and (CurrentScreen = Editor) then
       AllowTextEntry(128, 33, EmployeeNum, 8)
     else if ((chr = 'c') or (chr = 'C')) and (CurrentScreen = Editor) then
       AllowTextEntry(128, 81, DepartmentCode, 8)
     else if ((chr = 'r') or (chr = 'R')) and (CurrentScreen = Editor) then
       AllowTextEntry(128, 97, ValForOp, 8)
     else if ((chr = 'm') or (chr = 'M')) and (CurrentScreen = Editor) then
       AllowTextEntry(16, 65, EmployeeName, 24)


     else
         PollKbd := 0
end;

{Anything before exiting, closes/saves files, cleans up the
 screen}
procedure PreExitStuff;
var
   tmp : char;
begin
     ClearScreen;

     PutString(95, 95, 'Thanks! ', $8);
     PutString(159, 95, ' BYE!!! ', $8);
     PutString(96, 96, 'Thanks! ', $7);
     PutString(160, 96, ' BYE!!! ', $7);

     GetCharNoEcho(tmp);
     SetVidMode(3);
     Close(TransFile);
     Close(MasterFile)
end;

{The main program loop - Handles nearly everything}
procedure MainProgLoop;
begin
     repeat
           Temp := MouseLoop;
           Temp2 := PollKbd
     until (Temp > 0) or (Temp2 > 0);

     if (Temp2 = 1) then
      begin
           PreExitStuff;
           Halt(0)
      end
     else if (Temp2 = 3) then
           EditorWindow
     else if (Temp2 = 4) then
           TransactWindow
     else if (Temp2 = 5) then
           ApplyWindow
     else if (Temp2 = 6) then
           HelpWindow
     else if (Temp2 = 7) then
        begin
            AllowTextEntry(128, 65, ValForOp, 8);
            Val(ValForOp.Txt, Trans.Valu, MoreTemp)
        end
     else if (Temp2 = 8) then
        begin
           AllowTextEntry(128, 33, EmployeeNum, 8);
           Val(EmployeeNum.Txt, Trans.ENum, MoreTemp)

        end
     else
      begin
      end;

     if (Temp = 1) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);

           ExitButton(304, 5, FALSE);
           PreExitStuff;
           Halt (0);
       end
     else if (Temp = 2) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);

           PutButton(220, 170, 300, 190, ' E(x)it ', FALSE);

           PreExitStuff;
           Halt (0);
      end
     else if (Temp = 3) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);

           PutButton(220, 80, 300, 100, '(E)ditor', FALSE);
           EditorWindow
      end
     else if (Temp = 4) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);

           PutButton(220, 110, 300, 130, 'Transact', FALSE);
           TransactWindow
      end
     else if (Temp = 5) then
      begin
          repeat
                PollMouse(x, y, Button)
          until (Button = None);

          PutButton(220, 140, 300, 160, '(A)pply ', FALSE);
          ApplyWindow
      end
     else if (Temp = 6) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);
           PutButton(220, 30, 300, 50, ' (H)elp ', FALSE);
           HelpWindow
      end
     else if (Temp = 7) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);
           PutButton(16, 128, 32, 140, '   <    ', FALSE)
      end
     else if (Temp = 8) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);
           PutButton(176, 128, 192, 140, '    >   ', FALSE)
      end
     else if (Temp = 9) then
      begin
           repeat
                 PollMouse(x, y, Button)
           until (Button = None);
           PutButton(64, 128, 152, 148, ' (S)ave ', FALSE)
      end
     else
      begin
      end
end;

{The title screen}
procedure TitleScreen;
var
   x, y : integer;
   col : byte;
   zagnut : char;
begin
   col := $10;
   y := 50;
   x := 0;
   repeat
         Rectangle(x, y, 320 - x, 200 - y, col, TRUE);
         x := x + 1;
         y := y + 1;
         col := col + 1
   until (x > 15);
   PutString(95, 79, '  The Pr', $8);
   PutString(159, 79, 'oject!  ', $8);
   PutString(96, 80, '  The Pr', $7);
   PutString(160, 80, 'oject!  ', $7);

   PutString(127, 95, '05/05/98', $8);
   PutString(128, 96, '05/05/98', $7);

   PutString(95, 111, 'By Gordo', $8);
   PutString(159, 111, 'n Keiser', $8);
   PutString(96, 112, 'By Gordo', $7);
   PutString(160, 112, 'n Keiser', $7);

   PutString(119, 177, 'Hit A Ke', $4);
   PutString(183, 177, 'y       ', $4);
   PutString(120, 178, 'Hit A Ke', $C);
   PutString(184, 178, 'y       ', $C);

   PutString(96, 32, '   Gnome', $5);
   PutString(160, 32, 'Toys    ', $5);

   GetCharNoEcho(zagnut);
end;

{proc 'Main' das meine Programme mšsste hab}
{This is just the main procedure which gets
 all the other BS accomplished.}
begin
     Assign(MasterFile, MasterName);
     Assign(TransFile, TransName);

     Reset(MasterFile);
     Rewrite(TransFile);

     TransOffset := 0;
     MasterOffset := 0;

     ClearScreenText;
     MouseInfo;

     SetVidMode($13);

     TitleScreen;

     CurrentScreen := None;

     Cursor[1] := $1FFF;           { 01000000 00000000 }
     Cursor[2] := $0FFF;           { 01100000 00000000 }
     Cursor[3] := $07FF;           { 01110000 00000000 }
     Cursor[4] := $03FF;           { 01111000 00000000 }
     Cursor[5] := $01FF;           { 01111100 00000000 }
     Cursor[6] := $00FF;           { 01111110 00000000 }
     Cursor[7] := $007F;           { 01111111 00000000 }
     Cursor[8] := $00FF;           { 01111110 00000000 }
     Cursor[9] := $01FF;           { 01111100 00000000 }
     Cursor[10] := $01FF;          { 01111100 00000000 }
     Cursor[11] := $01FF;          { 01111100 00000000 }
     Cursor[12] := $00FF;          { 01100110 00000000 }
     Cursor[13] := $10FF;          { 01000110 00000000 }
     Cursor[14] := $387F;          { 00000011 00000000 }
     Cursor[15] := $F87F;          { 00000011 00000000 }
     Cursor[16] := $FC7F;          { 00000001 10000000 }

     Cursor[17] := $4000;           { 01000000 00000000 }
     Cursor[18] := $6000;           { 01100000 00000000 }
     Cursor[19] := $7000;           { 01110000 00000000 }
     Cursor[20] := $7800;           { 01111000 00000000 }
     Cursor[21] := $7C00;           { 01111100 00000000 }
     Cursor[22] := $7E00;           { 01111110 00000000 }
     Cursor[23] := $7F00;           { 01111111 00000000 }
     Cursor[24] := $7E00;           { 01111110 00000000 }
     Cursor[25] := $7C00;           { 01111100 00000000 }
     Cursor[26] := $7C00;           { 01111100 00000000 }
     Cursor[27] := $7C00;           { 01111100 00000000 }
     Cursor[28] := $6600;           { 01100110 00000000 }
     Cursor[29] := $4600;           { 01000011 00000000 }
     Cursor[30] := $0300;           { 00000001 10000000 }
     Cursor[31] := $0300;           { 00000000 11000000 }
     Cursor[32] := $0000;           { 00000000 01100000 }
     Cursor[33] := $0000;

     BluePalette;
     MainWindow;

     asm
        push es
        push ds
        pop es

        mov ax, 12h
        mov bh, 1
        mov ch, 16
        mov bl, 0
        mov cl, 0
        lea dx, Cursor
        int 33h


        mov ax, 9
        mov bx, 0
        mov cx, 0
        lea dx, Cursor
        int 33h

        pop es
     end;

     ShowMouse;

     HeckFreezesOver := FALSE;

     repeat
               MainProgLoop
     until HeckFreezesOver;

     ClearScreen;
     SetVidMode(3);
end.
