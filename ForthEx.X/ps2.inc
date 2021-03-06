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

;NOM: ps2.inc
;DESCRIPTION: constante reli�e au clavier PS/2
;DATE: 2015-09-28
;REF: http://www.computer-engineering.org/ps2keyboard/scancodes2.html 
; utilise scancode set 2
    
.ifndef PS2_INC
.equ PS2_INC, 1

;commandes clavier
.equ KCMD_RESET, 0xFF ; reset keybaord
.equ KCMD_RESEND, 0xFE ; resend last code
.equ KCMD_LED, 0xED    ; set keyboard leds
    
.equ SC_BATOK, 0xAA ; basic assurance test OK
.equ SC_ERROR, 0xFC ; erreur clavier
.equ SC_KREL,  0xF0 ; touche rel�ch�e
.equ SC_XKEY,  0xE0 ; code �tendu
.equ SC_C,     0x21 ; scan code touche 'C'    
 ;codes touches contr�les
.equ L_SHIFT,  0x12
.equ R_SHIFT,  0x59
.equ L_CTRL,   0x14
.equ L_ALT,    0x11
.equ RETRN,    0x5A
.equ CAPS,     0x58
.equ SCROLL,   0x7E
.equ NUM,      0x77
.equ ESC,      0x76
.equ F1,       0x05
.equ F2,       0x06
.equ F3,       0x04
.equ F4,       0x0C
.equ F5,       0x03
.equ F6,       0x0B
.equ F7,       0x83 
.equ F8,       0x0A
.equ F9,       0x01
.equ F10,      0x09
.equ F11,      0x78
.equ F12,      0x07
 ; touches clavier num�rique
.equ KP0,      0x70
.equ KP1,      0x69
.equ KP2,      0x72
.equ KP3,      0x7A
.equ KP4,      0x6B
.equ KP5,      0x73
.equ KP6,      0x74
.equ KP7,      0x6C
.equ KP8,      0x75
.equ KP9,      0x7D
.equ KPDOT,    0x71
.equ KPPLUS,   0x79
.equ KPMINUS,  0x7B
.equ KPSTAR,   0x7C
; code �tendus (pr�c�d� de 0xE0) 
.equ R_CTRL,   0x14
.equ L_GUI,    0x1f
.equ R_GUI,    0x27
.equ R_ALT,    0x11
.equ APPLI,    0x2f 
.equ INSERT,   0x70
.equ HOME,     0x6C
.equ PGUP,     0x7D
.equ DEL,      0x71
.equ END,      0x69
.equ PGDN,     0x7A
.equ UP,       0x75
.equ DOWN,     0x72
.equ LEFT,     0x6B
.equ RIGHT,    0x74
.equ KPSLH,    0x4A
.equ KPENT,    0x5A 
 
;indicateurs bool�ens dans key_state
.equ F_SHIFT, 0 ; touche majuscule enfonc�e
.equ F_CTRL, 1  ; touche ctrl enfonc�e
.equ F_ALT, 2   ; touche alt enfonc�e
.equ F_CAPS, 3  ; FixMaj actif
.equ F_NUM,  4  ; clavier num�rique actif
.equ F_XKEY, 5 ; touche �tendue
.equ F_KREL, 6 ; rel�chement touche
.equ F_KBDOK, 7 ; clavier pr�sent
.equ F_SEND, 15; indicateur d'envoie
 
; grandeur file interface PS/2 
.equ PS2_QUEUE_SIZE, 32
.endif

