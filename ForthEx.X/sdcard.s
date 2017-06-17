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

;NOM: sdcard.s
;Date: 2017-03-20
; DESCRIPTION:  
; Interface de base pour l'acc�s � la carte SD en utilisant l'interface SPI de celle-ci.
; Permet l'initialisation de la carte ainsi que la lecture et l'�criture d'un bloc de
; donn�e sur la carte.
; REF: http://elm-chan.org/docs/mmc/mmc_e.html
; REF: http://elm-chan.org/docs/mmc/pic/sdinit.png    
; REF: https://www.sdcard.org/downloads/pls/
; HTML:
; <br>
; :HTML
 
; indicateurs bool�ens carte SD
.equ F_SDC_IN, 0 ; carte dans la fente
.equ F_SDC_OK,1 ; carte ins�r�e et initialis�e
.equ F_SDC_V2,2 ; carte version 2
.equ F_SDC_HC,3 ; carte haute capacit�, adress�e par bloc de 512 octets.
.equ F_SDC_TO,4 ; commande time out
.equ F_SDC_WE,5 ; erreur �criture
.equ F_SDC_RE,6 ; erreur lecture
.equ F_SDC_IE,7 ; erreur initialisation  
.equ F_BAD_CARD,8 ; la carte ne r�pond pas
 
;commandes carte SD
.equ GO_IDLE_STATE, 0            ; CMD0 - r�initialise carte
.equ SEND_OP_COND,        1      ; CMD1 - requ�te condition d'op�ration
.equ SEND_IF_COND,        8      ; CMD8 - requ�te condition d'interface
.equ SEND_CSD,            9      ; CMD9 - requ�te pour lecture du registre CSD
.equ SEND_CID,            10     ; CMD10 - requ�te pour lecture du registre CID    
.equ SET_BLOCKLEN,        16     ; CMD16 - fixe longueur bloc
.equ READ_SINGLE_BLOCK,   17     ; CMD17 - lecture d'un seul bloc
.equ WRITE_SINGLE_BLOCK,    24   ; CMD24 - �criture d'un bloc
.equ APP_CMD,                55  ; CMD55 - commande escape
.equ READ_OCR,            58     ; CMD58 - requ�te registre ocr
.equ CRC_ON_OFF,            59   ; CMD59 - activation/d�sactivation CRC
.equ SD_STATUS,            13    ; ACMD13 - requ�te status
.equ SEND_OP_COND,        41  ; ACMD41 - requ�te condition d'op�ration
; certaines commandes requi�re une valeur pour CRC
.equ CMD0_CRC, 0x95 
.equ CMD8_CRC, 0x87
.equ CMDX_CRC, 0xFF  ; autre commandes
    
.equ SECTOR_SIZE, 512 ; nombre d'octets par secteur carte SD.    
    
.section .sdc.bss  bss
.global sdc_status
sdc_status: .space 2 ; indicateurs bool�ens carte SD
blocs_count: .space 4 ; nombre de bloc de 1024 octets
seg_count: .space 2 ;  nombre de segments de 65535 blocs
sdc_segment: .space 2 ; segment s�lectionn�. 
sdc_R: .space 32; tampon pour la r�ponse de la carte 
 
 
INTR
;la broche SDC_DETECT
; a chang�e d'�tat
; carte ins�r�e ou retir�e. 
.global __CNInterrupt
__CNInterrupt:
    bclr SDC_IFS,#SDC_IF
    clr sdc_status
    btss SDC_PORT,#SDC_DETECT
    bset sdc_status,#F_SDC_IN
    retfie
    
 
.text
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; envoie 80 cycles clock SPI
; la carte est d�s�lectionn�e
; pendant cette proc�dure
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
; d�s�lection de la carte SD
; 1 octet doit-�tre envoy�e
; apr�s que CS est ramen� � 1
; pour lib�r� la ligne MISO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
sdc_deselect:
    bset SDC_LAT,#SDC_SEL
    mov.b #0xff,W0
    spi_write
    _disable_spi
    return
  
; attend que la carte soit pr�te
sdc_wait_ready:
    push W0
    mov #10,W0
    mov W0,tone_len
