;****************************************************************************
; Copyright 2015,2016,2017 Jacques Desch�nes
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
; NOM: math.s
; DATE: 2017-05-18
; DESCRIPTION: 
;    Ce module contient les op�rateurs arithm�tiques, logiques et relationnels.
    

; nom:  MSB  ( -- u )
;   Constante retournant la valeur du bit le plus significatif d'un entier.
; arguments:
;   aucun
; retourne:
;   u   Valeur de l'entier dont seul le bit le plus significatif est � 1.    
DEFCONST "MSB",3,,MSB,0x8000

; nom: MAX-INT  ( -- n )
;   Constante retourant la valeur du plus grand entier sign�.
; arguments:
;   aucun
; retourne:
;   n    Valeur du plus grand entier sign�.
DEFCONST "MAX-INT",7,,MAXINT,0x7FFF ; 32767
 
; nom: MIN-INT  ( -- n )
;   Constante retournant le plus petit entier sign�.
; arguments:
;   aucun
; retourne:
;   n   Plus petit entier sign�.    
DEFCONST "MIN-INT",7,,MININT,0x8000 ; -32768

; nom: HEX  ( -- )
;   Initialise la variable syst�me BASE avec la valeur 16. Apr�s l'ex�cution
;   de ce mot, l'interpr�teur condis�re que les cha�nes converties en nombre
;   sont en base 16 et les nombres � imprim�s sont aussi convertis dans cette base.
; arguments:
;   Aucun
; retourne:
;   rien    
DEFWORD "HEX",3,,HEX ; ( -- )
    .word LIT,16,BASE,STORE,EXIT
    
; nom: DECIMAL ( -- )
;   Initialise la variable syst�me BASE avec la valeur 10. Apr�s l'ex�cution
;   de ce mot, l'interpr�teur condis�re que les cha�nes converties en nombre
;   sont en base 10 et les nombres � imprim�s sont aussi convertis dans cette base.
; arguments:
;   Aucun
; retourne:
;   rien    
DEFWORD "DECIMAL",7,,DECIMAL ; ( -- )
    .word LIT,10,BASE,STORE,EXIT
    
; nom: +  ( x1 x2 -- x3 )  x3=x1+x2
;   Additionne les 2 entiers au sommet de la pile des arguments.
; arguments:
;   x1  premier entier.
;   x2  deuxi�me entier.
; retourne:
;   x3   somme de x1 et x2  
DEFCODE "+",1,,PLUS
    add T, [DSP--], T
    NEXT
 
; nom: -  ( x1 x2 -- x3 )  x3 = x1-x2
;   Soustrait l'entier x2 de l'entier x1.
; arguments:
;   x1    premier entier.
;   x2    deuxi�me entier au sommet de la pile.
; retourne:
;   x3    valeur obtenu en soustrayant x2 de x1.    
DEFCODE "-",1,,MINUS 
    mov [DSP--],W0
    sub W0,T,T
    NEXT
    
; nom: 1+  ( x1 -- x2 )  x2=x1+1
;   Incr�mente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 incr�ment� de 1.
DEFCODE "1+",2,,ONEPLUS ; ( n -- n+1 )
    add #1, T
    NEXT

    
; nom: 2+  ( x1 -- x2 )  x2=x1+2
;   Incr�mente de 2 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 incr�ment� de 2.
DEFCODE "2+",2,,TWOPLUS
    add #2, T
    NEXT
    
; nom: 1-  ( x1 -- x2 )  x2=x1-1
;   D�cr�mente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 d�cr�ment� de 1.
DEFCODE "1-",2,,ONEMINUS
    sub #1, T
    NEXT
    
; nom: 2-  ( x1 -- x2 )  x2=x1-2
;   D�cr�mente de 2 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 d�cr�ment� de 2.
DEFCODE "2-",2,,TWOMINUS
    sub #2, T
    NEXT
    
