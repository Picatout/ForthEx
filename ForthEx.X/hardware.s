;****************************************************************************
; Copyright 2015, 2016, 2017 Jacques Deschenes
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
; hardware setup
    
.include "hardware.inc"
.include "core.s" 
.include "TVout.S"
.include "serial.s"
.include "sound.s"
.include "store.s"
.include "keyboard.s"    
.include "flash.s"
.include "sdcard.s"
    
    
.section .heap.bss bss address (EDS_BASE)
.global _heap
_heap: .space RAM_END-EDS_BASE-VIDEO_BUFF_SIZE
 
.section .hardware.bss  bss
    
.global systicks , seed, fwarm  
.align 2    
systicks: ; compteur de millisecondes
.space 2
seed: ; PRNG 32 bits    
.space 4
 ; si contient une valeur autre que 0 lance un warm boot       
fwarm: .space 2  
; adresse buffer CRC
crcbuffer: .space 2
; nombre d'octets bloc crc
blksize: .space 2
 
 
INTR
.global __MathError    
__MathError:
    mov #MATH_EXCEPTION,W0
    mov W0,fwarm
    reset
    
.global __StackError
__StackError:
    mov #STACK_EXCEPTION,W0
    mov W0,fwarm
    reset
    
    
; les interruptions non d�finies 
; r�initialisent le processeur    
.global __DefaultInterrupt
__DefaultInterrupt:
    reset

;;;;;;;;;;;;;;;;;;;;;;;;;;    
; interruption TIMER1
; interruption multi-t�ches    
; * incr�mente 'systicks',
; * minuterie dur�e son    
; * clignotement du curseur texte    
;;;;;;;;;;;;;;;;;;;;;;;;;
.global __T1Interrupt   
__T1Interrupt:
    bclr IFS0, #T1IF
    push.d W0
    push.d W2
    ; mise � jour compteur systicks
    inc systicks
    ; minuterie son
    cp0 tone_len
    bra z, 1f
    dec tone_len
    bra nz, 1f
    bclr AUDIO_TMRCON, #TON
1:   
;clignotement curseur texte
    cp0.b cursor_sema
    bra nz, isr_exit
    btsc.b fcursor, #CURSOR_ACTIVE
    call cursor_blink
isr_exit:
    pop.d W2
    pop.d W0
    retfie

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; r�ponse au signal /REBOOT
; envoy� par l'interface clavier
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
.global __INT1Interrupt
__INT1Interrupt:
    reset
    
    
; vecteur de r�initialisation du processeur    
.section .start.text code address(0x200)
.global __reset    
__reset: 
    clr ANSELA    ; d�sactivation entr�es analogiques
    ; priorit� 6 pour _INT1Interrupt
    mov #6, W0
    ior IPC5
    mov #rstack, RSP
    mov #pstack, DSP
    mov #_SYS_VARS,VP 
    mov DSP, W0
    sub #RSTK_GUARD, W0
    mov W0, SPLIM
    movpag #1,DSWPAG
    btsc RCON,#SWR
    bra 1f
    movpag #psvpage(_cold),DSRPAG
    mov #psvoffset(_cold),IP
    NEXT
1:  movpag #psvpage(_reboot),DSRPAG
    mov #psvoffset(_reboot),IP
    NEXT
    
.text

   
_reboot:
    .word QCOLD,TBRANCH,_cold-$
_warm:
    .word LIT,fwarm,DUP,FETCH,LIT,0,ROT,STORE,DP,FETCH,LATEST,FETCH
    .word STDIN,FETCH,STDOUT,FETCH
    .word CLS,CLR_LOW_RAM
    .word HARDWARE_INIT,VARS_INIT
    .word STDOUT,STORE,STDIN,STORE
    .word LATEST,STORE,DP,STORE
    .word DUP,LIT,USER_ABORT,EQUAL,ZBRANCH,1f-$
    .word DROP,LIT,_user_aborted,BRANCH,8f-$
