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
; DESCRIPTION: manipulation des cha�nes de caract�res.
  
; nom: -TRAILING  ( c-addr u1 -- c-addr u2 )    
;   Remplace tous les caract�res <=32 � la fin d'une cha�ne par des z�ro.
; arguments:
;   c-addr  adresse du d�but de la cha�ne.    
;   u1 longueur initiale de la cha�ne.
; retourne:    
;   u2 longueur finale de la cha�ne.    
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
;   Avance c-addr de n caract�res et r�duit u d'autant.
; arguments:
;   c-addr   adresse du premier caract�re de la cha�ne.
;   u        longueur de la cha�ne.
;   n        nombre de caract�res � avancer.
; retourne:
;   c-addr'    c-addr+n
;   u'         u-n    
DEFWORD "/STRING",7,,SLASHSTRING 
    .word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

    
; nom: CMOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc d'octets RAM.  
;   D�bute la copie � partir de l'adresse du d�but du bloc en adresse croissante.
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
;   La copie d�bute � la fin du bloc en adresses d�croissantes.    
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
;   Retourne le caract�re � l'adresse point�e par c-addr et avance le pointeur au caract�re suivant.
;   � utiliser si c-addr pointe vers la m�moire RAM et EDS.    
;  arguments:
;	c-addr  Pointeur sur la cha�ne de caract�res.
;  retourne:
;     addr+1   Pointeur avanc�e d'un caract�re
;     c        caract�re obtenu    
DEFWORD "EC@+",5,,ECFETCHPLUS
    .word DUP,ECFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; nom: C@+   ( c-addr -- c-addr' c )    
;   Retourne le caract�re � l'adresse point�e par c-addr et avance le pointeur au caract�re suivant.
;   � utiliser si c-addr pointe la m�moire ou FLASH.
;  arguments:
;   c-addr  pointeur sur la cha�ne de caract�res.
;  retourne:
;   c-addr'   Pointeur avanc�e d'un caract�re
;     c       caract�re obtenu    
DEFWORD "C@+",4,,CFETCHPLUS
    .word DUP,CFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; nom: CSTR>RAM ( c-addr1 c-addr2 -- )     
;   Copie une chaine compt�e de la m�moire FLASH vers la m�moire RAM.
; arguments:
;   c-addr1    adresse de la cha�ne en m�moire flash.
;   c-addr2    adresse destination en m�moire RAM.
; retourne:
;   rien    
DEFWORD "CSTR>RAM",8,,CSTRTORAM 
    .word TOR, DUP,CFETCH,ONEPLUS,RFROM,NROT ; s: c-addr2 c-addr1 n
    .word FALSE,DODO ; s: addr2 addr1
2:  .word CFETCHPLUS,SWAP,TOR,OVER,CSTORE,CHARPLUS,RFROM
    .word DOLOOP,2b-$
    .word TWODROP,EXIT
    
; nom: S=    ( c-addr1 u1 c-addr2 u2 -- f )    
;   Comparaison de 2 cha�nes. Retourne VRAI si �gales sinon FAUX.
;   Les 2 cha�nes doivent-�tre en m�moire RAM.
; arguments:
;   c-addr1   Adresse du premier caract�re de la cha�ne 1
;   u1        longueur de la cha�ne 1    
;   c-addr2   Adresse du premier caract�re de la cha�ne 2
;   u2        longueur de la cha�ne 2    
; retourne:
;   f	  Indicateur Bool�en d'�galit�.    
DEFWORD "S=",2,,SEQUAL ; ( c-addr1 u1 c-addr2 u2 -- f )
    .word ROT,OVER,EQUAL,ZBRANCH,6f-$
    .word FALSE,DODO
2:  .word TOR,ECFETCHPLUS,RFROM,ECFETCHPLUS
    .word ROT,EQUAL,ZBRANCH,4f-$
    .word DOLOOP,2b-$ 
    .word TWODROP,TRUE,EXIT
4:  .word UNLOOP,BRANCH,8f-$
6:  .word DROP
8:  .word TWODROP,FALSE  
9:  .word EXIT

; nom: BLANK  ( c-addr u -- )
;   Si u est plus grand que z�ro met u caract�res espace (BL) � partir de l'adresse c-addr
; arguments:
;   c-addr  Adresse d�but RAM
;   u       nombre d'espaces � d�poser dans cette r�gion.
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
;   Compare la cha�ne de caract�re d�butant � l'adresse c-addr1de longueur u1
;   avec la cha�ne de caract�re d�butant � l'adresse c-addr2 de longueur u2
;   Cette comparaison de fait selon l'orde des caract�res dans la table ASCII.
;   Si u1==u2 et que tous les caract�res correspondent la valeur 0 est retourn�e,
;   sinon le premier caract�re qui diverge d�termine la valeur retourn�e c1<c2 retourne -1 autrement retourne 1.    
;   Si u1<u2 et que tous les caract�res de cette cha�ne sont en correspondance avec
;   l'autre cha�ne la valeur -1 est retourn�e.
;   Si u1>u2 et que tous les caract�res de c-addr2 correspondent avec ceux de c-addr1
;   la valeur 1 est retourn�e.
; arguments:
;   c-addr1  Adresse du premier caract�re de la cha�ne 1
;   u1       Longueur de la cha�ne 1.
;   c-addr2  Adresse du premier caract�re de la cha�ne 2.
;   u2       longueur de la cha�ne 2.
DEFWORD "COMPARE",7,,COMPARE
    .word ROT,TWODUP,TWOTOR,UMIN,FALSE,DODO ; s: c-addr1 c-addr2 r: u2 u1
1:  .word TOR,ECFETCHPLUS,RFROM,ECFETCHPLUS,ROT,TWODUP,EQUAL,ZBRANCH,8f-$
    .word TWODROP,DOLOOP,1b-$
    .word TWODROP,TWORFROM ; S: u2 u1
    .word TWODUP,EQUAL,ZBRANCH,2f-$,TWODROP,FALSE,EXIT
2:  .word UGREATER,ZBRANCH,4f-$,TRUE,EXIT
4:  .word LIT,1,EXIT
8:  .word RDROP,RDROP,TWOSWAP,TWODROP,ULESS,ZBRANCH,9f-$,TRUE,EXIT
9:  .word LIT,1,EXIT
  

; nom: SEARCH  ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 f )
;   Recherche la cha�ne 2 dans la cha�ne 1. Si f est vrai c'est que la cha�ne 2
;   est sous-cha�ne de la cha�ne 1, alors c-addr3 u3 indique la position et le 
;   nombre de caract�res restants. En cas d'�chec c-addr3==c-addr1 et u3==u1.
;   exemple:
;     : s1 s" A la claire fontaine."
;     : s2 s" claire"
;     s1 s2 SEARCH   /  c-addr3=c-addr1+5 u3=16  f=VRAI  
; arguments:
;   c-addr1  Adresse du premier carcact�re de la cha�ne cible.
;   u1       Longueur de la cha�ne cible.
;   c-addr2  Adresse du premier caract�re de la sous-cha�ne recherch�e.
;   u2       Longueur de la sous-cha�ne recherch�e.
; retourne:
;   c-addr3  si f est VRAI  Adresse du premier caract�re de la sous-cha�ne, sinon = c-addr1
;   u3       si f est VRAI nombre de caract�re restant dans la cha�ne � partir de c-addr3
;   f        Indicateur Bool�en succ�s/�chec.  
DEFWORD "SEARCH",6,,SEARCH ; ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 f )
    ; si s2 plus long que s1 retourne faux.
    .word TWOTOR,TWODUP,TWORFROM ; s: c-addr1 u1 c-addr3 u1 c-addr2 u2
    .word ROT,OVER,MINUS,DUP,ZEROLT,ZBRANCH,2f-$
    ; s1 trop court pour contenir s2
    .word TWODROP,TWODROP,FALSE,EXIT ; s: c-addr1 u1 0
