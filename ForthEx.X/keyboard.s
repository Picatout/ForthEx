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
;
; Fichier: keyboard.s
; Description: transcription code clavier PS/2 en ASCII
; Auteur: Jacques Deschênes
; Date: 2015-09-28
;

.include "hardware.inc"    
.include "video.inc"
.include "ps2.inc"
.include "keyboard.inc"    
.include "gen_macros.inc"
    
 
.equ KBD_QUEUE_SIZE, 32    
 
.data
kbd_queue:
.space KBD_QUEUE_SIZE    
kbd_head:
.word 0
kbd_tail:
.word 0
key_state:    
.byte 0
    
.text

;;;;;;;;;;;;;;;;;;;;;;;
; retourne le code clavier
; dans W0 sinon retourne 0
;;;;;;;;;;;;;;;;;;;;;;;
.global get_code    
get_code:
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
    return

;;;;;;;;;;;;;;;;;;;;;;;;
; recherche code clavier
; dans la table
; entrée: W2=index table    
;         W1=scancode recherché
; sortie: W0 contient caractère
;         W0=0 si scancode pas dans la table
; modifie: W0,W2,W3    
;;;;;;;;;;;;;;;;;;;;;;;;;
search_table:
1:
    mov [W2++], W0
    cp0 W0
    bra eq, 2f
    mov W0, W3
    ze W3,W3
    cp W3,W1
    bra neq, 1b
    swap W0
    ze W0,W0
2: ; pas trouvé
    return

    
;;;;;;;;;;;;;;;;;;;;;;;
; retourne un caractère
; si disponible
; sortie: W0
;;;;;;;;;;;;;;;;;;;;;;;    
.global kbd_get

kbd_get:
    push PSVPAG
    call get_code
    cp0 W0
    bra eq, kbd_no_key   
    ;code clavier touche étendue?
    mov #SC_XKEY, W1
    cp W1,W0
    bra neq, 1f
    bset key_state, #F_XKEY
    call get_code
    cp0 W0
    bra eq, kbd_no_key
1:
    ;code clavier relâchement touche?
    mov #SC_KREL, W1
    cp W1, W0
    bra neq, 2f
    bset key_state, #F_KREL
    call get_code
    cp0 W0
    bra eq, kbd_no_key
2:
    mov W0,W1
    btss key_state, #F_XKEY
    bra try_shifted
    ; recherche table 'extended'
    set_psv extended, W2
    call search_table
    cp0 W0
    bra eq, try_shifted
    ; scancode trouvé dans la table 'extended'
    bra exit_goodkey
try_shifted:  ; recherche table 'shifted'
    btss key_state, #F_SHIFT
    bra try_ascii
    set_psv shifted, W2
    call search_table
    cp0 W0
    bra eq, try_ascii
    ; scancode trouvé dans la table 'shifted'
    bra exit_goodkey
try_ascii:  ; recherche table 'ascii'
    set_psv ascii, W2
    call search_table
    cp0 W0
    bra eq, try_ext_key
    ; scancode trouvé dans la table 'ascii'
    mov #'a', W1
    cp W0,W1
    bra ltu, exit_goodkey
    mov #'z', W1
    cp W0, W1
    bra gtu, exit_goodkey
    ;lettre
    btsc key_state, #F_KREL
    bra exit_ignore_it
    btss key_state, #F_CAPS
    btg  W0, #5 
    btsc key_state, #F_SHIFT
    btg W0, #5
    bra exit_goodkey
try_ext_key:
    set_psv extended, W2
    call search_table
    cp0 W0
    bra eq, try_mod_key
    bra exit_goodkey
try_mod_key:
    set_psv mod, W2
    call search_table
    cp0 W0
    bra eq, try_xmod_key
    bra mod_switch
try_xmod_key:
    set_psv xmod, W2
    call search_table
    cp0 W0
    bra eq, exit_ignore_it
mod_switch:
    mov #VK_SHIFT, W1
    cp W0,W1
    bra neq, 6f
    bclr key_state, #F_SHIFT
    btss key_state, #F_KREL
    bset key_state, #F_SHIFT
    bra exit_ignore_it
6:
    mov #VK_CAPS, W1
    cp W0,W1
    bra neq, 7f
    btss key_state, #F_KREL
    btg key_state, #F_CAPS
    bra exit_ignore_it
7:  
    mov #VK_CTRL, W1
    cp W0, W1
    bra neq, 8f
    bclr key_state, #F_CTRL
    btss key_state, #F_KREL
    bset key_state, #F_CTRL
    bra exit_ignore_it
8:
    mov #VK_ALT, W1
    cp W0,W1
    bra neq, exit_ignore_it
    bclr key_state, #F_ALT
    btss key_state, #F_KREL
    bset key_state, #F_CTRL
exit_ignore_it:    
exit_badkey: ;sortie touche refusée
    clr W0
exit_goodkey:  ; sortie touche acceptée
    bclr key_state, #F_KREL
    bclr key_state, #F_XKEY
kbd_no_key: ; sortie file vide
    pop PSVPAG
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;
; interruption TIMER1
; incrémente SYSTICK
; et traitement primaire
; file ps2_queue vers kbd_queue
;;;;;;;;;;;;;;;;;;;;;;;;;

.extern systicks
.extern ps2_head
.extern ps2_tail    
.extern ps2_queue  
    
.global __T1Interrupt   
__T1Interrupt:
    push W0
    push W1
    push W2
    push W3
    inc systicks
    mov ps2_head, W0
    cp ps2_tail
    bra z, isr_exit
    mov #ps2_queue, W1
    add W0, W1, W1
    mov [W1], W0
    lsr W0,W0
    bra c, 9f ; start bit doit-être zéro
    btst.c W0, #9
    bra nc, 9f ; stop bit doit-être 1
    clr W3
    and #0x1ff, W0
    mov #0, W2
1:
    btst.c W0,W2
    bra nc, 2f
    inc W3,W3
2:    
    inc W2,W2
    cp W2, #9
    bra neq, 1b
    ; paritée impaire, W3 doit-être impaire.
    btss W3,#0
    bra 9f
    mov #kbd_queue, W1
    mov kbd_tail, W2
    add W2,W1,W1
    mov.b W0,[W1]
    add #1,W2
    and #(KBD_QUEUE_SIZE-1),W2
    mov W2, kbd_tail
9:    
    ;incrémente ps2_head
    inc2 ps2_head
    mov #(PS2_QUEUE_SIZE-1), W0
    and ps2_head
isr_exit:
    pop W3
    pop W2
    pop W1
    pop W0
    bclr IFS0, #T1IF
    retfie
    
.end
    