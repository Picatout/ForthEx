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

; NOM: ed.s
; DESCRIPTION: un éditeur de texte simple utilisant la mémoire SPIRAM comme mémoire
;   pour le texte à éditer. L'éditeur doit-être fonctionnel aussi bien en remote
;   console qu'en local console.    
;   Les lignes de texte sont sauvegardées à longueur fixe de 64 caractères. Le
;   premier caractère indique la longueur de la ligne.    
;   Liste des commandes:
;    La touche ESC est utilisée comme accès aux commandes    
;	N  nouveau fichier
;	S  sauvegarde du fichier
;	L  chargement d'un fichier
;	X  quitter l'éditeur
    
; DATE: 2017-04-12
    
    
.include "vt102.s"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilisée par ED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCONST "MAXLN",5,,MAXLN,2048
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; variables utilisées par ED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; position 1ière SPIRAM
; affichée à l'écran    
DEFCONST "SCROFS",6,,SCROFS,0x8000
; nombres de lignes du fichier
DEFCONST "LNCNT",5,,LNCNT,0x8002
; fichier midifié
DEFCONST "ED_FLAGS",8,,ED_FLAGS, 0x8004     
; début de l'espace libre
DEFCONST "GAP",3,,GAP,0x8006     
; début fin du texte
DEFCONST "TAIL",4,,TAIL,0x8008
;nom du fichier 32 octets
DEFCONST "FNAME",5,,FNAME,0x800A
     
;;;;;;;;;;;;;;;;;;;;;;
; indicateurs booléens
;;;;;;;;;;;;;;;;;;;;;;
     
;indicateur écrasement
DEFCONST "F_OVER",6,,F_OVER,1
;indicateur fichier modifié
DEFCONST "F_MOD",5,,F_MOD,2
     

; initialisation de l'éditeur    
DEFWORD "EDINIT",6,,EDINIT ; ( -- )
     ; iniatise les variables à zéro
    .word SCROFS,LIT,0x2A,LIT,0,FILL
    .word MAXLN,TAIL,STORE
    .word CLS
    .word EXIT
 
; met à 0 un indicateur booléen dans ED_FLAGS
; arguments:
;   n  masque booléen    
DEFWORD "CLREFLAG",8,,CLRFLAG ; ( n -- )
    .word INVERT,ED_FLAGS,DUP,EFETCH,ROT,AND,SWAP,STORE,EXIT
    
; met à 1 un indicateur booléen dans ED_FLAGS
; arguments:
;   n masque booléen    
DEFWORD "SETEFLAG",8,,SETEFLAG ; ( n -- )
    .word ED_FLAGS,DUP,EFETCH,ROT,OR,SWAP,STORE,EXIT
    
   
; déplace une ligne de texte entre l'écran et 
; la SPIRAM
; arguments:
;   n1  indice ligne dans SPIRAM  {0..2047}  
;   n2  indice ligne écran {0..23}
;   xt  opération  ' RLOAD ou ' RSTORE
DEFWORD "MOVLN",5,,MOVLN ; (	n1 n2 xt -- )
    .word TOR
    ; converti no. ligne écran en adresse buffer
    .word LIT,CPL,DUP,TOR,STAR,LIT,_video_buffer,PLUS
    ; convertie no. ligne SPIRAM en adresse SPIRAM
    .word SWAP,RFETCH,MSTAR
    .word RFROM,NROT,RFROM,EXECUTE,EXIT
    
; arguments:
;   n1  indice ligne dans SPIRAM  {0..2047}  
;   n2  indice ligne écran {0..23}
DEFWORD "PRTLN",5,,PRTLN ; ( n1 n2 -- )
    .word LIT,RLOAD,MOVLN,EXIT
    
; arguments:
;   n1  indice ligne dans SPIRAM  {0..2047}  
;   n2  indice ligne écran {0..23}
DEFWORD "STORLN",6,,STORLN ; ( n1 n2 -- )
    .word LIT,RSTORE,MOVLN,EXIT
    
    
; déplace le curseur à la fin de la ligne
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD ">EOL",4,,TOEOL ; ( -- )    
    .word LIT,CPL,ONEMINUS,SETX
1:  .word SCRCHAR,QDUP,ZEROEQ,TBRANCH,2f-$
    .word BL,EQUAL,TBRANCH,2f-$
    .word GETX,LIT,CPL,ONEMINUS,EQUAL,TBRANCH,9f-$
    .word RIGHT,BRANCH, 9f-$
2:  .word GETX,ZEROEQ,TBRANCH,9f-$
    .word LEFT,BRANCH,1b-$