; nom: 2*  ( x1 -- x2 )   x2 = 2*x1
;   Multiplie par 2 la valeur au sommet de la pile des arguments.
; arguments:
;   x1
; retourne:
;   x2    x1 multipli� par 2.    
DEFCODE "2*",2,,TWOSTAR
    add T,T, T
    NEXT
    
; nom: 2/  ( x1 -- x2 ) x2=x1/2
;   Divise par 2 la valeur au sommet de la pile des arguments.
; arguments:
;   x1
; retourne:
;   x2     x2 divis� par 2.    
DEFCODE "2/",2,,TWOSLASH
    asr T,T
    NEXT
    
; nom: LSHIFT  ( x1 u -- x2 )  x2=x1<<u
;   D�cale vers la gauche de u bits le nombre x1. Ce qui �quivaut � 
;   une multipliation par 2^u.    
; arguments:
;   x1   Nombre qui sera d�cal� vers la gauche.
;   u    Nombre de bits de d�calage.
; retourne:
;   x2   x2=x1<<u    
DEFCODE "LSHIFT",6,,LSHIFT
    mov T, W0
    DPOP
    cp0 W0
    bra z,9f
    mov #16,W1
    cp W0,W1
    bra leu, 1f
    mov W1,W0
1:  dec W0,W0
    repeat W0
    sl T,T
9:  NEXT
    
; nom: RSHIFT ( x1 u -- x2 ) x2 = x1>>u
;   D�calage vers la droite de u bits de la valeur x1.
;   �quivaut � une division par 2^u. 
; arguments:
;   x1   Nombre qui sera d�cal�.
;   u    Nombre de bits de d�calage.
; retourne:
;    x2   x2=x1>>u    
DEFCODE "RSHIFT",6,,RSHIFT ; ( x1 u -- x2 ) x2=x1>>u
    mov T,W0
    DPOP
    cp0 W0
    bra z, 9f
    mov #16,W1
    cp W0,W1
    bra leu, 1f
    mov W1,W0    
1:  dec W0,W0
    repeat W0
    lsr T,T
9:  NEXT
    
; nom: +!  ( n a-addr -- )  *a-addr = *a-addr+n
;   Additionne un entier � la valeur d'une variable.
; arguments:
;    n Entier � ajouter � la valeur de la variable.
;    a-addr  Adresse de la variable.
; retourne:
;    rien    
DEFCODE "+!",2,,PLUSSTORE
    mov [T], W0
    add W0, [DSP--],W0
    mov W0, [T]
    DPOP
    NEXT

; nom: D+  ( d1 d2 -- d3 )   d3=d1+d2    
;   Addition de 2 entiers double.
; arguments:
;   d1  Premier entier double.
;   d2  Deuxi�me enteier double.
; retourne:
;   d3  Somme de d1 et d2    
DEFCODE "D+",2,,DPLUS ; ( d1 d2 -- d3 )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    add W0,[DSP],[DSP]
    addc W1,T,T
    NEXT
 
; nom: D-  ( d1 d2 -- d3 )  d3 = d1-d2    
;   Soustractions de 2 entiers doubles.
; arguments:
;   d1  Premier entier double.
;   d2  Deuxi�me entier double.
; retourne:
;   d3  Entier double r�sultant de la soustration d1-d2.    
DEFCODE "D-",2,,DMINUS ; ( d1 d2 -- d3 )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    mov [DSP],W2
    sub W2,W0,[DSP]
    subb T,W1,T
    NEXT
    
; nom: M+  ( d1 n -- d2 ) d2 = d1+n
;   Addition d'un entier simple � un entier double.
; arguments:
;   d1  Entier double.
;   n   Entier simple.
; retourne:
;   d2  Entier double r�sultant de d1+n    
DEFCODE "M+",2,,MPLUS
    mov T,W0
    DPOP
    clr W1
    btsc W0,#15
    setm W1
    add W0,[DSP],[DSP]
    addc W1,T,T
    NEXT
 
