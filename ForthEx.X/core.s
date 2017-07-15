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
    
; NOM: core.s
; DATE: 2015-10-03
; DESCRIPTION: 
;    Vocabulaire de base du syst�me ForthEx.
;    Liste de r�f�rences utiles concernant le langage Forth.    
; REF: http://www.forth200x.org/documents/forth16-1.pdf    
; REF: http://www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt
; REF: http://www.bradrodriguez.com/papers/
; REF: http://www.camelforth.com/download.php?view.25
; REF: http://sinclairql.speccy.org/archivo/docs/books/Threaded_interpretive_languages.pdf    
; REF: http://www.exemark.com/FORTH/eForthOverviewv5.pdf
; REF: http://forthfiles.net/ting/sysguidefig.pdf    
    
    
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
; m�moire tampon d'entr�e du terminal.
.global _TIB    
_TIB: .space 2
.global _PAD 
_PAD: .space 2   
.global _PASTE
_PASTE: .space 2 
 .global _TICKSOURCE
; adresse et longueur de la m�moire tampon d'�valuation
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

; run time 
;    M�canisme d'appel des mots de haut-niveaux 
;    CFA compil� par les mots qui cr�s des d�finitions de haut-niveau. 
 .global ENTER
ENTER:
    RPUSH IP   
    mov WP,IP
    NEXT

; run time 
;    Empile l'adresse d'une variable syst�me.
;    Utilis� par le syst�me interne seulement.    
 .global DOUSER
DOUSER: 
    DPUSH
    mov [WP++],W0
    add W0,VP,T
    NEXT

; run time    
;    Code dont le CFA est compil� par VARIABLE
 .global DOVAR
DOVAR:
    DPUSH
    mov WP,T
    NEXT
 
; run time    
;   code dont le CFA est compil� par CONSTANT.    
 .global DOCONST
DOCONST:
    DPUSH
    mov [WP],T
    NEXT

    
; run time
;   M�canisme de sortie d'un mot de haut-niveau.
;   premier mot du dictionnaire il est cependant cach�
;   � l'utilisateur. 
;   Le CFA de ce mot est compil� pour terminer une d�finition de haut-niveau.    
HEADLESS EXIT,CODE
    RPOP IP
    NEXT

; run time    
;   Empile un entier lit�ral. CFA compil� par LITERAL.
HEADLESS LIT  ; ( -- x )  
    DPUSH
    mov [IP++], T
    NEXT

; run time   
;   empile un caract�re lit�ral. CFA compil� par C@
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
;   code dont le CFA est compil� par DO
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
;   code dont le CFA est compil� par  ?DO
HEADLESS DOQDO ; ( n n -- ) R( -- | I LIMIT )    
    cp T,[DSP]
    bra z, 9f
    add #(2*CELL_SIZE),IP ; saute le branchement inconditionnel
    bra doit
9:  DPOP
    DPOP
    NEXT

; runtime    
;   code dont le CFA est compil� par DOLOOP
;   La boucle se termine quand I==LIMIT 
;   A la sortie de la boucle I et LIMIT sont restaur�s � partir de R: LIMIT I
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
;   code dont le CFA est compil� par +LOOP
;   La boucle s'arr�te lorsque I franchi la fronti�re
;   entre LIMIT et LIMIT-1 dans un sens ou l'autre
;   A la sortie de la boucle I et LIMIT sont restaur�s � partir de R: LIMIT I
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

; marqueur fin du dictionnaire.    
    SYSDICT
   .word 0 
0: .word 0    

; DESCRIPTION:
; Cette section d�cris les diff�rentes constantes utilis�es par le syst�me ForthEx.

; nom: VERSION   ( -- c-addr )
;   Constante syst�me, Adresse de la cha�ne compt� qui contient l'information de version firmware.
;   Utilisation: VERSION COUNT TYPE
; arguments:
;   aucun
; retourne:
;   c-addr  Adresse de la cha�ne constante en m�moire FLASH.    
DEFCONST "VERSION",7,,VERSION,psvoffset(_version)
    
; nom: R0  ( -- a-addr )
;   Constante syst�me, retourne l'adresse de la base de la pile des retours.       
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse de la base de la pile des retours.    
DEFCONST "R0",2,,R0,rstack   ; base pile retour
    
; nom: S0   ( -- a-addr )
;   Constante syst�me qui retourne l'adresse de la base de la piles des arguments.    
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse de la base de la pile des arguments.    
DEFCONST "S0",2,,S0,pstack   ; base pile arguments   
    
