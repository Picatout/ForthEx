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

; NOM: vt102.s
; DESCRIPTION: séquence de contrôle générées par l'émulateur de terminal minicom
;  en mode VT102.
;  La touche CTRL enfoncée simultanément avec une lettre génère un code entre
;  1 et 26 correspondant à l'ordre de la lettre dans l'alphabet. i.e. CTRL_A=1, CTRL_Z=26
;    
; DATE: 2017-04-12

SYSDICT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; caractères de contrôles
; reconnu par terminal VT102
; ref: http://vt100.net/docs/vt102-ug/appendixc.html    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  séquences de contrôles ^[
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; les 4 flèches
 
CUU: ; curseur vers le haut 
 .byte 27,91,65
CUD: ; curseur vers le bas
 .byte 27,91,66
CUF: ; curseur vers la droite
 .byte 27,91,67
CUB: ; curseur vers la gauche
 .byte 27,91,68
CCUU: ; CTRL curseur vers le haut
 .byte 27,91,49,59,53,65   
CCUD: ; CTRL curseur vers le bas
 .byte 27,91,49,59,53,66
CCUF: ; CTRL curseur vers la droite
 .byte 27,91,49,59,53,67
CCUB: ; CTRL curseur vers la gauche
 .byte 27,91,49,59,53,68

INSERT: 
 .byte 27,91,50,126
HOME:
 .byte 27,91,49,126    
VTDELETE:
 .byte 27,91,51,126
END:
 .byte 27,79,70
PGUP:
 .byte 27,91,53,126  
PGDN:
 .byte 27,91,54,126
CDELETE: ; CTRL_DELETE
 .byte 27,91,51,59,53,126
CHOME: ;CTRL_HOME
 .byte 27,91,51,59,53,72   
CEND: ; CTRL_END 
 .byte 27,91,51,59,53,70    
CPGUP: ; CTRL_PGUP
 .byte 27,91,53,59,53,126
CPGDN: ; CTRL_PGDN
 .byte 27,91,54,59,53,126
 
; caractères de contrôle de flux.
DEFCONST "XON",3,,XON,CTRL_Q 
DEFCONST "XOFF",4,,XOFF,CTRL_S
 
; Table utilisée par VT-FILTER
; pour la combinaison CTRL_x où x est une lettre
; VT102 envoie l'ordre de la lettre dans l'alphabet
; i.e.  CTRL_a -> 1,  CTRL_b -> 2,..., CTRL_z -> 26    
SYSDICT
CTRL_TABLE:
    .word 0,0,0,0
    .word 0,0,0,0
    .word -1,0,0,0  ; VK_BACK
    .word -1,-1,0,0  ; CTRL_L,VK_CR
    .word 0,0,0,0
    .word 0,0,-1,0  ; CTRL_V 
    .word -1,0,0,0  ; CTRL_X
    .word 0,0,0,0  
 
; nom: VT-FILTER ( u -- u false | c true )    
;   filtre  et retourne un caractère 'c' et 'vrai'
;   si u fait partie de l'ensemble reconnu.
;   sinon retourne 'u' et 'faux'   
;   accepte:
;      VK_CR, VK_BACK, CTRL_X, CTRL_V et {32-126}
; arguments:
;   u    code à vérifier
; retourne:
;   code refusé:    
;   u       même code
;   false   indicateur booléen 
;   code reconnu:
;   c       caractère reconnu.
;   true    indicateur booléen.
DEFWORD "VT-FILTER",9,,VTFILTER
    .word DUP,BL,LESS,TBRANCH,2f-$
    .word DUP,LIT,127,LESS,TBRANCH,1f-$
    .word FALSE,EXIT
1:  .word TRUE,EXIT
2:  .word DUP,CELLS 
    .word LIT,CTRL_TABLE,PLUS,FETCH,EXIT    

; nom: VT-KEY? ( -- 0|c)
;   vérifie s'il y a un caractère répondant aux 
;   critères du filtre disponible dans la file. 
;   S'il y a des caractères non valides les jettes.    
; arguments:
;   aucun
; retourne:
;   0   aucun caractère disponible
;   c   le premier caractère valide de la file.    
DEFWORD "VT-KEY?",7,,VTKEYQ
1: .word SGETCQ,DUP,ZBRANCH,9f-$
   .word DROP,SGETC,VTFILTER,TBRANCH,9f-$
   .word DROP,BRANCH,1b-$
9: .word EXIT
    
; nom: VT-KEY  ( -- c )
;   Attend la réception d'un caractère valide du clavier
; arguments:
;   aucun 
; retourne:
;   c   caractère filtré 
DEFWORD "VT-KEY",6,,VTKEY    
1:  .word VTKEYQ,QDUP
    .word ZBRANCH,1b-$
    .word EXIT 

