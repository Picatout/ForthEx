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
; Auteur: Jacques Desch�nes
; Date: 2015-09-28
; REF: http://www.computer-engineering.org/ps2keyboard/scancodes2.html
; DESCRIPTION: 
;    Interface mat�rielle entre le clavier PS/2 et la console LOCAL.
;    La majorit� des mots d�finis dans ce module n'ont pas d'ent�te dans
;    le dictionnaire ForthEx. Ils ne sont accessible qu'� travers la table
;    des fonctions de la console LOCAL.    

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
    mov.b W0,[W1+W2]
    inc W2,W2
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

    
; LC-EKEY? ( -- f )
;   V�rifie s'il y a un caract�re en attente dans la file du clavier et 
;   retourne un indicateur bool�en.
; arguments:
;   aucun
; retourne:
;   f   indicateur bool�en, vrai si la file n'est pas vide.
HEADLESS LCEKEYQ,CODE    
;DEFCODE "LC-EKEY?",8,,LCEKEYQ
    DPUSH
    mov kbd_head,W0
    sub kbd_tail,WREG
    mov W0,T
    NEXT
    
; PEEK-KEY ( -- c )
;   lit le caract�re en t�te de file sans l'extraire.
; arguments:
;   aucun
; retourne:
;   c Caract�re lu    
HEADLESS PEEK_KEY,CODE
    DPUSH
    mov kbd_head,W0
    mov #kbd_queue,W1
    mov.b [W1+W0],T
    ze T,T
    NEXT
    
; GETKEY ( -- c )
;   Extrait le caract�re en t�te de file.
; arguments;
;   aucun
; retourne:
;   rien
HEADLESS GETKEY,CODE
    DPUSH
    mov kbd_head,W0
    mov #kbd_queue,W1
    mov.b [W1+W0],T
    ze T,T
    inc W0,W0
    and #(QUEUE_SIZE-1),W0
    mov W0,kbd_head
    NEXT
    
    
; LC-EKEY  ( -- u )
;   Attend jusqu'� r�ception d'un code du clavier
;   retourne le premier code re�u.
; arguments:
;   aucun
; retourne:
;    u   code  VK_xxx non filtr� re�u du clavier.
HEADLESS LCEKEY,CODE    
;DEFCODE "LC-EKEY",7,,LCEKEY  
    call cursor_enable
    DPUSH
1:  mov kbd_tail, W0
    cp kbd_head
    bra z, 1b
    mov kbd_head,W0
    mov #kbd_queue,W1
    mov.b [W1+W0], T
    ze T,T
    inc kbd_head
    mov #(KBD_QUEUE_SIZE-1), W0
    and kbd_head
    call cursor_disable
    NEXT

    
;  LC-FILTER ( u -- u FALSE | c TRUE )    
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
HEADLESS LCFILTER,CODE    
;DEFCODE "LC-FILTER",9,,LCFILTER
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

    
; nom: ?PRTCHAR   ( n -- f )
;   V�rifie si  'n' est une caract�re imprimable dans l'intervalle {32..126}
;   et retourne un indicateur bool�en.
; arguments:
;    n	 Entier simple
; retourne:
;    f Indicateur bool�en, vrai si n &rarr; {32..126}  
DEFWORD "?PRTCHAR",8,,QPRTCHAR 
    .word DUP,BL,ULESS,TBRANCH,7f-$
    .word LIT,127,ULESS,ZBRANCH,8f-$
    .word TRUE,EXIT
7:  .word DROP
8:  .word FALSE,EXIT
  
;  LC-KEY? ( -- f)
;   V�rifie s'il y a un caract�re dans l'intervalle {32..126} disponible 
;   dans la file du clavier. S'il y a des caract�res non valides en d�but de file
;   ils sont jet�s.    
; arguments:
;   aucun
; retourne:
;   f   Indicateur bool�en, vrai s'il y a un caract�re valide en t�te de file.
HEADLESS LCKEYQ,HWORD
;DEFWORD "LC-KEY?",7,,LCKEYQ
1: .word LCEKEYQ,TBRANCH,2f-$,FALSE,EXIT
2: .word PEEK_KEY,QPRTCHAR,TBRANCH,8f-$
   .word GETKEY,DROP,BRANCH,1b-$
8: .word TRUE,EXIT   
    
;  LC-KEY  ( -- c )
;   Attend la r�ception d'un caract�re valide {32..126} du clavier.
; arguments:
;   aucun 
; retourne:
;   c   caract�re filtr�. 
HEADLESS LCKEY,HWORD 
;DEFWORD "LC-KEY",6,,LCKEY
    .word TRUE,CURENBL
1:  .word LCKEYQ,ZBRANCH,1b-$
    .word GETKEY,FALSE,CURENBL,EXIT 
    

    