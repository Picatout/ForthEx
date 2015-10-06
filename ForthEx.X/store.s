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
    
    