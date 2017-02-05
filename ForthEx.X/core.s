;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschênes
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
;   http://sinclairql.speccy.org/archivo/docs/books/Threaded_interpretive_languages.pdf    
;   http://www.exemark.com/FORTH/eForthOverviewv5.pdf
;   http://forthfiles.net/ting/sysguidefig.pdf    
    
    
.global pstack, rstack, user,tib,pad
    
.section .core.bss bss
.global user    
    
.section .param.stack.bss, bss , address(RAM_BASE+RSTK_SIZE)    
pstack:
.space DSTK_SIZE

.section .return.stack.bss stack , address(RAM_BASE)
rstack:
.space RSTK_SIZE

.section .buffers.bss bss
tib: .space TIB_SIZE
pad: .space PAD_SIZE
 
.section .user_vars.bss bss
.global _USER_VARS
_USER_VARS:    
.global _TIB    
_TIB: .space 2
.global _PAD 
_PAD: .space 2    
 .global _TICKSOURCE
; adresse et longueur du buffer d'évaluation
_TICKSOURCE: .space 2
; identifiant de la source: 0->interactif, -1, fichier
 .global _CNTSOURCE
_CNTSOURCE: .space 2
; pointeur data 
 .global _DP
_DP: .space 2 
; état interpréteur : 0 interactif, 1 compilation
 .global _STATE
_STATE: .space 2
; base numérique utilisée pour l'affichage des entiers
 .global _BASE
_BASE: .space 2
; pointeur position parser
 .global _TOIN
_TOIN: .space 2 
; adresse début pile arguments
 .global _S0
_S0: .space 2
; adresse début pile des retours
 .global _R0
_R0: .space 2
; pointeur HOLD conversion numérique
 .global _HP
_HP: .space 2
; LFA dernière entrée dans le dictionnaire utilisateur
 .global _LATEST
_LATEST: .space 2 
 .global _SYSLATEST
_SYSLATEST: .space 2
 
 
; dictionnaire utilisateur dans la RAM 
.section .user_dict bss  address(USER_BASE)
.global _user_dict 
_user_dict: .space RAM_SIZE-USER_BASE
    
; constantes dans la mémoire flash
.section .ver_str.const psv       
.global _version
_version:
.byte 12    
.ascii "ForthEx V0.1"    
.global _compile_only
_compile_only:
.ascii "compile only word"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mot système qui ne sont pas
; dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FORTH_CODE
    
    .global ENTER
ENTER: ; entre dans un mot de haut niveau (mot défini par ':')
    RPUSH IP   
    mov WP,IP
    NEXT

    .global DOUSER
DOUSER: ; empile pointeur sur variable utilisateur
    DPUSH
    mov [WP++],W0
    add W0,UP,T
    NEXT

    .section .sysdict psv
    .align 2
    .global name_EXIT
name_EXIT :
    .word 0
0:  .byte 4
    .ascii "EXIT"
    .align 2
    .global EXIT
EXIT:
    .word code_EXIT	; codeword
    FORTH_CODE
    .global code_EXIT
code_EXIT :			;pfa,  assembler code follows
    RPOP IP
    NEXT
   
    
HEADLESS LIT ; ( -- x ) empile une valeur  
    DPUSH
    mov [IP++], T
    NEXT

HEADLESS CLIT  ; ( -- c )
    DPUSH
    mov [IP++], T
    ze T,T
    NEXT

; branchement inconditionnel
HEADLESS BRANCH ; ( -- )
    add IP, [IP], IP
    NEXT
    
; branchement si T<>0
HEADLESS TBRANCH ; ( f -- )
    cp0 T
    DPOP
    bra nz, code_BRANCH
    inc2 IP,IP
    NEXT

; branchement si T==0
HEADLESS ZBRANCH ; ( f -- )
    cp0 T
    DPOP
    bra z, code_BRANCH
    inc2, IP,IP
    NEXT
    
    
; exécution de DO
HEADLESS DODO ; ( n  n -- ) R( -- n n )
    RPUSH LIMIT
    RPUSH I
    mov T, I
    DPOP
    mov T, LIMIT
    DPOP
    NEXT

; exécution de LOOP
HEADLESS DOLOOP ; ( -- )  R( n n -- )
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

; empile IP
HEADLESS IPFETCH  ; ( -- n )
    DPUSH
    mov IP,T
    NEXT
    
; T->IP
HEADLESS IPSTORE ; ( n -- )
    mov T,IP
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots qui sont dans le dictionnaire
; système
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
DEFCODE "REBOOT",6,,REBOOT ; ( -- )  démarrage à froid
    reset
    
    
DEFCODE "EXECUTE",7,,EXECUTE ; ( i*x cfa -- j*x ) 6.1.1370 exécute le code à l'adresse *cfa
    mov T, WP ; CFA
    DPOP
    mov [WP++],W0  ; code address
    goto W0

DEFCODE "@EXECUTE",8,,FEXEC   ; ( *addr -- ) exécute le code à l'adresse *T
    mov [T],W0
    DPOP
    mov #USER_BASE,W1
    cp W0,W1
    bra ltu, 1f
    goto W0
1:  NEXT    
    
