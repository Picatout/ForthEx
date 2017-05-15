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
; copie de la dernière interprétée en mode interactif
; permet de réafficher cette ligne avec CTRL_v 
paste: .space TIB_SIZE+2
 
 
.section .sys_vars.bss bss
.global _SYS_VARS
_SYS_VARS:    
; control stack pointer
.global csp
csp: .space 2
; NFA dernière entrée dans le dictionnaire système
 .global _SYSLATEST
_SYSLATEST: .space 2
; NFA dernière entrée dans le dictionnaire utilisateur
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
; adresse et longueur du buffer d'évaluation
_TICKSOURCE: .space 2
; identifiant de la source: 0->interactif, -1, fichier
 .global _CNTSOURCE
_CNTSOURCE: .space 2
; pointeur data 
 .global _DP
_DP: .space 2 
; base numérique utilisée pour l'affichage des entiers
 .global _BASE
_BASE: .space 2
 .global _STATE
; état interpréteur : 0 interpréteur, -1 compilation
_STATE: .space 2
; pointeur position parser
 .global _TOIN
_TOIN: .space 2 
; pointeur HOLD conversion numérique
 .global _HP
_HP: .space 2
; vecteur pour le terminal actif.
; par défaut LCONSOLE 
_SYSCONS: .space 2
; sauvegarde de RSP par BREAK
_RPBREAK: .space 2 
; flag activation/désactivaton break points
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
; mot système qui ne sont pas
; dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FORTH_CODE

; run time 
;    Mécanisme d'appel des mots de haut-niveaux 
;    CFA compilé par les mots qui crés des définitions de haut-niveau. 
 .global ENTER
ENTER:
    RPUSH IP   
    mov WP,IP
    NEXT

; run time 
;    Empile l'adresse d'une variable système.
;    Utilisé par le système interne seulement.    
 .global DOUSER
DOUSER: 
    DPUSH
    mov [WP++],W0
    add W0,VP,T
    NEXT

; run time    
;    Code dont le CFA est compilé par VARIABLE
 .global DOVAR
DOVAR:
    DPUSH
    mov WP,T
    NEXT
 
; run time    
;   code dont le CFA est compilé par CONSTANT.    
 .global DOCONST
DOCONST:
    DPUSH
    mov [WP],T
    NEXT

    
; run time
;   Mécanisme de sortie d'un mot de haut-niveau.
;   premier mot du dictionnaire il est cependant caché
;   à l'utilisateur. 
;   Le CFA de ce mot est compilé pour terminer une définition de haut-niveau.    
    .section .sysdict psv
    .align 2
    .global name_EXIT
name_EXIT :
    .word 0     ; LFA
0:  .byte 4|F_MARK|F_HIDDEN ; NFA
    .ascii "EXIT"
    .align 2
    .global EXIT
EXIT:
    .word code_EXIT	; CFA
    FORTH_CODE
    .global code_EXIT
code_EXIT :		;code
    RPOP IP
    NEXT

; nom: NOP ( -- )
;   mot vide, ne fait rien.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "NOP",3,,NOP 
    .word EXIT

; nom: CALL  ( i*x ud -- j*x )
;    Appel d'une routine écrite en code machine et résident en mémoire flash.
;    La routine doit se terminée par une instruction machine RETURN.
; arguments:
;     i*x    Arguments consommés par la routine, dépend de celle-ci.
;     ud     adresse de la routine.
; retourne:
;     j*x    Valeurs laissées sur la pile par la routine, dépend de celle-ci.   
DEFCODE "CALL",4,,CALL 
    mov T, W1
    DPOP
    mov T, W0
    DPOP
    call.l W0
    NEXT
    
; run time    
;   Empile un entier litéral. CFA compilé par LITERAL.
HEADLESS LIT  ; ( -- x )  
    DPUSH
    mov [IP++], T
    NEXT

; run time   
;   empile un caractère litéral. CFA compilé par C@
HEADLESS CLIT  ; ( -- c )
    DPUSH
    mov [IP++], T
    ze T,T
    NEXT

; run time    
;   branchement inconditionnel
HEADLESS BRANCH    ; ( -- )
    add IP, [IP], IP
    NEXT
    
; run time    
;   branchement si T<>0, consomme le sommet de la pile.    
HEADLESS TBRANCH  ; ( f -- )
;DEFCODE "(TBRANCH)",9,F_HIDDEN,TBRANCH ; ( f -- )
    cp0 T
    DPOP
    bra nz, code_BRANCH
    inc2 IP,IP
    NEXT

; run time    
;   branchement si T==0, consomme le sommet de la pile.
HEADLESS ZBRANCH ; ( f -- )
    cp0 T
    DPOP
    bra z, code_BRANCH
    inc2, IP,IP
    NEXT
    
    
; run time   ( limit index -- )     
;   code dont le CFA est compilé par DO
HEADLESS DODO  ; ( n1  n2 -- ) R( -- I LIMIT )   
doit:
    RPUSH LIMIT
    RPUSH I
    mov T, I
    DPOP
    mov T,LIMIT
    DPOP
    NEXT

; run time  ( limit index  -- )    
;   code dont le CFA est compilé par  ?DO
HEADLESS DOQDO ; ( n n -- ) R( -- | I LIMIT )    
    cp T,[DSP]
    bra z, 9f
    add #(2*CELL_SIZE),IP ; saute le branchement inconditionnel
    bra doit
9:  DPOP
    DPOP
    NEXT

; runtime    
;   code dont le CFA est compilé par DOLOOP
;   La boucle se termine quand I==LIMIT 
;   A la sortie de la boucle I et LIMIT sont restaurés à partir de R: LIMIT I
HEADLESS DOLOOP
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

; runtime     
;   code dont le CFA est compilé par +LOOP
;   La boucle s'arrête lorsque I franchi la frontière
;   entre LIMIT et LIMIT-1 dans un sens ou l'autre
;   A la sortie de la boucle I et LIMIT sont restaurés à partir de R: LIMIT I
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

; nom:  I  ( -- n )    
;   Empile compteur de boucle.
; arguments:
;   aucun
; retourne:
;   n   valeur actuelle de I    
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

; nom: L  ( -- n )    
;   Empile la limite de boucle.    
; arguments:
;   aucun
; retourne:
;   n   valeur de LIMIT.    
DEFCODE "L",1,,DOL ; ( -- n )
    DPUSH
    mov LIMIT,T
    NEXT
    
; nom: J  ( -- n )    
;   Empile le compteur de la boucle qui englobe la boucle actuelle.
; arguments:
;   aucun
; retourne:
;   n   valeur actuelle de J
DEFCODE "J",1,,DOJ  ; ( -- n ) R: limitJ indexJ
    DPUSH
    mov [RSP-2],T
    NEXT
  
; nom: UNLOOP ( R: n1 n2 -- )
;   Restaure les valeurs des variables I et LIMIT tels qu'elles étaient
;   avant l'exécution du dernier DO ou ?DO.
;   Après exécution  LIMIT=n1, I=n2
; arguments:
;   aucun
; retourne:
;   rien.    
DEFCODE "UNLOOP",6,,UNLOOP
    RPOP I
    RPOP LIMIT
    NEXT
    
; nom: IP@  ( -- n )  
;   empile la valeur de la variable IP.
; arguments:
;   aucun
; retourne:
;   n     valeur de IP    
DEFCODE "IP@",3,,IPFETCH  ; ( -- n )
    DPUSH
    mov IP,T
    NEXT
    
; nom: REBOOT ( -- )
;   Redémarre le système avec le même effet qu'une mise sous tension
;   en exécutant l'instruction machine RESET.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "REBOOT",6,,REBOOT
    reset
    
; nom: EXECUTE  ( i*x CFA -- j*x )
;   Exécute le mot dont le Code Field Address est au sommet de la pile.
; arguments:
;   i*x    Liste des arguments consommés par ce mot.
;   CFA    Pointeur qui contient l'adresse du mot à exécuter.
; retourne:
;   j*x    Liste de valeur dépendant du mot exécuté.    
DEFCODE "EXECUTE",7,,EXECUTE
exec:
    mov T, WP ; CFA
    DPOP
    mov [WP++],W0  ; code address, WP=PFA
    goto W0

; nom: @XT  ( i*x a-addr -- j*x )
;   Exécution vectorisée. 
;   Lit le contenu d'une variable qui contient le point d'entrée d'une routine
;   et exécute cette routine.
; arguments:
;    i*x  arguments attendus par la fonction qui sera exécutée.    
;    a-addr   vers le code à exécuter.
; retourne:
;    j*x  dépend de la fonction exécutée.    
DEFCODE "@EXEC",5,,FETCHEXEC
    mov [T],T
    bra exec

; nom: VECEXEC ( i*x a-addr n -- j*x )
;   Excécute la fonction n dans une table de pointeur de fonctions.
; arguments:
;    i*x   arguments requis par la fonction à exécuter.
;    a-addr  adresse de la table de vecteurs.
;    n     numéro du vecteur à exécuter.
; retourne:
;    j*x   valeurs retournées par la fonction exécutée.    
DEFCODE "VEXEC",5,,VEXEC
    mul.uu T,#CELL_SIZE,W0
    DPOP
    add W0,T,T
    mov [T],T
    bra exec
    
; nom: @   ( a-addr -- n )
;   Empile la valeur d'une variable dont l'adresse est au sommet de la pile.
; arguments:
;   a-addr  adresse de la variable.
; retourne:
;   n	valeur de la variable.    
DEFCODE "@",1,,FETCH 
    mov [T],T
    NEXT

; nom: C@  ( c-addr -- c )
;   Empile la valeur d'une variable caractère dont l'adresse est au sommet de la pile.
; arguments:
;   c-addr  adresse de la variable.
; retourne:
;   c   caractère contenu dans la variable.    
DEFCODE "C@",2,,CFETCH 
    mov.b [T],T
    ze T,T
    NEXT
    
; nom: E@  ( a-addr -- n )    
;   Empile la valeur d'une variable qui est dans la RAM EDS (Extended Data Space).
; arguments:
;   a-addr  adresse de la variable
; retourne:
;   n	valeur de la variable.    
DEFCODE "E@",2,,EFETCH ; ( addr -- n )
    SET_EDS
    mov [T],T
    RESET_EDS
    NEXT
    
; nom: EC@  ( c-addr -- c )    
;   Empile le caractère contenu dans une variable qui est dans la RAM EDS.
; arguments:
;   c-addr   adresse de la variable dans l'espace EDS.
; retourne:
;   c	caractère contenu dans la variable.    
DEFCODE "EC@",3,,ECFETCH 
    SET_EDS
    mov.b [T],T
    ze T,T
    RESET_EDS
    NEXT
    
; nom: 2@  ( a-addr -- d )    
;   Empile la valeur d'une variable de type entier double.
;   Cette variable peut-être dans la mémoire EDS.    
; arguments:
;   a-addr   adresse de la variable
; retourne:
;   d   entier double, valeur de cette variable.    
DEFCODE "2@",2,,TWOFETCH 
    SET_EDS
    mov [T],W0 
    add #CELL_SIZE,T
    mov [T],T
    mov W0,[++DSP]
    RESET_EDS
    NEXT
    
; nom: TBL@  ( n a-addr -- n )    
;   Empile l'élément n d'un vecteur. Les valeurs d'indice débute à zéro.
;   Si a-addr est >= 0x8000 il s'agit d'un vecteur en mémoire flash.    
; arguments:
;   n  indice
;   a-addr  adresse du vecteur.
; retourne:
;   n    Valeur de l'élément n du vecteur.    
DEFCODE "TBL@",4,,TBLFETCH
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W1,W0,W0
    add T,W0,W0
    mov [W0],T
    NEXT

; nom: TBL!  ( n1 n2 a-addr -- )    
;   Sauvegarde une valeur dans l'élément d'un vecteur.
;   a-addr[n2] = n1.
;   Ce vecteur peut-être situé en mémoire EDS.    
; arguments:
;   n1  valeur à affecté à l'élément
;   n2  indice de l'élément
;   a-addr  adresse de la table
; retourne:
;    
DEFCODE "TBL!",4,,TBLSTORE ; ( n1 n2 addr -- )    
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W0,W1,W0
    add T,W0,W0
    DPOP 
    mov T,[W0]
    DPOP
    NEXT
    
; nom: !  ( n a-addr -- )    
;   Sauvegarde d'un entier dans une variable.
;   La variable peut-être en mémoire EDS.    
; arguments:
;   n    valeur à sauvegarder
;   a-addr adresse de la variable.    
; retourne:
;   rien    
DEFCODE "!",1,,STORE 
    mov [DSP--],[T]
    DPOP
    NEXT

