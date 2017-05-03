;****************************************************************************
; Copyright 2015, 2016, 2017 Jacques Deschenes
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

; NOM: block.s
; DATE: 2017-04-24
; DESCRIPTION: implémentation des mots de gestion de fichiers par blocs tel
;   que définis ici: http://lars.nocrew.org/forth2012/block.html
;           ou  ici: http://lars.nocrew.org/dpans/dpans7.htm#7.6.1    
; NOTES:
;  1) Les blocs sont de 1024 octets par tradition car à l'époque où
;     Charles Moore a développé ce système il l'utilisait pour stocker
;     les écrans du moniteur sous forme de texte source. Le moniteur qu'il
;     utilisait affichait 16 lignes de 64 caractères donc 1024 caractères.
;     Son éditeur de texte fonctionnait par pages écran.
;    
;  2) La numérotation des blocs de stockage commence à 1.     
    
;  buffers pour les bloc de fichiers.    
.equ MAX_BUFFERS, 4    ; nombre maximum de buffers utilisés.
.equ BUFFER_SIZE, 1024
.equ BLOCK_SIZE, BUFFER_SIZE
		     
; buffer structure
.equ BUFFER_ADDR, 0  ; adresse du buffer dans l'EDS, 0 signifie inutilisé.
.equ BLOCK_NBR, 2    ; numéor du bloc sur la mémoire de masse
.equ UPDATE_CNTR, 4  ; compteur de mises à jour, le compteur qui contient
                     ; le plus gros chiffre est celui qui a été mis à jour
		     ; en dernier. Si 0 le buffer n'a pas été modifié.
.equ BUFFER_STRUCT_SIZE, 6

.section .hardware.bss  bss
.align 2		     
;espace réservé pour les descripteurs de blocs.
_blk_buffers: .space MAX_BUFFERS*BUFFER_STRUCT_SIZE
_blk: .space 2 ; numéro du bloc actuellement en traitement.
_update_cntr: .space 2  ; incrémenté chaque fois qu'un buffer est mis à jour.
                        ; cette valeur incrémentée est copiée dans le champ UPDATE_CNTR.
; identifiant du stockage de masse actif {_SPIEEPROM, _SPIRAM,_SDCARD}
_block_dev: .space 2 
 
 
; allocation de mémoire dynamique pour les buffers
HEADLESS BLOCK_INIT, HWORD
    .word LIT,_blk_buffers,LIT,MAX_BUFFERS,LIT,0,DODO ; S: _blk_buffers
1:  .word LIT,BUFFER_SIZE,MALLOC,OVER
    .word LIT,BUFFER_STRUCT_SIZE,DOI,STAR,PLUS,STORE
    .word DOLOOP,1b-$,DROP
    .word EXIT
 
; convertie no de buffer en a-addr début structure
; arguments:
;    n   no de buffer
; retourne:
;    a-addr:  adresse début de la structure
HEADLESS STRUCADDR, HWORD ; ( n -- a-addr )
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word LIT,_blk_buffers,PLUS,EXIT
    
    
; ?BUFFERED vérifie si le bloc est dans un buffer
; arguments:
;   u   no. du bloc recherché.
; retourne:
;   n  no du buffer si le bloc est dans un buffer.|
;      -1 si le bloc n'est pas dans un buffer.    
HEADLESS QBUFFERED, HWORD ; ( u -- n|-1 )
    .word LIT,_blk_buffers,LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BUFFER_STRUCT_SIZE,DOI,STAR,OVER,PLUS
    .word LIT,BLOCK_NBR,PLUS,FETCH,OVER,EQUAL,ZBRANCH,2f-$
    .word TWODROP,DOI,UNLOOP,BRANCH,9f-$
    .word DOLOOP,1b-$,TWODROP,LIT,-1
9:  .word EXIT
   
; ?NOTUSED  recherche un buffer libre
; si le champ BLOCK_ADDR==0 le bloc est libre.
; arguments:
;   aucun
; retourne:
;   n    no. de bloc libre trouvé |
;        -1 si aucun libre
HEADLESS QNOTUSED, HWORD ; ( -- n )
    .word LIT, MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BUFFER_STRUCT_SIZE,DOI,STAR,FETCH
    .word TBRANCH,2f-$
    .word DOI,UNLOOP,BRANCH,9f-$
2:  .word DOLOOP,1b-$,LIT,-1
9:  .word EXIT
  
; OLDEST recherche le buffer dont la dernière
; modification est la plus ancienne.
; arguments:
;   aucun
; retourne:
;    n    no. du buffer dont UPDATE_CNTR est le plus petit.  
HEADLESS OLDEST,HWORD ; ( -- n )  
    .word LIT,0,LIT,0xffff,LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,LIT,BUFFER_STRUCT_SIZE,STAR
    .word LIT,_blk_buffers,PLUS,LIT,UPDATE_CNTR,PLUS
    .word FETCH,OVER,TWODUP,LESS,ZBRANCH,2f-$
    .word DROP,DOI,NROT,SWAP,DROP,BRANCH,4f-$