; nom: *  ( n1 n2 -- n3 )  n3=n1*n2
;   Multiplication sign�e de 2 entiers simple.
; arguments:
;   n1   Premier entier.
;   n2   Deuxi�me entier.
; retourne:
;   n3   Produit des 2 entiers.    
DEFCODE "*",1,,STAR ; ( n1 n2 -- n1*n2) 
    mul.ss T,[DSP--],W0
    mov W0,T
    NEXT

; nom: M*   ( n1 n2 -- d )  d=n1*n2    
;   Produit de 2 entiers simples, conserve l'entier double.
; arguments:
;   n1  Premier entier simple.
;   n2  Deuxi�me entier simple.
; retourne:
;   d  Entier double r�sultant du produit de n1*n2.    
DEFCODE "M*",2,,MSTAR ; ( n1 n2 -- d )
    mul.ss T,[DSP],W0
    mov W0,[DSP]
    mov W1,T
    NEXT

; nom: UM*  ( u1 u2 -- ud )   ud=u1*u2    
;   Muttiplication non sign�e de 2 entiers simple r�sultant en un entier double non sign�.
; arguments:
;   u1  premier entier simple non sign�.
;   u2  deuxi�me entier simple non sign�.
; retourne:
;   ud  Entier double non sign�.    
DEFCODE "UM*",3,,UMSTAR ; ( u1 u2 -- ud )
    mul.uu T,[DSP],W0
    mov W1,T
    mov W0,[DSP]
    NEXT
   
; nom: UD*  ( ud1 u2 -- ud3 )  ud3=ud1*u2    
;   Multiplication non sign�e d'un entier double par un entier simple.
; arguments:
;   ud1  Entier double non sign�.    
;    u2  Entier simple non sign�.
; retourne:    
;   ud3  Entier double non sign� r�sultant du produit de ud1 u2.  
DEFCODE "UD*",3,,UDSTAR ; ( ud1 u2 -- ud3 )
    mul.uu T,[DSP],W0
    mov W0,[DSP]
    mov T,W0
    DPOP
    mul.uu W0,[DSP],W0
    add W1,T,T
    mov W0,[DSP]
    NEXT

; nom: /  ( n1 n2 -- n3 )  n3=n1/n2
;   Division enti�re sign�e sur nombres simple.
; arguments:
;   n1  Num�rateur 
;   n2  D�nominateur
; retourne:
;   n3  Quotient entier.    
DEFCODE "/",1,,SLASH
    mov [DSP--],W0
    repeat #17
    div.s W0,T
    mov W0,T
    NEXT

; nom: MOD  ( n1 n2 -- n3 )  n3=n1%n2    
;    Division enti�re de 2 entiers simple o� seul le restant est conserv�.
; arguments:
;    n1  Num�rateur
;    n2  D�nominateur
; retourne:
;    n3   Reste de la division.    
DEFCODE "MOD",3,,MOD 
   mov [DSP--],W0
   repeat #17
   div.s W0,T
1: mov W1,T
   NEXT
   
; nom: */  ( n1 n2 n3 -- n4 ) n4=(n1*n2)/n3   
;   Une multiplication de n1 par n2 est suivit d'une division du r�sultat par n3.
;   Le produit de n1 et n2 est conserv� comme entier double avant la division.
; arguments:
;    n1 Premier entier simple.
;    n2 Deuxi�me entier simple.
;    n3 Troisi�me entier simple.
; retourne:
;    n4  Entier simple r�sultant de la division du double n1*n2 par n3.   
DEFCODE "*/",2,,STARSLASH
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.sd W0,T
    mov W0,T
    NEXT

