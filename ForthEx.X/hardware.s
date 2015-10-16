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

.include "core.inc"
    
.data 
.global systicks    
systicks: ; compteur de millisecondes
.space 2
seed: ; PRNG 32 bits    
.space 4
    
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
    call serial_init
    call store_init
    ; verouillage configuration I/O
    bset OSCCON, #IOLOCK
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots forth
;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "TICKS",5,,TICKS  ; ( -- n )
    DPUSH
    mov systicks, T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  délais en millisecondes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "MSEC",4,,MSEC  ; ( n -- )
    mov systicks, W0
    add W0,T,W0
0:    
    cp systicks
    bra neq, 0b
    DPOP
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; générateur pseudo hazard
; génère un nombre de 16 bits
;  si seed impaire incrémente
;  ensuite Sn=(Sn-1)*3/2
;  on ne garde que le bit
;  le moins significatif
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "RAND",4,,RAND
    clr W2
    mov #15,W3
0:
    btss seed,#0
    bra 1f
    inc seed
    bra nc, 1f
    inc seed+2
 1:
    sl seed,WREG
    mov W0,W1
    rlc seed+2, WREG
    exch W0,W1
    add seed
    mov W1,W0
    addc seed+2
    lsr seed+2,
    rrc seed
    lsr seed, WREG
    rrc W3,W3
    dec W4,W4
    bra c, 1b
    DPUSH
    mov W3,T
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
;initialisation variable seed
; utilisation de l'ADC
; on ne garde que le bit 
; le plus faible de chaque
; lecture.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "SRAND",5,,SRAND
    ; initialisation du convertisseur
    
    NEXT
.end


