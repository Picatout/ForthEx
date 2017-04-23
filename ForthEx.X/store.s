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
    mov #((1<<SDC_SEL)+(1<<SRAM_SEL)+(1<<EEPROM_SEL)), W0
    ior STR_LAT
    mov #~((1<<STR_CLK)+(1<<STR_MOSI)),W0
    and STR_LAT
    mov #~((1<<SDC_SEL)+(1<<SRAM_SEL)+(1<<EEPROM_SEL)+(1<<STR_CLK)+(1<<STR_MOSI)),W0
    and STR_TRIS
    ; initialisation détection carte SD
    bset SDC_CNEN,#SDC_DETECT
    mov #~(7<<SDC_CNIP),W0
    and SDC_IPC
    mov #(3<<SDC_CNIP),W0
    ior SDC_IPC
    bset SDC_IEC,#SDC_IE
    bclr SDC_IFS,#SDC_IF
    btss SDC_PORT,#SDC_SEL
    bset sdc_status,#F_SDC_IN
    ; configuration SPI
    mov #(1<<MSTEN)|(1<<CKE)|SCLK_FAST, W0 
    mov W0, STR_SPICON1
;    bset STR_SPICON2, #SPIBEN ; enhanced mode
    _enable_spi
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; configure la fréquence clock SPI
; entrée: W1 contient la nouvelle valeur
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
set_spi_clock:
;    _disable_spi
    mov #0xFFE0,W0
    and STR_SPICON1
    mov W1,W0
    ior STR_SPICON1
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; vérifie si le bit WIP (Write In Progress)
; est actif et attend
; qu'il revienne à zéro.
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
 
    
;;;;;;;;;;;;;;;
;  Forth words
;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; arguments: 
;    u1  adresse bloc RAM
;    n+  nombre d'octets
;    ud1  adresse SPIRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RSTORE",6,,RSTORE ; ( u1 n+ ud1 -- )
    SET_EDS
    _enable_sram
    mov #RWRITE,W0
    spi_write
    call spi_send_address
    mov T, W1 ; nombre d'octets
    DPOP
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
; arguments: 
;    u1  adresse bloc RAM
;    n+  nombre d'octets
;    ud1  adresse SPIRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "RLOAD",5,,RLOAD ; ( u1 n+ ud1 -- )
    _enable_sram
    mov #RREAD, W0
    spi_write
    call spi_send_address
    mov T, W1 ; nombre d'octets à transférer
    DPOP
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
;   512 rangées de 256 octets pour la commande EWRITE.
;   Il est possible de mette à jour 1 seul octet mais
;   on ne peut donc écrire qu'un maximum de 
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
    
;boucle tant l'EEPROM n'a pas terminée
; le cycle d'écriture.    
DEFWORD "WWIP",4,,WWIP ; ( -- )
1: .word QWIP,TBRANCH,1b-$,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enregistrement d'une plage RAM dans l'EEPROM
; IMPORTANT:
;     la mémoire EEPROM est divisée en
;     rangées de 256 octets. Lorsque le pointeur
;     d'adresse atteint la fin d'une rangée il 
;     revient au début de celle-ci. Donc si 'ud'
;     est au début de la rangée un maximum de 256
;     octets peuvent-être écris avant l'écrasement
;     des premiers octets. 
; arguments: 
;    'r-addr'  entier simple, adresse 16 bits début RAM
;    'size'  entier simple, nombre d'octets à enregistrer 
;    'ee-addr'  entier double, adresse 24 bits destination EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEWRITE",7,,EEWRITE  ;( r-addr size ee-addr -- )
    SET_EDS
    ; on s'assure qu'il n'y a pas une écrire en cours
    call wait_wip0 
    ; envoie de la commande d'authorisation d'écriture
    _enable_eeprom
    mov #EWREN, W0 
    spi_write
    _disable_eeprom
    ; envoie la commande écriture et l'adresse EEPROM
    _enable_eeprom
    mov #EWRITE, W0 ; envoide de la commande écriture
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
; lecture d'une plage EEPROM vers la mémoire RAM
; arguments:
;    'r-addr'  entier simple, adresse 16 bits début RAM
;    'size'  entier simple, nombre d'octets à lire 
;    'ee-addr'  entier double, adresse 24 bits destination EEPROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "EEREAD",6,,EEREAD   ; ( r-addr size ud -- )
     ; on s'assure qu'il n'y a pas d'écriture en cours
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
    
; efface page/secteur/complètement l'EEPROM
; arguments:
;   'n' numéro de page {0..511} ou de secteur {0..3}
;   'op' opération: EPAGE|ESECTOR|EALL    
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

; IMG>RAM charge en RAM une image système
; *** format image boot ****
; 00 signature MAGIC, 2 octets
; 02 sauvegarde de LATEST, 2 octets
; 04 sauvegarde de DP, 2 octets  
; 06 data_size 2 octets
; 08 données image débute ici.    
; *************************    

