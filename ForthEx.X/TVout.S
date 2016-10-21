;****************************************************************************
; Copyright 2015, Jacques Deschênes
; This file is part of ForthEx.
;
;     ForthEx is free software: you can redistribute it and/or modify
;     it under the terms of the GNU General Public License as published by
;     the Free Software Foundation, either version 3 of the License, or
;     (at your option) any later version.
;
;     ForthEx is distributed in the hope that it will be useful,
;     but WITHOUT ANY WARRANTY; without even the implied warranty of
;     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;     GNU General Public License for more details.
;
;     You should have received a copy of the GNU General Public License
;     along with ForthEx.  If not, see <http://www.gnu.org/licenses/>.
;
;****************************************************************************
; vidéo NTSC B/W sur PIC24FJ64G002
; T2 période ligne horizontale
; OC1 sortie sync  sur RPB4
; OC2 contrôle début sortie vidéo
; sortie vidéo sur RPB3

    
.include "hardware.inc"
.include "video.inc"
.include "gen_macros.inc"
.if (VIDEO_STD==NTSC)
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
.include "core.inc"
.include "keyboard.inc"
    
.data
line_count: .word 0xffff
even: .byte 0xff
.align 2 
xpos: .byte 0
ypos: .byte 0
 
.global _video_buffer
_video_buffer: .space TV_BUFFER


.text
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialisation générateur vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global tvout_init
tvout_init:
    bclr VIDEO_TRIS, #VIDEO_OUT ; sortie vidéo
    bclr SYNC_TRIS, #SYNC_OUT  ; sortie sync vidéo
;    bclr VIDEO_TRIS, #VIDEO_PORCH ; seuil video
    ; configuration PPS
    mov VIDEO_RPOR, W0
    mov #~(0x1f<<VIDEO_RPORbit),W1 ;mask
    and W0,W1,W0
    mov #(VIDEO_FN<<VIDEO_RPORbit), W1
    ior W0,W1,W0
    mov W0, VIDEO_RPOR
    mov SYNC_RPOR, W0
    mov #~(0x1f<<SYNC_RPORbit),W1 ;mask
    and W0,W1,W0
    mov #(SYNC_FN<<SYNC_RPORbit), W1
    ior W0,W1,W0
    mov W0, SYNC_RPOR
    ; configuration VIDEO_SPI
    mov #(3<<PPRE0),W0
    mov W0,VIDEO_SPICON1
    mov #(2<<SPRE0),W0
    ior VIDEO_SPICON1
    mov #(1<<MSTEN), W0
    ior VIDEO_SPICON1
    bset VIDEO_SPICON2,#0
    bset VIDEO_SPISTAT, #SPIEN
    clr VIDEO_SPIBUF
    ; configuration output compare
    mov #HLINE, W0
    ; période timer
    mov W0, SYNC_PER
    mov W0, SYNC_OCRS
    mov W0, VIDEO_OCR
    mov #HSYNC, W0
    mov W0, SYNC_OCR
    mov  #VIDEO_DLY, W0
    mov W0, VIDEO_OCRS
    ; configuraton output compare mode 5
    mov #5, W0
    mov W0, SYNC_OCCON1
    mov W0, VIDEO_OCCON1
    ; configuration priorité d'interruptions
    ; priorité 5 pour les 2
    mov #~(7<<SYNC_IPbit), W0
    and SYNC_IPC
    mov #(5<<SYNC_IPbit), W0 
    ior SYNC_IPC
    mov #~(7<<VIDEO_IPbit), W0
    and VIDEO_IPC
    mov #(5<<VIDEO_IPbit), W0
    ior VIDEO_IPC
    setm line_count
    setm.b even
    ; activation interruption  SYNC_TIMER
    bclr SYNC_IFS, #SYNC_IF
    bset SYNC_IEC, #SYNC_IE
    ; activation timer
    bset SYNC_TMRCON, #TON
    return

;********************
; interruption TIMER2
; synchronisation    
;********************
.global __T2Interrupt
INT    
__T2Interrupt:
    push W0
    inc line_count
    bra z, 1f
    mov #6, W0
    cp line_count
    bra z, 2f
    mov #12, W0
    cp line_count
    bra z, 3f
    mov #18, W0
    cp line_count
    bra z, 4f
    mov #TOPLINE, W0
    cp line_count
    bra z, 5f
    mov #TOPLINE+YRES, W0
    cp line_count
    bra z, 6f
    mov #ELPFRM, W0
    cp line_count
    bra z, 7f
    mov #OLPFRM, W0
    cp line_count
    bra z, 8f
0:
    bclr SYNC_IFS, #SYNC_IF
    pop W0
    retfie
1: ; line_count==0 start VSYNC 6 half line narrow neg. pulses
    mov #SERATION, W0
    mov W0, SYNC_OCR
    mov #HALFLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra 0b
2: ; line_count==6 , 6 half line large neg. pulses
    mov #(HALFLINE-SERATION), W0
    mov W0, SYNC_OCR
    bra 0b
3: ; line_count==12 , 6 half line narrow neg. pulses
    mov #SERATION, W0
    mov W0, SYNC_OCR
    bra 0b
4: ; line_count==18 , end of VSYNC
    mov #HSYNC, W0
    mov W0, SYNC_OCR
    mov #HLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra 0b
5: ; line_count==TOPLINE  activation interruption video
    bclr VIDEO_IFS, #VIDEO_IF
    bset VIDEO_IEC, #VIDEO_IE
    bra 0b
