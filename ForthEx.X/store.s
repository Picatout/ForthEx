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
    dec W3,W3
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
DEFCODE "EEREAD",6,,EEREAD   ; ( addr size ud -- )
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

; le BOOT charge en RAM une image système
; *** format image boot ****
; 00 signature MAGIC, 2 octets
; 02 sauvegarde de LATEST, 2 octets
; 04 sauvegarde de DP, 2 octets  
; 06 data_size 2 octets
; 08 données image débute ici.    
; *************************    

;; retourne l'adresse début d'un tampon
;; les tampons sont situés dans la mémoire EDS
;; et ont une dimension de 256 octets.    
;; #buffer {0..73}
;; si #buffer>73 alors utilise #buffer % 74    
;DEFWORD "BUFADDR",7,,BUFADDR ; ( #buffer -- addr )
;    .word LIT,74,MOD,LIT,256,STAR,ULIMIT,PLUS,EXIT
;    
;    
;; écris un entier dans un tampon
;; arguments:
;;   '#t' numéro du tampon
;;   'ofs' position dans le tampon 
;;   'n' valeur à écrire    
;DEFWORD "BUFFER!",7,,BUFFERSTORE ; ( n ofs #t -- )
;    .word BUFADDR, PLUS, STORE, EXIT
;    
;; écris un octet dans le tampon
;; arguments:
;;   '#t' numéro du tampon
;;   'ofs' position dans le tampon 
;;   'c' valeur à écrire    
;DEFWORD "BUFFERC!",8,,BUFFERCSTORE ; ( c ofs #t -- )
;    .word BUFADDR, PLUS, CSTORE, EXIT
;    
;;lire un entier d'un tampon    
;; arguments
;;   '#t' numéro du tampon
;;   'ofs' position dans le tampon 
;;  retourne:
;;     'n'  entier lu
;DEFWORD "BUFFER@",7,,BUFFERFETCH ; ( ofs #t -- n )
;    .word BUFADDR,PLUS,FETCH,EXIT
;    
;;lire un octet d'un tampon    
;; arguments
;;   '#t' numéro du tampon
;;   'ofs' position dans le tampon 
;;  retourne:
;;     'c'  octet lu
;DEFWORD "BUFFERC@",8,,BUFFERCFETCH 
;    .word BUFADDR, PLUS,CFETCH,EXIT
    
    
;vérifie s'il y a une image boot
; retourne:
;     indicateur booléen vrai|faux
DEFWORD "?BOOT",5,,QBOOT ; (  -- f )
    .word BTHEAD,BTSIGN,PLUS,FETCH
    .word MAGIC,EQUAL,EXIT 

;retourne la taille d'une image à partir
;de l'entête de celle-ci chargée dans le
; retourne:
;   'n'  taille en octets    
DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word BTHEAD,BTSIZE,PLUS,FETCH
    .word EXIT
    
; combiens d'octets à lire/écrire dans la page suivante 
;  arguments:
;   'dp' position actuelle du pointer data
;  retourne:
;    min(EPAGE_SIZE,HERE-dp)    
DEFWORD "?BYTES",6,,QBYTES ; ( dp -- n )
    .word HERE,SWAP,MINUS,LIT,EPAGE_SIZE,UMIN
    .word EXIT

;retourne l'état de l'opération de transfert
; lorsque 'dp'==DP c'est complété
; arguments:
;   'dp'  pointeur de donnée
; retourne:
;    'f'  indicateur booléen vrai|faux    
DEFWORD "?DONE",5,,QDONE ;  ( dp -- f )
    .word QBYTES,ZEROEQ,EXIT
    
; lit la valeur de DP dans le tampon 0
; et assigne cette valeur à la variable 
; système DP.
; doit-être appellée après que la page
; 0 d'une image a étée chargée.    
DEFWORD "SETDP",5,,SETDP ; ( -- )
    .word BTDP,LIT,0,BUFFERFETCH
    .word DP,STORE,EXIT
    
; lit la valeur de LATEST dans le tampon 0
; et assigne cette valeur à la variable 
; système LATEST.
; doit-être appellée après que la page
; 0 d'une image a étée chargée.    
DEFWORD "SETLATEST",9,,SETLATEST ; ( -- )
    .word BTLATST,LIT,0,BUFFERFETCH
    .word LATEST,STORE,EXIT
    
; charge la page EEPROM à la position de dp
; utilise le tampon #1.    
; arguments:
;   'dp' pointeur de donnée
;   'p' page eeprom à lire    
; retourne:
;   'dp'  data pointer mis à jour
DEFWORD "PGLOAD",6,,PGLOAD ; ( dp p -- dp )
    ;lecture de l'EERPOM dans le tampon #1
    .word LIT,1,SWAP,EEREAD ; dp
    ;copie le tampon vers *dp
    .word DUP,QBYTES ; S: dp n
    .word TWODUP,PLUS,TOR ; S: dp n  R: dp+n
    .word LIT,1,BUFADDR,NROT,CMOVE
    .word RFROM,EXIT
    
; s'il y a une image système au début de l'EEPROM
; la charge en mémoire
DEFWORD "BOOT",4,,BOOT ; ( -- )
    .word QBOOT,ZBRANCH,9f-$
    .word CLEAR,SETDP,DP0,LIT,1,TOR  ; S: dp  R: page
1:  .word DUP,QDONE,TBRANCH,8f-$
    .word RFROM,DUP,ONEPLUS,TOR
    .word PGLOAD,BRANCH,1b-$
8:  .word RFROM,TWODROP,SETLATEST    
9:  .word EXIT
    
    
;écris l'entête du boot sector, et retourne
; la grandeur de l'image.
; utilisation du tampon #0  
DEFWORD "HEADWRITE",9,,HEADWRITE ; ( --  )
    .word LIT,0,TOR ; R: 0
    .word MAGIC,BTSIGN,RFETCH,BUFFERSTORE ; champ signature
    .word LATEST,FETCH,BTLATST,RFETCH,BUFFERSTORE; champ LATEST 
    .word HERE,BTDP,RFETCH,BUFFERSTORE ; champ DP
    .word HERE,DP0,MINUS,BTSIZE,RFETCH,BUFFERSTORE ; champ taille
    .word RFROM,DUP,EEWRITE,EXIT ; tampon > EEPROM

DEFWORD ">BUFFER",7,,TOBUFFER ; ( dp t -- dp' )
    .word BUFADDR,OVER,DUP ; S: dp addr dp dp 
    .word QBYTES,DUP,ROT,PLUS,TOR ; S: dp addr n   R: dp+n
    .word LIT,0,DODO
1:  .word SWAP,DUP,ONEPLUS,NROT
    .word CFETCH,OVER,CSTORE,ONEPLUS,DOLOOP,1b-$
    .word TWODROP,RFROM,EXIT
    
;écris la page suivante dans l'EEPROM
; utilise le tampon #1 pour le transfert > EEPROM.    
; arguments:
;   'p' no de page EEPROM
;   'dp' pointeur data
; retourne:
;   'dp+n'  position de dp actualisée
DEFWORD "PGSAVE",6,,PGSAVE ; ( p dp -- dp+n )
    ; copie du data dans le tampon
    .word LIT,1,TOBUFFER,SWAP
;    .word DUP,QBYTES,TWODUP,PLUS,NROT ; S: p dp+n dp n   
;    .word LIT,1,BUFADDR,SWAP,CMOVE,SWAP ; S: dp+n p  
    ; écriture du tampon dans l'EEPROM
    .word LIT,1,SWAP,EEWRITE ; S: dp+n
    .word EXIT ; S: dp+n 
    
; sauvegarde une image au début de l'EEPROM
DEFWORD ">BOOT",5,,TOBOOT ; ( -- )
    .word EMPTY,ZBRANCH,1f-$
    .word EXIT ; rien à sauvegarder
1:  .word LIT,1 ; S: p 
    .word HEADWRITE,DP0 ; S: p dp
2:  .word DUP,QDONE,TBRANCH,9f-$ ; S: p dp  
    .word OVER,ONEPLUS,NROT ; S: p+1 p dp 
    .word PGSAVE,BRANCH,2b-$   
9:  .word TWODROP,EXIT 
