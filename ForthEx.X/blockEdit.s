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
;   �cran occupait 1024 caract�res. Il avait donc eu l'id�e de sauvegarder le contenu
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
;   �tre sauvegard� dans un bloc. L'�diteur le mot SCR-SIZE d�fini dans le fichier block.s
;   et rapporte une alerte si ce nombre d�passe BLOCK_SIZE.
;   Il est problable que la majorit� du temps un �cran avec les lignes tronqu�es apr�s
;   le dernier caract�re r�pondra � ce crit�re. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   Le curseur peut-�tre d�plac� n'importe o� sur l'�cran et le texte modifi�.
;   Cependant le curseur ne peut sortir des limites de l'�cran, il n'y a pas de d�filement.
;   L'�diteur fonctionne en mode �crasement, donc si le curseur est d�plac� au dessus d'un
;   caract�re il sera remplac� par le caract�re tap� � cet endroit. La seule fa�on d'ins�rer
;   un caract�re au milieu d'un ligne est d'utiliser la touche INSERT suivie du caract�re.     
; COMMANDES:
;   D�placement du curseur:
;   UP D�place le curseur sur la ligne sup�rieure.
;   DOWN D�place le curseur sur la ligne suivante.
;   LEFT D�place le curseur d'un caract�re vers la gauche.
;   RIGHT D�place le curseur d'un caract�re vers la droite.    
;   HOME   Va au d�but de la ligne.
;   END    Va � la fin de la ligne.
;   PGUP   D�place le curseur dans le coin sup�rieur gauche de l'�cran.
;   PGDN   D�place le curseur � la fin du texte.    
;   �dition:   
;   L'�diteur fonctionne en mode �crasement, i.e. le caract�re est plac� � la 
;   position du curseur et le curseur est avanc� d'une position vers la droite.    
;   DELETE  Efface le caract�re � la position du curseur.
;   INSERT  Ins�re un espace � la position du curseur. S'il y a un caract�re � la colonne 64 il est perdu.    
;   BACKSPACE Efface le caract�re � gauche du curseur.
;   CTRL_K Efface � partir du curseur jusqu'� la fin de la ligne    
;   CTRL_X  Supprime la ligne sur laquelle le curseur r�side.
;   CTRL_Y  Ins�re une ligne vide avant celle o� se trouve le curseur.
;   Manipulation des blocs:    
;   CTRL_B  Affiche le num�ro du bloc, sa taille ainsi que num�ro du bloc pr�c�demment �dit�.    
;   CTRL_S  Sauvegarde de l'�cran dans le bloc.
;   CTRL_N  Charge le bloc suivant pour �dition.
;   CTRL_P  Charge le bloc pr�c�dent pour �dition.     
;   CTRL_I  �dtion d'un bloc quelconque. Demande le num�ro du bloc.
;   CTRL_Q  Quitte l'�diteur.

     
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
;   u  Nombre maximum de caract�res que peut contenir l'�cran. Selon le standard ANS Forth c'est 1024 caract�res.    
DEFCONST "MAXCHAR",7,,MAXCHAR,BLOCK_SIZE
    
    
; nom: TEXTEND  ( -- )
;   Positionne le curseur � la fin du texte. Balaie la m�moire tampon de l'�cran � partir
;   de la fin et s'arr�te apr�s le premier caract�re non blanc.     
; arguments:
;   aucun
; retourne:
;   rien 
DEFWORD "TEXTEND",7,,TEXTEND     
;HEADLESS TEXTEND,HWORD
     .word SCRBUF,LIT,CPL,LIT,LPS,STAR,DUP,TOR,PLUS
     .word RFROM,LIT,0,DODO
1:   .word ONEMINUS,DUP,ECFETCH,BL,UGREATER,ZBRANCH,2f-$
     .word UNLOOP,BRANCH,9f-$
