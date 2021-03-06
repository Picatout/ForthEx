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
; DATE: 2017-04-12
; DESCRIPTION: 
; P�riph�rique pour la comminication avec un terminal ou �mulateur
; VT102, impl�mentation partielle. 
; Le contr�le de flux est logiciel, i.e. XON, XOFF
; La vitesse de transmission par d�faut est 115200 bauds.
; Configuration:  8 bits, 1 stop, pas de parit�.    
; Lorsque le terminal re�ois un ASCII 13 (CR) il ne doit pas ajout� un ASCII 10 (LF).
    
SYSDICT
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; caract�res de contr�les
; reconnu par terminal VT102
; ref: http://vt100.net/docs/vt102-ug/appendixc.html    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  s�quences de contr�le ESC[
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; les 4 fl�ches
 
;CUU: ; curseur vers le haut 
; .byte 27,91,65
;CUD: ; curseur vers le bas
; .byte 27,91,66
;CUF: ; curseur vers la droite
; .byte 27,91,67
;CUB: ; curseur vers la gauche
; .byte 27,91,68
;CCUU: ; CTRL curseur vers le haut
; .byte 27,91,49,59,53,65   
;CCUD: ; CTRL curseur vers le bas
; .byte 27,91,49,59,53,66
;CCUF: ; CTRL curseur vers la droite
; .byte 27,91,49,59,53,67
;CCUB: ; CTRL curseur vers la gauche
; .byte 27,91,49,59,53,68
;
;INSERT: 
; .byte 27,91,50,126
;HOME:
; .byte 27,91,49,126    
;VTDELETE:
; .byte 27,91,51,126
;END:
; .byte 27,79,70
;PGUP:
; .byte 27,91,53,126  
;PGDN:
; .byte 27,91,54,126
;CDELETE: ; CTRL_DELETE
; .byte 27,91,51,59,53,126
;CHOME: ;CTRL_HOME
; .byte 27,91,51,59,53,72   
;CEND: ; CTRL_END 
; .byte 27,91,51,59,53,70    
;CPGUP: ; CTRL_PGUP
; .byte 27,91,53,59,53,126
;CPGDN: ; CTRL_PGDN
; .byte 27,91,54,59,53,126
 
.section .vt102.bss bss
; maintient une copie locale de la position du curseur
; pour des raison d'efficacit�. 
vtcolon: .space 1
vtline: .space 1

; sauvegarde la position du curseur vt102
; u1 colonne
; u2 ligne
HEADLESS CPOS_STORE,CODE  ; ( u1 u2 -- )
    mov T, W0
    mov.b WREG,vtline
    DPOP
    mov T, W0
    mov.b WREG,vtcolon
    DPOP
    NEXT

; empile la position du curseur vt102    
; u1 colonne
; u2 ligne
HEADLESS CPOS_FETCH,CODE ; ( -- u1 u2 )	
    DPUSH
    mov.b vtcolon,WREG
    ze W0,T
    DPUSH
    mov.b vtline,WREG
    ze W0,T
    NEXT
    
; curseur en d�but de ligne
HEADLESS COLON1,CODE
    mov #1,W0
    mov.b WREG,vtcolon
    NEXT
    
; incr�mente vtcolon
HEADLESS INC_COLON,CODE
    mov #CPL,W0
    cp.b vtcolon
    bra z, 9f
    inc.b vtcolon
9:  NEXT

; d�cr�mente vtcolon
HEADLESS DEC_COLON,CODE
    mov #1,W0
    cp.b vtcolon
    bra z, 9f
    dec.b vtcolon
9:  NEXT
    
; incr�mente vtline
HEADLESS INC_LINE,CODE
    mov #LPS,W0
    cp.b vtline
    bra z, 9f
    inc.b vtline
9:  NEXT
    
    
; VT-INIT ( -- )
;   Initialise le p�riph�rique VT102. 115200 BAUD 8N1
; arguments;
;   aucun
; retourne:
;  rien
HEADLESS VTINIT,HWORD    
;DEFWORD "VT-INIT",7,,VTINIT
    .word B115200,BAUD,XON,VTCLS,LIT,1,DUP,CPOS_STORE,EXIT
    
 