1:  spi_read
    cp.b W0,#0xFF
    bra z, 2f
    cp0 tone_len
    bra nz, 1b
2:  pop W0
    return
    
; calcule l'adresse � partir du no de bloc
; arguments: 
;   ud1 Num�ro de secteur
; retourne:
;   ud2   Adresse absolue sur la carte SD.    
sector_to_address: ;   ( ud1 -- ud2 )    
    mov #BLOCK_SIZE,W2
    mul.uu T,W2,W0
    mov W0,T
    mul.uu W2,[DSP],W0
    add T,W1,T
    mov W0,[DSP]
    return
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; envoie d'une commande carte SD
; arguments: 
;    W0  index commande
;    W1  arg b1 b2  W1[15:8]->R:31..24,W1[7:0]->R:23..16
;    W2  arg b3 b4  W2[15:7]->R:15..8,W2[7:0]->R:7..0
;    W3  nombre d'octets suppl�mentaire dans la r�ponse
;    W4  pointeur tampon r�ponse  
; retourne:
;    T  R1
;    r�ponse de la carte dans sdc_R    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sdc_cmd:
    call sdc_wait_ready
    push W5
    mov W0,W5
    ior #0x40,W0
    spi_write
    mov W1,W0
    swap W0
    spi_write
    mov W1,W0
    spi_write
    mov W2,W0
    swap W0
    spi_write
    mov W2,W0
    spi_write
    cp0 W5 
    bra nz, 1f
    mov #CMD0_CRC,W0
    spi_write
    bra wait_response
1:  mov #SEND_IF_COND,W0
    cp W0,W5
    bra nz, 2f
    mov #CMD8_CRC,W0
    spi_write
    bra wait_response
2:  mov #CMDX_CRC,W0
    spi_write
wait_response:
; r�ception de R1    
    mov #8,W1 ; d�lais r�ponse
1:
    mov.b #0xff,W0
    spi_write
    xor.b #0xFF,W0
    bra nz, 2f
    dec W1,W1
    bra nz, 1b
    bset sdc_status, #F_SDC_TO
    DPUSH
    clr T
    pop W5
    return
2: ; octet R1 re�u, transfert dans T.
    xor.b #0xFF,W0
    DPUSH
    ze W0,T
    ; r�ception autres octets de la r�ponse.
3:  cp0 W3
    bra nz, 4f
    pop W5
    return
4:  spi_read
    mov.b W0,[W4++]
    dec W3,W3
    bra 3b

; lecture de CSD|CID    
; arguments:
;  W0 index commande, CMD9|CMD10
read_card_register:
    _enable_sdc
    clr W1
    clr W2
    clr W3
    call sdc_cmd
    cp0 T
    bra z, wait_data_token
    clr T
    bra 9f
wait_data_token:
    spi_read
    cp.b W0,#0xff
    bra z, wait_data_token
    cp.b W0,#0xfe
    bra z,accept_data
    clr T
    bra 9f
accept_data:    
    mov #sdc_R,W1
    mov #16,W2
2:  spi_read
    mov.b W0,[W1++]
    dec W2,W2
    bra nz,2b
accept_crc:
    spi_read
    spi_read
    setm T
9:  call sdc_deselect
    return
   
; lecture capacit� de la carte.
set_size:    
    mov #SEND_CSD,W0
    call read_card_register
    cp0 T
    bra z, 9f
    btss sdc_status,#F_SDC_HC
    bra version1
    mov #sdc_R,W2
    mov.b [W2++],W1
    ze W1,W1
    swap W1
    mov.b [W2],W0
    ze W0,W0
    add W0,W1,W0
    inc W0,W0
    bra 8f
version1:
    ; � compl�t�

8:  ; nombre de blocs de 1Ko
    mov #512,W1
    mul.uu W0,W1,W0
    mov W0,seg_count
    mov W1,seg_count+2
    
9:  return
    
; retourne:
;    f   vrai si succ�s    
DEFCODE "READ-CSD",8,,READCSD
    mov #SEND_CSD,W0
    call read_card_register
    NEXT
    
    
; retourne:
;    f   vrai si succ�s    
DEFCODE "READ-CID",8,,READCID
    mov #SEND_CID,W0
    call read_card_register
    NEXT
    