6: ; line_count==TOPLINE+VIDEDO désactivaion int. video
    bclr VIDEO_IEC, #VIDEO_IE
    bra 0b
7: ; line_count==ELPFRM
    clr W0
    cp.b even
    bra z, 0b
    setm line_count
    clr.b even
    bra 0b
8: ;line_count==OLPFRM
    setm line_count
    setm.b even
    bra 0b

    
;*********************
; interruption OC2
; serialisation des pixels    
;*********************
.extern _font
.equ CH_ROW, W5    
.equ pVIDBUF, W4
.equ pFONT, W3
.equ CH_COUNT, W2    
.global __OC2Interrupt    
__OC2Interrupt:
    push.D W0
    push.D CH_COUNT
    push.D pVIDBUF
    push DSRPAG
    mov SYNC_TMR, W0
    and W0, #3, W0
    sl W0,W0
    bra W0
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    movpag #edspage(_font),DSRPAG
    mov line_count, W1
    sub #TOPLINE, W1
    and  W1,#7,CH_ROW
    lsr W1,#3,W1
    mov #CPL, CH_COUNT
    mul.uu CH_COUNT,W1, W0
    mov #_video_buffer, pVIDBUF
    add W0, pVIDBUF, pVIDBUF
    mov #edsoffset(_font), pFONT
 1:
    mov.b [pVIDBUF++], W0
    and  #127,W0
    sl W0, #3, W0
    add pFONT,W0,W1
    add W1,CH_ROW, W1
    mov.b [W1],W1
    ze W1, W1
2:
    btst VIDEO_SPISTAT, #SPITBF
    bra nz, 2b
    mov W1, VIDEO_SPIBUF
    dec CH_COUNT, CH_COUNT
    bra nz, 1b 
3:
    btst VIDEO_SPISTAT, #SPITBF
    bra nz, 3b
    clr VIDEO_SPIBUF
    pop DSRPAG
    pop.D pVIDBUF
    pop.D CH_COUNT
    pop.D W0
    bclr VIDEO_IFS, #VIDEO_IF
    retfie

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots Forth
;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;
; nettoie écran
;;;;;;;;;;;;;;;;;;
DEFCODE "CLS",3,,CLS   ; ( -- )
    mov #0x2020, W0
    mov #_video_buffer, W1
    repeat #(TV_BUFFER/2-1)
    mov W0,[W1++]
    clr xpos  ; xpos=0, ypos=0
    NEXT

;;;;;;;;;;;;;;;;;;;;;;
; définie position X
; du curseur texte
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "XPOS",4,, XPOS  ; ( n -- )
    mov #CPL-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
 1:
    mov.b WREG,xpos
    DPOP
    NEXT

;;;;;;;;;;;;;;;;;;;;;;
; définie position Y
; du curseur texte
;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "YPOS",4,,YPOS  ; ( n -- )
    cp T, #LPS
    bra ltu, 1f
    mov #(LPS-1), T
1:
    mov T, W0
    mov.b WREG,ypos
    DPOP
    NEXT
    
DEFWORD "CURPOS",6,,CURPOS  ; ( ny nx -- )
.word XPOS, YPOS, EXIT
    
;;;;;;;;;;;;;;;;;;;;;;
; place caractère 
; au sommet de la pile
; dans le buffer video    
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EMIT",4,,EMIT  ; ( c -- )
    cp T,#VK_RETURN
    bra neq, 1f
    DPOP
    bra crlf
1:    
    mov.b #CPL, W0
    mul.b ypos
    mov.b xpos, WREG
    ze W0,W0
    add W0,W2,W0
    mov #_video_buffer, W1
    add W0,W1,W1
    mov.b T, [W1]
    DPOP
    inc.b xpos
    mov #CPL, W0
    cp.b xpos
    bra neq, 2f
crlf:    
    clr.b xpos
    mov #(LPS-1), W0
    cp.b ypos
    bra eq, code_SCROLLUP
    inc.b ypos
2:    
    NEXT

;;;;;;;;;;;;;;;;;;;
; retour à la ligne
;;;;;;;;;;;;;;;;;;;;
DEFCODE "CR",2,,CR  ; ( -- )
    bra crlf

;;;;;;;;;;;;;;;;;;;;;;
; imprime un espace
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SPACE",5,,SPACE   ; ( -- )
    DPUSH
    mov #32, T
    bra code_EMIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; défile écran vers le haut
; d'une ligne texte.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SCROLLUP",8,,SCROLLUP  ; ( -- )
    mov #_video_buffer, W1
    mov #CPL, W0
    add W0,W1,W2
    mov #TV_BUFFER, W3
    sub W3,W0,W3
    lsr W3,W3
    dec W3,W3
    repeat W3
    mov [W2++],[W1++]
    DPUSH
    mov #(LPS-1), T
    bra code_CLRLN
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface la ligne indiquée
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "CLRLN",5,,CLRLN    ; ( n -- )
    mov #_video_buffer, W2
    mov #LPS, W0
    cp T, W0
    bra geu, 1f
    mov #CPL, W0
    mul.uu T, W0,W0
    add W0, W2,W2
    mov #0x2020, W0
    repeat #(CPL/2-1)
    mov W0, [W2++]
1:    
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime une chaîne de
; caractère à l'écran
;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
.word LIT, 0, DODO, DUP, CFETCH, EMIT, DOLOOP,-8,EXIT     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime l'entier au sommet de la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD ".",1,,DOT

.word    EXIT
    

    
.end

