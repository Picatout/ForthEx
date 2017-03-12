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
;Description:  interface avec les m�moire externe SPIRAM et SPIEEPROM
;Date: 2015-10-06
    
.include "store.inc"
    
.section .hardware.bss  bss
sdc_status: .space 2 ; indicateur bool�ens carte SD
sdc_size: .space 4 ; nombre de secteurs de 512 octets
sdc_R: .space 5; r�ponse de la carte 
 
INTR
;la broche SDC_DETECT
; a chang�e d'�tat
; carte ins�r�e ou retir�e. 
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
    ; SDC_SEL  s�lection carte SD interface SPI
    ; SRAM_SEL s�lection RAM SPI
    ; EEPROM_SEL s�lection EEPROM SPI
    ; STR_CLK  signal clock SPI
    ; STR_MOSI signal MOSI SPI
    mov #((1<<SDC_SEL)+(1<<SRAM_SEL)+(1<<EEPROM_SEL)), W0
    ior STR_LAT
    mov #~((1<<STR_CLK)+(1<<STR_MOSI)),W0
    and STR_LAT
    mov #~((1<<SDC_SEL)+(1<<SRAM_SEL)+(1<<EEPROM_SEL)+(1<<STR_CLK)+(1<<STR_MOSI)),W0
    and STR_TRIS
    ; initialisation d�tection carte SD
    bset SDC_CNEN,#SDC_DETECT
    mov #~(7<<SDC_CNIP),W0
    and SDC_IPC
    mov #(3<<SDC_CNIP),W0
    ior SDC_IPC
    bset SDC_IEC,#SDC_IE
    bclr SDC_IFS,#SDC_IF
    ; configuration SPI
    mov #(1<<MSTEN)|(1<<CKE)|SCLK_FAST, W0 
    mov W0, STR_SPICON1
;    bset STR_SPICON2, #SPIBEN ; enhanced mode
    _enable_spi
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; configure la fr�quence clock SPI
; entr�e: W1 contient la nouvelle valeur
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
; la carte est d�s�lectionn�e
; pendant cette proc�dure
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
; d�s�lection de la carte SD
; 1 octet doit-�tre envoy�e
; apr�s que CS est ramen� � 1
; pour lib�r� la ligne MISO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
sdc_deselect:
    _disable_sdc
    mov.b #0xff,W0
    spi_write
    return
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; envoie d'une commande carte SD
; entr�e: 
;    W0  index commande
;    W1  argb1b2  b15:8->byte1,b7:0->byte2
;    W2  argb3b4  b15:7->byte3,b7:0->byte4
;    W3  nombre d'octets suppl�mentaire dans la r�ponse
;    W4  pointeur buffer r�ponse    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sdc_cmd:
    mov W0,W5
    ;initialisation g�n�rateur CRC
    ;mode CRC7=x?+x�+1
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
spi_send_address: ; ( ud -- )
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
_wip0:    
    mov #ERDSR, W0
    spi_write
    spi_read
    btsc W0, #WIP
    bra _wip0
    _disable_eeprom
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
    mov #SCLK_SLOW,W1
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
; entr�e: adresse RAM, adresse SPIRAM, nombre d'octet
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
; entr�e: adresse RAM, adresse SPIRAM, nombre d'octet
; sortie: aucune
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",5,,RLOAD ; ( addr-bloc addr-sramL addr-sramH n -- )
    _enable_sram
    mov #RREAD, W0
    spi_write
    mov T, W1 ; nombre d'octets � transf�rer
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
  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   INTERFACE EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INFORMATION:
;   l'EEPROM 25LC1024 est divis�e en 
;   512 rang�es de 256 octets pour la commande EWRITE.
;   Il est possible de mette � jour 1 seul octet mais
;   on ne peut donc �crire qu'un maximum de 
;   256 octets par commande EWRITE.    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       

