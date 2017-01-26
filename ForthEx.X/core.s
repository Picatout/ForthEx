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
.byte 12    
.ascii "ForthEx V0.1"    
.global _compile_only
_compile_only:
.ascii "compile only word"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mot système qui ne sont pas
; dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
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
    
    
DEFCODE "EXECUTE",7,,EXECUTE ; ( i*x xt -- j*x ) 6.1.1370 exécute le code à l'adresse xt
    mov T, WP
    DPOP
    mov [WP++],W0
    goto W0
    
DEFCODE "@",1,,FETCH ; ( addr -- n )
    mov [T],T
    NEXT
    
DEFCODE "C@",2,,CFETCH  ; ( c-addr -- c )
    mov.b [T], T
    ze T, T
    NEXT

DEFCODE "2@",2,,TWOFETCH ; ( addr -- n1 n2 )
    mov [T],W0
    add #CELL_SIZE,T
    mov [T],[++DSP]
    mov W0,T
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
    
DEFCODE "M+",2,,ADDPLUS  ; ( d n --  d ) simple + double
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

DEFWORD "HERE",4,,HERE
    .word DP,FETCH,EXIT

DEFWORD "IMMEDIATE",9,,IMMEDIATE
    .word LATEST,FETCH,DUP,SYSLATEST,FETCH,EQUAL,TBRANCH,1f-$
    .word TWOPLUS,DUP,CFETCH,IMMED,OR,CSTORE,BRANCH,2f-$
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
DEFVAR "SOURCE-ID",9,,SOURCE_ID ; tampon source pour l'évaluation
    
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
DEFCODE "SOURCE",6,,SOURCE ; ( -- c-addr u ) 
    DPUSH
    mov _SOURCE,T
    DPUSH
    mov _SOURCE+2,T
    NEXT

; sauvegarde les valeur de source    
DEFCODE "SOURCE!",7,,SRCSTORE ; ( c-addr u -- )
    mov T,_SOURCE+2
    DPOP
    mov T,_SOURCE
    DPOP
    NEXT
    
    
;vérifie si le caractère est un digit
;valide dans la base B
; si valide retourne la valeur du digit et -1
; si invalide retourne 0
DEFWORD "?DIGIT",6,,QDIGIT ; ( c B -- 0| n -1 )
    .word SWAP,CLIT,'0',MINUS,DUP,ZEROLT,TBRANCH,not_digit-$
    .word DUP,LIT,10,ULESS,TBRANCH,base_test-$
    .word LIT,7,MINUS
base_test:
    .word DUP,ROT,ULESS,ZBRANCH,1f-$
    .word LIT,-1,BRANCH,2f-$
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
DEFWORD ">NUMBER",7,,TONUMBER ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
    .word BASE,FETCH,TOR
1:  .word DUP,ZEROEQ,TBRANCH,4f-$
    
4:    
    .word EXIT
    
;vérifie s'il y a un signe '-'|'+'
; à la première postion de la chaîne spécifiée par <c-addr u>
; retourne -1 si '-', retourne 1 si '+' autrement retourne 0    
; s'il y a un signe incrémente c-addr et décrémente u    
DEFWORD "?SIGN",5,,QSIGN ; ( c-addr u -- c-addr u 0|-1|1 )
    .word OVER,FETCH,DUP,CLIT,'-',EQUAL,ZBRANCH,1f-$
    .word DROP,LIT,-1,TOR, BRANCH,2f-$
1: .word CLIT,'+',EQUAL,ZBRANCH,3f-$
   .word LIT,1,TOR
2: .word  TOR, ONEPLUS,RFROM, ONEMINUS,RFROM,BRANCH,4f-$
3: .word LIT,0
4:  .word EXIT
    
;conversion d'une chaîne en nombre
; c-address indique le début de la chaîne
; utilise la base active
DEFWORD "?NUMBER",7,,QNUMBER ; ( c-addr -- c-addr 0| n -1 )
    .word DUP,LIT,0,DUP,ROT,COUNT ; c-addr 0 0 c-addr u
    .word QSIGN,TOR,TONUMBER   
    
    .word EXIT
    
;imprime la liste des mots du dictionnaire
DEFWORD "WORDS",5,,WORDS ; ( -- )
    .word CR,LATEST
