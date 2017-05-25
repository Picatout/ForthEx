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

; NOM: blockedit.s
; DATE: 2017-04-12
; DESCRIPTION: 
;   �diteur de texte simple qui travail sur un seul �cran � la fois et permet
;   de sauvegarder le texte de cet �cran dans un bloc. Ult�rieurement ce
;   bloc peut-�tre �valu� avec la commande LOAD. 
;   L'id�e d'un �diteur de bloc viens de l'origine m�me du langage. Charles Moore
;   Travaillait sur un terminal vid�o de 16 lignes de 64 caract�res, ce qui fait qu'un
;   �cran occupait 1024 carct�res. Il avait donc eu l'id�e de sauvegarder le contenu
;   de la m�moire vid�o sur l'unit� de stockage permanent sans modification.
;   Chaque �cran sauvegard� s'appelait un bloc.
;   Le probl�me c'est que ForthEx utilise un �cran de 24 lignes au lieu de 16 ce qui
;   fait qu'un bloc serait de 1536 caract�res au lieu de 1024. Mais comme le standard
;   ANS Forth d�finie toujours les blocs comme �tant 1024 caract�res je devais trouver
;   une solution pour sauvegarder les �crans dans des blocs. Entre autre solutions il y a
;   1) M'�carter du standard et modifier la taille des blocs � 1536 octets.
;   2) Utiliser 2 blocs standards pour sauvegarder un �cran, occasionne une perte d'espace.
;   3) Compressser le contenu de l'�cran pour le faire entrer dans un bloc standard, gain d'espace.
;   J'ai opt� pour la 3i�me solution.     
;   En principe Lorsqu'on �cris du code source les lignes ne sont pas pleines.
;   Parfois on laisse m�me des lignes vides pour rendre le texte plus facile � lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronqu�es apr�s le dernier caract�re
;   et un caract�re de fin de ligne est ajout�. Il y a 24 lignes sur un �cran donc
;   si la longueur moyenne des lignes est inf�rieure � (BLOCK_SIZE-24)/24 l'�cran peut
;   �tre sauvegard� dans un bloc. L'�diteur calcule constamment le nombre de caract�res
;   dans un �cran en �dition et rapporte une alerte si ce nombre d�passe BLOCK_SIZE.
;   Il est problable que la majorit� du temps un �cran avec les lignes tronqu�es apr�s
;   le dernier caract�re r�pondra � ce crit�re. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   Le curseur peut-�tre d�plac� n'importe o� sur l'�cran et le texte modifi�.
;   Cependant le curseur ne peut sortir des limites de l'�cran, il n'y a pas de d�filement.    
; COMMANDES:
;   UP_ARROW D�place le curseur sur la ligne sup�rieure.
;   DOWN_ARROW D�place le curseur sur la ligne suivante.
;   LEFT_ARROW D�place le curseur d'un caract�re vers la gauche.
;   RIGHT_ARROW D�place le curseur d'un caract�re vers la droite.    
;   DELETE  Efface le caract�re � la position du curseur.
;   INSERT Ins�re un espace � la position du curseur.    
;   BACKSPACE Efface le caract�re � gauche du curseur.
;   CTRL_X  Efface la ligne sur laquelle le curseur r�side.
;   CTRL_Y  Ins�re une ligne vide avant celle o� se trouve le curseur.
;   HOME   Va au d�but de la ligne.
;   END    Va � la fin de la ligne.    
;   CTRL_S  Sauvegarde de l'�cran dans le bloc.
;   CTRL_N  Efface l'�cran pour �diter le bloc suivant.
;   CTRL_P  Reviens au bloc pr�c�demment �dit�.     
;   CTRL_I  �dtion d'un bloc quelconque. Demande le num�ro du bloc.
;   CTRL_Q  Quitte l'�diteur.

     
.section blkedit.bss bss 
_blknbr: .space 2
_blkprev: .space 2 
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilis�es par l'�diteur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: MAXCHAR  ( -- u )
;   Retourne le nombre maximum de caract�res que peut contenir un �cran pour �tre
;   sauvegard� dans un bloc. Cette valeur correspond � la grandeur d'un bloc sur
;   le p�riph�rique de stockage.
; arguments:
;   aucun
; retourne:
;   u  Nombre maximum de caract�res que peut contenir l'�cran. Selon le standard ANS Forth c'est 1024 octets.    
DEFCONST "MAXCHAR",7,,MAXCHAR,BLOCK_SIZE
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; variables utilis�es par ED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom:  BLK-NBR   ( -- a-addr )
;   Variable qui contient le num�ro du bloc en cours d'�dition.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.
DEFCODE "BLK-NBR",7,,BLKNBR 
     DPUSH
     mov _blknbr,T
     NEXT
     
