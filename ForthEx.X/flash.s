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
;  Permet l'acc�s � des donn�es stock�es dans la m�moire flash du MCU.
;  Pour prot�ger le syst�me l'�criture n'est autoris�e qu'� partir de l'adresse 
;  0x8000. Une image de la m�moire RAM utilisateur peut-�tre sauvegard�e dans la
;  m�moire flash du MCU avec le mot IMGSAVE.    
;  Cette image est automatiquement r�cup�r�e au d�marrage du syt�me. De plus si
;  cette image contient une d�finition appell�e AUTORUN celle-ci sera ex�cut�e au
;  au d�marrage de l'ordinateur ou suite � une commande REBOOT. 
;  La taille d'une image �tant limit�e par la RAM utilistateur disponible � 27912 octets
;  le reste de la m�moire flash peut-�tre utilis�e pour stocker des donn�es.
;  Il n'y pas de risque d'endommager une image si on enregistre des donn�es � partir
;  de l'adresse 0xF000 jusqu'� 0x557FE.    
; REF:
;  Pour plus d'information sur la programmation en runtime de la m�moire flash    
;  consultez les documents de r�f�rence Microchip: DS70609D et DS70000613D
;    
    
.section .hardware.bss  bss
; adresse du tampon pour �criture m�moire flash du MCU
_mflash_buffer: .space 2 
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots de bas niveau pour
; l'acc�s � la m�moire FLASH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; MFLASH   ( -- a-addr ) 
;   Retourne l'adresse du descripteur m�moire FLASH MCU
; arguments:
;   aucun
; retourne:
;   aucun 
;DEFTABLE "MFLASH",6,,MFLASH
;    .word _MCUFLASH ; m�moire FLASH du MCU    
;    .word FFETCH 
;    .word TOFLASH
;    .word FLASHTORAM
;    .word RAMTOFLASH
    
; nom: FBUFFER  (  -- a-addr )
;   R�servation d'un bloc de m�moire dynamique pour �criture d'une rang�e flash MCU.
;   Pour modifier une rang�e on la lit dans ce tampon et lorsque les modifications sont
;   compl�t�e, la rang�e est effac�e et reprogramm�e avec le contenu de ce tampon. 
;   Ce bloc de m�moire dynamique peut-�tre lib�r� apr�s usage en utilisant FREE il est
;   donc important de conserver une copie de son adresse. 
; arguments:
;   aucun
; retourne:
;   a-addr   Adresse du premier octet de donn�e du tampon.
DEFWORD "FBUFFER",7,,FBUFFER ; ( -- a-addr ) 
    .word LIT,FLASH_PAGE_SIZE,MALLOC,DUP,LIT,_mflash_buffer,STORE
    .word EXIT

    
; nom: F@  (  ud1 -- u )    
;   Lecture d'un mot de 16 bits dans la m�moire FLASH.
;   Si ud1 est pair utilise l'instruction machine TBLRDL pour retourner les bits 15:0
;   Si ud1 est impair utilise l'instruction machine TBLRDH pour retourner les bits 32:16
;   les bit 32:24 sont � z�ro puisque cet octet n'est pas impl�ment� dans le MCU.    
; arguments:
;   ud1  Adresse dans la m�mmoire flash du MCU.
; retourne:
;   u    Valeur lue � l'adresse ud1.
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
;    Si ud1 est impair  les bits 15:8 sont retourn�s, sinon les bits 7:0 sont retourn�s.
; arguments:
;   ud1  Entier double correspondant � l'adresse en m�moire flash.
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
;    Lecture d'un octet dans la m�moire flash du mot fort de l'instruction.
;    Utilise l'instruction machine TBLRDH.B
;    Si ud1 est impair retourne la valeur 0, sinon retourne les bits 23:16 de l'instruction.    
; arguments:
;   a-addr Adresse du premier octet de donn�e du tampon.
; retourne:
;   c Valeur lue � l'adresse ud1.  c repr�sente les bits 23..16 de l'instruction � l'adresse a-addr-1.
DEFCODE "FC@H",4,,FCFETCHH ; ( ud1 -- n )
    RPUSH TBLPAG
    mov T,TBLPAG
    DPOP
    tblrdh.b [T],T
    ze T,T
    RPOP TBLPAG
    NEXT

