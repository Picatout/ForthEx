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
; REF: http://www.computer-engineering.org/ps2keyboard/scancodes2.html

.include "hardware.inc"    
.include "video.inc"
.include "ps2.inc"
.include "keyboard.inc"    
.include "gen_macros.inc"
.include "core.inc"    
 
.equ KBD_QUEUE_SIZE, 32    
 
.data
kbd_queue:
.space KBD_QUEUE_SIZE    
kbd_head:
.space 2
kbd_tail:
.space 2
key_state:    
.space 2
 
;;;;;;;;;;;;;;;;;;;;;;;;;
; interruption TIMER1
; incrémente 'systicks'
; et traitement primaire
; file ps2_queue vers kbd_queue
;;;;;;;;;;;;;;;;;;;;;;;;;
.extern systicks
.extern ps2_head
.extern ps2_tail    
.extern ps2_queue  
INT    
.global __T1Interrupt   
__T1Interrupt:
    bclr IFS0, #T1IF
    push W0
    push W1
    push W2
    inc systicks
    cp0 tone_len
    bra z, 0f
    dec tone_len
    bra nz, 0f
    bclr AUDIO_TMRCON, #TON
0:    
    ;traitement file ps2_queue
    ;vers file kbd_queue
    mov ps2_head, W0
    cp ps2_tail
    bra z, isr_exit ; file ps2_queue vide
    mov #ps2_queue, W1
    add W0, W1, W1
    btss [W1], #10
    bra 9f ; rejet: stop bit doit-être 1
    mov [W1], W0
    lsr W0,W0
    bra c, 9f ; rejet: start bit doit-être zéro
    ;vérification paritée
    clr W1 ; compte les bits à 1
    mov #8, W2 ; test bits <8:0>
1:
    btst.c W0,W2
    addc #0, W1 
2:    
    dec W2,W2
    bra nn, 1b
    ; paritée impaire: W1 doit-être impaire.
    btss W1,#0
    bra 9f ; rejet: mauvaise parité
    and #255,W0
    ; vérifie code relâchement
    mov #SC_KREL, W1
    cp  W0,W1
    bra neq, 3f
    bset key_state, #F_KREL
    bra 9f
3:  ; vérifie code étendu
    mov #SC_XKEY, W1
    cp W0,W1
    bra neq, 4f
    bset key_state, #F_XKEY
    bra 9f
4:  
    ; vérification CTRL
    mov #L_CTRL,W1
    cp W1, W0
    bra neq, 5f
    bclr key_state, #F_CTRL
    btss key_state, #F_KREL
    bset key_state, #F_CTRL
    bclr key_state, #F_KREL
    bclr key_state, #F_XKEY
5:
    mov #SC_C, W1
    cp W1,W0
    bra neq, 8f
    btss key_state, #F_CTRL
    bra 8f
    clr W2
    repeat #17
    div.s W0,W2 ; génère une exception __MathError
8:    
    ; tranfert code dans file
    ; kbd_queue
    mov #kbd_queue, W1
    mov kbd_tail, W2
    add W2,W1,W1
    mov.b W0,[W1]
    add #1,W2
    and #(KBD_QUEUE_SIZE-1),W2 ; arg1 <#lit10>
    mov W2, kbd_tail
9:    
    ;incrémente ps2_head
    inc2 ps2_head
    mov #(PS2_QUEUE_SIZE-1), W0
    and ps2_head
isr_exit:
    pop W2
    pop W1
    pop W0
    retfie
    
