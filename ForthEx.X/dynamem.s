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
 
 HEADLESS HEAP_INIT
    mov #EDS_BASE+HEAD_SIZE,W0
    mov W0,_heap_free
    mov #HEAP_SIZE-HEAD_SIZE,W1
    mov W1,[W0-BSIZE]
    mov W1,_free_bytes
    clr W1
    mov W1,[W0-NLNK]
    mov W1,[W0-PLNK]
    mov W1,_heap_used
    NEXT
    
; retourne la grandeur du HEAP
DEFCONST "HEAPSIZE",8,,HEAPSIZE,HEAP_SIZE ; ( -- n )

; retourne la grandeur libre
DEFCODE "HEAPFREE",8,,HEAPFREE ; ( -- n )
    DPUSH
    mov _free_bytes,T
    NEXT

HEADLESS FREE_BYTES_STORE
    mov T,_free_bytes
    DPOP
    NEXT
    
; retourne la variable _heap_free
DEFCODE "FREELIST",8,,FREELIST
    DPUSH
    mov #_heap_free,T
    NEXT
    
; retourne la variable _heap_used
DEFCODE "USEDLIST",8,,USEDLIST
    DPUSH
    mov #_heap_used,T
    NEXT
    
; retourne le pointeur de t�te
; de la liste libre.
DEFCODE "FREEHEAD",8,,FREEHEAD ; ( -- addr )
    DPUSH
    mov _heap_free,T
    NEXT
 
; retourne le pointeur de t�te
; de la liste utilil�s.
DEFCODE "USEDHEAD",8,,USEDHEAD ; ( -- addr )
    DPUSH
    mov _heap_used,T
    NEXT
    
    
; retourne la grandeur d'un bloc
; arguments:
;   addr  adresse retourn�e par MALLOC
; retourne:
;   n   octets data    
DEFWORD "BSIZE@",6,,BSIZEFETCH ; ( addr -- n )
    .word LIT,BSIZE,MINUS,EFETCH,EXIT

; assigne le champ block_size
; arguments:
;    n   valeur � assigner
;   addr pointeur bloc
DEFWORD "BSIZE!",6,,BSIZESTORE ; ( n addr -- )
    .word LIT,BSIZE,MINUS,STORE,EXIT
    
    
; retourne le pointeur sur le prochain bloc
; arguments:
;    addr1 adresse retourn�e par MALLOC
; retourne:
;   addr2  adresse du prochain bloc dans la cha�ne.
DEFWORD "NLNK@",5,,NLNKFETCH ; ( addr1 -- addr2 )
    .word LIT,NLNK,MINUS,EFETCH,EXIT
    
; retourne le pointeur sur le bloc pr�c�dent
; arguments:
;   addr1   adresse retourn�e par MALLOC
; retourne:
;   addr2  adresse du bloc pr�c�dent dans la cha�ne.    
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
    
; retire le premier bloc de la cha�ne
; arguments:
;    addr   pointeur bloc
; retourne:
;   rien    
DEFWORD "ULNKFIRST",9,,ULNKFIRST ; ( addr -- )
    .word FREEHEAD,OVER,EQUAL,ZBRANCH,2f-$
    .word NLNKFETCH,FREELIST,STORE,EXIT
2:  .word NLNKFETCH,USEDLIST,STORE,EXIT
  
; retire un bloc de la liste auquel il apartient.
; arguments:
;   addr   pointeur du bloc
; retourne:
;   addr   pointeur du bloc avec NLNK et PLNK � 0
DEFWORD "UNLINK",6,,UNLINK ; ( addr -- addr )
    .word DUP,NLNKFETCH,OVER,PLNKFETCH ; S: addr nlnk plnk
    .word DUP,ZBRANCH,2f-$,TWODUP,NLNKSTORE,BRANCH,4f-$
2:  .word LIT,2,PICK,ULNKFIRST  ; S: addr nlnk plnk  
4:  .word SWAP,DUP,ZBRANCH,8f-$,PLNKSTORE,EXIT    
8:  .word TWODROP
    .word EXIT
    
