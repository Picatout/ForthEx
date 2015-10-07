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
    

.equ BUFF_SIZE, 16
    
.data
rx_queue: .space BUFF_SIZE
tx_queue: .space BUFF_SIZE
rx_head:  .space 1
rx_tail:  .space 1
tx_head:  .space 1
tx_tail:  .space 1
  
 
.text
    
.global serial_init
serial_init:
    ; mettre broche en mode sortie
    mov #~(1<<SER_TX_OUT), W0
    and SER_TRIS
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
    bset SER_MOD, #UARTEN
    bset SER_STA, #UTXEN
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
    mov W0, SER_TXREG
    return
 
    
CODE ser_put
1:  btsc SER_STA, #UTXBF
    bra 1b
    mov T, SER_TXREG
    DPOP
    NEXT
    
CODE ser_get
    DPUSH
    clr T
    btsc SER_STA, #URXDA
    mov SER_RXREG, T
    NEXT
    
    
    
INT
.global __U1RXInterrupt
__U1RXInterrupt:
    mov #rx_queue, W0
    add.b rx_tail, WREG
    mov SER_RXBUF, W1
    ze W1
    mov.b W1, [W0]
    inc.b rx_tail
    mov #(BUFF_SIZE-1), W0
    and.b rx_tail
    mov rx_tail, W0
    cp W0, #(BUFF_SIZE-4)
    bra ltu, 1f
    btsc SER_STA, #TXBF
    bra 1f
    mov #XON, W0
    mov W0, SER_TXREG
1:    
    bclr  SER_RX_IFS, #SER_RX_IF
    retfie
    
    
.global __U1TXInterrupt
__U1TXInterrupt:
    mov tx_head, W0
    cp  tx_tail
    bra eq, 2f
    
2:    
    bclr SER_TX_IFS, #SER_TX_IF
    retfie
.end
