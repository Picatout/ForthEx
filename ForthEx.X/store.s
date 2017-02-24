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
  
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   INTERFACE EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INFORMATION:
;   l'EEPROM 25LC1024 est divisée en 
;   512 pages de 256 octets pour la commande EWRITE.
;   L'accès de base de l'EEPROM se fait
;   par l'intermédiaire de mémoires tampons de 256 octets
;   situées dans l'EDS (adresse commençant à $8000)    
;   Il y a 20480 octets de mémoire EDS
;   les 1536 derniers sont occupés par
;   le tampon vidéo. Il reste donc 18944 octets pour
;   les tampons EEPROM, donc il de l'espace pour 74 tampons
;   de 256 octets. l'interface EEPROM utilises les 4 premiers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;       
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement tampon dans l'EEPROM
; arguments: 
;    'tampon' est le numéro du tampon {0-63}
;    'page'   page EEPROM destination    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEWRITE",7,,EEWRITE  ;( tampon page -- )
    SET_EDS
    call wait_wip0 ; on s'assure qu'il n'y a pas une écrire en cours
    _enable_eeprom
    mov #EWREN, W0 ; envoie de la commande d'authorisation d'écriture
    spi_write
    _disable_eeprom
    nop
    _enable_eeprom
    mov #EWRITE, W0 ; envoide de la commande écriture
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
    add T,W2,W2 ; addresse début tampon: 0x8000+#tampon*256
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
;   'tampon' numéro du tampon
;   'page' page EEPROM à lire
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEREAD",6,,EEREAD   ; ( tampon page -- )
     ; on s'assure qu'il n'y a pas d'écriture en cours
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
    

; efface le contenu d'un secteur de l'EEPROM
; ou toute l'EEPROM si n=-1    
DEFCODE "EERASE",6,,EERASE ; ( n -- )
    call wait_wip0
    _enable_eeprom
    mov #EWREN, W0
    spi_write
    _disable_eeprom
    nop
    _enable_eeprom
    inc T,W0
    cp0 W0
    bra nz,8f
    DPOP
    mov #ECE, W0
    spi_write
    bra 9f
8:  ; efface un secteur
    ; calcule l'adresse du secteur
    and #3,T
    mov #ESECTOR_SIZE,W0
    mul.uu T,W0,W0
    mov W1,T
    mov W0,[++DSP]
    mov #ESE, W0 ; commande SECTOR ERASE
    spi_write
    call spi_send_address ; adresse du secteur
9:  _disable_eeprom
    NEXT

; *** format image ****
;entête d'image:
; page 0    
; 00 signature 0xAA55, 2 octets
; 02 sauvegarde de LATEST, 2 octets
; 04 sauvegarde de DP, 2 octets  
; 06 data_size 1 octet
; 07-255 data
; pages suivantes:
; 00 data_size 0-255, 1 octet
; 01-255 data    
; *************************    

