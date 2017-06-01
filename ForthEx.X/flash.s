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

; NOM: flash.s
; DATE: 2017-03-07
; DESCRIPTION:
;  Permet l'accès à des données stockées dans la mémoire flash du MCU.
;  Pour protéger le système l'écriture n'est autorisée qu'à partir de l'adresse 
;  0x8000. Le système au complet doit résidé en déça de cette adresse sauf
;  pour une image du dictionnaire en RAM  qui peut-être sauvegardé dans la FLASH 
;  à partir de l'adresse 0x8000 avec le mot IMGSAVE. Cette image est 
;  automatiquement récupérée au démarrage du sytème par le mot IMGLOAD.  
;
; REF:    
;  documents de référence Microchip: DS70609D et DS70000613D
;    
    
.section .hardware.bss  bss
; adresse du tampon pour écriture mémoire flash du MCU
_mflash_buffer: .space 2 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots de bas niveau pour
; l'accès à la mémoire FLASH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; MFLASH   ( -- a-addr ) 
;   Retourne l'adresse du descripteur mémoire FLASH MCU
; arguments:
;   aucun
; retourne:
;   aucun 
;DEFTABLE "MFLASH",6,,MFLASH
;    .word _MCUFLASH ; mémoire FLASH du MCU    
;    .word FFETCH 
;    .word TOFLASH
;    .word FLASHTORAM
;    .word RAMTOFLASH
    
; nom: FBUFFER  ( -- a-addr )
;   Réservation d'un bloc de mémoire dynamique pour écriture d'une page flash MCU.
; arguments:
;   aucun
; retourne:
;   a-addr   adresse du premier octet de donnée du tampon.
DEFWORD "FBUFFER",7,,FBUFFER ; ( -- a-addr ) 
    .word LIT,FLASH_PAGE_SIZE,MALLOC,DUP,LIT,_mflash_buffer,STORE
    .word EXIT

    
; nom: F@  (  ud1 -- n )    
;   Lecture d'un mot de 16 bits dans la mémoire.
;   Si ud1 est pair utilise l'instruction machine TBLRDL pour retourner les bits 15:0
;   Si ud1 est impair utilise l'instruction machine TBLRDH pour retourner les bits 23:16    
; arguments:
;   ud1  adrese dans la mémmoire flash du MCU.
; retourne:
;   n    valeur lue à l'adresse ud1. Si ud1 est impair les bits 15:8 sont à zéro.
DEFCODE "F@",2,,FFETCH ; ( ud1 -- n )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    btss T,#0
    bra 2f
    bclr T,#0
    tblrdh [T],T
    bra 9f
2:  tblrdl [T],T
9:  RPOP TBLPAG
    NEXT
  
; nom: FC@L ( ud1 -- n )
;   Lecture d'un octet dans la partie basse de l'instruction. 
;   Utilise l'instruction machine TBLRDL.B    
;    Si ud1 est impair  les bits 15:8 sont retournés, sinon les bits 7:0 sont retournés.
; arguments:
;   ud1  entier double correspondant à l'adresse en mémoire flash.
; retourne:
;   n    si impair(ud1) n=bits{15:8}  sinon n=bits{7:0}
DEFCODE "FC@L",4,,FCFETCHL 
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdl.b [T],T
    ze T,T
    RPOP TBLPAG
    NEXT
    
    
; nom: FC@H   ( ud1 -- n )    
;    Lecture d'un octet dans la mémoire flash du mot lourd de l'instruction.
;    Utilise l'instruction machine TBLRDH.B
;    Si ud1 est impair retourne la valeur 0, sinon retourne les bits 23:16 de l'instruction.    
; arguments:
;   a-addr   adresse du premier octet de donnée du tampon.
; retourne:
;   n	valeur lue à l'adresse ud1.  n représente les bits 23..16 de l'instruction à l'adresse a-addr-1.
DEFCODE "FC@H",4,,FCFETCHH ; ( ud1 -- n )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdh.b [T],T
    ze T,T
    RPOP TBLPAG
    NEXT

