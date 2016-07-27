include "osvars.asm"

; zp areas
conttemp   =   &61
randoml    =   &62
randomh    =   &63
stackptr   =   &64
continued  =   &65
; vocab pointers so we don't overwrite them
verbptr    =   &66
nounptr    =   &68
; local variable stores for inside procs only
actscount  =   &6a
swapstore1 =   &6b
swapstore2 =   &6c
locastore  =   &6d
locxstore  =   &6e
locystore  =   &6f
bufptr     =   &70
foundptr   =   &72
msgnum     =   &74
roomptr    =   &75
astore     =   &77
xstore     =   &78
ystore     =   &79
exitnum    =   &7a
verb       =   &7b
noun       =   &7c
actpar     =   &7d
; 4 bytes reserved here - up to &80
parptr     =   &81
nresp      =   &82
cond       =   &83
parm       =   &84
currentc   =   &85
redraw     =   &86
actioned   =   &87
redrawg    =   &88

workbuffer =   &500
roombuffer =   &600
linebuffer =   &620

; Reserve save game areas
org &c00
.gamestate
.flags         skip 32
.counters
.count0        skip 1
.count1        skip 1
.count2        skip 1
.count3        skip 1
.count4        skip 1
.count5        skip 1
.count6        skip 1
.count7        skip 1
.count8        skip 1
.count9        skip 1
.count10       skip 1
.count11       skip 1
.count12       skip 1
.count13       skip 1
.count14       skip 1
.count15       skip 1
.roomflags
.room0         skip 1
.room1         skip 1
.room2         skip 1
.room3         skip 1
.currentroom   skip 1
.currentctr    skip 1
.savedroom     skip 1
.lighttime     skip 1
.objectlocs

; We may change this to be calculated
actionsptr =   &900
verbsptr   =   &902
nounsptr   =   &904
roomsptr   =   &906
msgsptr    =   &908
objectsptr =   &90a
dictptr    =   &90c

datastart  =   &1c00
datastarth =   &1c
nitems     =   &1c0e
nactions   =   &1c0f
nverbs     =   &1c10
nnouns     =   &1c11
nrooms     =   &1c12
mcarry     =   &1c13
startroom  =   &1c14
wlen       =   &1c15
llen       =   &1c16
nmess      =   &1c17
trroom     =   &1c18

org &e00
; first things - copy the pointers to memory areas and update for offset
; assume we load at load
.start
.engineinit:   ldx #&d
.ptrloop:      lda datastart,x
               clc
               adc #datastarth
               sta actionsptr,x
               dex
               lda datastart,x
               sta actionsptr,x
               dex
               bpl ptrloop
               ; seed random
               lda &ffe4
               sta randomh
               ldx #vducodes MOD 256
               ldy #vducodes DIV 256
               jsr printbuf
               tsx
               stx stackptr
               ; first save stackpoint

; initialises the game
; should only be called if the game is restarted from scratch
.gameinit      ; blank out gamearea
{
               ; see whether we want to load a saved game
               lda #23
               jsr printsystemmsg
               jsr getyesno
               bne dontload
               lda #31
               jsr printsystemmsg
               jsr getinputline
               jsr setuposfile
               lda #1
               sta osfileblock+11               
               lda #&ff
               jsr doosfile
               sty redraw           ; redraw screen
               sty redrawg
               jmp main            
.dontload      lda #0
               ldx #0
.initloop      dex
               sta gamestate,x
               bne initloop
               ; now copy object locations
               lda objectsptr
               sta bufptr
               lda objectsptr+1
               sta bufptr+1
               ; x is number of items
               ; y is index
               ldx #&ff
               ldy #0
.objloop       jsr skipstringbp
.enddesc       lda (bufptr),y
               inx
               sta objectlocs,x
               lda #2
               clc
               jsr addtobufptr
.cont          cpx nitems
               bne objloop
               ; Copy other info from the header
               lda startroom
               sta currentroom
               lda llen
               sta lighttime
               lda #1
               sta redraw                    ; to draw initial room
               sta redrawg
               lda #12
               jsr oswrch
               ; fall through
               ldx #<mainwindow
               ldy #>mainwindow
               jsr prtvdu
.main:         
               lda #0
               sta verb
               sta noun
               jsr performaction             ; auto actions
               ;lda actioned
               ;bne checkredraw
               ;lda #18
               ;jsr printsystemmsg
               ;jmp input
.checkredraw   lda #0
               sta actioned
               lda redraw
               beq input
               lda currentroom
               cmp nrooms                    ; am I dead?
               bne showroom
               jmp quitgame
.showroom      jsr displayroom
.input
               lda #&c
               jsr printsystemmsg
               jsr getinputline
               ldx #<linebuffer
               ldy #>linebuffer
               jsr parsecommand
               lda verb
               cmp #&ff
               bne verbok
               tay
.searchspc     iny
               lda (verbptr),y
               cmp #&0d
               beq replace
               cmp #&20
               bne searchspc
.replace       lda #&00
               sta (verbptr),y
.verbmsg       ldx verbptr
               ldy verbptr+1
               jsr printbuf
               jsr osasci
               lda #9
               jsr printsystemmsg
               jsr osnewl
               jmp input
.verbok        lda noun
               cmp #&ff
               bne nounok
               lda #26
               jsr printsystemmsg
               ldx nounptr
               ldy nounptr+1
               jsr printbuf
               jmp input
.nounok        jsr performaction
               jsr handlelight
               lda actioned
               bne loopback
               lda #18
               jsr printsystemmsg               
.loopback      lda #0
               sta actioned
               jmp main
}

