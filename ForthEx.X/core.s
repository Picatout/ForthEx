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
;   http://sinclairql.speccy.org/archivo/docs/books/Threaded_interpretive_languages.pdf    
    
.include "hardware.inc"
.include "core.inc"
.include "gen_macros.inc"
.include "sound.inc"
    
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
 .global _SOURCE
; adresse et longueur du buffer d'évaluation
_SOURCE: .space 4
; identifiant de la source: 0->interactif, -1, fichier
 .global _SOURCE_ID
_SOURCE_ID: .space 2
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
.asciz "ForthEx V0.1"    
.global _compile_only
_compile_only:
    .ascii "compile only word"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mot système qui ne sont pas
; dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
FORTH_CODE


 .global __MathError,_warm
_warm:	   ; ( -- )  démarrage à chaud
__MathError:
    mov #pstack, DSP
    mov #rstack, RSP
    mov #edsoffset(ABORT),IP
    NEXT
    
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
    
    .section .sysdict psv
    .align 2
    .global name_EXIT
name_EXIT :
    .word 0
    .byte 4
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
    
DEFCODE "REBOOT",6,,REBOOT,EXIT ; ( -- )  démarrage à froid
    reset
    
    
DEFCODE "EXECUTE",7,,EXECUTE,REBOOT; ( i*x xt -- j*x ) 6.1.1370 exécute le code à l'adresse xt
    mov T, WP
    DPOP
    mov [WP++],W0
    goto W0
    
DEFCODE "@",1,,FETCH,EXECUTE ; ( addr -- n )
    mov [T],T
    NEXT
    
DEFCODE "C@",2,,CFETCH,FETCH  ; ( c-addr -- c )
    mov.b [T], T
    ze T, T
    NEXT

DEFCODE "2@",2,,TWOFETCH,CFETCH ; ( addr -- n1 n2 )
    mov [T],W0
    add #CELL_SIZE,T
    mov [T],[++DSP]
    mov W0,T
    NEXT
    
DEFCODE "!",1,,STORE,TWOFETCH  ; ( n  addr -- )
    mov [DSP--],[T]
    DPOP
    NEXT
    
DEFCODE "C!",2,,CSTORE,STORE  ; ( char c-addr  -- )
    mov [DSP--],w0
    mov.b W0,[T]
    DPOP
    NEXT
    
DEFCODE "2!",2,,TWOSTORE,CSTORE ; ( n1 n2 addr -- ) n2->addr, n1->addr+CELL_SÌZE
    mov [DSP--],[T]
    add #CELL_SIZE,T
    mov [DSP--],[T]
    DPOP
    NEXT
    
; empile compteur de boucle    
DEFCODE "I",1,,DOI,TWOSTORE  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

; empile compteur boucle externe    
DEFCODE "J",1,,DOJ,DOI  ; ( -- n )
    DPUSH
    mov [RSP-2],T
    NEXT
    
DEFCODE "UNLOOP",6,,UNLOOP,DOJ   ; R:( n1 n2 -- ) n1=LIMIT_J, n2=J
    RPOP I
    RPOP LIMIT
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; mots manipulant les arguments sur la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "DUP",3,,DUP,UNLOOP ; ( n -- n n )
    DPUSH
    NEXT

DEFCODE "2DUP",4,,TWODUP,DUP ; ( n1 n2 -- n1 n2 n1 n2 )
    mov [DSP],W0
    DPUSH
    mov W0,[++DSP]
    NEXT
    
DEFCODE "?DUP",4,,QDUP,TWODUP ; ( n - n | n n )
    cp0 T
    bra z, 0f
    DPUSH
0:  NEXT
    
    
DEFCODE "DROP",4,,DROP,QDUP ; ( n -- )
    DPOP
    NEXT

DEFCODE "2DROP",5,,TWODROP,DROP ; ( n1 n2 -- )
    DPOP
    DPOP
    NEXT
    
DEFCODE "SWAP",4,,SWAP,TWODROP ; ( n1 n2 -- n2 n1)
    mov T, W0
    mov [DSP], T
    mov W0, [DSP]
    NEXT

