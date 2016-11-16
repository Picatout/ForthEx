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
 
; dictionnaire utilisateur dans la RAM 
.section .user_dict bss  address(USER_BASE)
.global user_dict 
user_dict: .space RAM_SIZE-USER_BASE
    

.section .ver_str.const psv       
;test string
version:
.asciz "ForthEx V0.1"    
    
FORTH_CODE
.global ENTER  ; s'appelle DOCOL dans Jonesforth  
    
ENTER: ; entre dans un mot de haut niveau (mot défini par ':')
    RPUSH IP   
    mov WP,IP
    NEXT
    
name_0:
    .word 0
    
DEFCODE "EXIT",4,,EXIT  ; ( -- ) (R: nest-sys -- ) 6.1.1380  sortie mot haut-niveau.
    RPOP IP
    NEXT
    
DEFCODE "REBOOT",6,,REBOOT,EXIT ; ( -- )  démarrage à froid
    reset
    

DEFCODE "WARM",4,,WARM,REBOOT   ; ( -- )  démarrage à chaud
__MathError:
    mov #pstack, DSP
    mov #rstack, RSP
    ; à faire: doit-remettre à zéro input buffer
    mov #edsoffset(cold_start),IP
    NEXT
    
DEFCODE "EXECUTE",7,,EXECUTE,WARM ; ( i*x xt -- j*x ) 6.1.1370 exécute le code à l'adresse xt
    mov T, WP
    DPOP
    mov [WP++],W0
    goto W0
    
DEFCODE "LIT",3,,LIT,EXECUTE  ; ( -- x ) empile une valeur  
    DPUSH
    mov [IP++], T
    NEXT

DEFCODE "CLIT",4,,CLIT,LIT  ; ( -- c )
    DPUSH
    mov.b [IP], T
    ze T,T
    inc2 IP,IP ;IP doit toujours être aligné sur un mot de 16 bits
    NEXT

DEFCODE "@",1,,FETCH,CLIT ; ( addr -- n )
    mov [T],T
    NEXT
    
DEFCODE "C@",2,,CFETCH,FETCH  ; ( c-addr -- c )
    mov.b [T], T
    ze T, T
    NEXT
    
DEFCODE "!",1,,STORE,CFETCH  ; ( n  addr -- )
    mov [DSP--],W0
    mov W0,[T]
    DPOP
    NEXT
    
DEFCODE "C!",2,,CSTORE,STORE  ; ( char c-addr  -- )
    mov [DSP--],W0
    mov.b W0,[T]
    DPOP
    NEXT
    
; branchement inconditionnel    
DEFCODE "BRANCH",5,,BRANCH,CSTORE  ; ( -- )
XBRAN:
    add IP, [IP], IP
    NEXT
    
; branchement si T<>0    
DEFCODE "?BRANCH",7,,TBRANCH,BRANCH ; ( n -- )
    cp0 T
    DPOP
    bra nz, XBRAN
    inc2 IP,IP
    NEXT

; branchement si T==0
DEFCODE "ZBRANCH",7,,ZBRANCH,TBRANCH ; ( n -- )
    cp0 T
    DPOP
    bra z, XBRAN
    inc2, IP,IP
    NEXT
    
    
; exécution de DO    
DEFCODE "(DO)",4,,DODO,ZBRANCH ; ( n  n -- ) R( -- n n )
    RPUSH LIMIT
    RPUSH I
    mov T, I
    DPOP
    mov T, LIMIT
    DPOP
    NEXT

; exécution de LOOP   
DEFCODE "(LOOP)",6,,DOLOOP,DODO  ; ( -- )  R( n n -- )
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
    
DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; adressage indirect 
; utilisant registre X
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; initialise X    
DEFCODE "X!",2,,XSTORE ; ( u -- )
    mov T,X
    DPOP
    NEXT

; empile la valeur dans X    
DEFCODE "X@",2,,XFETCH ; ( -- u )
    DPUSH
    mov X,T
    NEXT

; store indirect via X
DEFCODE "!IX",3,,STRIX   ; ( n -- ) 
    mov T,[X]
    DPOP
    NEXT
    
; load indirect via X
DEFCODE "@IX",3,,LDIX  ; ( -- n )
    DPUSH
    mov [X],T
    NEXT
    
; incrémente X
DEFCODE "X++",3,,INCX  ; X=X+1
    inc X,X
    NEXT
    
; décrément X
DEFCODE "X--",3,,DECX  ; X=X-1
    dec X,X
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
    
