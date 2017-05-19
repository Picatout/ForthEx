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

; NOM: strings.s
; DATE: 2017-04-16
; DESCRIPTION: manipulation des chaînes de caractères.
  
; nom: -TRAILING  ( c-addr u1 -- c-addr u2 )    
;   Remplace tous les caractères <=32 à la fin d'une chaîne par des zéro.
; arguments:
;   c-addr  adresse du début de la châine.    
;   u1 longueur initiale de la chaîne.
; retourne:    
;   u2 longueur finale de la chaîne.    
DEFCODE "-TRAILING",9,,MINUSTRAILING ; ( addr u1 -- addr u2 )
    SET_EDS
    cp0 T
    mov [DSP],W1
    add W1,T,W1
    mov #33,W0
1:  cp0 T
    bra z,9f
    dec T,T
    dec W1,W1
    cp.b W0,[W1]
    bra gtu, 1b
2:  inc T,T
9:  RESET_EDS
    NEXT
 
; nom: /STRING  ( c-addr u n -- c-addr' u' )   
;   Avance c-addr de n caractères et réduit u d'autant.
; arguments:
;   c-addr   adresse initiale
;   u        longueur de la zone
;   n        nombre de caractères à avancer.
; retourne:
;   c-addr'    c-addr+n
;   u'         u-n    
DEFWORD "/STRING",7,,SLASHSTRING 
    .word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

    
; nom: CMOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc d'octets RAM.  
;   Débute la opie à l'adresse la plus basse.
; arguments:
;   c-addr1  source
;   c-addr2  destination
;   u      compte en octets.   
; retourne:
;   rien    
DEFCODE "CMOVE",5,,CMOVE  ;( c-addr1 c-addr2 u -- )
move_up:
    SET_EDS
    mov T, W0 ; compte
    DPOP
    mov T, W1 ; destination
    DPOP
    cp0 W0
    bra z, 1f
    dec W0,W0
    repeat W0
    mov.b [T++],[W1++]
1:  DPOP
    RESET_EDS
    NEXT

; nom: CMOVE>  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc d'octets RAM  
;   La copie débute à l'adresse la plus haute.    
; arguments:
;   c-addr1  source
;   c-addr2  destination
;   u      compte en octets.   
; retourne:
;   rien    
DEFCODE "CMOVE>",6,,CMOVETO ; ( c-addr1 c-addr2 u -- )
move_dn:
    SET_EDS
    mov T, W0
    DPOP
    mov T,W1
    add W0,W1,W1
    DPOP
    add W0,T,T
    cp0 W0
    bra z, 1f
    dec W0,W0
    repeat W0
    mov.b [--T],[--W1]
1:  DPOP
    RESET_EDS
    NEXT
    
    