DEFCODE "2SWAP",5,,TWOSWAP,SWAP ; ( n1 n2 n3 n4 -- n3 n4 n1 n2 )
    mov [DSP-2],W0
    mov T,[DSP-2]
    mov W0, T
    mov [DSP-4],W0
    mov [DSP],W1
    mov W1, [DSP-4]
    mov W0, [DSP]
    NEXT
    
DEFCODE "ROT",3,,ROT,TWOSWAP  ; ( n1 n2 n3 -- n2 n3 n1 )
    mov T, W0
    mov [DSP], T
    mov [DSP-2], W1
    mov W1, [DSP]
    mov W0, [DSP-2]
    NEXT

DEFCODE "-ROT",4,,NROT,ROT ; ( n1 n2 n3 -- n3 n1 n2 )
    mov T, W0
    mov [DSP],T
    mov [DSP-2],W1
    mov W1,[DSP]
    mov W0,[DSP-2]
    NEXT
    
DEFCODE "OVER",4,,OVER,NROT  ; ( n1 n2 -- n1 n2 n1 )
    DPUSH
    mov [DSP-2],T
    NEXT

DEFCODE "2OVER",5,,TWOOVER,OVER ; ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
    DPUSH
    mov [DSP-4],T
    mov [DSP-6],W0
    mov W0,[++DSP]
    NEXT
    
DEFCODE "NIP",3,,NIP,TWOOVER   ; ( n1 n2 -- n2 )
    dec2 DSP,DSP
    NEXT
    
DEFCODE ">R",2,,TOR,NIP   ;  ( n -- )  R:( -- n)
    RPUSH T
    DPOP
    NEXT
    
DEFCODE "R>",2,,RFROM,TOR  ; ( -- n ) R( n -- )
    DPUSH
    RPOP T
    NEXT

DEFCODE "R@",2,,RFETCH,RFROM ; ( -- n ) (R: n -- n )
    DPUSH
    mov [RSP-2], T
    NEXT
    
DEFCODE "SP@",3,,SPFETCH,RFETCH ; ( -- n )
    mov DSP,W0
    DPUSH
    mov W0, T
    NEXT
    
DEFCODE "SP!",3,,SPSTORE,SPFETCH  ; ( n -- )
    mov T, DSP
    DPOP
    NEXT
    
DEFCODE "RP@",3,,RPFETCH,SPSTORE  ; ( -- n )
    DPUSH
    mov RSP, T
    NEXT
    
DEFCODE "RP!",3,,RPSTORE,RPFETCH  ; ( n -- )
    mov T, RSP
    DPOP
    NEXT
    
DEFCODE "TUCK",4,,TUCK,RPSTORE  ; ( n1 n2 -- n2 n1 n2 )
    mov [DSP], W0
    mov T, [DSP]
    mov W0,[++DSP]
    NEXT

DEFCODE "DEPTH",5,,DEPTH,TUCK ; ( -- +n1 ) nombre d'élément sur la pile data avant que +n1 soit inséré
    mov _S0,W0
    sub DSP,W0,W0
    DPUSH
    lsr W0,T
    NEXT
    
;;;;;;;;;;;;;;;;
;     MATH
;;;;;;;;;;;;;;;;
    
DEFWORD "HEX",3,,HEX,DEPTH ; ( -- )
    .word LIT,16,BASE,STORE,EXIT
    
DEFWORD "DECIMAL",7,,DECIMAL,HEX ; ( -- )
    .word LIT,10,BASE,STORE,EXIT
    
DEFCODE "+",1,,PLUS,DECIMAL   ;( n1 n2 -- n1+n2 )
    add T, [DSP--], T
    NEXT
    
DEFCODE "-",1,,MINUS,PLUS   ; ( n1 n2 -- n1-n2 )
    mov [DSP--],W0
    sub W0,T,T
    NEXT
    
DEFCODE "1+",2,,ONEPLUS,MINUS ; ( n -- n+1 )
    add #1, T
    NEXT

DEFCODE "2+",2,,TWOPLUS,ONEPLUS ; ( N -- N+2 )
    add #2, T
    NEXT
    
DEFCODE "1-",2,,ONEMINUS,TWOPLUS  ; ( n -- n-1 )
    sub #1, T
    NEXT
    
DEFCODE "2-",2,,TWOMINUS,ONEMINUS ; ( n -- n-2 )
    sub #2, T
    NEXT
    
