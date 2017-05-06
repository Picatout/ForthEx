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
.equ BUFFER_ADR, 0   ; adresse du buffer dans l'EDS, 0 signifie inutilisé.
.equ BLOCK_NBR, 1    ; numéor du bloc sur la mémoire de masse
.equ DEVICE, 2       ; à quelle périphérique appartient ce bloc.
.equ UPDATED, 3  ; compteur de mises à jour, le compteur qui contient
                     ; le plus gros chiffre est celui qui a été mis à jour
		     ; en dernier. Si 0 le buffer n'a pas été modifié.
		     
.equ BUFFER_STRUCT_SIZE, 8

.section .hardware.bss  bss
.align 2		     
;espace réservé pour les descripteurs de blocs.
_blk_buffers: .space MAX_BUFFERS*BUFFER_STRUCT_SIZE
_blk: .space 2 ; numéro du bloc actuellement en traitement.
_update_cntr: .space 2  ; incrémenté chaque fois qu'un buffer est mis à jour.
                        ; cette valeur incrémentée est copiée dans le champ UPDATED.
; identifiant du stockage de masse actif {EEPROM, XRAM, SDCARD}
_block_dev: .space 2 
 
 
; allocation de mémoire dynamique pour les buffers
HEADLESS BLOCK_INIT, HWORD
    .word LIT,_blk_buffers,LIT,MAX_BUFFERS,LIT,0,DODO ; S: _blk_buffers
1:  .word LIT,BUFFER_SIZE,MALLOC,OVER
    .word LIT,BUFFER_STRUCT_SIZE,DOI,STAR,PLUS,STORE
    .word DOLOOP,1b-$,DROP
    ; périphérique par défaut EEPROM
    .word LIT,EEPROM,BLOCKDEV,STORE
    .word EXIT
 
; convertie no de buffer en adresse début structure
; arguments:
;    n   no de buffer
; retourne:
;    u:  adresse début de la structure
HEADLESS STRUCADR, HWORD ; ( n -- u )
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word LIT,_blk_buffers,PLUS,EXIT
    
; nom: SAME? 
;    Vérifie si le no. de bloc et l'identifiant périphique correspondent
;    à ce buffer.
; arguments:
;    n+    numéro de block
;    u     identifiant périphérique de stockage
;    a-addr   adresse de la structure BUFFER
; retourne:
;    f    indicateur booléen vrai si n+==BLOCK_NBR && u==DEVICE
DEFWORD "=BUFFER",7,,EQBUFFER
    .word TOR,LIT,DEVICE,RFETCH,TBLFETCH
    .word EQUAL,ZBRANCH,8f-$
    .word LIT,BLOCK_NBR,RFROM,TBLFETCH
    .word EQUAL,EXIT
8:  .word DROP,RDROP,LIT,0,EXIT
  
  
; nom: BUFFERED?  ( n+ u -- n|-1)
;   vérifie si le bloc est dans un buffer
; arguments:
;   n+  numéro du bloc recherché.    
;   u   identifiant périphérique
; retourne:
;   n  no du buffer si le bloc est dans un buffer.|
;      -1 si le bloc n'est pas dans un buffer.    
HEADLESS BUFFEREDQ, HWORD
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word TWODUP,DOI,STRUCADR,EQBUFFER
    .word TBRANCH,8f-$
    .word LOOP,1b-$,TWODROP,LIT,-1,EXIT
8:  .word TWODROP,DOI,UNLOOP,EXIT
   
; NOTUSED  recherche un buffer libre
; si le champ BLOCK_NBR==0 le bloc est libre.
; arguments:
;   aucun
; retourne:
;   n    no. de bloc libre trouvé |
;        -1 si aucun libre
HEADLESS NOTUSED, HWORD ; ( -- n )
    .word LIT, MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,LIT,BLOCK_NBR,SWAP,TBLFETCH
    .word ZBRANCH,2f-$
    .word DOI,UNLOOP,BRANCH,9f-$
2:  .word DOLOOP,1b-$,LIT,-1
9:  .word EXIT
  