2:  .word TWODROP
4:  .word DOLOOP,1b-$
9:  .word DROP,EXIT
  
; est-ce que le buffer a été modifié?
; arguments:
;   n  no. du buffer
; retourne:
;   u valeur du UPDATE_CNTR  
HEADLESS QUPDATE, HWORD ; ( n -- f )
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word LIT,UPDATE_CNTR,PLUS
    .word LIT,_blk_buffers,PLUS,FETCH
    .word EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; vocabulaire de base
;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: BLK    
;   ref: 7.6.1.0790 BLK
;   variable qui contient le no de bloc  
;   actuellement interprété ou 0
; arguments:
;   aucun
; retourne:
;   a-addr|0  a-addr est l'adresse de la cellule contenant le no. de bloc.    
DEFCODE "BLK",3,,BLK ; ( -- a-addr|0)
    DPUSH
    mov #_blk,T
    NEXT

; nom: BLOCK>ADR ( n -- ud )   
;   convertiE un numéro de bloc en adresse 32 bits. Qui correspond
;   à la position sur le média de stockage.    
; arguments:
;    n   numéro de bloc
; retourne:
;    ud  adresse 32 bits sur le périphérique de stockage    
DEFWORD "BLOCK>ADR",9,,BLOCKTOADR ; ( n -- ud )
    .word LIT,BLOCK_SIZE,UMSTAR,EXIT
    
; nom: BUF>EE  ( a-addr n -- )  
;   Écriture d'un buffer dans d'un bloc de l'EEPROM.
; arguments:
;    a-addr    adresse du buffer
;    n    numéro du bloc sur le périphérique de stockage
;  retourne:
;    rien    
DEFWORD "BUF>EE",6,,BUFTOEE ; ( a-addr n -- )
    .word LIT,BLOCK_SIZE,SWAP,BLOCKTOADR,RAMTOEE
    .word EXIT
    
; nom: EE>BUF ( a-addr n -- )
; Lecture d'un bloc dans un buffer à partir de l'EEPROM
; arguments:
;    a-addr    adresse du buffer
;    n    numéro du bloc sur le périphérique de stockage
;  retourne:
;    rien    
DEFWORD "EE>BUF",6,,EETOBUF ; ( a-addr n -- )
    .word LIT,BLOCK_SIZE,SWAP,BLOCKTOADR,EEREAD,EXIT
    
; sauvegarde du buffer sur stockage
; remise à zéro de UPDATE_CNTR    
; arguments:
;   n   no du buffer.    
DEFWORD "WRITEBACK",9,,WRITEBACK ; ( n -- )
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word DUP,FETCH,OVER,BUFTOEE
    .word LIT,UPDATE_CNTR,PLUS,LIT,0,SWAP,STORE
    .word EXIT
    
; 7.6.1.0800 BLOCK
; retourne l'adresse d'un buffer pour le bloc.
; le no. de bloc est stocké dans _blk
; arguments:
;   u   no. du bloc requis.
; retourne:    
;  a-addr  addresse du buffer contenant le block    
DEFWORD "BLOCK",5,,BLOCK ; ( u -- a-addr )    
    ; est-ce que le bloc est déjà dans un buffer?
    .word DUP,QBUFFERED,DUP,ONEPLUS,ZBRANCH,2f-$
    ; il est dans un buffer.
    .word LIT,BUFFER_STRUCT_SIZE,STAR,FETCH
    .word SWAP,DROP,EXIT
    ; il n'est pas dans un buffer
    ; est-ce qu'il y a un buffer libre?
2:  .word  QNOTUSED,DUP,ONEPLUS,ZBRANCH,2f-$
    .word  BRANCH,4f-$ 
    ;aucun buffer libre, doit en libéré un,
    ;celui dont UPDATE_CNTR est le plus petit.
2:  .word OLDEST,DUP,QUPDATE,ZBRANCH,4f,DUP,WRITEBACK
    ; chargement du bloc dans le buffer. S: u n  
4:    
9:  .word EXIT
  
  
; 7.6.1.0820 BUFFER
; 7.6.1.1360 EVALUATE   ; voir core.s
; 7.6.1.1559 FLUSH
; 7.6.1.1790 LOAD
; 7.6.1.2180 SAVE-BUFFERS
; 7.6.1.2400 UPDATE

;;;;;;;;;;;;;;;;;;;;;;;;;; 
; vocabulaire édendue. 
;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; 7.6.2.1330 EMPTY-BUFFERS
; 7.6.2.1770 LIST
; 7.6.2.2125 REFILL
; 7.6.2.2190 SCR
; 7.6.2.2280 THRU
; 7.6.2.2535 \ extension de la sémentique des commentaires voir core.s
 

