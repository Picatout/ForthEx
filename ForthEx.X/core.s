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
; REF: http://www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt
; REF: http://www.bradrodriguez.com/papers/
; REF: http://www.camelforth.com/download.php?view.25
; REF: http://www.greenarraychips.com/home/documents/dpans94.pdf
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
;   Constante syst�me qui retourne l'adresse apr�s la fin de la m�moire RAM.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse fin de la RAM+1    
DEFCONST "RAMEND",6,,RAMEND,RAM_END
    
; nom: IMMED  ( -- n )
;   Constante syst�me qui retourne le bit F_IMMEDIATE. Ce bit inscrit dans le
;   premier octet du champ NFA et indique si le mot est immm�diat.
; arguments:
;   aucun
; retourne:
;   n     F_IMMED bit indicateur mot imm�diat.    
DEFCONST "IMMED",5,,IMMED,F_IMMED       ; drapeau mot imm�diat
    
; nom: HIDDEN   ( -- n )
;   Constante syst�me qui retourne le bit F_HIDDEN. Ce bit est inscrit dans le 
;   premier octet du champ NFA et indique si le mot est cach� � la recherche par FIND.
; arguments:
;   rien
; retourne:
;   n	F_HIDDEN bit indicateur de mot cach�.       
DEFCONST "HIDDEN",6,,HIDDEN,F_HIDDEN    ; drapeau mot cach�
    
; nom: NMARK  ( -- n )
;   Constante syst�me qui retourne le bit F_MARK. Ce bit est inscrit dans le
;   premier octet du champ NFA et sert la localis� ce champ. Ce bit est utilis�
;   par le mot CFA>NFA.    
DEFCONST "NMARK",5,,NMARK,F_MARK     ; drapeau marqueur utilis� par CFA>NFA
    
; nom: LENMASK   ( -- n )
;   Constante syst�me retourne le masque pour la longueur du nom dans les ent�tes
;   du dictionnaire. Ce masque sert � �liminer les bits F_NMARK,F_HIDDEN et F_IMMED
;   pour ne conserver que les bits qui indique la longueur du nom.
; arguments:
;   aucun
; retourne:
;   n   masque LEN_MASK    
DEFCONST "LENMASK",7,,LENMASK,LEN_MASK ; masque longueur nom

; nom: BL  ( -- n )
;   Constante syst�me qui retourne la valeur ASCII 32 (espace).
; arguments:
;   aucun
; retourne:
;   n    valeur ASCII 32  qui repr�sente l'espace.    
DEFCONST "BL",2,,BL,32                       ; caract�re espace

; nom: TIBSIZE   ( -- n )
;   Constante syst�me qui retourne la longueur du TIB (Transaction Input Buffer)
; arguments:
;   aucun
; retourne:
;   n    longueur du tampon TIB.    
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
    
; nom: PADSIZE   ( -- n )
;   Constante syst�me qui retourne la longueur du tampon PAD.
; arguments:
;   aucun
; retourne:
;   n    longueur du tampon PAD.    
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD

; nom: ULIMIT   ( -- a-addr )
;   Constante syst�me qui retourne l'adresse limite+1 de la m�moire r�servr�
;   au donn�es du dictionnaire utilisateur.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse fin dictionnaire+1    
DEFCONST "ULIMIT",6,,ULIMIT,EDS_BASE        ; limite espace dictionnaire

; nom: TRUE  ( -- f )
;   Constante syst�me qui retourne la valeur Bool�enne VRAI.
; arguments:
;   rien
; retourne:
;   f      indicateur Bool�en VRAI = -1    
DEFCONST "TRUE",4,,TRUE,-1 ; valeur bool�enne vrai
    
; nom: FALSE  ( -- f )
;   Constante syst�me qui retourne la valeur Bool�enne FAUX.
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
;   a-addr   Adresse du d�but espace utilisateur en m�moire RAM.    
DEFCONST "DP0",3,,DP0,DATA_BASE ; d�but espace utilisateur
   
; nom: CELL   ( -- u )    
;   Constante syst�me qui retourne la taille d'une cellule. 
;   Une cellule est le nom donn� � un �l�ment de la pile. 
;   Pour forthEx sur PIC24EP les entiers sont de 16 bits donc
;   la pile utilise des cellules de 2 octets.    
; arguments:
;   aucun
; retourne:
;   u   Grandeur d'une cellule.    
DEFCONST "CELL",4,,CELL,CELL_SIZE
 
; DESCRIPTION:
;  Cette section d�cris les diff�rentes variables utilis�es par le syst�me.
    
; nom: STATE  ( -- a-addr )
;   Variable syst�me qui indique si le syst�me est en mode interpr�tation ou compilation.
;   STATE=0 -> interpr�tation,  STATE=-1 -> compilation.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "STATE",5,,STATE 

; nom: DP ( -- a-addr )
;   Variable syst�me qui contient la position du pointeur de donn�e dans l'esapce utilisateur.
;   Lorsqu'une nouvelle d�finition est cr��e ou que de l'espace est r�serv� avec ALLOT ce
;   pointeur avance � la premi�re position libre.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "DP",2,,DP 

; nom: BASE  ( -- a-addr )
;   Variable syst�me qui contient la valeur de la base num�rique active.
;   Le contenu de cette variable est modifi� par les mots HEX et DECIMAL.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "BASE",4,,BASE     ; base num�rique

; nom: SYSLATEST  ( -- a-addr )
;   Variable syst�me qui contient le NFA du dernier mot d�fini dans le dictionnaire
;   syst�me en m�moire FLASH.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "SYSLATEST",9,,SYSLATEST ; t�te du dictionnaire en FLASH
    
; nom: LATEST  ( -- a-addr )
;   Variable syst�me qui contient le NFA du dernier mot d�fini par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "LATEST",6,,LATEST ; pointer dernier mot dictionnaire

; nom: PAD ( -- a-addr )
;   Variable syst�me qui contient l'adresse d'un tampon utilis� pour le travail
;   sur des cha�nes de caract�re. Ce tampon est utilis� entre autre pour la conversion
;   des entiers en cha�ine de caract�res pour l'affichage.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "PAD",3,,PAD       ; tampon de travail

; nom: TIB ( -- a-addr )
;   Variable syst�me contenant l'adresse du tampon de saisie des cha�nes � partir
;   du clavier. Ce tampon est utilis� par l'interpr�teur/compilateur en mode interactif.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "TIB",3,,TIB       ; tampon de saisie clavier
; nom: PASTE  ( -- a-addr )
;   Variable syst�me qui contient l'adresse d'un tampon qui contient une copie
;   de la derni�re cha�ne interpr�t�e en mode interactif. Permet de rappeller cette
;   cha�ne � l'�cran par la commande CTRL_V.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "PASTE",5,,PASTE   ; copie de TIB
    
; nom: >IN   ( -- a-addr )
;   Variable syst�me indique la position ou est rendue l'analyseur lexical dans
;   le traitement de la cha�ne d'entr�e. Cette variable est utilis�e par l'interpr�teur/compilateur.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER ">IN",3,,TOIN     ; pointeur position apr�s le dernier mot retourn� par WORD
    
; NOM: HP   ( -- a-addr )
;   Variable syst�me contenant la position du pointeur de conversion de nombres en cha�ne.
;   Cette variable est utilis�e lors de la conversion d'entiers en cha�ne de caract�res.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "HP",2,,HP       ; HOLD pointer
    
; nom: 'SOURCE	( -- a-addr )
;   Variable syst�me qui contient le pointeur du d�but du tampon utilis� par
;   l'interpr�teur/compilateur.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "'SOURCE",7,,TICKSOURCE ; tampon source pour l'�valuation
    
; nom: #SOURCE  ( -- a-addr )
;   Variable syst�me contenant la grandeur du tampon source.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "#SOURCE",7,,CNTSOURCE ; grandeur du tampon

; nom: RPBREAK   ( -- a-addr )
;   Variable syst�me utilis� par le mot BREAK pour sauvegarder la position
;   de RSP pour la r�entr�e.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "RPBREAK",7,,RPBREAK ; valeur de RSP apr�s l'appel de BREAK 
    
; nom: DBGEN  ( -- a-addr)
;   Variable syst�me qui contient un indicateur Bool�en d'activation/d�sactivation des breakpoints.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "DBGEN",5,,DBGEN ; activation d�sactivation break points
    
