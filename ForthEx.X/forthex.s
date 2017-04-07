;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschenes
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
;
;NOM: forthex
;DESCRIPTION: fichier principal du projet. Tous les autres fichiers qui ont
;  des noms dans le dictionnaire sont assemblés par inclusion dans celui-ci.
;  Ceci est requis pour que le lien entre les mots se fasse. L'étiquette '0:'
;  doit-être réservée pour la création de ce lien, voir macro 'HEADER'
;    
;****************************************************************************

.include "macros.inc" ; toutes les macros sont dans ce fichier
.include "hardware.s" ; initialisaton matérielle. 

; .sysinfo contient les données d'initialisation des 
; variables système.    
.section .vars_init psv  address(FLASH_DRIVE_BASE-FLASH_ROW_SIZE)    
.global vars_count
vars_count: .word 20
csp_init: .word cstack
syslatest_init: .word 0b
latest_init: .word 0b    
tib_init: .word tib
pad_init: .word pad
paste_init: .word paste 
ticksource_init: .word tib 
cntsource_init: .word TIB_SIZE 
dp0_init: .word DATA_BASE
dp_init: .word DATA_BASE
r0_init: .word rstack
s0_init: .word pstack    
base_init: .word 10
btdev_init: .word _MCUFLASH
btfn_init: .word FLASHTORAM
state_init: .word 0
toin_init: .word 0
hp_init: .word 0
stdin_init: .word KEY
stdout_init: .word PUTC
 
.text
.global _code_end
_code_end: .space 4
    
.end

    

