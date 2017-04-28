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
 
; nom: VT-EKEY? ( -- f )
;  vérifie s'il y a un caractère en attente
;   dans la file et retourne un indicateur booléen.
; arguments:
;   aucun
; retourne:
;   f   indicateur vrai|faux
DEFWORD "VT-EKEY?",8,,VTEKEYQ
 
    .word EXIT

; nom: VT-EKEY  ( -- u )
;  Attend jusqu'à réception d'un code du clavier
;  retourne le premier code reçu.
; arguments:
;  aucun
; retourne:
;   u   caractère non filtré.    
DEFWORD "VT-EKEY",7,,VTEKEY
    
    .word EXIT
    
; nom: VT-FILTER ( u -- u false | c true )    
;   filtre  et retourne un caractère 'c' et 'vrai'
;   si u fait partie de l'ensemble reconnu.
;   sinon retourne 'u' et 'faux'   
;   accèpte:
;      VK_CR, VK_BACK, CTRL_X, CTRL_V {32-126}
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
    .word DUP,LIT,31,GREATER,ZBRANCH,1f-$
    .word EXIT
1:  .word DUP,CLIT,27,EQUAL,ZBRANCH,6f-$
    .word DROP,SGETC,EXIT 
6:  .word LIT,CTRL_TABLE,PLUS,CFETCH,EXIT    

; pour la combinaison CTRL_x où x est une lettre
; minicom envoie l'ordre de la lettre dans l'alphabet
; i.e.  CTRL_a -> 1,  CTRL_b -> 2, CTRL_z -> 26    
CTRL_TABLE:
    .byte 32,32,32,32
    .byte 32,32,32,32
    .byte VK_BACK,32,32,32
    .byte VK_FF,VK_CR,32,32
    .byte 32,32,32,32
    .byte 32,32,VK_SYN,32
    .byte VK_SYN,32,32,32
    
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
    
    .word EXIT
    
; nom: VT-KEY  ( -- c )
;   Attend la réception d'un caractère valide du clavier
; arguments:
;   aucun 
; retourne:
;   c   caractère filtré 
DEFWORD "VT-KEY",6,,VTKEY    
    
    .word EXIT

; nom: VT-EMIT ( c -- )
;  transmet un caractère à la console.
; arguments:
;    c   caractère à transmettre
; retourne:
;    rien    
DEFWORD "VT-EMIT",7,,VTEMIT
    
    .word EXIT

; nom: VT-EMIT? ( -- f )
;  vérifie si le terminal est prêt à recevoir
; arguments:
;    aucun
; retourne:
;    f      indicateur booléen vrai si terminal prêt à recevoir.
DEFWORD "VT-EMIT?",8,,VTEMITQ
    .word SREADYQ
    .word EXIT
    
; nom: AT-XY ( u1 u2 -- )
;   Positionne le curseur de la console.
; arguments:
;   u1   colonne 
;   u2   ligne
;  retourne:
;    rien
DEFWORD "VT-AT-XY",8,,VTATXY
    
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
    
  
DEFWORD "VT-CRLF",7,,VTCRLF ; ( -- )
    .word LIT,13,SPUTC
    .word LIT,10,SPUTC
    .word EXIT
   
DEFWORD "VT-DELBACK",10,,VTDELBACK ; ( -- )
    .word LIT,VK_BACK,SPUTC
    .word BL,SPUTC,LIT,VK_BACK,SPUTC
    .word EXIT

; code VT100 pour suprimer la ligne courante.    
DEFWORD "VT-DELLN",8,,VTDELLN ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC
    .word LIT,'2',SPUTC
    .word LIT,'K',SPUTC,LIT,13,SPUTC,EXIT

DEFWORD "VT-CURSOR?",10,,VTCURSORQ ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC,LIT,'6',SPUTC
    .word LIT,'n',SPUTC,EXIT
    
; demande la position du curseur
; sortie:
;   v position verticale
;   H position horizontale    
DEFWORD "VT-GETYX",8,,VTGETYX ; ( -- v h )
    .word VTCURSORQ
1:  .word SGETC,LIT,27,EQUAL,ZBRANCH,1b-$
    .word SGETC,DROP ; [
    .word SGETC,LIT,'0',MINUS
    .word SGETC,DUP,LIT,';',EQUAL,TBRANCH,2f-$
    .word LIT,'0',MINUS,SWAP,LIT,10,STAR,PLUS,SGETC
2:  .word DROP,SGETC,LIT,'0',MINUS
    .word SGETC,DUP,LIT,'R',EQUAL,TBRANCH,9f-$
    .word LIT,'0',MINUS,SWAP,LIT,10,STAR,PLUS,SGETC
9:  .word DROP,EXIT
    
    