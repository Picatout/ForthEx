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
 .global _htab
_htab: .space 1 ; largeur tabulation

.align 2
.global fcursor, cursor_dly , cursor_sema
cursor_dly: .space 2 ; contrôle vitesse clignotement
cursor_sema: .space 1 ; sémaphore 
fcursor: .space 1 ; indicateur booléens curseur texte
 
.section .tvout.buffer.bss bss address(RAM_END-VIDEO_BUFF_SIZE)
.global _video_buffer
_video_buffer: .space VIDEO_BUFF_SIZE
 

.equ OC4IFS,IFS1 
.equ OC4IEC,IEC1
.equ OC4IPC,IPC6
 
;********************
; interruption TIMER2
; synchronisation  vidéo  
;********************
INTR    
.global __T2Interrupt
__T2Interrupt:
    bclr SYNC_IFS, #SYNC_IF
    bset VIDEO_BLKLEVEL_TRIS,#VIDEO_BLKLEVEL_OUT
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
    mov #17,W0
    cp line_count
    bra z, even2
    mov #18, W0
    cp line_count
    bra z, 5f
    mov #29,W0
    cp line_count
    bra z, 8f
    mov #TOPLINE, W0
    cp line_count
    bra z, 6f
    mov #TOPLINE+YRES, W0
    cp line_count
    bra z, 7f
    mov	 #FIELD_LINES, W0
    cp line_count
    bra neq, 1f
    cp0.b even
    bra nz, even1
    mov #HALFLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
even1:    
    com.b even
    setm line_count
1:
    pop W0
    retfie
even2:
    cp0.b even
    bra z, 1b
    mov #HLINE,W0
    mov W0,SYNC_OCRS
    mov W0,SYNC_PER
    bra 1b
2: ; line_count==0 start VSYNC 6 half line narrow neg. pulses
    bclr OC4IEC,#OC4IE
    mov #SERATION, W0
    mov W0, SYNC_OCR
    mov #HALFLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra 1b
3: ; line_count==6 , 6 half line large neg. pulses
    mov #(HALFLINE-HSYNC), W0
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
8:  
    bclr OC4IFS,#OC4IF
    bset OC4IEC,#OC4IE
    bra 1b
    
; début seuil niveau noir    
.global __OC4Interrupt    
__OC4Interrupt:
    bclr OC4IFS,#OC4IF
    bclr VIDEO_BLKLEVEL_TRIS,#VIDEO_BLKLEVEL_OUT
    retfie
    
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
    movpag #1,DSRPAG
    mov.b [pVIDBUF++], W0
    clr fINVERT
    btsc W0,#7
    setm fINVERT
    and  #127,W0
    sl W0, #3, W0
    add pFONT,W0,W1
    add W1,CH_ROW, W1
    movpag #edspage(_font),DSRPAG
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
    push W0
    mov #CURSOR_DELAY,W0
    mov W0,cursor_dly
    btg.b fcursor,#CURSOR_INV
    pop W0 ; attention toggle_char est un point d'entré!!
toggle_char:
    push.d W0
    push W2
    SET_EDS
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
    RESET_EDS
    pop W2
    pop.d W0
    return

cursor_enable:
    push W0
    btsc.b fcursor,#CURSOR_ACTIVE
    return
    mov	#CURSOR_DELAY, W0
    mov W0, cursor_dly
    clr.b cursor_sema
    mov #1<<CURSOR_ACTIVE,W0
    mov.b WREG, fcursor
    pop W0
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
    push.d W0
    push.d W2
    SET_EDS
    cursor_incr_sema
    cursor_sync
    mov #_video_buffer, W1 ;destination
    mov #CPL, W0
    add W0,W1,W2  ; source
    mov #VIDEO_BUFF_SIZE, W3
    sub W3,W0,W3
    lsr W3,W3
    dec W3,W3
    repeat W3
    mov [W2++],[W1++]
    mov #0x2020,W0
    repeat #CPL/2-1
    mov W0, [W1++]
    cursor_decr_sema
    RESET_EDS
    pop.d W2
    pop.d W0
    return
    
