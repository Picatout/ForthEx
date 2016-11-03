;****************************************************************************
; Copyright 2015,2016 Jacques Deschênes
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
;   ANS FORTH 94: http://www.greenarraychips.com/home/documents/dpans94.pdf
    
    
.include "hardware.inc"
.include "core.inc"
.include "gen_macros.inc"
.include "sound.inc"
    
.global pstack, rstack, user
    
.section .core.bss bss
.global user    
    
.section .param.stack.bss, bss , address(RAM_BASE+RSTK_SIZE)    
pstack:
.space DSTK_SIZE

.section .return.stack.bss stack , address(RAM_BASE)
rstack:
.space RSTK_SIZE

.section .tib.bss bss
.global tib    
tib: .space TIB_SIZE
.section .pad.bss bss
.global pad 
pad: .space PAD_SIZE    
    
.section .user_dict bss  address(USER_BASE)
.global user 
user: .space RAM_SIZE-USER_BASE
    

.section .ver_str.const psv       
;test string
version:
.asciz "ForthEx V0.1\n"    
    
FORTH_CODE
.global ENTER    
ENTER: ; entre dans un mot de haut niveau (mot défini par ':')
    RPUSH IP   
    mov WP,IP
    NEXT

DEFCODE "EXIT",4,,EXIT  ; ( -- ) (R: nest-sys -- ) 6.1.1380  sortie mot haut-niveau.
    RPOP IP
    NEXT
    
DEFCODE "COLD",4,,COLD ; ( -- )  démarrage à froid
    reset
    

DEFCODE "WARM",4,,WARM   ; ( -- )  démarrage à chaud
__MathError:
    mov #pstack, DSP
    mov #rstack, RSP
    ; à faire: doit-remettre à zéro input buffer
    mov #edsoffset(COLD),IP
    mov #edsoffset(QUIT), WP
    mov [WP++], W0
    goto W0

    
DEFCODE "EXECUTE",7,,EXECUTE ; ( i*x xt -- j*x ) 6.1.1370 exécute le code à l'adresse xt
    mov T, WP
    DPOP
    mov [WP++],W0
    goto W0
    
DEFCODE "LIT",3,,LIT  ; ( -- x ) empile une valeur  
    DPUSH
    mov [IP++], T
    NEXT

DEFCODE "CLIT",4,,CLIT  ; ( -- c )
    DPUSH
    mov.b [IP], T
    ze T,T
    inc2 IP,IP ;IP doit toujours être aligné sur un mot de 16 bits
    NEXT

DEFCODE "@",1,,FETCH ; ( addr -- n )
    mov [T],T
    NEXT
    
DEFCODE "C@",2,,CFETCH  ; ( c-addr -- c )
    mov.b [T], T
    ze T, T
    NEXT
    
DEFCODE "!",1,,STORE  ; ( n  addr -- )
    mov [DSP--],W0
    mov W0,[T]
    DPOP
    NEXT
    
DEFCODE "C!",2,,CSTORE  ; ( c addr  -- )
    mov [DSP--],W0
    ze W0, W0
    mov.b W0,[T]
    DPOP
    NEXT
    
; branchement inconditionnel    
DEFCODE "BRANCH",5,,BRANCH  ; ( -- )
XBRAN:
    add IP, [IP], IP
    NEXT
    
; branchement si T==0    
DEFCODE "?BRANCH",6,,ZBRANCH ; ( n -- )
    cp0 T
    DPOP
    bra z, XBRAN
    inc2 IP,IP
    NEXT

; exécution de DO    
DEFCODE "(DO)",4,,DODO ; ( n  n -- ) R( -- n n )
    RPUSH I
    mov T, I
    mov [DSP--],[RSP++]
;    DPOP
;    RPUSH T
    DPOP
    NEXT

; exécution de LOOP   
DEFCODE "(LOOP)",6,,DOLOOP  ; ( -- )  R( n n -- )
    inc I, I
    mov [RSP-2],W0
    cp I, W0
    bra z, 1f
    add IP, [IP], IP
    NEXT
1:
    inc2 IP,IP
    RDROP    
    RPOP I
    NEXT

; empile compteur de boucle    
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

DEFCODE "J",1,,DOJ  ; ( -- n )
    DPUSH
    mov [RSP-4],T
    NEXT
    
DEFCODE "UNLOOP",6,,UNLOOP   ; R:( n1 n2 -- ) jette les arguments d'une boucle
    RDROP
    RPOP I
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; mots manipulant les arguments sur la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "DUP",3,,DUP ; ( n -- n n )
    DPUSH
    NEXT

