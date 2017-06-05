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
;  Mot qui manipules les caract�res caract�res.


; nom: BL  ( -- n )
;   Constante syst�me qui retourne la valeur ASCII 32 (espace).
; arguments:
;   aucun
; retourne:
;   n    valeur ASCII 32  qui repr�sente l'espace.    
DEFCONST "BL",2,,BL,32                       ; caract�re espace

; nom: >CHAR  ( n -- c )    
;   V�rifie que n est dans l'intervalle ASCII 32..126, sinon remplace c par '_'  
; arguments:
;   n   Entier � convertir en caract�re.
; retourne:
;   c    Valeur ASCII entre 32 et 126    
DEFCODE ">CHAR",5,,TOCHAR 
    mov #126,W0
    cp W0,T
    bra gtu,1f
    cp T,#32
    bra geu, 2f
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
;   c-addr   adresse align�e sur caract�re.
; retourne:
;   c-addr'  adresse align�e sur caract�re suivant.  
DEFWORD "CHAR+",5,,CHARPLUS ; ( addr -- addr' )  
    .word LIT,CHAR_SIZE,PLUS,EXIT
  
; nom: CHAR   ( cccc -- c )    
;   Recherche le prochain mot dans le flux d'entr�e et empile le premier caract�re de ce mot.
;   A la suite de cette op�ration la variable >IN pointe apr�s le mot.    
; arguments:
;    cccc   cha�ne de caract�re dans le flux d'entr�.
; retourne:
;    c      Le premier caract�re du mot extrait du flux d'entr�e.
DEFWORD "CHAR",4,,CHAR ; cccc ( -- c )
    .word BL,WORD,DUP,CFETCH,ZEROEQ
    .word QABORT
    .byte 16
    .ascii "missing caracter"
    .align 2
    .word ONEPLUS,CFETCH,EXIT

; nom: [CHAR]   ( ccccc -- )
;   Mot � n'utiliser qu'� l'int�rieur d'une d�finition.    
;   Mot compilant le premier caract�re du mot suivant dans le flux d'entr�.
;   Apr�s cette op�ration la variable >IN pointe apr�s le mot trouv�.
; arguments:
;   cccc  Cha�ne de caract�re dans le flux d'entr�.    
; retourne:
;   rien   Le caract�re es compil� dans la d�finition.    
DEFWORD "[CHAR]",6,F_IMMED,COMPILECHAR ; cccc 
    .word QCOMPILE
    .word CHAR,CFA_COMMA,LIT,COMMA,EXIT
    
; nom: FILL ( c-addr u c -- )    
;   Initialise un bloc m�moire RAM de dimension u avec le caract�re c.
;   Si c-addr > 32767 la m�moire r�side en EDS.    
; arguments:
;   c-addr   Adresse du d�but de la zone RAM.
;   u        Nombre de caract�res � remplir.
;   c        Caract�re de remplissage.    
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
;   Raccourci la cha�ne c-addr u1 du nombre d'espace qu'il y a � la fin de celle-ci.
;   Tous les caract�res <=32 sont consid�r�s comme des espaces.    
;   Si c-addr > 32767 acc�de la m�moire EDS.    
; arguments:
;   c-addr  Adresse du d�but de la cha�ne.    
;   u1 Longueur initiale de la cha�ne.
; retourne: 
;   c-addr Adresse du d�but de la cha�ne.     
;   u2 longueur finale de la cha�ne.    
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

; nom: SCAN ( c-addr u c -- c-addr' u' )  
;   Recherche du caract�re 'c' dans le bloc
;   m�moire d�butant � l'adresse 'c-addr' et de dimension 'u' octets
;   retourne la position de 'c' et
;   le nombre de caract�res restant dans le bloc
; arguments:
;   c-addr  adresse d�but zone RAM
;   u       longueur de la zone en octets.    
;   c       caract�re recherch�.
; retourne:
;   c-addr'  adresse du premier 'c' trouv� dans cette zone
;   u'       longueur de la zone restante � partir de c-addr'    
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

; nom: SKIP ( c-addr u c -- c-addr' u' )  
;   avance au del� de 'c'. Retourne l'adresse du premier caract�re
;   diff�rent de 'c' et la longueur restante de la zone.    
; arguments:
;   c-addr    adresse d�but de la zone
;   u         longueur de la zone
;   c         caract�re � sauter.
; retourne:
;   c-addr'   adresse premier caract�re <> 'c'
;   u'        longueur de la zone restante � partir c-addr'    
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
;   produit lorsque les 2 r�gion se superposent et qu'un octet copi� est recopi�
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
    
; DESCRIPTION:
;   Commentaires.

; nom: (    ( cccc -- )    
;   Ce mot introduit un commentaire qui se termine  par ')'.
;   Tous les caract�res dans le tampon d'entr�e sont saut�s jusqu'apr�s le ')'.    
;   Il doit y avoir un espace de chaque c�t� de '(' car c'est un mot forth.
;   Il s'agit d'un mot imm�diat, il s'ex�cute donc m�me en mode compilation.    
; arguments:
;   aucun  
; retourne:    
;   rien    
DEFWORD "(",1,F_IMMED,LPAREN ; parse ccccc)
    .word LIT,')',PARSE,TWODROP,EXIT

; nom: \    ( cccc -- )    
;   Ce mot introduit un commentaire qui se termine � la fin de la ligne.
;   Tous les caract�res dans le tampon d'entr� sont saut�s jusqu'� la fin de ligne.    
;   Il s'agit d'un mot imm�diat, il s'�x�cute donc m�me en mode compilation.
; arguments:
;   aucun  
; retourne:
;   rien    
DEFWORD "\\",1,F_IMMED,COMMENT ; ( -- )
    .word BLK,FETCH,ZBRANCH,2f-$
    .word CLIT,VK_CR,PARSE,TWODROP,EXIT
2:  .word SOURCE,PLUS,ADRTOIN,EXIT

; nom: .(   cccc) ( -- )    
;   Affiche le texte d�limit� par ).
;   Extrait tous les caract�res du flux d'entr�e jusqu'apr�s le caract�re ')'.
;   Le d�limiteur ')' n'est pas imprim�.    
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD ".(",2,F_IMMED,DOTPAREN ; ccccc    
    .word LIT,')',PARSE,TYPE,EXIT
 
    
