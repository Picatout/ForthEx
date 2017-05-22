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
    
; NOM: core.s
; DATE: 2015-10-03
; DESCRIPTION: 
;    Vocabulaire de base du système ForthEx.
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
HEADLESS EXIT,CODE
    RPOP IP
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

; marqueur fin du dictionnaire.    
    SYSDICT
   .word 0 
0: .word 0    

; DESCRIPTION:
; Cette section décris les différentes constantes utilisées par le système ForthEx.

; nom: VERSION   ( -- c-addr )
;   Constante système, Adresse de la chaîne compté qui contient l'information de version firmware.
;   Utilisation: VERSION COUNT TYPE
; arguments:
;   aucun
; retourne:
;   c-addr  Adresse de la chaîne constante en mémoire FLASH.    
DEFCONST "VERSION",7,,VERSION,psvoffset(_version)
    
; nom: R0  ( -- a-addr )
;   Constante système, retourne l'adresse de la base de la pile des retours.       
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse de la base de la pile des retours.    
DEFCONST "R0",2,,R0,rstack   ; base pile retour
    
; nom: S0   ( -- a-addr )
;   Constante système qui retourne l'adresse de la base de la piles des arguments.    
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse de la base de la pile des arguments.    
DEFCONST "S0",2,,S0,pstack   ; base pile arguments   
    
; nom: RAMEND  ( -- a-addr )
;   Constante système qui retourne l'adresse après la fin de la mémoire RAM.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse fin de la RAM+1    
DEFCONST "RAMEND",6,,RAMEND,RAM_END
    
; nom: IMMED  ( -- n )
;   Constante système qui retourne le bit F_IMMEDIATE. Ce bit inscrit dans le
;   premier octet du champ NFA et indique si le mot est immmédiat.
; arguments:
;   aucun
; retourne:
;   n     F_IMMED bit indicateur mot immédiat.    
DEFCONST "IMMED",5,,IMMED,F_IMMED       ; drapeau mot immédiat
    
; nom: HIDDEN   ( -- n )
;   Constante système qui retourne le bit F_HIDDEN. Ce bit est inscrit dans le 
;   premier octet du champ NFA et indique si le mot est caché à la recherche par FIND.
; arguments:
;   rien
; retourne:
;   n	F_HIDDEN bit indicateur de mot caché.       
DEFCONST "HIDDEN",6,,HIDDEN,F_HIDDEN    ; drapeau mot caché
    
; nom: NMARK  ( -- n )
;   Constante système qui retourne le bit F_MARK. Ce bit est inscrit dans le
;   premier octet du champ NFA et sert la localisé ce champ. Ce bit est utilisé
;   par le mot CFA>NFA.    
DEFCONST "NMARK",5,,NMARK,F_MARK     ; drapeau marqueur utilisé par CFA>NFA
    
; nom: LENMASK   ( -- n )
;   Constante système retourne le masque pour la longueur du nom dans les entêtes
;   du dictionnaire. Ce masque sert à éliminer les bits F_NMARK,F_HIDDEN et F_IMMED
;   pour ne conserver que les bits qui indique la longueur du nom.
; arguments:
;   aucun
; retourne:
;   n   masque LEN_MASK    
DEFCONST "LENMASK",7,,LENMASK,LEN_MASK ; masque longueur nom

; nom: BL  ( -- n )
;   Constante système qui retourne la valeur ASCII 32 (espace).
; arguments:
;   aucun
; retourne:
;   n    valeur ASCII 32  qui représente l'espace.    
DEFCONST "BL",2,,BL,32                       ; caractère espace

; nom: TIBSIZE   ( -- n )
;   Constante système qui retourne la longueur du TIB (Transaction Input Buffer)
; arguments:
;   aucun
; retourne:
;   n    longueur du tampon TIB.    
DEFCONST "TIBSIZE",7,,TIBSIZE,TIB_SIZE       ; grandeur tampon TIB
    
; nom: PADSIZE   ( -- n )
;   Constante système qui retourne la longueur du tampon PAD.
; arguments:
;   aucun
; retourne:
;   n    longueur du tampon PAD.    
DEFCONST "PADSIZE",7,,PADSIZE,PAD_SIZE       ; grandeur tampon PAD

; nom: ULIMIT   ( -- a-addr )
;   Constante système qui retourne l'adresse limite+1 de la mémoire réservré
;   au données du dictionnaire utilisateur.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse fin dictionnaire+1    
DEFCONST "ULIMIT",6,,ULIMIT,EDS_BASE        ; limite espace dictionnaire

