;.include "p24Fxxxx.inc"
.include "hardware.inc"

;config CONFIG1, FWDTEN_OFF & JTAGEN_OFF
;config CONFIG2, FNOSC_PRIPLL & FCKSM_CSDCMD  & POSCMOD_HS & OSCIOFNC_ON


.text
.global _main
_main:
    call hardware_init
    bra $

.end
