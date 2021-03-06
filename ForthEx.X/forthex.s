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
;  des noms dans le dictionnaire sont assembl�s par inclusion dans celui-ci.
;  Ceci est requis pour que le lien entre les mots se fasse. L'�tiquette '0:'
;  doit-�tre r�serv�e pour la cr�ation de ce lien, voir macro 'HEADER'
;    
;****************************************************************************

.include "macros.inc" ; toutes les macros sont dans ce fichier
.include "hardware.s" ; initialisaton mat�rielle. 

; .sysinfo contient les donn�es d'initialisation des 
; variables syst�me.    
.section .vars_init psv  address(IMG_FLASH_ADDR-FLASH_ROW_SIZE)    
.global vars_count
vars_count: .word 16
csp_init: .word cstack
syslatest_init: .word 0b
latest_init: .word 0b    
tib_init: .word tib
pad_init: .word pad
paste_init: .word paste 
ticksource_init: .word tib 
cntsource_init: .word TIB_SIZE 
dp_init: .word DATA_BASE
base_init: .word 10
state_init: .word 0
toin_init: .word 0
hp_init: .word 0
syscons_init: .word LCCONS+CELL_SIZE
efree_init: .word EDS_BASE
efsize_init: .word HEAP_SIZE
 
.text
.global _code_end
_code_end: .space 4
    
.end

    

