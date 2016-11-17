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

.include "hardware.inc"    
.include "store.inc"

;;;;;;;;;;;;;;;
;  Forth words
;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; entrée: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RSTORE",6,,RSTORE,TONE ; ( addr-bloc addr-sramL addr-sramH n -- )
    _enable_sram
    mov #RWRITE,W0
    spi_write
    mov T, W1 ; nombre d'octets
    DPOP
    call spi_send_address
    mov T, W2 ; adresse bloc RAM
    DPOP
0:
    cp0 W1
    bra z, 1f
    mov.b [W2++], W0
    spi_write
    dec W1,W1
    bra 0b
1:    
    _disable_sram
    NEXT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM SPI vers la RAM du MCU
; entrée: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie: aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",5,,RLOAD,RSTORE ; ( addr-bloc addr-sramL addr-sramH n -- )
    _enable_sram
    mov #RREAD, W0
    spi_write
    mov T, W1 ; nombre d'octets à transférer
    DPOP
    call spi_send_address
    mov T, W2 ; adresse bloc RAM
    DPOP
    mov #STR_SPIBUF, W3
0:    
    cp0 W1
    bra z, 3f
    spi_read
    mov.b [W3], [W2++]
    dec W1,W1
    bra 0b
3:
    _disable_sram
    NEXT
  
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement bloc RAM dans EEPROM
; entrée: bloc-adress, page
; l'eeprom est organisée en 512 pages de
; 256 octets.
; Bien qu'il soit possible de programmer
; un seule octet à la fois
; cette routine est conçue pour programmer
; une page complète.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ESTORE",6,,ESTORE,RLOAD  ;( addr-bloc page -- )
    call wait_wip0 ; on s'assure qu'il n'y a pas une écrire en cours
    _enable_eeprom
    mov #EWREN, W0
    spi_write
    _disable_eeprom
    nop
    _enable_eeprom
    mov #EWRITE, W0
    spi_write
    sl  T, #8, T
    DPUSH
    clr T
    rlc T,T
    call spi_send_address
    mov T, W2 ; addr-bloc
    DPOP
    mov #256, W3
1:
    mov.b [W2++], W0
    spi_write
    dec W3,W3
    bra nz, 1b
    _disable_eeprom
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; charque une page EEPROM
; en mémoire RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ELOAD",5,,ELOAD,ESTORE   ; ( addr-bloc page -- )
    call wait_wip0 ; on s'assure qu'il n'y a pas une écrire en cours
    _enable_eeprom
    mov #EREAD, W0
    spi_write
    sl  T, #8, T
    DPUSH
    clr T
    rlc T,T
    call spi_send_address
    mov T, W2 ; addr-bloc
    DPOP
    mov #256, W3
1:
    spi_read
    mov STR_SPIBUF, W0
    mov.b W0, [W2++]
    dec W3,W3
    bra nz, 1b
    _disable_eeprom
    NEXT
    


