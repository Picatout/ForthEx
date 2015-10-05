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
;NOM: core.inc
;Description: définition de base pour le système Forth
;Date: 2015-10-03
    
; utilisation des registres    
.equ RSP, W15 ; pile retours
.equ DSP, W14 ; pile arguments
.equ R, W13 ; sommet pile retour
.equ T, W12 ; sommet pile arguments
.equ W, W11 ; pointeur paramètres
.equ X, W10 ; pointeur d'adresse
.equ UP, W9  ; pointeur variables utilisateur
.equ IP, W8 ; pointeur d'instruction 
.equ I, W7  ; compteur de boucle    
    
.equ CELL_SIZE, 2
.equ DSTK_SIZE, 64
.equ RSTK_SIZE, 128

;offset variables utilisateurs
.equ RBASE, 0  ; adresse début pile retours
.equ PBASE, 2  ; adresse début pile paramètres
.equ BASE, 4   ; base numérique
.equ HERE, 6   ; valeur du pointeur HERE
    
    
;;;;;;;;;;;;    
; macros
;;;;;;;;;;;;
.macro DPUSH  
    mov T, [++DSP]
.endm
    
.macro DPOP
    mov [DSP--], T
.endm
    
.macro RPUSH
    push R
.endm
    
.macro RPOP
    pop R
.endm
    
.macro DSWAP
    mov T, W0
    DPOP
    mov W0, [++DSP]
.endm
    
    