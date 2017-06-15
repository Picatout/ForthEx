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
; NOM: math.s
; DATE: 2017-05-18
; DESCRIPTION: 
;    Ce module contient les opérateurs arithmétiques, logiques et relationnels.
    

; nom:  MSB  ( -- u )
;   Constante retournant la valeur du bit le plus significatif d'un entier.
; arguments:
;   aucun
; retourne:
;   u   Valeur de l'entier dont seul le bit le plus significatif est à 1.    
DEFCONST "MSB",3,,MSB,0x8000

; nom: MAX-INT  ( -- n )
;   Constante retourant la valeur du plus grand entier signé.
; arguments:
;   aucun
; retourne:
;   n    Valeur du plus grand entier signé.
DEFCONST "MAX-INT",7,,MAXINT,0x7FFF ; 32767
 
; nom: MIN-INT  ( -- n )
;   Constante retournant le plus petit entier signé.
; arguments:
;   aucun
; retourne:
;   n   Plus petit entier signé.    
DEFCONST "MIN-INT",7,,MININT,0x8000 ; -32768

; nom: HEX  ( -- )
;   Initialise la variable système BASE avec la valeur 16. Après l'exécution
;   de ce mot, l'interpréteur condisère que les chaînes converties en nombre
;   sont en base 16 et les nombres à imprimés sont aussi convertis dans cette base.
; arguments:
;   Aucun
; retourne:
;   rien    
DEFWORD "HEX",3,,HEX ; ( -- )
    .word LIT,16,BASE,STORE,EXIT
    
; nom: DECIMAL ( -- )
;   Initialise la variable système BASE avec la valeur 10. Après l'exécution
;   de ce mot, l'interpréteur condisère que les chaînes converties en nombre
;   sont en base 10 et les nombres à imprimés sont aussi convertis dans cette base.
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
;   x2  deuxième entier.
; retourne:
;   x3   somme de x1 et x2  
DEFCODE "+",1,,PLUS
    add T, [DSP--], T
    NEXT
 
; nom: -  ( x1 x2 -- x3 )  x3 = x1-x2
;   Soustrait l'entier x2 de l'entier x1.
; arguments:
;   x1    premier entier.
;   x2    deuxième entier au sommet de la pile.
; retourne:
;   x3    valeur obtenu en soustrayant x2 de x1.    
DEFCODE "-",1,,MINUS 
    mov [DSP--],W0
    sub W0,T,T
    NEXT
    
; nom: 1+  ( x1 -- x2 )  x2=x1+1
;   Incrémente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 incrémenté de 1.
DEFCODE "1+",2,,ONEPLUS ; ( n -- n+1 )
    add #1, T
    NEXT

    
; nom: 2+  ( x1 -- x2 )  x2=x1+2
;   Incrémente de 2 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 incrémenté de 2.
DEFCODE "2+",2,,TWOPLUS
    add #2, T
    NEXT
    
; nom: 1-  ( x1 -- x2 )  x2=x1-1
;   Décrémente de 1 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 décrémenté de 1.
DEFCODE "1-",2,,ONEMINUS
    sub #1, T
    NEXT
    
; nom: 2-  ( x1 -- x2 )  x2=x1-2
;   Décrémente de 2 la valeur au sommet de la pile.
; arguments:
;   x1   Valeur au sommet de la pile des arguments.
; retourne:
;   x2   x1 décrémenté de 2.
DEFCODE "2-",2,,TWOMINUS
    sub #2, T
    NEXT
    
; nom: 2*  ( x1 -- x2 )   x2 = 2*x1
;   Multiplie par 2 la valeur au sommet de la pile des arguments.
; arguments:
;   x1
; retourne:
;   x2    x1 multiplié par 2.    
DEFCODE "2*",2,,TWOSTAR
    add T,T, T
    NEXT
    
; nom: 2/  ( x1 -- x2 ) x2=x1/2
;   Divise par 2 la valeur au sommet de la pile des arguments.
; arguments:
;   x1
; retourne:
;   x2     x2 divisé par 2.    
DEFCODE "2/",2,,TWOSLASH
    asr T,T
    NEXT
    