; nom: TRUE  ( -- f )
;   Constante système qui retourne la valeur Booléenne VRAI.
; arguments:
;   rien
; retourne:
;   f      indicateur Booléen VRAI = -1    
DEFCONST "TRUE",4,,TRUE,-1 ; valeur booléenne vrai
    
; nom: FALSE  ( -- f )
;   Constante système qui retourne la valeur Booléenne FAUX.
; arguments:
;   rien
; retourne:
;   f      indicateur Booléen FAUX = 0    
DEFCONST "FALSE",5,,FALSE,0 ; valeur booléenne faux
    
; nom: DP0    ( -- a-addr )
;   Constante système qui retourne l'adresse du début de l'espace de données utilisateur.
; arguments:
;   rien
; retourne:
;   a-addr   Adresse du début espace utilisateur en mémoire RAM.    
DEFCONST "DP0",3,,DP0,DATA_BASE ; début espace utilisateur
   
; nom: CELL   ( -- u )    
;   Constante système qui retourne la taille d'une cellule. 
;   Une cellule est le nom donné à un élément de la pile. 
;   Pour forthEx sur PIC24EP les entiers sont de 16 bits donc
;   la pile utilise des cellules de 2 octets.    
; arguments:
;   aucun
; retourne:
;   u   Grandeur d'une cellule.    
DEFCONST "CELL",4,,CELL,CELL_SIZE
 
; DESCRIPTION:
;  Cette section décris les différentes variables utilisées par le système.
    
; nom: STATE  ( -- a-addr )
;   Variable système qui indique si le système est en mode interprétation ou compilation.
;   STATE=0 -> interprétation,  STATE=-1 -> compilation.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "STATE",5,,STATE 

; nom: DP ( -- a-addr )
;   Variable système qui contient la position du pointeur de donnée dans l'esapce utilisateur.
;   Lorsqu'une nouvelle définition est créée ou que de l'espace est réservé avec ALLOT ce
;   pointeur avance à la première position libre.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "DP",2,,DP 

; nom: BASE  ( -- a-addr )
;   Variable système qui contient la valeur de la base numérique active.
;   Le contenu de cette variable est modifié par les mots HEX et DECIMAL.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "BASE",4,,BASE     ; base numérique

; nom: SYSLATEST  ( -- a-addr )
;   Variable système qui contient le NFA du dernier mot défini dans le dictionnaire
;   système en mémoire FLASH.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "SYSLATEST",9,,SYSLATEST ; tête du dictionnaire en FLASH
    
; nom: LATEST  ( -- a-addr )
;   Variable système qui contient le NFA du dernier mot défini par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "LATEST",6,,LATEST ; pointer dernier mot dictionnaire

; nom: PAD ( -- a-addr )
;   Variable système qui contient l'adresse d'un tampon utilisé pour le travail
;   sur des chaînes de caractère. Ce tampon est utilisé entre autre pour la conversion
;   des entiers en chaêine de caractères pour l'affichage.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "PAD",3,,PAD       ; tampon de travail

; nom: TIB ( -- a-addr )
;   Variable système contenant l'adresse du tampon de saisie des chaînes à partir
;   du clavier. Ce tampon est utilisé par l'interpréteur/compilateur en mode interactif.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "TIB",3,,TIB       ; tampon de saisie clavier
; nom: PASTE  ( -- a-addr )
;   Variable système qui contient l'adresse d'un tampon qui contient une copie
;   de la dernière chaîne interprétée en mode interactif. Permet de rappeller cette
;   chaîne à l'écran par la commande CTRL_V.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "PASTE",5,,PASTE   ; copie de TIB
    
; nom: >IN   ( -- a-addr )
;   Variable système indique la position ou est rendue l'analyseur lexical dans
;   le traitement de la chaîne d'entrée. Cette variable est utilisée par l'interpréteur/compilateur.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER ">IN",3,,TOIN     ; pointeur position après le dernier mot retourné par WORD
    
; NOM: HP   ( -- a-addr )
;   Variable système contenant la position du pointeur de conversion de nombres en chaîne.
;   Cette variable est utilisée lors de la conversion d'entiers en chaîne de caractères.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "HP",2,,HP       ; HOLD pointer
    
; nom: 'SOURCE	( -- a-addr )
;   Variable système qui contient le pointeur du début du tampon utilisé par
;   l'interpréteur/compilateur.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "'SOURCE",7,,TICKSOURCE ; tampon source pour l'évaluation
    
