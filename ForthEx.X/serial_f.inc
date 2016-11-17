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

.include "serial.inc"    
    
DEFCODE "SEMIT",5,,SEMIT,KBD_CMD
    cp0 tx_wait
    bra neq, 0f
    btsc SER_STA, #UTXBF
    bra 0f
    mov T, SER_TXREG
    DPOP
    bra 3f
0:    
    mov #QUEUE_SIZE, W0
1:
    cp tx_wait
    bra eq, 1b
2:    
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
3:    
    NEXT
    
DEFCODE "SGET",4,,SGET,SEMIT
    DPUSH
0:    
    cp0 rx_in
    bra nz, 1f
;    mov #XON, W0
;    btss SER_STA, #UTXBF
;    mov.b WREG, SER_TXREG
    bra 0b
1:
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
    