; nom: RAMEND  ( -- a-addr )
;   Constante syst�me qui retourne l'adresse qui suis la fin de la m�moire RAM.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse fin de la RAM+1    
DEFCONST "RAMEND",6,,RAMEND,RAM_END
    
; nom: ULIMIT   ( -- a-addr )
;   Constante syst�me qui retourne l'adresse qui suis la fin de la RAM utilisateur.
;   Cette adresse correspond au d�but de la m�moire HEAP qui est g�r�e par les d�finitions dans dynamem.s
;   Microchip appelle cette m�moire RAM, d�butant � 0x8000, EDS (Extended Data Space).
;   Le m�moire tampon vid�o se trouve � la fin de l'EDS. Le reste de l'EDS constitue
;   le HEAP (m�moire dynamique). 
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse d�but HEAP.    
DEFCONST "ULIMIT",6,,ULIMIT,EDS_BASE        ; limite espace dictionnaire

; nom: TRUE  ( -- f )
;   Constante syst�me qui retourne la valeur Bool�enne VRAI. Cette valeur est repr�sent�e
;   par l'entier -1 (tous les bit � 1 ). 
; arguments:
;   rien
; retourne:
;   f      indicateur Bool�en VRAI = -1    
DEFCONST "TRUE",4,,TRUE,-1 ; valeur bool�enne vrai
    
; nom: FALSE  ( -- f )
;   Constante syst�me qui retourne la valeur Bool�enne FAUX. Cette valeur est repr�sent�e
;   par l'entier 0 ( tous les bits � z�ro). 
; arguments:
;   rien
; retourne:
;   f      indicateur Bool�en FAUX = 0    
DEFCONST "FALSE",5,,FALSE,0 ; valeur bool�enne faux
    
; nom: DP0    ( -- a-addr )
;   Constante syst�me qui retourne l'adresse du d�but de l'espace de donn�es utilisateur.
; arguments:
;   rien
; retourne:
;   a-addr   Adresse du d�but de l'espace utilisateur en m�moire RAM.    
DEFCONST "DP0",3,,DP0,DATA_BASE ; d�but espace utilisateur
   
; nom: CELL   ( -- u )    
;   Constante syst�me qui retourne la taille d'une cellule. 
;   Une cellule est le nom donn� � un �l�ment de la pile. 
;   Pour forthEx sur PIC24EP les entiers sont de 16 bits donc
;   la pile utilise des cellules de 2 octets.    
; arguments:
;   aucun
; retourne:
;   u   Grandeur d'une cellule en octets.    
DEFCONST "CELL",4,,CELL,CELL_SIZE
 
; DESCRIPTION:
;  Cette section d�cris les diff�rentes variables utilis�es par le syst�me.
    
; nom: DP ( -- a-addr )
;   Variable syst�me qui contient la position du pointeur de donn�e dans l'esapce utilisateur.
;   Lorsqu'une nouvelle d�finition est cr��e ou que de l'espace est r�serv� avec ALLOT ce
;   pointeur avance � la premi�re position libre. La valeur de cette variable est retourn�e
;   par le mot HERE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "DP",2,,DP 

; nom: BASE  ( -- a-addr )
;   Variable syst�me qui contient la valeur de la base num�rique active.
;   Le contenu de cette variable est modifi�e par les mots HEX et DECIMAL.
;   Peut aussi �tre modifi�e manuellement exemple:
;   2 BASE ! \ passage en base binaire. 
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "BASE",4,,BASE     ; base num�rique

; nom: SYSLATEST  ( -- a-addr )
;   Variable syst�me qui contient le NFA (Name Field Address) du dernier mot d�fini dans le dictionnaire
;   syst�me en m�moire FLASH. Le dictionnaire est divis� en 2 parties, la partie syst�me
;   qui r�side en m�moire FLASH et la partie utilisateur qui r�side en m�moire RAM. 
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "SYSLATEST",9,,SYSLATEST ; t�te du dictionnaire en FLASH
    
; nom: LATEST  ( -- a-addr )
;   Variable syst�me qui contient le NFA du dernier mot d�fini par l'utilisateur.
;   Si le dictionnaire utilisateur est vide LASTEST contient la m�me valeur que SYSLATEST. 
;   C'est le d�but de la liste des mots d�finis par l'utilisateur. 
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "LATEST",6,,LATEST ; pointer dernier mot dictionnaire