DEFCODE "2*",2,,TWOSTAR,TWOMINUS  ; ( n -- n ) 2*n
    add T,T, T
    NEXT
    
DEFCODE "2/",2,,TWOSLASH,TWOSTAR ; ( n -- n ) n/2
    lsr T,T
    NEXT
    
DEFCODE "LSHIFT",6,,LSHIFT,TWOSLASH ; ( x1 u -- x2 ) x2=x1<<u    
    mov T, W0
    DPOP
    dec W0,W0
    repeat W0
    sl T,T
    NEXT
    
DEFCODE "RSHIFT",6,,RSHIFT,LSHIFT ; ( x1 u -- x2 ) x2=x1>>u
    mov T,W0
    DPOP
    dec W0,W0
    repeat W0
    lsr T,T
    NEXT
    
DEFCODE "+!",2,,PLUSSTORE,RSHIFT  ; ( n addr  -- ) [addr]=[addr]+n     
    mov [T], W0
    add W0, [DSP--],W0
    mov W0, [T]
    DPOP
    NEXT
    
DEFCODE "M+",2,,ADDPLUS,PLUSSTORE  ; ( d n --  d ) simple + double
    mov [DSP-2], W0 ; d faible
    mov T, W1 ; n
    DPOP    ; T= d fort
    add W0,W1, [DSP]
    addc #0, T
    NEXT
 
DEFCODE "*",1,,MULTIPLY,ADDPLUS ; ( n1 n2 -- n1*n2) 
    mov T, W0
    DPOP
    mul.ss W0,T,W0
    mov W0,T
    NEXT
    
DEFCODE "/",1,,DIVIDE,MULTIPLY ; ( n1 n2 -- n1/n2 )
    mov [DSP--],W2
    repeat #17
    div.s W2,T
    mov W0, T
    NEXT

DEFCODE "*/",2,,STARSLASH,DIVIDE   ; ( n1 n2 n3 -- n4 ) n1*n2/n3, n4 quotient
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.s W0,T
    mov W0,T
    NEXT

DEFCODE "*/MOD",5,,STARSLASHMOD,STARSLASH ; ( n1 n2 n3 -- n4 n5 ) n1*n2/n3, n4 reste, n5 quotient
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.s W0,T 
    mov W1,[++DSP]
    mov W0,T
    NEXT
    
DEFCODE "/MOD",4,,DIVMOD,STARSLASHMOD ; ( n1 n2 -- r q )
    mov [DSP],W2
    repeat #17
    div.sd W2,T
    mov W0,T     ; quotient
    mov W1,[DSP] ; reste
    NEXT

