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
;   Le problème c'est que ForthEx utilise un écran de 24 lignes au lieu de 16 ce qui
;   fait qu'un bloc serait de 1536 caractères au lieu de 1024. Mais comme le standard
;   ANS Forth définie toujours les blocs comme étant 1024 caractères je devais trouver
;   une solution pour sauvegarder les écrans dans des blocs. Entre autre solutions il y a
;   1) M'écarter du standard et modifier la taille des blocs à 1536 octets.
;   2) Utiliser 2 blocs standards pour sauvegarder un écran, occasionne une perte d'espace.
;   3) Compressser le contenu de l'écran pour le faire entrer dans un bloc standard, gain d'espace.
;   J'ai opté pour la 3ième solution.     
;   En principe Lorsqu'on écris du code source les lignes ne sont pas pleines.
;   Parfois on laisse même des lignes vides pour rendre le texte plus facile à lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronquées après le dernier caractère
;   et un caractère de fin de ligne est ajouté. Il y a 24 lignes sur un écran donc
;   si la longueur moyenne des lignes est inférieure à (BLOCK_SIZE-24)/24 l'écran peut
;   être sauvegardé dans un bloc. L'éditeur le mot SCR-SIZE défini dans le fichier block.s
;   et rapporte une alerte si ce nombre dépasse BLOCK_SIZE.
;   Il est problable que la majorité du temps un écran avec les lignes tronquées après
;   le dernier caractère répondra à ce critère. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   Le curseur peut-être déplacé n'importe où sur l'écran et le texte modifié.
;   Cependant le curseur ne peut sortir des limites de l'écran, il n'y a pas de défilement.
;   L'éditeur fonctionne en mode écrasement, donc si le curseur est déplacé au dessus d'un
;   caractère il sera remplacé par le caractère tapé à cet endroit. La seule façon d'insérer
;   un caractère au milieu d'un ligne est d'utiliser la touche INSERT suivie du caractère.     
; COMMANDES:
;   Déplacement du curseur:
;   UP Déplace le curseur sur la ligne supérieure.
;   DOWN Déplace le curseur sur la ligne suivante.
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
;   CTRL_K Efface à partir du curseur jusqu'à la fin de la ligne    
;   CTRL_X  Supprime la ligne sur laquelle le curseur réside.
;   CTRL_Y  Insère une ligne vide avant celle où se trouve le curseur.
;   Manipulation des blocs:    
;   CTRL_B  Affiche le numéro du bloc, sa taille ainsi que numéro du bloc précédemment édité.    
;   CTRL_S  Sauvegarde de l'écran dans le bloc.
;   CTRL_N  Charge le bloc suivant pour édition.
;   CTRL_P  Charge le bloc précédent pour édition.     
;   CTRL_I  Édtion d'un bloc quelconque. Demande le numéro du bloc.
;   CTRL_Q  Quitte l'éditeur.

     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilisées par l'éditeur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: MAXCHAR  ( -- u )
;   Retourne le nombre maximum de caractères que peut contenir un écran pour être
;   sauvegardé dans un bloc. Cette valeur correspond à la grandeur d'un bloc sur
;   le périphérique de stockage.
; arguments:
;   aucun
; retourne:
;   u  Nombre maximum de caractères que peut contenir l'écran. Selon le standard ANS Forth c'est 1024 caractères.    
DEFCONST "MAXCHAR",7,,MAXCHAR,BLOCK_SIZE
    
    
; nom: TEXTEND  ( -- )
;   Positionne le curseur à la fin du texte. Balaie la mémoire tampon de l'écran à partir
;   de la fin et s'arrête après le premier caractère non blanc.     
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
;   Initialise les variable de l'éditeur BLKED. Appellé par BLKED au démarrage de ce dernier.
; arguments:
;   n+    Numéro du bloc à éditer
; retourne:
;   rien     
HEADLESS EDINIT,HWORD
    .word LIST,TEXTEND,EXIT
 
    
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
;   Sauvegarde la ligne d'écran n dans le tampon PAD.
; arguments:
;   n	numéro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word LNADR  ; s: src
    .word PAD,FETCH,LIT,CPL,OVER,CSTORE ; s: src dest 
    .word ONEPLUS,LIT,CPL,MOVE,EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'écran à partir du tampon PASTE
; arguments:
;   n	numéro de la ligne à restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word PAD,FETCH,COUNT,ROT ; s: src len n
    .word LNADR ; s: src len dest
    .word SWAP,MOVE
    .word EXIT
    
