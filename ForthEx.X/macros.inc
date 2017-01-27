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

;Fichier: macros.inc
;Description:  définition de macros utilisées par le projet
;Date: 2015-10-02
.ifndef MACROS
.equ MACROS, 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    MACHINE VIRTUELLE    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  un programme pour la machine virtuelle
;  consiste en une liste d'adresse pointé par IP
;  fonctionnement de la machine virtuelle
;   consiste en une boucle de 3 instructions    
;	mov [IP++],W0
;	call W0
;	bra $-4
;   chaque mot code doit donc se terminer par
;   l'instruction 'return'
;   Si une intruction de la VM a besoin de données
;   litérales celle-ci suivent l'adresse de son appel
;   dans le flux du programme. Donc IP doit-être 
;   avancé après ces données litérales avant la sortie
;   de l'instruction VM.    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; utilisation des registres
; par la machine virtuelle
;;;;;;;;;;;;;;;;;;;;;;;;;;;        
.equ RSP, W15 ; pointeur pile retours
.equ DSP, W14 ; pointeur pile arguments
.equ T, W13   ; sommet pile arguments
.equ WP, W12  ;  pointeur paramètres
.equ UP, W11  ; pointeur _USER_VARS
.equ IP, W10  ; pointeur d'instruction machine virtuelle
.equ I, W9    ; compteur de boucle    
.equ LIMIT,W8 ; limite des boucles
    
    
.equ CELL_SIZE, 2  ; 2 octets
.equ DSTK_SIZE, 32*CELL_SIZE  ; dimension pile arguments
.equ RSTK_SIZE, 64*CELL_SIZE  ; dimension pile des retours
.equ RSTK_GUARD, 24 ; réserve 16 octets pour les interrupts et exceptions    
.equ TIB_SIZE, 80   ; Terminal Input Buffer,  80 octets
.equ PAD_SIZE, 80   ; scratch pad, 80 octets
.equ USER_BASE, 0x1900 ; début espace utilisateur
    
;;;;;;;;;;;;    
; macros
;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; interpréteur interne
; exécute l'instruction suivante
; de la machine virtuelle 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
.macro NEXT
    mov [IP++], WP  ; WP=CFA, IP pointe vers item suivant
    mov [WP++], W0  ; W0= adresse code, WP=PFA
    goto W0         ; saut vers code routine
.endm    
 
; aligment sur adresse paire
; valeur registre    
.macro SET_EVEN reg
    btsc \reg, #0
    inc \reg, \reg
.endm

; empile le registre T
; sur la pile des arguments
.macro DPUSH  
    mov T, [++DSP]
;    cp DSP, #RBASE
;    bra nz, .+4
;    reset
.endm

; dépile la pile des arguments
; dans T    
.macro DPOP
    mov [DSP--], T
.endm

; empile un registre
; sur la pile des retours    
.macro RPUSH reg
    push \reg
.endm

; dépile la pile des retourne
; vers le registre    
.macro RPOP reg
    pop \reg
.endm

; jette le sommet de la
; pile des retours
.macro RDROP
    dec2 RSP,RSP
.endm

; section dictionnaire système 
.macro SYSDICT
    .section .sysdict psv
    .align 2
.endm

; section de code FORTH 
.macro FORTH_CODE
    .section .forth_code.text code
.endm
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; macros inspirées par JonesForth et CamelForth   
;REF: http:;www.eecs.wsu.edu/~hauser/teaching/Arch-F07/handouts/jonesforth.s.txt    
;REF: http://www.camelforth.com/news.php    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; Flags
.equ F_IMMED,0x80
.equ F_HIDDEN,0x20
.equ F_LENMASK,0x1f	; length mask

;macro pour la création des entêtes de dictionnaire
.macro HEADER name,namelen,flags=0,label
	.print "\label"
	SYSDICT
	.global lfa_\label
lfa_\label :  
	.word 0b ; link
0:	.byte \flags+\namelen	; NFA flags + length byte
	.ascii "\name"		; the name
	.align 2		; padding to word boundary
	.global \label
\label :
.endm
	
;macro utilisée pour créer les entête des mots de haut niveaux.
.macro DEFWORD name, namelen, flags=0, label
	HEADER "\name",\namelen,\flags,\label
	.word ENTER
	;pfa:  liste des paramètres
.endm

; macro utilisée pour créer les entêtes des mots en code machine	
.macro DEFCODE name, namelen, flags=0, label
	HEADER "\name",\namelen,\flags,\label
	.word code_\label	; codeword
	FORTH_CODE
	.global code_\label
code_\label :	;point d'entrée du code assembleur
.endm

.equiv CODE,1  ; mot code
.equiv HWORD,2 ; mot haut niveau
    
	
; macro utilisé pour créer les mots sans entête de dictionnaire
.macro HEADLESS label, type=CODE
	.print "\label"
	SYSDICT
	.global \label
\label :
	.if ( \type == CODE )
	.word code_\label
	FORTH_CODE
	.global code_\label
code_\label :
        .else
	.word ENTER
	.endif
	
.endm
    
	
; macro utilisée pour créer des variables
.macro DEFVAR name, namelen, flags=0, label
	HEADER "\name",\namelen,\flags,\label
        .word DOUSER
;pfa:  paramètres
	.word _\label-_USER_VARS 
.endm

	
; macro utilisée pour créer des constantes
.macro DEFCONST name, namelen, flags=0, label, value
	DEFCODE "\name",\namelen,\flags,\label
	DPUSH
	mov #\value, T
	NEXT
.endm

    
; initialisation table en flash
; pour lecture
.macro set_eds_table table, reg
    movpag #edspage(\table), DSRPAG
    mov #edsoffset(\table), \reg
.endm

; case select macro W0 contient la valeur de contrôle
.macro case value, target
    xor W0, #\value
    bra nz, 1f
    bra \target
1:  xor W0, #\value
.endm    
    
.endif

