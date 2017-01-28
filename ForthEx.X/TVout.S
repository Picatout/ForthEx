;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschenes
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
; vidéo NTSC B/W sur PIC24FJ64G002
; T2 période ligne horizontale
; OC1 sortie sync  sur RPB4
; OC2 contrôle début sortie vidéo
; sortie vidéo sur RPB3

    
.include "video.inc"
.if (VIDEO_STD==NTSC)
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
    
.section .tvout.bss bss

.global video_on, xpos,ypos    
line_count: .space 2
even: .space 1
video_on: .space 1
.align 2 
xpos: .space 1
ypos: .space 1


.global fcursor, cursor_dly , cursor_sema
cursor_dly: .space 2 ; contrôle vitesse clignotement
cursor_sema: .space 1 ; sémaphore 
fcursor: .space 1 ; indicateur booléens curseur texte
 
.align 2 
.global _video_buffer
_video_buffer: .space TV_BUFFER_SIZE
 

;********************
; interruption TIMER2
; synchronisation  vidéo  
;********************
INTR    
.global __T2Interrupt
__T2Interrupt:
    bclr SYNC_IFS, #SYNC_IF
    bclr VIDEO_SPISTAT, #SPIEN
    push W0
    inc line_count
    bra z, 2f
    mov #6, W0
    cp line_count
    bra z, 3f
    mov #12, W0
    cp line_count
    bra z, 4f
    mov #18, W0
    cp line_count
    bra z, 5f
    mov #TOPLINE, W0
    cp line_count
    bra z, 6f
    mov #TOPLINE+YRES, W0
    cp line_count
    bra z, 7f
    mov	 #FIELD_LINES, W0
    cp0.b even
    bra z, odd_field
    inc W0,W0
odd_field:    
    cp line_count
    bra neq, 1f
    com.b even
    setm line_count
1:
    pop W0
    retfie
2: ; line_count==0 start VSYNC 6 half line narrow neg. pulses
    mov #SERATION, W0
    mov W0, SYNC_OCR
    mov #HALFLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra 1b
3: ; line_count==6 , 6 half line large neg. pulses
    mov #(HALFLINE-SERATION), W0
    mov W0, SYNC_OCR
    bra 1b
4: ; line_count==12 , 6 half line narrow neg. pulses
    mov #SERATION, W0
    mov W0, SYNC_OCR
    bra 1b
5: ; line_count==18 , end of VSYNC
    mov #HSYNC, W0
    mov W0, SYNC_OCR
    mov #HLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra 1b
6: ; line_count==TOPLINE  activation interruption video
    cp0.b video_on
    bra z, 1b
    bclr VIDEO_IFS, #VIDEO_IF
    bset VIDEO_IEC, #VIDEO_IE
    bra 1b
7: ; line_count==TOPLINE+VIDEDO désactivaion int. video
    bclr VIDEO_IEC, #VIDEO_IE
    bra 1b

    
;*********************
; interruption OC2
; serialisation des pixels    
;*********************
.extern _font
.equ fINVERT, W6    
.equ CH_ROW, W5    
.equ pVIDBUF, W4
.equ pFONT, W3
.equ CH_COUNT, W2    
.global __OC2Interrupt    
__OC2Interrupt:
    bclr VIDEO_IFS, #VIDEO_IF
    push.D W0
    push.D CH_COUNT
    push.D pVIDBUF
    push fINVERT
    push DSRPAG
    movpag #edspage(_font),DSRPAG
    mov line_count, W1
    sub #TOPLINE, W1
    and  W1,#7,CH_ROW
    lsr W1,#3,W1
    mov #CPL, CH_COUNT
    mul.uu CH_COUNT,W1, W0
    mov #_video_buffer, pVIDBUF
    add W0, pVIDBUF, pVIDBUF
    mov #edsoffset(_font), pFONT
    mov VIDEO_TMR, W0
    and W0, #3, W0
    bra W0
    nop
    nop
    nop
    bset VIDEO_SPISTAT, #SPIEN
1:  cp0 CH_COUNT
    bra z, 3f
    mov.b [pVIDBUF++], W0
    clr fINVERT
    btsc W0,#7
    setm fINVERT
    and  #127,W0
    sl W0, #3, W0
    add pFONT,W0,W1
    add W1,CH_ROW, W1
    mov.b [W1],W0
    btsc fINVERT,#7
    com W0,W0
 2:
    btst VIDEO_SPISTAT, #SPITBF
    bra nz, 2b
    mov.b WREG,VIDEO_SPIBUF
    dec CH_COUNT,CH_COUNT
    bra 1b
3:   
    btst VIDEO_SPISTAT, #SPITBF
    bra nz, 3b
    clr VIDEO_SPIBUF
    pop DSRPAG
    pop fINVERT
    pop.D pVIDBUF
    pop.D CH_COUNT
    pop.D W0
    retfie

    
