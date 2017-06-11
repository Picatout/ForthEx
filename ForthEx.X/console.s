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
;    type de terminal. les tables contiennent le CFA de chaque fonction.
;    Il y a 2 terminaux, la console LOCAL constitu�e du clavier et du moniteur
;    branch� � l'ordinateur ForthEx et la REMOTE qui utilise le port s�riel RS-232
;    pour se connecter � un PC qui utilise � �mulateur de terminal VT102.
;    On passe d'une console � l'autre en invoquant leur nom:
;    REMOTE  \ l'interface utilisateur utilise le port s�riel.
;    LOCAL  \ l'interface utilisateur utilise le clavier et le moniteur de l'ordinateur.
;
;    La variable syst�me SYSCONS contient le vecteur de la console s�lectionn�e.
;    Ce vecteur est une table contenant les fonctions � ex�cuter pour chacune des
;    fonctions suivantes:
; HTML:
; <table border="single">
; <tr><th>fonction#</th><th>nom</th></tr>
; <tr><td>0</td><td>KEY</td></tr>
; <tr><td>1</td><td>KEY?</td></tr>
; <tr><td>2</td><td>EKEY</td></tr>
; <tr><td>3</td><td>EKEY?</td></tr>
; <tr><td>4</td><td>EMIT</td></tr>
; <tr><td>5</td><td>EMIT?</td></tr>
; <tr><td>6</td><td>AT-XY</td></tr>
; <tr><td>7</td><td>PAGE</td></tr>
; <tr><td>8</td><td>EKEY>CHAR</td></tr>
; <tr><td>9</td><td>XY?</td></tr>
; <tr><td>10</td><td>B/W</td></tr>
; <tr><td>11</td><td>INSRTLN</td></tr>
; <tr><td>12</td><td>RMVLN</td></tr>
; <tr><td>13</td><td>DELLN</td></tr>
; <tr><td>14</td><td>WHTLN</td></tr>
; </table>    
; :HTML
;  Exemple de d�finition d'un mot vectoris�.
; : KEY  SYSCONS @ 0 VEXEC ;
    
    


; constantes num�ro de fonction.    
.equ FN_KEY, 0  ; KEY
.equ FN_KEYQ,1  ; KEY?
.equ FN_EKEY,2  ; EKEY
.equ FN_EKEYQ,3 ; EKEY?
.equ FN_EMIT,4  ; EMIT
.equ FN_EMITQ,5 ; EMIT?   
.equ FN_ATXY,6  ; AT-XY
.equ FN_PAGE,7  ; PAGE
.equ FN_EKEYTOCHAR,8 ; EKEY>CHAR
.equ FN_XYQ,9  ; XY?  
.equ FN_BSLASHW,10 ; B/W
.equ FN_INSRTLN,11 ; INSERTLN
.equ FN_RMVLN,12   ; RMVLN
.equ FN_DELLN,13   ; DELLN 
.equ FN_WHITELN,14 ; WHITELN
    
; nom: LC-CONS ( -- a-addr )
;   Retourne l'adresse du vecteur des fonctions pour la console locale.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse du vecteur contenant les CFA des fonctions de la console locale.    
DEFTABLE "LC-CONS",7,,LCCONS
    .word LCKEY    ; keyboard.s
    .word LCKEYQ   ; keyboard.s
    .word LCEKEY   ; keyboard.s
    .word LCEKEYQ  ; keyboard.s
    .word LCEMIT   ; tvout.s
    .word LCEMITQ  ; tvout.s
    .word LCATXY   ; tvout.s
    .word LCPAGE   ; tvout.s
    .word LCFILTER ; keyboard.s
    .word LCXYQ ; tvout.s
    .word LCBSLASHW   ; tvout.s
    .word LCINSRTLN ; tvout.s
    .word LCRMVLN ; tvout.s
    .word LCDELLN ; tvout.s
    .word LCWHITELN ; tvout.s
    
; nom: VT-CONS ( -- a-addr )
;   Retourne l'adresse du vecteur des fonctions pour la console locale.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse du vecteur contenant les CFA des fonctions de la console locale.    
DEFTABLE "VT-CONS",7,,VTCONS
    .word VTKEY    ; vt102.s
    .word VTKEYQ   ; vt102.s
    .word VTEKEY   ; serial.s
    .word SGETCQ   ; serial.s
    .word VTEMIT   ; vt102.s
    .word SREADYQ  ; serial.s
    .word VTATXY   ; vt102.s
    .word VTPAGE   ; vt102.s
    .word VTFILTER ; vt102.s
    .word VTXYQ ; vt102.s
    .word VTBSLASHW   ; vt102.s
    .word VTINSRTLN ; vt102.2
    .word VTRMVLN ; vt102.s
    .word VTDELLN ; vt102.s
    .word VTWHITELN ; vt102.s
    
