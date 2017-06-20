;****************************************************************************
; Copyright 2015,2016 Jacques Desch�nes
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
;Date: 2015-10-07
; DESCRIPTION:
;    Configuration et fonctions de base pour la communication par le port s�riel RS232.
    
.include "serial.inc"
   
.equ F_TXSTOP, 0 ; un caract�re XOFF a �t� re�u du terminal
.equ F_RXSTOP, 1 ; un caract�re XOFF a �t� envoy� au terminal    
.equ F_ESC,    2 ; le caract�re A_ESC (27) a �t� re�u
.equ F_LBRA,   3 ; le caract�re '[' (91) a �t� re�u apr�s A_ESC
.equ F_RXDAT,  4 ; data en attente dans la file rx_queue
    
.section .serial.bss bss
;.global tx_wait, tx_tail,tx_queue,rx_head,rx_queue,rx_in    
rx_queue: .space QUEUE_SIZE
;tx_queue: .space QUEUE_SIZE
;tx_wait:  .space 2 ; nombre de caract�res dans tx_queue 
;tx_head:  .space 1
;tx_tail:  .space 1
ser_flags: .space 2
rx_in:	  .space 2 ; nombre de caract�re dans rx_queue
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
    
; activation port s�riel
serial_enable:
    call empty_queues
;    bclr SER_TX_IFS, #SER_TX_IF
;    bset SER_TX_IEC, #SER_TX_IE
;    clr SER_TXREG
    bclr SER_RX_IFS, #SER_RX_IF
    bset SER_RX_IEC, #SER_RX_IE
    bset SER_STA, #UTXEN
    return

; d�sactivation port s�riel    
serial_disable:
;    bclr SER_TX_IEC,#SER_TX_IE
    bclr SER_RX_IEC,#SER_RX_IE
    bclr SER_STA,#UTXEN
    bset SER_LAT,#SER_TX_OUT
    return
    
    
; r�ception d'un caract�re du port RS-232.    
INTR
.global __U1RXInterrupt
__U1RXInterrupt:
    bclr  SER_RX_IFS, #SER_RX_IF
    push.d W0
    push W2
    btss SER_STA,#URXDA
    bra 9f
    mov SER_RXREG, W2
    cp.b W2,#CTRL_C
    bra nz, 1f
    mov #USER_ABORT,W0
    mov W0, fwarm
    reset
1:  cp.b W2,#CTRL_S ; XOFF
    bra nz, 2f
    bset ser_flags,#F_TXSTOP ; XOFF re�u du terminal
    bra 9f
2:  cp.b W2,#CTRL_Q ; XON
    bra nz, 3f
    bclr ser_flags,#F_TXSTOP ; XON re�u du terminal
    bra 9f
3:  mov.b rx_tail, WREG
    ze W0,W0
    mov #rx_queue, W1
    add W0,W1,W1
    mov.b W2, [W1]
    bset ser_flags,#F_RXDAT
    inc rx_in
    inc.b rx_tail
    mov #(QUEUE_SIZE-1), W0
    and.b rx_tail
    mov #(QUEUE_SIZE/2), W0
    cp.b rx_in
    bra ltu, 9f   
    mov #CTRL_S, W0
    mov.b WREG, SER_TXREG   ; envoie un XOFF au terminal
    bset ser_flags,#F_RXSTOP 
9:  pop W2
    pop.d W0
    retfie
 
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
 ; interruption transmission s�rielle  
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
; mots syst�me FORTH
;;;;;;;;;;;;;;;;;;;;;;


;initialisation port s�rie  
; BAUD par d�faut 57600
HEADLESS SERIAL_INIT,CODE ; ( -- )
    ; met broche � 1 lorsque le UARTX est d�sactiv�
    bset SER_LAT,#SER_TX_OUT
    ; mettre broche en mode sortie
    bclr SER_TRIS, #SER_TX_OUT
    ; s�lection PPS pour transmission
    mov #~(0x1f<<SER_TX_PPSbit), W0
    and SER_TX_RPOR
    mov #(SER_TX_FN<<SER_TX_PPSbit), W0
    ior SER_TX_RPOR
    ; s�lection PPS pour r�ception
    mov #~(0x1f<<SER_RX_PPSbit), W0
    and SER_RX_RPINR
    mov #(SER_RX_INP<<SER_RX_PPSbit), W0
    ior SER_RX_RPINR
    ; baud rate 115200
    mov #(FCY/16/115200), W0
    mov W0, SER_BRG
    ; activation  8 bits, 1 stop, pas de parit�e
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
;   Activation/d�sactivation du port s�riel. Le port est activ� si 'f' est VRAI
;   sinon il est d�sactiv�.    
; arguments:
;     f TRUE activation, FALSE d�sactivation    
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

