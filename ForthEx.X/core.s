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
.asciz "ForthEx V0.1"    
    
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
    
DEFCODE "C!",2,,CSTORE  ; ( char c-addr  -- )
    mov [DSP--],W0
    mov.b W0,[T]
    DPOP
    NEXT
    
; branchement inconditionnel    
DEFCODE "BRANCH",5,,BRANCH  ; ( -- )
XBRAN:
    add IP, [IP], IP
    NEXT
    
; branchement si T<>0    
DEFCODE "?BRANCH",7,,TBRANCH ; ( n -- )
    cp0 T
    DPOP
    bra nz, XBRAN
    inc2 IP,IP
    NEXT

; branchement si T==0
DEFCODE "ZBRANCH",7,,ZBRANCH ; ( n -- )
    cp0 T
    DPOP
    bra z, XBRAN
    inc2, IP,IP
    NEXT
    
    
; exécution de DO    
DEFCODE "(DO)",4,,DODO ; ( n  n -- ) R( -- n n )
    RPUSH LIMIT
    RPUSH I
    mov T, I
    DPOP
    mov T, LIMIT
    DPOP
    NEXT

; exécution de LOOP   
DEFCODE "(LOOP)",6,,DOLOOP  ; ( -- )  R( n n -- )
    inc I, I
    cp I, LIMIT
    bra z, 1f
    add IP, [IP], IP
    NEXT
1:
    inc2 IP,IP
    RPOP I    
    RPOP LIMIT
    NEXT

; empile compteur de boucle    
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

DEFCODE "J",1,,DOJ  ; ( -- n )
    DPUSH
    mov [RSP],T
    NEXT
    
DEFCODE "UNLOOP",6,,UNLOOP   ; R:( n1 n2 -- ) n1=LIMIT_J, n2=J
    RPOP I
    RPOP LIMIT
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; mots manipulant les arguments sur la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "DUP",3,,DUP ; ( n -- n n )
    DPUSH
    NEXT

DEFCODE "2DUP",4,,TWODUP ; ( n1 n2 -- n1 n2 n1 n2 )
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

DEFCODE "2DROP",5,,TWODROP ; ( n1 n2 -- )
    DPOP
    DPOP
    NEXT
    
DEFCODE "SWAP",4,,DOSWAP ; ( n1 n2 -- n2 n1)
    mov T, W0
    mov [DSP], T
    mov W0, [DSP]
    NEXT

DEFCODE "2SWAP",6,,TWOSWAP ; ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
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
    dec2 DSP,DSP
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
    add T, [DSP--], T
    NEXT
    
DEFCODE "-",1,,MINUS   ; ( n1 n2 -- n1-n2 )
    mov [DSP--],W0
    sub W0,T,T
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

