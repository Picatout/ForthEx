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

;struct BUFFER{
;    char* DATA_ADDR;
;    unsigned BLOCK_NBR;
;    device* DEVICE
;    unsigned UPDATED
;};
		     
; chamsp de la structure BUFFER
.equ DATA_ADDR, 0    ; adresse du buffer dans l'EDS, 0 signifie inutilisé.
.equ BLOCK_NBR, 1    ; numéor du bloc sur la mémoire de masse
.equ DEVICE, 2       ; descripteur de périphérique auquel appartient ce bloc.
.equ UPDATED, 3      ; compteur de mises à jour, le compteur qui contient
                     ; le plus gros chiffre est celui qui a été mis à jour
		     ; en dernier. Si 0 le buffer n'a pas été modifié.
; grandeur de la structure BUFFER		     
.equ BUFFER_STRUCT_SIZE, 8

.section .hardware.bss  bss
.align 2		     
;table de structure BUFFER.
_blk_buffers: .space MAX_BUFFERS*BUFFER_STRUCT_SIZE
 ; numéro du bloc actuellement en traitement.
_blk: .space 2
 ; incrémenté chaque fois qu'un buffer est mis à jour. 
 ; cette valeur incrémentée est copiée dans le champ UPDATED.
_update_cntr: .space 2 
; variable contenant le descripteur du stockage  {EEPROM, XRAM, SDCARD}
_block_dev: .space 2 
; variable contenant le numéro du dernier bloc listé
_scr: .space 2
 
; nom: BLK  ; ( -- a-addr)  
;   Variable qui contient le no de bloc  
;   actuellement interprété
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la variable _blk
DEFCODE "BLK",3,,BLK 
    DPUSH
    mov #_blk,T
    NEXT

; nom: SCR ( -- a-addr )
;   variable contenant le dernier numéro de bloc listé.
; arguments:
;   aucun    
; retourne:
;   a-addr   adresse de la variable _scr
DEFCODE "SCR",3,,SCR
    DPUSH
    mov #_scr,T
    NEXT
    
; nom: BLKDEV  ( -- a-addr )
;    variable contenant l'adresse du descripteur du périphérique
;    de stockage actif.
; arguments:
;   aucun
; retourne:
;    a-addr  *device, adresse de la variable _block_dev
DEFCODE "BLKDEV",6,,BLKDEV
    DPUSH
    mov #_block_dev,T
    NEXT
 
; nom: BUFARRAY  ( -- a-ddr )
;   Variable qui retourne l'adresse du tableau
;   contenant les structures BUFFER    
; arguments:
;   aucun
; retourne:
;   a-addr    *BUFFER[] adresse de la variable _blk_buffers
DEFCODE "BUFARRAY",8,,BUFARRAY
    DPUSH
    mov #_blk_buffers,T
    NEXT

; nom: STRUCADR ( n -- a-addr)
;   convertie no de buffer en adresse début structure
; arguments:
;    n   no de buffer
; retourne:
;    a-addr  *BUFFER adresse début de la structure
HEADLESS STRUCADR, HWORD ; ( n -- u )
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word BUFARRAY,PLUS,EXIT

; nom: DATA ( a-addr1 -- a-addr2 )
;   Retourne un pointeur sur le début du bloc de données du BUFFER.    
; arguments:
;   a-addr1   *BUFFER
; retourne:
;   a-addr2   *data adresse début du bloc de données.
HEADLESS DATA,HWORD ;DEFWORD "DATA",4,,DATA
    .word LIT,DATA_ADDR,SWAP,TBLFETCH,EXIT
    
    
; nom: BLOCK_INIT ( -- )    
;   initialisation de l'unité BLOCK 
; arguments:
;   aucun
; retourne:
;       
HEADLESS BLOCK_INIT, HWORD
    ; allocation de mémoire dynamique pour les buffers
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BUFFER_SIZE,MALLOC
    .word DOI,STRUCADR,STORE
    .word DOLOOP,1b-$
    ; périphérique par défaut EEPROM
    .word LIT,EEPROM,BLKDEV,STORE
    .word EXIT
 
; nom: OWN?  ( n+ u a-addr -- f )
;    Vérifie si le no. de bloc et l'identifiant périphique correspondent
;    à ce buffer.
; arguments:
;    n+      numéro de block
;    u       *device  périphérique de stockage
;    a-addr  *BUFFER adresse de la structure BUFFER
; retourne:
;    f    indicateur booléen vrai si n+==BLOCK_NBR && u==DEVICE
HEADLESS OWNQ,HWORD  ;DEFWORD "OWN?",4,,OWNQ
    .word TOR,LIT,DEVICE,RFETCH,TBLFETCH
    .word EQUAL,ZBRANCH,8f-$
    .word LIT,BLOCK_NBR,RFROM,TBLFETCH
    .word EQUAL,EXIT
