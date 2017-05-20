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
.include "math.s"    
.include "tvout.s"
.include "serial.s"
.include "sound.s"
.include "store.s"
.include "keyboard.s"
.include "vt102.s"    
.include "console.s"    
.include "flash.s"
.include "sdcard.s"
.include "strings.s"    
.include "dynamem.s"
.include "block.s" 
.include "tools.s"    
;.include "eefile.s"    
;.include "ed.s"    
    
; constantes dans la mémoire flash
.section .str.const psv       
.global _version,_math_error,_user_aborted,_stack_reset,_unknown_reset
_version:
.byte 12    
.ascii "ForthEx V0.1"    
_math_error:
.byte  21
.ascii "Math exception reset."
_user_aborted:
.byte  24
.ascii "Program aborted by user."
_stack_reset:
.byte  18
.ascii "Stack error reset."   
_unknown_reset:
.byte  22
.ascii "unknowned event reset."
_dstack_err_underflow:
.byte 23
.ascii "pstack underflow reset."    
_dstack_err_overflow:
.byte 22
.ascii "pstack overflow reset."
    
    
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
    
    
; les interruptions non définies 
; réinitialisent le processeur    
.global __DefaultInterrupt
__DefaultInterrupt:
    reset

;;;;;;;;;;;;;;;;;;;;;;;;;;    
; interruption TIMER1
; interruption multi-tâches    
; * incrémente 'systicks',
; * minuterie durée son    
; * clignotement du curseur texte    
;;;;;;;;;;;;;;;;;;;;;;;;;
.global __T1Interrupt   
__T1Interrupt:
    bclr IFS0, #T1IF
;    push.d W0
;    push.d W2
    ; mise à jour compteur systicks
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
;    pop.d W2
;    pop.d W0
    retfie

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
; réponse au signal /REBOOT
; envoyé par l'interface clavier
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
.global __INT1Interrupt
__INT1Interrupt:
    reset
    
    
; vecteur de réinitialisation du processeur    
.section .start.text code address(0x200)
.global __reset    
__reset: 
    clr ANSELA    ; désactivation entrées analogiques
    bset CNPDA,#CNPDA1 ; pulldown pour éviter entrée flottante
    ; priorité 6 pour _INT1Interrupt
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
    .word SYSCONS,FETCH
    .word CLS,CLR_LOW_RAM
    .word HARDWARE_INIT,VARS_INIT
    .word SYSCONS,STORE
    .word LATEST,STORE,DP,STORE
    .word DUP,LIT,USER_ABORT,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,_user_aborted,BRANCH,8f-$
2:  .word DUP,LIT,MATH_EXCEPTION,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,_math_error,BRANCH,8f-$
2:  .word DUP,LIT,STACK_EXCEPTION,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,_stack_reset,BRANCH,8f-$
    .word DUP,LIT,DSTACK_UNDERFLOW,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,_dstack_err_underflow,BRANCH,8f-$
2:  .word DUP,LIT,DSTACK_OVERFLOW,EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,_dstack_err_overflow,BRANCH,8f-$
2:  .word DROP,LIT,_unknown_reset    
8:  .word COUNT,TYPE,CR,QUIT
  
_cold:
    .word CLR_RAM,VARS_INIT,HARDWARE_INIT
    .word VERSION,COUNT,TYPE,CR
    .word IMGLOAD; autochargement d'une image  RAM 
    .word QAUTORUN
    .byte 7
    .ascii "AUTORUN"
    .align 2
    .word QUIT ; boucle de l'interpréteur

; s'il y a un mot appellé AUTORUN exécute le.    
HEADLESS QAUTORUN,HWORD
    .word DOSTR
    .word FIND,ZBRANCH,2f-$,EXECUTE,BRANCH,9f-$
2:  .word DROP
9:  .word EXIT
  
; est-ce un cold reboot    
HEADLESS QCOLD,HWORD
    .word LIT,fwarm,FETCH,ZEROEQ,EXIT
    
