;****************************************************************************
; Copyright 2015,2016,2017 Jacques Deschênes
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

; NOM: sdcard.s
; Date: 2017-03-20
; DESCRIPTION:  
; Interface de bas niveau pour l'accès à la carte SD.
; Permet l'initialisation de la carte ainsi que la lecture et l'écriture d'un bloc de
; donnée sur la carte. Cette interface n'est compatible qu'avec les cartes SD V1 et V2.
; REF: http://elm-chan.org/docs/mmc/mmc_e.html
; REF: http://elm-chan.org/docs/mmc/pic/sdinit.png    
; REF: https://www.sdcard.org/downloads/pls/
; HTML:
; <br>
; :HTML
 
; indicateurs booléens carte SD
.equ F_SDC_IN, 0 ; carte dans la fente
.equ F_SDC_OK,1 ; carte insérée et initialisée
.equ F_SDC_V2,2 ; carte version 2
.equ F_SDC_HC,3 ; carte haute capacité, adressée par bloc de 512 octets.
.equ F_SDC_TO,4 ; commande time out
.equ F_SDC_WE,5 ; erreur écriture
.equ F_SDC_RE,6 ; erreur lecture
.equ F_SDC_IE,7 ; erreur initialisation  
.equ F_BAD_CARD,8 ; la carte ne répond pas
 
;commandes carte SD
.equ GO_IDLE_STATE, 0            ; CMD0 - réinitialise carte
.equ SEND_OP_COND,        1      ; CMD1 - requête condition d'opération
.equ SEND_IF_COND,        8      ; CMD8 - requête condition d'interface
.equ SEND_CSD,            9      ; CMD9 - requête pour lecture du registre CSD
.equ SEND_CID,            10     ; CMD10 - requête pour lecture du registre CID    
.equ SET_BLOCKLEN,        16     ; CMD16 - fixe longueur bloc
.equ READ_SINGLE_BLOCK,   17     ; CMD17 - lecture d'un seul bloc
.equ WRITE_SINGLE_BLOCK,    24   ; CMD24 - écriture d'un bloc
.equ APP_CMD,                55  ; CMD55 - commande escape
.equ READ_OCR,            58     ; CMD58 - requête registre ocr
.equ CRC_ON_OFF,            59   ; CMD59 - activation/désactivation CRC
.equ SD_STATUS,            13    ; ACMD13 - requête status
.equ SEND_OP_COND,        41  ; ACMD41 - requête condition d'opération
; certaines commandes requière une valeur pour CRC
.equ CMD0_CRC, 0x95 
.equ CMD8_CRC, 0x87
.equ CMDX_CRC, 0xFF  ; autre commandes
    
.equ SECTOR_SIZE, 512 ; nombre d'octets par secteur carte SD.    
    
.section .sdc.bss  bss
.global sdc_status
sdc_status: .space 2 ; indicateurs booléens carte SD
blocks_count: .space 4 ; nombre de bloc de 1024 octets
seg_count: .space 2 ;  nombre de segments de 65535 blocs
sdc_segment: .space 2 ; segment sélectionné. 
sdc_R: .space 16; tampon pour la réponse de la carte 
 
 
INTR
; La broche SDC_DETECT
; a changée d'état
; carte insérée ou retirée. 
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
    bset SDC_LAT,#SDC_SEL
    mov.b #0xff,W0
    spi_write
    _disable_spi
    return
  
; attend que la carte soit prête
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
    
; calcule l'adresse à partir du no de secteur.
; Un secteur est de 512 octets.    
; arguments: 
;   ud1 Numéro de secteur
; retourne:
;   ud2   Adresse sur la carte SD.    
sector_to_address: ;   ( ud1 -- ud2 )    
    mov #SECTOR_SIZE,W2
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
;    W3  nombre d'octets supplémentaire dans la réponse
;    W4  pointeur tampon réponse  
; retourne:
;    T  R1
;    réponse de la carte dans sdc_R    
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
; réception de R1    
    mov #8,W1 ; délais réponse
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
2: ; octet R1 reçu, transfert dans T.
    xor.b #0xFF,W0
    DPUSH
    ze W0,T
    ; réception autres octets de la réponse.
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
9:  
    return
   
