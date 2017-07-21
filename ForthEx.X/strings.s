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
; DESCRIPTION: 
;    Manipulation des cha�nes et des caract�res.
;    ForthEx utilise les caract�res ASCII.
;    REF: http://www.asciitable.com/
   
; DESCRIPTIONS:
;  Mots qui manipulent des caract�res.

; nom: BL  ( -- c )
;   Constante qui retourne la valeur ASCII 32 (espace).
; arguments:
;   aucun
; retourne:
;   c  Valeur ASCII 32  qui repr�sente l'espace.    
DEFCODE "BL",2,,BL
    DPUSH
    mov #32,T
    NEXT

; nom: >CHAR  ( n -- c )    
;   V�rifie que 'n' est dans l'intervalle ASCII 32..126, sinon remplace c par '_'  
; arguments:
;   n Entier � convertir en caract�re.
; retourne:
;   c Valeur ASCII entre 32 et 126    
DEFCODE ">CHAR",5,,TOCHAR 
    cp.b T,#32
    bra ltu,1f
    cp.b T,#127
    bra ltu, 2f
1:  mov #'_',T
2:  NEXT
 
; nom: CHARS   ( n1 -- n2 )    
;   Retourne l'espace occup�e par n caract�res en octets.
;   Puisque ForthEx utilise les caract�res ASCII et que ceux-ci occupe 1 seul octet
;   n1==n2.    
; arguments:
;   n1  Nombre de caract�res
; retourne:
;   n2  Espace requis pour n1 caract�res.    
DEFWORD "CHARS",5,,CHARS ; ( n1 -- n2 )
9:  .word LIT,CHAR_SIZE,STAR,EXIT
   
