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
;
; NOM: console.s
; DATE: 2017-04-27
; DESCRIPTION: 
;    Fonctions associ�es � la console.
;    Syst�me de console bas� sur des tables de vecteurs pour chaque
;    type de terminal. les tables contiennent le XT de chaque fonction.
;    Les fonctions sont celles d�finies dans le standard DPANS-94
;    REF: http://lars.nocrew.org/dpans/dpans10.htm#10.6.1
;
;    Il a 2 terminaux, la console LOCAL constitu�e du clavier et du moniteur
;    branch� � l'ordinateur ForthEx et la REMOTE qui utilise le port s�riel RS-232
;    pour se connect� � un PC qui utilise � �mulateur de terminal VT102.
;    On passe d'une console � l'autre avec les 2 phrases suivantes:
;    REMOTE CONSOLE  \ l'interface utilisateur utilise le port s�riel.
;    LOCAL CONSOLE   \ l'interface utilisateur utilise le clavier et le moniteur
;                    \ de l'ordinateur ForthEx. C'est la console par d�faut.    
;
;    La variable syst�me SYSCONS contient le vecteur de la console s�lectionn�e.
;    Ce vecteur est une table contenant les fonctions � ex�cuter pour chacun des
;    mots d�finis dans DPANS-94, tel qu'indiquer dans la table suivante.
;        
;FNBR   NOM       LCONCOLE     RCONCOLE
;       DPANS-94    CFA          CFA
;========================================
;0      KEY        LC-KEY       VT-KEY
;1      KEY?       LC-KEY?      VT-CHAR?
;2      EKEY       LC-EKEY      VT-ECHAR
;3      EKEY?      LC-EKEY?     SGETC?
;4      EMIT       LC-EMIT      VT-EMIT
;5      EMIT?      LC-EMIT?     VT-EMIT?    
;6      AT-XY      CURPOS       VT-AT-XY
;7      PAGE       CLS          VT-PAGE
;8      EKEY>CHAR  LC-FILTER    VT-FILTER
;9                 LC-GETCUR    VT-GETCUR
    
;
;  Exemple de d�finition d'un mot vectoris�.
; : KEY  SYSCONS @ FN_KEY VEXEC ;
    

; table des vecteurs pour la console LOCAL.
    
; table des vecteurs pour pour la console REMOTE.
    

; d�finitions des mot du standard DPANS-94

; constantes num�ro de fonction.    
.equ FN_KEY, 0
.equ FN_KEYQ,1
.equ FN_EKEY,2
.equ FN_EKEYQ,3
.equ FN_EMIT,4
.equ FN_EMITQ,5    
.equ FN_ATXY,6
.equ FN_PAGE,7
.equ FN_EKEYTOCHAR,8
.equ FN_GETCUR,9    
 
;table de vecteur pour la console locale
DEFTABLE "LC-CONS",7,,LCCONS
    .word LCKEY    ; keyboard.s
    .word LCKEYQ   ; keyboard.s
    .word LCEKEY   ; keyboard.s
    .word LCEKEYQ  ; keyboard.s
    .word LCEMIT   ; TVout.s
    .word LCEMITQ  ; TVout.s
    .word CURPOS   ; TVout.s
    .word LCPAGE   ; TVout.s
    .word LCFILTER ; keyboard.s
    .word LCGETCUR ; TVout.s
    
; table des vecteurs pour la console s�rielle.    
DEFTABLE "SERCONS",7,,SERCONS
    .word VTKEY    ; vt102.s
    .word VTKEYQ   ; vt102.s
    .word SGETC    ; serial.s
    .word SGETCQ   ; serial.s
    .word VTEMIT   ; vt102.s
    .word SREADYQ  ; serial.s
    .word VTATXY   ; vt102.s
    .word VTPAGE   ; vt102.s
    .word VTFILTER ; vt102.s
    .word VTGETCUR ; vt102.s
    