; nom: C!  ( c c-addr -- )    
;   Sauvegarde un caractère dans une variable. Cette variable peut-être
;   en mémoire EDS.
; arguments:
;   c   valeur à sauvegarder.
;   c-addr  adresse de la variable.
; retourne:
;    rien    
DEFCODE "C!",2,,CSTORE
    mov [DSP--],W0
    mov.b W0,[T]
    DPOP
    NEXT

; nom: 2!   ( d a-addr -- )    
;   Sauvegarde d'un entier double. La variable peut-être en mémoire EDS.
; arguments:
;   d   entier double
;   a-addr  adresse de la variable.
; retourne:
;   rien    
DEFCODE "2!",2,,TWOSTORE
    mov [DSP--],[++T]
    mov [DSP--],[--T]
    mov [DSP],T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; mots manipulant les arguments sur la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

; nom: DUP ( x1 -- x1 x2 )
;   Clone la valeur au sommet de la pile.
; arguments:
;    x1    valeur au sommet de  la pile    
; retourne:
;    x1    valeur originale    
;    x2    copie de la valeur originalement au sommet de la pile     
DEFCODE "DUP",3,,DUP ; ( n -- n n )
    DPUSH
    NEXT

; nom: 2DUP   ( d1 -- d1 d2 )
;   Clone l'entier double qui est au sommet de la pile.
; arguments:
;   d1      entier double.
; retourne:
;   d1      valeur originale.
;   d2      copie de d1.
DEFCODE "2DUP",4,,TWODUP 
    mov [DSP],W0
    DPUSH
    mov W0,[++DSP]
    NEXT
    
; nom: ?DUP  ( x1 -- 0 | x1 x2 )    
;    Clone la valeur au sommet de la pile si cette valeur
;    est différente de zéro.
; arguments:
;    x1   valeur au sommet de la pile.
; retourne:
;    x1   valeur originale
;    x2   Copie de x1 si x1<>0    
DEFCODE "?DUP",4,,QDUP 
    cp0 T
    bra z, 1f
    DPUSH
1:  NEXT
    
; nom: DROP ( x -- )
;   Jette la valeur au sommet de la pile.
; arguments:
;    x    valeur au sommet de la pile.
; retourne:
;    rien     La pile contient 1 élément de moins.    
DEFCODE "DROP",4,,DROP
    DPOP
    NEXT

; nom: 2DROP ( x1 x2 -- )
;   Jette les 2 valeurs au sommet de la pile.    
; arguments:
;   x1  Valeur sous le sommet.
;   x2  Valeur au sommet de la pile.
; retourne:
;   rien La pile contient 2 élémnents de moins.    
DEFCODE "2DROP",5,,TWODROP
    DPOP
    DPOP
    NEXT
    
; nom: RDROP  ( R: x -- )
;   Jette la valeur au sommet de la pile des retours.
; arguments:
;    x     valeur au sommet de la pile des retours.
; retourne:
;   rien La pile des retours contient 1 élément de moins.    
DEFCODE "RDROP",5,,RDROP ; ( R: n -- )
    sub #CELL_SIZE,RSP
    NEXT
    
; nom: SWAP  ( x1 x2 -- x2 x1 )
;   Inverse l'ordre des 2 éléments au sommet de la pile.
; arguments:
;   x1   deuxième élément de la pile.
;   x2   élément au sommet de la pile.
; retourne:
;   x2   La valeur qui était au sommet est maintenant en second.
;   x1   La valeur qui était en seconde est maintenant au sommet.    
DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
    mov [DSP],W0
    exch W0,T
    mov W0,[DSP]
    NEXT

; nom: 2SWAP  ( d1 d2 -- d2 d1 )
; notation alternative: ( n1 n2 n3 n4 -- n3 n4 n1 n2 )    
;   Inverse l'ordre de 2 entiers doubles au sommet de la pile.
; arguments:
;   d1   Second entier doublde de la pile.
;   d2   Entier double au sommet.
; retourne:
;   d2   Le sommet est maintenant en second.
;   d1   Le second est maintenant au sommet.    
DEFCODE "2SWAP",5,,TWOSWAP 
    mov [DSP-2],W0
    mov T,[DSP-2]
    mov W0, T
    mov [DSP-4],W0
    mov [DSP],W1
    mov W1, [DSP-4]
    mov W0, [DSP]
    NEXT
    
; nom: ROT ( n1 n2 n3 -- n2 n3 n1 )
;   Rotation des 3 éléments du sommet de sorte que le 3ième se retrouve au sommet.
; argments:
;   n1  Élément en 3ième position de la pile.
;   n2  Élément en 2ième position de la pile.
;   n3  Élément a sommet de la pile 
; retourne:
;   n2  Le second est maintenant en 3ième position.
;   n3  Le sommet est maintenant en 2ième position.
;   n1  Le 3ième est maintenant au sommet.    
DEFCODE "ROT",3,,ROT  ; ( n1 n2 n3 -- n2 n3 n1 )
    mov [DSP], W0 ; n1
    exch T,W0   ; W0=n3, T=n2
    mov W0, [DSP]  ; n3
    mov [DSP-2],W0 ; n1
    exch W0,T ; T=n1, W0=n2
    mov W0,[DSP-2] 
    NEXT

; nom: -ROT ( n1 n2 n3 -- n3 n1 n2 )
;   Rotation inverse des 3 éléments du sommet de la pile.
;   Le sommet est envoyé en 3ième position.
; arguments:
;   n1   3ième élément de la pile.
;   n2   2ième élément de la pile.
;   n3   1ier élément de la pile.
; retourne:
;   n3   Le sommet est maintenant en 3ième position.
;   n1   Le 3ième est maintenant en 2ième position.
;   n2   Le second élément est maintenant au somment.    
DEFCODE "-ROT",4,,NROT ; ( n1 n2 n3 -- n3 n1 n2 )
    mov T, W0    
    mov [DSP],T
    mov [DSP-2],W1
    mov W1,[DSP]
    mov W0,[DSP-2]
    NEXT
    
; nom: OVER  ( n1 n2 -- n1 n2 n1 )
;   Une copie du seconde élément de la pile est créé au sommet de celle-ci.
; arguments:
;   n1 Second élément de la pile.
;   n2 Sommet de la pile.
; retourne:
;   n1   Le second est maintenant le 3ième.
;   n2   Le sommet est maintenant le 2ième.
;   n1   Une copie du second se retrouve maintenant au somment.    
DEFCODE "OVER",4,,OVER  ; ( n1 n2 -- n1 n2 n1 )
    DPUSH
    mov [DSP-2],T
    NEXT

; nom: 2OVER  ( d1 d2 -- d1 d2 d1 )
;   Si on considère qu'il y a 2 entiers doubles au sommet de la pile, une
;   copie du second est créé au sommet. La pile s'allonge donc de 2 cellules.
; arguments:
;   d1   Entier double en seconde position.
;   d2   Entier double au somment.
; retourne:
;   d1   L'entier double qui était en second est maintenant en 3ième position.
;   d2   L'entier double qui était au sommet est maintenant en 2ième position.
;   d1   Une copie du 2ième entier double est maintenant au somment.    
DEFCODE "2OVER",5,,TWOOVER ; ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
    DPUSH
    mov [DSP-4],T
    mov [DSP-6],W0
    mov W0,[++DSP]
    NEXT
    
; nom: NIP ( x1 x2 -- x2 )
;   Jette le second élément de la pile.
; arguments:
;   x1   Valeur en second sur la pile.
;   x2   Valeur au sommet de la pile.
; retourne:
;   x2   La valeur au sommet n'a pas changée mais le 2ième élément est disparue.
;        La pile a donc diminuée d'un élément.    
DEFCODE "NIP",3,,NIP   ; ( n1 n2 -- n2 )
    dec2 DSP,DSP
    NEXT
    
; nom: >R  (  x --  R: -- x )
;   Transfert le sommet de la pile des arguments au sommet de la pile des retours.
;   Après cette opération la pile des arguments a raccourcie d'un élément et la
;   pile des retours a rallongée d'un élément.    
; arguments:
;   x   Valeur au sommet de la pile des arguments.
; retourne:
;   x   La valeur x est maintenant au sommet de la pile des retours.  
    
DEFCODE ">R",2,,TOR  
    RPUSH T
    DPOP
    NEXT
    
; nom: R>  ( -- x  R: x -- )     
;   Transfert d'un élément de la pile des retours vers la pile des arguments.
;   Après cette opération la pile des retours a raccourcie de 1 élément et la
;   pile des arguments a rallongée d'un élément.
; arguments:
;   x   Valeur au somment de R
; retourne:
;   x   valeur qui était au somment de R est maintenant ajoutée au sommet de S.    
DEFCODE "R>",2,,RFROM  
    DPUSH
    RPOP T
    NEXT

; nom: R@  ( -- x R: x -- x )
;    La valeur au sommet de la pile des retours est copiée au sommet de la pile
;    des arguments. Le contenu de la pile des retours n'est pas modifié. Le contenu
;    de la pile des arguments a 1 élément supplémentaire.
; arguments:
;    x   Valeur au somment de R
; retourne:
;    x    Valeur ajoutée à la pile des arguments, copie du sommet de R.    
DEFCODE "R@",2,,RFETCH 
    DPUSH
    mov [RSP-2], T
    NEXT

; nom: SP@  ( -- n )
;   Empile la valeur du pointeur de la pile des
;   arguments.
; arguments:
;   aucun
; retourne:
;   n   valeur de la variable SP.    
DEFCODE "SP@",3,,SPFETCH ; ( -- n )
    mov DSP,W0
    DPUSH
    mov W0, T
    NEXT
    
; nom: SP! ( n -- )
;   Initialise le pointeur de la pile des arguments avec la valeur
;   au sommet de la pile des arguments.
; arguments:
;   n  Valeur d'initialisation de SP.
; retourne:
;   rien    
DEFCODE "SP!",3,,SPSTORE  ; ( n -- )
    mov T, DSP
    NEXT
    
; nom: RP@  ( -- n )
;   Empile la valeur du pointeur de la pile des retours.
; arguments:
;   aucun
; retourne:
;   n   valeur du pointeur de la pile des retours.    
DEFCODE "RP@",3,,RPFETCH  ; ( -- n )
    DPUSH
    mov RSP, T
    NEXT
    
; nom: RP! ( n -- )
;   Initialiste le pointeur de la pile des retours avec la valeur
;   qui est au sommet de la pile des arguments.
; arguments:
;   n   valeur d'initialistaion de RP.
; retourne:
;   rien    
DEFCODE "RP!",3,,RPSTORE  ; ( n -- )
    mov T, RSP
    DPOP
    NEXT
    
; nom: TUCK  ( x1 x2 -- x2 x1 x2 )
;   Insère une copie de la valeur au sommet de la pile des arguments en 
;   Sous la valeur en 2ième position. Après cette opération la pile contient
;   1 élément de plus.
; arguments:
;   x1  Second éléméent de la pile.
;   x2  Élément au sommet de la pile.
; retourne:
;   x2  copie du sommet de la pile.
;   x1  2ieme élément de la pile demeure inchangé.
;   x2  Sommet de la pile demeure inchangé.    
DEFCODE "TUCK",4,,TUCK 
    mov [DSP],W0 ; n1
    mov T,[DSP]  ; n2 n2 
    mov W0,[++DSP] ; n2 n1 n2
    NEXT

; nom: DEPTH  ( -- n )    
;   Retourne le nombre d'éléments sur la pile des arguments. Le nombre d'éléments
;   renvoyé est exclu ce nouvel élément.
; arguments:
;   aucun
; retourne:
;   n   Nombre d'éléments qu'il y avait sur la pile avant cette opération.    
DEFCODE "DEPTH",5,,DEPTH ; ( -- +n1 )
    mov #pstack,W0
    sub DSP,W0,W0
    DPUSH
    lsr W0,T
    NEXT

; nom: PICK  ( i*x n --  i*x x )
;   insère le nième élément de la pile au sommet
;   l'argument n est retiré de la pile avant le comptage.
;   Si n==0 équivaut à DUP 
;   Si n==1 équivaut à OVER
; arguments:
;   i*x   Liste des éléments présent sur la pile.
;   n     position de l'élément recherché, 0 étant le sommet. n est retiré
;         de la pile avant le comptage.
; retourne:
;   i*x   Liste originale des éléments.
;   x     copie de l'élément en position n.    
DEFCODE "PICK",4,,PICK
    mov DSP,W0
    sl T,T
    sub W0,T,W0
    mov [W0],T
    NEXT
    
