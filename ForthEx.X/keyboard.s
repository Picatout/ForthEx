;****************************************************************************
; Copyright 2015, 2016,2017 Jacques Desch�nes
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
; Auteur: Jacques Desch�nes
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
; r�ception d'un caract�re
; envoy� par le clavier
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
.global __U2RXInterrupt    
__U2RXInterrupt:
    bclr KBD_RX_IFS,#KBD_RX_IF
    push.d W0
    push W2
    mov KBD_RXREG,W0
    cp.b W0,#CTRL_C
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
8:  pop W2
    pop.d W0
    retfie

    
;;;;;;;;;;;;;;;;;;;;;;
; d�finitions Forth
;;;;;;;;;;;;;;;;;;;;;;    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialisation interface clavier 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HEADLESS KBD_INIT,CODE ; ( -- )
; configuration en sortie de la broche ~HRST
    bset KBD_RST_ODC, #KBD_RST_OUT ; KBD_RST_OUT doit-�tre open drain
    bclr KBD_RST_TRIS,#KBD_RST_OUT ; broche en sortie
    bclr KBD_RST_LAT, #KBD_RST_OUT ; maintient l'interface clavier en RESET
; configuration de l'entr�e du signal ~REBOOT
; utilise une interruption externe
    ; PPS s�lection broche associ� � l'interruption
    mov #(KBD_RBT_RPI<<KBD_RBT_PPSbit),W0
    mov W0,KBD_RBT_RPINR
    bset KBD_RBT_INTCON,#KBD_RBT_INTEP ; interruption sur transition n�gative
    mov #(7<<KBD_RBT_IPCbit),W0 ; priorit� d'interruption 7 (la plus haute)
    ior KBD_RBT_IPC
; configuration de l'entr�e r�ception des codes du clavier    
    ; PPS s�lection broche pour kbd_rx
    mov #(KBD_RX_RPI<<KBD_RX_PPSbit), W0
    mov W0,KBD_RX_RPINR
    ; baud rate 9600
    mov #(FCY/(16*9600)-1), W0
    mov W0, KBD_RX_BRG
    ; activation  8 bits, 1 stop, pas de parit�e
    bset KBD_RX_MODE, #UARTEN
    ; configuration priorit� interruption
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

; r�iniatilise l'interface clavier    
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

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; nom: LC-EKEY? ( -- f )
;   V�rifie s'il y a un caract�re en attente
;   dans la file clavier et retourne un indicateur bool�en.
; arguments:
;   aucun
; retourne:
;   f   indicateur vrai|faux
DEFCODE "LC-EKEY?",8,,LCEKEYQ
    DPUSH
    clr T
    mov kbd_head,W0
    cp kbd_tail
    bra z, 9f
    com T,T
9:  NEXT
    
    
; nom: LC-EKEY  ( -- u )
;   Attend jusqu'� r�ception d'un code du clavier
;   retourne le premier code re�u.
; arguments:
;   aucun
; retourne:
;    u   code  VK_xxx non filtr� re�u du clavier.
DEFCODE "LC-EKEY",7,,LCEKEY  
    DPUSH
1:  mov kbd_tail, W0
    cp kbd_head
    bra z, 1b
    mov kbd_head,W0
    mov #kbd_queue,W1
    add W0,W1,W1
    inc kbd_head
    mov #(KBD_QUEUE_SIZE-1), W0
    and kbd_head
    mov.b [W1], T
    ze T,T
    NEXT

    
; nom: LC-FILTER ( u -- u FALSE | c TRUE )    
;   Filtre  et retourne un caract�re 'c' et 'vrai'
;   si u fait partie de l'ensemble reconnu.
;   sinon retourne 'u' et 'faux'   
;   accepte:
;      VK_CR, VK_BACK, CTRL_X, CTRL_V {32-126}
; arguments:
;   u    code � v�rifier
; retourne:
;   refus�:    
;   u       m�me code
;   FALSE   indicateur bool�en, valeur 0 
;   reconnu:
;   c       caract�re reconnu.
;   TRUE    indicateur bool�en, valeur -1
DEFCODE "LC-FILTER",9,,LCFILTER
    mov T,W0
    DPUSH
    setm T
    cp.b W0, #32
    bra ltu, 2f
    cp.b W0,#127
    bra ltu, 9f
2:  cp.b W0,#CTRL_L
    bra z, 9f
    cp.b W0, #VK_CR
    bra z, 9f
    cp.b W0, #VK_BACK
    bra z, 9f
    cp.b W0, #CTRL_D
    bra z, 9f
    cp.b W0, #CTRL_V
    bra z, 9f
    clr T  
9:    
    NEXT

    
; nom: LC-KEY? ( -- 0|c)
;   V�rifie s'il y a un caract�re r�pondant aux 
;   crit�res du filtre LC-FILTER disponible dans la file du clavier. 
;   S'il y a des caract�res non valides les jettes.    
; arguments:
;   aucun
; retourne:
;   0   aucun caract�re disponible
;   c   le premier caract�re valide de la file.    
DEFWORD "LC-KEY?",7,,LCKEYQ
1: .word LCEKEYQ,DUP,ZBRANCH,9f-$
   .word DROP,LCEKEY,LCFILTER,TBRANCH,9f-$
   .word DROP,BRANCH,1b-$
9: .word EXIT
    
; nom: LC-KEY  ( -- c )
;   Attend la r�ception d'un caract�re valide pour LC-FILTER du clavier.
; arguments:
;   aucun 
; retourne:
;   c   caract�re filtr�. 
DEFWORD "LC-KEY",6,,LCKEY
1:  .word LCKEYQ,QDUP
    .word ZBRANCH,1b-$
    .word EXIT 
    

    