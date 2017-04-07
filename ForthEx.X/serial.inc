;****************************************************************************
; Copyright 2015, Jacques Deschênes
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

;NOM: serial.inc
;Description:  communication port sériel RS232 via USART
;Date: 2015-10-07

; codes de contrôle ASCII    
.equ  A_XON,  17  ; minicom vt102 mode: CTRL-Q
.equ  A_XOFF, 19  ; minicom vt102 mode: CTRL-S
.equ  A_ESC,  27  ;     
.equ  A_STX , 2   ; minicom vt102 mode: CTRL-B
.equ  A_ETX , 3   ; minicom vt102 mode: CTRL-C
; séquence VT_100
.equ ESC_A, 'A'   ; ESC[A  cursor up
.equ ESC_B, 'B'   ; ESC[B  cursor down
.equ ESC_C, 'C'   ; ESC[C  cursor right
.equ ESC_D, 'D'   ; ESC[D  cursor left 
    
; pour la combinaison CTRL_x où x est une lettre
; minicom envoie l'ordre de la lettre dans l'alphabet
; i.e.  CTRL_a -> 1,  CTRL_b -> 2, CTRL_z -> 26    
    
.equ QUEUE_SIZE, 32
    