; nom: >CSTK  ( x --   C: -- x )    
;   Tranfert du sommet de la pile des arguments 
;   vers la pile de contrôle. Après cette opération la pile 
;   des arguments à perdue un élément et la pile de contrôle en a
;   gagné un.    
; arguments:
;   x   Valeur au sommet de la pile des arguments.
; retourne:
;   C: x    Le sommet de  la pile de contrôle contient x.    
DEFCODE ">CSTK",5,,TOCSTK 
    mov csp,W0
    mov T,[W0++]
    mov W0,csp
    DPOP
    NEXT

; nom: CSTK>  ( -- x C: x -- )
;   Transfert du sommet de la pile de contrôle
;   vers la pile des arguments. Après cette opération la pile de contrôle
;   contient un élément de moins et la pile des arguments un élément de plus.
; arguments:
;    C: x   Valeur au sommet de la pile de contrôle.
; retourne:
;    x    Valeur ajoutée au sommet de la pile des arguments.    
DEFCODE "CSTK>",5,,CSTKFROM 
    DPUSH
    mov csp,W0
    mov [--W0],T
    mov W0,csp
    NEXT
    
    
;;;;;;;;;;;;;;;;
;     MATH
;;;;;;;;;;;;;;;;

; nom:  MSB  ( -- u )
;   Constante retournant la valeur du bit le plus significatif d'un entier.
; arguments:
;   aucun
; retourne:
;   u   Valeur de l'entier dont seul le bit le plus significatif est à 1.    
DEFCONST "MSB",3,,MSB,0x8000

; nom: MAX-INT  ( -- n )
;   Constante retourant la valeur du plus grand entier signé.
; arguments:
;   aucun
; retourne:
;   n    Valeur du plus grand entier signé.
DEFCONST "MAX-INT",7,,MAXINT,0x7FFF ; 32767
 
; nom: MIN-INT  ( -- n )
;   Constante retournant le plus petit entier signé.
; arguments:
;   aucun
; retourne:
;   n   Plus petit entier signé.    
DEFCONST "MIN-INT",7,,MININT,0x8000 ; -32768

; nom: HEX  ( -- )
;   Initialise la variable système BASE avec la valeur 16. Après l'exécution
;   de ce mot, l'interpréteur condisère que les chaînes converties en nombre
;   sont en base 16 et les nombres à imprimés sont aussi convertis dans cette base.
; arguments:
;   Aucun
; retourne:
;   rien    
DEFWORD "HEX",3,,HEX ; ( -- )
    .word LIT,16,BASE,STORE,EXIT
    
; nom: DECIMAL ( -- )
;   Initialise la variable système BASE avec la valeur 10. Après l'exécution
;   de ce mot, l'interpréteur condisère que les chaînes converties en nombre
;   sont en base 10 et les nombres à imprimés sont aussi convertis dans cette base.
; arguments:
;   Aucun
; retourne:
;   rien    
DEFWORD "DECIMAL",7,,DECIMAL ; ( -- )
    .word LIT,10,BASE,STORE,EXIT
    
; nom: +  ( x1 x1 -- x3 )  x3=x1+x2
;   Additionne les 2 entiers au sommet de la pile des arguments.
; arguments:
;   x1  premier entier.
;   x2  deuxième entier.
; retourne:
;   x3   somme de x1 et x2  
DEFCODE "+",1,,PLUS
    add T, [DSP--], T
    NEXT
 
; nom: -  ( x1 x2 -- x3 )  x3 = x1-x2
;   Soustrait l'entier x2 de l'entier x1.
; arguments;
;   x1    premier entier.
;   x2    deuxième entier au sommet de la pile.
; retourne:
;   x3    valeur obtenu en soustrayant x2 de x1.    
DEFCODE "-",1,,MINUS 
    mov [DSP--],W0
    sub W0,T,T
    NEXT
    
; nom: 1+  ( x1 -- x2 )  x2=x1+1
;   Incrémente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 incrémenté de 1.
DEFCODE "1+",2,,ONEPLUS ; ( n -- n+1 )
    add #1, T
    NEXT

    
; nom: 2+  ( x1 -- x2 )  x2=x1+2
;   Incrémente de 2 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 incrémenté de 2.
DEFCODE "2+",2,,TWOPLUS
    add #2, T
    NEXT
    
; nom: 1-  ( x1 -- x2 )  x2=x1-1
;   décrémente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 décrémenté de 1.
DEFCODE "1-",2,,ONEMINUS
    sub #1, T
    NEXT
    
; nom: 2-  ( x1 -- x2 )  x2=x1-2
;   décrémente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 décrémenté de 2.
DEFCODE "2-",2,,TWOMINUS
    sub #2, T
    NEXT
    
; nom: 2*  ( x1 -- x2 )   x2 = 2*x1
;   Multiplie par 2 la valeur au sommet de la pile des arguments.
; arguments:
;   x1
; retourne:
;   x2    x1 multiplié par 2.    
DEFCODE "2*",2,,TWOSTAR
    add T,T, T
    NEXT
    
; nom: 2/  ( x1 -- x2 ) x2=x1/2
;   Divise par 2 la valeur au sommet de la pile des arguments.
; arguments:
;   x1
; retourne:
;   x2     x2 divisé par 2.    
DEFCODE "2/",2,,TWOSLASH
    asr T,T
    NEXT
    
; nom: LSHIFT  ( x1 u -- x2 )  x2=x1<<u
;   Décale vers la gauche de u bits le nombre x1. Ce qui équivaut à 
;   une multipliation par 2^u.    
; arguments:
;   x1   Nombre qui sera décalé vers la gauche.
;   u    Nombre de bits de décalage.
; retourne:
;   x2   x2=x1<<u    
DEFCODE "LSHIFT",6,,LSHIFT
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
    
; nom: RSHIFT ( x1 u -- x2 ) x2 = x1>>u
;   décalage vers la droite de u bits de la valeur x1.
; arguments:
;   x1   Nombre qui sera décalé.
;   u    Nombre de bits de décalage.
; retourne:
;    x2   x2=x1>>u    
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
    
; nom: +!  ( n a-addr -- )  *a-addr = *a-addr+n
;   Additionne un entier à la valeur d'une variable.
; arguments;
;    n   entier à ajouter à la valeur de la variable.
;    a-addr   adresse de la variable.
; retourne:
;    rien    
DEFCODE "+!",2,,PLUSSTORE
    mov [T], W0
    add W0, [DSP--],W0
    mov W0, [T]
    DPOP
    NEXT

; nom: D+  ( d1 d2 -- d3 )   d3=d1+d2    
;   addition de 2 entiers double.
; arguments:
;   d1  premier entier double.
;   d2  deuxième enteier double.
; retourne:
;   d3  somme de d1 et d2    
DEFCODE "D+",2,,DPLUS ; ( d1 d2 -- d3 )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    add W0,[DSP],[DSP]
    addc W1,T,T
    NEXT
 
; nom: D-  ( d1 d2 -- d3 )  d3 = d1-d2    
;   soustractions de 2 entiers doubles.
; arguments:
;   d1  premier entier double.
;   d2  deuxième entier double.
; retourne:
;   d3  Entier double résultant de la soustration d1-d2.    
DEFCODE "D-",2,,DMINUS ; ( d1 d2 -- d3 )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    mov [DSP],W2
    sub W2,W0,[DSP]
    subb T,W1,T
    NEXT
    
; nom: M+  ( d1 n -- d2 ) d2 = d1+n
;   addition d'un entier simple à un entier double.
; arguments:
;   d1  Entier double.
;   n   Entier simple.
; retourne:
;   d2  Entier double résultant de d1+n    
DEFCODE "M+",2,,MPLUS
    mov [DSP-2], W0 ; d1 faible
    add W0,T, W0 ; d2 faible
    DPOP    ; T= d1 fort
    addc #0, T
    mov W0,[DSP]
    NEXT
 
; nom: *  ( n1 n2 -- n3 )  n3=n1*n2
;   Multiplication signée de 2 entiers simple.
; arguments:
;   n1   premier entier.
;   n2   deuxième entier.
; retourne:
;   n3   Produit des 2 entiers.    
DEFCODE "*",1,,STAR ; ( n1 n2 -- n1*n2) 
    mul.ss T,[DSP--],W0
    mov W0,T
    NEXT

; nom: M*   ( n1 n2 -- d )  d=n1*n2    
;   Produit de 2 entiers simples, conserve l'entier double.
; arguments:
;   n1  Premier entier simple.
;   n2  Deuxième entier simple.
; retourne:
;   d  Entier double résultant du produit de n1*n2.    
DEFCODE "M*",2,,MSTAR ; ( n1 n2 -- d )
    mul.ss T,[DSP],W0
    mov W0,[DSP]
    mov W1,T
    NEXT

; nom: UM*  ( u1 u2 -- ud )   ud=u1*u2    
;   Muttiplication non signée de 2 entiers simple résultant en un entier double.
; arguments:
;   u1  premier entier simple non signé.
;   u2  deuxième entier simple non signé.
; retourne:
;   ud  Entier double non signé.    
DEFCODE "UM*",3,,UMSTAR ; ( u1 u2 -- ud )
    mul.uu T,[DSP],W0
    mov W1,T
    mov W0,[DSP]
    NEXT
   
; nom: UD*  ( ud1 u2 -- ud3 )  ud3=ud1*u2    
;   Multiplication non signée d'un entier double par un entier simple.
; arguments:
;   ud1  entier double non signé.    
;    u2  Entier simple non signé.
; retourne:    
;   ud3  Entier double non signé résultant du produit de ud1 u2.  
DEFCODE "UD*",3,,UDSTAR ; ( ud1 u2 -- ud3 )
    mul.uu T,[DSP],W0
    mov W0,[DSP]
    mov T,W0
    DPOP
    mul.uu W0,[DSP],W0
    add W1,T,T
    mov W0,[DSP]
    NEXT

; nom: /  ( n1 n2 -- n3 )  n3=n1/n2
;   Division entière signée sur nombres simple.
; arguments:
;   n1  numérateur 
;   n2  dénominateur
; retourne:
;   n3  quotient entier.    
DEFCODE "/",1,,DIVIDE
    mov [DSP--],W0
    repeat #17
    div.s W0,T
    mov W0,T
    NEXT

; nom: MOD  ( n1 n2 -- n3 )  n3=n1%n2    
;    Division entière de 2 entiers simple où seul le restant est conservé.
; arguments:
;    n1  numérateur
;    n2  dénominateur
; retourne:
;    n3   reste de la division.    
DEFCODE "MOD",3,,MOD 
   mov [DSP--],W0
   repeat #17
   div.s W0,T
1: mov W1,T
   NEXT
   
; nom: */  ( n1 n2 n3 -- n4 ) n4=(n1*n2)/n3   
;   Une multiplication de n1 par n2 est suivit d'une division du résultat par n3.
;   Le produit de n1 et n2 est conservé comme entier double avant la division.
; arguments:
;    n1 Premier entier simple.
;    n2 Deuxième entier simple.
;    n3 Troisième entier simple.
; retourne:
;    n4  Entier simple résultant de la division du double n1*n2 par n3.   
DEFCODE "*/",2,,STARSLASH
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.sd W0,T
    mov W0,T
    NEXT

; nom: */MOD ( n1 n2 n3 -- n4 n5 )
;   Une multiplication de n1 par n2 est suivit d'une division par n3 le quotient
;   et le reste sont conservés. Le résultat intermédiaire de la multipllication
;   est un entier double.
; arguments:
;   n1  premier entier simple.
;   n2  deuxième entier simple.
;   n3  troisième entier simple.
; retourne:
;   n4  reste de la division de (n1*n2)/n3
;   n5  quotient dela division de (n1*n2)/n3    
DEFCODE "*/MOD",5,,STARSLASHMOD
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.sd W0,T
1:  mov W1,[++DSP]
    mov W0,T
    NEXT
    
; nom: /MOD  ( n1 n2 -- n3 n4 ) 
;   Division signée de n1 par n2 , le reste et le quotient sont conservés.    
; arguments:
;   n1  numérateur
;   n2  dénominateur
; retourne:
;   n3  reste
;   n4  quotient    
DEFCODE "/MOD",4,,SLASHMOD ; ( n1 n2 -- r q )
    mov [DSP],W0
    repeat #17
    div.s W0,T
1:  mov W0,T     ; quotient
    mov W1,[DSP] ; reste
    NEXT

; nom: UM/MOD  ( ud u1 -- u2 u2 )    
;   Division d'un entier double non signé
;   par un entier simple non signé
;   résulant en un quotient et reste simple
; arguments:    
;   ud   numérateur entier double non signé.    
;   u1    dénominateur entier simple non signé.
; retourne:    
;   u2 reste
;   u3 quotient    
DEFCODE "UM/MOD",6,,UMSLASHMOD 
    mov [DSP--],W1
    mov [DSP--],W0
    repeat #17
    div.ud W0,T
    mov W0,T
    mov W1,[++DSP]
    NEXT
    
