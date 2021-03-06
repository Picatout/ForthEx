;****************************************************************************
; Copyright 2015, 2016 Jacques Desch�nes
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

; constante pour g�n�ration signal vid�o standard PAL
; REF: http://martin.hinner.info/vga/pal.html
.ifndef PAL_CONST

.equ PAL_CONST, 1
    
.equ HFREQ, 15625 ; fr�quence horizontale pour information seulement
.equ HLINE, (FCY/HFREQ-1) ; PR2= p�riode ligne horizontale
.equ HSYNC, (47*FCY_MHZ/10-1)  ; OC1R=47e-6*FCY-1 sync pulse horizontal
.equ HALFLINE, (HLINE/2) ; p�riode demi-ligne horizontale (VSYNC)
.equ SERATION, (HSYNC/2) ;dur�e pulse dans VSYNC
.equ TOPLINE, 70  ; premi�re ligne visible
.equ ELPFRM,  321  ; nombre de lignes par frame pair
.equ OLPFRM,  322   ; nombre de lignes par frame impair
.equ VIDEO_DLY, (2*HSYNC+300) ; d�lais d�clenche interruption video=HSYNC+VIDEO_DLY
    
.endif
