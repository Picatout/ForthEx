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
; DESCRIPTION: 
;   Impl�mentation des mots de gestion de fichiers par blocs.
;   REF: http://lars.nocrew.org/forth2012/block.html
;   REF: http://lars.nocrew.org/dpans/dpans7.htm#7.6.1    
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

;struct BUFFER{
;    char* DATA_ADDR;
;    unsigned BLOCK_NBR;
;    device* DEVICE
;    unsigned UPDATED
;};
		     
; chamsp de la structure BUFFER
.equ DATA_ADDR, 0    ; adresse du buffer dans l'EDS, 0 signifie inutilis�.
.equ BLOCK_NBR, 1    ; num�or du bloc sur la m�moire de masse
.equ DEVICE, 2       ; descripteur de p�riph�rique auquel appartient ce bloc.
.equ UPDATED, 3      ; compteur de mises � jour, le compteur qui contient
                     ; le plus gros chiffre est celui qui a �t� mis � jour
		     ; en dernier. Si 0 le buffer n'a pas �t� modifi�.
; grandeur de la structure BUFFER		     
.equ BUFFER_STRUCT_SIZE, 8

.section .hardware.bss  bss
.align 2		     
;table de structure BUFFER.
_blk_buffers: .space MAX_BUFFERS*BUFFER_STRUCT_SIZE
 ; num�ro du bloc actuellement en traitement.
_blk: .space 2
 ; incr�ment� chaque fois qu'un buffer est mis � jour. 
 ; cette valeur incr�ment�e est copi�e dans le champ UPDATED.
_update_cntr: .space 2 
; variable contenant le descripteur du stockage  {EEPROM, XRAM, SDCARD}
_block_dev: .space 2 
; variable contenant le num�ro du dernier bloc list�
_scr: .space 2
 
; nom: BLK   ( -- a-addr)  
;   Variable qui contient le no de bloc actuellement interpr�t�.
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la variable _blk
DEFCODE "BLK",3,,BLK 
    DPUSH
    mov #_blk,T
    NEXT

; nom: SCR ( -- a-addr )
;   variable contenant le dernier num�ro de bloc affich� � l'�cran.
; arguments:
;   aucun    
; retourne:
;   a-addr   adresse de la variable SCR.
DEFCODE "SCR",3,,SCR
    DPUSH
    mov #_scr,T
    NEXT
    
; nom: BLKDEV  ( -- a-addr )
;    variable contenant l'adresse du descripteur du p�riph�rique
;    de stockage actif.
; arguments:
;   aucun
; retourne:
;    a-addr  Adresse de la variable BLKDEV
DEFCODE "BLKDEV",6,,BLKDEV
    DPUSH
    mov #_block_dev,T
    NEXT
 
; nom: BUFARRAY  ( -- a-ddr )
;   Retourne l'adresse du tableau contenant les structures BUFFER.
; arguments:
;   aucun
; retourne:
;   a-addr    Adresse du tableau qui contient le structures BUFFER.
DEFCODE "BUFARRAY",8,,BUFARRAY
    DPUSH
    mov #_blk_buffers,T
    NEXT

; nom: STRUCADR ( n -- a-addr)
;   convertie le num�ro de buffer en adresse de la structure BUFFER.
; arguments:
;    n   Num�ro du buffer.
; retourne:
;    a-addr  Adresse d�but de la structure.
    
;HEADLESS STRUCADR, HWORD ; ( n -- u )
DEFWORD "STRUCADR",8,,STRUCADR    
    .word LIT,BUFFER_STRUCT_SIZE,STAR
    .word BUFARRAY,PLUS,EXIT

; nom: DATA ( a-addr1 -- a-addr2 )
;   Retourne un pointeur sur le d�but du bloc de donn�es du BUFFER.    
; arguments:
;   a-addr1   Adresse de la structure BUFFER.
; retourne:
;   a-addr2   Adresse d�but du bloc de donn�es.
    
;HEADLESS DATA,HWORD 
DEFWORD "DATA",4,,DATA
    .word LIT,DATA_ADDR,SWAP,TBLFETCH,EXIT
    
    
; BLOCK_INIT ( -- )    
;   initialisation de l'unit� BLOCK 
; arguments:
;   aucun
; retourne:
;       
HEADLESS BLOCK_INIT, HWORD
    ; allocation de m�moire dynamique pour les buffers
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BUFFER_SIZE,MALLOC
    .word DOI,STRUCADR,STORE
    .word DOLOOP,1b-$
    ; p�riph�rique par d�faut EEPROM
    .word EEPROM,BLKDEV,STORE
    .word EXIT
 