2:   .word DOLOOP,1b-$
9:   .word ONEPLUS,SCRBUF,MINUS,LIT,CPL,SLASHMOD
     .word ONEPLUS,SWAP,ONEPLUS,SWAP,CURPOS,EXIT
     
; EDINIT  ( n+ -- )
;   Initialise les variable de l'�diteur BLKED. Appell� par BLKED au d�marrage de ce dernier.
; arguments:
;   n+    Num�ro du bloc � �diter
; retourne:
;   rien     
HEADLESS EDINIT,HWORD
    .word LIST,TEXTEND,EXIT
 
    
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
    .word SCR,FETCH,DUP,SCRTOBLK,DROP
    .word ONEPLUS,LIST,TEXTEND,EXIT
    
; nom: PREVBLOCK  ( -- )
;   Sauvegarde l'�cran actuel et charge le bloc pr�c�dent pour �dition.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "PREVBLOCK",9,,PREVBLOCK
    .word SCR,FETCH,DUP,SCRTOBLK,DROP
    .word ONEMINUS,QDUP,ZBRANCH,9f-$
    .word LIST,TEXTEND
9:  .word EXIT


; nom: OPENBLOCK  ( -- )
;   Charge un nouveau bloc pour �dition. Le num�ro du bloc est fourni par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "OPENBLOCK",9,,OPENBLOCK
    .word FALSE,CURENBL,LIT,1,DUP,SAVELINE,GETCUR ; s: 1 col line
    .word ROT,SETY,CLEARLN ; s: col line
    .word STRQUOTE
    .byte 14
    .ascii "block number? "
    .align 2
    .word TYPE,LIT,1,TRUE,INVLN,TRUE,CURENBL
    .word TIB,FETCH,DUP,LIT,CPL-1,ACCEPT,FALSE,CURENBL
    .word SRCSTORE,LIT,0,TOIN,STORE
    .word BL,WORD,DUP,CFETCH,ZBRANCH,8f-$
    .word QNUMBER,ZBRANCH,8f-$
    .word LIST,TEXTEND,BRANCH,9f-$
8:  .word LIT,1,RESTORELINE,CURPOS
9:  .word TRUE,CURENBL,EXIT
    
    
; VT-UPDATE  ( -- )
;   l'�diteur doit mettre � jour l'�cran de la console VT102 si le syst�me est en REMOTE CONSOLE
; arguments:
;   aucun
; retourne:
;   rien    
;DEFWORD "VT-UPDATE",9,,VTUPDATE
;    .word SYSCONS,FETCH,SERCONS,EQUAL,TBRANCH,2f-$,DROP,EXIT
;2:  .word GETCUR,ROT  
;    .word DUP,LIT,0,SWAP,VTATXY
;    .word LIT,CPL,STAR,SCRBUF,PLUS,LIT,CPL,LIT 
;    .word EXIT   
 
; Efface du curseur jusqu'� la fin de la ligne    
HEADLESS DELEOL,HWORD
    .word FALSE,CURENBL
    .word LIT,CPL,GETX,DODO
1:  .word DOI,GETY,BL,CHRTOSCR,DOLOOP,1b-$
    .word TRUE,CURENBL,EXIT

; Insi�re une ligne au dessus de celle o� se trouve le curseur.
; Sauf s'il y a du texte sur la derni�re ligne de l'�ran.    
HEADLESS INSLN,HWORD
    .word LCGETCUR,TEXTEND,GETY,LIT,LPS,EQUAL,ZBRANCH,2f-$
    .word CURPOS,EXIT
2:  .word FALSE,CURENBL    
    .word SWAP,DROP,TOR,RFETCH,LNADR,DUP,LIT,CPL,PLUS
    .word SCRBUF,LIT,CPL,LIT,LPS,STAR,PLUS,OVER,MINUS
    .word MOVE,RFROM,SETY,CLRLN
    .word TRUE,CURENBL,EXIT
    