DEFCODE "2DUP",4,,DDUP ; ( n1 n2 -- n1 n2 n1 n2 )
    mov [DSP],W0
    mov W0, [++DSP]
    NEXT
    
DEFCODE "?DUP",4,,QDUP ; ( n - n | n n )
    cp0 T
    bra z, 0f
    DPUSH
0:  NEXT
    
    
DEFCODE "DROP",4,,DROP ; ( n -- )
    DPOP
    NEXT

DEFCODE "2DROP",5,,DDROP ; ( n1 n2 -- )
    mov [DSP-2],T
    sub #4,DSP
    NEXT
    
DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
    mov T, W0
    mov [DSP], T
    mov W0, [DSP+0]
    NEXT

DEFCODE "2SWAP",6,,DSWAP ; ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
    mov [DSP-2],W0
    mov T,[DSP-2]
    mov W0, T
    mov [DSP-4],W0
    mov [DSP],W1
    mov W1, [DSP-4]
    mov W0, [DSP]
    NEXT
    
DEFCODE "ROT",3,,ROT  ; ( n1 n2 n3 -- n2 n3 n1 )
    mov T, W0
    mov [DSP], T
    mov [DSP-2], W1
    mov W1, [DSP]
    mov W0, [DSP-2]
    NEXT

DEFCODE "-ROT",4,,NROT ; ( n1 n2 n3 -- n3 n1 n2 )
    mov T, W0
    mov [DSP],T
    mov [DSP-2],W1
    mov W1,[DSP]
    mov W0,[DSP-2]
    NEXT
    
DEFCODE "OVER",4,,OVER  ; ( n1 n2 -- n1 n2 n1 )
    DPUSH
    mov [DSP-2],T
    NEXT
    
DEFCODE "NIP",3,,NIP   ; ( n1 n2 -- n2 )
    sub #2, DSP
    NEXT
    
DEFCODE ">R",2,,TOR   ;  ( n -- )  R:( -- n)
    RPUSH T
    DPOP
    NEXT
    
DEFCODE "R>",2,,RFROM  ; ( -- n ) R( n -- )
    DPUSH
    RPOP T
    NEXT

DEFCODE "R@",2,,RFETCH ; ( -- n ) R ( -- )
    DPUSH
    mov [RSP-2], T
    NEXT
    
DEFCODE "SP@",3,,SPFETCH ; ( -- n )
    DPUSH
    mov DSP, T
    NEXT
    
DEFCODE "SP!",3,,SPSTORE  ; ( n -- )
    mov T, DSP
    DPOP
    NEXT
    
DEFCODE "RP@",3,,RPFETCH  ; ( -- n )
    DPUSH
    mov RSP, T
    NEXT
    
DEFCODE "RP!",3,,RPSTORE  ; ( n -- )
    mov T, RSP
    DPOP
    NEXT
    
DEFCODE "TUCK",4,,TUCK  ; ( n1 n2 n3 -- n3 n1 n2 )
    mov T, W0
    mov [DSP], T
    mov [DSP-2], W1
    mov W0, [DSP-2]
    mov W1, [DSP]
    NEXT

    
;;;;;;;
; MATH
;;;;;;;
DEFCODE "+",1,,PLUS   ;( n1 n2 -- n1+n2 )
    add T, [DSP++], T
    NEXT
    
DEFCODE "-",1,,MINUS   ; ( n1 n2 -- n1-n2 )
    sub T, [DSP--], T
    NEXT
    
DEFCODE "1+",2,,ONEPLUS ; ( n -- n+1 )
    add #1, T
    NEXT

DEFCODE "2+",2,,TWOPLUS ; ( N -- N+2 )
    add #2, T
    NEXT
    
DEFCODE "1-",2,,ONEMINUS  ; ( n -- n-1 )
    sub #1, T
    NEXT
    
DEFCODE "2-",2,,TWOMINUS ; ( n -- n-2 )
    sub #2, T
    NEXT
    
DEFCODE "2*",2,,TWOSTAR  ; ( n -- n ) 2*n
    add T,T, T
    NEXT
    
DEFCODE "2/",2,,TWOSLASH ; ( n -- n ) n/2
    lsr T,T
    NEXT
    
DEFCODE "LSHIFT",6,,LSHIFT ; ( x1 -- x2 ) x2=x1<<1    
    sl T,T
    NEXT
    