; DESCRIPTION:
;   Mots utilis�s dans la conversion d'entiers en cha�nes de caract�res.

    
; nom: DIGIT  ( u -- c )    
;   Convertion d'un chiffre en caract�re ASCII selon la valeur de BASE.
; arguments:
;   u  Un entier entre 0..BASE-1 
; retourne:
;   c  Repr�sentation ASCII de cet entier qui repr�sente 1 seul digit dans la base active.    
DEFWORD "DIGIT",5,,DIGIT ; ( u -- c )
    .word LIT,9,OVER,LESS,LIT,7,AND,PLUS,LIT,48,PLUS
    .word EXIT

; nom: EXTRACT  ( ud u -- ud2 c )    
;   Extrait le chiffre le moins significatif de ud et le convertie en caract�re
;   en accord avec la valeur de la base u. 
; arguments:
;   ud Entier double non sign� qui est le  nombre � convertir en cha�ne ASCII.
;   u  Entier simple non sign� repr�sente la valeur de la base num�rique.
; retourne:
;   ud2 Entier double qui est le quotient de ud/u, c'est la partie du nombre qui reste � convertir.
;   c   Caract�re ASCII qui repr�sente le digit r�sultant de ud%u (modulo de ud par u ).    
DEFWORD "EXTRACT",7,,EXTRACT ; ( ud u -- ud2 c )     
    .word UDSLASHMOD,ROT,DIGIT,EXIT
    
