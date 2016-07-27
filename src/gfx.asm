;include "osvars.asm"

vdu19w =    &4f
gfxptr =    &50
gfxlen =    &52
plots  =    &54
mode   =    &55
gfxx   =    &56
gfxy   =    &58
col0   =    &5a 
col1   =    &5b 
col2   =    &5c 
col3   =    &5d 
tcol   =    &5e
gstore =    &5f

.drawscr
{
            sta gstore
            dec gstore
            lda #25
            sta plots
            lda #&ff
            sta col1
            sta col2
.setcolours ldx #0
.colourslp  lda colours,x
            jsr oswrch
            inx
            cpx #21
            bne colourslp
            ldy #0
            lda gstore
            asl a
            asl a
            tax
            lda graphics,x
            sta gfxptr
            inx
            lda graphics,x
            clc
            adc #>graphics
            sta gfxptr+1
            inx
            lda graphics,x
            clc
            adc gfxptr
            sta gfxlen
            inx
            lda graphics,x
            adc gfxptr+1
            sta gfxlen+1
.gfxmain            
.reducelp   cpy #0
            beq next
            dey
            inc gfxptr
            bne checkfinished
            inc gfxptr+1
.checkfinished
            lda gfxptr+1
            cmp gfxlen+1
            bne reducelp
            lda gfxptr
            cmp gfxlen
            bne reducelp
            rts
.next       lda #0
            sta gfxx+1
            sta gfxy+1
            lda (gfxptr),y
            iny
            cmp #&ff
            beq defcol
            cmp #&c0
            beq move
            cmp #&c1
            beq fill
            
.draw       ldx #5
            jmp docoords

.move       lda (gfxptr),y
            iny
            ldx #4
            jmp docoords
            
.defcol     lda (gfxptr),y
            iny
            sta tcol
            tax
            lda paltbl,x
            sta col0
            tax
            ;jsr vdu19
            lda #7
            ;tax
            ;lda invertcol,x
            ;tax
            ;lda paltbl,x
            sta col3
            ;tax
            ;lda #3
            ;jsr vdu19
            jmp gfxmain
            
.fill       lda (gfxptr),y
            iny
            cmp #0
            bne notcol0
            lda col0
.notcol0            
            tax
            lda paltbl,x
            ; check which colour to redefine it as          
            ldx #1
.colchkloop cmp col0,x
            beq leaveloop
            inx
            cpx #4
            bne colchkloop
            beq defcol1
.leaveloop  txa
            jmp skipit
.defcol1    tax
            lda col1
            cmp #&ff
            bne defcol2
            lda #1
            stx col1
            bne defineit ; bne to save a byte
.defcol2    lda col2
            cmp #&ff
            bne skipit
            lda #2            
            stx col2
.defineit   jsr vdu19
            ldx vdu19w
.skipit     txa
            jsr gcol
            ldx #133
            lda (gfxptr),y
            iny

.docoords   jsr converty
            lda (gfxptr),y
            iny
            jsr convertx
            txa
            jsr plot
            jmp gfxmain
            
.plot       sta mode
            ldx #0
.plotloop   lda plots,x
            jsr oswrch
            inx
            cpx #6
            bne plotloop
            rts
            
.gcol       tax
            lda #18
            jsr oswrch
            lda #0
            jsr oswrch
            txa
            jsr oswrch
            rts

.vdu19      sta vdu19w
            lda #19
            jsr oswrch
            lda vdu19w
            jsr oswrch
            txa 
            jsr oswrch
            lda #0
            jsr oswrch
            jsr oswrch
            jsr oswrch
            rts
            
.convertx   sta gfxx
            asl gfxx
            rol gfxx+1
            asl gfxx
            rol gfxx+1            
            rts
            
.converty   sta gfxy
            asl gfxy
            rol gfxy+1
            asl gfxy
            rol gfxy+1            
            rts
}
            
.colours    ;equb 29:equw 756:equw 600
            ;equb 24:equw 0:equw 192:equw 508:equw 380
            equb 29:equw 128:equw 256
            equb 24:equw 0:equw 384:equw 1016:equw 760
            equb 18,0,3
            equb 18,0,128
            equb 16            
            
.paltbl     equb 0,4,1,5,2,6,3,7
.invertcol  equb 7,6,5,4,3,2,1,0
            
graphics    = &3400