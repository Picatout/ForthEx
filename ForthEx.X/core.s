;****************************************************************************
; Copyright 2015,2016,2017 Jacques Desch�nes
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
;Description: base pour le syst�me Forth
;Date: 2015-10-03
;REF: http://www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt
;   http://www.bradrodriguez.com/papers/
;   msp430 camelForth source code: http://www.camelforth.com/download.php?view.25
;   ANS FORTH 94: http://www.greenarraychips.com/home/documents/dpans94.pdf
;   http://sinclairql.speccy.org/archivo/docs/books/Threaded_interpretive_languages.pdf    
;   http://www.exemark.com/FORTH/eForthOverviewv5.pdf
;   http://forthfiles.net/ting/sysguidefig.pdf    
    
    
.global pstack, rstack,cstack,user,tib,pad
    
.section .core.bss bss
.global user    

.equ _RP0, (RAM_BASE)    
.section .return.stack.bss stack , address(_RP0)
rstack:
.space RSTK_SIZE

.equ _SP0, (RAM_BASE+RSTK_SIZE)    
.section .param.stack.bss, bss , address(_SP0)    
pstack:
.space DSTK_SIZE

.equ  CSTK_BASE, _SP0+DSTK_SIZE    
.section .control.stack.bss bss, address(CSTK_BASE)
cstack:
.space CSTK_SIZE 
    
.section .tib.bss bss
tib: .space TIB_SIZE
.section .pad.bss bss 
pad: .space PAD_SIZE
.section .paste.bss bss
; copie de la derni�re interpr�t�e en mode interactif
; permet de r�afficher cette ligne avec CTRL_v 
paste: .space TIB_SIZE+2
 
 
.section .sys_vars.bss bss
.global _SYS_VARS
_SYS_VARS:    
; control stack pointer
.global csp
csp: .space 2
; NFA derni�re entr�e dans le dictionnaire syst�me
 .global _SYSLATEST
_SYSLATEST: .space 2
; NFA derni�re entr�e dans le dictionnaire utilisateur
 .global _LATEST
_LATEST: .space 2
; Terminal input buffer
.global _TIB    
_TIB: .space 2
.global _PAD 
_PAD: .space 2   
.global _PASTE
_PASTE: .space 2 
 .global _TICKSOURCE
; adresse et longueur du buffer d'�valuation
_TICKSOURCE: .space 2
; identifiant de la source: 0->interactif, -1, fichier
 .global _CNTSOURCE
_CNTSOURCE: .space 2
; pointeur data 
 .global _DP
_DP: .space 2 
; base num�rique utilis�e pour l'affichage des entiers
 .global _BASE
_BASE: .space 2
 .global _STATE
; �tat interpr�teur : 0 interpr�teur, -1 compilation
_STATE: .space 2
; pointeur position parser
 .global _TOIN
_TOIN: .space 2 
; pointeur HOLD conversion num�rique
 .global _HP
_HP: .space 2
; vecteur pour le terminal actif.
; par d�faut LCONSOLE 
_SYSCONS: .space 2
; sauvegarde de RSP par BREAK
_RPBREAK: .space 2 
; flag activation/d�sactivaton break points
_DBGEN: .space 2 

; enregistrement information boot loader
.section .boot.bss bss address(BOOT_HEADER)
.global _boot_header
_boot_header: .space BOOT_HEADER_SIZE
; dictionnaire utilisateur dans la RAM 
.section .user_dict.bss bss  address (DATA_BASE)
.global _user_dict 
_user_dict: .space EDS_BASE-DATA_BASE
    
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mot syst�me qui ne sont pas
; dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FORTH_CODE
    
    .global ENTER
ENTER: ; entre dans un mot de haut niveau (mot d�fini par ':')
    RPUSH IP   
    mov WP,IP
    NEXT

    .global DOUSER
DOUSER: ; empile pointeur sur variable utilisateur
    DPUSH
    mov [WP++],W0
    add W0,VP,T
    NEXT

    
    .global DOVAR
DOVAR:
    DPUSH
    mov WP,T
    NEXT
    
    .global DOCONST
DOCONST:
    DPUSH
    mov [WP],T
    NEXT

    
    
    .section .sysdict psv
    .align 2
    .global name_EXIT
name_EXIT :
    .word 0
0:  .byte 4|F_MARK
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

DEFWORD "NOP",3,,NOP ; ( -- )
    .word EXIT

DEFCODE "CALL",4,,CALL ; ( ud -- )
    mov T, W1
    DPOP
    mov T, W0
    DPOP
    call.l W0
    NEXT
    
; empile un lit�ral
HEADLESS LIT    
;DEFCODE "(LIT)",5,F_HIDDEN,LIT ; ( -- x ) 
    DPUSH
    mov [IP++], T
    NEXT

; empile un caract�re litaral
HEADLESS CLIT    
;DEFCODE "(CLIT)",6,F_HIDDEN,CLIT  ; ( -- c )
    DPUSH
    mov [IP++], T
    ze T,T
    NEXT

; branchement inconditionnel
HEADLESS BRANCH    
;DEFCODE "(BRANCH)",8,F_HIDDEN,BRANCH ; ( -- )
    add IP, [IP], IP
    NEXT
    
; branchement si T<>0
HEADLESS TBRANCH
;DEFCODE "(TBRANCH)",9,F_HIDDEN,TBRANCH ; ( f -- )
    cp0 T
    DPOP
    bra nz, code_BRANCH
    inc2 IP,IP
    NEXT

; branchement si T==0
HEADLESS ZBRANCH
;DEFCODE "(?BRANCH)",9,F_HIDDEN,ZBRANCH ; ( f -- )
    cp0 T
    DPOP
    bra z, code_BRANCH
    inc2, IP,IP
    NEXT
    
    
; runtime de DO
HEADLESS DODO    
;DEFCODE "(DO)",4,F_HIDDEN,DODO ; ( n  n -- ) R( -- I LIMIT )
doit:
    RPUSH LIMIT
    RPUSH I
    mov T, I
    DPOP
    mov T,LIMIT
    DPOP
    NEXT

    
; runtime de ?DO
HEADLESS DOQDO
;DEFCODE "(?DO)",5,F_HIDDEN,DOQDO ; ( n n -- ) R( -- | I LIMIT )    
    cp T,[DSP]
    bra z, 9f
    add #(2*CELL_SIZE),IP ; saute le branchement inconditionnel
    bra doit
9:  DPOP
    DPOP
    NEXT
    
; ex�cution de LOOP
; la boucle se termine quand I==LIMIT    
HEADLESS DOLOOP
;DEFCODE "(LOOP)",6,F_HIDDEN,DOLOOP ; ( -- )
    inc I, I
    cp I, LIMIT
    bra eq, 1f
    add IP, [IP], IP
    NEXT
1:
    inc2 IP,IP
    RPOP I    
    RPOP LIMIT
    NEXT

;ex�cution de +LOOP
;La boucle s'arr�te lorsque I franchi la fronti�re
;entre LIMIT et LIMIT-1 dans un sens ou l'autre    
HEADLESS DOPLOOP
;DEFCODE "(+LOOP)",7,F_HIDDEN,DOPLOOP ; ( n -- )     
    mov I,W0
    add I,T,I
    DPOP
    cp W0, LIMIT
    bra lt, 3f
    dec LIMIT,W0
    cp I,W0
    bra le , 1b
    bra 2f
3:  cp I,LIMIT
    bra ge, 1b
2:  add IP,[IP],IP
    NEXT
    
; empile compteur de boucle    
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

; empile la limite de boucle
DEFCODE "L",1,,DOL ; ( -- n )
    DPUSH
    mov LIMIT,T
    NEXT
    
; empile compteur boucle externe    
DEFCODE "J",1,,DOJ  ; ( -- n ) R: limitJ indexJ
    DPUSH
    mov [RSP-2],T
    NEXT
    
DEFCODE "UNLOOP",6,,UNLOOP   ; R:( n1 n2 -- ) n1=LIMIT_J, n2=J
    RPOP I
    RPOP LIMIT
    NEXT
    
    
; empile IP
DEFCODE "IP@",3,,IPFETCH  ; ( -- n )
    DPUSH
    mov IP,T
    NEXT
    
DEFCODE "REBOOT",6,,REBOOT ; ( -- )  d�marrage � froid
    reset
    
    
DEFCODE "EXECUTE",7,,EXECUTE ; ( i*x cfa -- j*x ) 6.1.1370 ex�cute le code � l'adresse *cfa
exec:
    mov T, WP ; CFA
    DPOP
    mov [WP++],W0  ; code address, WP=PFA
    goto W0

; nom: @XT
;   Ex�cution vectoris�e. 
;   Lit le contenu d'une variable qui contient un XT
;   et ex�cute ce XT.
; arguments:
;    i*x  arguments attendus par la fonction qui sera ex�cut�e.    
;    a-addr   adresse contenant le vecteur XT
; retourne:
;    j*x  d�pend de la fonction ex�cut�e.    
DEFCODE "@EXEC",5,,FETCHEXEC ; ( i*x a-addr -- j*x )
    mov [T],T
    bra exec

; nom: VECEXEC ( i*x a-addr n -- j*x )
;   exc�cute la fonction n dans une table de vecteur
; arguments:
;    i*x   arguments requis par la fonction � ex�cuter.
;    a-addr  adresse de la table de vecteurs.
;    n     num�ro du vecteur � ex�cuter.
DEFCODE "VEXEC",5,,VEXEC
    mul.uu T,#CELL_SIZE,W0
    DPOP
    add W0,T,T
    mov [T],T
    bra exec
    
    
DEFCODE "@",1,,FETCH ; ( addr -- n )
    mov [T],T
    NEXT

DEFCODE "C@",2,,CFETCH ; ( addr -- c)
    mov.b [T],T
    ze T,T
    NEXT
    
; lecture d'un entier dans la m�moire EDS    
DEFCODE "E@",2,,EFETCH ; ( addr -- n )
    SET_EDS
    mov [T],T
    RESET_EDS
    NEXT
    
;lecture d'un caract�re dans la m�moire RAM EDS
DEFCODE "EC@",3,,ECFETCH ; ( c-addr -- c )
    SET_EDS
    mov.b [T],T
    ze T,T
    RESET_EDS
    NEXT
    