; nom: CHAR+   ( c-addr -- c-addr' )  
;   Incr�mente l'adresse de l'espace occup� par un caract�re.
; arguments:
;   c-addr  Adresse align�e sur un caract�re.
; retourne:
;   c-addr' Adresse align�e sur caract�re suivant.  
DEFWORD "CHAR+",5,,CHARPLUS ; ( addr -- addr' )  
    .word LIT,CHAR_SIZE,PLUS,EXIT
  
; nom: CHAR   ( cccc S: -- c )    
;   Recherche le prochain mot dans le flux d'entr�e et empile le premier caract�re de ce mot.
;   A la suite de cette op�ration la variable >IN pointe apr�s le mot.    
; arguments:
;    cccc  Cha�ne de caract�re dans le flux d'entr�.
; retourne:
;    c  Le premier caract�re du mot extrait du flux d'entr�e.
DEFWORD "CHAR",4,,CHAR ; cccc ( -- c )
    .word BL,WORD,DUP,CFETCH,ZEROEQ
    .word QABORT
    .byte 16
    .ascii "missing caracter"
    .align 2
    .word ONEPLUS,CFETCH,EXIT

; nom: [CHAR]   ( cccc S: -- )
;   Mot imm�diat � n'utiliser qu'� l'int�rieur d'une d�finition.    
;   Mot compilant le premier caract�re du mot suivant dans le flux d'entr�.
;   Apr�s cette op�ration la variable >IN pointe apr�s le mot trouv�.
;   Lors de L'ex�cution de cette d�finition le caract�re compil� est empil�.   
;   exemple:
;   : test [char] Hello ;
;   test \ S: H     
; arguments:
;   cccc Cha�ne de caract�re dans le flux d'entr�.    
; retourne:
;   rien 
DEFWORD "[CHAR]",6,F_IMMED,COMPILECHAR ; cccc 
    .word QCOMPILE
    .word CHAR,CFA_COMMA,LIT,COMMA,EXIT
    
; nom: FILL ( c-addr u c -- )    
;   Initialise un bloc m�moire RAM de dimension 'u' avec le caract�re 'c'.
;   Si c-addr > 32767 la m�moire r�side en EDS.    
; arguments:
;   c-addr   Adresse du d�but de la zone RAM.
;   u   Nombre de caract�res � remplir.
;   c  Caract�re de remplissage.    
; retourne:
;   rien    
DEFCODE "FILL",4,,FILL ; ( c-addr u c -- )  for{0:(u-1)}-> m[T++]=c
    mov T,W0 ; c
    mov [DSP--],W1 ; u
    mov [DSP--],W2 ; c-addr
    DPOP
    cp0 W1
    bra z, 1f
    dec W1,W1
    repeat W1
    mov.b W0,[W2++]
1:  NEXT
    
    
; nom: -TRAILING  ( c-addr u1 -- c-addr u2 )    
;   Raccourci la cha�ne 'c-addr' 'u1' du nombre d'espace qu'il y a � la fin de celle-ci.
;   Tous les caract�res <=32 sont consid�r�s comme des espaces.    
;   Si c-addr > 32767 acc�de la m�moire EDS.    
; arguments:
;   c-addr Adresse du d�but de la cha�ne.    
;   u1 Longueur initiale de la cha�ne.
; retourne: 
;   c-addr Adresse du d�but de la cha�ne.     
;   u2 Longueur de la cha�ne tronqu�e.    
DEFCODE "-TRAILING",9,,MINUSTRAILING ; ( addr u1 -- addr u2 )
    SET_EDS
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
 
; nom: /STRING  ( c-addr1 u1 n -- c-addr2 u2 )   
;   Avance 'c-addr' de 'n' caract�res et r�duit 'u' d'autant.
; arguments:
;   c-addr1   Adresse du premier caract�re de la cha�ne.
;   u1        Longueur de la cha�ne.
;   n        Nombre de caract�res � avancer.
; retourne:
;   c-addr2    c-addr1+n
;   u2    u1-n    
DEFWORD "/STRING",7,,SLASHSTRING 
    .word ROT,OVER,PLUS,ROT,ROT,MINUS,EXIT

    
; nom: UPPER   ( c-addr -- c-addr )  
;   Convertie la cha�ne compt�e en majuscules. Le vocabulaire de ForthEx est
;   est insensible � la casse. Les noms sont tous convertis en majuscules avant
;   d'�tre ajout�s dans le dictionnaire.  
; arguments:
;   c-addr  Adressse du d�but de la cha�ne compt�e.
; retourne:
;   c-addr  La m�me adresse.  
DEFCODE "UPPER",5,,UPPER ; ( c-addr -- c-addr )
    SET_EDS
    mov T, W1
    mov.b [W1],W2
1:  cp0.b W2
    bra z, 3f
    inc W1,W1
    mov.b [W1],W0
    dec.b W2,W2
    cp.b W0, #'a'
    bra ltu, 1b
    cp.b W0,#'z'
    bra gtu, 1b
    sub.b #32,W0
    mov.b W0,[W1]
    bra 1b
3:  RESET_EDS
    NEXT

; nom: SCAN ( c-addr1 u1 c -- c-addr1 u2 )  
;   Recherche du caract�re 'c' dans la cha�ne d�butant � l'adresse
;  'c-addr1' et de longueur 'u1' octets.
;   retourne la position de 'c' et le nombre de caract�res restant dans la cha�ne.
; arguments:
;   c-addr1 Adresse du d�but de la cha�ne.
;   u1      Longueur de la cha�ne.    
;   c       Caract�re recherch�.
; retourne:
;   c-addr2  Adresse du premier 'c' trouv� dans la cha�ne.
;   u2       Longueur restante de la cha�ne � partir de c-addr2.
DEFCODE "SCAN",4,,SCAN 
    SET_EDS
    mov T, W0   ; c
    DPOP        ; T=u
    mov [DSP],W1 ; W1=c-addr
    cp0 T 
    bra z, 4f ; aucun caract�re restant dans le tampon.
1:  bra ltu, 4f
    cp.b W0,[W1]
    bra z, 4f
    inc W1,W1
    dec T,T
    bra nz, 1b
4:  mov W1,[DSP]
    RESET_EDS
    NEXT

; nom: SKIP ( c-addr1 u1 c -- c-addr2 u2 )  
;   Avance au del� de 'c'. Retourne l'adresse du premier caract�re
;   diff�rent de 'c' et la longueur restante de la cha�ne.    
; arguments:
;   c-addr Adresse d�but de la cha�ne.
;   u     Longueur de la cha�ne.
;   c    Caract�re recherch�.
; retourne:
;   c-addr2  Adresse premier caract�re apr�s 'c'.
;   u2      Longueur restante de la cha�ne � partir c-addr2.    
DEFCODE "SKIP",4,,SKIP 
    SET_EDS
    mov T, W0 ; c
    DPOP ; T=u
    mov [DSP],W1 ; addr
    cp0 T
    bra z, 8f
2:  cp.b W0,[W1]
    bra nz, 8f
    inc W1,W1
    dec T,T
    bra nz, 2b
8:  mov W1,[DSP]
    RESET_EDS
    NEXT

; nom: GETLINE ( c-addr u1 -- c-addr u2 )
;   Scan une m�moire tampon contenant du texte jusqu'au prochain caract�re de fin de ligne.
; arguments:
;   c-addr  Adresse du premier caract�re.
;   u1 Longueur du tampon.      
; retourne:
;   c-addr Adresse du premier caract�re de la ligne.
;   u2 Longueur de la ligne excluant le caract�re de fin de ligne.
    
;HEADLESS GETLINE,HWORD ; ( c-addr u -- c-addr u' )
DEFWORD "GETLINE",7,,GETLINE      
      .word OVER,SWAP,LIT,VK_CR,SCAN ; s: c-addr c-addr' u'
      .word DROP,OVER,MINUS,EXIT
      
    
; nom: MOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc m�moire RAM en �vitant la propagation. La propagation se
;   produit lorsque les 2 r�gions se superposent et qu'un octet copi� est recopi�
;   parce qu'il a �cras� l'octet original dans la r�gion source.     
; arguments:
;   c-addr1  Adresse de la source.
;   c-addr2  Adresse de la destination.
;   u      Nombre d'octets � copier.   
; retourne:
;   rien    
DEFCODE "MOVE",4,,MOVE  ; ( addr1 addr2 u -- )
    mov [DSP-2],W0 ; source
    cp W0,[DSP]    
    bra ltu, move_dn ; source < dest
    bra move_up      ; source > dest
  
    
; nom: CMOVE  ( c-addr1 c-addr2 u -- )    
;   Copie un bloc d'octets RAM.  
;   D�bute la copie � partir de l'adresse du d�but du bloc en adresse croissante.
; arguments:
;   c-addr1  Adresse source.
;   c-addr2  Adresse destination.
;   u      Compte en octets.   
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
;   Copie un bloc d'octets RAM.  
;   La copie d�bute � la fin du bloc en adresses d�croissantes.    
; arguments:
;   c-addr1  Adresse source.
;   c-addr2  Adresse destination.
;   u      Compte en octets.   
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
    
    
; nom: EC@+   ( c-addr1 -- c-addr2 c )   
;   Retourne le caract�re � l'adresse point�e par 'c-addr1' et avance le pointeur au caract�re suivant.
;   � utiliser si 'c-addr1' pointe vers la m�moire RAM ou EDS.    
;  arguments:
;	c-addr1  Pointeur sur la cha�ne de caract�res.
;  retourne:
;     addr2   Pointeur avanc�e d'un caract�re.
;     c       Caract�re � l'adresse c-addr1.    
DEFWORD "EC@+",4,,ECFETCHPLUS
    .word DUP,ECFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; nom: C@+   ( c-addr1 -- c-addr2 c )    
;   Retourne le caract�re � l'adresse point�e par 'c-addr1' et avance le pointeur au caract�re suivant.
;   � utiliser si 'c-addr1' pointe la m�moire RAM ou FLASH.
;  arguments:
;   c-addr1  Pointeur sur la cha�ne de caract�res.
;  retourne:
;   c-addr'   Pointeur avanc�e d'un caract�re.
;     c       Caract�re � l'adresse 'c-addr1'.    
DEFWORD "C@+",3,,CFETCHPLUS
    .word DUP,CFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; nom: CSTR>RAM ( c-addr1 c-addr2 -- )     
;   Copie une chaine compt�e de la m�moire FLASH vers la m�moire RAM.
; arguments:
;   c-addr1    Adresse de la cha�ne en m�moire flash.
;   c-addr2    Adresse destination en m�moire RAM.
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
;   Les 2 cha�nes doivent-�tre en m�moire RAM ou EDS.
; arguments:
;   c-addr1   Adresse du premier caract�re de la cha�ne 1.
;   u1        Longueur de la cha�ne 1.    
;   c-addr2   Adresse du premier caract�re de la cha�ne 2.
;   u2        Longueur de la cha�ne 2.    
; retourne:
;   f	  Indicateur Bool�en d'�galit�, vrai si les cha�nes sont identiques.    
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
;   D�pose 'u' caract�res espace (BL) � partir de l'adresse c-addr
; arguments:
;   c-addr  Adresse d�but RAM
;   u       Nombre d'espaces � d�poser dans cette r�gion.
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
 
; nom: C-COMP ( c1 c2 -- -1|0|1 )
;   Compare les 2 caract�res et retourne une des 3 valeur suivante:
;   -1 si c1 < c2
;    0 si c1==c2
;    1 si c1>c2
; arguments:
;   c1 Premier caract�re � comparer
;   c2 Deuxi�me caract�re � comparer
; retourne:
;   -1|0|1  Indique la relation entre les 2 caract�res.
DEFCODE "C-COMP",6,,CCOMP
    mov.b T,W0
    DPOP
    cp.b T,W0
    bra z,c_equal
    bra ltu,c1_less
    mov #1, T
    bra 9f
c_equal:
    clr T
    bra 9f
c1_less:
    setm T
9:  NEXT
    
    
    
; nom: COMPARE ( c-addr1 u1 c-addr2 u2 -- -1|0?1 )
;   Compare la cha�ne de caract�re d�butant � l'adresse 'c-addr1' de longueur 'u1'
;   avec la cha�ne de caract�re d�butant � l'adresse 'c-addr2' de longueur 'u2'
;   Cette comparaison se fait selon l'orde des caract�res dans la table ASCII.
;   Si 'u1'=='u2' et que tous les caract�res correspondent la valeur 0 est retourn�e,
;   sinon le premier caract�re qui diverge d�termine la valeur retourn�e c1<c2 
;    retourne -1 autrement retourne 1.    
;   Si u1<u2 et que tous les caract�res de cette cha�ne sont en correspondance avec
;   l'autre cha�ne la valeur -1 est retourn�e.
;   Si u1>u2 et que tous les caract�res de c-addr2 correspondent avec ceux de c-addr1
;   la valeur 1 est retourn�e.
; arguments:
;   c-addr1  Adresse du premier caract�re de la cha�ne 1.
;   u1       Longueur de la cha�ne 1.
;   c-addr2  Adresse du premier caract�re de la cha�ne 2.
;   u2       Longueur de la cha�ne 2.
; retourne:
;   -1|0|1 Retourne -1 si cha�ne1<cha�ne2, 0 si cha�ne1==cha�ne2, 1 si cha�ne1>cha�ne2    
DEFWORD "COMPARE",7,,COMPARE
    .word ROT,TWODUP,TWOTOR,UMIN,FALSE,DODO ; s: c-addr1 c-addr2 r: u2 u1
1:  .word TOR,ECFETCHPLUS,RFROM,ECFETCHPLUS,ROT,SWAP,CCOMP,QDUP,ZBRANCH,2f-$
    .word NROT,TWODROP,TWORFROM,TWODROP,UNLOOP,EXIT
2:  .word DOLOOP,1b-$,TWODROP,TWORFROM ; S: u2 u1
    .word TWODUP,EQUAL,ZBRANCH,2f-$,TWODROP,FALSE,EXIT
2:  .word UGREATER,ZBRANCH,4f-$,TRUE,EXIT
4:  .word LIT,1,EXIT
  

; nom: SEARCH  ( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 f )
;   Recherche la cha�ne 2 dans la cha�ne 1. Si f est vrai c'est que la cha�ne 2
;   est sous-cha�ne de la cha�ne 1, alors c-addr3 u3 indique la position et le 
;   nombre de caract�res restants. En cas d'�chec c-addr3==c-addr1 et u3==u1.
;   exemple:
;     : s1 s" A la claire fontaine." ;
;     : s2 s" claire" ;
;     s1 s2 SEARCH   \  c-addr3=c-addr1+5 u3=16  f=VRAI  
; arguments:
;   c-addr1  Adresse du premier carcact�re de la cha�ne principale.
;   u1       Longueur de la cha�ne principale.
;   c-addr2  Adresse du premier caract�re de la sous-cha�ne recherch�e.
;   u2       Longueur de la sous-cha�ne recherch�e.
; retourne:
;   c-addr3  Si f est VRAI  Adresse du premier caract�re de la sous-cha�ne, sinon = c-addr1
;   u3       Si f est VRAI nombre de caract�re restant dans la cha�ne � partir de c-addr3
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
;   Compile le descripteur d'une cha�ne qui est sur la pile des arguments.
;   A l'ex�cution le descripteur est empil�.
;   exemple:
;   : s1 s" test" ; immediate
;   : type-s1 s1 sliteral type ;
;   type-s1  test  OK
; arguments:
;   c-addr  Adresse du premier caract�re de la cha�ne.
;   u       Longueur de la cha�ne.
; retourne:
;    rien
DEFWORD "SLITERAL",8,F_IMMED,SLITERAL
    .word QCOMPILE,SWAP,LITERAL,LITERAL,EXIT
    
; DESCRIPTION:
;   Commentaires.

; nom: (    ( cccc S: -- )    
;   Ce mot introduit un commentaire qui se termine  par ')'.
;   Tous les caract�res dans le tampon d'entr�e sont saut�s jusqu'apr�s le ')'.    
;   Il doit y avoir un espace de chaque c�t� de '(' car c'est un mot Forth.
;   Il s'agit d'un mot imm�diat, il s'ex�cute donc m�me en mode compilation.    
; arguments:
;   cccc  commentaire dans le texte d'entr�e termin� par ')'. 
; retourne:    
;   rien    
DEFWORD "(",1,F_IMMED,LPAREN ; parse ccccc)
    .word LIT,')',PARSE,TWODROP,EXIT

; nom: \    ( cccc S: -- )    
;   Ce mot introduit un commentaire qui se termine � la fin de la ligne.
;   Tous les caract�res dans le tampon d'entr� sont saut�s jusqu'� la fin de ligne.    
;   Il s'agit d'un mot imm�diat, il s'�x�cute donc m�me en mode compilation.
; arguments:
;   cccc  Caract�res dans le texte d'entr�e termin� par une fin de ligne. 
; retourne:
;   rien    
DEFWORD "\\",1,F_IMMED,COMMENT ; ( -- )
    .word BLK,FETCH,ZBRANCH,2f-$
    .word CLIT,VK_CR,PARSE,TWODROP,EXIT
2:  .word SOURCE,PLUS,ADRTOIN,EXIT

; nom: .(   cccc) ( -- )    
;   Mot imm�diat, affiche le texte d�limit� par ).
;   Extrait tous les caract�res du texte d'entr�e jusqu'apr�s le caract�re ')'.
;   Le d�limiteur ')' n'est pas imprim�.    
; arguments:
;   cccc Caract�res dans le texte d'entr�e termin�s par ')'.
; retourne:
;   rien    
DEFWORD ".(",2,F_IMMED,DOTPAREN ; ccccc    
    .word LIT,')',PARSE,TYPE,EXIT
 
    