;vérifie s'il y a une image sur le périphérique
; désigné par BOOTDEV    
; retourne:
;     indicateur booléen vrai|faux
DEFWORD "?IMG",4,,QIMG ; (  -- f )
    .word BTHEAD,LIT,BOOT_HEADER_SIZE,FN_IMGFROM,DUP,BOOTADR
    .word ROT,BOOTDEV,FETCH,TBLFETCH,EXECUTE
    .word BTSIGN,TBLFETCH,MAGIC,EQUAL
    .word EXIT
    
;retourne la taille d'une image à partir
;de l'entête de celle-ci. 
; retourne:
;   'n'  taille en octets    
DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word BTSIZE,TBLFETCH,EXIT
    
; combiens d'octets à lire/écrire dans la page suivante 
;  arguments:
;   'dp' position actuelle du pointer data
;  retourne:
;    min(EPAGE_SIZE,HERE-dp)    
;DEFWORD "?BYTES",6,,QBYTES ; ( dp -- n )
;    .word HERE,SWAP,MINUS,LIT,EPAGE_SIZE,UMIN
;    .word EXIT

;retourne l'état de l'opération de transfert
; lorsque 'dp'==DP c'est complété
; arguments:
;   'dp'  pointeur de donnée
; retourne:
;    'f'  indicateur booléen vrai|faux    
;DEFWORD "?DONE",5,,QDONE ;  ( dp -- f )
;    .word QBYTES,ZEROEQ,EXIT

; constantes liées au chargeur système (boot loader)
DEFCONST "BTHEAD",6,,BTHEAD,BOOT_HEADER ; entête secteur démarrage
DEFCONST "MAGIC",5,,MAGIC,0x55AA ; signature
DEFCONST "FBTROW",6,,FBTROW,FLASH_FIRST_ROW  ; numéro première ligne FLASH BOOT  

; champ signature    
DEFWORD "BTSIGN",6,,BTSIGN  ; ( -- addr )
    .word LIT,0,BTHEAD,EXIT

; champ LATEST    
DEFWORD "BTLATST",7,,BTLATST  ; ( -- addr )
    .word LIT,1,BTHEAD,EXIT

; champ DP    
DEFWORD "BTDP",4,,BTDP ; ( -- addr )
    .word LIT,2,BTHEAD,EXIT
    
; champ taille    
DEFWORD "BTSIZE",6,,BTSIZE ; ( -- addr )
    .word LIT,3,BTHEAD,EXIT
    
    
; initialise l'entête d'image  
DEFWORD "SETHEADER",9,,SETHEADER ; ( -- )
    .word MAGIC,BTSIGN,TBLSTORE ; signature
    .word HERE,BTDP,TBLSTORE ; DP
    .word LATEST,FETCH,BTLATST,TBLSTORE ; latest
    .word HERE,DP0,MINUS,BTSIZE,TBLSTORE ; size
    .word EXIT

; écriture d'une plage RAM dans l'EEPROM externe 
; doit tenir compte des limites de plages    
; arguments:
;   'r-addr' entier simple, adresse RAM début
;   'size' entier simple, nombre d'octets à écrire
;   'e-addr'  entier double, adresse EEPROM début    
DEFWORD "RAM>EE",6,,RAMTOEE ; ( r-adr size e-addr -- )    
1:  .word TWOTOR,QDUP,ZBRANCH,8f-$
    .word TWODUP,TWORFETCH,LIT,256,UMSLASHMOD
    .word DROP,LIT,256,SWAP,MINUS,MIN,SWAP,OVER,DUP,TWORFETCH
    .word ROT,TOR,EEWRITE,RFETCH,MINUS,RFROM,TWORFROM,ROT,MPLUS
    .word BRANCH,1b-$
8:  .word DROP,TWORFROM,TWODROP
    .word EXIT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
; descripteurs de périphérique ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; il s'agit d'une structure de données
; contenants les pointeurs de fonctions
; des périphériques    
;  champs:
;   identifiant
;   XT lecture
;   XT écriture
;   XT autre fonction
;   ...
    
; descripteur SPIRAM    
DEFTABLE "XRAM",4,,XRAM
    .word _SPIRAM ; RAM SPI externe
    .word RLOAD   ; lecture
    .word RSTORE  ; écriture
    .word RLOAD   ; IMG>
    .word RSTORE  ; >IMG
    
; descripteur clavier
DEFTABLE "KEYBOARD",8,,KEYBOARD
    .word _KEYBOARD ; clavier
    .word KEY       ; lecture du clavier
    .word KBD_RESET ; réinitialiation du clavier
    .word EKEY      ; lecture canonique du clavier
    .word NOP
    
; descripteur écran    
DEFTABLE "SCREEN",6,,SCREEN
    .word _SCREEN ; écran
    .word SCRCHAR ; 
    .word PUTC
    .word NOP
    .word NOP
    
; descripteur port sériel    
DEFTABLE "SERIAL",6,,SERIAL
    .word _SERIAL ; port série
    .word VTKEY  ;
    .word SPUTC  ;
    .word SGETC  ; lecture canonique du port sériel
    .word NOP
    