; empile un entier double    
DEFCODE "2@",2,,TWOFETCH ; ( addr -- n1 n2 ) 
    mov [T],W0 
    add #CELL_SIZE,T
    mov [T],T
    mov W0,[++DSP]
    NEXT
    
; lecture �l�ment d'un vecteur
; arguments:
;   n  indice
;   addr  adresse table
; retourne:
;   x  = table[n]    
DEFCODE "TBL@",4,,TBLFETCH ; ( n addr -- x )
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W1,W0,W0
    add T,W0,W0
    mov [W0],T
    NEXT
    
; �criture d'un �l�ment dans une table
;  table[n2] = n1
; arguments:
;   n1  valeur � affect� � l'�l�ment
;   n2  indice de l'�l�ment
;   addr  adresse de la table    
DEFCODE "TBL!",4,,TBLSTORE ; ( n1 n2 addr -- )    
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W0,W1,W0
    add T,W0,W0
    DPOP 
    mov T,[W0]
    DPOP
    NEXT
    
    
; met en m�moire un entier simple    
DEFCODE "!",1,,STORE  ; ( n  addr -- )
    mov [DSP--],[T]
    DPOP
    NEXT
  
; met en m�moire 1 octet    
DEFCODE "C!",2,,CSTORE  ; ( char c-addr  -- )
    mov [DSP--],W0
    mov.b W0,[T]
    DPOP
    NEXT

; met en m�moire un entier double    
DEFCODE "2!",2,,TWOSTORE ; ( n1 n2 addr -- ) n2->addr, n1->addr+CELL_S�ZE
    mov [DSP--],[++T]
    mov [DSP--],[--T]
    mov [DSP],T
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
    
; duplique T si <> 0    
DEFCODE "?DUP",4,,QDUP ; ( n -- 0 | n n )
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
    
DEFCODE "RDROP",5,,RDROP ; ( R: n -- )
    sub #CELL_SIZE,RSP
    NEXT
    
DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
    mov [DSP],W0
    exch W0,T
    mov W0,[DSP]
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
    mov [DSP],W0 ; n1
    mov T,[DSP]  ; n2 n2 
    mov W0,[++DSP] ; n2 n1 n2
    NEXT

; nombre d'�l�ment sur la pile data
DEFCODE "DEPTH",5,,DEPTH ; ( -- +n1 )
    mov #pstack,W0
    sub DSP,W0,W0
    DPUSH
    lsr W0,T
    NEXT

; ins�re le ni�me �l�ment de la pile au sommet
; l'argument +n1 est retir� de la pile avant le comptage
; si +n1==0 �quivaut � DUP 
; is +n1==1 �quivaut � OVER    
DEFCODE "PICK",4,,PICK ; ( +n1 -- n )
    mov DSP,W0
    sl T,T
    sub W0,T,W0
    mov [W0],T
    NEXT
    
; tranfert de la pile des arguments 
; vers la pile de contr�le
DEFCODE ">CSTK",5,,TOCSTK ; ( x -- C: -- x )
    mov csp,W0
    mov T,[W0++]
    mov W0,csp
    DPOP
    NEXT
    
; transfert de la pile de contr�le
; vers la pile des arguments
DEFCODE "CSTK>",5,,CSTKFROM ; ( -- x  C: x -- )
    DPUSH
    mov csp,W0
    mov [--W0],T
    mov W0,csp
    NEXT
    
    
;;;;;;;;;;;;;;;;
;     MATH
;;;;;;;;;;;;;;;;

DEFCONST "MSB",3,,MSB,0x8000 ; bit le plus significatif (1<<15).
DEFCONST "MAX-INT"7,,MAXINT,0x7FFF ; 32767
DEFCONST "MIN-INT"7,,MININT,0x8000 ; -32768

    
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
    asr T,T
    NEXT
    
DEFCODE "LSHIFT",6,,LSHIFT ; ( x1 u -- x2 ) x2=x1<<u    
    mov T, W0
    DPOP
    cp0 W0
    bra z,9f
    mov #16,W1
    cp W0,W1
    bra leu, 1f
    mov W1,W0
1:  dec W0,W0
    repeat W0
    sl T,T
9:  NEXT
    
DEFCODE "RSHIFT",6,,RSHIFT ; ( x1 u -- x2 ) x2=x1>>u
    mov T,W0
    DPOP
    cp0 W0
    bra z, 9f
    mov #16,W1
    cp W0,W1
    bra leu, 1f
    mov W1,W0    
1:  dec W0,W0
    repeat W0
    lsr T,T
9:  NEXT
    
DEFCODE "+!",2,,PLUSSTORE  ; ( n addr  -- ) [addr]=[addr]+n     
    mov [T], W0
    add W0, [DSP--],W0
    mov W0, [T]
    DPOP
    NEXT

; addition de 2 entiers double    
DEFCODE "D+",2,,DPLUS ; ( d1 d2 -- d3 )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    add W0,[DSP],[DSP]
    addc W1,T,T
    NEXT
    
DEFCODE "M+",2,,MPLUS  ; ( d1 n --  d2 ) simple + double
    mov [DSP-2], W0 ; d1 faible
    add W0,T, W0 ; d2 faible
    DPOP    ; T= d1 fort
    addc #0, T
    mov W0,[DSP]
    NEXT
 
DEFCODE "*",1,,STAR ; ( n1 n2 -- n1*n2) 
    mul.ss T,[DSP--],W0
    mov W0,T
    NEXT

    
; produit de 2 entier simple conserve entier double
DEFCODE "M*",2,,MSTAR ; ( n1 n2 -- d )
    mul.ss T,[DSP],W0
    mov W0,[DSP]
    mov W1,T
    NEXT

; muttiplication non sign�e 16x16
; r�sultat entier double    
DEFCODE "UM*",3,,UMSTAR ; ( u1 u2 -- ud )
    mul.uu T,[DSP],W0
    mov W1,T
    mov W0,[DSP]
    NEXT
    
;multiplication non sign�e 32*16->32
; ud1 32 bits
; u2 16 bits
; ud3 32 bits  
DEFCODE "UD*",3,,UDSTAR ; ( ud1 u2 -- ud3 )
    mul.uu T,[DSP],W0
    mov W0,[DSP]
    mov T,W0
    DPOP
    mul.uu W0,[DSP],W0
    add W1,T,T
    mov W0,[DSP]
    NEXT
    
;DEFWORD "UD*",3,,UDSTAR  ; ( ud1 u2 -- ud3 ) 32*16->32    
;    .word DUP,TOR,UMSTAR,DROP
;    .word SWAP,RFROM,UMSTAR,ROT,PLUS,EXIT
    
DEFCODE "/",1,,DIVIDE ; ( n1 n2 -- n1/n2 )
    mov [DSP--],W0
    repeat #17
    div.s W0,T
    mov W0,T
    NEXT

; retourne le reste de la division enti�re.    
DEFCODE "MOD",3,,MOD ; ( n1 n2 -- n1%n2 )
   mov [DSP--],W0
   repeat #17
   div.s W0,T
1: mov W1,T
   NEXT
   
DEFCODE "*/",2,,STARSLASH  ; ( n1 n2 n3 -- n4 ) n1*n2/n3, n4 quotient
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.sd W0,T
    mov W0,T
    NEXT

DEFCODE "*/MOD",5,,STARSLASHMOD ; ( n1 n2 n3 -- n4 n5 ) n1*n2/n3, n4 reste, n5 quotient
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.sd W0,T
1:  mov W1,[++DSP]
    mov W0,T
    NEXT
    
DEFCODE "/MOD",4,,SLASHMOD ; ( n1 n2 -- r q )
    mov [DSP],W0
    repeat #17
    div.s W0,T
1:  mov W0,T     ; quotient
    mov W1,[DSP] ; reste
    NEXT

; division d'un entier double non sign�
; par un entier simple non sign�
; r�sulant en un quotient et reste simple
; u1 reste
; u2 quotient    
DEFCODE "UM/MOD",6,,UMSLASHMOD ; ( ud u -- u1 u2 )
    mov [DSP--],W1
    mov [DSP--],W0
    repeat #17
    div.ud W0,T
    mov W0,T
    mov W1,[++DSP]
    NEXT
    
;division d'un entier double non sign�
; par un entier simple non sign� r�sultant
; en un quotient double et un reste simple
; arguments:
;   ud1 ->dividend
;    u1 -> diviseur
; r�sultat:
;   u2 reste entier simple
;   ud2 quotient entier double    
DEFCODE "UD/MOD",6,,UDSLASHMOD ; ( ud1 u1 -- u2 ud2 )
    clr W1
    mov [DSP],W0
    repeat #17
    div.ud W0,T
    mov W0,W4  ; partie forte du quotient
    mov [DSP-2],W0 
    repeat #17
    div.ud W0,T
    mov W1,[DSP-2] ;reste entier simple
    mov W0,[DSP]  ; partie faible du quotient
    mov W4,T  ; partie forte du quotient
    NEXT
    
    