; nom: UD/MOD  ( ud1 u1 -- u2 ud2 )    
;   Division d'un entier double non signé
;   par un entier simple non signé résultant
;   en un quotient double et un reste simple
; arguments:
;   ud1   numérateur entier double non signé.
;    u1   dénominateur entier simple non signé.
; résultat:
;   u2	reste entier simple
;   ud2 quotient entier double    
DEFCODE "UD/MOD",6,,UDSLASHMOD
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
    
; nom: MAX  ( n1 n2 -- n ) n=max(n1,n2) 
;   Retourne le plus grand des 2 entier signés.
; arguments:
;   n1 premier entier
;   n2 deuxième entier
; retourne:
;   n  le plus grand des 2 entiers signés.    
DEFCODE "MAX",3,,MAX 
    mov [DSP--],W0
    cp T,W0
    bra ge, 1f
    exch T,W0
1:  NEXT    
    
    
; nom: MIN  ( n1 n2 -- n ) n=min(n1,n2) 
;   Retourne le plus petit des 2 entiers signés.
; arguments:
;   n1 premier entier
;   n2 deuxième entier
; retourne:
;   n  le plus petit des 2 entiers signés.    
DEFCODE "MIN",3,,MIN
    mov [DSP--],W0
    cp W0,T
    bra ge, 1f
    exch T,W0
1:  NEXT
    
; nom: UMAX  ( u1 u2 -- u ) u=max(u1,u2) 
;   Retourne le plus grand des 2 entiers non signés.
; arguments:
;   u1 premier entier non signé.
;   u2 deuxième entier non signé
; retourne:
;   u  le plus grand des 2 entiers non signés.    
DEFCODE "UMAX",4,,UMAX
    mov [DSP--],W0
    cp T,W0
    bra geu,1f
    exch W0,T
1:  NEXT
    
; nom: UMIN  ( u1 u2 -- u ) u=min(u1,u2) 
;   Retourne le plus petit des 2 entiers non signés.
; arguments:
;   u1 premier entier non signé.
;   u2 deuxième entier non signé
; retourne:
;   u  le plus petit des 2 entiers non signés.    
DEFCODE "UMIN",4,,UMIN
    mov [DSP--],W0
    cp W0,T
    bra geu, 1f
    exch T,W0
1:  NEXT
    
; nom: WITHIN  ( n1|u1 n2|u2 n3|u3 -- f ) 
;   Vérifie si l'entier n2|u2<=n1|u1<n3|u3.
;   La vérification doit fonctionner aussi bien avec les entiers
;   signés et non signés.    
; arguments:
;   n1|u1   Entier à vérifier,signé ou non.
;   n2|u2   Limite inférieure,signé ou non.
;   n3|u3   Limite supérieure, signé ou non. 
; retourne:
;   f    Indicateur booléen vrai si condition n2|u2<=n1|u1<n3|u3.    
DEFCODE "WITHIN",6,,WITHIN  
    mov T,W0   
    DPOP
    sub W0,T,[RSP++]
    mov [DSP],W0
    sub W0,T,[DSP]
    mov [--RSP],T
    bra code_ULESS

; nom: EVEN  ( n -- f )
;   Retourne un indicateur booléen vrai si l'entier est pair.
; arguments:
;   n   Entier à vérifier.
; retourne:
;   f   indicateur booléen, vrai si entier pair.    
DEFCODE "EVEN",4,,EVEN ; ( n -- f ) vrai si n pair
    setm W0
    btsc T,#0
    clr W0
    mov W0,T
    NEXT
    
; nom: ODD  ( n -- f )
;   Retourne un indicateur booléen vrai si l'entier est impair.
; arguments:
;   n   Entier à vérifier.
; retourne:
;   f   indicateur booléen, vrai si entier impair.    
DEFCODE "ODD",3,,ODD
    setm W0
    btss T,#0
    clr W0
    mov W0,T
    NEXT

; nom: ABS  ( n -- n|-n ) 
;   Retourne la valeur absolue d'un entier simple.
; arguments:
;   n    Entier simple signé.
; retourne:
;  n|-n  Retourne la valeur absolue de n.    
DEFCODE "ABS",3,,ABS
    btsc T,#15
    neg T,T
    NEXT

; nom: DABS ( d -- d|-d )    
;   Retourne la valeur absolue d'un entier double.
; arguments:
;    d   Entier double signé.
; retourne:
;    d|-d  Valeur absolue de d.    
DEFCODE "DABS",4,,DABS 
    btss T,#15
    bra 9f
    mov [DSP],W0
    com T,T
    com W0,W0
    add #1,W0
    addc #0,T
    mov W0,[DSP]
9:  NEXT    

; nom: S>D   ( n -- d )    
;   convertie entier simple en entier double. Après l'exécution de ce mot
;   la pile contient 1 élément de plus.    
; arguments:
;   n    entier simple signé.
; retourne:
;   d    entier double signé.    
DEFCODE "S>D",3,,STOD ; ( n -- d ) 
    DPUSH
    clr W0
    btsc T,#15
    com W0,W0
    mov W0,T
    NEXT

; nom: ?NEGATE  ( n1 n2 -- n3 )
;   Inverse n1 si n2 est négatif. Après l'exécution la pile compte
;   1 élément de moins.    
; arguments:
;   n1   entier simple signé.
;   n2   entier simple signé.
; retourne:
;   n3   n2<0?-n1:n1    
DEFCODE "?NEGATE",7,,QNEGATE
    mov T,W0
    DPOP
    btsc W0,#15
    neg T,T
    NEXT    

; nom: SM/REM    ( d1 n1 -- n2 n3 )    
;   Division symétrique entier double par simple arrondie vers zéro.
;   REF: http://lars.nocrew.org/forth2012/core/SMDivREM.html    
;   Adapté de camel Forth pour MSP430.
; arguments:
;    d1   Entier double signé, numérateur.
;    n1   Entier simple signé, dénominateur.
; retourne:    
;    n2   Reste de la division.
;    n3   Quotient de la division.    
DEFWORD "SM/REM",6,,SMSLASHREM ; ( d1 n1 -- n2 n3 )
    .word TWODUP,XOR,TOR,OVER,TOR
    .word ABS,TOR,DABS,RFROM,UMSLASHMOD
    .word SWAP,RFROM,QNEGATE,SWAP,RFROM,QNEGATE
    .word EXIT

; nom: FM/MOD  ( d1 n1 -- n2 n3 )    
;   Division double/simple arrondie au plus petit.
;   REF: http://lars.nocrew.org/forth2012/core/FMDivMOD.html
;   Adapté de camel Forth pour MSP430.    
DEFWORD "FM/MOD",6,,FMSLASHMOD ; ( d1 n1 -- n2 n3 )    
    .word DUP,TOR,TWODUP,XOR,TOR,TOR
    .word DABS,RFETCH,ABS,UMSLASHMOD
    .word SWAP,RFROM,QNEGATE,SWAP,RFROM,ZEROLT,ZBRANCH,9f-$
    .word NEGATE,OVER,ZBRANCH,9f-$
    .word RFETCH,ROT,MINUS,SWAP,ONEMINUS
9:  .word RDROP,EXIT

; nom: EVAR+  ( a-addr -- )  
;   Incrémente une variable résidante en mémoire EDS.
; arguments:
;   a-addr   adresse de la variable.
; retourne:
;   rien     La pile décrois d'un élément.  
DEFWORD "EVAR+",5,,EVARPLUS 
    .word DUP,EFETCH,ONEPLUS,SWAP,STORE,EXIT
    
; nom: EVAR- ( a-addr -- )    
;   Décrémente une variable résidante en mémoire EDS.
; arguments:    
;    a-addr   adresse de la variable.
; retourne:
;    rien    La pile décrois d'un élément.    
DEFWORD "EVAR-",5,,EVARMINUS ; ( addr -- )
    .word DUP,EFETCH,ONEMINUS,SWAP,STORE,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; opérations logiques bit à bit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; nom: AND  ( n1 n2 -- n3 )
;   Opération Booléenne bit à bit ET.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:
;   n3  Résultat de l'opération.    
DEFCODE "AND",3,,AND 
    and T,[DSP--],T
    NEXT
    
; nom: OR  ( n1 n2 -- n3 )
;   Opération Booléenne bit à bit OU inclusif.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:
;   n3  Résultat de l'opération.    
DEFCODE "OR",2,,OR
    ior T,[DSP--],T
    NEXT
    
; nom: XOR  ( n1 n2 -- n3 )
;   Opération Booléenne bit à bit OU exclusif.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:
;   n3  Résultat de l'opération.    
DEFCODE "XOR",3,,XOR
    xor T,[DSP--],T
    NEXT
    
; nom: NOT  ( n1 -- n2 )
;   Opération Booléenne de négation. VRAI devient FAUX et vice-versa.
; arguments:
;   n1  opérande.
; retourne:
;   n2  Résultat de l'opération.    
DEFCODE "NOT",3,,NOT ; ( f -- f)
    cp0 T
    bra nz, 1f
    setm T
    bra 9f
1:  clr T
9:  NEXT
    
; nom: INVERT  ( n1 -- n2 )
;   Inversion des bits, complément de 1.
; arguments:
;   n1   opérande.
; retourne:
;   n2   inverse bit à bit de n1.    
DEFCODE "INVERT",6,,INVERT ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
; nom: DINVERT   ( d1 -- d2 ))
;   Invesion bit à bit d'un entier double. Complément de 1.
; arguments:
;   d1   opérande.
; retourne:
;   d2   Inverse bit à bit de d1.    
DEFCODE "DINVERT",7,,DINVERT
    com T,T
    com [DSP],[DSP]
    NEXT
    
; nom: NEGATE  ( n1 -- n2 )
;   Inverse arithmétique de n1. Complément de 2.
; arguments:
;   n1   Entier à inversé.
; retourne:
;   n2   n2=-n1    
DEFCODE "NEGATE",6,,NEGATE ; ( n - n ) complément à 2
    neg T, T
    NEXT
    
; nom: DNEGATE ( d1 -- d2 )
;   Inverse arithmétique d'un entier double. Complément de 2.
; arguments:
;    d1   Entier double à inversé.
; retourne:
;    d2   d2=-d1    
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
    
; nom: 0=  ( n -- f )
;   Vérifie si n est égal à zéro. Retourne un indicateur Booléen.
; arguments:
;    n   Entier à vérifier. Est remplacé par l'indicateur Booléen.
; retourne:
;    f   Indicateur Booléen VRAI|FAUX    
DEFCODE "0=",2,,ZEROEQ  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT

; nom: 0<>  ( n -- f )    
;   Vérifie si n est différent de zéro. Retourne un indicateur Booléen.
; arguments:
;    n  Entier à vérifier. Est remplacé par l'indicateur Booléen. 
; retourne:
;    f  Indicateur Booléen VRAI|FAUX    
DEFCODE "0<>",3,,ZERODIFF ; ( n -- f ) 
    clr W0
    cp0 T
    bra z, 9f
    com W0,W0
9:  mov W0,T
    NEXT
    
    
; nom: 0<  ( n -- f )    
;   Vérifie si n est plus petit que zéro. Retourne un indicateur Booléen.
; arguments:
;    n  Entier à vérifier. Est remplacé par l'indicateur Booléen. 
; retourne:
;    f  Indicateur Booléen VRAI|FAUX    
DEFCODE "0<",2,,ZEROLT ; ( n -- f ) f= n<0
    add T,T,T
    subb T,T,T
    com T,T
    NEXT

; nom: 0>  ( n -- f )    
;   Vérifie si n est plus grand que zéro. Retourne un indicateur Booléen.
; arguments:
;    n  Entier à vérifier. Est remplacé par l'indicateur Booléen. 
; retourne:
;    f  Indicateur Booléen VRAI|FAUX    
DEFCODE "0>",2,,ZEROGT ; ( n -- f ) f= n>0
    clr W0
    cp0 T
    bra le, 8f
    setm W0
8:  mov W0,T    
    NEXT

; nom: =  ( n1 n2 -- f )
;   Vérifie l'égalité des 2 entiers. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacé par l'indicateur.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen VRAI|FAUX, vrai si égaux.    
DEFCODE "=",1,,EQUAL  ; ( n1 n2 -- f ) f= n1==n2
    clr W0
    cp T, [DSP--]
    bra nz, 1f
    setm W0
 1: 
    mov W0,T
    NEXT

