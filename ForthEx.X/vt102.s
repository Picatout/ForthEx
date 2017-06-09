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

; NOM: vt102.s
; DESCRIPTION: s�quence de contr�le g�n�r�es par l'�mulateur de terminal minicom
;  en mode VT102.
;  La touche CTRL enfonc�e simultan�ment avec une lettre g�n�re un code entre
;  1 et 26 correspondant � l'ordre de la lettre dans l'alphabet. i.e. CTRL_A=1, CTRL_Z=26
;    
; DATE: 2017-04-12

SYSDICT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; caract�res de contr�les
; reconnu par terminal VT102
; ref: http://vt100.net/docs/vt102-ug/appendixc.html    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  s�quences de contr�les ^[
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; les 4 fl�ches
 
CUU: ; curseur vers le haut 
 .byte 27,91,65
CUD: ; curseur vers le bas
 .byte 27,91,66
CUF: ; curseur vers la droite
 .byte 27,91,67
CUB: ; curseur vers la gauche
 .byte 27,91,68
CCUU: ; CTRL curseur vers le haut
 .byte 27,91,49,59,53,65   
CCUD: ; CTRL curseur vers le bas
 .byte 27,91,49,59,53,66
CCUF: ; CTRL curseur vers la droite
 .byte 27,91,49,59,53,67
CCUB: ; CTRL curseur vers la gauche
 .byte 27,91,49,59,53,68

INSERT: 
 .byte 27,91,50,126
HOME:
 .byte 27,91,49,126    
VTDELETE:
 .byte 27,91,51,126
END:
 .byte 27,79,70
PGUP:
 .byte 27,91,53,126  
PGDN:
 .byte 27,91,54,126
CDELETE: ; CTRL_DELETE
 .byte 27,91,51,59,53,126
CHOME: ;CTRL_HOME
 .byte 27,91,51,59,53,72   
CEND: ; CTRL_END 
 .byte 27,91,51,59,53,70    
CPGUP: ; CTRL_PGUP
 .byte 27,91,53,59,53,126
CPGDN: ; CTRL_PGDN
 .byte 27,91,54,59,53,126
 
; nom: XON  ( -- c ) 
;   Constante, retourne le caract�re ASCII DC1
;   Ce caract�re est utilis� dans le contr�le de flux logicel pour signifier
;   que le terminal est pr�t � rececoir.
; arguments:
;   aucun
; retourne:
;   c   Caract�re ASCII DC1 valeur 17   
DEFCONST "XON",3,,XON,CTRL_Q 
 
; nom: XOFF  ( -- c ) 
;   Constante, retourne le caract�re ASCII DC3
;   Ce caract�re est utilis� dans le contr�le de flux logicel pour signifier
;   que le terminal n'est pas pr�t � rececoir.
; arguments:
;   aucun
; retourne:
;   c   Caract�re ASCII DC3 valeur 19   
DEFCONST "XOFF",4,,XOFF,CTRL_S

SYSDICT 
 VK_TILDE:
   .byte 0
   .byte VK_HOME
   .byte VK_INSERT
   .byte VK_DELETE
   .byte 0
   .byte VK_PGUP
   .byte VK_PGDN
   .byte 0
   .byte 0
   .byte 0
   