; test eeprom WRITE IN PROCESS bit
DEFCODE "?WIP",4,,QWIP ; ( -- f )
    _enable_eeprom
    mov #ERDSR, W0
    spi_write
    spi_read
    and	#(1<<WIP),W0
    DPUSH
    mov W0,T
    _disable_eeprom
    NEXT
    
;boucle tant l'EEPROM n'a pas termin�e
; le cycle d'�criture.    
DEFWORD "WWIP",4,,WWIP ; ( -- )
1: .word QWIP,TBRANCH,1b-$,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement d'une plage RAM dans l'EEPROM
; IMPORTANT:
;     la m�moire EEPROM est divis�e en
;     rang�es de 256 octets. Lorsque le pointeur
;     d'adresse atteint la fin d'une rang�e il 
;     revient au d�but de celle-ci. Donc si 'ud'
;     est au d�but de la rang�e un maximum de 256
;     octets peuvent-�tre �cris avant l'�crasement
;     des premiers octets. 
; arguments: 
;    'r-addr'  entier simple, adresse 16 bits d�but RAM
;    'size'  entier simple, nombre d'octets � enregistrer 
;    'ee-addr'  entier double, adresse 24 bits destination EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEWRITE",7,,EEWRITE  ;( r-addr size ee-addr -- )
    SET_EDS
    ; on s'assure qu'il n'y a pas une �crire en cours
    call wait_wip0 
    ; envoie de la commande d'authorisation d'�criture
    _enable_eeprom
    mov #EWREN, W0 
    spi_write
    _disable_eeprom
    ; envoie la commande �criture et l'adresse EEPROM
    _enable_eeprom
    mov #EWRITE, W0 ; envoide de la commande �criture
    spi_write
    call spi_send_address
    ; compte dans W1
    mov T,W1
    DPOP
    ; adresse RAM dans W2
    mov T,W2
    DPOP
1:  mov.b [W2++], W0
    spi_write
    dec W1,W1
    bra nz, 1b  
    _disable_eeprom
    RESET_EDS
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; lecture d'une plage EEPROM vers la m�moire RAM
; arguments:
;    'r-addr'  entier simple, adresse 16 bits d�but RAM
;    'size'  entier simple, nombre d'octets � lire 
;    'ee-addr'  entier double, adresse 24 bits destination EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEREAD",6,,EEREAD   ; ( addr size ud -- )
     ; on s'assure qu'il n'y a pas d'�criture en cours
    call wait_wip0
    ;envoie de la commande et de l'adresse EEPROM
    _enable_eeprom
    mov #EREAD, W0 ; envoie de la commande lecture
    spi_write
    call spi_send_address
    ; size dans W1
    mov T, W1
    DPOP
    ; adresse RAM dans W2
    mov T,W2
    DPOP
1:
    spi_read
    mov.b W0, [W2++]
    dec W1,W1
    bra nz, 1b
    _disable_eeprom
    NEXT
    
DEFCONST "EPAGE",5,,EPAGE,EPE ;efface page
DEFCONST "ESECTOR",7,,ESECTOR,ESE ; efface secteur
DEFCONST "EALL",4,,EALL,ECE    
    
; efface page/secteur/compl�tement l'EEPROM
; arguments:
;   'n' num�ro de page {0..511} ou de secteur {0..3}
;   'op' op�ration: EPAGE|ESECTOR|EALL    
DEFCODE "EERASE",6,,EERASE ; ( EALL | n {EPAGE|ESECTOR} -- )
    call wait_wip0
    _enable_eeprom
    mov #EWREN, W0
    spi_write
    _disable_eeprom
    _enable_eeprom
    mov T,W2
    DPOP
    mov W2,W0
    spi_write
    cp.b W2,#ECE
    bra z, 9f
    cp.b W2,#EPE
    bra nz,2f
    ; efface page
    mov #0x1ff,W0 ; page < 512
    and T,W0,W0
    mov #EPAGE_SIZE,W1
    bra 3f
2:  ; efface un secteur
    ; calcule l'adresse du secteur
    mov #3,W0  ; secteur < 4	
    and T,W0,W0
    mov #ESECTOR_SIZE,W1