.global scroll_down    
scroll_down:
    push.d W0
    push W2
    SET_EDS
    cursor_incr_sema
    cursor_sync
    mov #_video_buffer, W1
    mov #VIDEO_BUFF_SIZE, W0
    add W1,W0,W1  ; W1 destination
    mov #CPL,W0
    sub W1,W0,W2  ; W2 source
    repeat #(VIDEO_BUFF_SIZE-CPL)/2-1
    mov [--W2],[--W1]
    mov 0x2020,W0
    repeat #CPL/2-1
    mov W0,[--W1]
    cursor_decr_sema
    RESET_EDS
    pop W2
    pop.d W0
    return
 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots du système FORTH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; adresse du buffer d'écran    
DEFCONST "SCRBUF",6,,SCRBUF,_video_buffer
; adresse de la variable
; contenant la largeur des tabulations.    
DEFCONST "HTAB",4,,HTAB,_htab
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialisation générateur vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;.global tvout_init
HEADLESS TVOUT_INIT, CODE ;tvout_init:
    bclr VIDEO_TRIS, #VIDEO_OUT ; sortie vidéo
    bclr SYNC_TRIS, #SYNC_OUT  ; sortie sync vidéo
    bset VIDEO_BLKLEVEL_LAT,#VIDEO_BLKLEVEL_OUT
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
    mov #2*HSYNC,W0
    mov W0,OC4RS
    mov #HSYNC,W0
    mov W0, OC4R
    mov #5|(7<<OCTSEL0), W0
    mov W0,OC4CON1
    bset OC4CON2,#OCTRIS
    mov #~(7<<OC4IP0),W0
    and OC4IPC
    mov #(5<<OC4IP0),W0
    ior OC4IPC
    mov.b #4,W0 ; largeur tabulation
    mov.b _htab
    bra code_CLS
    
; nom: VIDEO  ( f -- ) \ T=on F=off 
;   active/désactive sortie vidéo
; arguments:
;    f indicateur booléen VRAI active la sortie vidéo, FAUX la désactive 
; retourne:
;   rien    
DEFCODE "VIDEO",5,,VIDEO   
    mov T, W0
    mov.b WREG,video_on
    DPOP
    NEXT

; nom: CURENBL   ( f -- ) \ T=active, F=désactive
;  active ou désactive le curseur texte
; arguments:
;   f   indicateur booléen,VRAI active le curseur, FAUX le désactive.
; retourne:    
;   rien
DEFCODE "CURENBL",7,,CURENBL 
    mov T, W0
    DPOP
    cp0 W0
    bra z, 1f
    call cursor_enable
    NEXT
1: ; désactive le clignotement 
    call cursor_disable
    NEXT
    
; nom: CLS  ( -- )
;   vide l'écran.
; arguments:    
;   aucun
; retourne:    
;   rien
DEFCODE "CLS",3,,CLS
    cursor_incr_sema
    mov #0x2020,W0
    mov #_video_buffer, W1
    repeat #(VIDEO_BUFF_SIZE/2-1)
    mov W0, [W1++]
    clr xpos  ; xpos=0, ypos=0
    bclr.b fcursor,#CURSOR_INV
    cursor_decr_sema
    NEXT

; nom: SCRLUP  ( -- )
;   glisse affichage vers le
;   haut d'une ligne texte
;   dernière ligne effacée.
; arguments:
;   aucun
; retourne:    
;   rien
DEFCODE "SCRLUP",6,,SCRLUP
    call scroll_up
    NEXT

; nom: SCRLDN  ( -- )
;   glisse affichage vers le
;   bas d'une ligne texte
;   première ligne effacée.
; arguments:
;   aucun
; retourne:    
;   rien
DEFCODE "SCRLDN",6,,SCRLDN 
    call scroll_down
    NEXT
    
; nom: GETX ( -- u )
;   retourne la colonne du curseur texte.
; arguments:
;   aucun
; retourne:    
;   u    colonne du curseur    
DEFCODE "GETX",4,,GETX
    DPUSH
    mov.b xpos, WREG
    mov W0,T
    ze T,T
    NEXT
    
