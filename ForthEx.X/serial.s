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
;tx_queue: .space QUEUE_SIZE
;tx_wait:  .space 2 ; nombre de caractères dans tx_queue 
;tx_head:  .space 1
;tx_tail:  .space 1
ser_flags: .space 2
rx_in:	  .space 2 ; nombre de caractère dans rx_queue
rx_head:  .space 1
rx_tail:  .space 1
 
 
.text

; vide les files
empty_queues:
    push W0
    mov #ser_flags,W0
    repeat #2
    clr [W0++]
    pop W0
    return
    
; activation port sériel
serial_enable:
    call empty_queues
;    bclr SER_TX_IFS, #SER_TX_IF
;    bset SER_TX_IEC, #SER_TX_IE
    bclr SER_RX_IFS, #SER_RX_IF
    bset SER_RX_IEC, #SER_RX_IE
    clr.b SER_TXREG
    bset SER_LAT,#SER_TX_OUT
    bset SER_STA, #UTXEN
    return

; désactivation port sériel    
serial_disable:
;    bclr SER_TX_IEC,#SER_TX_IE
    bclr SER_RX_IEC,#SER_RX_IE
    bclr SER_STA,#UTXEN
    bclr SER_LAT,#SER_TX_OUT
    return
    
    
; réception d'un caractère du port RS-232.    
INTR
.global __U1RXInterrupt
__U1RXInterrupt:
    bclr  SER_RX_IFS, #SER_RX_IF
    DPUSH
    btss SER_STA,#URXDA
    bra 9f
    mov SER_RXREG, T
    cp.b T,#CTRL_S ; XOFF
    bra nz, 1f
    bset ser_flags,#F_TXSTOP ; XOFF reçu du terminal
    bra 9f
1:  cp.b T,#CTRL_Q ; XON
    bra nz, 2f
    bclr ser_flags,#F_TXSTOP ; XON reçu du terminal
    bra 9f
2:  cp.b T,#CTRL_C
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
;.global __U1TXInterrupt
;__U1TXInterrupt:
;    btsc ser_flags,#F_TXSTOP
;    retfie 
;    bclr SER_TX_IFS, #SER_TX_IF
;    push.d W0
;    cp0 tx_wait
;    bra z, 2f
;    mov.b tx_head,WREG
;    ze W0,W0
;    mov #tx_queue, W1
;    add W0,W1,W1
;    mov.b [W1],W0
;    mov.b WREG, SER_TXREG
;    clr.b [W1]
;    dec tx_wait
;    inc.b tx_head
;    mov #(QUEUE_SIZE-1), W0
;    and.b tx_head
;2:    
;    pop.d W0
;    retfie
    
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
    ; baud rate 115200
    mov #(FCY/16/115200), W0
    mov W0, SER_BRG
    ; activation  8 bits, 1 stop, pas de paritée
    bset SER_MODE, #UARTEN
    ;priorisation interruption
;    mov #~(7<<SER_TX_IPbit), W0
;    and SER_TX_IPC
;    mov #(3<<SER_TX_IPbit), W0
;    ior SER_TX_IPC
    mov #~(7<<SER_RX_IPbit), W0
    and SER_RX_IPC
    mov #(3<<SER_RX_IPbit), W0
    ior SER_RX_IPC
    call serial_enable
    NEXT

; nom: SERENBL  ( f -- )    
;   activation/désactivation du port sériel. Le port est activé si 'f' est VRAI
;   sinon il est désactivé.    
; arguments:
;     f TRUE activation, FALSE désactivation    
; retourne:
;     rien    
DEFCODE "SERENBL",7,,SERENBL ; ( f -- )
    cp0 T
    DPOP
    bra z, 1f
    call serial_enable
    bra 9f
1:  call serial_disable
9:  NEXT

; nom: Bxxxxx  ( -- n )  
;   Plusieurs constantes sont définies pour l'ajustement de la vitesse de transfert
;   du port sériel. Les constantes suivantes sont disponibles.
;   B2400 -> 2400 BAUD
;   B4800 -> 4800 BAUD
;   B9600 -> 9600 BAUD
;   B19200 -> 19200 BAUD
;   B38400 -> 38400 BAUD
;   B57600 -> 57600 BAUD
;   B115200 -> 115200 BAUD 
; arguments:
;   aucun
; retourne:
;   n   Une constante qui sert à programmer le registre qui contrôle la vitesse du port.    
DEFCONST "B2400",5,,B2400,(FCY/16/2400)
DEFCONST "B4800",5,,B4800,(FCY/16/4800)-1
DEFCONST "B9600",5,,B9600,(FCY/16/9600)
DEFCONST "B19200",6,,B19200,(FCY/16/19200)
DEFCONST "B38400",6,,B38400,(FCY/16/38400)
DEFCONST "B57600",6,,B57600,(FCY/16/57600)
DEFCONST "B115200",7,,B115200,(FCY/16/115200)
    
; nom: BAUD  ( u -- )     
;   Ajuste la vitesse du port sériel et l'active.
; exemple:  
;   B57600 BAUD / le port est activé à la vitesse de 57600 BAUD.    
; arguments:
;   u   Une des constantes pré-difinies dont le nom commence par B.
; retourne:
;   rien   Le port est activé.
DEFCODE "BAUD",4,,BAUD   ; ( u -- )
    call serial_disable
    mov T, SER_BRG
    DPOP
    call serial_enable
    NEXT

; nom: SPUTC   ( c -- )
;   Transmission d'un caractère via le port sériel. Au démarrage le port est
;   activé à la vitesse de 115200 BAUD, 8 bits, 1 stop, pas de parité.    
; arguments:
;    c  caractère à transmettre.
; retourne:
;   rien    
DEFCODE "SPUTC",5,,SPUTC ; ( c -- )
1:  btsc ser_flags,#F_TXSTOP
    bra 1b
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
 
; nom: SGETC  ( -- c )
;   Attend un careactère du port sériel. Cette attente n'expire jamais.
; arguments:
;   aucun
; retourne:
;   c   Caractère reçu du port sériel.    
DEFCODE "SGETC",5,,SGETC  ; ( -- c )
1:    
    btss ser_flags,#F_RXDAT
    bra 1b
    mov.b rx_head, WREG
    ze W0,W0
    mov #rx_queue, W1
    add W0,W1,W1
    DPUSH
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
    setm T
    NEXT
    
; nom: SGETC? ( -- f )
;   Vérifie s'il y a un caractère de disponible dans
;   la file de réception du port sériel.
; arguments:
;    aucun    
; retourne:
;   f   indicateur booléen, VRAI si un caractère est disponible.
DEFCODE "SGETC?",6,,SGETCQ
    DPUSH
    clr T
    btsc ser_flags, #F_RXDAT
    setm T
9:  NEXT
    
    