; nom: */MOD ( n1 n2 n3 -- n4 n5 )
;   Une multiplication de n1 par n2 est suivit d'une division par n3 le quotient
;   et le reste sont conserv�s. Le r�sultat interm�diaire de la multipllication
;   est un entier double.
; arguments:
;   n1  Premier entier simple.
;   n2  Deuxi�me entier simple.
;   n3  Troisi�me entier simple.
; retourne:
;   n4  Reste de la division de (n1*n2)/n3
;   n5  Quotient dela division de (n1*n2)/n3    
DEFCODE "*/MOD",5,,STARSLASHMOD
    mov [DSP--],W0
    mov [DSP--],W1
    mul.ss W0,W1,W0
    repeat #17
    div.sd W0,T
1:  mov W1,[++DSP]
    mov W0,T
    NEXT
    
; nom: /MOD  ( n1 n2 -- n3 n4 ) 
;   Division sign�e de n1 par n2 , le reste et le quotient sont conserv�s.    
; arguments:
;   n1  Num�rateur
;   n2  D�nominateur
; retourne:
;   n3  Reste
;   n4  Quotient    
DEFCODE "/MOD",4,,SLASHMOD ; ( n1 n2 -- r q )
    mov [DSP],W0
    repeat #17
    div.s W0,T
1:  mov W0,T     ; quotient
    mov W1,[DSP] ; reste
    NEXT

; nom: UM/MOD  ( ud u1 -- u2 u2 )    
;   Division d'un entier double non sign�
;   par un entier simple non sign�
;   r�sulant en un quotient et reste simple.
; arguments:    
;   ud   Entier double non sign�, num�rateur.
;   u1   Entier simple non sign�, d�nominateur.
; retourne:    
;   u2 Entier simple non sign�, Reste
;   u3 Entier simple non sign�, Quotient    
DEFCODE "UM/MOD",6,,UMSLASHMOD 
    mov [DSP--],W1
    mov [DSP--],W0
    repeat #17
    div.ud W0,T
    mov W0,T
    mov W1,[++DSP]
    NEXT
    
; nom: UD/MOD  ( ud1 u1 -- u2 ud2 )    
;   Division d'un entier double non sign�
;   par un entier simple non sign� r�sultant
;   en un quotient double et un reste simple
; arguments:
;   ud1   Entier double non sign�, num�rateur.
;    u1   Entier simple non sign�, d�nominateur.
; r�sultat:
;   u2	Entier simple non sign�, reste.
;   ud2 Entier double non sign�, quotient.    
DEFCODE "UD/MOD",6,,UDSLASHMOD
    clr W1
    mov [DSP],W0
    repeat #17
    div.ud W0,T
    mov W0,W4  ; partie forte du quotient
    mov [DSP-2],W0 
    repeat #17
    div.ud W0,T
    mov W1,[DSP-2] ;reste entier simple
    mov W0,[DSP]  ; partie faible du quotient
    mov W4,T  ; partie forte du quotient
    NEXT
    
; nom: MAX  ( n1 n2 -- n ) n=max(n1,n2) 
;   Retourne le plus grand des 2 entier sign�s.
; arguments:
;   n1 Premier entier
;   n2 Deuxi�me entier
; retourne:
;   n  Le plus grand des 2 entiers sign�s.    
DEFCODE "MAX",3,,MAX 
    mov [DSP--],W0
    cp T,W0
    bra ge, 1f
    exch T,W0
1:  NEXT    
    
    
; nom: MIN  ( n1 n2 -- n ) n=min(n1,n2) 
;   Retourne le plus petit des 2 entiers sign�s.
; arguments:
;   n1 Premier entier
;   n2 Deuxi�me entier
; retourne:
;   n  Le plus petit des 2 entiers sign�s.    
DEFCODE "MIN",3,,MIN
    mov [DSP--],W0
    cp W0,T
    bra ge, 1f
    exch T,W0
1:  NEXT
    
; nom: UMAX  ( u1 u2 -- u ) u=max(u1,u2) 
;   Retourne le plus grand des 2 entiers non sign�s.
; arguments:
;   u1 Premier entier non sign�.
;   u2 Deuxi�me entier non sign�.
; retourne:
;   u  Le plus grand des 2 entiers non sign�s.    
DEFCODE "UMAX",4,,UMAX
    mov [DSP--],W0
    cp T,W0
    bra geu,1f
    exch W0,T