; nom: I@   ( ud -- u1 u2 u3 )    
;   lit 1 instruction de la m�moire FLASH du MCU. L'instrucion est s�par�e en
;   3 octets. Acc�s � la m�moire flash en utilisant les instructions machine TBLRDL et TBLRDH .
; arguments:    
;   ud  Adresse 24 bits m�moire flash
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
;   Lit 1 octet dans la m�moire flash � l'adresse d'instruction ud et � la position
;   d�sign�e par u. u est dans l'intervalle {0..2}
;   0 retourne l'octet faible, bits 7:0
;   1 retourne l'octet du milieu, bits 15:8
;   2 retourne l'octet fort, bits 23:16
; arguments:
;   ud   Entier double adresse de l'instruction. ud doit-?tre un nombre pair.
;   u    Entier dans l'intervalle {0..2} indiquant quel octet de l'instruction doit-�tre lu.
; retourne:
;   c    Octet lu dans la m�moire flash.
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
;   Initialise le pointeur d'addresse 24 bits pour la programmation de la m�moire FLASH du MCU.
;   Les addresse FLASH ont 24 bits. Il s'agit d'initialiser les registres sp�ciaux du MCU appell�es NVMADRU:NVMADR
; arguments:
;   ud   Entier double repr�sentant l'adresse en m�moire FLASH MCU.
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
;   Incr�mente le pointeur pour la programmation du prochain mot en m�moire FLASH MCU.
;   Il s'agit d'incr�menter les registres sp�ciaux du MCU  NVMARDU:NVBADR qui ensemble forme un pointeur 24 bits.
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
;   �criture de 6 octets dans les tampons utilis�s pour la programmation de la m�moire flash.
;   Le MCU PIC24EP512GP202 contient 2 registres de 24 bits pour les donn�es � enregistr�s dans
;   la m�moire flash. Une fois ces 2 registes intialis�s avec les donn�es on proc�de � l'op�ration
;   d'�criture proprement dit. Les 'latches' de programmation sont aux adresses 0xFA0000 et 0xFA0002   
; arguments:    
;   c-addr  Adresse du premier octet en m�moire RAM � copi� dans les tampons flash.
; retourne:
;   rien    
HEADLESS "WRITE_LATCH" ; ( addr --  )
    RPUSH DSRPAG
    movpag #1,DSRPAG
    RPUSH TBLPAG
    mov #0xFA,W0
    mov W0,TBLPAG
    mov #0,W0
    mov T, W1 ; adresse donn�e en RAM
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
;   S�quence d'�criture dans la m�moire flash du MCU.
;   op�rations disponibles:
;   0  programmation d'un seul registre de configuration.
;   1  programmation de 2 mots.
;   2  programmation de tous les latches.
;   3  efface une page pour le PIC24EP512GP202 il s'agit de 1024 instructions ou 3072 octets.
;   10 efface toute la m�moire flash auxiliaire ( sans effet sur PIC24EP512GP202).
;   13 efface toute la m�moire flash
;   Pour des raisons �videntes les op�rations > 3 sont refus�es.    
; arguments:
;   n    Constante identifiant le type d'op�ration flash � effectuer.
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
8:  btsc NVMCON,#WR ; attend la fin de l'op�ration.
    bra 8b
9:  NEXT
  
; nom: ?FLIMITS   ( ud -- ud f )    
;   V�rifie si l'adresse 24 bits repr�ssent�e par ud est dans la plage
;   valide et retourne un indicateur bool�en.
; arguments:
;   ud   Adresse 24 bits � contr�ler.
; retourne:
;   ud   Adresse contr�l�e.
;   f    Indicateur Bool�en, faux si cette adresse n'est pas valide.    
DEFWORD "?FLIMITS",8,,QFLIMITS ; ( addrl addrh -- addrl addrh f )
    .word TWODUP, LIT,IMG_FLASH_ADDR&0xFFFF,LIT,(IMG_FLASH_ADDR>>16)
    .word UDREL,ZEROLT,ZBRANCH,1f-$
    .word LIT,0,EXIT
