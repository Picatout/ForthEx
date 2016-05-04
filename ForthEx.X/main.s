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

.include "hardware.inc"
.include "gen_macros.inc"
.include "core.inc"
    
;config CONFIG1, FWDTEN_OFF & JTAGEN_OFF
;config CONFIG2, FNOSC_PRIPLL & FCKSM_CSDCMD  & POSCMOD_HS & OSCIOFNC_ON

.extern kbd_get
.extern _video_buffer
.extern get_code
.extern cold
    
.text
    
.global _main
    
_main:
  
; test vidéo
;    call cls
    set_eds_table quick, W1
    mov #_video_buffer,W2
    clr W0
1:
    mov.b [W1++], W0
    ze W0,W0
    bra z, 2f
    mov.b W0, [W2++]
    bra 1b
2:    
; fin test vidéo
; test clavier
3:  
    push W2
    call kbd_get
    pop W2
    cp0 W0
    bra eq, 3b
    and #127, W0
    mov.b W0, [W2]
    bra 3b
    
    bra .
    
;test string
quick:
.ascii "01234567890123456789012345678901234567890123456789"    
.ascii "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG.      "
.asciz "The quick brown fox jumps over the lazy dog.      " 
    
.end
