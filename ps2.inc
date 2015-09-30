;
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

;NOM: ps2.inc
;DESCRIPTION: constante reliée au clavier PS/2
;DATE: 2015-09-28

 ;codes claviers
.equ SC_BREAK, 0xF0
.equ SC_XTKEY, 0xE0
.equ L_SHIFT,  0x12
.equ R_SHIFT,  0x59
.equ L_CTRL,   0x14
.equ L_ALT,    0x11
.equ ENTER,    0x5A
    
;indicateurs booléins
.equ F_SHIFT, 0
.equ F_CTRL, 1
.equ F_ALT, 2
.equ F_CAPS, 3
.equ F_NUM,  4

.equ PS2_QUEUE_SIZE, 32
 