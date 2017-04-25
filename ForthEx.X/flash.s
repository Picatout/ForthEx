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

;NOM: flash.s
;DESCRIPTION:
;  Permet l'accès à des données stockées dans la mémoire flash du MCU.
;  Pour protéger le système l'écriture n'est autorisée qu'à partir de l'adresse 
;  0x8000. Le système au complet doit résidé en déça de cette adresse sauf
;  pour une image du dictionnaire en RAM  qui peut-être sauvegardé dans la FLASH 
;  à partir de l'adresse 0x8000 avec le mot IMG>FLASH. Cette image est 
;  automatiquement récupérée au démarrage du sytème par le mot FLASH>IMG.  
;
; REF:    
;  documents de référence Microchip: DS70609D et DS70000613D
;    
;DATE: 2017-03-07
    
.section .hardware.bss  bss
; adresse du buffer pour écriture mémoire flash du MCU
_mflash_buffer: .space 2 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots de bas niveau pour
; l'accès à la mémoire FLASH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; descripteur mémoire FLASH MCU    
DEFTABLE "MFLASH",6,,MFLASH
    .word _MCUFLASH ; mémoire FLASH du MCU    
    .word TBLFETCHL ;
    .word TOFLASH
    .word FLASHTORAM
    .word RAMTOFLASH
    
 
;réservation de mémoire pour écriture flash MCU
; arguments:
;   aucun
; retourne:
;   a-addr   adresse du buffer
DEFWORD "FBUFFER",7,,FBUFFER ; ( -- a-addr ) 
    .word LIT,FLASH_PAGE_SIZE,MALLOC,DUP,LIT,_mflash_buffer,STORE
    .word EXIT
 
; lecture d'un mot dans la mémoire flash low word
DEFCODE "TBL@L",5,,TBLFETCHL ; ( ud1 -- n )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdl [T],T
    RPOP TBLPAG
    NEXT
    
; lecture d'un mot dans la mémoire flash low word
DEFCODE "TBL@H",5,,TBLFETCHH ; ( ud1 -- n )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdh [T],T
    RPOP TBLPAG
    NEXT

;lit 1 instruction de la mémoire flash
;  'ud'  adresse 24 bits mémoire flash
; retourne:
;   'n1' bits 16:23 
;   'n2' bits 8:15
;   'n3' bits 0:7    
DEFCODE "I@",2,,IFETCH ; ( ud -- n1 n2 n3 )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    mov T, W0
    tblrdh [W0],[++DSP]
    tblrdl.b [W0++],T
    ze T,T
    tblrdl.b [W0],W0
    ze W0,W0
    mov W0,[++DSP]
    RPOP TBLPAG
    NEXT
 
; addresse 24 bits mémoire FLASH 
DEFCODE "FADDR",5,,FADDR ; ( ud -- )
    mov T, NVMADRU
    DPOP
    mov T, NVMADR
    DPOP
    NEXT

DEFCODE "FNEXT",5,,FNEXT ; ( -- )
    mov #4,W0
    add NVMADR
    clr W0
    addc NVMADRU
    NEXT


    
; écriture de 6 octets dans les latches    
; addr adresse tampon RAM    
HEADLESS "WRITE_LATCH" ; ( addr --  )
    RPUSH DSRPAG
    movpag #1,DSRPAG
    RPUSH TBLPAG
    mov #0xFA,W0
    mov W0,TBLPAG
    mov #0,W0
    mov T, W1 ; adresse donnée en RAM
    DPOP
    tblwtl.b [W1++],[W0++]
    tblwtl.b [W1++],[W0--]
    tblwth.b [W1++],[W0]
    inc2 W0,W0
    tblwtl.b [W1++],[W0++]
    tblwtl.b [W1++],[W0--]
    tblwth.b [W1++],[W0]
    RPOP TBLPAG
    RPOP DSRPAG
    NEXT

;sequence d'écriture dans la mémoire flash    
HEADLESS "FLASH_OP"  ; ( op -- )
    mov #(1<<WREN),W0 ; write enable
    ior T,W0,W0
    DPOP
    mov W0,NVMCON
    disi #6
    mov #0x55,W0
    mov W0, NVMKEY
    mov #0xAA,W0
    mov W0, NVMKEY
    bset NVMCON,#WR
    NOP
    NOP
    btsc NVMCON,#WR
    bra $-2
    NEXT
    