3:  mul.uu W1,W0,W0
    mov W1,T
    mov W0,[++DSP]
    call spi_send_address ; adresse du secteur
9:  _disable_eeprom
    NEXT

; le BOOT charge en RAM une image syst�me
; *** format image boot ****
; 00 signature MAGIC, 2 octets
; 02 sauvegarde de LATEST, 2 octets
; 04 sauvegarde de DP, 2 octets  
; 06 data_size 2 octets
; 08 donn�es image d�bute ici.    
; *************************    

;v�rifie s'il y a une image sur le p�riph�rique
; d�sign� par BOOTDEV    
; retourne:
;     indicateur bool�en vrai|faux
DEFWORD "?BOOT",5,,QBOOT ; (  -- f )
    .word BTHEAD,LIT,BOOT_HEADER_SIZE,BOOTADR
    .word BOOTFN,FETCH,EXECUTE
    .word BTSIGN,FETCH,MAGIC,EQUAL
    .word EXIT
    
;retourne la taille d'une image � partir
;de l'ent�te de celle-ci charg�e dans le
; retourne:
;   'n'  taille en octets    
DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word BTSIZE,FETCH,EXIT
    
; combiens d'octets � lire/�crire dans la page suivante 
;  arguments:
;   'dp' position actuelle du pointer data
;  retourne:
;    min(EPAGE_SIZE,HERE-dp)    
;DEFWORD "?BYTES",6,,QBYTES ; ( dp -- n )
;    .word HERE,SWAP,MINUS,LIT,EPAGE_SIZE,UMIN
;    .word EXIT

;retourne l'�tat de l'op�ration de transfert
; lorsque 'dp'==DP c'est compl�t�
; arguments:
;   'dp'  pointeur de donn�e
; retourne:
;    'f'  indicateur bool�en vrai|faux    
;DEFWORD "?DONE",5,,QDONE ;  ( dp -- f )
;    .word QBYTES,ZEROEQ,EXIT

; constantes li�es au chargeur syst�me (boot loader)
DEFCONST "BTHEAD",6,,BTHEAD,BOOT_HEADER ; ent�te secteur d�marrage
DEFCONST "MAGIC",5,,MAGIC,0x55AA ; signature
DEFCONST "FBTROW",6,,FBTROW,FLASH_FIRST_ROW  ; num�ro premi�re ligne FLASH BOOT  

; champ signature    
DEFWORD "BTSIGN",6,,BTSIGN  ; ( -- addr )
    .word BTHEAD,EXIT

; champ LATEST    
DEFWORD "BTLATST",7,,BTLATST  ; ( -- addr )
    .word BTHEAD,LIT,1,CELLS,PLUS,EXIT

; champ DP    
DEFWORD "BTDP",4,,BTDP ; ( -- addr )
    .word BTHEAD,LIT,2,CELLS,PLUS,EXIT
    
; champ taille    
DEFWORD "BTSIZE",6,,BTSIZE ; ( -- addr )
    .word BTHEAD,LIT,3,CELLS,PLUS,EXIT
    
    
; initialise l'enregistrement de boot  
DEFWORD "SETHEADER",9,,SETHEADER ; ( -- )
    .word MAGIC,BTSIGN,STORE ; signature
    .word HERE,BTDP,STORE ; DP
    .word LATEST,FETCH,BTLATST,STORE ; latest
    .word HERE,DP0,MINUS,BTSIZE,STORE ; size
    .word EXIT

; �criture d'une plage RAM dans l'EEPROM externe 
; doit tenir compte des limites de plages    
; arguments:
;   'r-addr' entier simple, adresse RAM d�but
;   'size' entier simple, nombre d'octets � �crire
;   'e-addr'  entier double, adresse EEPROM d�but    
DEFWORD "RAM>EE",6,,RAMTOEE ; ( r-adr size e-addr -- )    
1:  .word TWOTOR,QDUP,ZBRANCH,8f-$
    .word TWODUP,TWORFETCH,LIT,256,UMSLASHMOD
    .word DROP,LIT,256,SWAP,MINUS,MIN,SWAP,OVER,DUP,TWORFETCH
    .word ROT,TOR,EEWRITE,RFETCH,MINUS,RFROM,TWORFROM,ROT,MPLUS
    .word BRANCH,1b-$
