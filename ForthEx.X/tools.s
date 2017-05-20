;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschênes
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
; NOM: tools.s
; DATE: 2017-05-18
; DESCRIPTION: Outils d'aide au débogage.
;    Retiré du fichier core.s pour les mettres ici.
    
; nom: ?DSP  ( -- )    
;   Outil de débogage.    
;   Vérifie si la variable DSP est dans les limites, réinitialise l'ordinateur
;   en cas d'erreur et affiche un message.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "?DSP",4,,QDSP
    mov #pstack,W0
    cp DSP,W0
    bra ltu,_underflow
    add #DSTK_SIZE-CELL_SIZE,W0
    cp W0,DSP
    bra ltu,_overflow
    NEXT
_underflow:
    mov #DSTACK_UNDERFLOW,W0
    mov WREG,fwarm
    reset
_overflow:
    mov #DSTACK_OVERFLOW,W0
    mov WREG,fwarm
    reset
    
; nom: .S   ( i*x -- i*x )    
;   Outil de débogage.    
;   Affiche le contenu de la pile des arguments sans en modifier le contenu.
;   La valeur la plus à droit est le sommet de la pile.    
;   FORMAT:  < n >  X1 X2 X3 ... Xn=T
;   n est le nombre d'éléments
;   Xn  valeurs sur la pile.  
; arguments:
;   i*x   Liste des valeurs sur la pile des arguments.
; retourne:
;   i*x   La pile est dans son état initial.    
DEFWORD ".S",2,,DOTS  ; ( -- )
    .word DEPTH,CLIT,'<',EMIT,DUP,DOT,CLIT,'>',EMIT,SPACE
1:  .word QDUP,ZBRANCH,2f-$,DUP,PICK,DOT,ONEMINUS
    .word BRANCH,1b-$  
2:  .word EXIT

; nom: .RTN    ( R: i*x -- i*x )  
;   Outil de débogage.  
;   Affiche le contenu de la pile des retours.
;   La valeur la plus à droite est le sommet de la pile.  
;   FORMAT:  R:  X1 X2 ... XN  
; arguments:
;   R: i*x  Liste des valeurs sur la pile des retours.
; retourne:
;   R: i*x  Le contenu de la pile n'est pas modifié.  
DEFWORD ".RTN",4,,DOTRTN ; ( -- )
    .word BASE, FETCH,HEX
    .word CLIT,'R',EMIT,CLIT,':',EMIT
    .word RPFETCH,R0,DODO
1:  .word DOI,FETCH,DOT,LIT,2,DOPLOOP,1b-$
    .word BASE,STORE,EXIT
 
; nom: DUMP   ( c-addr n+ -- )    
;   Outil de débogage.
;   Affiche en hexadécimal le contenu d'un région mémoire.
; arguments:   
;   c-addr  adresse du premier octet à afficher.
;   n nombre d'octets à afficher.
; retourne:
;   rien    
DEFWORD "DUMP",4,,DUMP ; ( addr +n -- )
    .word QDUP,TBRANCH,3f-$,EXIT
3:  .word BASE,FETCH,TOR,HEX
    .word SWAP,LIT,0xFFFE,AND,SWAP,LIT,0,DODO
1:  .word DOI,LIT,15,AND,TBRANCH,2f-$
    .word CR,DUP,LIT,4,UDOTR,SPACE
2:  .word DUP,ECFETCH,LIT,3,UDOTR,LIT,1,PLUS
    .word DOLOOP,1b-$,DROP
    .word RFROM,BASE,STORE,EXIT

; nom: DEBUG  ( f -- )    
;   Outil de débogage.    
;   Active/désactive les breaks points.
; arguments:
;   f   Indicateur Booléen,VRAI active les break points.
; retourne: 
;   rien    
DEFWORD "DEBUG",5,,DEBUG ; ( f -- )
    .word DBGEN,STORE    
    .word EXIT

; nom: BREAK ( i*x n -- i*x )     
;   Outil de débogage.    
;   Interrompt le programme en cours d'exécution et
;   entre en mode inter-actif. L'utilisateur peut examiner
;   les piles, des variables ou faire un DUMP.    
;   L'application est redémarrée par le mot RESUME.
; arguments:
;   n    Identifie le break point par une valeur entière qui est affiché sur la console inter-active.    
; retourne:
;   rien    
DEFWORD "BREAK",5,,BREAK ; ( ix n -- ix )
    .word DBGEN,FETCH,TBRANCH,1f-$
    .word DROP,EXIT
1:  .word RPFETCH,RPBREAK,STORE
    .word CR,DOTSTR
    .byte  13
    .ascii "break point: "
    .align 2
    .word DOT,CR,DOTS,CR,REPL
    .word EXIT

; nom: RESUME  ( -- )
;   Outil de débogage.    
;   Redémarre l'exécution du programme au point d'interruption par le mot BREAK.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "RESUME",6,,RESUME ; ( -- )
    .word DBGEN,FETCH,ZBRANCH,9f-$
    .word RPBREAK,FETCH,QDUP,ZBRANCH,9f-$
    .word RPSTORE,LIT,0,RPBREAK,STORE
9:  .word EXIT
    
; affice le code source d'un mot qui est
; dans le dictionnaire
;DEFWORD "SEE",3,F_IMMED,SEE ; ( <ccc> -- )    
;    .word BL,WORD,FIND,TBRANCH,1f-$
;    .word SPACE,LIT,'?',EMIT,DROP,BRANCH,3f-$
;1:  .word DUP,FETCH,LIT,ENTER,EQUAL,TBRANCH,2f-$
;    .word DROP,DOTSTR
;    .byte 9
;    .ascii "code word"
;    .align 2
;    .word BRANCH,3f-$
;2:  .word SEELIST
;3:  .word EXIT    

; imprime la liste des mots qui construite une définition
; de HAUT-NIVEAU  
;DEFWORD "SEELIST",7,F_IMMED,SEELIST ; ( cfa -- )
;    .word BASE,FETCH,TOR,HEX,CR
;    .word LIT,2,PLUS ; première adresse du mot 
;1:  .word DUP,FETCH,DUP,CFATONFA,QDUP,ZBRANCH,4f-$
;    .word COUNT,LENMASK,AND
;    .word DUP,GETX,PLUS,LIT,CPL,LESS,TBRANCH,2f-$,CR 
;2:  .word TYPE
;3:  .word LIT,',',EMIT,FETCH,LIT,code_EXIT,EQUAL,TBRANCH,6f-$
;    .word LIT,2,PLUS,BRANCH,1b-$
;4:  .word UDOT,DVP,BRANCH,3b-$
;6:  .word DROP,RFROM,BASE,STORE,EXIT
  
    