; lecture capacité de la carte.
set_size:    
    mov #SEND_CSD,W0
    call read_card_register
    cp0 T
    bra z, 9f
    btss sdc_status,#F_SDC_HC
    bra version1
    mov #sdc_R+8,W2
    mov.b [W2++],W1
    ze W1,W1
    swap W1
    mov.b [W2],W0
    ze W0,W0
    add W0,W1,W0
    inc W0,W0
    bra 8f
version1:
;C_SIZE
;This parameter is used to compute the user data card capacity (not include the security protected
;area). The memory capacity of the card is computed from the entries C_SIZE, C_SIZE_MULT and
;READ_BL_LEN as follows:
;memory capacity = BLOCKNR * BLOCK_LEN
;Where
; BLOCKNR = (C_SIZE+1) * MULT
; MULT = 2^(C_SIZE_MULT+2) , (C_SIZE_MULT < 8)
; BLOCK_LEN = 2^READ_BL_LEN , (READ_BL_LEN < 12)
;To indicate 2 GByte card, BLOCK_LEN shall be 1024 bytes.
;Therefore, the maximal capacity that can be coded is 4096*512*1024 = 2 G bytes.
;Example: A 32 Mbyte card with BLOCK_LEN = 512 can be coded by C_SIZE_MULT = 3 and C_SIZE =
;2000.    
    ; extraction READ_BL_LEN
    mov #sdc_R+5,W2
    mov.b [W2++],W0
    and #0xf,W0 ; READ_BL_LEN
    dec W0,W0
    mov  #1,W4
    repeat W0
    sl W4,W4   ; W4=BLOCK_LEN=2^READ_BL_LEN   
    ; extraction C_SIZE
    mov.b [W2++],W0
    and #0x3,W0
    swap W0
    mov.b [W2++],W1
    ze W1,W1
    ior W1,W0,W0
    mov.b [W2++],W1
    swap W1
    sl W1,W1
    rlc W0,W0
    sl W1,W1
    rlc W0,W3 ; C_SIZE
    inc W3,W3 ; C_SIZE+1
    ; extraction C_SIZE_MULT
    mov.b [W2++],W0
    and #3,W0
    mov.b [W2],W1
    swap W1
    sl W1,W1
    rlc W0,W0
    inc W0,W0
    mov #1,W1
    repeat W0 ; 
    sl W1,W1 ; W1=MULT=2^(C_SIZE_MULT+2)
    mul.uu W1,W3,W0 ; BLOCKNR=(C_SIZE+1)*MULT
    mov W1,W2
    ; BLOCKBR * BLOCK_LEN
    mul.uu W4,W0,W0
    mul.uu W4,W2,W2
    add W2,W1,W1 ; W1:W0=capacity
    ; division par 1Ko pour obtenir le nombre de blocs.
    mov #10,W2
2:  lsr W1,W1
    rrc W0,W0
    dec W2,W2
    bra nz, 2b
    bra 4f
8:  ; carte V2
    ; nombre de blocs de 1Ko
    mov #512,W1
    mul.uu W0,W1,W0
4:  mov W0,blocks_count
    mov W1,blocks_count+2
    setm W3
    repeat #17
    div.ud W0,W3
    mov W0,seg_count
    cp0 W0
    bra nz, 9f
    inc seg_count
9:  return

; READ-CSD ( -- f )
;    Lecture du registre CSD de la carte SD. Les informations se enregistrées
;    dans SDC-R. Pour en examiner le contenu faire: 
;    READ-CSD DROP SDC-R 16 DUMP    
; arguments:
;   aucun    
; retourne:
;    f   vrai si succès    
HEADLESS READCSD,CODE    
;DEFCODE "READ-CSD",8,,READCSD    
    _enable_sdc
    mov #SEND_CSD,W0
    call read_card_register
    call sdc_deselect
    NEXT
  
;  READ-CID ( -- f )       
;    Lecture du registre CID de la carte SD. Les informations se enregistrées
;    dans SDC-R. Pour en examiner le contenu faire: 
;    READ-CID DROP SDC-R 16 DUMP    
; retourne:
;    f   vrai si succès    
HEADLESS READCID,CODE    
;DEFCODE "READ-CID",8,,READCID
    _enable_sdc
    mov #SEND_CID,W0
    call read_card_register
    call sdc_deselect
    NEXT
    