; ins�re un bloc orphelin au d�but d'une liste
; arguments:
;    addr1  pointeur du bloc � ins�rer
;    list   variable contenant le pointeur de t�te de la liste.
; retourne:
;    rien
DEFWORD "PREPEND",7,,PREPEND ; ( addr1 list -- )
    .word TUCK,EFETCH,DUP,ZBRANCH,2f-$ ; S: list addr1 listhead
    .word TWODUP,PLNKSTORE ; S: list addr1 listhead
2:  .word OVER,NLNKSTORE,SWAP,STORE
    .word EXIT
    
;v�rifie si n < addr->bsize
; arguments:
;    addr   pointeur bloc
; retourne:
;    f   indicateur bool�en
DEFWORD "?FIT",4,,QFIT ;  ( n addr1 -- f )    
    .word BSIZEFETCH,LESS,EXIT

; retourne le pointeur du plus petit bloc
; arguments:
;   addr1   pointeur bloc 1
;   addr2    pointeur bloc 2
DEFWORD "SMALLBLK",8,,SMALLBLK ; ( addr1 addr2 -- addr )
    .word QDUP,ZBRANCH,9f-$
    .word TOR,DUP,ZBRANCH,2f-$,DUP,BSIZEFETCH ; S: addr1 size1 R: addr2
    .word RFETCH,BSIZEFETCH,ULESS,ZBRANCH,2f-$
1:  .word RDROP,EXIT
2:  .word DROP,RFROM
9:  .word EXIT
  
    
; retourne le plus petit bloc de liste
; qui peut contenir 'n' octets.    
; arguments:
;    n       taille requise
;    addr1   t�te de liste.    
; retourne:
;    addr|0    pointeur sur le bloc|0.
DEFWORD "SMALLEST",8,,SMALLEST ; ( n addr1 -- addr|0 )
    .word LIT,0,TOR ; S: n addr1 R: 0
    ; d�but boucle
2:  .word QDUP,ZBRANCH,8f-$    
    .word TWODUP,QFIT,ZBRANCH,4f-$
    .word DUP,RFROM,SMALLBLK,TOR
4:  .word NLNKFETCH,BRANCH,2b-$
8:  .word DROP,RFROM
9:  .word EXIT
  
;enl�ve l'exc�dent du bloc en cr�ant un nouveau bloc libre.
; arguments:
;    n    octets requis
;    addr pointeur bloc � r�duire
; retourne:
;    addr pointeur du bloc de taille ajust�.
DEFWORD "CUT",3,,CUT ; ( n addr -- addr )
    .word DUP,TOR,BSIZEFETCH,OVER,MINUS ; S: n diff R: addr
    .word DUP,LIT,HEAD_SIZE,GREATER,ZBRANCH,8f-$ ; S: n diff R: addr
    .word SWAP,DUP,RFETCH,BSIZESTORE,RFETCH,PLUS ; S: diff addr2 R: addr
    .word LIT,HEAD_SIZE,TUCK,PLUS,TOR,MINUS,RFETCH,BSIZESTORE ; R: addr2 addr
    .word RFROM,FREELIST,PREPEND
    .word HEAPFREE,LIT,HEAD_SIZE,MINUS,FREE_BYTES_STORE
    .word RFROM,EXIT
8:  .word TWODROP,RFROM,EXIT    
  
; allocation d'un bloc de m�moire
; recherche d'un bloc libre dont la taille est le plus
; proche possible de n.
; retourne un pointeur sur le data.
;  arguments:
;     n    grandeur requise
;  retourne
;     addr|0   
DEFWORD "MALLOC",6,,MALLOC ; ( n -- addr|0 )
    .word ALIGNED ; n doit-�ter pair.
    .word DUP,FREEHEAD,SMALLEST ; S: n addr|0
    .word DUP,TBRANCH,2f-$
    .word SWAP,DROP,EXIT
2:  ; S: n addr
    .word UNLINK,CUT,DUP,BSIZEFETCH,HEAPFREE,SWAP,MINUS,FREE_BYTES_STORE
    .word DUP,USEDLIST,PREPEND
