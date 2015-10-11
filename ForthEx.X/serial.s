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

;NOM: serial.s
;Description:  communication port sériel RS232 via USART
;Date: 2015-10-07
    
.include "hardware.inc"
.include "core.inc"
.include "serial.inc"
.include "core.inc"    

.equ QUEUE_SIZE, 16
    
.data
rx_queue: .space QUEUE_SIZE
tx_queue: .space QUEUE_SIZE
tx_wait:  .space 2 ; nombre de caractère à transmettre 
rx_head:  .space 1
rx_tail:  .space 1
tx_head:  .space 1
tx_tail:  .space 1
  
 
.text
    
.global serial_init
serial_init:
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
    mov #XON, W0
    mov.b WREG, SER_TXREG
    bset SER_STA, #UTXEN
    return
 
    
DEFCODE "SEMIT",5,,SEMIT
    mov #QUEUE_SIZE, W0
1:
    btsc SER_STA, #TRMT
    ; on s'arrure que la transmission aura lieu
    bset SER_TX_IFS, #SER_TX_IF     
    cp tx_wait
    bra eq, 1b
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
    NEXT
    
DEFCODE "SGET",4,,SGET
    DPUSH
    clr T
    mov.b rx_head, WREG
    cp.b  rx_tail
    bra neq, 1f
    ze W0,W0
    cp W0, #QUEUE_SIZE
    bra neq, 2f
    clr rx_head  ; remet rx_head et rx_tail à zéro
0:    
    btsc SER_STA, #UTXBF
    bra 0b
    mov #XON, W0
    mov W0, SER_TXREG
    bra 2f
1:    
    ze W0,W0
    mov #rx_queue, W1
    add W0,W1,W1
    mov.b [W1], T
    inc.b rx_head
    mov #QUEUE_SIZE, W0
    cp.b rx_head
2:    
    NEXT
    
    
    
INT
.global __U1RXInterrupt
__U1RXInterrupt:
    bclr  SER_RX_IFS, #SER_RX_IF
    push W0
    push W1
    mov.b rx_tail, WREG
    ze W0,W0
    cp W0, #QUEUE_SIZE ; PIC24F <#lit5>, PIC24E <#lit8>
    bra eq, 0f
    mov #rx_queue, W1
    add W0,W1,W1
    mov SER_RXREG, W0
    mov.b W0, [W1]
    inc.b rx_tail
    mov #(QUEUE_SIZE-4), W0
    cp.b rx_tail
    bra ltu, 1f
0:    
    btsc SER_STA, #UTXBF
    bra 1f
    mov #XOFF, W0
    mov W0, SER_TXREG
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
.end