; DESCRIPTION:
;  La machine Virtuelle ForthEx utilise 3 piles.
;  La pile des arguments sert a passer des arguments d'une fonction � une autre
;  ainsi qu'� retourner les valeurs des fonctions.
;  La pile des retours sert principalement a conserver la valeur du pointeur
;  d'instruction lors de l'appel de mots de haut-niveau afin de retourner au point
;  initial. Mais elle sert aussi � conserver des valeurs temporaires.
;  La 3i�me pile est utilis�e seulement par le compilateur pour conserver des adresses
;  de sauts qui doivent-�tre r�solues avant de terminer la compilation.
;  Les mots suivants servent � manipuler le contenu des piles.
;  Lorsqu'il n'y a pas d'indication il s'agit de la pile des arguments autrement,
;  R: repr�sente la pile des retours et C: la pile de contr�le.
 
; nom: DUP ( x1 -- x1 x2 )
;   Clone la valeur au sommet de la pile.
; arguments:
;    x1    Valeur au sommet de  la pile des arguments.    
; retourne:
;    x1    Valeur originale.
;    x2    Copie de x1.
DEFCODE "DUP",3,,DUP ; ( n -- n n )
    DPUSH
    NEXT

; nom: 2DUP   ( d1 -- d1 d2 )
;   Clone l'entier double qui est au sommet de la pile.
; arguments:
;   d1      Entier double.
; retourne:
;   d1      Valeur originale.
;   d2      Copie de d1.
DEFCODE "2DUP",4,,TWODUP 
    mov [DSP],W0
    DPUSH
    mov W0,[++DSP]
    NEXT
    
; nom: ?DUP  ( x1 -- 0 | x1 x2 )    
;    Clone la valeur au sommet de la pile si cette valeur est diff�rente de z�ro.
; arguments:
;    x1   Valeur au sommet de la pile.
; retourne:
;    x1   Valeur originale.
;    x2   Copie de x1 si x1<>0.    
DEFCODE "?DUP",4,,QDUP 
    cp0 T
    bra z, 1f
    DPUSH
1:  NEXT
    
; nom: DROP ( x -- )
;   Jette la valeur au sommet de la pile.
; arguments:
;    x    Valeur au sommet de la pile.
; retourne:
;    rien     La pile contient 1 �l�ment de moins.    
DEFCODE "DROP",4,,DROP
    DPOP
    NEXT

; nom: 2DROP ( x1 x2 -- )
;   Jette les 2 valeurs au sommet de la pile.    
; arguments:
;   x1  Valeur sous le sommet.
;   x2  Valeur au sommet de la pile.
; retourne:
;   rien La pile contient 2 �l�ments de moins.    
DEFCODE "2DROP",5,,TWODROP
    DPOP
    DPOP
    NEXT
    
; nom: RDROP  ( R: x -- )
;   Jette la valeur au sommet de la pile des retours.
; arguments:
;    x  Valeur au sommet de la pile des retours.
; retourne:
;   rien La pile des retours contient 1 �l�ment de moins.    
DEFCODE "RDROP",5,,RDROP ; ( R: n -- )
    sub #CELL_SIZE,RSP
    NEXT
    
; nom: SWAP  ( x1 x2 -- x2 x1 )
;   Inverse l'ordre des 2 �l�ments au sommet de la pile des arguments.
; arguments:
;   x1   Deuxi�me �l�ment de la pile.
;   x2   �l�ment au sommet de la pile.
; retourne:
;   x2   La valeur qui �tait au sommet est maintenant en second.
;   x1   La valeur qui �tait en second est maintenant au sommet.    
DEFCODE "SWAP",4,,SWAP ; ( n1 n2 -- n2 n1)
    mov [DSP],W0
    exch W0,T
    mov W0,[DSP]
    NEXT

