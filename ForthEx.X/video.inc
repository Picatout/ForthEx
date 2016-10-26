;****************************************************************************
; Copyright 2015,2016 Jacques Deschênes
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

; constantes liées au générateur de caractères
.ifndef VIDEO_INC
.equ VIDEO_INC, 1
    
.equ CHAR_WIDTH,  (8)
.equ CHAR_HEIGHT, (8)
.equ FONT_SIZE, (128)
; caractères pa ligne    
.equ CPL, (64)
; ligne par écran    
.equ LPS, (24)  
;résolution d'image
.equ XRES, (CHAR_WIDTH*CPL)
.equ YRES, (CHAR_HEIGHT*LPS)
 ; grandeur du tampon vidéo    
.equ TV_BUFFER_SIZE, (CPL*LPS)

.endif
 