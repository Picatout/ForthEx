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
;Description:  interface avec carte SC en utilisant l'interface SPI
;Date: 2017-03-20
    
.equ BLOCK_SIZE, 512 ; nombre d'octets par secteur carte SD.    
    
.section .hardware.bss  bss
.global sdc_status
sdc_status: .space 2 ; indicateurs booléens carte SD
sdc_size: .space 4 ; nombre de secteurs de 512 octets
sdc_R: .space 4; réponse de la carte 
sdc_first: .space 4  ; adresse du premier bloc sur la carte SD.
 
 
INTR
;la broche SDC_DETECT
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
    
; calcule l'adresse à partir du no de bloc
; argument 
;   ud1 no. de secteur
; sortie:
;   ud2   adresse absolue    
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
; entrée: 
;    W0  index commande
;    W1  argb1b2  b15:8->byte1,b7:0->byte2
;    W2  argb3b4  b15:7->byte3,b7:0->byte4
;    W3  nombre d'octets supplémentaire dans la réponse
;    W4  pointeur buffer réponse    
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
    mov #8,W1
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
2:
    xor.b #0xFF,W0
    DPUSH
    ze W0,T
3:  cp0 W3
    bra nz, 4f
    pop W5
    return
4:  spi_read
    mov.b W0,[W4++]
    dec W3,W3
    bra 3b
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;    
;initialisation carte SD 
;ref: http://elm-chan.org/docs/mmc/pic/sdinit.png    
;;;;;;;;;;;;;;;;;;;;;;;;;    
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
    btsc sdc_status, #F_SDC_V2
    bra cmd16
    mov #READ_OCR,W0
    clr W1
    clr W2
    mov #4,W3
    call sdc_cmd
    cp0 T
    bra nz, 8f
    mov [--W4],W0
    cp W0,#0x40
    bra z, cmd16
    bset sdc_status,#F_SDC_HC
cmd16:
    mov #SET_BLOCKLEN,W0
    clr W1
    mov #0x200,W2
    clr W3
    call sdc_cmd
    cp0 T
    DPOP
    bra z, succeed
    bra failed
timeout:
    bset sdc_status,#F_SDC_TO
failed:
    DPUSH
    clr T
    bra 9f
succeed:
    bset sdc_status,#F_SDC_OK
    DPUSH
    mov #-1,T
8:  call sdc_deselect
9:  mov #SCLK_FAST,W1
    call set_spi_clock
    NEXT
 
; retourne sdc_status    
DEFCODE "?SDC",4,,QSDC ; ( -- u )
    DPUSH
    mov sdc_status,T
    NEXT

; la carte SD est-elle prête?    
DEFWORD "?SDCOK",6,,QSDCOK ; ( -- f )
    .word QSDC,LIT,1,LIT,F_SDC_OK,LSHIFT,AND,EXIT
    
    
; lecture d'un secteur de la carte
; bloc de 512 octets    
;  arguments:
;   addr   adresse du tampon RAM
;   ud   numéro du secteur à lire 
;  retourne:
;   f  indicateur booléen échec/succcès    
DEFCODE "SDCREAD",7,,SDCREAD ; ( addr ud -- f )
    _enable_sdc
    btss sdc_status, #F_BLK_ADDR
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
    
    
; écriture d'un secteur de la carte
; arguments:
;   addr   adresse RAM
;   ud  numéro du secteur carte SD    
DEFCODE "SDCWRITE",8,,SDCWRITE ; ( addr ud -- )
    SET_EDS
    _enable_sdc
    btss sdc_status,#F_BLK_ADDR
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
3:  ; attend la fin de l'écriture
    spi_read
    cp.b W0,#0xFF
    bra nz, 3b
    com T,T
write_failed:
    call sdc_deselect
    RESET_EDS
    NEXT