; nom: I@   ( ud -- u1 u2 u3 )    
;   lit 1 instruction de la mémoire flash du MCU. L'instrucion est séparé en
;   3 octets. Accès à la mémoire flash en utilisant les instructions 'tblrdl' et 'tblrdh'.
; arguments:    
;   ud  adresse 24 bits mémoire flash
; retourne:
;   u1  bits 16:23 
;   u2  bits 8:15
;   u3  bits 0:7    
DEFCODE "I@",2,,IFETCH 
    RPUSH TBLPAG
    mov T,TBLPAG
    mov [DSP], W0
    tblrdh [W0],[DSP]
    tblrdl.b [W0++],T
    ze T,T
    tblrdl.b [W0],W0
    ze W0,W0
    mov W0,[++DSP]
    RPOP TBLPAG
    NEXT
 
; nom: IC@ ( ud n -- c )
;   Lit 1 octet dans la mémoire flash à l'adresse d'instruction ud et à la position
;   désignée par n. n est dans l'intervalle {0..2}
;   0 retourne l'octet le faible, bits 7:0
;   1 retourne l'octet du milieu, bits 15:8
;   2 retourne l'octet le fort, bits 23:16
; arguments:
;   ud   Entier double pair adresse de l'instruction.
;   n    entier dans l'intervalle {0..2} indiquant quel octet de l'instruction doit-être lu.
; retourne:
;   c    octet lu dans la mémoire flash.
DEFCODE "IC@",3,,ICFETCH ; ( ud n -- c )
    mov T, W0
    DPOP
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    cp0 W0
    bra z, 4f
    dec W0,W0
    bra z, 2f
    tblrdh.b [T],T
    bra 9f
2:  inc T,T
4:  tblrdl.b [T],T
9:  RPOP TBLPAG
    NEXT
    
; nom: FADDR   ( ud -- )    
;   Initialise le pointeur d'addresse 24 bits pour la programmation de la mémoire FLASH du MCU.
;   Les addresse FLASH ont 24 bits.
; arguments:
;   ud   Entier double représentant l'adresse en mémoire FLASH MCU.
; retourne:
;   rien    
DEFCODE "FADDR",5,,FADDR ; ( ud -- )
    mov T, NVMADRU
    DPOP
    mov T, NVMADR
    DPOP
    NEXT

; nom: FNEXT   ( -- )
;   Incrémente le pointeur pour la programmation du prochain mot en mémoire FLASH MCU.
; arguments:
;   aucun
; retourne:
;   rien    
DEFCODE "FNEXT",5,,FNEXT ; ( -- )
    mov #4,W0
    add NVMADR
    clr W0
    addc NVMADRU
    NEXT


; nom: WRITE_LATCH  ( c-addr -- )    
;   Écriture de 6 octets dans les tampons utilisés pour la programmation de la mémoire flash.    
; arguments:    
;   c-addr  Adresse du premier octet en mémoire RAM à copié dans les tampons flash.
; retourne:
;   rien    
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

; FLASH_OP	 ( n -- )    
;   Séquence d'écriture dans la mémoire flash du MCU.
; arguments:
;   n    Constante identifiant le type d'opération flash à effectuer.
; retourne:
;   rien    
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
  
; nom: ?FLIMITS   ( ud -- ud f )    
;   Vérifie si l'adresse 24 bits représsentée par ud est dans la plage
;   IMG_FLASH_ADDR <= addr < FLASH_END et retourne un indicateur booléen.
; arguments:
;   ud   adresse 24 bits à contrôler.
; retourne:
;   ud   adresse contrôlée.
;   f    indicateur Booléen.    
DEFWORD "?FLIMITS",8,,QFLIMITS ; ( addrl addrh -- addrl addrh f )
    .word TWODUP, LIT,IMG_FLASH_ADDR&0xFFFF,LIT,(IMG_FLASH_ADDR>>16)
    .word UDREL,ZEROLT,ZBRANCH,1f-$
    .word LIT,0,EXIT
1:  .word TWODUP,LIT,FLASH_END&0xFFFF,LIT,(FLASH_END>>16)
    .word UDREL,ZEROLT,EXIT
    
; nom: ROW>FADR  ( u -- ud )
;   La plus petite plage de mémoire flash qui peut-être effacée est appellée ligne.    
;   Convertie un numéro de ligne en adresse FLASH 24 bits.
; arguments:
;   u    Numéro de ligne.
; arguments:
;   ud   Adresse 24 bits de la ligne.    
DEFWORD "ROW>FADR",8,,ROWTOFADR 
    .word LIT,FLASH_ROW_SIZE,MSTAR,EXIT
   