; nom: SYSCONS   ( -- a-addr )
;   Variable syst�me qui indique le p�riph�rique actuel utilis� par la console.
;   La console peut fonctionn� en mode LOCAL ou REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "SYSCONS",7,,SYSCONS 
    
 
; DESCRIPTION:
;  La machine Virtuelle ForthEx utilise 3 piles.
;  La pile des arguments sert a passer des arguments d'une fonction � une autre
;  ainsi qu'� retourner les valeurs des fonctions.
;  La pile des retours sert principalement a conserver la valeur du pointeur
;  d'instruction lors de l'appel de mots de haut-niveau afin de retourner au point
;  initial. Mais elle sert aussi � conserver des valeurs temporaires.
;  La 3i�me pile est utilis�e seulement par le compilateur pour conserver des adresses
;  de sauts qui doivent-�tre r�solues avant de terminer la compilation.
;  Les mots suivants servent � manipuler le contenu des 3 piles.

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
;   x   Valeur au somment des retours.
; retourne:
;   x   valeur qui �tait au somment de R: est maintenant ajout�e au sommet de S:.    
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
DEFCODE "DEPTH",5,,DEPTH ; ( -- +n1 )
    mov #pstack,W0
    sub DSP,W0,W0
    DPUSH
    lsr W0,T
    NEXT

; nom: PICK  ( i*x n --  i*x x )
;   Ins�re le ni�me �l�ment de la pile au sommet
;   l'argument n est retir� de la pile avant le comptage.
;   Si n==0 �quivaut � DUP 
;   Si n==1 �quivaut � OVER
; arguments:
;   i*x   Liste des �l�ments pr�sent sur la pile.
;   n     position de l'�l�ment recherch�, 0 �tant le sommet.
; retourne:
;   i*x   Liste originale des �l�ments.
;   x     copie de l'�l�ment en position n.    
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
;    x   Valeur au somment de R
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
;   n   Valeur du pointeur SP.    
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
;   Initialiste le pointeur de la pile des retours avec la valeur
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
;   Les adresses > 32767 acc�dent la m�moire FLASH dans l'interval {0..32766}.    
; arguments:
;   a-addr  Adresse de la variable.
; retourne:
;   n	Entier contenu � cette adresse.
DEFCODE "@",1,,FETCH 
    mov [T],T
    NEXT

; nom: C@  ( c-addr -- c )
;   Retourne l'octet contenu � l'adresse caract�re qui est au sommet de la pile.
;   Les adresses > 32767 acc�dent la m�moire FLASH dans l'interval {0..32767}.    
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
;   Les adresses > 32767 acc�s la m�moire EDS.    
; arguments:
;   a-addr   Adresse de la variable
; retourne:
;   d   Entier double, valeur de cette variable.    
DEFCODE "2@",2,,TWOFETCH 
    SET_EDS
    mov [T],W0 
    add #CELL_SIZE,T
    mov [T],T
    mov W0,[++DSP]
    RESET_EDS
    NEXT
    
; nom: TBL@  ( n a-addr -- n )    
;   Retourne l'�l�ment n d'un vecteur. Les valeurs d'indice d�bute � z�ro.
;   L'adresse de la table doit-�tre align�e sur une adresse paire.
;   Les adresses > 32767 sont en m�moire FLASH.    
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
;   Les adresses > 32767 acc�s la m�moire EDS.    
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
;   Acc�s RAM et EDS.    
; arguments:
;   n    Valeur � sauvegarder
;   a-addr Adresse de la variable.    
; retourne:
;   rien    
DEFCODE "!",1,,STORE 
    mov [DSP--],[T]
    DPOP
    NEXT

; nom: C!  ( c c-addr -- )    
;   Sauvegarde un caract�re dans une variable.
;   Acc�s RAM et EDS.
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
;   Acc�s RAM et EDS    
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
;    Convertie l'entier n1 en la taille occup�e par n1 cellules.
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
;   Retourne le compteur de boucle I.
; arguments:
;   aucun
; retourne:
;   n   Valeur actuelle de I.
DEFCODE "I",1,,DOI  ; ( -- n )
    DPUSH
    mov I, T
    NEXT

; nom: L  ( -- n )    
;   Retourne la limite de boucle LIMIT.    
; arguments:
;   aucun
; retourne:
;   n   Valeur de LIMIT.    
DEFCODE "L",1,,DOL ; ( -- n )
    DPUSH
    mov LIMIT,T
    NEXT
    
; nom: J  ( -- n )    
;   Retourne le compteur de la boucle qui englobe la boucle actuelle.
; arguments:
;   aucun
; retourne:
;   n   Valeur actuelle de J.
DEFCODE "J",1,,DOJ  ; ( -- n ) R: limitJ indexJ
    DPUSH
    mov [RSP-2],T
    NEXT
  
; nom: UNLOOP ( R: n1 n2 -- )
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
    
; nom: EXECUTE  ( i*x a-addr -- j*x )
;   Ex�cute le mot dont le Code Field Address est au sommet de la pile.
; arguments:
;   i*x    Liste des arguments consomm�s par ce mot.
;   a-addr CFA du mot � ex�cuter.
; retourne:
;   j*x   Valeurs retourn�es l'ex�cution du mot.
DEFCODE "EXECUTE",7,,EXECUTE
exec:
    mov T, WP ; CFA
    DPOP
    mov [WP++],W0  ; code address, WP=PFA
    goto W0

; nom: @XT  ( i*x a-addr -- j*x )
;   Ex�cution vectoris�e. 
;   Lit le contenu d'une adresse qui contient le CFA d'un mot et ex�cute ce mot.
;   : @XT  @ EXECUTE ;    
; arguments:
;    i*x   Arguments attendus par la fonction qui sera ex�cut�e.    
;    a-addr Adresse qui contient le CFA du code � ex�cuter. Acc�s RAM + FLASH
; retourne:
;    j*x  Valeurs laiss�es par le mot ex�cut�.    
DEFCODE "@EXEC",5,,FETCHEXEC
    mov [T],T
    bra exec

; nom: VEXEC ( i*x a-addr n -- j*x )
;   Exc�cute la fonction n dans une table contenant des CFA.
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
; arguments:
;     i*x    Arguments consomm�s par la routine, d�pend de celle-ci.
;     ud     adresse 24 bits de la routine.
; retourne:
;     j*x    Valeurs laiss�es sur la pile par la routine, d�pend de celle-ci.   
DEFCODE "CALL",4,,CALL 
    mov T, W1
    DPOP
    mov T, W0
    DPOP
    call.l W0
    NEXT
    
; nom: ALIGN  ( -- )    
;   Si la variable syst�me DP  (Data Pointer) pointe sur une adresse impaire, 
;   aligne DP sur l'adresse paire sup�rieure.
;   Met 0 dans l'octet saut�.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "ALIGN",5,,ALIGN ; ( -- )
    .word HERE,ODD,ZBRANCH,9f-$
    .word LIT,0,HERE,CSTORE,LIT,1,ALLOT
9:  .word EXIT    
 
; nom: ALIGNED  ( addr -- a-addr )  
;   Si l'adrsse au sommet de la pile est impaire, aligne cette adresse sur la valeur paire sup�rieure.
; arguments:
;   addr  Adresse � v�rifier.
; retourne:
;   a-addr Adresse align�e.  
DEFCODE "ALIGNED",7,,ALIGNED ; ( addr -- a-addr )
    btsc T,#0
    inc T,T
    NEXT

; nom: HERE   ( -- addr )    
;   Retourne la valeur de la variable syst�me DP (Data Pointer).
; arguments:
;   aucun
; retourne:
;   addr   Valeur de la variable DP.    
DEFWORD "HERE",4,,HERE
    .word DP,FETCH,EXIT

; nom: MOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc m�moire RAM en �vitant la propagation. La propagation se
;   produit lorsque les 2 r�gion se superposent et qu'un octet copi� est recopi�
;   parce qu'il a �cras� l'octet original dans la r�gion source.     
; arguments:
;   c-addr1  Adresse de la source.
;   c-addr2  Adresse de la destination.
;   u      Nombre d'octets � copier.   
; retourne:
;   rien    
DEFCODE "MOVE",4,,MOVE  ; ( addr1 addr2 u -- )
    mov [DSP-2],W0 ; source
    cp W0,[DSP]    
    bra ltu, move_dn ; source < dest
    bra move_up      ; source > dest
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  manipulation de caract�res
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

; nom: >CHAR  ( n -- c )    
;   V�rifie que n est dans l'intervalle ASCII 32..126, sinon remplace c par '_'  
; arguments:
;   n   Entier � convertir en caract�re.
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
 
; nom: CHARS   ( n1 -- n2 )    
;   Retourne l'espace occup�e par n caract�res en octets.
;   Puisque ForthEx utilise les caract�res ASCII et que ceux-ci occupe 1 seul octet
;   n1==n2.    
; arguments:
;   n1  Nombre de caract�res
; retourne:
;   n2  Espace requis pour n1 caract�res.    
DEFWORD "CHARS",5,,CHARS ; ( n1 -- n2 )
9:  .word LIT,CHAR_SIZE,STAR,EXIT
   