; nom: XON  ( -- ) 
;   Envoie le caract�re de contr�le XON (ASCII 17) au terminal VT102
; arguments:
;   aucun
; retourne:
;   c   Caract�re ASCII DC1 valeur 17   
DEFWORD "XON",3,,XON
    .word LIT,CTRL_Q,SPUTC,EXIT 
 
; nom: XOFF  ( -- c ) 
;   Envoie le caract�re de contr�le XOFF (ASCII 19) au terminal VT102.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "XOFF",4,,XOFF
    .word LIT,CTRL_S,SPUTC,EXIT

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
   
; re�u une s�quence ESC[ n  o� n est un un digit, attend un ~   
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
2:  .word DROP,SGETC,DUP,DIGITQ,ZBRANCH,2f-$
    .word SWAP,DROP,EXPECT_TILDE,EXIT
2:  .word DROP,ARROWS,EXIT
9:  .word LIT,0,EXIT
  
;  VT-EKEY  ( -- u )
;   R�ception d'un code �tendue du terminal VT102. Les s�quencees ANSI
;   sont converties en touche virtuelles VK_xx. 
; arguments:
;   aucun
; retourne:
;   u   Code  re�u du terminal.
HEADLESS VTEKEY,HWORD  
;DEFWORD "VT-EKEY",7,,VTEKEY
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
    .word -1,0,0,0  ; CTRL_D
    .word -1,0,0,0  ; VK_BACK
    .word -1,-1,0,0  ; CTRL_L,VK_CR
    .word 0,0,0,0
    .word 0,0,-1,0  ; CTRL_V 
    .word 0,0,0,0  
    .word 0,0,0,0  
 
; VT-FILTER ( u -- u false | c true )    
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
HEADLESS VTFILTER,HWORD    
;DEFWORD "VT-FILTER",9,,VTFILTER
    .word DUP,BL,ULESS,TBRANCH,2f-$
    .word DUP,LIT,128,ULESS,TBRANCH,1f-$
    .word FALSE,EXIT
1:  .word TRUE,EXIT
2:  .word DUP,CELLS 
    .word LIT,CTRL_TABLE,PLUS,FETCH,EXIT    

;  VT-KEY? ( -- 0|c)
;   v�rifie s'il y a un caract�re r�pondant aux 
;   crit�res du filtre disponible dans la file. 
;   S'il y a des caract�res non valides les jettes.    
; arguments:
;   aucun
; retourne:
;   0   aucun caract�re disponible
;   c   le premier caract�re valide de la file.
HEADLESS VTKEYQ,HWORD    
;DEFWORD "VT-KEY?",7,,VTKEYQ
1: .word SGETCQ,DUP,ZBRANCH,9f-$
   .word DROP,VTEKEY,DUP,QPRTCHAR,TBRANCH,9f-$
   .word DROP,BRANCH,1b-$
9: .word EXIT
    
;  VT-KEY  ( -- c )
;   Attend la r�ception d'un caract�re valide du terminal VT102.
; arguments:
;   aucun 
; retourne:
;   c   caract�re filtr� 
HEADLESS VTKEY,HWORD 
;DEFWORD "VT-KEY",6,,VTKEY    
1:  .word VTKEYQ,QDUP
    .word ZBRANCH,1b-$
    .word EXIT 

;  VT-TYPE  ( c-addr u -- )
;   Transmet au terminal VT102 une cha�ne de caract�re. 
;   VT-TYPE utilise SPUTC, les caract�res de la cha�ne ne sont pas filtr�s.    
; arguments:
;   c-addr     adresse du premier caract�re
;   u          longueur de la cha�ne.
; retourne:
;   rien
HEADLESS VTTYPE,HWORD    
;DEFWORD "VT-TYPE",7,,VTTYPE
    .word LIT,0, DODO
1:  .word DUP,ECFETCH,SPUTC,ONEPLUS,DOLOOP,1b-$
    .word DROP,EXIT
    
;  VT-SNDARG  ( n -- )
;   convertie un entier en cha�ne avant de l'envoyer au terminal VT102.
; arguments:
;   n	entier � envoyer.
; retourne:  
;   rien
HEADLESS VTSNDARG,HWORD    
;DEFWORD "VT-SNDARG",9,,VTSNDARG
    .word LIT,0,STR,VTTYPE,EXIT
    
    
; ESC[ ( -- )
;   Envoie la s�quence 'ESC['  i.e. 27 91  au terminal VT102
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS ESCLBRAC,HWORD    
;DEFWORD "ESC[",4,,ESCLBRAC
    .word CLIT,27,SPUTC,CLIT,'[',SPUTC,EXIT

; VT-UP ( -- )
;   Envoie la s�quence ANSI 'ESC[A'  au terminal VT102.
;   Cette s�quence d�place le curseur � la ligne pr�c�dente de l'affichage.    
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTUP,HWORD    
;DEFWORD "VT-UP",5,,VTUP
    .word CPOS_FETCH,DUP,LIT,1,EQUAL,ZBRANCH,2f-$,TWODROP,EXIT
2:  .word ESCLBRAC,LIT,'A',SPUTC,ONEMINUS,CPOS_STORE,EXIT
  
;  VT-DOWN ( -- )
;   Envoie la s�quence ANSI 'ESC[B' au terminal VT102.
;   Cette s�quence d�place le curseur sur la ligne suivante de l'affichage.    
; arguments:
;   aucun
; retourne:
;    rien
HEADLESS VTDOWN,HWORD  
;DEFWORD "VT-DOWN",7,,VTDOWN
    .word CPOS_FETCH,DUP,LIT,LPS,EQUAL,ZBRANCH,2f-$,TWODROP,EXIT
2:  .word ESCLBRAC,LIT,'B',SPUTC,ONEPLUS,CPOS_STORE,EXIT
  
; VT-RIGHT ( -- )
;   Envoie la s�quence ANSI 'ESC[C'  au terminal VT102.
;   Cete s�quence d�place le curseur d'un caract�re vers la droite.    
; arguments:
;   aucun
; retourne:
;    rien
HEADLESS VTRIGHT,HWORD  
;DEFWORD "VT-RIGHT",8,,VTRIGHT
    .word CPOS_FETCH,DROP,LIT,CPL,EQUAL,ZBRANCH,2f-$,EXIT
2:  .word ESCLBRAC,LIT,'C',SPUTC,INC_COLON,EXIT
    
;  VT-LEFT ( -- )
;   Envoie la s�quence ANSI 'ESC[D'  au terminal VT102.
;   Cette s�quence d�place le curseur d'un caract�re vers la gauche.    
; arguments:
;   aucun
; retourne:
;    rien
HEADLESS VTLEFT,HWORD  
;DEFWORD "VT-LEFT",7,,VTLEFT
    .word CPOS_FETCH,DROP,LIT,1,EQUAL,ZBRANCH,2f-$,EXIT
2:  .word ESCLBRAC,LIT,'D',SPUTC,CPOS_FETCH,SWAP,ONEMINUS,SWAP
    .word CPOS_STORE,EXIT
  
;  VT-HOME ( -- )
;   Envoie une s�quence de contr�le au terminal VT102 pour d�placer le curseur en d�but de ligne.    
; arguments:
;   aucun
; retourne:
;    rien
HEADLESS VTHOME,HWORD    
;DEFWORD "VT-HOME",7,,VTHOME
    .word COLON1,CPOS_FETCH,VTATXY,EXIT
    
;  VT-END ( -- )
;   Envoie une s�quence de contr�le au terminal VT102 pour d�placer le curseur � la fin de la ligne.
; arguments:
;   aucun
; retourne:
;    rien
HEADLESS VTEND,HWORD    
;DEFWORD "VT-END",6,,VTEND
    .word CPOS_FETCH,SWAP,DROP,LIT,CPL,SWAP,VTATXY,EXIT
    
; VT-TOP
;   Envoie le curseur � colonne 1, ligne 1.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS VTTOP,HWORD
    .word LIT,1,DUP,VTATXY,EXIT
    
; VT-BOTTOM
;   Envoie le curseur � la position 64,24
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS VTBOTTOM,HWORD
    .word LIT,CPL,LIT,LPS,VTATXY,EXIT
    
; VT-TAB ( -- )
;   D�placele curseur � la prochaine colonne.
; arguments:
;   aucun
; retourne:
;   rien    
HEADLESS VTTAB,HWORD
    .word CPOS_FETCH,SWAP,HTAB,CFETCH,SWAP ; s: line tab col
    .word OVER,SLASH,OVER,STAR,PLUS,SWAP,VTATXY,EXIT
    
;  VT-AT-XY ( u1 u2 -- )
;   Envoie une s�quence de contr�le au terminal VT102 pour positionner le curseur    
;   aux coordonn�es {u1,u2}
; arguments:
;   u1   num�ro de colonne {1..64}
;   u2   num�ro de ligne   {1..24}
;  retourne:
;    rien
HEADLESS VTATXY,HWORD    
;DEFWORD "VT-AT-XY",8,,VTATXY
    .word SWAP,LIT,CPL,UMIN,SWAP
    .word LIT,LPS,UMIN
2:  .word TWODUP,CPOS_STORE
    .word ESCLBRAC,VTSNDARG
    .word LIT,';',SPUTC
    .word VTSNDARG
    .word LIT,'H',SPUTC
    .word EXIT

;  VT-DELEOL ( -- )
;   Efface tous les caract�res � partir du curseur jusqu'� la fin de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTDELEOL,HWORD    
;DEFWORD "VT-DELEOL",9,,VTDELEOL
    .word ESCLBRAC,LIT,'K',SPUTC,CPOS_SYNC,EXIT
    
    
;  VT-CLS ( -- )
;  Envoie une commande au terminal VT102 pour effacer l'�cran.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTCLS,HWORD    
;DEFWORD "VT-CLS",6,,VTCLS
    .word LIT,CTRL_L,SPUTC,LIT,1,DUP,CPOS_STORE
    .word EXIT
    

;  VT-DELETE ( -- )
;   Supprime le caract�re � la position du curseur ferme l'espace.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTDEL,HWORD    
;DEFWORD "VT-DEL",6,,VTDEL
    .word ESCLBRAC,LIT,'1',SPUTC,LIT,'P',SPUTC
    .word EXIT
    
;  VT-INSERT ( -- )
;   Ins�re un espace � la position du curseur.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTINSERT,HWORD    
;DEFWORD "VT-INSERT",9,,VTINSERT
    .word ESCLBRAC,LIT,'4',SPUTC,LIT,'h',SPUTC
    .word BL,SPUTC,VTLEFT
    .word ESCLBRAC,LIT,'4',SPUTC,LIT,'l',SPUTC
    .word CPOS_FETCH,LIT,65,OVER,VTATXY,VTDEL
    .word VTATXY
    .word EXIT
    
; VT-BACKDEL  ( -- )
;   Envoie une commande au terminal VT102 pour effacer le caract�re � gauche du curseur.
;   Le curseur est d�plac� � la position du caract�re supprim�.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTBACKDEL,HWORD    
;DEFWORD "VT-BACKDEL",10,,VTBACKDEL ; ( -- )
    .word CPOS_FETCH,DROP,LIT,1,EQUAL,ZBRANCH,2f-$,EXIT
2:  .word LIT,VK_BACK,SPUTC,ESCLBRAC,LIT,'1',SPUTC,LIT,'P',SPUTC
    .word DEC_COLON,EXIT

; VT-DELLN   ( -- )    
;   Envoie une commande au terminal VT102 pour supprimer la ligne sur laquelle
;   se trouve le curseur. Le curseur est d�plac� au d�but de la ligne.    
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTDELLN,HWORD    
;DEFWORD "VT-DELLN",8,,VTDELLN ; ( -- )
    .word ESCLBRAC,LIT,'2',SPUTC
    .word LIT,'K',SPUTC,LIT,13,SPUTC
    .word COLON1,EXIT

;  VT-RMVLN ( -- )
;   Supprime la ligne du curseur et d�cale toutes celles en dessous vers le haut.    
; arguments:
;   aucun
; retourne:
;    rien
HEADLESS VTRMVLN,HWORD    
;DEFWORD "VT-RMVLN",8,,VTRMVLN
    .word ESCLBRAC,LIT,'M',SPUTC,COLON1,EXIT
    
; VT-INSRTLN ( -- )
;   Ins�re une ligne avant la ligne o� se trouve le curseur.
;   S'il y a du texte sur la derni�re ligne ce texte est perdu.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTINSRTLN,HWORD    
;DEFWORD "VT-INSRTLN",10,,VTINSRTLN 
    .word ESCLBRAC,LIT,'L',SPUTC,COLON1,CPOS_FETCH,VTATXY,EXIT
  
; VT-WHITELN ( n -- )
;   Imprime ligne blanche de 64 caract�res sur la console REMOTE.
;   Laisse le curseur au d�but de la ligne et le mode noir/blanc.    
; arguments:
;   n  Num�ro de ligne, {1..24}
; retourne:
;   rien
HEADLESS VTWHITELN,HWORD    
;DEFWORD "VT-WHILELN",10,,VTWHITELN
    .word FALSE,WRAP
    .word DUP,LIT,1,SWAP,VTATXY,TRUE,VTBSLASHW
    .word LIT,64,LIT,0,DODO
1:  .word BL,SPUTC,DOLOOP,1b-$    
    .word LIT,1,SWAP,VTATXY,TRUE,WRAP,EXIT
    
; nom: VT-PRTINV  ( c-addr u n -- )
;   Imprime sur la REMOTE console la ligne de texte 'c-addr' sur la ligne 'n'.
;   Imprime en inverse vid�o, blanc/noir. L'affichage demeure en inverse vid�eo.
;   Pour revenir en vid�o normal il faut faire la phrase: FALSE B/W
;   L'inversion vid�o affecte aussi la console LOCAL.    
; arguments:
;   c-addr Adresse du premier caract�re � imprimer.
;   u Nombre de caract�res
;   n Num�ro de la ligne {1..24}
DEFWORD "VT-PRTINV",9,,VTPRTINV
    .word DUP,VTWHITELN
    .word LIT,1,SWAP,VTATXY,VTTYPE,EXIT
    
; VT-DSR  ( -- )
;   Envoie la s�quence de contr�le ANSI 'ESC[6n' au terminal VT102.
;   Le terminal r�pond � cette commande en envoyant la la position du curseur. 
;   VT-DSR est utilis� par VT-XY?
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTDSR,HWORD    
;DEFWORD "VT-DSR",6,,VTDSR ; ( -- )
    .word LIT,27,SPUTC,LIT,'[',SPUTC,LIT,'6',SPUTC
    .word LIT,'n',SPUTC,EXIT

; VT-GETP  ( c -- n f )
;   R�ception d'un param�tre num�rique envoy� par le terminal.    
;   La valeur num�rique est termin�e par le caract�re c.
;   VT-GETP est utilis� par les commandes qui attendent une r�ponse du terminal
;   en sachant que la r�ponse contient des valeur num�riques.    
; arguments:
;   c caract�re d�limitant la cha�ne num�rique.
; retourne:
;   n    nombre lue
;   f    indicateur bool�en de succ�s.
HEADLESS VTGETP,HWORD    
;DEFWORD "VT-GETP",7,,VTGETP
    .word TOR,LIT,0
1:  .word SGETC,DUP,RFETCH,EQUAL,TBRANCH,8f-$
    .word DUP,DECIMALQ,ZBRANCH,2f-$ ; si ce n'est pas un digit d�cimial erreur
    .word TOBASE10,BRANCH,1b-$
2:  .word DROP,RDROP,FALSE,EXIT    
8:  .word DROP,RDROP,TRUE,EXIT  
    
  
; ESCSEQ?  ( -- f )
;   Attend une s�quence d'�chappement  'ESC[' du terminal.
; arguments:
;   aucun
; retourne:
;   f  indicateur bool�en, FAUX si la s�quence re�u n'est pas ESC[  
HEADLESS ESCSEQQ,HWORD  
;DEFWORD "ESCSEQ?",7,,ESCSEQQ  ; ( -- f )
    .word SGETC,LIT,27,EQUAL,ZBRANCH,9f-$
    .word SGETC,LIT,'[',EQUAL,ZBRANCH,9f-$
    .word TRUE,EXIT
9:  .word FALSE,EXIT

  
;  VT-XY?  ( -- u1 u2 | -1 -1 )
;   Envoie une requ�te de position du curseur au terminal VT102 et fait la lecture de la r�ponse.
;   Contrairement � la console locale le terminal VT102 num�rote les colonnes et ligne � partir de 1.  
; arguments:
;   aucun
; retourne:
;   u1    colonne  {1..64}
;   u2    ligne    {1..24}
;   en cas d'erreur reoturne -1 -1  
HEADLESS VTXYQ,HWORD  
;DEFWORD "VT-XY?",9,,VTXYQ ; ( -- u1 u2 | -1 -1 )
    .word VTDSR ; requ�te position du curseur
    ; attend la r�ponse
    .word ESCSEQQ,ZBRANCH,8f-$
    .word LIT,';',VTGETP,TBRANCH,2f-$
    .word DROP,BRANCH,8f-$
2:  .word LIT,'R',VTGETP,TBRANCH,2f-$
    .word TWODROP,BRANCH,8f-$
2:  .word SWAP,EXIT
8:  .word LIT,-1,DUP,EXIT    
   
; synchronise les variables vtcolon et vtline avec la position
; rapport�e par VT-XY?
HEADLESS CPOS_SYNC,HWORD
    .word VTXYQ,CPOS_STORE,EXIT
  
;  VT-CRLF 
;   Envoie la s�quence 'CRTL_M CTRL_J'  (i.e. ASCII 13 10)  au terminal VT102.
;   Le terminal r�pond en d�placant le curseur au d�but de la ligne suivante.  
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS VTCRLF,HWORD    
;DEFWORD "VT-CRLF",7,,VTCRLF
   .word LIT,CTRL_M,SPUTC
   .word CPOS_FETCH,SWAP,DROP,LIT,LPS,EQUAL,ZBRANCH,2f-$
   .word LIT,video_flags,CFETCH,LIT,1,LIT,F_SCROLL,LSHIFT,AND,ZBRANCH,9f-$
2: .word LIT,CTRL_J,SPUTC
9: .word CPOS_SYNC,EXIT
   
; VT-PUTC ( c -- )
;   Envoie un caract�re au terminal VT102. Les caract�res ne sont pas filtr�s.
; arguments:
;   c   caract�re � envoyer au terminal.
; retourne:
;   rien
HEADLESS VTPUTC,HWORD   
;DEFWORD "VT-PUTC",7,,VTPUTC
   .word SPUTC,CPOS_FETCH,DROP
   .word LIT,CPL,EQUAL,ZBRANCH,9f-$
   .word QWRAP,TBRANCH,2f-$,VTLEFT,EXIT
2: .word VTCRLF,EXIT
9: .word INC_COLON,EXIT
 
;  VT-B/W  ( f -- )
;   Terminal VT102. 
;   D�termine si les caract�res s'affichent noir sur blanc ou l'inverse
;   Si l'indicateur Bool�en 'f' est vrai les caract�res s'affichent noir sur blanc.
;   Sinon ils s'affiche blancs sur noir (valeur par d�faut).
; arguments:
;   f   Indicateur Bool�en, inverse vid�o si vrai.    
; retourne:
;   rien    
HEADLESS VTBSLASHW,HWORD 
;DEFWORD "VT-B/W",6,,VTBSLASHW
    .word DUP,LCBSLASHW
    .word ESCLBRAC,ZBRANCH,2f-$
    .word LIT,'7',SPUTC
2:  .word LIT,'m',SPUTC,EXIT
   
    
    
    