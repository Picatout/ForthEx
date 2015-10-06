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
; interface clavier PS/2
; REF: http://www.computer-engineering.org/ps2protocol/
    
.include "hardware.inc"
.include "ps2.inc"
    
.equ SENTRY, 0x0400
    
.global ps2_queue, ps2_head, ps2_tail
.data
ps2_shiftin:    
.word  0
ps2_queue:
.space PS2_QUEUE_SIZE     
ps2_head:
.word 0
ps2_tail:
.word 0
    
.text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialistaion interface clavier PS/2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global ps2_init
ps2_init:
    ; PPS sélection broche pour kbd_clk
    ; interruption externe
    mov #~(0x1f<<KBD_PPSbit), W0
    and KBD_RPINR
    mov #(KBD_CLK<<KBD_PPSbit), W0
    ior KBD_RPINR
    ; polarité interruption transition négative
    bset KBD_INTCON, #KBD_INTEP
    ; priorité d'interruption 7
    mov #(7<<KBD_IPCbit), W0
    ior KBD_IPC 
    ; activation interruption clavier
    bclr KBD_IFS, #KBD_IF
    bset KBD_IEC, #KBD_IE
    ; initialisation TIMER1
    ; mise à jour systicks
    ; et traitement file clavier
    mov #15999, W0
    mov W0, PR1
    mov #~(7<<T1IP0), W0
    and IPC0
    mov #(3<<T1IP0), W0
    ior IPC0
    mov #SENTRY, W0
    mov W0, ps2_shiftin
    bclr IFS0, #T1IF
    bset IEC0, #T1IE
    bset T1CON, #TON
    return

   
 ; interruption signal clock
 ; du clavier sur INT1
.global __INT1Interrupt
 INT
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
    mov #SENTRY, W0
    mov W0, ps2_shiftin
1:    
    pop W1
    pop W0
    bclr KBD_IFS, #KBD_IF
    retfie
.end    


