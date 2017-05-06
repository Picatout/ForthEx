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
; DESCRIPTION: impl�mentation des mots de gestion de fichiers par blocs tel
;   que d�finis ici: http://lars.nocrew.org/forth2012/block.html
;           ou  ici: http://lars.nocrew.org/dpans/dpans7.htm#7.6.1    
; NOTES:
;  1) Les blocs sont de 1024 octets par tradition car � l'�poque o�
;     Charles Moore a d�velopp� ce syst�me il l'utilisait pour stocker
;     les �crans du moniteur sous forme de texte source. Le moniteur qu'il
;     utilisait affichait 16 lignes de 64 caract�res donc 1024 caract�res.
;     Son �diteur de texte fonctionnait par pages �cran.
;    
;  2) La num�rotation des blocs de stockage commence � 1.     
    
;  buffers pour les bloc de fichiers.    
.equ MAX_BUFFERS, 4    ; nombre maximum de buffers utilis�s.
.equ BUFFER_SIZE, 1024
.equ BLOCK_SIZE, BUFFER_SIZE
		     
; buffer structure
.equ BUFFER_ADR, 0   ; adresse du buffer dans l'EDS, 0 signifie inutilis�.
.equ BLOCK_NBR, 1    ; num�or du bloc sur la m�moire de masse
.equ DEVICE, 2       ; � quelle p�riph�rique appartient ce bloc.
.equ UPDATED, 3  ; compteur de mises � jour, le compteur qui contient
                     ; le plus gros chiffre est celui qui a �t� mis � jour
		     ; en dernier. Si 0 le buffer n'a pas �t� modifi�.
		     
.equ BUFFER_STRUCT_SIZE, 8

.section .hardware.bss  bss
.align 2		     
;espace r�serv� pour les descripteurs de blocs.
_blk_buffers: .space MAX_BUFFERS*BUFFER_STRUCT_SIZE
_blk: .space 2 ; num�ro du bloc actuellement en traitement.
_update_cntr: .space 2  ; incr�ment� chaque fois qu'un buffer est mis � jour.
                        ; cette valeur incr�ment�e est copi�e dans le champ UPDATED.
; identifiant du stockage de masse actif {EEPROM, XRAM, SDCARD}
_block_dev: .space 2 
 
 
; allocation de m�moire dynamique pour les buffers
HEADLESS BLOCK_INIT, HWORD
    .word LIT,_blk_buffers,LIT,MAX_BUFFERS,LIT,0,DODO ; S: _blk_buffers
1:  .word LIT,BUFFER_SIZE,MALLOC,OVER
    .word LIT,BUFFER_STRUCT_SIZE,DOI,STAR,PLUS,STORE
    .word DOLOOP,1b-$,DROP
    ; p�riph�rique par d�faut EEPROM
    .word LIT,EEPROM,BLOCKDEV,STORE
    .word EXIT
 
; convertie no de buffer en adresse d�but structure
; arguments:
;    n   no de buffer
; retourne:
;    u:  adresse d�but de la structure
HEADLESS STRUCADR, HWORD ; ( n -- u )
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word LIT,_blk_buffers,PLUS,EXIT
    
; nom: SAME? 
;    V�rifie si le no. de bloc et l'identifiant p�riphique correspondent
;    � ce buffer.
; arguments:
;    n+    num�ro de block
;    u     identifiant p�riph�rique de stockage
;    a-addr   adresse de la structure BUFFER
; retourne:
;    f    indicateur bool�en vrai si n+==BLOCK_NBR && u==DEVICE
DEFWORD "=BUFFER",7,,EQBUFFER
    .word TOR,LIT,DEVICE,RFETCH,TBLFETCH
    .word EQUAL,ZBRANCH,8f-$
    .word LIT,BLOCK_NBR,RFROM,TBLFETCH
    .word EQUAL,EXIT
8:  .word DROP,RDROP,LIT,0,EXIT
  
  
; nom: BUFFERED?  ( n+ u -- n|-1)
;   v�rifie si le bloc est dans un buffer
; arguments:
;   n+  num�ro du bloc recherch�.    
;   u   identifiant p�riph�rique
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
;   n    no. de bloc libre trouv� |
;        -1 si aucun libre
HEADLESS NOTUSED, HWORD ; ( -- n )
    .word LIT, MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,LIT,BLOCK_NBR,SWAP,TBLFETCH
    .word ZBRANCH,2f-$
    .word DOI,UNLOOP,BRANCH,9f-$
2:  .word DOLOOP,1b-$,LIT,-1
9:  .word EXIT
  
; OLDEST recherche le buffer dont la derni�re
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
;   Est-ce que le buffer a �t� modifi�?
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
;   actuellement interpr�t�
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la variable
DEFCODE "BLK",3,,BLK ; ( -- a-addr)
    DPUSH
    mov #_blk,T
    NEXT

; nom: BLOCKDEV  ( -- a-addr )
;    variable contenant l'adresse du descripteur du p�riph�rique
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
;   retourne l'identiant du p�riph�rique de stockage actif.
; arguments:
;    
; retourne:
;    n    indenfiant du p�riph�rique
DEFWORD "BLKDEV?",7,,BLKDEVQ
    .word LIT,DEVID,BLOCKDEV,FETCH,TBLFETCH,EXIT
    
    
; nom: BLOCK>ADR ( n -- ud )       ; adresse de la structure du BUFFER
    .word STRUCADR,TOR
    ; @ adresse du buffer.
    .word LIT,BUFFER_ADR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ p�riph�rique
    .word LIT,DEVICE,RFETCH,TBLFETCH,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC

