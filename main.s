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
    mov #psvpage(quick), W0
    mov W0, PSVPAG
    mov #psvoffset(quick), W1
    mov #_video_buffer,W2
    clr W0
1:
    mov.b [W1++], W0
    ze W0,W0
    bra z, 2f
    sub #32, W0
    mov.b W0, [W2++]
    bra 1b
2:    
; fin test vidéo
; test clavier
3:    
    call kbd_count
    add #16,W0
    mov.b W0, [W2]
    bra 3b
    bra .
    
;test string
quick:
.ascii "01234567890123456789012345678901234567890123456789"    
.asciz "The quick brown fox jumps over the lazy dog." 
    
.end
