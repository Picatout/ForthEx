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

;eeprom status bits
.equ WIP, 0
.equ WEN, 1
.equ BP0, 2
.equ BP1, 3
.equ WPEN, 7
 
.equ EPAGE_SIZE, 256
 
 .macro spi_write
    mov.b WREG, STR_SPIBUF
    btss STR_SPISTAT, #SPIRBF
    bra .-2
    mov STR_SPIBUF, W0
.endm

.macro spi_read
    setm.b STR_SPIBUF    
    btss STR_SPISTAT, #SPIRBF
    bra .-2
.endm

.macro _enable_sram
    bclr STR_LAT, #SRAM_SEL
.endm
    
.macro _disable_sram
    bset STR_LAT, #SRAM_SEL
.endm
    
.macro _enable_eeprom
   bclr STR_LAT, #EEPROM_SEL
.endm
   
.macro _disable_eeprom
   bset STR_LAT, #EEPROM_SEL
.endm
   
