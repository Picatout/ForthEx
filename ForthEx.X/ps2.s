;****************************************************************************
; Copyright 2015, 2016 Jacques Deschênes
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
    
.section .ps2.bss bss

.global ps2_queue, ps2_head, ps2_tail
    
ps2_shiftin:  ; utilisé par ISR INT1 réception bits clavier
.space 2  
ps2_shiftout:  ; utilisé par ISR INT1 envoie bits au clavier    
.space 2
send_count:  ; nombre de bits à envoyer
.space 2 
ps2_queue:
.space PS2_QUEUE_SIZE     
ps2_head:
.space 2 
ps2_tail:
.space 2
.global key_state    
key_state:    
.space 2 
    
.text
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialistaion interface clavier PS/2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global ps2_init
ps2_init:
    ; sortie en mode open drain
    mov #(1<<KBD_CLK|1<<KBD_DAT),W0
    ior KBD_ODC
    com W0,W0
    ; PPS sélection broche pour kbd_clk
    ; interruption externe
    ;mov #~(0x7f<<KBD_PPSbit), W0
    ;and KBD_RPINR
    clr KBD_RPINR
    mov #(KBD_RPI<<KBD_PPSbit), W0
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
    mov #(1<<TCKPS0),W0
    mov WREG,T1CON
    mov #(FCY_MHZ*1000/8-1), W0
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

; signale au clavier l'envoie d'un octet
; ref: http://www.computer-engineering.org/ps2protocol/
ps2_signal:
    ; désactive interruption clavier
    bclr KBD_IEC, #KBD_IE
    ; prendre le contrôle de la ligne clock et la mettre à zéro
    ; pour au moins 100µsec
    bclr KBD_LAT, #KBD_CLK 
    bclr KBD_TRIS, #KBD_CLK 
    mov #TCY_USEC, W1
    sl W1,#7,W1 ; 128µsec
    repeat W1
    nop
    ;prendre le contrôle de la ligne data et la mettre à zéro
    bclr KBD_LAT, #KBD_DAT
    bclr KBD_TRIS, #KBD_DAT
    ; relaché la ligne clock
    bset KBD_TRIS, #KBD_CLK
    bset key_state, #F_SEND
    ;réactive interruption clavier
    bclr KBD_IFS, #KBD_IF
    bset KBD_IEC, #KBD_IE
    return

;envoie d'un octet au clavier
; octet dans W0    
.global ps2_send
ps2_send:    
    ; calcul de la parité
    clr W1   ; compteur de bits
    mov #7,W2 ; bits à vérifier <7:0>
1:  btst.c W0,W2
    addc #0,W1 
    dec W2,W2
    bra nn, 1b
    btss W1, #0 ;doit-être impair
    bset W0,#8 ; parité bit
    bset W0,#9 ; stop bit
    mov W0,ps2_shiftout
    ; initialise le compteur de bits
    mov #10, W0
    mov W0, send_count
    call ps2_signal
    btsc key_state,#F_SEND
    return
    
 ; interruption signal clock
 ; du clavier sur INT1
.global __INT1Interrupt
 INTR
__INT1Interrupt:
;    push W0
;    push W1
    bclr KBD_IFS, #KBD_IF
    push.s
    btsc key_state,#F_SEND
    bra sending
receiving:    
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
sending:
    cp0 send_count
    bra nz, 0f
    bclr key_state, #F_SEND
    bra 1f
0:
    bclr KBD_LAT, #KBD_DAT
    btsc ps2_shiftout,#0
    bset KBD_LAT,#KBD_DAT
    lsr ps2_shiftout
    dec send_count
    bra nz, 1f
    bset KBD_TRIS,#KBD_DAT
1:    
    pop.s
    retfie
.end    


