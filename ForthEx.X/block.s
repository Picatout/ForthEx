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
;   Retourne l'adresse du tableau
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
;HEADLESS STRUCADR, HWORD ; ( n -- u )
DEFWORD "STRUCADR",8,,STRUCADR    
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word BUFARRAY,PLUS,EXIT

; nom: DATA ( a-addr1 -- a-addr2 )
;   Retourne un pointeur sur le début du bloc de données du BUFFER.    
; arguments:
;   a-addr1   *BUFFER
; retourne:
;   a-addr2   *data adresse début du bloc de données.
;HEADLESS DATA,HWORD 
DEFWORD "DATA",4,,DATA
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
    .word EEPROM,BLKDEV,STORE
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
;HEADLESS OWNQ,HWORD
DEFWORD "OWN?",4,,OWNQ
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
;HEADLESS BUFFEREDQ, HWORD
DEFWORD "BUFFERED?",9,,BUFFEREDQ  
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word TWODUP,DOI,STRUCADR,OWNQ
    .word TBRANCH,8f-$
    .word DOLOOP,1b-$,TWODROP,LIT,0,EXIT
8:  .word TWODROP,DOI,STRUCADR,UNLOOP,EXIT
   
; nom: NOTUSED ( -- a-addr|0 )
;   Recherche un buffer libre
;   si le champ BLOCK_NBR==0 le bloc est libre.
; arguments:
;   aucun
; retourne:
;   a-addr  *BUFFER  buffer libre ou 0
;HEADLESS NOTUSED, HWORD
DEFWORD "NOTUSED",7,,NOTUSED  
    .word LIT, MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BLOCK_NBR,DOI,STRUCADR,TBLFETCH
    .word TBRANCH,2f-$
    .word DOI,STRUCADR,UNLOOP,EXIT
2:  .word DOLOOP,1b-$,LIT,0
9:  .word EXIT
  
; nom: OLDEST ( -- a-addr )
;   recherche le buffer dont la dernière
;   modification est la plus ancienne i.e. min(UPDATED).
; arguments:
;   aucun
; retourne:
;    a-addr   *BUFFER    
;HEADLESS OLDEST,HWORD 
DEFWORD "OLDEST",6,,OLDEST  
    .word LIT,0,LIT,0xffff,LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,UPDATED,DOI,STRUCADR,TBLFETCH  ; S: n old_update new_updated
    .word TWODUP,LESS,TBRANCH,2f-$ ; S: n old_updated new_updated 
    .word TOR,TWODROP,DOI,RFROM,BRANCH,4f-$
2:  .word DROP
4:  .word DOLOOP,1b-$ ; S: n oldest_updated
9:  .word DROP,STRUCADR,EXIT
  
; nom: UPDATED@  ( a-addr -- u )
;   retourne la valeur du champ UPDATED
; arguments:
;   a-addr  *BUFFER
; retourne:
;   u valeur du champ UPDATED  
;HEADLESS UPDATEDFETCH, HWORD 
DEFWORD "UPDATED@",8,,UPDATEDFETCH  
    .word LIT,UPDATED,SWAP,TBLFETCH
    .word EXIT
    
; nom: BLKDEV@  ( -- u )
;   retourne le descripteur du périphérique de stockage actif.
; arguments:
;    
; retourne:
;    u    descripteur du périphérique
;HEADLESS BLKDEVFETCH,HWORD 
DEFWORD "BLKDEV@",7,,BLKDEVFETCH
    .word BLKDEV,FETCH,EXIT
    
; nom: BLK>ADR ( a-addr -- ud )
;   Convertie un numéro de bloc d'un buffer en adresse 32 bits. Qui correspond
;   à la position absolue sur le média de stockage.    
; arguments:
;    a-addr   BUFFER
; retourne:
;    ud  adresse 32 bits sur le périphérique de stockage    
DEFWORD "BLK>ADR",7,,BLKTOADR
    .word DUP,TOR,LIT,BLOCK_NBR,SWAP,TBLFETCH
    .word RFROM,FN_BLKTOADR,VEXEC,EXIT
    
