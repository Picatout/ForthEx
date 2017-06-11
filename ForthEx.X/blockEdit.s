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
;   Le probl�me c'est que BLKED utilise un �cran de 23 lignes au lieu de 16 ce qui
;   fait qu'un bloc serait de 1472 caract�res au lieu de 1024. Mais comme le standard
;   ANS Forth d�finie toujours les blocs comme �tant 1024 caract�res je devais trouver
;   une solution pour sauvegarder les �crans dans des blocs. Entre autre solutions il y a
;   1) M'�carter du standard et modifier la taille des blocs � 1472 octets.
;   2) Utiliser 2 blocs standards pour sauvegarder un �cran, occasionne une perte d'espace.
;   3) Compressser le contenu de l'�cran pour le faire entrer dans un bloc standard, gain d'espace.
;   J'ai opt� pour la 3i�me solution.     
;   En principe Lorsqu'on �cris du code source les lignes ne sont pas pleines.
;   Parfois on laisse m�me des lignes vides pour rendre le texte plus facile � lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronqu�es apr�s le dernier caract�re
;   et un caract�re de fin de ligne est ajout�. Il y a 23 lignes sur un �cran donc
;   si la longueur moyenne des lignes est inf�rieure � (BLOCK_SIZE-23)/23 l'�cran peut
;   �tre sauvegard� dans un bloc. Le mot SCR-SIZE d�fini dans le fichier block.s
;   permet de conna�tre la taille occup�e par un �cran dans un bloc.
;   Il est problable que la majorit� des cas un �cran avec les lignes tronqu�es apr�s
;   le dernier caract�re r�pondra � ce crit�re. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   BLKED r�serve la ligne 24 comme ligne d'�tat donc un bloc de texte occupe les
;   lignes 1..23.     
;   Le curseur peut-�tre d�plac� n'importe o� sur l'�cran et le texte modifi�.
;   Cependant le curseur ne peut sortir des limites de l'�cran, il n'y a pas de d�filement.
;   L'�diteur fonctionne en mode �crasement, donc si le curseur est d�plac� au dessus d'un
;   caract�re il sera remplac� par le caract�re tap� � cet endroit. La seule fa�on d'ins�rer
;   un caract�re au milieu d'un ligne est d'utiliser la touche INSERT suivie du caract�re.     
; COMMANDES:
;   D�placement du curseur:
;   UP D�place le curseur d'une ligne vers le haut.
;   DOWN D�place le curseur d'une ligne vers le bas.
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
;   CTRL_D  Efface la ligne du curseur et place celui-ci � la marge gauche.     
;   CTRL_K  Efface � partir du curseur jusqu'� la fin de la ligne.    
;   CTRL_L  Efface tout l'�cran. 
;   CTRL_X  Supprime la ligne sur laquelle le curseur r�side.
;   CTRL_Y  Ins�re une ligne vide avant celle o� se trouve le curseur.
;   Manipulation des blocs:    
;   CTRL_B  Sauvegarde de l'�cran dans le bloc.
;   CTRL_N  Sauvegarde le bloc actuel et charge le bloc suivant pour �dition.
;   CTRL_P  Sauvegarde le bloc actuel et charge le bloc pr�c�dent pour �dition.     
;   CTRL_O  Sauvegarde le bloc actuel et saisie d'un num�ro de bloc pour �dition.
;   CTRL_E  Quitte l'�diteur,le contenu de l'�cran n'est pas sauvegard�.

     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilis�es par l'�diteur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOM: EDITLN ( -- n )
;   Nombre de lignes de texte utilis�es par BLKED.
; arguments:
;   aucun
; retourne:
;   n Nombre de lignes, 23, i.e. {1..23}, ligne 24 r�serv�e.
DEFCODE "EDITLN",6,,EDITLN
     DPUSH
     mov #LPS-1,T
     NEXT
     
; nom: TEXTEND  ( -- )
;   Positionne le curseur � la fin du texte. Balaie la m�moire tampon de l'�cran � partir
;   de la fin de la ligne 23 et s'arr�te apr�s le premier caract�re non blanc.     
; arguments:
;   aucun
; retourne:
;   rien 
DEFWORD "TEXTEND",7,,TEXTEND     
;HEADLESS TEXTEND,HWORD
     .word SCRBUF,LIT,CPL,EDITLN,STAR,DUP,TOR,PLUS
     .word RFROM,LIT,0,DODO