; nom: LSHIFT  ( x1 u -- x2 )  x2=x1<<u
;   Décale vers la gauche de u bits le nombre x1. Ce qui équivaut à 
;   une multipliation par 2^u.    
; arguments:
;   x1   Nombre qui sera décalé vers la gauche.
;   u    Nombre de bits de décalage.
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
;   Décalage vers la droite de u bits de la valeur x1.
;   Équivaut à une division par 2^u. 
; arguments:
;   x1   Nombre qui sera décalé.
;   u    Nombre de bits de décalage.
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
;   Additionne un entier à la valeur d'une variable.
; arguments:
;    n Entier à ajouter à la valeur de la variable.
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
;   d2  Deuxième enteier double.
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
;   d2  Deuxième entier double.
; retourne:
;   d3  Entier double résultant de la soustration d1-d2.    
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
;   Addition d'un entier simple à un entier double.
; arguments:
;   d1  Entier double.
;   n   Entier simple.
; retourne:
;   d2  Entier double résultant de d1+n    
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
;   Multiplication signée de 2 entiers simple.
; arguments:
;   n1   Premier entier.
;   n2   Deuxième entier.
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
;   n2  Deuxième entier simple.
; retourne:
;   d  Entier double résultant du produit de n1*n2.    
DEFCODE "M*",2,,MSTAR ; ( n1 n2 -- d )
    mul.ss T,[DSP],W0
    mov W0,[DSP]
    mov W1,T
    NEXT

; nom: UM*  ( u1 u2 -- ud )   ud=u1*u2    
;   Muttiplication non signée de 2 entiers simple résultant en un entier double non signé.
; arguments:
;   u1  premier entier simple non signé.
;   u2  deuxième entier simple non signé.
; retourne:
;   ud  Entier double non signé.    
DEFCODE "UM*",3,,UMSTAR ; ( u1 u2 -- ud )
    mul.uu T,[DSP],W0
    mov W1,T
    mov W0,[DSP]
    NEXT
   
; nom: UD*  ( ud1 u2 -- ud3 )  ud3=ud1*u2    
;   Multiplication non signée d'un entier double par un entier simple.
; arguments:
;   ud1  Entier double non signé.    
;    u2  Entier simple non signé.
; retourne:    
;   ud3  Entier double non signé résultant du produit de ud1 u2.  
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
;   Division entière signée sur nombres simple.
; arguments:
;   n1  Numérateur 
;   n2  Dénominateur
; retourne:
;   n3  Quotient entier.    
DEFCODE "/",1,,SLASH
    mov [DSP--],W0
    repeat #17
    div.s W0,T
    mov W0,T
    NEXT

; nom: MOD  ( n1 n2 -- n3 )  n3=n1%n2    
;    Division entière de 2 entiers simple où seul le restant est conservé.
; arguments:
;    n1  Numérateur
;    n2  Dénominateur
; retourne:
;    n3   Reste de la division.    
DEFCODE "MOD",3,,MOD 
   mov [DSP--],W0
   repeat #17
   div.s W0,T
1: mov W1,T
   NEXT
   
; nom: */  ( n1 n2 n3 -- n4 ) n4=(n1*n2)/n3   
;   Une multiplication de n1 par n2 est suivit d'une division du résultat par n3.
;   Le produit de n1 et n2 est conservé comme entier double avant la division.
; arguments:
;    n1 Premier entier simple.
;    n2 Deuxième entier simple.
;    n3 Troisième entier simple.
; retourne:
;    n4  Entier simple résultant de la division du double n1*n2 par n3.   
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
;   et le reste sont conservés. Le résultat intermédiaire de la multipllication
;   est un entier double.
; arguments:
;   n1  Premier entier simple.
;   n2  Deuxième entier simple.
;   n3  Troisième entier simple.
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
;   Division signée de n1 par n2 , le reste et le quotient sont conservés.    
; arguments:
;   n1  Numérateur
;   n2  Dénominateur
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
;   Division d'un entier double non signé
;   par un entier simple non signé
;   résulant en un quotient et reste simple.
; arguments:    
;   ud   Entier double non signé, numérateur.
;   u1   Entier simple non signé, dénominateur.
; retourne:    
;   u2 Entier simple non signé, Reste
;   u3 Entier simple non signé, Quotient    
DEFCODE "UM/MOD",6,,UMSLASHMOD 
    mov [DSP--],W1
    mov [DSP--],W0
    repeat #17
    div.ud W0,T
    mov W0,T
    mov W1,[++DSP]
    NEXT
    