; nom: 2SWAP  ( d1 d2 -- d2 d1 )
;   Notation alternative: ( n1 n2 n3 n4 -- n3 n4 n1 n2 )    
;   Inverse l'ordre de 2 entiers doubles au sommet de la pile.
; arguments:
;   d1   Second entier double de la pile des arguments.
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
;   Rotation des 3 �l�ments du sommet de sorte que le 3i�me se retrouve au sommet.
; arguments:
;   n1  �l�ment en 3i�me position de la pile.
;   n2  �l�ment en 2i�me position de la pile.
;   n3  �l�ment a sommet de la pile.
; retourne:
;   n2  Le second est maintenant en 3i�me position.
;   n3  Le sommet est maintenant en 2i�me position.
;   n1  Le 3i�me est maintenant au sommet.    
DEFCODE "ROT",3,,ROT  ; ( n1 n2 n3 -- n2 n3 n1 )
    mov [DSP], W0 ; n1
    exch T,W0   ; W0=n3, T=n2
    mov W0, [DSP]  ; n3
    mov [DSP-2],W0 ; n1
    exch W0,T ; T=n1, W0=n2
    mov W0,[DSP-2] 
    NEXT

; nom: -ROT ( n1 n2 n3 -- n3 n1 n2 )
;   Rotation inverse des 3 �l�ments du sommet de la pile.
;   Le sommet est envoy� en 3i�me position.
; arguments:
;   n1   3i�me �l�ment de la pile.
;   n2   2i�me �l�ment de la pile.
;   n3   1ier �l�ment de la pile.
; retourne:
;   n3   Le sommet est maintenant en 3i�me position.
;   n1   Le 3i�me est maintenant en 2i�me position.
;   n2   Le second �l�ment est maintenant au sommet.    
DEFCODE "-ROT",4,,NROT ; ( n1 n2 n3 -- n3 n1 n2 )
    mov T, W0    
    mov [DSP],T
    mov [DSP-2],W1
    mov W1,[DSP]
    mov W0,[DSP-2]
    NEXT
    
; nom: OVER  ( n1 n2 -- n1 n2 n1 )
;   Copie du second �l�ment de la pile par dessus le sommet de celle-ci.
; arguments:
;   n1 Second �l�ment de la pile.
;   n2 Sommet de la pile.
; retourne:
;   n1   Le second est maintenant le 3i�me.
;   n2   Le sommet est maintenant le 2i�me.
;   n1   Une copie du second se retrouve maintenant au somment.    
DEFCODE "OVER",4,,OVER  ; ( n1 n2 -- n1 n2 n1 )
    DPUSH
    mov [DSP-2],T
    NEXT

; nom: 2OVER  ( d1 d2 -- d1 d2 d1 )
;   Si on consid�re qu'il y a 2 entiers doubles au sommet de la pile, une
;   copie du second est cr�� au sommet. La pile s'allonge donc de 2 cellules.
; arguments:
;   d1   Entier double en seconde position.
;   d2   Entier double au somment.
; retourne:
;   d1   L'entier double qui �tait en second est maintenant en 3i�me position.
;   d2   L'entier double qui �tait au sommet est maintenant en 2i�me position.
;   d1   Une copie du 2i�me entier double est maintenant au somment.    
DEFCODE "2OVER",5,,TWOOVER ; ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )
    DPUSH
    mov [DSP-4],T
    mov [DSP-6],W0
    mov W0,[++DSP]
    NEXT
    
; nom: NIP ( x1 x2 -- x2 )
;   Jette le second �l�ment de la pile.
; arguments:
;   x1   Valeur en second sur la pile.
;   x2   Valeur au sommet de la pile.
; retourne:
;   x2   La valeur au sommet n'a pas chang�e mais le 2i�me �l�ment est disparue.
DEFCODE "NIP",3,,NIP   ; ( n1 n2 -- n2 )
    dec2 DSP,DSP
    NEXT

; nom: TUCK  ( x1 x2 -- x2 x1 x2 )
;   Ins�re une copie de la valeur au sommet de la pile des arguments
;   Sous la valeur en 2i�me position. Apr�s cette op�ration la pile contient
;   1 �l�ment de plus.
; arguments:
;   x1  Second �l�m�ent de la pile.
;   x2  �l�ment au sommet de la pile.
; retourne:
;   x2  copie du sommet de la pile.
;   x1  2ieme �l�ment de la pile demeure inchang�.
;   x2  Sommet de la pile demeure inchang�.    
DEFCODE "TUCK",4,,TUCK 
    mov [DSP],W0 ; n1
    mov T,[DSP]  ; n2 n2 
    mov W0,[++DSP] ; n2 n1 n2
    NEXT

    
