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
;   Éditeur de texte simple qui travail sur un seul écran à la fois et permet
;   de sauvegarder le texte de cet écran dans un bloc. Ultérieurement ce
;   bloc peut-être évalué avec la commande LOAD. 
;   L'idée d'un éditeur de bloc viens de l'origine même du langage. Charles Moore
;   Travaillait sur un terminal vidéo de 16 lignes de 64 caractères, ce qui fait qu'un
;   écran occupait 1024 caractères. Il avait donc eu l'idée de sauvegarder le contenu
;   de la mémoire vidéo sur l'unité de stockage permanent sans modification.
;   Chaque écran sauvegardé s'appelait un bloc.
;   Le problème c'est que BLKED utilise un écran de 23 lignes au lieu de 16 ce qui
;   fait qu'un bloc serait de 1472 caractères au lieu de 1024. Mais comme le standard
;   ANS Forth définie toujours les blocs comme étant 1024 caractères je devais trouver
;   une solution pour sauvegarder les écrans dans des blocs. Entre autre solutions il y a
;   1) M'écarter du standard et modifier la taille des blocs à 1472 octets.
;   2) Utiliser 2 blocs standards pour sauvegarder un écran, occasionne une perte d'espace.
;   3) Compressser le contenu de l'écran pour le faire entrer dans un bloc standard, gain d'espace.
;   J'ai opté pour la 3ième solution.     
;   En principe Lorsqu'on écris du code source les lignes ne sont pas pleines.
;   Parfois on laisse même des lignes vides pour rendre le texte plus facile à lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronquées après le dernier caractère
;   et un caractère de fin de ligne est ajouté. Il y a 23 lignes sur un écran donc
;   si la longueur moyenne des lignes est inférieure à (BLOCK_SIZE-23)/23 l'écran peut
;   être sauvegardé dans un bloc. Le mot SCR-SIZE défini dans le fichier block.s
;   permet de connaître la taille occupée par un écran dans un bloc.
;   Il est problable que la majorité des cas un écran avec les lignes tronquées après
;   le dernier caractère répondra à ce critère. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   BLKED réserve la ligne 24 comme ligne d'état donc un bloc de texte occupe les
;   lignes 1..23.     
;   Le curseur peut-être déplacé n'importe où sur l'écran et le texte modifié.
;   Cependant le curseur ne peut sortir des limites de l'écran, il n'y a pas de défilement.
;   L'éditeur fonctionne en mode écrasement, donc si le curseur est déplacé au dessus d'un
;   caractère il sera remplacé par le caractère tapé à cet endroit. La seule façon d'insérer
;   un caractère au milieu d'un ligne est d'utiliser la touche INSERT suivie du caractère.     
; COMMANDES:
;   Déplacement du curseur:
;   UP Déplace le curseur d'une ligne vers le haut.
;   DOWN Déplace le curseur d'une ligne vers le bas.
;   LEFT Déplace le curseur d'un caractère vers la gauche.
;   RIGHT Déplace le curseur d'un caractère vers la droite.    
;   HOME   Va au début de la ligne.
;   END    Va à la fin de la ligne.
;   PGUP   Déplace le curseur dans le coin supérieur gauche de l'écran.
;   PGDN   Déplace le curseur à la fin du texte.    
;   Édition:   
;   L'éditeur fonctionne en mode écrasement, i.e. le caractère est placé à la 
;   position du curseur et le curseur est avancé d'une position vers la droite.    
;   DELETE  Efface le caractère à la position du curseur.
;   INSERT  Insère un espace à la position du curseur. S'il y a un caractère à la colonne 64 il est perdu.    
;   BACKSPACE Efface le caractère à gauche du curseur.
;   CTRL_D  Efface la ligne du curseur et place celui-ci à la marge gauche.     
;   CTRL_K  Efface à partir du curseur jusqu'à la fin de la ligne.    
;   CTRL_L  Efface tout l'écran. 
;   CTRL_X  Supprime la ligne sur laquelle le curseur réside.
;   CTRL_Y  Insère une ligne vide avant celle où se trouve le curseur.
;   Manipulation des blocs:    
;   CTRL_B  Sauvegarde de l'écran dans le bloc.
;   CTRL_N  Sauvegarde le bloc actuel et charge le bloc suivant pour édition.
;   CTRL_P  Sauvegarde le bloc actuel et charge le bloc précédent pour édition.     
;   CTRL_O  Sauvegarde le bloc actuel et saisie d'un numéro de bloc pour édition.
;   CTRL_E  Quitte l'éditeur,le contenu de l'écran n'est pas sauvegardé.

     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilisées par l'éditeur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOM: EDITLN ( -- n )