; nom: GETY  ( -- u )
;   retourne la ligne du curseur.
; arguments:
;   aucun
; retourne:    
;   u    ligne du curseur    
DEFCODE "GETY",4,,GETY
    DPUSH
    mov.b ypos, WREG
    mov W0,T
    ze T,T
    NEXT
    
; nom: SETX
;  Positionne le curseur texte à la colonne u.
; arguments:
;    u   colonne.
; retourne:    
;    rien
DEFCODE "SETX",4,, SETX ; ( u -- )
    cursor_incr_sema
    cursor_sync
    mov #CPL-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
1:  mov.b WREG,xpos
    cursor_decr_sema
    DPOP
    NEXT

; nom: SETX
;  Positionne le curseur texte à la ligne u.
; arguments:
;    u   ligne
; retourne:    
;    rien
DEFCODE "SETY",4,,SETY  ; ( u -- )
    cursor_incr_sema
    cursor_sync
    mov #LPS-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
1:  mov.b WREG,ypos
    cursor_decr_sema
    DPOP
    NEXT

; nom: CURADR  ( -- c-addr )
;  Retourne l'adresse dans le buffer d'écran correspondant
;  à la position actuelle du curseur
; arguments:
;   aucun
; retourne
;   c-addr   addresse buffer du curseur    
DEFCODE "CURADR",6,,CURADR
    DPUSH
    mov #_video_buffer,T
    mov #CPL,W0
    mul.b ypos
    add W2,T,T
    mov.b xpos,WREG
    ze W0,W0
    add T,W0,T
    NEXT
    
    
; nom: CURPOS  ( u1 u2 -- )
;  positionne le curseur texte à la colonne u1 et la ligne u2
; arguments:
;    u1    colonne
;    u2    ligne
; retourne:
;   rien    
DEFWORD "CURPOS",6,,CURPOS  ; ( u1 u2 -- )
    .word SETY, SETX, EXIT

; nom: SCRCHAR  ( -- c )    
;   retourne le caractère à la position du curseur
; arguments:
;   aucun
; retourne:
;   c   caractère à la position du curseur.    
DEFCODE "SCRCHAR",7,,SCRCHAR ; ( -- c )
    SET_EDS
    mov.b ypos,WREG
    ze W0,W0
    mov #CPL,W1
    mul.uu W0,W1,W0
    exch W0,W1
    mov.b xpos,WREG
    ze W0,W0
    add W0,W1,W0
    DPUSH
    mov #_video_buffer,W1
    add W1,W0,W0
    mov.b [W0],T
    ze T,T
    bclr T,#7
    RESET_EDS
    NEXT

; nom: CHR>SCR  ( x y c -- )    
;   Met le caractère c la position x,y de l'écran.
; arguments:
;   x colonne
;   y ligne
;   c caractère    
; retourne:
;   rien    
DEFCODE "CHR>SCR",7,,CHRTOSCR
    cursor_incr_sema
    cursor_sync
    mov [DSP--],W0
    ze W0,W0
    mov #CPL,W1
    mul.uu W0,W1,W0
    mov [DSP--],W1
    ze W1,W1
    add W0,W1,W0
    mov #_video_buffer,W1
    add W1,W0,W0
    mov.b T,[W0]
    DPOP
    cursor_decr_sema
    NEXT
    
; nom: INVLN  ( n f -- )    
; inverse ligne écran
; arguments:
;   n   no. de ligne {0..23}
;   f   TRUE -> inverse vidéo, FALSE -> vidéo normal
; retourne:
;   rien    
DEFCODE "INVLN",5,,INVLN
    SET_EDS
    mov #CPL,W0
    mov [DSP--],W1
    ze W1,W1
    mul.uu W0,W1,W0
    mov #_video_buffer,W1
    add W1,W0,W0
    cp0 T
    bra z, normal_video
    repeat #CPL-1
    bset.b [W0++],#7
    bra 9f
normal_video:
    repeat #CPL-1
    bclr.b [W0++],#7
9:  RESET_EDS
    DPOP
    NEXT
    
    