DEFCODE "@",1,,FETCH ; ( addr -- n )
    mov [T],T
    NEXT
    
DEFCODE "C@",2,,CFETCH  ; ( c-addr -- c )
    mov.b [T], T
    ze T, T
    NEXT

DEFCODE "2@",2,,TWOFETCH ; ( addr -- n1 n2 ) double en mémoire en format little indian
    mov [T],W0 
    add #CELL_SIZE,T
    mov [T],T
    mov W0,[++DSP]
    NEXT
    
DEFCODE "!",1,,STORE  ; ( n  addr -- )
    mov [DSP--],[T]
    DPOP
    NEXT
    
DEFCODE "C!",2,,CSTORE  ; ( char c-addr  -- )
    mov [DSP--],w0
    mov.b W0,[T]
    DPOP
    NEXT
    
DEFCODE "2!",2,,TWOSTORE ; ( n1 n2 addr -- ) n2->addr, n1->addr+CELL_SÌZE
    mov [DSP--],[T]
    add #CELL_SIZE,T
    mov [DSP--],[T]
    DPOP
    NEXT
    
; empile compteur de boucle    
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

; empile compteur boucle externe    
DEFCODE "J",1,,DOJ  ; ( -- n )
    DPUSH
    mov [RSP-2],T
    NEXT
    
DEFCODE "UNLOOP",6,,UNLOOP   ; R:( n1 n2 -- ) n1=LIMIT_J, n2=J
    RPOP I
    RPOP LIMIT
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; mots manipulant les arguments sur la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

DEFWORD "LITERAL",7,F_IMMED,LITERAL  ; ( x -- ) 
        .word STATE,FETCH,ZBRANCH,LITER1-$
        .word LIT,LIT,COMPILE,COMPILE
LITER1: .word EXIT
    
DEFCODE "DUP",3,,DUP ; ( n -- n n )
    DPUSH
    NEXT

DEFCODE "2DUP",4,,TWODUP ; ( n1 n2 -- n1 n2 n1 n2 )
    mov [DSP],W0
    DPUSH
    mov W0,[++DSP]
    NEXT
    
DEFCODE "?DUP",4,,QDUP ; ( n - n | n n )
    cp0 T
    bra z, 1f
    DPUSH
1:  NEXT
    
    
DEFCODE "DROP",4,,DROP ; ( n -- )
    DPOP
    NEXT

DEFCODE "2DROP",5,,TWODROP ; ( n1 n2 -- )
    DPOP
    DPOP
    NEXT
    
DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
    mov T, W0
    mov [DSP], T
    mov W0, [DSP]
    NEXT

DEFCODE "2SWAP",5,,TWOSWAP ; ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
    mov [DSP-2],W0
    mov T,[DSP-2]
    mov W0, T
    mov [DSP-4],W0
    mov [DSP],W1
    mov W1, [DSP-4]
    mov W0, [DSP]
    NEXT
    
DEFCODE "ROT",3,,ROT  ; ( n1 n2 n3 -- n2 n3 n1 )
    mov [DSP], W0 ; n1
    exch T,W0   ; W0=n3, T=n2
    mov W0, [DSP]  ; n3
    mov [DSP-2],W0 ; n1
    exch W0,T ; T=n1, W0=n2
    mov W0,[DSP-2] 
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

DEFCODE "2OVER",5,,TWOOVER ; ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
    DPUSH
    mov [DSP-4],T
    mov [DSP-6],W0
    mov W0,[++DSP]
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

DEFCODE "R@",2,,RFETCH ; ( -- n ) (R: n -- n )
    DPUSH
    mov [RSP-2], T
    NEXT
    
DEFCODE "SP@",3,,SPFETCH ; ( -- n )
    mov DSP,W0
    DPUSH
    mov W0, T
    NEXT
    
DEFCODE "SP!",3,,SPSTORE  ; ( n -- )
    mov T, DSP
    NEXT
    
DEFCODE "RP@",3,,RPFETCH  ; ( -- n )
    DPUSH
    mov RSP, T
    NEXT
    
DEFCODE "RP!",3,,RPSTORE  ; ( n -- )
    mov T, RSP
    DPOP
    NEXT
    
DEFCODE "TUCK",4,,TUCK  ; ( n1 n2 -- n2 n1 n2 )
    mov [DSP], W0
    mov T, [DSP]
    mov W0,[++DSP]
    NEXT

DEFCODE "DEPTH",5,,DEPTH ; ( -- +n1 ) nombre d'élément sur la pile data avant que +n1 soit inséré
    mov _S0,W0
    sub DSP,W0,W0
    DPUSH
    lsr W0,T
    NEXT

DEFCODE "PICK",4,,PICK ; ( +n1 -- n ) copie le nième élément de la pile au sommet
    mov DSP,W0
    sl T,T
    sub W0,T,W0
    mov [W0],T
    NEXT
    
;;;;;;;;;;;;;;;;
;     MATH
;;;;;;;;;;;;;;;;
    
DEFWORD "HEX",3,,HEX ; ( -- )
    .word LIT,16,BASE,STORE,EXIT
    
