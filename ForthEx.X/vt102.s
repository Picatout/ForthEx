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
    
NUL: .byte 0
ETX: .byte 3  ; end of text
EOT: .byte 4  ; end of transmission
ENQ: .byte 5  ; enquire
BEL: .byte 7  ; bell
BS:  .byte 8  ; back space
HT:  .byte 9  ; horizontal tabulation
LF:  .byte 10 ; line feed
VT:  .byte 11 ; vertical tab ( même effet que LF )
FF:  .byte 12 ; form feed (efface écran)
.ifnotdef CR
CR:  .byte 13 ; carriage return (renvoie le curseur au début de la ligne).
.endif  
SO:  .byte 14 ; shift out ( sélection jeux de caractère G1).
SI:  .byte 15 ; shift in (sélection jeux de caractère G0  ).
DC1: .byte 17 ; device control 1 (XON).
DC3: .byte 19 ; device control 3 (XOFF).
CAN: .byte 24 ; cancel  
SUB: .byte 26 ; substitute  (traité comme CAN).
ESC: .byte 27 ; introduit une séquence de contrôle. 
DEL: .byte 127 ; delete 

 
    
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
 
 