9:  .word EXIT
    
;lib�ration d'un bloc m�moire
; 1) sortir le bloc de la liste des allou�s.
; 2) ins�rer le bloc au d�but de la liste des libres.  
; arguments:
;   addr pointeur retourn� par MALLOC    
DEFWORD "BLKFREE",7,,BLKFREE ; ( addr -- )
    .word DUP,ZBRANCH,9f-$
    .word UNLINK,DUP,BSIZEFETCH,HEAPFREE,PLUS,FREE_BYTES_STORE
    .word FREELIST,PREPEND
9:  .word EXIT
   
; �changes liens PLNK et NLNK des 2 blocs
; arguments:
;    addr1   pointeur bloc 1
;    addr2   pointeur bloc 2
DEFWORD "LNKSWAP",7,,LNKSWAP ; ( addr1 addr2 -- )
    .word TOR
    .word DUP,PLNKFETCH,RFETCH,PLNKFETCH,ROT ; S: plnk1 plnk2 addr1 R: addr2
    .word DUP,NLNKFETCH,RFETCH,NLNKFETCH,ROT ; S: plnk1 plnk2 nlnk1 nlnk2 addr1 R: addr2
    .word DUP,TOR,NLNKSTORE,SWAP,RFROM,PLNKSTORE ; S: plnk1 nlnk1 R: addr2
    .word RFETCH,NLNKSTORE,RFROM,PLNKSTORE,EXIT
    
; interchange les 2 �l�ments si le premier est plus grand
; que le deuxi�me.
; arguments:
;    addr1   premier pointeur de bloc
;    addr2   deuxi�me pointeur de bloc
; retourne:
;    addr   pointeur vers l'�l�ment qui viens en second.
DEFWORD "BSORT",5,,BSORT ; ( addr1 addr2 -- addr < addr )
    .word TWODUP,UGREATER,ZBRANCH,8f-$
    .word SWAP,TWODUP,LNKSWAP  
8:  .word EXIT

; fusionne 2 blocs s'ils sont adjacents
; arguments:
;   addr1   pointeur bloc 1
;   addr2   pointeur bloc 2
; retourne:
;   f    indicateur bool�en de fusion
DEFWORD "BMERGE",6,F_HIDDEN,BMERGE  ; ( addr1 addr2 -- f )
    .word BSORT,TOR,DUP,BSIZEFETCH,LIT,HEAD_SIZE,PLUS ; S: addr size R: addr
    .word OVER,PLUS,RFETCH,EQUAL,ZBRANCH,8f-$
    .word RFETCH,BSIZEFETCH,LIT,HEAD_SIZE,PLUS,OVER,BSIZESTORE
    .word RFROM,NLNKFETCH,SWAP,NLNKSTORE,LIT,HEAD_SIZE,HEAPFREE,PLUS
    .word FREE_BYTES_STORE
    .word LIT,-1,EXIT
8:  .word RFROM,TWODROP,LIT,0,EXIT    
    
;trie croissant des �l�ments de la liste cha�n�e
; le trie se fait sur le pointeur du bloc
; bubble sort: lent mais simple.
; arguments:
;   addr1  pointeur t�te de liste
; retourne:
;   addr2  pointeur nouvelle t�te de liste.  
DEFWORD "LISTSORT",8,F_HIDDEN,LISTSORT ; ( addr1 -- addr2 )
    .word LIT,0,SWAP ; ins�rer indicateur de commutation
2:  ; begin loop
    .word DUP,NLNKFETCH,QDUP,ZBRANCH,4f-$
    .word OVER,LESS,ZBRANCH,2b-$
4:  .word OVER,TBRANCH,2b-$ ; while
    
    
;d�fragmentation des block libres
; 1) trier la liste ordre croissant des pointeurs.  
; 2) fusionner les blocs contigus  
DEFWORD "HDEFRAG",7,F_HIDDEN,HDEFRAG ; ( -- )
    .word FREELIST,LISTSORT
    .word EXIT
    
  