; nom: <>  ( n1 n2 -- f )
;   Vérifie si les 2 entiers sont différents. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacé par l'indicateur.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen VRAI|FAUX, vrai si différent.    
DEFCODE "<>",2,,NOTEQ ; ( n1 n2 -- f ) f = n1<>n2
    clr W0
    cp T, [DSP--]
    bra z, 1f
    com W0,W0
1:  
    mov W0, T
    NEXT
    
; nom: <  ( n1 n2 -- f )
;   Vérifie si n1 < n2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacé par l'indicateur.
;   Il s'agit d'une comparaison sur nombre signés.    
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen VRAI|FAUX, vrai si n1 < n2.    
 DEFCODE "<",1,,LESS  ; ( n1 n2 -- f) f= n1<n2
    setm W0
    cp T,[DSP--]
    bra gt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: > ( n1 n2 -- f )
;   Vérifie si n1 > n2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacé par l'indicateur.
;   Il s'agit d'une comparaison sur nombre signés.    
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen VRAI|FAUX, vrai si n1 > n2.    
DEFCODE ">",1,,GREATER  ; ( n1 n2 -- f ) f= n1>n2
    setm W0
    cp T,[DSP--]
    bra lt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: U<  ( u1 u2 -- f )
;   Vérifie si u1 < u2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacé par l'indicateur.
;   Il s'agit d'une comparaison sur nombre non signés.    
; arguments:
;   u1  Première opérande.
;   u2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen VRAI|FAUX, vrai si u1 < u2.    
DEFCODE "U<",2,,ULESS  ; (u1 u2 -- f) f= u1<u2
    clr W0
    cp T,[DSP--]
    bra leu, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: U>  ( u1 u2 -- f )
;   Vérifie si u1 > u2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacé par l'indicateur.
;   Il s'agit d'une comparaison sur nombre non signés.    
; arguments:
;   u1  Première opérande.
;   u2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen VRAI|FAUX, vrai si u1 > u2.    
DEFCODE "U>",2,,UGREATER ; ( u1 u2 -- f) f=u1>u2
    clr W0
    cp T,[DSP--]
    bra geu, 1f
    com W0,W0
1:
    mov W0,T
    NEXT

; nom: CELL   ( -- u )    
;   Empile la taille en octets d'une cellule. Une cellule est le nom donné à un
;   élément de la pile.    
DEFCODE "CELL",4,,CELL ; ( -- CELL_SIZE )
    DPUSH
    mov #CELL_SIZE, T
    NEXT