9:  .word EXIT
  
; déplace le curseur au début de la ligne
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD ">BOL",4,,TOBOL ; ( -- )
    .word LIT,0,SETX,EXIT
    
; efface la fin de la ligne à partir
; de la position du curseur
DEFWORD "CLREOL",6,,CLREOL ; ( -- )
    .word GETX,TOR,GETY,TOR
1:  .word GETX,LIT,CPL-1,EQUAL,TBRANCH,8f-$
    .word LIT,0,EMIT,BRANCH,1b-$
8:  .word LIT,0,EMIT,RFROM,RFROM,CURPOS
    .word EXIT

; déplace le curseur sur la ligne précédente.    
DEFWORD "LNUP",4,,LNUP ; ( -- )
    .word GAP,EFETCH,TBRANCH,1f-$,EXIT
1:  .word GETY,TBRANCH,2f-$
    .word SCRLDN,SCROFS,EFETCH,ONEMINUS,SCROFS,STORE
    .word SCROFS,EFETCH,LIT,0,PRTLN
2:  .word GAPTOTAIL
    .word GETY,QDUP,ZBRANCH,9f-$
    .word ONEMINUS,SETY
9:  .word EXIT

; déplace le curseur sur la ligne suivante.    
DEFWORD "LNDN",4,,LNDN ; ( -- )
    .word GAP,EFETCH,LNCNT,EFETCH,EQUAL,ZBRANCH,1f-$,EXIT
1:  .word     
    .word EXIT
    
; retour à la ligne suivante
DEFWORD "DOCRLF",6,,DOCRLF ; ( -- )
    .word FALSE,CURENBL
    .word GETY,DUP,SCROFS,EFETCH,PLUS,SWAP
    .word LIT,RSTORE,MOVLN
    .word GETY,LIT,LPS-1,EQUAL,ZBRANCH,9f-$
    .word SCROFS,EFETCH,ONEPLUS,SCROFS,STORE
9:  .word GAP,EFETCH,ONEPLUS,GAP,STORE
    .word CR,TRUE,CURENBL,EXIT
  
; test touche
; arguments:
;    c  caractère reçu du clavier
;    n  valeur de comparaison
;  retourne:
;    retourne c FALSE si c<>n sinon retourne TRUE
DEFWORD "KCASE",5,, KCASE ; ( c n -- c FALSE | TRUE )
    .word OVER,EQUAL,DUP,ZBRANCH,2f-$
    .word SWAP,DROP
2:  .word EXIT
  
;insère le caractère à la position du curseur
; argugments:
;    c  caractère à insérer
; retourne:
;   rien
DEFWORD "INSCHR",6,,INSCHR ; ( c -- )
    .word GETX,LIT,CPL-1,EQUAL,ZBRANCH,1f-$,DROP,EXIT
1:  .word ED_FLAGS,EFETCH,F_OVER,AND,ZBRANCH,2f-$
     ; mode écrasement
    .word PUTC,EXIT
    ; mode insertion
2:  .word FALSE,CURENBL
    .word GETX,DUP,ONEPLUS,LIT,CPL,OVER,MINUS ; S: c Xs Xd n       
    .word LIT,_video_buffer,GETY,LIT,CPL,STAR,PLUS
    .word DUP,TOR,ROT,PLUS,SWAP,ROT,RFROM,PLUS,NROT,MOVE
    .word PUTC,TRUE,CURENBL,EXIT

; efface le caractère la position du curseur
DEFWORD "DELCHR",6,,DELCHR ; ( -- )
    .word FALSE,CURENBL
    .word GETX,LIT,CPL-1,EQUAL,TBRANCH,9f-$
    .word GETX,DUP,ONEPLUS,LIT,CPL,OVER,MINUS,ROT,SWAP ; S: c Xs Xd n       
    .word LIT,_video_buffer,GETY,LIT,CPL,STAR,PLUS
    .word DUP,TOR,ROT,PLUS,SWAP,ROT,RFROM,PLUS,NROT,MOVE
9:  .word LIT,63,GETY,LIT,0,CHRTOSCR
    .word TRUE,CURENBL,EXIT
    
; attend une touche du clavier  
DEFWORD "EDKEY",5,,EDKEY ; ( -- c T | 0 )
1:   .word EKEY,QDUP,ZBRANCH,1b-$
     .word EXIT

;déplace la fente d'une ligne vers la fin
DEFWORD "GAPFWD",6,,GAPFWD ; ( -- )
     .word GAP,EFETCH,ONEPLUS,GAP,STORE
     .word TAIL,EFETCH,ONEMINUS,TAIL,STORE
     .word EXIT