1:  .word FETCH,DUP,ZEROEQ,TBRANCH,3f-$
    .word DUP,DUP,CFETCH,LENMASK,AND  ; NFA NFA LEN
    .word DUP,GETX,PLUS,LIT,64,ULESS,TBRANCH,2f-$
    .word CR
2:  .word TOR,ONEPLUS,RFROM,TYPE,SPACE,TWOMINUS,BRANCH,1b-$
;    .word GETX,LIT,54,ULESS,TBRANCH,2f-$
;    .word CR
;2:  .word DUP,TWOPLUS,DUP,CFETCH,LENMASK,AND,TOR,ONEPLUS,RFROM,TYPE,SPACE
;    .word BRANCH,1b-$
3:   .word DROP,CR,EXIT
    
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
    
; localise le prochain mot délimité par 'c'
; la variable TOIN indique la position courante
; le mot trouvé est copié dans lPAD 
; met à jour TOIN    
DEFCODE "WORD",4,,WORD  ; ( c -- c-addr)
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
.equ  LFA, W1 ; link field address
.equ  NFA, W2 ; name field addrress
.equ  TARGET,W3 ;pointer chaîne recherchée
.equ  LEN, W4  ; longueur de la chaîne recherchée
.equ CNTR, W5
.equ NAME, W6 ; nom dans dictionnaire 
.equ FLAGS,W7    
DEFCODE "FIND",4,,FIND ; ( c-addr -- c-addr 0 | xt 1 | xt -1 )
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
; c-addr addresse du buffer
; +n1 longueur du buffer
; +n2 longueur de la chaîne lue    
DEFWORD "ACCEPT",6,,ACCEPT  ; ( c-addr +n1 -- +n2 )
        .word OVER,DUP,TOIN,STORE,PLUS,OVER  ; 2,3,4,5,3,2,3 ( c-addr bound cursor )
acc1:   .word TWODUP,EQUAL,TBRANCH,acc6-$ ; 3,5,4,3
        .word KEY,DUP,LIT,13,EQUAL,TBRANCH,acc5-$ ; 3,4,5,6,5,4 ( c-addr bound cursor c )
        .word DUP,LIT,8,EQUAL,ZBRANCH,acc3-$ ; 4,5,6,5,4 ( c-addr bound cursor c )
	.word DROP,BACKCHAR,ONEMINUS,BRANCH,acc1-$ ; 4,3,3,3
acc3:	.word DUP,EMIT,OVER,CSTORE,ONEPLUS ;4,5,4,5,3,3
        .word BRANCH,acc1-$
acc5:   .word DROP; 4,3
acc6:   .word LIT,0,OVER,CSTORE,NIP,SWAP,MINUS,EXIT ; 3,2,2,1

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
   .word EXIT
   
; interprète une chaine  la chaîne indiquée par
; c-addr u   
DEFWORD "INTERPRET",9,,INTERPRET ; ( c-addr u -- )
interp1:    
    .word BL,WORD,DUP,CFETCH,ZEROEQ,TBRANCH,interp2-$ ; 0,1,1,2,2,2,1
    .word FIND,DUP,ZBRANCH,interp15-$
    .word DROP,EXECUTE
    .word CR,BRANCH,interp1-$ ; 2,3,2,1,1,2,0
interp15:; le mot n'est pas dans le dictionnaire    
    .word SWAP,ERROR
interp2:    
    .word DROP,EXIT
    
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
    .word R0,FETCH,RPSTORE ;0,1,1,0
    .word LIT,0,DUP,STATE,STORE,SOURCE_ID,STORE ;0,1,2,0
    .word TIB,FETCH,TOIN,STORE ;1,1,2,0
quit0:
    .word TIB, FETCH, LIT,CPL,ONEMINUS,ACCEPT,DROP ;0,1,1,2,2,1,0
    .word SPACE,INTERPRET ; 0, 0
    .word STATE, FETCH, ZEROEQ,ZBRANCH,quit1-$ ;0,1,1,1,0
    .word OK
quit1:
    .word CR
    .word BRANCH, quit0-$
    
DEFCODE "INFLOOP",7,,INFLOOP
    bra .

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   debug tool
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
    
   
;.end