DEFCODE "UMAX",4,,UMAX,DIVMOD ; ( u1 u2 -- max(u1,u2)
    mov [DSP--],W0
    cp T,W0
    bra geu, 1f
    exch T,W0
1:  NEXT    
    
DEFCODE "UMIN",4,,UMIN,UMAX ; ( u1 u2 -- min(u1,u2)
    mov [DSP--],w0
    cp W0,T
    bra geu, 1f
    exch T,W0
1:  NEXT
    
DEFCODE "EVEN",4,,EVEN,UMIN ; ( n -- f ) vrai si n pair
    setm W0
    btsc T,#0
    clr W0
    mov W0,T
    NEXT
    
DEFCODE "ODD",3,,ODD,EVEN ; ( n -- f ) vrai si n est impair
    setm W0
    btss T,#0
    clr W0
    mov W0,T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; opérations logiques bit à bit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "AND",3,,AND,ODD  ; ( n1 n2 -- n)  ET bit à bit
    and T,[DSP--],T
    NEXT
    
DEFCODE "OR",2,,OR,AND   ; ( n1 n2 -- n ) OU bit à bit
    ior T,[DSP--],T
    NEXT
    
DEFCODE "XOR",3,,XOR,OR ; ( n1 n2 -- n ) OU exclusif bit à bit
    xor T,[DSP--],T
    NEXT
    
    
DEFCODE "INVERT",6,,INVERT,XOR ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
DEFCODE "NEGATE",6,,NEGATE,INVERT ; ( n - n ) complément à 2
    neg T, T
    NEXT
    
;;;;;;;;;;;;;;;
; comparaisons
;;;;;;;;;;;;;;;
DEFCODE "0=",2,,ZEROEQ,NEGATE  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT
    
DEFCODE "0<",2,,ZEROLT,ZEROEQ ; ( n -- f ) f= n<0
    add T,T,T
    subb T,T,T
    com T,T
    NEXT

DEFCODE "0>",2,,ZEROGT,ZEROLT ; ( n -- f ) f= n>0
    add T,T,T
    subb T,T,T
    NEXT
    
DEFCODE "=",1,,EQUAL,ZEROGT  ; ( n1 n2 -- f ) f= n1==n2
    clr W0
    cp T, [DSP--]
    bra nz, 1f
    setm W0
 1: 
    mov W0,T
    NEXT
    
DEFCODE "<>",2,,NOTEQ,EQUAL ; ( n1 n2 -- f ) f = n1<>n2
    clr W0
    cp T, [DSP--]
    bra z, 1f
    com W0,W0
1:  
    mov W0, T
    NEXT
    
 DEFCODE "<",1,,LESS,NOTEQ  ; ( n1 n2 -- f) f= n1<n2
    setm W0
    cp T,[DSP--]
    bra gt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE ">",1,,GREATER,LESS  ; ( n1 n2 -- f ) f= n1>n2
    setm W0
    cp T,[DSP--]
    bra lt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE "U<",2,,ULESS,GREATER  ; (u1 u2 -- f) f= u1<u2
    clr W0
    cp T,[DSP--]
    bra leu, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
DEFCODE "U>",2,,UGREATER,ULESS ; ( u1 u2 -- f) f=u1>u2
    clr W0
    cp T,[DSP--]
    bra geu, 1f
    com W0,W0
1:
    mov W0,T
    NEXT
    
    
DEFCODE "CELL",4,,CELL,UGREATER ; ( -- CELL_SIZE )
    DPUSH
    mov #CELL_SIZE, T
    NEXT
    
DEFCODE "CELL+",5,,CELLPLUS,CELL ; ( addr -- addr+CELL_SIZE )
    add #CELL_SIZE, T
    NEXT
    
DEFCODE "CELLS",5,,CELLS,CELLPLUS ; ( n -- n*CELL_SIZE )
    mul.uu T,#CELL_SIZE,W0
    mov W0,T
    NEXT

DEFWORD "HERE",4,,HERE,CELLS
    .word DP,FETCH,EXIT

DEFWORD "IMMEDIATE",9,,IMMEDIATE,HERE
    .word LATEST,FETCH,DUP,SYSLATEST,FETCH,EQUAL,TBRANCH
    DEST 1f
    .word TWOPLUS,DUP,CFETCH,IMMED,OR,CSTORE,BRANCH
    DEST 2f
1:  .word DROP  
2:  .word EXIT
    
; copie un bloc mémoire    
DEFCODE "MOVE",4,,MOVE,IMMEDIATE  ; ( addr1 addr2 u -- )
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
DEFCODE "CMOVE",5,,CMOVE,MOVE  ;( c-addr1 c-addr2 u -- )
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

    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mot forth I/O
;;;;;;;;;;;;;;;;;;;;;;;;;;    
.include "hardware.inc"
.include "video.inc"
.include "keyboard.inc"
.include "serial.inc"
.include "sound.inc"
.include "store.inc"
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  variables système
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFVAR "STATE",5,,STATE,ELOAD   ; état compile=1/interprète=0
DEFVAR "DP",2,,DP,STATE         ; pointeur fin dictionnaire
DEFVAR "BASE",4,,BASE,DP     ; base numérique
DEFVAR "SYSLATEST",9,,SYSLATEST,BASE ; tête du dictionnaire en FLASH    
DEFVAR "LATEST",6,,LATEST,SYSLATEST ; pointer dernier mot dictionnaire
DEFVAR "R0",2,,R0,LATEST   ; base pile retour
DEFVAR "S0",2,,S0,R0   ; base pile arguments   
DEFVAR "PAD",3,,PAD,S0       ; tampon de travail
DEFVAR "TIB",3,,TIB,PAD       ; tampon de saisie clavier
DEFVAR ">IN",3,,TOIN,TIB     ; pointeur position début dernier mot retourné par WORD
DEFVAR "HP",2,,HP,TOIN       ; HOLD pointer
DEFVAR "SOURCE-ID",9,,SOURCE_ID,HP ; tampon source pour l'évaluation
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes système
;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCONST "VERSION",7,,VERSION,psvoffset(_version),HP        ; adresse chaîne version
DEFCONST "RAMEND",6,,RAMEND,RAM_END,VERSION          ;  fin mémoire RAM
DEFCONST "IMMED",5,,IMMED,F_IMMED,RAMEND       ; drapeau mot immédiat
DEFCONST "HIDDEN",6,,HIDDEN,F_HIDDEN,IMMED    ; drapeau mot caché
DEFCONST "LENMASK",7,,LENMASK,F_LENMASK,HIDDEN ; masque longueur nom   
DEFCONST "BL",2,,BL,32,LENMASK                       ; caractère espace
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE,BL       ; grandeur tampon TIB
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE,TIBSIZE       ; grandeur tampon PAD
DEFCONST "ULIMIT",6,,ULIMIT,RAM_END-1,PADSIZE        ; limite espace dictionnaire
DEFCONST "DOCOL",5,,DOCOL,psvoffset(ENTER),ULIMIT  ; pointeur vers ENTER

; addresse buffer pour l'évaluateur    
DEFCODE "SOURCE",6,,SOURCE,DOCOL ; ( -- c-addr u ) 
    DPUSH
    mov _SOURCE,T
    DPUSH
    mov _SOURCE+2,T
    NEXT

; sauvegarde les valeur de source    
DEFCODE "SOURCE!",7,,SRCSTORE,SOURCE ; ( c-addr u -- )
    mov T,_SOURCE+2
    DPOP
    mov T,_SOURCE
    DPOP
    NEXT
    
    
;vérifie si le caractère est un digit
;valide dans la base B
; si valide retourne la valeur du digit et -1
; si invalide retourne 0
DEFWORD "?DIGIT",6,,QDIGIT,SRCSTORE ; ( c B -- 0| n -1 )
    .word SWAP,CLIT,'0',MINUS,DUP,ZEROLT,TBRANCH
    DEST not_digit
    .word DUP,LIT,10,ULESS,TBRANCH
    DEST base_test
    .word LIT,7,MINUS
base_test:
    .word DUP,ROT,ULESS,ZBRANCH
    DEST 1f
    .word LIT,-1,BRANCH
    DEST 2f
not_digit:
    .word DROP
1:  .word DROP,LIT,0
2:  .word EXIT
    
;converti la chaîne en nombre
;en utilisant la valeur de BASE
;la conversion s'arrête au premier
;caractère non numérique
; <c-addr1 u1> spécifie le début et le nombre
; de caractères de la chaîne    
DEFWORD ">NUMBER",7,,TONUMBER,QDIGIT ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
    .word BASE,FETCH,TOR
1:  .word DUP,ZEROEQ,TBRANCH
    DEST 4f
    
4:    
    .word EXIT
    
;vérifie s'il y a un signe '-'|'+'
; à la première postion de la chaîne spécifiée par <c-addr u>
; retourne -1 si '-', retourne 1 si '+' autrement retourne 0    
; s'il y a un signe incrémente c-addr et décrémente u    
DEFWORD "?SIGN",5,,QSIGN,TONUMBER ; ( c-addr u -- c-addr u 0|-1|1 )
    .word OVER,FETCH,DUP,CLIT,'-',EQUAL,ZBRANCH
    DEST 1f
    .word DROP,LIT,-1,TOR, BRANCH
    DEST 2f
1: .word CLIT,'+',EQUAL,ZBRANCH
    DEST 3f
   .word LIT,1,TOR
2: .word  TOR, ONEPLUS,RFROM, ONEMINUS,RFROM,BRANCH
    DEST 4f
3: .word LIT,0
4:  .word EXIT
    
;conversion d'une chaîne en nombre
; c-address indique le début de la chaîne
; utilise la base active
DEFWORD "?NUMBER",7,,QNUMBER,QSIGN ; ( c-addr -- c-addr 0| n -1 )
    .word DUP,LIT,0,DUP,ROT,COUNT ; c-addr 0 0 c-addr u
    .word QSIGN,TOR,TONUMBER   
    
    .word EXIT
    
;imprime la liste des mots du dictionnaire
DEFWORD "WORDS",5,,WORDS,QNUMBER ; ( -- )
    .word CR,LATEST
1:  .word FETCH,DUP,ZEROEQ,TBRANCH
    DEST words_exit
    .word DUP,TWOPLUS,DUP,CFETCH,LENMASK,AND
    .word DUP,GETX,PLUS,LIT,64,ULESS,TBRANCH
    DEST 2f
    .word CR
2:  .word TOR,ONEPLUS,RFROM,TYPE,SPACE,BRANCH
    DEST 1b
;    .word GETX,LIT,54,ULESS,TBRANCH
;    DEST 2f
;    .word CR
;2:  .word DUP,TWOPLUS,DUP,CFETCH,LENMASK,AND,TOR,ONEPLUS,RFROM,TYPE,SPACE
;    .word BRANCH
;    DEST 1b
words_exit:
    .word DROP,CR,EXIT
    
; imprime une chaîne zéro terminée  ( c-addr -- )    
DEFWORD "ZTYPE",5,,ZTYPE,WORDS
ztype0:  
.word DUP,CFETCH,DUP,ZBRANCH
DEST ztype1 
.word EMIT,ONEPLUS,BRANCH
DEST  ztype0
ztype1:    
.word TWODROP, EXIT     

; convertie la chaîne comptée en majuscules
DEFCODE "UPPER",5,,UPPER,ZTYPE  ; ( c-addr -- )
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
    
; localise le prochain mot délimité par 'c'
; la variable TOIN indique la position courante
; le mot trouvé est copié dans lPAD 
; met à jour TOIN    
DEFCODE "WORD",4,,WORD,UPPER  ; ( c -- c-addr)
    mov #_PAD,W2 ; current dest pointer
    mov W2,W3  ; PAD[0]
    mov #_TIB,W0 ; TIB address
    add #TIB_SIZE,W0 ; TIB end
    mov W0,W4 ; limit
    mov _TOIN,W1 
1:  cp W1,W4  
    bra geu, 4f 
    mov.b [W1],W0
    cp0.b W0
    bra z,4f
    inc W1,W1
    cp.b w0,T
    bra z, 1b
2:  mov.b W0,[++W2]
    cp W1,W4
    bra geu, 4f
    mov.b [W1],W0
    cp0.b W0
    bra z, 4f
    inc W1,W1
    cp.b W0,T
    bra neq, 2b
4:  mov W1, _TOIN
    mov W3,T
    sub W2,T,W2
    mov.b W2,[T]
    NEXT

; recherche un mot dans le dictionnaire
; retourne: c-addr 0 si adresse non trouvée
;           xt 1 trouvé mot immédiat
;	    xt -1 trouvé mot non-immédiat
.equ  LINK, W1
.equ  NFA, W2
.equ  TARGET,W3 ;pointer chaîne recherchée
.equ  LEN, W4  ; longueur de la chaîne recherchée
.equ CNTR, W5
.equ NAME, W6 ; nom dans dictionnaire 
.equ FLAGS,W7    
DEFCODE "FIND",4,,FIND,WORD ; ( c-addr -- c-addr 0 | xt 1 | xt -1 )
    mov #_LATEST, LINK
    mov LINK,W0
    mov T, TARGET
    DPUSH
    mov.b [TARGET++],LEN ; longueur
try_next:
    mov [LINK],W0
    cp0 W0
    bra z, not_found
    mov W0,LINK
    inc2 W0,NFA  ; W3=NFA
    mov.b [NFA++],W0 ; flags+name_lengh
    mov.b W0,FLAGS
    and.b #F_LENMASK,W0
    cp.b W0,LEN
    bra nz, try_next
    ; compare les 2 chaînes
    mov TARGET,NAME
    mov.b LEN,CNTR
1:  cp0.b CNTR
    bra z, match
    mov.b [NAME++],W0
    cp.b W0,[NFA++]
    bra neq, try_next
    dec.b CNTR,CNTR
    bra 1b
    ;trouvé 
match:
    btsc NFA,#0 ; alignement sur adresse paire
    inc NFA,NFA ; CFA
    mov NFA,[DSP] ; XT
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
; c-addre addresse du buffer
; +n1 longueur du buffer
; +n2 longueur de la chaîne lue    
DEFWORD "ACCEPT",6,,ACCEPT,FIND  ; ( c-addr +n1 -- +n2 )
        .word OVER,DUP,TOIN,STORE,PLUS,OVER  ; 2,3,4,5,3,2,3 ( c-addr bound cursor )
acc1:   .word TWODUP,EQUAL,TBRANCH ; 3,5,4,3
        DEST acc6
        .word KEY,DUP,LIT,13,EQUAL,TBRANCH ; 3,4,5,6,5,4 ( c-addr bound cursor c )
        DEST acc5
        .word DUP,LIT,8,EQUAL,ZBRANCH ; 4,5,6,5,4 ( c-addr bound cursor c )
        DEST acc3
	.word DROP,BACKCHAR,ONEMINUS,BRANCH ; 4,3,3,3
        DEST acc1
acc3:	.word DUP,EMIT,OVER,CSTORE,ONEPLUS ;4,5,4,5,3,3
        .word BRANCH
        DEST acc1
acc5:   .word DROP; 4,3
acc6:   .word LIT,0,OVER,CSTORE,NIP,SWAP,MINUS,EXIT ; 3,2,2,1

; retourne la spécification
; de la chaîne comptée dont
; l'adresse est dans T   
DEFWORD "COUNT",5,,COUNT,ACCEPT ; ( c-addr1 -- c-addr2 u )
   .word DUP,CFETCH,TOR,ONEPLUS,RFROM,EXIT
   
; imprime 'mot ?'        
DEFWORD "ERROR",5,,ERROR,COUNT ;  ( c-addr -- )  
   .word SPACE,COUNT,TYPE
   .word SPACE,CLIT,'?',EMIT
   .word LIT,0,STATE,STORE
   .word S0,FETCH,SPSTORE
   .word EXIT
   
; interprète une chaine  la chaîne indiquée par
; c-addr u   
DEFWORD "INTERPRET",9,,INTERPRET,ERROR ; ( c-addr u -- )
interp1:    
    .word BL,WORD,DUP,CFETCH,ZEROEQ,TBRANCH ; 0,1,1,2,2,2,1
    DEST interp2
    .word FIND,DUP,ZBRANCH
    DEST interp15
    .word DROP,EXECUTE
    .word CR,BRANCH ; 2,3,2,1,1,2,0
    DEST interp1
interp15:; le mot n'est pas dans le dictionnaire    
    .word SWAP,ERROR
interp2:    
    .word DROP,EXIT
    
; imprime le prompt et passe à la ligne suivante    
DEFWORD "OK",2,,OK,INTERPRET  ; ( -- )
.word SPACE, LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    

    
DEFWORD "ABORT",5,,ABORT,OK
    .word S0,FETCH,SPSTORE,QUIT
    
; si x1<>0 affiche message et appel ABORT
DEFWORD "ABORT\"",6,,ABORTQ,ABORT ; ( i*x x1 -- i*x )
    .word ZBRANCH
    DEST 2f
    .word IPFETCH,DUP,CFETCH,TWODUP,TOR,TOR
    .word SWAP,ONEPLUS,SWAP,TYPE
    .word RFROM,RFROM,PLUS,ONEPLUS,DUP,EVEN,TBRANCH
    DEST 1f
    .word ONEPLUS
1:  .word IPSTORE,ABORT  
2:  .word EXIT
    
; boucle de l'interpréteur    
DEFWORD "QUIT",4,,QUIT,ABORTQ ; ( -- )
    .word R0,FETCH,RPSTORE ;0,1,1,0
    .word LIT,0,DUP,STATE,STORE,SOURCE_ID,STORE ;0,1,2,0
    .word TIB,FETCH,TOIN,STORE ;1,1,2,0
quit0:
    .word TIB, FETCH, LIT,CPL,ONEMINUS,ACCEPT,DROP ;0,1,1,2,2,1,0
    .word SPACE,INTERPRET ; 0, 0
    .word STATE, FETCH, ZEROEQ,ZBRANCH ;0,1,1,1,0
    DEST quit1
    .word OK
quit1:
    .word CR 
    .word BRANCH
    DEST quit0
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   TESTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text 
prt_hex:; W0 entier à imprimer
    push.d W0
    push.d W2
    mov #_video_buffer,W3
    add #32,W3
1:  mov #16,W2
    repeat #17
    div.u W0,W2
    exch W1,W0
    add.b #'0',W0
    cp.b W0,#'9'
    bra leu, 2f
    add.b #7,W0
2:  mov.b W0,[W3--]
    cp0 W1
    exch W1,W0
    bra nz,1b
    pop.d W2
    pop.d W0
    return
    
    
;DEFWORD "COUNT",5,,COUNT,QUIT
;    .word SPFETCH,PBASE,FETCH,MINUS,TWOSLASH,LIT,'0',PLUS
;    .WORD DUP,LIT,'9',GREATER,ZBRANCH
;    DEST 1f
;    .word LIT,7,PLUS
;1:  .word EMIT,EXIT
    
;DEFWORD "TEST",4,,TEST ,COUNT  
;.word  CLS,VERSION,HOME,OK,LIT,333, MSEC,HOME,OKOFF, LIT,333,MSEC,BRANCH, -22
;
;DEFWORD "SERTEST",7,,SERTEST,TEST
;.word CLS,VERSION,SGET,SEMIT,BRANCH,-6    
;
;DEFWORD "HOME",5,,HOME,SERTEST
;.word LIT,0,LIT,0,CURPOS,EXIT
;    
;DEFWORD "OKOFF",6,,OKOFF,HOME
;.word SPACE,SPACE,EXIT 
;    
;
;.section .quick_str.const psv
;quick:
;.asciz "The quick brown fox jump over the lazy dog."

;DEFWORD "VERSION",7,,VERSION,COUNT
;.word CLS,LIT,version,ZTYPE,CR,EXIT    

;DEFWORD "QUICKTEST",9,,QUICKTEST,OKOFF
;.word LIT,quick,ZTYPE,EXIT
;    
;DEFWORD "STRTEST",7,,STRTEST
;.word CLS,LIT, quick, ZTYPE,LIT,_video_buffer,LIT,0,LIT,0,LIT,43,RSTORE,DELAY
;.word CLS,DELAY,LIT, _video_buffer,LIT,0,LIT,0,LIT,43,RLOAD,DELAY,BRANCH, -26
;
;DEFWORD "EEPROMTEST",10,,EEPROMTEST
;.word CLS,LIT, quick, ZTYPE, LIT,500,MSEC, LIT, _video_buffer,LIT,43,ESTORE
;.word CLS, DELAY, LIT, _video_buffer,LIT,100,ELOAD,BRANCH,-32
;
;DEFWORD "LOOPTEST",8,,LOOPTEST
;.word LIT,'Z'+1,LIT,'A',DODO,DOI,EMIT,DOLOOP,-6,INFLOOP    
;
;DEFWORD "TYPETEST",8,,TYPETEST
;.word TIB,FETCH,DUP,LIT,63,ACCEPT,CR,TYPE,EXIT 
;    
;DEFWORD "CRTEST",6,,CRTEST
;.word CLS,LIT,'A',DUP,EMIT,CR,ONEPLUS,DUP,LIT,'X',EQUAL,ZBRANCH,-18,INFLOOP    
;    
;DEFWORD "DELAY",5,,DELAY
;.word  LIT, 500, MSEC, EXIT
; 
;DEFWORD "2DUPTEST",8,,TWODUPTEST
;.word LIT,'B',LIT,'A',TWODUP,EMIT,EMIT,EMIT,EMIT,INFLOOP
;
;DEFWORD "TEST4",5,,TEST4
;    .word KEY,DUP,LIT,'0',MINUS,SPACES,EMIT,EXIT
    
;DEFWORD "INFLOOP",7,,INFLOOP
;.word  BRANCH, -2

DEFCODE "INFLOOP",7,,INFLOOP,QUIT
    bra .

;DEFWORD "FNTTEST",7,,FNTTEST
;.WORD LIT,128,LIT,0,DODO, DOI, EMIT, DOLOOP,-6,CR,EXIT
;    
;DEFWORD "BOX",3,,BOX
;.WORD CLIT,1,EMIT,CLIT,11,EMIT,CLIT,3,EMIT,CR,CLIT,14,EMIT,CLIT,7,EMIT,CLIT,15,EMIT
;.WORD CR,CLIT,2,EMIT,CLIT,12,EMIT,CLIT,4,EMIT,CR,EXIT


.section .link psv  address(0x7FFE)    
.global _sys_latest
_sys_latest:
.word link
    
   
.end

