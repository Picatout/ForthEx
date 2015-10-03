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
;
; Fichier: keyboard.inc
; Description: constantes pour les touches retournées par kbd_get
; Auteur: Jacques Deschênes
; Date: 2015-10-01
; Les touches non associées à un caractères ASCII
; on une valeur inférieure à 32 ou supérieure à 127
.ifndef KBD_INC
.equ KBD_INC, 1
    
;Nom			valeur	    Description
.equ VK_BACK,		8	    ;	Backspace
.equ VK_ESCAPE,		27	    ;	Esc
.equ VK_RETURN,		13	    ; touche Entrée    
.equ VK_CTRL,           128         ; touche contrôle droite ou gauche
.equ VK_SHIFT,          129         ; touche maj. droite ou gauche
.equ VK_ALT,            130         ; touche ALT gauche ou droite
.equ VK_CAPS,           131         ; touche fix Maj. 
.equ VK_TAB,		9           ; touche tabulation
.equ VK_DEL,            132         ; touche Suppr
.equ VK_INS,		133	    ; touche Inser
.equ VK_HOME,		134	    ; touche début fichier
.equ VK_END,		135	    ; touche fin de fichier
.equ VK_UP,		136	    ; flèche vers le haut
.equ VK_DOWN,		137	    ; flèvhe vers le bas
.equ VK_LEFT,		138	    ; flèche vers la gauche
.equ VK_RIGHT,		139	    ; flèche vers le bas
.equ VK_PGUP,		140	    ; page vers le haut
.equ VK_PGDN,		141	    ; page vers le bas
.equ VK_F1,		150	    ; fonction F1
.equ VK_F2,		151	    ; fonction F2
.equ VK_F3,		152	    ; fonction F3
.equ VK_F4,		153	    ; fonction F4
.equ VK_F5,		154	    ; fonction F5
.equ VK_F6,		155	    ; fonction F6
.equ VK_F7,		156	    ; fonction F7
.equ VK_F8,		157	    ; fonction F8
.equ VK_F9,		158	    ; fonction F9
.equ VK_F10,		159	    ; fonction F10
.equ VK_F11,		160	    ; fonction F11
.equ VK_F12,		161	    ; fonction F12    

.endif
    
    