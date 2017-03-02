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
;     along with ForthEx.  If not, see <http:;www.gnu.org/licenses/>.
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
 
;;;;;;;;;;;;;;;;;;;;
; constantes EEPROM
; 25LC1024 
;;;;;;;;;;;;;;;;;;;;
 
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
 
.equ EPAGE_SIZE, 256  ;octets
.equ EPAGE_COUNT, 512  ; nombre de pages
.equ ESECTOR_SIZE, 32768 ; nombre de secteurs
.equ EPG_SECTOR, (ESECTOR_SIZE/EPAGE_SIZE) ; page par secteur 
 
 
;ref: http://www.microchip.com/forums/m530149.aspx
;ref: http://elm-chan.org/docs/mmc/mmc_e.html 

; indicateurs booléens carte SD
.equ F_SDC_IN, 0 ; carte dans la fente
.equ F_SDC_OK,1 ; carte insérée et initialisée
.equ F_SDC_V1,2 ; carte version 1
.equ F_SDC_HC,3 ; carte haute capacité
.equ F_SDC_TO,4 ; commande time out
.equ F_SDC_WE,5 ; erreur écriture
.equ F_SDC_RE,6 ; erreur lecture
.equ F_SDC_IE,7 ; erreur initialisation  
.equ F_BAD_CARD,8 ; la carte ne répond pas
 
;commandes carte SD
.equ GO_IDLE_STATE,         0    ; CMD0 - réinitialise carte
.equ SEND_OP_COND,        1      ; CMD1 - requête condition d'opération
.equ SEND_IF_COND,        8      ; CMD8 - requête condition d'interface
.equ SEND_CSD,            9      ; CMD9 - requête status
.equ SET_BLOCKLEN,        16     ; CMD16 - fixe longueur bloc
.equ WRITE_SINGLE_BLOCK,    24   ; CMD24 - écriture d'un bloc
.equ APP_CMD,                55  ; CMD55 - commande escape
.equ READ_OCR,            58     ; CMD58 - requête registre ocr
.equ CRC_ON_OFF,            59   ; CMD59 - activation/désactivation CRC
.equ SD_STATUS,            13    ; ACMD13 - requête status
.equ SD_SEND_OP_COND,        41  ; ACMD41 - requête condition d'opération
; certaines commandes requière une valeur pour CRC
.equ CMD0_CRC, 0x95 
.equ CMD8_CRC, 0x87
.equ CMDX_CRC, 0xFF  ; autre commandes
 
 
; fréquence SPI clock
.equ SCLK_SLOW, (0<<2)|(0)  ; SPRE->8:1, PPRE->64:1 pour FCY=70Mhz > 136,7Khz 
.equ SCLK_FAST, (4<<2)|(0)  ; SPRE->4:1, PPRE->1:1 pour FCY=70Mhz > 17,5Mhz
 
.macro _disable_spi
    bclr STR_SPISTAT, #SPIEN
.endm
   
.macro _enable_spi
    bset STR_SPISTAT, #SPIEN
.endm
 
.macro spi_write
    mov.b WREG, STR_SPIBUF
    btss STR_SPISTAT, #SPIRBF
    bra $-2
    mov STR_SPIBUF, W0
.endm

.macro spi_read
    setm.b STR_SPIBUF    
    btss STR_SPISTAT, #SPIRBF
    bra $-2
    mov.b STR_SPIBUF,WREG
.endm

.macro _enable_sram
    bclr STR_LAT, #SRAM_SEL
    bra $+2  ; délais TCSS voir 23LC1024 datasheet
    _enable_spi
.endm
    
.macro _disable_sram
    bset STR_LAT, #SRAM_SEL
    bra $+2   ; délais TCSD voir 23LC1024 datasheet
    _disable_spi
.endm
    
.macro _enable_eeprom
   bclr STR_LAT, #EEPROM_SEL
   bra $+2  ; délais TCSS 
   nop	    ;voir 25LC1024 datasheet
   _enable_spi
.endm
   
.macro _disable_eeprom
   bset STR_LAT, #EEPROM_SEL
   bra $+2    ; délais TCSD
   nop        ; voir 25LC1024 datasheet
   _disable_spi
.endm
   
.macro _enable_sdc
   bclr SDC_LAT,#SDC_SEL
.endm
   
.macro _disable_sdc
   bset SDC_LAT,#SDC_SEL
.endm
   
   