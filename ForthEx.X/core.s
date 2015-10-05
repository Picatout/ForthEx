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
;NOM: core.s
;Description: base pour le système Forth
;Date: 2015-10-03
 
.include "hardware.inc"
.include "core.inc"
.include "gen_macros.inc"
    
.global pstack, rstack, user
    
.data
user: ; variables utilisateur
.space 20
    
.section _pstack, bss, address(PSV_BASE-RSTK_SIZE-DSTK_SIZE)    
pstack:
.space DSTK_SIZE

.section _rstack, bss, address(PSV_BASE-RSTK_SIZE)
rstack:
.space RSTK_SIZE
    
    
INT    
.global __DefaultInterrupt
__DefaultInterrupt:
    reset

.section .start code   
.global __reset    
__reset: 
;    mov #RAM_BASE, W0
;    mov #(RAM_SIZE/2-1), W1
;    repeat W1
;    clr [W0++]
    ; modification du pointeur 
    ; de pile des retours
    mov #rstack, RSP
    mov #user, UP
    ; conserve adresse de la pile
    mov RSP, [UP+RBASE]
    call hardware_init
    mov #(PSV_BASE), W0
    mov W0, SPLIM
    mov #pstack, DSP
    mov DSP, [UP+PBASE]
    mov #10, W0
    mov W0, [UP+BASE]
; test vidéo
    call cls
    set_psv quick, W1
    mov #_video_buffer,W2
    clr W0
1:
    mov.b [W1++], W0
    ze W0,W0
    bra z, 2f
    mov.b W0, [W2++]
    bra 1b
2:    
; fin test vidéo
; test clavier
3:  
    push W2
    call kbd_get
    pop W2
    cp0 W0
    bra eq, 3b
    and #127, W0
    mov.b W0, [W2]
    bra 3b
    
    bra .

.section .const psv   
;test string
quick:
.ascii "01234567890123456789012345678901234567890123456789"    
.ascii "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.      "
.asciz "The quick brown fox jumps over the lazy dog.      " 

  
   

.text    
.global next    
next:
    mov [IP++], W
    goto W
 
    
.end