1:   .word ONEMINUS,DUP,ECFETCH,BL,UGREATER,ZBRANCH,2f-$
     .word UNLOOP,BRANCH,9f-$
2:   .word DOLOOP,1b-$
9:   .word ONEPLUS,SCRBUF,MINUS,LIT,CPL,SLASHMOD
     .word ONEPLUS,SWAP,ONEPLUS,SWAP
     .word DUP,EDITLN,UGREATER,ZBRANCH,2f-$
     .word TWODROP,LIT,CPL,EDITLN
2:   .word ATXY,EXIT
     
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
;   Sauvegarde de la ligne d'�cran 'n' dans le tampon PAD.
;   Pour que RESTORELINE restitue la ligne d'�cran � son �tat original
;   l'application doit �viter d'�craser le contenu des 64 premiers caract�res
;   du  PAD entre les 2 appels.
; arguments:
;   n Num�ro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word FALSE,CURENBL,LNADR  ; s: src
    .word PAD,FETCH,LIT,CPL,MOVE 
    .word TRUE,CURENBL,EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'�cran � partir du tampon PAD.
; arguments:
;   n Num�ro de la ligne � restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word FALSE,CURENBL,LNADR,PAD,FETCH,LIT,CPL,ROT ; s: src len n
    .word SWAP,MOVE
    .word TRUE,CURENBL,EXIT
    
; nom: ED-WITHELN ( n -- )
;   Console LOCAL et REMOTE.    
;   Imprime une ligne blanche et laisse le curseur au d�but de celle-ci
;   � la sortie le mode vid�o est invers�, i.e. noir/blanc.
; arguments:
;   n Num�ro de la ligne {1..24}
; retourne:
;   rien
DEFWORD "ED-WHITELN",10,,EDWHITELN
    .word DUP,LCWHITELN,VTWHITELN,EXIT
    
; nom: PROMPT  ( c-addr u n -- )
;   Affiche un message en vid�o invers� sur la ligne 'n' de l'�cran.
;   Utilise SAVELINE pour conserver le contenu original de cette ligne dans
;   la m�moire tampon PAD.  Les applications qui utilisent PROMPT et doivent restaurer
;   le contenu original de la ligne utilis�e par PROMPT doivent s'assurer
;   de ne pas �craser les 64 premiers caract�res du PAD.
;   Apr�s l'ex�cution de PROMPT la sortie vid�o est en mode invers�e et le curseur
;   est positionn� apr�s le prompt permettant une saisie d'information par l'application.    
; arguments:
;   c-addr Adresse du premier caract�re du message � afficher.
;   u Nombre de caract�res du message, maximum 63.
;   n Num�ro de la ligne sur laquelle le message sera affich�, {1..24}
; retourne:
;   rien    
DEFWORD "PROMPT",6,,PROMPT ; ( c-addr u n+ -- )
    .word DUP,SAVELINE,WHITELN ; s: c-addr u n+
    .word LIT,CPL-1,AND,TYPE,EXIT 
    
; nom: MSGLINE  ( c-addr u n -- )
;   Affiche un message � l'�cran et attend une touche au clavier pour poursuivre
;   l'ex�cution. Le message doit tenir sur une seule ligne d'�cran. Cette ligne
;   d'�cran est sauvegard�e et restaur�e � la sortie de ce mot. Le curseur texte
;   est retourn� � la position qu'il avait avant l'appel de MSGLINE.    
; arguments:
;   c-addr Adresse du premier caract�re du message.
;   u  Longueur du message, limit� � 63 caract�res.
;   n  Num�ro de la ligne o� doit-�tre affich� le message.
DEFWORD "MSGLINE",7,,MSGLINE ; ( c-addr u n -- )
     .word GETCUR,TWOTOR ; S: c-addr u n R: col line
     .word DUP,TOR,PROMPT ; s:  r: col line n
     .word KEY,DROP
     .word FALSE,BSLASHW,RFROM,RESTORELINE
2:   .word TWORFROM,ATXY,EXIT
  
HEADLESS SAVEFAILED,HWORD
    .word STRQUOTE
    .byte 30
    .ascii "Failed to save screen."
    .align 2
9:  .word LIT,LPS,MSGLINE,EXIT
    