.text
;ctrl_c_reset:
;    clr kbd_head
;    clr kbd_tail
;    clr ps2_head
;    clr ps2_tail
;    clr key_state
;    goto code_WARM
    
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
; si disponible sinon 0
; sortie: W0
;;;;;;;;;;;;;;;;;;;;;;; 
; Cette routine est complexe car une touche peut-être composée
; de plusieurs codes. 
; Lorsqu'une touche est relâchée son scancode est précédé du code 0xF0
; Certaines touches ont un scancode étendu, i.e. le premier code est 0xE0
; Lorsqu'une touche à code étendu est relaché il y a 3 codes envoyés
; par le clavier  0xE0, 0xF0 suivit du code de la touche.
; exemple touche <HOME>  lorsqu'elle est enfoncée le clavier envoie 0xE0,0x6C
; lorsqu'elle est relâchée le clavier envoie 0xE0,0xF0,0x6C
; référence scancode: http://www.computer-engineering.org/ps2keyboard/scancodes2.html    
; Le décodage est partiel sinon la routine serait encore plus complexe. 
; Les rela?hements de touches sont ignorés sauf pour <CTRL>,<ALT>,<SHIFT>     
.global kbd_get
kbd_get:
    push DSRPAG
    call get_code
    cp0 W0
    bra eq, kbd_no_key   
    mov W0,W1
    btss key_state, #F_KREL
    bra 3f
    btsc key_state, #F_XKEY
    bra try_xmod_key
    bra try_mod_key
3:    
    btss key_state, #F_XKEY
    bra try_shifted
    ; recherche table 'extended'
    set_eds_table extended, W2
    call search_table
    cp0 W0
    bra eq, try_xmod_key
    ; scancode trouvé dans la table 'extended'
    bra kbd_goodkey
try_xmod_key:
    set_eds_table xmod, W2
    call search_table
    cp0 W0
    bra eq, kbd_ignore_it
    bra mod_switch
try_shifted:  ; recherche table 'shifted'
    btss key_state, #F_SHIFT
    bra try_ascii
    set_eds_table shifted, W2
    call search_table
    cp0 W0
    bra nz, kbd_goodkey
try_ascii:  ; recherche table 'ascii'
    set_eds_table ascii, W2
    call search_table
    cp0 W0
    bra eq, try_mod_key
    ; scancode trouvé dans la table 'ascii'
    mov #'a', W1
    cp W0,W1
    bra ltu, kbd_goodkey
    mov #'z', W1
    cp W0, W1
    bra gtu, kbd_goodkey
    ;lettre
    btss key_state, #F_CAPS
    btg  W0, #5 
    btsc key_state, #F_SHIFT
    btg W0, #5
    bra kbd_goodkey
try_mod_key:
    set_eds_table mod, W2
    call search_table
    cp0 W0
    bra eq, kbd_ignore_it
mod_switch:
    mov #VK_SHIFT, W1
    cp W0,W1
    bra neq, 6f
    bclr key_state, #F_SHIFT
    btss key_state, #F_KREL
    bset key_state, #F_SHIFT
    bra kbd_ignore_it
6:
    mov #VK_CAPS, W1
    cp W0,W1
    bra neq, 7f
    btss key_state, #F_KREL
    btg key_state, #F_CAPS
    bra kbd_ignore_it
7:  
    mov #VK_CTRL, W1
    cp W0, W1
    bra neq, 8f
    bclr key_state, #F_CTRL
    btss key_state, #F_KREL
    bset key_state, #F_CTRL
    bra kbd_ignore_it
8:
    mov #VK_ALT, W1
    cp W0,W1
    bra neq, kbd_ignore_it
    bclr key_state, #F_ALT
    btss key_state, #F_KREL
    bset key_state, #F_CTRL
kbd_ignore_it:    
    clr W0
kbd_goodkey:  ; sortie touche acceptée
    bclr key_state, #F_KREL
    bclr key_state, #F_XKEY
kbd_no_key: ; sortie file vide
    pop DSRPAG
    return

;;;;;;;;;;;;;;;;;;;;;;
; définitions Forth
;;;;;;;;;;;;;;;;;;;;;;    
    
DEFCODE "?KEY",4,,QKEY  ; ( -- 0 | T c )
    call kbd_get
    DPUSH
    mov W0, T
    cp0 W0
    bra eq, 1f
    DPUSH
    setm T
1:    
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;
; attend une touche
; du clavier
;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "KEY",3,,KEY ; ( -- c)
0:
    call kbd_get
    cp0 W0
    bra z, 0b
    DPUSH
    mov W0, T
    NEXT
    
    
.end
    