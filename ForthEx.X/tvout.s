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

.global xpos,ypos    
line_count: .space 2
even: .space 1

; indicateurs booléens dans la variable video_flags 
.equ F_VIDEO_OFF,0 ; sortie vidéo désactivée.
.equ F_SCROLL,1 ; le curseur de déplace pas lorsqu'il est dans le coin inférieur-droit. 
.equ F_WRAP,2 ; activation retour à la ligne automatique
.equ F_INVERT,7  ; inverse vidéo, caractères noir/blanc.
 
video_flags: .space 1
; video_on: .space 1
 
.align 2 
xpos: .space 1
ypos: .space 1

.align 2
.global fcursor, cursor_dly , cursor_sema
cursor_dly: .space 2 ; contrôle vitesse clignotement
cursor_sema: .space 1 ; sémaphore 
fcursor: .space 1 ; indicateur booléens curseur texte
_htab: .space 1 ; largeur tabulation
 
.section .tvout.buffer.bss bss address(RAM_END-VIDEO_BUFF_SIZE)
.global _video_buffer
_video_buffer: .space VIDEO_BUFF_SIZE
 
.ifdef BLACKLEVEL
.equ OC4IFS,IFS1 
.equ OC4IEC,IEC1
.equ OC4IPC,IPC6
.endif 

;********************
; interruption TIMER2
; synchronisation  vidéo  
;********************
INTR    
.global __T2Interrupt
__T2Interrupt:
    bclr SYNC_IFS, #SYNC_IF
.ifdef BLACKLEVEL    
    bset VIDEO_BLKLEVEL_TRIS,#VIDEO_BLKLEVEL_OUT
.endif    
    bclr VIDEO_SPISTAT, #SPIEN
    push W0
    inc line_count
    bra nz, 2f
PreEqual: ; line_count==0..5, impulsions de pré-égalisation
.ifdef BLACKLEVEL
    bclr OC4IEC,#OC4IE
.endif    
    mov #SERATION, W0
    mov W0, SYNC_OCR
    mov #HALFLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra T2isr_exit
2:  mov #6, W0
    cp line_count
    bra nz, 2f
Vsync: ; line_count==6..11, impulsions vertical sync
    mov #(HALFLINE-HSYNC), W0
    mov W0, SYNC_OCR
    bra T2isr_exit
2:  mov #12, W0
    cp line_count
    bra nz, 2f
PostEqual: ; line_count==12..17/18 ,impulsions de post-égalisation.
    mov #SERATION, W0
    mov W0, SYNC_OCR
    bra T2isr_exit
2:  mov #17,W0
    cp line_count
    bra nz, 2f
EvenFieldFL: ; champ pair première ligne complète
    cp0.b even
    bra z, T2isr_exit
    mov #HLINE,W0
    mov W0,SYNC_OCRS
    mov W0,SYNC_PER
    bra T2isr_exit
2:  mov #18, W0
    cp line_count
    bra nz, 2f
OddFieldFL: ; champ impair première ligne complète.
    mov #HSYNC, W0
    mov W0, SYNC_OCR
    mov #HLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
    bra T2isr_exit
.ifdef BLACKLEVEL
2:  mov #29,W0
    cp line_count
    bra nz, 2f
BackPorchEnable:  
    bclr OC4IFS,#OC4IF
    bset OC4IEC,#OC4IE
    bra T2isr_exit
.endif    
2:  mov #TOPLINE, W0
    cp line_count
    bra nz, 2f
EnableVideo: ; line_count==TOPLINE,  activation interruption video
    btsc.b video_flags,#F_VIDEO_OFF
;    cp0.b video_on
    bra T2isr_exit
    bclr VIDEO_IFS, #VIDEO_IF
    bset VIDEO_IEC, #VIDEO_IE
    bra T2isr_exit
2:  mov #TOPLINE+YRES, W0
    cp line_count
    bra nz, 2f
DisableVideo: ; line_count==TOPLINE+YRES, désactivaion int. video
    bclr VIDEO_IEC, #VIDEO_IE
    bra T2isr_exit
2:  mov #FIELD_LINES,W0
    cp0.b even
    bra z, OddField
EvenField:    ; fin du champ pair
    dec W0,W0
    cp line_count
    bra nz, T2isr_exit
    bra FieldEnd
