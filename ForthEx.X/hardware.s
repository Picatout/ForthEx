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
; hardware setup
    
.include "hardware.inc"
.if VIDEO_STD==NTSC
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
    
.data 
.global systicks    
systicks:
.word 0
    
.text
.global hardware_init
hardware_init:
    bclr CORCON, #PSV
    clr W0
    mov W0, PSVPAG
    bset CORCON, #PSV ; espace programme visible en RAM
    clr CLKDIV
    bset OSCCON, #NOSC0
    bset OSCCON, #CLKLOCK ; verrouillage clock
    bclr INTCON1, #NSTDIS ; interruption multi-niveaux
    setm TRISA      ; port A tout en entrée
    setm TRISB      ; port B tout en entrée
    setm CNPU1       ;activation pullup
    setm CNPU2
    setm AD1PCFG    ; désactivation entrées analogiques
    call tvout_init
    call ps2_init
    call store_init
    ; verouillage configuration I/O
    bset OSCCON, #IOLOCK
    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  délais en millisecondes
;  entrée: W0 délais
; utilise W0,W1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
.global delay_msec    
delay_msec:    
    mov systicks, W1
    add W1,W0,W1
 1:
    mov systicks, W0
    cp W0, W1
    bra neq, 1b
    return

.end