; nom: OWN?  ( n+ u a-addr -- f )
;    V�rifie si le num�ro de bloc et l'identifiant p�riphique correspondent
;    � ce buffer.
; arguments:
;    n+      Num�ro de bloc.
;    u       P�riph�rique de stockage.
;    a-addr  Adresse de la structure BUFFER.
; retourne:
;    f    Indicateur bool�en vrai si n+==BLOCK_NBR && u==DEVICE.
    
;HEADLESS OWNQ,HWORD
DEFWORD "OWN?",4,,OWNQ
    .word TOR,LIT,DEVICE,RFETCH,TBLFETCH
    .word EQUAL,ZBRANCH,8f-$
    .word LIT,BLOCK_NBR,RFROM,TBLFETCH
    .word EQUAL,EXIT
8:  .word DROP,RDROP,LIT,0,EXIT
  
  
; nom: BUFFERED?  ( n+ u -- a-addr|0)
;   V�rifie si le bloc est dans un buffer.
; arguments:
;   n+  Num�ro du bloc recherch�.    
;   u   Descripteur du p�riph�rique auquel appartient ce bloc.
; retourne:
;   a-addr|0 Adresse du  buffer contenant ce bloc ou 0 s'il n'est pas dans un buffer.
  
;HEADLESS BUFFEREDQ, HWORD
DEFWORD "BUFFERED?",9,,BUFFEREDQ  
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word TWODUP,DOI,STRUCADR,OWNQ
    .word TBRANCH,8f-$
    .word DOLOOP,1b-$,TWODROP,LIT,0,EXIT
8:  .word TWODROP,DOI,STRUCADR,UNLOOP,EXIT
   
; nom: NOTUSED ( -- a-addr|0 )
;   Recherche un buffer libre. Retourne 0 si aucun buffer libre.
; arguments:
;   aucun
; retourne:
;   a-addr|0  Adresse de la struturce BUFFER libre ou 0.
  
;HEADLESS NOTUSED, HWORD
DEFWORD "NOTUSED",7,,NOTUSED  
    .word LIT, MAX_BUFFERS,LIT,0,DODO
1:  .word LIT,BLOCK_NBR,DOI,STRUCADR,TBLFETCH
    .word TBRANCH,2f-$
    .word DOI,STRUCADR,UNLOOP,EXIT
2:  .word DOLOOP,1b-$,LIT,0
9:  .word EXIT
  
; nom: OLDEST ( -- a-addr )
;   Recherche le buffer dont la derni�re modification est la plus ancienne.
; arguments:
;   aucun
; retourne:
;    a-addr   Adresse de la structure BUFFER.    
  
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
;   Retourne la valeur du champ UPDATED d'une structure BUFFER.
; arguments:
;   a-addr  Adresse de la structure BUFFER.
; retourne:
;   u Valeur du champ UPDATED.
  
;HEADLESS UPDATEDFETCH, HWORD 
DEFWORD "UPDATED@",8,,UPDATEDFETCH  
    .word LIT,UPDATED,SWAP,TBLFETCH
    .word EXIT
    
; nom: BLKDEV@  ( -- u )
;   Retourne le descripteur du p�riph�rique de stockage actif.
; arguments:
;   aucun 
; retourne:
;    u    Descripteur du p�riph�rique actif.
    
;HEADLESS BLKDEVFETCH,HWORD 
DEFWORD "BLKDEV@",7,,BLKDEVFETCH
    .word BLKDEV,FETCH,EXIT
    
; nom: BLK>ADR ( a-addr -- ud )
;   Convertie un num�ro de bloc d'un buffer en adresse 32 bits. Qui correspond
;   � la position absolue sur le m�dia de stockage.    
; arguments:
;    a-addr Adresse de la structure BUFFER.
; retourne:
;    ud  Adresse 32 bits sur le p�riph�rique de stockage.
DEFWORD "BLK>ADR",7,,BLKTOADR
    .word DUP,TOR,LIT,BLOCK_NBR,SWAP,TBLFETCH
    .word RFROM,FN_BLKTOADR,VEXEC,EXIT
    