; ajuste le compteur et le pointeur pour
; le secteur suivant
; arguments:
;    u1  adresse RAM
;    u2  nombre d'octets à lire ou écrire
; sortie:
;    u3  adresse RAM incrémentée de BLOCK_SIZE
;    u4  nombre d'octets décrémentés de BLOCK_SIZE
;        MAX(0,u4') 
;    ajuste le no. de secteur qui est sur R: IP ud    
DEFWORD "NSECTOR",7,,NSECTOR ; ( u1 u2 -- u3 u4 )
    .word LIT,BLOCK_SIZE,MINUS,LIT,0,MAX ; u1 u4
    .word SWAP,LIT,BLOCK_SIZE,PLUS,SWAP  ; u3 u4
    .word RFROM,TWORFROM,LIT,1,MPLUS ; u3 u4 IP ud1+1
    .word TWOTOR,TOR ; u3 u4 R: ud1+1 IP
    .word EXIT
    
; sauvegarde image système sur la carte SD
; arugments:
;   u1  adresse ram début
;   u2  nombre d'octets à sauvegarder
;   ud1 no. de secteur début sauvegarde    
DEFWORD "IMG>SDC",7,,IMGTOSDC ; ( u1 u2 ud1 -- )
    .word TWOTOR,QSDCOK,TBRANCH,5f-$ 
    .word SDCINIT,ZBRANCH,9f-$
5:  .word OVER,TWORFETCH,SDCWRITE 
    .word NSECTOR,DUP,ZBRANCH,8f-$
    .word BRANCH,5b-$
8:  .word TWODROP,TWORFROM,TWODROP,EXIT
9:  .word DOTSTR
    .byte  18
    .ascii "SDcard write error"
    .align 2
    .word CR,ABORT
    
    
; récupération image système à partir de la carte SD.
; arguments:
;   u1 adresse RAM
;   u2 nombre d'octets à lire    
;   ud1 no de secteur début image sur carte SD.    
DEFWORD "SDC>IMG",7,,SDCTOIMG ; ( u1 u2 ud1 -- )
    .word TWOTOR,QSDCOK,TBRANCH,4f-$
    .word SDCINIT,ZBRANCH,9f-$
4:  .word OVER,TWORFETCH,SDCREAD,ZBRANCH,9f-$
    .word NSECTOR,DUP,ZBRANCH,8f-$
    .word BRANCH,4b-$
8:  .word TWODROP,TWORFROM,TWODROP,EXIT
9:  .word DOTSTR
    .byte  17
    .ascii "SDcard read error"
    .align 2
    .word CR,ABORT
    

; nom: SDFIRST ; ( -- u )
;    variable contenant l'adresse du premeir bloc utilisé sur la carte SD
; arguments:
;
; retourne:
;    u    pointeur de la variable
DEFCODE "SDFIRST",7,,SDFIRST
    DPUSH
    mov #sdc_first,T
    NEXT
    
; constantes nombre maximal de blocs utilisés sur la carte SD
DEFCONST "SDBLKCOUNT",10,,SDBLKCOUNT,65535

; nom: SDBOUND  ( n+ -- f)
;   Vérifie si le numéro de bloc est dans les limites
; arguments:
;   n+   numéro du bloc à vérifier. {1..65535}
; retourne:
;   f   indicateur booléen.
DEFWORD "SDBOUND",7,,SDBOUND
    .word ZEROEQ,NOT,EXIT
    
; nom: SDBLK>ADR  ( u -- ud )
;   Convertie un numéro de bloc de la carte SD en adresse absolue.
; arguments:
;   u    numéro du bloc {1..65535}
; retourne:
;   ud   adresse absolue de 32 bits sur la carte SD.
DEFWORD "SDBLK>ADR",9,,SDBLKTOADR
    .word ONEMINUS,LIT,BLOCK_SIZE,MSTAR,SDFIRST,TWOFETCH,DPLUS,EXIT
    
; descripteur carte Secure Digital    
DEFTABLE "SDCARD",6,,SDCARD
    .word _SDCARD 
    .word SDCREAD
    .word SDCWRITE
    .word SDBLKTOADR
    .word SDBOUND
