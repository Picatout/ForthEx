;****************************************************************************
; Copyright 2015, Jacques Deschênes
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

/*
  NOM: hardware.inc
  DESCRIPTION: contient toutes les constantes et alias de SFR. Tout ce qui concerne
               l'affectation des périphériques est défini dans ce fichier.
     
  MCU: PIC24FJ64GA002
  FLASH: 64Ko (22Kloc)
  RAM: 8Ko,  
    MAP: 0x0-0x7FF SFR
         0x800-0x27FF RAM
         0x2800-67FF  PSV
     
  Utilisation des périphériques:
     
  - TIMER1, interruption à intervalle de 1msec. 
     * incrémente <systicks>
     * décrémente <tone_len>
     * filtre données clavier de ps2_queue vers kbd_queue
    
  - TIMER2,  interruption synchronistaion vidéeo intervalle 63,5µsec
    * OC1,   génération signal synchronisation NTSC
    * OC2,   interruption pour envoie bits vidéo, intervalle 63,5µsec
    * SPI2,  sérialisation des bits vidéo.
     
  - TIMER3, minuterie pour générateur audio    
    * OC3,  PWM générateur tonalités audio, pas d'interruption
     
  - INT1,  interruption externe sur transition descendante décenchée par
           signal clock du clavier PS/2. (priorité la plus élevée).
     
  - SPI1,  interface avec les mémoires externes RAM 23LC104 et EEPROM 25LC1024
     
*/
    
.ifndef HARD_INC
.equ HARD_INC, 1
    
.include "p24EP512GP202.inc"

.NOLIST
.equ FCY, 70000000   ;70Mhz
.equ FCY_MHZ, 70
    
; PLL settings
.equ PLLPRE, 0  ; 8Mhz/2
.equ PLLPOST, 0 ; 280Mhz/2, Fpllo=140Mhz
.equ PLLDIV, 68 ; 4Mhz*70
    
.equ RAM_SIZE, 0xC000 ; 48KO
.equ RAM_BASE, 0x1000 ; 4096
.equ EDS_BASE, 0x8000 ; 32768
    
; sortie vidéo
.equ NTSC, 1
.equ PAL, 2
;sélection du standard vidéo NTSC ou PAL    
.equ VIDEO_STD, NTSC
    
.equ VIDEO_PORT, PORTB
.equ VIDEO_LAT, LATB    
.equ VIDEO_TRIS, TRISB
; vidéo sur RB3 (pin 7) périphérique SPI2/SDO
.equ VIDEO_OUT,  RB3   ; sortie vidéo RP35
; OC2 utilisé comme vidéo output trigger    
.equ VIDEO_OCR, OC2R
.equ VIDEO_OCRS, OC2RS
.equ VIDEO_OCCON1, OC2CON1
.equ VIDEO_OCCON2, OC2CON2    
.equ VIDEO_RPOR, RPOR0  ; registre PPS pour sortie pin 7
.equ VIDEO_RPORbit, RP35R0  ; RP35
.equ VIDEO_FN,  8    ; fonction SDO2
.equ VIDEO_IFS, IFS0 ; registre IFS pour OC2IF
.equ VIDEO_IEC, IEC0 ; registre IEC pour SPI2
.equ VIDEO_IF,  OC2IF ; trigger vidéo
.equ VIDEO_IE, OC2IE  ; activation interruption OC2
.equ VIDEO_IPC, IPC1  ; priorité interruption OC2
.equ VIDEO_IPbit, OC2IP0 ; priorité OC2
.equ VIDEO_SPICON1, SPI2CON1
.equ VIDEO_SPICON2, SPI2CON2
.equ VIDEO_SPISTAT, SPI2STAT
.equ VIDEO_SPIBUF, SPI2BUF
; synchronistation vidéo
; vidéo SYNC RB4 (pin 11) périphérique OC1
.equ SYNC_PORT, PORTB
.equ SYNC_TRIS, TRISB
.equ SYNC_LAT,  LATB    
.equ SYNC_OUT,   RB4  ;sortie SYNC
.equ SYNC_TMR, TMR2
.equ SYNC_TMRCON, T2CON
.equ SYNC_PER, PR2
.equ SYNC_OCRS,  OC1RS
.equ SYNC_OCR, OC1R
.equ SYNC_OCCON1, OC1CON1
.equ SYNC_OCCON2, OC1CON2    
.equ SYNC_RPOR, RPOR1  ; RP36
.equ SYNC_RPORbit, RP36R0 ; RP36
.equ SYNC_FN,   16 ; fonction OC1
.equ SYNC_IFS, IFS0 ; registre pour T2IF
.equ SYNC_IEC, IEC0 ; registre pour T2EI
.equ SYNC_IF,  T2IF 
.equ SYNC_IE,  T2IE
.equ SYNC_IPC, IPC1 ; priorité int. T2
.equ SYNC_IPbit, T2IP0