; nom: <#   ( -- )    
;   Initalise le d�but de la conversion d'un entier en cha�ne ASCII.
;   La valeur de la variable HP est modifi�e pour point� � la fin du PAD.
;   Lors de la conversion les caract�res sont ajout�s de la droite vers la gauche dans le PAD.
; arguments:
;   aucun
; retourne:
;    rien   
DEFWORD "<#",2,,LTSHARP ; ( -- )
    .word PAD,FETCH,PADSIZE,PLUS,HP,STORE
    .word EXIT
 
; nom: HOLD ( c -- )    
;   Met le caract�re dans c dans le PAD et recule HP de 1 caract�re.
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
;   Si n est  n�gatif alors on ajoute un signe '-' au d�but de la cha�ne.
; arguments:
;   n Entier qui repr�sente le signe du nombre qui a �t� convertie.
; retourne:
;   rien  
DEFWORD "SIGN",4,,SIGN ; ( n -- )
    .word ZEROLT,ZBRANCH,1f-$
    .word CLIT,'-',HOLD
1:  .word EXIT
  
; nom: #>  ( ud -- addr u )  
;   Termine la conversion d'un entier en cha�ne ASCII en ajoutant la longueur
;   au d�but de la cha�ne.
; arguments:
;    ud   n'est pas utilis� c'est le relicat du mot #S. Cette valeur est simplement jet�e.
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
;   Affiche un entier simple en format libre.
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
;   Affiche un entier double en format libre.
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
;   v�rifie si c est dans l'ensemble ASCII {'0'..'9'}
; arguments:
;   c   caract�re ASCII � v�rifier.
; retourne:
;   f   indicateur bool�en.
DEFWORD "DECIMAL?",8,,DECIMALQ
    .word DUP,LIT,'0',LESS,ZBRANCH,2f-$
    .word DROP,FALSE,EXIT
2:  .word LIT,'9',GREATER,INVERT,EXIT
  
    
; nom: >BASE10  ( u1 c -- u2 )
;   �tape de conversion d'une cha�ne de caract�re en 
;   entier d�cimal.
; arguments:
;   u1  entier r�sultant de la conversion d'une cha�ne en d�cimal
;   c  caract�re ASCII  dans l'intervalle {'0'..'9'}
; retourne:
;   u2    
DEFWORD ">BASE10",7,,TOBASE10
    .word LIT,'0',MINUS,LIT,10,ROT,STAR
    .word PLUS,EXIT
   
; nom: ?DIGIT  ( c -- x 0 | n -1 )    
;   V�rifie si le caract�re est un digit valide dans la base actuelle.
;   Si valide retourne la valeur du digit et -1
;   Si invalide retourne x 0
; arguments:
;   c   caract�re � convertir dans la base active.
; retourne:
;   x    un entier quelconque qui doit-�tre ignor�.
;   0    le caract�re n'�tait pas valide, x doit-�tre ignor�.
;   n    Le caract�re convertie en digit de la base active.
;   -1   Le caract�re �tait valide et n doit-�tre conserv�.    
DEFWORD "?DIGIT",6,,QDIGIT ; ( c -- x 0 | n -1 )
    .word DUP,LIT,'a'-1,UGREATER,ZBRANCH,1f-$
    .word LIT,32,MINUS ; convertie en majuscule.
1:  .word DUP,LIT,'9',UGREATER,ZBRANCH,3f-$
    .word DUP,LIT,'A',ULESS,ZBRANCH,2f-$
    .word LIT,0,EXIT ; pas un digit
2:  .word LIT,7,MINUS    
3:  .word LIT,'0',MINUS
    .word DUP,BASE,FETCH,ULESS,EXIT
 