HEADLESS SAVESUCCESS,HWORD
    .word STRQUOTE
    .byte 13
    .ascii "Screen saved."
    .align 2
    .word BRANCH,9b-$
    
; NEXTBLOCK ( -- )
;   Sauvegarde l'�cran actuel et charge le bloc suivant pour �dition.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS NEXTBLOCK,HWORD    
;DEFWORD "NEXTBLOCK",9,,NEXTBLOCK
    .word SCR,FETCH,DUP,SCRTOBLK,TBRANCH,2f-$
    .word SAVEFAILED,EXIT
2:  .word ONEPLUS,DUP,BLKDEVFETCH,FN_BOUND,VEXEC,ZBRANCH,9f-$
    .word LIST,EXIT
9:  .word DROP,EXIT
    
; PREVBLOCK  ( -- )
;   Sauvegarde l'�cran actuel et charge le bloc pr�c�dent pour �dition.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS PREVBLOCK,HWORD  
;DEFWORD "PREVBLOCK",9,,PREVBLOCK
    .word SCR,FETCH,DUP,SCRTOBLK,TBRANCH,2f-$
    .word SAVEFAILED,EXIT
2:  .word ONEMINUS,QDUP,ZBRANCH,9f-$
    .word LIST
9:  .word EXIT


; OPENBLOCK  ( -- )
;   Charge un nouveau bloc pour �dition. Le num�ro du bloc est fourni par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS OPENBLOCK,HWORD  
;DEFWORD "OPENBLOCK",9,,OPENBLOCK
    .word GETCUR,STRQUOTE
    .byte 14
    .ascii "block number? "
    .align 2
    .word LIT,LPS,PROMPT
    .word TIB,FETCH,DUP,LIT,CPL,GETX,MINUS,ACCEPT,FALSE,BSLASHW
    .word SRCSTORE,LIT,0,TOIN,STORE
    .word BL,WORD,DUP,CFETCH,ZBRANCH,8f-$
    .word QNUMBER,ZBRANCH,8f-$
    .word LIST,TWODROP,EXIT
8:  .word LIT,LPS,RESTORELINE,CURPOS
9:  .word EXIT
    

  
; Insi�re une ligne au dessus de celle o� se trouve le curseur.
; Sauf s'il y a du texte sur la derni�re ligne de l'�ran.    
HEADLESS INSLN,HWORD
    .word LCGETCUR,TEXTEND,GETY,LIT,LPS,EQUAL,ZBRANCH,2f-$
    .word CURPOS,EXIT
2:  .word FALSE,CURENBL    
    .word SWAP,DROP,TOR,RFETCH,LNADR,DUP,LIT,CPL,PLUS
    .word SCRBUF,LIT,CPL,LIT,LPS,STAR,PLUS,OVER,MINUS
    .word MOVE,RFROM,SETY,DELLN
    .word TRUE,CURENBL,EXIT
    
; Supprime le caract�re � la position du curseur.
HEADLESS DELCHR,HWORD
    .word LCDEL,ISLOCAL,TBRANCH,2f-$,VTDEL
2:  .word EXIT
    
; D�place le texte d'un position vers la droite
; pour laisser un espace � la position du curseur.
HEADLESS INSERTBL,HWORD
    .word FALSE,CURENBL
    .word CURADR,DUP,ONEPLUS,LIT,CPL,GETX,MINUS,MOVE
    .word BL,CURADR,CSTORE,ISLOCAL,TBRANCH,2f-$,VTINSERT
2:  .word TRUE,CURENBL,EXIT
    
; D�place le curseur � la fin du texte sur cette ligne.    
HEADLESS TOEOL,HWORD
    .word LCEND, ISLOCAL,TBRANCH,2f-$
    .word LCGETCUR,VTATXY
2:  .word EXIT
   
; D�place le curseur au d�but de la ligne.    
HEADLESS TOSOL,HWORD
    .word LIT,VK_HOME,EMIT,EXIT
    
; D�place le curseur 1 ligne vers le haut.    
HEADLESS LNUP,HWORD
    .word LIT,VK_UP,EMIT
    .word EXIT
    
;D�place le curseur une ligne vers le bas.     
HEADLESS LNDN,HWORD
    .word LCGETCUR,SWAP,DROP,EDITLN,EQUAL,TBRANCH,9f-$
    .word LIT,VK_DOWN,EMIT
