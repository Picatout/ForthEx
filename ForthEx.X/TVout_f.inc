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
; mot forth lié à TVout

.include "video.inc"
.include "keyboard.inc"
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; active/désactive sortie vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "VIDON",5,,VIDON ; ( f -- )  T=on F=off  
    mov T, W0
    mov.b WREG,video_on
    DPOP
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; active ou désactive le curseur texte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "CURENBL",7,,CURENBL  ; ( f -- )  T=active, F=désactive
    mov T, W0
    DPOP
    cp0 W0
    bra z, 1f
    call cursor_enable
    NEXT
1: ; désactive le clignotement 
    call cursor_disable
    NEXT
    
;;;;;;;;;;;;;;;;;;
; nettoie écran
;;;;;;;;;;;;;;;;;;
DEFCODE "CLS",3,,CLS   ; ( -- )
    cursor_incr_sema
    mov #0x2020, W0
    mov #_video_buffer, W1
    repeat #(TV_BUFFER_SIZE/2-1)
    mov W0,[W1++]
    clr xpos  ; xpos=0, ypos=0
    bclr.b fcursor,#CURSOR_INV
    cursor_decr_sema
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;
; glisse affichage vers le
; haut d'une ligne texte
; dernière ligne effacée
;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "SCRLUP",6,,SCRLUP  ; ( -- )
    call scroll_up
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; glisse affichage vers le
; bas d'une ligne texte
; première ligne effacée
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "SCRLDN",6,,SCRLDN  ; ( -- )
    call scroll_down
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;
; obtient la valeur
; de xpos
;;;;;;;;;;;;;;;;;;;;;
DEFCODE "GETX",4,,GETX ; ( -- n )
    DPUSH
    mov.b xpos, WREG
    mov W0,T
    ze T,T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;
; obtient la valeur
; de ypos
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "GETY",4,,GETY ; ( -- n )
    DPUSH
    mov.b ypos, WREG
    mov W0,T
    ze T,T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;
; définie position X
; du curseur texte
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SETX",4,, SETX  ; ( n -- )
    cursor_incr_sema
    cursor_sync
    mov #CPL-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
 1:
    mov.b WREG,xpos
    cursor_decr_sema
    DPOP
    NEXT

;;;;;;;;;;;;;;;;;;;;;;
; définie position Y
; du curseur texte
;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SETY",4,,SETY  ; ( n -- )
    cursor_incr_sema
    cursor_sync
    cp T, #LPS
    bra ltu, 1f
    mov #(LPS-1), T
1:
    mov T, W0
    mov.b WREG,ypos
    cursor_decr_sema
    DPOP
    NEXT
    
DEFWORD "CURPOS",6,,CURPOS  ; ( ny nx -- )
.word SETX, SETY, EXIT
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; déplace le curseur 1 caractère
; vers la gauche
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "LEFT",4,,LEFT ; ( -- )
    cursor_incr_sema
    cursor_sync
    dec.b xpos
    bra nn, 2f
    dec.b ypos
    bra nn, 1f
    call scroll_down
    clr.b ypos
1:
    mov #CPL,W0
    dec W0,W0
    mov.b WREG,xpos
2:
    cursor_decr_sema
    NEXT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; déplace le curseur 1 caractère
; vers la droite
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "RIGHT",5,,RIGHT  ; ( -- )
    cursor_incr_sema
    cursor_sync
    inc.b xpos
    mov #CPL, W0
    cp.b xpos
    bra ltu, 2f
    clr.b xpos
    inc.b ypos
    mov #LPS, W0
    cp.b ypos
    bra ltu, 2f
    call scroll_up
    dec.b ypos
2:    
    cursor_decr_sema
    NEXT

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; inverse le bit #7 du caractère 
; à la position du curseur
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "TGLCHAR",7,,TGLCHAR  ; ( -- )
    cursor_incr_sema
    cursor_sync
    call toggle_char
    cursor_decr_sema
    NEXT
    
    
;;;;;;;;;;;;;;;;;;;;;;
; place caractère 
; au sommet de la pile
; dans le buffer video    
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EMIT",4,,EMIT  ; ( c -- )
    cursor_incr_sema
    cursor_sync
    mov.b #CPL, W0
    mul.b ypos
    mov.b xpos, WREG
    ze W0,W0
    add W0,W2,W0
    mov #_video_buffer, W1
    add W0,W1,W1
    mov.b T, [W1]
    DPOP
    cursor_decr_sema
    bra code_RIGHT

;;;;;;;;;;;;;;;;;;;
; retour à la ligne
;;;;;;;;;;;;;;;;;;;;
DEFCODE "CR",2,,CR  ; ( -- )
    cursor_incr_sema
    cursor_sync
    mov #CPL-1,W0
    mov.b WREG,xpos
    cursor_decr_sema
    bra code_RIGHT

;;;;;;;;;;;;;;;;;;;;;;
; imprime un espace
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SPACE",5,,SPACE   ; ( -- )
    DPUSH
    mov #32, T
    bra code_EMIT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime n espaces
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "SPACES",6,,SPACES  ; ( n -- )
    .word DUP,LIT,0,GREATER,TBRANCH
    DEST spaces1
    .word DROP,EXIT
spaces1:    
    .word LIT,0,DODO
spaces0:
    .word SPACE,DOLOOP
    DEST spaces0
    .word EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface la ligne indiquée
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "CLRLN",5,,CLRLN    ; ( n -- )
    cursor_incr_sema
    cursor_sync
    mov #_video_buffer, W2
    mov #LPS, W0
    cp T, W0
    bra geu, 1f
    mov #CPL, W0
    mul.uu T, W0,W0
    add W0, W2,W2
    mov #0x2020, W0
    repeat #(CPL/2-1)
    mov W0, [W2++]
1:    
    cursor_decr_sema
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime une chaîne de
; caractère à l'écran
;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
.word DUP,TBRANCH
DEST type1
.word TWODROP, EXIT
type1:    
.word LIT, 0, DODO
type0:
.word  DUP, CFETCH, EMIT,ONEPLUS
.word DOLOOP
DEST type0
.word DROP, EXIT     

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface le caractère
; sous le curseur
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "DELETE",7,,DELETE  ; ( -- )
    .word BL,EMIT,EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;efface le carctère à gauche
; du curseur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "BACKCHAR",8,,BACKCHAR   ; ( -- )
    .word LEFT,DELETE,LEFT,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime l'entier au sommet de la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD ".",1,,DOT

.word    EXIT
    


