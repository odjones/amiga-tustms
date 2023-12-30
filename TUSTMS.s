;
; It's here... The Ultimate SoundTracker Module Scanner! Coded on the 1st of May
; by Oliver D. Jones. Copyright © May 1994 by Funny Farm Software.
;
; Revisions:
;
; 8th May - Slight bug in the save routine removed (user can now press [Return]
;           at the prompt to abort saving)
;           A really nasty bug in the Continue Scanning option was removed. It
;           used to try to continue to scan past the 2MB barrier (causing a non-
;           recoverable crash in the process)
;           A cosmetic bug was removed in the Continue Scanning option. When no
;           more modules were found, the last found module's name should appear
;           as if nothing had happened. Instead, a lot of corrupted characters
;           appeared - causing much confusion!
;           All CLI and file Write routines optimised. Assembled code is now 130
;           bytes shorter.
;

          output    ram:TUSTMS          send finished object code to ram disk

          include   /system.gs          pre-assembled header

          include   libraries.mac       library macros
          include   files.mac           file macros

WriteStr  macro                         macro for writing strings
          move.l    \1Handle(pc),d1     ;
          move.l    \2,d2               ;
          move.l    \3,d3               ;
          bsr.w     _Write              ;
          endm                          ;

          OpenLib   DOS                 attempt to open the dos library
          bne.s     dos_ok              ;
          rts                           it didn't open, so quit to CLI

dos_ok    GetOutput CLI                 ask AmigaDOS for an output window

          WriteStr  CLI,#M0,#ML0        display the startup text

          moveq     #0,d7               we haven't found anything yet
restart   move.l    #1080,a3            search from address 1080 onwards
scan      bsr.w     search              do it...
          bne.w     failed              ;

          move.l    a3,a5               keep a copy of the identifier address
          sub.l     #1080,a5            find start address of module
          move.l    a5,a4               keep a copy of the module address
          moveq     #0,d6               current length of module title is zero
.title    cmp.b     #0,(a4)+            have we reached the end of the title?
          beq.s     .end                ;
          cmp.b     #20,d6              have we reached the 20-character limit?
          beq.s     .end                ;
          addq.l    #1,d6               add one to title length
          bra.s     .title              go back and get another character
.end      move.l    a3,a0               crude check to see if module is valid
          sub.l     #132,a0             ;
          tst.b     (a0)+               is encoded digit zero?
          bne.s     scan                ;
          cmp.b     #1,(a0)+            is encoded digit one?
          bne.s     scan                ;
          btst.b    #7,(a0)             is pattern data =<127?
          bne.s     scan                ;
          moveq     #1,d7               we have found a module

          moveq     #0,d5               find quantity and length of samples
          move.l    a5,a4               get start of module
          add.l     #20,a4              find start of sample data
          moveq     #32,d0              number of samples+1
          moveq     #0,d1               length of samples
addsample add.l     #22,a4              get address of sample length
          subq.l    #1,d0               ;
          beq.s     patterns            ;
          moveq     #0,d2               find length of sample
          move.b    (a4),d2             read and calculate high byte
          rol.w     #8,d2               ;
          addq.l    #1,a4               ;
          move.b    (a4),d2             read low byte
          rol.w     #1,d2               multiply by 2
          tst.l     d2                  is this sample empty?
          beq.s     empty               ;
          addq.l    #1,d5               we've found one more sample
          add.l     d2,d1               add to total
empty     addq.l    #7,a4               ;
          bra.s     addsample           get next sample length

patterns  moveq     #1,d4               find quantity and length of patterns
          move.l    a3,a4               calculate address of pattern data
          sub.l     #130,a4             ;
          move.b    (a4),d0             number of patterns
          move.b    d0,_Length          ;
          moveq     #0,d2               last pattern
          addq.l    #2,a4               get start address of pattern table
findmax   cmp.b     (a4),d2             is this pattern the biggest so far?
          bge.s     notmax              ;
          move.b    (a4),d2             yes - update 'last' pattern
