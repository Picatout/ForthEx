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
    btss SDC_PORT,#SDC_SEL
    bset sdc_status,#F_SDC_IN
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
;    _disable_spi
    mov #0xFFE0,W0
    and STR_SPICON1
    mov W1,W0
    ior STR_SPICON1
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
    mov T, W1 ; nombre d'octets � transf�rer
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
DEFCODE "EEREAD",6,,EEREAD   ; ( r-addr size ud -- )
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

; �criture d'une plage RAM dans l'EEPROM externe 
; l'�criture se fait par segment de 256 octets.    
; arguments:
;   'r-addr' entier simple, adresse RAM d�but
;   'size' entier simple, nombre d'octets � �crire, multiple de 256
;   'e-addr'  entier double, adresse EEPROM d�but align�e % 256    
DEFWORD "RAM>EE",6,,RAMTOEE ; ( r-addr size e-addr -- )    
    .word ROT,LIT,0,DODO
1:  .word TWOTOR,LIT,256,TWODUP,TWORFETCH,EEWRITE ; S: r-addr 256 R: e-addr
    .word PLUS,TWORFROM,LIT,256,MPLUS,LIT,256,DOPLOOP,1b-$
    .word TWODROP,DROP,EXIT

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
; descripteurs de p�riph�rique ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; il s'agit d'une structure de donn�es
; contenants les pointeurs de fonctions
; des p�riph�riques    
;  champs:
;   identifiant
;   XT lecture
;   XT �criture
;   XT autre fonction
;   ...
    
; descripteur SPIRAM    
DEFTABLE "XRAM",4,,XRAM
    .word _SPIRAM ; RAM SPI externe
    .word RLOAD   ; lecture
    .word RSTORE  ; �criture
    .word RLOAD   ; IMG>
    .word RSTORE  ; >IMG
    
; descripteur clavier
DEFTABLE "KEYBOARD",8,,KEYBOARD
    .word _KEYBOARD ; clavier
    .word KEY       ; lecture du clavier
    .word KBD_RESET ; r�initialiation du clavier
    .word EKEY      ; lecture canonique du clavier
    
; descripteur �cran    
DEFTABLE "SCREEN",6,,SCREEN
    .word _SCREEN ; �cran
    .word SCRCHAR ; 
    .word PUTC
    
; descripteur port s�riel    
DEFTABLE "SERIAL",6,,SERIAL
    .word _SERIAL ; port s�rie
    .word VTKEY  ;
    .word SPUTC  ;
    .word SGETC  ; lecture canonique du port s�riel
    
; descripteur EEPROM SPI    
DEFTABLE "EEPROM",6,,EEPROM
    .word _SPIEEPROM ; m�moire EEPROM externe
    .word EEREAD
    .word EEWRITE
    .word EEREAD     ;IMG>
    .word RAMTOEE    ;>IMG
;    .word EEMOUNT    ; monte le syst�me de fichier EEFS
;    .word EEUMOUNT   ; d�monte le syst�me de fichier EEFS
    
; descripteur carte Secure Digital    
DEFTABLE "SDCARD",6,,SDCARD
    .word _SDCARD ; carte m�moire SD
    .word SDCREAD
    .word SDCWRITE
    .word SDCTOIMG  ; IMG>
    .word IMGTOSDC  ; >IMG
    
; acceseurs de champs    
DEFCONST "DEVID",5,,DEVID,0    
; op�rations    
DEFCONST "FN_READ",7,,FN_READ,1
DEFCONST "FN_WRITE",8,,FN_WRITE,2
DEFCONST "FN_IMG>",7,,FN_IMGFROM,3
DEFCONST "FN_>IMG",7,,FN_TOIMG,4    
DEFCONST "MOUNT",5,,FN_MOUNT,5
DEFCONST "UMOUNT",6,,FN_UMOUNT,6

; execute une commande pour un p�riph�rique
; les opcodes ainsi que les param�tres d'entr�es
; et les r�sultats en sortie d�pendandent de
; l'op�ration effectu�e ainsi que du p�riph�rique.
; arguments:
;    i*x    arguments en entr�e sp�cifique au opcode et au devid
;    opcode code de l'op�ration � effectuer
;    devid  identifiant du p�riph�rique
; retourne:
;    j*x   d�pend du opcode et du devid    
DEFWORD "DEVIO",5,,DEVIO ; ( i*x opcode devid -- j*x )
    .word SWAP,CELLS,PLUS,FETCH,EXECUTE,EXIT
    
    
; lecture d'un �cran
; arguments
;    u1   adresse RAM
;    u2   no. de bloc
;    u3   no. de p�riph�que
; sortie:
;    n2   nombre de lignes
DEFWORD "LOAD",4,,LOAD ; ( u1 u2 u3 -- n2 )  
    .word FN_READ,SWAP,TBLFETCH
    
    .word EXIT

    