; nom: CARD-INFO  ( -- )
;   Affiche les informations sur la carte SD.
;   La carte doit d'abord avoir été initialisée avec SDC-INIT.
; HTML:
; <br><table border="single">
; <tr><th>nom</th><th>description</th></tr>  
; <tr><td>VER</td><td> Card version.</td></tr>  
; <tr><td>MID</td><td> Manufacturer ID.</td></tr>
; <tr><td>OID</td><td> OEM/Application ID.</td></tr>
; <tr><td>PNM</td><td> Product name.</td></tr>
; <tr><td>PRV</td><td> Product revision.</td></tr>
; <tr><td>PSN</td><td> Product serial number.</td></tr>
; <tr><td>MTD</td><td> Manufacturing date.</td></tr>
; <tr><td>BLK</td><td> Capacitée en nombre de blocs de 1024 octets.</td></tr>
; <tr><td>SEG</td><td> Nombre de segments, 1 segment correspond à 65535 blocs.</td></tr>    
; </table><br> 
; :HTML  
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "CARD-INFO",9,,CARDINFO
    .word QSDCOK,ZBRANCH,9f-$
    .word READCID, ZBRANCH,9f-$
    .word CR,DOTSTR
    .byte 5
    .ascii "VER: "
    .align 2
    .word LIT,1,QSDC,LIT,F_SDC_V2,BITMASK,AND,ZBRANCH,2f-$,TWOSTAR
2:  .word UDOT,CR
    .word SDCR,DOTSTR
    .byte 4
    .ascii "MID:"
    .align 2
    .word DUP,CFETCH,UDOT,CR
    .word DOTSTR
    .byte 5
    .ascii "OID: "
    .align 2
    .word ONEPLUS,DUP,LIT,2,TYPE,CR
    .word DOTSTR
    .byte 5
    .ascii "PNM: "
    .align 2
    .word TWOPLUS,DUP,LIT,5,TYPE,CR
    .word DOTSTR
    .byte 4
    .ascii "PRV:"
    .align 2
    .word LIT,5,PLUS,DUP,CFETCH
    .word DUP,LIT,4,RSHIFT,DOT,LIT,'.',EMIT
    .word LIT,15,AND,DOT,CR
    .word DOTSTR
    .byte 4
    .ascii "PSN:"
    .align 2
    .word ONEPLUS,DUP,BIDFETCH,UDDOT,CR,LIT,4,PLUS
    .word DOTSTR
    .byte 4
    .ascii "MTD:"
    .align 2
    .word DUP,CFETCH,LIT,4,LSHIFT,TOR,ONEPLUS,CFETCH,DUP,LIT,4,RSHIFT
    .word RFROM,PLUS,LIT,2000,PLUS,UDOT,LIT,'/',EMIT
    .word LIT,15,AND,UDOT,CR
    .word DOTSTR
    .byte 4
    .ascii "BLK:"
    .align 2
    .word LIT,blocks_count,TWOFETCH,UDDOT
    .word CR,DOTSTR
    .byte 4
    .ascii "SEG:"
    .align 2
    .word LIT,seg_count,FETCH,UDOT
    .word CR
9:  .word EXIT
  
  
; SDC-R ( -- a-addr )
;   Adresse de la mémoire tampon de 16 octets qui reçois les réponses de la carte SD.
; arguments:
;   aucun
; retourne:
;   a-addr Adresse du tampon réponse carte SD.
HEADLESS SDCR,CODE
    DPUSH
    mov #sdc_R,T
    NEXT
;DEFCONST "SDC-R",5,,SDCR,sdc_R    
    
; nom: SDC-INIT ( -- f )
;   Initialisation carte SD 
;   REF: http://elm-chan.org/docs/mmc/pic/sdinit.png    
; arguments:
;   aucun
; retourne:
;    f   Indicateur Booléen, vrai si l'initialisation est réussie.   
DEFCODE "SDC-INIT",8,,SDCINIT ; ( -- f )
    clr sdc_status
    clr sdc_segment
    clr seg_count
    clr blocks_count
    clr blocks_count+2
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
    mov W0,tone_len ; délais 1 seconde
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