OddField:  ; fin du champ impair, se termine par une demi-ligne.  
    cp line_count
    bra nz, T2isr_exit
    mov #HALFLINE, W0
    mov W0, SYNC_OCRS
    mov W0, SYNC_PER
FieldEnd:  ; réinitialisation du compteur de ligne et inversion parité champ. 
    com.b even
    setm line_count
T2isr_exit:
    pop W0
    retfie
    
.ifdef BLACKLEVEL    
; début seuil niveau noir    
.global __OC4Interrupt    
__OC4Interrupt:
    bclr OC4IFS,#OC4IF
    bclr VIDEO_BLKLEVEL_TRIS,#VIDEO_BLKLEVEL_OUT
    retfie
.endif
    
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
    bra 9f
    mov	#CURSOR_DELAY, W0
    mov W0, cursor_dly
    clr.b cursor_sema
    mov #1<<CURSOR_ACTIVE,W0
    mov.b WREG, fcursor
9:  pop W0
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
    repeat #(((VIDEO_BUFF_SIZE-CPL)/2)-1)
    mov [--W2],[--W1]
    mov #0x2020,W0
    repeat #((CPL/2)-1)
    mov W0,[--W1]
    cursor_decr_sema
    RESET_EDS
    pop W2
    pop.d W0
    return
 
; DESCRIPTION:
;   Mot contrôlant l'affichage de la console LOCAL.
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  mots du système FORTH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; nom: SCRBUF  ( -- c-addr )    
;   Constante, adresse du tampon vidéo.
; arguments:
;   aucun
; retourne:
;   c-addr  Adresse du tampon vidéo. 
DEFCONST "SCRBUF",6,,SCRBUF,_video_buffer
    
; nom: HTAB   ( -- a-addr )   
;   Variable retourne l'adresse de la variable contenant la largeur des tabulations.
;   Au démarrage cette valeur est fixée à 4 caractères.
; arguments:
;   aucun
; retourne:
;   a-addr Adresse de la variable HTAB.    
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
    clr.b video_flags
    ;setm.b video_on
    ; activation interruption  SYNC_TIMER
    bclr SYNC_IFS, #SYNC_IF
    bset SYNC_IEC, #SYNC_IE
    ; activation timer
    bset SYNC_TMRCON, #TON
    ; activation du curseur texte
    mov #CURSOR_DELAY,W0
    mov W0, cursor_dly
    clr.b cursor_sema
;    bset fcursor, #CURSOR_ACTIVE
    bclr fcursor, #CURSOR_INV
.ifdef BLACKLEVEL    
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
.endif    
    mov.b #4,W0 ; largeur tabulation
    mov.b WREG,_htab
    bset video_flags,#F_SCROLL
    bset video_flags,#F_WRAP
    bra code_LCCLS
    
; nom: VIDEO  ( f -- )
;   Active/désactive la sortie vidéo. La synchronisation demeure active
;   mais les pixels vidéo ne sont plus envoyés au moniteur.   
; arguments:
;    f Indicateur booléen, si VRAI active la sortie vidéo, autrement la désactive.
; retourne:
;   rien    
DEFCODE "VIDEO",5,,VIDEO   
    cp0 T
    bra nz, 2f
    bset.b video_flags,#F_VIDEO_OFF
    bra 9f
2:  bclr.b video_flags,#F_VIDEO_OFF    
9:  DPOP
    NEXT

; LC-INIT  ( -- )
; initialise la console locale
HEADLESS LCINIT,HWORD
    .word LCCLS,LIT,0,DUP,LIT,kbd_head,STORE
    .word LIT,kbd_tail,STORE,EXIT
    
; LC-B/W ( f -- ) 
;   Console locale.    
;   Détermine si les caractères s'affichent noir sur blanc ou l'inverse
;   Si l'indicateur Booléen 'f' est vrai les caractères s'affichent noir sur blanc.
;   Sinon ils s'affiche blancs sur noir (valeur par défaut).
; arguments:
;   f   Indicateur Booléen, inverse vidéo si vrai.    
; retourne:
;   rien    
HEADLESS LCBSLASHW,CODE   
;DEFCODE "LC-B/W",6,,LCBSLASHW
    cp0 T
    bra z, 2f
    bset.b video_flags,#F_INVERT
    bra 9f
2:  bclr.b video_flags,#F_INVERT
9:  DPOP
    NEXT
    