notmax    addq.l    #1,a4               move onto next table entry
          subq.b    #1,d0               ;
          bne.s     findmax             ;
          add.l     d2,d4               ;
          rol.l     #8,d2               multiply by 256
          rol.l     #2,d2               multiply by 4
          add.l     d1,d2               add sample length to pattern length
          add.l     #2108,d2            add header data to total
          move.l    d2,d3               preserve total length

          move.l    a3,_Identity        preserve our new-found statistics
          move.l    d3,_FSize           ;
          move.b    d4,_Patterns        ;
          move.b    d5,_Samples         ;
          move.b    d6,_FNSize          ;

showname  WriteStr  CLI,#M2,#ML2        display module name header
          move.b    _FNSize(pc),d6      is module untitled?
          bne.s     named               ;
          WriteStr  CLI,#M3,#ML3        substitute 'Untitled' for module name
          bra.s     menu                ;
named     WriteStr  CLI,a5,d6           display module name

menu      WriteStr  CLI,#M4,#ML4        show menu on screen

getinput  WaitChar  CLI,#1              wait until the user enters something
          beq.s     getinput            ;

readagain Read      CLI,#_String,#1     get a character
          cmp.b     #10,_String         has the user just pressed [Return]?
          bne.s     valid               ;
          WriteStr  CLI,#CRS,#1         write a carriage return
          bra.w     showname            ;
valid     or.b      #32,_String         make it lowercase

flush     Read      CLI,#_String+1,#1   flush input buffer
          cmp.b     #10,_String+1       ;
          bne.s     flush               ;

          move.b    _String(pc),d0      decide what the user entered

          cmp.b     #'c',d0             is it to continue scanning?
          beq.w     cntscan             ;
          cmp.b     #'r',d0             is it to restart scanning?
          beq.w     resscan             ;
          cmp.b     #'v',d0             is it to view the statistics?
          beq.w     viewstats           ;
          cmp.b     #'e',d0             is it to edit the module length?
          beq.w     edmodlen            ;
          cmp.b     #'s',d0             is it to save the module?
          beq.w     savemod             ;
          cmp.b     #'q',d0             is it to quit?
          beq.w     quit                ;

          WriteStr  CLI,#CRS,#1         write a carriage return
          bra.w     showname            user made a mistake, so show menu again

failed    tst.l     d7                  have we actually found anything yet?
          bne.s     modules             ;
          WriteStr  CLI,#E0,#EL0        tell user that there are no modules in
          WriteStr  CLI,#E2,#EL2        memory

finished  CloseLib  DOS                 close the dos library

          moveq     #0,d0               quit to CLI
          rts                           ;

modules   move.l    _Identity(pc),a3    restore identifier of last module
          move.l    a3,a5               ;
          sub.l     #1080,a5            re-calculate name address of last module
          WriteStr  CLI,#E3,#EL3        tell user that there are no more modules
          bra.w     showname            in memory

          Library   DOS                 define the dos library

          File      CLI                 define the output window handle
          File      _String             define the save file handle

          LibName   DOS,DOSNAME         define the name of the dos library

cntscan   WriteStr  CLI,#M1,#ML1        tell user we are searching
          bra.w     scan                ;
resscan   WriteStr  CLI,#M1,#ML1        tell user we are searching
          bra.w     restart             ;

edmodlen  WriteStr  CLI,#M10,#ML10      allow user to edit module length by hand
          Read      CLI,#_String,#11    read in input from keyboard
          cmp.l     #11,d0              check to see if there is a CR on the end
          bne.s     for_sure            ;
          cmp.b     #10,_String+10      ;
          beq.s     for_sure            ;
          WriteStr  CLI,#E4,#EL4        tell user of length limit
numflush  WaitChar  CLI,#1              flush the keyboard buffer
          beq.s     nochars             ;
          Read      CLI,#_String,#1     ;
          cmp.b     #10,_String         ;
          bne.s     numflush            ;
nochars   bra.w     showname            ;
for_sure  subq.l    #1,d0               there is definately a cr in there
          beq.s     abort               ;
          lea       _String(pc),a1      convert the string to a number
          move.l    d0,d1               ;
          bsr.w     DStrToNum           ;
          tst.l     d0                  is it an illegal number?
          beq.s     num_ok              ;
          WriteStr  CLI,#E5,#EL5        ask the user what (s)he is playing at?
          bra.s     numflush            ;