DEFCODE "MAX",3,,MAX ; ( n1 n2 -- max(n1,n2)
    mov [DSP--],W0
    cp T,W0
    bra ge, 1f
    exch T,W0
1:  NEXT    
    
DEFCODE "MIN",3,,MIN ; ( n1 n2 -- min(n1,n2) )
    mov [DSP--],W0
    cp W0,T
    bra ge, 1f
    exch T,W0
1:  NEXT
    
DEFCODE "UMAX",4,,UMAX ; ( u1 u2 -- max(u1,u2) )
    mov [DSP--],W0
    cp T,W0
    bra geu,1f
    exch W0,T
1:  NEXT
    
DEFCODE "UMIN",4,,UMIN ; ( u1 u2 -- min(u1,u2) )
    mov [DSP--],W0
    cp W0,T
    bra geu, 1f
    exch T,W0
1:  NEXT
    
;   REF: http://lars.nocrew.org/forth2012/core/WITHIN.html    
;   : WITHIN ( test low high -- flag ) OVER - >R - R> U< ;
DEFCODE "WITHIN",6,,WITHIN ; ( u1 u2 u3 -- f ) 
    mov T,W0   
    DPOP
    sub W0,T,[RSP++]
    mov [DSP],W0
    sub W0,T,[DSP]
    mov [--RSP],T
    bra code_ULESS

    
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

;valeur absolue d'un entier double
DEFCODE "DABS",4,,DABS ; ( d -- +d )
    btss T,#15
    bra 9f
    mov [DSP],W0
    com T,T
    com W0,W0
    add #1,W0
    addc #0,T
    mov W0,[DSP]
9:  NEXT    
    
; convertie valeur simple en 
; valeur double    
DEFCODE "S>D",3,,STOD ; ( n -- d ) 
    DPUSH
    clr W0
    btsc T,#15
    com W0,W0
    mov W0,T
    NEXT

; inverse n1 si n2 est n�gatif    
DEFCODE "?NEGATE",7,,QNEGATE ; ( n1 n2 -- n3)
    mov T,W0
    DPOP
    btsc W0,#15
    neg T,T
    NEXT    
    
; division sym�trique entier double par simple
; arrondie vers z�ro    
; adapt� de camel Forth pour MSP430
DEFWORD "SM/REM",6,,SMSLASHREM ; ( d1 n1 -- n2 n3 )
    .word TWODUP,XOR,TOR,OVER,TOR
    .word ABS,TOR,DABS,RFROM,UMSLASHMOD
    .word SWAP,RFROM,QNEGATE,SWAP,RFROM,QNEGATE
    .word EXIT

; division double/simple arrondie au plus petit.
; adapt� de camel Forth pour MSP430    
DEFWORD "FM/MOD",6,,FMSLASHMOD ; ( d1 n1 -- n2 n3 )    
    .word DUP,TOR,TWODUP,XOR,TOR,TOR
    .word DABS,RFETCH,ABS,UMSLASHMOD
    .word SWAP,RFROM,QNEGATE,SWAP,RFROM,ZEROLT,ZBRANCH,9f-$
    .word NEGATE,OVER,ZBRANCH,9f-$
    .word RFETCH,ROT,MINUS,SWAP,ONEMINUS
9:  .word RDROP,EXIT

; incr�mente une variable EDS
; arguments:
;   addr   adresse de la variable    
DEFWORD "EVAR+",5,,EVARPLUS ; ( addr -- )
    .word DUP,EFETCH,ONEPLUS,SWAP,STORE,EXIT
    
; d�cr�mente une variable EDS
; arguments:    
;    addr   adresse de la variable
DEFWORD "EVAR-",5,,EVARMINUS ; ( addr -- )
    .word DUP,EFETCH,ONEMINUS,SWAP,STORE,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; op�rations logiques bit � bit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "AND",3,,AND  ; ( n1 n2 -- n)  ET bit � bit
    and T,[DSP--],T
    NEXT
    
DEFCODE "OR",2,,OR   ; ( n1 n2 -- n ) OU bit � bit
    ior T,[DSP--],T
    NEXT
    
DEFCODE "XOR",3,,XOR ; ( n1 n2 -- n ) OU exclusif bit � bit
    xor T,[DSP--],T
    NEXT
    
; inverse la valeur logique de f    
DEFCODE "NOT",3,,NOT ; ( f -- f)
    cp0 T
    bra nz, 1f
    setm T
    bra 9f
1:  clr T
9:  NEXT
    
    
DEFCODE "INVERT",6,,INVERT ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
DEFCODE "DINVERT",7,,DINVERT ; ( d -- d ) inversion des bits d'un double
    com T,T
    com [DSP],[DSP]
    NEXT
    
DEFCODE "NEGATE",6,,NEGATE ; ( n - n ) compl�ment � 2
    neg T, T
    NEXT
    
;n�gation d'un nombre double pr�cision
DEFCODE "DNEGATE",7,,DNEGATE ; ( d -- n )
    com T,T
    com [DSP],[DSP]
    mov #1,W0
    add W0,[DSP],[DSP]
    addc #0,T
    NEXT
    
;;;;;;;;;;;;;;;
; comparaisons
;;;;;;;;;;;;;;;
    
DEFCODE "0=",2,,ZEROEQ  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT

;vrai si n diff�rent d0 0    
DEFCODE "0<>",3,,ZERODIFF ; ( n -- f ) 
    clr W0
    cp0 T
    bra z, 9f
    com W0,W0
9:  mov W0,T
    NEXT
    
    
DEFCODE "0<",2,,ZEROLT ; ( n -- f ) f= n<0
    add T,T,T
    subb T,T,T
    com T,T
    NEXT

DEFCODE "0>",2,,ZEROGT ; ( n -- f ) f= n>0
    clr W0
    cp0 T
    bra le, 8f
    setm W0
8:  mov W0,T    
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
    
;empile la taille en octets d'une cellule.    
DEFCODE "CELL",4,,CELL ; ( -- CELL_SIZE )
    DPUSH
    mov #CELL_SIZE, T
    NEXT

; incr�mente T de la taille d'une cellule en octets    
DEFCODE "CELL+",5,,CELLPLUS ; ( addr -- addr+CELL_SIZE )
    add #CELL_SIZE, T
    NEXT

; retourne le nombre d'octets occup�es par n cellules    
DEFCODE "CELLS",5,,CELLS ; ( n -- n*CELL_SIZE )
    mul.uu T,#CELL_SIZE,W0
    mov W0,T
    NEXT

; aligne DP sur adresse paire sup�rieure.
; met 0 dans l'octet saut�.    
; suppose un adressage par octet    
DEFWORD "ALIGN",5,,ALIGN ; ( -- )
    .word HERE,ODD,ZBRANCH,9f-$
    .word LIT,0,HERE,CSTORE,LIT,1,ALLOT
9:  .word EXIT    
    
; aligne la valeur de T sur une valeur paire sup�rieure.    
; suppose un adressage par octet    
DEFCODE "ALIGNED",7,,ALIGNED ; ( addr -- a-addr )
    btsc T,#0
    inc T,T
    NEXT

; v�rifie que T est dans l'intervalle ASCII 32..127
; sinon remplace c par '_'    
DEFCODE ">CHAR",5,,TOCHAR ; ( c -- c)
    and #127,T
    cp T,#32
    bra ge, 1f
    mov #'_',T
1:  NEXT
 
; empile la valeur de DP    
DEFWORD "HERE",4,,HERE
    .word DP,FETCH,EXIT

; copie un bloc m�moire RAM
; en �vitant la propagation 
;  arguments:
;   addr1  source
;   addr2  dest
;   u      compte    
DEFCODE "MOVE",4,,MOVE  ; ( addr1 addr2 u -- )
    mov [DSP-2],W0 ; source
    cp W0,[DSP]    
    bra ltu, move_dn ; source < dest
    bra move_up      ; source > dest
    
; copie un bloc d'octets RAM  
; DSRPAG configur� pour acc�s � L'EDS
; copie de l'adresse la plus basse vers la plus haute    
DEFCODE "CMOVE",5,,CMOVE  ;( c-addr1 c-addr2 u -- )
move_up:
    SET_EDS
    mov T, W0 ; compte
    DPOP
    mov T, W1 ; destination
    DPOP
    cp0 W0
    bra z, 1f
    dec W0,W0
    repeat W0
    mov.b [T++],[W1++]
1:  DPOP
    RESET_EDS
    NEXT

; copie un bloc d'octets RAM  
; DSRPAG configur� pour acc�s � L'EDS
; copie de l'adresse la plus haute vers la plus basse    
DEFCODE "CMOVE>",6,,CMOVETO ; ( c-addr1 c-addr2 u -- )
move_dn:
    SET_EDS
    mov T, W0
    DPOP
    mov T,W1
    add W0,W1,W1
    DPOP
    add W0,T,T
    cp0 W0
    bra z, 1f
    dec W0,W0
    repeat W0
    mov.b [--T],[--W1]
1:  DPOP
    RESET_EDS
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  manipulation de caract�res
;  et cha�nes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

; retourne l'espace occup�e
; par n caract�res en unit� adresse
DEFWORD "CHARS",5,,CHARS ; ( n1 -- n2 )
9:  .word EXIT
   
; incr�mente l'adresse d'un caract�re
DEFWORD "CHAR+",5,,CHARPLUS ; ( addr -- addr' )  
    .word ONEPLUS,EXIT
    
; recherche le prochain mot s�par�
; par un espace dans le flux d'entr�.    
; et empile le premier caract�re de ce mot
DEFWORD "CHAR",4,,CHAR ; cccc ( -- c )
    .word BL,WORD,DUP,CFETCH,ZEROEQ
    .word QABORT
    .byte 16
    .ascii "missing caracter"
    .align 2
    .word ONEPLUS,CFETCH,EXIT

; version compilateur de CHAR  
DEFWORD "[CHAR]",6,F_IMMED,COMPILECHAR ; cccc 
    .word QCOMPILE
    .word CHAR,CFA_COMMA,LIT,COMMA,EXIT
    
    
; recherche du caract�re 'c' dans le bloc
; m�moire d�butant � l'adresse 'c-addr' et de dimension 'u' octets
; retourne la position de 'c' et
; le nombre de caract�res qui suit dans le bloc
; le buffer doit-�tre en RAM, pas d'acc�s � la PSV    
DEFCODE "SCAN"4,,SCAN ; ( c-addr u c -- c-addr' u' )
    SET_EDS
    mov T, W0   ; c
    DPOP        ; T=U
    mov [DSP],W1 ; W1=c-addr
    cp0 T
    bra z, 4f
1:  cp.b W0,[W1]
    bra z, 4f
    inc W1,W1
    dec T,T
    bra nz, 1b
4:  mov W1,[DSP]
    RESET_EDS
    NEXT

; nom: FILL ( c-addr u c -- )    
;   Initialise un bloc m�moire RAM de dimension u avec
;   le caract�re c.
; arguments:
;   c-addr   adresse d�but zone.
;   u        nombre de caract�res � remplir
;   c        caract�re de remplissage    
; retourne:
;       
DEFCODE "FILL",4,,FILL ; ( c-addr u c -- )  for{0:(u-1)}-> m[T++]=c
    SET_EDS
    mov T,W0 ; c
    mov [DSP--],W1 ; u
    mov [DSP--],W2 ; c-addr
    DPOP
    cp0 W1
    bra z, 1f
    dec W1,W1
    repeat W1
    mov.b W0,[W2++]
1:  RESET_EDS
    NEXT
    
; remplace tous les caract�res <=32 � la fin d'une cha�ne
; par des z�ro
; u1 longueur initiale de la cha�ne
; u2 longueur finale de la cha�ne    
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
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  variables syst�me
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFUSER "STATE",5,,STATE   ; �tat compile=1/interpr�te=0
DEFUSER "DP",2,,DP         ; pointeur fin dictionnaire
DEFUSER "BASE",4,,BASE     ; base num�rique
DEFUSER "SYSLATEST",9,,SYSLATEST ; t�te du dictionnaire en FLASH    
DEFUSER "LATEST",6,,LATEST ; pointer dernier mot dictionnaire
DEFUSER "PAD",3,,PAD       ; tampon de travail
DEFUSER "TIB",3,,TIB       ; tampon de saisie clavier
DEFUSER "PASTE",5,,PASTE   ; copie de TIB     
DEFUSER ">IN",3,,TOIN     ; pointeur position d�but dernier mot retourn� par WORD
DEFUSER "HP",2,,HP       ; HOLD pointer
DEFUSER "'SOURCE",6,,TICKSOURCE ; tampon source pour l'�valuation
DEFUSER "#SOURCE",7,,CNTSOURCE ; grandeur du tampon
DEFUSER "RPBREAK",7,,RPBREAK ; valeur de RSP apr�s l'appel de BREAK 
DEFUSER "DBGEN",5,,DBGEN ; activation d�sactivation break points
DEFUSER "SYSCONS",7,,SYSCONS ; entr�e standard
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes syst�me
;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCONST "VERSION",7,,VERSION,psvoffset(_version)        ; adresse cha�ne version
DEFCONST "R0",2,,R0,rstack   ; base pile retour
DEFCONST "S0",2,,S0,pstack   ; base pile arguments   
DEFCONST "RAMEND",6,,RAMEND,RAM_END          ;  fin m�moire RAM
DEFCONST "IMMED",5,,IMMED,F_IMMED       ; drapeau mot imm�diat
DEFCONST "HIDDEN",6,,HIDDEN,F_HIDDEN    ; drapeau mot cach�
DEFCONST "NMARK",5,,NMARK,F_MARK     ; drapeau marqueur utilis� par CFA>NFA
DEFCONST "LENMASK",7,,LENMASK,LEN_MASK ; masque longueur nom   
DEFCONST "BL",2,,BL,32                       ; caract�re espace
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD
DEFCONST "ULIMIT",6,,ULIMIT,EDS_BASE        ; limite espace dictionnaire
DEFCONST "DOCOL",5,,DOCOL,psvoffset(ENTER)  ; pointeur vers ENTER
DEFCONST "TRUE",4,,TRUE,-1 ; valeur bool�enne vrai
DEFCONST "FALSE",5,,FALSE,0 ; valeur bool�enne faux
DEFCONST "DP0",3,,DP0,DATA_BASE ; d�but espace utilisateur
    
; addresse buffer pour l'�valuateur    
DEFCODE "'SOURCE",7,,TSOURCE ; ( -- c-addr u ) 
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   conversion d'une cha�ne
;   en nombre
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: "DECIMAL?"  ( c -- f )
;   v�rifie si c est dans l'ensemble ASCII {'0'..'9'}
; arguments:
;   c   caract�re ASCII � v�rifier.
; retourne:
;   f   indicateur bool�en.
DEFWORD "DECIMAL?",8,,DECIMALQ
    .word DUP,LIT,'0',LESS,ZBRANCH,2f-$
    .word DROP,FALSE,EXIT
2:  .word LIT,'9',GREATER,INVERT,EXIT
  
    
; nom: >BASE10  ( u1 c -- u2 )
;   �tape de conversion d'une cha�ne de caract�re en 
;   entier d�cimal.
; arguments:
;   u1  entier r�sultant de la conversion d'une cha�ne en d�cimal
;   c  caract�re ASCII  dans l'intervalle {'0'..'9'}
; retourne:
;   u2    
DEFWORD ">BASE10",7,,TOBASE10
    .word LIT,'0',MINUS,LIT,10,ROT,STAR
    .word PLUS,EXIT
    
;v�rifie si le caract�re est un digit
; si valide retourne la valeur du digit et -1
; si invalide retourne x 0
DEFWORD "?DIGIT",6,,QDIGIT ; ( c -- x 0 | n -1 )
    .word DUP,LIT,96,UGREATER,ZBRANCH,1f-$
    .word LIT,32,MINUS ; lettre minuscule? convertie en minuscule
1:  .word DUP,LIT,'9',UGREATER,ZBRANCH,3f-$
    .word DUP,LIT,'A',ULESS,ZBRANCH,2f-$
    .word LIT,0,EXIT ; pas un digit
2:  .word LIT,7,MINUS    
3:  .word LIT,'0',MINUS
    .word DUP,BASE,FETCH,ULESS,EXIT
  
;v�rifie si le caract�re qui a mis fin � >NUMBER
; est {'.'|','}. Si c'est le cas il s'agit d'un
; nombre double pr�cision. saute le caract�re
; et retourne -1. Dans le cas contraire retourne 0  
DEFWORD "?DOUBLE",7,,QDOUBLE ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,LIT,'.',EQUAL,ZBRANCH,2f-$
1:  .word LIT,1,SLASHSTRING,LIT,-1,BRANCH,9f-$
2:  .word OVER,CFETCH,LIT,',',EQUAL,ZBRANCH,8f-$
    .word BRANCH,1b-$
8:  .word LIT,0
9:  .word EXIT  
  
;converti la cha�ne en nombre
;en utilisant la valeur de BASE
;la conversion s'arr�te au premier
;caract�re non num�rique
; 'ud1' est initialis� � z�ro  
; <c-addr1 u1> sp�cifie le d�but et le nombre
; de caract�res de la cha�ne    
DEFWORD ">NUMBER",7,,TONUMBER ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
1:   .word LIT,0,TOR ; indique si le dernier caract�re �tait un digit
2:   .word DUP,ZBRANCH,7f-$
     .word OVER,CFETCH,QDIGIT  ; ud1 c-addr u1 n|x f
     .word TBRANCH,4f-$
     .word RFROM,ZBRANCH,8f-$
     .word DROP,QDOUBLE,ZBRANCH,9f-$
     .word RFROM,RFROM,LIT,2,OR,TOR,TOR ; on change le flag du signe pour ajouter le flag double
     .word BRANCH,1b-$
4:   .word RDROP,LIT,-1,TOR ; dernier caract�re �tait un digit
     .word TOR,TWOSWAP,BASE,FETCH,UDSTAR
     .word RFROM,MPLUS,TWOSWAP
     .word LIT,1,SLASHSTRING,BRANCH,2b-$
7:   .word RFROM
8:   .word DROP
9:   .word EXIT
   
;v�rifie s'il y a un signe '-'
; � la premi�re postion de la cha�ne sp�cifi�e par <c-addr u>
; retourne f=1 si '-' sinon f=0    
; s'il y a un signe avance au del� du signe
DEFWORD "?SIGN",5,,QSIGN ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,CLIT,'-',EQUAL,TBRANCH,8f-$
    .word LIT,0,BRANCH,9f-$
8:  .word LIT,1,SLASHSTRING,LIT,1
9:  .word EXIT
    
;v�rifie s'il y a un modificateur de base
; modifie la base en cons�quence 
; avance le pointeur c-addr si requis  
DEFWORD "?BASE",5,,QBASE ; ( c-addr u1 -- c-addr' u1'  )
    .word OVER,CFETCH,CLIT,'$',EQUAL,ZBRANCH,1f-$
    .word LIT,16,BASE,STORE,BRANCH,8f-$
1:  .word OVER,CFETCH,CLIT,'#',EQUAL,ZBRANCH,2f-$
    .word LIT,10,BASE,STORE,BRANCH,8f-$
2:  .word OVER,CFETCH,CLIT,'%',EQUAL,ZBRANCH,9f-$
    .word LIT,2,BASE,STORE
8:  .word SWAP,ONEPLUS,SWAP,ONEMINUS    
9:  .word EXIT

; conversion d'une cha�ne en nombre
; c-addr indique le d�but de la cha�ne
; utilise la base active sauf si la cha�ne d�bute par '$'|'#'|'%'
; pour entrer un nombre double pr�cision
; il faut mettre un point � une position quelconque
; sauf � la premi�re position
; double ::=  ['-'](digit['.'])* 
DEFWORD "?NUMBER",7,,QNUMBER ; ( c-addr -- c-addr 0 | n -1 )
    .word BASE,FETCH,TOR ; sauvegarde la valeur de BASE 
    .word DUP,LIT,0,DUP,ROT,COUNT,QBASE  ; c-addr 0 0 c-addr' u'
    .word QSIGN,TOR  ; c-addr 0 0 c-addr' u' R: signFlag
4:  .word TONUMBER ; c-addr n1 n2 c-addr' u'
    .word ZBRANCH,1f-$ 
    .word RFROM,TWODROP,TWODROP,LIT,0,BRANCH,8f-$
1:  .word DROP,ROT,DROP
    .word RFETCH,ODD,ZBRANCH,2f-$
    .word DNEGATE
2:  .word RFROM,LIT,2,AND,TBRANCH,3f-$
    .word DROP
3:  .word LIT,-1
8:  .word RFROM,BASE,STORE ; restitue la valeur de BASE
    .word EXIT
    
  
;imprime la liste des mots du dictionnaire
DEFWORD "WORDS",5,,WORDS ; ( -- )
    .word LIT,0,NEWLINE,LATEST
1:  .word FETCH,QDUP,ZBRANCH,8f-$
    .word DUP,CFETCH,LENMASK,AND  ; n NFA LEN
    .word GETCUR,DROP
5:  .word PLUS,LIT,64,ULESS,TBRANCH,3f-$ ; n NFA
    .word NEWLINE
3:  .word TOR,ONEPLUS,RFETCH,COUNT,TYPE,SPACE
    .word RFROM,TWOMINUS,BRANCH,1b-$
8:  .word NEWLINE,DOT,EXIT
    
; convertie la cha�ne compt�e en majuscules
DEFCODE "UPPER",5,,UPPER ; ( c-addr -- c-addr )
    mov T, W1
    mov.b [W1],W2
1:  cp0.b W2
    bra z, 3f
    inc W1,W1
    mov.b [W1],W0
    dec.b W2,W2
    cp.b W0, #'a'
    bra ltu, 1b
    cp.b W0,#'z'
    bra gtu, 1b
    sub.b #32,W0
    mov.b W0,[W1]
    bra 1b
3:  NEXT

;avance au del� de 'c'
DEFCODE "SKIP",4,,SKIP ; ( addr u c -- addr' u' )
    mov T, W0 ; c
    DPOP ; T=u
    mov [DSP],W1 ; addr
    cp0 T
    bra z, 8f
2:  cp.b W0,[W1]
    bra nz, 8f
    inc W1,W1
    dec T,T
    bra nz, 2b
8:  mov W1,[DSP]
    NEXT
  
; avance ajuste >IN
DEFWORD "ADR>IN",7,,ADRTOIN ; ( adr' -- )
    .word TSOURCE,ROT,ROT,MINUS,MIN,LIT,0,MAX
    .word TOIN,STORE,EXIT
    
;avance a de n caract�res     
DEFWORD "/STRING",7,,SLASHSTRING ; ( a u n -- a+n u-n )
    .word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

; saute touts les caract�re 'c'
; ensuite accumule les caract�re jusqu'au
; prochain 'c'    
DEFWORD "PARSE",5,,PARSE ; c -- c-addr n
        .word TSOURCE,TOIN,FETCH,SLASHSTRING ; c src' u'
        .word OVER,TOR,ROT,SCAN  ; src' u'
        .word OVER,SWAP,ZBRANCH, parse1-$ 
        .word ONEPLUS  ; char+
parse1: .word ADRTOIN ; adr'
        .word RFROM,TUCK,MINUS,EXIT 
    
    
; localise le prochain mot d�limit� par 'c'
; la variable TOIN indique la position courante
; le mot trouv� est copi� � la position DP
; met � jour >IN
DEFWORD "WORD",4,,WORD ; ( c -- c-addr )
    .word DUP,TSOURCE,TOIN,FETCH,SLASHSTRING ; c c c-addr' u'
    .word ROT,SKIP ; c c-addr' u'
    .word DROP,ADRTOIN,PARSE
    .word HERE,TOCOUNTED,HERE
    .word EXIT
    

; recherche un mot dans le dictionnaire
; ne retourne pas les mots cach�s (attribut: F_HIDDEN)    
; retourne: c-addr 0 si adresse non trouv�e
;           xt 1 trouv� mot imm�diat
;	    xt -1 trouv� mot non-imm�diat
.equ  LFA, W1 ; link field address
.equ  NFA, W2 ; name field addrress
.equ  TARGET,W3 ;pointer cha�ne recherch�e
.equ  LEN, W4  ; longueur de la cha�ne recherch�e
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
    and.b #LEN_MASK+F_HIDDEN,W0
    cp.b W0,LEN
    bra z, same_len
next_entry:    
    mov [LFA],NFA
    bra try_next
same_len:    
    ; compare les 2 cha�nes
    mov TARGET,NAME
    mov.b LEN,CNTR
1:  cp0.b CNTR
    bra z, match
    mov.b [NAME++],W0
    cp.b W0,[NFA++]
    bra neq, next_entry
    dec.b CNTR,CNTR
    bra 1b
    ;trouv� 
match:
    btsc NFA,#0 ; alignement sur adresse paire
    inc NFA,NFA ; CFA
    mov NFA,[DSP] ; CFA
    setm T
    and.b #F_IMMED,FLAGS
    bra z, 2f
    neg T,T
    bra 2f
    ; pas trouv�
not_found:    
    mov #0,T
2:  NEXT

  
 
; lecture d'une ligne de texte au clavier
; cha�ne termin�e par touche 'ENTER'
; cette touche est remplac�e par un espace (ASCII 32 )
; et est compt� dans la longueur de la cha�ne.    
; arguments:
;   c-addr addresse du buffer
;   +n1 longueur du buffer
; retourne:
;   +n2 longueur de la cha�ne lue    
DEFWORD "ACCEPT",6,,ACCEPT  ; ( c-addr +n1 -- +n2 )
    .word OVER,PLUS,TOR,DUP  ;  ( c-addr c-addr  R: bound )
1:  .word KEY,DUP,LIT,VK_CR,EQUAL,ZBRANCH,2f-$
    .word DROP,BL,OVER,CSTORE,SWAP,MINUS,ONEPLUS,RDROP,EXIT
2:  .word DUP,LIT,VK_BACK,EQUAL,ZBRANCH,3f-$
    .word DROP,TWODUP,EQUAL,TBRANCH,1b-$
    .word DELBACK,ONEMINUS,BRANCH,1b-$
3:  .word DUP,LIT,CTRL_X,EQUAL,ZBRANCH,4f-$
    .word DROP,DELLINE,DROP,DUP,BRANCH,1b-$
4:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,4f-$
    .word EMIT,DROP,DUP,BRANCH,1b-$
4:  .word DUP,LIT,CTRL_V,EQUAL,ZBRANCH,5f-$
    .word DROP,DELLINE,PASTE,FETCH,COUNT,TYPE
    .word DROP,DUP,GETCLIP,PLUS,BRANCH,1b-$
5:  .word OVER,RFETCH,EQUAL,TBRANCH,6f-$
    .word DUP,EMIT,OVER,CSTORE,ONEPLUS,BRANCH,1b-$
6:  .word DROP,BRANCH,1b-$
  
   
; retourne la sp�cification
; de la cha�ne compt�e dont
; l'adresse est c-addr1  
DEFWORD "COUNT",5,,COUNT ; ( c-addr1 -- c-addr2 u )
   .word DUP,CFETCH,TOR,ONEPLUS,RFROM,LENMASK,AND,EXIT
   
; imprime 'mot?'
; signifiant que le mot n'a pas
; �t� trouv� dans le dictionnaire.
; r�initialise DSP et appel QUIT   
DEFWORD "ERROR",5,,ERROR ;  ( c-addr -- )  
   .word SPACE,COUNT,TYPE
   .word SPACE,CLIT,'?',EMIT
   .word LIT,0,STATE,STORE
   .word S0,FETCH,SPSTORE
   .word NEWLINE,QUIT

; copie cha�ne compt�e de src vers dest
; src addresse cha�ne � copi�e
; n longueur de la cha�ne
; dest adresse destination   
DEFWORD ">COUNTED",8,,TOCOUNTED ; ( src n dest -- )
    .word TWODUP,CSTORE,ONEPLUS,SWAP,MOVE,EXIT

; interpr�te la cha�ne indiqu�e par c-addr u   
; facteur commun entre QUIT et EVALUATE    
DEFWORD "INTERPRET",9,,INTERPRET ; ( c-addr u -- )
        .word SRCSTORE,LIT,0,TOIN,STORE
1:      .word BL,WORD,DUP,CFETCH,ZBRANCH,9f-$
        .word UPPER,FIND,QDUP,ZBRANCH,4f-$
        .word ONEPLUS,STATE,FETCH,ZEROEQ,OR
        .word ZBRANCH,2f-$
        .word EXECUTE,BRANCH,1b-$
2:      .word COMMA
3:      .word BRANCH,1b-$
4:      .word QNUMBER,ZBRANCH,5f-$
        .word LITERAL,BRANCH,1b-$
5:      .word COUNT,TYPE,LIT,'?',EMIT,NEWLINE,ABORT
9:      .word DROP,EXIT

; interpr�te la cha�ne � l'adrese 'c-addr' et de longueur 'u'
; sauvegarde la valeur de source SUR R: � l'entr�e
; et restaure avant de quitter.      
DEFWORD "EVALUATE",8,,EVAL ; ( i*x c-addr u -- j*x )
    .word TSOURCE,TOR,TOR ; sauvegarde source
    .word TOIN,FETCH,TOR,INTERPRET
    .word RFROM,TOIN,STORE,RFROM,RFROM,SRCSTORE 
    .word EXIT
    
; imprime le prompt et passe � la ligne suivante    
;DEFWORD "OK",2,,OK 
HEADLESS OK,HWORD  ; ( -- )
    .word GETX,LIT,3,PLUS,LIT,CPL,LESS,TBRANCH,1f-$,NEWLINE    
1:  .word SPACE, LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    

; vide la pile dstack et appel QUIT
; si compilation en cours annulle les effets de celle-ci  
DEFWORD "ABORT",5,,ABORT
    .word STATE,FETCH,ZBRANCH,1f-$
    .word LATEST,FETCH,NFATOLFA,DUP,FETCH,LATEST,STORE,DP,STORE
1:  .word S0,SPSTORE,QUIT
    
;runtime de ABORT"
HEADLESS QABORT,HWORD  
;DEFWORD "?ABORT",6,F_HIDDEN,QABORT ; ( i*x f  -- | i*x) ( R: j*x -- | j*x )
    .word DOSTR,SWAP,ZBRANCH,9f-$
    .word COUNT,TYPE,NEWLINE,ABORT
9:  .word DROP,EXIT
  
; compile le runtime de ?ABORT
; a utilis� � l'int�rieur d'une d�finition  
DEFWORD "ABORT\"",6,F_IMMED,ABORTQUOTE ; (  --  )
    .word CFA_COMMA,QABORT,STRCOMPILE,EXIT
    
; copie le TIB dans PASTE
;  le premier caract�re dans PASTE est le compte    
;  arguments:
;	n+ nombre de caract�res    
DEFWORD "CLIP",4,,CLIP ; ( n+ -- )
    .word DUP,PASTE,FETCH,STORE
    .word TIB,FETCH,SWAP,PASTE,FETCH,ONEPLUS,SWAP,MOVE,EXIT

; copie PASTE dans TIB
; retourne le compte.    
DEFWORD "GETCLIP",7,,GETCLIP ; ( -- n+ )
    .word PASTE,FETCH,COUNT,SWAP,OVER 
    .word TIB,FETCH,SWAP,MOVE  
    .word EXIT
    
; boucle lecture/ex�cution/impression
HEADLESS REPL,HWORD    
;DEFWORD "REPL",4,F_HIDDEN,REPL ; ( -- )
1:  .word TIB,FETCH,DUP,LIT,CPL-1,ACCEPT,DUP,ONEMINUS,CLIP ; ( addr u )
    .word SPACE,INTERPRET 
    .word STATE,FETCH,TBRANCH,2f-$
    .word OK
2:  .word NEWLINE
    .word BRANCH, 1b-$
    
; boucle de l'interpr�teur    
DEFWORD "QUIT",4,,QUIT ; ( -- )
    .word LIT,0,STATE,STORE
    .word R0,RPSTORE
    .word REPL
    
; commentaire limit� par ')'
DEFWORD "(",1,F_IMMED,LPAREN ; parse ccccc)
    .word LIT,')',PARSE,TWODROP,EXIT

; commentaire jusqu'� la fin de la ligne
DEFWORD "\\",1,F_IMMED,COMMENT ; ( -- )
    .word TSOURCE,PLUS,ADRTOIN,EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   compilateur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; les 3 mots suivants servent � 
; passer d'un champ � l'autre dans
; l'ent�te du dictionnaire
    
; passage du champ NFA au champ LFA
; simple puisqu'il est juste avant ce dernier    
DEFWORD "NFA>LFA",7,,NFATOLFA ; ( nfa -- lfa )
    .word LIT,2,MINUS,EXIT
    
; passe du champ NFA au champ CFA
; le CFA est apr�s le nom align� sur adresse paire.    
DEFWORD "NFA>CFA",7,,NFATOCFA ; ( nfa -- cfa )
    .word DUP,CFETCH,LENMASK,AND,PLUS,ONEPLUS,ALIGNED,EXIT
 
; passe du champ CFA au champ PFA
DEFWORD ">BODY",5,,TOBODY ; ( cfa -- pfa )
    .word DUP,FETCH,LIT,FETCH_EXEC,EQUAL,ZBRANCH,1f-$
    .word CELLPLUS
1:  .word CELLPLUS,EXIT;

    
;passe du champ CFA au champ NFA
;  Il n'y a pas de lien arri�re entre le CFA et le NFA
;  Le bit F_MARK est utilis� pour marquer l'octet � la position NFA
;  le CFA �tant imm�diatement apr�s le nom, il suffit de 
;  reculer octet par octet jusqu'� atteindre un octet avec le bit F_MARK==1
;  puisque les caract�res du nom sont tous < 128    
DEFWORD "CFA>NFA",7,,CFATONFA ; ( cfa -- nfa|0 )
    .word DUP,LIT,DATA_BASE,ULESS,ZBRANCH,1f-$ ; si cfa<DATA_BASE ce n'est pas un cfa
    .word DUP,XOR,BRANCH,9f-$ ; ( cfa -- 0 )
1:  .word DUP,TOR,LIT,33,TOR ; (cfa -- R: cfa 33 ) recule au maximum de 33 octets
2:  .word ONEMINUS,DUP,CFETCH,DUP,LIT,F_MARK,AND,TBRANCH,3f-$  ; F_MARK?
    .word DROP,RFROM,ONEMINUS,DUP,ZBRANCH,7f-$ 
    .word TOR,BRANCH,2b-$
3:  .word RDROP,LENMASK,AND   ; branche ici si F_MARK
    .word OVER,PLUS,ONEPLUS,ALIGNED,RFROM,EQUAL,DUP,ZBRANCH,8f-$ ; aligned(NFA+LEN+1)==CFA ?
    .word DROP,BRANCH,9f-$ ; oui
7:  .word RDROP  ; compteur limite � z�ro
8:  .word SWAP,DROP  ;non
9:  .word EXIT
  
; v�rifie si le dictionnaire utilisateur
; est vide  
DEFWORD "?EMPTY",6,,QEMPTY ; ( -- f)
    .word DP0,HERE,EQUAL,EXIT 
    
; met � 1 l'indicateur F_IMMED
; sur le dernier mot d�fini.    
DEFWORD "IMMEDIATE",9,,IMMEDIATE ; ( -- )
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,IMMED,OR,SWAP,CSTORE
9:  .word EXIT
    
;cache la d�finition en cours  
; la variable LAST contient le NFA  
DEFWORD "HIDE",4,,HIDE ; ( -- )
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,HIDDEN,OR,SWAP,CSTORE
9:  .word EXIT

; marque le champ compte du nom
; pour la recherche de CFA>NFA
HEADLESS NAMEMARK,HWORD  
;DEFWORD "(NMARK)",7,F_HIDDEN,NAMEMARK
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,NMARK,OR,SWAP,CSTORE
9:  .word EXIT
  
  
DEFWORD "REVEAL",6,,REVEAL ; ( -- )
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,HIDDEN,INVERT,AND,SWAP,CSTORE
9:  .word EXIT
    
; allocation/rendition de m�moire dans le dictionnaire
; si n est n�gatif n octets seront rendus.
;  arguements:
;     n   nombre d'octets
DEFWORD "ALLOT",5,,ALLOT ; ( n -- )
    .word DP,PLUSSTORE,EXIT

; alloue une cellule pour x � la position DP
DEFWORD ",",1,,COMMA  ; ( x -- )
    .word HERE,STORE,LIT,CELL_SIZE,ALLOT
    .word EXIT
    
; alloue le caract�re 'c' � la position DP    
DEFWORD "C,",2,,CCOMMA ; ( c -- )    
    .word HERE,CSTORE,LIT,1,ALLOT
    .word EXIT
    
    
    
; Extrait le mot suivant du flux 
; d'entr�e et le recherche dans le dictionnaire
; l'op�ration avorte en cas d'erreur.    
DEFWORD "'",1,,TICK ; ( <ccc> -- xt )
    .word BL,WORD,DUP,CFETCH,ZEROEQ,QNAME
    .word UPPER,FIND,ZBRANCH,5f-$
    .word BRANCH,9f-$
5:  .word COUNT,TYPE,SPACE,LIT,'?',EMIT,NEWLINE,ABORT    
9:  .word EXIT

; version imm�diate de '
DEFWORD "[']",3,F_IMMED,COMPILETICK ; cccc 
    .word QCOMPILE
    .word TICK,CFA_COMMA,LIT,COMMA,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  les 4 mots suivants
;  sont utilis�s pour r�soudre
;  les adresses de sauts.    
;  les sauts sont des relatifs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;empile la position actuelle de DP
; cette adresse sera la cible
; d'un branchement arri�re    
DEFWORD "<MARK",5,F_IMMED,MARKADDR ; ( -- a )
   .word QCOMPILE,HERE, EXIT

;compile l'adresse d'un branchement arri�re
; compl�ment de '<MARK'    
; le branchement est relatif � la position
; actuelle de DP    
DEFWORD "<RESOLVE",8,F_IMMED,BACKJUMP ; ( a -- )    
    .word QCOMPILE,HERE,MINUS,COMMA, EXIT
    
;reserve un espace pour la cible d'un branchement avant qui
; sera r�solu ult�rieurement.    
DEFWORD ">MARK",5,F_IMMED,MARKSLOT ; ( -- slot )
    .word QCOMPILE,HERE,LIT,0,COMMA,EXIT
    
; compile l'adresse cible d'un branchement avant
; compl�ment de '>MARK'    
; l'espace r�serv� pour la cible est indiqu�e
; au sommet de la pile
DEFWORD ">RESOLVE",8,F_IMMED,FOREJUMP ; ( -- slot )
    .word QCOMPILE,DUP,HERE,SWAP,MINUS,SWAP,STORE,EXIT
    

; passe en mode interpr�tation
DEFWORD "[",1,F_IMMED,LBRACKET ; ( -- )
    .word LIT,0,STATE,STORE
9:  .word EXIT
  
; passe en mode compilation
DEFWORD "]",1,F_IMMED,RBRACKET ; ( -- )
    .word LIT,-1,STATE,STORE
9:  .word EXIT

;compile le mot suivant dans le flux
;DEFWORD "[COMPILE]",9,F_IMMED,BRCOMPILE ; ( <cccc> -- )
;  .word QCOMPILE,TICK,COMMA,EXIT
  
;compile un cfa fourni en literal
DEFWORD "CFA,",6,F_IMMED,CFA_COMMA  ; ( -- )
  .word RFROM,DUP,FETCH,COMMA,CELLPLUS,TOR,EXIT

; avorte si le nom n'est pas trouv� dans le dictionnaire  
DEFWORD "?WORD",5,,QWORD ; ( -- c-addr 0 | cfa 1 | cfa -1 )
   .word BL,WORD,UPPER,FIND,QDUP,ZBRANCH,2f-$,EXIT
2: .word COUNT,TYPE,LIT,'?',EMIT,ABORT
  
;diff�re la compilation du mot qui suis dans le flux
DEFWORD "POSTPONE",8,F_IMMED,POSTONE ; ( <ccc> -- )
    .word QCOMPILE ,QWORD
    .word ZEROGT,TBRANCH,3f-$
  ; mot non immm�diat
    .word CFA_COMMA,LIT,COMMA,CFA_COMMA,COMMA,EXIT
  ; mot imm�diat  
3:  .word COMMA    
    .word EXIT    
  
DEFWORD "LITERAL",7,F_IMMED,LITERAL  ; ( x -- ) 
    .word STATE,FETCH,ZBRANCH,9f-$
    .word CFA_COMMA,LIT,COMMA
9:  .word EXIT

;RUNTIME  qui retourne l'adresse d'une cha�ne lit�rale
;utilis� par (S") et (.")
HEADLESS DOSTR, HWORD  
;DEFWORD "(DO$)",5,F_HIDDEN,DOSTR ; ( -- addr )
    .word RFROM, RFETCH, RFROM, COUNT,PLUS, ALIGNED, TOR, SWAP, TOR, EXIT

;RUNTIME  de s"
; empile le descripteur de la cha�ne lit�rale
; qui suis.    
HEADLESS STRQUOTE, HWORD    
;DEFWORD "(S\")",4,F_HIDDEN,STRQUOTE ; ( -- addr u )    
    .word DOSTR,COUNT,EXIT
 
;RUNTIME de C"
; empile l'adresse de la cha�ne compt�e.
HEADLESS RT_CQUOTE, HWORD    
;DEFWORD "(C\")",4,F_HIDDEN,RT_CQUOTE ; ( -- c-addr )
    .word DOSTR,EXIT
    
;RUNTIME DE ."
; imprime la cha�ne lit�rale    
HEADLESS DOTSTR, HWORD    
;DEFWORD "(.\")",4,F_HIDDEN,DOTSTR ; ( -- )
    .word DOSTR,COUNT,TYPE,EXIT

; empile le descripteur de la cha�ne qui suis dans le flux.    
HEADLESS SLIT, HWORD    
;DEFWORD "SLIT",4,F_HIDDEN, SLIT ; ( -- c-addr u )
    .word LIT,'"',WORD,COUNT,EXIT
    
; (,") compile une cha�ne lit�rale    
HEADLESS STRCOMPILE, HWORD    
;DEFWORD "(,\")",4,F_HIDDEN,STRCOMPILE ; ( -- )
    .word SLIT,PLUS,ALIGNED,DP,STORE,EXIT

    
; interpr�tation: imprime la cha�ne lit�rale qui suis.    
; compilation: compile le runtine (S") et la cha�ne lit�rale    
DEFWORD "S\"",2,F_IMMED,SQUOTE ; ccccc" runtime: ( -- | c-addr u)
    .word QCOMPILE
    .word CFA_COMMA,STRQUOTE,STRCOMPILE,EXIT
    
DEFWORD "C\"",2,F_IMMED,CQUOTE ; ccccc" runtime ( -- c-addr )
    .word QCOMPILE
    .word CFA_COMMA,RT_CQUOTE,STRCOMPILE,EXIT
    
    
; interpr�tation: imprime la cha�ne lit�rale qui suis
; compilation: compile le runtime  (.")    
DEFWORD ".\"",2,F_IMMED,DOTQUOTE ; ( -- )
    .word STATE,FETCH,ZBRANCH,4f-$
    .word CFA_COMMA,DOTSTR,STRCOMPILE,EXIT
4:  .word SLIT,TYPE,EXIT  
    
DEFWORD "RECURSE",7,F_IMMED,RECURSE ; ( -- )
    .word LATEST,FETCH,NFATOCFA,COMMA,EXIT 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots contr�lant le flux
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; compile xt de (DO)
; empile l'adresse du d�but de la boucle sur cstack
; empile 0 comme garde pour FIXLEAVE   
DEFWORD "DO",2,F_IMMED,DO ; ( C: -- a 0 ) compile xt de (DO)
    .word QCOMPILE,CFA_COMMA,DODO
    .word HERE,TOCSTK,LIT,0,TOCSTK,EXIT

; compile xt de (?DO) ref: 6.2.0620
; ?DO est semblabe � DO except� que la 
; boucle n'est ex�cut�e qui si les param�tres initiaux
; ne sont pas �gaux: start<>limit    
; empile l'adresse de d�but de la boucle sur cstack
; empile 0 comme garde pour FIXLEAVE
DEFWORD "?DO",3,F_IMMED,QDO ; ( C: -- a-addr1 0 a-addr2 )
    .word QCOMPILE,CFA_COMMA,DOQDO
    .word HERE,LIT,2*CELL_SIZE,PLUS,TOCSTK,LIT,0,TOCSTK
    .word CFA_COMMA,BRANCH,HERE,TOCSTK,EXIT
    
    
;compile LEAVE
DEFWORD "LEAVE",5,F_IMMED,LEAVE ; (C: -- slot )
    .word QCOMPILE,CFA_COMMA,UNLOOP
    .word CFA_COMMA,BRANCH,MARKSLOT,TOCSTK,EXIT  
    
    
; r�sout toutes les adresses pour les branchements
; � l'int�rieur des boucles DO LOOP|+LOOP
HEADLESS FIXLEAVE, HWORD    
;DEFWORD "FIXLEAVE",8,F_IMMED|F_HIDDEN,FIXLEAVE ; (C: a 0 i*slot -- )
1:  .word CSTKFROM,QDUP,ZBRANCH,9f-$
    .word DUP,HERE,CELLPLUS,SWAP,MINUS,SWAP,STORE
    .word BRANCH,1b-$
9:  .word CSTKFROM,BACKJUMP,EXIT    
 
; compile xt de (LOOP)  
; r�sout toutes les adresses de saut.  
DEFWORD "LOOP",4,F_IMMED,LOOP ; ( -- )
    .word QCOMPILE,CFA_COMMA,DOLOOP,FIXLEAVE,EXIT
    
; compile execution de +LOOP
; r�sout toutes les adressess de saut.    
DEFWORD "+LOOP",5,F_IMMED,PLUSLOOP ; ( -- )
    .word QCOMPILE,CFA_COMMA,DOPLOOP,FIXLEAVE,EXIT
    
; compile le d�but d'une boucle    
DEFWORD "BEGIN",5,F_IMMED,BEGIN ; ( -- a )
    .word QCOMPILE, MARKADDR, EXIT

; compile une boucle infinie    
DEFWORD "AGAIN",5,F_IMMED,AGAIN ; ( a -- )
    .word QCOMPILE,CFA_COMMA,BRANCH,BACKJUMP,EXIT
    
DEFWORD "UNTIL",5,F_IMMED,UNTIL ; ( a -- )
    .word QCOMPILE,CFA_COMMA,ZBRANCH,BACKJUMP,EXIT

DEFWORD "IF",2,F_IMMED,IIF ; ( -- slot )
    .word QCOMPILE,CFA_COMMA,ZBRANCH,MARKSLOT,EXIT

DEFWORD "THEN",4,F_IMMED,THEN ; ( slot -- )
    .word QCOMPILE,FOREJUMP,EXIT
    
DEFWORD "ELSE",4,F_IMMED,ELSE ; ( slot1 -- slot2 )     
    .word QCOMPILE,CFA_COMMA,BRANCH,MARKSLOT,SWAP,THEN,EXIT

; compile un branchement avant    
DEFWORD "WHILE",5,F_IMMED,WHILE ;  ( a -- slot a)   
    .word QCOMPILE,CFA_COMMA,ZBRANCH,MARKSLOT,SWAP,EXIT
    
; compile un branchement arri�re et
; r�sout le branchement avant du WHILE    
DEFWORD "REPEAT",6,F_IMMED,REPEAT ; ( slot a -- )
    .word QCOMPILE,CFA_COMMA,BRANCH,BACKJUMP,FOREJUMP,EXIT

;marque le d�but d'une structure CASE ENDCASE
DEFWORD "CASE",4,F_IMMED,CASE ; ( -- case-sys )
    .word QCOMPILE,LIT,0,EXIT ; marque la fin de la liste des fixup

;compile la strucutre d'un OF    
DEFWORD "OF",2,F_IMMED,OF ; ( -- slot )    
    .word QCOMPILE,CFA_COMMA,OVER,CFA_COMMA,EQUAL,CFA_COMMA,ZBRANCH
    .word MARKSLOT,EXIT
    
;compile la structure d'un ENDOF
DEFWORD "ENDOF",5,F_IMMED,ENDOF ; ( slot 1 -- slot2 )
    .word QCOMPILE,CFA_COMMA,BRANCH,MARKSLOT,SWAP,FOREJUMP,EXIT
    
;r�soue les sauts de chaque ENDOF
; et compile un DROP
DEFWORD "ENDCASE",7,F_IMMED,ENDCASE ; ( case-sys -- )    
    .word QCOMPILE
1:  .word QDUP,ZBRANCH,8f-$
    .word FOREJUMP,BRANCH,1b-$
8:  .word CFA_COMMA,DROP,EXIT
  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; certains mots ne peuvent-�tre utilis�s
; que par le compilateur
DEFWORD "?COMPILE",8,F_IMMED,QCOMPILE ; ( -- )
    .word STATE,FETCH,ZEROEQ,TBRANCH,1f-$,EXIT
1:  .word CR,HERE,COUNT,TYPE,SPACE
2:  .word LIT,-1 
    .word QABORT
    .byte 17
    .ascii "compile only word"
    .align 2
    .word EXIT

; Si f==0 affiche message "name missing" et appelle ABORT    
DEFWORD "?NAME",5,,QNAME ; ( i*x f -- | i*x )
    .word QABORT
    .byte 12
    .ascii "name missing"
    .align 2
    .word EXIT

; ins�re le lien vers le NFA du mot dont
; CFA est au sommet de S � la fin de la cha�ne
; de liens du dictionnaire.
; si xt1 n'a pas de nom dans le dictionnaire
; le r�sultat est impr�visible.    
;DEFWORD "LINK",4,F_IMMED,LINK ; ( S: xt1 -- )
;    ; met le NFA qui est dans LATEST dans le NFA de xt1
;    .word CFATONFA,DUP,LATEST,FETCH,OVER,NFATOLFA,STORE
;    ; met le NFA de xt1 dans LATEST
;    .word LATEST,STORE,EXIT 

; cr� une d�finition sans nom dans le dictionnaire
; et laisse son CFA (xt) sur la pile S
; met STATE en mode compilation    
DEFWORD ":NONAME",7,,COLON_NO_NAME ; ( S: -- xt )
    .word HERE,CFA_COMMA,ENTER,RBRACKET,EXIT
    
DEFWORD "EXIT,",5,F_IMMED,EXITCOMMA ; ( -- )
    .word CFA_COMMA,EXIT,EXIT

; ajoute un nouveau nom dans le dictionnaire
; � la sortie HERE retourne l'adresse du CFA    
DEFWORD "HEADER",6,,HEADER ; ( -- )
    .word LATEST,DUP,FETCH,COMMA,HERE
    .word SWAP,STORE
    .word BL,WORD,UPPER,CFETCH,DUP,ZEROEQ,QNAME
    .word ONEPLUS,ALLOT,ALIGN,NAMEMARK,HIDE,EXIT
 
; efface le mot d�sign�e et tous les suivant
DEFWORD "FORGET",6,,FORGET ; cccc
    .word TICK,CFATONFA,NFATOLFA,DUP,LIT,0x8000,UGREATER
    .word QABORT
    .byte  26
    .ascii "Can't forget word in FLASH"
    .align 2
    .word DUP,DP,STORE,FETCH,LATEST,STORE,EXIT    

; cr�e un mot marker qui efface tous les mots qui le suivent
; lorsqu'il est invoqu�.
DEFWORD "MARKER",6,,MARKER ; cccc
    .word HEADER,HERE,CFA_COMMA,ENTER,CFA_COMMA,LIT,COMMA
    .word CFA_COMMA,RT_MARKER,EXITCOMMA,REVEAL,EXIT
    
HEADLESS  RT_MARKER,HWORD   
    .word CFATONFA,NFATOLFA,DUP,DP,STORE,FETCH,LATEST,STORE
    .word EXIT
  
; cr�e une nouvelle d�finition dans le dictionnaire    
DEFWORD ":",1,,COLON ; ( name --  )
    .word HEADER ; ( -- )
    .word RBRACKET,CFA_COMMA,ENTER,EXIT

;RUNTIME utilis� par CREATE
; remplace ENTER    
    .global FETCH_EXEC
    FORTH_CODE
FETCH_EXEC: ; ( -- pfa )
     DPUSH
     mov WP,T         
     mov [T++],WP  ; CFA
     mov [WP++],W0
     goto W0
    
;cr� une nouvelle ent�te dans le dictionnaire
;qui peut-�tre �tendue par DOES>
DEFWORD "CREATE",6,,CREATE ; ( -- hook )
    .word HEADER,REVEAL
    .word LIT,FETCH_EXEC,COMMA
    .word CFA_COMMA,NOP
    .word EXIT    
  
    
; runtime DOES>    
HEADLESS "RT_DOES", HWORD ; ( -- )
    .word RFROM,DUP,CELLPLUS,TOR,FETCH,LATEST,FETCH
    .word NFATOCFA,CELLPLUS,STORE
    .word EXIT
    
; ajoute le runtime RT_DOES
DEFWORD "DOES>",5,F_IMMED,DOESTO  ; ( -- )
    .word CFA_COMMA,RT_DOES,HERE,LIT,2,CELLS,PLUS,COMMA
    .word EXITCOMMA,COLON_NO_NAME,DROP
    .word EXIT
    
; cr�ation d'une variable
DEFWORD "VARIABLE",8,,VARIABLE ; ()
    .word CREATE,LIT,0,COMMA,EXIT

; cr�ation d'une constante
DEFWORD "CONSTANT",8,,CONSTANT ; ()
    .word HEADER,REVEAL,LIT,DOCONST,COMMA,COMMA,EXIT
    
   
    
; termine une d�finition d�but�e par ":"
DEFWORD ";",1,F_IMMED,SEMICOLON  ; ( -- ) 
    .word QCOMPILE
    .word EXITCOMMA
    .word REVEAL
    .word LBRACKET,EXIT
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots du core �tendu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RUNTIME COMPIL�E PAR DEFER    
HEADLESS NOINIT,HWORD
;DEFWORD "(NOINIT)",8,F_HIDDEN,NOINIT ; ( -- )
    .word DOTSTR
    .byte  26
    .ascii "Uninitialized defered word"
    .align 2
    .word NEWLINE,ABORT
    
HEADLESS DEFEREXEC,HWORD
     .word FETCH,EXECUTE,EXIT
     
; cr�ation d'un mot la d�finition de la s�mantique d'ex�cution
; est diff�r�e.
; Utilise � s�mantique par d�faut (NOINIT)
DEFWORD "DEFER",5,,DEFER ; ccccc ( -- )
    .word CREATE,CFA_COMMA,NOINIT
    .word RT_DOES,DEFEREXEC,EXIT

; initialise la s�mantique d'ex�cution d'un mot d�finit avec DEFER 
;  xt1  CFA de la s�mantique que le mot doit ex�cut�
;  xt2  CFA du mot dif�r�.    
DEFWORD "DEFER!",6,,DEFERSTORE ;  ( xt1 xt2 -- )
    .word TOBODY,STORE,EXIT

; empile le xt interpr�t� par un mot d�fini avec DEFER
; xt1 CFA du mot dif�r�
; xt2 CFA de la s�mantique d'ex�cution de ce mot.    
DEFWORD "DEFER@",6,,DEFERFETCH ; ( xt1 -- xt2 )
    .word TOBODY,FETCH,EXIT
 
; initilalise la s�mantique d'ex�cution d'un mot d�finit avec DEFER
; le nom du mot dif�r� est fourni en texte    
DEFWORD "IS",2,,IS  ; ( xt1 cccc -- )
    .word TICK,TOBODY,STORE,EXIT
    
    
DEFWORD "ACTION-OF",9,,ACTIONOF ; ( ccc -- xt2 )
    .word TICK,TOBODY,FETCH,EXIT
    
    
; imprime le commentaire d�limit� par )
DEFWORD ".(",2,F_IMMED,DOTPAREN ; ccccc    
    .word LIT,')',WORD,COUNT,TYPE,EXIT
    
; envoie 2 �l�ment de S au sommet de R
; de sorte qu'il soient dans le m�me ordre
; >>> ne pas utiliser en mode interpr�tation    
DEFWORD "2>R",3,,TWOTOR ;  S: x1 x2 --  R: -- x1 x2
    .word RFROM,NROT,SWAP,TOR,TOR,TOR,EXIT
    
; envoie 2 �l�ments de R vers de sorte
; qu'ils soient dans le m�me ordre
; >>> ne pas utiliser en mode interpr�tation    
DEFWORD "2R>"3,,TWORFROM ; S: -- x1 x2  R: x1 x2 --
    .word RFROM,RFROM,RFROM,SWAP,ROT,TOR,EXIT
    
; copie 2 �l�ments de R vers S en consversant l'ordre    
; >>> ne pas utiliser en mode interpr�tation
; >>> 2R> doit-�tre appell� avant la sortie
; >>> de la routine qui utilise ce mot.    
; >>> Au pr�alable 2>R a �t� appell� dans la m�me routine.    
DEFWORD "2R@",3,,TWORFETCH ; S: -- x1 x2 R: x1 x2 -- x1 x2    
    .word RFROM,RFROM,RFETCH,OVER,TOR,ROT,TOR
    .word SWAP,EXIT
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;     OUTILS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Les mots suivants sont
;  des outils qui facilite
;  le d�bogage.
    
; v�rifie si DSP est dans les limites    
DEFWORD "?DSP",4,,QDSP    
    .word SPFETCH,S0,FETCH,ULESS
    .word QABORT
    .byte 17
    .ascii "S stack underflow"
    .align 2
    .word SPFETCH,S0,FETCH,LIT,DSTK_SIZE,TWOMINUS,PLUS,UGREATER
    .word QABORT
    .byte  16
    .ascii "S stack overflow"
    .align 2
    .word EXIT
    
; imprime le contenu de la pile des arguments
; sans en affect� le contenu.
; FORMAT:  < n >  X1 X2 X3 ... Xn=T
;  n est le nombre d'�l�ments
;  Xn  valeur sur la pile.  
DEFWORD ".S",2,,DOTS  ; ( -- )
    .word DEPTH,CLIT,'<',EMIT,DUP,DOT,CLIT,'>',EMIT,SPACE
1:  .word QDUP,ZBRANCH,2f-$,DUP,PICK,DOT,ONEMINUS
    .word BRANCH,1b-$  
2:  .word EXIT

;imprime le contenu de la pile des retours  
DEFWORD ".RTN",4,,DOTRTN ; ( -- )
    .word BASE, FETCH,HEX
    .word CLIT,'R',EMIT,CLIT,':',EMIT
    .word RPFETCH,R0,DODO
1:  .word DOI,FETCH,DOT,LIT,2,DOPLOOP,1b-$
    .word BASE,STORE,EXIT
  
;lit et imprime une plage m�moire
; n nombre de mots � lire
; addr adresse de d�part
; 8 mots par ligne d'affichage
DEFWORD "DUMP",4,,DUMP ; ( addr +n -- )
    .word QDUP,TBRANCH,3f-$,EXIT
3:  .word BASE,FETCH,TOR,HEX
    .word SWAP,LIT,0xFFFE,AND,SWAP,LIT,0,DODO
1:  .word DOI,LIT,15,AND,TBRANCH,2f-$
    .word NEWLINE,DUP,LIT,4,UDOTR,SPACE
2:  .word DUP,ECFETCH,LIT,3,UDOTR,LIT,1,PLUS
    .word DOLOOP,1b-$,DROP
    .word RFROM,BASE,STORE,EXIT

; active/d�sactive les breaks points    
DEFWORD "DEBUG",5,,DEBUG ; ( f -- )
    .word DBGEN,STORE    
    .word EXIT
    
; interrompt le programme en cours d'ex�cution et
; entre en mode interpr�teur
DEFWORD "BREAK",5,,BREAK ; ( ix n -- ix )
    .word DBGEN,FETCH,TBRANCH,1f-$
    .word DROP,EXIT
1:  .word RPFETCH,RPBREAK,STORE
    .word NEWLINE,DOTSTR
    .byte  13
    .ascii "break point: "
    .align 2
    .word DOT,NEWLINE,DOTS,NEWLINE,REPL
    .word EXIT

; r�sume le programme interrompu par BREAK
DEFWORD "RESUME",6,,RESUME ; ( -- )
    .word DBGEN,FETCH,ZBRANCH,9f-$
    .word RPBREAK,FETCH,QDUP,ZBRANCH,9f-$
    .word RPSTORE,LIT,0,RPBREAK,STORE
9:  .word EXIT
    
    
    
; affice le code source d'un mot qui est
; dans le dictionnaire
;DEFWORD "SEE",3,F_IMMED,SEE ; ( <ccc> -- )    
;    .word BL,WORD,FIND,TBRANCH,1f-$
;    .word SPACE,LIT,'?',EMIT,DROP,BRANCH,3f-$
;1:  .word DUP,FETCH,LIT,ENTER,EQUAL,TBRANCH,2f-$
;    .word DROP,DOTSTR
;    .byte 9
;    .ascii "code word"
;    .align 2
;    .word BRANCH,3f-$
;2:  .word SEELIST
;3:  .word EXIT    

; imprime la liste des mots qui construite une d�finition
; de HAUT-NIVEAU  
;DEFWORD "SEELIST",7,F_IMMED,SEELIST ; ( cfa -- )
;    .word BASE,FETCH,TOR,HEX,NEWLINE
;    .word LIT,2,PLUS ; premi�re adresse du mot 
;1:  .word DUP,FETCH,DUP,CFATONFA,QDUP,ZBRANCH,4f-$
;    .word COUNT,LENMASK,AND
;    .word DUP,GETX,PLUS,LIT,CPL,LESS,TBRANCH,2f-$,NEWLINE 
;2:  .word TYPE
;3:  .word LIT,',',EMIT,FETCH,LIT,code_EXIT,EQUAL,TBRANCH,6f-$
;    .word LIT,2,PLUS,BRANCH,1b-$
;4:  .word UDOT,DVP,BRANCH,3b-$
;6:  .word DROP,RFROM,BASE,STORE,EXIT
  

