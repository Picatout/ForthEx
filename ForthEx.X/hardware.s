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
; hardware setup
    
.include "hardware.inc"
.if VIDEO_STD==NTSC
.include "ntsc_const.inc"    
.else
.include "pal_const.inc"
.endif
    
.data 
.global systicks    
systicks:
.word 0
    
.text
.global hardware_init
hardware_init:
    bclr CORCON, #PSV
    clr W0
    mov W0, PSVPAG
    bset CORCON, #PSV ; espace programme visible en RAM
    clr CLKDIV
    bset OSCCON, #NOSC0
    bset OSCCON, #CLKLOCK ; verrouillage clock
    bclr INTCON1, #NSTDIS ; interruption multi-niveaux
    setm TRISA      ; port A tout en entrée
    setm TRISB      ; port B tout en entrée
    setm CNPU1       ;activation pullup
    setm CNPU2
    setm AD1PCFG    ; désactivation entrées analogiques
    call tvout_init
    call kbd_init
    call store_init
    ; verouillage configuration I/O
    bset OSCCON, #IOLOCK
    
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialisation générateur vidéo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
tvout_init:
    bclr VIDEO_TRIS, #VIDEO_OUT ; sortie vidéo
    bclr SYNC_TRIS, #SYNC_OUT  ; sortie sync vidéo
    ; configuration PPS
    mov VIDEO_RPOR, W0
    mov #~(0x1f<<VIDEO_RPORbit),W1
    and W0,W1,W0
    mov #(VIDEO_FN<<VIDEO_RPORbit), W1
    ior W0,W1,W0
    mov W0, VIDEO_RPOR
    mov SYNC_RPOR, W0
    mov #~(0x1f<<SYNC_RPORbit),W1
    and W0,W1,W0
    mov #(SYNC_FN<<SYNC_RPORbit), W1
    ior W0,W1,W0
    mov W0, SYNC_RPOR
    ; configuration VIDEO_SPI
    mov #(3+(6<<SPRE0)+1<<MSTEN), W0
    mov W0, VIDEO_SPICON1
    bset VIDEO_SPISTAT, #SPIEN
    clr VIDEO_SPIBUF
    ; configuration output compare
    mov #HLINE, W0
    ; période timer Fcy/15748-1
    mov W0, SYNC_PER
    mov W0, SYNC_OCRS
    mov W0, VIDEO_OCR
    mov #HSYNC, W0
    mov W0, SYNC_OCR
    add  #VIDEO_DLY, W0
    mov W0, VIDEO_OCRS
    ; configuraton output compare mode 5
    mov #5, W0
    mov W0, SYNC_OCCON
    mov W0, VIDEO_OCCON
    ; configuration priorité d'interruptions
    ; priorité 5 pour les 2
    mov #~(7<<SYNC_IPbit), W0
    and SYNC_IPC
    mov #(5<<SYNC_IPbit), W0 
    ior SYNC_IPC
    mov #~(7<<VIDEO_IPbit), W0
    and VIDEO_IPC
    mov #(5<<VIDEO_IPbit), W0
    ior VIDEO_IPC
    call tvsync_init
    ; activation interruption  SYNC_TIMER
    bclr SYNC_IFS, #SYNC_IF
    bset SYNC_IEC, #SYNC_IE
    ; activation timer
    bset SYNC_TMRCON, #TON
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; initialistaion clavier PS/2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
kbd_init:
    ; PPS sélection broche pour kbd_clk
    ; interruption externe
    mov #~(0x1f<<KBD_PPSbit), W0
    and KBD_RPINR
    mov #(KBD_CLK<<KBD_PPSbit), W0
    ior KBD_RPINR
    ; polarité interruption transition négative
    bset KBD_INTCON, #KBD_INTEP
    ; priorité d'interruption 7
    mov #(7<<KBD_IPCbit), W0
    ior KBD_IPC 
    ; activation interruption clavier
    bclr KBD_IFS, #KBD_IF
    bset KBD_IEC, #KBD_IE
    ; initialisation TIMER1
    ; mise à jour systicks
    ; et traitement file clavier
    mov #15999, W0
    mov W0, PR1
    mov #~(7<<T1IP0), W0
    and IPC0
    mov #(3<<T1IP0), W0
    ior IPC0
    call ps2_init
    bclr IFS0, #T1IF
    bset IEC0, #T1IE
    bset T1CON, #TON
    return

;;;;;;;;;;;;;;;;;;;;;;;
; initialisation SPI
; interface SPIRAM et
; SPIEERPOM 
;;;;;;;;;;;;;;;;;;;;;;;    
store_init:
    ; changement de direction des broches en sorties
    mov #((1<<SRAM_SEL)+(1<<EEPROM_SEL)+(1<<STR_CLK)+(1<<STR_MOSI)), W0
    ior STR_LAT
    com W0,W0
    and STR_TRIS
    ;sélection des PPS
    ; signal MISO
    mov #~(0x1f<<STR_SDI_PPSbit), W0
    and STR_RPINR
    mov #(STR_MISO<<STR_SDI_PPSbit), W0
    ior STR_RPINR
    ; signal STR_CLK
    mov #~(0x1f<<STR_CLK_RPORbit), W0
    and STR_CLK_RPOR
    mov #(STR_CLK_FN<<STR_CLK_RPORbit),W0
    ior STR_CLK_RPOR
    ; signal STR_MOSI
    mov #~(0x1f<<STR_SDO_RPORbit), W0
    and STR_SDO_RPOR
    mov #(STR_SDO_FN<<STR_SDO_RPORbit),W0
    ior STR_SDO_RPOR
    ; configuration SPI
    mov #(3+(6<<SPRE0)+1<<MSTEN), W0 ; clock 8Mhz
    mov W0, STR_SPICON1
    bset STR_SPISTAT, #SPIEN
    return
    
    
.end


