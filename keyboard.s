; interface clavier PS/2
    
.include "hardware.inc"
    
    

.global __INT1Interrupt
__INT1Interrupt:
    
    bclr KBD_IFS, #KBD_IF
    retfie
.end    


