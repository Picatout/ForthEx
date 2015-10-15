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

;NOM: store.s
;Description:  interface avec les mémoire externe SPIRAM et SPIEEPROM
;Date: 2015-10-06
    
.include "hardware.inc"
.include "core.inc"
    
 ; commandes SPIRAM   
.equ WRMR, 1
.equ RDMR, 5
.equ RREAD, 3
.equ RWRITE, 2
 ; modes SPIRAM
.equ RMBYTE, 0
.equ RMPAGE, (2<<6) 
.equ RMSEQ, (1<<6)    
 
; commandes EEPROM
.equ EWRITE, 2 
.equ EREAD,  3
.equ EWREN,  6
.equ EWRDI,  4
.equ ERDSR,  5
.equ EWRSR,  1
.equ EPE,    0x42
.equ ESE,    0xD8
.equ ECE,    0xC7
.equ RDID,   0xAB
.equ EDPD,   0xB9 

.equ EPAGE_SIZE, 256
 
 .text
 
 .macro spi_write
    mov.b WREG, STR_SPIBUF
    btss STR_SPISTAT, #SPIRBF
    bra .-2
    mov STR_SPIBUF, WREG
.endm

.macro spi_read
    setm.b STR_SPIBUF
    btss STR_SPISTAT, #SPIRBF
    bra .-2
.endm
   
 ;;;;;;;;;;;;;;;;;;;;;;;
; initialisation SPI
; interface SPIRAM et
; SPIEERPOM 
;;;;;;;;;;;;;;;;;;;;;;; 
.global store_init 
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
    bclr STR_SPISTAT, #SPIEN
    ; configuration SPI
    mov #(1<<MSTEN)|(6<<SPRE0)|(3<<PPRE0)|(1<<CKE), W0 ; clock 8Mhz
    mov W0, STR_SPICON1
;    bset STR_SPICON2, #SPIBEN ; enhanced mode
    bset STR_SPISTAT, #SPIEN
    ; met la SPIRAM en mode séquenctiel.
;    bclr STR_LAT, #SRAM_SEL
;    mov #WRMR, W0
;    spi_write
;    mov #RMSEQ, W0
;    spi_write
    bset STR_LAT, #SRAM_SEL
    return


    
;;;;;;;;;;;;;;;;;;;;
; envoie d'une adresse via STR_SPI
; adresse sur dstack
; adresse de 24 bits
;;;;;;;;;;;;;;;;;;;;    
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
    
;;;;;;;;;;;;;;;
;  Forth words
;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; entrée: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RSTORE",6,,RSTORE ; ( c-addr c-addr.D n -- )
    bclr STR_LAT, #SRAM_SEL
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
    bset STR_LAT, #SRAM_SEL
    NEXT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM SPI vers la RAM du MCU
; entrée: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie: aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",6,,RLOAD ; ( c-addr c-addr.D n -- )
    bclr STR_LAT, #SRAM_SEL
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
    bset STR_LAT, #SRAM_SEL
    NEXT
  
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement bloc RAM dans EEPROM
; entrée: bloc-adress, ee-address, count    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ESTORE",6,,ESTORE  ;( c-addr c-addr. n -- )
    
    NEXT
    

DEFCODE "ELOAD",5,,ELOAD   ; ( c-addr c-addr. n -- )
    
    NEXT
    
    
 .end
    
    