; OLDEST recherche le buffer dont la dernière
; modification est la plus ancienne.
; arguments:
;   aucun
; retourne:
;    n    no. du buffer dont UPDATED est le plus petit.  
HEADLESS OLDEST,HWORD ; ( -- n )  
    .word LIT,0xffff,LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,LIT,UPDATED,SWAP,TBLFETCH
    .word TWODUP,LESS,TBRANCH,2f-$
    .word SWAP
2:  .word DROP,DOLOOP,1b-$
9:  .word EXIT
  
; nom: UPDATE?  
;   Est-ce que le buffer a été modifié?
; arguments:
;   n  no. du buffer
; retourne:
;   u valeur du UPDATED  
HEADLESS UPDATEQ, HWORD ; ( n -- u )
    .word STRUCADR,LIT,UPDATED,SWAP,TBLFETCH
    .word EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; vocabulaire de base
;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: BLK    
;   ref: 7.6.1.0790 BLK
;   variable qui contient le no de bloc  
;   actuellement interprété
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la variable
DEFCODE "BLK",3,,BLK ; ( -- a-addr)
    DPUSH
    mov #_blk,T
    NEXT

; nom: BLOCKDEV  ( -- a-addr )
;    variable contenant l'adresse du descripteur du périphérique
;    de stockage actif.
; arguments:
;    aucun
; retourne:
;    a-addr  adresse de la variable _block_dev
DEFCODE "BLOCKDEV",8,,BLOCKDEV
    DPUSH
    mov #_block_dev,T
    NEXT
    
; nom: BLKDEV?  ( -- n )
;   retourne l'identiant du périphérique de stockage actif.
; arguments:
;    
; retourne:
;    n    indenfiant du périphérique
DEFWORD "BLKDEV?",7,,BLKDEVQ
    .word LIT,DEVID,BLOCKDEV,FETCH,TBLFETCH,EXIT
    
    
; nom: BLOCK>ADR ( n -- ud )       ; adresse de la structure du BUFFER
    .word STRUCADR,TOR
    ; @ adresse du buffer.
    .word LIT,BUFFER_ADR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ périphérique
    .word LIT,DEVICE,RFETCH,TBLFETCH,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC

;   convertiE un numéro de bloc en adresse 32 bits. Qui correspond
;   à la position sur le média de stockage.    
; arguments:
;    n   numéro de bloc
; retourne:
;    ud  adresse 32 bits sur le périphérique de stockage    
DEFWORD "BLOCK>ADR",9,,BLOCKTOADR ; ( n -- ud )
    .word BLOCKDEV,FETCH,LIT,FN_BLKTOADR,VEXEC,EXIT
    
; nom: BUFPARAM  ( n -- u1 u2 u3 u4 )
;   Obtient les paramètres du buffer à partir de son numéro
; arguments:
;    n   numéro du buffer
; retourne:
;   u1    adresse du premier octet de donnée
;   u2    numéro du bloc    
;   u3    indentifiant du périphérique
;   u4    adresse de la structure buffer    
DEFWORD "BUFPARAM",8,,BUFPARAM
    ; adresse de la structure buffer
    .word STRUCADR,TOR
    ; @ adresse du buffer.
    .word LIT,BUFFER_ADR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ périphérique
    .word LIT,DEVICE,RFETCH,TBLFETCH,DUP
    .word RFROM,EXIT

; nom: UPDATE  ( n -- )
;    Met à jour le compteur UPDATED avec la valeur
;    incrémentée de _update_cntr
; paramètre:
;    n   numéro de la structure buffer
; retourne:    
;
DEFWORD "UPDATE",6,,UPDAT
    ; incrémente _update_cntr
    .word LIT,1,LIT,_update_cntr,PLUSSTORE
    .word LIT,_update_cntr,FETCH,QDUP,ZBRANCH,2f-$
    .word SWAP,STRUCADR,LIT,UPDATED,SWAP,TBLSTORE,EXIT
2:  ; si _update_cntr a fait un rollover on sauvegarde
    ; tous les buffers modifiés.
    .word DROP,SAVEBUFFERS,EXIT
    
; nom: NOUPDATE  ( u1 -- )
;   Remet le compteur UPDATE_CTNR à zéro
; arguments:
;   u1     adresse de la structure BUFFER
; retourne:
;    
DEFWORD "NOUPDATE",8,,NOUPDATE
    .word TOR,LIT,0,LIT,UPDATED,RFROM,TBLSTORE,EXIT
    
