;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschenes
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

; NOM: dynamem.s
; DATE: 2017-04-15
; DESCRIPTION: Gestion dynamique de la mémoire EDS.
;  Le gestionnaire maintiens 2 listes chaînée.
;  * la liste des blocs disponibles
;  * la liste des blocs utilisés.    
;    
;  STRUCTURE ENTÊTE DE BLOC
;  ========================
;  pos.   octets   description
; ----------------------------
;   0       2        grandeur excluant l'entête
;   2       2        lien vers le bloc suivant.
;   4	    2	     lien vers le bloc précédent.
    
;  La taille mininale d'un bloc est de 8 octets, 6 pour l'entête plus 2 octets
;  pour le data. Les blocs sont arrondis au nombre pair supérieur pour assurer
;  l'alignement sur des adresses paires.    
    
;section contenant les variables
; utilisées à l'interne par
; le gesionnaire.    
.section .heap_vars.bss bss
;pointeur sur la tête de la liste des blocs libre.    
_heap_free: .space 2
; total des fragments libres.
_free_bytes: .space 2 
;pointeur sur la tête de la liste des blocs utiliés.
_heap_used: .space 2

.equ HEAD_SIZE, 6
.equ BSIZE, HEAD_SIZE ; champ grandeur  ptr-6
.equ NLNK, 4  ; champ next  ptr-4
.equ PLNK, 2  ; champ prev  ptr-2

; nom: HEAPINIT  ( -- ) 
;   Initialiation du gestionnaire, libère tous les blocs alloués.
;   Remet à zéro la mémoire. 
; arguments:
;   aucun
; retourne:
;   rien 
DEFCODE "HEAPINIT",8,, HEAP_INIT ; ( -- )
    mov #EDS_BASE,W0
    repeat  #((HEAP_SIZE/2)-1)
    clr [W0++]
    mov #EDS_BASE+HEAD_SIZE,W0
    mov W0,_heap_free
    mov #HEAP_SIZE-HEAD_SIZE,W1
    mov W1,[W0-BSIZE]
    mov W1,_free_bytes
    clr W1
    mov W1,_heap_used
    NEXT

; nom: HEAPSIZE   ( -- n+ )
;   Constante, retourne la grandeur de la mémoire dynamique en octets.
; arguments:
;   aucun
; retourne:
;   n+   Grandeur de la mémoire dynamique. 
DEFCONST "HEAPSIZE",8,,HEAPSIZE,HEAP_SIZE ; ( -- n )

; nom: HEAPFREE ( -- n )    
;   Retourne le nombre d'octets libres dans la mémoire dynamique.
; arguments:
;   aucun
; retourne:
;    n    Octets libres.    
DEFCODE "HEAPFREE",8,,HEAPFREE ; ( -- n )
    DPUSH
    mov _free_bytes,T
    NEXT

HEADLESS FREE_BYTES_STORE
    mov T,_free_bytes
    DPOP
    NEXT
    
; nom: FREELIST   ( -- a-addr )    
;   Retourne l'adresse de la variable qui contient la tête de liste des blocs libres.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable tête de liste.    
DEFCODE "FREELIST",8,,FREELIST
    DPUSH
    mov #_heap_free,T
    NEXT
    
; nom: USEDLIST  ( -- a-addr )    
;   Retourne l'adresse de la variable qui contient la tête de liste des blocs utilisés.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable tête de liste.    
DEFCODE "USEDLIST",8,,USEDLIST
    DPUSH
    mov #_heap_used,T
    NEXT
    
; nom: BSIZE@   ( a-addr -- n )    
;   Retourne la grandeur d'un bloc
; arguments:
;   a-addr  adresse retournée par MALLOC
; retourne:
;   n   Nombre d'octets de données du bloc.    
DEFWORD "BSIZE@",6,,BSIZEFETCH ; ( a-addr -- n )
    .word LIT,BSIZE,MINUS,EFETCH,EXIT

; nom: BSIZE!   ( n a-addr -- )    
;   Initialise la grandeur du bloc de donnée.
; arguments:
;    n   Nombre d'octets dans le bloc de données.
;   a-addr pointeur vers la structure bloc.
DEFWORD "BSIZE!",6,,BSIZESTORE ; ( n addr -- )
    .word LIT,BSIZE,MINUS,STORE,EXIT
    
; nom: NLNK@   ( a-addr1 -- a-addr2 )    
;   Retourne le pointeur sur le prochain bloc dans la chaîne de blocs.
; arguments:
;    addr1 adresse du bloc dans la chaîne.
; retourne:
;   addr2  adresse du prochain bloc dans la chaîne.
DEFWORD "NLNK@",5,,NLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,NLNK,MINUS,EFETCH,EXIT
  