; initialisation matérielle    
HEADLESS HARDWARE_INIT, HWORD
    .word SET_CLOCK
    .word TICKS_INIT
    .word HEAP_INIT
    .word TVOUT_INIT
    .word KBD_INIT
    .word SERIAL_INIT
    .word STORE_INIT
    .word BLOCK_INIT
    .word SOUND_INIT
    .word IO_LOCK
    .word KBD_RESET
    .word SDCINIT,DROP
    .word EXIT

; initialisation TIMER1
; utilisé pour compteur systicks    
HEADLESS TICKS_INIT
    ; diviseur prescale 1:8
    mov #(1<<TCKPS0),W0
    mov WREG,T1CON
    ; periode 1 msec
    mov #(FCY_MHZ*125-1), W0
    mov W0, PR1
    ; priorité d'interruption 3
    mov #~(7<<T1IP0), W0
    and IPC0
    mov #(3<<T1IP0), W0
    ior IPC0
    ; activation de l'interruption
    bclr IFS0, #T1IF
    bset IEC0, #T1IE
    bset T1CON, #TON
    NEXT

; ajustement de la fréquence oscillateur.    
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
    
; mise à zéro de la RAM
HEADLESS CLR_RAM
    mov #CSTK_BASE, W0
    repeat #((EDS_BASE-CSTK_BASE)/2-1)
    clr [W0++]
    NEXT

; verouillage configuration I/O
HEADLESS IO_LOCK    
    bset OSCCON, #IOLOCK
    NEXT

; initialisation registres système forth
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
    
; nom: TICKS  ( -- n )    
;   Le système contient un compteur qui est incrémenté à toute les millisecondes.
;   Il s'agit d'un compteur 16 bits, le compteur boucle à zéro à toute les 65,5 secondes.    
;   TICKS retourne la valeur de ce compteur.  
; arguments:
;   aucun
; retourne:
;   n	    Valeur du compteur système systicks.    
DEFCODE "TICKS",5,,TICKS  ; ( -- n )
    DPUSH
    mov systicks, T
    NEXT

; nom: USEC   ( u -- ) 
;   Pause en microsecondes. A cause des interruptions cette valeur ne peut-être
;   garantie. La valeur u passée en argument est une valeur minimale.
; arguments:
;   u   durée de la pause en microsecondes.
; retourne:
;   rien    
DEFCODE "USEC",4,,USEC
    mov #70,W0  ; cette valeur est basée sur FCY=70Mhz
    mul.uu T,W0,W0
    mov W0,PR5
    clr TMR5
    bclr IFS1,#T5IF
    bset T5CON,#TON
1:  btss IFS1,#T5IF
    bra 1b
    bclr T5CON,#TON
    DPOP
    NEXT
 
; nom: MS  ( u -- )
;   Boucle d'attente qui dure au moins u millisecondes. Cette boucle utitise
;   le compteur systicks. L'erreur sur la durée est de ± 1msec.    
; arguments:
;   u    Durée en millisecondes.
; retourne:
;   rien
DEFWORD "MS",2,,MS
    ; si TMR1 > PR1/2 ajoute 1 à u
    .word LIT,FCY_MHZ*125/2,LIT,TMR1,FETCH,ULESS ; S: u 0|-1
    .word MINUS
    .word TICKS,DUP,ROT,PLUS,TWOTOR
2:  .word TICKS,TWORFETCH,WITHIN,TBRANCH,2b-$
    .word RDROP,RDROP
    .word EXIT
    

.equ TAPSH, 0x8020
.equ TAPSL, 0x0002    
; nom: LFSR  ( -- n )
;   Générnateur pseudo-hasard basé sur un Linear Feedback Shift Register de 32 bits.
;   Ce générateur doit-être initialisé avec SRAND avant utilisation sinon 
;   la valeur retournée est toujours 0.
; arguments:
;   aucun
; retourne:
;   n    Un entier de 16 bits.    
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