DEFCODE "RSHIFT",6,,RSHIFT ; ( x1 -- x2 ) x2=x1>>1
    lsr T,T
    NEXT
    
DEFCODE "+!",2,,PLUSSTORE  ; ( n addr  -- ) [addr]=[addr]+n     
    mov [T], W0
    add W0, [DSP--],W0
    mov W0, [T]
    DPOP
    NEXT
    
DEFCODE "M+",2,,DADD  ; ( d n --  d ) simple + double
    mov [DSP-2], W0 ; d faible
    mov T, W1 ; n
    DPOP    ; T= d fort
    add W0,W1, [DSP]
    addc #0, T
    NEXT
 
DEFCODE "*",1,,MULTIPLY ; ( n1 n2 -- n1*n2) 
    mov T, W0
    DPOP
    mul.ss W0,T,W0
    mov W0,T
    NEXT
    
DEFCODE "/",1,,DIVIDE ; ( n1 n2 -- n1/n2 )
    mov [DSP--],W2
    repeat #17
    div.s W2,T
    mov W0, T
    NEXT
    
DEFCODE "/MOD",4,,DIVMOD ; ( n1 n2 -- r q )
    mov [DSP],W2
    repeat #17
    div.s W2,T
    mov W0,T     ; quotient
    mov W1,[DSP] ; reste
    NEXT
    
; opérations logiques bit à bit    
DEFCODE "AND",3,,_AND  ; ( n1 n2 -- n)  ET bit à bit
    and T,[DSP--],T
    NEXT
    
DEFCODE "OR",2,,_OR   ; ( n1 n2 -- n ) OU bit à bit
    ior T,[DSP--],T
    NEXT
    
DEFCODE "XOR",3,,_XOR ; ( n1 n2 -- n ) OU exclusif bit à bit
    xor T,[DSP--],T
    NEXT
    
    
DEFCODE "INVERT",6,,INVERT ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
DEFCODE "NEGATE",6,,NEGATE ; ( n - n ) complément à 2
    neg T, T
    NEXT

; comparaisons

DEFCODE "0=",2,,ZEROEQ  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT
    
DEFCODE "0<",2,,ZEROLT ; ( n -- f ) f= n<0
    setm W0
    add T,T,T
    subb T,T,T
    xor W0,T,T
    NEXT

DEFCODE "=",1,,EQUAL  ; ( n1 n2 -- f ) f= n1==n2
    clr W0
    cp T, [DSP--]
    bra nz, 1f
    com W0,W0
 1: 
    mov W0,T
    NEXT
    
DEFCODE "<>",2,,NEQUAL ; ( n1 n2 -- f ) f = n1<>n2
    clr W0
    cp T, [DSP--]
    bra z, 1f
    com W0,W0
1:  
    mov W0, T
    NEXT
    
 DEFCODE "<",1,,LESS  ; ( n1 n2 -- f) f= n1<n2
    clr W0
    cp T,[DSP--]
    bra le, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE ">",1,,GREATER  ; ( n1 n2 -- f ) f= n1>n2
    clr W0
    cp T,[DSP--]
    bra ge, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE "U<",2,,ULESS  ; (u1 u2 -- f) f= u1<u2
    clr W0
    cp T,[DSP--]
    bra leu, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE "U>",2,,UGREATER ; ( u1 u2 -- f) f=u1>u2
    clr W0
    cp T,[DSP--]
    bra geu, 1f
    com W0,W0
1:
    mov W0,T
    NEXT
    
    
DEFCODE "CELL",4,,CELL ; ( -- CELL_SIZE )
    DPUSH
    mov #CELL_SIZE, T
    NEXT
    
DEFCODE "CELL+",5,,CELLPLUS ; ( addr -- addr+CELL_SIZE )
    add #CELL_SIZE, T
    NEXT
    
DEFCODE "CELLS",5,,CELLS ; ( n -- n*CELL_SIZE )
    mul.uu T,#CELL_SIZE,W0
    mov W0,T
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  variables système
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFVAR "STATE",5,,STATE
DEFVAR "HERE",4,,HERE
DEFVAR "BASE",4,,BASE
DEFVAR "LATEST",6,,LATEST
DEFVAR "RBASE",5,,RBASE
DEFVAR "PBASE",5,,PBASE    
DEFVAR "PAD",3,,PAD
DEFVAR "TIB",3,,TIB    
DEFVAR "SOURCE-ID",9,,SOURCE_ID
DEFVAR ">IN",3,,INPTR
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes système
;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCONST "VERSION",7,,VERSION,version
DEFCONST "RAMEND",6,,RAMEND,RAM_END
DEFCONST "F_IMMED",7,,_F_IMMED,F_IMMED
DEFCONST "F_HIIDEN",8,,_F_HIDDEN,F_HIDDEN
DEFCONST "F_LENMASK",9,,_F_LENMASK,F_LENMASK    
DEFCONST "BL",2,,BL,32
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE 
DEFCONST "ULIMIT",6,,ULIMIT,RAM_END-1
    