DEFCODE "UMAX",4,,UMAX ; ( u1 u2 -- max(u1,u2)
    mov [DSP--],W0
    cp T,W0
    bra geu, 1f
    exch T,W0
1:  NEXT    
    
DEFCODE "UMIN",4,,UMIN ; ( u1 u2 -- min(u1,u2)
    mov [DSP--],w0
    cp W0,T
    bra geu, 1f
    exch T,W0
1:  NEXT
    
    
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

DEFWORD "HERE",4,,HERE
    .word DP,FETCH,EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mot forth I/O
;;;;;;;;;;;;;;;;;;;;;;;;;;    
.include "hardware_f.inc"
.include "TVout_f.inc"
.include "keyboard_f.inc"
.include "serial_f.inc"
.include "sound_f.inc"
.include "store_f.inc"
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  variables système
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFVAR "STATE",5,,STATE   ; état compile=1/interprète=0
DEFVAR "DP",4,,DP         ; pointeur fin dictionnaire
DEFVAR "BASE",4,,BASE     ; base numérique
DEFVAR "LATEST",6,,LATEST ; pointer dernier mot dictionnaire
DEFVAR "RBASE",5,,RBASE   ; base pile retour
DEFVAR "PBASE",5,,PBASE   ; base pile arguments   
DEFVAR "PAD",3,,PAD       ; tampon de travail
DEFVAR "TIB",3,,TIB       ; tampon de saisie clavier
DEFVAR "SOURCE-ID",9,,SOURCE_ID ; source de la chaîne traité par l'interpréteur
DEFVAR ">IN",3,,INPTR     ; pointeur position début dernier mot retourné par WORD
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes système
;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCONST "VERSION",7,,VERSION,version        ; adresse chaêine version
DEFCONST "RAMEND",6,,RAMEND,RAM_END          ;  fin mémoire RAM
DEFCONST "F_IMMED",7,,_F_IMMED,F_IMMED       ; drapeau mot immédiat
DEFCONST "F_HIIDEN",8,,_F_HIDDEN,F_HIDDEN    ; drapeau mot caché
DEFCONST "F_LENMASK",9,,_F_LENMASK,F_LENMASK ; masque longueur nom   
DEFCONST "BL",2,,BL,32                       ; caractère espace
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD
DEFCONST "ULIMIT",6,,ULIMIT,RAM_END-1        ; limite espace dictionnaire

; imprime une chaîne zéro terminée  ( c-addr -- )    
DEFWORD "ZTYPE",5,,ZTYPE
ztype0:    
.word DUP,CFETCH,DUP,ZBRANCH
DEST ztype1 
.word EMIT,ONEPLUS,BRANCH
DEST  ztype0
ztype1:    
.word DROP,DROP, EXIT     

; lecture d'une ligne de texte au clavier
DEFWORD "ACCEPT",6,,ACCEPT  ; ( c-addr +n1 -- +n2 )
        .word OVER,PLUS,OVER  ;( tib last ptr )
acc1:   .word KEY,DUP,LIT,13,EQUAL,TBRANCH
        DEST acc5
        .word DUP,LIT,8,NEQUAL,TBRANCH
        DEST acc3
        .word DROP,BACKCHAR,ONEMINUS,TOR,OVER,RFROM,UMAX
        .word BRANCH
        DEST acc1
acc3:   .word DUP,EMIT,OVER,CSTORE,ONEPLUS,OVER,UMIN
acc4:   .word BRANCH
        DEST acc1
acc5:   .word DROP,NIP,DOSWAP,MINUS,EXIT
        
    
   
; interprète une chaine    
DEFWORD "INTERPRET",9,,INTERPRET ; ( c-addr +n -- )
    .word CR,TYPE
    .word EXIT
    
; imprime le prompt et passe à la ligne suivante    
DEFWORD "OK",2,,OK  ; ( -- )
.word SPACE, LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    
    
; boucle de l'interpréteur    
DEFWORD "QUIT",4,,QUIT
    .word RBASE,FETCH,RPSTORE
    .word LIT,0,STATE,STORE
    .word VERSION,ZTYPE,CR
    .word TIB,FETCH,INPTR,STORE
quit0:
    .word TYPETEST,CR,BRANCH
    DEST quit0
    .word TIB, FETCH, DUP,LIT,CPL,ONEMINUS,ACCEPT
    .word SPACE, INTERPRET
    .word STATE, FETCH, ZEROEQ,ZBRANCH
    DEST quit1
    .word OK
quit1:
    .word CR
    .word BRANCH
    DEST quit0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "TEST",4,,TEST   
.word  CLS,VERSION,HOME,OK,LIT,333, MSEC,HOME,OKOFF, LIT,333,MSEC,BRANCH, -22

DEFWORD "SERTEST",7,,SERTEST
.word CLS,VERSION,SGET,SEMIT,BRANCH,-6    

DEFWORD "HOME",5,,HOME
.word LIT,0,LIT,0,CURPOS,EXIT
    
DEFWORD "OKOFF",6,,OKOFF
.word SPACE,SPACE,EXIT 
    

.section .quick_str.const psv
quick:
.asciz "The quick brown fox jump over the lazy dog."

;DEFWORD "VERSION",7,,VERSION
;.word CLS,LIT,version,ZTYPE,CR,EXIT    

DEFWORD "QUICKTEST",9,,QUICKTEST
.word LIT,quick,ZTYPE,EXIT
    
DEFWORD "STRTEST",7,,STRTEST
.word CLS,LIT, quick, ZTYPE,LIT,_video_buffer,LIT,0,LIT,0,LIT,43,RSTORE,DELAY
.word CLS,DELAY,LIT, _video_buffer,LIT,0,LIT,0,LIT,43,RLOAD,DELAY,BRANCH, -26

DEFWORD "EEPROMTEST",10,,EEPROMTEST
.word CLS,LIT, quick, ZTYPE, LIT,500,MSEC, LIT, _video_buffer,LIT,43,ESTORE
.word CLS, DELAY, LIT, _video_buffer,LIT,100,ELOAD,BRANCH,-32

DEFWORD "LOOPTEST",8,,LOOPTEST
.word LIT,'Z'+1,LIT,'A',DODO,DOI,EMIT,DOLOOP,-6,INFLOOP    

DEFWORD "TYPETEST",8,,TYPETEST
.word TIB,FETCH,DUP,LIT,63,ACCEPT,CR,TYPE,EXIT 
    
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


.section .link psv  address(0x7FFE)    
.global sys_latest
sys_latest:
.word link
    
.text    
    
.end