; nom: EC@+   ( c-addr -- c-addr' c )   
;   Retourne le caractère à l'adresse et avance l'adresse d'un caractère
;   à utiliser si addr pointe vers mémoire EDS    
;  arguments:
;	c-addr  adresse où se trouve le caractère recherché.
;  retourne:
;     addr+1   adresse avancée d'un caractère
;     c        caractère obtenu    
DEFWORD "EC@+",5,,ECFETCHPLUS
    .word DUP,ECFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; nom: C@+   ( c-addr -- c-addr' c )    
;   Retourne le caractère à l'adresse c-addr et avance le pointeur au caractère suivant.
;  arguments:
;   c-addr  pointeur sur le caractère.
;  retourne:
;   c-addr'   adresse avancée d'un caractère
;     c       caractère obtenu    
DEFWORD "C@+",4,,CFETCHPLUS
    .word DUP,CFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; nom: CSTR>RAM ( c-addr1 c-addr2 -- )     
;   Copie une chaine comptée de la mémoire FLASH vers la mémoire RAM.
; arguments:
;   c-addr1    adresse de la chaîne en mémoire flash.
;   c-addr2    adresse destination en mémoire RAM.
; retourne:
;   rien    
DEFWORD "CSTR>RAM",8,,CSTRTORAM 
    .word TOR, DUP,CFETCH,ONEPLUS,RFROM,NROT ; s: c-addr2 c-addr1 n
    .word LIT,0,DODO ; s: addr2 addr1
2:  .word CFETCHPLUS,SWAP,TOR,OVER,CSTORE,CHARPLUS,RFROM
    .word DOLOOP,2b-$
    .word TWODROP,EXIT
    
; nom: STR=    ( c-addr1 c-addr2 -- f )    
;   Comparaison de 2 chaînes comptée. Retourne VRAI si égales sinon FAUX.
;   Les 2 chaînes doivent-être en mémoire RAM.
; arguments:
;   c-addr1   descripteur chaîne 1
;   c-addr2   descriptieur chaîne 2
; retourne:
;   f	  Indicateur Booléen d'égalité.    
DEFWORD "STR=",4,,STREQUAL ; ( addr1 addr2 -- f )
    .word TOR,ECFETCH,RFROM,ECFETCH
    .word ROT,OVER,EQUAL,ZBRANCH,6f-$
    .word LIT,0,DODO
2:  .word TOR,ECFETCHPLUS,RFROM,ECFETCHPLUS
    .word ROT,EQUAL,ZBRANCH,4f-$
    .word DOLOOP,2b-$ 
    .word TWODROP,LIT,-1,EXIT
4:  .word UNLOOP,BRANCH,8f-$
6:  .word DROP
8:  .word TWODROP,LIT,0    
9:  .word EXIT

; nom: BLANK  ( c-addr u -- )
;   Si u est plus grand que zéro met 7 caractères espace (BL) à partir de l'adresse c-addr
; arguments:
;   c-addr  Adresse début RAM
;   u       nombre d'espaces à déposer dans cette région.
; retourne:
;   rien
DEFCODE "BLANK",5,,BLANK
    cp0 T
    bra z, 9f
    dec T,T
    mov #32,W0
    mov [DSP],W1
    repeat T
    mov.b W0,[W1++]
9:  DPOP
    DPOP
    NEXT
 
; nom: COMPARE ( c-addr1 u1 c-addr2 u2 -- -1|0|1 )
;   Compare la chaîne de caractère débutant à l'adresse c-addr1de longueur u1
;   avec la chaîne de caractère débutant à l'adresse c-addr2 de longueur u2
;   Cette comparaison de fait selon l'orde des caractères dans la table ASCII.
;   Si u1==u2 et que tous les caractères correspondent la valeur 0 est retournée,
;   sinon le premier caractère qui diverge détermine la valeur retournée c1<c2 retourne -1 autrement retourne 1.    
;   Si u1<u2 et que tous les caractères de cette chaîne sont en correspondance avec
;   l'autre chaîne la valeur -1 est retournée.
;   Si u1>u2 et que tous les caractères de c-addr2 correspondent avec ceux de c-addr1
;   la valeur 1 est retournée.
; arguments:
;   c-addr1  Adresse du premier caractère de la chaîne 1
;   u1       Longueur de la chaîne 1.
;   c-addr2  Adresse du premier caractère de la chaîne 2.
;   u2       longueur de la chaîne 2.
DEFWORD "COMPARE",7,,COMPARE
    .word ROT,TWODUP,TWOTOR,UMIN,LIT,0,DODO ; s: c-addr1 c-addr2 r: u2 u1
1:  .word TOR,ECFETCHPLUS,RFROM,ECFETCHPLUS,ROT,TWODUP,EQUAL,ZBRANCH,8f-$
    .word TWODROP,DOLOOP,1b-$
    .word TWODROP,TWORFROM ; S: u2 u1
    .word TWODUP,EQUAL,ZBRANCH,2f-$,TWODROP,LIT,0,EXIT
2:  .word UGREATER,ZBRANCH,4f-$,TRUE,EXIT
4:  .word LIT,1,EXIT
8:  .word RDROP,RDROP,TWOSWAP,TWODROP,ULESS,ZBRANCH,9f-$,LIT,-1,EXIT
9:  .word LIT,1,EXIT
  

; nom: SEARCH  ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 f )
;   Recherche la chaîne 2 dans la chaîne 1. Si f est vrai c'est que la chaîne 2
;   est sous-chaîne de la chaîne 1, alors c-addr3 u3 indique la position et le 
;   nombre de caractères restants. En cas d'échec c-addr3==c-addr1 et u3==u1.
; arguments:
;   c-addr1  Adresse du premier carcactère de la chaîne cible.
;   u1       Longueur de la chaîne cible.
;   c-addr2  Adresse du premier caractère de la sous-chaîne recherchée.
;   u2       Longueur de la sous-chaîne recherchée.
DEFWORD "SEARCH",6,,SEARCH 
    .word TWODROP,LIT,0,EXIT

; nom: SLITERAL ( c-addr u -- )
;   Mot immédiat à n'utiliser qu'à l'intérieur d'une définition.
;   Compile une chaîne litérale dont le descripteur est sur la pile des arguments.
;   A l'exécution le descripteur est empilée.    
; arguments:
;   c-addr  Adresse du premier caractère de la chaîne.
;   u       Longueur de la chaîne.
; retourne:
;    rien
DEFWORD "SLITERAL",8,F_IMMED,SLITERAL
    .word QCOMPILE,SWAP,CFA_COMMA,LIT,COMMA,CFA_COMMA,LIT,COMMA,EXIT
    
    