; Generic procedures - to minimise code size
; Print prints the message at YYXX, terminated by 0 or 0x0d; A does not survive
; printbuf(x=low,y=high)
.printbuf
{
               stx bufptr
               sty bufptr+1
               ldy #0
.printloop     lda (bufptr),y
               beq quit
               pha
               jsr osasci
               pla
               cmp #&0d
               beq quit
               iny
               bne printloop
.quit          rts
}

.prtvdu
{
               stx bufptr
               sty bufptr+1
               ldy #0
.printloop     lda (bufptr),y
               jsr oswrch
               iny
               cpy #8
               bne printloop
               rts
}
               
.getinputline
{
               lda #0
               ldx #oswordblock MOD 256
               ldy #oswordblock DIV 256
               jmp osword
}

.setuposfile
{
               lda #<linebuffer
               sta osfileblock
               lda #>linebuffer
               sta osfileblock+1
               lda #0
               ldx #15
.osfileloop    sta osfileblock+2,x
               dex
               bne osfileloop
               lda #&c
               sta osfileblock+3
               lda #&d
               sta osfileblock+15
               rts
}               

.doosfile
{
               ldx #osfileblock MOD 256
               ldy #osfileblock DIV 256
               jmp osfile
}
               
; printsystemmsg(a=msg)
; to cut down repeat code
.printsystemmsg
{
               jsr findsystemmsg
               ldx foundptr
               ldy foundptr+1
               inx
               bne printit
               iny
.printit       jmp printbuf
}

.printmessage
{
               jsr findmessage
               jsr copymessage
               ldx #workbuffer MOD 256
               ldy #workbuffer DIV 256
               jmp printbuf
}

.getyesno
{
               jsr getinputline
               lda linebuffer
               ora #&20
               cmp #&79             ; "y"
               rts
}

.countbits
{
               ldx #7
               ldy #0
.loop          dex
               beq out
               ror a
               bcc loop
               iny
               bcs loop
.out           tya
               rts
}

.getexitindex
{
                                   ; X = 0-5 for which exit to return
               lda #0              ; A = bitmask to test against exits bitfield
               tay                 ; Y = index in exits list
               sec                 ; set carry, so the ROL A below yields 1 the first time round the loop
.cbits
               rol a               ; subsequent times round the loop yield 2, 4, 8 etc (C will be clear)
               dex
               bmi doneallbits     ; exit loop if X<0
               bit exitnum         ; is this exit defined?
               beq cbits           ; no - reloop
               iny                 ; yes - inc index of exits list
               bne cbits           ; ...and reloop
.doneallbits
               and exitnum         ; now see if our exit is actually defined
               beq return          ; it isn't - return 0
               lda (foundptr),Y    ; it is - look up actual exit number from the list
.return        rts
}

; parsecommand - splits up the input into verbs and nouns
; parsecommand(YX); returns verb in verb and noun in noun
; (00 = unknown word)
; (ff = no word)
.parsecommand
print "Parse: ",~parsecommand
{
               stx bufptr
               sty bufptr+1
               ; search for verbs
               jsr skipspaces
               ; check for short words
               ldy #1
               lda (bufptr),y
               cmp #&0d
               bne notoneword
               ldy #0
               lda (bufptr),y
               ldx #0
.onewordloop   cmp shortverbs,x
               beq foundoneword
               inx
               cpx #7
               bne onewordloop
               beq notoneword
.foundoneword  cpx #6
               bcc direction
               lda #14
               sta verb
               jmp onlyverb
.direction     lda #1
               sta verb
               inx
               txa
               sta noun
               rts
.notoneword
               lda bufptr
               sta verbptr
               lda bufptr+1
               sta verbptr+1
               lda verbsptr
               sta foundptr
               lda verbsptr+1
               sta foundptr+1
               lda nverbs
               jsr findword
               sta verb
               ; locate the space
               ldy #&ff
.spaceloop     iny
               lda (bufptr),y
               cmp #&0d             ; end of sentence - store 00 for word
               bne stillmore
.onlyverb      lda #&00
               sta noun
               rts
.stillmore     cmp #&20
               bne spaceloop
               iny
               tya
               clc
               adc bufptr
               sta bufptr
               jsr skipspaces
               ; quick check if no spaces
               lda (bufptr),y
               cmp #&0d
               beq onlyverb
               lda bufptr
               sta nounptr
               lda bufptr+1
               sta nounptr+1
               lda nounsptr
               sta foundptr
               lda nounsptr+1
               sta foundptr+1
               lda nnouns
               jsr findword
               sta noun
}

; skipspaces - skips any spaces at bufptr
.skipspaces
{
               ldy #&ff
.skiploop      iny
               lda (bufptr),y
               cmp #&20
               beq skiploop
               tya
               jmp addtobufptr
}

