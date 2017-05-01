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
   
.equ F_TXSTOP, 0 ; un caractère XOFF a été reçu du terminal
.equ F_RXSTOP, 1 ; un caractère XOFF a été envoyé au terminal    
.equ F_ESC,    2 ; le caractère A_ESC (27) a été reçu
.equ F_LBRA,   3 ; le caractère '[' (91) a été reçu après A_ESC
.equ F_RXDAT,  4 ; data en attente dans la file rx_queue
    
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
ser_flags: .space 2
 
 
.text

; vide les files
empty_queues:
    push.d W0
    mov #tx_wait,W1
    repeat #7
    clr.b [W1++]
    pop.d W0
    return
    
; activation port sériel
serial_enable:
    call empty_queues
    bclr SER_TX_IFS, #SER_TX_IF
    bset SER_TX_IEC, #SER_TX_IE
    bclr SER_RX_IFS, #SER_RX_IF
    bset SER_RX_IEC, #SER_RX_IE
    clr.b SER_TXREG
    bset SER_LAT,#SER_TX_OUT
    bset SER_STA, #UTXEN
    return

; désactivation port sériel    
serial_disable:
    bclr SER_TX_IEC,#SER_TX_IE
    bclr SER_RX_IEC,#SER_RX_IE
    bclr SER_STA,#UTXEN
    bclr SER_LAT,#SER_TX_OUT
    return
    
    
    
INTR
.global __U1RXInterrupt
__U1RXInterrupt:
    bclr  SER_RX_IFS, #SER_RX_IF
    DPUSH
    btss SER_STA,#URXDA
    bra 9f
    mov SER_RXREG, T
    cp.b T,#A_XOFF
    bra nz, 1f
    bset ser_flags,#F_TXSTOP ; XOFF reçu du terminal
    bra 9f
1:  cp.b T,#A_XON
    bra nz, 2f
    bclr ser_flags,#F_TXSTOP ; XON reçu du terminal
    bra 9f
2:  cp.b T,#A_ETX
    bra nz, 3f
    mov #USER_ABORT,W0
    mov W0, fwarm
    reset
3:  push.d W0
    mov.b rx_tail, WREG
    ze W0,W0
    mov #rx_queue, W1
    add W0,W1,W1
    mov.b T, [W1]
    bset ser_flags,#F_RXDAT
    inc rx_in
    inc.b rx_tail
    mov #(QUEUE_SIZE-1), W0
    and.b rx_tail
    mov #(QUEUE_SIZE/4), W1
    sub W0,W1,W0
    cp.b rx_in
    bra ltu, 8f   
    mov #A_XOFF, W0
    mov.b WREG, SER_TXREG   ; envoie un XOFF au terminal
    bset ser_flags,#F_RXSTOP 
8:  pop.d W0
9:  DPOP
    retfie
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
 ; interruption transmission sérielle  
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.global __U1TXInterrupt
__U1TXInterrupt:
    btsc ser_flags,#F_TXSTOP
    retfie 
    bclr SER_TX_IFS, #SER_TX_IF
    push.d W0
    cp0 tx_wait
    bra z, 2f
    mov.b tx_head,WREG
    ze W0,W0
    mov #tx_queue, W1
    add W0,W1,W1
    mov.b [W1],W0
    mov.b WREG, SER_TXREG
    clr.b [W1]
    dec tx_wait
    inc.b tx_head
    mov #(QUEUE_SIZE-1), W0
    and.b tx_head
2:    
    pop.d W0
    retfie
    
;;;;;;;;;;;;;;;;;;;;;;
; mots système FORTH
;;;;;;;;;;;;;;;;;;;;;;


;initialisation port série  
; BAUD par défaut 57600
HEADLESS SERIAL_INIT,CODE ; ( -- )
    ; met broche à 1 lorsque le UARTX est désactivé
    bset SER_LAT,#SER_TX_OUT
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
    ; baud rate 57600
    mov #(FCY/(16*57600)-1), W0
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
    call serial_enable
    NEXT

; activation/désactivation port série
;  argument:
;     f TRUE activation FALSE désactivation    
DEFCODE "SERENBL",7,,SERENBL ; ( f -- )
    cp0 T
    DPOP
    bra z, 1f
    call serial_enable
    bra 9f
1:  call serial_disable
9:  NEXT
    
; ajuste la vitesse du port sériel et l'active.
; argument:
;   u   baud rate maximum: 57600
; sortie:
;   port actif.    
DEFCODE "BAUD",4,,BAUD   ; ( u -- )
    call serial_disable
    mov #FCY&0xffff,W0
    mov #FCY>>16,W1
    mov #4,W2 ; FCY/16
1:  lsr W1,W1
    rrc W0,W0
    dec W2,W2
    bra nz, 1b
    repeat #17  ; W1:W0/T
    div.ud W0,T
    dec W0,W0
    mov W0, SER_BRG
    call serial_enable
    DPOP
    NEXT


; transmission d'un caractère par
; le port sériel.
; argument:
;    c  caractère à transmettre.
DEFCODE "SPUTC",5,,SPUTC ; ( c -- )
1:  btsc SER_STA,#UTXBF
    bra 1b
    ze T,T
    mov T,SER_TXREG
    DPOP
    NEXT
;     ; vérification file transmission
;     ; attend libération d'un espace
;     bset SER_TX_IFS, #SER_TX_IF 
;     mov #QUEUE_SIZE,W0
;1:   cp.b tx_wait  
;     bra z,1b
;     mov.b tx_tail,WREG
;     ze W0,W0
;     mov #tx_queue,W1
;     add W0,W1,W1
;     mov.b T,[W1]
;     DPOP
;     bclr SER_TX_IEC,#SER_TX_IE
;     inc.b tx_wait
;     inc.b tx_tail
;     mov.b #(QUEUE_SIZE-1),W0
;     and.b tx_tail
;     bset SER_TX_IFS,#SER_TX_IF
;     bset SER_TX_IEC,#SER_TX_IE
;     NEXT
 
; attend un careactère du port sériel    
DEFCODE "SGETC",5,,SGETC  ; ( -- c )
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
    ze T,T
    dec rx_in
    bra nz,1f
    bclr ser_flags, #F_RXDAT
1:  inc.b rx_head
    mov #(QUEUE_SIZE-1), W0
    and.b rx_head
    btss ser_flags,#F_RXSTOP
    bra 2f
    mov #(QUEUE_SIZE/4),W1
    sub W0,W1,W0
    cp.b rx_in
    bra gtu, 2f
    mov #A_XON,W0
    mov.b WREG, SER_TXREG
    bclr ser_flags,#F_RXSTOP
2:  NEXT

; nom: SREADY? ( -- f )
;  vérifie si le terminal est prêt à recevoir
; arguments:
;    aucun
; retourne:
;    f      indicateur booléen, vrai si terminal prêt à recevoir.
DEFCODE "SREADY?",7,,SREADYQ
    DPUSH
    clr T
    btss ser_flags,#F_TXSTOP
    com T,T
    NEXT
    
; nom: SGETC? ( -- f )
;   Vérifie s'il y a un caractère de disponible dans
;   la file de réception
; arguments:
;    aucun    
; retourne:
;   f   indicateur booléen, VRAI si caractère disponible
DEFCODE "SGETC?",6,,SGETCQ
    DPUSH
    clr T
    mov.b rx_head,WREG
    cp.b rx_tail
    bra z,9f
    setm T
9:  NEXT
    
    