;vérifie s'il y a une image présente
; dans le secteur EEPROM
; arguments:
;   #t numéro du tampon utilisé pour la lecture
;   #s  numéro de page    
DEFWORD "?IMG",4,,QIMG ; ( #t #page -- f )
    .word OVER,TOR ; garde une copie de #tampon
    .word EEREAD,RFROM, BUFADDR, EFETCH,LIT,0xAA55 ; vérification signature
    .word EQUAL,EXIT 
 
; le tampon contient la premier page
; d'une image. restaure LATEST et DP
; et charge les données à la position DP0 
;  argument:
;   '#t' no du tampon    
;  retourne:
;   '*d' position du pointer data après la copie    
DEFWORD "PG0>",4,,PG0LOAD ; ( #t -- *d )
    ; lecture de l'entête
    .word LIT,2,OVER,BUFFERFETCH,LATEST,STORE ; restaure LATEST
    .word LIT,4,OVER,BUFFERFETCH,DP,STORE  ; restaure DP
    .word LIT,6,OVER,BUFFERCFETCH,TOR   ; nombre d'octet à lire dans la page
    ; copie du tampon dans le data_space à partir de DP0
    .word BUFADDR,LIT,7,PLUS; saute l'entête
    .word DP0,RFETCH,CMOVE ; buffer+ofs dest compte
    .word DP0,RFROM,PLUS,EXIT

; copie le contenu du tampon dans le dataspace    
; arguments:
;   '*d' pointeur data
;   '#t' no du tampon 
; retourne:
;   '*d'  pointeur data mis à jour    
DEFWORD "BUF>DAT",7,,BUFTODAT ; ( #t *d -- *d' )
    .word TOR,DUP,BUFADDR,CEFETCH ; S: #t n  R: *d
    .word SWAP,BUFADDR,ONEPLUS,SWAP,RFETCH,SWAP
    .word DUP,TOR,CMOVE
    .word RFROM,RFROM,PLUS,EXIT
    
; convertie le no de secteur en no de page EEPROM
; argument: 
;   '#s' numéro de secteur 
; retourne:
;   '#p' numéro de page    
DEFWORD "S>P",3,,SECTOPG ; ( #s -- #p )
    .word LIT,3,AND ; #s<4
    .word LIT,EPG_SECTOR,STAR,EXIT
    
; charge une image à partir d'un secteur 
; de l'EEPROM
; l'EEPROM 25LC1024 a 4 secteurs de 32K
; arguments:
;   '#t' est numéro du tampon {0..63}    
;   '#s' est le numéro de secteur {0..3}    
DEFWORD "IMG>",4,,IMGLOAD ; ( #t #s -- )
    .word SECTOPG ; secteur>page  S: #t #p
    .word TWODUP,QIMG, ZBRANCH, 8f-$
    .word CLEAR ; efface l'image en mémoire
    .word OVER,PG0LOAD ; S: #t #p *data
1:  .word DUP,HERE,EQUAL,ZBRANCH,2f-$
    .word DROP,BRANCH,8f-$
2:  .word TOR,ONEPLUS,TWODUP,EEREAD ; charge la page suivante  S: #t #p  R: *data
    .word OVER,RFETCH,BUFTODAT ; S: #t #p *data 
    .word BRANCH,1b-$
8:  .word TWODROP    
9:  .word EXIT    
    
    
; s'il y a une image dans le secteur 0
; la charge en mémoire
; le secteur 0 est le 'BOOT SECTOR'    
DEFWORD "BOOT",8,,BOOTLOAD ; ( --  )
    .word LIT,0,DUP,IMGLOAD,EXIT
    
; écriture de la page 0 de l'EEPROM
; à partir du tampon désigné.
;DEFWORD "BOOTSAVE",8,,BOOTSAVE ; ( tampon -- )
;    .word LIT,0,EEWRITE,EXIT
    
    
; retourne le plus petit de 
;  256 et HERE-addr
DEFWORD "BYTESLEFT",9,,BYTESLEFT ; ( addr -- n )
    .word HERE,SWAP,MINUS,LIT,256
    .word MIN, EXIT


;écris la page zéro de l'image
; retourne la nouvelle valeur du pointeur data    
DEFWORD "PG0WRITE",8,,PG0WRITE ; ( #t #p -- n )
    .word OVER,BUFADDR,LIT,0xAA55,OVER,STORE ; signature
    .word CELLPLUS,LATEST,FETCH,OVER,STORE ; sauvegarde de LATEST
    .word CELLPLUS,HERE,OVER,STORE ; sauvegarde de DP
    .word CELLPLUS,HERE,DP0,MINUS,LIT,EPAGE_SIZE,LIT,7,MINUS
    .word MIN,DUP,TOR,OVER,CSTORE,ONEPLUS,DP0,SWAP,RFETCH,CMOVE
    .word EEWRITE,RFROM,DP0,PLUS,EXIT
 
;écris la page suivante dans l'EEPROM
; arguments:
;   '#t' no de tampon
;   '#p' no de page
;   '*d' pointeur data
; retourne:
;     '*d' pointeur data mis à jour
DEFWORD "EWRNEXT",7,,EWRNEXT ; ( #t #p *d -- *d' )
    ; copie du data dans le tampon
    .word TOR ; préserve *d ,  S: #t #p R: *d
    .word OVER,BUFADDR,RFETCH ; S: #t #p *buff *d  R: *d
    .word HERE,OVER,MINUS,LIT,EPAGE_SIZE,ONEMINUS,MIN,TOR ; S: #t #p *buff *d  R: *d n
    .word RFETCH,LIT,2,PICK,CSTORE,TOR,ONEPLUS,RFROM,RFETCH,CMOVE
    .word EEWRITE,RFROM,RFROM,PLUS,EXIT
    
    
; sauvarge une image dans l'EEPROM
; arguments:
;   '#t' numéro de tampon à utiliser
;   '#s' numéro de secteur à utiliser    
DEFWORD ">IMG",4,,TOIMG ; ( #t #s -- )
    .word SYSLATEST,FETCH,LATEST,FETCH,EQUAL,ZBRANCH,2f-$
1:  .word TWODROP,EXIT ; mémoire vide
2:  .word SECTOPG,TWODUP,PG0WRITE  ; #t #p n
3:  .word DUP,HERE,EQUAL,ZBRANCH,4f-$
    .word DROP,BRANCH,1b-$ ; écriture image complétée
4:  .word DUP,HERE,OVER,MINUS,LIT,EPAGE_SIZE,ONEMINUS,MIN
    .word TOR,TOR,OVER,BUFADDR,RFROM,SWAP,RFETCH,CMOVE
    