; skipstringbp - skips a string at bufptr
.skipstringbp
{
               ldy #0
               lda (bufptr),y
               ; follow through to addtobufptr
}

; simple routine to add A to bufptr and save a few bytes
.addtobufptr
{
               clc
               adc bufptr
               sta bufptr
               bcc nooverflow
               inc bufptr+1
.nooverflow    rts
}

; skipstring - skips a string at foundptr
.skipstring
{
               ldy #0
               lda (foundptr),y
               ; follow through to add to foundptr             
}

.addtofoundptr
{
               clc
               adc foundptr
               sta foundptr
               bcc nooverflow
               inc foundptr+1
.nooverflow    rts
}

.copybptofp
{
               lda bufptr
               sta foundptr            
               lda bufptr+1
               sta foundptr+1
               rts
}

; findword
; on entry bufptr = word to check; foundptr = dictionary list; a = dict size
; returns word in a
.findword    
print "findword ", ~findword     
{
               sta astore
               lda #&ff
               sta exitnum          ; for the unsynonym command
               ldx #0
               ; word loop
.wordloop      ldy #0
               lda (foundptr),y
               bmi charloop
               stx exitnum
               ; char loop
.charloop      lda (foundptr),y
               and #&7f             ; remove synonym flag               
               cmp (bufptr),y
               bne checkshort
               cmp #&20             ; Check whether it's a space
               beq success          ; it is - success! Do this after the cmp
               iny                  ; to differ 'twixt GO and GONE etc.
               cpy wlen
               bne charloop
               ; success - we have a match
.success       lda exitnum
               rts
.checkshort    cmp #&20
               bne nextword
               lda (bufptr),y
               cmp #&0d
               beq success
.nextword      inx
               cpx astore
               beq failed
               lda wlen
               jsr addtofoundptr
               jmp wordloop
.failed        lda #&ff
               rts
}
               
; find procedures - each one finds the type of object
; stores the address in foundaddr
; findmessage(a=msgnum);
; findmessagebuf - to allow routine to be reused, bufptr and msgnum need to be setup
.findmessage:  sta msgnum
               lda msgsptr                         
               sta bufptr                           
               lda msgsptr+1
               sta bufptr+1
.findmessagebuf
{               
               ldx #0           ; checks whether we've found the message
.searchloop:   cpx msgnum       ; have we got to the message
               beq found
               inx
               jsr skipstringbp
               jmp searchloop
.found         jmp copybptofp
}

; findroom(a=roomnum)
.findroom:
{              sta msgnum
               lda roomsptr                         
               sta bufptr                           
               lda roomsptr+1
               sta bufptr+1                         
               ldx #0           ; checks whether we've found the message
.searchloop    cpx msgnum       ; have we got to the message
               beq finish
               jsr skipstringbp
               inx              ; exits
               lda (bufptr),y  
               stx xstore
               jsr countbits    ; convert the number in a to a real number
               ldx xstore
               clc
               adc #1           ; To include the value of this byte
               jsr addtobufptr
               jmp searchloop
.finish        jmp copybptofp
}

; findobject(a=objectnum)
.findobject
{
               sta msgnum
               lda objectsptr
               sta bufptr
               lda objectsptr+1
               sta bufptr+1
               ldy #0
               ldx #&ff                ; as we inx at start it should be min-1
.searchloop    inx
               cpx msgnum
               beq out
               jsr skipstringbp
               lda #2
               clc
               jsr addtobufptr
               jmp searchloop
.out           jmp copybptofp
}
            
; findsystemmsg(a=message)
.findsystemmsg
{
               sta msgnum
               lda #systemmessages MOD 256
               sta bufptr                           
               lda #systemmessages DIV 256
               sta bufptr+1                         
               jmp findmessagebuf
}

; Do stuff procedures
; copymessage(&71&70 = message)
; decodes the message pointed to by &71&70 and stores it in workbuffer
.copymessage:
{              lda dictptr
               sta bufptr
               lda dictptr+1
               sta bufptr+1
               ldx #0           ; pointer for output buffer
               ldy #0
               lda (foundptr),y ; get size to save for later
               iny
               sta exitnum
.copyloop:     lda (foundptr),y
               bmi token        ; if bit 8 set treat as token
               cpy exitnum
               beq quit
               sta workbuffer,x ; else, store in buffer
               inx
               jmp next         ; skip token printing
.quit:         lda #&0d
               sta workbuffer,x
               rts
.token:        sty ystore       ; save y as we're going to be using it
               clc              ; safety
               and #&7f         ; last 7 bits
               sta msgnum
               adc msgnum
               tay              ; offset = token number * 2
               lda (bufptr),y
               sta workbuffer,x
               iny
               inx
               lda (bufptr),y
               sta workbuffer,x
               inx
               ldy ystore
.next:         iny
               cpy exitnum
               beq quit
               jmp copyloop      ; back to the loop
}