; nom: Bnnnnnn  ( -- n )  
;   Plusieurs constantes sont d�finies pour l'ajustement de la vitesse de transfert
;   du port s�riel. Les constantes suivantes sont disponibles.
; HTML:
; <br><table border="single">
; <tr><th>nom</th><th>vitesse<br>BAUD</th></tr>    
; <tr><td>B2400</td><td>2400</td></tr>
; <tr><td>B4800</td><td>4800</td></tr>
; <tr><td>B9600</td><td>9600</td></tr>
; <tr><td>B19200</td><td>19200</td></tr>
; <tr><td>B38400</td><td>38400</td></tr>
; <tr><td>B57600</td><td>57600</td></tr>
; <tr><td>B115200</td><td>115200</td></tr>
; </table><br>
; :HTML    
; arguments:
;   aucun
; retourne:
;   n   Une constante qui sert � programmer la vitesse du port.    
DEFCONST "B2400",5,,B2400,(FCY/16/2400)
DEFCONST "B4800",5,,B4800,(FCY/16/4800)-1
DEFCONST "B9600",5,,B9600,(FCY/16/9600)
DEFCONST "B19200",6,,B19200,(FCY/16/19200)
DEFCONST "B38400",6,,B38400,(FCY/16/38400)
DEFCONST "B57600",6,,B57600,(FCY/16/57600)
DEFCONST "B115200",7,,B115200,(FCY/16/115200)
    
; nom: BAUD  ( u -- )     
;   Ajuste la vitesse du port s�riel et l'active.
; exemple:  
;   B57600 BAUD \ Le port est activ� � la vitesse � 57600 BAUD.    
; arguments:
;   u   Une des constantes pr�-difinies dont le nom commence par B.
; retourne:
;   rien   Le port est activ�.
DEFCODE "BAUD",4,,BAUD   ; ( u -- )
    call serial_disable
    mov T, SER_BRG
    DPOP
    call serial_enable
    NEXT

; nom: SPUTC   ( c -- )
;   Transmission d'un caract�re via le port s�riel. Au d�marrage le port est
;   activ� � la vitesse de 115200 BAUD, 8 bits, 1 stop, pas de parit�.    
; arguments:
;    c Caract�re � transmettre.
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
 
; nom: SGETC  ( -- c )
;   Attend un caract�re du port s�riel. Cette attente n'expire jamais.
; arguments:
;   aucun
; retourne:
;   c   Caract�re re�u du port s�riel.    
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
    bclr SER_RX_IEC,#SER_RX_IE
    dec rx_in
    bra nz,1f
    bclr ser_flags, #F_RXDAT
1:  bset SER_RX_IEC, #SER_RX_IE
    inc.b rx_head
    mov #(QUEUE_SIZE-1), W0
    and.b rx_head
    btss ser_flags,#F_RXSTOP
    bra 2f
    mov #(QUEUE_SIZE/4),W0
    cp.b rx_in
    bra gtu, 2f
    mov #CTRL_Q,W0
    mov.b WREG, SER_TXREG ; envoie XON
    bclr ser_flags,#F_RXSTOP
2:  NEXT

; nom: SREADY? ( -- f )
;  V�rifie si le terminal est pr�t � recevoir.
; arguments:
;    aucun
; retourne:
;    f Indicateur bool�en, vrai si le terminal pr�t � recevoir.
DEFCODE "SREADY?",7,,SREADYQ
    DPUSH
    clr T
    btss ser_flags,#F_TXSTOP
    setm T
    NEXT
    
; nom: SGETC? ( -- f )
;   V�rifie s'il y a un caract�re de disponible dans
;   la file de r�ception du port s�riel.
; arguments:
;    aucun    
; retourne:
;   f Indicateur bool�en, VRAI si un caract�re est disponible.
DEFCODE "SGETC?",6,,SGETCQ
    DPUSH
    clr T
    btsc ser_flags, #F_RXDAT
    setm T
9:  NEXT
    
    