num_ok    move.l    d1,_FSize           change the file size
          bra.w     viewstats           show the user the new statistics
abort     WriteStr  CLI,#CRS,#1         write a carriage return
          bra.w     showname            ;

savemod   WriteStr  CLI,#M11,#ML11      save the current module
          Read      CLI,#_String,#26    get user input
          cmp.l     #1,d0               has the user entered anything?
          bne.s     sname_ok            ;
          WriteStr  CLI,#CRS,#1         write a carriage return
          bra.w     showname            ;
sname_ok  cmp.l     #26,d0              check to see if there is a CR on the end
          bne.s     save                ;
          cmp.b     #10,_String+25      ;
          beq.s     save                ;
          WriteStr  CLI,#E6,#EL6        inform user that filename is too long
          bra.w     numflush            ;
save      lea       _String(pc),a1      zero-terminate the filename
          subq.l    #1,d0               ;
          add.l     d0,a1               ;
          move.b    #0,(a1)             ;
          Open      _String,NEWFILE     attempt to open a file
          beq.w     save_err            ;
          WriteStr  CLI,#M12,#ML12      tell user we are saving module...
          WriteStr  _String,a5,_FSize   save module...
          move.l    d0,-(sp)            ;
          Close     _String             close file
          WriteStr  CLI,#E8,#EL8        tell user how much we saved
          move.l    (sp)+,d1            ;
          lea       _String(pc),a1      ;
          bsr.w     DNumToStr           ;
          lea       _String(pc),a1      ;
          bsr.w     chopstr             ;
          WriteStr  CLI,a1,d0           ;
          WriteStr  CLI,#E9,#EL9        ;
          bra.w     showname            ;
save_err  WriteStr  CLI,#E7,#EL7        tell user there was an error
          bra.w     showname            ;

viewstats WriteStr  CLI,#M5,#ML5        display the module statistics
          lea       _String(pc),a1      convert file size
          move.l    _FSize(pc),d1       ;
          bsr.w     DNumToStr           ;
          lea       _String(pc),a1      chop off excess zeros
          bsr.w     chopstr             ;
          WriteStr  CLI,a1,d0           display the value
          WriteStr  CLI,#M6,#ML6        ;
          lea       _String(pc),a1      convert length of module
          moveq     #0,d1               ;
          move.b    _Length(pc),d1      ;
          bsr.w     DNumToStr           ;
          lea       _String(pc),a1      chop off excess zeros
          bsr.w     chopstr             ;
          WriteStr  CLI,a1,d0           display the value
          WriteStr  CLI,#M7,#ML7        ;
          lea       _String(pc),a1      convert patterns
          moveq     #0,d1               ;
          move.b    _Patterns(pc),d1    ;
          bsr.w     DNumToStr           ;
          lea       _String(pc),a1      chop off excess zeros
          bsr.w     chopstr             ;
          WriteStr  CLI,a1,d0           display the value
          WriteStr  CLI,#M8,#ML8        ;
          lea       _String(pc),a1      convert samples
          moveq     #0,d1               ;
          move.b    _Samples(pc),d1     ;
          bsr.w     DNumToStr           ;
          lea       _String(pc),a1      chop off excess zeros
          bsr.w     chopstr             ;
          WriteStr  CLI,a1,d0           display the value
          WriteStr  CLI,#M9,#ML9        tell user to press [Return]
.poll     WaitChar  CLI,#1              wait until (s)he does...
          beq.s     .poll               ;
.flush    Read      CLI,#_String,#10    flush any remaining characters...
          cmp.l     #10,d0              ;
          beq.s     .flush              ;
          WriteStr  CLI,#CRS,#1         write a carriage return
          bra.w     showname            return to menu

quit      WriteStr  CLI,#M13,#ML13      tell user we are quitting
          bra.w     finished            ;

;
; Special-purpose subroutines.
;

notfound  lea       trackerid+4(pc),a2  get end address of the identifier
          move.l    a3,a1               get address of memory to search
          moveq     #3,d1               ;
.cmpbyte  move.b    (a1)+,d0            compare both bytes
          cmp.b     -(a2),d0            ;
          bne.s     search              ;
          dbra      d1,.cmpbyte         repeat until done
          moveq     #0,d0               ;
          rts                           we found it - address in a3
