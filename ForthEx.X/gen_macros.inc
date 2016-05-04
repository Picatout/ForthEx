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

;Fichier: gen_macro.inc
;Description:  définition de macros d'usage général
;Date: 2015-10-02
.ifndef GEN_MACCRO
.equ GEN_MACRO, 1

; initialisation table en flash
; pour lecture
.macro set_eds_table table, reg
    mov #edspage(\table), \reg
    mov \reg, DSRPAG
    mov #edsoffset(\table), \reg
.endm

.endif

