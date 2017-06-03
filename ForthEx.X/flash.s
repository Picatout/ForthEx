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
;  0x8000. Une image de la mémoire RAM utilisateur peut-être sauvegardée dans la
;  mémoire flash du MCU avec le mot IMGSAVE.    
;  Cette image est automatiquement récupérée au démarrage du sytème. De plus si
;  cette image contient une définition appellée AUTORUN celle-ci sera exécutée au
;  au démarrage de l'ordinateur ou suite à une commande REBOOT. 
;  La taille d'une image étant limitée par la RAM utilistateur disponible à 27912 octets
;  le reste de la mémoire flash peut-être utilisée pour stocker des données.
;  Il n'y pas de risque d'endommager une image si on enregistre des données à partir
;  de l'adresse 0xF000 jusqu'à 0x557FE.    
; REF:
;  Pour plus d'information sur la programmation en runtime de la mémoire flash    
;  consultez les documents de référence Microchip: DS70609D et DS70000613D
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
    
; nom: FBUFFER  (  -- a-addr )
;   Réservation d'un bloc de mémoire dynamique pour écriture d'une rangée flash MCU.
;   Pour modifier une rangée on la lit dans ce tampon et lorsque les modifications sont
;   complétée, la rangée est effacée et reprogrammée avec le contenu de ce tampon. 
;   Ce bloc de mémoire dynamique peut-être libéré après usage en utilisant FREE il est
;   donc important de conserver une copie de son adresse. 
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse du premier octet de donnée du tampon.
DEFWORD "FBUFFER",7,,FBUFFER ; ( -- a-addr ) 
    .word LIT,FLASH_PAGE_SIZE,MALLOC,DUP,LIT,_mflash_buffer,STORE
    .word EXIT

    
; nom: F@  (  ud1 -- u )    
;   Lecture d'un mot de 16 bits dans la mémoire FLASH.
;   Si ud1 est pair utilise l'instruction machine TBLRDL pour retourner les bits 15:0
;   Si ud1 est impair utilise l'instruction machine TBLRDH pour retourner les bits 32:16
;   les bit 32:24 sont à zéro puisque cet octet n'est pas implémenté dans le MCU.    
; arguments:
;   ud1  Adresse dans la mémmoire flash du MCU.
; retourne:
;   u    Valeur lue à l'adresse ud1.
DEFCODE "F@",2,,FFETCH ; ( ud1 -- u )
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
  
; nom: FC@L ( ud1 -- c )
;   Lecture d'un octet dans la partie basse de l'instruction. 
;   Utilise l'instruction machine TBLRDL.B    
;    Si ud1 est impair  les bits 15:8 sont retournés, sinon les bits 7:0 sont retournés.
; arguments:
;   ud1  Entier double correspondant à l'adresse en mémoire flash.
; retourne:
;   c    Si impair(ud1) c=bits{15:8}  sinon c=bits{7:0}
DEFCODE "FC@L",4,,FCFETCHL 
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdl.b [T],T
    ze T,T
    RPOP TBLPAG
    NEXT
    
    
; nom: FC@H   ( ud1 -- c )    
;    Lecture d'un octet dans la mémoire flash du mot fort de l'instruction.
;    Utilise l'instruction machine TBLRDH.B
;    Si ud1 est impair retourne la valeur 0, sinon retourne les bits 23:16 de l'instruction.    
; arguments:
;   a-addr Adresse du premier octet de donnée du tampon.
; retourne:
;   c Valeur lue à l'adresse ud1.  c représente les bits 23..16 de l'instruction à l'adresse a-addr-1.
DEFCODE "FC@H",4,,FCFETCHH ; ( ud1 -- n )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdh.b [T],T
    ze T,T
    RPOP TBLPAG
    NEXT