1:  NEXT
    
; nom: UMIN  ( u1 u2 -- u ) u=min(u1,u2) 
;   Retourne le plus petit des 2 entiers non sign�s.
; arguments:
;   u1 Premier entier non sign�.
;   u2 Deuxi�me entier non sign�.
; retourne:
;   u  Le plus petit des 2 entiers non sign�s.    
DEFCODE "UMIN",4,,UMIN
    mov [DSP--],W0
    cp W0,T
    bra geu, 1f
    exch T,W0
1:  NEXT
    
; nom: WITHIN  ( n1|u1 n2|u2 n3|u3 -- f ) 
;   V�rifie si l'entier n1|u1<=n2|u2<n3|u3.
;   La v�rification doit fonctionner aussi bien avec les entiers
;   sign�s et non sign�s.    
; arguments:
;   n1|u1   Entier � v�rifier,sign� ou non.
;   n2|u2   Borne inf�rieure ferm�e,sign� ou non.
;   n3|u3   Borne sup�rieure ouverte, sign� ou non. 
; retourne:
;   f    Indicateur bool�en vrai si condition n1|u1<=n2|u2<n3|u3.    
DEFCODE "WITHIN",6,,WITHIN  
    mov T,W0   
    DPOP
    sub W0,T,[RSP++]
    mov [DSP],W0
    sub W0,T,[DSP]
    mov [--RSP],T
    bra code_ULESS

; nom: EVEN  ( n -- f )
;   Retourne un indicateur bool�en vrai si l'entier est pair.
; arguments:
;   n   Entier � v�rifier.
; retourne:
;   f  Indicateur bool�en, vrai si entier pair.    
DEFCODE "EVEN",4,,EVEN ; ( n -- f ) vrai si n pair
    setm W0
    btsc T,#0
    clr W0
    mov W0,T
    NEXT
    
; nom: ODD  ( n -- f )
;   Retourne un indicateur bool�en vrai si l'entier est impair.
; arguments:
;   n   Entier � v�rifier.
; retourne:
;   f   Indicateur bool�en, vrai si entier impair.    
DEFCODE "ODD",3,,ODD
    setm W0
    btss T,#0
    clr W0
    mov W0,T
    NEXT

; nom: ABS  ( n1 -- n2 ) 
;   Retourne la valeur absolue d'un entier simple.
; arguments:
;   n1    Entier simple sign�.
; retourne:
;  n2  La valeur absolue de n1.    
DEFCODE "ABS",3,,ABS
    btsc T,#15
    neg T,T
    NEXT

; nom: DABS ( d1 -- d2 )    
;   Retourne la valeur absolue d'un entier double.
; arguments:
;    d1   Entier double sign�.
; retourne:
;    d2  Valeur absolue de d1.    
DEFCODE "DABS",4,,DABS 
    btss T,#15
    bra 9f
    mov [DSP],W0
    com T,T
    com W0,W0
    add #1,W0
    addc #0,T
    mov W0,[DSP]
9:  NEXT    

; nom: S>D   ( n -- d )    
;   Convertie entier simple en entier double. 
; arguments:
;   n    Entier simple sign�.
; retourne:
;   d    Entier double sign�.    
DEFCODE "S>D",3,,STOD ; ( n -- d ) 
    DPUSH
    clr W0
    btsc T,#15
    com W0,W0
    mov W0,T
    NEXT

; nom: ?NEGATE  ( n1 n2 -- n3 )
;   Inverse n1 si n2 est n�gatif.
; arguments:
;   n1   Entier simple sign�.
;   n2   Entier simple sign�, valeur de contr�le.
; retourne:
;   n3   Entier simple, n2<0?-n1:n1    
DEFCODE "?NEGATE",7,,QNEGATE
    mov T,W0
    DPOP
    btsc W0,#15
    neg T,T
    NEXT    