; nom: #SOURCE  ( -- a-addr )
;   Variable système contenant la grandeur du tampon source.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "#SOURCE",7,,CNTSOURCE ; grandeur du tampon

; nom: RPBREAK   ( -- a-addr )
;   Variable système utilisé par le mot BREAK pour sauvegarder la position
;   de RSP pour la réentrée.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "RPBREAK",7,,RPBREAK ; valeur de RSP après l'appel de BREAK 
    
; nom: DBGEN  ( -- a-addr)
;   Variable système qui contient un indicateur Booléen d'activation/désactivation des breakpoints.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "DBGEN",5,,DBGEN ; activation désactivation break points
    
; nom: SYSCONS   ( -- a-addr )
;   Variable système qui indique le périphérique actuel utilisé par la console.
;   La console peut fonctionné en mode LOCAL ou REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "SYSCONS",7,,SYSCONS 
    
 
; DESCRIPTION:
;  La machine Virtuelle ForthEx utilise 3 piles.
;  La pile des arguments sert a passer des arguments d'une fonction à une autre
;  ainsi qu'à retourner les valeurs des fonctions.
;  La pile des retours sert principalement a conserver la valeur du pointeur
;  d'instruction lors de l'appel de mots de haut-niveau afin de retourner au point
;  initial. Mais elle sert aussi à conserver des valeurs temporaires.
;  La 3ième pile est utilisée seulement par le compilateur pour conserver des adresses
;  de sauts qui doivent-être résolues avant de terminer la compilation.
;  Les mots suivants servent à manipuler le contenu des 3 piles.

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
;    Clone la valeur au sommet de la pile si cette valeur est différente de zéro.
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
;   rien La pile contient 2 éléments de moins.    
DEFCODE "2DROP",5,,TWODROP
    DPOP
    DPOP
    NEXT
    
; nom: RDROP  ( R: x -- )
;   Jette la valeur au sommet de la pile des retours.
; arguments:
;    x  Valeur au sommet de la pile des retours.
; retourne:
;   rien La pile des retours contient 1 élément de moins.    
DEFCODE "RDROP",5,,RDROP ; ( R: n -- )
    sub #CELL_SIZE,RSP
    NEXT
    
; nom: SWAP  ( x1 x2 -- x2 x1 )
;   Inverse l'ordre des 2 éléments au sommet de la pile des arguments.
; arguments:
;   x1   Deuxième élément de la pile.
;   x2   Élément au sommet de la pile.
; retourne:
;   x2   La valeur qui était au sommet est maintenant en second.
;   x1   La valeur qui était en second est maintenant au sommet.    
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
;   Rotation des 3 éléments du sommet de sorte que le 3ième se retrouve au sommet.
; arguments:
;   n1  Élément en 3ième position de la pile.
;   n2  Élément en 2ième position de la pile.
;   n3  Élément a sommet de la pile.
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
;   n2   Le second élément est maintenant au sommet.    
DEFCODE "-ROT",4,,NROT ; ( n1 n2 n3 -- n3 n1 n2 )
    mov T, W0    
    mov [DSP],T
    mov [DSP-2],W1
    mov W1,[DSP]
    mov W0,[DSP-2]
    NEXT
    
; nom: OVER  ( n1 n2 -- n1 n2 n1 )
;   Copie du second élément de la pile par dessus le sommet de celle-ci.
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
DEFCODE "NIP",3,,NIP   ; ( n1 n2 -- n2 )
    dec2 DSP,DSP
    NEXT

; nom: TUCK  ( x1 x2 -- x2 x1 x2 )
;   Insère une copie de la valeur au sommet de la pile des arguments
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

    
; nom: >R  (  x --  R: -- x )
;   Transfert le sommet de la pile des arguments au sommet de la pile des retours.
;   Après cette opération la pile des arguments a raccourcie d'un élément et la
;   pile des retours a rallongée d'un élément.    
; arguments:
;   x   Valeur au sommet de la pile des arguments.
; retourne:
;   rien   La valeur x est maintenant au sommet de la pile des retours.  
DEFCODE ">R",2,,TOR  
    RPUSH T
    DPOP
    NEXT
    