1:  .word DUP,LIT,MATH_EXCEPTION,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,_math_error,BRANCH,8f-$
2:  .word DUP,LIT,STACK_EXCEPTION,EQUAL,ZBRANCH,3f-$
    .word DROP,LIT,_stack_reset,BRANCH,8f-$
3:  .word DROP,LIT,_unknown_reset    
8:  .word COUNT,TYPE,NEWLINE,QUIT
  
_cold:
    .word CLR_RAM,HARDWARE_INIT,VARS_INIT
    .word VERSION,COUNT,TYPE,NEWLINE 
    .word BOOTDEV,FETCH,BOOT; autochargement syst�me en RAM � partir d'une en FLASH MCU ou EEPROM
    .word QUIT ; boucle de l'interpr�teur

; est-ce un cold reboot    
HEADLESS QCOLD,HWORD
    .word LIT,fwarm,FETCH,ZEROEQ,EXIT
    
; initialisation mat�rielle    
HEADLESS HARDWARE_INIT, HWORD
    .word SET_CLOCK
    .word TICKS_INIT
    .word TVOUT_INIT
    .word KBD_INIT
    .word SERIAL_INIT
    .word STORE_INIT
    .word SOUND_INIT
    .word IO_LOCK
    .word KBD_RESET
    .word SDCINIT,DROP
    .word EXIT

; initialisation TIMER1
; utilis� pour compteur systicks    
HEADLESS TICKS_INIT
    ; diviseur prescale 1:8
    mov #(1<<TCKPS0),W0
    mov WREG,T1CON
    ; periode 1 msec
    mov #(FCY_MHZ*1000/8-1), W0
    mov W0, PR1
    ; priorit� d'interruption 3
    mov #~(7<<T1IP0), W0
    and IPC0
    mov #(3<<T1IP0), W0
    ior IPC0
    ; activation de l'interruption
    bclr IFS0, #T1IF
    bset IEC0, #T1IE
    bset T1CON, #TON
    NEXT

; ajustement de la fr�quence oscillateur.    
HEADLESS SET_CLOCK
    clr CLKDIV
    mov #PLLDIV, W0
    mov W0, PLLFBD
    bset OSCCON, #CLKLOCK ; verrouillage clock
    bclr INTCON1, #NSTDIS ; interruption multi-niveaux
    NEXT

; efface seulement l'espace avant USER_DICT
HEADLESS CLR_LOW_RAM
    mov #CSTK_BASE,W0
    repeat #((DATA_BASE-CSTK_BASE)/2-1)
    clr [W0++]
    NEXT
    
; mise � z�ro de la RAM
HEADLESS CLR_RAM
    mov #CSTK_BASE, W0
    repeat #((RAM_END-CSTK_BASE)/2-1)
    clr [W0++]
    NEXT

; verouillage configuration I/O
HEADLESS IO_LOCK    
    bset OSCCON, #IOLOCK
    NEXT

; initialisation registres syst�me forth
; initialisation variables utilisateur
HEADLESS VARS_INIT
    push DSRPAG
    mov VP,W2
    mov #psvpage(vars_count),W0
    mov W0,DSRPAG
    mov #psvoffset(vars_count),W0
    mov [W0++],W1
    dec W1,W1
    repeat W1
    mov [W0++],[W2++]
    pop DSRPAG
    NEXT

    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mots dans le dictionnaire
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
; empile le compteur systicks    
DEFCODE "TICKS",5,,TICKS  ; ( -- n )
    DPUSH
    mov systicks, T
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; d�lais en microsecondes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "USEC",4,,USEC
    mov #TCY_USEC,W0
    dec T,T
    mul.uu T,W0,W0
    repeat W0
    nop
    DPOP
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  d�lais en millisecondes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "MSEC",4,,MSEC  ; ( n -- )
    mov systicks, W0
    add W0,T,W0