; nom: I@   ( ud -- u1 u2 u3 )    
;   lit 1 instruction de la mémoire FLASH du MCU. L'instrucion est séparée en
;   3 octets. Accès à la mémoire flash en utilisant les instructions machine TBLRDL et TBLRDH .
; arguments:    
;   ud  Adresse 24 bits mémoire flash
; retourne:
;   u1  Bits 16:23 
;   u2  Bits 8:15
;   u3  Bits 0:7    
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
 
; nom: IC@ ( ud u -- c )
;   Lit 1 octet dans la mémoire flash à l'adresse d'instruction ud et à la position
;   désignée par u. u est dans l'intervalle {0..2}
;   0 retourne l'octet faible, bits 7:0
;   1 retourne l'octet du milieu, bits 15:8
;   2 retourne l'octet fort, bits 23:16
; arguments:
;   ud   Entier double adresse de l'instruction. ud doit-?tre un nombre pair.
;   u    Entier dans l'intervalle {0..2} indiquant quel octet de l'instruction doit-être lu.
; retourne:
;   c    Octet lu dans la mémoire flash.
DEFCODE "IC@",3,,ICFETCH ; ( ud u -- c )
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
    
; FADDR   ( ud -- )    
;   Initialise le pointeur d'addresse 24 bits pour la programmation de la mémoire FLASH du MCU.
;   Les addresse FLASH ont 24 bits. Il s'agit d'initialiser les registres spéciaux du MCU appellées NVMADRU:NVMADR
; arguments:
;   ud   Entier double représentant l'adresse en mémoire FLASH MCU.
; retourne:
;   rien    
HEADLESS FADDR,CODE    
;DEFCODE "FADDR",5,,FADDR ; ( ud -- )
    mov T, NVMADRU
    DPOP
    mov T, NVMADR
    DPOP
    NEXT

; FNEXT   ( -- )
;   Incrémente le pointeur pour la programmation du prochain mot en mémoire FLASH MCU.
;   Il s'agit d'incrémenter les registres spéciaux du MCU  NVMARDU:NVBADR qui ensemble forme un pointeur 24 bits.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS FNEXT,CODE    
;DEFCODE "FNEXT",5,,FNEXT ; ( -- )
    mov #4,W0
    add NVMADR
    clr W0
    addc NVMADRU
    NEXT


; WRITE_LATCH  ( c-addr -- )    
;   Écriture de 6 octets dans les tampons utilisés pour la programmation de la mémoire flash.
;   Le MCU PIC24EP512GP202 contient 2 registres de 24 bits pour les données à enregistrés dans
;   la mémoire flash. Une fois ces 2 registes intialisés avec les données on procède à l'opération
;   d'écriture proprement dit. Les 'latches' de programmation sont aux adresses 0xFA0000 et 0xFA0002   
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
;   opérations disponibles:
;   0  programmation d'un seul registre de configuration.
;   1  programmation de 2 mots.
;   2  programmation de tous les latches.
;   3  efface une page pour le PIC24EP512GP202 il s'agit de 1024 instructions ou 3072 octets.
;   10 efface toute la mémoire flash auxiliaire ( sans effet sur PIC24EP512GP202).
;   13 efface toute la mémoire flash
;   Pour des raisons évidentes les opérations > 3 sont refusées.    
; arguments:
;   n    Constante identifiant le type d'opération flash à effectuer.
; retourne:
;   rien    
HEADLESS "FLASH_OP"  ; ( op -- )
    cp T,#4
    bra ltu,2f
    DPOP
    bra 9f
2:  mov #(1<<WREN),W0 ; write enable
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
8:  btsc NVMCON,#WR ; attend la fin de l'opération.
    bra 8b
9:  NEXT
  