; Retire la ligne sur laquelle se trouve le curseur    
HEADLESS RMLN,HWORD
    .word FALSE,CURENBL
    .word GETY,LNADR,TOR,RFETCH,LIT,CPL,PLUS
    .word DUP,SCRBUF,LIT,CPL,LIT,LPS,STAR,PLUS,SWAP,MINUS
    .word RFROM,SWAP,MOVE
    .word LIT,1,GETY,LIT,LPS,SETY,CLRLN,CURPOS
    .word TRUE,CURENBL,EXIT
   
; Supprime le caract�re � la position du curseur.
HEADLESS DELCHR,HWORD
    .word DELETE
    .word EXIT
    
; D�place le texte d'un position vers la droite
; pour laisser un espace � la position du curseur.
HEADLESS INSERTBL,HWORD
    .word FALSE,CURENBL
    .word CURADR,DUP,ONEPLUS,LIT,CPL,GETX,MINUS,MOVE
    .word BL,CURADR,CSTORE
    .word TRUE,CURENBL,EXIT
    
; D�place le curseur � la fin du texte sur cette ligne.    
HEADLESS TOEOL,HWORD
    .word LIT,VK_END,EMIT
    .word EXIT
   
; D�place le curseur au d�but de la ligne.    
HEADLESS TOSOL,HWORD
    .word LIT,VK_HOME,EMIT,EXIT
    
; D�place le curseur 1 ligne vers le haut.    
HEADLESS LNUP,HWORD
    .word LIT,VK_UP,EMIT
    .word EXIT
    
;D�place le curseur une ligne vers le bas.     
HEADLESS LNDN,HWORD
    .word LIT,VK_DOWN,EMIT
    .word EXIT

; D�place le curseur au d�but de la ligne suivante
; sauf s'il est sur la derni�re ligne.    
HEADLESS CRLF,HWORD
    .word GETY,LIT,LPS,EQUAL,TBRANCH,9f-$
    .word LCCR
9:  .word EXIT
    
; d�pose le caract�re dans la m�moire tampon vid�o.
; � la position actuelle du curseur.    
HEADLESS CHRTOBUF,HWORD ; ( c -- )
    .word CURADR,CSTORE,EXIT
    
; Affiche le caract�re � la position de l'�cran.
HEADLESS PUTCHR,HWORD ; ( c -- )
    .word LCGETCUR,LIT,LPS,EQUAL,ZBRANCH,8f-$
    .word LIT,CPL,EQUAL,ZBRANCH,9f-$
    .word CHRTOBUF,EXIT
8:  .word DROP
9:  .word LCEMIT,EXIT

; attend une touche au clavier.  
HEADLESS EDKEY,HWORD
    .word SCRSIZE,MAXCHAR,GREATER,ZBRANCH,2f-$
    .word STRQUOTE
    .byte 31
    .ascii "Screen to big to fit in a bloc."
    .align 2
    .word LIT,1,MSGLINE
2:  .word LCEKEY, EXIT

; efface le caract�re avant le curseur.  
HEADLESS BACKCHAR,HWORD 
    .word GETX,ONEMINUS,ZBRANCH,9f-$,DELBACK
9:  .word EXIT

; D�place le curseur 1 caract�re � gauche.  
HEADLESS LEFT,HWORD
    .word LIT,VK_LEFT,EMIT
    .word EXIT

; D�placele curseur 1 caract�re � droite.    
HEADLESS RIGHT,HWORD
    .word LIT,VK_RIGHT,EMIT
    .word EXIT

; D�place le caract�re dans le coin sup�rieur gauche.    
HEADLESS PAGEUP,HWORD
    .word LIT,1,LIT,1,CURPOS,EXIT
    
; sauvegarde l'�cran dans le bloc. 
DEFWORD "SAVESCREEN",10,,SAVESCREEN ; ( -- )   
;HEADLESS SAVESCREEN,HWORD
    .word SCR,FETCH,SCRTOBLK
    .word TBRANCH,8f-$
    .word STRQUOTE
    .byte 22
    .ascii "Failed to save screen."
    .align 2
    .word BRANCH,9f-$