DEFWORD "QUIT",4,,QUIT
    .word VERSION,ZTYPE,CR
    .word TIB,FETCH,INPTR,STORE
quit0:
    .word ACCEPT
    .word OK
    .word BRANCH
    DEST quit0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "TEST",4,,TEST   
.word  CLS,VERSION,HOME,OK,LIT,333, MSEC,HOME,OKOFF, LIT,333,MSEC,BRANCH, -22

DEFWORD "SERTEST",7,,SERTEST
.word CLS,VERSION,SGET,SEMIT,BRANCH,-6    

DEFWORD "ACCEPT",6,,ACCEPT
kbdtest0:
    .word KEY,DUP,LIT,13,NEQUAL,ZBRANCH
    DEST kbdtest1
    .word EMIT,BRANCH
    DEST kbdtest0 
kbdtest1:
    .word EXIT
    
DEFWORD "HOME",5,,HOME
.word LIT,0,LIT,0,CURPOS,EXIT
    
DEFWORD "OKOFF",6,,OKOFF
.word SPACE,SPACE,EXIT 
    
DEFWORD "OK",2,,OK
.word BL,EMIT,LIT, 'O', EMIT, LIT,'K',EMIT, CR, EXIT    

.section .quick_str.const psv
quick:
.asciz "The quick brown fox jump over the lazy dog.\r"

;DEFWORD "VERSION",7,,VERSION
;.word CLS,LIT,version,ZTYPE,CR,EXIT    

DEFWORD "ZTYPE",5,,ZTYPE
.word DUP,CFETCH,DUP,ZBRANCH,10,EMIT,ONEPLUS,BRANCH,-16
.word DROP,DROP, EXIT     

DEFWORD "QUICKTEST",9,,QUICKTEST
.word CLS,LIT,quick,ZTYPE,BRANCH,-2
    
DEFWORD "STRTEST",7,,STRTEST
.word CLS,LIT, quick, ZTYPE,LIT,_video_buffer,LIT,0,LIT,0,LIT,43,RSTORE,DELAY
.word CLS,DELAY,LIT, _video_buffer,LIT,0,LIT,0,LIT,43,RLOAD,DELAY,BRANCH, -26

DEFWORD "EEPROMTEST",10,,EEPROMTEST
.word CLS,LIT, quick, ZTYPE, LIT,500,MSEC, LIT, _video_buffer,LIT,43,ESTORE
.word CLS, DELAY, LIT, _video_buffer,LIT,100,ELOAD,BRANCH,-32

DEFWORD "LOOPTEST",8,,LOOPTEST
.word CLS,DELAY,LIT,'Z'+1,LIT,'A',DODO,DOI,EMIT,DOLOOP,-6,INFLOOP    

    
DEFWORD "CRTEST",6,,CRTEST
.word CLS,LIT,'A',DUP,EMIT,CR,ONEPLUS,DUP,LIT,'X',EQUAL,ZBRANCH,-18,INFLOOP    
    
DEFWORD "DELAY",5,,DELAY
.word  LIT, 500, MSEC, EXIT
    
;DEFWORD "INFLOOP",7,,INFLOOP
;.word  BRANCH, -2

DEFCODE "INFLOOP",7,,INFLOOP
    bra .

DEFWORD "FNTTEST",7,,FNTTEST
.WORD LIT,128,LIT,0,DODO, DOI, EMIT, DOLOOP,-6,CR,EXIT
    
DEFWORD "BOX",3,,BOX
.WORD CLIT,1,EMIT,CLIT,11,EMIT,CLIT,3,EMIT,CR,CLIT,14,EMIT,CLIT,7,EMIT,CLIT,15,EMIT
.WORD CR,CLIT,2,EMIT,CLIT,12,EMIT,CLIT,4,EMIT,CR,EXIT
    
SYSDICT
.global sys_latest
sys_latest:
.word link
    
    
.end

