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
;     along with ForthEx.  If not, see <http:;www.gnu.org/licenses/>.
;
;****************************************************************************
;NOM: core.inc
;Description: définition de base pour le système Forth
;Date: 2015-10-03
 
.ifndef CORE_INC
.equ CORE_INC, 1
    
; utilisation des registres    
.equ RSP, W15 ; pile retours
.equ DSP, W14 ; pile arguments
;.equ R, W13 ; sommet pile retour
.equ T, W12 ; sommet pile arguments
.equ WP, W11 ; pointeur paramètres
.equ X, W10 ; pointeur d'adresse
.equ UP, W9  ; pointeur variables utilisateur
.equ IP, W8 ; pointeur d'instruction 
.equ I, W7  ; compteur de boucle    
    
.equ CELL_SIZE, 2
.equ DSTK_SIZE, 32*CELL_SIZE
.equ RSTK_SIZE, 64*CELL_SIZE

;offset variables utilisateurs
.equ RBASE, 0  ; adresse début pile retours
.equ PBASE, 2  ; adresse début pile paramètres
.equ BASE, 4   ; base numérique
.equ HERE, 6   ; valeur du pointeur HERE
.equ LATEST, 8 ; pointeur dernière définition    
.equ PAD, 10   ; pointeur vers PAD
    
;;;;;;;;;;;;    
; macros
;;;;;;;;;;;;
.macro NEXT
    mov [IP++], WP  ; WP=CFA, IP pointe vers item suivant
    mov [WP++], W0  ; W0= adresse code, WP=PFA
    goto W0         ; saut vers code routine
.endm    
 
.macro SET_EVEN reg
    btsc \reg, #0
    inc \reg, \reg
.endm
    
.macro DPUSH  
    mov T, [++DSP]
;    cp DSP, #RBASE
;    bra nz, .+4
;    reset
.endm
    
.macro DPOP
    mov [DSP--], T
.endm
    
.macro RPUSH reg
;    push R
;    mov \reg, R    
    push \reg
.endm
    
.macro RPOP reg
    pop \reg
;    mov R, \reg
;    pop R
.endm
    
.macro RDROP
    dec2 RSP,RSP
    ; pop R
.endm
    
.macro SYSDICT
    .section .sysdict psv
    .align 2
.endm
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; macros empruntée et modifiée, à partir de Jones Forth    
;REF: http:;www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt    

; Flags
.equ F_IMMED,0x80
.equ F_HIDDEN,0x20
.equ F_LENMASK,0x1f	; length mask

; Store the chain of links.
.equ link,0
;macro utilisée pour créer les entête des mots de haut niveaux.
.macro DEFWORD name, namelen, flags=0, label
    .section .sysdict psv
    .align 2
    .global name_\label
name_\label :
    .word link		; lien vers élément précédent du dictionnaire
    .equ link, name_\label
    .byte \flags+\namelen	; flags + length byte
    .ascii "\name"		; the name
    .align 2		; padding to next 2 byte boundary
    .global \label
\label :
    .word handle(DOCOLON)
	;pfa:  list of word pointers follow
.endm

; macro utilisée pour créer les entêtes des mots en code machine	
.macro DEFCODE name, namelen, flags=0, label
	.section .sysdict psv
	.align 2
	.global name_\label
name_\label :
	.word link		; link
	.set link,name_\label
	.byte \flags+\namelen	; flags + length byte
	.ascii "\name"		; the name
	.align 2		; padding to next 4 byte boundary
	.global \label
\label :
	.word handle(code_\label)	; codeword
	.text
	.global code_\label
code_\label :			;pfa,  assembler code follows
	
.endm
 
; macro utilisée pour créer des variables
.macro DEFVAR name, namelen, flags=0, label, initial=0
	DEFCODE \name,\namelen,\flags,\label
	DPUSH
	mov var_\name, T
	NEXT
	.data
	.align 2
var_\name :
	.word \initial
.endm

	
; macro utilisée pour créer des constantes
.macro DEFCONST name, namelen, flags=0, label, value
	DEFCODE \name,\namelen,\flags,\label
	DPUSH
	mov #\value, T
	NEXT
.endm

.endif
	
	