1:  .word TWODUP,LIT,FLASH_END&0xFFFF,LIT,(FLASH_END>>16)
    .word UDREL,ZEROLT,EXIT
    
; nom: ROW>FADR  ( u -- ud )
;   Convertie un num�ro de rang�e en adresse FLASH 24 bits.
;   La plus petite plage de m�moire flash qui peut-�tre effac�e est appell�e rang�e ou page.    
;   Pour le PIC24EP512GP202 une rang�e repr�sente 1024 instructions machine
;   soit 2048 adresses PC ou 3072 octets.
;   donc ud=2048*u    
; arguments:
;   u    Num�ro de rang�e.
; retourne:
;   ud   Adresse 24 bits de la rang�e.    
DEFWORD "ROW>FADR",8,,ROWTOFADR 
    .word LIT,FLASH_ROW_SIZE,MSTAR,EXIT
   
; nom: FERASE   ( u -- )    
;   Efface une rang�e de m�moire FLASH MCU
;   Une rang�e correspond � 1024 instructions.
;   Les instructions �tant cod�es sur 24 bits, 1 rang�e correspond � 3072 octets.
;   Le compteur d'instruction du MCU incr�mente par 2 et pointe toujours sur une adresse paire. 
;   Voir ROW>FADR    
; arguments:      
;   u  num�ro de la rang�e.
; retourne:
;   rien
DEFWORD "FERASE",6,,FERASE ; ( u -- )
    .word ROWTOFADR ; S: ud
    .word QFLIMITS,ZBRANCH, 8f-$
    .word SWAP,LIT,0xF800,AND,SWAP ; rang�e align� sur 11 bits
    .word FALSE,VIDEO
    .word FADDR,LIT,FOP_EPAGE, FLASH_OP,TRUE,VIDEO,EXIT   
8:  .word DOTS,TWODROP
9:  .word EXIT
  
; nom: RAM>FLASH  ( c-addr n ud -- )    
;   �cris en m�moire flash un bloc de donn�es en RAM.
;   Si n n'est pas un  multiple de 6, jusqu'� 5 octets au del� du tampon seront copi�s en FLASH. 
;   Au besoin remplir les octets exc�dentaires avec la valeur 0xFF.    
; arguments:    
;   c-addr  Adresse d�but donn�es en RAM.
;   n     Nombre d'octets � �crire.
;   ud    Entier double, addresse 24 bits en m�moire FLASH.
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
;  Lecture d'un bloc FLASH dans un tampon en m�moire RAM.
; arguments:  
;   c-addr  Adresse 16 bits d�but RAM.
;   n     Nombre d'octets � lire.
;   ud    Entier double, adresse d�but plage FLASH.
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
;   image binaire dans la m�moire
;   flash du MCU. Cette image
;   est recharg�e automatiquement
;   au d�marrage de l'ordinateur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  
; IMGHEAD  ( -- a-addr )
;   Constante syst�me.    
;   Adresse de la structure d'ent�te d'image.
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
;   Constante syst�me.
;   signature pour reconna�tre s'il y a une image sauvegard�e en m�moire FLASH.
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
;   Constante syst�me.
;   Num�ro de la rang�e (page) o� est sauvegard�e l'image RAM en m�moire FLASH.
; arguments:
;   aucun
; retourne:
;   u	Num�ro de la rang�e
HEADLESS IMGROW,CODE
    DPUSH
    mov #FLASH_FIRST_ROW,T
    NEXT
;DEFCONST "IMGROW",6,,IMGROW,FLASH_FIRST_ROW  ; num�ro premi�re rang�e FLASH IMG  

