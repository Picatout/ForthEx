;
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

;
; Fichier: keyboard.s
; Description: transcription code clavier PS/2 en ASCII
; Auteur: Jacques Deschênes
; Date: 2015-09-28
;

.include "hardware.inc"    
.include "video.inc"
.include "ps2.inc"    

.equ KBD_QUEUE_SIZE, 32    
.data
kbd_queue:
.space KBD_QUEUE_SIZE    
kbd_head:
.word 0
kbd_tail:
.word 0
key_state:    
.byte 0
    
.text    
.global kbd_count
kbd_count:
    mov kbd_head, W0
    sub kbd_tail, WREG
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;
; interruption TIMER1
;;;;;;;;;;;;;;;;;;;;;;;;;

.extern systicks
.extern ps2_head
.extern ps2_tail    
.extern ps2_queue  
    
.global __T1Interrupt   
__T1Interrupt:
    push W0
    push W1
    push W2
    push W3
    inc systicks
    mov ps2_head, W0
    cp ps2_tail
    bra z, isr_exit
    mov #ps2_queue, W1
    add W0, W1, W1
    mov [W1], W0
    lsr W0,W0
    bra c, 9f ; start bit doit-être zéro
    btst.c W0, #9
    bra nc, 9f ; stop bit doit-être 1
    clr W3
    and #0x1ff, W0
    mov #0, W2
1:
    btst.c W0,W2
    bra nc, 2f
    inc W3,W3
2:    
    inc W2,W2
    cp W2, #9
    bra neq, 1b
    ; paritée impaire, W3 doit-être impaire.
    btss W3,#0
    bra 9f
    mov #kbd_queue, W1
    mov kbd_tail, W2
    add W2,W1,W1
    mov.b W0,[W1]
    add #1,W2
    and #(KBD_QUEUE_SIZE-1),W2
    mov W2, kbd_tail
9:    
    ;incrémente ps2_head
    inc2 ps2_head
    mov #(PS2_QUEUE_SIZE-1), W0
    and ps2_head
isr_exit:
    pop W3
    pop W2
    pop W1
    pop W0
    bclr IFS0, #T1IF
    retfie
    
.end
    