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
    mov #((1<<SDC_SEL)+(1<<SRAM_SEL)+(1<<EEPROM_SEL)+(1<<STR_CLK)+(1<<STR_MOSI)), W0
    ior STR_LAT
    com W0,W0
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
    mov #(1<<MSTEN)|(1<<CKE)|SPI_CLK_17MHZ, W0 ; SCLK=FCY/4
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
;   512 pages de 256 octets pour la commande EWRITE.
;   L'acc�s de base de l'EEPROM se fait
;   par l'interm�diaire de m�moires tampons de 256 octets
;   situ�es dans l'EDS (adresse commen�ant � $8000)    
;   Il y a 20480 octets de m�moire EDS
;   les 1536 derniers sont occup�s par
;   le tampon vid�o. Il reste donc 18944 octets pour
;   les tampons EEPROM, donc il de l'espace pour 74 tampons
;   de 256 octets. l'interface EEPROM utilises les 4 premiers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement tampon dans l'EEPROM
; arguments: 
;    'tampon' est le num�ro du tampon {0-63}
;    'page'   page EEPROM destination    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEWRITE",7,,EEWRITE  ;( tampon page -- )
    SET_EDS
    call wait_wip0 ; on s'assure qu'il n'y a pas une �crire en cours
    _enable_eeprom
    mov #EWREN, W0 ; envoie de la commande d'authorisation d'�criture
    spi_write
    _disable_eeprom
    nop
    _enable_eeprom
    mov #EWRITE, W0 ; envoide de la commande �criture
    spi_write
    and #511,T ; limite: page < 512
    sl  T, #8, T ; bits 0:15 addresse EEPROM de la page
    DPUSH
    clr T
    rlc T,T   ; bit 16 de l'adresse EEPROM
    call spi_send_address
    and #63,T ; limite: tampon < 64
    sl T,#8,T ; offset tampon
    mov #EDS_BASE,W2  ; 0x8000 
    add T,W2,W2 ; addresse d�but tampon: 0x8000+#tampon*256
    DPOP
    mov #BUFF_SIZE,W3 ; dimension du tampon en octets
1:  mov.b [W2++], W0
    spi_write
    dec W3,W3
    bra nz, 1b
9:  _disable_eeprom
    RESET_EDS
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; lecture d'une page EEPROM dans un tampon
; arguments:
;   'tampon' num�ro du tampon
;   'page' page EEPROM � lire
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEREAD",6,,EEREAD   ; ( tampon page -- )
     ; on s'assure qu'il n'y a pas d'�criture en cours
    call wait_wip0
    _enable_eeprom
    mov #EREAD, W0 ; envoie de la commande lecture
    spi_write
    ;calcul et envoie de l'adresse EEPROM
    and #511,T ; limite: page < 512
    sl  T, #8, T  
    DPUSH
    clr T
    rlc T,T
    call spi_send_address
    ; calcul de l'adresse tampon
    ; 0x8000+#tampon*256
    and #63,T  ; limite: tampon < 64
    sl T,#8,T  
    mov #EDS_BASE,W2
    add T, W2,W2 
    DPOP
    mov #BUFF_SIZE,W3 ; dimension tampon
1:
    spi_read
    mov.b W0, [W2++]
    dec W3,W3
    bra nz, 1b
9:  _disable_eeprom
    NEXT
    
DEFCONST "MAGIC",5,,MAGIC,0x55AA ; signature
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
    nop
    _enable_eeprom
    mov T,W2
    DPOP
    mov W2,W0
    spi_write
    cp W2,#ECE
    bra z, 9f
    cp W2,#EPE
    bra nz,2f
    ; efface page
    mov #511,W0 ; page < 512
    and T,W0,W0
    mov EPAGE_SIZE,W1
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
; si la page 0 indique la pr�sence d'une telle image    
; *** format image boot ****
; page 0, ent�te d'image    
; 00 signature MAGIC, 2 octets
; 02 sauvegarde de LATEST, 2 octets
; 04 sauvegarde de DP, 2 octets  
; 06 data_size 2 octets
; 08-255 pas utilis�   
;    
; pages suivantes:
; 0-255 data
; *************************    

;v�rifie s'il y a une image boot
; retourne vrai|faux    
DEFWORD "?BOOT",5,,QBOOT ; (  -- f )
    .word LIT,0,DUP,DUP,EEREAD
    .word BUFADDR, EFETCH,MAGIC ; v�rification signature
    .word EQUAL,EXIT 

; combiens d'octets � �crire dans la page suivante 
;  arguments:
;   'dp' position actuelle du pointer
;  retourne:
;    min(EPAGE_SIZE,HERE-dp)    
DEFWORD "BYTESLEFT",9,,BYTESLEFT ; ( dp -- n )
    .word HERE,SWAP,MINUS,LIT,EPAGE_SIZE,MIN
    .word EXIT
    
