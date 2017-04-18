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
    clr W0
    mov W0,_heap_used
    NEXT
    
; retourne la grandeur du HEAP
DEFCONST "HEAPSIZE",8,,HEAPSIZE,HEAP_SIZE ; ( -- n )

; retourne la grandeur libre
DEFCODE "HEAPFREE",8,,HEAPFREE ; ( -- n )
    SET_EDS
    DPUSH
    mov _heap_free,W0
    mov [W0-HEAD_SIZE],T
    RESET_EDS
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
DEFWORD "?BSIZE",6,,QBSIZE ; ( addr -- n )
    .word LIT,HEAD_SIZE,MINUS,EFETCH,EXIT
    
; retourne le pointeur sur le prochain bloc
; arguments:
;    addr1 adresse retournée par MALLOC
; retourne:
;   addr2  adresse du prochain bloc dans la chaîne.
DEFWORD "NEXTLNK",7,,NEXTLNK ; ( addr1 -- addr2 )
    .word LIT,NLNK,MINUS,EFETCH,EXIT
    
; retourne le pointeur sur le bloc précédent
; arguments:
;   addr1   adresse retournée par MALLOC
; retourne:
;   addr2  adresse du bloc précédent dans la chaîne.    
DEFWORD "PREVLNK",7,,PREVLNK ; ( addr1 -- addr2 )
    .word LIT,PLNK,MINUS,EFETCH,EXIT
    
; allocation d'un bloc de mémoire
; retourne un pointeur sur le data.
;  arguments:
;     n    grandeur requise
;  retourne
;     addr|0   
DEFWORD "MALLOC",6,,MALLOC ; ( n -- addr|0 )
    .word DUP,ODD,ZBRANCH,2f-$,ONEPLUS 
2:  .word HEAPFREE,OVER,LESS,ZBRANCH,2f-$
    .word DROP,LIT,0,EXIT ;trop grrand.
    .word FREELIST,DUP,QBSIZE,HEAPSIZE ; n freelist freesize heapsize
    .word TWOTOR,OVER,TWORFROM  ; n freelist n freesize heapsize
    .word WITHIN  ; n freelist f
    
9:  .word EXIT
    
;libération d'un bloc mémoire
; arguments:
;   addr pointeur retourné par MALLOC    
DEFWORD "BLKFREE",7,,BLKFREE ; ( addr -- )
    .word 
9:  .word EXIT
    
    