; nom: FIELDS  ( a-addr -- u1 u2 u3 a-addr )
;   Obtient les param�tres du buffer � partir de son adresse.
; arguments:
;    a-addr   Adresse de la structure BUFFER.
; retourne:
;   u1    Champ DATA
;   u2    Champ BLOCK_NBR    
;   u3    Champ DEVICE
;   a-addr    Adresse de la structure BUFFER.
DEFWORD "FIELDS",6,,FIELDS
    .word TOR
    ; @ adresse du data
    .word LIT,DATA_ADDR,RFETCH,TBLFETCH
    ; @ no. du block
    .word LIT,BLOCK_NBR,RFETCH,TBLFETCH
    ; @ p�riph�rique
    .word LIT,DEVICE,RFETCH,TBLFETCH
    .word RFROM,EXIT

; nom: UPDATE  ( a-addr -- )
;    Met � jour le compteur UPDATED avec la valeur incr�ment�e de _update_cntr.
; arguments:
;    a-addr   Adresse de la structure BUFFER.
; retourne:    
;   rien
DEFWORD "UPDATE",6,,UPDATE
    ; incr�mente _update_cntr
    .word LIT,1,LIT,_update_cntr,PLUSSTORE
    .word LIT,_update_cntr,FETCH,QDUP,ZBRANCH,2f-$ ; S: a-addr cntr
    .word LIT,UPDATED,ROT,TBLSTORE,EXIT
2:  ; si _update_cntr a fait un rollover on sauvegarde
    ; tous les buffers modifi�s.
    .word DROP,SAVEBUFFERS,EXIT
    
; nom: NOUPDATE  ( a-addr -- )
;    Remet le champ UPDATED de la structure BUFFER � z�ro.
; arguments:
;   a-addr     Adresse de la structure BUFFER.
; retourne:
;   rien    
DEFWORD "NOUPDATE",8,,NOUPDATE
    .word LIT,0,LIT,UPDATED,ROT,TBLSTORE,EXIT
    
; nom: DATA> ( a-addr -- )    
;   Sauvegarde du data sur le p�riph�rique de stockage et remise � z�ro du champ UPDATED.
; arguments:
;   a-addr   Adresse de la structure BUFFER.
; retourne:
;   rien 
DEFWORD "DATA>",5,,DATAOUT 
    ; ne sauvegarder que si n�cessaire
    .word DUP,UPDATEDFETCH,TBRANCH,2f-$,DROP,EXIT
2:  .word FIELDS ; S: data  no-block device *BUFFER
    .word TOR,DUP,TOR
    ; conversion BLK>ADR
    .word FN_BLKTOADR,VEXEC
    ; �criture
    .word RFROM,FN_WRITE,VEXEC
    ; raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
; nom: >DATA  ( a-addr -- )
;   Charge un bloc dans un buffer � partir du p�riph�rique de stockage.
;   La structure BUFFER indentifi� par a-addr doit contenir le num�ro 
;   du bloc et le descripteur du p�riph�rique.
; arguments:
;   a-addr    Adresse de la structure BUFFER.
; retourne:
;   rien  
DEFWORD ">DATA",5,,TODATA
    .word FIELDS,TOR,DUP,TOR ; S: data block_nbr device r: a-addr device
    ; conversion BLK>ADR
    .word FN_BLKTOADR,VEXEC,LIT,BLOCK_SIZE,NROT ; s: data u ud r: a-addr device
    ;lecture des  donn�es
    .word RFROM,FN_READ,VEXEC
    ;raz compteur
    .word RFROM,NOUPDATE
    .word EXIT
    
; nom: ASSIGN  ( n+ -- a-addr )
;   Assigne un BUFFER � un bloc appartenant au p�riph�rique s�lectionn� par
;   BLKDEV. Lib�re un BUFFER au besoin.
; arguments:
;   n+  num�ro du bloc requis.    
; retourne:
;   a-addr   Adresse du d�but de la zone de donn�es.
DEFWORD "ASSIGN",6,,ASSIGN
    ; est-ce que le bloc est d�j� dans un buffer?
    .word DUP,BLKDEVFETCH,BUFFEREDQ,QDUP,ZBRANCH,4f-$
    ; oui S: n+ a-addr  
    .word SWAP,DROP,DUP,DATAOUT,EXIT
4:  ; non il n'est pas dans un buffer S: n+ 
    ;   recherche d'un buffer libre
    .word NOTUSED,QDUP,TBRANCH,6f-$
    ; aucun buffer libre S: n+
    .word OLDEST,DUP,UPDATED,ZBRANCH,6f-$
    .word DUP,DATAOUT
    ; trouv� buffer libre S: n+ a-addr