; descripteur EEPROM SPI    
DEFTABLE "EEPROM",6,,EEPROM
    .word _SPIEEPROM ; mémoire EEPROM externe
    .word EEREAD
    .word EEWRITE
    .word EEREAD     ;IMG>
    .word RAMTOEE    ;>IMG
    .word EEMOUNT    ; monte le système de fichier EEFS
    .word EEUMOUNT   ; démonte le système de fichier EEFS
    
; descripteur carte Secure Digital    
DEFTABLE "SDCARD",6,,SDCARD
    .word _SDCARD ; carte mémoire SD
    .word SDCREAD
    .word SDCWRITE
    .word SDCTOIMG  ; IMG>
    .word IMGTOSDC  ; >IMG
    
; descripteur mémoire FLASH MCU    
DEFTABLE "MFLASH",6,,MFLASH
    .word _MCUFLASH ; mémoire FLASH du MCU    
    .word TBLFETCHL
    .word TOFLASH
    .word FLASHTORAM
    .word RAMTOFLASH
    
; acceseurs de champs    
DEFCONST "DEVID",5,,DEVID,0    
; opérations    
DEFCONST "FN_READ",7,,FN_READ,1
DEFCONST "FN_WRITE",8,,FN_WRITE,2
DEFCONST "FN_IMG>",7,,FN_IMGFROM,3
DEFCONST "FN_>IMG",7,,FN_TOIMG,4    
DEFCONST "MOUNT",5,,FN_MOUNT,5
DEFCONST "UMOUNT",6,,FN_UMOUNT,6

; execute une commande pour un périphérique
; les opcodes ainsi que les paramètres d'entrées
; et les résultats en sortie dépendandent de
; l'opération effectuée ainsi que du périphérique.
; arguments:
;    i*x    arguments en entrée spécifique au opcode et au devid
;    opcode code de l'opération à effectuer
;    devid  identifiant du périphérique
; retourne:
;    j*x   dépend du opcode et du devid    
DEFWORD "DEVIO",5,,DEVIO ; ( i*x opcode devid -- j*x )
    .word SWAP,CELLS,PLUS,FETCH,EXECUTE,EXIT
    
    
; initialise l'adresse boot du périphérique
; arguments
;     fn fonction à exécuter    
; retourne:
;   ud adresse  EEPROM, MCU_FLASH,SDCARD,SPIRAM   
DEFWORD "BOOTADR",7,,BOOTADR ; ( fn -- ud )
    .word BOOTDEV,FETCH,DUP,MFLASH,EQUAL,TBRANCH,1f-$
    .word SWAP,DROP,SDCARD,EQUAL,ZBRANCH,3f-$
    .word LIT,1,LIT,0,EXIT
1:  .word DROP,FN_TOIMG,EQUAL,ZBRANCH,2f-$
    .word ERASEROWS
2:  .word FBTROW,ROWTOFADR,EXIT
3:  .word LIT,0,DUP,EXIT    
    
; sauvegarde une image du système en RAM sur un périphérique
;  dev -> { MFLASH, EEPROM, SDCARD, SPIRAM }  
DEFWORD "IMG!",4,,IMGSTORE ; ( dev -- )
    .word QEMPTY,ZBRANCH,2f-$ ; si RAM vide quitte
    .word DROP,EXIT
2:  .word BOOTDEV,STORE,SETHEADER
    .word FN_TOIMG
    .word BTHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS,ROT,DUP,BOOTADR
    .word ROT,BOOTDEV,FETCH,TBLFETCH,EXECUTE
9:  .word EXIT 

; charge une image système en RAM à partir d'un périphérique.
; arguments:
;    dev PFA du descripteur de périphérique.
DEFWORD "IMG@",4,,IMGFETCH ; ( dev -- )
    .word BOOTDEV,STORE,QIMG,NOT,QABORT
    .byte 24
    .ascii "No boot image available."
    .align 2
    .word BTHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS
    .word FN_IMGFROM,DUP,BOOTADR,ROT ; S: r-addr size e-addr fn
    .word BOOTDEV,FETCH,TBLFETCH,EXECUTE
    ; après le chargement de l'image, *DP0==*SYSLATEST
    ; si ce n'est pas le cas l'image est invalide.
    .word SYSLATEST,FETCH,DP0,FETCH,NOTEQ,QABORT
    .byte  20
    .ascii "Boot image outdated."
    .align 2
    .word BTDP,TBLFETCH,DP,STORE 
    .word BTLATST,TBLFETCH,LATEST,STORE
9:  .word EXIT

; lecture d'un écran
; arguments
;    u1   adresse RAM
;    u2   no. de bloc
;    u3   no. de périphéque
; sortie:
;    n2   nombre de lignes
DEFWORD "LOAD",4,,LOAD ; ( u1 u2 u3 -- n2 )  
    .word FN_READ,SWAP,TBLFETCH
    
    .word EXIT

    