;****************************************************************************
; Copyright 2015,2016 Jacques Desch�nes
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

; constantes li�es au g�n�rateur de caract�res
.ifndef VIDEO_INC
.equ VIDEO_INC, 1

.if (VIDEO_STD==NTSC)
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
    
.equ CHAR_WIDTH,  (8)
.equ CHAR_HEIGHT, (8)
.equ FONT_SIZE, (128)
; caract�res pa ligne    
.equ CPL, (64)  ;>>> doit-�tre pair <<<<
; ligne par �cran    
.equ LPS, (24)  
;r�solution d'image
.equ XRES, (CHAR_WIDTH*CPL)
.equ YRES, (CHAR_HEIGHT*LPS)
 ; grandeur du tampon vid�o    
.equ VIDEO_BUFF_SIZE, (CPL*LPS)

 ; constantes pour curseur texte
.equ CURSOR_ACTIVE, 0  ; clignotement activ
.equ CURSOR_INV, 7     ; caract�re invers� par le curseur
.equ CURSOR_DELAY, 333
.equ INV_MASK,(1<<7) 
 
 
.macro cursor_incr_sema  ; verrouille acc�s � fcursor 
    inc.b cursor_sema
.endm
 
.macro cursor_decr_sema ; d�verrouille acc�s � fcursor
    dec.b cursor_sema
.endm

.macro cursor_sync  ; syncrhonise le bit CURSOR_INV
    btsc.b fcursor,#CURSOR_INV
    call toggle_char
    bclr.b fcursor,#CURSOR_INV
.endm
    
.endif
 