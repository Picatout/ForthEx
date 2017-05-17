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
; DESCRIPTION: Gestion dynamique de la m�moire EDS.
;  Le gestionnaire maintiens 2 listes cha�n�e.
;  * la liste des blocs disponibles
;  * la liste des blocs utilis�s.    
;    
;  STRUCTURE ENT�TE DE BLOC
;  ========================
;  pos.   octets   description
; ----------------------------
;   0       2        grandeur excluant l'ent�te
;   2       2        lien vers le bloc suivant.
;   4	    2	     lien vers le bloc pr�c�dent.
    
;  La taille mininale d'un bloc est de 8 octets, 6 pour l'ent�te plus 2 octets
;  pour le data. Les blocs sont arrondis au nombre pair sup�rieur pour assurer
;  l'alignement sur des adresses paires.    
    
;section contenant les variables
; utilis�es � l'interne par
; le gesionnaire.    
.section .heap_vars.bss bss
;pointeur sur la t�te de la liste des blocs libre.    
_heap_free: .space 2
; total des fragments libres.
_free_bytes: .space 2 
;pointeur sur la t�te de la liste des blocs utili�s.
_heap_used: .space 2

.equ HEAD_SIZE, 6
.equ BSIZE, HEAD_SIZE ; champ grandeur  ptr-6
.equ NLNK, 4  ; champ next  ptr-4
.equ PLNK, 2  ; champ prev  ptr-2

; nom: HEAPINIT  ( -- ) 
;   Initialiation du gestionnaire, lib�re tous les blocs allou�s.
;   Remet � z�ro la m�moire. 
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
;   Constante, retourne la grandeur de la m�moire dynamique en octets.
; arguments:
;   aucun
; retourne:
;   n+   Grandeur de la m�moire dynamique. 
DEFCONST "HEAPSIZE",8,,HEAPSIZE,HEAP_SIZE ; ( -- n )

; nom: HEAPFREE ( -- n )    
;   Retourne le nombre d'octets libres dans la m�moire dynamique.
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
;   Retourne l'adresse de la variable qui contient la t�te de liste des blocs libres.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable t�te de liste.    
DEFCODE "FREELIST",8,,FREELIST
    DPUSH
    mov #_heap_free,T
    NEXT
    
; nom: USEDLIST  ( -- a-addr )    
;   Retourne l'adresse de la variable qui contient la t�te de liste des blocs utilis�s.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable t�te de liste.    
DEFCODE "USEDLIST",8,,USEDLIST
    DPUSH
    mov #_heap_used,T
    NEXT
    
; nom: BSIZE@   ( a-addr -- n )    
;   Retourne la grandeur d'un bloc
; arguments:
;   a-addr  adresse retourn�e par MALLOC
; retourne:
;   n   Nombre d'octets de donn�es du bloc.    
DEFWORD "BSIZE@",6,,BSIZEFETCH ; ( a-addr -- n )
    .word LIT,BSIZE,MINUS,EFETCH,EXIT

; nom: BSIZE!   ( n a-addr -- )    
;   Initialise la grandeur du bloc de donn�e.
; arguments:
;    n   Nombre d'octets dans le bloc de donn�es.
;   a-addr pointeur vers la structure bloc.
DEFWORD "BSIZE!",6,,BSIZESTORE ; ( n addr -- )
    .word LIT,BSIZE,MINUS,STORE,EXIT
    
; nom: NLNK@   ( a-addr1 -- a-addr2 )    
;   Retourne le pointeur sur le prochain bloc dans la cha�ne de blocs.
; arguments:
;    addr1 adresse du bloc dans la cha�ne.
; retourne:
;   addr2  adresse du prochain bloc dans la cha�ne.
DEFWORD "NLNK@",5,,NLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,NLNK,MINUS,EFETCH,EXIT
  
; nom: PLNK@   ( a-addr1 -- a-addr2 )    
;   Retourne le pointeur sur le bloc pr�c�dent dans la cha�ne de blocs.
; arguments:
;   addr1   adresse du bloc.
; retourne:
;   addr2  adresse du bloc pr�c�dent dans la cha�ne.    
DEFWORD "PLNK@",5,,PLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,PLNK,MINUS,EFETCH,EXIT
    
; nom: NLNK!  ( a-addr1 a-addr2 -- )    
;   Initialise le champ NLNK de la structure bloc, c'est le pointeur
;   vers le bloc suivant dans la cha�ne.    
; arguments:
;   a-addr1  adresse du bloc suivant.    
;   a-addr2  pointeur sur le bloc dont le champ NLNK doit-�tre initialis�.
DEFWORD "NLNK!",5,,NLNKSTORE  ; ( n addr -- )
    .word LIT,NLNK,MINUS,STORE,EXIT
    
; nom: PLNK!   ( a-addr1 a-addr2 -- )    
;   Initialise le champ PLNK de la structure bloc, c'est le pointeur
;   vers le bloc pr�c�dent dans la cha�ne.    
; arguments:
;   a-addr1  adresse du bloc pr�c�dent.    
;   a-addr2  pointeur sur le bloc dont le champ PLNK doit-�tre initialis�.
DEFWORD "PLNK!",5,,PLNKSTORE  ; ( n addr -- )
    .word LIT,PLNK,MINUS,STORE,EXIT
    