; nom: LC-LEFT  ( -- )
;   Déplace le curseur 1 caractère vers la gauche.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "LC-LEFT",7,,LCLEFT
    cursor_incr_sema
    cursor_sync
    cp0.b xpos
    bra z,2f
    dec.b xpos
2:
    cursor_decr_sema
    NEXT
    
    
; nom: LC-RIGHT  ( -- )
;   Déplace le curseur 1 caractère vers la droite.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "LC-RIGHT",8,,LCRIGHT
    cursor_incr_sema
    cursor_sync
    mov #CPL-1,W0
    cp.b xpos
    bra z,2f
    inc.b xpos
2:    
    cursor_decr_sema
    NEXT


; nom: LC-HOME  ( -- )
;   Déplace le curseur au début de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
DEFCODE "LC-HOME",7,,LCHOME
    cursor_incr_sema
    cursor_sync
    clr.b xpos
    cursor_decr_sema
    NEXT
    
; nom: LC-END  ( -- )
;   Déplace le curseur après le dernier caractère de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LC-END",6,,LCEND
    .word FALSE,CURENBL
    .word CURADR,LIT,63,DUP,INVERT,ROT,AND ; S: 63 _video_buffer+cpl*ypos
1:  .word TWODUP,PLUS,ECFETCH,BL,EQUAL,ZBRANCH,4f-$ ; S: 63 c-addr
    .word SWAP,ONEMINUS,DUP,ZBRANCH,2f-$
    .word SWAP,BRANCH,1b-$
2:  .word SETX,DROP,BRANCH,8f-$
4:  .word DROP,SETX,LCRIGHT
8:  .word TRUE,CURENBL  
    .word EXIT
    
    
; nom: LC-UP   ( -- )
;  déplace le curseur d'une ligne vers le haut.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "LC-UP",5,,LCUP
    cursor_incr_sema
    cursor_sync
    cp0.b ypos
    bra z, 9f
    dec.b ypos
9:  cursor_decr_sema
    NEXT

; nom: LC-DOWN   ( -- )
;  déplace le curseur d'une ligne vers le bas.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "LC-DOWN",6,,LCDOWN
    cursor_incr_sema
    cursor_sync
    mov #LPS-1,W0
    cp.b ypos
    bra z, 9f
    inc.b ypos
9:  cursor_decr_sema
    NEXT
    
    
; nom: TGLCHAR  ( -- )
;   inverse le bit #7 du caractère à la position du curseur.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "TGLCHAR",7,,TGLCHAR 
    cursor_incr_sema
    cursor_sync
    call toggle_char
    cursor_decr_sema
    NEXT
    
; nom: PUTC  ( c -- )
;   Affiche le caractère à la position du curseur et avance
;   le curseur vers la droite. Si le curseur est en fin de ligne
;   passe au début de la ligne suivante sauf si c'est la dernière ligne
;   de l'affichage.    
; arguments:
;   c   caractère à afficher
; retourne:
;   rien    
DEFCODE "PUTC",4,,PUTC 
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
    mov #(CPL-1),W0
    cp.b xpos
    bra z, 2f
    inc.b xpos
    bra 9f
2:  clr.b xpos
    mov #(LPS-1),W0
    cp.b ypos
    bra z,8f
    inc.b ypos
    bra 9f
8:  call scroll_up
9:  cursor_decr_sema
    NEXT
    
; nom: CR ( -- )
; Envoie le curseur au début de la ligne suivante défile l'écran
; vers le haut si nécessaire.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "CR",2,,CR 
    cursor_incr_sema
    cursor_sync
    clr.b xpos
    mov #(LPS-1),W0
    cp.b ypos
    bra z, 2f
    inc.b ypos
    bra 9f
2:  call scroll_up    
9:  cursor_decr_sema
    NEXT


; nom: NEXT-COLON  ( -- )    
;   avance le curseur à la prochaine tabulation    
; arguments:
;   aucun
; retourne:
;   rien 
DEFWORD "NEXT-COLON",10,,NEXTCOLON
    .word FALSE,CURENBL
    .word HTAB,CFETCH,TBRANCH,2f-$,LIT,4,HTAB,CSTORE