search    addq.l    #1,a3               move onto next byte
          cmp.l     #2048*1024,a3       have we reached the end of memory?
          bne.s     notfound            ;
          moveq     #-1,d0              yes - signal that we didn't find it
          rts                           ;

chopstr   moveq     #10,d0              chop leading zeros off number
.chop     cmp.b     #48,(a1)            is it a zero?
          bne.s     chopped             ;
          addq.l    #1,a1               ;
          subq.l    #1,d0               ;
          cmp.b     #1,d0               make sure that there is at least one
          bne.s     .chop               zero in the string
chopped   rts                           ;

          include   dnumtostr.lib       number to string conversion library
          include   dstrtonum.lib       string to number conversion library

_Write    CALLDOS   Write               subroutine to call AmigaDOS Write call
          rts                           ;

;
; SoundTracker identifier. It's backwards, so the search routine won't find the
; string embedded in the code if it is loaded into chip ram.
;

trackerid dc.b      ".K.M"

;
; Various variables.
;

_Identity dc.l      0                   identity address of current module
_FSize    dc.l      0                   size of module
_Length   dc.b      0                   length of module
_Patterns dc.b      0                   number of patterns
_Samples  dc.b      0                   number of samples
_FNSize   dc.b      0                   length of filename
_String   dc.b      "0000000000000"     string buffer
          dc.b      "0000000000000"     ;

;
; Here are all the general messages.
;

CR        equ       10

M0        dc.b      CR,"The Ultimate SoundTracker Module Scanner - Version 1.0"
          dc.b      CR,"Designed & Coded by Oliver D. Jones, May 1994.",CR
M1        dc.b      CR,"Scanning..."
ML0       equ       *-M0
ML1       equ       *-M1
M2        dc.b      13,"Current Module : "
ML2       equ       *-M2
M3        dc.b      "Untitled"
ML3       equ       *-M3
M4        dc.b      CR,CR,"Please select an option."
          dc.b      CR,CR,"C - Continue Scanning."
          dc.b      CR,"R - Restart Scan."
          dc.b      CR,"V - View Module Statistics."
          dc.b      CR,"E - Edit Module Length."
          dc.b      CR,"S - Save Module."
          dc.b      CR,"Q - Quit."
          dc.b      CR,CR,"Please choose : "
ML4       equ       *-M4
M5        dc.b      CR,"Module Statistics:"
          dc.b      CR,CR,"File size : "
ML5       equ       *-M5
M6        dc.b      CR,CR,"Length    : "
ML6       equ       *-M6
M7        dc.b      CR,"Patterns  : "
ML7       equ       *-M7
M8        dc.b      CR,"Samples   : "
ML8       equ       *-M8
M9        dc.b      CR,CR,"Press [Return] to continue..."
ML9       equ       *-M9
M10       dc.b      CR,"Please enter a new length for the module in decimal."
          dc.b      CR,CR,"New length : "
ML10      equ       *-M10
M11       dc.b      CR,"Please enter a filename to save the module under."
          dc.b      CR,CR,"Filename : "
ML11      equ       *-M11
M12       dc.b      CR,"Saving..."
ML12      equ       *-M12
M13       dc.b      CR,"Quitting...",CR,CR
ML13      equ       *-M13

CRS       equ       *-2

;
; Here are all the error messages.
;

E0        dc.b      13,"Couldn't find any "
EL0       equ       *-E0
E1        dc.b      "more "
EL1       equ       *-E1
E2        dc.b      "SoundTracker Modules!",CR,CR
EL2       equ       *-E2
E3        equ       E0
EL3       equ       EL0+EL1+EL2
E4        dc.b      CR,"Decimal number cannot be more than 10 digits.",CR,CR
EL4       equ       *-E4
E5        dc.b      CR,"That is NOT a decimal number!",CR,CR
EL5       equ       *-E5
E6        dc.b      CR,"Filename is too long.",CR,CR
EL6       equ       *-E6
E7        dc.b      CR,"Can't open output file!",CR,CR
EL7       equ       *-E7
E8        dc.b      13,"Saved "
EL8       equ       *-E8
E9        dc.b      " bytes.",CR,CR
EL9       equ       *-E9