; nom: SEGMENT ( u -- )
;   Détermine quel segment de la carte est actif.
;   Le système définit dans block.s ne permet que d'accéder 65535 blocs sur un périphérique
;   ce qui représente 1024*65535 ou 2^10 * (2^16-1)= 67 107 840 octets.
;   Pour les cartes de plus de 64Mo il faut diviser l'espace de données de la carte
;   en segments de 65535 blocs.
; arguments:
;   u Numéro du segment.
; retourne:
;   rien    
DEFCODE "SEGMENT",7,,SEGMENT 
    mov seg_count,W0
    dec W0,W0
    cp T,W0
    bra gtu, 9f
    mov T,sdc_segment
9:  DPOP
    NEXT
    
; nom: SEGMENT? ( -- u )
;   Retourne le numéro du segment actif.
; arguments:
;   aucun
; retourne:
;   u	Numéro du segment actif {0..SDC-SEGMENTS-1}    
DEFCODE "SEGMENT?",8,,SEGMENTQ
    DPUSH
    mov sdc_segment,T
    NEXT
    
; nom: ?SDC  ( -- u )    
;   Retourne un entier non signé contenant les indicateurs booléen suivants
; HTML:
; <br><table border="single">    
; <tr><th><center>bit</center></th><th>nom</th><th>description</th></tr>    
; <tr><td><center>0</center></td><td>F_SDC_IN</td><td>1 &rarr; S'il y a une carte dans la fente.</td></tr>
; <tr><td><center>1</center></td><td>F_SDC_OK</td><td>1 &rarr; Si la carte est initialisée.</td></tr>
; <tr><td><center>2</center></td><td>F_SDC_V2</td><td>1  &rarr; S'il s'agit d'une carte version 2.</td></tr>
; <tr><td><center>3</center></td><td>F_SDC_HC</td><td>1 &rarr; S'il s'agit d'une carte haute capacitée. Adressable par bloc de 512 octets.</td></tr>
; <tr><td><center>4</center></td><td>F_SDC_TO</td><td>1 &rarr; Si la dernière commande a expirée avant d'aboutir.</td></tr>
; <tr><td><center>5</center></td><td>F_SDC_WE</td><td>1 &rarr; S'il s'est produit une erreur d'écriture.</td></tr>
; <tr><td><center>6</center></td><td>F_SDC_RE</td><td>1 &rarr; S'il s'est produit une erreur de lecture.</td></tr>
; <tr><td><center>7</center></td><td>F_SDC_IE</td><td>1 &rarr; S'il s'est prdouit une erreur d'initialisation.</td></tr>
; <tr><td><center>8</center></td><td>F_BAD_CARD</td><td>1 &rarr; S'il n'y a pas de réponse de la carte.</td></tr>
; </table><br>
; :HTML    
; arguments:
;   aucun
; retourne:
;   u  État de la carte.    
DEFCODE "?SDC",4,,QSDC ; ( -- u )
    DPUSH
    mov sdc_status,T
    NEXT

; nom: ?SDCOK  ( -- n )    
;   Retourne la valeur du bit F_SDC_OK. La valeur 2 indique qu'il y a une carte
;   dans la fente et qu'elle est initialisée.    
; arguments:
;   aucun
; retourne:
;   n Valeur du bit F_SDC_OK &rarr; {0,2}.    
DEFWORD "?SDCOK",6,,QSDCOK ; ( -- f )
    .word QSDC,LIT,F_SDC_OK,BITMASK,AND,EXIT
    
; nom: SDCREAD  ( c-addr ud -- f )    
;   Lecture d'un secteur de la carte SD.
;   Un secteur compte 512 octets.    
;  arguments:
;   addr Adresse du tampon RAM
;   ud  Numéro du secteur sur la carte SD. 
;  retourne:
;   f  Indicateur booléen échec/succcès    
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
    mov #SECTOR_SIZE,W4
3:  spi_read
    mov.b W0,[W5++]
    dec W4,W4
    bra nz, 3b
    com T,T
read_failed:
    call sdc_deselect
    NEXT
    
; nom: SDCWRITE   ( addr ud -- f )   
;   Écriture d'un secteur de 512 octets sur la carte SD.
; arguments:
;   addr Adresse du tampon RAM des données à écrire.
;   ud	 Numéro du secteur la carte SD où effectuer l'écriture.
; retourne:
;   f Indicateur booléen succès/échec    
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
    mov #SECTOR_SIZE,W4