; lecture de l'ent�te d'image
; r�initialise LATEST et DP
; retourne:
;    'n'  grandeur de l'image en octet    
DEFWORD "BOOTHEAD",8,,BOOTHEAD ; ( -- n )
    .word LIT,0,LIT,2,OVER,BUFFERFETCH,LATEST,STORE ; restaure LATEST
    .word LIT,4,OVER,BUFFERFETCH,DP,STORE  ; restaure DP
    .word LIT,6,SWAP,BUFFERCFETCH,EXIT

; charge la page EEPROM � la position de dp
; arguments:
;   'n' nombre d'octets restant � charger
;   'dp' pointeur de donn�e
;   'p' page eeprom � lire    
DEFWORD "PGLOAD",6,,PGLOAD ; ( n dp p -- n' )
    .word LIT,0,SWAP,EEREAD ; n dp
    .word OVER,LIT,EPAGE_SIZE,MIN ; n dp n' 
    .word DUP,TOR,LIT,0,BUFADDR,NROT,CMOVE
    .word RFROM,DUP,ALLOT,MINUS,EXIT
    
; s'il y a une image syst�me au d�but de l'EEPROM
; la charge en m�moire
DEFWORD "BOOT",4,,BOOT ; ( --  )
    .word QBOOT,ZBRANCH,9f-$
    .word CLEAR,BOOTHEAD,LIT,1,TOR
1:  .word DUP,ZBRANCH,8f-$
    .word HERE,RFROM,DUP,ONEPLUS,TOR
    .word PGLOAD,BRANCH,1b-$
8:  .word RFROM,TWODROP    
9:  .word EXIT
    
    
; copie le contenu du tampon dans le dataspace    
; arguments:
;   '*d' pointeur data
;   '#t' no du tampon 
; retourne:
;   '*d'  pointeur data mis � jour    
DEFWORD "BUF>DAT",7,,BUFTODAT ; ( #t *d -- *d' )
    .word TOR,DUP,BUFADDR,CEFETCH ; S: #t n  R: *d
    .word SWAP,BUFADDR,ONEPLUS,SWAP,RFETCH,SWAP
    .word DUP,TOR,CMOVE
    .word RFROM,RFROM,PLUS,EXIT
    
; convertie le no de secteur en no de page EEPROM
; argument: 
;   '#s' num�ro de secteur 
; retourne:
;   '#p' num�ro de page    
DEFWORD "S>P",3,,SECTOPG ; ( #s -- #p )
    .word LIT,3,AND ; #s<4
    .word LIT,EPG_SECTOR,STAR,EXIT
    
    
    
;�cris l'ent�te du boot sector, et retourne
; la grandeur de l'image.    
DEFWORD "HEADWRITE",9,,HEADWRITE ; ( -- dp )
    .word MAGIC,LIT,0,DUP,BUFFERSTORE ; signature
    .word LATEST,FETCH,LIT,2,LIT,0,BUFFERSTORE 
    .word HERE,LIT,4,LIT,0,BUFFERSTORE
    .word HERE,DP0,MINUS,LIT,6,LIT,0,BUFFERSTORE
    .word LIT,0,DUP,EEWRITE,DP0,EXIT
    
;�cris la page suivante dans l'EEPROM
; arguments:
;   'n' octets restant � �crire
;   'dp' pointeur data
;   'p' no de page EEPROM
; retourne:
;     'p+1'  page EEPROM suivante
;     'dp+n'  position de dp actualis�e
DEFWORD "PGWRITE",7,,PGWRITE ; ( p dp n -- p+1 dp+n )
    ; copie du data dans le tampon
    .word TWODUP,PLUS,TOR; sauvegarde dp+n S: p dp n  R: dp+n
    .word LIT,0,BUFADDR,SWAP,CMOVE ; S: p R: dp+n   
    .word LIT,0,OVER,EEWRITE ; S: p R: dp+n
    .word ONEPLUS,RFROM,EXIT ; S: p+1 dp+n R:
    
; sauvarge une image au d�but de l'EEPROM
DEFWORD ">BOOT",5,,TOBOOT ; ( -- )
    .word SYSLATEST,FETCH,LATEST,FETCH,EQUAL,ZBRANCH,1f-$
    .word EXIT ; m�moire vide
    .word LIT,1 ; S: p
1:  .word HEADWRITE ; S: p dp
2:  .word DUP,BYTESLEFT,QDUP,ZBRANCH,9f-$ ; S: p dp n 
    .word PGWRITE,BRANCH,2b-$   
9:  .word TWODROP,EXIT 
