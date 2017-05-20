;****************************************************************************
; Copyright 2015,2016 Jacques Deschênes
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

;NOM: sound.s
;DATE: 2015-10-16
;DESCRIPTION: routines sortie tonalités audio.
    
.include "sound.inc"

.equ FCT, (FCY/64)
    
.section .sound.bss bss
    
.global tone_len    
tone_len: .space 2
    
;.text
;.global sound_init 
;sound_init:
HEADLESS SOUND_INIT,CODE 
    ; confuration porte
    mov #~(1<<AUDIO_OUT), W0
    and AUDIO_TRIS
    ; configuration PPS
    mov #~(0x1f<<AUDIO_PPSbit),W0
    and AUDIO_RPOR
    mov #(AUDIO_FN<<AUDIO_PPSbit),W0
    ior AUDIO_RPOR
    ; configuration output compare
    mov #((1<<OCTRIG)|(0xd)),W0 ; trigger on OCxRS compare
    mov W0,AUDIO_OCCON2
    mov #((AUDIO_TMR<<OCTSEL0)|(3<<OCM0)), W0  ; toggle mode
    mov W0, AUDIO_OCCON1
    mov #(2<<TCKPS0),W0  ; Fct=Fcy/64
    mov W0, AUDIO_TMRCON
   ; return
    NEXT
    
; nom: TONE   ( u1 u2 -- )
;   Génère une tonalité de fréquence u2 et de durée u1.	
; arguments:
;   u1   durée en millisecondes.
;   u2   fréquence en hertz.
; retourne:
;   rien 
 DEFCODE "TONE",4,,TONE  ; ( duration Nfr -- )
1:  cp0 tone_len
    bra nz, 1b
    mov #((FCT/2)&0xffff),W0
    mov #((FCT/2)>>16),W1
    repeat #17
    div.ud W0,T
    dec W0,W0
    mov W0, AUDIO_OCRS
    mov W0, AUDIO_OCR
    DPOP
    bset AUDIO_TMRCON, #TON
    mov T, tone_len
    DPOP
    NEXT
    


  
; .end   
