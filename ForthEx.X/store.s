;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschenes
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
    
.include "store.inc"
    
.section .hardware.bss  bss
sdc_status: .space 2 ; indicateur booléens carte SD
sdc_size: .space 4 ; nombre de secteurs de 512 octets
sdc_R: .space 5; réponse de la carte 
 
INTR
;la broche SDC_DETECT
; a changée d'état
; carte insérée ou retirée. 
.global __CNInterrupt
__CNInterrupt:
    clr sdc_status
    btss SDC_PORT,#SDC_DETECT
    bset sdc_status,#F_SDC_IN
    bclr SDC_IFS,#SDC_IF
    retfie
    
 .text
 
   
 ;;;;;;;;;;;;;;;;;;;;;;;
; initialisation SPI
; interface SPIRAM et
; SPIEERPOM et SDCARD 
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
    ; configuration SPI
    mov #(1<<MSTEN)|(1<<CKE)|SPI_CLK_17MHZ, W0 ; SCLK=FCY/4
    mov W0, STR_SPICON1
;    bset STR_SPICON2, #SPIBEN ; enhanced mode
    _enable_spi
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
    mov.b #0xff,W0
    mov #10,W1
1:  spi_write
    dec W1,W1
    bra nz, 1b
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; désélection de la carte SD
; 1 octet doit-être envoyée
; après que CS est ramené à 1
; pour libéré la ligne MISO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
sdc_deselect:
    _disable_sdc
    mov.b #0xff,W0
    spi_write
    return
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; envoie d'une commande carte SD
; entrée: 
;    W0  index commande
;    W1  argb1b2  b15:8->byte1,b7:0->byte2
;    W2  argb3b4  b15:7->byte3,b7:0->byte4
;    W3  nombre d'octets supplémentaire dans la réponse
;    W4  pointeur buffer réponse    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sdc_cmd:
    mov W0,W5
    ;initialisation générateur CRC
    ;mode CRC7=x?+x³+1
    mov #0x89,W0
    mov W0,CRCXORL
    clr CRCXORH
    bset CRCCON1,#CRCEN
    mov #(7<<DWIDTH0)+(7<<PLEN0),W0
    mov W0, CRCCON2
    clr CRCWDATL
    clr CRCWDATH
    mov.b W5,W0
    bset W0,#6
    bclr W0,#7
    mov.b WREG,CRCDATL
    spi_write
    mov W1,W0
    swap W0
    mov.b WREG,CRCDATL
    spi_write
    mov W1,W0
    mov.b WREG,CRCDATL
    spi_write
    mov W2,W0
    swap W0
    mov.b WREG,CRCDATL
    spi_write
    mov W2,W0
    mov.b WREG,CRCDATL
    bset CRCCON1,#CRCGO
    spi_write
    btsc CRCCON1,#CRCGO
    bra .-2
    mov.b CRCWDATL,WREG
    spi_write
wait_response:
    mov #8,W1
1:
    mov.b #0xff,W0
    spi_write
    xor.b #0xFF,W0
    bra nz, 2f
    dec W1,W1
    bra nz, 1b
    bset sdc_status, #F_SDC_TO
    return
2:
    mov.b W0, [W4++]
3:  cp0 W3
    bra nz, 4f
    return
4:  spi_read
    mov.b W0,[W4++]
    dec W3,W3
    bra 3b
    
    
    
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

;;;;;;;;;;;;;;;;;;;;;;;;;    
;initialisation carte SD 
;ref: http://elm-chan.org/docs/mmc/pic/sdinit.png    
;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "SDCINIT",7,,SDCINIT
    clr sdc_status
    btsc SDC_PORT,#SDC_DETECT
    return
    bset sdc_status,#F_SDC_IN
    mov #SPI_CLK_137KHZ,W1
    call set_spi_clock
    call dummy_clock
    _enable_sdc
    ;envoie CMD0
    mov #GO_IDLE_STATE,W0
    clr W1
    clr W2
    clr W3
    mov #sdc_R,W4
    call sdc_cmd
    
    NEXT
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; entrée: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RSTORE",6,,RSTORE ; ( addr-bloc addr-sramL addr-sramH n -- )
    SET_EDS
    _enable_sram
    mov #RWRITE,W0
    spi_write
    mov T, W1 ; nombre d'octets
    DPOP
    call spi_send_address
    mov T, W2 ; adresse bloc RAM
    DPOP
1:
    cp0 W1
    bra z, 2f
    mov.b [W2++], W0
    spi_write
    dec W1,W1
    bra 1b
2:    
    _disable_sram
    RESET_EDS
    NEXT


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM SPI vers la RAM du MCU
; entrée: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie: aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",5,,RLOAD ; ( addr-bloc addr-sramL addr-sramH n -- )
    _enable_sram
    mov #RREAD, W0
    spi_write
    mov T, W1 ; nombre d'octets à transférer
    DPOP
    call spi_send_address
    mov T, W2 ; adresse bloc RAM
    DPOP
1:    
    cp0 W1
    bra z, 3f
    spi_read
    mov.b W0, [W2++]
    dec W1,W1
    bra 1b