; nom: CARD-INFO  ( -- )
;   Affiche les informations inscrite dans le registre CID de la carte.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "CARD-INFO",9,,CARDINFO
    .word READCID, ZBRANCH,9f-$
    .word SDCR,CR,STRQUOTE
    .byte 4
    .ascii "MID:"
    .align 2
    .word TYPE, DUP,CFETCH,UDOT,CR
    .word STRQUOTE
    .byte 5
    .ascii "OID: "
    .align 2
    .word TYPE,ONEPLUS,DUP,LIT,2,TYPE,CR
    .word STRQUOTE
    .byte 5
    .ascii "PNM: "
    .align 2
    .word TYPE,TWOPLUS,DUP,LIT,5,TYPE,CR
    .word STRQUOTE
    .byte 4
    .ascii "PRV:"
    .align 2
    .word TYPE,LIT,5,PLUS,DUP,CFETCH
    .word DUP,LIT,4,RSHIFT,DOT,LIT,'.',EMIT
    .word LIT,15,AND,DOT,CR
    .word STRQUOTE
    .byte 4
    .ascii "PSN:"
    .align 2
    .word TYPE,ONEPLUS,DUP,BIDFETCH,UDDOT,CR,LIT,4,PLUS
    .word STRQUOTE
    .byte 4
    .ascii "MTD:"
    .align 2
    .word TYPE,DUP,CFETCH,LIT,4,LSHIFT,TOR,ONEPLUS,CFETCH,DUP,LIT,4,RSHIFT
    .word RFROM,PLUS,LIT,2000,PLUS,UDOT,LIT,'/',EMIT
    .word LIT,15,AND,UDOT,CR
    .word READCSD,ZBRANCH,9f-$
    .word SDCR,LIT,8,PLUS,DUP,CFETCH,LIT,8,LSHIFT,TOR,ONEPLUS,CFETCH,RFROM,PLUS
    .word ONEPLUS,LIT,10,SLASH
    .word STRQUOTE
    .byte 5
    .ascii "SIZE:"
    .align 2
    .word TYPE,UDOT,STRQUOTE
    .byte 2
    .ascii "GB"
    .align 2
    .word TYPE,CR
9:  .word EXIT
  
; nom: SDC-R ( -- a-addr )
;   Adresse de la m�moire tampon de 16 octets qui re�ois la r�ponse de la carte SD.
; arguments:
;   aucun
; retourne:
;   a-addr Adresse du vecteur r�ponse carte SD.
DEFCONST "SDC-R",5,,SDCR,sdc_R    
    
; nom: SDCINIT ( -- f )
;   Initialisation carte SD 
;   REF: http://elm-chan.org/docs/mmc/pic/sdinit.png    
; arguments:
;   aucun
; retourne:
;    f   Indicateur Bool�en, vrai si l'initialisation est r�ussie.   
DEFCODE "SDCINIT",7,,SDCINIT ; ( -- f )
    clr sdc_status
    btsc SDC_PORT,#SDC_DETECT
    bra failed
    bset sdc_status,#F_SDC_IN
    mov #SCLK_SLOW,W1
    call set_spi_clock
    call dummy_clock
    mov #2,W0
    mov W0,tone_len
1:  cp0 tone_len
    bra nz, 1b
    _enable_sdc
cmd0:
    mov #GO_IDLE_STATE,W0
    clr W1
    clr W2
    clr W3
    mov #sdc_R,W4
    call sdc_cmd
    cp.b T,#1
    DPOP
    bra z, cmd8
    bra failed
cmd8:
    mov #SEND_IF_COND,W0
    clr W1
    mov #0x1AA,W2
    mov #4,W3
    call sdc_cmd
    cp.b T,#1
    DPOP
    bra z, 3f
    bra acmd41 ; carte V1?
3:
    mov [--W4],W0
    swap W0
    cp W2,W0
    bra nz, failed
    bset sdc_status,#F_SDC_V2
acmd41:
    mov #1000,W0
    mov W0,tone_len ; d�lais 1 seconde
