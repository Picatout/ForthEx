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
;    Chaque console d�finie le code � ex�cuter pour chacune des fonction suivantes:
; HTML:
; <br><table border="single">
; <tr><th>fonction#</th><th>nom</th></tr>
; <tr><td>0</td><td>KEY</td></tr>
; <tr><td>1</td><td>KEY?</td></tr>
; <tr><td>2</td><td>EKEY</td></tr>
; <tr><td>3</td><td>EKEY?</td></tr>
; <tr><td>4</td><td>EMIT</td></tr>
; <tr><td>5</td><td>EMIT?</td></tr>
; <tr><td>6</td><td>AT-XY</td></tr>
; <tr><td>7</td><td>CLS</td></tr>
; <tr><td>8</td><td>XY?</td></tr>
; <tr><td>9</td><td>B/W</td></tr>
; <tr><td>10</td><td>INSRTLN</td></tr>
; <tr><td>11</td><td>RMVLN</td></tr>
; <tr><td>12</td><td>DELLN</td></tr>
; <tr><td>13</td><td>WHTLN</td></tr>
; <tr><td>14</td><td>CR</td></tr>    
; <tr><td>15</td><td>DELETE</td></tr>    
; <tr><td>16</td><td>DELEOL</td></tr>    
; <tr><td>17</td><td>BACKDEL</td></tr>    
; <tr><td>18</td><td>UP</td></tr>    
; <tr><td>19</td><td>DOWN</td></tr>    
; <tr><td>20</td><td>LEFT</td></tr>    
; <tr><td>21</td><td>RIGHT</td></tr>    
; <tr><td>22</td><td>HOME</td></tr>    
; <tr><td>23</td><td>END</td></tr>    
; <tr><td>24</td><td>TOP</td></tr>    
; <tr><td>25</td><td>BOTTOM</td></tr>    
; <tr><td>26</td><td>TAB</td></tr>    
; </table><br>    
; :HTML
    
; constantes num�ro de fonction.    
.equ FN_KEY, 0  ; KEY
.equ FN_KEYQ,1  ; KEY?
.equ FN_EKEY,2  ; EKEY
.equ FN_EKEYQ,3 ; EKEY?
.equ FN_EMIT,4  ; EMIT
.equ FN_EMITQ,5 ; EMIT?   
.equ FN_ATXY,6  ; AT-XY
.equ FN_CLS,7  ; CLS
.equ FN_XYQ,8  ; XY?  
.equ FN_BSLASHW,9 ; B/W
.equ FN_INSRTLN,10 ; INSERTLN
.equ FN_RMVLN,11   ; RMVLN
.equ FN_DELLN,12   ; DELLN 
.equ FN_WHITELN,13 ; WHITELN
.equ FN_CR,14 ; CR
.equ FN_DELETE,15 ; DELETE
.equ FN_DELEOL,16 ; DELEOL
.equ FN_BACKDEL,17 ; BACKDEL    
.equ FN_UP, 18 ; UP
.equ FN_DOWN,19 ; DOWN
.equ FN_LEFT,20 ; LEFT
.equ FN_RIGHT,21 ; RIGHT
.equ FN_HOME,22 ; HOME
.equ FN_END,23 ; END
.equ FN_TOP,24 ; PGUP
.equ FN_BOTTOM,25 ; PGDN    
.equ FN_TAB,26 ; TAB
    
; LC-CONS ( -- a-addr )
;   Retourne l'adresse du vecteur des fonctions pour la console locale.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse du vecteur contenant les CFA des fonctions de la console LOCAL.    
DEFTABLE "LC-CONS",7,F_HIDDEN,LCCONS
    .word LCKEY    ; 0 keyboard.s
    .word LCKEYQ   ; 1 keyboard.s
    .word LCEKEY   ; 2 keyboard.s
    .word LCEKEYQ  ; 3 keyboard.s
    .word PUTC     ; 4 tvout.s
    .word LCEMITQ  ; 5 tvout.s
    .word LCATXY   ; 6 tvout.s
    .word LCCLS    ; 7 tvout.s
    .word LCXYQ    ; 8 tvout.s
    .word LCBSLASHW ; 9  tvout.s
    .word LCINSRTLN ; 10 tvout.s
    .word LCRMVLN ; 11 tvout.s
    .word LCDELLN ; 12 tvout.s
    .word LCWHITELN ; 13 tvout.s
    .word LCCRLF ; 14 tvout.s
    .word LCDEL ; 15 tvout.s
    .word LCDELEOL ; 16 tvout.s
    .word LCBACKDEL ; 17 tvout.s
    .word LCUP ; 18 tvout.s
    .word LCDOWN ; 19 tvout.s
    .word LCLEFT ; 20 tvout.s
    .word LCRIGHT ; 21 tvout.s
    .word LCHOME ; 22 tvout.s
    .word LCEND ; 23 tvout.s
    .word LCTOP ; 24 tvout.s
    .word LCBOTTOM ; 25 tvout.s
    .word LCTAB ;  26 tvout.s
    
