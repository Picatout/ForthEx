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
; mots forth lié au clavier

.include "keyboard.inc"

    
;;;;;;;;;;;;;;;;;;;;;;
; définitions Forth
;;;;;;;;;;;;;;;;;;;;;;    
    
DEFCODE "?KEY",4,,QKEY,DOT  ; ( -- 0 | T c )
    call kbd_get
    DPUSH
    mov W0, T
    cp0 W0
    bra eq, 1f
    DPUSH
    setm T
1:    
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;
; attend une touche
; du clavier
;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "KEY",3,,KEY,QKEY ; ( -- c)
0:
    call kbd_get
    cp0 W0
    bra z, 0b
    DPUSH
    mov W0, T
    NEXT
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; envoie d'un octet au clavier
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "KBD_CMD",7,,KBD_CMD,KEY ; ( c -- )
    mov T, W0
    call ps2_send
    inc2 T,T
    NEXT
    