; clavier
.equ RPI47, 0x2F   ; INT1 
.equ KBD_CLK, RB15   ; pin 26, RPI47
.equ KBD_DAT, RB14   ; pin 25, RPI46
.equ KBD_PORT, PORTB
.equ KBD_LAT, LATB
.equ KBD_TRIS, TRISB
.equ KBD_ODC, ODCB    
.equ KBD_RPINR, RPINR0  ; INT1R0
.equ KBD_PPSbit, INT1R0
.equ KBD_IFS, IFS1
.equ KBD_IF, INT1IF
.equ KBD_IEC, IEC1
.equ KBD_IE, INT1IE
.equ KBD_IPC, IPC5
.equ KBD_IPCbit, INT1IP0
.equ KBD_INTEP, INT1EP
.equ KBD_INTCON, INTCON2

; interface SPI1 RAM et EEPROM
.equ SRAM_SEL, RB10   ; pin 21, RP42 
.equ EEPROM_SEL, RB6  ; pin 18, RP41
.equ STR_CLK,   RB7   ; pin 17, RP40
.equ STR_MOSI,  RB8   ; pin 15, RP38
.equ STR_MISO,  RB9   ; pin 16, RP39
.equ STR_PORT, PORTB
.equ STR_TRIS, TRISB
.equ STR_LAT, LATB
.equ STR_SPICON1, SPI1CON1    
.equ STR_SPICON2, SPI1CON2
.equ STR_SPISTAT, SPI1STAT
.equ STR_SPIBUF,  SPI1BUF
.equ STR_SPIIFS,  IFS0
.equ STR_SPIIF,   SPI1IF    

; communication port série
.equ  RPI44, 44    
.equ  SER_PORT, PORTB
.equ  SER_LAT,  LATB
.equ  SER_TRIS, TRISB
.equ  SER_TX_OUT, RB11  ; pin 22, RP43
.equ  SER_RX_INP, 44    ; pin 23, RPI44  
.equ  SER_MODE, U1MODE
.equ  SER_STA,  U1STA
.equ  SER_BRG,  U1BRG
.equ  SER_TXREG, U1TXREGL
.equ  SER_RXREG, U1RXREGL
.equ  SER_RX_RPINR, RPINR18 ; select RX PPS
.equ  SER_RX_PPSbit, U1RXR0     
.equ  SER_TX_FN, 3
.equ  SER_TX_RPOR,  RPOR4 
.equ  SER_TX_PPSbit, RP43R0    
.equ  SER_TX_IFS, IFS0
.equ  SER_TX_IF,  U1TXIF
.equ  SER_TX_IEC, IEC0
.equ  SER_TX_IE,  U1TXIE
.equ  SER_TX_IPC,  IPC3
.equ  SER_TX_IPbit, U1TXIP0  
.equ  SER_RX_IFS, IFS0
.equ  SER_RX_IF,  U1RXIF
.equ  SER_RX_IEC, IEC0
.equ  SER_RX_IE,  U1RXIE
.equ  SER_RX_IPC, IPC2
.equ  SER_RX_IPbit, U1RXIP0
 
 ;sortie audio tonalités
 .equ AUDIO_PORT, PORTB
 .equ AUDIO_TRIS, TRISB
 .equ AUDIO_LAT,  LATB
 .equ AUDIO_OUT,  RB5 ; pin 14, RP37
 .equ AUDIO_TMR,  TMR3
 .equ AUDIO_TMRCON, T3CON
 .equ AUDIO_PER,  PR3
 .equ AUDIO_OCCON1, OC3CON1
 .equ AUDIO_OCCON2, OC3CON2
 .equ AUDIO_OCR,  OC3R
 .equ AUDIO_OCRS, OC3RS
 .equ AUDIO_RPOR, RPOR1
 .equ AUDIO_PPSbit, RP37R0
 .equ AUDIO_FN, 18
 
.LIST
 
; section pour regrouper les routine ISR    
.macro INT  
.section .int code
.align 2
.endm

; aide au débogage
; affiche un caractère à l'écran 
.macro progress c
   mov #\c, W0
   mov.b WREG, _video_buffer
.endm
 

.endif