; DESCRIPTION:
;   Mots utilis�s dans la conversion d'entiers en cha�nes de caract�res.
;   La cha�ne est construite � la fin dun tampon PAD. La variable HP (Hold Pointer)
;   est utilis�e pour indiqu�e l'endroit o� doit-�tre d�pos� le prochain caract�re
;   de la cha�ne construite.     
    
; nom: DIGIT  ( u -- c )    
;   Convertion d'un chiffre en caract�re ASCII selon la valeur de BASE.
; arguments:
;   u  Un entier entre 0..BASE-1 
; retourne:
;   c  Repr�sentation ASCII de cet entier qui repr�sente 1 seul digit dans la base active.    
DEFWORD "DIGIT",5,,DIGIT ; ( u -- c )
    .word LIT,9,OVER,LESS,LIT,7,AND,PLUS,LIT,48,PLUS
    .word EXIT

; nom: EXTRACT  ( ud1 u -- ud2 c )    
;   Extrait le chiffre le moins significatif de 'ud1' et le convertie en caract�re
;   en accord avec la valeur de la base 'u'. 
; arguments:
;   ud1 Entier double non sign� qui est le  nombre � convertir en cha�ne ASCII.
;   u  Entier simple non sign�, valeur de la base num�rique.
; retourne:
;   ud2 Entier double qui est le quotient de ud/u, c'est la partie du nombre qui reste � convertir.
;   c   Caract�re ASCII qui repr�sente le digit r�sultant de ud%u (modulo de ud par u ).    
DEFWORD "EXTRACT",7,,EXTRACT ; ( ud u -- ud2 c )     
    .word UDSLASHMOD,ROT,DIGIT,EXIT
    