6:  .word DUP,TOR,LIT,BLOCK_NBR,SWAP,TBLSTORE
    .word BLKDEVFETCH,LIT,DEVICE,RFETCH,TBLSTORE
    ; mettre champ UPDATE � z�ro
    .word RFETCH,NOUPDATE
    .word RFROM
    .word EXIT ; S: no_buffer

    
; nom: BUFFER  ( n+ -- a-addr )
;   Retourne l'adresse d'un bloc de donn�es. Si aucun buffer n'est disponible
;   lib�re celui qui � la plus petite valeur UPDATED.
;   Contrairement � BLOCK il n'y a pas de lecture du p�riph�rique de stockage.
;   le contenu du buffer est mis � z�ro.    
; arguments:
;   n+    num�ro du bloc.
; retourne:
;    a-addr   Adresse d�but de la zone de donn�es.
DEFWORD "BUFFER",6,,BUFFER
    .word ASSIGN,DATA,DUP,LIT,BLOCK_SIZE,LIT,0,FILL,EXIT
  
    
; nom: BLOCK  ( n+ -- a-addr )
;   Lit un bloc d'un p�riph�rique de stockage vers un buffer. Lib�re un buffer au besoin.
;   Le p�riph�rique est celui d�termin� par la variable BLKDEV.    
; arguments:
;    n+   no. du bloc requis.
; retourne:    
;   a-addr  Adresse du d�but de la zone de donn�es.    
DEFWORD "BLOCK",5,,BLOCK 
    .word ASSIGN,DUP,TODATA
    .word DATA,EXIT

; nom: LOAD ( i*x n+ -- j*x )
;   �value un bloc. Si le bloc n'est pas d�j� dans un buffer il est charg�
;   � partir du p�riph�rique d�sign� par BLKDEV. Le num�ro du bloc �valu� 
;   est enregistr� dans la variable BLK.    
; arguments:
;   i*x  �tat de la pile des arguments avant l'�valutaion du bloc n+.    
;   n+   Num�ro du bloc � �valuer.
; retourne:
;    j*x  �tat de la pile des arguments apr�s l'�valuation du bloc n+.
DEFWORD "LOAD",4,,LOAD
    .word DUP,BLK,STORE,BLOCK,DUP,LIT,0,SCAN
    .word SWAP,DROP,EVAL,EXIT
    
; nom: SAVE-BUFFERS ( -- )  
;   Sauvegarde tous les buffers qui ont �t� modifi�s.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "SAVE-BUFFERS",12,,SAVEBUFFERS
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,DATAOUT
4:  .word DOLOOP,1b-$    
    .word EXIT
   
; nom: EMPTY-BUFFERS  ( -- )
;   Lib�re tous les buffers sans sauvegarder.
; arguments:
;   aucun
; retourne:
;   rien 
DEFWORD "EMPTY-BUFFERS",13,,EMPTYBUFFERS
    .word LIT,MAX_BUFFERS,LIT,0,DODO
1:  .word DOI,STRUCADR,CELLPLUS
    .word LIT,BUFFER_STRUCT_SIZE,LIT,CELL_SIZE,MINUS
    .word LIT,0,FILL
    .word DOLOOP,1b-$
    .word EXIT
    
; nom: FLUSH ( -- )
;   Sauvegarde tous les buffers et les lib�res.
; arguments:
;   aucun
; retourne:
;   rien 
DEFWORD "FLUSH",5,,FLUSH
    .word SAVEBUFFERS,EMPTYBUFFERS,EXIT
    
; nom: LIST ( n+ -- )
;   Affiche le contenu du bloc � l'�cran. Si le bloc n'est pas d�j� dans un buffer
;   il est charg� � partir du p�riph�rique d�sign� par BLKDEV.    
; arguments:
;   n+  num�ro du bloc
; retourne:
;   rien    
DEFWORD "LIST",4,,LIST
    .word DUP,SCR,STORE,CLS
    .word BLOCK,LIT,BLOCK_SIZE,LIT,0,DODO
1:  .word DUP,ECFETCH,QDUP,TBRANCH,2f-$
    .word UNLOOP,BRANCH,9f-$ ; premier z�ro arr�te l'affichage.