;   Nombre de lignes de texte utilisées par BLKED.
; arguments:
;   aucun
; retourne:
;   n Nombre de lignes, 23, i.e. {1..23}, ligne 24 réservée.
DEFCODE "EDITLN",6,,EDITLN
     DPUSH
     mov #LPS-1,T
     NEXT
     
; nom: TEXTEND  ( -- )
;   Positionne le curseur à la fin du texte. Balaie la mémoire tampon de l'écran à partir
;   de la fin de la ligne 23 et s'arrête après le premier caractère non blanc.     
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
;   compare le caractère 'c' reçu du clavier avec la valeur n.  
; arguments:
;    c  Caractère reçu du clavier
;    n  Valeur de comparaison
;  retourne:
;    c  retourne le caractère reçu.
;    f  T si c==n, F si c<>n
HEADLESS KCASE,HWORD
    .word OVER,EQUAL,DUP,ZBRANCH,2f-$
    .word SWAP,DROP
2:  .word EXIT
  
; nom: SAVELINE ( n -- )
;   Sauvegarde de la ligne d'écran 'n' dans le tampon PAD.
;   Pour que RESTORELINE restitue la ligne d'écran à son état original
;   l'application doit éviter d'écraser le contenu des 64 premiers caractères
;   du  PAD entre les 2 appels.
; arguments:
;   n Numéro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word FALSE,CURENBL,LNADR  ; s: src
    .word PAD,FETCH,LIT,CPL,MOVE 
    .word TRUE,CURENBL,EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'écran à partir du tampon PAD.
; arguments:
;   n Numéro de la ligne à restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word FALSE,CURENBL,LNADR,PAD,FETCH,LIT,CPL,ROT ; s: src len n
    .word SWAP,MOVE
    .word TRUE,CURENBL,EXIT
    
; nom: ED-WITHELN ( n -- )
;   Console LOCAL et REMOTE.    
;   Imprime une ligne blanche et laisse le curseur au début de celle-ci
;   À la sortie le mode vidéo est inversé, i.e. noir/blanc.
; arguments:
;   n Numéro de la ligne {1..24}
; retourne:
;   rien
DEFWORD "ED-WHITELN",10,,EDWHITELN
    .word DUP,LCWHITELN,VTWHITELN,EXIT
    
; nom: PROMPT  ( c-addr u n -- )
;   Affiche un message en vidéo inversé sur la ligne 'n' de l'écran.
;   Utilise SAVELINE pour conserver le contenu original de cette ligne dans
;   la mémoire tampon PAD.  Les applications qui utilisent PROMPT et doivent restaurer
;   le contenu original de la ligne utilisée par PROMPT doivent s'assurer
;   de ne pas écraser les 64 premiers caractères du PAD.
;   Après l'exécution de PROMPT la sortie vidéo est en mode inversée et le curseur
;   est positionné après le prompt permettant une saisie d'information par l'application.    
; arguments:
;   c-addr Adresse du premier caractère du message à afficher.
;   u Nombre de caractères du message, maximum 63.
;   n Numéro de la ligne sur laquelle le message sera affiché, {1..24}
; retourne:
;   rien    
DEFWORD "PROMPT",6,,PROMPT ; ( c-addr u n+ -- )
    .word DUP,SAVELINE,WHITELN ; s: c-addr u n+
    .word LIT,CPL-1,AND,TYPE,EXIT 
    