.text
.global cursor_blink, toggle_char, cursor_enable, cursor_disable
cursor_blink:
    dec cursor_dly
    bra z, 1f
    return
1:    
    mov #CURSOR_DELAY,W0
    mov W0,cursor_dly
    btg.b fcursor,#CURSOR_INV
toggle_char:
    cursor_incr_sema
    mov.b #CPL, W0
    mul.b ypos
    mov.b xpos, WREG
    ze W0,W0
    add W0,W2,W0
    mov #_video_buffer, W1
    add W0,W1,W1
    btg.b [W1],#7
    cursor_decr_sema
    return

cursor_enable:
    btsc.b fcursor,#CURSOR_ACTIVE
    return
    mov	#CURSOR_DELAY, W0
    mov W0, cursor_dly
    clr.b cursor_sema
    mov #1<<CURSOR_ACTIVE,W0
    mov.b WREG, fcursor
    return
    
cursor_disable:
    cursor_incr_sema
    btsc.b fcursor,#CURSOR_INV
    call toggle_char
    clr.b fcursor
    cursor_decr_sema
    return

.global scroll_up
scroll_up:
    cursor_incr_sema
    cursor_sync
    mov #_video_buffer, W1 ;destination
    mov #CPL, W0
    add W0,W1,W2  ; source
    mov #TV_BUFFER_SIZE, W3
    sub W3,W0,W3
    lsr W3,W3
    dec W3,W3
    repeat W3
    mov [W2++],[W1++]
    mov #0x2020,W0
    repeat #CPL/2-1
    mov W0, [W1++]
    cursor_decr_sema
    return
    
.global scroll_down    
scroll_down:
    cursor_incr_sema
    cursor_sync
    mov #_video_buffer, W1
    mov #TV_BUFFER_SIZE, W0
    add W1,W0,W1  ; W1 source
    mov #CPL,W0
    sub W1,W0,W2  ; W2 destination
    repeat #(TV_BUFFER_SIZE-CPL)/2-1
    mov [--W1],[--W2]
    mov 0x2020,W0
    repeat #CPL/2-1
    mov W0,[--W2]
    cursor_decr_sema
    return
 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots du système FORTH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialisation générateur vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;.global tvout_init
HEADLESS TVOUT_INIT, CODE ;tvout_init:
    bclr VIDEO_TRIS, #VIDEO_OUT ; sortie vidéo
    bclr SYNC_TRIS, #SYNC_OUT  ; sortie sync vidéo
    ; configuration PPS
    mov VIDEO_RPOR, W0
    mov #~(0x1f<<VIDEO_RPORbit),W1 ;mask
    and W0,W1,W0
    mov #(VIDEO_FN<<VIDEO_RPORbit), W1
    ior W0,W1,W0
    mov W0, VIDEO_RPOR
    mov SYNC_RPOR, W0
    mov #~(0x1f<<SYNC_RPORbit),W1 ;mask
    and W0,W1,W0
    mov #(SYNC_FN<<SYNC_RPORbit), W1
    ior W0,W1,W0
    mov W0, SYNC_RPOR
    ; configuration VIDEO_SPI
    mov #(3<<PPRE0)|(2<<SPRE0)|(1<<MSTEN),W0
    mov W0,VIDEO_SPICON1
    bset VIDEO_SPICON2, #SPIBEN
    ; configuration output compare
    mov #HLINE, W0
    ; période timer
    mov W0, SYNC_PER
    mov W0, SYNC_OCRS
    mov W0, VIDEO_OCR
    mov #HSYNC, W0
    mov W0, SYNC_OCR
    mov  #VIDEO_DLY, W0
    mov W0, VIDEO_OCRS
    ; configuraton output compare mode 5, clock=Fp
    mov #5|(7<<OCTSEL0), W0
    mov W0, SYNC_OCCON1
    mov W0, VIDEO_OCCON1
    ;configuration priorité d'interruptions
    ;priorité 5 pour les 2
    mov #~(7<<SYNC_IPbit), W0
    and SYNC_IPC
    mov #(5<<SYNC_IPbit), W0 
    ior SYNC_IPC
    mov #~(7<<VIDEO_IPbit), W0
    and VIDEO_IPC
    mov #(5<<VIDEO_IPbit), W0
    ior VIDEO_IPC
    setm line_count
    setm.b even
    setm.b video_on
    ; activation interruption  SYNC_TIMER
    bclr SYNC_IFS, #SYNC_IF
    bset SYNC_IEC, #SYNC_IE
    ; activation timer
    bset SYNC_TMRCON, #TON
    ; activation du curseur texte
    mov #CURSOR_DELAY,W0
    mov W0, cursor_dly
    clr.b cursor_sema
    bset fcursor, #CURSOR_ACTIVE
    bclr fcursor, #CURSOR_INV
    NEXT
    
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
DEFCODE "GETX",4,,GETX; ( -- n )
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
DEFCODE "SETX",4,, SETX ; ( n -- )
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
DEFCODE "CR",2,,CR ; ( -- )
    cursor_incr_sema
    cursor_sync
    mov #CPL-1,W0
    mov.b WREG,xpos
    cursor_decr_sema
    bra code_RIGHT