; nom: FIELDS  ( a-addr -- u1 u2 u3 a-addr )
;   Obtient les paramètres du buffer à partir de son numéro
; arguments:
;    a-addr   adresse de la structure BUFFER
; retourne:
;   u1    champ DATA
;   u2    champ BLOCK_NBR    
;   u3    champ DEVICE
;   a-addr    *BUFFER
DEFWORD "FIELDS",6,,FIELDS
    .word TOR
    ; @ adresse du data
    .word LIT,DATA_ADDR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ périphérique
    .word LIT,DEVICE,RFETCH,TBLFETCH
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
    .word FN_BLKTOADR,VEXEC
    ; écriture
    .word RFROM,FN_WRITE,VEXEC
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
DEFWORD ">DATA",5,,TODATA
    .word FIELDS,TOR,DUP,TOR ; S: data block_nbr device r: a-addr device
    ; conversion BLK>ADR
    .word FN_BLKTOADR,VEXEC,LIT,BLOCK_SIZE,NROT ; s: data u ud r: a-addr device
    ;lecture des  données
    .word RFROM,FN_READ,VEXEC
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
    .word RFROM
    .word EXIT ; S: no_buffer

    
; nom: BUFFER  ( n+ -- a-addr )
;   Retourne l'adresse d'un bloc de données. Si aucun buffer n'est disponible
;   libère celui qui à la plus petite valeur UPDATED.
;   Contrairement à BLOCK il n'y a pas de lecture du périphérique de stockage.
;   le contenu du buffer est mis à zéro.    
; arguments:
;   n+    numéro du bloc.
; retourne:
;    a-addr   *data adresse début de la zone de données.
DEFWORD "BUFFER",6,,BUFFER
    .word ASSIGN,DATA,DUP,LIT,BLOCK_SIZE,LIT,0,FILL,EXIT
  
    
; nom: BLOCK  ( n+ -- a-addr )
;    Retourne l'adresse d'un buffer pour le bloc.
;    Le no. de bloc est stocké dans la variable BLK
; arguments:
;    n+   no. du bloc requis.
; retourne:    
;   a-addr  *data Pointeur vers les données du bloc.    
DEFWORD "BLOCK",5,,BLOCK 
    .word ASSIGN,DUP,TODATA
    .word DATA,EXIT

; nom: LOAD ( n+ -- )
;   Évalue un bloc. Charge le bloc en mémooire si requis.    
; arguments:
;   n+   numéro du bloc à évaluer.
; retourne:
;    
DEFWORD "LOAD",4,,LOAD
    .word BLOCK,DUP,LIT,0,SCAN
    .word SWAP,DROP,EVAL,EXIT
    
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
;   Affiche le contenu du bloc à l'écran.
; arguments:
;   n+  numéro du bloc
; retourne:
;       
DEFWORD "LIST",4,,LIST
    .word DUP,SCR,STORE,CLS
    .word BLOCK,LIT,BLOCK_SIZE,LIT,0,DODO
1:  .word DUP,ECFETCH,QDUP,TBRANCH,2f-$
    .word UNLOOP,BRANCH,9f-$ ; premier zéro arrête l'affichage.
2:  .word EMIT,ONEPLUS,DOLOOP,1b-$
9:  .word DROP,EXIT

  
; nom: REFILL  ( -- f )
;   **comportement non standard**  
;   Si la variable BLK est à zéro retourne faux.
;   Sinon incrémente BLK et si cette nouvelle valeur est valide
;   charge ce bloc pour évaluation et retourne vrai, sinon
;   remet BLK à zéro et retourne faux.
DEFWORD "REFILL",6,,REFILL
    .word BLK,FETCH,DUP,ZBRANCH,9f-$
    .word BLK,LIT,1,OVER,FETCH,PLUS,DUP,ROT,STORE
    .word DUP,FN_BOUND,BLKDEV,FETCH,VEXEC
    .word DUP,ZBRANCH,8f-$
    .word DROP,BLOCK,TRUE,EXIT
8:  .word DUP,BLK,STORE    
9:  .word EXIT    
  