5:  mov #APP_CMD,W0
    clr W1
    clr W2
    clr W3
    mov #sdc_R,W4
    call sdc_cmd
    DPOP
    mov #SEND_OP_COND,W0
    btsc sdc_status,#F_SDC_V2
    mov #0x4000,W1
    call sdc_cmd
    cp0 T
    DPOP
    bra z, cmd58
6:  cp0 tone_len
    bra nz, 5b
    bra timeout
cmd58:
    btss sdc_status, #F_SDC_V2
    bra cmd16
    mov #READ_OCR,W0
    clr W1
    clr W2
    mov #4,W3
    call sdc_cmd
    cp0 T
    DPOP
    bra nz, failed
    btss.b sdc_R,#6
    bra cmd16
    bset sdc_status,#F_SDC_HC
    bra query_size
cmd16:
    mov #SET_BLOCKLEN,W0
    clr W1
    mov #0x200,W2
    clr W3
    call sdc_cmd
    cp0 T
    DPOP
    bra z, query_size
    bra failed
timeout:
    bset sdc_status,#F_SDC_TO
failed:
    DPUSH
    clr T
    bra 9f
query_size:
    call set_size
    cp0 T
    bra z, 9f-$
succeed:
    bset sdc_status,#F_SDC_OK
    DPUSH
    mov #-1,T
8:  call sdc_deselect
9:  mov #SCLK_FAST,W1
    call set_spi_clock
    NEXT

; nom: segment ( u -- )
;   D�termine quel segment de la carte est actif.
;   Le syst�me d�finit dans block.s ne permet que d'acc�der 65535 blocs sur un p�riph�rique
;   ce qui repr�sente 1024*65535 ou 2^10 * (2^16-1)= 67107840 octets hors les plus petites
;   cartes disponible de nos jours sont de 2Go. Les cartes sont donc subdivis�es en segments
;   de 65535 blocs chacun.    
; arguments:
;   u Num�ro du segment.
; retourne:
;   rien    
    
; nom: ?SDC  ( -- u )    
;   Retourne un entier non sign� contenant les indicateurs bool�en suivants
; HTML:
; <br><table border="single">    
; <tr><th><center>bit</center></th><th>nom</th><th>description</th></tr>    
; <tr><td><center>0</center></td><td>F_SDC_IN</td><td>1 &rarr; S'il y a une carte dans la fente.</td></tr>
; <tr><td><center>1</center></td><td>F_SDC_OK</td><td>1 &rarr; Si la carte est initialis�e.</td></tr>
; <tr><td><center>2</center></td><td>F_SDC_V2</td><td>1  &rarr; S'il s'agit d'une carte version 2.</td></tr>
; <tr><td><center>3</center></td><td>F_SDC_HC</td><td>1 &rarr; S'il s'agit d'une carte haute capacit�e. Adressable par bloc de 512 octets.</td></tr>
; <tr><td><center>4</center></td><td>F_SDC_TO</td><td>1 &rarr; Si la derni�re commande a expir�e avant d'aboutir.</td></tr>
; <tr><td><center>5</center></td><td>F_SDC_WE</td><td>1 &rarr; S'il s'est produit une erreur d'�criture.</td></tr>
; <tr><td><center>6</center></td><td>F_SDC_RE</td><td>1 &rarr; S'il s'est produit une erreur de lecture.</td></tr>
; <tr><td><center>7</center></td><td>F_SDC_IE</td><td>1 &rarr; S'il s'est prdouit une erreur d'initialisation.</td></tr>
; <tr><td><center>8</center></td><td>F_BAD_CARD</td><td>1 &rarr; S'il n'y a pas de r�ponse de la carte.</td></tr>
; </table><br>
; :HTML    
; arguments:
;   aucun
; retourne:
;   u  �tat de la carte.    
DEFCODE "?SDC",4,,QSDC ; ( -- u )
    DPUSH
    mov sdc_status,T
    NEXT

; nom: ?SDCOK  ( -- n )    
;   Retourne la valeur du bit F_SDC_OK. La valeur 2 indique qu'il y a une carte
;   dans la fente et qu'elle est initialis�e.    
; arguments:
;   aucun
; retourne:
;   n Valeur du bit F_SDC_OK &rarr; {0,2}.    
DEFWORD "?SDCOK",6,,QSDCOK ; ( -- f )
    .word QSDC,LIT,1,LIT,F_SDC_OK,LSHIFT,AND,EXIT
    