; nom: VT-EMIT ( c -- )
;  transmet un caractère à la console.
; arguments:
;    c   caractère à transmettre
; retourne:
;    rien    
DEFWORD "VT-EMIT",7,,VTEMIT
    .word DUP,BL,LESS,TBRANCH,2f-$
    .word DUP,LIT,127,LESS,ZBRANCH,2f-$
    .word VTPUTC,EXIT
2:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,2f-$
    .word SPUTC,EXIT
2:  .word DUP,LIT,VK_CR,EQUAL,ZBRANCH,2f-$
    .word DROP,VTCRLF,EXIT
2:  .word DUP,LIT,CTRL_J,EQUAL,ZBRANCH,2f-$
    .word DROP,VTCRLF,EXIT
2:  .word DUP,LIT,VK_BACK,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDELBACK,EXIT
2:  .word DUP,LIT,CTRL_X,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDELLN,EXIT
2:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,2f-$
    .word SPUTC,EXIT
2:  .word DUP,LIT,VK_UP,EQUAL,ZBRANCH,2f-$
    .word DROP,VTUP,EXIT
2:  .word DUP,LIT,VK_DOWN,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDOWN,EXIT
2:  .word DUP,LIT,VK_LEFT,EQUAL,ZBRANCH,2f-$
    .word DROP,VTLEFT,EXIT
2:  .word DUP,LIT,VK_RIGHT,EQUAL,ZBRANCH,2f-$
    .word DROP,VTRIGHT,EXIT
2:  .word DUP,LIT,VK_HOME,EQUAL,ZBRANCH,2f-$
    .word DROP,VTHOME,EXIT
2:  .word DUP,LIT,VK_END,EQUAL,ZBRANCH,2f-$
    .word DROP,VTEND,EXIT
2:  .word DROP    
    .word EXIT

; nom: VT-TYPE  ( c-addr u -- )
;   Affiche sur  la remote console une chaîne comptée.    
; arguments:
;   c-addr     adresse du premier caractère
;   u          longueur de la chaîne.
; retourne:
; 
DEFWORD "VT-TYPE",7,,VTTYPE
    .word LIT,0, DODO
1:  .word DUP,ECFETCH,SPUTC,ONEPLUS,DOLOOP,1b-$
    .word DROP,EXIT
    
; nom: VT-SNDARG  ( n -- )
;   convertie un entier en chaîne avant de l'envoyé au port sériel.
; arguments:
;   n	entier à envoyer.
; retourne:  
;
DEFWORD "VT-SNDARG",9,,VTSNDARG
    .word LIT,0,STR,VTTYPE,EXIT
    
    