; nom: BLK-PREV ( -- a-addr )
;   Variable qui contient le num�ro du bloc pr�c�demment en �dition.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.
DEFCODE "BLK-PREV",8,,BLKPREV
     DPUSH
     mov _blkprev,T
     NEXT
     
     
     
; EDINIT  ( -- )
;   Initialise les variable de l'�diteur BLKED. Appell� par BLKED au d�marrage de ce dernier.
; arguments:
;   aucun
; retourne:
;   rien     
HEADLESS EDINIT,HWORD
    .word LIT,0,DUP,BLKNBR,STORE,BLKPREV,STORE
    .word LCPAGE,VTPAGE,EXIT
 
    
;  KCASE  ( c n -- c f )    
;   compare le caract�re 'c' re�u du clavier avec la valeur n.  
; arguments:
;    c  Caract�re re�u du clavier
;    n  Valeur de comparaison
;  retourne:
;    c  retourne le caract�re re�u.
;    f  T si c==n, F si c<>n
HEADLESS KCASE,HWORD
    .word OVER,EQUAL,DUP,ZBRANCH,2f-$
    .word SWAP,DROP
2:  .word EXIT
  
; nom: SAVELINE ( n -- )
;   Sauvegarde la ligne d'�cran n dans le tampon PAD.
; arguments:
;   n	num�ro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word LNADR  ; s: src
    .word PAD,FETCH,LIT,CPL,OVER,CSTORE ; s: src dest 
    .word ONEPLUS,LIT,CPL,MOVE,EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'�cran � partir du tampon PASTE
; arguments:
;   n	num�ro de la ligne � restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word PAD,FETCH,COUNT,ROT ; s: src len n
    .word LNADR ; s: src len dest
    .word SWAP,MOVE
    .word EXIT
    
; nom: MSGLINE  ( c-addr u n -- )
;   Affiche un message � l'�cran et attend une touche au clavier pour poursuivre
;   l'ex�cution. Le message doit tenir sur une seule ligne d'�cran. Cette ligne
;   d'�cran est sauvegard�e et restaur�e � la sortie de ce mot.
; arguments:
;   c-addr Adresse du premier caract�re du message.
;   u  Longueur du message, limit� � 63 caract�res.
;   n  num�ro de la ligne o� doit-�tre affich� le message.
DEFWORD "MSGLINE",7,,MSGLINE ; ( c-addr u n -- )
    .word FALSE,CURENBL,GETCUR,TWOTOR,DUP,SAVELINE
    .word DUP,LIT,1,SWAP,ATXY,TRUE,BSLASHW,CLEARLN,NROT ; S: n c-addr u
    .word LIT,CPL-1,AND,TYPE,DUP,TRUE,INVLN
1:  .word KEYQ,ZBRANCH,1b-$
    .word FALSE,BSLASHW,RESTORELINE,TWORFROM,ATXY,TRUE,CURENBL,EXIT
  
; nom: NEXTBLOCK ( -- )
;   Sauvegarde l'�cran actuel et charge le bloc suivant pour �dition.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "NEXTBLOCK",9,,NEXTBLOCK
    .word BLKNBR,FETCH,DUP,SCRTOBLK,DROP
    .word DUP,BLKPREV,STORE
    .word ONEPLUS,DUP,BLKNBR,STORE,LIST
    .word EXIT
    
; nom: PREVBLOCK  ( -- )
;   Sauvegarde l'�cran actuel et charge le bloc pr�c�dent pour �dition.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "PREVBLOCK",9,,PREVBLOCK
    .word BLKNBR,FETCH,SCRTOBLK,DROP
    .word BLKPREV,FETCH,DUP,BLKNBR,STORE
    .word LIST,EXIT


; nom: OPENBLOCK  ( -- )
;   Charge un nouveau bloc pour �dition. Le num�ro du bloc est fourni par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "OPENBLOCK",9,,OPENBLOCK
    
    .word EXIT
    
    
; nom: VT-UPDATE  ( -- )
;   l'�diteur doit mettre � jour l'�cran de la console VT102 si le syst�me est en REMOTE CONSOLE
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "VT-UPDATE",9,,VTUPDATE
    .word SYSCONS,FETCH,SERCONS,EQUAL,TBRANCH,2f-$,DROP,EXIT
2:  .word GETCUR,ROT  
    .word DUP,LIT,0,SWAP,VTATXY
    .word LIT,CPL,STAR,SCRBUF,PLUS,LIT,CPL,LIT 
    .word EXIT   
    
HEADLESS DELLN,HWORD
    .word EXIT