; nom: MSGLINE  ( c-addr u n -- )
;   Affiche un message à l'écran et attend une touche au clavier pour poursuivre
;   l'exécution. Le message doit tenir sur une seule ligne d'écran. Cette ligne
;   d'écran est sauvegardée et restaurée à la sortie de ce mot. Le curseur texte
;   est retourné à la position qu'il avait avant l'appel de MSGLINE.    
; arguments:
;   c-addr Adresse du premier caractère du message.
;   u  Longueur du message, limité à 63 caractères.
;   n  Numéro de la ligne où doit-être affiché le message.
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
;   Sauvegarde l'écran actuel et charge le bloc suivant pour édition.
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
;   Sauvegarde l'écran actuel et charge le bloc précédent pour édition.
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
;   Charge un nouveau bloc pour édition. Le numéro du bloc est fourni par l'utilisateur.    
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
    

  
; Insière une ligne au dessus de celle où se trouve le curseur.
; Sauf s'il y a du texte sur la dernière ligne de l'éran.    
HEADLESS INSLN,HWORD
    .word LCGETCUR,TEXTEND,GETY,LIT,LPS,EQUAL,ZBRANCH,2f-$
    .word CURPOS,EXIT
2:  .word FALSE,CURENBL    
    .word SWAP,DROP,TOR,RFETCH,LNADR,DUP,LIT,CPL,PLUS
    .word SCRBUF,LIT,CPL,LIT,LPS,STAR,PLUS,OVER,MINUS
    .word MOVE,RFROM,SETY,DELLN
    .word TRUE,CURENBL,EXIT
    
; Supprime le caractère à la position du curseur.
HEADLESS DELCHR,HWORD
    .word LCDEL,ISLOCAL,TBRANCH,2f-$,VTDEL
2:  .word EXIT
    
; Déplace le texte d'un position vers la droite
; pour laisser un espace à la position du curseur.
HEADLESS INSERTBL,HWORD
    .word FALSE,CURENBL
    .word CURADR,DUP,ONEPLUS,LIT,CPL,GETX,MINUS,MOVE
    .word BL,CURADR,CSTORE,ISLOCAL,TBRANCH,2f-$,VTINSERT
2:  .word TRUE,CURENBL,EXIT
    
; Déplace le curseur à la fin du texte sur cette ligne.    
HEADLESS TOEOL,HWORD
    .word LCEND, ISLOCAL,TBRANCH,2f-$
    .word LCGETCUR,VTATXY
2:  .word EXIT
   
; Déplace le curseur au début de la ligne.    
HEADLESS TOSOL,HWORD
    .word LIT,VK_HOME,EMIT,EXIT
    
; Déplace le curseur 1 ligne vers le haut.    
HEADLESS LNUP,HWORD
    .word LIT,VK_UP,EMIT
    .word EXIT
    
;Déplace le curseur une ligne vers le bas.     
HEADLESS LNDN,HWORD
    .word LCGETCUR,SWAP,DROP,EDITLN,EQUAL,TBRANCH,9f-$
    .word LIT,VK_DOWN,EMIT
9:  .word EXIT

; Déplace le curseur au début de la ligne suivante
; sauf s'il est sur la dernière ligne.    
HEADLESS CRLF,HWORD
    .word GETY,EDITLN,EQUAL,TBRANCH,9f-$
    .word CR
9:  .word EXIT
    
; check si c'est la dernière position de l'écran.
HEADLESS LASTPOS,HWORD
    .word LCGETCUR,EDITLN,EQUAL,ZBRANCH,9f-$
    .word LIT,CPL,EQUAL,EXIT
9:  .word DROP,FALSE,EXIT    
    
; Affiche le caractère à la position du curseur.
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

; efface le caractère avant le curseur.  
HEADLESS BACKCHAR,HWORD 
    .word GETX,ONEMINUS,ZBRANCH,9f-$,DELBACK
9:  .word EXIT

; Déplace le curseur 1 caractère à gauche.  
HEADLESS LEFT,HWORD
    .word LIT,VK_LEFT,EMIT
    .word EXIT

; Déplace le curseur 1 caractère à droite.    
HEADLESS RIGHT,HWORD
    .word LIT,VK_RIGHT,EMIT
    .word EXIT

