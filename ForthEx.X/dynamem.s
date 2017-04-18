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
 
 HEADLESS HEAP_INIT
    mov #EDS_BASE+HEAD_SIZE,W0
    mov W0,_heap_free
    mov #HEAP_SIZE-HEAD_SIZE,W1
    mov W1,[W0-HEAD_SIZE]
    mov W1,_free_bytes
    clr W0
    mov W0,_heap_used
    NEXT
    
; retourne la grandeur du HEAP
DEFCONST "HEAPSIZE",8,,HEAPSIZE,HEAP_SIZE ; ( -- n )

; retourne la grandeur libre
DEFCODE "HEAPFREE",8,,HEAPFREE ; ( -- n )
    DPUSH
    mov _free_bytes,T
    NEXT
    
; retourne le pointeur de tête
; de la liste libre.
DEFCODE "FREELIST",8,,FREELIST ; ( -- addr )
    DPUSH
    mov _heap_free,T
    NEXT
 
; retourne le pointeur de tête
; de la liste utililés.
DEFCODE "USEDLIST",8,,USEDLIST ; ( -- addr )
    DPUSH
    mov _heap_used,T
    NEXT
    
    
; retourne la grandeur d'un bloc
; arguments:
;   addr  adresse retournée par MALLOC
; retourne:
;   n   octets data    
DEFWORD "BSIZE@",6,,BSIZEFETCH ; ( addr -- n )
    .word LIT,BSIZE,MINUS,EFETCH,EXIT

; assigne le champ block_size
; arguments:
;    n   valeur à assigner
;   addr pointeur bloc
DEFWORD "BSIZE!",6,,BSIZESTORE ; ( n addr -- )
    .word LIT,BSIZE,MINUS,STORE,EXIT
    
    
; retourne le pointeur sur le prochain bloc
; arguments:
;    addr1 adresse retournée par MALLOC
; retourne:
;   addr2  adresse du prochain bloc dans la chaîne.
DEFWORD "NLNK@",5,,NLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,NLNK,MINUS,EFETCH,EXIT
    
; retourne le pointeur sur le bloc précédent
; arguments:
;   addr1   adresse retournée par MALLOC
; retourne:
;   addr2  adresse du bloc précédent dans la chaîne.    
DEFWORD "PLNK@",5,,PLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,PLNK,MINUS,EFETCH,EXIT
    
; assigne une valeur au champ NLNK
; arguments:
;   n    valeur 
;   addr pointeur bloc
DEFWORD "NLNK!",5,,NLNKSTORE  ; ( n addr -- )
    .word LIT,NLNK,MINUS,STORE,EXIT
    
; assigne une valeur au champ PLNK
; arguments:
;   n    valeur 
;   addr pointeur bloc
DEFWORD "PLNK!",5,,PLNKSTORE  ; ( n addr -- )
    .word LIT,PLNK,MINUS,STORE,EXIT
    
;vérifie si n < addr.bsize
; arguments:
;    addr   pointeur bloc
; retourne:
;    f   indicateur booléen
DEFWORD "?FIT",4,,QFIT ;  ( n addr1 -- f )    
    .word BSIZEFETCH,LESS,EXIT

; retourne le plus petit des 2 blocs
; arguments:
;    addr1   pointeur bloc 1
;    addr2   pointeur bloc 2    
; retourne:
;    addr    pointeur du plus petit.
DEFWORD "SMALLEST",8,,SMALLEST ; ( addr1 addr2 -- addr )
    .word TOR, DUP ,BSIZEFETCH,RFETCH,BSIZEFETCH
    .word LESS, ZBRANCH,2f-$
    .word RFROM,DROP,EXIT
2:  .word DROP,RFROM,EXIT
  
; allocation d'un bloc de mémoire
; recherche d'un bloc libre dont la taille est le plus
; proche possible de n.
; retourne un pointeur sur le data.
;  arguments:
;     n    grandeur requise
;  retourne
;     addr|0   
DEFWORD "MALLOC",6,,MALLOC ; ( n -- addr|0 )
    .word DUP,ODD,ZBRANCH,2f-$,ONEPLUS ; n doit-êter pair.
2:  .word HEAPFREE,OVER,LESS,ZBRANCH,2f-$
    .word DROP,LIT,0,EXIT ;trop grrand.
2:  .word FREELIST,DUP,TWOTOR
2:  .word RFROM,TWODUP,QFIT,ZBRANCH,4f-$
    .word RFROM,SMALLEST,DUP,TOR