; nom: CELL+  ( a-addr -- a-addr' )    
;   Incrémente l'adresse au sommet de la pile de la taille d'une cellule.
; arguments:
;   a-addr   Adresse 
; retourne:
;   a-addr'  adresse incrémentée.    
DEFCODE "CELL+",5,,CELLPLUS ; ( addr -- addr+CELL_SIZE )
    add #CELL_SIZE, T
    NEXT

; nom: CELLS  ( n1 -- n2 )    
;    Convertie l'entier n1 en la taille occupée par n1 cellules.
; arguments:
;    n1   Nombre de cellules.
; retourne:
;    n2   Espace occupé par n1 cellules.   
DEFCODE "CELLS",5,,CELLS ; ( n -- n*CELL_SIZE )
    mul.uu T,#CELL_SIZE,W0
    mov W0,T
    NEXT

; nom: ALIGN  ( -- )    
;   Si la variable système DP  (Data Pointer) pointe sur une adresse impaire, 
;   aligne DP sur l'adresse paire supérieure.
;   Met 0 dans l'octet sauté.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "ALIGN",5,,ALIGN ; ( -- )
    .word HERE,ODD,ZBRANCH,9f-$
    .word LIT,0,HERE,CSTORE,LIT,1,ALLOT
9:  .word EXIT    
 
; nom: ALIGNED  ( addr -- a-addr )  
;   Si l'adrsse au sommet de la pile est impaire, aligne cette adresse sur la valeur paire supérieure.
; arguments:
;   addr  adresse à vérifier.
; retourne:
;   a-addr adresse alignée.  
DEFCODE "ALIGNED",7,,ALIGNED ; ( addr -- a-addr )
    btsc T,#0
    inc T,T
    NEXT

; nom: >CHAR  ( n -- c )    
;   Vérifie que n est dans l'intervalle ASCII 32..126, sinon remplace c par '_'  
; arguments:
;   n   Entier à convertir en caractère.
; retourne:
;   c    Valeur ASCII entre 32 et 126    
DEFCODE ">CHAR",5,,TOCHAR 
    mov #126,W0
    cp W0,T
    bra gtu,1f
    cp T,#32
    bra geu, 2f
1:  mov #'_',T
2:  NEXT
 
; nom: HERE   ( -- addr )    
;   Empile la valeur de la variable système DP (Data Pointer).
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "HERE",4,,HERE
    .word DP,FETCH,EXIT

; nom: MOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc mémoire RAM en évitant la propagation.
; arguments:
;   c-addr1  source
;   c-addr2  destination
;   u      compte en octets.   
; retourne:
;   rien    
DEFCODE "MOVE",4,,MOVE  ; ( addr1 addr2 u -- )
    mov [DSP-2],W0 ; source
    cp W0,[DSP]    
    bra ltu, move_dn ; source < dest
    bra move_up      ; source > dest
  
; nom: CMOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc d'octets RAM.  
;   Débute la opie à l'adresse la plus basse.
; arguments:
;   c-addr1  source
;   c-addr2  destination
;   u      compte en octets.   
; retourne:
;   rien    
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

; nom: CMOVE>  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc d'octets RAM  
;   La copie débute à l'adresse la plus haute.    
; arguments:
;   c-addr1  source
;   c-addr2  destination
;   u      compte en octets.   
; retourne:
;   rien    
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
;  manipulation de caractères
;  et chaînes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

; retourne l'espace occupée
; par n caractères en unité adresse
DEFWORD "CHARS",5,,CHARS ; ( n1 -- n2 )
9:  .word EXIT
   
; incrémente l'adresse d'un caractère
DEFWORD "CHAR+",5,,CHARPLUS ; ( addr -- addr' )  
    .word ONEPLUS,EXIT
    
; recherche le prochain mot séparé
; par un espace dans le flux d'entré.    
; et empile le premier caractère de ce mot
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
    
; nom: FILL ( c-addr u c -- )    
;   Initialise un bloc mémoire RAM de dimension u avec
;   le caractère c.
; arguments:
;   c-addr   adresse début zone.
;   u        nombre de caractères à remplir
;   c        caractère de remplissage    
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
    
; remplace tous les caractères <=32 à la fin d'une chaîne
; par des zéro
; u1 longueur initiale de la chaîne
; u2 longueur finale de la chaîne    
DEFCODE "-TRAILING",9,,MINUSTRAILING ; ( addr u1 -- addr u2 )
    SET_EDS
    cp0 T
    mov [DSP],W1
    add W1,T,W1
    mov #33,W0
1:  cp0 T
    bra z,9f
    dec T,T
    dec W1,W1
    cp.b W0,[W1]
    bra gtu, 1b
2:  inc T,T
9:  RESET_EDS
    NEXT
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  variables système
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFUSER "STATE",5,,STATE   ; état compile=1/interprète=0
DEFUSER "DP",2,,DP         ; pointeur fin dictionnaire
DEFUSER "BASE",4,,BASE     ; base numérique
DEFUSER "SYSLATEST",9,,SYSLATEST ; tête du dictionnaire en FLASH    
DEFUSER "LATEST",6,,LATEST ; pointer dernier mot dictionnaire
DEFUSER "PAD",3,,PAD       ; tampon de travail
DEFUSER "TIB",3,,TIB       ; tampon de saisie clavier
DEFUSER "PASTE",5,,PASTE   ; copie de TIB     
DEFUSER ">IN",3,,TOIN     ; pointeur position début dernier mot retourné par WORD
DEFUSER "HP",2,,HP       ; HOLD pointer
DEFUSER "'SOURCE",7,,TICKSOURCE ; tampon source pour l'évaluation
DEFUSER "#SOURCE",7,,CNTSOURCE ; grandeur du tampon
DEFUSER "RPBREAK",7,,RPBREAK ; valeur de RSP après l'appel de BREAK 
DEFUSER "DBGEN",5,,DBGEN ; activation désactivation break points
DEFUSER "SYSCONS",7,,SYSCONS ; entrée standard
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes système
;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCONST "VERSION",7,,VERSION,psvoffset(_version)        ; adresse chaîne version
DEFCONST "R0",2,,R0,rstack   ; base pile retour
DEFCONST "S0",2,,S0,pstack   ; base pile arguments   
DEFCONST "RAMEND",6,,RAMEND,RAM_END          ;  fin mémoire RAM
DEFCONST "IMMED",5,,IMMED,F_IMMED       ; drapeau mot immédiat
DEFCONST "HIDDEN",6,,HIDDEN,F_HIDDEN    ; drapeau mot caché
DEFCONST "NMARK",5,,NMARK,F_MARK     ; drapeau marqueur utilisé par CFA>NFA
DEFCONST "LENMASK",7,,LENMASK,LEN_MASK ; masque longueur nom   
DEFCONST "BL",2,,BL,32                       ; caractère espace
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD
DEFCONST "ULIMIT",6,,ULIMIT,EDS_BASE        ; limite espace dictionnaire
DEFCONST "DOCOL",5,,DOCOL,psvoffset(ENTER)  ; pointeur vers ENTER
DEFCONST "TRUE",4,,TRUE,-1 ; valeur booléenne vrai
DEFCONST "FALSE",5,,FALSE,0 ; valeur booléenne faux
DEFCONST "DP0",3,,DP0,DATA_BASE ; début espace utilisateur
    
; addresse buffer pour l'évaluateur    
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
;   conversion d'une chaîne
;   en nombre
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: "DECIMAL?"  ( c -- f )
;   vérifie si c est dans l'ensemble ASCII {'0'..'9'}
; arguments:
;   c   caractère ASCII à vérifier.
; retourne:
;   f   indicateur booléen.
DEFWORD "DECIMAL?",8,,DECIMALQ
    .word DUP,LIT,'0',LESS,ZBRANCH,2f-$
    .word DROP,FALSE,EXIT
2:  .word LIT,'9',GREATER,INVERT,EXIT
  
    
; nom: >BASE10  ( u1 c -- u2 )
;   étape de conversion d'une chaîne de caractère en 
;   entier décimal.
; arguments:
;   u1  entier résultant de la conversion d'une chaîne en décimal
;   c  caractère ASCII  dans l'intervalle {'0'..'9'}
; retourne:
;   u2    
DEFWORD ">BASE10",7,,TOBASE10
    .word LIT,'0',MINUS,LIT,10,ROT,STAR
    .word PLUS,EXIT
    
;vérifie si le caractère est un digit
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
  
;vérifie si le caractère qui a mis fin à >NUMBER
; est {'.'|','}. Si c'est le cas il s'agit d'un
; nombre double précision. saute le caractère
; et retourne -1. Dans le cas contraire retourne 0  
DEFWORD "?DOUBLE",7,,QDOUBLE ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,LIT,'.',EQUAL,ZBRANCH,2f-$
1:  .word LIT,1,SLASHSTRING,LIT,-1,BRANCH,9f-$
2:  .word OVER,CFETCH,LIT,',',EQUAL,ZBRANCH,8f-$
    .word BRANCH,1b-$
8:  .word LIT,0
9:  .word EXIT  
  
;converti la chaîne en nombre
;en utilisant la valeur de BASE
;la conversion s'arrête au premier
;caractère non numérique
; 'ud1' est initialisé à zéro  
; <c-addr1 u1> spécifie le début et le nombre
; de caractères de la chaîne    
DEFWORD ">NUMBER",7,,TONUMBER ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
1:   .word LIT,0,TOR ; indique si le dernier caractère était un digit
2:   .word DUP,ZBRANCH,7f-$
     .word OVER,CFETCH,QDIGIT  ; ud1 c-addr u1 n|x f
     .word TBRANCH,4f-$
     .word RFROM,ZBRANCH,8f-$
     .word DROP,QDOUBLE,ZBRANCH,9f-$
     .word RFROM,RFROM,LIT,2,OR,TOR,TOR ; on change le flag du signe pour ajouter le flag double
     .word BRANCH,1b-$
4:   .word RDROP,LIT,-1,TOR ; dernier caractère était un digit
     .word TOR,TWOSWAP,BASE,FETCH,UDSTAR
     .word RFROM,MPLUS,TWOSWAP
     .word LIT,1,SLASHSTRING,BRANCH,2b-$
7:   .word RFROM
8:   .word DROP
9:   .word EXIT
   
;vérifie s'il y a un signe '-'
; à la première postion de la chaîne spécifiée par <c-addr u>
; retourne f=1 si '-' sinon f=0    
; s'il y a un signe avance au delà du signe
DEFWORD "?SIGN",5,,QSIGN ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,CLIT,'-',EQUAL,TBRANCH,8f-$
    .word LIT,0,BRANCH,9f-$
8:  .word LIT,1,SLASHSTRING,LIT,1
9:  .word EXIT
    
;vérifie s'il y a un modificateur de base
; modifie la base en conséquence 
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

; conversion d'une chaîne en nombre
; c-addr indique le début de la chaîne
; utilise la base active sauf si la chaîne débute par '$'|'#'|'%'
; pour entrer un nombre double précision
; il faut mettre un point à une position quelconque
; sauf à la première position
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
    .word LIT,0,CR,LATEST
1:  .word FETCH,QDUP,ZBRANCH,8f-$
    .word DUP,CFETCH,LENMASK,AND  ; n NFA LEN
    .word GETCUR,DROP
5:  .word PLUS,LIT,64,ULESS,TBRANCH,3f-$ ; n NFA
    .word CR
3:  .word TOR,ONEPLUS,RFETCH,COUNT,TYPE,SPACE
    .word RFROM,TWOMINUS,BRANCH,1b-$
8:  .word CR,DOT,EXIT
    
; convertie la chaîne comptée en majuscules
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

; nom: SCAN ( c-addr u c -- c-addr' u' )  
;   Recherche du caractère 'c' dans le bloc
;   mémoire débutant à l'adresse 'c-addr' et de dimension 'u' octets
;   retourne la position de 'c' et
;   le nombre de caractères restant dans le bloc
; arguments:
;   c-addr  adresse début zone RAM
;   u       longueur de la zone en octets.    
;   c       caractère recherché.
; retourne:
;   c-addr'  adresse du premier 'c' trouvé dans cette zone
;   u'       longueur de la zone restante à partir de c-addr'    
DEFCODE "SCAN",4,,SCAN 
    SET_EDS
    mov T, W0   ; c
    DPOP        ; T=u
    mov [DSP],W1 ; W1=c-addr
    cp0 T 
    bra z, 4f ; aucun caractère restant dans le buffer.
1:  bra ltu, 4f
    cp.b W0,[W1]
    bra z, 4f
    inc W1,W1
    dec T,T
    bra nz, 1b
4:  mov W1,[DSP]
    RESET_EDS
    NEXT

; nom: SKIP ( c-addr u c -- c-addr' u' )  
;   avance au delà de 'c'. Retourne l'adresse du premier caractère
;   différent de 'c' et la longueur restante de la zone.    
; arguments:
;   c-addr    adresse début de la zone
;   u         longueur de la zone
;   c         caractère à sauter.
; retourne:
;   c-addr'   adresse premier caractère <> 'c'
;   u'        longueur de la zone restante à partir c-addr'    
DEFCODE "SKIP",4,,SKIP 
    SET_EDS
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
    RESET_EDS
    NEXT
  
; nom: ADR>IN  ( c-addr -- ) 
;   Ajuste la variable  >IN à partir de la position laissée
;   par le dernier PARSE
; arguments:
;   c-addr  adresse du pointeur après le dernier PARSE
; retourne:
;    
DEFWORD "ADR>IN",6,,ADRTOIN
    .word TSOURCE,ROT,ROT,MINUS,MIN,LIT,0,MAX
    .word TOIN,STORE,EXIT

; nom: /STRING  ( c-addr u n -- c-addr' u' )   
;   Avance c-addr de n caractères et réduit u d'autant.
; arguments:
;   c-addr   adresse initiale
;   u        longueur de la zone
;   n        nombre de caractères à avancer.
; retourne:
;   c-addr'    c-addr+n
;   u'         u-n    
DEFWORD "/STRING",7,,SLASHSTRING 
    .word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

; nom: PARSE   ( c -- c-addr u )    
;   Accumule les caractères jusqu'au
;   prochain 'c'. Met à jour la variable >IN
;   PARSE filtre les caractères suivants:
; arguments: 
;   c    caractère délimiteur
; retourne:
;   c-addr   adresse du premier caractère de la chaîne
;   u        longueur de la chaîne.
DEFWORD "PARSE",5,,PARSE ; c -- c-addr u
    .word TSOURCE,TOIN,FETCH,SLASHSTRING ; c src' u'
    .word OVER,TOR,ROT,SCAN  ; src' u'
    .word OVER,SWAP,ZBRANCH, 1f-$ 
    .word ONEPLUS  ; char+
1:  .word ADRTOIN ; adr'
    .word RFROM,TUCK,MINUS,EXIT     
    
; nom: >COUNTED ( src n dest -- )   
;   copie une chaîne dont l'adresse et la longueur sont fournies
;   en arguments vers une chaîne comptée dont l'adresse est fournie.
; arguments:    
;   src addresse chaîne à copiée
;   n longueur de la chaîne
;   dest adresse destination
; retourne:
;    
DEFWORD ">COUNTED",8,,TOCOUNTED 
    .word TWODUP,CSTORE,ONEPLUS,SWAP,MOVE,EXIT

; nom: PARSE-NAME    ( ccccc -- c-addr u ) 
;   Recherche le prochain mot dans le flux d'entrée
;   Tout caractère < 32 est considéré comme un espace
; arguments:
;   cccc    chaîne de caractères dans le flux d'entrée.
; retourne:
;   c-addr  addresse premier caractère.
;   u    longueur de la chaîne.
DEFCODE "PARSE-NAME",10,,PARSENAME
    mov _TICKSOURCE,W1
    mov _CNTSOURCE,W2
    mov _TOIN,W0
    add W0,W1,W1  ;pointeur
    DPUSH
    mov W1,T
    sub W2,W0,W2  ;longueur buffer
    cp0 W2
    bra nz, 1f 
    DPUSH
    clr T
    NEXT
1: ;saute les espaces
    mov #32,W0
1:  cp.b W0,[W1]    
    bra ltu, 4f
    inc W1,W1
    dec W2,W2
    bra z,6f
    bra 1b
4:  ; début du mot
    mov W1,T 
5:  inc W1,W1
    dec W2,W2
    bra z, 8f ; fin du buffer
    cp.b W0,[W1]
    bra ltu,5b
    bra 8f
6:  ; fin du buffer avant premier caractère.
    mov W1,T
    DPUSH
    clr T
7:  mov _TICKSOURCE,W0
    sub W1,W0,W0
    mov WREG,_TOIN
    NEXT
8:  ; fin du mot
    DPUSH
    sub W1,[DSP],T
    cp0 W2
    mov T,W2
    bra z, 9f
    inc W2,W2
9:  add W2,[DSP],W1
    bra 7b
    
; nom: WORD  ( c -- c-addr )  
;   localise le prochain mot délimité par 'c'
;   la variable TOIN indique la position courante
;   le mot trouvé est copié à la position DP
; arguments:
;   c   caractère délimiteur
; retourne:    
;   c-addr    adresse chaîne comptée.    
DEFWORD "WORD",4,,WORD 
    .word DUP,TSOURCE,TOIN,FETCH,SLASHSTRING ; c c c-addr' u'
    .word ROT,SKIP ; c c-addr' u'
    .word DROP,ADRTOIN,PARSE
    .word HERE,TOCOUNTED,HERE
    .word EXIT
  
; nom: FIND  ( c-addr -- c-addr 0 | cfa 1 | cfa -1 )   
;   Recherche un mot dans le dictionnaire
;   ne retourne pas les mots cachés (attribut: F_HIDDEN).
; arguments:
;   c-addr  adresse de la chaîne comptée à rechercher.
; retourne: 
;    c-addr 0 si adresse non trouvée
;    xt 1 trouvé mot immédiat
;    xt -1 trouvé mot non-immédiat
.equ  LFA, W1 ; link field address
.equ  NFA, W2 ; name field addrress
.equ  TARGET,W3 ;pointer chaîne recherchée
.equ  LEN, W4  ; longueur de la chaîne recherchée
.equ CNTR, W5
.equ NAME, W6 ; nom dans dictionnaire 
.equ FLAGS,W7    
DEFCODE "FIND",4,,FIND 
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

  
; nom: ACCEPT ( c-addr +n1 -- +n2 ) 
;   Lecture d'une ligne de texte à partir de la console.
;   La chaîne terminée par touche la touche 'ENTER'.
;   Les touches de contrôles suivantes sont reconnues:
;   - VK_CR   termine la saisie
;   - CTRL_X  efface la ligne et place le curseur à gauche
;   - VK_BACK recule le curseur d'une position et efface le caractère.
;   - CTRL_L  efface l'écran au complet et plac le curseur dans le coin
;             supérieur gauche.
;   - CTRL_V  Réaffiche la dernière ligne saisie
;   - Les autres touches de contrôles sont ignorées. 
; arguments:
;   c-addr   addresse du buffer
;   +n1      longueur du buffer
; retourne:
;   +n2      longueur de la chaîne lue    
DEFWORD "ACCEPT",6,,ACCEPT  ; ( c-addr +n1 -- +n2 )
    .word OVER,PLUS,TOR,DUP  ;  ( c-addr c-addr  R: bound )
1:  .word KEY,DUP,LIT,31,UGREATER,ZBRANCH,2f-$
    .word OVER,RFETCH,EQUAL,TBRANCH,3f-$
    .word DUP,EMIT,OVER,CSTORE,ONEPLUS,BRANCH,1b-$
3:  .word DROP,BRANCH,1b-$
2:  .word DUP,LIT,VK_CR,EQUAL,ZBRANCH,2f-$
    .word DROP,SWAP,MINUS,RDROP,EXIT
2:  .word DUP,LIT,VK_BACK,EQUAL,ZBRANCH,2f-$
    .word DROP,TWODUP,EQUAL,TBRANCH,1b-$
    .word DELBACK,ONEMINUS,BRANCH,1b-$
2:  .word DUP,LIT,CTRL_X,EQUAL,ZBRANCH,2f-$
    .word DROP,DELLINE,DROP,DUP,BRANCH,1b-$
2:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,2f-$
    .word EMIT,DROP,DUP,BRANCH,1b-$
2:  .word DUP,LIT,CTRL_V,EQUAL,ZBRANCH,2f-$
    .word DROP,DELLINE,PASTE,FETCH,COUNT,TYPE
    .word DROP,DUP,GETCLIP,PLUS,BRANCH,1b-$
2:  .word DROP,BRANCH,1b-$  
   
; retourne la spécification
; de la chaîne comptée dont
; l'adresse est c-addr1  
DEFWORD "COUNT",5,,COUNT ; ( c-addr1 -- c-addr2 u )
   .word DUP,CFETCH,TOR,ONEPLUS,RFROM,LENMASK,AND,EXIT
   
; imprime 'mot?'
; signifiant que le mot n'a pas
; été trouvé dans le dictionnaire.
; réinitialise DSP et appel QUIT   
DEFWORD "ERROR",5,,ERROR ;  ( c-addr -- )  
   .word SPACE,COUNT,TYPE
   .word SPACE,CLIT,'?',EMIT
   .word LIT,0,STATE,STORE
   .word S0,FETCH,SPSTORE
   .word CR,QUIT

; interprète la chaîne indiquée par c-addr u   
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
5:      .word COUNT,TYPE,LIT,'?',EMIT,CR,ABORT
9:      .word DROP,EXIT

; interprète la chaîne à l'adrese 'c-addr' et de longueur 'u'
; sauvegarde la valeur de source SUR R: à l'entrée
; et restaure avant de quitter.      
DEFWORD "EVALUATE",8,,EVAL ; ( i*x c-addr u -- j*x )
    .word TSOURCE,TOR,TOR ; sauvegarde source
    .word TOIN,FETCH,TOR,INTERPRET
    .word RFROM,TOIN,STORE,RFROM,RFROM,SRCSTORE 
    .word EXIT
    
; imprime le prompt et passe à la ligne suivante    
;DEFWORD "OK",2,,OK 
HEADLESS OK,HWORD  ; ( -- )
    .word GETX,LIT,3,PLUS,LIT,CPL,LESS,TBRANCH,1f-$,CR    
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
    .word COUNT,TYPE,CR,ABORT
9:  .word DROP,EXIT
  
; compile le runtime de ?ABORT
; a utilisé à l'intérieur d'une définition  
DEFWORD "ABORT\"",6,F_IMMED,ABORTQUOTE ; (  --  )
    .word CFA_COMMA,QABORT,STRCOMPILE,EXIT
    
; copie le TIB dans PASTE
;  le premier caractère dans PASTE est le compte    
;  arguments:
;	n+ nombre de caractères    
DEFWORD "CLIP",4,,CLIP ; ( n+ -- )
    .word DUP,PASTE,FETCH,STORE
    .word TIB,FETCH,SWAP,PASTE,FETCH,ONEPLUS,SWAP,MOVE,EXIT

; copie PASTE dans TIB
; retourne le compte.    
DEFWORD "GETCLIP",7,,GETCLIP ; ( -- n+ )
    .word PASTE,FETCH,COUNT,SWAP,OVER 
    .word TIB,FETCH,SWAP,MOVE  
    .word EXIT
    
; boucle lecture/exécution/impression
HEADLESS REPL,HWORD    
;DEFWORD "REPL",4,F_HIDDEN,REPL ; ( -- )
1:  .word TIB,FETCH,DUP,LIT,CPL-1,ACCEPT,DUP,CLIP ; ( addr u )
    .word SPACE,INTERPRET
    .word STATE,FETCH,TBRANCH,2f-$
    .word OK
2:  .word CR
    .word BRANCH, 1b-$
    
; boucle de l'interpréteur    
DEFWORD "QUIT",4,,QUIT ; ( -- )
    .word LIT,0,STATE,STORE
    .word R0,RPSTORE
    .word REPL
    
; commentaire limité par ')'
DEFWORD "(",1,F_IMMED,LPAREN ; parse ccccc)
    .word LIT,')',PARSE,TWODROP,EXIT

; commentaire jusqu'à la fin de la ligne
DEFWORD "\\",1,F_IMMED,COMMENT ; ( -- )
    .word BLK,FETCH,ZBRANCH,2f-$
    .word CLIT,VK_CR,PARSE,TWODROP,EXIT
2:  .word TSOURCE,PLUS,ADRTOIN,EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   compilateur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; les 3 mots suivants servent à 
; passer d'un champ à l'autre dans
; l'entête du dictionnaire
    
; passage du champ NFA au champ LFA
; simple puisqu'il est juste avant ce dernier    
DEFWORD "NFA>LFA",7,,NFATOLFA ; ( nfa -- lfa )
    .word LIT,2,MINUS,EXIT
    
; passe du champ NFA au champ CFA
; le CFA est après le nom aligné sur adresse paire.    
DEFWORD "NFA>CFA",7,,NFATOCFA ; ( nfa -- cfa )
    .word DUP,CFETCH,LENMASK,AND,PLUS,ONEPLUS,ALIGNED,EXIT
 
; passe du champ CFA au champ PFA
DEFWORD ">BODY",5,,TOBODY ; ( cfa -- pfa )
    .word DUP,FETCH,LIT,FETCH_EXEC,EQUAL,ZBRANCH,1f-$
    .word CELLPLUS
1:  .word CELLPLUS,EXIT;

    
;passe du champ CFA au champ NFA
;  Il n'y a pas de lien arrière entre le CFA et le NFA
;  Le bit F_MARK est utilisé pour marquer l'octet à la position NFA
;  le CFA étant immédiatement après le nom, il suffit de 
;  reculer octet par octet jusqu'à atteindre un octet avec le bit F_MARK==1
;  puisque les caractères du nom sont tous < 128    
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
7:  .word RDROP  ; compteur limite à zéro
8:  .word SWAP,DROP  ;non
9:  .word EXIT
  
; vérifie si le dictionnaire utilisateur
; est vide  
DEFWORD "?EMPTY",6,,QEMPTY ; ( -- f)
    .word DP0,HERE,EQUAL,EXIT 
    
; met à 1 l'indicateur F_IMMED
; sur le dernier mot défini.    
DEFWORD "IMMEDIATE",9,,IMMEDIATE ; ( -- )
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,IMMED,OR,SWAP,CSTORE
9:  .word EXIT
    
;cache la définition en cours  
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
    
; allocation/rendition de mémoire dans le dictionnaire
; si n est négatif n octets seront rendus.
;  arguements:
;     n   nombre d'octets
DEFWORD "ALLOT",5,,ALLOT ; ( n -- )
    .word DP,PLUSSTORE,EXIT

; alloue une cellule pour x à la position DP
DEFWORD ",",1,,COMMA  ; ( x -- )
    .word HERE,STORE,LIT,CELL_SIZE,ALLOT
    .word EXIT
    
; alloue le caractère 'c' à la position DP    
DEFWORD "C,",2,,CCOMMA ; ( c -- )    
    .word HERE,CSTORE,LIT,1,ALLOT
    .word EXIT
    
    
    
; Extrait le mot suivant du flux 
; d'entrée et le recherche dans le dictionnaire
; l'opération avorte en cas d'erreur.    
DEFWORD "'",1,,TICK ; ( <ccc> -- xt )
    .word BL,WORD,DUP,CFETCH,ZEROEQ,QNAME
    .word UPPER,FIND,ZBRANCH,5f-$
    .word BRANCH,9f-$
5:  .word COUNT,TYPE,SPACE,LIT,'?',EMIT,CR,ABORT    
9:  .word EXIT

; version immédiate de '
DEFWORD "[']",3,F_IMMED,COMPILETICK ; cccc 
    .word QCOMPILE
    .word TICK,CFA_COMMA,LIT,COMMA,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  les 4 mots suivants
;  sont utilisés pour résoudre
;  les adresses de sauts.    
;  les sauts sont des relatifs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;empile la position actuelle de DP
; cette adresse sera la cible
; d'un branchement arrière    
DEFWORD "<MARK",5,F_IMMED,MARKADDR ; ( -- a )
   .word QCOMPILE,HERE, EXIT

;compile l'adresse d'un branchement arrière
; complément de '<MARK'    
; le branchement est relatif à la position
; actuelle de DP    
DEFWORD "<RESOLVE",8,F_IMMED,BACKJUMP ; ( a -- )    
    .word QCOMPILE,HERE,MINUS,COMMA, EXIT
    
;reserve un espace pour la cible d'un branchement avant qui
; sera résolu ultérieurement.    
DEFWORD ">MARK",5,F_IMMED,MARKSLOT ; ( -- slot )
    .word QCOMPILE,HERE,LIT,0,COMMA,EXIT
    
; compile l'adresse cible d'un branchement avant
; complément de '>MARK'    
; l'espace réservé pour la cible est indiquée
; au sommet de la pile
DEFWORD ">RESOLVE",8,F_IMMED,FOREJUMP ; ( -- slot )
    .word QCOMPILE,DUP,HERE,SWAP,MINUS,SWAP,STORE,EXIT
    
;compile un cfa fourni en literal
DEFWORD "CFA,",4,F_IMMED,CFA_COMMA  ; ( -- )
  .word QCOMPILE,RFROM,DUP,FETCH,COMMA,CELLPLUS,TOR,EXIT


; passe en mode interprétation
DEFWORD "[",1,F_IMMED,LBRACKET ; ( -- )
    .word LIT,0,STATE,STORE
    .word EXIT
  
; passe en mode compilation
DEFWORD "]",1,F_IMMED,RBRACKET ; ( -- )
    .word LIT,-1,STATE,STORE
    .word EXIT

; avorte si le nom n'est pas trouvé dans le dictionnaire  
DEFWORD "?WORD",5,,QWORD ; ( -- c-addr 0 | cfa 1 | cfa -1 )
   .word BL,WORD,UPPER,FIND,QDUP,ZBRANCH,2f-$,EXIT
2: .word COUNT,TYPE,LIT,'?',EMIT,ABORT
  
;diffère la compilation du mot qui suis dans le flux
DEFWORD "POSTPONE",8,F_IMMED,POSTONE ; ( <ccc> -- )
    .word QCOMPILE ,QWORD
    .word ZEROGT,TBRANCH,3f-$
  ; mot non immmédiat
    .word CFA_COMMA,LIT,COMMA,CFA_COMMA,COMMA,EXIT
  ; mot immédiat  
3:  .word COMMA    
    .word EXIT    
  
DEFWORD "LITERAL",7,F_IMMED,LITERAL  ; ( x -- ) 
    .word STATE,FETCH,ZBRANCH,9f-$
    .word CFA_COMMA,LIT,COMMA
9:  .word EXIT

;RUNTIME  qui retourne l'adresse d'une chaîne litérale
;utilisé par (S") et (.")
HEADLESS DOSTR, HWORD  
;DEFWORD "(DO$)",5,F_HIDDEN,DOSTR ; ( -- addr )
    .word RFROM, RFETCH, RFROM, COUNT,PLUS, ALIGNED, TOR, SWAP, TOR, EXIT

;RUNTIME  de s"
; empile le descripteur de la chaîne litérale
; qui suis.    
HEADLESS STRQUOTE, HWORD    
;DEFWORD "(S\")",4,F_HIDDEN,STRQUOTE ; ( -- addr u )    
    .word DOSTR,COUNT,EXIT
 
;RUNTIME de C"
; empile l'adresse de la chaîne comptée.
HEADLESS RT_CQUOTE, HWORD    
;DEFWORD "(C\")",4,F_HIDDEN,RT_CQUOTE ; ( -- c-addr )
    .word DOSTR,EXIT
    
;RUNTIME DE ."
; imprime la chaîne litérale    
HEADLESS DOTSTR, HWORD    
;DEFWORD "(.\")",4,F_HIDDEN,DOTSTR ; ( -- )
    .word DOSTR,COUNT,TYPE,EXIT

; empile le descripteur de la chaîne qui suis dans le flux.    
HEADLESS SLIT, HWORD    
;DEFWORD "SLIT",4,F_HIDDEN, SLIT ; ( -- c-addr u )
    .word LIT,'"',WORD,COUNT,EXIT
    
; (,") compile une chaîne litérale    
HEADLESS STRCOMPILE, HWORD    
;DEFWORD "(,\")",4,F_HIDDEN,STRCOMPILE ; ( -- )
    .word SLIT,PLUS,ALIGNED,DP,STORE,EXIT

    
; interprétation: imprime la chaîne litérale qui suis.    
; compilation: compile le runtine (S") et la chaîne litérale    
DEFWORD "S\"",2,F_IMMED,SQUOTE ; ccccc" runtime: ( -- | c-addr u)
    .word QCOMPILE
    .word CFA_COMMA,STRQUOTE,STRCOMPILE,EXIT
    
DEFWORD "C\"",2,F_IMMED,CQUOTE ; ccccc" runtime ( -- c-addr )
    .word QCOMPILE
    .word CFA_COMMA,RT_CQUOTE,STRCOMPILE,EXIT
    
    
; interprétation: imprime la chaîne litérale qui suis
; compilation: compile le runtime  (.")    
DEFWORD ".\"",2,F_IMMED,DOTQUOTE ; ( -- )
    .word STATE,FETCH,ZBRANCH,4f-$
    .word CFA_COMMA,DOTSTR,STRCOMPILE,EXIT
4:  .word SLIT,TYPE,EXIT  
    
DEFWORD "RECURSE",7,F_IMMED,RECURSE ; ( -- )
    .word LATEST,FETCH,NFATOCFA,COMMA,EXIT 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots contrôlant le flux
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; compile xt de (DO)
; empile l'adresse du début de la boucle sur cstack
; empile 0 comme garde pour FIXLEAVE   
DEFWORD "DO",2,F_IMMED,DO ; ( C: -- a 0 ) compile xt de (DO)
    .word QCOMPILE,CFA_COMMA,DODO
    .word HERE,TOCSTK,LIT,0,TOCSTK,EXIT

; compile xt de (?DO) ref: 6.2.0620
; ?DO est semblabe à DO excepté que la 
; boucle n'est exécutée qui si les paramètres initiaux
; ne sont pas égaux: start<>limit    
; empile l'adresse de début de la boucle sur cstack
; empile 0 comme garde pour FIXLEAVE
DEFWORD "?DO",3,F_IMMED,QDO ; ( C: -- a-addr1 0 a-addr2 )
    .word QCOMPILE,CFA_COMMA,DOQDO
    .word HERE,LIT,2*CELL_SIZE,PLUS,TOCSTK,LIT,0,TOCSTK
    .word CFA_COMMA,BRANCH,HERE,TOCSTK,EXIT
    
    
;compile LEAVE
DEFWORD "LEAVE",5,F_IMMED,LEAVE ; (C: -- slot )
    .word QCOMPILE,CFA_COMMA,UNLOOP
    .word CFA_COMMA,BRANCH,MARKSLOT,TOCSTK,EXIT  
    
    
; résout toutes les adresses pour les branchements
; à l'intérieur des boucles DO LOOP|+LOOP
HEADLESS FIXLEAVE, HWORD    
;DEFWORD "FIXLEAVE",8,F_IMMED|F_HIDDEN,FIXLEAVE ; (C: a 0 i*slot -- )
1:  .word CSTKFROM,QDUP,ZBRANCH,9f-$
    .word DUP,HERE,CELLPLUS,SWAP,MINUS,SWAP,STORE
    .word BRANCH,1b-$
9:  .word CSTKFROM,BACKJUMP,EXIT    
 
; compile xt de (LOOP)  
; résout toutes les adresses de saut.  
DEFWORD "LOOP",4,F_IMMED,LOOP ; ( -- )
    .word QCOMPILE,CFA_COMMA,DOLOOP,FIXLEAVE,EXIT
    
; compile execution de +LOOP
; résout toutes les adressess de saut.    
DEFWORD "+LOOP",5,F_IMMED,PLUSLOOP ; ( -- )
    .word QCOMPILE,CFA_COMMA,DOPLOOP,FIXLEAVE,EXIT
    
; compile le début d'une boucle    
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
    
; compile un branchement arrière et
; résout le branchement avant du WHILE    
DEFWORD "REPEAT",6,F_IMMED,REPEAT ; ( slot a -- )
    .word QCOMPILE,CFA_COMMA,BRANCH,BACKJUMP,FOREJUMP,EXIT

;marque le début d'une structure CASE ENDCASE
DEFWORD "CASE",4,F_IMMED,CASE ; ( -- case-sys )
    .word QCOMPILE,LIT,0,EXIT ; marque la fin de la liste des fixup

;compile la strucutre d'un OF    
DEFWORD "OF",2,F_IMMED,OF ; ( -- slot )    
    .word QCOMPILE,CFA_COMMA,OVER,CFA_COMMA,EQUAL,CFA_COMMA,ZBRANCH
    .word MARKSLOT,EXIT
    
;compile la structure d'un ENDOF
DEFWORD "ENDOF",5,F_IMMED,ENDOF ; ( slot 1 -- slot2 )
    .word QCOMPILE,CFA_COMMA,BRANCH,MARKSLOT,SWAP,FOREJUMP,EXIT
    
;résoue les sauts de chaque ENDOF
; et compile un DROP
DEFWORD "ENDCASE",7,F_IMMED,ENDCASE ; ( case-sys -- )    
    .word QCOMPILE
1:  .word QDUP,ZBRANCH,8f-$
    .word FOREJUMP,BRANCH,1b-$
8:  .word CFA_COMMA,DROP,EXIT
  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; certains mots ne peuvent-être utilisés
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

; insère le lien vers le NFA du mot dont
; CFA est au sommet de S à la fin de la chaîne
; de liens du dictionnaire.
; si xt1 n'a pas de nom dans le dictionnaire
; le résultat est imprévisible.    
;DEFWORD "LINK",4,F_IMMED,LINK ; ( S: xt1 -- )
;    ; met le NFA qui est dans LATEST dans le NFA de xt1
;    .word CFATONFA,DUP,LATEST,FETCH,OVER,NFATOLFA,STORE
;    ; met le NFA de xt1 dans LATEST
;    .word LATEST,STORE,EXIT 

; cré une définition sans nom dans le dictionnaire
; et laisse son CFA (xt) sur la pile S
; met STATE en mode compilation    
DEFWORD ":NONAME",7,,COLON_NO_NAME ; ( S: -- xt )
    .word HERE,CFA_COMMA,ENTER,RBRACKET,EXIT
    
DEFWORD "EXIT,",5,F_IMMED,EXITCOMMA ; ( -- )
    .word CFA_COMMA,EXIT,EXIT

; ajoute un nouveau nom dans le dictionnaire
; à la sortie HERE retourne l'adresse du CFA    
DEFWORD "HEADER",6,,HEADER ; ( -- )
    .word LATEST,DUP,FETCH,COMMA,HERE
    .word SWAP,STORE
    .word BL,WORD,UPPER,CFETCH,DUP,ZEROEQ,QNAME
    .word ONEPLUS,ALLOT,ALIGN,NAMEMARK,HIDE,EXIT
 
; efface le mot désignée et tous les suivant
DEFWORD "FORGET",6,,FORGET ; cccc
    .word TICK,CFATONFA,NFATOLFA,DUP,LIT,0x8000,UGREATER
    .word QABORT
    .byte  26
    .ascii "Can't forget word in FLASH"
    .align 2
    .word DUP,DP,STORE,FETCH,LATEST,STORE,EXIT    

; crée un mot marker qui efface tous les mots qui le suivent
; lorsqu'il est invoqué.
DEFWORD "MARKER",6,,MARKER ; cccc
    .word HEADER,HERE,CFA_COMMA,ENTER,CFA_COMMA,LIT,COMMA
    .word CFA_COMMA,RT_MARKER,EXITCOMMA,REVEAL,EXIT
    
HEADLESS  RT_MARKER,HWORD   
    .word CFATONFA,NFATOLFA,DUP,DP,STORE,FETCH,LATEST,STORE
    .word EXIT
  
; crée une nouvelle définition dans le dictionnaire    
DEFWORD ":",1,,COLON ; ( name --  )
    .word HEADER ; ( -- )
    .word RBRACKET,CFA_COMMA,ENTER,EXIT

;RUNTIME utilisé par CREATE
; remplace ENTER    
    .global FETCH_EXEC
    FORTH_CODE
FETCH_EXEC: ; ( -- pfa )
     DPUSH
     mov WP,T         
     mov [T++],WP  ; CFA
     mov [WP++],W0
     goto W0
    
;cré une nouvelle entête dans le dictionnaire
;qui peut-être étendue par DOES>
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
    .word EXITCOMMA,CFA_COMMA,ENTER
    .word EXIT
    
; création d'une variable
DEFWORD "VARIABLE",8,,VARIABLE ; ()
    .word CREATE,LIT,0,COMMA,EXIT

; création d'une constante
DEFWORD "CONSTANT",8,,CONSTANT ; ()
    .word HEADER,REVEAL,LIT,DOCONST,COMMA,COMMA,EXIT
    
   
    
; termine une définition débutée par ":"
DEFWORD ";",1,F_IMMED,SEMICOLON  ; ( -- ) 
    .word QCOMPILE
    .word EXITCOMMA
    .word REVEAL
    .word LBRACKET,EXIT
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots du core étendu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RUNTIME COMPILÉE PAR DEFER    
HEADLESS NOINIT,HWORD
;DEFWORD "(NOINIT)",8,F_HIDDEN,NOINIT ; ( -- )
    .word DOTSTR
    .byte  26
    .ascii "Uninitialized defered word"
    .align 2
    .word CR,ABORT
    
HEADLESS DEFEREXEC,HWORD
     .word FETCH,EXECUTE,EXIT
     
; création d'un mot la définition de la sémantique d'exécution
; est différée.
; Utilise à sémantique par défaut (NOINIT)
DEFWORD "DEFER",5,,DEFER ; ccccc ( -- )
    .word CREATE,CFA_COMMA,NOINIT
    .word RT_DOES,DEFEREXEC,EXIT

; initialise la sémantique d'exécution d'un mot définit avec DEFER 
;  xt1  CFA de la sémantique que le mot doit exécuté
;  xt2  CFA du mot diféré.    
DEFWORD "DEFER!",6,,DEFERSTORE ;  ( xt1 xt2 -- )
    .word TOBODY,STORE,EXIT

; empile le xt interprété par un mot défini avec DEFER
; xt1 CFA du mot diféré
; xt2 CFA de la sémantique d'exécution de ce mot.    
DEFWORD "DEFER@",6,,DEFERFETCH ; ( xt1 -- xt2 )
    .word TOBODY,FETCH,EXIT
 
; initilalise la sémantique d'exécution d'un mot définit avec DEFER
; le nom du mot diféré est fourni en texte    
DEFWORD "IS",2,,IS  ; ( xt1 cccc -- )
    .word TICK,TOBODY,STORE,EXIT
    
    
DEFWORD "ACTION-OF",9,,ACTIONOF ; ( ccc -- xt2 )
    .word TICK,TOBODY,FETCH,EXIT
    
    
; imprime le commentaire délimité par )
DEFWORD ".(",2,F_IMMED,DOTPAREN ; ccccc    
    .word LIT,')',PARSE,TYPE,EXIT
    
; envoie 2 élément de S au sommet de R
; de sorte qu'il soient dans le même ordre
; >>> ne pas utiliser en mode interprétation    
DEFWORD "2>R",3,,TWOTOR ;  S: x1 x2 --  R: -- x1 x2
    .word RFROM,NROT,SWAP,TOR,TOR,TOR,EXIT
    
; envoie 2 éléments de R vers de sorte
; qu'ils soient dans le même ordre
; >>> ne pas utiliser en mode interprétation    
DEFWORD "2R>",3,,TWORFROM ; S: -- x1 x2  R: x1 x2 --
    .word RFROM,RFROM,RFROM,SWAP,ROT,TOR,EXIT
    
; copie 2 éléments de R vers S en consversant l'ordre    
; >>> ne pas utiliser en mode interprétation
; >>> 2R> doit-être appellé avant la sortie
; >>> de la routine qui utilise ce mot.    
; >>> Au préalable 2>R a été appellé dans la même routine.    
DEFWORD "2R@",3,,TWORFETCH ; S: -- x1 x2 R: x1 x2 -- x1 x2    
    .word RFROM,RFROM,RFETCH,OVER,TOR,ROT,TOR
    .word SWAP,EXIT
    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;     OUTILS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Les mots suivants sont
;  des outils qui facilite
;  le débogage.
    
; vérifie si DSP est dans les limites    
DEFCODE "?DSP",4,,QDSP
    mov #pstack,W0
    cp DSP,W0
    bra ltu,_underflow
    add #DSTK_SIZE-CELL_SIZE,W0
    cp W0,DSP
    bra ltu,_overflow
    NEXT
_underflow:
    mov #DSTACK_UNDERFLOW,W0
    mov WREG,fwarm
    reset
_overflow:
    mov #DSTACK_OVERFLOW,W0
    mov WREG,fwarm
    reset
    
    
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

;imprime le contenu de la pile des retours  
DEFWORD ".RTN",4,,DOTRTN ; ( -- )
    .word BASE, FETCH,HEX
    .word CLIT,'R',EMIT,CLIT,':',EMIT
    .word RPFETCH,R0,DODO
1:  .word DOI,FETCH,DOT,LIT,2,DOPLOOP,1b-$
    .word BASE,STORE,EXIT
  
;lit et imprime une plage mémoire
; n nombre de mots à lire
; addr adresse de départ
; 8 mots par ligne d'affichage
DEFWORD "DUMP",4,,DUMP ; ( addr +n -- )
    .word QDUP,TBRANCH,3f-$,EXIT
3:  .word BASE,FETCH,TOR,HEX
    .word SWAP,LIT,0xFFFE,AND,SWAP,LIT,0,DODO
1:  .word DOI,LIT,15,AND,TBRANCH,2f-$
    .word CR,DUP,LIT,4,UDOTR,SPACE
2:  .word DUP,ECFETCH,LIT,3,UDOTR,LIT,1,PLUS
    .word DOLOOP,1b-$,DROP
    .word RFROM,BASE,STORE,EXIT

; active/désactive les breaks points    
DEFWORD "DEBUG",5,,DEBUG ; ( f -- )
    .word DBGEN,STORE    
    .word EXIT
    
; interrompt le programme en cours d'exécution et
; entre en mode interpréteur
DEFWORD "BREAK",5,,BREAK ; ( ix n -- ix )
    .word DBGEN,FETCH,TBRANCH,1f-$
    .word DROP,EXIT
1:  .word RPFETCH,RPBREAK,STORE
    .word CR,DOTSTR
    .byte  13
    .ascii "break point: "
    .align 2
    .word DOT,CR,DOTS,CR,REPL
    .word EXIT

; résume le programme interrompu par BREAK
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

; imprime la liste des mots qui construite une définition
; de HAUT-NIVEAU  
;DEFWORD "SEELIST",7,F_IMMED,SEELIST ; ( cfa -- )
;    .word BASE,FETCH,TOR,HEX,CR
;    .word LIT,2,PLUS ; première adresse du mot 
;1:  .word DUP,FETCH,DUP,CFATONFA,QDUP,ZBRANCH,4f-$
;    .word COUNT,LENMASK,AND
;    .word DUP,GETX,PLUS,LIT,CPL,LESS,TBRANCH,2f-$,CR 
;2:  .word TYPE
;3:  .word LIT,',',EMIT,FETCH,LIT,code_EXIT,EQUAL,TBRANCH,6f-$
;    .word LIT,2,PLUS,BRANCH,1b-$
;4:  .word UDOT,DVP,BRANCH,3b-$
;6:  .word DROP,RFROM,BASE,STORE,EXIT
  