; nom: SDCREAD  ( c-addr ud -- f )    
;   Lecture d'un secteur de la carte SD, bloc de 512 octets    
;  arguments:
;   addr Adresse du tampon RAM
;   ud  Num�ro du secteur sur la carte SD. 
;  retourne:
;   f  Indicateur bool�en �chec/succc�s    
DEFCODE "SDCREAD",7,,SDCREAD ; ( addr ud -- f )
    _enable_sdc
    btss sdc_status, #F_SDC_HC
    call sector_to_address
    mov T,W1 ; addresse Hi(address)
    DPOP
    mov T,W2 ; addresse Lo(address)
    DPOP
    mov T,W5 ; adresse tampon RAM
    clr T
    clr W3
    mov #READ_SINGLE_BLOCK,W0
    call sdc_cmd
    cp0 T
    DPOP
    bra nz, read_failed
2:  spi_read
    cp.b W0,#0xfe
    bra nz, 2b
    mov #BLOCK_SIZE,W4
3:  spi_read
    mov.b W0,[W5++]
    dec W4,W4
    bra nz, 3b
    com T,T
read_failed:
    call sdc_deselect
    NEXT
    
; nom: SDCWRITE   ( addr ud -- )   
;   �criture d'un secteur de 512 octets sur la carte SD.
; arguments:
;   addr Adresse du tampon RAM des donn�es � �crire.
;   ud	 Num�ro du secteur la carte SD o� effectuer l'�criture.
; retourne:
;   rien    
DEFCODE "SDCWRITE",8,,SDCWRITE ; ( addr ud -- )
    SET_EDS
    _enable_sdc
    btss sdc_status,#F_SDC_HC
    call sector_to_address
    mov T,W1  ; Hi(address)
    DPOP
    mov T,W2  ; Lo(address)
    DPOP
    mov T,W5  ; adresse RAM
    clr T
    clr W3
    mov #WRITE_SINGLE_BLOCK,W0
    call sdc_cmd
    cp0 T
    DPOP
    bra nz, write_failed
    mov.b #0xFE,W0
    spi_write
    mov #BLOCK_SIZE,W4
2:  mov.b [W5++],W0
    spi_write
    dec W4,W4
    bra nz, 2b
    mov.b #255,W0
    spi_write
    mov.b #255,W0
    spi_write
3:  ; attend la fin de l'�criture
    spi_read
    cp.b W0,#0xFF
    bra nz, 3b
    com T,T
write_failed:
    call sdc_deselect
    RESET_EDS
    NEXT

; nom: SDBLKCOUNT  ( -- u )    
;   Constante, nombre maximal de blocs utilis�s sur la carte SD
; arguments:
;   aucun
; retourne:
;   u   Nombre de blocs disponibles.    
DEFCONST "SDBLKCOUNT",10,,SDBLKCOUNT,65535

; nom: SDBOUND  ( n+ -- f)
;   V�rifie si le num�ro de bloc est dans les limites
; arguments:
;   n+  Num�ro du bloc � v�rifier. {1..65535}
; retourne:
;   f   Indicateur bool�en.
DEFWORD "SDBOUND",7,,SDBOUND
    .word ZEROEQ,NOT,EXIT
    
; nom: SDBLK>ADR  ( u -- ud )
;   Convertie un num�ro de bloc de la carte SD en adresse absolue.
; arguments:
;   u    Num�ro du bloc {1..65535}
; retourne:
;   ud   Adresse absolue de 32 bits sur la carte SD.
DEFWORD "SDBLK>ADR",9,,SDBLKTOADR
    .word ONEMINUS,LIT,BLOCK_SIZE,QSDC,LIT,F_SDC_HC,AND,ZBRANCH,9f-$
    .word LIT,SECTOR_SIZE,SLASH
9:  .word MSTAR,EXIT
    
    
; descripteur carte Secure Digital    
DEFTABLE "SDCARD",6,,SDCARD
    .word _SDCARD 
    .word SDCREAD
    .word SDCWRITE
    .word SDBLKTOADR
    .word SDBOUND