; nom: WRITEBACK ( n -- )    
;   Sauvegarde du buffer sur stockage
;   remise à zéro de UPDATED.
; arguments:
;   n   no du buffer.
; retourne:
;    
DEFWORD "BUFFER>",7,,BUFFEROUT ; ( n -- )
    .word BUFPARAM ; S: buf-addr  no-block devid *struc
    .word TOR,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC
    ; écriture
    .word RFROM,LIT,FN_WRITE,VEXEC
    ; raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
; nom: ">BUFFER"  ( n -- )
;   Charge un bloc dans un bufffer. Le buffer est préinialisé avec
;   le numéro du bloc,le device et UPDATED à 0.
; arguments:
;   n    numéro du buffer.
; retourne:
;     
DEFWORD ">BUFFER",7,,INBUFFER
    .word BUFPARAM,TOR,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC
    ;lecture des  données
    .word RFROM,LIT,FN_READ,VEXEC
    ;raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
    
; nom: BLOCK  ( n+ -- u )
;   Retourne l'adresse d'un buffer pour le bloc.
;   Le no. de bloc est stocké dans _blk
; arguments:
;   u   no. du bloc requis.
; retourne:    
;  a-addr  addresse du buffer contenant les données du bloc.    
DEFWORD "BLOCK",5,,BLOCK ; ( u -- a-addr )    
    ; est-ce que le bloc est déjà dans un buffer?
    .word DUP,BUFFEREDQ,DUP,ONEPLUS,ZBRANCH,2f-$
    ; il est dans un buffer.
    .word DUP,BLK,STORE,STRUCADR,LIT,BUFFER_ADR,SWAP,TBLFETCH
    .word SWAP,DROP,EXIT
    ; il n'est pas dans un buffer
    ; est-ce qu'il y a un buffer libre?
2:  .word  NOTUSED,DUP,ONEPLUS,ZBRANCH,2f-$
    .word  BRANCH,4f-$ 
    ;aucun buffer libre, doit en libéré un,
    ;celui dont UPDATED est le plus petit.
2:  .word OLDEST,DUP,UPDATEQ,ZBRANCH,4f,DUP,BUFFEROUT
    ; chargement du bloc dans le buffer. S: u n  
4:    
9:  .word EXIT
  


  
; nom: BUFFER  ( u -- a-addr )
;   Retourne l'adresse d'un buffer. Si aucun buffer n'est disponible
;   libère celui qui à la plus petite valeur UPDATED.
;   Contrairement à BLOCK il n'y a pas de lecture du périphérique de stockage.  
; arguments:
;   u    numéro du bloc à assigné à ce buffer.
; retourne:
;    a-addr   adresse début de la zone de données du buffer.
DEFWORD "BUFFER",6,,BUFFER
    .word DUP,BUFFEREDQ,DUP,ONEPLUS,ZBANCH,2f-$
    ; il y a déjà un  buffer d'assigné à ce bloc
    .word EXIT
  
; 7.6.1.1360 EVALUATE   ; voir core.s
; 7.6.1.1559 FLUSH
; 7.6.1.1790 LOAD

; nom: SAVE-BUFFERS ( -- )  
;   Sauvegarde tous les buffers qui ont été modifiés.
; arguments:
;
; retourne:
;  
DEFWORD "SAVE-BUFFERS",12,,SAVEBUFFERS
    .word LIT,MAX_BUFFERS,LIT,0,DO
1:  .word DOI,STRUCADR
    .word LIT,BLOCK_NBR,OVER,TBLFETCH
    .word TBRANCH,2f-$,DROP,BRANCH,4f-$
2:  .word LIT,UPDATED,SWAP,TBLFETCH
    .word ZBRANCH,4f-$
    .word DOI,BUFFEROUT
4:  .word DOLOOP,1b-$    
    .word EXIT
    

;;;;;;;;;;;;;;;;;;;;;;;;;; 
; vocabulaire édendue. 
;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; 7.6.2.1330 EMPTY-BUFFERS
; 7.6.2.1770 LIST
; 7.6.2.2125 REFILL
; 7.6.2.2190 SCR
; 7.6.2.2280 THRU
; 7.6.2.2535 \ extension de la sémentique des commentaires voir core.s
 

