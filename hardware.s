; hardware setup
    
.include "hardware.inc"
.include "ntsc_const.inc"    
    
.text
.global hardware_init
hardware_init:
    bset CORCON, #PSV ; vue de la mémoire programme à l'adresse 0x8000
    clr CLKDIV  ; pas de post-div Fcy=Fosc/2
    bset OSCCON, #NOSC0
    bset OSCCON, #CLKLOCK ; verrouillage clock
    bclr INTCON1, #NSTDIS; interruption multi-niveaux
    setm TRISB      ; port tous en entrée
    setm AD1PCFG    ; désactivation entrées analogiques
    call tvout_init
    call kbd_init
    
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
    sl  W0, #1, W0
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
    mov #~(0x1f<<KBD_PPSbit), W0
    and KBD_RPINR
    mov #(KBD_CLK<<KBD_PPSbit), W0
    ior KBD_RPINR
    ; priorité d'interruption 7
    mov #(7<<KBD_IPCbit), W0
    ior KBD_IPCR 
     ; interruption sur transition négative
    bset INTCON2, #KBD_INTEP
    ; activation interruption clavier
    bclr KBD_IFS, #KBD_IF
    bset KBD_IEC, #KBD_IE
    return
    
.end