; VT-CONS ( -- a-addr )
;   Retourne l'adresse du vecteur des fonctions pour la console REMOTE.
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse du vecteur contenant les CFA des fonctions de la console locale.    
DEFTABLE "VT-CONS",7,F_HIDDEN,VTCONS
    .word VTKEY    ; 0 vt102.s
    .word VTKEYQ   ; 1 vt102.s
    .word VTEKEY   ; 2 serial.s
    .word SGETCQ   ; 3 serial.s
    .word VTPUTC    ; 4 vt102.s
    .word SREADYQ  ; 5 serial.s
    .word VTATXY   ; 6 vt102.s
    .word VTCLS    ; 7 vt102.s
    .word VTXYQ    ; 8 vt102.s
    .word VTBSLASHW ; 9 vt102.s
    .word VTINSRTLN ; 10 vt102.2
    .word VTRMVLN ; 11 vt102.s
    .word VTDELLN ; 12 vt102.s
    .word VTWHITELN ; 13 vt102.s
    .word VTCRLF ; 14 vt102.s
    .word VTDEL ; 15 tvout.s
    .word VTDELEOL ; 16 tvout.s
    .word VTBACKDEL ; 17 tvout.s
    .word VTUP ; 18 tvout.s
    .word VTDOWN ; 19 tvout.s
    .word VTLEFT ; 20 tvout.s
    .word VTRIGHT ; 21  tvout.s
    .word VTHOME ; 22 tvout.s
    .word VTEND ; 23 tvout.s
    .word VTTOP ;  24 tvout.s
    .word VTBOTTOM ; 25 tvout.s
    .word VTTAB ; 26 tvout.s
    
    
; SYSCONS   ( -- a-addr )
;   Variable syst�me qui contient l'adresse de la table des fonctions du 
;   p�riph�rique utilis� par la console. Information utilis�e par la console.
;   La console peut fonctionner en mode LOCAL ou REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable SYSCONS   
DEFUSER "SYSCONS",7,F_HIDDEN,SYSCONS 
    
; nom: LOCAL ( -- )
;   Transfert l'interface utilisateur � la console LOCAL.
;   La console LOCAL utilise le clavier et l'�cran de l'ordinateur ForthEx.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LOCAL",5,,LOCAL 
    .word LCINIT,LCCONS,CONSOLE,EXIT

    
; nom: REMOTE ( -- )
;   Transfert l'interface utilisateur vers la console s�rielle.
;   Cette interface utilisateur utilise un terminal ou �mulateur VT102
;   pour contr�ler l'ordinateur. 
;   La commication est � 115200 bauds, 8 bits, 1 stop bit et pas de parit�. 
;   Le contr�le de flux est logiciel (XON | XOFF).
;   L'�mulateur de terminal ne doit pas ajouter de LF (ASCII 10) lorsqu'il 
;   re�oit un CR (ASCII 13).     
;   L'ordinateur ForthEx n'impl�mente que partiellement le standard VT102
;   juste ce qui est n�cessaire pour que la console REMOTE ait les m�me fonctionnalit�s
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
    
; nom: LOCAL? ( -- f )
;   Retourne un indicateur Bool�en VRAI si la console est en mode LOCAL.
; arguments:
;   aucun
; retourne:
;   f Indicateur Bool�en vrai si console LOCAL.
DEFWORD "LOCAL?",6,,ISLOCAL
    .word SYSCONS,FETCH,LCCONS,EQUAL,EXIT
    
    
; CONSEXEC ( i*x u -- j*x )
;   Execute une fonction console
; arguments:    
;   i*x  arguments utilis�s par la fonction
;   u	Num�ro de la fonction.
; retourne:
;   j*x Valeurs retroun�s par la fonction.    
HEADLESS CONSEXEC,HWORD ; ( i*x u -- j*x )
    .word SYSCONS,FETCH,SWAP,VEXEC,EXIT
    