; nom: <#   ( -- )    
;   Initalise le d�but de la conversion d'un entier en cha�ne ASCII.
;   La valeur de la variable HP est modifi�e pour pointer � la fin du PAD.
;   Lors de la conversion les caract�res sont ajout�s de la fin vers le d�but.
;   � chaque caract�re ajout�  � la cha�ne la variable HP est d�cr�ment�e.    
; arguments:
;   aucun
; retourne:
;    rien   
DEFWORD "<#",2,,LTSHARP ; ( -- )
    .word PAD,FETCH,PADSIZE,PLUS,HP,STORE
    .word EXIT
 
; nom: HOLD ( c -- )    
;   D�pose le caract�re 'c' dans le PAD et d�cr�mente la variable HP.
; arguments:
;   c  Caract�re � ins�rer dans la cha�ne.
; retourne:
;   rien    
DEFWORD "HOLD",4,,HOLD ; ( c -- )
    .word LIT,-1,HP,PLUSSTORE
    .word HP,FETCH,CSTORE
    .word EXIT

; nom: #  ( ud1 -- ud2 )    
;   Convertion du digit le moins significatif de ud1 en ASCII et l'ajoute � la cha�ne
;   dans PAD.  Retourne le restant de ud1.    
; arguments:
;     ud1  Entier double non sign� � convertir.
; retourne:    
;     ud2  Entier double non sign� restant, i.e. ud1/base    
DEFWORD "#",1,,SHARP ; ( ud1 -- ud2 )
    .word BASE,FETCH,EXTRACT,HOLD,EXIT