; nom: LOCAL ( -- a-addr )
;   Empile le vecteur de la table LCONSOLE qui sert d'argument pour CONSOLE.
;   Efface l'�cran local.    
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la table LCONSOLE    
DEFWORD "LOCAL",5,,LOCAL 
    .word LCPAGE,LCCONS,EXIT

; nom: REMOTE ( -- a-addr )
;   Empile le vecteur de la table LREMOTE qui sert d'argument pour CONSOLE.
;   Envoie une commande au terminal VT102 pour effacer l'�cran.    
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la table LREMOTE    
DEFWORD "REMOTE",6,,REMOTE
    .word TRUE,SERENBL
    .word LIT,4,LIT,0,DODO
1:  .word LIT,65,SPUTC,DOLOOP,1b-$
    .word LIT,CTRL_L,SPUTC,SERCONS,EXIT
    
; nom: CONSOLE ( a-addr --  )
;   D�termine la console active. 
;   Cette information est enregistr�e dans la variable syst�me SYSCONS    
; arguments:
;   a-addr   adresse de la table des fonctions de la nouvelle console.
; retourne:
;   rien   
DEFWORD "CONSOLE",7,,CONSOLE
    .word SYSCONS,STORE,EXIT
    
    
; nom: KEY  ( -- c )  
;   Lecture d'un caract�re � partir de la console active
;   les caract�res invalides sont rejet�s jusqu'� la r�ception
;   d'un caract�re valide. Les caract�res valides sont les
;   caract�res ASCII {32..126}. Pour accepter tous les caract�res
;   Il faut utiliser EKEY.
;   Attend ind�finiement la r�ception d'un caract�re.    
; arguments:
;   aucun
;  retourne:
;    c   caract�re re�u de la console 
DEFWORD "KEY",3,,KEY  
    .word SYSCONS,FETCH,LIT,FN_KEY,VEXEC,EXIT
    
; nom: KEY?  ( -- f )
;   Retourne vrai si un caract�re valide est disponible.
;   S'il y a des caract�res non valides dans la file ils
;   sont jet�s et rendus indisponibles.
; arguments:
;   aucun
; retourne:
;   f   bool�en VRAI|FAUX
DEFWORD "KEY?",4,,KEYQ 
    .word SYSCONS,FETCH,LIT,FN_KEYQ,VEXEC,EXIT
    
; nom: EKEY  ( -- c )
;  R�ception d'un �v�nement clavier incluant les codes de 
;  contr�les. Attend ind�finiment la r�ception d'un caract�re.    
; arguments:
;   aucun
; retourne:
;   c   caract�re re�u
DEFWORD "EKEY",4,,EKEY 
    .word SYSCONS,FETCH,LIT,FN_EKEY,VEXEC,EXIT

; nom: EKEY? ( -- f )
;   V�rifie s'il y a un caract�re dans la file de r�ception de la console.
;   Retourne un bool�en indiquant l'�tat.
; arguments:
;   aucun
; retourne:
;    f   bool�en VRAI|FAUX
DEFWORD "EKEY?",5,,EKEYQ  
    .word SYSCONS,FETCH,LIT,FN_EKEYQ,VEXEC,EXIT
    
    
; nom: EMIT ( c -- )
;  transmet un caract�re � la console. Les caract�res sont filtr�s.
; arguments:
;    c   caract�re � transmettre.
; retourne:
;    rien    
DEFWORD "EMIT",4,,EMIT 
    .word SYSCONS,FETCH,LIT,FN_EMIT,VEXEC,EXIT
    
    
; nom: EMIT? ( -- f )
;  V�rifie si le terminal est pr�t � recevoir. La console locale retourne toujours VRAI.
; arguments:
;    aucun
; retourne:
;    f      indicateur bool�en FALSE|TRUE
DEFWORD "EMIT?",5,,EMITQ
    .word SYSCONS,FETCH,LIT,FN_EMITQ,VEXEC,EXIT
    
    
