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
    
    
    
.section .hardware.bss  bss
.global sdc_status
sdc_status: .space 2 ; indicateurs booléens carte SD
sdc_size: .space 4 ; nombre de secteurs de 512 octets
sdc_R: .space 4; réponse de la carte 

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
DEFCODE "SDCINIT",7,,SDCINIT
    btss sdc_status,#F_SDC_IN
    bra failed
    clr sdc_status
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
    bra nz, 9f
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
9:  call sdc_deselect
    mov #SCLK_FAST,W1
    call set_spi_clock
    NEXT
 
; retourne sdc_status    
DEFCODE "?SDC",4,,QSDC ; ( -- u )
    DPUSH
    mov sdc_status,T
    NEXT

; lecture d'un secteur de la carte
; bloc de 512 octets    
;  arguments:
;   addr   adresse du tampon RAM
;   ud   numéro du secteur à lire 
;  retourne:
;   f  indicateur booléen échec/succcès    
DEFCODE "SDCREAD",7,,SDCREAD ; ( addr ud -- f )
    _enable_sdc
    mov T,W1 ; no de bloc hiword
    DPOP
    mov T,W0 ; no de block loword
    DPOP
    mov T, W5 ; adresse RAM
    clr T
    mov #512,W4 ; W4 compteur pour lecture 
    btss sdc_status, #F_BLK_ADDR 
    mul.uu W4,W0,W0 ; W0 adresse carte SD
    mov W0,W2 ; addresse loword, W1 addresse hiword
    clr W3
    mov #READ_SINGLE_BLOCK,W0
    call sdc_cmd
    cp0 T
    DPOP
    bra nz, read_failed
1:  spi_read
    cp.b W0,#0xfe
    bra nz, 1b
2:  spi_read
    mov.b W0,[W5++]
    dec W4,W4
    bra nz, 2b
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
    mov T,W1  ; no secteur hiword
    DPOP
    mov T,W0  ; no secteur loword
    DPOP
    mov T,W5  ; adresse RAM
    clr T
    mov #512,W4
    btss sdc_status,#F_BLK_ADDR
    mul.uu W4,W0,W0
    mov W0,W2
    clr W3
    mov #WRITE_SINGLE_BLOCK,W0
    call sdc_cmd
    cp0 T
    DPOP
    bra nz, write_failed
    mov.b #0xFE,W0
    spi_write
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