2:  .word EMIT,ONEPLUS,DOLOOP,1b-$
9:  .word DROP,EXIT

  
; nom: REFILL  ( -- f )
;   **comportement non standard**  
;   Si la variable BLK est � z�ro retourne faux.
;   Sinon incr�mente BLK et si cette nouvelle valeur est valide
;   charge ce bloc pour �valuation et retourne vrai, sinon
;   remet BLK � z�ro et retourne faux.
; arguments:
;   aucun
; retourne:
;   f    retourne faux si la variable BLK=0 ou s'il n'y a plus de bock valide.  
DEFWORD "REFILL",6,,REFILL
    .word BLK,FETCH,DUP,ZBRANCH,9f-$
    .word BLK,LIT,1,OVER,FETCH,PLUS,DUP,ROT,STORE
    .word DUP,FN_BOUND,BLKDEV,FETCH,VEXEC
    .word DUP,ZBRANCH,8f-$
    .word DROP,BLOCK,TRUE,EXIT
8:  .word DUP,BLK,STORE    
9:  .word EXIT    
  
; nom: THRU  ( i*x u1 u2 -- j*x )
;   Interpr�tation des blocs u1 � u2 . LOAD est appell� pour chacun des blocs dans la s�quence.
; arguments:
;   i*x  �tat initial de pile.
;   u1   premier bloc � interpr�ter.
;   u2   dernier bloc � interpr�ter.
; retourne:
;   j*x  �tat de la pile apr�s l'interpr�tation des blocs.
DEFWORD "THRU",4,,THRU 
    .word ONEPLUS,SWAP,DODO
1:  .word DOI,LOAD,DOLOOP,1b-$
    .word EXIT

; nom: ADD-CR  ( c-addr u -- c-addr u' )  
;   Ajoute un CR � la fin de la ligne incr�mente u de 1.
; arguments:
;   c-addr   Adresse d�but cha�ne
;   u        Longueur cha�ne
; retourne:
;   c-addr   Adresse d�but cha�ne
;   u'       Longueur de la cha�ne incr�ment�e de 1 caract�re.    
    
;HEADLESS ADD_CR,HWORD ;( c-addr u -- c-addr u' )
DEFWORD "ADD-CR",6,,ADDCR    
    .word TWODUP,PLUS,CLIT,VK_CR,SWAP,CSTORE,ONEPLUS,EXIT
   
; nom: >PAD ( c-addr -- u )    
;   Copie la cha�ne dans PAD, supprime les blancs en fin de ligne.
;   V�rifie que total+u' <= BUFFER_SIZE.
; arguments:
;   c-addr  Adresse d�but ligne dans frame buffer vid�o
; retourne:
;   u       Longueur de la cha�ne tronqu�e qui est dans PAD    
    
;HEADLESS TOPAD,HWORD ; ( c-addr -- u  )
DEFWORD ">PAD",4,,TOPAD    
    .word PAD,FETCH,LIT,CPL,TWODUP,TWOTOR,CMOVE ; S:  r: pad CPL
    .word TWORFROM,MINUSTRAILING,ADDCR ; pad u'
    .word SWAP,DROP,EXIT

; nom: PAD>BUFFER  ( c-addr u -- c-addr' )    
;   Copie PAD dans le buffer. 
; arguments:
;   c-addr  Pointeur vers la zone buffer destination.
;   u       Longueur de la cha�ne � copier.  
; retourne:
;   c-addr'   Pointeur incr�ment� de u caract�res.  
    
;HEADLESS PADTOBUFFER,HWORD  
DEFWORD "PAD>BUFFER",10,,PADTOBUFFER 
    .word TWODUP ; s: data u data u
    .word PAD,FETCH,NROT,CMOVE ; s: data u 
    .word PLUS,EXIT ; s: data+u
    
; nom: SCR>BLK  ( n+ -- f )
;   Sauvegarde du frame buffer de l'�cran dans un bloc sur p�riph�rique de stockage.
;   Si l'�cran a plus de 1024 caract�res seul les 1024 premiers sont sauvegarder.
;   Les espaces qui termines les lignes sont supprim�s et chaque ligne est compl�t�e
;   par un VK_CR.
;   * ne fonctionne qu'avec LOCAL CONSOLE. Cependant BLKEDIT utilise le frame buffer
;     local m�me lorsque la console est en mode REMOTE, donc BLKEDIT peut sauvegarder
;     le bloc en �dition.    
; arguments:
;   n+    num�ro du bloc o� sera sauvegard� l'�cran.
; retourne:
;   f     indicateur bool�en, si l'�cran requi�re plus d'un bloc retourne faux.
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
    
; nom BLKEDIT  ( n+ -- )
;   Edition d'un bloc contenant du texte.
; arguments:
;   n+   num�ro du bloc � �diter.
; retourne:
;   rien
DEFWORD "BLKEDIT",7,,BLKEDIT

    .word EXIT
    
    