; displayroom(a)
.displayroom
print "displayroom ",~displayroom
{
               sta locastore     ; store for later
               ; change window to screen window
               lda #&86
               jsr osbyte
               stx mainwindow+6
               sty mainwindow+7
               ldx #<roomwindow
               ldy #>roomwindow
               jsr prtvdu
               ; First check whether its dark
               jsr isdark
               bne doroom
               lda #27
               jsr printsystemmsg
               jmp leave
.doroom        ; graphics
               lda redrawg
               beq nogfx
               lda locastore
               jsr drawscr
               lda #0
               sta redrawg
.nogfx         lda locastore
               jsr findroom
               ; Now print out the room description
.showit        jsr copymessage
               lda foundptr+1
               sta roomptr+1
               lda foundptr
               sta roomptr       ; save foundptr for use with the exits
               sty ystore
               ; check whether it starts with a *
               lda workbuffer
               cmp #'*'
               beq skipone
               lda #8
               jsr printsystemmsg
.skipone
               ldx #<workbuffer
               ldy #>workbuffer
               lda workbuffer
               cmp #'*'
               bne printit
               inx
               bne printit
               iny
.printit       jsr printbuf
               ; print exits
               lda #6
               jsr printsystemmsg
               ldx #&ff
               ldy ystore
               lda (roomptr),y
.exitloop      inx
               cpx #5
               beq finish
               lsr a
               bcc exitloop
               stx xstore
               sta ystore
               txa
               jsr printsystemmsg
               lda ystore
               ldx xstore
               jmp exitloop
.finish        jsr osnewl
               ; Objects - first get a count
               jsr osnewl
               lda locastore
               jsr countobjectsin
               cmp #0
               beq leave
               lda #7
               jsr printsystemmsg 
               jsr osnewl
               ldx #0
.objectloop    lda objectlocs,x
               cmp locastore
               beq printobject
.nextobject    inx
               cpx nitems
               bne objectloop
.leave         lda #0
               sta redraw
               sta redrawg
               ; restore window
               ldx #<mainwindow
               ldy #>mainwindow
               jsr prtvdu
               rts
.printobject   stx xstore
               txa
               jsr findobject
.prtobj        jsr copymessage
               lda #0
               sta workbuffer,x
               ldx #<workbuffer
               ldy #>workbuffer
               jsr printbuf
               ldx #<objsep
               ldy #>objsep
               jsr printbuf
               ldx xstore
               jmp nextobject
}

; performaction - i.e. do stuff; verb is in verb and noun is in noun
; stuff to add - shortcuts for commands; default commands (e.g. look)
.performaction
{
               lda #1
               sta continued
               ; check for movement
               ldx verb
               ldy noun
               cpx #1
               bne notgo
               cpy #7
               bcs notgo
               ; check for darkness
               stx locxstore
               sty locystore
               jsr isdark
               bne movement
               lda #14
               jsr printsystemmsg
               ldx locxstore
               ldy locystore
print "movement ",~movement               
.movement      lda #1
               sta actioned
               jmp handle_go
.notgo         ldx #&ff
               lda actionsptr
               sta roomptr
               lda actionsptr+1
               sta roomptr+1
.actionsloop   inx
               cpx nactions
               beq getcheck
               ldy #0
               lda (roomptr),y
               iny
               cmp verb
               beq chknouns
               bne failedvocab
.chknouns      cmp #0
               beq zeroverb
               sta continued
               lda (roomptr),y
               cmp #0
               beq chkconds
               cmp noun
               beq chkconds
.failedvocab   lda #1
               sta continued           ; stop continues from multiple firing
               jsr nextaction
               jmp actionsloop
.chkconds      stx actscount
               lda continued           ; have we continued?
               bne notcontinued
               lda conttemp
               sta continued           ; to make sure we don't continue again
.notcontinued  jsr checkconditions
               bne doacts
.carryon       ldx actscount
               ldy #1                  ; as a generic - to make sure we're at the start
               jsr nextaction
               jmp actionsloop
.doacts        iny
               jsr doactions
               lda continued           ; continued stuff
               beq carryon
.quit          lda verb
               beq carryon             ; handle auto actions - as they don't stop
               rts                     ; as it worked, then we can skip the rest
.getcheck      ; check for gets
               ldx verb
               ldy noun
               cpx #10
               bne notget
.handleget     jsr handle_getdrop
               sta actioned
               jmp printsystemmsg
.notget        cpx #18
               beq handleget
.leave         rts
.zeroverb      ; get percentage
               lda (roomptr),y
               bne notcontinue
               lda continued
               beq chkconds            ; is it a continued command
               bne failed
.notcontinue   sta continued
               cmp #100                ; 100% - always do it
               beq chkconds
               cmp #0
               bne percentage
.failed        jsr nextaction
               jmp actionsloop         ; to be altered when we do continue
.percentage    sta astore
               jsr getrand             ; cheat for now
               and #&7f
               cmp #100
               bcs percentage          ; we want <100
               cmp astore
               bcs failed
               bcc chkconds
}

