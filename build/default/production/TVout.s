# 1 "TVout.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "TVout.S"
;****************************************************************************
; Copyright 2015, Jacques Deschênes
; This file is part of ForthEx.
;
; ForthEx is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; ForthEx is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with ForthEx. If not, see <http:
;
;****************************************************************************
; vidéo NTSC B/W sur PIC24FJ64G002
; T2 période ligne horizontale
; OC1 sortie sync sur RPB4
; OC2 contrôle début sortie vidéo
; sortie vidéo sur RPB3

.include "hardware.inc"
.include "video.inc"
.if VIDEO_STD==NTSC
.include "ntsc_const.inc"
.else
.include "pal_const.inc"
.endif

; constantes génération signal NTSC




.data
.global _T2counter
_T2counter: .space 2 ; compte les interruptions T2
line_count: .word 0xffff
even: .byte 0xff

.global _video_buffer
_video_buffer: .space TV_BUFFER


.text

;********************
; interruption TIMER2
;********************
.global __T2Interrupt
__T2Interrupt:
    push W0
    inc _T2counter
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
5: ; line_count==TOPLINE activation interruption video
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
;*********************
.extern _font
.equ CH_ROW, W5
.equ pVIDBUF, W4
.equ pFONT, W3
.equ CH_COUNT, W2
.global __OC2Interrupt
__OC2Interrupt:
    push W0
    push W1
    push CH_COUNT
    push pFONT
    push pVIDBUF
    push CH_ROW
    push PSVPAG
    mov SYNC_TMR, W0
    and W0, #3, W0
    sl W0,#1, W0
    bra W0
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    mov #psvpage(_font),W0
    mov W0, PSVPAG
    mov line_count, W1
    sub #TOPLINE, W1
    and W1,#7,CH_ROW
    lsr W1,#3,W1
    mov #CPL, CH_COUNT
    mul.uu CH_COUNT,W1, W0
    mov #_video_buffer, pVIDBUF
    add W0, pVIDBUF, pVIDBUF
 1:
    mov #psvoffset(_font), pFONT
    mov.b [pVIDBUF++], W0
    ze W0,W0
    sl W0, #3, W0
    add pFONT,W0,pFONT
    add pFONT,CH_ROW, pFONT
    mov.b [pFONT],W1
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
    pop PSVPAG
    pop CH_ROW
    pop pVIDBUF
    pop pFONT
    pop CH_COUNT
    pop W1
    pop W0
    bclr VIDEO_IFS, #VIDEO_IF
    retfie


.end
