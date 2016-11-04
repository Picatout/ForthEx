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
; active désactive sortie vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "VIDON",5,,VIDON ; ( f -- )    
    mov T, W0
    mov.b WREG,video_on
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;
; nettoie écran
;;;;;;;;;;;;;;;;;;
DEFCODE "CLS",3,,CLS   ; ( -- )
    mov #0x2020, W0
    mov #_video_buffer, W1
    repeat #(TV_BUFFER_SIZE/2-1)
    mov W0,[W1++]
    clr xpos  ; xpos=0, ypos=0
    NEXT

;;;;;;;;;;;;;;;;;;;;;;
; définie position X
; du curseur texte
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "XPOS",4,, XPOS  ; ( n -- )
    mov #CPL-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
 1:
    mov.b WREG,xpos
    DPOP
    NEXT

;;;;;;;;;;;;;;;;;;;;;;
; définie position Y
; du curseur texte
;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "YPOS",4,,YPOS  ; ( n -- )
    cp T, #LPS
    bra ltu, 1f
    mov #(LPS-1), T
1:
    mov T, W0
    mov.b WREG,ypos
    DPOP
    NEXT
    
DEFWORD "CURPOS",6,,CURPOS  ; ( ny nx -- )
.word XPOS, YPOS, EXIT
    
;;;;;;;;;;;;;;;;;;;;;;
; place caractère 
; au sommet de la pile
; dans le buffer video    
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EMIT",4,,EMIT  ; ( c -- )
    cp T,#VK_RETURN
    bra neq, 1f
    DPOP
    bra crlf
1:    
    mov.b #CPL, W0
    mul.b ypos
    mov.b xpos, WREG
    ze W0,W0
    add W0,W2,W0
    mov #_video_buffer, W1
    add W0,W1,W1
    mov.b T, [W1]
    DPOP
    inc.b xpos
    mov #CPL, W0
    cp.b xpos
    bra neq, 2f
crlf:    
    clr.b xpos
    mov #(LPS-1), W0
    cp.b ypos
    bra eq, code_SCROLLUP
    inc.b ypos
2:    
    NEXT

;;;;;;;;;;;;;;;;;;;
; retour à la ligne
;;;;;;;;;;;;;;;;;;;;
DEFCODE "CR",2,,CR  ; ( -- )
    bra crlf

;;;;;;;;;;;;;;;;;;;;;;
; imprime un espace
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SPACE",5,,SPACE   ; ( -- )
    DPUSH
    mov #32, T
    bra code_EMIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; défile écran vers le haut
; d'une ligne texte.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SCROLLUP",8,,SCROLLUP  ; ( -- )
    mov #_video_buffer, W1
    mov #CPL, W0
    add W0,W1,W2
    mov #TV_BUFFER_SIZE, W3
    sub W3,W0,W3
    lsr W3,W3
    dec W3,W3
    repeat W3
    mov [W2++],[W1++]
    DPUSH
    mov #(LPS-1), T
    bra code_CLRLN
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface la ligne indiquée
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "CLRLN",5,,CLRLN    ; ( n -- )
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
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime une chaîne de
; caractère à l'écran
;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
.word LIT, 0, DODO, DUP, CFETCH, EMIT, DOLOOP,-8,EXIT     

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime l'entier au sommet de la pile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD ".",1,,DOT

.word    EXIT
    


