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
;   bloc peut-être évaluer avec la commande LOAD.     
;   En principe Lorsqu'on écris du code source les lignes ne sont pas pleines.
;   Parfois on laisse même des lignes vides pour rendre le texte plus facile à lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronquées après le dernier caractère
;   et un carctère de fin de ligne est ajouté. Il y a 24 lignes sur un écran donc
;   si la longueur moyenne des lignes est inférieure à (BLOCK_SIZE-24)/24 l'écran peut
;   être sauvegardé dans un bloc. L'éditeur calcule constamment le nombre de caractères
;   dans un écran en édition et rapporte une alerte si ce nombre dépasse BLOCK_SIZE.     
; FONCTIONNEMENT:
;   Le curseur peut-être déplacé n'importe où sur l'écran et le texte modifié.
; COMMANDES:
;   CTRL_S  Sauvegarde de l'écran dans le bloc.
;   CTRL_N  Efface l'écran pour éditer le bloc suivant.
;   CTRL_P  Reviens au bloc précédemment édité.     
;   CTRL_I  Édtion d'un bloc quelconque. Demande le numéro du bloc.
;   CTRL_Q  Quitte l'éditeur.

     
.section blkedit.bss bss 
_blknbr: .space 2
_blkprev: .space 2 
_edsize: .space 2
 
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
;   u  Nombre maximum de caractères que peut contenir l'écran.     
DEFCONST "MAXCHAR",7,,MAXCHAR,BLOCK_SIZE
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; variables utilisées par ED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom:  BLK-NBR   ( -- a-addr )
;   Variable qui contient le numéro du bloc en cours d'édition.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.
DEFCODE "BLK-NBR",7,,BLKNBR 
     DPUSH
     mov _blknbr,T
     NEXT
     
; nom: BLK-PREV ( -- a-addr )
;   Variable qui contient le numéro du bloc précédemment en édition.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.
DEFCODE "BLK-PREV",8,,BLKPREV
     DPUSH
     mov _blkprev,T
     NEXT
     
; nom: ED-SIZE ( -- a-addr )
;   Variable qui contient le nombres de caractères dans l'écran.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.
DEFCODE "ED-SIZE",7,,EDSIZE
     DPUSH
     mov _edsize,T
     NEXT
     
     
;;;;;;;;;;;;;;;;;;;;;;
; indicateurs booléens
;;;;;;;;;;;;;;;;;;;;;;
     
; nom: EDINIT  ( -- )
;   Initialise les variable de l'éditeur BLKED. Appellé par BLKED au démarrage de ce dernier.
; arguments:
;   aucun
; retourne:
;   rien     
DEFWORD "EDINIT",6,,EDINIT ; ( -- )
    .word LIT,0,DUP,BLKNBR,STORE,BLKPREV,STORE
    .word LCPAGE,VTPAGE,EXIT
 
    
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
;   Sauvegarde la ligne d'écran n dans le tampon CLIP.
; arguments:
;   n	numéro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word LIT,CPL,STAR,SCRBUF,PLUS  ; s: c-addr1
    .word LIT,CPL,PASTE,FETCH,DUP,NROT,CSTORE ; s: c-addr1 c-addr2 
    .word LIT,CPL,MOVE,EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'écran à partir du tampon PASTE
; arguments:
;   n	numéro de la ligne à restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word GETCUR,ROT,DUP,LIT,0,ATXY
    .word PASTE,FETCH,COUNT,TYPE
    .word PASTE,FETCH,ONEPLUS
   
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
    .word DUP,SAVELINE
    .word DUP,LIT,0,SWAP,ATXY,CLEARLN,NROT ; S: n c-addr u
    .word LIT,CPL-1,AND,TYPE
1:  .word KEYQ,ZBRANCH,1b-$
    .word RESTORELINE,EXIT
  
; nom: NEXTBLOCK ( -- )
;   Sauvegarde l'écran actuel et charge le bloc suivant pour édition.
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
;   Sauvegarde l'écran actuel et charge le bloc précédent pour édition.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "PREVBLOCK",9,,PREVBLOCK
    .word BLKNBR,FETCH,SCRTOBLK,DROP
    .word BLKPREV,FETCH,DUP,BLKNBR,STORE
    .word LIST,EXIT


; nom: OPENBLOCK  ( -- )
;   Charge un nouveau bloc pour édition. Le numéro du bloc est fourni par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "OPENBLOCK",9,,OPENBLOCK
    
    .word EXIT
    
    
; nom: VT-UPDATE  ( -- )
;   l'éditeur doit mettre à jour l'écran de la console VT102 si le système est en REMOTE CONSOLE
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
    
HEADLESS LNDN,HWORD
    .word EXIT
    
HEADLESS INSCHR,HWORD
    .word EXIT

HEADLESS  CRLF,HWORD  
    .word EXIT

HEADLESS EDKEY,HWORD
    .word EXIT

HEADLESS BACKCHAR,HWORD    
    .word EXIT

HEADLESS LEFT,HWORD
    .word EXIT

HEADLESS RIGHT,HWORD
    .word EXIT

    
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
    
    