8:  .word DROP,RDROP,LIT,0,EXIT
  
  
; nom: BUFFERED?  ( n+ u -- a-addr|0)
;   vérifie si le bloc est dans un buffer
; arguments:
;   n+  numéro du bloc recherché.    
;   u   *device périphérique auquel appartien ce bloc.
; retourne:
;   a-addr  *BUFFER  buffer contenant ce bloc ou 0
HEADLESS BUFFEREDQ, HWORD
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word TWODUP,DOI,STRUCADR,OWNQ
    .word TBRANCH,8f-$
    .word LOOP,1b-$,TWODROP,LIT,-1,EXIT
8:  .word TWODROP,DOI,STRUCADR,UNLOOP,EXIT
   
; nom: NOTUSED ( -- a-addr|0 )
;   Recherche un buffer libre
;   si le champ BLOCK_NBR==0 le bloc est libre.
; arguments:
;   aucun
; retourne:
;   a-addr  *BUFFER  buffer libre ou 0
HEADLESS NOTUSED, HWORD
    .word LIT, MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BLOCK_NBR,DOI,STRUCADR,TBLFETCH
    .word ZBRANCH,2f-$
    .word DOI,STRUCADR,UNLOOP,EXIT
2:  .word DOLOOP,1b-$,LIT,-1
9:  .word EXIT
  
; nom: OLDEST ( -- a-addr )
;   recherche le buffer dont la dernière
;   modification est la plus ancienne i.e. min(UPDATED).
; arguments:
;   aucun
; retourne:
;    a-addr   *BUFFER    
HEADLESS OLDEST,HWORD 
    .word LIT,0xffff,LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,UPDATED,DOI,STRUCADR,TBLFETCH
    .word TWODUP,LESS,TBRANCH,2f-$,SWAP
2:  .word DROP,DOLOOP,1b-$
9:  .word STRUCADR,EXIT
  
; nom: UPDATED@  ( a-addr -- u )
;   retourne la valeur du champ UPDATED
; arguments:
;   a-addr  *BUFFER
; retourne:
;   u valeur du champ UPDATED  
HEADLESS UPDATEDFETCH, HWORD 
    .word LIT,UPDATED,SWAP,TBLFETCH
    .word EXIT
    
; nom: BLKDEV@  ( -- u )
;   retourne le descripteur du périphérique de stockage actif.
; arguments:
;    
; retourne:
;    u    descripteur du périphérique
HEADLESS BLKDEVFETCH,HWORD ;DEFWORD "BLKDEV@",7,,BLKDEVFETCH
    .word BLKDEV,FETCH,EXIT
    
; nom: BLK>ADR ( a-addr -- ud )
;   Convertie un numéro de bloc en adresse 32 bits. Qui correspond
;   à la position absolue sur le média de stockage.    
; arguments:
;    a-addr   *BUFFER
; retourne:
;    ud  adresse 32 bits sur le périphérique de stockage    
DEFWORD "BLK>ADR",7,,BLKTOADR
    .word DUP,TOR,LIT,BLOCK_NBR,SWAP,TBLFETCH
    .word RFROM,LIT,FN_BLKTOADR,VEXEC,EXIT
    
; nom: FIELDS  ( n -- u1 u2 u3 u4 )
;   Obtient les paramètres du buffer à partir de son numéro
; arguments:
;    n   numéro du buffer
; retourne:
;   u1    champ DATA
;   u2    champ BLOCK_NBR    
;   u3    champ DEVICE
;   u4    *BUFFER
DEFWORD "FIELDS",6,,FIELDS
    ; adresse de la structure BUFFER
    .word STRUCADR,TOR
    ; @ adresse du data
    .word LIT,DATA_ADDR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ périphérique
    .word LIT,DEVICE,RFETCH,TBLFETCH,DUP
    .word RFROM,EXIT

; nom: UPDATE  ( a-addr -- )
;    Met à jour le compteur UPDATED avec la valeur
;    incrémentée de _update_cntr
; paramètre:
;    a-addr   *BUFFER structure buffer
; retourne:    
;
DEFWORD "UPDATE",6,,UPDATE
    ; incrémente _update_cntr
    .word LIT,1,LIT,_update_cntr,PLUSSTORE
    .word LIT,_update_cntr,FETCH,QDUP,ZBRANCH,2f-$ ; S: a-addr cntr
    .word LIT,UPDATED,ROT,TBLSTORE,EXIT
2:  ; si _update_cntr a fait un rollover on sauvegarde
    ; tous les buffers modifiés.
    .word DROP,SAVEBUFFERS,EXIT
    
; nom: NOUPDATE  ( a-addr -- )
;    Remet le champ UPDATED à zéro
; arguments:
;   a-addr     *BUFFER  adresse de la structure
; retourne:
;    
DEFWORD "NOUPDATE",8,,NOUPDATE
    .word LIT,0,LIT,UPDATED,ROT,TBLSTORE,EXIT
    
; nom: DATA> ( a-addr -- )    
;   Sauvegarde du data sur stockage
;   remise à zéro du champ UPDATED.
; arguments:
;   a-addr   *BUFFER
; retourne:
;    
DEFWORD "DATA>",5,,DATAOUT 
    ; ne sauvegarder que si nécessaire
    .word DUP,UPDATEDFETCH,TBRANCH,2f-$,DROP,EXIT
