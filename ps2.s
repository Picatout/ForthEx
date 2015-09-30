; interface clavier PS/2
; REF: http://www.computer-engineering.org/ps2protocol/
    
.include "hardware.inc"
.include "ps2.inc"
    
.equ SHFT_INIT, 0x0400
    
.global ps2_queue, ps2_head, ps2_tail
.data
ps2_shiftin:    
.word  SHFT_INIT   
ps2_queue:
.space PS2_QUEUE_SIZE     
ps2_head:
.word 0
ps2_tail:
.word 0
    
.text
 
 ; interruption signal clock
 ; du clavier sur INT1
.global __INT1Interrupt
__INT1Interrupt:
    push W0
    push W1
    ; lecture du bit sur ligne PS/2 data
    mov KBD_PORT, W0
    btst.c W0,#KBD_DAT
    rrc ps2_shiftin
    bra nc, 1f
;    ; si le carry==1 les 11 bits sont lus
;    ; sauvegarde dans ps2_queue
    mov #ps2_queue, W0
    mov ps2_tail, W1
    add W0, W1, W1
    mov ps2_shiftin,W0
    lsr W0,#5,W0
    mov W0,[W1]
;    ; ajustement de l'index fin de queue
    inc2 ps2_tail
    mov #(PS2_QUEUE_SIZE-1), W0
    and ps2_tail
;    ; réinitialisation registre réception
    mov #SHFT_INIT, W0
    mov W0, ps2_shiftin
1:    
    pop W1
    pop W0
    bclr KBD_IFS, #KBD_IF
    retfie
.end    


