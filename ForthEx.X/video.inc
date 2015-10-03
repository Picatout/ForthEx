;****************************************************************************
; Copyright 2015, Jacques Desch�nes
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
    
.equ CHAR_WIDTH,  (8)
.equ CHAR_HEIGHT, (8)
.equ FONT_SIZE, (128)
; caract�res pa ligne    
.equ CPL, (50)
; ligne par �cran    
.equ LPS, (24)  
;r�solution d'image
.equ XRES, (CHAR_WIDTH*CPL)
.equ YRES, (CHAR_HEIGHT*LPS)
 ; grandeur du tampon vid�o    
.equ TV_BUFFER, (CPL*LPS)

.endif
 