; nom: ED-CONS ( -- a-addr )
;   Retourne l'adresse du vecteur des fonctions pour la console de l'�diteur de bloc.
;   BLKED utilise cette console en mode REMOTE. Cette console a de particulier que
;   les sorties sont dirig�es vers le moniteur vid�o et le port s�riel.    
; arguments:
;   aucun
; retourne:
;   a-addr Adresse du vecteur contenant les CFA des fonctions de la console de l'�diteur.
DEFTABLE "ED-CONS"7,,EDCONS
    .word VTKEY    ; vt102.s
    .word VTKEYQ   ; vt102.s
    .word VTEKEY   ; serial.s
    .word SGETCQ   ; serial.s
    .word EDEMIT   ; blockEdit.s
    .word SREADYQ  ; serial.s
    .word EDATXY   ; blockEdit.s
    .word EDPAGE   ; blockEdit.s
    .word VTFILTER ; vt102.s
    .word VTXYQ ; vt102.s
    .word EDBSLASHW ; blockEdit.s
    .word EDINSRTLN ; blockEdit.s
    .word EDRMVLN ; blockEdit.s
    .word EDDELLN ; blockEdit.s
    .word EDWHITELN ; blockEdit.s
    
    
; nom: SYSCONS   ( -- a-addr )
;   Variable syst�me qui contient l'adresse de la table des fonctions du 
;   p�riph�rique utilis� par la console. Information utilis�e par la console.
;   La console peut fonctionner en mode LOCAL ou REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable SYSCONS   
DEFUSER "SYSCONS",7,,SYSCONS 
    
; nom: LOCAL ( -- )
;   Passe en mode console locale.
;   La console locale utilise le clavier et l'�cran de l'ordinateur ForthEx.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LOCAL",5,,LOCAL 
    .word LCINIT,LCCONS,CONSOLE,EXIT

    
; nom: REMOTE ( -- )
;   Passe en mode console VT102 via le port s�riel.
;   Dans ce mode l'interface utilisateur utilise un terminal ou �mulateur VT102
;   pour contr�ler l'ordinateur. 
;   La commication est � 115200 bauds, 8 bits, 1 stop bit et pas de parit�. 
;   Le contr�le de flux est logiciel via XON, XOFF.
;   L'ordinateur ForthEx n'impl�mente que partiellement le standard VT102
;   juste ce qui est n�cessaire pour que la console REMOTE est les m�me fonctionnalit�s
;   que la console LOCAL.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "REMOTE",6,,REMOTE
    .word VTINIT,VTCONS,CONSOLE,EXIT
    
; CONSOLE ( a-addr --  )
;   D�termine la CONSOLE active {LOCAL,REMOTE}    
;   Affecte la variable syst�me SYSCONS avec l'adresse 'a-addr'.
;   Cette adresse correspond � une table fonctions � utiliser par la console.
; arguments:
;   a-addr Adresse de la table des fonctions qui seront utilis�es par la console.
; retourne:
;   rien 
HEADLESS CONSOLE,HWORD    
;DEFWORD "CONSOLE",7,,CONSOLE
    .word SYSCONS,STORE,EXIT
    
; nom: IS-LOCAL ( -- f )
;   Retourne un indicateur Bool�en VRAI si la console est en mode LOCAL.
; arguments:
;   aucun
; retourne:
;   f	Indicateur Bool�en vrai si console LOCAL.
DEFWORD "IS-LOCAL",8,,ISLOCAL
    .word SYSCONS,FETCH,LCCONS,EQUAL,EXIT
    
    
; nom: KEY  ( -- c )  
;   Lecture d'un caract�re � partir de la console.
;   Les caract�res invalides sont rejet�s jusqu'� la r�ception
;   d'un caract�re valide. Les caract�res valides sont les
;   caract�res ASCII {32..126}|VK_CR. Pour accepter tous les caract�res
;   Il faut utiliser EKEY.
;   Attend ind�finiement la r�ception d'un caract�re.    
; arguments:
;   aucun
;  retourne:
;    c   Caract�re re�u de la console 
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
;  R�ception d'un code clavier incluant les codes de 
;  contr�les. Attend ind�finiment la r�ception d'un caract�re.    
; arguments:
;   aucun
; retourne:
;   c   Code re�u.
DEFWORD "EKEY",4,,EKEY 
    .word SYSCONS,FETCH,LIT,FN_EKEY,VEXEC,EXIT

; nom: EKEY? ( -- f )
;   V�rifie s'il y a un code dans la file de r�ception de la console.
;   Retourne un bool�en indiquant l'�tat.
; arguments:
;   aucun
; retourne:
;    f   Bool�en VRAI|FAUX
DEFWORD "EKEY?",5,,EKEYQ  
    .word SYSCONS,FETCH,LIT,FN_EKEYQ,VEXEC,EXIT
    
    
; nom: EMIT ( c -- )
;  transmet un caract�re � la console. Les caract�res sont filtr�s.
;  Les codes de contr�les reconnus sont mis en actions, les autres sont jet�s.    
; arguments:
;    c   Caract�re � transmettre.
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
; arguments:
;   u1   Colonne {1..64} 
;   u2   Ligne {1..24}
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
;   Accepte les codes VK_CR, VK_BACK, CTRL_X, CTRL_V {32-126}    
; arguments:
;   u  code re�u de la console
; retourne:
;    u	FALSE  Si le code n'est pas dans l'ensemble accept�.
;    c	TRUE   Si le code est dans l'ensemble reconnu par le filtre.
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
  
