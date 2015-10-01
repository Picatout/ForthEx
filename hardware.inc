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
.include "p24Fxxxx.inc"

.NOLIST

; sortie vidéo
.equ NTSC, 1
.equ PAL, 2
;sélection du standard vidéo NTSC ou PAL    
.equ VIDEO_STD, NTSC
    
.equ VIDEO_PORT, PORTB
.equ VIDEO_TRIS, TRISB
.equ VIDEO_OUT,  3
.equ VIDEO_OCR, OC2R
.equ VIDEO_OCRS, OC2RS
.equ VIDEO_OCCON, OC2CON
.equ VIDEO_RPOR, RPOR1
.equ VIDEO_RPORbit, RP3R0
.equ VIDEO_FN,  10
.equ VIDEO_IFS, IFS0
.equ VIDEO_IEC, IEC0
.equ VIDEO_IF,  OC2IF
.equ VIDEO_IE, OC2IE
.equ VIDEO_IPC, IPC1
.equ VIDEO_IPbit, OC2IP0
.equ VIDEO_SPICON1, SPI2CON1
.equ VIDEO_SPICON2, SPI2CON2
.equ VIDEO_SPISTAT, SPI2STAT
.equ VIDEO_SPIBUF, SPI2BUF
; synchronistation NTSC
.equ SYNC_PORT, PORTB
.equ SYNC_TRIS, TRISB
.equ SYNC_OUT,   4
.equ SYNC_TMR, TMR2
.equ SYNC_TMRCON, T2CON
.equ SYNC_PER, PR2
.equ SYNC_OCRS,  OC1RS
.equ SYNC_OCR, OC1R
.equ SYNC_OCCON, OC1CON
.equ SYNC_RPOR, RPOR2
.equ SYNC_RPORbit, RP4R0
.equ SYNC_FN,   18
.equ SYNC_IFS, IFS0
.equ SYNC_IEC, IEC0
.equ SYNC_IF,  T2IF
.equ SYNC_IE,  T2IE
.equ SYNC_IPC, IPC1
.equ SYNC_IPbit, T2IP0

; clavier
.equ KBD_CLK, RB15
.equ KBD_DAT, RB14
.equ KBD_PORT, PORTB
.equ KBD_LAT, LATB
.equ KBD_TRIS, TRISB
.equ KBD_RPINR, RPINR0
.equ KBD_PPSbit, INT1R0
.equ KBD_IFS, IFS1
.equ KBD_IF, INT1IF
.equ KBD_IEC, IEC1
.equ KBD_IE, INT1IE
.equ KBD_IPC, IPC5
.equ KBD_IPCbit, INT1IP0
.equ KBD_INTEP, INT1EP
.equ KBD_INTCON, INTCON2
.LIST