.checkconditions
{
               iny                     ; to get to start of conditions
               lda (roomptr),y
               and #&0f
               sta nresp
               lda (roomptr),y
               and #&f0
               sta xstore
               ldx #4
               lda #1
               sta exitnum             ; result of conditions stored here
               lda #0
               sta parptr
.clearloop     dex
               sta actpar,x
               lsr xstore              ; steal the loop to do this
               cpx #0
               bne clearloop
}
.condloop                              ; leave global as we'll be coming back here
{              ldx xstore              ; now parse the conditions
               beq condleave           ; end of conditions
               iny
               dex
               lda (roomptr),y
               sta cond
               bpl getparm
               and #&7f
               sta parm
               lda #0
               sta cond
               jmp jumpcond
.getparm       iny
               dex
               lda (roomptr),y
               sta parm
.jumpcond      stx xstore              ; free up x for use
               ldx cond
               lda condlow,x
               sta bufptr
               lda condhigh,x
               sta bufptr+1
               ldx parm
               lda objectlocs,x        ; as a shortcut
               jmp setcondret          ; set up stack properly
.jumptable     jmp (bufptr)
.setcondret    jsr jumptable
}
; again, these are global as we'll be jmping here
.condret       beq condloop            ; condition succeeded
               lda #0
               sta exitnum             ; otherwise leave
.condleave     lda exitnum
               rts
               
.conditionsstart
.pushpar
{
               txa
               ldx parptr
               sta actpar,x
               inc parptr
               lda #0
               rts
}

.itemcarried
{
               cmp #&ff
               rts
}

.itemroom
{
               cmp currentroom
               rts
}

.itemcarriedroom
{
               jsr itemcarried
               bne itemroom
               rts
}

.inroom
{
               cpx currentroom
               rts
}

.itemnotproom
{
               cmp currentroom
               beq failit
               bne succeed
}

.itemnotc
{
               cmp #&ff
               beq failit
               bne succeed
}

.notinroom
{
               cpx currentroom
               beq failit
               bne succeed
}

.something
{
               jsr nothing
               beq failit
}

.nothing
{
               ldx nitems
.objloop       lda objectlocs,x
               cmp #&ff
               beq failit
               dex
               bpl objloop
}

.succeed       lda #0
               rts
.failit        lda #1
               rts

.flagset
{
               jmp getflag
}

.flagclear
{
               jsr getflag
               beq failit
               bne succeed
}

.itemncarryroom
{
               cmp #&ff
               beq failit
               cmp currentroom
               beq failit
               bne succeed
}
.itemingame
{
               cmp #&00
               beq failit
               bne succeed
}

.itemnotgame
{
               cmp #&00
               rts
}

.counterle
{
               cpx currentctr
               bcs succeed
               rts
}

.counterge
{
               cpx currentctr
               bcc succeed
               bcs failit
}

.iteminitial
{
               sty ystore
               jsr findobject
               jsr skipstring
               ldy #0
               lda (foundptr),y
               ldy ystore
               cmp objectlocs,x
               rts
}

.itemninitial
{
               jsr iteminitial
               bne succeed
               beq failit
}

.countere
{
               cpx currentctr
               rts
}
.conditionsend
print "Condition size: ",~conditionsend-conditionsstart

; getflag x=flag, ret state in Z
.getflag
{
               lda flags,x
               eor #1
               rts
}

.doactions
{
               lda #1
               sta actioned
               stx xstore
               ldx #0                  ; x will count the responses
               stx parptr              ; blank the parameter ptr
.responseloop  cpx nresp
               beq leave
               lda (roomptr),y
               iny
               inx
               cmp #0
               beq responseloop        ; null action
               cmp #52
               bcc message
               sbc #50                 ; no sec needed as we know its set
               cmp #52
               bcs message
               sec
               sbc #2               
               stx cond
               sty parm
               tax
               lda resplow,x
               sta bufptr
               lda resphigh,x
               sta bufptr+1
               jmp setrespret          ; set up stack properly
.jumptable     jmp (bufptr)
.setrespret    jsr jumptable
               ldx cond
               ldy parm
               jmp responseloop
.leave         ldx xstore
               rts 

.message       stx cond
               sty parm
               jsr printmessage
               ldy parm
               ldx cond
               jmp responseloop            
}

.getpar
{
               ldx parptr
               inc parptr
               lda actpar,x
               tax
               rts
}

.getitem
{
               jsr getpar
               ldx #10
               stx xstore
               tax
               jmp checkinv
}

.moveroom
{
               jsr getpar
               lda currentroom
               sta objectlocs,x
               stx redraw
               rts
}               

.movetoroom
{
               jsr getpar
               stx currentroom
               stx redraw
               stx redrawg
               rts
}

.removeitem
{
               jsr getpar
               lda #0
               sta objectlocs,x
               stx redraw
               rts
}               
               
.setdark
{
               ldx #15
               jmp setflag2
}
               
.setlight
{
               ldx #15
               jmp clearflag2
}

.setflag
               jsr getpar
.setflag2
{
               lda #1
               sta flags,x
               rts
}

.clearflag
               jsr getpar
.clearflag2
{
               lda #0
               sta flags,x
               rts
}

.death
{
               ldx #15
               jsr clearflag2
               lda nrooms
               sta currentroom
               sta redraw
               sta redrawg
               rts
}
               
.itemtoroom
{
               jsr getpar
               stx locxstore
               jsr getpar
               txa 
               ldx locxstore
               sta objectlocs,x
               stx redraw
               rts
}