; Déplace le caractère dans le coin supérieur gauche.    
HEADLESS PAGEUP,HWORD
    .word LIT,1,LIT,1,CURPOS,EXIT
    
; sauvegarde l'écran dans le bloc. 
DEFWORD "SAVESCREEN",10,,SAVESCREEN ; ( -- )   
;HEADLESS SAVESCREEN,HWORD
    .word SCR,FETCH,SCRTOBLK
    .word TBRANCH,8f-$
    .word SAVEFAILED,EXIT
8:  .word SAVESUCCESS
    .word EXIT    
 
; avance le curseur à la prochaine tabulation.    
HEADLESS TABADV, HWORD
    .word NEXTCOLON,ISLOCAL,ZBRANCH,1f-$,EXIT
1:  .word LCGETCUR,VTATXY,EXIT    
    
; Affiche la ligne d'état    
; Indique le numéro du bloc et la taille actuelle de l'écran.    
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
;   Émetteur de caractère utilisé par BLKED lorsque la console est en REMOTE.
;   Cet émetteur spécial est requis car il faut maintenir un tampon local de
;   l'écran. À cet effet le tampon vidéo local est utilisé.    
; arguments
;   c	Caractère à émettre
; retourne:    
;   rien
DEFWORD "ED-EMIT",7,,EDEMIT
    .word DUP,LCEMIT,VTEMIT
    .word EXIT
    
; nom: ED-AT-XY ( n1 n2 -- )
;   Console locate et remote.
;   Positionne le curseur à la colonnne 'n1' et la ligne 'n2'
; arguments:
;   n1 Colonne {1..64}
;   n2 Ligne {1..24}
; retourne:
;   rien
DEFWORD "ED-AT-XY",8,,EDATXY
    .word TWODUP,LCATXY,VTATXY,EXIT

; nom: ED-PAGE ( -- )
;   Console LOCAL et REMOTE
;   Efface l'écrran.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "ED-PAGE",7,,EDPAGE
    .word LCPAGE,VTPAGE,EXIT
    
; nom: ED-B/W  ( f -- )  
;   Console LOCAL et REMOTE    
;   Inverse l'affichage vidéo.
; arguments:
;   f Indicateur Booléen, si VRAI inverse la sortie vidéo, si FAUX vidéo normal.
; retourne:
;   rien
DEFWORD "ED-B/W",6,,EDBSLASHW
    .word DUP,LCBSLASHW,VTBSLASHW,EXIT
    
; nom: ED-INSRTLN ( -- )
;   Console LOCAL et REMOTE    
;   Insère une ligne vide à la position du curseur. Les lignes à partir du curseur
;   en sont décalées vers le bas. S'il y a du texte sur la dernière ligne celui-ci disparaît.
; arguments:    
;   aucun
; retourne:
;   rien
DEFWORD "ED-INSRTLN",10,,EDINSRTLN
    .word LCINSRTLN,VTINSRTLN,EXIT
    
; nom: ED-DELLN ( -- )
;   Console LOCAL et REMOTE
;   Vide la ligne du curseur et ramène celui-ci à gauche de l'écran.
; arguments:    
;   aucun
; retourne:
;   rien
DEFWORD "ED-DELLN",8,,EDDELLN
    .word LCDELLN,VTDELLN,EXIT
    
; nom: ED-RMVLN  ( -- )
;   Console LOCAL et REMOTE    
;   Supprime la ligne à la position du curseur. Les lignes sous celle-ci sont
;   décalées vers haut pour combler le vide et la dernière ligne de la console
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
;   Éditeur de bloc texte. Edite 1 bloc à la fois.
;   Le curseur peut-être déplacé à n'importe qu'elle position sur l'écran et 
;   son contenu modifié à volonté avant de le sauvegarder le bloc sur le
;   périphéirque de stockage actif. Si ce bloc contient du texte source ForthEx
;   il peut-être ultérieurement évalué par la commande LOAD ou THRU.  
; arguments:
;   n+   Le numéro du bloc à éditer.
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
    
    