2:  .word GETX,DUP,LIT,CPL-4,LESS,TBRANCH,2f-$
    .word DROP,BRANCH,9f-$
2:  .word HTAB,CFETCH,PLUS
    .word HTAB,CFETCH,ONEMINUS,INVERT,AND,SETX    
9:  .word TRUE,CURENBL,EXIT
    
;DEFCODE "NEXT-COLON",10,,NEXTCOLON 
;    cursor_incr_sema
;    cursor_sync
;    mov #(CPL-4),W0
;    cp.b xpos
;    bra geu, 9f
;    mov.b xpos,WREG
;    ze W0,W0
;2:  add #4,W0
;    and.b #~3,W0
;    mov.b WREG,xpos
;9:  cursor_decr_sema
;    NEXT

; nom: LC-DEL ( -- )
;  Supprime le caractère à la position du curseur
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LC-DEL",6,,LCDEL
    .word FALSE,CURENBL
    .word CURADR,ONEPLUS ; S: c-addr
    .word LIT,CPL,GETX,ONEPLUS,DOQDO,BRANCH,2f-$
1:  .word DUP,ECFETCH,OVER,ONEMINUS,CSTORE,ONEPLUS,DOLOOP,1b-$
2:  .word ONEMINUS,BL,SWAP,CSTORE,TRUE,CURENBL,EXIT
    
; nom: LC-INSRT ( -- )
;    Insère un espace à la position du curseur si la ligne.
;    2 conditions pour refuser l'insertion:  
;       1) le curseur est après le dernier caractère de la ligne.
;       2) la ligne est pleine.
;  
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LC-INSRT",8,,LCINSRT 
    .word GETX,LCEND,GETX,TWODUP,EQUAL,TBRANCH,9f-$ ; si vrai curseur en fin de ligne
    .word DUP,LIT,CPL-1,EQUAL,TBRANCH,9f-$ ; si vrai ligne pleine.
1:  .word LCLEFT,SCRCHAR,GETX,ONEPLUS,GETY,ROT,CHRTOSCR
    .word ONEMINUS,TWODUP,EQUAL,ZBRANCH,1b-$
    .word OVER,GETY,BL,CHRTOSCR
9:  .word DROP,SETX,EXIT
  
; nom: BACKDEL ( -- )
;  efface le carctère à gauche du curseur
; arguments:
;   aucun
; retourne:
;   rien  
DEFWORD "BACKDEL",7,,BACKDEL   ; ( -- )
    .word GETX,ZBRANCH,9f-$
    .word LCLEFT,LCDEL
9:  .word EXIT
    
; nom: CLRLN ( -- )
;  efface toute la ligne sur laquelle se trouve le curseur
; arguments:
;   aucun
; retourne:
;   rien
DEFCODE "CLRLN",5,,CLRLN 
    cursor_incr_sema
    cursor_sync
    mov #CPL,W0
    mul.b ypos
    mov #_video_buffer,W1
    add W2,W1,W1
    mov #0x2020,W0
    repeat #(CPL/2-1)
    mov W0,[W1++]
    clr.b xpos
    cursor_decr_sema
    NEXT
    
    
; nom: LC-BEL ( -- )
;  fait entendre un beep.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LC-BEL",6,,LCBEL
    .word LIT,200,LIT,1000,TONE,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;