; nom: ?DOUBLE   ( c-addr u -- c-addr' u' f )    
;   V�rifie si le caract�re qui a mis fin � >NUMBER
;   est {'.'|','}. Si c'est le cas il s'agit d'un
;   nombre double pr�cision. saute le caract�re et retourne -1.
;   Dans le cas contraire retourne 0.
; arguments:
;   c-addr  pointe vers l'adresse du dernier caract�re analys� par >NUMBER
;   u       longueur de la cha�ne restante.
; retourne:
;   c-addr' acresse incr�ment� si le crit�re {'.'|','} est vrai.
;   u'      longueur d�cr�ment�e si le crit�re {'.'|','} est vrai.
;   f       indicateur Bool�en indiquant s'il s'agit d'un entier double.    
DEFWORD "?DOUBLE",7,,QDOUBLE ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,LIT,'.',EQUAL,ZBRANCH,2f-$
1:  .word LIT,1,SLASHSTRING,LIT,-1,BRANCH,9f-$
2:  .word OVER,CFETCH,LIT,',',EQUAL,ZBRANCH,8f-$
    .word BRANCH,1b-$
8:  .word LIT,0
9:  .word EXIT  
  
; nom: >NUMBER  (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )   
;   Converti la cha�ne en nombre en utilisant la valeur de BASE.
;   La conversion s'arr�te au premier caract�re non num�rique.
; arguments:  
; 'ud1'	    est initialis� � z�ro  
;  c-addr1 Adrese du d�but de la cha�ne � convertir en entier.
;  u1      Longueur du tampon � analyser.  
; retourne:
;  ud2     Entier double r�sultant de la conversion.
;  c-addr2  Adresse pointant apr�s le nombre dans le tampon.
;  u2      Longueur restante dans le tampon.  
DEFWORD ">NUMBER",7,,TONUMBER ; (ud1 c-addr1 u1 -- ud2 c-addr2 u2 )
1:   .word LIT,0,TOR ; indique si le dernier caract�re �tait un digit
2:   .word DUP,ZBRANCH,7f-$
     .word OVER,CFETCH,QDIGIT  ; ud1 c-addr u1 n|x f
     .word TBRANCH,4f-$
     .word RFROM,ZBRANCH,8f-$
     .word DROP,QDOUBLE,ZBRANCH,9f-$
     .word RFROM,RFROM,LIT,2,OR,TOR,TOR ; on change le flag du signe pour ajouter le flag double
     .word BRANCH,1b-$
4:   .word RDROP,LIT,-1,TOR ; dernier caract�re �tait un digit
     .word TOR,TWOSWAP,BASE,FETCH,UDSTAR
     .word RFROM,MPLUS,TWOSWAP
     .word LIT,1,SLASHSTRING,BRANCH,2b-$
7:   .word RFROM
8:   .word DROP
9:   .word EXIT
   
; nom: ?SIGN   ( c-addr u -- c-addr' u' f )   
;   V�rifie s'il y a un signe '-' � la premi�re postion de la cha�ne sp�cifi�e par <c-addr u>
;   Retourne f=VRAI si '-' sinon f=FAUX.    
;   S'il y a un signe avance au del� du signe
; arguments:
;   c-addr   adresse o� d�bute l'analyse.
;   u        longueur du tampon � analyser.
; retourne:
;   c-addr'  adresse incr�ment au del� du signe '-' s'il y a lieu.
;   u'       longueur restante dans le tampon.
;   f        Indicateur Bool�en, VRAI s'il le premier caract�re est '-'.   
DEFWORD "?SIGN",5,,QSIGN ; ( c-addr u -- c-addr' u' f )
    .word OVER,CFETCH,CLIT,'-',EQUAL,TBRANCH,8f-$
    .word LIT,0,BRANCH,9f-$
8:  .word LIT,1,SLASHSTRING,LIT,1
9:  .word EXIT
    
; nom: ?BASE  ( c-addr u1 -- c-addr' u1' )  
;   V�rifie s'il y a un modificateur de base
;   Si oui modifie la valeur de BASE en cons�quence et  avance le pointeur c-addr.
; arguments:
;   c-addr  Adresse du d�but de la cha�ne � analyser.
;   u1      longueur maximale de la cha�ne.
; retourne:
;   c-addr'  adresse incr�ment�e au del� du caract�re modificateur de BASE.
;   u'       longueur restante de la cha�ne.  
DEFWORD "?BASE",5,,QBASE ; ( c-addr u1 -- c-addr' u1'  )
    .word OVER,CFETCH,CLIT,'$',EQUAL,ZBRANCH,1f-$
    .word LIT,16,BASE,STORE,BRANCH,8f-$