DEFWORD "DECIMAL",7,,DECIMAL ; ( -- )
    .word LIT,10,BASE,STORE,EXIT
    
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
    
DEFCODE "LSHIFT",6,,LSHIFT ; ( x1 u -- x2 ) x2=x1<<u    
    mov T, W0
    DPOP
    dec W0,W0
    repeat W0
    sl T,T
    NEXT
    
DEFCODE "RSHIFT",6,,RSHIFT ; ( x1 u -- x2 ) x2=x1>>u
    mov T,W0
    DPOP
    dec W0,W0
    repeat W0
    lsr T,T
    NEXT
    
DEFCODE "+!",2,,PLUSSTORE  ; ( n addr  -- ) [addr]=[addr]+n     
    mov [T], W0
    add W0, [DSP--],W0
    mov W0, [T]
    DPOP
    NEXT
    
DEFCODE "M+",2,,MPLUS  ; ( d n --  d ) simple + double
    mov [DSP-2], W0 ; d faible
    mov T, W1 ; n
    DPOP    ; T= d fort
    add W0,W1, [DSP]
    addc #0, T
    NEXT
 
DEFCODE "*",1,,STAR ; ( n1 n2 -- n1*n2) 
    mov T, W0
    DPOP
    mul.ss W0,T,W0
    mov W0,T
    NEXT

DEFCODE "UM*",3,,UMSTAR ; ( u1 u2 -- ud )
    mul.uu T,[DSP],W0
    mov W1,T
    mov W0,[DSP]
    NEXT
    
;multiplication 32*16->32
; ud1 32 bits
; d2 16 bits
; ud3 32 bits    
DEFWORD "UD*",3,,UDSTAR  ; ( ud1 d2 -- ud3 ) 32*16->32    
    .word DUP,TOR,UMSTAR,DROP
    .word SWAP,RFROM,UMSTAR,ROT,PLUS,EXIT
    
DEFCODE "/",1,,DIVIDE ; ( n1 n2 -- n1/n2 )
    mov [DSP--],W2
    repeat #17
    div.s W2,T
    mov W0, T
    NEXT

DEFCODE "*/",2,,STARSLASH  ; ( n1 n2 n3 -- n4 ) n1*n2/n3, n4 quotient
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.s W0,T
    mov W0,T
    NEXT

DEFCODE "*/MOD",5,,STARSLASHMOD ; ( n1 n2 n3 -- n4 n5 ) n1*n2/n3, n4 reste, n5 quotient
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.s W0,T 
    mov W1,[++DSP]
    mov W0,T
    NEXT
    
DEFCODE "/MOD",4,,DIVMOD ; ( n1 n2 -- r q )
    mov [DSP],W2
    repeat #17
    div.sd W2,T
    mov W0,T     ; quotient
    mov W1,[DSP] ; reste
    NEXT

DEFCODE "UM/MOD",6,,UMSLASHMOD ; ( ud u -- r q )
    mov [DSP--],W1
    mov [DSP--],W0
    repeat #17
    div.ud W0,T
    mov W0,T
    mov W1,[++DSP]
    NEXT
    