; nom: UD/MOD  ( ud1 u1 -- u2 ud2 )    
;   Division d'un entier double non signé
;   par un entier simple non signé résultant
;   en un quotient double et un reste simple
; arguments:
;   ud1   Entier double non signé, numérateur.
;    u1   Entier simple non signé, dénominateur.
; résultat:
;   u2	Entier simple non signé, reste.
;   ud2 Entier double non signé, quotient.    
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
;   Retourne le plus grand des 2 entier signés.
; arguments:
;   n1 Premier entier
;   n2 Deuxième entier
; retourne:
;   n  Le plus grand des 2 entiers signés.    
DEFCODE "MAX",3,,MAX 
    mov [DSP--],W0
    cp T,W0
    bra ge, 1f
    exch T,W0
1:  NEXT    
    
    
; nom: MIN  ( n1 n2 -- n ) n=min(n1,n2) 
;   Retourne le plus petit des 2 entiers signés.
; arguments:
;   n1 Premier entier
;   n2 Deuxième entier
; retourne:
;   n  Le plus petit des 2 entiers signés.    
DEFCODE "MIN",3,,MIN
    mov [DSP--],W0
    cp W0,T
    bra ge, 1f
    exch T,W0
1:  NEXT
    
; nom: UMAX  ( u1 u2 -- u ) u=max(u1,u2) 
;   Retourne le plus grand des 2 entiers non signés.
; arguments:
;   u1 Premier entier non signé.
;   u2 Deuxième entier non signé.
; retourne:
;   u  Le plus grand des 2 entiers non signés.    
DEFCODE "UMAX",4,,UMAX
    mov [DSP--],W0
    cp T,W0
    bra geu,1f
    exch W0,T
1:  NEXT
    
; nom: UMIN  ( u1 u2 -- u ) u=min(u1,u2) 
;   Retourne le plus petit des 2 entiers non signés.
; arguments:
;   u1 Premier entier non signé.
;   u2 Deuxième entier non signé.
; retourne:
;   u  Le plus petit des 2 entiers non signés.    
DEFCODE "UMIN",4,,UMIN
    mov [DSP--],W0
    cp W0,T
    bra geu, 1f
    exch T,W0
1:  NEXT
    
; nom: WITHIN  ( n1|u1 n2|u2 n3|u3 -- f ) 
;   Vérifie si l'entier n1|u1<=n2|u2<n3|u3.
;   La vérification doit fonctionner aussi bien avec les entiers
;   signés et non signés.    
; arguments:
;   n1|u1   Entier à vérifier,signé ou non.
;   n2|u2   Borne inférieure fermée,signé ou non.
;   n3|u3   Borne supérieure ouverte, signé ou non. 
; retourne:
;   f    Indicateur booléen vrai si condition n1|u1<=n2|u2<n3|u3.    
DEFCODE "WITHIN",6,,WITHIN  
    mov T,W0   
    DPOP
    sub W0,T,[RSP++]
    mov [DSP],W0
    sub W0,T,[DSP]
    mov [--RSP],T
    bra code_ULESS

; nom: EVEN  ( n -- f )
;   Retourne un indicateur booléen vrai si l'entier est pair.
; arguments:
;   n   Entier à vérifier.
; retourne:
;   f  Indicateur booléen, vrai si entier pair.    
DEFCODE "EVEN",4,,EVEN ; ( n -- f ) vrai si n pair
    setm W0
    btsc T,#0
    clr W0
    mov W0,T
    NEXT
    
; nom: ODD  ( n -- f )
;   Retourne un indicateur booléen vrai si l'entier est impair.
; arguments:
;   n   Entier à vérifier.
; retourne:
;   f   Indicateur booléen, vrai si entier impair.    
DEFCODE "ODD",3,,ODD
    setm W0
    btss T,#0
    clr W0
    mov W0,T
    NEXT

; nom: ABS  ( n1 -- n2 ) 
;   Retourne la valeur absolue d'un entier simple.
; arguments:
;   n1    Entier simple signé.
; retourne:
;  n2  La valeur absolue de n1.    
DEFCODE "ABS",3,,ABS
    btsc T,#15
    neg T,T
    NEXT

; nom: DABS ( d1 -- d2 )    
;   Retourne la valeur absolue d'un entier double.
; arguments:
;    d1   Entier double signé.
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
;   n    Entier simple signé.
; retourne:
;   d    Entier double signé.    
DEFCODE "S>D",3,,STOD ; ( n -- d ) 
    DPUSH
    clr W0
    btsc T,#15
    com W0,W0
    mov W0,T
    NEXT

; nom: ?NEGATE  ( n1 n2 -- n3 )
;   Inverse n1 si n2 est négatif.
; arguments:
;   n1   Entier simple signé.
;   n2   Entier simple signé, valeur de contrôle.
; retourne:
;   n3   Entier simple, n2<0?-n1:n1    
DEFCODE "?NEGATE",7,,QNEGATE
    mov T,W0
    DPOP
    btsc W0,#15
    neg T,T
    NEXT    