; imprime un caractère à l'écran ou accepte un caractère de contrôle.
; Liste des contrôles reconnus:
;  déplacement du curseur.    
;     VK_CR   retour de chariot et ligne suivante.
;     VK_TAB  avance à la colonne de tabulation suivante.
;     VK_LEFT déplace le curseur à gauche d'un caractère
;     VL_RIGHT déplace le curseur à droite d'un caractère.    
;     VK_HOME déplace le curseur au début de la ligne.
;     VK_END  déplace le curseur à la fin de la ligne.
;     VK_UP   déplace le curseur 1 ligne vers le haut.
;     VK_DOWN déplace le curseur 1 ligne vers le bas.
;  modification de l'affichage
;     VK_BACK déplace le curseur à gauche d'un caractère et efface le caractère.    
;     CTRL_X  efface la ligne sur laquelle le curseur est.
;     VK_DELETE efface le caractère à la position du curseur.    
;     CTRL_L  efface l'écran au complet
;     VK_INSERT  insère un espace
;  autres fonctions:    
;    
;  argument:
;    caractère à transmettre
DEFWORD "LC-EMIT",4,,LCEMIT ; ( c -- )
    ; caractères imprimables 32-126
    .word DUP,LIT,VK_SPACE,ULESS,TBRANCH,2f-$
    .word DUP,LIT,126,UGREATER,TBRANCH,2f-$
    .word PUTC,EXIT
    ; déplacement du curseur
2:  .word DUP,LIT,VK_CR,EQUAL,ZBRANCH,2f-$
    .word DROP,CR,EXIT
2:  .word DUP,LIT,VK_TAB,EQUAL,ZBRANCH,2f-$
    .word DROP,NEXTCOLON,EXIT
2:  .word DUP,LIT,VK_LEFT,EQUAL,ZBRANCH,2f-$
    .word DROP,LCLEFT,EXIT
2:  .word DUP,LIT,VK_RIGHT,EQUAL,ZBRANCH,2f-$
    .word DROP,LCRIGHT,EXIT
2:  .word DUP,LIT,VK_HOME,EQUAL,ZBRANCH,2f-$
    .word DROP,LCHOME,EXIT
2:  .word DUP,LIT,VK_END,EQUAL,ZBRANCH,2f-$
    .word DROP,LCEND,EXIT
2:  .word DUP,LIT,VK_UP,EQUAL,ZBRANCH,2f-$
    .word DROP,LCUP,EXIT
2:  .word DUP,LIT,VK_DOWN,EQUAL,ZBRANCH,2f-$
    .word DROP,LCDOWN,EXIT
    ; modification de l'affichage
2:  .word DUP,LIT,VK_BACK,EQUAL,ZBRANCH,2f-$
    .word DROP,BACKDEL,EXIT
2:  .word DUP,LIT,CTRL_X,EQUAL,ZBRANCH,2f-$
    .word DROP,CLRLN,EXIT
2:  .word DUP,LIT,VK_DELETE,EQUAL,ZBRANCH,2f-$
    .word DROP,LCDEL,EXIT
2:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,2f-$
    .word DROP,CLS,EXIT
2:  .word DUP,LIT,VK_INSERT,EQUAL,ZBRANCH,2f-$
    .word DROP,LCINSRT,EXIT
    ; autres fonctions
2:  .word DUP,LIT,CTRL_G,EQUAL,ZBRANCH,2f-$
    .word DROP,LCBEL,EXIT
    ; les codes non reconnus sont imprimés.    
2:  .word PUTC,EXIT
    
    
; nom: LC-EMIT?  ( -- f )
;  retourne toujrours VRAI
; arguments:
;  aucun
; retourne:
;   f   VRAI  
DEFCODE "LC-EMIT?",8,,LCEMITQ  
    DPUSH
    mov #-1,T
    NEXT
    

; nom: LC-PAGE ( -- )
;  Efface l'écran du terminal
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LC-PAGE",7,,TVPAGE
    .word CLS
    .word EXIT
    
    
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
; arguments:
;   ud entier double non signé ( nombre à convertir)
;   u  entier simple non signé ( base numérique )    
DEFWORD "EXTRACT",7,,EXTRACT ; ( ud u -- ud2 c )     
    .word UDSLASHMOD,ROT,DIGIT,EXIT
    
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

;converti un digit d'un entier double
; non signé
;  argument:
;     ud1  entier double non signé
;     ud2  entier double non signé restant    
DEFWORD "#",1,,SHARP ; ( ud1 -- ud2 )
    .word BASE,FETCH,EXTRACT,HOLD,EXIT

