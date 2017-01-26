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

;NOM: serial.s
;Description:  communication port sériel RS232 via USART
;Date: 2015-10-07
    
.include "serial.inc"
   


    
.section .serial.bss bss
;.global tx_wait, tx_tail,tx_queue,rx_head,rx_queue,rx_in    
rx_queue: .space QUEUE_SIZE
tx_queue: .space QUEUE_SIZE
tx_wait:  .space 2 ; nombre de caractères dans tx_queue 
tx_head:  .space 1
tx_tail:  .space 1
rx_in:	  .space 2 ; nombre de caractère dans rx_queue
rx_head:  .space 1
rx_tail:  .space 1
 
 
.text

    
    
INTR
.global __U1RXInterrupt
__U1RXInterrupt:
    bclr  SER_RX_IFS, #SER_RX_IF
    push W0
    push W1
    mov.b rx_tail, WREG
    ze W0,W0
    mov #rx_queue, W1
    add W0,W1,W1
    btss SER_STA, #URXDA
    bra 1f
    mov SER_RXREG, W0
    mov.b W0, [W1]
    inc rx_in
    inc.b rx_tail
    mov #(QUEUE_SIZE-1), W0
    and.b rx_tail
;    mov #(QUEUE_SIZE-4), W0
;    cp rx_in
;    bra ltu, 1f   
;    btsc SER_STA, #UTXBF
;    bra 1f
;    mov #XOFF, W0
;    mov.b WREG, SER_TXREG
1:    
    pop W1
    pop W0
    retfie
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
 ; interruption transmission sérielle  
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global __U1TXInterrupt
__U1TXInterrupt:
    bclr SER_TX_IFS, #SER_TX_IF
    push W0
    push W1
    cp0 tx_wait
    bra z, 2f
    mov.b tx_head,WREG
    ze W0,W0
    mov #tx_queue, W1
    add W0,W1,W1
    mov.b [W1],W0
    mov.b WREG, SER_TXREG
    dec tx_wait
    inc.b tx_head
    mov #(QUEUE_SIZE-1), W0
    and.b tx_head
2:    
    pop W1
    pop W0
    retfie
    
;;;;;;;;;;;;;;;;;;;;;;
; mots système FORTH
;;;;;;;;;;;;;;;;;;;;;;

;initialisation port série  
; BAUD par défaut 9600
HEADLESS SERIAL_INIT,CODE ; ( -- )
    ; mettre broche en mode sortie
    bclr SER_TRIS, #SER_TX_OUT
    ; sélection PPS pour transmission
    mov #~(0x1f<<SER_TX_PPSbit), W0
    and SER_TX_RPOR
    mov #(SER_TX_FN<<SER_TX_PPSbit), W0
    ior SER_TX_RPOR
    ; sélection PPS pour réception
    mov #~(0x1f<<SER_RX_PPSbit), W0
    and SER_RX_RPINR
    mov #(SER_RX_INP<<SER_RX_PPSbit), W0
    ior SER_RX_RPINR
    ; baud rate 9600
    mov #(FCY/(16*9600)-1), W0
    mov W0, SER_BRG
    ; activation  8 bits, 1 stop, pas de paritée
    bset SER_MODE, #UARTEN
    ;priorisation interruption
    mov #~(7<<SER_TX_IPbit), W0
    and SER_TX_IPC
    mov #(3<<SER_TX_IPbit), W0
    ior SER_TX_IPC
    mov #~(7<<SER_RX_IPbit), W0
    and SER_RX_IPC
    mov #(3<<SER_RX_IPbit), W0
    ior SER_RX_IPC
    ; activation interrupts
    bclr SER_TX_IFS, #SER_TX_IF
    bset SER_TX_IEC, #SER_TX_IE
    bclr SER_RX_IFS, #SER_RX_IF
    bset SER_RX_IEC, #SER_RX_IE
    clr.b SER_TXREG
    bset SER_STA, #UTXEN
    NEXT
    
DEFCODE "BAUD",4,,BAUD   ; ( u -- ) u<=57600
    bclr SER_MODE, #UARTEN
    mov #FCY&0xffff,W0
    mov #FCY>>16,W1
    mov #4,W2 ; FCY/16
1:  lsr W1,W1
    rrc W0,W0
    dec W2,W2
    repeat #17  ; W1:W0/T
    div.ud W0,T
    dec W0,W0
    mov W0, SER_BRG
    bset SER_MODE, #UARTEN
    DPOP
    NEXT
    
DEFCODE "SEMIT",5,,SEMIT
    cp0 tx_wait
    bra neq, 1f
    btsc SER_STA, #UTXBF
    bra 1f
    mov T, SER_TXREG
    DPOP
    bra 4f
1:    
    mov #QUEUE_SIZE, W0
2:
    cp tx_wait
    bra eq, 2b
3:    
    mov.b tx_tail, WREG
    ze W0,W0
    mov #tx_queue, W1
    add W0,W1,W1
    mov.b T, [W1]
    DPOP
    inc tx_wait
    inc.b tx_tail
    mov #(QUEUE_SIZE-1), W0
    and.b tx_tail
4:    
    NEXT
    
DEFCODE "SGET",4,,SGET
    DPUSH
1:    
    cp0 rx_in
    bra nz, 2f
    bra 1b
2:
    mov.b rx_head, WREG
    ze W0,W0
    mov #rx_queue, W1
    add W0,W1,W1
    mov.b [W1], T
    dec rx_in
    inc.b rx_head
    mov #(QUEUE_SIZE-1), W0
    and.b rx_head
    NEXT
    



    
;.end