; nom: UNLINK   ( a-addr1 a-addr2 -- a-addr1 )    
;   Retire un bloc de la liste auquel il apartient.
; arguments:
;   a-addr1  pointeur du bloc � retirer.
;   a-addr2  Adresse de la variable qui contient t�te de liste auquel appartient ce bloc.  
; retourne:
;   a-addr1   pointeur du bloc avec NLNK et PLNK � 0
DEFWORD "UNLINK",6,,UNLINK ; ( addr list -- addr )
    .word OVER,DUP,PLNKFETCH,LIT,0,ROT,PLNKSTORE,TOR ; S: addr list R: plnk
    .word OVER,DUP,NLNKFETCH,LIT,0,ROT,NLNKSTORE ; S: addr list nlnk R: plnk
    .word RFETCH,ZBRANCH,2f-$
    ; au milieu ou � la fin de la liste
    .word SWAP,DROP,DUP,RFETCH,NLNKSTORE,RFROM,BRANCH,4f-$ ; S: addr nlnk plnk
    ;premier de la liste
2:  .word DUP,ROT,STORE,RFROM ; S: addr nlnk plnk
4:  .word OVER,ZBRANCH,6f-$ ; S: addr nlnk plnk
    .word SWAP,TWODUP,PLNKSTORE ; S: addr plnk nlnk
6:  .word TWODROP
    .word EXIT
    
; nom: PREPEND  ( a-addr1 a-addr2 -- )    
;   Ins�re un bloc orphelin au d�but d'une liste
; arguments:
;    a-addr1  pointeur du bloc � ins�rer
;    a-addr2  Adresse de la variable contenant le pointeur de t�te de la liste.
; retourne:
;    rien
DEFWORD "PREPEND",7,,PREPEND ; ( addr1 list -- )
    .word TUCK,EFETCH,DUP,ZBRANCH,2f-$ ; S: list addr1 listhead
    .word TWODUP,PLNKSTORE ; S: list addr1 listhead
2:  .word OVER,NLNKSTORE,SWAP,STORE
    .word EXIT
    
; nom: ?FIT  ( n a-addr1 -- f )    
;   v�rifie si le bloc d�sign� par a-addr1 est assez grand pour contenir n octets de donn�es.
; arguments:
;    n     nombre d'octets requis.    
;    a-addr   pointeur bloc
; retourne:
;    f   indicateur bool�en
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
;    a-addr  Adresse de la variable contenant la t�te de liste.
; retourne:
;    a-addr1 | 0    pointeur sur le bloc ou 0 si aucun ne fait l'affaire.
DEFWORD "SMALLEST",8,,SMALLEST ; ( n list -- addr|0 )
    .word FETCH,LIT,0,TOR ; S: n addr1 R: 0
    ; d�but boucle
2:  .word QDUP,ZBRANCH,8f-$    
    .word TWODUP,QFIT,ZBRANCH,4f-$
    .word DUP,RFROM,SMALLBLK,TOR
4:  .word NLNKFETCH,BRANCH,2b-$
8:  .word DROP,RFROM
9:  .word EXIT
  
; nom: CUT  ( n a-addr1 -- a-addr2 )  
;   Ampute  l'exc�dent d'un bloc et cr� un nouveau bloc libre avec l'exc�dent.
; arguments:
;    n    octets requis
;    a-addr1 pointeur bloc � r�duire.
; retourne:
;    a-addr2  pointeur du bloc de taille ajust�.
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
;   Allocation d'un bloc de m�moire dynamique.
;   Retourne un pointeur sur le premier octet de donn�es de ce bloc.
;   Si aucun bloc n'est disponible retourne 0.  
;  arguments:
;     n    grandeur requise
;  retourne:
;     a-addr | 0  Adresse du premier octet de donn�e du bloc, ou 0 si non disponible.  
DEFWORD "MALLOC",6,,MALLOC ; ( n -- addr|0 )
    .word ALIGNED ; n doit-�ter pair.
    .word DUP,FREELIST,SMALLEST ; S: n addr|0
    .word DUP,TBRANCH,2f-$
    .word SWAP,DROP,EXIT
2:  ; S: n addr
    .word FREELIST,UNLINK,CUT,DUP,BSIZEFETCH,HEAPFREE,SWAP,MINUS,FREE_BYTES_STORE
    .word DUP,USEDLIST,PREPEND
9:  .word EXIT
  
; nom: ?>LIST   ( a-addr1 a-addr2 -- a-addr | 0 )  
;   V�rifie si le bloc � l'adresse a-addr1 est membre de la liste d�sign�e par a-addr2
; arguments:
;   a-addr1  adresse du bloc � v�rifier
;   a-addr2  Variable contenant le pointeur de la t�te de la liste.  
;  retourne:
;   a-addr | 0   Adresse du bloc ou 0 si le bloc n'est pas membre de cette liste.
DEFWORD "?>LIST",6,,QINLIST ; ( addr list -- addr|0 )
    .word FETCH
1:  .word DUP,ZBRANCH,8f-$
    .word TWODUP,EQUAL,TBRANCH,8f-$
    .word NLNKFETCH,BRANCH,1b-$    
8:  .word SWAP,DROP,EXIT
 
; nom: FREE  ( a-addr -- )  
;   Lib�ration d'un bloc m�moire dynamique. Le bloc lib�r� est ajout� � la liste des blocs libres.
; arguments:
;   a-addr pointeur sur le bloc � lib�rer.
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
   
    