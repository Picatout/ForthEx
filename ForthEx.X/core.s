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
.align 2    
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
    mov #psvoffset(ENTRY), IP
    NEXT
    

.section .const psv       
;test string
version:
.asciz "ForthEx V0.1"    
    
.text    
DOCOLON:
    RPUSH IP
    mov WP,IP
    NEXT
    
DEFCODE "EXIT",4,,EXIT
    RPOP IP
    NEXT

DEFCODE "DOLIT",2,,DOLIT
    DPUSH
    mov [IP++], T
    NEXT

DEFCODE "DOBRA",5,,DOBRA
    mov [IP++], W0
    goto W0
    
DEFCODE "DO0BRA",6,,DO0BRA
    mov T, W1
    DPOP
    cp0 W1
    bra nz, 1f
    mov [IP++], W0
    goto W0
1:
    inc2 IP
    NEXT

DEFCODE "DODO",4,,DODO
    RPUSH
    mov I, RP
    mov T, I
    DPOP
    RPUSH
    mov T, RP
    DPOP
    
    NEXT

DEFCODE "DOLOOP",6,,DOLOOP
    DPUSH
    mov I, T
    
    
DEFWORD "TEST",4,,TEST   
.word  CLS,OK,INFLOOP
    
DEFWORD "OK",2,,OK
.word BL,DOLIT, 'O', EMIT, DOLIT,'K',EMIT, EXIT    

DEFCODE "INFLOOP",7,,INFLOOP
    bra .
    
    
SYSDICT
.global ENTRY
ENTRY: 
.word TEST
.global sys_latest
sys_latest:
.word link
    
    
.end