; nom: PLNK@   ( a-addr1 -- a-addr2 )    
;   Retourne le pointeur sur le bloc précédent dans la chaîne de blocs.
; arguments:
;   addr1   adresse du bloc.
; retourne:
;   addr2  adresse du bloc précédent dans la chaîne.    
DEFWORD "PLNK@",5,,PLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,PLNK,MINUS,EFETCH,EXIT
    
; nom: NLNK!  ( a-addr1 a-addr2 -- )    
;   Initialise le champ NLNK de la structure bloc, c'est le pointeur
;   vers le bloc suivant dans la chaîne.    
; arguments:
;   a-addr1  adresse du bloc suivant.    
;   a-addr2  pointeur sur le bloc dont le champ NLNK doit-être initialisé.
DEFWORD "NLNK!",5,,NLNKSTORE  ; ( n addr -- )
    .word LIT,NLNK,MINUS,STORE,EXIT
    
; nom: PLNK!   ( a-addr1 a-addr2 -- )    
;   Initialise le champ PLNK de la structure bloc, c'est le pointeur
;   vers le bloc précédent dans la chaîne.    
; arguments:
;   a-addr1  adresse du bloc précédent.    
;   a-addr2  pointeur sur le bloc dont le champ PLNK doit-être initialisé.
DEFWORD "PLNK!",5,,PLNKSTORE  ; ( n addr -- )
    .word LIT,PLNK,MINUS,STORE,EXIT
    
; nom: UNLINK   ( a-addr1 a-addr2 -- a-addr1 )    
;   Retire un bloc de la liste auquel il apartient.
; arguments:
;   a-addr1  pointeur du bloc à retirer.
;   a-addr2  Adresse de la variable qui contient tête de liste auquel appartient ce bloc.  
; retourne:
;   a-addr1   pointeur du bloc avec NLNK et PLNK à 0
DEFWORD "UNLINK",6,,UNLINK ; ( addr list -- addr )
    .word OVER,DUP,PLNKFETCH,LIT,0,ROT,PLNKSTORE,TOR ; S: addr list R: plnk
    .word OVER,DUP,NLNKFETCH,LIT,0,ROT,NLNKSTORE ; S: addr list nlnk R: plnk
    .word RFETCH,ZBRANCH,2f-$
    ; au milieu ou à la fin de la liste
    .word SWAP,DROP,DUP,RFETCH,NLNKSTORE,RFROM,BRANCH,4f-$ ; S: addr nlnk plnk
    ;premier de la liste
2:  .word DUP,ROT,STORE,RFROM ; S: addr nlnk plnk
4:  .word OVER,ZBRANCH,6f-$ ; S: addr nlnk plnk
    .word SWAP,TWODUP,PLNKSTORE ; S: addr plnk nlnk
6:  .word TWODROP
    .word EXIT
    
; nom: PREPEND  ( a-addr1 a-addr2 -- )    
;   Insère un bloc orphelin au début d'une liste
; arguments:
;    a-addr1  pointeur du bloc à insérer
;    a-addr2  Adresse de la variable contenant le pointeur de tête de la liste.
; retourne:
;    rien
DEFWORD "PREPEND",7,,PREPEND ; ( addr1 list -- )
    .word TUCK,EFETCH,DUP,ZBRANCH,2f-$ ; S: list addr1 listhead
    .word TWODUP,PLNKSTORE ; S: list addr1 listhead
2:  .word OVER,NLNKSTORE,SWAP,STORE
    .word EXIT
    
; nom: ?FIT  ( n a-addr1 -- f )    
;   vérifie si le bloc désigné par a-addr1 est assez grand pour contenir n octets de données.
; arguments:
;    n     nombre d'octets requis.    
;    a-addr   pointeur bloc
; retourne:
;    f   indicateur booléen
DEFWORD "?FIT",4,,QFIT ;  ( n addr1 -- f )    
    .word BSIZEFETCH,ONEPLUS,ULESS,EXIT

; nom: SMALLBLK   ( a-addr1 a-addr2 -- a-addr )    
;   Compare la grandeur de 2 blocs et retourne le pointeur du plus petit des deux.
; arguments:
;   a-addr1   pointeur bloc 1
;   a-addr2   pointeur bloc 2
; retourne:
;   a-addr    pointeur sur le plus petit des 2 blocs.    
DEFWORD "SMALLBLK",8,,SMALLBLK ; ( addr1 addr2 -- addr )
    .word QDUP,ZBRANCH,9f-$
    .word TOR,DUP,ZBRANCH,2f-$,DUP,BSIZEFETCH ; S: addr1 size1 R: addr2
    .word RFETCH,BSIZEFETCH,ULESS,ZBRANCH,2f-$