; nom: RAND   ( -- n )    
;   Générateur pseudo-hasard qui génère un entier de 16 bits. Utilise la variable 
;   Ce générateur doit-être initialisé avec SRAND avant utilisation sinon 
;   la valeur retournée est toujours 0.
;   algorithme:
;    rand=0
;    count=0
;    a) rand<<1
;    b) si impair(seed) alors seed++
;    c) seed=seed*3/2
;    d) rand |= seed&1
;    e) ++count==16?termine:goto a    
; arguments:
;   aucun
; retourne:    
;   n   Entier de 16 bits.
DEFCODE "RAND",4,,RAND   ; ( -- n)
    DPUSH
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
    rrc T,T
    dec W4,W4
    bra nz, 2b
    NEXT

; nom: SRAND ( -- )    
;   Initialisation du registre des générateurs pseudo-aléatoire LFSR et RAND.
;   Cette initialisation doit-être faite avant le premier appel de LFSR ou RAND.
; arguments:
;   aucun
; retourne:
;   rien    Modifie seulement un registre 'seed' interne au système.      
DEFCODE "SRAND",5,,SRAND  ; ( -- )
    mov systicks,W0
    mov #3,W2
    div.u W0,W2
    mov W0, seed
    mov W1, seed+2
    NEXT
   
; nom: CLEAR  ( -- )
;   Efface la mémoire de données utilisateur. Tous les mot définis par l'utilisateur
;   sont supprimés du dictionnaire.  La valeur de DP est réiniialisé à DP0.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "CLEAR",5,,CLEAR ; ( -- )
    .word DP0,DP,STORE
    .word SYSLATEST,FETCH,LATEST,STORE
    .word EXIT
    
; nom: UNUSED ( -- n )    
;   Retourne la quantité de RAM de données disponible.
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "UNUSED",6,,UNUSED    
    .word ULIMIT,HERE,MINUS,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; périphérique CRC
; document de référence Microchip: DS70346B
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; activation désactivation périphérique CRC    
;DEFCODE "CRCENBL",7,,CRCENBL  ; ( f -- )    
;    bclr CRCCON1,#CRCEN
;    cp0 T
;    bra z, 8f
;    bset CRCCON1,#CRCEN
;8:  DPOP
;    NEXT

; vérifie l'état du CRC FIFO
; retourne:
;       0 plein
;       1 vide
;       2 ni plein ni vide    
;DEFCODE "?CRCFIFO",8,,QCRCFIFO ; ( -- n )
;    DPUSH
;    clr T
;    btsc CRCCON1,#CRCFUL
;    bra 9f
;    mov #1,T
;    btss CRCCON1,#CRCMPT
;    inc T,T
;9:  NEXT
    

; sélection de l'orde des bits de données
;  argument:
;      FALSE  bit le plus significatif en premier
;      TRUE   bit le moins significatif en premier (Little Endian)
;DEFCODE "CRCLE",5,,CRCLE ; ( f -- )
;    bclr CRCCON1,#LENDIAN
;    cp0 T
;    bra z, 9f
;    bset CRCCON1,#LENDIAN
;9:  DPOP
;    NEXT
    
    
    
;démarrage du CRC shift register     
;DEFCODE "CRCSTART",8,,CRCSTART ; ( -- )
;    bclr IFS4,#CRCIF
;    bset CRCCON1,#CRCGO
;    NEXT
    
; longueur du data  (data width)
; argument:
;   'n' nombre de bits  {1..32}  
;DEFCODE "CRCDW",5,,CRCDW ; ( n -- )    
;    dec T,T
;    ze T,T
;    swap T
;    mov CRCCON2,W0
;    ze W0,W0
;    ior W0,T,W0
;    mov W0,CRCCON2
;    DPOP
;    NEXT
    
