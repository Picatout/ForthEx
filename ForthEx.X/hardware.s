;****************************************************************************
; Copyright 2015, 2016, 2017 Jacques Deschênes
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
    
.if (VIDEO_STD==NTSC)
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
    
.include "video.inc"
.include "core.inc"
    
.section .hardware.bss  bss
    
.global systicks , seed   
systicks: ; compteur de millisecondes
.space 2
seed: ; PRNG 32 bits    
.space 4
    
    
INTR    
; les interruptions non définies 
; réinitialisent le processeur    
.global __DefaultInterrupt
__DefaultInterrupt:
    reset

; vecteur de réinitialisation du processeur    
.section .start.text code address(0x200)
.global __reset    
__reset: 
    clr ANSELA    ; désactivation entrées analogiques
    mov #rstack, RSP
    mov #pstack, DSP
    mov DSP, W0
    sub #RSTK_GUARD, W0
    mov W0, SPLIM
    movpag #1,DSWPAG
    movpag #psvpage(_cold),DSRPAG
    mov #psvoffset(_cold),IP
    NEXT
    
.text
.global _cold    
_cold:
    .word HARDWARE_INIT,VARS_INIT
    .word VERSION,ZTYPE,CR  
    .word QUIT ; cette fonction ne quitte jamais

; initialisation matérielle    
HEADLESS HARDWARE_INIT, HWORD
    .word SET_CLOCK
    .word CLR_RAM    
    .word TICKS_INIT
    .word TVOUT_INIT
    .word KBD_INIT
    .word SERIAL_INIT
    .word STORE_INIT
    .word SOUND_INIT
    .word IO_LOCK
    .word KBD_RESET
    .word EXIT

; initialisation TIMER1
; utilisé pour compteur systicks    
HEADLESS TICKS_INIT
    ; diviseur prescale 1:8
    mov #(1<<TCKPS0),W0
    mov WREG,T1CON
    ; periode 1 msec
    mov #(FCY_MHZ*1000/8-1), W0
    mov W0, PR1
    ; priorité d'interruption 3
    mov #~(7<<T1IP0), W0
    and IPC0
    mov #(3<<T1IP0), W0
    ior IPC0
    ; activation de l'interruption
    bclr IFS0, #T1IF
    bset IEC0, #T1IE
    bset T1CON, #TON
    NEXT

; ajustement de la fréquence oscillateur.    
HEADLESS SET_CLOCK
    clr CLKDIV
    mov #PLLDIV, W0
    mov W0, PLLFBD
    bset OSCCON, #CLKLOCK ; verrouillage clock
    bclr INTCON1, #NSTDIS ; interruption multi-niveaux
    NEXT

; mise à zéro de la RAM
HEADLESS CLR_RAM
    mov #RAM_BASE+DSTK_SIZE+RSTK_SIZE, W0
    repeat #((RAM_SIZE-DSTK_SIZE-RSTK_SIZE)/2-1)
    clr [W0++]
    NEXT

; verouillage configuration I/O
HEADLESS IO_LOCK    
    bset OSCCON, #IOLOCK
    NEXT

; initialisation registres système forth
; initialisation variables utilisateur
HEADLESS VARS_INIT    
    mov #rstack, W0
    mov W0,_R0
    mov #pstack, W0
    mov W0, _S0
    mov #10, W0  ; base numérique par défaut: décimale
    mov W0, _BASE
    mov #pad, W0
    mov W0, _PAD
    mov #tib, W0
    mov W0, _TIB
    mov W0,_SOURCE
    mov #TIB_SIZE,W0
    mov W0,_SOURCE+2
    mov #USER_BASE, W0
    mov W0,_DP
    mov #_USER_VARS,UP
    movpag #psvpage(_sys_latest),DSRPAG
    mov #psvoffset(_sys_latest),W0
    mov [W0], W0 ; LFA du dernier mot système
    mov W0, _SYSLATEST
    mov W0, _LATEST
    NEXT

; empile le compteur systicks    
DEFCODE "TICKS",5,,TICKS,CMOVE  ; ( -- n )
    DPUSH
    mov systicks, T
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; délais en microsecondes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "USEC",4,,USEC,TICKS
    mov #TCY_USEC,W0
    dec T,T
    mul.uu T,W0,W0
    repeat W0
    nop
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  délais en millisecondes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "MSEC",4,,MSEC,USEC  ; ( n -- )
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
DEFCODE "LFSR",4,,LFSR,MSEC  ; ( -- )
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
DEFCODE "RAND",4,,RAND,LFSR   ; ( -- n)
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
DEFCODE "SRAND",5,,SRAND,RAND  ; ( -- )
    mov systicks,W0
    mov #3,W2
    div.u W0,W2
    mov W0, seed
    mov W1, seed+2
    NEXT
    
    
    
.end
    