;converti tous les digits d'un entier double
; non signé.
; arguments:
;   entier double non signé à convertir en chaîne
; sortie:
;   entier double de valeur nulle.    
DEFWORD "#S",2,,SHARPS ; ( ud1 -- ud2==0 )
1:  .word SHARP,TWODUP,OR,TBRANCH,1b-$,EXIT
  
;ajoute le signe au début de la chaîne numérique
; argument:
;  n est la partie forte du nombre
;  qui a été converti.  
DEFWORD "SIGN",4,,SIGN ; ( n -- )
    .word ZEROLT,ZBRANCH,1f-$
    .word CLIT,'-',HOLD
1:  .word EXIT
  
;termine la conversion en ajoutant la longueur
;en calculant la longueur de la chaîne.
DEFWORD "#>",2,,SHARPGT ; ( d -- addr u )
  .word TWODROP,HP,FETCH,PAD,FETCH,PADSIZE,PLUS,OVER,MINUS, EXIT
  
; convertions entier double en chaîne
; argument:
;   d   entier double à convertir en chaîne
; sortie:
;   addr   adresse premier caractère de la chaîne
;   u  longueur de la chaîne.  
DEFWORD "STR",3,,STR ; ( d -- addr u )
  .word DUP,TOR,DABS,LTSHARP,SHARPS,RFROM,SIGN,SHARPGT,EXIT

; imprime les espaces nécessaires au début
; de la colonne pour que le nombre
; soit aligé à droite.
; argument:
;   n1+ largeur de la colonne
;   n2+ longueur de la chaîne numérique  
DEFWORD "COLFILL",7,,COLFILL ; ( n1+ n2+ -- )
    .word MINUS,DUP,ZEROGT,TBRANCH,1f-$
    .word DROP,BRANCH,8f-$
1:  .word SPACES
8:  .word EXIT
  
; imprime un nombre dans un colonne de largeur fixe
; aligné à droite
; arguments:
;   n  nombre à imprimer
;   n+ largeur de la colonne  
DEFWORD ".R",2,,DOTR  ; ( n +n -- ) +n est la largeur de la colonne
    .word TOR,STOD,RFROM,DDOTR,EXIT
    
; imprime un nombre non sigé dans une colonne de 
; largeur fixe, aligné à droite
DEFWORD "U.R",3,,UDOTR ; ( u +n -- )
  .word TOR,LIT,0,RFROM,UDDOTR,EXIT
  
; imprime un entier simple non signé en format libre
DEFWORD "U.",2,,UDOT ; ( n -- )
udot:  .word LIT,0,UDDOT,EXIT
  
; imprime un entier simple en format libre
DEFWORD ".",1,,DOT ; ( n -- )
  .word BASE,FETCH,LIT,10,EQUAL,ZBRANCH,udot-$,STOD,DDOT,EXIT
  
; imprime le contenu d'une adresse
; on s'assure de l'alignement sur
; une adresse paire.  
DEFWORD "?",1,,QUESTION ; ( addr -- )
  .word LIT,0xFFFE,AND,FETCH,DOT,EXIT

;lit et imprime l'octet à l'adresse c-addr
DEFWORD "C?",2,,CQUESTION ; ( c-addr -- )    
    .word CFETCH,DOT,EXIT
  
; imprime un entier double non signé en format libre
DEFWORD "UD."3,,UDDOT ; ( ud -- )    
_uddot:
    .word LTSHARP,SHARPS,SHARPGT,SPACE,TYPE
    .word EXIT
    
; imprime un entier double en format libre    
DEFWORD "D.",2,,DDOT ; ( d -- )
    .word BASE,FETCH,LIT,10,EQUAL,ZBRANCH,_uddot-$
    .word STR,SPACE,TYPE
    .word EXIT
    
; imprime un entier double dans une colonne de largeur fixe
; alignée à droite    
DEFWORD "D.R",3,,DDOTR ; ( d n+ -- )
    .word TOR,STR,RFROM,OVER,COLFILL,TYPE,EXIT

DEFWORD "UD.R",4,,UDDOTR ; ( ud n+ -- )
    .word TOR,LTSHARP,SHARPS,SHARPGT,RFROM,OVER
    .word COLFILL,TYPE,EXIT
    