; nom: SM/REM    ( d1 n1 -- n2 n3 )    
;   Division sym�trique entier double par simple arrondie vers z�ro.
;   REF: http://lars.nocrew.org/forth2012/core/SMDivREM.html    
;   Adapt� de Camel Forth pour MSP430.
; arguments:
;    d1   Entier double sign�, num�rateur.
;    n1   Entier simple sign�, d�nominateur.
; retourne:    
;    n2   Reste de la division.
;    n3   Quotient de la division.    
DEFWORD "SM/REM",6,,SMSLASHREM ; ( d1 n1 -- n2 n3 )
    .word TWODUP,XOR,TOR,OVER,TOR
    .word ABS,TOR,DABS,RFROM,UMSLASHMOD
    .word SWAP,RFROM,QNEGATE,SWAP,RFROM,QNEGATE
    .word EXIT

; nom: FM/MOD  ( d1 n1 -- n2 n3 )    
;   Division double/simple arrondie au plus petit.
;   REF: http://lars.nocrew.org/forth2012/core/FMDivMOD.html
;   Adapt� de Camel Forth pour MSP430.
; arguments:
;    d1   Entier double sign�, num�rateur.
;    n1   Entier simple sign�, d�nominateur.
; retourne:    
;    n2   Reste de la division.
;    n3   Quotient de la division.    
DEFWORD "FM/MOD",6,,FMSLASHMOD ; ( d1 n1 -- n2 n3 )    
    .word DUP,TOR,TWODUP,XOR,TOR,TOR
    .word DABS,RFETCH,ABS,UMSLASHMOD
    .word SWAP,RFROM,QNEGATE,SWAP,RFROM,ZEROLT,ZBRANCH,9f-$
    .word NEGATE,OVER,ZBRANCH,9f-$
    .word RFETCH,ROT,MINUS,SWAP,ONEMINUS
9:  .word RDROP,EXIT

; nom: EVAR+  ( a-addr -- )  
;   Incr�mente une variable r�sidante en m�moire EDS.
; arguments:
;   a-addr   Adresse de la variable.
; retourne:
;   rien     
DEFWORD "EVAR+",5,,EVARPLUS 
    .word DUP,EFETCH,ONEPLUS,SWAP,STORE,EXIT
    
; nom: EVAR- ( a-addr -- )    
;   D�cr�mente une variable r�sidante en m�moire EDS.
; arguments:    
;    a-addr  Adresse de la variable.
; retourne:
;    rien    
DEFWORD "EVAR-",5,,EVARMINUS ; ( addr -- )
    .word DUP,EFETCH,ONEMINUS,SWAP,STORE,EXIT
    
    
; nom: UDREL  ( ud1 ud2 -- n )    
;   Compare 2 nombres double non sign�s et retourne un indicateur de relation.
;   n = 1 si ud1>ud2
;   n = 0 si ud1==ud2
;   n = -1 si ud1<ud2
; arguments:
;   ud1   Premier entier double non sign�.
;   ud2   Deuxi�me entier double non sign�.
; retourne:
;    n    R�sultat de la comparaison.    
DEFCODE "UDREL",5,,UDREL ; ( ud1 ud2 -- n )
    mov T,W1
    DPOP
    mov T,W0
    DPOP
    mov T, W3
    DPOP
    mov T, W2
    clr T
    sub W2,W0,W0
    subb W3,W1,W1
    bra ltu, 8f
    ior W0,W1,W2
    bra z, 9f
    inc T,T
    bra 9f
8:  setm T    
9:  NEXT
    
    
; nom: NEGATE  ( n1 -- n2 )
;   Inverse arithm�tique de n1. Compl�ment de 2.
; arguments:
;   n1   Entier � invers�.
; retourne:
;   n2   n2=-n1    
DEFCODE "NEGATE",6,,NEGATE ; ( n - n ) compl�ment � 2
    neg T, T
    NEXT
    