; nom: KEY  ( -- c )  
;   Attend ind�finiement la r�ception d'un caract�re de la console.    
;   Les caract�res invalides sont rejet�s jusqu'� la r�ception
;   d'un caract�re valide. 
;   KEY n'accepte que les caract�res graphiques {32..126}
;   Pour accepter tous les caract�res envoy�s par la console il faut
;   utiliser EKEY.    
; arguments:
;   aucun
;  retourne:
;    c   Caract�re re�u de la console dans l'intervalle {32..126}. 
DEFWORD "KEY",3,,KEY  
    .word LIT,FN_KEY,CONSEXEC,EXIT
    
; nom: KEY?  ( -- f )
;   Retourne vrai si un caract�re valide est disponible.
;   S'il y a des caract�res non valides dans la file ils
;   sont jet�s et rendus indisponibles.
; arguments:
;   aucun
; retourne:
;   f Indicateur bool�en VRAI s'il y a une touche disponible dans la file de r�ception.
DEFWORD "KEY?",4,,KEYQ 
    .word LIT,FN_KEYQ,CONSEXEC,EXIT
    
; nom: EKEY  ( -- c )
;  R�ception d'un code clavier incluant les codes de 
;  contr�les. Attend ind�finiment la r�ception d'un caract�re.    
; arguments:
;   aucun
; retourne:
;   c Code re�u.
DEFWORD "EKEY",4,,EKEY 
    .word LIT,FN_EKEY,CONSEXEC,EXIT

; nom: EKEY? ( -- f )
;   V�rifie s'il y a un code dans la file de r�ception de la console.
;   Retourne un bool�en indiquant l'�tat.
; arguments:
;   aucun
; retourne:
;    f   Indicateur Bool�en VRAI si un caract�re est disponible dans la file.
DEFWORD "EKEY?",5,,EKEYQ  
    .word LIT,FN_EKEYQ,CONSEXEC,EXIT
    
    
; nom: EMIT ( c -- )
;  Imprime les caract�res ASCII dans l'intervalle {32..126}
;  EMIT transmet tous les codes re�u sans filtre donc l'effet des codes
;  en dehors de l'intervalle {32..126} d�pend de la console utilis�e.   
;  Pour la console LOCAL  les codes 0..32 ont une repr�sentation graphique
;  et les codes {128..255} sont les m�me mais en inverse vid�o.
;  Pour la console REMOTE cel� peu d�pendre de l'�mulateur utilis�.
;  Par exemple, minicom pour les codes {0..31} affiche un rectangle avec de petits chiffres
;  � l'int�rieur et pour les codes de {128..255} il affiche un losange avec un '?' �
;  l'int�rieur.    
; arguments:
;    c Caract�re � transmettre.
; retourne:
;    rien    
DEFWORD "EMIT",4,,EMIT 
    .word LIT,FN_EMIT,CONSEXEC,EXIT
    
    
; nom: EMIT? ( -- f )
;  V�rifie si le terminal est pr�t � recevoir. La console LOCAL retourne toujours VRAI.
;  La console remote retourne faux si le terminal a envoy� un XOFF et que l'ordinateur
;  ForthEx est en attente d'un XON.    
; arguments:
;    aucun
; retourne:
;    f Indicateur Bool�en vrai si la console est en �tat de recevoir.
DEFWORD "EMIT?",5,,EMITQ
    .word LIT,FN_EMITQ,CONSEXEC,EXIT
    
    
; nom: AT-XY ( u1 u2 -- )
;   Positionne le curseur de la console aux coordonn�es {u1,u2}.
; arguments:
;   u1   Colonne {1..64} 
;   u2   Ligne {1..24}
;  retourne:
;    rien
DEFWORD "AT-XY",5,,ATXY 
    .word LIT,FN_ATXY,CONSEXEC,EXIT
    
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
;   n	Nombre d'espaces � imprimer.
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
    .word LIT,FN_DELLN,CONSEXEC,EXIT
    
; nom: RMVLN ( -- )
;   Supprime la ligne du curseur et d�cale toutes celles en dessus vers le haut. 
;   Place le curseur � la marge de gauche.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "RMVLN",5,,RMVLN
    .word LIT,FN_RMVLN,CONSEXEC,EXIT
    
; nom: INSRTLN ( -- )
;   D�calle toutes les lignes � partir du curseur d'une position vers le bas.
;   Laisse la ligne du curseur vide avec le curseur � la marge de gauche.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "INSRTLN",7,,INSRTLN
    .word LIT,FN_INSRTLN,CONSEXEC,EXIT
    
    
; nom:  TYPE ( c-addr n+ -- )
;  Imprime une cha�ne � l'�cran de la console.
;  TYPE utilise EMIT donc ne filtre pas les caract�res.    
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
;   ETYPE utilise EMIT donc ne filtre pas les caract�res.  
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
;   Supprime le caract�re � la position du curseur. Les caract�res � droite
;   sont d�cal�s vers la gauche d'une position.  
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELETE",6,,DELETE  ; ( -- )
    .word LIT,FN_DELETE,CONSEXEC,EXIT
   