; re�u une s�quence ESC[ n  o� est une un digit, attend un ~   
HEADLESS EXPECT_TILDE,HWORD
    .word SGETC,LIT,'~',EQUAL,ZBRANCH,3f-$
    .word LIT,VK_TILDE,PLUS,CFETCH,EXIT
3:  .word DROP,LIT,CTRL_X,SPUTC,LIT,0,EXIT
  
; re�u une s�quence ESC[ suivit d'une lettre A,B,C,D  
HEADLESS ARROWS,HWORD ; ( c -- )
    .word DUP,LIT,'A',EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,VK_UP,EXIT
2:  .word DUP,LIT,'B',EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,VK_DOWN,EXIT
2:  .word DUP,LIT,'C',EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,VK_RIGHT,EXIT
2:  .word DUP,LIT,'D',EQUAL,ZBRANCH,2f-$
    .word DROP,LIT,VK_LEFT,EXIT
2:  .word DROP,LIT,0,EXIT      

; apr�s avoir re�u un ESC, reconnais les formes:  ESC[n~, ESC[{A|B|C|D} et ESCOF  
HEADLESS ESCTOVK,HWORD ; ( -- u )
    .word SGETC,DUP,LIT,'[',EQUAL,TBRANCH,2f-$
    .word LIT,'O',EQUAL,ZBRANCH,9f-$
    .word SGETC,LIT,'F',EQUAL,ZBRANCH,9f-$
    .word LIT,VK_END,EXIT
2:  .word DROP,SGETC,DUP,QDIGIT,ZBRANCH,2f-$
    .word EXPECT_TILDE,EXIT
2:  .word DROP,ARROWS,EXIT
9:  .word LIT,0,EXIT
  
; nom: VT-EKEY  ( -- u )
;   R�ception d'un code �tendue du terminal VT102. Les s�quencees ANSI
;   sont converties en touche virtuelles VK_xx. 
; arguments:
;   aucun
; retourne:
;   u   Code  re�u du terminal.
DEFWORD "VT-EKEY",7,,VTEKEY
    .word BASE,FETCH,TOR,DECIMAL
1:  .word SGETC,DUP,LIT,27,EQUAL,ZBRANCH,9f-$ 
    .word DROP,ESCTOVK,QDUP,ZBRANCH,1b-$
9:  .word RFROM,BASE,STORE,EXIT
    
 
; Table utilis�e par VT-FILTER
; pour la combinaison CTRL_x o� x est une lettre
; VT102 envoie l'ordre de la lettre dans l'alphabet
; i.e.  CTRL_a -> 1,  CTRL_b -> 2,..., CTRL_z -> 26    
SYSDICT
CTRL_TABLE:
    .word 0,0,0,0
    .word 0,0,0,0
    .word -1,0,0,0  ; VK_BACK
    .word -1,-1,0,0  ; CTRL_L,VK_CR
    .word 0,0,0,0
    .word 0,0,-1,0  ; CTRL_V 
    .word -1,0,0,0  ; CTRL_X
    .word 0,0,0,0  
 
; nom: VT-FILTER ( u -- u false | c true )    
;   Filtre u et retourne un caract�re 'c' et 'vrai' si u fait partie de l'ensemble reconnu.
;   sinon retourne 'u' et 'faux'   
;   accepte:
;      VK_CR, VK_BACK, CTRL_X, CTRL_V et {32-126}
; arguments:
;   u    Le code qui doit-�tre filtr�.
; retourne:
;   - refus�:    
;   u       m�me code
;   false   indicateur bool�en 
;   - reconnu:
;   c       caract�re reconnu.
;   true    indicateur bool�en.
DEFWORD "VT-FILTER",9,,VTFILTER
    .word DUP,BL,ULESS,TBRANCH,2f-$
    .word DUP,LIT,127,ULESS,TBRANCH,1f-$
    .word FALSE,EXIT
1:  .word TRUE,EXIT
2:  .word DUP,CELLS 
    .word LIT,CTRL_TABLE,PLUS,FETCH,EXIT    

; nom: VT-KEY? ( -- 0|c)
;   v�rifie s'il y a un caract�re r�pondant aux 
;   crit�res du filtre disponible dans la file. 
;   S'il y a des caract�res non valides les jettes.    
; arguments:
;   aucun
; retourne:
;   0   aucun caract�re disponible
;   c   le premier caract�re valide de la file.    
DEFWORD "VT-KEY?",7,,VTKEYQ
1: .word SGETCQ,DUP,ZBRANCH,9f-$
   .word DROP,VTEKEY,VTFILTER,TBRANCH,9f-$
   .word DROP,BRANCH,1b-$
9: .word EXIT
    
; nom: VT-KEY  ( -- c )
;   Attend la r�ception d'un caract�re valide du terminal VT102.
; arguments:
;   aucun 
; retourne:
;   c   caract�re filtr� 
DEFWORD "VT-KEY",6,,VTKEY    
1:  .word VTKEYQ,QDUP
    .word ZBRANCH,1b-$
    .word EXIT 

    
    
; nom: VT-EMIT ( c -- )
;  transmet un caract�re � la console VT102.
;  VT-EMIT filtre c rejette les caract�res non reconnus.    
; arguments:
;    c   caract�re � transmettre
; retourne:
;    rien    
DEFWORD "VT-EMIT",7,,VTEMIT
    .word DUP,QPRTCHAR,ZBRANCH,2f-$
    .word VTPUTC,EXIT
2:  .word DUP,LIT,CTRL_D,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDELLN,EXIT
2:  .word DUP,LIT,CTRL_K,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDELEOL,EXIT
2:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,2f-$
    .word SPUTC,EXIT
2:  .word DUP,LIT,VK_CR,EQUAL,ZBRANCH,2f-$
    .word DROP,VTCRLF,EXIT
2:  .word DUP,LIT,CTRL_J,EQUAL,ZBRANCH,2f-$
    .word DROP,VTCRLF,EXIT
2:  .word DUP,LIT,VK_BACK,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDELBACK,EXIT
2:  .word DUP,LIT,CTRL_X,EQUAL,ZBRANCH,2f-$
    .word DROP,VTRMVLN,EXIT
2:  .word DUP,LIT,CTRL_Y,EQUAL,ZBRANCH,2f-$
    .word DROP,VTINSRTLN,EXIT
2:  .word DUP,LIT,CTRL_L,EQUAL,ZBRANCH,2f-$
    .word SPUTC,EXIT
2:  .word DUP,LIT,VK_UP,EQUAL,ZBRANCH,2f-$
    .word DROP,VTUP,EXIT
2:  .word DUP,LIT,VK_DOWN,EQUAL,ZBRANCH,2f-$
    .word DROP,VTDOWN,EXIT
2:  .word DUP,LIT,VK_LEFT,EQUAL,ZBRANCH,2f-$
    .word DROP,VTLEFT,EXIT
2:  .word DUP,LIT,VK_RIGHT,EQUAL,ZBRANCH,2f-$
    .word DROP,VTRIGHT,EXIT
2:  .word DUP,LIT,VK_HOME,EQUAL,ZBRANCH,2f-$
    .word DROP,VTHOME,EXIT
2:  .word DUP,LIT,VK_END,EQUAL,ZBRANCH,2f-$
    .word DROP,VTEND,EXIT
2:  .word DROP    
    .word EXIT

; nom: VT-TYPE  ( c-addr u -- )
;   Transmet au terminal VT102 une cha�ne de caract�re. 
;   VT-TYPE utilise SPUTC, les caract�res de la cha�ne ne sont pas filtr�s.    
; arguments:
;   c-addr     adresse du premier caract�re
;   u          longueur de la cha�ne.
; retourne:
;   rien
DEFWORD "VT-TYPE",7,,VTTYPE
    .word LIT,0, DODO
1:  .word DUP,ECFETCH,SPUTC,ONEPLUS,DOLOOP,1b-$
    .word DROP,EXIT
    
; nom: VT-SNDARG  ( n -- )
;   convertie un entier en cha�ne avant de l'envoyer au terminal VT102.
; arguments:
;   n	entier � envoyer.
; retourne:  
;   rien
DEFWORD "VT-SNDARG",9,,VTSNDARG
    .word LIT,0,STR,VTTYPE,EXIT
    
    
; nom: ESC[ ( -- )
;   Envoie la s�quence 'ESC['  i.e. 27 91  au terminal VT102
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "ESC[",4,,ESCRBRAC
    .word CLIT,27,SPUTC,CLIT,'[',SPUTC,EXIT
    
; nom: VT-UP ( -- )
;   Envoie la s�quence ANSI 'ESC[A'  au terminal VT102.
;   Cette s�quence d�place le curseur � la ligne pr�c�dente de l'affichage.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-UP",5,,VTUP
    .word ESCRBRAC,LIT,'A',SPUTC,EXIT
    
; nom: VT-DOWN ( -- )
;   Envoie la s�quence ANSI 'ESC[B' au terminal VT102.
;   Cette s�quence d�place le curseur sur la ligne suivante de l'affichage.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "VT-DOWN",7,,VTDOWN
    .word ESCRBRAC,LIT,'B',SPUTC,EXIT

; nom: VT-RIGHT ( -- )
;   Envoie la s�quence ANSI 'ESC[C'  au terminal VT102.
;   Cete s�quence d�place le curseur d'un caract�re vers la droite.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "VT-RIGHT",8,,VTRIGHT
    .word VTGETCUR,DROP,LIT,CPL,EQUAL,ZBRANCH,2f-$,EXIT
2:  .word ESCRBRAC,LIT,'C',SPUTC,EXIT
    
; nom: VT-LEFT ( -- )
;   Envoie la s�quence ANSI 'ESC[D'  au terminal VT102.
;   Cette s�quence d�place le curseur d'un caract�re vers la gauche.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "VT-LEFT",7,,VTLEFT
    .word ESCRBRAC,LIT,'D',SPUTC,EXIT
    
; nom: VT-HOME ( -- )
;   Envoie une s�quence de contr�le au terminal VT102 pour d�placer le curseur en d�but de ligne.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "VT-HOME",7,,VTHOME
    .word VTGETCUR,DUP,ZEROLT,ZBRANCH,2f-$,DROP,EXIT
2:  .word SWAP,DROP,LIT,1,SWAP
    .word VTATXY,EXIT
    
; nom: VT-END ( -- )
;   Envoie une s�quence de contr�le au terminal VT102 pour d�placer le curseur � la fin de la ligne.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "VT-END",6,,VTEND
    .word VTGETCUR,DUP,ZEROLT,ZBRANCH,2f-$,DROP,EXIT
2:  .word SWAP,DROP,LIT,CPL-1,SWAP
    .word VTATXY,EXIT
    
; nom: VT-AT-XY ( u1 u2 -- )
;   Envoie une s�quence de contr�le au terminal VT102 pour positionner le curseur    
;   aux coordonn�es {u1,u2}
; arguments:
;   u1   num�ro de colonne {1..64}
;   u2   num�ro de ligne   {1..24}
;  retourne:
;    rien
DEFWORD "VT-AT-XY",8,,VTATXY
    .word ESCRBRAC,VTSNDARG
    .word LIT,';',SPUTC
    .word VTSNDARG
    .word LIT,'H',SPUTC
    .word EXIT

; nom: VT-DELEOL ( -- )
;   Efface tous les caract�res � partir du curseur jusqu'� la fin de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-DELEOL",9,,VTDELEOL
    .word ESCRBRAC,LIT,'K',SPUTC,EXIT
    
    
; nom: VT-PAGE ( -- )
;  Envoie une commande au terminal VT102 pour effacer l'�cran.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-PAGE",7,,VTPAGE
    .word LIT,CTRL_L,SPUTC
    .word EXIT
    
  
; nom: VT-DELBACK  ( -- )
;   Envoie une commande au terminal VT102 pour effacer le caract�re � gauche du curseur.
;   Le curseur est d�plac� � la position du caract�re supprim�.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-DELBACK",10,,VTDELBACK ; ( -- )
    .word LIT,VK_BACK,SPUTC
    .word BL,SPUTC,LIT,VK_BACK,SPUTC
    .word EXIT

; nom: VT-DELLN   ( -- )    
;   Envoie une commande au terminal VT102 pour supprimer la ligne sur laquelle
;   se trouve le curseur. Le curseur est d�plac� au d�but de la ligne.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-DELLN",8,,VTDELLN ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC
    .word LIT,'2',SPUTC
    .word LIT,'K',SPUTC,LIT,13,SPUTC,EXIT

; nom: VT-INSRTLN ( -- )
;   Ins�re une ligne avant la ligne o� se trouve le curseur.
;   S'il y a du texte sur la derni�re ligne ce texte est perdu.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-INSRTLN",10,,VTINSRTLN 
    .word ESCRBRAC,LIT,'L',SPUTC,VTHOME,EXIT
  
; nom: VT-RMVLN ( -- )
;   Supprime la ligne du curseur et d�cale toutes celles en dessous vers le haut.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "VT-RMVLN",8,,VTRMVLN
    .word ESCRBRAC,LIT,'M',SPUTC,EXIT

; nom: VT-WHITELN ( n -- )
;   Imprime ligne blanche de 64 caract�res sur la console REMOTE.
;   Laisse le curseur au d�but de la ligne et le mode noir/blanc.    
; arguments:
;   n  Num�ro de ligne, {1..24}
; retourne:
;   rien
DEFWORD "VT-WHILELN",10,,VTWHITELN
    .word FALSE,VTWRAP
    .word DUP,LIT,1,SWAP,VTATXY,TRUE,VTBSLASHW
    .word LIT,64,LIT,0,DODO
1:  .word BL,VTEMIT,DOLOOP,1b-$    
    .word LIT,1,SWAP,VTATXY,TRUE,VTWRAP,EXIT
    
; nom: VT-PRTINV  ( c-addr u n -- )
;   Imprime sur la REMOTE console la ligne de texte 'c-addr' sur la ligne 'n'.
;   Si 'f' est vrai imprime noir/blanc, sinon imprime blanc/noir.
; arguments:
;   c-addr Adresse du premier caract�re � imprimer.
;   u Nombre de caract�res
;   n Num�ro de la ligne {1..24}
DEFWORD "VT-PRTINV",9,,VTPRTINV
    .word DUP,VTWHITELN
    .word LIT,1,SWAP,VTATXY,VTTYPE,EXIT
    
; nom: VT-DSR  ( -- )
;   Envoie la s�quence de contr�le ANSI 'ESC[6n' au terminal VT102.
;   Le terminal r�pond � cette commande en envoyant la la position du curseur. 
;   VT-DSR est utilis� par VT-GETCUR
; arguments:
;   aucun
; retourne:
;   rien    
DEFWORD "VT-DSR",6,,VTDSR ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC,LIT,'6',SPUTC
    .word LIT,'n',SPUTC,EXIT

; nom: VT-GETP  ( c -- n f )
;   R�ception d'un param�tre num�rique envoy� par le terminal.    
;   La valeur num�rique est termin�e par le caract�re c.
;   VT-GETP est utilis� par les commandes qui attendent une r�ponse du terminal
;   en sachant que la r�ponse contient des valeur num�riques.    
; arguments:
;   c caract�re d�limitant la cha�ne num�rique.
; retourne:
;   n    nombre lue
;   f    indicateur bool�en de succ�s.
DEFWORD "VT-GETP",7,,VTGETP
    .word TOR,LIT,0
1:  .word SGETC,DUP,RFETCH,EQUAL,TBRANCH,8f-$
    .word DUP,DECIMALQ,ZBRANCH,2f-$ ; si ce n'est pas un digit d�cimial erreur
    .word TOBASE10,BRANCH,1b-$
2:  .word DROP,RDROP,FALSE,EXIT    
8:  .word DROP,RDROP,TRUE,EXIT  
    
  
; nom: ESCSEQ?  ( -- f )
;   Attend une s�quence d'�chappement  'ESC[' du terminal.
; arguments:
;   aucun
; retourne:
;   f  indicateur bool�en, FAUX si la s�quence re�u n'est pas ESC[  
DEFWORD "ESCSEQ?",7,,ESCSEQQ  ; ( -- f )
    .word SGETC,LIT,27,EQUAL,ZBRANCH,9f-$
    .word SGETC,LIT,'[',EQUAL,ZBRANCH,9f-$
    .word TRUE,EXIT
9:  .word FALSE,EXIT

  
; nom: VT-GETCUR  ( -- u1 u2 | -1 -1 )
;   Envoie une requ�te de position du curseur au terminal VT102 et fait la lecture de la r�ponse.
;   Contrairement � la console locale le terminal VT102 num�rote les colonnes et ligne � partir de 1.  
; arguments:
;   aucun
; retourne:
;   u1    colonne  {1..64}
;   u2    ligne    {1..24}
;   en cas d'erreur reoturne -1 -1  
DEFWORD "VT-GETCUR",9,,VTGETCUR ; ( -- u1 u2 | -1 -1 )
    .word VTDSR ; requ�te position du curseur
    ; attend la r�ponse
    .word ESCSEQQ,ZBRANCH,8f-$
    .word LIT,';',VTGETP,TBRANCH,2f-$
    .word DROP,BRANCH,8f-$
2:  .word LIT,'R',VTGETP,TBRANCH,2f-$
    .word TWODROP,BRANCH,8f-$
2:  .word SWAP,EXIT
8:  .word LIT,-1,DUP,EXIT    
   
; nom: VT-CRLF 
;   Envoie la s�quence 'CRTL_M CTRL_J'  (i.e. ASCII 13 10)  au terminal VT102.
;   Le terminal r�pond en d�placant le curseur au d�but de la ligne suivante.  
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "VT-CRLF",7,,VTCRLF
   .word LIT,CTRL_M,SPUTC,LIT,CTRL_J,SPUTC,EXIT
   
; nom: VT-PUTC
;   Envoie un caract�re au terminal VT102. Les caract�res ne sont pas filtr�s.
;   Si la colonne du curseur apr�s l'affichage du caract�re est � 65 force un VT-CRLF.   
; arguments:
;   c   caract�re � envoyer au terminal.
; retourne:
;   rien
DEFWORD "VT-PUTC",7,,VTPUTC
   .word SPUTC,VTGETCUR,DROP
   .word LIT,CPL+1,EQUAL,ZBRANCH,9f-$
   .word QWRAP,TBRANCH,2f-$,VTLEFT,EXIT
2: .word VTCRLF
9: .word EXIT
 
; nom: VT-B/W  ( f -- )
;   Terminal VT102. 
;   D�termine si les caract�res s'affichent noir sur blanc ou l'inverse
;   Si l'indicateur Bool�en 'f' est vrai les caract�res s'affichent noir sur blanc.
;   Sinon ils s'affiche blancs sur noir (valeur par d�faut).
; arguments:
;   f   Indicateur Bool�en, inverse vid�o si vrai.    
; retourne:
;   rien    
DEFWORD "VT-B/W",6,,VTBSLASHW
    .word DUP,LCBSLASHW
    .word ESCRBRAC,ZBRANCH,2f-$
    .word LIT,'7',SPUTC
2:  .word LIT,'m',SPUTC,EXIT
   
; nom: VT-WRAP ( f -- )
;   Active ou d�sactive le retour � la ligne automatique.
; arguments:
;   f Indicateur Bool�en, VRAI actif, FAUX inactif.
; retourne:
;   rien
DEFWORD "VT-WRAP",7,,VTWRAP
    .word DUP,LCWRAP,ESCRBRAC,LIT,'?',SPUTC,LIT,'7',SPUTC
    .word ZBRANCH,2f-$,LIT,'h',SPUTC,EXIT
2:  .word LIT,'l',SPUTC,EXIT    
    
    
    