DEFCODE "MAX",4,,MAX ; ( n1 n2 -- max(n1,n2)
    mov [DSP--],W0
    cp T,W0
    bra ge, 1f
    exch T,W0
1:  NEXT    
    
DEFCODE "MIN",4,,MIN ; ( n1 n2 -- min(n1,n2)
    mov [DSP--],W0
    cp W0,T
    bra ge, 1f
    exch T,W0
1:  NEXT
    
DEFCODE "WITHIN",6,,WITHIN ; ( u1 u2 u3 -- f ) u2<=u1<u3
    clr W0
    mov [DSP--],W2 ; u2
    mov [DSP--],W1 ; u1
    cp W1,W2
    bra ltu, 1f
    cp W1,T
    bra geu, 1f
    setm W0
1:  mov W0,T    
    NEXT
    
DEFCODE "EVEN",4,,EVEN ; ( n -- f ) vrai si n pair
    setm W0
    btsc T,#0
    clr W0
    mov W0,T
    NEXT
    
DEFCODE "ODD",3,,ODD ; ( n -- f ) vrai si n est impair
    setm W0
    btss T,#0
    clr W0
    mov W0,T
    NEXT
    
DEFCODE "ABS",3,,ABS ; ( n -- +n ) valeur absolue de n
    btsc T,#15
    neg T,T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; opérations logiques bit à bit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "AND",3,,AND  ; ( n1 n2 -- n)  ET bit à bit
    and T,[DSP--],T
    NEXT
    
DEFCODE "OR",2,,OR   ; ( n1 n2 -- n ) OU bit à bit
    ior T,[DSP--],T
    NEXT
    
DEFCODE "XOR",3,,XOR ; ( n1 n2 -- n ) OU exclusif bit à bit
    xor T,[DSP--],T
    NEXT
    
    
DEFCODE "INVERT",6,,INVERT ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
DEFCODE "NEGATE",6,,NEGATE ; ( n - n ) complément à 2
    neg T, T
    NEXT
    
;;;;;;;;;;;;;;;
; comparaisons
;;;;;;;;;;;;;;;
DEFCODE "0=",2,,ZEROEQ  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT
    
DEFCODE "0<",2,,ZEROLT ; ( n -- f ) f= n<0
    add T,T,T
    subb T,T,T
    com T,T
    NEXT

DEFCODE "0>",2,,ZEROGT ; ( n -- f ) f= n>0
    add T,T,T
    subb T,T,T
    NEXT
    
DEFCODE "=",1,,EQUAL  ; ( n1 n2 -- f ) f= n1==n2
    clr W0
    cp T, [DSP--]
    bra nz, 1f
    setm W0
 1: 
    mov W0,T
    NEXT
    
DEFCODE "<>",2,,NOTEQ ; ( n1 n2 -- f ) f = n1<>n2
    clr W0
    cp T, [DSP--]
    bra z, 1f
    com W0,W0
1:  
    mov W0, T
    NEXT
    
 DEFCODE "<",1,,LESS  ; ( n1 n2 -- f) f= n1<n2
    setm W0
    cp T,[DSP--]
    bra gt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE ">",1,,GREATER  ; ( n1 n2 -- f ) f= n1>n2
    setm W0
    cp T,[DSP--]
    bra lt, 1f
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

DEFCODE "ALIGNED",7,,ALIGNED ; ( addr -- a-addr ) aligne addresse sur nombre pair.
    btsc T,#0
    inc T,T
    NEXT
    
DEFCODE ">CHAR",5,,TOCHAR ; ( c -- c)
    and #127,T
    cp T,#32
    bra ge, 1f
    mov #'_',T
1:  NEXT
 
    
DEFWORD "HERE",4,,HERE
    .word DP,FETCH,EXIT

DEFWORD "IMMEDIATE",9,,IMMEDIATE
    .word LATEST,FETCH,DUP,SYSLATEST,FETCH,EQUAL,TBRANCH,1f-$
    .word DUP,CFETCH,IMMED,OR,CSTORE,EXIT
1:  .word DROP  
2:  .word EXIT
    
; copie un bloc mémoire    
DEFCODE "MOVE",4,,MOVE  ; ( addr1 addr2 u -- )
    mov T, W0 ; compte
    DPOP
    mov T, W2 ; destination
    DPOP
    mov T, W1 ; source
    DPOP
    cp0 W0
    bra z, 1f
    dec W0,W0
    repeat W0
    mov [W1++],[W2++]
1:  NEXT

; copie un bloc d'octets    
DEFCODE "CMOVE",5,,CMOVE  ;( c-addr1 c-addr2 u -- )
    mov T, W0 ; compte
    DPOP
    mov T, W2 ; destination
    DPOP
    mov T, W1 ; source
    DPOP
    cp0 W0
    bra z, 1f
    dec W0,W0
    repeat W0
    mov.b [W1++],[W2++]
1:  NEXT

; recherche du caractère 'c' dans le bloc
; mémoire 'c-addr' de dimension 'u'
; retourne la position de 'c' et
; le nombre de caractères qui suit dans le bloc
DEFCODE "SCAN"4,,SCAN ; ( c-addr u c -- c-addr' u' )
    mov T, W0   ; c
    DPOP        ; T=U
    mov [DSP],W1 ; W1=c-addr
    cp0 T
    bra z, 3f
1:  cp.b W0,[W1]
    bra z, 3f
    inc W1,W1
    dec T,T
    bra nz, 1b
3:  mov W1,[DSP]
    NEXT

    
; initialise un bloc mémoire
DEFCODE "FILL",4,,FILL ; ( addr u n -- )  for{0:(u-1)}-> m[T++]=n
    mov [DSP--],W0 ; n
    mov [DSP--],W1 ; u
    cp0 W1
    bra z, 1f
    dec W1,W1
    repeat W1
    mov W0,[T++]
1:  DPOP    
    NEXT
    
; initialise un bloc d'octets
DEFCODE "CFILL",5,,CFILL ; ( addr u b -- ) for{0:(u-1)} -> m[T++]=b
    mov [DSP--],W0
    mov [DSP--],W1
    cp0 W1
    bra z, 1f
    dec W1,W1
    repeat W1
    mov.b W0,[T++]
1:  DPOP    
    NEXT
    
; supprime tous les caractères <=32 à la fin d'une chaîne
; par des zéro
; u1 longueur initiale de la chaîne
; u2 longueur finale de laq chaîne    
DEFCODE "-TRAILING",9,,MINUSTRAILING ; ( addr u1 -- addr u2 )     
    mov [DSP],W0
    add W0,T,W0
    mov #33,W1
1:  dec W0,W0
    cp.b W1,[W0]
    bra gtu, 1f
    inc W0,W0
    sub W0,[DSP],T
    NEXT
 
; copie une chaine de caractère
; sur une adresse alignée
DEFWORD "PACK$",5,,PACKS ; ( src u dest -- a-dest )  copi src de longeur u vers aligned(dest)
    .word ALIGNED,DUP,TOR  ; src u a-dest R: a-dest
    .word OVER,DUP,LIT,0   ; src u a-dest u u 0
    .word LIT,2,UMSLASHMOD,DROP ; src u a-dest u r
    .word MINUS,OVER,PLUS ; src u a-dest a-dest+u
    .word LIT,0,SWAP,STORE ; src u a-dest
    .word TWODUP,CSTORE,LIT,1,PLUS ; src u a-dest+1
    .word SWAP,CMOVE,RFROM,EXIT ; ( -- a-dest)
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  variables système
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFVAR "STATE",5,,STATE   ; état compile=1/interprète=0
DEFVAR "DP",2,,DP         ; pointeur fin dictionnaire
DEFVAR "BASE",4,,BASE     ; base numérique
DEFVAR "SYSLATEST",9,,SYSLATEST ; tête du dictionnaire en FLASH    
DEFVAR "LATEST",6,,LATEST ; pointer dernier mot dictionnaire
DEFVAR "R0",2,,R0   ; base pile retour
DEFVAR "S0",2,,S0   ; base pile arguments   
DEFVAR "PAD",3,,PAD       ; tampon de travail
DEFVAR "TIB",3,,TIB       ; tampon de saisie clavier
DEFVAR ">IN",3,,TOIN     ; pointeur position début dernier mot retourné par WORD
DEFVAR "HP",2,,HP       ; HOLD pointer
DEFVAR "'SOURCE",6,,TICKSOURCE ; tampon source pour l'évaluation
DEFVAR "#SOURCE",7,,CNTSOURCE ; grandeur du tampon
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes système
;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCONST "VERSION",7,,VERSION,psvoffset(_version)        ; adresse chaîne version
DEFCONST "RAMEND",6,,RAMEND,RAM_END          ;  fin mémoire RAM
DEFCONST "IMMED",5,,IMMED,F_IMMED       ; drapeau mot immédiat
DEFCONST "HIDDEN",6,,HIDDEN,F_HIDDEN    ; drapeau mot caché
DEFCONST "LENMASK",7,,LENMASK,F_LENMASK ; masque longueur nom   
DEFCONST "BL",2,,BL,32                       ; caractère espace
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD
DEFCONST "ULIMIT",6,,ULIMIT,RAM_END-1        ; limite espace dictionnaire
DEFCONST "DOCOL",5,,DOCOL,psvoffset(ENTER)  ; pointeur vers ENTER

; addresse buffer pour l'évaluateur    
DEFCODE "'SOURCE",6,,TSOURCE ; ( -- c-addr u ) 
    DPUSH
    mov _TICKSOURCE,T
    DPUSH
    mov _CNTSOURCE,T
    NEXT

; sauvegarde les valeur de source    
DEFCODE "SOURCE!",7,,SRCSTORE ; ( c-addr u -- )
    mov T,_CNTSOURCE
    DPOP
    mov T,_TICKSOURCE
    DPOP
    NEXT

; vérifie si la chaîne commence
; avec un modificateur de base i.e. '$','%','#'
; fixe la base en conséquence
; ajustement de addr et n si requis  
DEFWORD "BASE?",5,,BASEQ ; ( addr n -- addr1 n1 | addr n )
    .word OVER,CFETCH,CLIT,'$',EQUAL,ZBRANCH,1f-$
    .word HEX,BRANCH,4f-$
1:  .word OVER,CFETCH,CLIT,'%',EQUAL,ZBRANCH, 3f-$
    .word LIT,2,BASE,STORE,BRANCH,4f-$
3:  .word OVER,CFETCH,CLIT,'#',EQUAL,ZBRANCH, 5f-$
    .word DECIMAL
4:  .word SWAP,ONEPLUS,SWAP,ONEMINUS    
5:  .word EXIT
  
; vérifie sit la chaine débute avec un '-'
; ajustement de addr et n si requis
DEFWORD "NEG?",4,,NEGQ ; ( addr n -- addr n | addr1 n1 R: sign )
    .word OVER,CFETCH,CLIT,'-',EQUAL,TOR
    .word SWAP,RFETCH,MINUS,SWAP,RFETCH,PLUS
    .word EXIT
    
; converti une chaîne en entier
; retourne entier et vrai ou addresse et faux  
DEFWORD "NUMBER?",7,,NUMBERQ ; (addr -- n T | addr F )
    .word BASE,FETCH,TOR,LIT,0,OVER,COUNT ;( a 0 addr+1 n) R: base
    .word BASEQ,NEGQ ;( a 0 b n) R: base sign
    .word QDUP, ZBRANCH, 4f-$ ; bout de la chaîne?
    ; boucle de conversion des digits
    .word LIT,0,SWAP,DODO ; ( a 0 b)
2:  .word DUP,TOR,CFETCH,BASE,FETCH,DIGITQ,TBRANCH,5f-$
    .word RFROM,DROP,UNLOOP,BRANCH,4f-$
5:  .word SWAP,BASE,FETCH,STAR,PLUS,RFROM,ONEPLUS,DOLOOP,2b-$
    .word DROP,RFETCH,ZBRANCH,7f-$
    .word NEGATE ; ( a n ) R: base sign
7:  .word SWAP ; ( n a ) R: base sign
4:  .word RFROM,TWODROP,RFROM, BASE,STORE,EXIT
    
;vérifie si le caractère est un digit
; si valide retourne la valeur du digit et -1
; si invalide retourne x 0
DEFWORD "DIGIT?",6,,DIGITQ ; ( c -- x 0 | n -1 )
    .word DUP,LIT,96,UGREATER,ZBRANCH,1f-$
    .word LIT,32,MINUS ; lettre minuscule? convertie en minuscule
1:  .word DUP,LIT,'9',UGREATER,ZBRANCH,3f-$
    .word DUP,LIT,'A',ULESS,ZBRANCH,2f-$
    .word LIT,0,EXIT ; pas un digit
2:  .word LIT,7,MINUS    
3:  .word LIT,'0',MINUS
    .word DUP,BASE,FETCH,ULESS,EXIT
  
;converti la chaîne en nombre
;en utilisant la valeur de BASE
;la conversion s'arrête au premier
;caractère non numérique
; <c-addr1 u1> spécifie le début et le nombre
; de caractères de la chaîne    
DEFWORD ">NUMBER",7,,TONUMBER ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
TONUM1: .word DUP,ZBRANCH,TONUM3-$
        .word OVER,CFETCH,DIGITQ
        .word ZEROEQ,ZBRANCH,TONUM2-$
        .word DROP,EXIT
TONUM2: .word TOR,TWOSWAP,BASE,FETCH,UDSTAR
        .word RFROM,MPLUS,TWOSWAP
        .word LIT,1,SLASHSTRING,BRANCH,TONUM1-$
TONUM3: .word EXIT
   
;vérifie s'il y a un signe '-'
; à la première postion de la chaîne spécifiée par <c-addr u>
; retourne f=2 si '-' sinon f=0    
; s'il y a un signe incrémente c-addr et décrémente u    
DEFWORD "?SIGN",5,,QSIGN ; ( c-addr u -- c-addr' u' f )
        .word OVER,CFETCH,LIT,',',MINUS,DUP,ABS
        .word LIT,1,EQUAL,AND,DUP,ZBRANCH,QSIGN1-$
        .word ONEPLUS,TOR,LIT,1,SLASHSTRING,RFROM
QSIGN1: .word EXIT
    
;conversion d'une chaîne en nombre
; c-address indique le début de la chaîne
; utilise la base active
DEFWORD "?NUMBER",7,,QNUMBER ; ( c-addr -- c-addr 0| n -1 )
        .word DUP,LIT,0,DUP,ROT,COUNT
        .word QSIGN,TOR,TONUMBER,ZBRANCH,QNUM1-$
        .word RFROM,TWODROP,TWODROP,LIT,0
        .word BRANCH,QNUM3-$
QNUM1:  .word TWODROP,NIP,RFROM,ZBRANCH,QNUM2-$
        .word NEGATE
QNUM2:  .word LIT,-1
QNUM3:  .word EXIT
    
;imprime la liste des mots du dictionnaire
DEFWORD "WORDS",5,,WORDS ; ( -- )
    .word CR,LATEST
1:  .word FETCH,DUP,ZEROEQ,TBRANCH,3f-$
    .word DUP,DUP,CFETCH,LENMASK,AND  ; NFA NFA LEN
    .word DUP,GETX,PLUS,LIT,64,ULESS,TBRANCH,2f-$
    .word CR
2:  .word TOR,ONEPLUS,RFROM,TYPE,SPACE,TWOMINUS,BRANCH,1b-$
3:  .word DROP,CR,EXIT
    
; convertie la chaîne comptée en majuscules
DEFCODE "UPPER",5,,UPPER ; ( c-addr -- )
    mov T, W1
    DPOP 
    mov.b [W1++],W2
1:  cp0.b W2
    bra z, 3f
    mov.b [W1++],W0
    dec.b W2,W2
    cp.b W0, #'a'
    bra ltu, 1b
    cp.b W0,#'z'
    bra gtu, 1b
    sub.b #32,W0
    mov.b W0,[W1-1]
    bra 1b
3:  NEXT

;avance au delà de 'c'
DEFCODE "SKIP",4,,SKIP ; ( addr u c -- addr' u' )
    mov T, W0 ; c
    DPOP ; T=u
    mov [DSP],W1 ; addr
2:  cp0 T
    bra z, 1f
    cp.b W0,[W1++]
    bra nz, 3f
    dec T,T
    bra 2b
3:  dec W1,W1    
1:  mov W1,[DSP]
    NEXT
  
; avance ajuste >IN
DEFWORD "ADR>IN",7,,ADRTOIN ; ( adr' -- )
    .word TSOURCE,ROT,ROT,MINUS,MIN,LIT,0,MAX
    .word TOIN,STORE,EXIT
    
;avance a de n caractères     
DEFWORD "/STRING",7,,SLASHSTRING ; ( a u n -- a+n u-n )
    .word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

    
DEFWORD "PARSE",5,,PARSE ; c -- c-addr n
        .word TSOURCE,TOIN,FETCH,SLASHSTRING ; c src' u'
        .word OVER,TOR,ROT,SCAN  ; src' u'
        .word OVER,SWAP,ZBRANCH, parse1-$ 
        .word ONEPLUS  ; char+
parse1: .word ADRTOIN ; adr'
        .word RFROM,TUCK,MINUS,EXIT 
    
    
; localise le prochain mot délimité par 'c'
; la variable TOIN indique la position courante
; le mot trouvé est copié dans lPAD 
; met à jour >IN
DEFWORD "WORD",4,,WORD ; ( c -- c-addr )
    .word DUP,TSOURCE,TOIN,FETCH,SLASHSTRING ; c c c-addr' u'
    .word ROT,SKIP ; c c-addr' u'
    .word DROP,ADRTOIN,PARSE
    .word HERE,TOCOUNTED,HERE
    .word BL,OVER,COUNT,PLUS,CSTORE,EXIT
    

; recherche un mot dans le dictionnaire
; retourne: c-addr 0 si adresse non trouvée
;           xt 1 trouvé mot immédiat
;	    xt -1 trouvé mot non-immédiat
.equ  LFA, W1 ; link field address
.equ  NFA, W2 ; name field addrress
.equ  TARGET,W3 ;pointer chaîne recherchée
.equ  LEN, W4  ; longueur de la chaîne recherchée
.equ CNTR, W5
.equ NAME, W6 ; nom dans dictionnaire 
.equ FLAGS,W7    
DEFCODE "FIND",4,,FIND ; ( c-addr -- c-addr 0 | cfa 1 | cfa -1 )
    mov T, TARGET
    DPUSH
    mov.b [TARGET++],LEN ; longueur
    mov _LATEST, NFA
try_next:
    cp0 NFA
    bra z, not_found
    dec2 NFA, LFA  
    mov.b [NFA++],W0 ; flags+name_lengh
    mov.b W0,FLAGS
    and.b #F_LENMASK,W0
    cp.b W0,LEN
    bra z, same_len
next_entry:    
    mov [LFA],NFA
    bra try_next
same_len:    
    ; compare les 2 chaînes
    mov TARGET,NAME
    mov.b LEN,CNTR
1:  cp0.b CNTR
    bra z, match
    mov.b [NAME++],W0
    cp.b W0,[NFA++]
    bra neq, next_entry
    dec.b CNTR,CNTR
    bra 1b
    ;trouvé 
match:
    btsc NFA,#0 ; alignement sur adresse paire
    inc NFA,NFA ; CFA
    mov NFA,[DSP] ; CFA
    setm T
    and.b #F_IMMED,FLAGS
    bra z, 2f
    neg T,T
    bra 2f
    ; pas trouvé
not_found:    
    mov #0,T
2:  NEXT
    
; lecture d'une ligne de texte au clavier
; c-addr addresse du buffer
; +n1 longueur du buffer
; +n2 longueur de la chaîne lue    
DEFWORD "ACCEPT",6,,ACCEPT  ; ( c-addr +n1 -- +n2 )
    .word OVER,PLUS,TOR,DUP  ;  ( c-addr c-addr  R: bound )
1:  .word KEY,DUP,LIT,13,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,32,OVER,CSTORE,SWAP,MINUS,ONEPLUS,RFROM,DROP,EXIT
2:  .word DUP,LIT,8,EQUAL,ZBRANCH,3f-$
    .word DROP,TWODUP,EQUAL,TBRANCH,1b-$
    .word BACKCHAR,ONEMINUS,BRANCH,1b-$
3:  .word OVER,RFETCH,EQUAL,TBRANCH,4f-$
    .word DUP,EMIT,OVER,CSTORE,ONEPLUS,BRANCH,1b-$
4:  .word DROP,BRANCH,1b-$
  
   
; retourne la spécification
; de la chaîne comptée dont
; l'adresse est dans T   
DEFWORD "COUNT",5,,COUNT ; ( c-addr1 -- c-addr2 u )
   .word DUP,CFETCH,TOR,ONEPLUS,RFROM,EXIT
   
; imprime 'mot ?'        
DEFWORD "ERROR",5,,ERROR ;  ( c-addr -- )  
   .word SPACE,COUNT,TYPE
   .word SPACE,CLIT,'?',EMIT
   .word LIT,0,STATE,STORE
   .word S0,FETCH,SPSTORE
   .word CR,QUIT

; copie chaîne comptée de src vers dest
DEFWORD ">COUNTED",8,,TOCOUNTED ; ( src n dest -- )
    .word TWODUP,CSTORE,ONEPLUS,SWAP,CMOVE,EXIT


DEFWORD "COMPILE",7,F_IMMED|F_COMPO,COMPILE  ; ( x -- ) compile x à la position DP
    .word HERE,DUP,TOR,STORE
    .word RFROM,CELLPLUS,DP,STORE,EXIT
    
    
; interprète la chaîne indiquée par
; c-addr u   
DEFWORD "INTERPRET",9,,INTERPRET ; ( c-addr u -- )
        .word SRCSTORE,LIT,0,TOIN,STORE
INTER1: .word BL,WORD,DUP,CFETCH,ZBRANCH,INTER9-$
;	.word COUNT,TYPE,CR,BRANCH,INTER1-$ ;test line
        .word FIND,QDUP,ZBRANCH,INTER4-$
        .word ONEPLUS,STATE,FETCH,ZEROEQ,OR
        .word ZBRANCH,INTER2-$
        .word EXECUTE,BRANCH,INTER3-$
INTER2: .word COMPILE
INTER3: .word BRANCH,INTER1-$
INTER4: .word QNUMBER,ZBRANCH,INTER5-$
        .word LITERAL,BRANCH,INTER1-$
INTER5: .word COUNT,TYPE,LIT,'?',EMIT,CR,ABORT
INTER9: .word DROP,EXIT

; interprète la chaîne à l'adrese 'c-addr' et de longueur 'u'
DEFWORD "EVALUATE",8,,EVAL ; ( i*x c-addr u -- j*x )
    .word TSOURCE,TOR,TOR ; sauvegarde source
    .word TOIN,FETCH,TOR,INTERPRET
    .word RFROM,TOIN,STORE,RFROM,RFROM,SRCSTORE 
    .word EXIT
    
; imprime le prompt et passe à la ligne suivante    
DEFWORD "OK",2,,OK  ; ( -- )
.word SPACE, LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    

    
DEFWORD "ABORT",5,,ABORT
    .word S0,FETCH,SPSTORE,QUIT
    
; si x1<>0 affiche message et appel ABORT
DEFWORD "ABORT\"",6,,ABORTQ ; ( i*x x1 -- i*x )
    .word ZBRANCH,2f-$
    .word IPFETCH,DUP,CFETCH,TWODUP,TOR,TOR
    .word SWAP,ONEPLUS,SWAP,TYPE
    .word RFROM,RFROM,PLUS,ONEPLUS,DUP,EVEN,TBRANCH,1f-$
    .word ONEPLUS
1:  .word IPSTORE,ABORT  
2:  .word EXIT
    
; boucle de l'interpréteur    
DEFWORD "QUIT",4,,QUIT ; ( -- )
1:  .word R0,FETCH,RPSTORE
    .word LIT,0,STATE,STORE
quit0:
    .word TIB,FETCH,DUP,LIT,CPL-1,ACCEPT ; ( addr u )
    .word SPACE,INTERPRET 
    .word STATE,FETCH,TBRANCH,quit1-$
    .word OK
quit1:
    .word CR
    .word BRANCH, quit0-$
    
; boucle sans fin    
DEFCODE "INFLOOP",7,,INFLOOP
    bra .

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;     OUTILS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Les mots suivants sont
;  des outils qui facilite
;  le débogage.
    
; imprime le contenu de la pile des arguments
; sans en affecté le contenu.
; FORMAT:  < n >  X1 X2 X3 ... Xn=T
;  n est le nombre d'éléments
;  Xn  valeur sur la pile.  
DEFWORD ".S",2,,DOTS  ; ( -- )
    .word DEPTH,CLIT,'<',EMIT,DUP,DOT,CLIT,'>',EMIT,SPACE
1:  .word QDUP,ZBRANCH,2f-$,DUP,PICK,DOT,ONEMINUS
    .word BRANCH,1b-$  
2:  .word EXIT
    

;lit et imprime une plage mémoire
; n nombre de mots à lire
; addr adresse de départ
; 8 mots par ligne d'affichage
DEFWORD "HDUMP",5,,HDUMP ; ( addr +n -- )
    .word QDUP,TBRANCH,3f-$,EXIT
3:  .word BASE,FETCH,TOR,HEX
    .word SWAP,LIT,0xFFFE,AND,SWAP,LIT,0,DODO
1:  .word DOI,LIT,7,AND,TBRANCH,2f-$
    .word CR,DUP,LIT,5,UDOTR,SPACE
2:  .word DUP,FETCH,LIT,5,UDOTR,LIT,2,PLUS
    .word DOLOOP,1b-$
    .word RFROM,BASE,STORE,EXIT

; affice le code source d'un mot qui est
; dans le dictionnaire
DEFWORD "SEE",3,F_IMMED,SEE ; ( <ccc> -- )    
    .word BL,WORD,FIND,TBRANCH,1f-$
    .word SPACE,LIT,'?',EMIT,DROP,EXIT
1:  .word DUP,FETCH,LIT,ENTER,EQUAL,TBRANCH,2f-$
    .word DROP,DOTQP
    .byte 9
    .ascii "code word"
    .align 2
    .word EXIT
2:  .word SEELIST,EXIT    

DEFWORD "CFA>NFA",7,,CFATONFA ; ( cfa -- nfa|0 )
    .word LIT, 0
    .word EXIT
  
; imprime la liste des mots qui construite une définition
; de HAUT-NIVEAU  
DEFWORD "SEELIST",7,F_IMMED,SEELIST ; ( cfa -- )
    .word BASE,FETCH,TOR,HEX,CR
    .word LIT,2,PLUS ; première adresse du mot 
1:  .word DUP,FETCH,DUP,CFATONFA,QDUP,ZBRANCH,NO_NAME-$
    .word COUNT,LIT,F_LENMASK,AND,TYPE
3:  .word LIT,EXIT,EQUAL,TBRANCH,2f-$
    .word LIT,2,PLUS,BRANCH,1b-$
NO_NAME:
    .word UDOT,BRANCH,3b-$
2:  .word DROP,RFROM,BASE,STORE,EXIT
  
;.end

