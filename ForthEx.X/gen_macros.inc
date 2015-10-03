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

;Fichier: gen_macro.inc
;Description:  d�finition de macros d'usage g�n�ral
;Date: 2015-10-02
.ifndef GEN_MACCRO
.equ GEN_MACRO, 1

.macro set_psv table, reg
    mov #psvpage(\table), \reg
    mov \reg, PSVPAG
    mov #psvoffset(\table), \reg
.endm

.endif