; nom: ?FLIMITS   ( ud -- ud f )    
;   Vérifie si l'adresse 24 bits représsentée par ud est dans la plage
;   valide et retourne un indicateur booléen.
; arguments:
;   ud   Adresse 24 bits à contrôler.
; retourne:
;   ud   Adresse contrôlée.
;   f    Indicateur Booléen, faux si cette adresse n'est pas valide.    
DEFWORD "?FLIMITS",8,,QFLIMITS ; ( addrl addrh -- addrl addrh f )
    .word TWODUP, LIT,IMG_FLASH_ADDR&0xFFFF,LIT,(IMG_FLASH_ADDR>>16)
    .word UDREL,ZEROLT,ZBRANCH,1f-$
    .word LIT,0,EXIT
1:  .word TWODUP,LIT,FLASH_END&0xFFFF,LIT,(FLASH_END>>16)
    .word UDREL,ZEROLT,EXIT
    
; nom: ROW>FADR  ( u -- ud )
;   Convertie un numéro de rangée en adresse FLASH 24 bits.
;   La plus petite plage de mémoire flash qui peut-être effacée est appellée rangée ou page.    
;   Pour le PIC24EP512GP202 une rangée représente 1024 instructions machine
;   soit 2048 adresses PC ou 3072 octets.
;   donc ud=2048*u    
; arguments:
;   u    Numéro de rangée.
; retourne:
;   ud   Adresse 24 bits de la rangée.    
DEFWORD "ROW>FADR",8,,ROWTOFADR 
    .word LIT,FLASH_ROW_SIZE,MSTAR,EXIT
   
; nom: FERASE   ( u -- )    
;   Efface une rangée de mémoire FLASH MCU
;   Une rangée correspond à 1024 instructions.
;   Les instructions étant codées sur 24 bits, 1 rangée correspond à 3072 octets.
;   Le compteur d'instruction du MCU incrémente par 2 et pointe toujours sur une adresse paire. 
;   Voir ROW>FADR    
; arguments:      
;   u  numéro de la rangée.
; retourne:
;   rien
DEFWORD "FERASE",6,,FERASE ; ( u -- )
    .word ROWTOFADR ; S: ud
    .word QFLIMITS,ZBRANCH, 8f-$
    .word SWAP,LIT,0xF800,AND,SWAP ; rangée aligné sur 11 bits
    .word FALSE,VIDEO
    .word FADDR,LIT,FOP_EPAGE, FLASH_OP,TRUE,VIDEO,EXIT   
8:  .word DOTS,TWODROP
9:  .word EXIT
  
; nom: RAM>FLASH  ( c-addr n ud -- )    
;   Écris en mémoire flash un bloc de données en RAM.
;   Si n n'est pas un  multiple de 6, jusqu'à 5 octets au delà du tampon seront copiés en FLASH. 
;   Au besoin remplir les octets excédentaires avec la valeur 0xFF.    
; arguments:    
;   c-addr  Adresse début données en RAM.
;   n     Nombre d'octets à écrire.
;   ud    Entier double, addresse 24 bits en mémoire FLASH.
; retourne:
;   rien    
DEFWORD "RAM>FLASH",9,,RAMTOFLASH ; ( c-addr n ud -- )    
    .word QFLIMITS,TBRANCH,1f-$
    .word TWODROP,TWODROP,EXIT
1:  .word FADDR  ; S: c-addr n
    .word LIT,0,DODO ; S: c-addr
2:  .word DUP, WRITE_LATCH, LIT, FOP_WDWRITE, FLASH_OP
    .word FNEXT,LIT,6,PLUS,LIT,6,DOPLOOP,2b-$,DROP
9:  .word EXIT
  
; nom: FLASH>RAM  ( c-addr n ud -- )  
;  Lecture d'un bloc FLASH dans un tampon en mémoire RAM.
; arguments:  
;   c-addr  Adresse 16 bits début RAM.
;   n     Nombre d'octets à lire.
;   ud    Entier double, adresse début plage FLASH.
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

  
; IMGHEAD  ( -- a-addr )
;   Constante système.    
;   Adresse de la structure d'entête d'image.
;   Structure BOOT_HEADER    
;   00 IMGSIGN, 2 octets
;   02 IMGLATST, 2 octets
;   04 IMGDP, 2 octets  
;   06 IMGSIZE 2 octets
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse de la structure BOOT_HEADER    
HEADLESS IMGHEAD,CODE
    DPUSH
    mov #BOOT_HEADER,T
    NEXT
    