9:  .word EXIT

; D�place le curseur au d�but de la ligne suivante
; sauf s'il est sur la derni�re ligne.    
HEADLESS CRLF,HWORD
    .word GETY,EDITLN,EQUAL,TBRANCH,9f-$
    .word CR
9:  .word EXIT
    
; check si c'est la derni�re position de l'�cran.
HEADLESS LASTPOS,HWORD
    .word LCGETCUR,EDITLN,EQUAL,ZBRANCH,9f-$
    .word LIT,CPL,EQUAL,EXIT
9:  .word DROP,FALSE,EXIT    
    
; Affiche le caract�re � la position du curseur.
HEADLESS PUTCHR,HWORD ; ( c -- )
    .word LASTPOS,NOT,WRAP
    .word EDEMIT
    .word EXIT

; attend une touche au clavier.  
HEADLESS EDKEY,HWORD
    .word SCRSIZE,LIT,BLOCK_SIZE,GREATER,ZBRANCH,2f-$
    .word STRQUOTE
    .byte 31
    .ascii "Screen to big to fit in a bloc."
    .align 2
    .word LIT,LPS,MSGLINE
2:  .word STATUSLN,EKEY,EXIT

; efface le caract�re avant le curseur.  
HEADLESS BACKCHAR,HWORD 
    .word GETX,ONEMINUS,ZBRANCH,9f-$,DELBACK
9:  .word EXIT

; D�place le curseur 1 caract�re � gauche.  
HEADLESS LEFT,HWORD
    .word LIT,VK_LEFT,EMIT
    .word EXIT

; D�place le curseur 1 caract�re � droite.    
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
    .word SAVEFAILED,EXIT
8:  .word SAVESUCCESS
    .word EXIT    
 
; avance le curseur � la prochaine tabulation.    
HEADLESS TABADV, HWORD
    .word NEXTCOLON,ISLOCAL,ZBRANCH,1f-$,EXIT
1:  .word LCGETCUR,VTATXY,EXIT    
    
; Affiche la ligne d'�tat    
; Indique le num�ro du bloc et la taille actuelle de l'�cran.    
HEADLESS STATUSLN,HWORD
    .word LCGETCUR,SCRSIZE ; S: col line size
    .word LIT,LPS,WHITELN
    .word STRQUOTE
    .byte  6
    .ascii "bloc#:"
    .align 2
    .word TYPE,SCR,FETCH,UDOT,SPACE,NEXTCOLON
    .word STRQUOTE
    .byte 5
    .ascii "size:"
    .align 2
    .word TYPE,UDOT,SPACE,NEXTCOLON
    .word STRQUOTE
    .byte 4
    .ascii "col:"
    .align 2
    .word TYPE,OVER,UDOT,SPACE,NEXTCOLON
    .word STRQUOTE
    .byte 5
    .ascii "line:"
    .align 2
    .word TYPE,DUP,UDOT
    .word FALSE,BSLASHW
    .word EDATXY,EXIT
   
; nom: ED-EMIT ( c -- )
;   Console locale et remote    
;   �metteur de caract�re utilis� par BLKED lorsque la console est en REMOTE.
;   Cet �metteur sp�cial est requis car il faut maintenir un tampon local de
;   l'�cran. � cet effet le tampon vid�o local est utilis�.    
; arguments
;   c	Caract�re � �mettre
; retourne:    
;   rien
DEFWORD "ED-EMIT",7,,EDEMIT
    .word DUP,LCEMIT,VTEMIT
    .word EXIT
    
; nom: ED-AT-XY ( n1 n2 -- )
;   Console locate et remote.
;   Positionne le curseur � la colonnne 'n1' et la ligne 'n2'
; arguments:
;   n1 Colonne {1..64}
;   n2 Ligne {1..24}
; retourne:
;   rien
DEFWORD "ED-AT-XY",8,,EDATXY
    .word TWODUP,LCATXY,VTATXY,EXIT

; nom: ED-PAGE ( -- )
;   Console LOCAL et REMOTE
;   Efface l'�crran.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "ED-PAGE",7,,EDPAGE
    .word LCPAGE,VTPAGE,EXIT
    