;;;;;;;;;;;;;;;;;;;;;;
; imprime un espace
;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "SPACE",5,,SPACE ; ( -- )
    DPUSH
    mov #32, T
    bra code_EMIT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime n espaces
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "SPACES",6,,SPACES ; ( n -- )
    .word DUP,LIT,0,GREATER,TBRANCH,spaces1-$
    .word DROP,EXIT
spaces1:    
    .word LIT,0,DODO
spaces0:
    .word SPACE,DOLOOP,spaces0-$
    .word EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface la ligne indiquée
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "CLRLN",5,,CLRLN   ; ( n -- )
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
.word DUP,TBRANCH,type1-$
.word TWODROP, EXIT
type1:    
.word LIT, 0, DODO
type0:
.word  DUP, CFETCH, EMIT,ONEPLUS
.word DOLOOP,type0-$
.word DROP, EXIT     

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface le caractère
; sous le curseur
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "DELETE",6,,DELETE  ; ( -- )
    .word BL,EMIT,EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;efface le carctère à gauche
; du curseur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "BACKCHAR",8,,BACKCHAR   ; ( -- )
    .word LEFT,DELETE,LEFT,EXIT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; routines pour la conversion
; d'un entier en chaîne
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; convertion d'un chiffre en caractère    
DEFWORD "DIGIT",5,,DIGIT ; ( u -- c )
    .word LIT,9,OVER,LESS,LIT,7,AND,PLUS,LIT,48,PLUS
    .word EXIT

; extrait le chiffre le moins significatif
; et le convertie en caractère    
DEFWORD "EXTRACT",7,,EXTRACT ; ( n1 base -- n2 c )     
    .word LIT,0,SWAP,UMSLASHMOD,SWAP,DIGIT,EXIT
    
;débute la conversion
;en initialisant la variable HP    
DEFWORD "<#",2,,LTSHARP ; ( -- )
    .word PAD,FETCH,PADSIZE,PLUS,HP,STORE
    .word EXIT
    
;met le caractère dans T au
; début de la chaîne de conversion
DEFWORD "HOLD",4,,HOLD ; ( c -- )
    .word LIT,-1,HP,PLUSSTORE
    .word HP,FETCH,CSTORE
    .word EXIT

;converti un digit
DEFWORD "#",1,,SHARP ; ( n1 -- n2 )
    .word BASE,FETCH,EXTRACT,HOLD,EXIT

;converti tous les digits
DEFWORD "#S",2,,SHARPS ; ( n1 -- 0 )
1:  .word SHARP,DUP,TBRANCH,1b-$,EXIT
  
;ajoute le signe au début de la chaîne numérique
DEFWORD "SIGN",4,,SIGN ; ( n -- )
    .word ZEROLT,ZBRANCH,1f-$
    .word CLIT,'-',HOLD
1:  .word EXIT
  
;termine la conversion en ajoutant la longueur
;de la chaîne au début de celle-ci.
DEFWORD "#>",2,,SHARPGT ; ( w -- addr u )
  .word DROP,HP,FETCH,PAD,FETCH,OVER,MINUS, EXIT
  
; convertions entier en chaîne
DEFWORD "STR",3,,STR ; ( n -- addr u )
  .word DUP,TOR,ABS,LTSHARP,SHARPS,RFROM,SIGN,SHARPGT,EXIT
  
; imprime un nombre dans un colonne de largeur fixe
; aligné à droite
DEFWORD ".R",2,,DOTR  ; ( n +n -- ) +n est la largeur de la colonne
  .word TOR, STR, RFROM,OVER,MINUS,SPACES,TYPE,EXIT
  
; imprime un nombre non sigé dans une colonne de 
; largeur fixe, aligné à droite
DEFWORD "U.R",3,,UDOTR ; ( u +n -- )
  .word TOR,LTSHARP,SHARPS,SHARPGT,RFROM,OVER
  .word MINUS,SPACES,TYPE,EXIT
  
; imprime un nombre non signé en format libre
DEFWORD "U.",2,,UDOT ; ( n -- )
UD:  .word LTSHARP,SHARPS,SHARPGT,SPACE,TYPE,EXIT
  
; imprime un nombre en format libre
DEFWORD ".",1,,DOT ; ( n -- )
  .word BASE,FETCH,LIT,10,XOR,TBRANCH, UD-$
  .word SPACE,STR,EXIT
  
; imprime le contenu d'une adresse
DEFWORD "?",1,,QUESTION ; ( addr -- )
  .word FETCH,DOT,EXIT
  
  

;.end