; nom: >R  (  x --  R: -- x )
;   Transfert le sommet de la pile des arguments au sommet de la pile des retours.
;   Apr�s cette op�ration la pile des arguments a raccourcie d'un �l�ment et la
;   pile des retours a rallong�e d'un �l�ment.    
; arguments:
;   x   Valeur au sommet de la pile des arguments.
; retourne:
;   rien   La valeur x est maintenant au sommet de la pile des retours.  
DEFCODE ">R",2,,TOR  
    RPUSH T
    DPOP
    NEXT
    
; nom: R>  ( -- x  R: x -- )     
;   Transfert d'un �l�ment de la pile des retours vers la pile des arguments.
;   Apr�s cette op�ration la pile des retours a raccourcie de 1 �l�ment et la
;   pile des arguments a rallong�e d'un �l�ment.
; arguments:
;   x  Valeur au somment des retours.
; retourne:
;   x  Valeur qui �tait au sommet de R: est maintenant ajout�e au sommet de S:.    
DEFCODE "R>",2,,RFROM  
    DPUSH
    RPOP T
    NEXT

; nom: IP@  ( -- n )  
;   Retourne la valeur du pointeur d'instruction de la machine virtuelle forth.
; arguments:
;   aucun
; retourne:
;   n     Valeur de IP.    
DEFCODE "IP@",3,,IPFETCH  ; ( -- n )
    DPUSH
    mov IP,T
    NEXT

; nom: DEPTH  ( -- n )    
;   Retourne le nombre d'�l�ments sur la pile des arguments. Le nombre d'�l�ments
;   renvoy�  exclu ce nouvel �l�ment.
; arguments:
;   aucun
; retourne:
;   n   Nombre d'�l�ments qu'il y avait sur la pile avant cette op�ration.    
DEFCODE "DEPTH",5,,DEPTH ; ( -- n )
    mov #pstack,W0
    sub DSP,W0,W0
    DPUSH
    lsr W0,T
    NEXT

; nom: PICK  ( i*x n --  i*x x )
;   Place une copie du ni�me �l�ment de la pile au sommet de celle-ci.
;   l'argument n est retir� de la pile avant le comptage.
;   Si n==0 �quivaut � DUP 
;   Si n==1 �quivaut � OVER
; arguments:
;   i*x   Liste des �l�ments pr�sent sur la pile.
;   n     Position de l'�l�ment recherch�, 0 �tant le sommet.
; retourne:
;   i*x   Liste originale des �l�ments.
;   x     Copie de l'�l�ment en position n.    
DEFCODE "PICK",4,,PICK
    mov DSP,W0
    sl T,T
    sub W0,T,W0
    mov [W0],T
    NEXT
    
    
; nom: R@  ( -- x R: x -- x )
;    La valeur au sommet de la pile des retours est copi�e au sommet de la pile
;    des arguments. Le contenu de la pile des retours n'est pas modifi�. Le contenu
;    de la pile des arguments a 1 �l�ment suppl�mentaire.
; arguments:
;    aucun  
; retourne:
;    x    Valeur ajout�e � la pile des arguments, copie du sommet de R.    
DEFCODE "R@",2,,RFETCH 
    DPUSH
    mov [RSP-2], T
    NEXT

; nom: SP@  ( -- n )
;   Retourne la valeur du pointeur de la pile des arguments.
; arguments:
;   aucun
; retourne:
;   n   Valeur du pointeur SP avant cette op�ration.
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
;   Retourne la valeur du pointeur de la pile des retours.
; arguments:
;   aucun
; retourne:
;   n   Valeur du pointeur de la pile des retours.    
DEFCODE "RP@",3,,RPFETCH  ; ( -- n )
    DPUSH
    mov RSP, T
    NEXT
    
; nom: RP! ( n -- )
;   Initialise le pointeur de la pile des retours avec la valeur
;   qui est au sommet de la pile des arguments.
; arguments:
;   n   Valeur d'initialistaion de RP.
; retourne:
;   rien    
DEFCODE "RP!",3,,RPSTORE  ; ( n -- )
    mov T, RSP
    DPOP
    NEXT
    
; nom: >CSTK  ( x --   C: -- x )
;   Utiliser par le compilateur.    
;   Tranfert du sommet de la pile des arguments 
;   vers la pile de contr�le. Apr�s cette op�ration la pile 
;   des arguments � perdue un �l�ment et la pile de contr�le en a
;   gagn� un.    
; arguments:
;   x   Valeur au sommet de la pile des arguments.
; retourne:
;   rien    Le sommet de  la pile de contr�le contient x.    
DEFCODE ">CSTK",5,,TOCSTK 
    mov csp,W0
    mov T,[W0++]
    mov W0,csp
    DPOP
    NEXT

