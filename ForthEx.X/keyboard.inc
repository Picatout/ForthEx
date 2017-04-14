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

; touches qui ne corespondes pas un symbole ASCII    
;Nom			valeur	    Description
.equ VK_NUL,    0
.equ VK_SOH,    1           
.equ CTRL_A,	1    
.equ VK_STX,    2
.equ CTRL_B,	2    
.equ VK_ETX,    3
.equ CTRL_C,	3    
.equ VK_EOT,    4
.equ CTRL_D,	4
.equ VK_ENQ,	5
.equ CTRL_E,	5    
.equ VK_ACK,    6
.equ CTRL_F,	6    
.equ VK_BEL,	7
.equ CTRL_G,	7
.equ VK_BACK,	8
.equ CTRL_H,	8
.equ VK_TAB,	9
.equ CTRL_I,	9
.equ VK_LF,	10
.equ CTRL_J,	10
.equ VK_VT,	11
.equ CTRL_K,	11
.equ VK_FF,     12
.equ CTRL_L,	12
.equ VK_CR,	13
.equ CTRL_M,	13
.equ VK_SO,	14
.equ CTRL_N,	14
.equ VK_SI,	15
.equ CTRL_O,	15
.equ VK_DLE,	16
.equ CTRL_P    ,16
.equ VK_DC1,	17
.equ CTRL_Q,	17
.equ VK_DC2,	18
.equ CTRL_R    ,18
.equ VK_DC3,    19
.equ CTRL_S,    19
.equ CTRL_BS,	19
.equ VK_DC4,	20
.equ CTRL_T,	20
.equ VK_NAK,	21
.equ CTRL_U  ,  21
.equ VK_SYN,    22
.equ CTRL_V    ,22
.equ VK_ETB,	23
.equ CTRL_W,	23
.equ VK_CANCEL, 24
.equ CTRL_X,	24
.equ VK_EM,	25
.equ CTRL_Y,	25
.equ VK_SUB,	26
.equ CTRL_Z    ,26
.equ VK_ESCAPE,	27	    ; ESC
.equ VK_SPACE,	32          ; touche espace    
.equ VK_DELETE,	127         
.equ VK_F1,	128
.equ VK_F2,	129
.equ VK_F3,	130
.equ VK_F4,	131
.equ VK_F5,	132
.equ VK_F6,	133
.equ VK_F7,	134
.equ VK_F8,	135
.equ VK_F9,	136
.equ VK_F10,	138
.equ VK_F11,	139
.equ VK_F12,	140
.equ VK_UP,	141
.equ VK_DOWN,	142
.equ VK_LEFT,	143
.equ VK_RIGHT,	144
.equ VK_HOME,	145
.equ VK_END,	146
.equ VK_PGUP,	147
.equ VK_PGDN,	148
.equ VK_INSERT,	149
.equ VK_APPS,	151
.equ VK_PRN,	152
.equ VK_PAUSE,	153
.equ VK_NLOCK,  154 ; numlock
.equ VK_CLOCK,	155 ; capslock
.equ VK_LSHIFT,	156
.equ VK_LCTRL,	157
.equ VK_LALT,	158
.equ VK_RSHIFT,	159
.equ VK_LGUI,	160
.equ VK_RCTRL,	161
.equ VK_RGUI,	162
.equ VK_RALT,	163
.equ VK_SCROLL,	164
.equ VK_NUM,	165 
.equ VK_CAPS,	168
;<SHIFT>-<KEY> 
.equ VK_SUP,	169
.equ VK_SDOWN,	170
.equ VK_SLEFT,	171
.equ VK_SRIGHT,	172
.equ VK_SHOME,	173
.equ VK_SEND,	174
.equ VK_SPGUP,	175
.equ VK_SPGDN,	176
;<CTRL>-<KEY>
.equ VK_CUP,	177
.equ VK_CDOWN,	178	
.equ VK_CLEFT,	179
.equ VK_CRIGHT,	180
.equ VK_CHOME,	181
.equ VK_CEND,	182
.equ VK_CPGUP,	183
.equ VK_CPGDN,	184

.endif
    
    