; nom: BACKDEL  ( -- )
;   D�place le curseur d'un caract�re � gauche et supprime le caract�re. Les 
;   caract�res � droite sont d�cal�s vers la gauche d'une position.    
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "BACKDEL",7,,BACKDEL ; ( -- )
    .word LIT,FN_BACKDEL,CONSEXEC,EXIT

; nom: DELEOL ( -- )
;  Efface tous les caract�res de la position du curseur jusqu'� la fin de la ligne.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELEOL",6,,DELEOL
    .word LIT,FN_DELEOL,CONSEXEC,EXIT
    
; nom: CR ( -- )    
;   Renvoie le curseur � la marge gauche de la ligne suivante.
;   Le texte n'est pas modifi� il s'agit simplement d'un d�placement du curseur.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "CR",2,,CR ; ( -- )
    .word LIT,FN_CR,CONSEXEC,EXIT

; nom: CLS  ( -- )    
;   Efface l'�cran de la console.
;   Le standard ANSI Forth utilise le mot PAGE pour cette fonction mais CLS me
;   semble plus famillier.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "CLS",3,,CLS 
    .word LIT,FN_CLS,CONSEXEC,EXIT
    
; nom: XY?  ( -- u1 u2 )
;   Retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1 Colonne  {1..64}
;   u2 Ligne    {1..24}
DEFWORD "XY?",3,,XYQ
    .word LIT,FN_XYQ,CONSEXEC,EXIT

; nom: B/W  ( f -- )    
;   D�termine si les caract�res s'affichent noir sur blanc ou l'inverse
;   Si l'indicateur Bool�en 'f' est vrai les caract�res s'affichent noir sur blanc.
;   Sinon ils s'affichent blanc sur noir (valeur par d�faut).
; arguments:
;   f   Indicateur Bool�en, inverse vid�o si vrai.    
; retourne:
;   rien    
DEFWORD "B/W",3,,BSLASHW
    .word LIT,FN_BSLASHW,CONSEXEC,EXIT
    
; nom: WITHELN ( n -- )
;   Imprime une ligne blanche et laisse le curseur au d�but de celle-ci
;   � la sortie le mode vid�o est invers�, i.e. noir/blanc.
; arguments:
;   n Num�ro de la ligne {1..24}
; retourne:
;   rien
DEFWORD "WHITELN",7,,WHITELN
    .word LIT,FN_WHITELN,CONSEXEC,EXIT
    
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
    
; nom: TAB ( -- )
;  Avance le curseur texte � la prochaine colonne texte.
;  Par d�faut les colonnes sont de 4 caract�res de largeur.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "TAB",3,,TAB
    .word LIT,FN_TAB,CONSEXEC,EXIT

; nom: UP  ( -- )
;   D�place le curseur d'une ligne vers le haut.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "UP",2,,UP
    .word LIT,FN_UP,CONSEXEC,EXIT
    
; nom: DOWN  ( -- )
;   D�place le curseur d'une ligne vers le bas.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "DOWN",4,,DOWN
    .word LIT,FN_DOWN,CONSEXEC,EXIT
    
; nom: LEFT  ( -- )
;   D�place le curseur d'un caract�re vers la gauche.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LEFT",4,,LEFT
    .word LIT,FN_LEFT,CONSEXEC,EXIT
    
; nom: RIGHT  ( -- )
;   D�place le curseur d'un caract�re vers la droite.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "RIGHT",5,,RIGHT
    .word LIT,FN_RIGHT,CONSEXEC,EXIT
    
; nom: HOME  ( -- )
;   D�place le curseur au d�but de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "HOME",4,,HOME
    .word LIT,FN_HOME,CONSEXEC,EXIT
    
; nom: END  ( -- )
;   D�place le curseur � la fin de la ligne.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "END",3,,END
    .word LIT,FN_END,CONSEXEC,EXIT
    
; nom: TOP  ( -- )
;   D�place le curseur dans le coin sup�rieur gauche de l'�cran.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "TOP",3,,TOP
    .word LIT,FN_TOP,CONSEXEC,EXIT
    
; nom: BOTTOM  ( -- )
;   D�place le curseur dans le coin inf�rieur droit de l'�cran.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "BOTTOM",6,,BOTTOM
    .word LIT,FN_BOTTOM,CONSEXEC,EXIT
    
    