; nom: #S  ( ud1 -- ud2 )     
;   Convertie tous les digits d'un entier double en cha�ne ASCII.
; arguments:
;   ud1 Entier double non sign� � convertir en cha�ne.
; retourne:
;   ud2 Entier double de valeur nulle qui reste apr�s la conversion.    
DEFWORD "#S",2,,SHARPS ; ( ud1 -- ud2==0 )
1:  .word SHARP,TWODUP,OR,TBRANCH,1b-$,EXIT
  
; nom: SIGN  ( n -- )  
;   Ajoute le signe au d�but de la cha�ne num�rique dans le PAD.
;   Si 'n' est  n�gatif alors on ajoute un signe '-' au d�but de la cha�ne.
; arguments:
;   n Entier qui repr�sente le signe du nombre qui a �t� convertie.
; retourne:
;   rien  
DEFWORD "SIGN",4,,SIGN ; ( n -- )
    .word ZEROLT,ZBRANCH,1f-$
    .word CLIT,'-',HOLD
1:  .word EXIT
  
; nom: #>  ( ud -- addr u )  
;   Termine la conversion d'un entier en cha�ne ASCII en empilant le descripteur
;   de la cha�ne.
; arguments:
;    ud   N'est pas utilis� c'est le relicat du mot #S. Cette valeur est simplement jet�e.
; retourne:
;   c-addr  Adresse du premier caract�re de la cha�ne num�rique.
;   u       Longueur de la cha�ne.  
DEFWORD "#>",2,,SHARPGT ; ( d -- c-addr u )
  .word TWODROP,HP,FETCH,PAD,FETCH,PADSIZE,PLUS,OVER,MINUS, EXIT
  
; nom: STR ( d -- c-addr u )  
;   Convertion d'un entier double en cha�ne ASCII, utilise le tampon PAD pour 
;   d�velopper la cha�ne ASCII. La variable HP est aussi utilis�e dans cette proc�dure.  
; arguments:
;   d   Entier double � convertir en cha�ne ASCII.
; retourne:
;   c-addr   Adresse premier caract�re de la cha�ne.
;   u  Longueur de la cha�ne.  
DEFWORD "STR",3,,STR ; ( d -- addr u )
  .word DUP,TOR,DABS,LTSHARP,SHARPS,RFROM,SIGN,SHARPGT,EXIT

; nom: COLFILL ( n1+ n2+ -- )  
;   Ajoute les espaces n�cessaires au d�but de la colonne pour que le nombre
;   soit align� � droite d'une colonne de largeur fixe.
; arguments:
;   n1+ Largeur de la colonne
;   n2+ Longueur de la cha�ne num�rique.
; retourne:
;   rien  
DEFWORD "COLFILL",7,,COLFILL ; ( n1+ n2+ -- )
    .word MINUS,DUP,ZEROGT,TBRANCH,1f-$
    .word DROP,BRANCH,8f-$
