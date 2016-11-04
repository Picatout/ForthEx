;****************************************************************************
; Copyright 2015,2016 Jacques Deschênes
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
    
.section .tvout.bss bss

.global video_on, xpos,ypos    
line_count: .space 2
even: .space 1
video_on: .space 1
.align 2 
xpos: .space 1
ypos: .space 1

 
.global _video_buffer
_video_buffer: .space TV_BUFFER_SIZE
 
.text
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialisation générateur vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global tvout_init
tvout_init:
    bclr VIDEO_TRIS, #VIDEO_OUT ; sortie vidéo
    bclr SYNC_TRIS, #SYNC_OUT  ; sortie sync vidéo
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
    mov #(3<<PPRE0)|(2<<SPRE0)|(1<<MSTEN),W0
    mov W0,VIDEO_SPICON1
    bset VIDEO_SPICON2, #SPIBEN
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
    ; configuraton output compare mode 5, clock=Fp
    mov #5|(7<<OCTSEL0), W0
    mov W0, SYNC_OCCON1
    mov W0, VIDEO_OCCON1
    ;configuration priorité d'interruptions
    ;priorité 5 pour les 2
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
    setm.b video_on
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
INTR    
__T2Interrupt:
    bclr SYNC_IFS, #SYNC_IF
    bclr VIDEO_SPISTAT, #SPIEN
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
    cp0.b video_on
    bra z, 0b
    bclr VIDEO_IFS, #VIDEO_IF
    bset VIDEO_IEC, #VIDEO_IE
    bra 0b
6: ; line_count==TOPLINE+VIDEDO désactivaion int. video
    bclr VIDEO_IEC, #VIDEO_IE
    bra 0b
7: ; line_count==ELPFRM
    cp0.b even
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
    bclr VIDEO_IFS, #VIDEO_IF
    push.D W0
    push.D CH_COUNT
    push.D pVIDBUF
    push DSRPAG
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
    mov VIDEO_TMR, W0
    and W0, #3, W0
    bra W0
    nop
    nop
    nop
    bset VIDEO_SPISTAT, #SPIEN
1:  cp0 CH_COUNT
    bra z, 3f
    mov.b [pVIDBUF++], W0
    and  #127,W0
    sl W0, #3, W0
    add pFONT,W0,W1
    add W1,CH_ROW, W1
    mov.b [W1],W0
 2:
    btst VIDEO_SPISTAT, #SPITBF
    bra nz, 2b
    mov.b WREG,VIDEO_SPIBUF
    dec CH_COUNT,CH_COUNT
    bra 1b
3:   
    btst VIDEO_SPISTAT, #SPITBF
    bra nz, 3b
    clr VIDEO_SPIBUF
    pop DSRPAG
    pop.D pVIDBUF
    pop.D CH_COUNT
    pop.D W0
    retfie

    

    
.end