; nom: ED-B/W  ( f -- )  
;   Console LOCAL et REMOTE    
;   Inverse l'affichage vid�o.
; arguments:
;   f Indicateur Bool�en, si VRAI inverse la sortie vid�o, si FAUX vid�o normal.
; retourne:
;   rien
DEFWORD "ED-B/W",6,,EDBSLASHW
    .word DUP,LCBSLASHW,VTBSLASHW,EXIT
    
; nom: ED-INSRTLN ( -- )
;   Console LOCAL et REMOTE    
;   Ins�re une ligne vide � la position du curseur. Les lignes � partir du curseur
;   en sont d�cal�es vers le bas. S'il y a du texte sur la derni�re ligne celui-ci dispara�t.
; arguments:    
;   aucun
; retourne:
;   rien
DEFWORD "ED-INSRTLN",10,,EDINSRTLN
    .word LCINSRTLN,VTINSRTLN,EXIT
    
; nom: ED-DELLN ( -- )
;   Console LOCAL et REMOTE
;   Vide la ligne du curseur et ram�ne celui-ci � gauche de l'�cran.
; arguments:    
;   aucun
; retourne:
;   rien
DEFWORD "ED-DELLN",8,,EDDELLN
    .word LCDELLN,VTDELLN,EXIT
    
; nom: ED-RMVLN  ( -- )
;   Console LOCAL et REMOTE    
;   Supprime la ligne � la position du curseur. Les lignes sous celle-ci sont
;   d�cal�es vers haut pour combler le vide et la derni�re ligne de la console
;   se retrouve vide.
; arguments:    
;   aucun
; retourne:
;   rien
DEFWORD "ED-RMVLN",8,,EDRMVLN
    .word LCRMVLN,VTRMVLN,EXIT
    
HEADLESS BLKEDINIT ,HWORD
    .word ISLOCAL,TBRANCH,1f-$
    .word EDCONS,SYSCONS,STORE
1:  .word LIST,EXIT    
    
; nom: BLKED  ( n+ -- )  
;   �diteur de bloc texte. Edite 1 bloc � la fois.
;   Le curseur peut-�tre d�plac� � n'importe qu'elle position sur l'�cran et 
;   son contenu modifi� � volont� avant de le sauvegarder le bloc sur le
;   p�riph�irque de stockage actif. Si ce bloc contient du texte source ForthEx
;   il peut-�tre ult�rieurement �valu� par la commande LOAD ou THRU.  
; arguments:
;   n+   Le num�ro du bloc � �diter.
; retourne:
;   rien  
DEFWORD "BLKED",5,,BLKED ; ( n+ -- )
    .word SYSCONS,FETCH,TOR,BLKEDINIT
1:  .word EDKEY,DUP,QPRTCHAR,ZBRANCH,2f-$
    .word PUTCHR,BRANCH,1b-$
2:  .word DUP,BL,ULESS,ZBRANCH,4f-$    
    ; c<32
2:  .word LIT,VK_CR,KCASE,ZBRANCH,2f-$,CRLF,BRANCH,1b-$
2:  .word LIT,VK_BACK,KCASE,ZBRANCH,2f-$,BACKCHAR,BRANCH,1b-$
2:  .word LIT,VK_TAB,KCASE,ZBRANCH,2f-$,TABADV,BRANCH,1b-$ 
2:  .word LIT,CTRL_L,KCASE,ZBRANCH,2f-$,CLS,BRANCH,1b-$  
2:  .word LIT,CTRL_D,KCASE,ZBRANCH,2f-$,DELLN,BRANCH,1b-$  
2:  .word LIT,CTRL_N,KCASE,ZBRANCH,2f-$,NEXTBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_P,KCASE,ZBRANCH,2f-$,PREVBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_E,KCASE,ZBRANCH,2f-$,CLS,RFROM,SYSCONS,STORE,TRUE,SCROLL,EXIT
2:  .word LIT,CTRL_B,KCASE,ZBRANCH,2f-$,SAVESCREEN,BRANCH,1b-$
2:  .word LIT,CTRL_O,KCASE,ZBRANCH,2f-$,OPENBLOCK,BRANCH,1b-$  
2:  .word LIT,CTRL_K,KCASE,ZBRANCH,2f-$,DELEOL,BRANCH,1b-$
2:  .word LIT,CTRL_X,KCASE,ZBRANCH,2f-$,RMVLN,BRANCH,1b-$  
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
    
    