; compare 2 nombres double non signés
; n = 1 si ud1>ud2
; n = 0 si ud1==ud2
; n = -1 si ud1<ud2    
DEFCODE "UDREL",5,,UDREL ; ( ud1 ud2 -- n )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    mov T, W3
    DPOP
    mov T, W2
    clr T
    sub W2,W0,W0
    subb W3,W1,W1
    bra ltu, 8f
    ior W0,W1,W2
    bra z, 9f
    inc T,T
    bra 9f
8:  setm T    
9:  NEXT
    
; vérifie si l'adresse est valide
;  IMG_FLASH_ADDR <= addr < FLASH_END    
DEFWORD "?FLIMITS",8,,QFLIMITS ; ( addrl addrh -- addrl addrh f )
    .word TWODUP, LIT,IMG_FLASH_ADDR&0xFFFF,LIT,(IMG_FLASH_ADDR>>16)
    .word UDREL,ZEROLT,ZBRANCH,1f-$
    .word LIT,0,EXIT
1:  .word TWODUP,LIT,FLASH_END&0xFFFF,LIT,(FLASH_END>>16)
    .word UDREL,ZEROLT,EXIT
    
; convertie no ligne en adresse FLASH 24 bits   
DEFWORD "ROW>FADR",8,,ROWTOFADR 
    .word LIT,FLASH_ROW_SIZE,MSTAR,EXIT
    
;efface une ligne FLASH
; une correspond à 1024 instructions ou 2048 adresses    
;  u  numéro de la ligne
;  les pages sont alignées sur 1024 instructions    
DEFWORD "FERASE",6,,FERASE ; ( u -- )
    .word ROWTOFADR ; S: ud
    .word QFLIMITS,ZBRANCH, 8f-$
    .word SWAP,LIT,0xF800,AND,SWAP ; ligne aligné sur 11 bits
    .word FALSE,VIDON
    .word FADDR,LIT,FOP_EPAGE, FLASH_OP,TRUE,VIDON,EXIT   
8:  .word DOTS,TWODROP
9:  .word EXIT
  

;écriture de 6 octets dans les latch FLASH MCU
; addr adresse RAM source
; ud  adresse mémoire flash  24 bits
DEFWORD ">FLASH",6,,TOFLASH ; ( addr ud -- )
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,DROP,EXIT ; jette les 2 adresses avant de quitter
1:  .word FADDR  ; S: addr
    .word WRITE_LATCH,LIT,FOP_WDWRITE,FLASH_OP,EXIT
    
  
;écris en mémoire flash un bloc RAM
;  'adr' début bloc RAM
;  'size' nombre d'octets
;  'ud' addresse FLASH 24 bits    
DEFWORD "RAM>FLASH",9,,RAMTOFLASH ; ( adr size ud -- )    
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,TWODROP,EXIT
1:  .word FADDR  ; S: addr size
    .word LIT,0,DODO ; S: addr
2:  .word DUP, WRITE_LATCH, LIT, FOP_WDWRITE, FLASH_OP
    .word FNEXT,LIT,6,PLUS,LIT,6,DOPLOOP,2b-$,DROP
9:  .word EXIT
  
  
; lecture d'un bloc FLASH dans un bloc RAM
; 'adr' adresse 16 bits début RAM
; 'size' nombre d'octets à lire
; 'ud' adresse FLASH 24 bits
DEFWORD "FLASH>RAM",9,,FLASHTORAM ; ( adr size ud -- )
    .word ROT ; S: adr ud size  
    .word LIT,0,DODO ; S: adr ud 
1:  .word TWODUP,LIT,2,MPLUS,TWOTOR,IFETCH ; S: adr n1 n2 n3 R: ud+2
    .word NROT,TWOTOR,OVER,CSTORE,ONEPLUS,RFROM,OVER,CSTORE
    .word ONEPLUS,RFROM,OVER,CSTORE,ONEPLUS
    .word TWORFROM,LIT,3,DOPLOOP,1b-$
    .word TWODROP,DROP