; nom: ESC[ ( -- )
;   Envoie la séquence ESC [  i.e. 27 91
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "ESC[",4,,ESCRBRAC
    .word CLIT,27,SPUTC,CLIT,'[',SPUTC,EXIT
    
; nom: VT-UP ( -- )
;   Envoie la séquence ANSI ESC[ A
; arguments:
;   aucun
; retourne:
;    
DEFWORD "VT-UP",5,,VTUP
    .word ESCRBRAC,LIT,'A',SPUTC,EXIT
    
; nom: VT-DOWN ( -- )
;   Envoie la séquence ANSI ESC[ B
; arguments:
;   aucun
; retourne:
;    
DEFWORD "VT-DOWN",7,,VTDOWN
    .word ESCRBRAC,LIT,'B',SPUTC,EXIT

; nom: VT-RIGHT ( -- )
;   Envoie la séquence ANSI ESC[ C
; arguments:
;   aucun
; retourne:
;    
DEFWORD "VT-RIGHT",8,,VTRIGHT
    .word ESCRBRAC,LIT,'C',SPUTC,EXIT
    
; nom: VT-LEFT ( -- )
;   Envoie la séquence ANSI ESC[ D
; arguments:
;   aucun
; retourne:
;    
DEFWORD "VT-LEFT",7,,VTLEFT
    .word ESCRBRAC,LIT,'D',SPUTC,EXIT
    
; nom: VT-HOME ( -- )
;   Envoie le curseur au début de la ligne.
; arguments:
;   aucun
; retourne:
;    
DEFWORD "VT-HOME",7,,VTHOME
    .word VTGETCUR,DUP,ZEROLT,ZBRANCH,2f-$,DROP,EXIT
2:  .word SWAP,DROP,LIT,1,SWAP
    .word VTATXY,EXIT
    
; nom: VT-END ( -- )
;   Envoie le curseur à la fin de la ligne
; arguments:
;   aucun
; retourne:
;    
DEFWORD "VT-END",6,,VTEND
    .word VTGETCUR,DUP,ZEROLT,ZBRANCH,2f-$,DROP,EXIT
2:  .word SWAP,DROP,LIT,CPL-1,SWAP
    .word VTATXY,EXIT
    
; nom: AT-XY ( u1 u2 -- )
;   Positionne le curseur de la console.
; arguments:
;   u1   colonne 
;   u2   ligne
;  retourne:
;    rien
DEFWORD "VT-AT-XY",8,,VTATXY
    .word ESCRBRAC,VTSNDARG
    .word LIT,';',SPUTC
    .word VTSNDARG
    .word LIT,'H',SPUTC
    .word EXIT

; nom: PAGE ( -- )
;  Efface l'écran du terminal
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-PAGE",7,,VTPAGE
    .word LIT,CTRL_L,SPUTC
    .word EXIT
    
  
;DEFWORD "VT-CRLF",7,,VTCRLF ; ( -- )
;    .word LIT,13,SPUTC
;    .word LIT,10,SPUTC
;    .word EXIT
   
DEFWORD "VT-DELBACK",10,,VTDELBACK ; ( -- )
    .word LIT,VK_BACK,SPUTC
    .word BL,SPUTC,LIT,VK_BACK,SPUTC
    .word EXIT

; code VT100 pour suprimer la ligne courante.    
DEFWORD "VT-DELLN",8,,VTDELLN ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC
    .word LIT,'2',SPUTC
    .word LIT,'K',SPUTC,LIT,13,SPUTC,EXIT

; nom: DSR  ( -- )
;  envoie la séquence de contrôle VT102 DSR: ESC [ 6 n 
;  rapporte la position du curseur.    
; arguments:
;   aucun
; retourne
;   rien    
DEFWORD "DSR",3,,DSR ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC,LIT,'6',SPUTC
    .word LIT,'n',SPUTC,EXIT

; nom: VT-GETP  ( c -- n f )
;   lecture d'une valeur numérique terminée par le caractère c    
; arguments:
;   c caractère délimitant la chaîne numérique.
; retourne:
;   n    nombre lue
;   f    indicateur booléen de succès.
DEFWORD "VT-GETP",7,,VTGETP
    .word TOR,LIT,0
1:  .word SGETC,DUP,RFETCH,EQUAL,TBRANCH,8f-$
    .word DUP,DECIMALQ,ZBRANCH,2f-$ ; si ce n'est pas un digit décimial erreur
    .word TOBASE10,BRANCH,1b-$
2:  .word DROP,RDROP,FALSE,EXIT    
8:  .word DROP,RDROP,TRUE,EXIT  
    
  
; nom: ESCSEQ?  ( -- f )
;   attend une séquence ESC [
; arguemnts:
;   aucun
; retourne:
;   f  indicateur booléen, FAUX si séquence reçu n'est pas ESC [  
DEFWORD "ESCSEQ?",7,,ESCSEQQ  ; ( -- f )
    .word SGETC,LIT,27,EQUAL,ZBRANCH,9b-$
    .word SGETC,LIT,'[',EQUAL,ZBRANCH,9b-$
    .word TRUE,EXIT
9:  .word FALSE,EXIT

  
; nom: LC-GETCUR  ( -- u1 u2 | -1 -1 )
;   retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1    colonne  {0..63}
;   u2    ligne    {0..23}
;   en cas d'erreur reoturne -1 -1  
DEFWORD "VT-GETCUR",9,,VTGETCUR ; ( -- u1 u2 | -1 -1 )
    .word DSR ; requête position du curseur
    ; attend la réponse
    .word ESCSEQQ,ZBRANCH,8f-$
    .word LIT,';',VTGETP,TBRANCH,2f-$
    .word DROP,BRANCH,8f-$
2:  .word LIT,'R',VTGETP,TBRANCH,2f-$
    .word TWODROP,BRANCH,8f-$
2:  .word SWAP,EXIT
8:  .word LIT,-1,DUP,EXIT    
   
; nom: VT-CRLF 
;   Envoie la séquence CRTL_M CTRL_J  i.e. ASCII 13,10
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-CRLF",7,,VTCRLF
   .word LIT,CTRL_M,SPUTC,LIT,CTRL_J,SPUTC,EXIT
   
; nom: VT-PUTC
;   Affiche un caractère au terminal et fait un renvoie à la ligne
;   si la position du curseur == CPL
; argument:
;   c   caractère à afficher.
; retourne:
;  
DEFWORD "VT-PUTC",7,,VTPUTC
   .word SPUTC,VTGETCUR,DROP,LIT,CPL,EQUAL,ZBRANCH,9f-$
   .word VTCRLF
9: .word EXIT
 