; nom: CSTK>  ( -- x C: x -- )
;   Utilis� par le compilateur.    
;   Transfert du sommet de la pile de contr�le
;   vers la pile des arguments. Apr�s cette op�ration la pile de contr�le
;   contient un �l�ment de moins et la pile des arguments un �l�ment de plus.
; arguments:
;    x   Valeur au sommet de la pile de contr�le.
; retourne:
;    x    Valeur ajout�e au sommet de la pile des arguments.    
DEFCODE "CSTK>",5,,CSTKFROM 
    DPUSH
    mov csp,W0
    mov [--W0],T
    mov W0,csp
    NEXT
    
; nom: @   ( a-addr -- n )
;   Retourne l'entier qui se trouve � l'adresse qui est au sommet de la pile des arguments.
;   Cette adresse doit-�tre align�e sur une adresse paire.    
;   Les adresses >= 32768 acc�dent la m�moire FLASH dans l'interval {0..32766}.
;   L'acc�s � la m�moire flash ne permet que la lecture du mot faible, i.e. bits 15:0 de l'instruction.    
; arguments:
;   a-addr  Adresse de la variable.
; retourne:
;   n	Entier contenu � cette adresse.
DEFCODE "@",1,,FETCH 
    mov [T],T
    NEXT

; nom: C@  ( c-addr -- c )
;   Retourne l'octet contenu � l'adresse caract�re qui est au sommet de la pile.
;   Les adresses >= 32768 acc�dent la m�moire FLASH dans l'interval {0..32767}.    
;   L'acc�s � la m�moire flash ne permet que la lecture des 2 octets du mot faible.
;   Si l'adresse est paire les bits 7:0 sont lus.
;   Si l'adresse est impaire les bits 15:8 sont lus.    
; arguments:
;   c-addr  Adresse align�e sur un octet.
; retourne:
;   c   Caract�re contenu � cette adresse.    
DEFCODE "C@",2,,CFETCH 
    mov.b [T],T
    ze T,T
    NEXT
    
; nom: 2@  ( a-addr -- d )    
;   Retourne la valeur de type entier double qui est � l'adresse a-addr.
;   Cette adresse doit-�tre align�e sur une valeur paire.    
;   Les adresses >= 32768 acc�dent la m�moire FLASH.  
;   S'il s'agit d'une adresse en FLASH, les valeurs du mot faible de 2 instructions
;   successive sont retourn�es.    
; arguments:
;   a-addr   Adresse de la variable
; retourne:
;   d   Entier double, valeur de cette variable.    
DEFCODE "2@",2,,TWOFETCH 
;    SET_EDS
    mov [T],[++DSP]
    add #CELL_SIZE,T
    mov [T],T
;    RESET_EDS
    NEXT

; nom: BID@  ( c-addr -- d )
;   Empile un entier double stock� en m�moire en format BIG INDIAN
; arguments:
;   c-addr  Adresse du premier octet.
; retourne:
;   d  Entier double.
DEFCODE "BID@",4,,BIDFETCH
    mov.b [T++],W0
    ze W0,W0
    swap W0
    mov.b [T++],W1
    ze W1,W1
    mov.b [T++],W2
    ze W2,W2
    swap W2
    mov.b [T],W3
    ze W3,W3
    add W0,W1,T
    add W2,W3,[++DSP]
    NEXT
    
    
; nom: TBL@  ( n a-addr -- n )    
;   Retourne l'�l�ment n d'un vecteur. Les valeurs d'indice d�bute � z�ro.
;   L'adresse de la table doit-�tre align�e sur une adresse paire.
;   Les adresses >= 32768 sont en m�moire FLASH. S'il s'agit d'une adresse en FLASH
;   la valeur du mot faible de l'instruction est retourn�.    
; arguments:
;   n  Indice dans le vecteur.
;   a-addr  Adresse du vecteur.
; retourne:
;   n    Valeur de l'�l�ment n du vecteur.    
DEFCODE "TBL@",4,,TBLFETCH
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W1,W0,W0
    add T,W0,W0
    mov [W0],T
    NEXT

    
