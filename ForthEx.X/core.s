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

.section _rstack,stack, address(PSV_BASE-RSTK_SIZE)
rstack:
.space RSTK_SIZE
    
    
INT    
.global __DefaultInterrupt
__DefaultInterrupt:
    reset

.section .start code   
.global __reset    
__reset: 
    ; mise à zéro de la RAM
    mov #RAM_BASE, W0
    mov #(RAM_SIZE/2-1), W1
    repeat W1
    clr [W0++]
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
    mov #psvoffset(sys_latest), W0
    mov W0, [UP+LATEST]
    mov #psvoffset(TEST), IP
    NEXT
    

.section .const psv   
;test string
version:
.asciz "ForthEx V0.1"    
    

.text    
ENTER:
    RPUSH IP
    mov [IP],IP
    NEXT
    
DEFCODE EXIT,4,,EXIT
    RPOP IP
    NEXT

    
;DEFWORD TEST,4,,TEST
.section .sysdict psv
TEST:
.word  code_CLS, code_INFINITE, EXIT

DEFCODE INFINITE,4,,INFINITE
    bra .
    
    
.text    
; test vidéo
test_video:    
    set_psv version, W1
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




    
    
SYSDICT
.global sys_latest
sys_latest:
.word link
    
    
.end