HEADLESS INSLN,HWORD
    .word EXIT
    
HEADLESS DELCHR,HWORD
    .word EXIT
    
HEADLESS TOEOL,HWORD
    .word EXIT
    
HEADLESS LNUP,HWORD
    .word EXIT
    
;     
HEADLESS LNDN,HWORD 
    .word EXIT
   
HEADLESS CRLF,HWORD
    .word EXIT
    
; d�pose le caract�re dans la m�moire tampon vid�o.
; � la position actuelle du curseur.    
HEADLESS CHRTOBUF,HWORD ; ( c -- )
    .word CURADR,CSTORE,EXIT
    
; Affiche le caract�re � la position de l'�cran.
HEADLESS INSCHR,HWORD ; ( c -- )
    .word DUP,CHRTOBUF,EMIT,EXIT

HEADLESS TOBIG,HWORD
    .word STRQUOTE
    .byte 31
    .ascii "Screen to big to fit in a bloc."
    .align 2
    .word EXIT
    
HEADLESS EDKEY,HWORD
    .word SCRSIZE,MAXCHAR,GREATER,ZBRANCH,2f-$
    .word TOBIG,COUNT,LIT,0,MSGLINE
2:  .word EKEY, EXIT

HEADLESS BACKCHAR,HWORD    
    .word EXIT

HEADLESS LEFT,HWORD
    .word EXIT

HEADLESS RIGHT,HWORD
    .word EXIT


HEADLESS TEE,HWORD
    .word DUP,LCEMIT,VTEMIT,EXIT
    
; nom: BLKED  ( n+ -- )  
;   �diteur de bloc texte. Edite 1 bloc � la fois.
;   Le curseur peut-�tre d�plac� � n'importe qu'elle position sur l'�cran et 
;   son contenu modifi� � volont� avant de le sauvegarder le bloc sur le
;   p�riph�irque de stockage actif. Ce bloc contenant du texte source peut-�tre
;   ult�rieurement �valu� par la commande LOAD ou THRU.  
; arguments:
;   n+   Le num�ro du bloc � �diter.
; retourne:
;   rien  
DEFWORD "BLKED",5,,BLKED ; ( n+ -- )
    .word EDINIT
1:  .word EDKEY,DUP,LIT,31,GREATER,ZBRANCH,2f-$
    .word DUP,LIT,127,LESS,ZBRANCH,4f-$
    .word INSCHR,BRANCH,1b-$
    ; c<32
2:  .word LIT,VK_CR,KCASE,ZBRANCH,2f-$,CRLF,BRANCH,1b-$
2:  .word LIT,VK_BACK,KCASE,ZBRANCH,2f-$,GETX,ZBRANCH,1b-$,BACKCHAR,BRANCH,1b-$
2:  .word LIT,CTRL_N,KCASE,ZBRANCH,2f-$,NEXTBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_P,KCASE,ZBRANCH,2f-$,PREVBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_Q,KCASE,ZBRANCH,2f-$,CLS,ABORT
2:  .word LIT,CTRL_S,KCASE,ZBRANCH,2f-$,BLKNBR,FETCH,SCRTOBLK,DROP,BRANCH,1b-$
2:  .word LIT,CTRL_I,KCASE,ZBRANCH,2f-$,OPENBLOCK,BRANCH,1b-$  
2:  .word LIT,CTRL_X,KCASE,ZBRANCH,2f-$,DELLN,BRANCH,1b-$
2:  .word LIT,CTRL_Y,KCASE,ZBRANCH,2f-$,INSLN,BRANCH,1b-$  
2:  .word DROP,BRANCH,1b-$
    ; c>=127
4:  .word LIT,VK_DELETE,KCASE,ZBRANCH,4f-$,DELCHR,BRANCH,1b-$    
4:  .word LIT,VK_LEFT,KCASE,ZBRANCH,4f-$,LEFT,BRANCH,1b-$
4:  .word LIT,VK_RIGHT,KCASE,ZBRANCH,4f-$,RIGHT,BRANCH,1b-$ 
4:  .word LIT,VK_HOME,KCASE,ZBRANCH,4f-$,LIT,0,SETX,BRANCH,1b-$
4:  .word LIT,VK_END,KCASE,ZBRANCH,4f-$,TOEOL,BRANCH,1b-$
4:  .word LIT,VK_UP,KCASE,ZBRANCH,4f-$,LNUP,BRANCH,1b-$
4:  .word LIT,VK_DOWN,KCASE,ZBRANCH,4f-$,LNDN,BRANCH,1b-$
  
4:  .word DROP,BRANCH,1b-$
   
    .word EXIT
    
    