; LC-WHITLN ( n -- )
;   Imprime une ligne blanche sur la console LOCAL.
;   Laisse le curseur au début de la ligne et le mode noir/blanc.    
; arguments:
;   n  Numéro de la ligne {1..24}
; retourne:
;   rien
HEADLESS LCWHITELN,HWORD    
;DEFWORD "LC-WHITELN",10,,LCWHITELN
    .word TRUE,LCBSLASHW
    .word LIT,1,OVER,LCATXY
    .word LNADR,LIT,CPL,LIT,128+32,FILL
    .word EXIT
    
    
; nom: CURENBL   ( f -- )
;   Console locale.    
;   Active ou désactive le curseur texte.
; arguments:
;   f   indicateur booléen, si VRAI active le curseur, sinon le désactive.
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
    
;  LC-CLS  ( -- )
;   Console locale.    
;   Vide l'écran.
; arguments:    
;   aucun
; retourne:    
;   rien
HEADLESS LCCLS,CODE  
;DEFCODE "LC-CLS",6,,LCCLS
    cursor_incr_sema
    mov #0x2020,W0
    mov #_video_buffer, W1
    repeat #(VIDEO_BUFF_SIZE/2-1)
    mov W0, [W1++]
    clr xpos  ; xpos=0, ypos=0
    bclr.b fcursor,#CURSOR_INV
    cursor_decr_sema
    NEXT

; nom: SCROLL-UP  ( -- )
;   Console locale.    
;   Glisse l'affichage vers le haut d'une ligne texte et efface la dernière ligne.
; arguments:
;   aucun
; retourne:    
;   rien
DEFCODE "SCROLL-UP",9,,SCRLUP
    call scroll_up
    NEXT

; nom: SCROLL-DOWN  ( -- )
;   Console locale.    
;   Glisse l'affichage vers le bas d'une ligne texte et efface la première ligne.
; arguments:
;   aucun
; retourne:    
;   rien
DEFCODE "SCROLL-DOWN",11,,SCRLDN 
    call scroll_down
    NEXT
    
; nom: GETX ( -- u )
;   Console locale.    
;   Retourne la colonne du curseur texte.
; arguments:
;   aucun
; retourne:    
;   u    colonne du curseur {1..64}   
DEFCODE "GETX",4,,GETX
    DPUSH
    mov.b xpos, WREG
    inc.b W0,T
    ze T,T
    NEXT
    
; nom: GETY  ( -- u )
;   Console locale.    
;   Retourne la ligne du curseur.
; arguments:
;   aucun
; retourne:    
;   u    ligne du curseur {1..24}
DEFCODE "GETY",4,,GETY
    DPUSH
    mov.b ypos, WREG
    inc.b W0,T
    ze T,T
    NEXT
    
; nom: SETX   ( u -- )
;   Console locale.    
;   Positionne le curseur texte à la colonne u.
; arguments:
;    u   colonne {1..64}
; retourne:    
;    rien
DEFCODE "SETX",4,, SETX ; ( u -- )
    cursor_incr_sema
    cursor_sync
    cp0 T
    bra gt, 1f
    mov #1,T
1:  dec T,T
    mov #CPL-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
1:  mov.b WREG,xpos
    cursor_decr_sema
    DPOP
    NEXT

; nom: SETY  ( u -- )
;   Console locale.    
;   Positionne le curseur texte à la ligne u.
; arguments:
;    u   ligne {1..24}
; retourne:    
;    rien
DEFCODE "SETY",4,,SETY  ; ( u -- )
    cursor_incr_sema
    cursor_sync
    cp0 T
    bra gt,1f
    mov #1,T
1:  dec T,T
    mov #LPS-1,W0
    cp T, W0
    bra gtu, 1f
    mov T, W0
1:  mov.b WREG,ypos
    cursor_decr_sema
    DPOP
    NEXT

; nom: LNADR  ( n -- c-addr )
;   Console locale.
;   Retourne l'adresse du premier caractère de la ligne dans le tampon vidéo.
; arguments:
;   n+	Numéro de la ligne {1..24}
; retourne:
;   c-addr  Adresse du premier caractère de cette ligne.
DEFWORD "LNADR",5,,LNADR 
    .word ONEMINUS,LIT,CPL,STAR,SCRBUF,PLUS,EXIT
    
    