; nom: FERASE   ( u -- )    
;   Efface une ligne de mémoire FLASH MCU
;   Une ligne correspond à 1024 instructions.
;   Les instructions étant codées sur 24 bits, 1 ligne correspond à 3072 octets.
;   Le compteur d'instruction du MCU incrémente par 2 et pointe toujours sur une adresse paire.    
; arguments:      
;   u  numéro de la ligne.
; retourne:
;   rien
DEFWORD "FERASE",6,,FERASE ; ( u -- )
    .word ROWTOFADR ; S: ud
    .word QFLIMITS,ZBRANCH, 8f-$
    .word SWAP,LIT,0xF800,AND,SWAP ; ligne aligné sur 11 bits
    .word FALSE,VIDEO
    .word FADDR,LIT,FOP_EPAGE, FLASH_OP,TRUE,VIDEO,EXIT   
8:  .word DOTS,TWODROP
9:  .word EXIT
  
; nom: >FLASH  ( addr ud -- )
;   La programmation du PIC24EP512GP202 se fait par 6 octets. On doit écrire
;   C'est 6 octets ( 2 instructions machine) doivent-être écris dans des registres
;   spéciaux (latches) avant d'effectuer la programmation.  
;   Écriture de 6 octets dans les tampons FLASH MCU
; arguments: 
;   addr adresse RAM du premier octet de donnée.
;    ud  adresse mémoire flash  24 bits
; retourne:
;   rien  
DEFWORD ">FLASH",6,,TOFLASH ; ( addr ud -- )
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,DROP,EXIT ; jette les 2 adresses avant de quitter
1:  .word FADDR  ; S: addr
    .word WRITE_LATCH,LIT,FOP_WDWRITE,FLASH_OP,EXIT
    
  
; nom: RAM>FLASH  ( addr n ud -- )    
;   Écris en mémoire flash un bloc de données en RAM.
;   Le bloc de mémoire RAM identifié par addr doit avoir une grandeur multiple de 6. 
;   Au besoin remplir les octets excédentaires avec la valeur 0xFF.    
; arguments:    
;   addr  Adresse début données en RAM.
;   n     Nombre d'octets à écrire.
;   ud    addresse 24 bits en mémoire FLASH.
; retourne:
;   rien    
DEFWORD "RAM>FLASH",9,,RAMTOFLASH ; ( adr size ud -- )    
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,TWODROP,EXIT
1:  .word FADDR  ; S: addr size
    .word LIT,0,DODO ; S: addr
2:  .word DUP, WRITE_LATCH, LIT, FOP_WDWRITE, FLASH_OP
    .word FNEXT,LIT,6,PLUS,LIT,6,DOPLOOP,2b-$,DROP
9:  .word EXIT
  
; nom: FLASH>RAM  ( c-addr n ud -- )  
;  Lecture d'un bloc FLASH dans un tampon en mémoire RAM.
; arguments:  
;   c-addr  Adresse 16 bits début RAM.
;   n     Nombre d'octets à lire.
;   ud    adresse début bloc FLASH.
; retourne:
;   rien  
DEFWORD "FLASH>RAM",9,,FLASHTORAM ; ( c-addr size ud -- )
    .word ROT ; S: c-addr ud size  
    .word LIT,0,DOQDO,BRANCH,9f-$ ; S: c-addr ud 
1:  .word DOI,LIT,3,MOD,DUP,TOR ; S: c-addr ud n R: n
2:  .word NROT,TWODUP,TWOTOR,ROT,ICFETCH ; S: c-addr n  R: n ud
    .word OVER,CSTORE,ONEPLUS,TWORFROM,RFROM
    .word LIT,2,EQUAL,ZBRANCH,8f-$
    .word LIT,2,MPLUS
8:  .word DOLOOP,1b-$
9:  .word TWODROP,DROP
    .word EXIT  

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

; nom: Constantes liées au chargeur système  
;   IMGHEAD  adresse de la structure BOOT_HEADER
;   MAGIC    champ signature au début de l'entête  0x55AA
;   IMGROW   champ numéro premier ligne flash où débute l'image.
DEFCONST "IMGHEAD",7,,IMGHEAD,BOOT_HEADER ; entête secteur démarrage
DEFCONST "MAGIC",5,,MAGIC,0x55AA ; signature
DEFCONST "IMGROW",6,,IMGROW,FLASH_FIRST_ROW  ; numéro première ligne FLASH IMG  