; nom: DNEGATE ( d1 -- d2 )
;   Inverse arithm�tique d'un entier double. Compl�ment de 2.
; arguments:
;    d1   Entier double � invers�.
; retourne:
;    d2   d2=-d1    
DEFCODE "DNEGATE",7,,DNEGATE ; ( d -- n )
    com T,T
    com [DSP],[DSP]
    mov #1,W0
    add W0,[DSP],[DSP]
    addc #0,T
    NEXT
    
; nom: INVERT  ( n1 -- n2 )
;   Inversion des bits, compl�ment de 1.
; arguments:
;   n1   Entier simple.
; retourne:
;   n2   Inverse bit � bit de n1.    
DEFCODE "INVERT",6,,INVERT ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
; nom: DINVERT   ( d1 -- d2 ))
;   Invesion bit � bit d'un entier double. Compl�ment de 1.
; arguments:
;   d1   Entier double.
; retourne:
;   d2   Inverse bit � bit de d1.    
DEFCODE "DINVERT",7,,DINVERT
    com T,T
    com [DSP],[DSP]
    NEXT
    
; DESCRIPTION:
;    op�rations logiques bit � bit.
    
; nom: AND  ( n1 n2 -- n3 )
;   Op�ration Bool�enne bit � bit ET.
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:
;   n3  R�sultat de l'op�ration.    
DEFCODE "AND",3,,AND 
    and T,[DSP--],T
    NEXT
    
; nom: OR  ( n1 n2 -- n3 )
;   Op�ration Bool�enne bit � bit OU inclusif.
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:
;   n3  R�sultat de l'op�ration.    
DEFCODE "OR",2,,OR
    ior T,[DSP--],T
    NEXT
    
; nom: XOR  ( n1 n2 -- n3 )
;   Op�ration Bool�enne bit � bit OU exclusif.
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:
;   n3  R�sultat de l'op�ration.    
DEFCODE "XOR",3,,XOR
    xor T,[DSP--],T
    NEXT
    
; nom: NOT  ( n1 -- n2 )
;   Op�ration Bool�enne de n�gation.
;   Si n1==0  n2=-1.
;   Si n1<>0  n2=0.    
; arguments:
;   n1  Op�rande.
; retourne:
;   n2  R�sultat de l'op�ration.    
DEFCODE "NOT",3,,NOT ; ( f -- f)
    cp0 T
    bra nz, 1f
    setm T
    bra 9f
1:  clr T
9:  NEXT
    
; DESCRIPTION:
;   Comparaisons alg�briques.
    
; nom: 0=  ( n -- f )
;   V�rifie si n est �gal � z�ro. Retourne un indicateur Bool�en.
; arguments:
;    n   Entier � v�rifier. Est remplac� par l'indicateur Bool�en.
; retourne:
;    f   Indicateur Bool�en, vrai si n==0    
DEFCODE "0=",2,,ZEROEQ  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT

; nom: 0<>  ( n -- f )    
;   V�rifie si n est diff�rent de z�ro. Retourne un indicateur Bool�en.
; arguments:
;    n  Entier � v�rifier. Est remplac� par l'indicateur Bool�en. 
; retourne:
;    f  Indicateur Bool�en, vrai si n<>0   
DEFCODE "0<>",3,,ZERODIFF ; ( n -- f ) 
    clr W0
    cp0 T
    bra z, 9f
    com W0,W0
9:  mov W0,T
    NEXT
    
    
; nom: 0<  ( n -- f )    
;   V�rifie si n est plus petit que z�ro. Retourne un indicateur Bool�en.
; arguments:
;    n  Entier � v�rifier. Est remplac� par l'indicateur Bool�en. 
; retourne:
;    f  Indicateur Bool�en, vrai si n<0.    
DEFCODE "0<",2,,ZEROLT ; ( n -- f ) f= n<0
    add T,T,T
    subb T,T,T
    com T,T
    NEXT

