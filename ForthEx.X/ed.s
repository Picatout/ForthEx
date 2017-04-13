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
DEFVAR "SCROFS",6,,SCROFS
; début fin du texte
DEFVAR "TAIL",4,,TAIL
; nombres de lignes du fichier
DEFVAR "LNCNT",5,,LNCNT
    

; initialisation de l'éditeur    
DEFWORD "EDINIT",6,,EDINIT ; ( -- )
    .word EXIT
    
    
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
  
    