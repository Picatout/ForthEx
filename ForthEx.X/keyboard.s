;****************************************************************************
; Copyright 2015, 2016,2017 Jacques Deschênes
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
;
; Fichier: keyboard.s
; Description: transcription code clavier PS/2 en ASCII
; Auteur: Jacques Deschênes
; Date: 2015-09-28
; REF: http://www.computer-engineering.org/ps2keyboard/scancodes2.html

.include "keyboard.inc"    
 
.equ KBD_QUEUE_SIZE, 32    
 
.section .keyboard.bss bss
 
.global kbd_queue, kbd_head    
kbd_queue:
.space KBD_QUEUE_SIZE    
kbd_head:
.space 2
kbd_tail:
.space 2

  
INTR ; section routines d'interruptions   
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; réception d'un caractère
; envoyé par le clavier
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
.global __U2RXInterrupt    
__U2RXInterrupt:
    bclr KBD_RX_IFS,#KBD_RX_IF
    push.d W0
    push.d W2
    mov KBD_RXREG,W0
    mov.b #VK_CTRL_C,W1
    cp.b W1,W0
    bra nz, 1f
    mov #USER_ABORT,W0
    mov W0, fwarm
    reset
; tranfert code dans file
; kbd_queue
1:  mov #kbd_queue, W1
    mov kbd_tail, W2
    add W2,W1,W1
    mov.b W0,[W1]
    add #1,W2
    and #(KBD_QUEUE_SIZE-1),W2
    mov W2, kbd_tail
    pop.d W2
    pop.d W0
    retfie
    
    
    



;;;;;;;;;;;;;;;;;;;;;;
; définitions Forth
;;;;;;;;;;;;;;;;;;;;;;    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialistaion interface clavier 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEADLESS KBD_INIT,CODE ; ( -- )
; configuration en sortie de la broche ~HRST
    bset KBD_RST_ODC, #KBD_RST_OUT ; KBD_RST_OUT doit-être open drain
    bclr KBD_RST_TRIS,#KBD_RST_OUT ; broche en sortie
    bclr KBD_RST_LAT, #KBD_RST_OUT ; maintient l'interface clavier en RESET
; configuration de l'entrée du signal ~REBOOT
; utilise une interruption externe
    ; PPS sélection broche associé à l'interruption
    mov #(KBD_RBT_RPI<<KBD_RBT_PPSbit),W0
    mov W0,KBD_RBT_RPINR
    bset KBD_RBT_INTCON,#KBD_RBT_INTEP ; interruption sur transition négative
    mov #(7<<KBD_RBT_IPCbit),W0 ; priorité d'interruption 7 (la plus haute)
    ior KBD_RBT_IPC
; configuration de l'entrée réception des codes du clavier    
    ; PPS sélection broche pour kbd_rx
    mov #(KBD_RX_RPI<<KBD_RX_PPSbit), W0
    mov W0,KBD_RX_RPINR
    ; baud rate 9600
    mov #(FCY/(16*9600)-1), W0
    mov W0, KBD_RX_BRG
    ; activation  8 bits, 1 stop, pas de paritée
    bset KBD_RX_MODE, #UARTEN
    ; configuration priorité interruption
    mov #~(7<<KBD_RX_IPCbit),W0
    and KBD_RX_IPC
    mov #(5<<KBD_RX_IPCbit),W0
    ior KBD_RX_IPC
    ; activation interruption rx clavier
    bclr KBD_RX_IFS, #KBD_RX_IF
    bset KBD_RX_IEC, #KBD_RX_IE
   ;activation interruption signal ~REBOOT
     bclr KBD_RBT_IFS, #KBD_RBT_IF
     bset KBD_RBT_IEC, #KBD_RBT_IE
    NEXT

; réiniatilise l'interface clavier    
HEADLESS KBD_RESET  ; ( -- )
    mov #250,W0
    add systicks,WREG
1:
    cp systicks
    bra neq, 1b
    bclr KBD_RST_LAT,#KBD_RST_OUT
    mov systicks,W0
    add W0,#3,W0
2:    
    cp systicks
    bra neq, 2b
    bset KBD_RST_LAT,#KBD_RST_OUT
    NEXT

; filtre le caractère dans T    
; accepte seulement
; VK_ENTER,VK_BKSP,VK_CLTRL_BACK, {32-126}
HEADLESS KEYFILTER,CODE  ; ( c|0 -- c|0 )
1:  cp T, #32
    bra ge, 7f
    cp T, #VK_RETURN
    bra eq, 9f
    cp T, #VK_BACK
    bra eq, 9f
    cp T, #VK_CTRL_BACK
    bra eq, 9f
    bra 8f
7:
    cp T, #127
    bra lt,9f
8:    
    clr T  
9:    
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; retourne le caractère
; en tête de file kbd_queue    
; retourne 0 si file vide.    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "GETKEY",6,,GETKEY   ; (  -- c|0 )  
    clr W0
    mov kbd_head, W1
    mov kbd_tail, W2
    cp  W1,W2
    bra eq, 1f
    mov #kbd_queue,W2
    add W1,W2,W2
    inc kbd_head
    mov #(KBD_QUEUE_SIZE-1), W0
    and kbd_head
    mov.b [W2], W0
    ze W0,W0
1:
    DPUSH
    mov W0,T
    NEXT

    
; lecture clavier sans attente.    
DEFWORD "?KEY",4,,QKEY  ; ( -- 0 | c T )
    .word GETKEY,KEYFILTER,DUP
    .word ZBRANCH,1f-$
    .word LIT,-1
1:  .word EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;
; attend une touche
; du clavier
;;;;;;;;;;;;;;;;;;;;;;;;    
DEFWORD "KEY",3,,KEY ; ( -- c)    
1:  .word QKEY,QDUP
    .word ZBRANCH,1b-$
    .word DROP,EXIT 
    

    