8:  .word DROP,TWORFROM,TWODROP
    .word EXIT

; identifiant p�riph�riques
DEFCONST "KEYBOARD",8,,KEYBOARD,_KEYBOARD ; clavier
DEFCONST "SCREEN",6,,SCREEN,_SCREEN ; �cran
DEFCONST "SERIAL",6,,SERIAL,_SERIAL ; port s�rie    
DEFCONST "XRAM",4,,XRAM,_SPIRAM ;  m�moire RAM externe
DEFCONST "EEPROM",6,,EEPROM,_SPIEEPROM ; m�moire EEPROM externe
DEFCONST "SDCARD",6,,SDCARD,_SDCARD ; carte m�moire SD
DEFCONST "MFLASH",6,,MFLASH,_MCUFLASH ; m�moire FLASH du MCU    
; op�rations    
DEFCONST "FN_READ",7,,FN_READ,0
DEFCONST "FN_WRITE",8,,FN_WRITE,1

; initialise le p�riph�rique d'autochargement
;  'dev' p�riph�rique  {MFLASH, EEPROM}
;  'fn' function    {FN_READ, FN_WRITE}
DEFWORD "SETBOOT",7,,SETBOOT  ; ( dev fn -- ) 
    .word OVER
    .word MFLASH,EQUAL,ZBRANCH,4f-$
  ; mcu flash
    .word FN_WRITE,EQUAL,ZBRANCH,2f-$
    ; op�ration �criture
    .word LIT,RAMTOFLASH,BRANCH,9f-$
    ; op�ration lecture
2:  .word LIT,FLASHTORAM,BRANCH,9f-$
  ; eeprom externe
4:  .word FN_WRITE,EQUAL,ZBRANCH,5f-$
    ;op�ration �criture
    .word LIT,RAMTOEE,BRANCH, 9f-$
    ;op�ration lecture
5:  .word LIT,EEREAD    
9:  .word BOOTFN,STORE,BOOTDEV,STORE
    .word EXIT

; initialise l'adresse boot du p�riph�rique
; ud adresse 24 bits EEPROM ou MCU_FLASH
DEFWORD "BOOTADR",7,,BOOTADR ; ( -- ud )
    .word BOOTDEV,FETCH,MFLASH,EQUAL,ZBRANCH,2f-$
    .word BOOTFN,FETCH,LIT,RAMTOFLASH,EQUAL,ZBRANCH,1f-$
    .word ERASEROWS
1:  .word FBTROW,ROWTOFADR,EXIT
2:  .word LIT,0,DUP,EXIT    
    
; sauvegarde une image boot sur un p�riph�rique
;  dev -> { MFLASH, EEPROM }  
DEFWORD ">BOOT",5,,TOBOOT ; ( dev -- )
    .word FN_WRITE,SETBOOT
    .word QEMPTY,TBRANCH,9f-$ ; si RAM vide quitte
    .word SETHEADER
    .word BTHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS,BOOTADR
    .word BOOTFN,FETCH,EXECUTE
9:  .word EXIT 

; charge une image RAM � partir du p�riph�rique d�sign�.
; dev -> { MFLASH, EEPROM }
DEFWORD "BOOT",4,,BOOT ; ( dev -- )
    .word FN_READ,SETBOOT,QBOOT,ZBRANCH,9f-$
    .word BTHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS,BOOTADR ; S: r-addr size e-addr
    .word BOOTFN,FETCH,EXECUTE
    .word BTDP,FETCH,DP,STORE 
    .word BTLATST,FETCH,LATEST,STORE
9:  .word EXIT
  