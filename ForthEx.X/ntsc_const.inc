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

; constantes génération signal NTSC
; REF: http://www.ntsc-tv.com/
.ifndef NTSC_CONST
.equ NTSC_CONST, 1
    
.equ HFREQ, 15748 ; fréquence horizontale pour information seulement
.equ HLINE, 1015 ; PR2= période ligne horizontale
.equ HSYNC, 74  ; OC1R=47e-6*FCY-1 sync pulse horizontal
.equ HALFLINE, 507 ; période demi-ligne horizontale (VSYNC)
.equ SERATION, (HSYNC/2) ;durée pulse dans VSYNC
.equ TOPLINE, 40  ; première ligne visible
.equ ELPFRM,  271  ; nombre de lignes par frame pair
.equ OLPFRM,  272  ; nombre de lignes par frame impair
.equ VIDEO_DLY, 50 ; délais déclenche interruption video=HSYNC+VIDEO_DLY

.endif


