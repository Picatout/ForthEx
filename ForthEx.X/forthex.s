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

.section .link psv  address(0x7FFE)    
.global _sys_latest
_sys_latest:
.word 0b
    
    
    
.end

    

