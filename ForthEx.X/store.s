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
.include "gen_macros.inc"
    
.section .hardware.bss  bss
sdc_status: .space 2 ; indicateur booléens carte SD
 
INTR
;détection carte SD    
.global __CNInterrupt
__CNInterrupt:
    bset sdc_status,#F_SDC_CHG
    bclr sdc_status,#F_SDC_IN
    btss SDC_PORT,#SDC_DETECT
    bset sdc_status,#F_SDC_IN
    bclr SDC_IFS,#SDC_IF
    retfie
    
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
    ; SDC_SEL  sélection carte SD interface SPI
    ; SRAM_SEL sélection RAM SPI
    ; EEPROM_SEL sélection EEPROM SPI
    ; STR_CLK  signal clock SPI
    ; STR_MOSI signal MOSI SPI
    mov #((1<<SDC_SEL)+(1<<SRAM_SEL)+(1<<EEPROM_SEL)+(1<<STR_CLK)+(1<<STR_MOSI)), W0
    ior STR_LAT
    com W0,W0
    and STR_TRIS
    ; initialisation détection carte SD
    bset SDC_CNEN,#SDC_DETECT
    mov #~(7<<SDC_CNIP),W0
    and SDC_IPC
    mov #(3<<SDC_CNIP),W0
    ior SDC_IPC
    bset SDC_IEC,#SDC_IE
    bclr SDC_IFS,#SDC_IF
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
    mov #(1<<MSTEN)|(1<<CKE)|SPI_CLK_17MHZ, W0 ; SCLK=FCY/4
    mov W0, STR_SPICON1
;    bset STR_SPICON2, #SPIBEN ; enhanced mode
    _enable_spi
    ; met la SPIRAM en mode séquenctiel.
;    bclr STR_LAT, #SRAM_SEL
;    mov #WRMR, W0
;    spi_write
;    mov #RMSEQ, W0
;    spi_write
;    bset STR_LAT, #SRAM_SEL
;    return
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; configure la fréquence clock SPI
; entrée: W1 contient la nouvelle valeur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_spi_clock:
    _disable_spi
    mov #0x1f,W0
    and STR_SPICON1
    mov W1,W0
    ior STR_SPICON1
    _enable_spi
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; envoie 80 cycles clock SPI
; la carte est désélectionnée
; pendant cette procédure
;  SDC_SEL=MOSI=1    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
dummy_clock:
    _disable_sdc
    _enable_spi
    mov.b #0xff,WREG
    mov #10,W1
1:  spi_write
    decsz W1
    bra 1b
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; désélection de la carte SD
; 1 octet doit-être envoyée
; après que CS est ramené à 1
; pour libéré la ligne MISO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
sdc_deselect:
    _sdc_disable
    mov.b #0xff,WREG
    _spi_write
    return
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; envoie d'une commande carte SD
; entrée: 
;    W0  index commande
;    W1  argHigh
;    W2  argLow
;    W3  pointeur buffer
;    W4  grandeur buffer en octets    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sdc_cmd:
    case GO_IDLE_STATE,cmd0
    
cmd0:
    
    return
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;    
;initialisation carte SD 
;ref: http://elm-chan.org/docs/mmc/pic/sdinit.png    
;;;;;;;;;;;;;;;;;;;;;;;;;    
HEADLESS SDC_INIT,CODE
    clr sdc_status
    btsc SDC_PORT,#SDC_DETECT
    return
    bset sdc_status,#F_SDC_IN
    mov #SPI_CLK_137KHZ,W1
    call set_spi_clock
    call dummy_clock
    _sdc_enable
    ;envoie CMD0
    mov #GO_IDLE_STATE,W0
    call sdc_cmd
    
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
; vérifie si le bit WIP (Write In Progress)
; est actif et attend
; qu'il revienne à zéro.
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
    
    
 .end
    
    