1:  .word SPACES
8:  .word EXIT
  
; nom: .R  ( n n+ -- )  
;   Affiche un nombre dans un colonne de largeur fixe align� � droite.
; arguments:
;   n  Nombre � afficher.
;   n+ Largeur de la colonne.
; retourne:
;   rien  
DEFWORD ".R",2,,DOTR  ; ( n +n -- ) +n est la largeur de la colonne
    .word TOR,STOD,RFROM,DDOTR,EXIT
    
; nom: U.R  ( u +n -- )    
;   Affiche un entier non sign� dans une colonne de largeur fixe align� � droite.
; arguments:
;   u	 Entier simple non sign� � afficher.    
;   n+   Largeur de la colonne.
; retourne:
;   rien    
DEFWORD "U.R",3,,UDOTR ; ( u +n -- )
  .word TOR,LIT,0,RFROM,UDDOTR,EXIT
  
; nom: U.  ( u -- )  
;   Affiche un entier simple non sign� en format libre.
; arguments:
;   u  Entier � afficher.
; retourne:
;   rien  
DEFWORD "U.",2,,UDOT ; ( n -- )
udot:  .word LIT,0,UDDOT,EXIT
  
; nom: .  ( n -- )  
;   Affiche un entier simple sign� en format libre.
; arguments:
;   n Entier � afficher.  
; retourne:
;   rien  
DEFWORD ".",1,,DOT ; ( n -- )
  .word BASE,FETCH,LIT,10,EQUAL,ZBRANCH,udot-$,STOD,DDOT,EXIT

; nom: ?  ( addr -- )  
;   Affiche l'entier simple � l'adresse donn�e. On s'assure de l'alignement sur
;   une adresse paire.  Si 'addr' est impaire l'adresse paire pr�c�dente est utilis�e.
; arguments:
;   addr  Adresse dont le contenu sera affich�.
; retourne:
;   rien  
DEFWORD "?",1,,QUESTION ; ( addr -- )
  .word LIT,0xFFFE,AND,FETCH,DOT,EXIT

; nom: C?  ( c-addr )  
;   Lit et affiche l'octet � l'adresse c-addr.
; arguments:
;   c-addr  Adresse dont le contenu sera affich�.
; retourne:
;   rien  
DEFWORD "C?",2,,CQUESTION ; ( c-addr -- )    
    .word CFETCH,DOT,EXIT
  
; nom: UD.  ( ud -- )    
;   Affiche un entier double non sign� en format libre.
; arguments:
;   ud  Entier double non sign�.
; retourne:
;   rien    
DEFWORD "UD.",3,,UDDOT ; ( ud -- )    
_uddot:
    .word LTSHARP,SHARPS,SHARPGT,SPACE,TYPE
    .word EXIT
    
; nom: D.   ( d -- )    
;   Affiche un entier double sign� en format libre.
; arguments:
;    d   Entier double � afficher.
; retourne:
;   rien    
DEFWORD "D.",2,,DDOT ; ( d -- )
    .word BASE,FETCH,LIT,10,EQUAL,ZBRANCH,_uddot-$
    .word STR,SPACE,TYPE
    .word EXIT

; nom: D.R  ( d n+ -- )    
;   Affiche un entier double dans une colonne de largeur fixe align�e � droite.
; arguments:
;   d  Entier double � afficher.
;   n+ Largeur de la colonne.
; retourne:
;   rien    
DEFWORD "D.R",3,,DDOTR ; ( d n+ -- )
    .word TOR,STR,RFROM,OVER,COLFILL,TYPE,EXIT

; nom: UD.R  ( ud n+ -- )
;   Affiche un entier double non sign� dans une colonne de largeur fixe align�e � droite.
; arguments:
;   ud Entier double non sign� � afficher.
;   n+ Largeur de la colonne.
; retourne:
;   rien    
DEFWORD "UD.R",4,,UDDOTR ; ( ud n+ -- )
    .word TOR,LTSHARP,SHARPS,SHARPGT,RFROM,OVER
    .word COLFILL,TYPE,EXIT

; DESCRIPTION:
;   Mots utilis�s dans la conversion d'une cha�ne de caract�res en entier.


; nom: DECIMAL?  ( c -- f )
;   v�rifie si 'c' est dans l'ensemble ASCII {'0'..'9'}
; arguments:
;   c   caract�re ASCII � v�rifier.
; retourne:
;   f   indicateur bool�en.
DEFWORD "DECIMAL?",8,,DECIMALQ
    .word DUP,LIT,'0',LESS,ZBRANCH,2f-$
    .word DROP,FALSE,EXIT
2:  .word LIT,'9',GREATER,INVERT,EXIT
  
    
; nom: >BASE10  ( u1 c -- u2 )
;   �tape de conversion d'une cha�ne de caract�res en 
;   entier d�cimal.
; arguments:
;   u1  Entier r�sultant de la conversion d'une cha�ne en d�cimal
;   c  Caract�re ASCII  dans l'intervalle {'0'..'9'}
; retourne:
;   u2  = u1*10+digit(c)
DEFWORD ">BASE10",7,,TOBASE10
    .word LIT,'0',MINUS,LIT,10,ROT,STAR
    .word PLUS,EXIT
   