; nom: MSGLINE  ( c-addr u n -- )
;   Affiche un message à l'écran et attend une touche au clavier pour poursuivre
;   l'exécution. Le message doit tenir sur une seule ligne d'écran. Cette ligne
;   d'écran est sauvegardée et restaurée à la sortie de ce mot.
; arguments:
;   c-addr Adresse du premier caractère du message.
;   u  Longueur du message, limité à 63 caractères.
;   n  numéro de la ligne où doit-être affiché le message.
DEFWORD "MSGLINE",7,,MSGLINE ; ( c-addr u n -- )
    .word FALSE,CURENBL,GETCUR,TWOTOR,DUP,SAVELINE
    .word DUP,LIT,1,SWAP,ATXY,TRUE,BSLASHW,CLEARLN,NROT ; S: n c-addr u
    .word LIT,CPL-1,AND,TYPE,DUP,TRUE,INVLN
1:  .word KEYQ,ZBRANCH,1b-$
    .word FALSE,BSLASHW,RESTORELINE,TWORFROM,ATXY,TRUE,CURENBL,EXIT
  
; nom: NEXTBLOCK ( -- )
;   Sauvegarde l'écran actuel et charge le bloc suivant pour édition.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "NEXTBLOCK",9,,NEXTBLOCK
    .word SCR,FETCH,DUP,SCRTOBLK,DROP
    .word ONEPLUS,LIST,TEXTEND,EXIT
    
; nom: PREVBLOCK  ( -- )
;   Sauvegarde l'écran actuel et charge le bloc précédent pour édition.
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
;   Charge un nouveau bloc pour édition. Le numéro du bloc est fourni par l'utilisateur.    
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
;   l'éditeur doit mettre à jour l'écran de la console VT102 si le système est en REMOTE CONSOLE
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
 
; Efface du curseur jusqu'à la fin de la ligne    
HEADLESS DELEOL,HWORD
    .word FALSE,CURENBL
    .word LIT,CPL,GETX,DODO
1:  .word DOI,GETY,BL,CHRTOSCR,DOLOOP,1b-$
    .word TRUE,CURENBL,EXIT

; Insière une ligne au dessus de celle où se trouve le curseur.
; Sauf s'il y a du texte sur la dernière ligne de l'éran.    
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
   
; Supprime le caractère à la position du curseur.
HEADLESS DELCHR,HWORD
    .word DELETE
    .word EXIT
    
; Déplace le texte d'un position vers la droite
; pour laisser un espace à la position du curseur.
HEADLESS INSERTBL,HWORD
    .word FALSE,CURENBL
    .word CURADR,DUP,ONEPLUS,LIT,CPL,GETX,MINUS,MOVE
    .word BL,CURADR,CSTORE
    .word TRUE,CURENBL,EXIT
    
; Déplace le curseur à la fin du texte sur cette ligne.    
HEADLESS TOEOL,HWORD
    .word LIT,VK_END,EMIT
    .word EXIT
   
; Déplace le curseur au début de la ligne.    
HEADLESS TOSOL,HWORD
    .word LIT,VK_HOME,EMIT,EXIT
    
; Déplace le curseur 1 ligne vers le haut.    
HEADLESS LNUP,HWORD
    .word LIT,VK_UP,EMIT
    .word EXIT
    
;Déplace le curseur une ligne vers le bas.     
HEADLESS LNDN,HWORD
    .word LIT,VK_DOWN,EMIT
    .word EXIT

; Déplace le curseur au début de la ligne suivante
; sauf s'il est sur la dernière ligne.    
HEADLESS CRLF,HWORD
    .word GETY,LIT,LPS,EQUAL,TBRANCH,9f-$
    .word LCCR
9:  .word EXIT
    
; dépose le caractère dans la mémoire tampon vidéo.
; à la position actuelle du curseur.    
HEADLESS CHRTOBUF,HWORD ; ( c -- )
    .word CURADR,CSTORE,EXIT
    
; Affiche le caractère à la position de l'écran.
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

; efface le caractère avant le curseur.  
HEADLESS BACKCHAR,HWORD 
    .word GETX,ONEMINUS,ZBRANCH,9f-$,DELBACK
9:  .word EXIT

; Déplace le curseur 1 caractère à gauche.  
HEADLESS LEFT,HWORD
    .word LIT,VK_LEFT,EMIT
    .word EXIT

; Déplacele curseur 1 caractère à droite.    
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
    
; affiche le numéro du bloc et sa taille.    
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
;   Éditeur de bloc texte. Edite 1 bloc à la fois.
;   Le curseur peut-être déplacé à n'importe qu'elle position sur l'écran et 
;   son contenu modifié à volonté avant de le sauvegarder le bloc sur le
;   périphéirque de stockage actif. Ce bloc contenant du texte source peut-être
;   ultérieurement évalué par la commande LOAD ou THRU.  
; arguments:
;   n+   Le numéro du bloc à éditer.
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
    
    