; nom: R>  ( -- x  R: x -- )     
;   Transfert d'un élément de la pile des retours vers la pile des arguments.
;   Après cette opération la pile des retours a raccourcie de 1 élément et la
;   pile des arguments a rallongée d'un élément.
; arguments:
;   x   Valeur au somment des retours.
; retourne:
;   x   valeur qui était au somment de R: est maintenant ajoutée au sommet de S:.    
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
;   Retourne le nombre d'éléments sur la pile des arguments. Le nombre d'éléments
;   renvoyé  exclu ce nouvel élément.
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
;   Insère le nième élément de la pile au sommet
;   l'argument n est retiré de la pile avant le comptage.
;   Si n==0 équivaut à DUP 
;   Si n==1 équivaut à OVER
; arguments:
;   i*x   Liste des éléments présent sur la pile.
;   n     position de l'élément recherché, 0 étant le sommet.
; retourne:
;   i*x   Liste originale des éléments.
;   x     copie de l'élément en position n.    
DEFCODE "PICK",4,,PICK
    mov DSP,W0
    sl T,T
    sub W0,T,W0
    mov [W0],T
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
;   vers la pile de contrôle. Après cette opération la pile 
;   des arguments à perdue un élément et la pile de contrôle en a
;   gagné un.    
; arguments:
;   x   Valeur au sommet de la pile des arguments.
; retourne:
;   rien    Le sommet de  la pile de contrôle contient x.    
DEFCODE ">CSTK",5,,TOCSTK 
    mov csp,W0
    mov T,[W0++]
    mov W0,csp
    DPOP
    NEXT

; nom: CSTK>  ( -- x C: x -- )
;   Utilisé par le compilateur.    
;   Transfert du sommet de la pile de contrôle
;   vers la pile des arguments. Après cette opération la pile de contrôle
;   contient un élément de moins et la pile des arguments un élément de plus.
; arguments:
;    x   Valeur au sommet de la pile de contrôle.
; retourne:
;    x    Valeur ajoutée au sommet de la pile des arguments.    
DEFCODE "CSTK>",5,,CSTKFROM 
    DPUSH
    mov csp,W0
    mov [--W0],T
    mov W0,csp
    NEXT
    
; nom: @   ( a-addr -- n )
;   Retourne l'entier qui se trouve à l'adresse qui est au sommet de la pile des arguments.
;   Cette adresse doit-être alignée sur une adresse paire.    
;   Les adresses > 32767 accèdent la mémoire FLASH dans l'interval {0..32766}.    
; arguments:
;   a-addr  Adresse de la variable.
; retourne:
;   n	Entier contenu à cette adresse.
DEFCODE "@",1,,FETCH 
    mov [T],T
    NEXT

; nom: C@  ( c-addr -- c )
;   Retourne l'octet contenu à l'adresse caractère qui est au sommet de la pile.
;   Les adresses > 32767 accèdent la mémoire FLASH dans l'interval {0..32767}.    
; arguments:
;   c-addr  Adresse alignée sur un octet.
; retourne:
;   c   Caractère contenu à cette adresse.    
DEFCODE "C@",2,,CFETCH 
    mov.b [T],T
    ze T,T
    NEXT
    
; nom: 2@  ( a-addr -- d )    
;   Retourne la valeur de type entier double qui est à l'adresse a-addr.
;   Cette adresse doit-être alignée sur une valeur paire.    
;   Les adresses > 32767 accès la mémoire EDS.    
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
;   Retourne l'élément n d'un vecteur. Les valeurs d'indice débute à zéro.
;   L'adresse de la table doit-être alignée sur une adresse paire.
;   Les adresses > 32767 sont en mémoire FLASH.    
; arguments:
;   n  Indice dans le vecteur.
;   a-addr  Adresse du vecteur.
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
;   Sauvegarde l'entier n1 dans l'élément d'indice n2 du vecteur dont d'adresse a-addr.
;   L'adresse de table doit-être alignée sur un nombre pair.    
;   a-addr[n2] = n1.
;   Les adresses > 32767 accès la mémoire EDS.    
; arguments:
;   n1  Valeur à affecté à l'élément.
;   n2  Indice de l'élément.
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
;   Accès RAM et EDS.    
; arguments:
;   n    Valeur à sauvegarder
;   a-addr Adresse de la variable.    
; retourne:
;   rien    
DEFCODE "!",1,,STORE 
    mov [DSP--],[T]
    DPOP
    NEXT

