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
    
 ; commandes SPIRAM   
.equ WRMR, 1
.equ RDMR, 5
.equ RREAD, 3
.equ RWRITE, 2
 ; mode s�quenciel SPIRAM
.equ RMSEQ, 1    
    
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
    ;s�lection des PPS
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
    bset STR_SPICON2, #SPIBEN ; enhanced mode
    bset STR_SPISTAT, #SPIEN
    ; met la SPIRAM en mode s�quenctiel.
    bclr STR_LAT, #SRAM_SEL
    mov #WRMR, W0
    mov.b WREG, STR_SPIBUF
    mov #RMSEQ, W0
    mov.b WREG, STR_SPIBUF
1:
    btss STR_SPISTAT, #SRMPT
    bra 1b
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
    mov.b WREG, STR_SPIBUF
    mov T, W0
    DPOP
    swap W0
    mov.b WREG, STR_SPIBUF
    swap W0
    mov.b WREG, STR_SPIBUF
    return
    
;;;;;;;;;;;;;;;
;  Forth words
;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; entr�e: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RSTORE",6,,RSTORE ; ( c-addr c-addr.D n -- )
    bclr STR_LAT, #SRAM_SEL
    mov #RWRITE,W0
    mov.b WREG, STR_SPIBUF
    mov T, W1 ; nombre d'octets
    DPOP
    call spi_send_address
    mov T, W2 ; adresse bloc RAM
    DPOP
    mov #STR_SPIBUF, W3
0:
    cp0 W1
    bra z, 1f
    btsc STR_SPISTAT, #SPITBF
    bra 0b
    mov.b [W2++], [W3]
    dec W1,W1
    bra 0b
1:  btss STR_SPISTAT, #SRMPT
    bra 1b    
    bset STR_LAT, #SRAM_SEL
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM SPI vers la RAM du MCU
; entr�e: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie: aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",6,,RLOAD ; ( c-addr c-addr.D n -- )
    bclr STR_LAT, #SRAM_SEL
    mov #RREAD, W0
    mov.b WREG, STR_SPIBUF
    mov T, W1 ; nombre d'octets � transf�rer
    DPOP
    call spi_send_address
    mov T, W2 ; adresse bloc RAM
    DPOP
    mov #STR_SPIBUF, W3
9:    
    btsc STR_SPISTAT, #SRXMPT
    bra 0f
    mov.b [W3],W0
    bra 9b
0:  cp0 W1
    bra z, 3f
1:  clr.b STR_SPIBUF
    dec W1,W1
    btsc STR_SPISTAT, #SPITBF
    bra .-2
    btsc STR_SPISTAT, #SPIRBF
    mov.b [W3], [W2++]
    bra 0b
3:  btsc STR_SPISTAT, #SRXMPT
    bra 4f
    mov.b [W3],[W2++]
    bra 3b
4:
    bset STR_LAT, #SRAM_SEL
    NEXT
  
 .end
    
    