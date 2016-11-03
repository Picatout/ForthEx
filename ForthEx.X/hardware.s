;****************************************************************************
; Copyright 2015, 2016 Jacques Deschênes
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
.include "ps2.inc"
    
.if (VIDEO_STD==NTSC)
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
    
.include "video.inc"
.include "core.inc"
    
.section .hardware.bss  bss
    
.global systicks    
systicks: ; compteur de millisecondes
.space 2
seed: ; PRNG 32 bits    
.space 4
    
    
INTR    
.global __DefaultInterrupt
__DefaultInterrupt:
    reset

.section .start.text code address(0x200)
.align 2    
.global __reset    
__reset: 
    ; mise à zéro de la RAM
    movpag #1, DSWPAG
    movpag #1, DSRPAG
    mov #RAM_BASE, W0
    mov #(RAM_SIZE/2-1), W1
    repeat W1
    clr [W0++]
    call hardware_init
    ; initialisation registres système forth
    mov #rstack, RSP
    mov #pstack, DSP
    mov DSP, SPLIM
    ; initialisation variables système
    mov RSP, var_RBASE
    mov DSP, var_PBASE
    mov #10, W0
    mov W0, var_BASE
    mov #pad, W0
    mov W0, var_PAD
    mov #tib, W0
    mov W0, var_TIB
    mov #USER_BASE, W0
    mov W0,var_HERE
    movpag #edspage(sys_latest),DSRPAG
    mov #edsoffset(sys_latest),W0
    mov [W0], W0
    mov W0, var_LATEST
    goto code_WARM
    
.text
.global hardware_init
hardware_init:
    clr CLKDIV
    mov #PLLDIV, W0
    mov W0, PLLFBD
    bset OSCCON, #CLKLOCK ; verrouillage clock
    bclr INTCON1, #NSTDIS ; interruption multi-niveaux
    clr ANSELA    ; désactivation entrées analogiques
    call tvout_init
    call ps2_init
    call serial_init
    call store_init
    call sound_init
    ; verouillage configuration I/O
    bset OSCCON, #IOLOCK
    ; réinitialise le clavier
    mov #KCMD_RESET,W0
    call ps2_send
    ; délais auto-test clavier 750 µsec.
    mov #TCY_USEC,W0
    mov #750,W1
    mul.uu W0,W1,W0
    repeat W0
    nop
;1:  btss key_state, #F_KBDOK
;    call kbd_error
    return

;kbd_error:
;    mov #440, W2  ; fréquence
;    mov #200, W1  ; durée
;    mov W2, AUDIO_PER
;    mov W2, AUDIO_OCRS
;    lsr W2,W0
;    mov W0, AUDIO_OCR
;    bset AUDIO_TMRCON, #TON
;    mov W1, tone_len
; 1: cp0 tone_len
;    bra nz, 1b
;    mov systicks, W0
;    add W0,W1,W0
; 2: cp systicks
;    bra neq, 2b
;    mov W2, AUDIO_PER
;    mov W2, AUDIO_OCRS
;    lsr W2,W0
;    mov W0, AUDIO_OCR
;    bset AUDIO_TMRCON, #TON
;    mov W1, tone_len
; 1: cp0 tone_len
;    bra nz, 1b
;    return
    
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
; générnateur pseudo-hasard
; basé sur une LFSR
;;;;;;;;;;;;;;;;;;;;;;;;;;;
.equ TAPSH, 0x8020
.equ TAPSL, 0x0002    
DEFCODE "LFSR",4,,LFSR  ; ( -- )
    lsr seed+2 
    rrc seed
    bra nc, 0f
    mov #TAPSH, W0
    xor seed+2
    mov #TAPSL, W0
    xor seed
0:    
    DPUSH
    mov seed, T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; générateur pseudo hazard
; génère un nombre de 16 bits
;  si seed impaire incrémente
;  ensuite Sn=(Sn-1)*3/2
;  on ne garde que le bit
;  le moins significatif
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "RAND",4,,RAND   ; ( -- n)
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
; seed=systicks/3
; seed+2=systicks%3    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "SRAND",5,,SRAND  ; ( -- )
    mov systicks,W0
    mov #3,W2
    div.u W0,W2
    mov W0, seed
    mov W1, seed+2
    NEXT


.end
    