; nom: THRU  ( i*x u1 u2 -- j*x )
;   Charge les blocs u1 à u2 .
; arguments:
;   i*x  État initial de pile.
;   u1   premier bloc à charger.
;   u2   dernier bloc à charger.
; retourne:
;   j*x  État de la pile après l'interprétation des blocs.
DEFWORD "THRU",4,,THRU 
    .word ONEPLUS,SWAP,DODO
1:  .word DOI,LOAD,DOLOOP,1b-$
    .word EXIT

; nom: ADD-CR    
;   ajoute un CR à la fin de la ligne
;   incrémente u de 1
; arguments:
;   c-addr   adresse début chaîne
;   u        longueur chaîne
; retourne:
;   c-addr   adresse début chaîne
;   u'       u+1    
;HEADLESS ADD_CR,HWORD ;( c-addr u -- c-addr u' )
DEFWORD "ADD-CR",6,,ADDCR    
    .word TWODUP,PLUS,CLIT,VK_CR,SWAP,CSTORE,ONEPLUS,EXIT
   
; nom: >PAD ( c-addr -- u )    
;   copie la chaîne dans PAD, trim et vérifie vérifie que total+u' <= BUFFER_SIZE
; arguments:
;   c-addr  adresse début ligne dans frame buffer vidéo
; retourne:
;   u       longueur de la chaîne tronquée qui est dans PAD    
;HEADLESS TOPAD,HWORD ; ( c-addr -- u  )
DEFWORD ">PAD",4,,TOPAD    
    .word PAD,FETCH,LIT,CPL,TWODUP,TWOTOR,CMOVE ; S:  r: pad CPL
    .word TWORFROM,MINUSTRAILING,ADDCR ; pad u'
    .word SWAP,DROP,EXIT

; PAD>BUFFER  ( data u -- data+u )    
;   Copie PAD dans le buffer 
; arguments:
;   data    pointeur vers la zone buffer destination  
;   u       longueur de la chaîne  
; retourne:
;   data'    data+u  
;HEADLESS PADTOBUFFER,HWORD  
DEFWORD "PAD>BUFFER",10,,PADTOBUFFER 
    .word TWODUP ; s: data u data u
    .word PAD,FETCH,NROT,CMOVE ; s: data u 
    .word PLUS,EXIT ; s: data+u
    
; nom: SCR>BLK  ( n+ -- f )
;   Sauvegarde du frame buffer de l'écran dans un bloc*.
;   Si l'écran a plus de 1024 caractères seul les 1024 premiers sont sauvegarder.
;   Les espaces qui termines les lignes sont supprimés et chaque ligne est complétée
;   par un VK_CR.
;   * ne fonctionne qu'avec LOCAL CONSOLE. Cependant BLKEDIT utilise le frame buffer
;     local même lorsque la console est en mode REMOTE, donc BLKEDIT peut sauvegarder
;     le bloc en édition.    
; arguments:
;   n+    numéro du bloc où sera sauvegardé l'écran.
; retourne:
;   f     indicateur booléen, si l'écran requière plus d'un bloc retourne faux.
DEFWORD "SCR>BLK",7,,SCRTOBLK
    .word DUP,BUFFER,SWAP,BLKDEVFETCH,BUFFEREDQ,UPDATE 
    .word LIT,0 ; S: data total
    .word LIT,LPS,LIT,0,DODO
1:  .word SCRBUF,DOI,LIT,CPL,STAR,PLUS ; S: data total scrline
    .word TOPAD,DUP,TOR,PLUS,DUP,LIT,BUFFER_SIZE,GREATER,ZBRANCH,2f-$ ; S: data total+u r: u
    .word TWODROP,RDROP,LIT,0,UNLOOP,EXIT
2:  .word RFROM,SWAP,TOR,PADTOBUFFER,RFROM  ; S: data+u total+u
    .word DOLOOP,1b-$
    .word TWODROP,FLUSH,LIT,-1
    .word EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;     editeur de bloc
;     simple.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; nom: BLKEDIT  ( n+ -- )
;   Edition d'un bloc contenant du texte.
; arguments:
;   n+   numéro du bloc à éditer.
; retourne:
;   
DEFWORD "BLKEDIT",7,,BLKEDIT

    .word EXIT
    
    