1:  .word OVER,CFETCH,CLIT,'#',EQUAL,ZBRANCH,2f-$
    .word LIT,10,BASE,STORE,BRANCH,8f-$
2:  .word OVER,CFETCH,CLIT,'%',EQUAL,ZBRANCH,9f-$
    .word LIT,2,BASE,STORE
8:  .word SWAP,ONEPLUS,SWAP,ONEMINUS    
9:  .word EXIT

; nom: ?PRTCHAR   ( n -- f )
;   V�rifie si  'n' est une caract�re imprimable dans l'intervalle {32..126}
;   et retourne un indicateur bool�en.
; arguments:
;    n	 Entier simple
; retourne:
;    f Indicateur bool�en, vrai si n -> {32..126}  
DEFWORD "?PRTCHAR",8,,QPRTCHAR 
    .word DUP,BL,ULESS,TBRANCH,7f-$
    .word LIT,127,ULESS,ZBRANCH,8f-$
    .word TRUE,EXIT
7:  .word DROP
8:  .word FALSE,EXIT
  
; nom: ?QUOTED-CHAR  ( c-addr -- c-addr 0 | n -1 )
;   V�rifie si la cha�ne est un caract�re entre 2 apostrophe si c'est le cas
;   Empile la valeur ASCII du caract�re et TRUE, sinon retourne 'c-addr' et FALSE.
; arguments:
;    c-addr  Adresse de la cha�ne compt�e.
; retourne:
;   c-addr  0 Adresse orignale et FALSE si ce n'est pas un quoted char.
;   n	-1 Valeur ascii du caract�re et VRAI.  
DEFWORD "?QUOTED-CHAR",12,,QQUOTEDCHAR
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
  
; nom: ?NUMBER   ( c-addr -- c-addr 0 | n -1 )  
;   Conversion d'une cha�ne en nombre
;    c-addr indique le d�but de la cha�ne
;   Utilise la base active sauf si la cha�ne d�bute par '$'|'#'|'%'
;   Accepte aussi 'c'  c'est � dire un caract�re ASCII imprimable entre 2 apostrophes.
;   Dans ce cas la valeur de l'entier est la valeur ASCII du caract�re.  
;   Pour entrer un nombre double pr�cision il faut mettre un point ou une virgule 
;   � une position quelconque de la cha�ne saisie sauf � la premi�re position.
; arguments:
;   c-addr   adresse de la cha�ne � analyser.
; retourne:
;   c-addr 0   S'il la conversio �choue retourne l'adresse et l'indicateur FAUX	
;   n -1    Si la conversion r�ussie retourne l'entier et l'indicateur VRAI.  
DEFWORD "?NUMBER",7,,QNUMBER ; ( c-addr -- c-addr 0 | n -1 )
    .word QQUOTEDCHAR,ZBRANCH,2f-$
    .word TRUE,EXIT  
2:  .word BASE,FETCH,TOR ; sauvegarde la valeur de BASE 
    .word DUP,LIT,0,DUP,ROT,COUNT,QBASE  ; c-addr 0 0 c-addr' u'
    .word QSIGN,TOR  ; c-addr 0 0 c-addr' u' R: signFlag
4:  .word TONUMBER ; c-addr n1 n2 c-addr' u'
    .word ZBRANCH,1f-$ 
    .word RFROM,TWODROP,TWODROP,LIT,0,BRANCH,8f-$
1:  .word DROP,ROT,DROP
    .word RFETCH,ODD,ZBRANCH,2f-$
    .word DNEGATE
2:  .word RFROM,LIT,2,AND,TBRANCH,3f-$
    .word DROP
3:  .word LIT,-1
8:  .word RFROM,BASE,STORE ; restitue la valeur de BASE
9:  .word EXIT
    
    