; nom: BOOT_HEADER   ( -- n addr )
;   Il s'agit d'une structure maintenue en mémoire RAM et possédant les champs suivants:
;   SIGN   signature
;   LATEST valeur de la variable système LATEST à sauvegarder avec l'image.
;   DP     valeur de la variable système DP à sauvegarder avec l'image.
;   SIZE   grandeur de l'image.  
;   Pour chaque champ il y a un facilitateur d'accès qui retourne l'index du champ
;   et l'adresse de la structure.  
;   IMGSIGN   renvoie l'index du champ signature.
;   IMGLATST  renvoie l'index du champ LATEST
;   IMGDP     renvoie l'index du champ DP
;   IMGSIZE   renvoie l'index du champ SIZE  
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
    
;    
; initialise l'entête d'image  
DEFWORD "SETHEADER",9,,SETHEADER ; ( -- )
    .word MAGIC,IMGSIGN,TBLSTORE ; signature
    .word HERE,IMGDP,TBLSTORE ; DP
    .word LATEST,FETCH,IMGLATST,TBLSTORE ; latest
    .word HERE,DP0,MINUS,IMGSIZE,TBLSTORE ; size
    .word EXIT

; nom: IMGADDR  ( -- ud )  
;   Retourne la position en mémoire flash de l'image système.
; arguments:
;   aucun
; retourne:
;   ud   adresse 24 bits  
DEFWORD "IMGADDR",7,,IMGADDR ; ( -- ud )
    .word LIT,IMG_FLASH_ADDR,LIT,0,EXIT
    
; nom: ?IMG  ( -- f )    
;   Vérifie s'il y a une image disponible en mémoire flash et retourne 
;   indicateur Booléen vrai|faux.
; arguments:
;   aucun    
; retourne:
;     indicateur booléen vrai|faux
DEFWORD "?IMG",4,,QIMG ; (  -- f )
    .word IMGHEAD,LIT,BOOT_HEADER_SIZE,IMGADDR
    .word FLASHTORAM
    .word IMGSIGN,TBLFETCH,MAGIC,EQUAL
    .word EXIT
    
; nom: ?SIZE   ( -- n )    
;  Retourne la taille d'une image à partir de l'information dans la strucutre BOOT_HEADER.
; arguments:
;   aucun    
; retourne:
;    n  taille en octets    
DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word IMGSIZE,TBLFETCH,EXIT
    
; nom: ERASEROWS   ( -- )   
;   Efface les lignes mémoire flash du MCU qui seront utilisées
;   pour la sauvegarde de l'image système en RAM.
; arguments:
;   audun
; retourne:
;   rien    
DEFWORD "ERASEROWS",9,,ERASEROWS ; ( -- )
    .word IMGSIZE,TBLFETCH
    .word LIT,BOOT_HEADER_SIZE,PLUS
    .word LIT,FLASH_PAGE_SIZE,SLASHMOD
    .word SWAP,ZBRANCH,1f-$
    .word ONEPLUS
1:  .word IMGROW,SWAP,LIT,0,DODO
2:  .word DUP,FERASE,ONEPLUS,DOLOOP,2b-$
    .word DROP,EXIT
 
; nom: IMGSAVE   ( -- )    
;   Sauvegarde une image de la RAM dans la mémoire flash du MCU
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "IMGSAVE",7,,IMGSAVE ; ( -- )
    .word QEMPTY,ZBRANCH,2f-$ ; si RAM vide quitte
    .word EXIT
2:  .word SETHEADER
    .word ERASEROWS
    .word IMGHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS,IMGADDR
    .word RAMTOFLASH
9:  .word EXIT 

; nom: IMGLOAD  ( -- )  
;    Charge une image système RAM à partir de la mémoire flash du MCU.
;    Au démarrage de l'ordinateur IMGLOAD est appellé et s'il y a une image
;    système en mémoire flash celle-ci est chargée en mémoire RAM.
;    S'il n'y a pas d'image disponible le message "No boot image available."
;    est affiché à l'écran.  
; arguments:
;   aucun
; retourne:
;   rien  
DEFWORD "IMGLOAD",7,,IMGLOAD ; ( -- )
    .word QIMG,NOT,QABORT
    .byte 24
    .ascii "No boot image available."
    .align 2
    .word IMGHEAD,QSIZE,LIT,BOOT_HEADER_SIZE,PLUS
    .word IMGADDR,FLASHTORAM
    .word IMGDP,TBLFETCH,DP,STORE
    .word IMGLATST,TBLFETCH,LATEST,STORE
    .word EXIT

  