;   convertiE un num�ro de bloc en adresse 32 bits. Qui correspond
;   � la position sur le m�dia de stockage.    
; arguments:
;    n   num�ro de bloc
; retourne:
;    ud  adresse 32 bits sur le p�riph�rique de stockage    
DEFWORD "BLOCK>ADR",9,,BLOCKTOADR ; ( n -- ud )
    .word BLOCKDEV,FETCH,LIT,FN_BLKTOADR,VEXEC,EXIT
    
; nom: BUFPARAM  ( n -- u1 u2 u3 u4 )
;   Obtient les param�tres du buffer � partir de son num�ro
; arguments:
;    n   num�ro du buffer
; retourne:
;   u1    adresse du premier octet de donn�e
;   u2    num�ro du bloc    
;   u3    indentifiant du p�riph�rique
;   u4    adresse de la structure buffer    
DEFWORD "BUFPARAM",8,,BUFPARAM
    ; adresse de la structure buffer
    .word STRUCADR,TOR
    ; @ adresse du buffer.
    .word LIT,BUFFER_ADR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ p�riph�rique
    .word LIT,DEVICE,RFETCH,TBLFETCH,DUP
    .word RFROM,EXIT

; nom: UPDATE  ( n -- )
;    Met � jour le compteur UPDATED avec la valeur
;    incr�ment�e de _update_cntr
; param�tre:
;    n   num�ro de la structure buffer
; retourne:    
;
DEFWORD "UPDATE",6,,UPDAT
    ; incr�mente _update_cntr
    .word LIT,1,LIT,_update_cntr,PLUSSTORE
    .word LIT,_update_cntr,FETCH,QDUP,ZBRANCH,2f-$
    .word SWAP,STRUCADR,LIT,UPDATED,SWAP,TBLSTORE,EXIT
2:  ; si _update_cntr a fait un rollover on sauvegarde
    ; tous les buffers modifi�s.
    .word DROP,SAVEBUFFERS,EXIT
    
; nom: NOUPDATE  ( u1 -- )
;   Remet le compteur UPDATE_CTNR � z�ro
; arguments:
;   u1     adresse de la structure BUFFER
; retourne:
;    
DEFWORD "NOUPDATE",8,,NOUPDATE
    .word TOR,LIT,0,LIT,UPDATED,RFROM,TBLSTORE,EXIT
    
; nom: WRITEBACK ( n -- )    
;   Sauvegarde du buffer sur stockage
;   remise � z�ro de UPDATED.
; arguments:
;   n   no du buffer.
; retourne:
;    
DEFWORD "BUFFER>",7,,BUFFEROUT ; ( n -- )
    .word BUFPARAM ; S: buf-addr  no-block devid *struc
    .word TOR,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC
    ; �criture
    .word RFROM,LIT,FN_WRITE,VEXEC
    ; raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
; nom: ">BUFFER"  ( n -- )
;   Charge un bloc dans un bufffer. Le buffer est pr�inialis� avec
;   le num�ro du bloc,le device et UPDATED � 0.
; arguments:
;   n    num�ro du buffer.
; retourne:
;     
DEFWORD ">BUFFER",7,,INBUFFER
    .word BUFPARAM,TOR,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC
    ;lecture des  donn�es
    .word RFROM,LIT,FN_READ,VEXEC
    ;raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
    
; nom: BLOCK  ( n+ -- u )
;   Retourne l'adresse d'un buffer pour le bloc.
;   Le no. de bloc est stock� dans _blk
; arguments:
;   u   no. du bloc requis.
; retourne:    
;  a-addr  addresse du buffer contenant les donn�es du bloc.    
DEFWORD "BLOCK",5,,BLOCK ; ( u -- a-addr )    
    ; est-ce que le bloc est d�j� dans un buffer?
    .word DUP,BUFFEREDQ,DUP,ONEPLUS,ZBRANCH,2f-$
    ; il est dans un buffer.
    .word DUP,BLK,STORE,STRUCADR,LIT,BUFFER_ADR,SWAP,TBLFETCH
    .word SWAP,DROP,EXIT
    ; il n'est pas dans un buffer
    ; est-ce qu'il y a un buffer libre?
2:  .word  NOTUSED,DUP,ONEPLUS,ZBRANCH,2f-$
    .word  BRANCH,4f-$ 
    ;aucun buffer libre, doit en lib�r� un,
    ;celui dont UPDATED est le plus petit.
2:  .word OLDEST,DUP,UPDATEQ,ZBRANCH,4f,DUP,BUFFEROUT
    ; chargement du bloc dans le buffer. S: u n  
4:    
9:  .word EXIT
  


  
; nom: BUFFER  ( u -- a-addr )
;   Retourne l'adresse d'un buffer. Si aucun buffer n'est disponible
;   lib�re celui qui � la plus petite valeur UPDATED.
;   Contrairement � BLOCK il n'y a pas de lecture du p�riph�rique de stockage.  
; arguments:
;   u    num�ro du bloc � assign� � ce buffer.
; retourne:
;    a-addr   adresse d�but de la zone de donn�es du buffer.
DEFWORD "BUFFER",6,,BUFFER
    .word DUP,BUFFEREDQ,DUP,ONEPLUS,ZBANCH,2f-$
    ; il y a d�j� un  buffer d'assign� � ce bloc
    .word EXIT
  
; 7.6.1.1360 EVALUATE   ; voir core.s
; 7.6.1.1559 FLUSH
; 7.6.1.1790 LOAD

; nom: SAVE-BUFFERS ( -- )  
;   Sauvegarde tous les buffers qui ont �t� modifi�s.
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
; vocabulaire �dendue. 
;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; 7.6.2.1330 EMPTY-BUFFERS
; 7.6.2.1770 LIST
; 7.6.2.2125 REFILL
; 7.6.2.2190 SCR
; 7.6.2.2280 THRU
; 7.6.2.2535 \ extension de la s�mentique des commentaires voir core.s
 