8:  .word STRQUOTE
    .byte 13
    .ascii "Screen saved."
    .align 2
9:  .word LIT,1,MSGLINE
    .word EXIT    
    
; affiche le num�ro du bloc et sa taille.    
HEADLESS BLKINFO,HWORD
    .word FALSE,CURENBL,GETCUR,SCRSIZE ; S: col line size
    .word LIT,1,DUP,SAVELINE,DUP,CURPOS,CLEARLN
    .word STRQUOTE
    .byte  6
    .ascii "bloc#:"
    .align 2
    .word TYPE,SCR,FETCH,UDOT,LIT,16,SETX
    .word STRQUOTE
    .byte 5
    .ascii "size:"
    .align 2
    .word TYPE,UDOT
    .word LIT,1,DUP,TRUE,INVLN
    .word LCKEY,DROP,RESTORELINE
    .word CURPOS,TRUE,CURENBL,EXIT
    
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
    .word DUP,LIT,127,ULESS,ZBRANCH,4f-$
    .word PUTCHR,BRANCH,1b-$
    ; c<32
2:  .word LIT,VK_CR,KCASE,ZBRANCH,2f-$,CRLF,BRANCH,1b-$
2:  .word LIT,VK_BACK,KCASE,ZBRANCH,2f-$,BACKCHAR,BRANCH,1b-$
2:  .word LIT,CTRL_B,KCASE,ZBRANCH,2f-$,BLKINFO,BRANCH,1b-$  
2:  .word LIT,CTRL_N,KCASE,ZBRANCH,2f-$,NEXTBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_P,KCASE,ZBRANCH,2f-$,PREVBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_Q,KCASE,ZBRANCH,2f-$,CLS,EXIT
2:  .word LIT,CTRL_S,KCASE,ZBRANCH,2f-$,SAVESCREEN,BRANCH,1b-$
2:  .word LIT,CTRL_I,KCASE,ZBRANCH,2f-$,OPENBLOCK,BRANCH,1b-$  
2:  .word LIT,CTRL_K,KCASE,ZBRANCH,2f-$,DELEOL,BRANCH,1b-$
2:  .word LIT,CTRL_X,KCASE,ZBRANCH,2f-$,RMLN,BRANCH,1b-$  
2:  .word LIT,CTRL_Y,KCASE,ZBRANCH,2f-$,INSLN,BRANCH,1b-$
2:  .word DROP,BRANCH,1b-$
    ; c>=127
4:  .word LIT,VK_DELETE,KCASE,ZBRANCH,4f-$,DELCHR,BRANCH,1b-$    
4:  .word LIT,VK_INSERT,KCASE,ZBRANCH,4f-$,INSERTBL,BRANCH,1b-$  
4:  .word LIT,VK_LEFT,KCASE,ZBRANCH,4f-$,LEFT,BRANCH,1b-$
4:  .word LIT,VK_RIGHT,KCASE,ZBRANCH,4f-$,RIGHT,BRANCH,1b-$ 
4:  .word LIT,VK_UP,KCASE,ZBRANCH,4f-$,LNUP,BRANCH,1b-$
4:  .word LIT,VK_DOWN,KCASE,ZBRANCH,4f-$,LNDN,BRANCH,1b-$
4:  .word LIT,VK_HOME,KCASE,ZBRANCH,4f-$,TOSOL,BRANCH,1b-$
4:  .word LIT,VK_END,KCASE,ZBRANCH,4f-$,TOEOL,BRANCH,1b-$
4:  .word LIT,VK_PGUP,KCASE,ZBRANCH,4f-$,PAGEUP,BRANCH,1b-$  
4:  .word LIT,VK_PGDN,KCASE,ZBRANCH,4f-$,TEXTEND,BRANCH,1b-$
4:  .word DROP,BRANCH,1b-$
   
    .word EXIT
    
    