; nom: C!  ( c c-addr -- )    
;   Sauvegarde un caractère dans une variable.
;   Accès RAM et EDS.
; arguments:
;   c   Valeur à sauvegarder.
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
;   Accès RAM et EDS    
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
;   R: d   Entier double à transféré.
; retourne:
;   d      Entier double ou 2 entiers simple en provenance de R:    
DEFWORD "2R>",3,,TWORFROM ; S: -- x1 x2  R: x1 x2 --
    .word RFROM,RFROM,RFROM,SWAP,ROT,TOR,EXIT
    
; nom: 2R@   ( S: -- d  R: d -- d )    
;   Copie un entier double de la pile des retours vers la pile des arguments.
; arguments:
;   R: d   Entier double qui sera copié sur S:
; retourne:
;   d      Copie d'un entier double en provenance de R:    
DEFWORD "2R@",3,,TWORFETCH ; S: -- x1 x2 R: x1 x2 -- x1 x2    
    .word RFROM,RFROM,RFETCH,OVER,TOR,ROT,TOR
    .word SWAP,EXIT
    

; nom: CELL+  ( addr -- addr' )    
;   Incrémente l'adresse au sommet de la pile de la taille d'une cellule.
; arguments:
;   addr   Adresse. 
; retourne:
;   addr'  Adresse incrémentée de la taille d'une cellule.    
DEFCODE "CELL+",5,,CELLPLUS ; ( addr -- addr+CELL_SIZE )
    add #CELL_SIZE, T
    NEXT

; nom: CELLS  ( n1 -- n2 )    
;    Convertie l'entier n1 en la taille occupée par n1 cellules.
;    n2=n1*CELL_SIZE    
; arguments:
;    n1   Nombre de cellules.
; retourne:
;    n2   Espace occupé par n1 cellules.   
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
;   Restore les valeurs des variables I et LIMIT tels qu'elles étaient
;   avant l'exécution du dernier DO ou ?DO. 
;   Après exécution  LIMIT=n1, I=n2
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "UNLOOP",6,,UNLOOP
    RPOP I
    RPOP LIMIT
    NEXT
    
; DESCRIPTION:
;   Les mots suivants servent à exécuter des fonctions à partir de l'information
;   qui se trouve sur la pile des arguments.
    
; nom: EXECUTE  ( i*x a-addr -- j*x )
;   Exécute le mot dont le Code Field Address est au sommet de la pile.
; arguments:
;   i*x    Liste des arguments consommés par ce mot.
;   a-addr CFA du mot à exécuter.
; retourne:
;   j*x   Valeurs retournées l'exécution du mot.
DEFCODE "EXECUTE",7,,EXECUTE
exec:
    mov T, WP ; CFA
    DPOP
    mov [WP++],W0  ; code address, WP=PFA
    goto W0

; nom: @XT  ( i*x a-addr -- j*x )
;   Exécution vectorisée. 
;   Lit le contenu d'une adresse qui contient le CFA d'un mot et exécute ce mot.
;   : @XT  @ EXECUTE ;    
; arguments:
;    i*x   Arguments attendus par la fonction qui sera exécutée.    
;    a-addr Adresse qui contient le CFA du code à exécuter. Accès RAM + FLASH
; retourne:
;    j*x  Valeurs laissées par le mot exécuté.    
DEFCODE "@EXEC",5,,FETCHEXEC
    mov [T],T
    bra exec

; nom: VEXEC ( i*x a-addr n -- j*x )
;   Excécute la fonction n dans une table contenant des CFA.
;   : VEXEC CELLS + @ EXECUTE ;    
; arguments:
;    i*x   Arguments requis par la fonction à exécuter.
;    a-addr  Adresse de la table des CFA.
;    n     Index de l'élément dans la table.
; retourne:
;    j*x   Valeurs retournées par la fonction exécutée.    
DEFCODE "VEXEC",5,,VEXEC
    mul.uu T,#CELL_SIZE,W0
    DPOP
    add W0,T,T
    mov [T],T
    bra exec

; nom: CALL  ( i*x ud -- j*x )
;    Appel d'une routine écrite en code machine et résident en mémoire flash.
;    La routine doit se terminée par une instruction machine RETURN.
;    Utilise l'instruction machine CALL.L spécifique aux PIC24E et dsPIC33E. 
; arguments:
;     i*x    Arguments consommés par la routine, dépend de celle-ci.
;     ud     adresse 24 bits de la routine.
; retourne:
;     j*x    Valeurs laissées sur la pile par la routine, dépend de celle-ci.   
DEFCODE "CALL",4,,CALL 
    mov T, W1
    DPOP
    mov T, W0
    DPOP
    call.l W0
    NEXT
 
