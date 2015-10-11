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
;REF: http://www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt
;   http://www.bradrodriguez.com/papers/
;   msp430 camelForth source code: http://www.camelforth.com/download.php?view.25

    
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
.global DOCOLON    
DOCOLON:
    RPUSH IP
    mov WP,IP
    NEXT

DEFCODE "EXECUTE",7,,DOCODE
    mov T, WP
    DPOP
    goto WP
    
DEFCODE "EXIT",4,,EXIT
    RPOP IP
    NEXT

DEFCODE "LIT",5,,LIT  ; ( -- n )
    DPUSH
    mov [IP+0], T
    inc2 IP, IP
    NEXT

DEFCODE "CLIT",4,,CLIT  ; ( -- c )
    DPUSH
    mov.b [IP+0], T
    inc2 IP, IP
    ze T,T
    NEXT

DEFCODE "C@",2,,CFETCH  ; ( c-addr -- c )
    mov.b [T+0], T
    ze T, T
    NEXT
    
DEFCODE "C!",2,,CSTORE  ; ( c-addr c -- )
    ze T, W0
    DPOP
    mov.b W0,[T+0]
    DPOP
    NEXT
    
; branchement inconditionnel    
DEFCODE "DOBRA",5,,DOBRA  ; ( -- )
    mov [IP], IP
    NEXT
    
; branchement si T==0    
DEFCODE "DO0BRA",6,,DO0BRA ; ( n -- )
    cp0 T
    DPOP
    bra nz, 1f
    mov [IP], IP
    NEXT   
1:
    inc2 IP,IP
    NEXT

; exécution de DO    
DEFCODE "DODO",4,,DODO ; ( n  n -- ) R( -- n n )
    RPUSH I
    mov T, I
    DPOP
    RPUSH T
    DPOP
    NEXT

; exécution de LOOP   
DEFCODE "DOLOOP",6,,DOLOOP  ; ( -- )  R( n n -- )
    inc I, I
    cp I, R
    bra eq, 1f
    mov [IP+0], IP
1:
    RPOP I
    RDROP    
    NEXT

; empile compteur de boucle    
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

DEFCODE "DUP",3,,DUP ; ( n -- n n )
    DPUSH
    NEXT
    
DEFCODE "DROP",4,,DROP ; ( n -- )
    DPOP
    NEXT

DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
    mov T, W0
    mov [DSP+0], T
    mov W0, [DSP+0]
    NEXT

DEFCODE "ROT",3,,ROT
    mov T, W0
    mov [DSP+0], T
    mov [DSP-2], W1
    mov W1, [DSP+0]
    mov W0, [DSP-2]
    NEXT
    
DEFCODE "OVER",4,,OVER
    DPUSH
    mov [DSP-2],T
    NEXT

; MATH
DEFCODE "1+",1,,INC1
    add #1, T
    NEXT
    
DEFWORD "TEST",4,,TEST   
.word  CLS,HOME,OK,LIT,333, MSEC,HOME,OKOFF, LIT,333,MSEC,DOBRA, TEST+6

DEFWORD "SERTEST",7,,SERTEST
.word MSG,LIT,1000,MSEC,DOBRA,SERTEST+2    
    
DEFWORD "HOME",5,,HOME
.word LIT,0,LIT,0,CURPOS,EXIT
    
DEFWORD "OKOFF",6,,OKOFF
.word BL,BL,EXIT 
    
DEFWORD "OK",2,,OK
.word LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    

.section .const psv
quick:
.asciz "The quick brown fox jump over the lazy dog.\r\n"
DEFWORD "MSG",3,,MSG
.word LIT,quick,ZTYPE, EXIT    

DEFWORD "ZTYPE",5,,ZTYPE
.word DUP,CFETCH,DUP,DO0BRA,ZTYPEOUT,SEMIT,INC1,DOBRA,ZTYPE+2
ZTYPEOUT:
.word DROP,DROP, EXIT     
    
DEFCODE "INFLOOP",7,,INFLOOP
    bra .
    
SYSDICT
.global ENTRY
ENTRY: 
.word SERTEST
.global sys_latest
sys_latest:
.word link
    
    
.end

