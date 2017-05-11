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
 
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   interface SPI RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; nom: XBLK>ADR ; ( u -- ud )
;   Convertie un numéro de bloc XRAM en adresse XRAM.    
; arguments:
;   u    entier non signé, numéro du bloc, {1..6535}
; retourne:
;   ud   entier double non signé, adresse début bloc dans XRAM
DEFWORD "XBLK>ADR",8,,XBLKTOADR
    .word ONEMINUS,LIT,BLOCK_SIZE,MSTAR,EXIT
    
    
; nom: XWRITE ( u1 n+ ud1 -- )
;   Transfert un bloc d'octets de la RAM du MCU vers la RAM SPI
; arguments: 
;    u1  adresse bloc RAM
;    n+  nombre d'octets
;    ud1  adresse SPIRAM 
; retourne    
;   rien
DEFCODE "XWRITE",6,,XWRITE ; ( u1 n+ ud1 -- )
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


; nom: XREAD  ( u1 n+ ud1 -- )
;   Transfert un bloc d'octets de la RAM SPI vers la RAM du MCU
; arguments: 
;    u1  adresse bloc RAM
;    n+  nombre d'octets
;    ud1  adresse SPIRAM
; retourne:    
;   rien
DEFCODE "XREAD",5,,XREAD ; ( u1 n+ ud1 -- )
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
    

; nom: EEBLK>ADR  ( u -- ud )
;   Convertie un numéro de bloc en adresse EEPROM
; arguments:
;   u	    entier simple non signé, numéro du block {1..65535}
; retourne:
;   ud      entier double non signé, adresse début bloc dans l'EEPROM
DEFWORD "EEBLK>ADR",9,,EEBLKTOADR
    .word ONEMINUS,LIT,BLOCK_SIZE,MSTAR,EXIT
 
; nom: EEWRITE ( u1 n+ ud1 -- )
;   Enregistrement d'une plage RAM dans l'EEPROM
; IMPORTANT:
;     la mémoire EEPROM est divisée en
;     rangées de 256 octets. Lorsque le pointeur
;     d'adresse atteint la fin d'une rangée il 
;     revient au début de celle-ci. Donc si 'ud'
;     est au début de la rangée un maximum de 256
;     octets peuvent-être écris avant l'écrasement
;     des premiers octets. 
; arguments: 
;    u1	  entier simple, adresse 16 bits début RAM
;    n+  entier simple positif, nombre d'octets à enregistrer {1..256} 
;    ud2  entier double, adresse 24 bits destination EEPROM
; retourne: 
;   rien
DEFCODE "RAM>EE",6,,RAMTOEE  
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
    
; nom: EEREAD   ( u1 n+ ud -- )
;   Lecture d'une plage EEPROM vers la mémoire RAM
; arguments:
;    u1	    entier simple, adresse 16 bits début RAM
;    n+	    entier simple, nombre d'octets à lire 
;    ud     entier double, adresse destination EEPROM
; retourne:
;   rien    
DEFCODE "EEREAD",6,,EEREAD   
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
    
; l'EEPROM peut-être effacée par page,secteur ou au complet.    
DEFCONST "EPAGE",5,,EPAGE,EPE ;efface page
DEFCONST "ESECTOR",7,,ESECTOR,ESE ; efface secteur
DEFCONST "EALL",4,,EALL,ECE    
    
; nom: EERASE ( eall | N {EPAGE|ESECTOR} -- )    
;   Efface unepage, 1 secteur ou l'EEPROM au complet.
; arguments:
;   'n' numéro de page {0..511} ou de secteur {0..3}
;   'op' opération: EPAGE|ESECTOR|EALL
; retourne:
;   rien    
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

; nom: EEWRITE  ( u1 ud -- )    
;   Écriture d'un bloc RAM dans l'EEPROM externe.
;   L'écriture se fait par segment de 256 octets. 
;   Un bloc compte 1024 octets.    
; arguments:
;   u1	    entier simple, adresse RAM début
;   ud      adresse absolue dans l'EEPROM
; retourne:
;   rien    
DEFWORD "EEWRITE",7,,EEWRITE 
    .word LIT,4,LIT,0,DODO  ; S: u1 ud
1:  .word TWOTOR,LIT,256,TWODUP,TWORFETCH,RAMTOEE ; S: u1 256 R: ud
    .word PLUS,TWORFROM,LIT,256,MPLUS,DOLOOP,1b-$
    .word TWODROP,DROP,EXIT

; constante nombre de blocs dans la SPIRAM    
DEFCONST "XBLKCOUNT",9,,XBLKCOUNT,128    
    
; nom: XBOUND  ( n+ -- f )
;   Vérifie si le numéro de bloc est dans les limites
; arguments:
;   n+   numéro du bloc à vérifier. {1..128}
; retourne:
;   f   indicateur booléen.
DEFWORD "XBOUND",6,,XBOUND
    .word DUP,ZBRANCH,9f-$
    .word XBLKCOUNT,UGREATER,NOT
9:  .word EXIT
   
;constante nombre de blocs dans l'EEPROM  
DEFCONST "EEBLKCOUNT",10,,EEBLKCOUNT,128
  
; nom: EEBOUND  ( n+ -- f )
;   Vérifie si le numéro de bloc est dans les limites
; arguments:
;   n+   numéro du bloc à vérifier. {1..128}
; retourne:
;   f   indicateur booléen.
DEFWORD "EEBOUND",7,,EEBOUND
    .word DUP,ZBRANCH,9f-$
    .word EEBLKCOUNT,UGREATER,NOT
9:  .word EXIT
   
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
; descripteurs de périphériques 
; pour les opérations sur blocs    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; il s'agit d'une structure de données
; contenants les pointeurs de fonctions
; des périphériques    
;  champs:
;   identifiant
;   CFA lecture
;   CFA écriture
;   CFA load


; acceseurs de champs    
DEFCONST "DEVID",5,,DEVID,0    
; opérations    
DEFCONST "FN_READ",7,,FN_READ,1   ; chargement d'un bloc dans un buffer
DEFCONST "FN_WRITE",8,,FN_WRITE,2 ; écriture d'un buffer dans un bloc device
DEFCONST "FN_BLK>ADR",10,,FN_BLKTOADR,3 ; convertion no. bloc à adresse absolue.
DEFCONST "FN_BOUND",8,,FN_BOUND,4 ; vérifie si le no. de block est dans les limites
    
; descripteur SPIRAM    
DEFTABLE "XRAM",4,,XRAM
    .word _SPIRAM ; RAM SPI externe
    .word XREAD   ; store -> buffer
    .word XWRITE  ; buffer -> store
    .word XBLKTOADR
    .word XBOUND
    
; descripteur EEPROM SPI    
DEFTABLE "EEPROM",6,,EEPROM
    .word _SPIEEPROM ; mémoire EEPROM externe
    .word EEREAD    
    .word EEWRITE
    .word EEBLKTOADR
    .word EEBOUND
    