1:  .word RDROP,EXIT
2:  .word DROP,RFROM
9:  .word EXIT
  
  
; nom: SMALLEST   ( n a-addr -- a-addr1 | 0 )  
;   Recherche dans une liste de blocs le plus petit qui est assez grand pour contenir n octets.
;   Si aucun ne peut contenir ce nombre d'octets, retourne 0.  
; arguments:
;    n       taille requise
;    a-addr  Adresse de la variable contenant la tête de liste.
; retourne:
;    a-addr1 | 0    pointeur sur le bloc ou 0 si aucun ne fait l'affaire.
DEFWORD "SMALLEST",8,,SMALLEST ; ( n list -- addr|0 )
    .word FETCH,LIT,0,TOR ; S: n addr1 R: 0
    ; début boucle
2:  .word QDUP,ZBRANCH,8f-$    
    .word TWODUP,QFIT,ZBRANCH,4f-$
    .word DUP,RFROM,SMALLBLK,TOR
4:  .word NLNKFETCH,BRANCH,2b-$
8:  .word DROP,RFROM
9:  .word EXIT
  
; nom: CUT  ( n a-addr1 -- a-addr2 )  
;   Ampute  l'excédent d'un bloc et cré un nouveau bloc libre avec l'excédent.
; arguments:
;    n    octets requis
;    a-addr1 pointeur bloc à réduire.
; retourne:
;    a-addr2  pointeur du bloc de taille ajusté.
DEFWORD "CUT",3,,CUT ; ( n addr -- addr )
    .word DUP,TOR,BSIZEFETCH,OVER,MINUS ; S: n diff R: addr
    .word DUP,LIT,HEAD_SIZE,GREATER,ZBRANCH,8f-$ ; S: n diff R: addr
    .word SWAP,DUP,RFETCH,BSIZESTORE,RFETCH,PLUS ; S: diff addr2 R: addr
    .word LIT,HEAD_SIZE,TUCK,PLUS,TOR,MINUS,RFETCH,BSIZESTORE ; R: addr2 addr
    .word RFROM,FREELIST,PREPEND
    .word HEAPFREE,LIT,HEAD_SIZE,MINUS,FREE_BYTES_STORE
    .word RFROM,EXIT
8:  .word TWODROP,RFROM,EXIT    
  
; nom: MALLOC  ( n -- a-addr | 0 )  
;   Allocation d'un bloc de mémoire dynamique.
;   Retourne un pointeur sur le premier octet de données de ce bloc.
;   Si aucun bloc n'est disponible retourne 0.  
;  arguments:
;     n    grandeur requise
;  retourne:
;     a-addr | 0  Adresse du premier octet de donnée du bloc, ou 0 si non disponible.  
DEFWORD "MALLOC",6,,MALLOC ; ( n -- addr|0 )
    .word ALIGNED ; n doit-êter pair.
    .word DUP,FREELIST,SMALLEST ; S: n addr|0
    .word DUP,TBRANCH,2f-$
    .word SWAP,DROP,EXIT
2:  ; S: n addr
    .word FREELIST,UNLINK,CUT,DUP,BSIZEFETCH,HEAPFREE,SWAP,MINUS,FREE_BYTES_STORE
    .word DUP,USEDLIST,PREPEND
9:  .word EXIT
  
; nom: ?>LIST   ( a-addr1 a-addr2 -- a-addr | 0 )  
;   Vérifie si le bloc à l'adresse a-addr1 est membre de la liste désignée par a-addr2
; arguments:
;   a-addr1  adresse du bloc à vérifier
;   a-addr2  Variable contenant le pointeur de la tête de la liste.  
;  retourne:
;   a-addr | 0   Adresse du bloc ou 0 si le bloc n'est pas membre de cette liste.
DEFWORD "?>LIST",6,,QINLIST ; ( addr list -- addr|0 )
    .word FETCH
1:  .word DUP,ZBRANCH,8f-$
    .word TWODUP,EQUAL,TBRANCH,8f-$
    .word NLNKFETCH,BRANCH,1b-$    
8:  .word SWAP,DROP,EXIT
 
; nom: FREE  ( a-addr -- )  
;   Libération d'un bloc mémoire dynamique. Le bloc libéré est ajouté à la liste des blocs libres.
; arguments:
;   a-addr pointeur sur le bloc à libérer.
; retourne:
;   rien  
DEFWORD "FREE",4,,FREE ; ( addr -- )
    .word DUP,LIT,EDS_BASE+HEAD_SIZE,ULESS,ZBRANCH,2f-$
1:  .word DUP,UDOT,SPACE,QABORT
    .byte 15
    .ascii "<- Bad pointer."
    .align 2
2:  .word DUP,USEDLIST,QINLIST,ZBRANCH,1b-$    
    .word USEDLIST,UNLINK,DUP,BSIZEFETCH,HEAPFREE,PLUS,FREE_BYTES_STORE
    .word FREELIST,PREPEND
    .word EXIT
   
    