2:  .word ONEPLUS,FALSE,DODO ; s: c-addr1 u1 c-addr3 c-addr2 u2
4:  .word TWOTOR,DUP,RFETCH,TWORFETCH,SEQUAL ; s: c-addr1 u1 c-addr3 f r: c-addr2 u2 
    .word ZBRANCH,6f-$
    ; sous-cha�ne trouv�e. s: c-addr1 u1 c-addr3 r: c-addr2 u2
    .word RDROP,RDROP,UNLOOP,DUP,TOR,ROT,MINUS,MINUS,RFROM,SWAP,TRUE,EXIT ; c-addr3 u3 -1
6:  .word CHARPLUS,TWORFROM,DOLOOP,4b-$,TWODROP,DROP,FALSE  ; s: c-addr1 u1 0  
    .word EXIT

    
; nom: SLITERAL ( c-addr u -- )
;   Mot imm�diat � n'utiliser qu'� l'int�rieur d'une d�finition.
;   Compile une cha�ne lit�rale dont le descripteur est sur la pile des arguments.
;   A l'ex�cution le descripteur est empil�e.    
; arguments:
;   c-addr  Adresse du premier caract�re de la cha�ne.
;   u       Longueur de la cha�ne.
; retourne:
;    rien
DEFWORD "SLITERAL",8,F_IMMED,SLITERAL
    .word QCOMPILE,SWAP,CFA_COMMA,LIT,COMMA,CFA_COMMA,LIT,COMMA,EXIT
    
    