;DEFCONST "IMGHEAD",7,,IMGHEAD,BOOT_HEADER

; MAGIC  ( -- u )
;   Constante système.
;   signature pour reconnaître s'il y a une image sauvegardée en mémoire FLASH.
; arguments:
;   aucun
; retourne:
;   u	Signature 0x55AA
HEADLESS MAGIC,CODE    
    DPUSH
    mov #0x55AA,T
    NEXT
;DEFCONST "MAGIC",5,,MAGIC,0x55AA
    
; IMGROW  ( -- u )
;   Constante système.
;   Numéro de la rangée (page) où est sauvegardée l'image RAM en mémoire FLASH.
; arguments:
;   aucun
; retourne:
;   u	Numéro de la rangée
HEADLESS IMGROW,CODE
    DPUSH
    mov #FLASH_FIRST_ROW,T
    NEXT
;DEFCONST "IMGROW",6,,IMGROW,FLASH_FIRST_ROW  ; numéro première rangée FLASH IMG  

; BOOT_HEADER   ( -- n addr )
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
    
; IMGSIGN  ( -- u a-addr )
;   Retourne l'indice du champ SIGN et l'adresse de la structure BOOT_HEADER
;   Permet d'accéder le champ avec TBL@ et TBL!    
; arguments:
;   aucun
; retourne:
;   u   Indice du champ.
;   a-addr  Adresse de la structure BOOT_HEADER    
HEADLESS IMGSIGN,HWORD    
;DEFWORD "IMGSIGN",7,,IMGSIGN  ; ( -- u addr )
    .word LIT,0,IMGHEAD,EXIT

; IMGLATST  ( -- u a-addr )
;   Retourne l'indice du champ LATEST et l'adresse de la structure BOOT_HEADER
;   Permet d'accéder le champ avec TBL@ et TBL!    
; arguments:
;   aucun
; retourne:
;   u   Indice du champ.
;   a-addr  Adresse de la structure BOOT_HEADER    
HEADLESS IMGLATST,HWORD    
;DEFWORD "IMGLATST",8,,IMGLATST  ; ( -- u addr )
    .word LIT,1,IMGHEAD,EXIT

; IMGDP  ( -- u a-addr )
;   Retourne l'indice du champ DP et l'adresse de la structure BOOT_HEADER
;   Permet d'accéder le champ avec TBL@ et TBL!    
; arguments:
;   aucun
; retourne:
;   u   Indice du champ.
;   a-addr  Adresse de la structure BOOT_HEADER    
HEADLESS IMGDP,HWORD    
;DEFWORD "IMGDP",5,,IMGDP ; ( -- u addr )
    .word LIT,2,IMGHEAD,EXIT
    
; IMGSIZE  ( -- u a-addr )
;   Retourne l'indice du champ signature et l'adresse de la structure BOOT_HEADER
;   Permet d'accéder le champ avec TBL@ et TBL!    
; arguments:
;   aucun
; retourne:
;   u   Indice du champ.
;   a-addr  Adresse de la structure BOOT_HEADER    
HEADLESS IMGSIZE,HWORD
;DEFWORD "IMGSIZE",7,,IMGSIZE ; ( -- u addr )
    .word LIT,3,IMGHEAD,EXIT
    
; SETHEADER ( -- )   
;   initialise la structure BOOT_HEADER avec les informations requises.
;   Appellé par IMGSAVE
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS SETHEADER,HWORD    
;DEFWORD "SETHEADER",9,,SETHEADER ; ( -- )
    .word MAGIC,IMGSIGN,TBLSTORE ; signature
    .word HERE,IMGDP,TBLSTORE ; DP
    .word LATEST,FETCH,IMGLATST,TBLSTORE ; latest
    .word HERE,DP0,MINUS,IMGSIZE,TBLSTORE ; size
    .word EXIT

