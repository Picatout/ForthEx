;****************************************************************************
; Copyright 2015, Jacques Desch�nes
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

;NOM: store.s
;Description:  interface avec les m�moire externe SPIRAM et SPIEEPROM
;Date: 2015-10-06
    
.include "hardware.inc"
.include "core.inc"
.include "store.inc"
    
 .text
 
   
 ;;;;;;;;;;;;;;;;;;;;;;;
; initialisation SPI
; interface SPIRAM et
; SPIEERPOM 
;;;;;;;;;;;;;;;;;;;;;;; 
;.global store_init 
;store_init:
HEADLESS STORE_INIT,CODE 
    ; changement de direction des broches en sorties
    mov #((1<<SRAM_SEL)+(1<<EEPROM_SEL)+(1<<STR_CLK)+(1<<STR_MOSI)), W0
    ior STR_LAT
    com W0,W0
    and STR_TRIS
;    ;s�lection des PPS
;    ; signal MISO
;    mov #~(0x1f<<STR_SDI_PPSbit), W0
;    and STR_RPINR
;    mov #(STR_MISO<<STR_SDI_PPSbit), W0
;    ior STR_RPINR
;    ; signal STR_CLK
;    mov #~(0x1f<<STR_CLK_RPORbit), W0
;    and STR_CLK_RPOR
;    mov #(STR_CLK_FN<<STR_CLK_RPORbit),W0
;    ior STR_CLK_RPOR
;    ; signal STR_MOSI
;    mov #~(0x1f<<STR_SDO_RPORbit), W0
;    and STR_SDO_RPOR
;    mov #(STR_SDO_FN<<STR_SDO_RPORbit),W0
;    ior STR_SDO_RPOR
;    bclr STR_SPISTAT, #SPIEN
    ; configuration SPI
    mov #(1<<MSTEN)|(1<<SPRE0)|(3<<PPRE0)|(1<<CKE), W0 ; SCLK=FCY/7
    mov W0, STR_SPICON1
;    bset STR_SPICON2, #SPIBEN ; enhanced mode
    bset STR_SPISTAT, #SPIEN
    ; met la SPIRAM en mode s�quenctiel.
;    bclr STR_LAT, #SRAM_SEL
;    mov #WRMR, W0
;    spi_write
;    mov #RMSEQ, W0
;    spi_write
;    bset STR_LAT, #SRAM_SEL
;    return
    NEXT

    
;;;;;;;;;;;;;;;;;;;;
; envoie d'une adresse via STR_SPI
; adresse sur dstack
; adresse de 24 bits
;;;;;;;;;;;;;;;;;;;;   
;.global spi_send_address    
spi_send_address:
    mov T, W0
    DPOP
    spi_write
    mov T, W0
    swap W0
    spi_write
    mov T,W0
    spi_write
    DPOP
    return
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; v�rifie si le bit WIP (Write In Progress)
; est actif et attend
; qu'il revienne � z�ro.
;;;;;;;;;;;;;;;;;;;;;;;;;
;.global wait_wip0    
wait_wip0:
    _enable_eeprom  
    mov #ERDSR, W0
    spi_write
    spi_read
    _disable_eeprom
    btsc STR_SPIBUF, #WIP
    bra wait_wip0
    return

    
 ;;;;;;;;;;;;;;;
;  Forth words
;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; entr�e: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RSTORE",6,,RSTORE,TOKBD ; ( addr-bloc addr-sramL addr-sramH n -- )
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
; entr�e: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie: aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",5,,RLOAD,RSTORE ; ( addr-bloc addr-sramL addr-sramH n -- )
    _enable_sram
    mov #RREAD, W0
    spi_write
    mov T, W1 ; nombre d'octets � transf�rer
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
; entr�e: bloc-adress, page
; l'eeprom est organis�e en 512 pages de
; 256 octets.
; Bien qu'il soit possible de programmer
; un seule octet � la fois
; cette routine est con�ue pour programmer
; une page compl�te.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ESTORE",6,,ESTORE,RLOAD  ;( addr-bloc page -- )
    call wait_wip0 ; on s'assure qu'il n'y a pas une �crire en cours
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
; en m�moire RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ELOAD",5,,ELOAD,ESTORE   ; ( addr-bloc page -- )
    call wait_wip0 ; on s'assure qu'il n'y a pas une �crire en cours
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
    
    
 .end
    
    