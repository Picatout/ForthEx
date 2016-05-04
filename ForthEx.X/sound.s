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

;Nom: sound.s
;Description: routines sortie tonalités audio.
;Date: 2015-10-16
    
.include "hardware.inc"
.include "core.inc"    

.equ FCT, (FCY/8)
    
.data
.global tone_len    
tone_len: .space 2
    
.text
.global sound_init 
sound_init:
    ; confuration porte
    mov #~(1<<AUDIO_OUT), W0
    and AUDIO_TRIS
    ; configuration PPS
    mov #~(0x1f<<AUDIO_PPSbit),W0
    and AUDIO_RPOR
    mov #(AUDIO_FN<<AUDIO_PPSbit),W0
    ior AUDIO_RPOR
    ; configuration output compare
    clr AUDIO_OCCON2
    mov #((1<<OCTSEL0)|(5<<OCM0)), W0
    mov W0, AUDIO_OCCON1
    mov #(1<<TCKPS0),W0  ; Fct=Fcy/8
    mov W0, AUDIO_TMRCON
    return
    
 ;;;;;;;;;;;;;;;;;;
 ; mots Forth
 ;;;;;;;;;;;;;;;;;;
 
 DEFCODE "TONE",4,,TONE  ; ( duration Nfr -- )
    mov T, AUDIO_PER
    mov T, AUDIO_OCRS
    lsr T, T
    mov T, AUDIO_OCR
    DPOP
    bset AUDIO_TMRCON, #TON
    mov T, tone_len
    DPOP
    NEXT
 
 .end   