; nom: CURADR  ( -- c-addr )
;   Console locale.    
;   Retourne l'adresse dans le tampon vidéo correspondant
;   à la position actuelle du curseur.
; arguments:
;   aucun
; retourne:
;   c-addr   addresse tampon correspondant à la position du curseur texte.
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
    
    
;  LC-AT-XY  ( u1 u2 -- )
;   Console locale.    
;   Positionne le curseur texte à la colonne u1 et la ligne u2.
; arguments:
;    u1    colonne {1..64}
;    u2    ligne {1..24}
; retourne:
;   rien    
HEADLESS LCATXY,HWORD    
;DEFWORD "LC-AT-XY",8,,LCATXY  ; ( u1 u2 -- )
    .word SETY, SETX, EXIT

; LC-XY?  ( -- u1 u2 )
;   Console locale.    
;   Retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1    colonne  {1..64}
;   u2    ligne    {1..24}
HEADLESS LCXYQ,HWORD    
;DEFWORD "LC-XY?",6,,LCXYQ
    .word GETX,GETY,EXIT
    
; nom: SCR-CHAR  ( -- c )    
;   Console locale.    
;   Retourne le caractère à la position du curseur.
; arguments:
;   aucun
; retourne:
;   c   caractère à la position du curseur.    
DEFCODE "SCR-CHAR",8,,SCRCHAR ; ( -- c )
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

; nom: CHR>SCR  ( u1 u2 c -- )    
;   Console locale.    
;   Dépose le caractère 'c' la position {u1,u2} dans le tampon vidéo. 
;   Cette opération n'affecte pas la position du curseur texte.    
; arguments:
;   u1 Colonne {1..64}
;   u2 Ligne {1..24}
;   c Caractère    
; retourne:
;   rien    
DEFCODE "CHR>SCR",7,,CHRTOSCR
    cursor_incr_sema
    cursor_sync
    mov [DSP--],W0
    dec W0,W0
    mov #CPL,W1
    mul.uu W0,W1,W0
    mov [DSP--],W1
    dec W1,W1
    add W0,W1,W0
    mov #_video_buffer,W1
    add W1,W0,W0
    btsc.b video_flags,#F_INVERT
    bset T,#7
    mov.b T,[W0]
    DPOP
    cursor_decr_sema
    NEXT
    
; INVLN  ( n f -- )    
;   Console locale.    
;   Inverse vidéo de la ligne n. L'inverse vidéo signifie que les caractères sont affiché noir/blanc.
; arguments:
;   n   Ligne {1..24}
;   f   T=inverse, F=vidéo normal
; retourne:
;   rien    
;DEFCODE "INVLN",5,,INVLN
;    SET_EDS
;    mov #CPL,W0
;    mov [DSP--],W1
;    dec W1,W1
;    mul.uu W0,W1,W0
;    mov #_video_buffer,W1
;    add W1,W0,W0
;    cp0 T
;    bra z, normal_video
;    repeat #CPL-1
;    bset.b [W0++],#7
;    bra 9f
;normal_video:
;    repeat #CPL-1
;    bclr.b [W0++],#7
;9:  RESET_EDS
;    DPOP
;    NEXT
    
    
;  LC-LEFT  ( -- )
;   Console locale.    
;   Déplace le curseur 1 caractère vers la gauche.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCLEFT,CODE    
;DEFCODE "LC-LEFT",7,,LCLEFT
    cursor_incr_sema
    cursor_sync
    cp0.b xpos
    bra z,2f
    dec.b xpos
2:
    cursor_decr_sema
    NEXT
    
    
;  LC-RIGHT  ( -- )
;   Console locale.    
;   Déplace le curseur 1 caractère vers la droite.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCRIGHT,CODE    
;DEFCODE "LC-RIGHT",8,,LCRIGHT
    cursor_incr_sema
    cursor_sync
    mov #CPL-1,W0
    cp.b xpos
    bra z,2f
    inc.b xpos
2:    
    cursor_decr_sema
    NEXT


; LC-HOME  ( -- )
;   Console locale.    
;   Déplace le curseur au début de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCHOME,CODE    
;DEFCODE "LC-HOME",7,,LCHOME
    cursor_incr_sema
    cursor_sync
    clr.b xpos
    cursor_decr_sema
    NEXT
    
; LC-END  ( -- )
;   Console locale.    
;   Déplace le curseur après le dernier caractère de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCEND,HWORD    
;DEFWORD "LC-END",6,,LCEND
    .word CURADR,LIT,CPL-1,DUP,INVERT,ROT,AND,SWAP ; S: c-addr CPL-1