; BOOT_HEADER   ( -- n addr )
;   Il s'agit d'une structure maintenue en m�moire RAM et poss�dant les champs suivants:
;   SIGN   signature
;   LATEST valeur de la variable syst�me LATEST � sauvegarder avec l'image.
;   DP     valeur de la variable syst�me DP � sauvegarder avec l'image.
;   SIZE   grandeur de l'image.  
;   Pour chaque champ il y a un facilitateur d'acc�s qui retourne l'index du champ
;   et l'adresse de la structure.  
;   IMGSIGN   renvoie l'index du champ signature.
;   IMGLATST  renvoie l'index du champ LATEST
;   IMGDP     renvoie l'index du champ DP
;   IMGSIZE   renvoie l'index du champ SIZE  
    
; IMGSIGN  ( -- u a-addr )
;   Retourne l'indice du champ SIGN et l'adresse de la structure BOOT_HEADER
;   Permet d'acc�der le champ avec TBL@ et TBL!    
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
;   Permet d'acc�der le champ avec TBL@ et TBL!    
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
;   Permet d'acc�der le champ avec TBL@ et TBL!    
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
;   Permet d'acc�der le champ avec TBL@ et TBL!    
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
;   Appell� par IMGSAVE
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
;   Retourne la position en m�moire flash de l'image syst�me.
; arguments:
;   aucun
; retourne:
;   ud   Adresse 24 bits 
HEADLESS IMGADDR,HWORD    
;DEFWORD "IMGADDR",7,,IMGADDR ; ( -- ud )
    .word LIT,IMG_FLASH_ADDR,LIT,0,EXIT
    
; nom: ?IMG  ( -- f )    
;   V�rifie s'il y a une image disponible en m�moire flash et retourne 
;   un indicateur Bool�en vrai|faux.
; arguments:
;   aucun    
; retourne:
;   f  Indicateur bool�en vrai|faux
DEFWORD "?IMG",4,,QIMG ; (  -- f )
    .word IMGHEAD,LIT,BOOT_HEADER_SIZE,IMGADDR
    .word FLASHTORAM
    .word IMGSIGN,TBLFETCH,MAGIC,EQUAL
    .word EXIT
    
; ?SIZE   ( -- n )    
;  Retourne la taille d'une image � partir de l'information dans la strucutre BOOT_HEADER.
;  Peut-�tre appell� apr�s ?IMG si cette fonction retourne vrai.
;  Peut aussi �tre appel� apr�s SETHEADER.    
; arguments:
;   aucun    
; retourne:
;    n  Taille de l'image en octets.    
HEADLESS QSIZE,HWORD    
;DEFWORD "?SIZE",5,,QSIZE ; ( -- n )  
    .word IMGSIZE,TBLFETCH,EXIT
    
; ERASEROWS   ( -- )   
;   Efface les lignes m�moire flash du MCU qui seront utilis�es
;   pour la sauvegarde de l'image syst�me en RAM. � partir de l'information
;   IMGSIZE contenu dans la structure BOOT_HEADER calcule le nombre de lignes
;   FLASH requises pour la sauvegarde de l'image et efface ces lignes.    
;   Appel� par IMGSAVE.    
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
;   Sauvegarde une image de la RAM dans la m�moire flash du MCU.
;   Les donn�es � partir de l'adresse DP0 jusqu'� l'adresse DP-1 sont
;   sauvegard�es dans cette image, ainsi que les valeurs des variables
;   syst�mes LATEST et DP.
;   Si le MCU est reprogramm� l'image est perdue et devra �tre resauvegard�e.    
;   l'image est sauvegard�e � l'adresse flash 0x8000. Les 8 premiers octets sont
;   une structure de donn�es utilis� par IMGLOAD. Cette structure est la suivante.
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
;    Charge une image syst�me RAM � partir de la m�moire flash du MCU.
;    Au d�marrage de l'ordinateur IMGLOAD est appell� et s'il y a une image
;    syst�me en m�moire flash celle-ci est charg�e en m�moire RAM.
;    S'il n'y a pas d'image disponible le message "No boot image available."
;    est affich� � l'�cran.
;    Si l'image charg�e en RAM contient une d�finition AUTORUN dans son dictionnaire
;    ce mot est ex�cut�.
;    IMGLOAD peut-�tre appell� manuellement pour restaurer l'�tat syst�me � l'�tat
;    initial au d�marrage, dans ce cas AUTORUN n'est pas ex�cut�.  
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

  