1:    
    cp systicks
    bra neq, 1b
    DPOP
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; g�n�rnateur pseudo-hasard
; bas� sur une LFSR
;;;;;;;;;;;;;;;;;;;;;;;;;;;
.equ TAPSH, 0x8020
.equ TAPSL, 0x0002    
DEFCODE "LFSR",4,,LFSR  ; ( -- )
    lsr seed+2 
    rrc seed
    bra nc, 1f
    mov #TAPSH, W0
    xor seed+2
    mov #TAPSL, W0
    xor seed
1:    
    DPUSH
    mov seed, T
    NEXT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; g�n�rateur pseudo hazard
; g�n�re un nombre de 16 bits
;  si seed impaire incr�mente
;  ensuite Sn=(Sn-1)*3/2
;  on ne garde que le bit
;  le moins significatif
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFCODE "RAND",4,,RAND   ; ( -- n)
    clr W2
    mov #16,W4 ; compteur boucle
1:
    btss seed,#0
    bra 2f
    inc seed
    bra nc, 2f
    inc seed+2
 2:
    ; 3*seed
    sl seed,WREG
    mov W0,W1
    rlc seed+2, WREG
    exch W0,W1
    add seed
    mov W1,W0
    addc seed+2
    ;seed/2
    lsr seed+2,
    rrc seed
    lsr seed, WREG
    rrc W3,W3
    dec W4,W4
    bra nz, 2b
    DPUSH
    mov W3,T
    NEXT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
;initialisation variable seed
; seed=systicks/3
; seed+2=systicks%3    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
DEFCODE "SRAND",5,,SRAND  ; ( -- )
    mov systicks,W0
    mov #3,W2
    div.u W0,W2
    mov W0, seed
    mov W1, seed+2
    NEXT
   

; efface la m�moire programme utilisateur    
DEFWORD "CLEAR",5,,CLEAR ; ( -- )
    .word DP0,DP,STORE
    .word SYSLATEST,FETCH,LATEST,STORE
    .word EXIT
    
; retourne la quantit� de RAM disponible    
DEFWORD "UNUSED",6,,UNUSED    
    .word ULIMIT,HERE,MINUS,EXIT
    
; imprime UNUSED
DEFWORD "FREE",4,,FREE
    .word UNUSED,DOT,EXIT
    
; retourne la quantit� RAM disponible sur le HEAP
DEFCONST "HEAPSIZE",8,,HEAPSIZE,(RAM_END-VIDEO_BUFF_SIZE-EDS_BASE) ; ( -- n )
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; p�riph�rique CRC
; document de r�f�rence Microchip: DS70346B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; activation d�sactivation p�riph�rique CRC    
DEFCODE "CRCENBL",7,,CRCENBL  ; ( f -- )    
    bclr CRCCON1,#CRCEN
    cp0 T
    bra z, 8f
    bset CRCCON1,#CRCEN
8:  DPOP
    NEXT

; v�rifie l'�tat du CRC FIFO
; retourne:
;       0 plein
;       1 vide
;       2 ni plein ni vide    
DEFCODE "?CRCFIFO",8,,QCRCFIFO ; ( -- n )
    DPUSH
    clr T
    btsc CRCCON1,#CRCFUL
    bra 9f
    mov #1,T
    btss CRCCON1,#CRCMPT
    inc T,T
9:  NEXT
    

; s�lection de l'orde des bits de donn�es
;  argument:
;      FALSE  bit le plus significatif en premier
;      TRUE   bit le moins significatif en premier (Little Endian)
DEFCODE "CRCLE",5,,CRCLE ; ( f -- )
    bclr CRCCON1,#LENDIAN
    cp0 T
    bra z, 9f
    bset CRCCON1,#LENDIAN
9:  DPOP
    NEXT
    
    
    
;d�marrage du CRC shift register     
DEFCODE "CRCSTART",8,,CRCSTART ; ( -- )
    bclr IFS4,#CRCIF
    bset CRCCON1,#CRCGO
    NEXT
    