1:  .word TWODUP,PLUS,ECFETCH,BL,EQUAL,ZBRANCH,2f-$    
    .word DUP,ZEROEQ,TBRANCH,4f-$
    .word ONEMINUS,BRANCH,1b-$
2:  .word DUP,LIT,CPL-1,NOTEQ,MINUS 
4:  .word ONEPLUS,SETX
    .word DROP
    .word EXIT
  
; LC-UP   ( -- )
;   Console locale.    
;   Déplace le curseur d'une ligne vers le haut.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCUP,CODE    
;DEFCODE "LC-UP",5,,LCUP
    cursor_incr_sema
    cursor_sync
    cp0.b ypos
    bra z, 9f
    dec.b ypos
9:  cursor_decr_sema
    NEXT

; LC-DOWN   ( -- )
;  Console locale.    
;  Déplace le curseur d'une ligne vers le bas.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCDOWN, CODE    
;DEFCODE "LC-DOWN",7,,LCDOWN
    cursor_incr_sema
    cursor_sync
    mov #LPS-1,W0
    cp.b ypos
    bra z, 9f
    inc.b ypos
9:  cursor_decr_sema
    NEXT
    
    
; LC-TOP ( -- )
;    Déplace le curseur dans le coin supérieur gauche.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCTOP,HWORD
    .word LIT,1,DUP,LCATXY,EXIT
    
; LC-BOTTOM ( -- )
;   Déplace le curseur dans le coin inférieur droit.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCBOTTOM,HWORD
    .word LIT,CPL,LIT,LPS,LCATXY,EXIT
    
; nom: TGLCHAR  ( -- )
;   Console locale.    
;   Inverse le bit #7 du caractère à la position du curseur.
;   Le bit #7 du caractère est utilisé comme indicateur d'inversion vidéo.
;   Lorsque ce bit est à 1 le caractère et affiché en noir sur fond blanc.    
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
;   Console locale.    
;   Affiche le caractère à la position du curseur et avance
;   le curseur vers la droite. Lorsque le curseur dépasse la fin de la ligne
;   l'état de WRAP et SCROLL sont pris en compte pour le retour à la ligne
;   automatique et le défilement vers le haut.    
; arguments:
;   c   Caractère à afficher.
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
    btsc.b video_flags,#F_INVERT
    bset T,#7
    mov.b T, [W1]
    DPOP
    mov #(CPL-1),W0
    cp.b xpos
    bra z, 2f
    inc.b xpos
    bra 9f
2:  btss.b video_flags,#F_WRAP
    bra 9f
    mov #(LPS-1),W0
    cp.b ypos
    bra z,8f
    clr.b xpos
    inc.b ypos
    bra 9f
8:  btss.b video_flags,#F_SCROLL
    bra 9f
    clr.b xpos
    call scroll_up
9:  cursor_decr_sema
    NEXT
    
;  LC-CRLF ( -- )
;   Console locale.    
;   Envoie le curseur au début de la ligne suivante défile l'écran
;   vers le haut si le curseur est sur la dernière ligne sauf si
;   SCROLL est désactivé. Dans ce cas renvoie de le curseur au début 
;   de la ligne sans autre action.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCCRLF,CODE    
;DEFCODE "LC-CRLF",7,,LCCRLF 
    cursor_incr_sema
    cursor_sync
    clr.b xpos
    mov #(LPS-1),W0
    cp.b ypos
    bra z, 2f
    inc.b ypos
    bra 9f
2:  btsc video_flags,#F_SCROLL
    call scroll_up    
9:  cursor_decr_sema
    NEXT


;  LC-TAB  ( -- )    
;   Console locale.    
;   Avance le curseur à la prochaine tabulation.
; arguments:
;   aucun
; retourne:
;   rien 
HEADLESS LCTAB,HWORD    
;DEFWORD "LC-TAB",6,,LCTAB
    .word LCXYQ,SWAP,HTAB,CFETCH,SWAP ; s: line tab col
    .word OVER,SLASH,OVER,STAR,PLUS,SWAP,LCATXY,EXIT
    