; nom: DIGIT?  ( c -- x 0 | n -1 )    
;   V�rifie si le caract�re est un digit valide dans la base actuelle.
;   Si valide retourne la valeur du digit et -1
;   Si invalide retourne x 0
; arguments:
;   c   Caract�re � convertir dans la base active.
; retourne:
;   x&nbsp;0 Faux et un entier quelconque qui doit-�tre ignor� car ce n'est pas un digit.
;   ou    
;   n&nbsp;-1 Vrai et le caract�re convertie en digit de la base active.
DEFWORD "DIGIT?",6,,DIGITQ ; ( c -- x 0 | n -1 )
    .word DUP,LIT,'a'-1,UGREATER,ZBRANCH,1f-$
    .word LIT,32,MINUS ; convertie en majuscule.
1:  .word DUP,LIT,'9',UGREATER,ZBRANCH,3f-$
    .word DUP,LIT,'A',ULESS,ZBRANCH,2f-$
    .word LIT,0,EXIT ; pas un digit
2:  .word LIT,7,MINUS    
3:  .word LIT,'0',MINUS
    .word DUP,BASE,FETCH,ULESS,EXIT
 
; nom: PONCT?  ( c -- f )
;  V�rifie si le caract�re 'c' est un point ou une virgule et retourne un 
;  indicateur vrai si c'est le cas.
; arguments:
;  c Caract�re � v�rifier.
; retourne:
;  f Indicateur bool�en, vrai si c est ','|'.'
DEFCODE "PONCT?",6,,PONCTQ
    mov T,W0
    setm T
    cp.b W0,#'.'
    bra z, 9f
    cp.b W0,#','
    bra z,9f
    clr T
9:  NEXT
    
  
; nom: >NUMBER  (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )   
;   Convertie la cha�ne en nombre en utilisant la valeur de BASE.
;   La conversion s'arr�te au premier caract�re non num�rique.
;     
; arguments:  
; 'ud1'	    Est initialis� � z�ro  
;  c-addr1 Adresse du d�but de la cha�ne � convertir en entier.
;  u1      Longueur de la cha�ne � analyser.  
; retourne:
;  ud2     Entier double r�sultant de la conversion.
;  c-addr2  Adresse pointant apr�s le nombre dans le tampon.
;  u2      Longueur restante dans le tampon.  
DEFWORD ">NUMBER",7,,TONUMBER ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
1:   .word LIT,0,TOR ; indique si le dernier caract�re �tait un digit
2:   .word DUP,ZBRANCH,7f-$
     .word OVER,CFETCH,DIGITQ  ; ud1 c-addr u1 n|x f
     .word TBRANCH,4f-$
     .word RFROM,ZBRANCH,8f-$
     .word DROP,OVER,CFETCH,PONCTQ,ZBRANCH,9f-$
     .word SWAP,CHARPLUS,SWAP,ONEMINUS,BRANCH,1b-$
4:   .word RDROP,LIT,-1,TOR ; dernier caract�re �tait un digit
     .word TOR,TWOSWAP,BASE,FETCH,UDSTAR
     .word RFROM,MPLUS,TWOSWAP
     .word LIT,1,SLASHSTRING,BRANCH,2b-$
7:   .word RFROM
8:   .word DROP
9:   .word EXIT
   
; nom: NEG?   ( c-addr u -- c-addr' u' f )   
;   V�rifie s'il y a un signe '-' � la premi�re postion de la cha�ne sp�cifi�e par <c-addr u>
;   Retourne f=VRAI si '-' sinon f=FAUX.    
;   S'il y a un signe avance au del� du signe.
; arguments:
;   c-addr   Adresse o� d�bute l'analyse.
;   u        Longueur de la cha�ne � analyser.
; retourne:
;   c-addr'  Adresse incr�ment�e au del� du signe '-' s'il y a lieu.
;   u'       Longueur restante dans le tampon.
;   f        Indicateur Bool�en, VRAI s'il le premier caract�re est '-'.   
DEFWORD "NEG?",5,,SIGNQ ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,CLIT,'-',EQUAL,TBRANCH,8f-$
    .word FALSE,EXIT
8:  .word LIT,1,SLASHSTRING,TRUE
9:  .word EXIT
    
; nom: BASE-MOD?  ( c-addr u1 -- c-addr' u1' )  
;   V�rifie s'il y a un modificateur de base
;   Si vrai, modifie la valeur de BASE en cons�quence et  avance le pointeur c-addr.
; arguments:
;   c-addr  Adresse du d�but de la cha�ne � analyser.
;   u1      Longueur de la cha�ne.
; retourne:
;   c-addr'  Adresse incr�ment�e au del� du caract�re modificateur de BASE.
;   u'       Longueur restante de la cha�ne.  
DEFWORD "BASE-MOD?",8,,BASEMODQ ; ( c-addr u1 -- c-addr' u1'  )
    .word OVER,CFETCH,CLIT,'$',EQUAL,ZBRANCH,1f-$
    .word LIT,16,BASE,STORE,BRANCH,8f-$
