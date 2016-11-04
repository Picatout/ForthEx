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
; mot forth lié au matériel
    
    
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
    