.quitgame
{
               ldx stackptr
               txs
               lda #22
               jsr printsystemmsg;
               jsr getyesno
               bne dontrepeat
               jmp engineinit
.dontrepeat    rts
}

.lookroom
.descroom
{
               lda #1
               sta redraw
               sta redrawg
               rts
}

.score
{
               rts
}

.inventory
{
print "inventory ",~inventory
               lda #16           ; I'm carrying
               jsr printsystemmsg
               lda #255
               jsr countobjectsin
               cmp #0
               beq nothingcarried
               ldx #0
.objectloop    lda objectlocs,x
               cmp #&ff
               beq printobject
.nextobject    inx
               cpx nitems
               bne objectloop
.leave         rts
.printobject   stx locxstore
               txa
               jsr findobject
.prtobj        jsr copymessage
               ldx #<workbuffer
               ldy #>workbuffer
               jsr printbuf
               ldx locxstore
               jmp nextobject
.nothingcarried
               lda #25
               jmp printsystemmsg
}

.setflag0
{
               ldx #0
               jmp setflag2
}
               
.clearflag0
{
               ldx #0
               jmp clearflag2
}
               
.refilllamp
{
               lda llen
               sta lighttime
               rts
}
               
.cls
{
               lda #12
               jmp osasci
}
               
.savegame
{
               lda #31
               jsr printsystemmsg
               jsr getinputline
               jsr setuposfile
               lda #&c
               sta osfileblock+11
               lda #0
               jmp doosfile
}
               
.swapitems
print "swapitems ",~swapitems
{
               jsr getpar
               stx locxstore
               lda objectlocs,x
               sta swapstore1
               jsr getpar
               stx locystore
               lda objectlocs,x
               ldx locxstore
               sta objectlocs,x
               lda swapstore1
               ldx locystore
               sta objectlocs,x
               stx redraw
               rts
}               
 
.continuel
{
               lda #0
               sta continued
               sta verb
               sta noun
               rts
}
               
.takeitem
{
               jsr getpar
               ldx #10
               stx xstore
               tax
               jmp objecttoinv               
}

.putitem
{
               jsr getpar
               stx xstore
               jsr getpar
               txa
               lda xstore
               sta objectlocs,x
               stx redraw
               rts
}               

.deccount
{
               dec currentctr
               rts
}
 
.printcount
{
               lda currentctr
               jmp printint
}
               
.setcount
{
               jsr getpar
               stx currentctr
               rts
}

.swaploc1
{
               lda savedroom
               ldx currentroom
               stx savedroom
               sta currentroom
               stx redraw
               stx redrawg
               rts
}
               
.selcount
{
               jsr getpar
               lda counters,x
               pha
               lda currentctr
               sta counters,x
               pla
               sta currentctr
               rts
}

.addcount
{
               jsr getpar
               txa
               clc
               adc currentctr
               sta currentctr
               rts
}

.subcount
{
               jsr getpar
               txa
               sec
               sbc currentctr
               sta currentctr
               rts
}
               
.printnoun
print "printnoun", ~printnoun
{
               ldy #0               ; we can mangle noun now
.nounloop      lda (nounptr),y
               beq printit
               cmp #&0d
               beq modify
               iny
               bne nounloop
.modify        lda #0
               sta (nounptr),y
.printit       ldx nounptr
               ldy nounptr+1
               jmp printbuf
}

.printnouncr
{
               jsr printnoun
}

.newline
{
               jmp osnewl
}               

.swaploc2
{
               jsr getpar
               lda roomflags,x
               sta locxstore
               lda currentroom
               sta roomflags,x
               lda locxstore
               sta currentroom
               rts
}

.pause
.drawpict
{
               rts
}

.nextaction
{
               iny
               lda (roomptr),y
               sta astore
               and #&0f
               sta ystore
               lda astore
               and #&f0
               stx xstore
               ldx #4
.shift         lsr a
               dex
               bne shift
               ldx xstore
               clc
               adc ystore
               adc #3                     ; y offsets
               adc roomptr
               sta roomptr
               bcc finish
               inc roomptr+1
.finish        rts
}               
               
        
.handle_go
{
               tya
               bne doexits
               ; no noun - error
               lda #19
               jmp printsystemmsg
.doexits       sta astore
               lda currentroom
               jsr findroom
               jsr skipstring
               lda (foundptr),y
               sta exitnum
               inc foundptr
               bne skipinc2
               inc foundptr+1
.skipinc2      ldx astore
               dex
               jsr getexitindex
               bne move
               ; can't go - check for dark flag
               jsr isdark
               beq killdark
               lda #&a
               jmp printsystemmsg
.move          sta currentroom
               lda #1
               sta redraw
               sta redrawg
               rts
.killdark      lda #29
               jsr printsystemmsg
               jmp death
}

