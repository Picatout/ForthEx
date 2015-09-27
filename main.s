;.include "p24Fxxxx.inc"
.include "hardware.inc"


    
;config CONFIG1, FWDTEN_OFF & JTAGEN_OFF
;config CONFIG2, FNOSC_PRIPLL & FCKSM_CSDCMD  & POSCMOD_HS & OSCIOFNC_ON


.text
.global _main
.extern _video_buffer
_main:
    call hardware_init
; test vidéo    
    mov #_video_buffer,W1
    mov #25, W2
0:    
    mov #40, W0
1:
    dec W0, W0   
    mov.b W0, [W1++]
    bra nz, 1b
    dec W2, W2
    bra nz, 0b
; fin test vidéo    
    bra $

.end