; longueur du data  (data width)
; argument:
;   'n' nombre de bits  {1..32}  
DEFCODE "CRCDW",5,,CRCDW ; ( n -- )    
    dec T,T
    ze T,T
    swap T
    mov CRCCON2,W0
    ze W0,W0
    ior W0,T,W0
    mov W0,CRCCON2
    DPOP
    NEXT
    
; longeur du polynome (polynomial length)
; argument:
;    'n' nombre de bits  {1..32]
DEFCODE "CRCPL",5,,CRCPL ; ( n -- )
    dec T,T
    ze T,T
    mov 0xFF00,W0
    and CRCCON2,WREG
    ior T,W0,W0
    mov W0,CRCCON2
    DPOP
    NEXT
    
; d�termine le polynome utilis�
;  argument:
;   ud  entier double non sign�e    
DEFCODE "CRCPOLY",7,,CRCPOLY ; ( ud -- )
    mov T,CRCXORH
    DPOP
    mov T,CRCXORL
    DPOP
    NEXT

; lecture d'un CRC < 32 bits
DEFCODE "CRC@",4,,CRCFETCH ; ( -- u )
    DPUSH
    mov CRCWDATL,T
    NEXT
    
; lecture du CRC-32 bits
DEFCODE "CRCD@",5,,CRCDFETCH ; ( -- ud )
    DPUSH
    mov CRCWDATL,T
    DPUSH
    mov CRCWDATH,T
    NEXT
    
    
; initialize CRCWDAT � z�ro
; et reset bit interruption    
DEFCODE "CRC0",4,,CRC0 ; ( -- )
    bclr CRCCON1,#CRCGO
    clr CRCWDATL
    clr CRCWDATH
    bclr IFS4,#CRCIF
    NEXT

; envoie un datum de 8 bits au CRC
DEFCODE "CRCC!",5,,CRCCSTORE ; ( c -- )
1:  btsc CRCCON1,#CRCFUL
    bra 1b
    mov T,W0
    mov.b WREG,CRCDATL
    DPOP
    NEXT
    
; envoie un datum de 16 bits au CRC    
DEFCODE "CRC!",4,,CRCSTORE ; ( n -- )
1:  btsc CRCCON1,#CRCFUL
    bra 1b
    mov T,CRCDATL
    DPOP
    NEXT
    
; envoie un datum de 32 bits au CRC    
DEFCODE "CRCD!",5,,CRCDSTORE, ; ( d -- )
1:  btsc CRCCON1,#CRCFUL
    bra 1b
    mov T,W0
    DPOP
    mov T,CRCDATL
    mov W0,CRCDATH
    DPOP
    NEXT
    
; v�rifie que l'op�ration CRC est compl�t�e
DEFCODE "CRCDONE",7,,CRCDONE ; ( -- f )
    DPUSH
    clr T
    btsc IFS4,#CRCIF
    setm T
9:  NEXT
    
    
; configure le CRC pour les blocs data des cartes SD
; C'est le polynome utilis� par les cartes secure digital    
; polynome:  x^16+x^12+x^5+1
; data width : 8
; poly length : 16
DEFWORD "CRC16",5,,CRC16 ; ( -- )
    ; mise � z�ro du checksum
    ; et du bit d'interruption
    .word CRC0
    ; activation du p�riph�rique
    .word TRUE,CRCENBL
    ; data 8 bits
    .word LIT,8,CRCDW
    ; polynome 16 bits
    .word LIT,16,CRCPL
    ; polynome: CRC16-CCITT x^16+x^12+x^5+1
    .word LIT,0x1021,LIT,0,CRCPOLY
    ; big indian
    .word FALSE,CRCLE
    .word CRCSTART
    .word EXIT
    
    
 DEFWORD "CRC7",4,,CRC7 ; ( -- )   
   .word CRC0
   .word TRUE,CRCENBL
   .word LIT,6,CRCDW
   .word LIT,6,CRCPL
   .word LIT,0x88,LIT,0,CRCPOLY
   .word FALSE,CRCLE
   .word CRCSTART
   .word EXIT
   
  