3:
    _disable_sram
    NEXT
  
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement bloc RAM dans EEPROM
; entrée: bloc-adress, page
; l'eeprom est organisée en 512 pages de
; 256 octets.
; l'accès est fait par page, s'il y a
; moins de 256 octets d'écris dans la page
; ceux-ci sont inscris au début de la page.    
; argumesnts:
;   'addr-bloc' est le début du bloc RAM
;   'page' est le numéro de page dans l'EEPROM
;   'n+' est le nombre d'octets à écrire: {1-255}    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ESTORE",6,,ESTORE  ;( addr-bloc page n+ -- )
    SET_EDS
    call wait_wip0 ; on s'assure qu'il n'y a pas une écrire en cours
    _enable_eeprom
    mov #EWREN, W0
    spi_write
    _disable_eeprom
    nop
    _enable_eeprom
    mov #EWRITE, W0
    spi_write
    mov T,W3
    and #255,W3
    DPOP
    sl  T, #8, T
    DPUSH
    clr T
    rlc T,T
    call spi_send_address
    mov T, W2 ; addr-bloc
    DPOP
    cp0 W3
    bra z, 9f
1:
    mov.b [W2++], W0
    spi_write
    dec W3,W3
    bra nz, 1b
9:  _disable_eeprom
    RESET_EDS
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; charque une page EEPROM
; en mémoire RAM
; arguments:
;   'addr-bloc' début RAM
;   'page' page EEPROM contenant l'information
;   'n+' nombre d'octets à lire    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "ELOAD",5,,ELOAD   ; ( addr-bloc page n+ -- )
    call wait_wip0 ; on s'assure qu'il n'y a pas une écrire en cours
    _enable_eeprom
    mov #EREAD, W0
    spi_write
    mov T,W3
    and #255,W3
    DPOP
    sl  T, #8, T
    DPUSH
    clr T
    rlc T,T
    call spi_send_address
    mov T, W2 ; addr-bloc
    DPOP
    cp0 W3
    bra z, 9f
1:
    spi_read
    mov.b W0, [W2++]
    dec W3,W3
    bra nz, 1b
9:  _disable_eeprom
    NEXT
    

; efface le contenu de l'EEPROM    
DEFCODE "ERASE",5,,ERASE ; ( -- )
    call wait_wip0
    _enable_eeprom
    mov #EWREN, W0
    spi_write
    _disable_eeprom
    nop
    _enable_eeprom
    mov #ECE, W0
    spi_write
    _disable_eeprom
    NEXT

;sauvegarde au début de l'EEPROM
;les valeurs de SYSLATEST,LATEST et DP
DEFWORD "USAVE",5,,USAVE ; ( -- )
    .word ULIMIT,DUP 
    .word SYSLATEST,FETCH, OVER, STORE
    .word CELLPLUS, LATEST,FETCH,OVER,STORE
    .word HERE,SWAP,CELLPLUS,STORE
    .word LIT,0,LIT,3,CELLS,ESTORE
    .word EXIT
    
;initialisze les variables système avec les
;valeur en page 0 de l'EEPROM
; SYSLATEST,LATEST,DP
DEFWORD "ULOAD",5,,ULOAD ;  ( -- )
    .word ULIMIT,DUP,LIT,0,LIT,3,CELLS,ELOAD
    .word DUP,EFETCH,SYSLATEST,STORE
    .word CELLPLUS,DUP,EFETCH,LATEST,STORE
    .word CELLPLUS,EFETCH,DP,STORE
    .word EXIT
    
    
; retourne le plus petit de 
;  256 et HERE-addr
DEFWORD "BYTESLEFT",9,,BYTESLEFT ; ( addr -- n )
    .word HERE,SWAP,MINUS,LIT,256
    .word MIN, EXIT
    
;sauvegarde d'une page de data_space
; arguments:
;   'addr'  adresse début
;   'page'  page EEPROM    
; sortie:
;   'n' nombre d'octets écris
DEFWORD "PSAVE",5,,PSAVE ; ( addr page -- n )
    .word OVER,BYTESLEFT,DUP,TOR
    .word ESTORE,RFROM,EXIT 
    
    
;chargement d'une page dans data_space
; arguments:
;   'addr'  adresse début
;   'page'  page EEPROM    
; sortie:
;   'n' nombre d'octets lus
DEFWORD "PLOAD",5,,PLOAD ; ( addr page -- n )
    .word OVER,BYTESLEFT,DUP,TOR
    .word ELOAD,RFROM,EXIT
    

    
DEFWORD "DSAVE",5,,DSAVE ; ( -- )
    .word USAVE,LIT,1,TOR,DP0
1:  .word DUP, RFROM,DUP,ONEPLUS,TOR
    .word PSAVE,QDUP,ZBRANCH,9f-$
    .word PLUS,1b-$
9:  .word RFROM,TWODROP,EXIT  
 
;chargement d'une page de data_space
; argument  
;chargement d'une image à partir de l'EEPROM  
DEFWORD "DLOAD",5,,DLOAD ; ( -- )
    .word ULOAD,LIT,1,TOR,DP0
1:  .word DUP,RFROM,DUP,ONEPLUS,TOR
    .word PLOAD,QDUP,ZBRANCH,9f-$
    .word PLUS,BRANCH,1b-$
9:  .word RFROM,TWODROP,EXIT    
    