; IMGADDR  ( -- ud )  
;   Retourne la position en mémoire flash de l'image système.
; arguments:
;   aucun
; retourne:
;   ud   Adresse 24 bits 
HEADLESS IMGADDR,HWORD    
;DEFWORD "IMGADDR",7,,IMGADDR ; ( -- ud )
    .word LIT,IMG_FLASH_ADDR,LIT,0,EXIT
    
; nom: ?IMG  ( -- f )    
;   Vérifie s'il y a une image disponible en mémoire flash et retourne 
;   un indicateur Booléen vrai|faux.
; arguments:
;   aucun    
; retourne:
;   f  Indicateur booléen vrai|faux
DEFWORD "?IMG",4,,QIMG ; (  -- f )
    .word IMGHEAD,LIT,BOOT_HEADER_SIZE,IMGADDR
    .word FLASHTORAM
    .word IMGSIGN,TBLFETCH,MAGIC,EQUAL
    .word EXIT
    
; ?SIZE   ( -- n )    
;  Retourne la taille d'une image à partir de l'information dans la strucutre BOOT_HEADER.
;  Peut-être appellé après ?IMG si cette fonction retourne vrai.
;  Peut aussi être appelé après SETHEADER.    
; arguments:
;   aucun    
; retourne:
;    n  Taille de l'image en octets.    
HEADLESS QSIZE,HWORD    
;DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word IMGSIZE,TBLFETCH,EXIT
    
; ERASEROWS   ( -- )   
;   Efface les lignes mémoire flash du MCU qui seront utilisées
;   pour la sauvegarde de l'image système en RAM. À partir de l'information
;   IMGSIZE contenu dans la structure BOOT_HEADER calcule le nombre de lignes
;   FLASH requises pour la sauvegarde de l'image et efface ces lignes.    
;   Appelé par IMGSAVE.    
; arguments:
;   audun
; retourne:
;   rien    
HEADLESS ERASEROWS,HWORD    
;DEFWORD "ERASEROWS",9,,ERASEROWS ; ( -- )
    .word IMGSIZE,TBLFETCH
    .word LIT,BOOT_HEADER_SIZE,PLUS
    .word LIT,FLASH_PAGE_SIZE,SLASHMOD
    .word SWAP,ZBRANCH,1f-$
    .word ONEPLUS
1:  .word IMGROW,SWAP,LIT,0,DODO
2:  .word DUP,FERASE,ONEPLUS,DOLOOP,2b-$
    .word DROP,EXIT
 
; nom: IMGSAVE   ( -- )    
;   Sauvegarde une image de la RAM dans la mémoire flash du MCU.
;   Les données à partir de l'adresse DP0 jusqu'à l'adresse DP-1 sont
;   sauvegardées dans cette image, ainsi que les valeurs des variables
;   systèmes LATEST et DP.
;   Si le MCU est reprogrammé l'image est perdue et devra être resauvegardée.    
;   l'image est sauvegardée à l'adresse flash 0x8000. Les 8 premiers octets sont
;   une structure de données utilisé par IMGLOAD. Cette structure est la suivante.
;   offset | description
;   ---------------------
;   0 | signature 0x55AA
;   2 | valeur de la variable LATEST pour cette image.
;   4 | valeur de la variable DP pour cette image.
;   6 | grandeur du data en octets.
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
;    Si l'image chargée en RAM contient une définition AUTORUN dans son dictionnaire
;    ce mot est exécuté.
;    IMGLOAD peut-être appellé manuellement pour restaurer l'état système à l'état
;    initial au démarrage, dans ce cas AUTORUN n'est pas exécuté.  
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

  