2:  .word FIELDS ; S: data  no-block device *BUFFER
    .word TOR,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC
    ; écriture
    .word RFROM,LIT,FN_WRITE,VEXEC
    ; raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
; nom: ">DATA"  ( a-addr -- )
;   Charge un bloc dans la RAM. La structure BUFFER indentifié par n
;   doit contenir le numéro du bloc et le descripteur device.
; arguments:
;   a-addr    *BUFFER
; retourne:
;     
DEFWORD ">DATA",5,,INDATA
    .word FIELDS,TOR,DUP,TOR
    ; conversion BLK>ADR
    .word LIT,FN_BLKTOADR,VEXEC
    ;lecture des  données
    .word RFROM,LIT,FN_READ,VEXEC
    ;raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
; nom: ASSIGN  ( n+ -- a-addr )
;   Assigne un BUFFER à un bloc appartenant au périphérique sélectionné par
;   BLKDEV. Libère un BUFFER au besoin.
; arguments:
;   n+  numéro du bloc requis.    
; retourne:
;   a-addr   *BUFFER  Pointeur sur la structure BUFFER
DEFWORD "ASSIGN",6,,ASSIGN
    ; est-ce que le bloc est déjà dans un buffer?
    .word DUP,BLKDEVFETCH,BUFFEREDQ,QDUP,ZBRANCH,4f-$
    ; oui S: n+ a-addr  
    .word SWAP,DROP,DUP,DATAOUT,EXIT
4:  ; non il n'est pas dans un buffer S: n+ 
    ;   recherche d'un buffer libre
    .word NOTUSED,QDUP,TBRANCH,6f-$
    ; aucun buffer libre S: n+
    .word OLDEST,DUP,UPDATED,ZBRANCH,6f-$
    .word DUP,DATAOUT
    ; trouvé buffer libre S: n+ a-addr
6:  .word DUP,TOR,LIT,BLOCK_NBR,SWAP,TBLSTORE
    .word BLKDEVFETCH,LIT,DEVICE,RFETCH,TBLSTORE
    ; mettre champ UPDATE à zéro
    .word RFETCH,NOUPDATE
    .word RFROM,EXIT ; S: no_buffer

    
; nom: BUFFER  ( n+ -- a-addr )
;   Retourne l'adresse d'un bloc de données. Si aucun buffer n'est disponible
;   libère celui qui à la plus petite valeur UPDATED.
;   Contrairement à BLOCK il n'y a pas de lecture du périphérique de stockage.  
; arguments:
;   n+    numéro du bloc.
; retourne:
;    a-addr   *data adresse début de la zone de données.
DEFWORD "BUFFER",6,,BUFFER
    .word ASSIGN,DATA,EXIT
  
    
; nom: BLOCK  ( n+ -- a-addr )
;    Retourne l'adresse d'un buffer pour le bloc.
;    Le no. de bloc est stocké dans la variable BLK
; arguments:
;    n+   no. du bloc requis.
; retourne:    
;   a-addr  *data Pointeur vers les données du bloc.    
DEFWORD "BLOCK",5,,BLOCK 
    .word ASSIGN,DUP,INDATA
    .word DATA,EXIT

; nom: LOAD ( n+ -- )
;   Évalue un bloc. Charge le bloc en mémooire si requis.    
; arguments:
;   n+   numéro du bloc à évaluer.
; retourne:
;    
DEFWORD "LOAD",4,,LOAD
    .word BLOCK,LIT,BLOCK_SIZE,EVAL,EXIT
    
; nom: SAVE-BUFFERS ( -- )  
;   Sauvegarde tous les buffers qui ont été modifiés.
; arguments:
;
; retourne:
;  
DEFWORD "SAVE-BUFFERS",12,,SAVEBUFFERS
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,DATAOUT
4:  .word DOLOOP,1b-$    
    .word EXIT
   
; nom: EMPTY-BUFFERS
;   Désassigne tous les BUFFERs sans sauvegarder
; arguments:
;   aucun
; retourne:
;    
DEFWORD "EMPTY-BUFFERS",13,,EMPTYBUFFERS
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,CELLPLUS
    .word LIT,BUFFER_STRUCT_SIZE,LIT,CELL_SIZE,MINUS
    .word LIT,0,FILL
    .word DOLOOP,1b-$
    .word EXIT
    
; nom: FLUSH ( -- )
;   Sauvegarde tous les BUFFER et désassigne
; arguments:
;   aucun
; retourne:
;    
DEFWORD "FLUSH",5,,FLUSH
    .word SAVEBUFFERS,EMPTYBUFFERS,EXIT
    
; nom: LIST ( n+ -- )
;   
    
; 7.6.2.2125 REFILL
; 7.6.2.2280 THRU
; 7.6.2.2535 \ extension de la sémentique des commentaires voir core.s
 