; nom: AT-XY ( u1 u2 -- )
;   Positionne le curseur de la console aux coordonn�es {u1,u2}.
;   Pour la console locale la num�rotation commence � z�ro mais pour le
;   terminal VT102 la num�rotation commence � 1.    
; arguments:
;   u1   colonne 
;   u2   ligne
;  retourne:
;    rien
DEFWORD "AT-XY",5,,ATXY 
    .word SYSCONS,FETCH,LIT,FN_ATXY,VEXEC,EXIT
    
; nom: PAGE ( -- )
;   Efface l'�cran de la console.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "PAGE",4,,PAGE 
    .word SYSCONS,FETCH,LIT,FN_PAGE,VEXEC,EXIT
    
; nom: EKEY>CHAR ( u -- u false | char true )
;   convertie un code re�u de la console en caract�re affichable.
;   Si le code est valide. Le code u doit r�pondre au crit�res du filtre.
; arguments:
;   u  code re�u de la console
; retourne:
;    u FALSE  si le code n'est pas dans l'ensemble {32..126} VK_CR, VK_BACK
;    c TRUE   si le code est dans l'ensemble reconnu par le filtre.
DEFWORD "EKEY>CHAR",9,,EKEYTOCHAR
    .word SYSCONS,FETCH,LIT,FN_EKEYTOCHAR,VEXEC,EXIT
    

; nom: SPACE ( -- )
;   Imprime un espace sur la console.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "SPACE",5,,SPACE
    .word LIT,VK_SPACE,EMIT,EXIT

; nom: SPACES ( n -- )
;   Imprime n espaces sur la console.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "SPACES",6,,SPACES
    .word DUP,LIT,0,GREATER,TBRANCH,1f-$
    .word DROP,EXIT
1:  .word LIT,0,DODO
2:  .word SPACE,DOLOOP,2b-$
    .word EXIT
  
; nom: CLEARLN  ( -- )
;   Efface la ligne sur laquelle le curseur est situ�.
;   Place le curseur au d�but de la ligne.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "CLEARLN",7,,CLEARLN   ; ( -- )
    .word LIT,CTRL_X,EMIT,EXIT
    
; nom:  TYPE ( c-addr n+ -- )
;  Imprime une cha�ne � l'�cran de la console active.
; arguments:
;   c-addr  adresse du premier caract�re de la cha�ne.
;   n+   Longueur de la cha�ne. 
; retourne:
;   rien    
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
    .word DUP,TBRANCH,1f-$
    .word TWODROP, EXIT
1:  .word LIT, 0, DODO
2:  .word DUP,CFETCH,EMIT,ONEPLUS
    .word DOLOOP,2b-$
    .word DROP, EXIT     

; nom: DELETE  ( -- )
;   Supprime le caract�re � la position du cureur.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELETE",6,,DELETE  ; ( -- )
    .word LIT,VK_DELETE,EMIT,EXIT
   
; nom: DELBACK  ( -- )
;   Supprime le caract�re � gauche du curseur et recule le curseur d'une position.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELBACK",7,,DELBACK ; ( -- )
    .word LIT,VK_BACK,EMIT,EXIT

; nom: DELLINE  ( -- )    
;   Supprime la ligne sur laquelle le curseur est positionn�.
;   Renvoie le curseur en d�but de ligne.    
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELLINE",7,,DELLINE ; ( -- )
    .word LIT,CTRL_X,EMIT,EXIT
 
; nom: CR ( -- )    
;   Renvoie le curseur au d�but de la ligne suivante.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "CR",2,,CR ; ( -- )
    .word LIT,VK_CR,EMIT,EXIT

; nom: CLS  ( -- )    
;   Efface l'�cran de la console.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "CLS",3,,CLS 
    .word SYSCONS,FETCH,LIT,FN_PAGE,VEXEC,EXIT
    
    
; nom: GETCUR  ( -- u1 u2 )
;   retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1    colonne  locale {0..63} remote {1..64}
;   u2    ligne    locale {0..23} remote {1..24}
DEFWORD "GETCUR",6,,GETCUR
    .word SYSCONS,FETCH,LIT,FN_GETCUR,VEXEC,EXIT
