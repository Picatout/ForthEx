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
.include "store.inc"
    
 .text
 
   
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
;    ;sélection des PPS
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
    ; met la SPIRAM en mode séquenctiel.
;    bclr STR_LAT, #SRAM_SEL
;    mov #WRMR, W0
;    spi_write
;    mov #RMSEQ, W0
;    spi_write
;    bset STR_LAT, #SRAM_SEL
    return


    
;;;;;;;;;;;;;;;;;;;;
; envoie d'une adresse via STR_SPI
; adresse sur dstack
; adresse de 24 bits
;;;;;;;;;;;;;;;;;;;;   
.global spi_send_address    
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
; vérifie si le bit WIP (Write In Progress)
; est actif et attend
; qu'il revienne à zéro.
;;;;;;;;;;;;;;;;;;;;;;;;;
.global wait_wip0    
wait_wip0:
    _enable_eeprom  
    mov #ERDSR, W0
    spi_write
    spi_read
    _disable_eeprom
    btsc STR_SPIBUF, #WIP
    bra wait_wip0
    return

    
    
    
 .end
    
    