9:  .word EXIT  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   Sauvegarde et restauration
;   image binaire dans la mémoire
;   flash du MCU. Cette image
;   est rechargée automatiquement
;   au démarrage de l'ordinateur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  
; IMG>RAM charge en RAM une image système
; *** format image boot ****
; 00 signature MAGIC, 2 octets
; 02 sauvegarde de LATEST, 2 octets
; 04 sauvegarde de DP, 2 octets  
; 06 data_size 2 octets
; 08 données image débute ici.    
; *************************    

; constantes liées au chargeur système (boot loader)
DEFCONST "IMGHEAD",7,,IMGHEAD,BOOT_HEADER ; entête secteur démarrage
DEFCONST "MAGIC",5,,MAGIC,0x55AA ; signature
DEFCONST "IMGROW",6,,IMGROW,FLASH_FIRST_ROW  ; numéro première ligne FLASH IMG  

; champ signature    
DEFWORD "IMGSIGN",7,,IMGSIGN  ; ( -- n addr )
    .word LIT,0,IMGHEAD,EXIT

; champ LATEST    
DEFWORD "IMGLATST",8,,IMGLATST  ; ( -- n addr )
    .word LIT,1,IMGHEAD,EXIT

; champ DP    
DEFWORD "IMGDP",5,,IMGDP ; ( -- n addr )
    .word LIT,2,IMGHEAD,EXIT
    
; champ taille    
DEFWORD "IMGSIZE",7,,IMGSIZE ; ( -- n addr )
    .word LIT,3,IMGHEAD,EXIT
    
    
; initialise l'entête d'image  
DEFWORD "SETHEADER",9,,SETHEADER ; ( -- )
    .word MAGIC,IMGSIGN,TBLSTORE ; signature
    .word HERE,IMGDP,TBLSTORE ; DP
    .word LATEST,FETCH,IMGLATST,TBLSTORE ; latest
    .word HERE,DP0,MINUS,IMGSIZE,TBLSTORE ; size
    .word EXIT

  
; position en mémoire flash de l'image. 
; arguments:
;   aucun
; retourne:
;   ud   adresse 32 bits  
DEFWORD "IMGADDR",7,,IMGADDR ; ( -- ud )
    .word LIT,IMG_FLASH_ADDR,LIT,0,EXIT
    
;vérifie s'il y a une image disponible
; retourne:
;     indicateur booléen vrai|faux
DEFWORD "?IMG",4,,QIMG ; (  -- f )
    .word IMGHEAD,LIT,BOOT_HEADER_SIZE,IMGADDR
    .word FLASHTORAM
    .word IMGSIGN,TBLFETCH,MAGIC,EQUAL
    .word EXIT
    
;retourne la taille d'une image à partir
;de l'entête de celle-ci. 
; retourne:
;   'n'  taille en octets    
DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word IMGSIZE,TBLFETCH,EXIT
    
  
; efface les lignes qui seront utilisées
; pour la sauvegarde de l'image RAM    
DEFWORD "ERASEROWS",9,,ERASEROWS ; ( -- )
    .word IMGSIZE,TBLFETCH
    .word LIT,BOOT_HEADER_SIZE,PLUS
    .word LIT,FLASH_PAGE_SIZE,SLASHMOD
    .word SWAP,ZBRANCH,1f-$
    .word ONEPLUS
1:  .word IMGROW,SWAP,LIT,0,DODO
2:  .word DUP,FERASE,ONEPLUS,DOLOOP,2b-$
    .word DROP,EXIT
 
; sauvegarde une image de la RAM dans la mémoire flash du MCU
DEFWORD "IMGSAVE",7,,IMGSAVE ; ( -- )
    .word QEMPTY,ZBRANCH,2f-$ ; si RAM vide quitte
    .word EXIT
2:  .word SETHEADER
    .word ERASEROWS
    .word IMGHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS,IMGADDR
    .word RAMTOFLASH
9:  .word EXIT 

; charge une image système RAM à partir de la mémoire flash du MCU.
DEFWORD "IMGLOAD",4,,IMGLOAD ; ( -- )
    .word QIMG,NOT,QABORT
    .byte 24
    .ascii "No boot image available."
    .align 2
    .word IMGHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS
    .word IMGADDR,FLASHTORAM
    .word IMGDP,TBLFETCH,DP,STORE
    .word IMGLATST,TBLFETCH,LATEST,STORE
    .word EXIT

  