4:  .word NLNKFETCH,QDUP,ZBRANCH,6f-$,TOR,BRANCH,2b-$
6:  .word DUP,RFROM,DUP,BSIZEFETCH,ROT,SWAP,MINUS ; S: n addr n-n2
    .word DUP,LIT,HEAD_SIZE,GREATER,ZBRANCH,8f-$
    .word ;....
9:  .word EXIT
    
;libération d'un bloc mémoire
; 1) sortir le bloc de la liste des alloués.
; 2) insérer le bloc au début de la liste des libres.  
; arguments:
;   addr pointeur retourné par MALLOC    
DEFWORD "BLKFREE",7,,BLKFREE ; ( addr -- )
    .word TOR 
    ; sortir le bloc de la chaîne des blocs alloués.
    .word RFETCH,NLNKFETCH,RFETCH,PLNKFETCH,NLNKSTORE
    .word RFETCH,PLNKFETCH,RFETCH,NLNKFETCH,PLNKSTORE
    ; insérer le bloc au début de la chaîne des blocs libres
    .word RFETCH,LIT,0,PLNKSTORE ; il sera la premier de la liste
    .word FREELIST,RFETCH,NLNKSTORE ; _heap_free devient le second 
    .word RFROM,LIT,_heap_free,STORE ; bloc libéré devient la tête.
9:  .word EXIT
   
; échanges liens PLNK et NLNK des 2 blocs
; arguments:
;    addr1   pointeur bloc 1
;    addr2   pointeur bloc 2
DEFWORD "LNKSWAP",7,,LNKSWAP ; ( addr1 addr2 -- )
    .word TOR
    .word DUP,PLNKFETCH,RFETCH,PLNKFETCH,ROT ; S: plnk1 plnk2 addr1 R: addr2
    .word DUP,NLNKFETCH,RFETCH,NLNKFETCH,ROT ; S: plnk1 plnk2 nlnk1 nlnk2 addr1 R: addr2
    .word DUP,TOR,NLNKSTORE,SWAP,RFROM,PLNKSTORE ; S: plnk1 nlnk1 R: addr2
    .word RFETCH,NLNKSTORE,RFROM,PLNKSTORE,EXIT
    
; interchange les 2 éléments si le premier est plus grand
; que le deuxième.
; arguments:
;    addr1   premier pointeur de bloc
;    addr2   deuxième pointeur de bloc
; retourne:
;    addr   pointeur vers l'élément qui viens en second.
DEFWORD "BSORT",5,,BSORT ; ( addr1 addr2 -- addr < addr )
    .word TWODUP,UGREATER,ZBRANCH,8f-$
    .word SWAP,TWODUP,LNKSWAP  
8:  .word EXIT

; fusionne 2 blocs adjacents
; arguments:
;   addr1   pointeur bloc 1
;   addr2   pointeur bloc 2
; retourne:
;   f    indicateur booléen de fusion
DEFWORD "BMERGE",6,,BMERGE  ; ( addr1 addr2 -- f )
    .word BSORT,TOR,DUP,BSIZEFETCH,LIT,HEAD_SIZE,PLUS
    .word OVER,PLUS,RFETCH,EQUAL,ZBRANCH,8f-$
    .word RFETCH,BSIZEFETCH,LIT,HEAD_SIZE,PLUS,OVER,BSIZESTORE
    .word RFROM,NLNKFETCH,SWAP,NLNKSTORE,LIT,-1,EXIT
8:  .word RFROM,TWODROP,LIT,0,EXIT    
    
;trie croissant des éléments de la liste chaînée
; le trie se fait sur le pointeur du bloc
; bubble sort: lent mais simple.
; arguments:
;   addr1  pointeur tête de liste
; retourne:
;   addr2  pointeur nouvelle tête de liste.  
DEFWORD "LISTSORT",8,,LISTSORT ; ( addr1 -- addr2 )
    .word LIT,0,SWAP ; insérer indicateur de commutation
2:  ; begin loop
    .word DUP,NLNKFETCH,QDUP,ZBRANCH,4f-$
    .word OVER,LESS,ZBRANCH,2b-$
4:  .word OVER,TBRANCH,2b-$ ; while
    
    
;défragmentation des block libres
; 1) trier en ordre croissant  
; 2) fusionner les blocs contigus  
DEFWORD "MDEFRAG",7,,MDEFRAG ; ( -- )
    .word FREELIST,LISTSORT
    .word EXIT
    
  