; nom: CHAR+   ( c-addr -- c-addr' )  
;   Incr�mente l'adresse de l'espace occup� par un caract�re.
; arguments:
;   c-addr   adresse align�e sur caract�re.
; retourne:
;   c-addr'  adresse align�e sur caract�re suivant.  
DEFWORD "CHAR+",5,,CHARPLUS ; ( addr -- addr' )  
    .word LIT,CHAR_SIZE,PLUS,EXIT
  
; nom: CHAR   ( cccc -- c )    
;   Recherche le prochain mot dans le flux d'entr�e et empile le premier caract�re de ce mot.
;   A la suite de cette op�ration la variable >IN pointe apr�s le mot.    
; arguments:
;    cccc   cha�ne de caract�re dans le flux d'entr�.
; retourne:
;    c      Le premier caract�re du mot extrait du flux d'entr�e.
DEFWORD "CHAR",4,,CHAR ; cccc ( -- c )
    .word BL,WORD,DUP,CFETCH,ZEROEQ
    .word QABORT
    .byte 16
    .ascii "missing caracter"
    .align 2
    .word ONEPLUS,CFETCH,EXIT

; nom: [CHAR]   ( ccccc -- )
;   Mot � n'utiliser qu'� l'int�rieur d'une d�finition.    
;   Mot compilant le premier caract�re du mot suivant dans le flux d'entr�.
;   Apr�s cette op�ration la variable >IN pointe apr�s le mot trouv�.
; arguments:
;   cccc  Cha�ne de caract�re dans le flux d'entr�.    
; retourne:
;   rien   Le caract�re es compil� dans la d�finition.    
DEFWORD "[CHAR]",6,F_IMMED,COMPILECHAR ; cccc 
    .word QCOMPILE
    .word CHAR,CFA_COMMA,LIT,COMMA,EXIT
    
; nom: FILL ( c-addr u c -- )    
;   Initialise un bloc m�moire RAM de dimension u avec le caract�re c.
;   Acc�s RAM et EDS.    
; arguments:
;   c-addr   Adresse du d�but de la zone RAM.
;   u        Nombre de caract�res � remplir.
;   c        Caract�re de remplissage.    
; retourne:
;   rien    
DEFCODE "FILL",4,,FILL ; ( c-addr u c -- )  for{0:(u-1)}-> m[T++]=c
;    SET_EDS
    mov T,W0 ; c
    mov [DSP--],W1 ; u
    mov [DSP--],W2 ; c-addr
    DPOP
    cp0 W1
    bra z, 1f
    dec W1,W1
    repeat W1
    mov.b W0,[W2++]
;1:  RESET_EDS
1:  NEXT
    
; nom: SOURCE  ( -- c-addr u ) 
;   Ce mot retourne l'adresse et la longueur du tampon qui est la source de
;   l'�valuation par l'interpr�teur/compilateur.    
; arguments:
;   rien
; retourne:
;   c-addr  Adresse d�but du tampon.
;   u       longueur du tampon.    
DEFCODE "'SOURCE",7,,TSOURCE ; ( -- c-addr u ) 
    DPUSH
    mov _TICKSOURCE,T
    DPUSH
    mov _CNTSOURCE,T
    NEXT

; nom: SOURCE!   ( c-addr u -- )    
;   sauvegarde les valeur de la SOURCE.
; arguments:
;   c-addr   Adresse du d�but du tampon qui doit-�tre �valu�.
;   u        Longueur du tampon.    
DEFCODE "SOURCE!",7,,SRCSTORE ; ( c-addr u -- )
    mov T,_CNTSOURCE
    DPOP
    mov T,_TICKSOURCE
    DPOP
    NEXT

; nom: WORDS   ( -- )  
;   Affiche sur la console la liste des mots du dictionnaire. Les mots dont l'attribut F_HIDDEN
;   est � 1 ne sont pas affich�s.
; arguments:
;   aucun
; retourne:
;   rien    
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
    
; nom: ADR>IN  ( c-addr -- ) 
;   Ajuste la variable  >IN � partir de la position laiss�e
;   par le dernier PARSE
; arguments:
;   c-addr  adresse du pointeur apr�s le dernier PARSE
; retourne:
;   rien
DEFWORD "ADR>IN",6,,ADRTOIN
    .word TSOURCE,ROT,ROT,MINUS,MIN,LIT,0,MAX
    .word TOIN,STORE,EXIT

; nom: PARSE   ( c -- c-addr u )    
;   Accumule les caract�res jusqu'au
;   prochain 'c'. Met � jour la variable >IN
;   PARSE filtre les caract�res suivants:
; arguments: 
;   c    caract�re d�limiteur
; retourne:
;   c-addr   adresse du premier caract�re de la cha�ne
;   u        longueur de la cha�ne.
DEFWORD "PARSE",5,,PARSE ; c -- c-addr u
    .word TSOURCE,TOIN,FETCH,SLASHSTRING ; c src' u'
    .word OVER,TOR,ROT,SCAN  ; src' u'
    .word OVER,SWAP,ZBRANCH, 1f-$ 
    .word ONEPLUS  ; char+
1:  .word ADRTOIN ; adr'
    .word RFROM,TUCK,MINUS,EXIT     
    
; nom: >COUNTED ( src n dest -- )   
;   copie une cha�ne dont l'adresse et la longueur sont fournies
;   en arguments vers une cha�ne compt�e dont l'adresse est fournie.
; arguments:    
;   src addresse cha�ne � copi�e
;   n longueur de la cha�ne
;   dest adresse destination
; retourne:
;   rien 
DEFWORD ">COUNTED",8,,TOCOUNTED 
    .word TWODUP,CSTORE,ONEPLUS,SWAP,MOVE,EXIT

; nom: PARSE-NAME    ( ccccc -- c-addr u ) 
;   Recherche le prochain mot dans le flux d'entr�e
;   Tout caract�re < 32 est consid�r� comme un espace
; arguments:
;   cccc    cha�ne de caract�res dans le flux d'entr�e.
; retourne:
;   c-addr  addresse premier caract�re.
;   u    longueur de la cha�ne.
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
4:  ; d�but du mot
    mov W1,T 
5:  inc W1,W1
    dec W2,W2
    bra z, 8f ; fin du buffer
    cp.b W0,[W1]
    bra ltu,5b
    bra 8f
6:  ; fin du buffer avant premier caract�re.
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
;   localise le prochain mot d�limit� par 'c'
;   la variable TOIN indique la position courante
;   le mot trouv� est copi� � la position DP
; arguments:
;   c   caract�re d�limiteur
; retourne:    
;   c-addr    adresse cha�ne compt�e.    
DEFWORD "WORD",4,,WORD 
    .word DUP,TSOURCE,TOIN,FETCH,SLASHSTRING ; c c c-addr' u'
    .word ROT,SKIP ; c c-addr' u'
    .word DROP,ADRTOIN,PARSE
    .word HERE,TOCOUNTED,HERE
    .word EXIT
  
; nom: FIND  ( c-addr -- c-addr 0 | cfa 1 | cfa -1 )   
;   Recherche un mot dans le dictionnaire
;   ne retourne pas les mots cach�s (attribut: F_HIDDEN).
; arguments:
;   c-addr  adresse de la cha�ne compt�e � rechercher.
; retourne: 
;    c-addr 0 si adresse non trouv�e
;    xt 1 trouv� mot imm�diat
;    xt -1 trouv� mot non-imm�diat
.equ  LFA, W1 ; link field address
.equ  NFA, W2 ; name field addrress
.equ  TARGET,W3 ;pointer cha�ne recherch�e
.equ  LEN, W4  ; longueur de la cha�ne recherch�e
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

  
; nom: ACCEPT ( c-addr +n1 -- +n2 ) 
;   Lecture d'une ligne de texte � partir de la console.
;   La cha�ne termin�e par touche la touche 'ENTER'.
;   Les touches de contr�les suivantes sont reconnues:
;   - VK_CR   termine la saisie
;   - CTRL_X  efface la ligne et place le curseur � gauche
;   - VK_BACK recule le curseur d'une position et efface le caract�re.
;   - CTRL_L  efface l'�cran au complet et plac le curseur dans le coin
;             sup�rieur gauche.
;   - CTRL_V  R�affiche la derni�re ligne saisie
;   - Les autres touches de contr�les sont ignor�es. 
; arguments:
;   c-addr   addresse du buffer
;   +n1      longueur du buffer
; retourne:
;   +n2      longueur de la cha�ne lue    
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
   
; nom: COUNT  ( c-addr1 -- c-addr2 u )  
;   Retourne la sp�cification de la cha�ne compt�e dont l'adresse est c-addr1.
; arguments:
;   c-addr1   Adresse d'une cha�ne de caract�res d�butant par un compteur.
; retourne:
;   c-addr2   Adresse du premier caract�re de la cha�ne.
;   u      longueur de la cha�ne.  
DEFWORD "COUNT",5,,COUNT ; ( c-addr1 -- c-addr2 u )
   .word DUP,CFETCH,TOR,ONEPLUS,RFROM,LENMASK,AND,EXIT
   
; nom: INTERPRET  ( c-addr u -- )   
;    �valuation d'un tampon contenant du texte source par l'interpr�teur/compilateur.
; arguments:
;   c-addr   Adresse du premier caract�re du tampon.
;   u   longueur du tampon.   
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

; nom: EVALUATE   ( i*x c-addr u -- j*x )      
;   �valuation d'un texte source. Le contenu de SOURCE est sauvegard�
;   et restaur� � la fin de cette �valuation.
; arguments:
;   i*x    Contenu initial de la pile des arguments avant l'�valulation de la cha�ne.
;   c-addr Adresse du premier caract�re de la cha�ne � �valuer.
;   u  Longueur de la cha�ne � �valuer.
; retourne:
;    j*x   Contenu final de la pile apr�s l'�valuation de la cha�ne.      
DEFWORD "EVALUATE",8,,EVAL ; ( i*x c-addr u -- j*x )
    .word TSOURCE,TOR,TOR ; sauvegarde source
    .word TOIN,FETCH,TOR,INTERPRET
    .word RFROM,TOIN,STORE,RFROM,RFROM,SRCSTORE 
    .word EXIT
    
; imprime le prompt et passe � la ligne suivante    
;DEFWORD "OK",2,,OK 
HEADLESS OK,HWORD  ; ( -- )
    .word GETX,LIT,3,PLUS,LIT,CPL,LESS,TBRANCH,1f-$,CR    
1:  .word SPACE, LIT, 'O', EMIT, LIT,'K',EMIT, EXIT    

; nom: ABORT ( -- )  
;   Vide la pile dstack et appel QUIT
;   Si une compilation est en cours annulle les effets de celle-ci  
; arguments:
;   aucun
; retourne:
;   rien  ne retourne pas mais branche sur QUIT  
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
  
; nom: ABORT"  ( cccc -- )     
;   Compile le runtime de ?ABORT
;   A  utiliser � l'int�rieur d'une d�finition seulement.  
DEFWORD "ABORT\"",6,F_IMMED,ABORTQUOTE ; (  --  )
    .word CFA_COMMA,QABORT,STRCOMPILE,EXIT
    
; nom: CLIP  ( n+ -- )    
;   Copie le contenu du tampon TIB dans le tampon PASTE.
;   Le contenu de PASTE est une cha�ne compt�e.
; arguments:
;	n+ nombre de caract�res de la cha�ne � copier.
; retourne:
;   rien    
DEFWORD "CLIP",4,,CLIP ; ( n+ -- )
    .word DUP,PASTE,FETCH,STORE
    .word TIB,FETCH,SWAP,PASTE,FETCH,ONEPLUS,SWAP,MOVE,EXIT

; nom: GETCLIP  ( -- n+ )    
;   Copie la cha�ne qui est dans le tampon PASTE dans le tampon TIB.
;   Retourne la longueur de la cha�ne.
; arguments:
;   aucun
; retourne:
;   n+ longueur de la ch�ine.    
DEFWORD "GETCLIP",7,,GETCLIP ; ( -- n+ )
    .word PASTE,FETCH,COUNT,SWAP,OVER 
    .word TIB,FETCH,SWAP,MOVE  
    .word EXIT
    
; boucle lecture/ex�cution/impression
HEADLESS REPL,HWORD    
;DEFWORD "REPL",4,F_HIDDEN,REPL ; ( -- )
1:  .word TIB,FETCH,DUP,LIT,CPL-1,ACCEPT,DUP,CLIP ; ( addr u )
    .word SPACE,INTERPRET
    .word STATE,FETCH,TBRANCH,2f-$
    .word OK
2:  .word CR
    .word BRANCH, 1b-$

; nom: QUIT   ( -- )    
;   Boucle de l'interpr�teur/compilateur. En d�pit de son nom cette boucle
;   ne quitte jamais. Il s'agit de l'interface avec l'utilisateur. 
;   A l'entr� la pile des retours est vid�e et la variable STATE est mise � 0.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "QUIT",4,,QUIT ; ( -- )
    .word LIT,0,STATE,STORE
    .word R0,RPSTORE
    .word REPL
    
; nom: (    ( ccccccc -- )    
;   Ce mot introduit un commentaire qui se termine  par ')'.
;   Il doit y avoir un espace de chaque c�t� de '(' car c'est un mot forth.
;   Il s'agit d'un mot imm�diat, il s'ex�cute donc m�me en mode compilation.    
; arguments:
;   aucun   Tous les caract�res dans le tampon d'entr� sont saut� jusqu'apr�s le '('.
; retourne:    
;   rien    
DEFWORD "(",1,F_IMMED,LPAREN ; parse ccccc)
    .word LIT,')',PARSE,TWODROP,EXIT

; nom: \    ( cccc -- )    
;   Ce mot introduit un commentaire qui se termine � la fin de la ligne.
;   Il s'agit d'un mot imm�diat, il s'�x�cute donc m�me en mode compilation.
; arguments:
;   aucun  Tous les caract�res dans le tampon d'entr� sont saut�s jusqu'� la fin de ligne.
; retourne:
;   rien    
DEFWORD "\\",1,F_IMMED,COMMENT ; ( -- )
    .word BLK,FETCH,ZBRANCH,2f-$
    .word CLIT,VK_CR,PARSE,TWODROP,EXIT
2:  .word TSOURCE,PLUS,ADRTOIN,EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   compilateur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; les 3 mots suivants servent � 
; passer d'un champ � l'autre dans
; l'ent�te du dictionnaire
   
; nom: NFA>LFA  ( a-addr1 -- a-addr2 )  
;   A partir de l'adresse NFA (Name Field Address) retourne
;   l'adresse LFA  (Link Field Address).  
; arguments:
;   a-addr1   adresse du champ NFA dans l'ent�te du dictionnaire.
; retourne:
;   a-addr2   adresse du champ LFA dans l'ent�te du dictionnaire.  
DEFWORD "NFA>LFA",7,,NFATOLFA ; ( nfa -- lfa )
    .word LIT,2,MINUS,EXIT
    
; nom: NFA>CFA  ( a-addr1 -- a-addr2 )    
;   A partir de l'adresse NFA (Name Field Address) retourne
;   l'adresse CFA (Code Field Address).    
; arguments:
;   a-addr1  Adresse du champ NFA dans l'ent�te du dictionnaire.
; retourne:
;   a-addr2  Adresse du CFA dans l'ent�te du dictionnaire.    
DEFWORD "NFA>CFA",7,,NFATOCFA ; ( nfa -- cfa )
    .word DUP,CFETCH,LENMASK,AND,PLUS,ONEPLUS,ALIGNED,EXIT
 
; nom: >BODY  ( a-addr1 -- a-addr2 )    
;   A partir du CFA (Code Field Address) retourne l'adresse PFA (Parameter Field Address)
; arguments:
;   a-addr1   Adresse du CFA dans l'ent�te du dictionnaire.
; retourne:
;   a-addr2   Adresse du PFA (Parameter Field Address).
DEFWORD ">BODY",5,,TOBODY ; ( cfa -- pfa )
    .word DUP,FETCH,LIT,FETCH_EXEC,EQUAL,ZBRANCH,1f-$
    .word CELLPLUS
1:  .word CELLPLUS,EXIT;

; nom: CFA>NFA   ( a-addr1 -- a-addr2 )    
;   Passe du champ CFA au champ NFA.
;   Il n'y a pas de lien arri�re entre le CFA et le NFA
;   Le bit F_MARK (bit 7) est utilis� pour marquer l'octet � la position NFA
;   Le CFA �tant imm�diatement apr�s le nom, il suffit de 
;   reculer octet par octet jusqu'� atteindre un octet avec le bit F_MARK==1
;   puisque les caract�res du nom sont tous < 128.
; arguments:
;   a-addr1   Adresse du CFA dans l'ent�te du dictionnaire.
; retourne:
;   a-addr2 Adresse du NFA dans l'ent�te du dictionnaire.
DEFWORD "CFA>NFA",7,,CFATONFA ; ( cfa -- nfa|0 )
    ; le champ nom a un maximum de 32 caract�res.
    .word LIT,32,LIT,0,DODO  
2:  .word LIT,CHAR_SIZE,MINUS,DUP,CFETCH,NMARK,ULESS,TBRANCH,3f-$
    .word UNLOOP,BRANCH,9f-$
3:  .word DOLOOP,2b-$
9:  .word EXIT

; nom: ?EMPTY  ( -- f )  
;   V�rifie si le dictionnaire utilisateur est vide.
; arguments:
;   aucun
; retourne:
;   f    Indicateur Bool�ean, retourne VRAI si dictionnaire utilisateur vide.  
DEFWORD "?EMPTY",6,,QEMPTY ; ( -- f)
    .word DP0,HERE,EQUAL,EXIT 
    
; nom: IMMEDIATE  ( -- )    
;   Met � 1 l'indicateur F_IMMED dans l'ent�te du dernier mot d�fini.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "IMMEDIATE",9,,IMMEDIATE ; ( -- )
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,IMMED,OR,SWAP,CSTORE
9:  .word EXIT
    
; nom: HIDE  ( -- )  
;   Met l'indicateur F_HIDDEN � 1 dans l'ent�te du dernier mot d�fini dans le dictionnaire.
; arguments:
;   aucun
; retourne:
;   rien    
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
  

; name: REVEAL  ( -- )
;   Met � 0 le bit F_HIDDEN dans l'ent�te du dictionnaire du dernier mot d�fini.  
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "REVEAL",6,,REVEAL ; ( -- )
    .word QEMPTY,TBRANCH,9f-$
    .word LATEST,FETCH,DUP,CFETCH,HIDDEN,INVERT,AND,SWAP,CSTORE
9:  .word EXIT

; nom: ALLOT  ( n -- )  
;   Allocation/rendition de m�moire dans le dictionnaire.
;   si n est n�gatif n octets seront rendus.
;   La variable DP est ajust�e en cons�quence.  
; arguements:
;   n   nombre d'octets
; retourne:
;   rien    modifie la valeur de DP.  
DEFWORD "ALLOT",5,,ALLOT ; ( n -- )
    .word DP,PLUSSTORE,EXIT

; nom: ,   ( x -- )    
;   Alloue une cellule pour x � la position DP et copie x dans cette cellule.
;   la Variable DP est incr�ment�e de la grandeur d'une cellule.
; arguments:
;    x   Valeur qui sera sauvegard�e dans l'espace de donn�e.    
; retourne:
;   rien   x est sauvegard� � position de DP et DP est incr�ment�.    
DEFWORD ",",1,,COMMA  ; ( x -- )
    .word HERE,STORE,LIT,CELL_SIZE,ALLOT
    .word EXIT
    
; nom: C,  ( c -- )    
;   Alloue l'espace n�cessaire pour enregistr� le caract�re c.
;   Le caract�re c est sauvegard� � la position DP et DP est incr�ment�.
; arguments:
;   c
; retourne:
;   rien  c est sauvegard� � la position DP et DP est incr�ment�.    
DEFWORD "C,",2,,CCOMMA ; ( c -- )    
    .word HERE,CSTORE,LIT,1,ALLOT
    .word EXIT
    
    
; nom: '   ( ccccc -- a-addr )    
;   Extrait le mot suivant du flux d'entr�e et le recherche dans le dictionnaire.
;   Retourne l'adresse du CFA de ce mot.
; arguments:
;    cccc   cha�ne de caract�re dans le flux d'entr�e qui repr�sente le mot recherch�.
; retourne:
;    a-addr  Adresse du CFA (Code Field Address) du mot recherch�.    
DEFWORD "'",1,,TICK ; ( <ccc> -- xt )
    .word BL,WORD,DUP,CFETCH,ZEROEQ,QNAME
    .word UPPER,FIND,ZBRANCH,5f-$
    .word BRANCH,9f-$
5:  .word COUNT,TYPE,SPACE,LIT,'?',EMIT,CR,ABORT    
9:  .word EXIT

; nom: [']   ( cccc -- )  
;   Version imm�diate de '  � utiliser � l'int�rieur d'une d�finition pour
;   compiler le CFA d'un mot existant dans le dictionnaire.
; arguments:
;   ccccc   Cha�ne de caract�re dans le flux d'entr�e qui repr�sente le mot recherch�.
; retourne:
;   rien    Le CFA est compil�.  
DEFWORD "[']",3,F_IMMED,COMPILETICK ; cccc 
    .word QCOMPILE
    .word TICK,CFA_COMMA,LIT,COMMA,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  les 4 mots suivants
;  sont utilis�s pour r�soudre
;  les adresses de sauts.    
;  les sauts sont des relatifs.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   Il s'agit d'un mot imm�diat � utiliser � l'int�rieur d'une d�finition    
;   empile la position actuelle de DP
;   cette adresse sera la cible
;   d'un branchement arri�re    
HEADLESS MARKADDR,HWORD    
;DEFWORD "<MARK",5,F_IMMED,MARKADDR ; ( -- a )
   .word HERE, EXIT

; compile l'adresse d'un branchement arri�re
; compl�ment de '<MARK'    
; le branchement est relatif � la position
; actuelle de DP    
HEADLESS BACKJUMP,HWORD   
;DEFWORD "<RESOLVE",8,F_IMMED,BACKJUMP ; ( a -- )    
    .word HERE,MINUS,COMMA, EXIT
    
;reserve un espace pour la cible d'un branchement avant qui
; sera r�solu ult�rieurement. 
HEADLESS MARKSLOT,HWORD    
;DEFWORD ">MARK",5,F_IMMED,MARKSLOT ; ( -- slot )
    .word HERE,LIT,0,COMMA,EXIT
    
; compile l'adresse cible d'un branchement avant
; compl�ment de '>MARK'    
; l'espace r�serv� pour la cible est indiqu�e
; au sommet de la pile
HEADLESS FOREJUMP,HWORD    
;DEFWORD ">RESOLVE",8,F_IMMED,FOREJUMP ; ( -- slot )
    .word DUP,HERE,SWAP,MINUS,SWAP,STORE,EXIT
    
;compile un cfa fourni en literal
HEADLESS CFA_COMMA,HWORD    
;DEFWORD "CFA,",4,F_IMMED,CFA_COMMA  ; ( -- )
  .word RFROM,DUP,FETCH,COMMA,CELLPLUS,TOR,EXIT

; nom: [  ( -- )
;   Mot imm�diat.  
;   Passe en mode interpr�tation en mettant la variable syst�me STATE � z�ro.
; arguments:
;   aucun
; retourne:
;   rien   Modifie la valeur de la variable syst�me STATE.  
DEFWORD "[",1,F_IMMED,LBRACKET ; ( -- )
    .word LIT,0,STATE,STORE
    .word EXIT
  
; nom: ]  ( -- ) 
;   Mot imm�diat.    
;   Passe en mode compilation en mettant la variable syt�me STATE � -1
; arguments:
;   aucun
; retourne:
;   rien   Modifie la valeur de la variable syst�me STATE.  
DEFWORD "]",1,F_IMMED,RBRACKET ; ( -- )
    .word LIT,-1,STATE,STORE
    .word EXIT

; nom: ?WORD  ( cccc  -- c-addr 0 | cfa 1 | cfa -1 )    
;   Analyse le flux d'entr� pour en extraire le prochain mot.
;   Recherche ce mot dans le dictionnaire.    
;   Avorte si le nom n'est pas trouv� dans le dictionnaire.
;   Retourne le CFA du nom et un indicateur.
; arguments:
;   ccccc    mot extrait du flux d'entr�e.
; retourne:
;    a-addr 1   le CFA du mot et 1 si c'est mot imm�diat.
;    a-addr -1  le CFA du mot et -1 si le mot n'est pas imm�diat.    
DEFWORD "?WORD",5,,QWORD ; ( -- c-addr 0 | cfa 1 | cfa -1 )
   .word BL,WORD,UPPER,FIND,QDUP,ZBRANCH,2f-$,EXIT
2: .word COUNT,TYPE,LIT,'?',EMIT,ABORT
  
; nom: POSTPONE   ( ccccc -- ) 
;   Mot imm�diat � utiliser dans une d�finition. 
;   Diff�re la compilation du mot qui suis dans le flux d'entr�e.
; arguments:
;   ccccc   Mot extrait du flux d'entr�e.
; retourne:
;   rien     
DEFWORD "POSTPONE",8,F_IMMED,POSTONE ; ( <ccc> -- )
    .word QCOMPILE ,QWORD
    .word ZEROGT,TBRANCH,3f-$
  ; mot non immm�diat
    .word CFA_COMMA,LIT,COMMA,CFA_COMMA,COMMA,EXIT
  ; mot imm�diat  
3:  .word COMMA    
    .word EXIT    

; nom: LITERAL  ( x -- )
;   Mot imm�diat qui compile la s�mantique runtime d'un entier. Il n'a d'effet 
;   qu'en mode compilation. Dans ce cas la valeur sommet de la pile est compil�e
;   avec la s�mantique runtime qui empile un entier.
; arguments:
;   x  Valeur au sommet de la pile des arguments. Cette valeur est consomm�e seulement en mode compilation.
; retourne:
;   rien    x reste au sommet de la pile en mode interpr�tation.    
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

; nom: S"   ( ccccc -- )  runtime S: c-addr u 
;   Mot imm�diat � n'utiliser qu'� l'int�rieur d'une d�finition.    
;   Lecture d'une cha�ne lit�rale dans le flux d'entr�e et compilation
;   de cette cha�ne dans l'espace de donn�e.    
;   La s�mentique rutime consiste � empiler l'adresse du premier caract�re de la
;   cha�ne et la longueur de la cha�ne.    
; arguments:
;   ccccc   Cha�ne termin�e par " dans le flux d'entr�e.
; retourne:
;   rien    
DEFWORD "S\"",2,F_IMMED,SQUOTE ; ccccc" runtime: ( -- | c-addr u)
    .word QCOMPILE
    .word CFA_COMMA,STRQUOTE,STRCOMPILE,EXIT
    
; nom: C"   ( ccccc --  )  runtime S:  c-addr
;   Mot imm�diat � n'utiliser qu'� l'int�rieur d'une d�finition.
;   Lecture d'une cha�ne lit�rale dans le flux d'entr�e et compilation de cette
;   cha�ne dans l'espace de donn�e.
;   La s�mantique runtime consiste � compiler l'adresse de la cha�ne compt�e.
; arguments:
;   ccccc  Cha�ne de caract�res termin�e par "  dans le flux d'entr�e.
; retourne:
;   rien    En runtime retourne empile l'adresse du descripteur de la cha�ne.    
DEFWORD "C\"",2,F_IMMED,CQUOTE ; ccccc" runtime ( -- c-addr )
    .word QCOMPILE
    .word CFA_COMMA,RT_CQUOTE,STRCOMPILE,EXIT
    
; nom: ."   ( ccccc -- )
;   Mot imm�diat.    
;   Interpr�tation: imprime la cha�ne lit�rale qui suis dans le flux d'entr�e.
;   En compilation: compile la cha�ne et la s�mantique permet d'imprimer cette
;   cha�ne lors de l'ex�cution du mot en cour de d�finition.
; arguments:
;   ccccc    Cha�ne termin�e par "  dans le flux d'entr�e.
; retourne:
;   rien         
DEFWORD ".\"",2,F_IMMED,DOTQUOTE ; ( -- )
    .word STATE,FETCH,ZBRANCH,4f-$
    .word CFA_COMMA,DOTSTR,STRCOMPILE,EXIT
4:  .word SLIT,TYPE,EXIT  
    
; nom: RECURSE  ( -- )
;   Mot imm�diat � n'utiliser qu'� l'int�rieur d'une d�finition.
;   Compile un appel r�cursif du mot en cour de d�finition.
; arguments:
;   aucun
; retourne:
;   rien  
DEFWORD "RECURSE",7,F_IMMED,RECURSE ; ( -- )
    .word QCOMPILE,LATEST,FETCH,NFATOCFA,COMMA,EXIT 
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots contr�lant le flux
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: DO  ( n1 n2 -- )
;   Mot imm�diat qui ne peut-�tre utilis� qu'� l'int�rieur d'une d�finition.    
;   D�bute une boucle avec compteur. Le valeur du compteur de boucle est incr�ment�e
;   � la fin de la boucle et compar�e avec la limite. La boucle se termine lorsque
;   le compteur atteind ou d�passe la limite. La boucle s'ex�cute au moins 1 fois.    
; arguments:
;    n1   Valeur limite du compteur de boucle.
;    n2   Valeur initiale du compteur de boucle.
; retourne:
;    rien    
DEFWORD "DO",2,F_IMMED,DO 
    .word QCOMPILE,CFA_COMMA,DODO
    .word HERE,TOCSTK,LIT,0,TOCSTK,EXIT

; nom: ?DO runtime ( n1 n2 -- )
;   Mot imm�diat qui ne peut-�tre utilis� qu'� l'int�rieur d'une d�finition.    
;   D�bute une boucle avec compteur. Cependant contrairement � DO la boucle
;   Ne sera pas exc�t�e si n2==n1. Le compteur de boucle est incr�ment� � la fin
;   de la boucle et le contr�le de limite est affectu� apr�s l'incr�mentation.    
; arguments:
;     n1     limite
;     n2     valeur initiale du compteur de boucle.
; retourne:
;   rien    
DEFWORD "?DO",3,F_IMMED,QDO 
    .word QCOMPILE,CFA_COMMA,DOQDO
    .word HERE,LIT,2*CELL_SIZE,PLUS,TOCSTK,LIT,0,TOCSTK
    .word CFA_COMMA,BRANCH,HERE,TOCSTK,EXIT
    
; nom: LEAVE  runtime ( -- )
;   Mot imm�diat qui ne peut-�tre utilis� qu'� l'int�rieur d'une d�finition.
;   LEAVE est utilis� � l'int�rieur des boucles avec compteur pour interrompre
;   pr�matur�ment la boucle.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LEAVE",5,F_IMMED,LEAVE 
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

; nom: LOOP  ( -- )
;   Mot imm�diat � n'utiliser qu'a l'int�rieur d'une d�finition.  
;   Derni�re instruction d'une boucle avec compteur.
;   Le compteur est incr�ment� et ensuite compar� � la valeur limite.
;   En cas d'�galit� le boucle est termin�e.
; arguments:
;    rien    
; retourne:
;   rien  
DEFWORD "LOOP",4,F_IMMED,LOOP ; ( -- )
    .word QCOMPILE,CFA_COMMA,DOLOOP,FIXLEAVE,EXIT
    
; nom: +LOOP   ( n -- )
;   Mot imm�diat � n'utiliser qu'a l'int�rieur d'une d�finition.  
;   Derni�re instruction de la boucle. La valeur n est ajout�e au compteur.
;   Ensuite cette valeur est compar�e � la limite et termine la boucle si 
;   la limite est atteinte ou d�pass�e.    
; arguments:
;    n   Ajoute cette valeur � la variable de contr�le de la boucle. Si I passe LIMIT quitte la boucle.    
; retourne:
;   rien  
DEFWORD "+LOOP",5,F_IMMED,PLUSLOOP ; ( -- )
    .word QCOMPILE,CFA_COMMA,DOPLOOP,FIXLEAVE,EXIT

; nom: BEGIN  ( -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   D�bute une boucle qui se termine par AGAIN, REPEAT ou UNTIL 
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "BEGIN",5,F_IMMED,BEGIN ; ( -- a )
    .word QCOMPILE, MARKADDR, EXIT

; nom: AGAIN   ( -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Effectue un branchement inconditionnel au d�but de la boucle.
;   Une boucle cr��e avec BEGIN ... AGAIN ne peut-�tre interrompue que
;   par ABORT ou ABORT".    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "AGAIN",5,F_IMMED,AGAIN ; ( a -- )
    .word QCOMPILE,CFA_COMMA,BRANCH,BACKJUMP,EXIT

; nom: UNTIL  compilation ( n -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Compile la fin d'une boucle conditionnelle. Termine la boucle si n est VRAI.
; arguments:
;   n  Valeur qui contr�le la boucle. La boucle est termin�e si n<>0.
; retourne:
;   rien    
DEFWORD "UNTIL",5,F_IMMED,UNTIL ; ( a -- )
    .word QCOMPILE,CFA_COMMA,ZBRANCH,BACKJUMP,EXIT

; nom: REPEAT  ( -- )    
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   S'Utilise avec une structure de boucle BEGIN ... WHILE ... REPEAT
;   Comme AGAIN effectue un branchement inconditionnel au d�but de la boucle.
;   Cependant au moins un WHILE doit-�tre pr�sent � l'int�rieur de la boucle
;   car c'est le WHILE qui contr�le la sortie de boucle.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "REPEAT",6,F_IMMED,REPEAT ; ( slot a -- )
    .word QCOMPILE,CFA_COMMA,BRANCH,BACKJUMP,FOREJUMP,EXIT

; nom: WHILE  ( n -- )    
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Utilis� � l'int�rieur d'une boucle BEGIN ... REPEAT, contr�le la sortie
;   de boucle. Tant que la valeur n au sommet de la pile est VRAI l'ex�cution
;   de la boucle se r�p�te au complet lorsque REPEAT est atteint.
; arguments:
;   n   Contr�le la sortie de boucle. Si n==0 il y a sortie de boucle.
; retourne:
;   rien    
DEFWORD "WHILE",5,F_IMMED,WHILE ;  ( a -- slot a)   
    .word QCOMPILE,CFA_COMMA,ZBRANCH,MARKSLOT,SWAP,EXIT
    
; nom: IF  ( n -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Ex�cution du code qui suit le IF si et seulement is n<>0.
; arguments:
;   n   Valeur consomm�e par IF, si n<>0 les instructions apr�s entre IF et ELSE ou THEN sont ex�cut�es.
; retourne:
;   rien    
DEFWORD "IF",2,F_IMMED,IIF ; ( n --  )
    .word QCOMPILE,CFA_COMMA,ZBRANCH,MARKSLOT,EXIT

; nom: THEN  ( -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Termine le bloc d'instruction qui d�bute apr�s un IF ou un ELSE.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "THEN",4,F_IMMED,THEN ; ( slot -- )
    .word QCOMPILE,FOREJUMP,EXIT
    
; nom: ELSE  ( -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Termine le bloc d'instruction qui d�bute apr�s un IF.
;   Les instructions entre le ELSE et le THEN qui suit sont exc�ut�e si la valeur n contr�l�e
;   par le IF est FAUSSE.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "ELSE",4,F_IMMED,ELSE ; ( slot1 -- slot2 )     
    .word QCOMPILE,CFA_COMMA,BRANCH,MARKSLOT,SWAP,THEN,EXIT

; nom: CASE  ( -- )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   Branchement conditionnel multiple par comparaison de la valeur au sommet  
;   de la pile des arguments avec d'autres valeurs de test. 
;   exemple:
;     : x
;     CASE 
;     1  OF ... ENDOF
;     2  OF ... ENDOF
;     ... ( instructions par d�faut ce bloc est optionnel.)
;     ENDCASE
;     3 x     
;   Dans cette exemple on d�finit le mot x et ensuite on l'ex�cute en lui passant la 
;   valeur 3 en arguments. Chaque valeur qui pr�c�de un OF est compar�e avec 3 et 
;   s'il y a �galit� le bloc entre OF et ENDOF est ex�cut�. Seul le premier test
;   qui r�pond au crit�re d'�galit� est ex�cut�. Si tous les test �chous et qu'il
;   y a un bloc d'instruction entre le derner ENDOF et le ENDCASE c'est ce bloc
;   qui est ex�cut�.   
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "CASE",4,F_IMMED,CASE ; ( -- case-sys )
    .word QCOMPILE,LIT,0,EXIT ; marque la fin de la liste des fixup

; nom: OF  ( x1 x2  -- |x1 )
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   S'utilise � l'int�rieur d'une structure CASE ... ENDCASE    
;   V�rifie si x1==x2 En cas d'�galit� les 2 valeurs sont consomm�e et 
;   le bloc d'instruction qui suis le OF jusqu'au ENDOF est ex�cut�.    
;   Si la condition d'�galit� n'est pas v�rifi�e la valeur x1 est conserv�e
;   et l'ex�cution se poursuis apr�s le prochain ENDOF.    
; arguments:
;   x1   Valeur de contr�le du case.
;   x2   Valeur de test du OF ... ENDOF    
; retourne:
;   |x1  x1 n'est pas consomm� si la condition d'�galit� n'est pas rencontr�e.      
DEFWORD "OF",2,F_IMMED,OF ; ( x1 x2 -- |x1 )    
    .word QCOMPILE,CFA_COMMA,OVER,CFA_COMMA,EQUAL,CFA_COMMA,ZBRANCH
    .word MARKSLOT,EXIT
 
; nom: ENDOF  ( -- )   
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   S'utilise � l'int�rieur d'une structure  CASE ... ENDCASE    
;   Termine un bloc d'instruction introduit par le mot OF
;   ENDOF branche apr�s le ENDCASE    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "ENDOF",5,F_IMMED,ENDOF ; ( slot 1 -- slot2 )
    .word QCOMPILE,CFA_COMMA,BRANCH,MARKSLOT,SWAP,FOREJUMP,EXIT
    
; nom: ENDCASE ( x -- )    
;   Mot imm�diat � utiliser seulement � l'int�rieur d'une d�finition.
;   S'utilise pour terminer une structure CASE ... ENDCASE.
;   ENDCASE n'est ex�cut� que si aucun bloc OF ... ENDOF n'a �t� ex�cut�.
;   Dans ce cas la valeur de contr�le qui est rest�e sur la pile est jet�.    
; arguments:
;   x   Valeur de contr�le qui est rest�e sur la pile.
; retourne:
;   rien    
DEFWORD "ENDCASE",7,F_IMMED,ENDCASE ; ( case-sys -- )    
    .word QCOMPILE
1:  .word QDUP,ZBRANCH,8f-$
    .word FOREJUMP,BRANCH,1b-$
8:  .word CFA_COMMA,DROP,EXIT
  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; certains mots ne peuvent-�tre utilis�s
; que par le compilateur
  
; nom: ?COMPILE  ( -- )
;   Mot imm�diat.
;   V�rifie la valeur de la variable syst�me STATE et si cette valeur est 0.
;   appelle ABORT" avec le message "compile only word". Ce mot d�bute la d�finition
;   de tous les mots qui ne doivent-�tre utilis�s qu'en mode compilation.  
; arguments:
;   aucun
; retourne:
;   rien  
DEFWORD "?COMPILE",8,F_IMMED,QCOMPILE ; ( -- )
    .word STATE,FETCH,ZEROEQ,TBRANCH,1f-$,EXIT
1:  .word CR,HERE,COUNT,TYPE,SPACE
2:  .word LIT,-1 
    .word QABORT
    .byte 17
    .ascii "compile only word"
    .align 2
    .word EXIT
    
; nom: ?NAME  ( f -- )    
;   Si f==0 appelle ABORT" avec le message "name missing" 
; arguments:
;    f   Indicateur Bool�en, si VRAI ABORT" name missing"
; retourne:
;   rien    
DEFWORD "?NAME",5,,QNAME ; ( i*x f -- | i*x )
    .word QABORT
    .byte 12
    .ascii "name missing"
    .align 2
    .word EXIT

; nom: :NONAME  ( -- a-addr )
;   Cr� une d�finition sans nom dans l'espace de donn�e.
;   et laisse son CFA sur la pile des arguments.
;   Met la variable STATE en mode compilation.
;   Le CFA de cette d�finition peut par exemple est assign�
;   � un mot cr�� avec DEFER.
;   exemple:
;   DEFER  p2 
;   :noname  DUP * ;
;   ' p2 DEFER! / maintenant p2 utilise le code de d�fini par :noname.    
; arguments:
;   aucun
; retourne:
;   a-addr  CFA de la nouvelle d�finition.
DEFWORD ":NONAME",7,,COLON_NO_NAME ; ( S: -- xt )
    .word HERE,CFA_COMMA,ENTER,RBRACKET,EXIT
 
HEADLESS EXITCOMMA,HWORD    
;DEFWORD "EXIT,",5,F_IMMED,EXITCOMMA ; ( -- )
    .word  QCOMPILE,CFA_COMMA,EXIT,EXIT

; name: HEADER ( cccc -- )    
;   Cr� une nouvelle ent�te dans le dictionnaire avec le nom qui suis dans le flux d'entr�e.
;   Apr�s l'ex�cution de ce mot HERE retourne l'adresse du CFA de ce mot.
; arguments:
;    cccc  Cha�ne de caract�re dans le flux d'entr�e qui repr�sente ne nom du mot cr��.
; retourne:
;   rien    
DEFWORD "HEADER",6,,HEADER ; ( -- )
    .word LATEST,DUP,FETCH,COMMA,HERE
    .word SWAP,STORE
    .word BL,WORD,UPPER,CFETCH,DUP,ZEROEQ,QNAME
    .word ONEPLUS,ALLOT,ALIGN,NAMEMARK,HIDE,EXIT
 
; nom: FORGET  ( cccc -- )    
;   Extrait du flux d'entr�e le mot suivant et supprime du dictionnaire ce mot
;   ainsi que tous ceux qui ont �t� d�finis apr�s lui.
;   Les mots syst�me d�finis en m�moire FLASH ne peuvent-�tr supprim�s.
; arguments:
;   cccc   Mot suivant dans le flux d'entr�e.
; arguments:
;   rien    
DEFWORD "FORGET",6,,FORGET ; cccc
    .word TICK,CFATONFA,NFATOLFA,DUP,LIT,0x8000,UGREATER
    .word QABORT
    .byte  26
    .ascii "Can't forget word in FLASH"
    .align 2
    .word DUP,DP,STORE,FETCH,LATEST,STORE,EXIT    

; nom: MARKER  ( cccc -- )    
;   Extrait du flux d'entr�e le mot suivant et cr� un mot portant ce nom
;   dans le dictionnaire. Lorsque ce mot est invoqu� il se suprime lui-m�me
;   ainsi que tous les mots qui ont �t� d�finis apr�s lui.    
; arguments:
;   cccc   Mot suivant dans le flux d'entr�e.
; arguments:
;   rien    
DEFWORD "MARKER",6,,MARKER ; cccc
    .word HEADER,HERE,CFA_COMMA,ENTER,CFA_COMMA,LIT,COMMA
    .word CFA_COMMA,RT_MARKER,EXITCOMMA,REVEAL,EXIT

; partie runtime de MARKER    
HEADLESS  RT_MARKER,HWORD   
    .word CFATONFA,NFATOLFA,DUP,DP,STORE,FETCH,LATEST,STORE
    .word EXIT

; nom: :   ( cccc -- )    
;   Extrait le mot suivant du flux d'entr�e et cr� une nouvelle ent�te dans
;   le dictionnaire qui porte ce nom. Ce mot introduit une d�finition de haut niveau.
;   Modifie la variable syst�me STATE pour passer en mode compilation.    
; arguments:
;   cccc  Mot suivant dans le flux d'entr�e.
; retourne:
;   rien    
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

;   mot vide, ne fait rien.
HEADLESS NOP,HWORD 
    .word EXIT
     
; nom: CREATE  ( cccc -- )     
;   Extrait le mot suivant du flux d'entr�e et cr� une nouvelle ent�te dans le dictionnaire
;   Lorsque ce nouveau mot est ex�cut� il retourne l'adresse PFA. Cependant la s�mantique
;   du mot peut-�tre �tendue en utilisant le mot DOES>.    
; exemple:     
;       / le mot VECTOR sert � cr�er des tableaux de n �l�ments.    
;	: VECTOR  ( n  -- )
;           CREATE CELLS ALLOT DOES> CELLS PLUS ;     
;       / utilisation du mot VECTOR pour cr�er le tableau V1 de 5 �l�ments.
;       5 VECTOR V1
;       / Met la valeur 35 dans l'�l�ment d'indice 2 de V1
;       35 2 V1 !    
; arguments:
;   cccc  Mot suivant dans le flux d'entr�e.
; retourne:
;   rien    
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
    
; nom: DOES>  ( -- )
;   Mot imm�diat qui ne peut-�tre utilis� qu'� l'int�rieur d'une d�finition.    
;   Ce mot permet d�finir l'action d'un mot cr�� avec CREATE. Surtout utile
;   pour d�finir des mots compilants. U mot compilant est un mot qui sert �
;   cr�er une classe de mots. Par exemples les mots VARIABLE et CONSTANT sont
;   des mots compilants.    
;   Le concept de DOES> est un des plus complexe du langage forth. Un article
;   sera donc consacr� � son utilisation.    
; arguments:
;   aucun
; retourne:
;   rien  
DEFWORD "DOES>",5,F_IMMED,DOESTO  ; ( -- )
    .word CFA_COMMA,RT_DOES,HERE,LIT,2,CELLS,PLUS,COMMA
    .word EXITCOMMA,CFA_COMMA,ENTER
    .word EXIT

; nom: ;  ( -- )    
;   Termine une d�finition d�but�e par ":".
;   Modifie la valeur de la variable STATE pour passer en mode interpr�tation.
; arguments:
;   aucun
; retourne:
;   rien  
DEFWORD ";",1,F_IMMED,SEMICOLON  ; ( -- ) 
    .word QCOMPILE
    .word EXITCOMMA
    .word REVEAL
    .word LBRACKET,EXIT
    
    
; nom: VARIABLE  ( cccc -- )    
;   Mot compilant qui sert � cr�er des variables dans le dictionnaire.
;   Extrait le mot suivant du flux d'entr�e et utilise ce mot comme nom
;   de la nouvelle variable. Les variables sont initialis�es � 0.
; arguments:
;   cccc   Prochain mot dans le flux d'entr�e. Nom de la variable.
; retourne:
;   rien    
DEFWORD "VARIABLE",8,,VARIABLE ; ()
    .word CREATE,LIT,0,COMMA,EXIT

; nom: CONSTANT  ( cccc  n -- )    
;   Mot compilant qui sert � cr�er des constantes dans le dictionnaire.
;   Extrait le mot suivant du flux d'entr�e et utilise ce mot comme nom
;   de la nouvelle constante. La constante  initialis�e avec la valeur
;   qui est au sommet de la pile des arguments au moment de sa cr�ation.    
; arguments:
;   cccc   Prochain mot dans le flux d'entr�e. Nom de la constante.
;   n      Valeur qui sera assign�e � cette constante.    
; retourne:
;   rien    
DEFWORD "CONSTANT",8,,CONSTANT ; ()
    .word HEADER,REVEAL,LIT,DOCONST,COMMA,COMMA,EXIT
   
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots du core �tendu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;action par d�faut d'un mot d�fini avec DEFER   
HEADLESS NOINIT,HWORD
;DEFWORD "(NOINIT)",8,F_HIDDEN,NOINIT ; ( -- )
    .word DOTSTR
    .byte  26
    .ascii "Uninitialized defered word"
    .align 2
    .word CR,ABORT
    
HEADLESS DEFEREXEC,HWORD
     .word FETCH,EXECUTE,EXIT
     
; nom: DEFER ( cccc -- )     
;   Mot compilant.
;   Cr� un nouveau mot dont l'action ne sera d�fini ult�rieurement.
;   Cependant ce mot poss�de une action par d�faut qui consiste � affich�
;   le message "Uninitialized defered word"     
; arguments:
;   cccc  Prochain mot dans le flux d'entr�e. Nom du nouveau mot.
; retourne:
;   rien     
DEFWORD "DEFER",5,,DEFER ; cccc ( -- )
    .word CREATE,CFA_COMMA,NOINIT
    .word RT_DOES,DEFEREXEC,EXIT

; nom: DEFER!  ( a-addr1 a-addr2 -- )     
;   Initialise une action �  un mot d�fini avec DEFER.
;   exemple:
;   DEFER p2  / le mot p2 est cr�� mais n'a pas d'action d�fini.
;   :noname  dup * ; / ( -- a-addr1 )  un mot sans nom viens d'�tre cr��.
;   ' p2 DEFER!  / ' p2 retourne le xt de p2 et DEFER! affecte a-addr1 � a-addr2
;   2 p2  4 ok  / maintenant lorsque p2 est utilis� retourne le carr� d'un entier.  
;    
; arguments:    
;  a-addr1  CFA de l'action que le mot doit ex�cuter.
;  a-addr2  CFA du mot diff�r�.
; retourne:
;   rien    
DEFWORD "DEFER!",6,,DEFERSTORE ;  ( xt1 xt2 -- )
    .word TOBODY,STORE,EXIT

; nom: DEFER@  ( a-addr1 -- a-addr2 )    
;   Empile le CFA interpr�t� par un mot d�fini avec DEFER dont le CFA est
;   au sommet de la pile des arguments.    
; arguments:
;   a-addr1 CFA du mot diff�r� dont on veut obtenir l'action.
; retourne:    
;   a-addr2  CFA de l'action  ex�cut�e par le mot diff�r�.
DEFWORD "DEFER@",6,,DEFERFETCH ; ( xt1 -- xt2 )
    .word TOBODY,FETCH,EXIT
 
; nom: IS    ( cccc a-addr -- )     
;   Extrait le prochain mot du flux d'entr�e. Recherche ce mot dans le dictionnaire.
;   Ce mot doit-�tre  un mot cr�� avec DEFER. Lorsque ce mot est trouv�,    
;   enregistre a-addr dans son CFA. a-addr est le CFA d'une action. 
; exemple:
;     / cr�ation d'un mot diff�r� qui peut effectuer diff�rentes op�rations arithm�tiques.
;     DEFER  MATH
;     ' * IS MATH   / maintenant le mot MATH agit comme *
;     ' + IS MATH   / maintenant le mot MATH agit comme +    
; arguments:
;   cccc  Prochain mot dans le flux d'entr�e. Correspond au nom d'un mot cr�� avec DEFER.
;   a-addr  Sommet de la pile des arguments qui correspond au CFA de l'action � assign� � ce mot.
; retourne:
;   rien    
DEFWORD "IS",2,,IS 
    .word TICK,TOBODY,STORE,EXIT
    

; nom: ACTION-OF   ( cccc -- a-addr )
;   Extrait le prochain mot du flux d'entr�e et le recherche dans le dictionnaire.
;   Ce mot doit-�tre un mot cr�� avec DEFER. Si le mot est trouv� dans le dictinnaire
;   le CFA de son action est empil�.
; arguments:
;   cccc   Prochain mot dans le flux d'entr�e. Nom recherch� dans le dictionnaire.
; retourne:
;   a-addr Adresse du CFA de l'action du mot diff�r�.    
DEFWORD "ACTION-OF",9,,ACTIONOF ; ( ccc -- xt2 )
    .word TICK,TOBODY,FETCH,EXIT
    
; nom: .(   cccc) ( -- )    
;   Affiche le commentaire d�limit� par )
; arguments:
;   cccc)   Commentaire extrait du flux d'entr�e.
; retourne:
;   rien    
DEFWORD ".(",2,F_IMMED,DOTPAREN ; ccccc    
    .word LIT,')',PARSE,TYPE,EXIT
 
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
;   R: d   Entier double � transf�r�.
; retourne:
;   d      Entier double ou 2 entiers simple en provenance de R:    
DEFWORD "2R>",3,,TWORFROM ; S: -- x1 x2  R: x1 x2 --
    .word RFROM,RFROM,RFROM,SWAP,ROT,TOR,EXIT
    
; nom: 2R@   ( S: -- d  R: d -- d )    
;   Copie un entier double de la pile des retours vers la pile des arguments.
; arguments:
;   R: d   Entier double qui sera copi� sur S:
; retourne:
;   d      Copie d'un entier double en provenance de R:    
DEFWORD "2R@",3,,TWORFETCH ; S: -- x1 x2 R: x1 x2 -- x1 x2    
    .word RFROM,RFROM,RFETCH,OVER,TOR,ROT,TOR
    .word SWAP,EXIT
    