;2:  .word GETX,DUP,LIT,CPL,HTAB,CFETCH,MINUS,LESS,TBRANCH,2f-$
;    .word DROP,BRANCH,9f-$
;2:  .word ONEMINUS,HTAB,CFETCH,DUP,TOR,SLASH,ONEPLUS,RFROM,STAR
;    .word ONEPLUS,SETX    
;9:  .word EXIT
    
;  LC-DEL ( -- )
;   Console locale.  
;   Supprime le caractère à la position du curseur.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCDEL,HWORD    
;DEFWORD "LC-DEL",6,,LCDEL
    .word CURADR,DUP,ONEPLUS,SWAP ; s: src dest
    .word LIT,CPL,GETX,MINUS,MOVE
    .word LIT,64,GETY,BL,CHRTOSCR,EXIT
    
;  LC-INSRT ( -- )
;   Console locale.  
;   Insère un espace à la position du curseur.
;   Il y a 2 conditions pour refuser l'insertion:  
;       1) le curseur est après le dernier caractère de la ligne.
;       2) la ligne est pleine.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCINSRT,HWORD  
;DEFWORD "LC-INSRT",8,,LCINSRT 
    .word GETX,LCEND,GETX,TWODUP,EQUAL,TBRANCH,9f-$ ; si vrai curseur en fin de ligne
    .word DUP,LIT,CPL-1,EQUAL,TBRANCH,9f-$ ; si vrai ligne pleine.
1:  .word LCLEFT,SCRCHAR,GETX,ONEPLUS,GETY,ROT,CHRTOSCR
    .word ONEMINUS,TWODUP,EQUAL,ZBRANCH,1b-$
    .word OVER,GETY,BL,CHRTOSCR
9:  .word DROP,SETX,EXIT
  
; LC-BACKDEL ( -- )
;   Console locale.  
;   Efface le carctère à gauche du curseur.
; arguments:
;   aucun
; retourne:
;   rien  
HEADLESS LCBACKDEL,HWORD  
;DEFWORD "LC-BACKDEL",10,,LCBACKDEL   ; ( -- )
    .word GETX,ZBRANCH,9f-$
    .word LCLEFT,LCDEL
9:  .word EXIT
    
; LC-DELLN ( -- )
;   Console locale.  
;   Efface toute la ligne sur laquelle se trouve le curseur et positionne
;   le curseur en début de ligne.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCDELLN,CODE  
;DEFCODE "LC-DELLN",8,,LCDELLN 
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

; LC-DELEOL ( -- )
;   Efface tous les caractères à partir du curseur jusqu'à la fin de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCDELEOL,HWORD    
;DEFWORD "LC-DELEOL",9,,LCDELEOL
    .word CURADR,LIT,CPL,GETX,ONEMINUS,MINUS,BL,FILL
    .word EXIT
    
    
    
;  LC-RMVLN ( -- )    
;   Retire la ligne sur laquelle se trouve le curseur.
;   Les lignes qui se trouvent sous celle-ci sont décallées vers le haut.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS LCRMVLN,HWORD    
;DEFWORD "LC-RMVLN",8,,LCRMVLN
    .word GETY,LNADR,TOR,RFETCH,LIT,CPL,PLUS
    .word DUP,SCRBUF,LIT,CPL,LIT,LPS,STAR,PLUS,SWAP,MINUS
    .word RFROM,SWAP,MOVE
    .word LIT,1,GETY,LIT,LPS,SETY,LCDELLN,LCATXY
    .word EXIT
   
    
; LC-INSRTLN ( -- )
;   Insère une ligne avant la ligne où se trouve le curseur.
;   Les lignes à partir du curseur sont décalées vers le bas.    
;   S'il y a du texte sur la dernière ligne ce texte est perdu.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS LCINSRTLN,HWORD    
;DEFWORD "LC-INSRTLN",10,,LCINSRTLN
    .word GETY,LNADR,DUP,LIT,CPL,PLUS ; s: src dest
    .word LIT,LPS,GETY,MINUS,LIT,CPL,STAR ; s: src dest count
    .word MOVE,LCDELLN,EXIT
    
    
    
; LC-EMIT?  ( -- f )
;   Console locale.
;   Vérifie si la console est prête à recevoir des caractères.  
;   Retourne toujrours VRAI.
; arguments:
;  aucun
; retourne:
;   f   VRAI  
HEADLESS LCEMITQ,CODE    
;DEFCODE "LC-EMIT?",8,,LCEMITQ  
    DPUSH
    mov #-1,T
    NEXT
    