;déplace la fente d'une ligne vers le début.     
DEFWORD "GAPBWD",6,,GAPBWD ; ( -- )
     .word GAP,EFETCH,ONEMINUS,GAP,STORE
     .word TAIL,EFETCH,ONEPLUS,TAIL,STORE
     .word EXIT
     
;déplace la première ligne avant TAIL vers GAP
DEFWORD "TAIL>GAP",8,,TAILTOGAP ; ( -- )
     .word TAIL,EFETCH,QDUP,ZBRANCH,9f-$
     .word DUP,MAXLN,EQUAL,ZBRANCH,2f-$,DROP,EXIT
2:   .word TIB,SWAP,LIT,CPL,SWAP,OVER,MSTAR,RLOAD
     .word TIB,GAP,EFETCH,ONEMINUS,LIT,CPL,SWAP,OVER,MSTAR,RSTORE
     .word GAPFWD
9:   .word EXIT

   
;déplace la dernière ligne avant GAP vers TAIL
DEFWORD "GAP>TAIL",8,,GAPTOTAIL ; ( -- )
     .word GAP,EFETCH,QDUP,ZBRANCH,9f-$
     .word ONEMINUS,TIB,SWAP,LIT,CPL,SWAP,OVER,MSTAR,RLOAD
     .word TIB,TAIL,EFETCH,ONEMINUS,LIT,CPL,SWAP,OVER,MSTAR,RSTORE
     .word GAPBWD
9:   .word EXIT
     
; sauvegarde la ligne écran dans la SPIRAM
DEFWORD "SAVELN",6,,SAVELN ; ( -- )
     .word GETY,DUP,SCROFS,EFETCH,PLUS,SWAP,STORLN
9:   .word EXIT

; met à jour l'affichage à partir de la mémoire SPIRAM
DEFWORD "REFRESH",7,,REFRESH ;  ( -- )
     .word LIT,LPS+1,LIT,0,DODO
2:   .word DOI,SCROFS,EFETCH,PLUS,DUP,GAP,EFETCH,LESS,ZBRANCH,4f-$
     ;avant le GAP
3:   .word DOI,LIT,RLOAD,MOVLN,BRANCH,8f-$
     ;après le GAP
4:   .word TAIL,EFETCH,GAP,EFETCH,MINUS,PLUS,BRANCH,3b-$      
8:   .word DOLOOP, 2b-$
     .word EXIT
     
; supprime la ligne sur laquelle se trouve le curseur
DEFWORD "DELLN",5,,DELLN ; ( -- )
     .word GETY,CLRLN,SAVELN,GAP,EFETCH,ONEMINUS,GAP,STORE,TAILTOGAP
     .word REFRESH 
     .word EXIT
     
; insère une ligne avant la ligne courante
DEFWORD "INSLN",5,,INSLN ; ( -- )

     .word EXIT
     
; sauvegarde du fichier
DEFWORD "FSAVE",5,,FSAVE ; ( -- )
     
     .word EXIT
     
; ouverture d'un fichier
DEFWORD "EDOPEN",6,,EDOPEN ; ( -- )
     
     .word EXIT
     
; mode commance initialisé par la touche ESC

DEFWORD "ESCAPED",7,,ESCAPED ; ( -- )
    .word EDKEY
    .word LIT,'q',KCASE,ZBRANCH,2f-$,CLS,ABORT
    
2:  .word DROP,EXIT
  
;éditeur de texte simple
DEFWORD "ED",2,,ED ; ( -- )
    .word EDINIT
1:  .word EDKEY,DUP,LIT,31,GREATER,ZBRANCH,2f-$
    .word DUP,LIT,127,LESS,ZBRANCH,4f-$
    .word INSCHR,BRANCH,1b-$
    ; c<32
2:  .word LIT,VK_CR,KCASE,ZBRANCH,2f-$,DOCRLF,BRANCH,1b-$
2:  .word LIT,VK_BACK,KCASE,ZBRANCH,2f-$,GETX,ZBRANCH,1b-$,BACKCHAR,BRANCH,1b-$
2:  .word LIT,CTRL_N,KCASE,ZBRANCH,2f-$,EDINIT,BRANCH,1b-$  
2:  .word LIT,CTRL_Q,KCASE,ZBRANCH,2f-$,CLS,ABORT
2:  .word LIT,CTRL_S,KCASE,ZBRANCH,2f-$,FSAVE,BRANCH,1b-$
2:  .word LIT,CTRL_O,KCASE,ZBRANCH,2f-$,FOPEN,BRANCH,1b-$  
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
    
    