; nom: TBL!  ( n1 n2 a-addr -- )    
;   Sauvegarde l'entier n1 dans l'�l�ment d'indice n2 du vecteur dont d'adresse a-addr.
;   L'adresse de table doit-�tre align�e sur un nombre pair.    
;   a-addr[n2] = n1.
;   Les adresses >= 32768 acc�dent la m�moire EDS.    
; arguments:
;   n1  Valeur � affect� � l'�l�ment.
;   n2  Indice de l'�l�ment.
;   a-addr  Adresse de la table.
; retourne:
;    rien
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
;   Acc�de les SFR, la RAM utilisateur et la RAM EDS.    
; arguments:
;   n    Valeur � sauvegarder.
;   a-addr Adresse de la variable.    
; retourne:
;   rien    
DEFCODE "!",1,,STORE 
    mov [DSP--],[T]
    DPOP
    NEXT

; nom: C!  ( c c-addr -- )    
;   Sauvegarde un caract�re dans une variable.
;   Acc�de les SFR, la RAM utilisateur et la RAM EDS.
; arguments:
;   c   Valeur � sauvegarder.
;   c-addr  Adresse de la variable.
; retourne:
;    rien    
DEFCODE "C!",2,,CSTORE
    mov [DSP--],W0
    mov.b W0,[T]
    DPOP
    NEXT

; nom: 2!   ( d a-addr -- )    
;   Sauvegarde d'un entier double.
;   Acc�de les SFR, la RAM utilisateur et la RAM EDS    
; arguments:
;   d   Entier double
;   a-addr  Adresse de la variable.
; retourne:
;   rien    
DEFCODE "2!",2,,TWOSTORE
    mov [DSP--],[++T]
    mov [DSP--],[--T]
    mov [DSP],T
    NEXT
    
; nom: 2>R   ( S: d --  R: -- d )    
;   Transfert un entier double de la pile des arguments vers la pile des retours.
; arguments:
;    d    Entier double ou 2 entiers simples.
; retourne:
;    rien  L'entier double est maintenant sur R:    
DEFWORD "2>R",3,,TWOTOR ;  S: x1 x2 --  R: -- x1 x2
    .word RFROM,NROT,SWAP,TOR,TOR,TOR,EXIT

; nom: 2R>   ( S: -- d  R: d -- )    
;   Transfert un entier double de la pile des retours vers la pile des arguments.
; arguments:
;   d Entier double sur R: � transf�rer sur S:.
; retourne:
;   d Entier double en provenance de R:    
DEFWORD "2R>",3,,TWORFROM ; S: -- x1 x2  R: x1 x2 --
    .word RFROM,RFROM,RFROM,SWAP,ROT,TOR,EXIT
    
; nom: 2R@   ( S: -- d  R: d -- d )    
;   Copie un entier double de la pile des retours vers la pile des arguments.
; arguments:
;   d   Entier double sur R: qui sera copi� sur S:
; retourne:
;   d Copie de l'entier double en provenance de R:    
DEFWORD "2R@",3,,TWORFETCH ; S: -- x1 x2 R: x1 x2 -- x1 x2    
    .word RFROM,RFROM,RFETCH,OVER,TOR,ROT,TOR
    .word SWAP,EXIT
    