; longeur du polynome (polynomial length)
; argument:
;    'n' nombre de bits  {1..32]
;DEFCODE "CRCPL",5,,CRCPL ; ( n -- )
;    dec T,T
;    ze T,T
;    mov 0xFF00,W0
;    and CRCCON2,WREG
;    ior T,W0,W0
;    mov W0,CRCCON2
;    DPOP
;    NEXT
    
; détermine le polynome utilisé
;  argument:
;   ud  entier double non signée    
;DEFCODE "CRCPOLY",7,,CRCPOLY ; ( ud -- )
;    mov T,CRCXORH
;    DPOP
;    mov T,CRCXORL
;    DPOP
;    NEXT

; lecture d'un CRC < 32 bits
;DEFCODE "CRC@",4,,CRCFETCH ; ( -- u )
;    DPUSH
;    mov CRCWDATL,T
;    NEXT
    
; lecture du CRC-32 bits
;DEFCODE "CRCD@",5,,CRCDFETCH ; ( -- ud )
;    DPUSH
;    mov CRCWDATL,T
;    DPUSH
;    mov CRCWDATH,T
;    NEXT
    
    
; initialize CRCWDAT à zéro
; et reset bit interruption    
;DEFCODE "CRC0",4,,CRC0 ; ( -- )
;    bclr CRCCON1,#CRCGO
;    clr CRCWDATL
;    clr CRCWDATH
;    bclr IFS4,#CRCIF
;    NEXT

; envoie un datum de 8 bits au CRC
;DEFCODE "CRCC!",5,,CRCCSTORE ; ( c -- )
;1:  btsc CRCCON1,#CRCFUL
;    bra 1b
;    mov T,W0
;    mov.b WREG,CRCDATL
;    DPOP
;    NEXT
    
; envoie un datum de 16 bits au CRC    
;DEFCODE "CRC!",4,,CRCSTORE ; ( n -- )
;1:  btsc CRCCON1,#CRCFUL
;    bra 1b
;    mov T,CRCDATL
;    DPOP
;    NEXT
    
; envoie un datum de 32 bits au CRC    
;DEFCODE "CRCD!",5,,CRCDSTORE, ; ( d -- )
;1:  btsc CRCCON1,#CRCFUL
;    bra 1b
;    mov T,W0
;    DPOP
;    mov T,CRCDATL
;    mov W0,CRCDATH
;    DPOP
;    NEXT
    
; vérifie que l'opération CRC est complétée
;DEFCODE "CRCDONE",7,,CRCDONE ; ( -- f )
;    DPUSH
;    clr T
;    btsc IFS4,#CRCIF
;    setm T
;9:  NEXT
    
    
; configure le CRC pour les blocs data des cartes SD
; C'est le polynome utilisé par les cartes secure digital    
; polynome:  x^16+x^12+x^5+1
; data width : 8
; poly length : 16
;DEFWORD "CRC16",5,,CRC16 ; ( -- )
;    ; mise à zéro du checksum
;    ; et du bit d'interruption
;    .word CRC0
;    ; activation du périphérique
;    .word TRUE,CRCENBL
;    ; data 8 bits
;    .word LIT,8,CRCDW
;    ; polynome 16 bits
;    .word LIT,16,CRCPL
;    ; polynome: CRC16-CCITT x^16+x^12+x^5+1
;    .word LIT,0x1021,LIT,0,CRCPOLY
;    ; big indian
;    .word FALSE,CRCLE
;    .word CRCSTART
;    .word EXIT
    
    
; DEFWORD "CRC7",4,,CRC7 ; ( -- )   
;   .word CRC0
;   .word TRUE,CRCENBL
;   .word LIT,6,CRCDW
;   .word LIT,6,CRCPL
;   .word LIT,0x88,LIT,0,CRCPOLY
;   .word FALSE,CRCLE
;   .word CRCSTART
;   .word EXIT
   
  