; nom: 0>  ( n -- f )    
;   V�rifie si n est plus grand que z�ro. Retourne un indicateur Bool�en.
; arguments:
;    n  Entier � v�rifier. Est remplac� par l'indicateur Bool�en. 
; retourne:
;    f  Indicateur Bool�en, vrai si n>0.    
DEFCODE "0>",2,,ZEROGT ; ( n -- f ) f= n>0
    clr W0
    cp0 T
    bra le, 8f
    setm W0
8:  mov W0,T    
    NEXT

; nom: =  ( n1 n2 -- f )
;   V�rifie l'�galit� des 2 entiers. Retourne un indicateur Bool�en.
;   Les deux entiers sont consomm�s et remplac�s par l'indicateur.
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:    
;    f  Indicateur Bool�en, vrai si n1==n2.
DEFCODE "=",1,,EQUAL  ; ( n1 n2 -- f ) f= n1==n2
    clr W0
    cp T, [DSP--]
    bra nz, 1f
    setm W0
 1: 
    mov W0,T
    NEXT

; nom: <>  ( n1 n2 -- f )
;   V�rifie si les 2 entiers sont diff�rents. Retourne un indicateur Bool�en.
;   Les deux entiers sont consomm�s et remplac�s par l'indicateur.
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:    
;    f  Indicateur Bool�en, vrai si n1<>n2.
DEFCODE "<>",2,,NOTEQ ; ( n1 n2 -- f ) f = n1<>n2
    clr W0
    cp T, [DSP--]
    bra z, 1f
    com W0,W0
1:  
    mov W0, T
    NEXT
    
; nom: <  ( n1 n2 -- f )
;   V�rifie si n1 < n2. Retourne un indicateur Bool�en.
;   Les deux entiers sont consomm�s et remplac�s par l'indicateur.
;   Il s'agit d'une comparaison sur nombre sign�s.    
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:    
;    f  Indicateur Bool�en, vrai si n1 < n2.    
 DEFCODE "<",1,,LESS  ; ( n1 n2 -- f) f= n1<n2
    setm W0
    cp T,[DSP--]
    bra gt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: > ( n1 n2 -- f )
;   V�rifie si n1 > n2. Retourne un indicateur Bool�en.
;   Les deux entiers sont consomm�s et remplac�s par l'indicateur.
;   Il s'agit d'une comparaison sur nombre sign�s.    
; arguments:
;   n1  Premi�re op�rande.
;   n2  Deuxi�me op�rande.
; retourne:    
;    f  Indicateur Bool�en, vrai si n1 > n2.    
DEFCODE ">",1,,GREATER  ; ( n1 n2 -- f ) f= n1>n2
    setm W0
    cp T,[DSP--]
    bra lt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: U<  ( u1 u2 -- f )
;   V�rifie si u1 < u2. Retourne un indicateur Bool�en.
;   Les deux entiers sont consomm�s et remplac�s par l'indicateur.
;   Il s'agit d'une comparaison sur nombre non sign�s.    
; arguments:
;   u1  Premi�re op�rande.
;   u2  Deuxi�me op�rande.
; retourne:    
;    f  Indicateur Bool�en, vrai si u1 < u2.    
DEFCODE "U<",2,,ULESS  ; (u1 u2 -- f) f= u1<u2
    clr W0
    cp T,[DSP--]
    bra leu, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: U>  ( u1 u2 -- f )
;   V�rifie si u1 > u2. Retourne un indicateur Bool�en.
;   Les deux entiers sont consomm�s et remplac�s par l'indicateur.
;   Il s'agit d'une comparaison sur nombre non sign�s.    
; arguments:
;   u1  Premi�re op�rande.
;   u2  Deuxi�me op�rande.
; retourne:    
;    f  Indicateur Bool�en, vrai si u1 > u2.    
DEFCODE "U>",2,,UGREATER ; ( u1 u2 -- f) f=u1>u2
    clr W0
    cp T,[DSP--]
    bra geu, 1f
    com W0,W0
1:
    mov W0,T
    NEXT


