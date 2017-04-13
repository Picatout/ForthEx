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
; DESCRIPTION: un �diteur de texte simple utilisant la m�moire SPIRAM comme m�moire
;   pour le texte � �diter. L'�diteur doit-�tre fonctionnel aussi bien en remote
;   console qu'en local console.    
;   Les lignes de texte sont sauvegard�es � longueur fixe de 64 caract�res. Le
;   premier caract�re indique la longueur de la ligne.    
;   Liste des commandes:
;    La touche ESC est utilis�e comme acc�s aux commandes    
;	N  nouveau fichier
;	S  sauvegarde du fichier
;	L  chargement d'un fichier
;	X  quitter l'�diteur
    
; DATE: 2017-04-12
    
    
.include "vt102.s"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilis�e par ED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCONST "MAXLN",5,,MAXLN,2048
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; variables utilis�es par ED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; position 1i�re SPIRAM
; affich�e � l'�cran    
DEFVAR "SCROFS",6,,SCROFS
; d�but fin du texte
DEFVAR "TAIL",4,,TAIL
; nombres de lignes du fichier
DEFVAR "LNCNT",5,,LNCNT
    

; initialisation de l'�diteur    
DEFWORD "EDINIT",6,,EDINIT ; ( -- )
    .word EXIT
    
    
; d�place une ligne de texte entre l'�cran et 
; la SPIRAM
; arguments:
;   n1  indice ligne dans SPIRAM  {0..2047}  
;   n2  indice ligne �cran {0..23}
;   xt  op�ration  ' RLOAD ou ' RSTORE
DEFWORD "MOVLN",5,,MOVLN ; (	n1 n2 xt -- )
    .word TOR
    ; converti no. ligne �cran en adresse buffer
    .word LIT,CPL,DUP,TOR,STAR,LIT,_video_buffer,PLUS
    ; convertie no. ligne SPIRAM en adresse SPIRAM
    .word SWAP,RFETCH,MSTAR
    .word RFROM,NROT,RFROM,EXECUTE,EXIT
    
; d�place le curseur � la fin de la ligne
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
  
; d�place le curseur au d�but de la ligne
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD ">BOL",4,,TOBOL ; ( -- )
    .word LIT,0,SETX,EXIT
    
; efface la fin de la ligne � partir
; de la position du curseur
DEFWORD "CLREOL",6,,CLREOL ; ( -- )
    .word GETX,TOR,GETY,TOR
1:  .word GETX,LIT,CPL-1,EQUAL,TBRANCH,8f-$
    .word LIT,0,EMIT,BRANCH,1b-$
8:  .word LIT,0,EMIT,RFROM,RFROM,CURPOS
    .word EXIT
  
    