DEFCODE "<>",2,,NEQUAL ; ( n1 n2 -- f ) f = n1<>n2
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
DEFCONST "F_HIDDEN",8,,_F_HIDDEN,F_HIDDEN    ; drapeau mot caché
DEFCONST "F_LENMASK",9,,_F_LENMASK,F_LENMASK ; masque longueur nom   
DEFCONST "BL",2,,BL,32                       ; caractère espace
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD
DEFCONST "ULIMIT",6,,ULIMIT,RAM_END-1        ; limite espace dictionnaire
DEFCONST "DOCOL",5,,DOCOL,#edsoffset(ENTER)  ; pointeur vers ENTER
    
    
; imprime une chaîne zéro terminée  ( c-addr -- )    
DEFWORD "ZTYPE",5,,ZTYPE
ztype0:    
.word DUP,CFETCH,DUP,ZBRANCH
DEST ztype1 
.word EMIT,ONEPLUS,BRANCH
DEST  ztype0
ztype1:    
.word DROP,DROP, EXIT     

; convertie la chaîne comptée en majuscules
DEFCODE "UPPER",5,,UPPER  ; ( c-addr -- )
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
    
; localise le prochain mot dans TIB
; la variable INPTR indique la position courante
; le mot trouvé est copié dans le PAD 
; met à jour INPTR    
DEFCODE "WORD",4,,WORD  ; ( c -- c-addr) c est le délimiteur
    mov #pad,W2 ; current dest pointer
    mov W2,W3  ; PAD[0]
    mov #tib,W0 ; TIB address
    add #TIB_SIZE,W0 ; TIB end
    mov W0,W4 ; limit
    mov var_INPTR,W1 
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
4:  mov W1, var_INPTR
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
.equ  TARGET,W3
.equ  LEN, W4
.equ CNTR, W5
.equ NAME, W6
.equ FLAGS,W7    
DEFCODE "FIND",4,,FIND ; ( c-addr -- c-addr 0 | xt 1 | xt -1 )
    mov var_LATEST, LINK
    mov LINK,W0
    mov T, TARGET
    DPUSH
    mov.b [TARGET++],LEN ; longueur
try_next:
;    call prt_hex ; debug
    mov [LINK],W0
;    call prt_hex
    cp0 W0
    bra z, not_found
    mov W0,LINK
    inc2 W0,NFA  ; W3=NFA
    mov.b [NFA++],W0 ;
    mov.b W0,FLAGS
    and.b #F_LENMASK,W0
    cp.b W0,LEN
    bra nz, try_next
    ; compare les 2 chaîne
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
    btsc NAME,#0 ; alignement sur adresse paire
    inc NAME,NAME ; CFA
    mov NAME,[DSP] ; XT
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
DEFWORD "ACCEPT",6,,ACCEPT  ; ( c-addr +n1 -- +n2 )
        .word OVER,DUP,INPTR,STORE,PLUS,OVER  ; 2,3,4,5,3,2,3 ( c-addr bound cursor )
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
   
        
    
   
; interprète une chaine  la chaîne dans TIB  
DEFWORD "INTERPRET",9,,INTERPRET ; ( -- )
    .word CR
interp1:    
    .word BL,WORD,DUP,CFETCH,ZEROEQ,TBRANCH ; 0,1,1,2,2,2,1
    DEST interp2
    .word FIND,COUNT,TWODROP,CR,BRANCH ; 2,3,2,1,1,2,0
    DEST interp1
interp2:    
    .word DROP,EXIT
    
; imprime le prompt et passe à la ligne suivante    
DEFWORD "OK",2,,OK  ; ( -- )
.word SPACE, LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    
    
; boucle de l'interpréteur    
DEFWORD "QUIT",4,,QUIT ; ( -- )
    .word RBASE,FETCH,RPSTORE ;0,1,1,0
    .word LIT,0,STATE,STORE ;0,1,2,0
    .word VERSION,ZTYPE,CR  ;1,0,0
    .word TIB,FETCH,INPTR,STORE ;1,1,2,0
quit0:
;    .word TEST4,CR,BRANCH
;    DEST quit0
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
    
    
DEFWORD "COUNT",5,,COUNT
    .word SPFETCH,PBASE,FETCH,MINUS,TWOSLASH,LIT,'0',PLUS,EMIT,EXIT
    
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
 
DEFWORD "2DUPTEST",8,,TWODUPTEST
.word LIT,'B',LIT,'A',TWODUP,EMIT,EMIT,EMIT,EMIT,INFLOOP

DEFWORD "TEST4",5,,TEST4
    .word KEY,DUP,LIT,'0',MINUS,SPACES,EMIT,EXIT
    
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
    .global cold_start
cold_start:
    .word QUIT
    .word REBOOT ; ne devrait jamais se rendre ici
    
.end

