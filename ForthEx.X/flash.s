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
;Description:  stockage dans la mémoire flash du MCU
;  n'utilise que les bits 0:15 les bits 16:23 sont ignorés    
;  donc seul les instructions TBLRDL ET TBLWTL  sont utilisées.
;  REF: family reference manual # DS70609D    
;Date: 2017-03-07
    
.section .flash.buffer.bss bss address(RAM_END-VIDEO_BUFF_SIZE-FLASH_PAGE_SIZE)
.global _flash_buffer
_flash_buffer: .space FLASH_PAGE_SIZE    


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
;  FLASH_DRIVE_BASE <= addr < FLASH_END    
DEFWORD "?FLIMITS",8,,QFLIMITS ; ( addrl addrh -- addrl addrh f )
    .word TWODUP, LIT,FLASH_DRIVE_BASE&0xFFFF,LIT,(FLASH_DRIVE_BASE>>16)
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
  

;écriture de W1 et W2 dans les latch FLASH MCU
; w1,w2 mots à écriredans la flash
; ud  adresse mémoire flash  
DEFWORD ">FLASH",6,,TOFLASH ; ( adr ud -- )
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,DROP,EXIT ; jette les 2 adresses avant de quitter
1:  .word FADDR  ; S: adr
    .word WRITE_LATCH,LIT,FOP_WDWRITE,FLASH_OP,EXIT
    
  
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
    
;écris en mémoire flash un bloc RAM
;  'adr' début bloc RAM
;  'size' nombre d'octets
;  'ud' addresse FLASH 24 bits    
DEFWORD "RAM>FLASH",9,,RAMTOFLASH ; ( adr size ud -- )    
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,TWODROP,EXIT
1:  .word FADDR  ; S: adr size
    .word LIT,0,DODO
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
  
DEFWORD "FLASHPG>",8,,FLASHPGFROM ; ( adr ud -- )
  
9:  .word EXIT
  
; initialise l'enregistrement de boot  
DEFWORD "SETHEADER",9,,SETHEADER ; ( -- )
    .word MAGIC,BTHEAD,BTSIGN,PLUS,STORE ; signature
    .word HERE,BTHEAD,BTDP,PLUS,STORE ; DP
    .word LATEST,FETCH,BTHEAD,BTLATST,PLUS,STORE ; latest
    .word HERE,DP0,MINUS,BTHEAD,BTSIZE,PLUS,STORE ; size
    .word EXIT

; efface les lignes qui seront utilisées
; pour la sauvegarde de l'image RAM    
DEFWORD "ERASEROWS",9,,ERASEROWS ; ( -- )
    .word BTHEAD,BTSIZE,PLUS,FETCH
    .word LIT,BOOT_HEADER_SIZE,PLUS
    .word LIT,FLASH_PAGE_SIZE,SLASHMOD
    .word SWAP,ZBRANCH,1f-$
    .word ONEPLUS
1:  .word FBTROW,SWAP,LIT,0,DODO
2:  .word DUP,FERASE,ONEPLUS,DOLOOP,2b-$
    .word DROP,EXIT
  
; sauvegarde de l'image RAM dans la FLASH du MCU  
DEFWORD "IMG>FLASH",9,,IMGTOFLASH ; ( -- ) 
    .word SETHEADER,ERASEROWS
    .word BTHEAD,HERE,DP0,MINUS,LIT,BOOT_HEADER_SIZE,PLUS ; adr size
    .word FBTROW,ROWTOFADR,RAMTOFLASH,EXIT

    
; restauraton de l'image RAM à partir de la FLASH du MCU
DEFWORD "FLASH>IMG",9,,FLASHTOIMG ; ( -- )
    ; lecture de l'entête boot
    .word BTHEAD,LIT,BOOT_HEADER_SIZE ; adr size
    .word FBTROW,ROWTOFADR,FLASHTORAM ; entête lue
    .word QBOOT,ZBRANCH,8f-$
    .word QSIZE,QDUP,ZBRANCH,8f-$
    .word CLEAR,BTHEAD,BTDP,PLUS,FETCH,DP,STORE 
    .word BTHEAD,BTLATST,PLUS,FETCH,LATEST,STORE
    .word BTHEAD,SWAP,LIT,BOOT_HEADER_SIZE,PLUS,FBTROW,ROWTOFADR,FLASHTORAM
8:  .word EXIT
  