; nom: CELL+  ( addr -- addr' )    
;   Incr�mente l'adresse au sommet de la pile de la taille d'une cellule.
; arguments:
;   addr   Adresse. 
; retourne:
;   addr'  Adresse incr�ment�e de la taille d'une cellule.    
DEFCODE "CELL+",5,,CELLPLUS ; ( addr -- addr+CELL_SIZE )
    add #CELL_SIZE, T
    NEXT

; nom: CELLS  ( n1 -- n2 )    
;    Convertie l'entier n1 en taille occup�e par n1 cellules.
;    n2=n1*CELL_SIZE    
; arguments:
;    n1   Nombre de cellules.
; retourne:
;    n2   Espace occup� par n1 cellules.   
DEFCODE "CELLS",5,,CELLS ; ( n -- n*CELL_SIZE )
    mul.uu T,#CELL_SIZE,W0
    mov W0,T
    NEXT

    
; nom:  I  ( -- n )    
;   Utilis� � l'int�rieur d'une boucle DO ... LOOP ou +LOOP.    
;   Retourne le compteur de boucle.
; arguments:
;   aucun
; retourne:
;   n   Valeur actuelle de I.
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

; nom: L  ( -- n )    
;   Utilis� � l'int�rieur d'une boucle DO ... LOOP ou +LOOP.    
;   Retourne la limite de boucle.    
; arguments:
;   aucun
; retourne:
;   n   Valeur de LIMIT.    
DEFCODE "L",1,,DOL ; ( -- n )
    DPUSH
    mov LIMIT,T
    NEXT
    
; nom: J  ( -- n )    
;   Utilis� � l'int�rieur d'une boucle DO ... LOOP imbriqu�e dans une autre.    
;   Retourne le compteur de la boucle externe.
; arguments:
;   aucun
; retourne:
;   n   Valeur actuelle du compteur de la boucle externe.
DEFCODE "J",1,,DOJ  ; ( -- n ) R: limitJ indexJ
    DPUSH
    mov [RSP-2],T
    NEXT
  
; nom: UNLOOP ( R: n1 n2 -- )
;   Utilis� � l'interieur d'une boucle DO ... LOOP ou +LOOP.    
;   Restore les valeurs des variables I et LIMIT tels qu'elles �taient
;   avant l'ex�cution du dernier DO ou ?DO.    
;   Apr�s ex�cution  LIMIT=n1, I=n2
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "UNLOOP",6,,UNLOOP
    RPOP I
    RPOP LIMIT
    NEXT
    
; DESCRIPTION:
;   Les mots suivants servent � ex�cuter des fonctions � partir de l'information
;   qui se trouve sur la pile des arguments.
    
; nom: EXECUTE  ( i*x a-addr -- j*x )
;   Ex�cute le mot dont le CFA (Code Field Address) est au sommet de la pile.
; arguments:
;   i*x    Liste des arguments consomm�s par ce mot.
;   a-addr CFA du mot � ex�cuter.
; retourne:
;   j*x   Valeurs retourn�es par l'ex�cution du mot.
DEFCODE "EXECUTE",7,,EXECUTE
exec:
    mov T, WP ; CFA
    DPOP
    mov [WP++],W0  ; code address, WP=PFA
    goto W0

; nom: @XT  ( i*x a-addr -- j*x )
;   Ex�cution vectoris�e. 
;   Lit le contenu d'une adresse qui contient le CFA d'un mot et ex�cute ce mot.
;   : @XT @ EXECUTE ;    
; arguments:
;    i*x   Arguments attendus par la fonction qui sera ex�cut�e.    
;    a-addr Adresse qui contient le CFA du code � ex�cuter. Acc�s RAM + FLASH
; retourne:
;    j*x  Valeurs laiss�es par le mot ex�cut�.    
DEFCODE "@EXEC",5,,FETCHEXEC
    mov [T],T
    bra exec

; nom: VEXEC ( i*x a-addr n -- j*x )
;   Exc�cution vectoris� de la fonction 'n' dans la table 'a-addr'.
;   Le premier indice de la table est z�ro.    
;   : VEXEC CELLS + @ EXECUTE ;    
; arguments:
;    i*x   Arguments requis par la fonction � ex�cuter.
;    a-addr  Adresse de la table des CFA.
;    n     Index de l'�l�ment dans la table.
; retourne:
;    j*x   Valeurs retourn�es par la fonction ex�cut�e.    
DEFCODE "VEXEC",5,,VEXEC
    mul.uu T,#CELL_SIZE,W0
    DPOP
    add W0,T,T
    mov [T],T
    bra exec

; nom: CALL  ( i*x ud -- j*x )
;    Appel d'une routine �crite en code machine et r�sident en m�moire flash.
;    La routine doit se termin�e par une instruction machine RETURN.
;    Utilise l'instruction machine CALL.L sp�cifique aux PIC24E et dsPIC33E.
;    � utiliser avec pr�caution, la routine en code machine ne doit pas �craser
;    les registres utilis�s par le syst�me ForthEx {W8..W15}.
;    Le code machine doit avoir �t� pr�alablement flash�e en utilisant
;    le mot RAM>FLASH. Un outil externe doit-�tre utilis� pour g�n�rer le code
;    binaire de cette fonction. ForthEx n'a pas d'assembleur.    
; arguments:
;     i*x    Arguments consomm�s par la routine, d�pend de celle-ci.
;     ud     Adresse 24 bits de la routine.
; retourne:
;     j*x    Valeurs laiss�es sur la pile par la routine, d�pend de celle-ci.   
DEFCODE "CALL",4,,CALL 
    mov T, W1
    DPOP
    mov T, W0
    DPOP
    call.l W0
    NEXT
 