2:  mov.b [W5++],W0
    spi_write
    dec W4,W4
    bra nz, 2b
    mov.b #255,W0
    spi_write
    mov.b #255,W0
    spi_write
3:  ; attend la fin de l'écriture
    spi_read
    cp.b W0,#0xFF
    bra nz, 3b
    com T,T
write_failed:
    call sdc_deselect
    RESET_EDS
    NEXT

; nom: SDC-BLOCKS  ( -- ud )    
;   Nombre de blocs de 1024 octets sur la carte SD.
; arguments:
;   aucun
; retourne:
;   ud   Entier double non signé, nombre de blocs.    
DEFCODE "SDC-BLOCKS",10,,SDCBLOCKS
    DPUSH
    mov blocks_count,T
    DPUSH
    mov blocks_count+2,T
    NEXT

; nom: SDC-SEGMENTS  ( -- u )    
;   Nombre de segments de 65535 blocs sur la carte SD.
; arguments:
;   aucun
; retourne:
;   u   Entier simple, nombre de segments.    
DEFCODE "SDC-SEGMENTS",12,,SDCSEGMENTS
    DPUSH
    mov seg_count,T
    NEXT

    
; SDC-VALID?  ( n+ -- f)
;   Vérifie si le numéro de bloc est dans les limites
; arguments:
;   n+  Numéro du bloc à vérifier. {1..65535}
; retourne:
;   f   Indicateur booléen.
HEADLESS SDCVALIDQ,HWORD    
;DEFWORD "SDC-VALID?",7,,SDCVALIDQ
    .word ZEROEQ,NOT,EXIT
    
; SDC-BLK>ADR  ( u -- ud )
;   Convertie un numéro de bloc de la carte SD en adresse absolue.
;   ud=(u-1)*2
;   Il suffit de multiplier par 2.    
; arguments:
;   u    Numéro du bloc {1..65535}
; retourne:
;   ud   Adresse absolue de 32 bits sur la carte SD.
HEADLESS SDCBLKTOADR,HWORD    
;DEFWORD "SDC-BLK>ADR",11,,SDCBLKTOADR
    .word ONEMINUS,LIT,2,MSTAR
    .word TRUE,SEGMENTQ,UMSTAR,DPLUS  
    .word EXIT

; SDC-BLK-READ  ( u1 ud1 -- )
;   Lecture d'un bloc sur la carte SD  
; arguments:
;   u1 Adresse tampon RAM destination des données.
;   ud1 Numéro secteur carte SD.
; retourne:
;   rien  
HEADLESS SDCBLKREAD,HWORD ; ( u1 ud1 --  )
    .word LIT,2,LIT,0,DODO
1:  .word TWOTOR,DUP,TWORFETCH,SDCREAD,DROP
    .word LIT,SECTOR_SIZE,PLUS,TWORFROM,LIT,1,MPLUS
    .word DOLOOP,1b-$,TWODROP,DROP
    .word EXIT

; SDC-BLK-WRITE ( u1 ud1 -- )    
;   Écriture d'un bloc sur la carte SD    
; arguments:
;   u1  Adresse tampon RAM source des données
;   ud1 Numéro secteur carte SD.
; retourne:
;   rien  
HEADLESS SDCBLKWRITE,HWORD ; ( u1 ud1 -- )
    .word LIT,2,LIT,0,DODO
1:  .word TWOTOR,DUP,TWORFETCH,SDCWRITE,DROP
    .word LIT,SECTOR_SIZE,PLUS,TWORFROM,LIT,1,MPLUS
    .word DOLOOP,1b-$,TWODROP,DROP
    .word EXIT
    
; nom: SDCARD  ( -- a-addr )  
;   Descripteur de périphérique pour la carte Secure Digital.
; arguments:
;   aucun
; retourne:
;   a-addr Adresse du descripteur de périphérique.  
DEFTABLE "SDCARD",6,,SDCARD
    .word _SDCARD 
    .word SDCBLKREAD
    .word SDCBLKWRITE
    .word SDCBLKTOADR
    .word SDCVALIDQ