; nom: SM/REM    ( d1 n1 -- n2 n3 )    
;   Division symétrique entier double par simple arrondie vers zéro.
;   REF: http://lars.nocrew.org/forth2012/core/SMDivREM.html    
;   Adapté de Camel Forth pour MSP430.
; arguments:
;    d1   Entier double signé, numérateur.
;    n1   Entier simple signé, dénominateur.
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
;   Adapté de Camel Forth pour MSP430.
; arguments:
;    d1   Entier double signé, numérateur.
;    n1   Entier simple signé, dénominateur.
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
;   Incrémente une variable résidante en mémoire EDS.
; arguments:
;   a-addr   Adresse de la variable.
; retourne:
;   rien     
DEFWORD "EVAR+",5,,EVARPLUS 
    .word DUP,EFETCH,ONEPLUS,SWAP,STORE,EXIT
    
; nom: EVAR- ( a-addr -- )    
;   Décrémente une variable résidante en mémoire EDS.
; arguments:    
;    a-addr  Adresse de la variable.
; retourne:
;    rien    
DEFWORD "EVAR-",5,,EVARMINUS ; ( addr -- )
    .word DUP,EFETCH,ONEMINUS,SWAP,STORE,EXIT
    
    
; nom: UDREL  ( ud1 ud2 -- n )    
;   Compare 2 nombres double non signés et retourne un indicateur de relation.
;   n = 1 si ud1>ud2
;   n = 0 si ud1==ud2
;   n = -1 si ud1<ud2
; arguments:
;   ud1   Premier entier double non signé.
;   ud2   Deuxième entier double non signé.
; retourne:
;    n    Résultat de la comparaison.    
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
;   Inverse arithmétique de n1. Complément de 2.
; arguments:
;   n1   Entier à inversé.
; retourne:
;   n2   n2=-n1    
DEFCODE "NEGATE",6,,NEGATE ; ( n - n ) complément à 2
    neg T, T
    NEXT
    
; nom: DNEGATE ( d1 -- d2 )
;   Inverse arithmétique d'un entier double. Complément de 2.
; arguments:
;    d1   Entier double à inversé.
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
;   Inversion des bits, complément de 1.
; arguments:
;   n1   Entier simple.
; retourne:
;   n2   Inverse bit à bit de n1.    
DEFCODE "INVERT",6,,INVERT ; ( n -- n ) inversion des bits
    com T, T
    NEXT
    
; nom: DINVERT   ( d1 -- d2 ))
;   Invesion bit à bit d'un entier double. Complément de 1.
; arguments:
;   d1   Entier double.
; retourne:
;   d2   Inverse bit à bit de d1.    
DEFCODE "DINVERT",7,,DINVERT
    com T,T
    com [DSP],[DSP]
    NEXT
    
; DESCRIPTION:
;    opérations logiques bit à bit.
    
; nom: AND  ( n1 n2 -- n3 )
;   Opération Booléenne bit à bit ET.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:
;   n3  Résultat de l'opération.    
DEFCODE "AND",3,,AND 
    and T,[DSP--],T
    NEXT
    
; nom: OR  ( n1 n2 -- n3 )
;   Opération Booléenne bit à bit OU inclusif.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:
;   n3  Résultat de l'opération.    
DEFCODE "OR",2,,OR
    ior T,[DSP--],T
    NEXT
    
; nom: XOR  ( n1 n2 -- n3 )
;   Opération Booléenne bit à bit OU exclusif.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:
;   n3  Résultat de l'opération.    
DEFCODE "XOR",3,,XOR
    xor T,[DSP--],T
    NEXT
    
; nom: NOT  ( n1 -- n2 )
;   Opération Booléenne de négation.
;   Si n1==0  n2=-1.
;   Si n1<>0  n2=0.    
; arguments:
;   n1  Opérande.
; retourne:
;   n2  Résultat de l'opération.    
DEFCODE "NOT",3,,NOT ; ( f -- f)
    cp0 T
    bra nz, 1f
    setm T
    bra 9f
1:  clr T
9:  NEXT
    
; DESCRIPTION:
;   Comparaisons algébriques.
    