; nom: DELLN  ( -- )
;   Efface la ligne sur laquelle le curseur est situ�.
;   Place le curseur au d�but de la ligne.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "DELLN",5,,DELLN   ; ( -- )
    .word LIT,CTRL_D,EMIT,EXIT
    
; nom: INSRTLN ( -- )
;   D�calle toutes les lignes � partir du curseur d'une position vers le bas.
;   Efface la ligne du curseur et positionne le curseur au d�but de celle-ci.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "INSRTLN",7,,INSRTLN
    .word SYSCONS,FETCH,LIT,FN_INSRTLN,VEXEC,EXIT
    
; nom: RMVLN ( -- )
;   Supprime la ligne du curseur et d�cale toutes celles en dessus vers le haut.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "RMVLN",5,,RMVLN
    .word LIT,CTRL_X,EMIT,EXIT
    
    
; nom:  TYPE ( c-addr n+ -- )
;  Imprime une cha�ne � l'�cran de la console active.
; arguments:
;   c-addr  adresse du premier caract�re de la cha�ne.
;   n+   Longueur de la cha�ne. 
; retourne:
;   rien    
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
    .word LIT, 0, DOQDO,BRANCH,9f-$
1:  .word DUP,CFETCH,EMIT,ONEPLUS
    .word DOLOOP,1b-$
9:  .word DROP, EXIT     

; nom: ETYPE ( c-addr u -- )
;   Imprime � l'�cran de la console une cha�ne qui r�side en m�moire EDS.
; arguments:    
;   c-addr  Adresse du premier caract�re de la cha�ne.
;   u Longueur de la cha�ne.
; retourne:
;   rien
DEFWORD "ETYPE",5,,ETYPE
    .word LIT,0,DOQDO,BRANCH,9f-$
1:  .word DUP,ECFETCH,EMIT,ONEPLUS
    .word DOLOOP,1b-$
9:  .word DROP,EXIT
    
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
 
; nom: DELEOL ( -- )
;  Efface tous les caract�res de la position du curseur jusqu'� la fin de la ligne.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELEOL",6,,DELEOL
    .word LIT,CTRL_K,EMIT,EXIT
    
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
    
    
; nom: XY?  ( -- u1 u2 )
;   Retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1 Colonne  {1..64}
;   u2 Ligne    {1..24}
DEFWORD "XY?",3,,XYQ
    .word SYSCONS,FETCH,LIT,FN_XYQ,VEXEC,EXIT

; nom: B/W  ( f -- )    
;   D�termine si les caract�res s'affichent noir sur blanc ou l'inverse
;   Si l'indicateur Bool�en 'f' est vrai les caract�res s'affichent noir sur blanc.
;   Sinon ils s'affiche blancs sur noir (valeur par d�faut).
; arguments:
;   f   Indicateur Bool�en, inverse vid�o si vrai.    
; retourne:
;   rien    
DEFWORD "B/W",3,,BSLASHW
    .word SYSCONS,FETCH,LIT,FN_BSLASHW,VEXEC,EXIT
    
; nom: WITHELN ( n -- )
;   Imprime une ligne blanche et laisse le curseur au d�but de celle-ci
;   � la sortie le mode vid�o est invers�, i.e. noir/blanc.
; arguments:
;   n Num�ro de la ligne {1..24}
; retourne:
;   rien
DEFWORD "WHITELN",7,,WHITELN
    .word SYSCONS,FETCH,LIT,FN_WHITELN,VEXEC,EXIT
    
; nom: WRAP ( f -- )
;   Active ou d�sactive le retour � la ligne automatique.
; arguments:
;   f Indicateur Bool�en, VRAI wrap actif, FAUX inactif.
; retourne:
;   rien
DEFCODE "WRAP",4,,WRAP
    cp0 T
    bra z,2f
    bset.b video_flags,#F_WRAP
    bra 9f
2:  bclr.b video_flags,#F_WRAP
9:  DPOP
    NEXT

; nom: ?WRAP ( -- f )
;   V�rifie si le mode retour automatique est actif.
; arguments:
;   aucun
; retourne:
;    f Indicateur Bool�ean VRAI si actif.
DEFCODE "?WRAP",5,,QWRAP
    DPUSH
    clr T
    btsc.b video_flags,#F_WRAP
    setm T
    NEXT
    
    
; nom: SCROLL ( f -- )
;   Active ou d�sactive le d�filement de l'�cran lorsque le curseur
;   atteint la fin de celui-ci, i.e. position {64,24}
;   Ce blocage du d�filement ne concerne que EMIT.    
; arguments:
;   f Indicateur Bool�en, VRAI d�finelement actif, FAUX inactif
; retourne:
;   rien
DEFCODE "SCROLL",6,,SCROLL
    cp0 T
    bra z,2f
    bset.b video_flags,#F_SCROLL
    bra 9f
2:  bclr.b video_flags,#F_SCROLL
9:  DPOP
    NEXT
    