1:  .word OVER,CFETCH,CLIT,'#',EQUAL,ZBRANCH,2f-$
    .word LIT,10,BASE,STORE,BRANCH,8f-$
2:  .word OVER,CFETCH,CLIT,'%',EQUAL,ZBRANCH,9f-$
    .word LIT,2,BASE,STORE
8:  .word SWAP,ONEPLUS,SWAP,ONEMINUS    
9:  .word EXIT

; nom: QUOTED-CHAR?  ( c-addr -- c-addr 0 | n -1 )
;   V�rifie si la cha�ne est un caract�re entre 2 apostrophe si c'est le cas
;   Empile la valeur ASCII du caract�re et TRUE, sinon retourne 'c-addr' et FALSE.
; arguments:
;    c-addr  Adresse de la cha�ne compt�e.
; retourne:
;   c-addr&nbsp;0 Faux et adresse orignale si ce n'est pas un quoted char.
;   ou  
;   n&nbsp;-1 Vrai et valeur ASCII du caract�re.  
DEFWORD "QUOTED-CHAR?",12,,QUOTEDCHARQ
    .word DUP,COUNT,LIT,3,EQUAL,ZBRANCH,9f-$
    ; s: c-addr c-addr+1
    .word DUP,CFETCH,DUP,LIT,'\'',EQUAL,ZBRANCH,8f-$
    ; s: c-addr c-addr+1 '
    .word OVER,LIT,2,CHARS,PLUS,CFETCH,XOR
    .word TBRANCH,9f-$
    ; s: c-addr c-addr+1
    .word LIT,1,CHARS,PLUS,CFETCH,DUP,QPRTCHAR,ZBRANCH,9f-$
    .word SWAP,DROP,TRUE,EXIT
8:  .word DROP  
9:  .word DROP,FALSE,EXIT
  

; nom: DOUBLE? ( c-addr -- f )
;   V�rifie si le mot contient un point ou une virgule et retourne vrai
;   si c'est le cas.
; arguments:  
;   c-addr  Adresse de la cha�ne compt�e qui contient le mot � v�rifier.
; retourne:
;   f Retourne vrai si la cha�ne contient un point ou une virgule.
DEFWORD "DOUBLE?",7,,DOUBLEQ
    .word COUNT,LIT,0,DODO
1:  .word DUP,CFETCH,PONCTQ,TBRANCH,6f-$
    .word CHARPLUS,DOLOOP,1b-$,DROP,FALSE,EXIT
6:  .word DROP,TRUE,UNLOOP,EXIT
  
; nom: NUMBER?   ( c-addr -- c-addr 0 | n -1 )  
;   Conversion d'un mot extrait par PARSE-NAME en entier. Ce mot est invoqu� par
;   INTERPRET lorsqu'un mot n'a pas �t� trouv� dans le dictionnaire. L'interpr�teur
;   s'attend donc � ce que le mot soit un entier (simple ou double). ?NUMBER
;   invoque >NUMBER et s'attend � ce que >NUMBER retourne 0 au sommet de la pile
;   car si >NUMBER ne convertie pas tous les caract�res �a signifit que le mot
;   n'est pas un entier valide.  
;   NUMBER? utilise la base active sauf si la cha�ne d�bute par '$'|'#'|'%'
;   NUMBER? accepte aussi un caract�re ASCII imprimable entre 2 apostrophes.
;   Dans ce cas la valeur de l'entier est la valeur ASCII du caract�re.  
;   Pour entrer un nombre double pr�cision il faut mettre un point ou une virgule 
;   � une position quelconque de la cha�ne saisie sauf � la premi�re position.
;   Il peut y avoir pleusieurs ponctuations, par exemple 12,267,324 est une 
;   entier double valide.  
; arguments:
;   c-addr   Adresse du mot � analyser.
; retourne:
;   c-addr&nbsp;0  Faux et l'adresse si ce n'est pas un entier.	
;   ou  
;   n&nbsp;-1  Vrai et l'entier.  
DEFWORD "NUMBER?",7,,NUMBERQ ; ( c-addr -- c-addr 0 | n -1 )
    .word QUOTEDCHARQ,ZBRANCH,2f-$
    .word TRUE,EXIT  
2:  .word BASE,FETCH,TOR ; sauvegarde la valeur de BASE 
    .word DUP,DOUBLEQ,TOR ;S: c-addr R: base fDouble
    .word DUP,LIT,0,DUP,ROT,COUNT,BASEMODQ  ; c-addr 0 0 c-addr' u'
    .word SIGNQ,TOR  ; c-addr 0 0 c-addr' u' R: base fDouble fSign
4:  .word TONUMBER ; c-addr ud c-addr' u' R: base fDouble fSign
    .word ZBRANCH,1f-$ 
    .word DROP,TWODROP,TWORFROM,TWODROP,FALSE,BRANCH,8f-$
1:  .word DROP,ROT,DROP
    .word RFROM,ZBRANCH,2f-$
    .word DNEGATE
2:  .word RFROM,TBRANCH,3f-$
    .word DROP
3:  .word LIT,-1
8:  .word RFROM,BASE,STORE ; restitue la valeur de BASE
9:  .word EXIT
    
    