.handle_getdrop
print "handle getdrop ", ~handle_getdrop
{
               ; Now we need to check the noun number against the object number
               stx xstore
               sty ystore
               ; First check whether it's dark
               jsr isdark
               beq cantdoit
               ldx #0
               lda objectsptr
               sta bufptr
               lda objectsptr+1
               sta bufptr+1
.objectloop    jsr skipstringbp
               ldy #1                     ; skip the location byte
               lda (bufptr),y
               cmp ystore
               beq checkpresent
.checknext     iny
               tya
               jsr addtobufptr
               inx
               cpx nitems
               bne objectloop
.cantdoit
               ldx xstore                 ; can't do it               
               lda #17
               cpx #18
               bne getmsg
               lda #15
.getmsg        rts
.checkpresent
               lda xstore
               cmp #18
               bne dropverb
               lda #&ff
               sta locastore
               bne continue
.dropverb      lda currentroom
               sta locastore
.continue      lda objectlocs,x
               cmp locastore
               bne checknext
}

.checkinv
{
               ldy xstore
               cpy #18
               beq objecttoinv
               stx astore
               lda #255
               jsr countobjectsin
               cmp mcarry
               bcs ptoomuch
}        

.objecttoinv              
{
               lda #255
               cpy #18
               bne alterobj
               lda currentroom
.alterobj      sta redraw
               sta objectlocs,x
               lda #11
               cpy #18
               bne message
               lda #11
               sta redraw
.message       rts
}

.ptoomuch
{
               lda #20
               rts
}

; countobjectsin A = room, returns answer in A
.countobjectsin 
{
               stx locxstore
               sty locystore
               sta locastore
               ldx #0
               ldy #0
.countloop     lda objectlocs,x
               cmp locastore
               bne notin
               iny
.notin         inx
               cpx nitems
               bne countloop
               tya
               ldx locxstore
               ldy locystore
               rts
}               

; isdark - checks whether it is dark, sets state in Z if it is
; also checks whether there's a light
.isdark
{
               ldx #15           ; dark bit
               jsr flagset
               bne quit
               ; now check for a light
               ldx #9            ; object 9 - lit lamp
               lda objectlocs,x
               jsr itemcarriedroom
               ; swap over z flags states
               bne setzero
               ; Check whether it has fuel
               lda lighttime
               rts
.setzero       lda #0               
.quit          rts
}

; handlelight - decrement lit counter if needed and display messages
.handlelight
{
               ldx #9
               lda objectlocs,x
               jsr itemingame
               bne quit
               ; lit lamp is in game so handle it
               lda lighttime
               cmp #&ff
               beq quit          ; lighttime is &ff - infinite
               cmp #0
               beq quit          ; so it doesn't mysteriously relight
               dec lighttime
               beq lightout       ; if light's just gone out
               lda lighttime
               cmp #25
               bcs quit
               lda #30
               bne printit             
.lightout      lda #28
.printit       jmp printsystemmsg
.quit          rts               
}

; random number generator
.getrand
print "getrand ",~getrand
{
               lda randomh
               sta locastore
               lda randoml
               asl a
               rol locastore
               asl a
               rol locastore
               clc
               adc randoml
               pha
               lda locastore
               adc randomh
               sta randomh
               pla
               adc #&11
               sta randoml
               lda randomh
               adc #&36
               sta randomh
               rts
}

.printint
print "printint ", ~printint
{
               ldx #0
               stx locastore
               ldx #&FF
               sec
.dec100        inx
               sbc #100
               bcs dec100
               adc #100
               jsr printdigit
               ldx #&FF
               sec
.dec10         inx
               sbc #10
               bcs dec10
               adc #10
               jsr printdigit
               tax
.printdigit    pha
               txa
               beq pad
               ora #'0'
.printit       jsr osasci
               lda #'0'
               sta locastore
               pla
               rts
.pad           lda locastore
               bne printit
               pla
               rts
}

; condition pointers
.condlow
equb pushpar MOD 256,        itemcarried MOD 256,  itemroom MOD 256,    itemcarriedroom MOD 256
equb inroom MOD 256,         itemnotproom MOD 256, itemnotc MOD 256,    notinroom MOD 256
equb flagset MOD 256,        flagclear   MOD 256,  something MOD 256,   nothing MOD 256
equb itemncarryroom MOD 256, itemingame MOD 256,   itemnotgame MOD 256, counterle MOD 256
equb counterge MOD 256,      iteminitial MOD 256,  itemninitial MOD 256,countere MOD 256

.condhigh
equb pushpar DIV 256,        itemcarried DIV 256,  itemroom DIV 256,    itemcarriedroom DIV 256
equb inroom DIV 256,         itemnotproom DIV 256, itemnotc DIV 256,    notinroom DIV 256
equb flagset DIV 256,        flagclear   DIV 256,  something DIV 256,   nothing DIV 256
equb itemncarryroom DIV 256, itemingame DIV 256,   itemnotgame DIV 256, counterle DIV 256
equb counterge DIV 256,      iteminitial DIV 256,  itemninitial DIV 256,countere DIV 256

.resplow
equb getitem MOD 256, moveroom MOD 256, movetoroom MOD 256, removeitem MOD 256
equb setdark MOD 256, setlight MOD 256, setflag MOD 256, removeitem MOD 256
equb clearflag MOD 256, death MOD 256, itemtoroom MOD 256, quitgame MOD 256
equb lookroom MOD 256, score MOD 256, inventory MOD 256, setflag0 MOD 256
equb clearflag0 MOD 256, refilllamp MOD 256, cls MOD 256, savegame MOD 256
equb swapitems MOD 256, continuel MOD 256, takeitem MOD 256, putitem MOD 256
equb descroom MOD 256, deccount MOD 256, printcount MOD 256, setcount MOD 256
equb swaploc1 MOD 256, selcount MOD 256, addcount MOD 256, subcount MOD 256
equb printnoun MOD 256, printnouncr MOD 256, newline MOD 256, swaploc2 MOD 256
equb pause MOD 256, drawpict MOD 256