; nom: 0=  ( n -- f )
;   Vérifie si n est égal à zéro. Retourne un indicateur Booléen.
; arguments:
;    n   Entier à vérifier. Est remplacé par l'indicateur Booléen.
; retourne:
;    f   Indicateur Booléen, vrai si n==0    
DEFCODE "0=",2,,ZEROEQ  ; ( n -- f )  f=  n==0
    sub #1,T
    subb T,T,T
    NEXT

; nom: 0<>  ( n -- f )    
;   Vérifie si n est différent de zéro. Retourne un indicateur Booléen.
; arguments:
;    n  Entier à vérifier. Est remplacé par l'indicateur Booléen. 
; retourne:
;    f  Indicateur Booléen, vrai si n<>0   
DEFCODE "0<>",3,,ZERODIFF ; ( n -- f ) 
    clr W0
    cp0 T
    bra z, 9f
    com W0,W0
9:  mov W0,T
    NEXT
    
    
; nom: 0<  ( n -- f )    
;   Vérifie si n est plus petit que zéro. Retourne un indicateur Booléen.
; arguments:
;    n  Entier à vérifier. Est remplacé par l'indicateur Booléen. 
; retourne:
;    f  Indicateur Booléen, vrai si n<0.    
DEFCODE "0<",2,,ZEROLT ; ( n -- f ) f= n<0
    add T,T,T
    subb T,T,T
    com T,T
    NEXT

; nom: 0>  ( n -- f )    
;   Vérifie si n est plus grand que zéro. Retourne un indicateur Booléen.
; arguments:
;    n  Entier à vérifier. Est remplacé par l'indicateur Booléen. 
; retourne:
;    f  Indicateur Booléen, vrai si n>0.    
DEFCODE "0>",2,,ZEROGT ; ( n -- f ) f= n>0
    clr W0
    cp0 T
    bra le, 8f
    setm W0
8:  mov W0,T    
    NEXT

; nom: =  ( n1 n2 -- f )
;   Vérifie l'égalité des 2 entiers. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacés par l'indicateur.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen, vrai si n1==n2.
DEFCODE "=",1,,EQUAL  ; ( n1 n2 -- f ) f= n1==n2
    clr W0
    cp T, [DSP--]
    bra nz, 1f
    setm W0
 1: 
    mov W0,T
    NEXT

; nom: <>  ( n1 n2 -- f )
;   Vérifie si les 2 entiers sont différents. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacés par l'indicateur.
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen, vrai si n1<>n2.
DEFCODE "<>",2,,NOTEQ ; ( n1 n2 -- f ) f = n1<>n2
    clr W0
    cp T, [DSP--]
    bra z, 1f
    com W0,W0
1:  
    mov W0, T
    NEXT
    
; nom: <  ( n1 n2 -- f )
;   Vérifie si n1 < n2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacés par l'indicateur.
;   Il s'agit d'une comparaison sur nombre signés.    
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen, vrai si n1 < n2.    
 DEFCODE "<",1,,LESS  ; ( n1 n2 -- f) f= n1<n2
    setm W0
    cp T,[DSP--]
    bra gt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: > ( n1 n2 -- f )
;   Vérifie si n1 > n2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacés par l'indicateur.
;   Il s'agit d'une comparaison sur nombre signés.    
; arguments:
;   n1  Première opérande.
;   n2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen, vrai si n1 > n2.    
DEFCODE ">",1,,GREATER  ; ( n1 n2 -- f ) f= n1>n2
    setm W0
    cp T,[DSP--]
    bra lt, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: U<  ( u1 u2 -- f )
;   Vérifie si u1 < u2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacés par l'indicateur.
;   Il s'agit d'une comparaison sur nombre non signés.    
; arguments:
;   u1  Première opérande.
;   u2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen, vrai si u1 < u2.    
DEFCODE "U<",2,,ULESS  ; (u1 u2 -- f) f= u1<u2
    clr W0
    cp T,[DSP--]
    bra leu, 1f
    com W0,W0
1:
    mov W0, T
    NEXT
    
; nom: U>  ( u1 u2 -- f )
;   Vérifie si u1 > u2. Retourne un indicateur Booléen.
;   Les deux entiers sont consommés et remplacés par l'indicateur.
;   Il s'agit d'une comparaison sur nombre non signés.    
; arguments:
;   u1  Première opérande.
;   u2  Deuxième opérande.
; retourne:    
;    f  Indicateur Booléen, vrai si u1 > u2.    
DEFCODE "U>",2,,UGREATER ; ( u1 u2 -- f) f=u1>u2
    clr W0
    cp T,[DSP--]
    bra geu, 1f
    com W0,W0
1:
    mov W0,T
    NEXT


