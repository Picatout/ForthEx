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

; NOM: keybind.s
; DESCRIPTION: table de transcription scancode set 2 vers ASCII
; REF: http://www.computer-engineering.org/ps2keyboard/scancodes2.html 
    
.include "ps2.inc"
.include "keyboard.inc"
    
.global ascii, shifted, extended
    
.section .const psv 
    
ascii:
.byte 0x1c,'a'
.byte 0x32,'b'
.byte 0x21,'c'
.byte 0x23,'d'
.byte 0x24,'e'
.byte 0x2b,'f'
.byte 0x34,'g'
.byte 0x33,'h'
.byte 0x43,'i'
.byte 0x3b,'j'
.byte 0x42,'k'
.byte 0x4b,'l'
.byte 0x3a,'m'
.byte 0x31,'n'
.byte 0x44,'o'
.byte 0x4d,'p'
.byte 0x15,'q'
.byte 0x2d,'r'
.byte 0x1b,'s'
.byte 0x2c,'t'
.byte 0x3c,'u'
.byte 0x2a,'v'
.byte 0x1d,'w'
.byte 0x22,'x'
.byte 0x35,'y'
.byte 0x1a,'z'
.byte 0x45,'0'
.byte 0x16,'1'
.byte 0x1e,'2'
.byte 0x26,'3'
.byte 0x25,'4'
.byte 0x2e,'5'
.byte 0x36,'6'
.byte 0x3d,'7'
.byte 0x3e,'8'
.byte 0x46,'9'
.byte 0x29,' '
.byte 0x4e,'-'
.byte 0x55,'='
.byte 0x0e,'`'
.byte 0x0d,'\t'
.byte 0x54,'['
.byte 0x5b,']'
.byte 0x4c,';'
.byte 0x41,','
.byte 0x49,'.'
.byte 0x4a,'/'
.byte 0x66,8    ; BACKSPACE
.byte 0x0d,9    ; TAB
.byte 0x5a,'\r' ; CR
.byte 0x76,27   ; ESC
.byte L_SHIFT, VK_SHIFT
.byte R_SHIFT, VK_SHIFT    
.byte L_CTRL,  VK_CTRL    
.byte L_ALT,   VK_ALT    
.byte 0,0

shifted:
.byte 0x0e,'~'
.byte 0x16,'!'
.byte 0x1e,'@'
.byte 0x26,'#'
.byte 0x25,'$'
.byte 0x2e,'%'
.byte 0x36,'^'
.byte 0x3d,'&'
.byte 0x3e,'*'
.byte 0x46,'('
.byte 0x45,')'
.byte 0x4e,'_'
.byte 0x64,'{'    
.byte 0x55,'+'
.byte 0x5b,'}'    
.byte 0x5d,'\\'
.byte 0x4c,':'
.byte 0x52,'"'
.byte 0x41,'<'
.byte 0x49,'>'
.byte 0x4a,'?'
.byte 0,0

extended:
.byte R_CTRL, VK_CTRL
.byte R_ALT,  VK_ALT
.byte INSERT, VK_INS
.byte HOME,   VK_HOME
.byte PGUP,   VK_PGUP
.byte DEL,    VK_DEL
.byte END,    VK_END
.byte PGDN,   VK_PGDN
.byte UP,     VK_UP
.byte DOWN,   VK_DOWN
.byte LEFT,   VK_LEFT
.byte RIGHT,  VK_RIGHT
.byte 0,0    
    
.end