.resphigh
equb getitem DIV 256, moveroom DIV 256, movetoroom DIV 256, removeitem DIV 256
equb setdark DIV 256, setlight DIV 256, setflag DIV 256, removeitem DIV 256
equb clearflag DIV 256, death DIV 256, itemtoroom DIV 256, quitgame DIV 256
equb lookroom DIV 256, score DIV 256, inventory DIV 256, setflag0 DIV 256
equb clearflag0 DIV 256, refilllamp DIV 256, cls DIV 256, savegame DIV 256
equb swapitems DIV 256, continuel DIV 256, takeitem DIV 256, putitem DIV 256
equb descroom DIV 256, deccount DIV 256, printcount DIV 256, setcount DIV 256
equb swaploc1 DIV 256, selcount DIV 256, addcount DIV 256, subcount DIV 256
equb printnoun DIV 256, printnouncr DIV 256, newline DIV 256, swaploc2 DIV 256
equb pause DIV 256, drawpict DIV 256

; System messages - we may want to transfer these to another file
; so they're changable!
.systemmessages
.directionn    equb 8,"North ",0                               ; 0
.directions    equb 8,"South ",0                               ; 1
.directione    equb 7,"East ",0                                ; 2
.directionw    equb 7,"West ",0                                ; 3
.directionu    equb 5,"Up ",0                                  ; 4
.directiond    equb 7,"Down ",0                                ; 5
.exitslead     equb 14,"Exits lead: ",0                        ; 6
.cansee        equb 13,"I can see: ",0                         ; 7
.youare        equb 11,"I'm in a ",0                           ; 8
.unknownverb   equb 23," isn't a word I know.",0               ; 9
.cantgo        equb 22,"I can't go that way.",&0d              ; 10
.ok            equb 6,"O.K.",&0d                               ; 11
.whatnow       equb 23,"What shall I do now? ",0               ; 12
.eh            equb 5,"Eh?",&0d                                ; 13
.movedark      equb 37,"It's dangerous to move in the dark!",&0d ; 14
.notpickedup   equb 19,"I haven't got it.",&0d                 ; 15
.carrying      equb 16,"I'm carrying: ",&0d                    ; 16
.cantsee       equb 22,"I can't see it here.",&0d              ; 17
.cantdo        equb 26,"That is beyond my power.",&0d          ; 18
.direction     equb 18,"Try a direction.",&0d                  ; 19
.toomuch       equb 24,"I'm carrying too much!",&0d            ; 20
.dead          equb 11,"I'm dead!",&0d                         ; 21
.again         equb 14,"Play again? ",0                        ; 22
.restoregame   equb 24,"Restore a saved game? ",0              ; 23
.cantdonow     equb 27,"I can't do that just now!",&0d         ; 24
.nothingm      equb 10,"Nothing.",&0d                          ; 25
.unknownnoun   equb 21,"I don't understand ",0                 ; 26
.toodark       equb 23,"It's too dark to see!",&0d             ; 27
.lightout      equb 20,"The light ran out!",&0d                ; 28
.breakneck     equb 26,"I fell and broke my neck",&0d          ; 29
.lightdim      equb 27,"Your light is growing dim",&0d         ; 30 
.filename      equb 12,"Filename? ",0                          ; 31

.shortverbs    equb "NSEWUDI"
.osfileblock
equb <linebuffer, >linebuffer
equb 0,&c,0,0
equb 0,0 ,0,0
equb 0,&c,0,0
equb 0,&d,0,0

.objsep
equb " - ",0
.oswordblock
equb <linebuffer, >linebuffer
equb &80, &20, &5a, 0

.vducodes:     equb 22,129,0
.roomwindow:   equb 28,0,20,39,14,12,0,0
.mainwindow:   equb 28,0,31,39,20,31,0,1

include "gfx.asm"
.end

save "engine",start,end

; add game files - disk1
;putfile "tgb",&1c00
;putfile "time",&1c00
;putfile "aod1",&1c00
;putfile "aod2",&1c00
;putfile "tgbgfx",graphics
;putfile "timegfx",graphics
;putfile "aod1gfx",graphics
;putfile "aod2gfx",graphics

; add game files - disk2
;putfile "pulsar",&1c00
;putfile "circus",&1c00
;putfile "feasib",&1c00
;putfile "akyrz",&1c00
;putfile "p7gfx",graphics
;putfile "cirgfx",graphics
;putfile "feasgfx",graphics
;putfile "akygfx",graphics

; add game files - disk2
putfile "g.perseus",&1c00
putfile "g.10ind",&1c00
putfile "g.waxwork",&1c00
putfile "l.perseus",graphics
putfile "l.10ind",graphics
putfile "l.waxwork",graphics
