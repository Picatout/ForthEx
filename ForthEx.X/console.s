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
;    Fonctions associées à la console.
;    Système de console basé sur des tables de vecteurs pour chaque
;    type de terminal. les tables contiennent le CFA de chaque fonction.
;    Il y a 2 terminaux, la console LOCAL constituée du clavier et du moniteur
;    branché à l'ordinateur ForthEx et la REMOTE qui utilise le port sériel RS-232
;    pour se connecter à un PC qui utilise à émulateur de terminal VT102.
;    On passe d'une console à l'autre en invoquant leur nom:
;    REMOTE  \ l'interface utilisateur utilise le port sériel.
;    LOCAL  \ l'interface utilisateur utilise le clavier et le moniteur de l'ordinateur.
;
;    La variable système SYSCONS contient le vecteur de la console sélectionnée.
;    Ce vecteur est une table contenant les fonctions à exécuter pour chacune des
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
;  Exemple de définition d'un mot vectorisé.
; : KEY  SYSCONS @ 0 VEXEC ;
    
    


; constantes numéro de fonction.    
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
;   Retourne l'adresse du vecteur des fonctions pour la console de l'éditeur de bloc.
;   BLKED utilise cette console en mode REMOTE. Cette console a de particulier que
;   les sorties sont dirigées vers le moniteur vidéo et le port sériel.    
; arguments:
;   aucun
; retourne:
;   a-addr Adresse du vecteur contenant les CFA des fonctions de la console de l'éditeur.
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
;   Variable système qui contient l'adresse de la table des fonctions du 
;   périphérique utilisé par la console. Information utilisée par la console.
;   La console peut fonctionner en mode LOCAL ou REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable SYSCONS   
DEFUSER "SYSCONS",7,,SYSCONS 
    
; nom: LOCAL ( -- )
;   Passe en mode console locale.
;   La console locale utilise le clavier et l'écran de l'ordinateur ForthEx.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "LOCAL",5,,LOCAL 
    .word LCINIT,LCCONS,CONSOLE,EXIT

    
; nom: REMOTE ( -- )
;   Passe en mode console VT102 via le port sériel.
;   Dans ce mode l'interface utilisateur utilise un terminal ou émulateur VT102
;   pour contrôler l'ordinateur. 
;   La commication est à 115200 bauds, 8 bits, 1 stop bit et pas de parité. 
;   Le contrôle de flux est logiciel via XON, XOFF.
;   L'ordinateur ForthEx n'implémente que partiellement le standard VT102
;   juste ce qui est nécessaire pour que la console REMOTE est les même fonctionnalités
;   que la console LOCAL.    
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "REMOTE",6,,REMOTE
    .word VTINIT,VTCONS,CONSOLE,EXIT
    
; CONSOLE ( a-addr --  )
;   Détermine la CONSOLE active {LOCAL,REMOTE}    
;   Affecte la variable système SYSCONS avec l'adresse 'a-addr'.
;   Cette adresse correspond à une table fonctions à utiliser par la console.
; arguments:
;   a-addr Adresse de la table des fonctions qui seront utilisées par la console.
; retourne:
;   rien 
HEADLESS CONSOLE,HWORD    
;DEFWORD "CONSOLE",7,,CONSOLE
    .word SYSCONS,STORE,EXIT
    
; nom: IS-LOCAL ( -- f )
;   Retourne un indicateur Booléen VRAI si la console est en mode LOCAL.
; arguments:
;   aucun
; retourne:
;   f	Indicateur Booléen vrai si console LOCAL.
DEFWORD "IS-LOCAL",8,,ISLOCAL
    .word SYSCONS,FETCH,LCCONS,EQUAL,EXIT
    
    
; nom: KEY  ( -- c )  
;   Lecture d'un caractère à partir de la console.
;   Les caractères invalides sont rejetés jusqu'à la réception
;   d'un caractère valide. Les caractères valides sont les
;   caractères ASCII {32..126}|VK_CR. Pour accepter tous les caractères
;   Il faut utiliser EKEY.
;   Attend indéfiniement la réception d'un caractère.    
; arguments:
;   aucun
;  retourne:
;    c   Caractère reçu de la console 
DEFWORD "KEY",3,,KEY  
    .word SYSCONS,FETCH,LIT,FN_KEY,VEXEC,EXIT
    
; nom: KEY?  ( -- f )
;   Retourne vrai si un caractère valide est disponible.
;   S'il y a des caractères non valides dans la file ils
;   sont jetés et rendus indisponibles.
; arguments:
;   aucun
; retourne:
;   f   booléen VRAI|FAUX
DEFWORD "KEY?",4,,KEYQ 
    .word SYSCONS,FETCH,LIT,FN_KEYQ,VEXEC,EXIT
    
; nom: EKEY  ( -- c )
;  Réception d'un code clavier incluant les codes de 
;  contrôles. Attend indéfiniment la réception d'un caractère.    
; arguments:
;   aucun
; retourne:
;   c   Code reçu.
DEFWORD "EKEY",4,,EKEY 
    .word SYSCONS,FETCH,LIT,FN_EKEY,VEXEC,EXIT

; nom: EKEY? ( -- f )
;   Vérifie s'il y a un code dans la file de réception de la console.
;   Retourne un booléen indiquant l'état.
; arguments:
;   aucun
; retourne:
;    f   Booléen VRAI|FAUX
DEFWORD "EKEY?",5,,EKEYQ  
    .word SYSCONS,FETCH,LIT,FN_EKEYQ,VEXEC,EXIT
    
    
; nom: EMIT ( c -- )
;  transmet un caractère à la console. Les caractères sont filtrés.
;  Les codes de contrôles reconnus sont mis en actions, les autres sont jetés.    
; arguments:
;    c   Caractère à transmettre.
; retourne:
;    rien    
DEFWORD "EMIT",4,,EMIT 
    .word SYSCONS,FETCH,LIT,FN_EMIT,VEXEC,EXIT
    
    
; nom: EMIT? ( -- f )
;  Vérifie si le terminal est prêt à recevoir. La console locale retourne toujours VRAI.
; arguments:
;    aucun
; retourne:
;    f      indicateur booléen FALSE|TRUE
DEFWORD "EMIT?",5,,EMITQ
    .word SYSCONS,FETCH,LIT,FN_EMITQ,VEXEC,EXIT
    
    
; nom: AT-XY ( u1 u2 -- )
;   Positionne le curseur de la console aux coordonnées {u1,u2}.
; arguments:
;   u1   Colonne {1..64} 
;   u2   Ligne {1..24}
;  retourne:
;    rien
DEFWORD "AT-XY",5,,ATXY 
    .word SYSCONS,FETCH,LIT,FN_ATXY,VEXEC,EXIT
    
; nom: PAGE ( -- )
;   Efface l'écran de la console.
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "PAGE",4,,PAGE 
    .word SYSCONS,FETCH,LIT,FN_PAGE,VEXEC,EXIT
    
; nom: EKEY>CHAR ( u -- u false | char true )
;   convertie un code reçu de la console en caractère affichable.
;   Si le code est valide. Le code u doit répondre au critères du filtre.
;   Accepte les codes VK_CR, VK_BACK, CTRL_X, CTRL_V {32-126}    
; arguments:
;   u  code reçu de la console
; retourne:
;    u	FALSE  Si le code n'est pas dans l'ensemble accepté.
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
;   Efface la ligne sur laquelle le curseur est situé.
;   Place le curseur au début de la ligne.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "DELLN",5,,DELLN   ; ( -- )
    .word LIT,CTRL_D,EMIT,EXIT
    
; nom: INSRTLN ( -- )
;   Décalle toutes les lignes à partir du curseur d'une position vers le bas.
;   Efface la ligne du curseur et positionne le curseur au début de celle-ci.
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "INSRTLN",7,,INSRTLN
    .word SYSCONS,FETCH,LIT,FN_INSRTLN,VEXEC,EXIT
    
; nom: RMVLN ( -- )
;   Supprime la ligne du curseur et décale toutes celles en dessus vers le haut.    
; arguments:
;   aucun
; retourne:
;    rien
DEFWORD "RMVLN",5,,RMVLN
    .word LIT,CTRL_X,EMIT,EXIT
    
    
; nom:  TYPE ( c-addr n+ -- )
;  Imprime une chaîne à l'écran de la console active.
; arguments:
;   c-addr  adresse du premier caractère de la chaîne.
;   n+   Longueur de la chaîne. 
; retourne:
;   rien    
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
    .word LIT, 0, DOQDO,BRANCH,9f-$
1:  .word DUP,CFETCH,EMIT,ONEPLUS
    .word DOLOOP,1b-$
9:  .word DROP, EXIT     

; nom: ETYPE ( c-addr u -- )
;   Imprime à l'écran de la console une chaîne qui réside en mémoire EDS.
; arguments:    
;   c-addr  Adresse du premier caractère de la chaîne.
;   u Longueur de la chaîne.
; retourne:
;   rien
DEFWORD "ETYPE",5,,ETYPE
    .word LIT,0,DOQDO,BRANCH,9f-$
1:  .word DUP,ECFETCH,EMIT,ONEPLUS
    .word DOLOOP,1b-$
9:  .word DROP,EXIT
    
; nom: DELETE  ( -- )
;   Supprime le caractère à la position du cureur.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELETE",6,,DELETE  ; ( -- )
    .word LIT,VK_DELETE,EMIT,EXIT
   
; nom: DELBACK  ( -- )
;   Supprime le caractère à gauche du curseur et recule le curseur d'une position.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELBACK",7,,DELBACK ; ( -- )
    .word LIT,VK_BACK,EMIT,EXIT

; nom: DELLINE  ( -- )    
;   Supprime la ligne sur laquelle le curseur est positionné.
;   Renvoie le curseur en début de ligne.    
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELLINE",7,,DELLINE ; ( -- )
    .word LIT,CTRL_X,EMIT,EXIT
 
; nom: DELEOL ( -- )
;  Efface tous les caractères de la position du curseur jusqu'à la fin de la ligne.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "DELEOL",6,,DELEOL
    .word LIT,CTRL_K,EMIT,EXIT
    
; nom: CR ( -- )    
;   Renvoie le curseur au début de la ligne suivante.
; arguments:
;   rien
; retourne:
;   rien    
DEFWORD "CR",2,,CR ; ( -- )
    .word LIT,VK_CR,EMIT,EXIT

; nom: CLS  ( -- )    
;   Efface l'écran de la console.
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
;   Détermine si les caractères s'affichent noir sur blanc ou l'inverse
;   Si l'indicateur Booléen 'f' est vrai les caractères s'affichent noir sur blanc.
;   Sinon ils s'affiche blancs sur noir (valeur par défaut).
; arguments:
;   f   Indicateur Booléen, inverse vidéo si vrai.    
; retourne:
;   rien    
DEFWORD "B/W",3,,BSLASHW
    .word SYSCONS,FETCH,LIT,FN_BSLASHW,VEXEC,EXIT
    
; nom: WITHELN ( n -- )
;   Imprime une ligne blanche et laisse le curseur au début de celle-ci
;   À la sortie le mode vidéo est inversé, i.e. noir/blanc.
; arguments:
;   n Numéro de la ligne {1..24}
; retourne:
;   rien
DEFWORD "WHITELN",7,,WHITELN
    .word SYSCONS,FETCH,LIT,FN_WHITELN,VEXEC,EXIT
    
; nom: WRAP ( f -- )
;   Active ou désactive le retour à la ligne automatique.
; arguments:
;   f Indicateur Booléen, VRAI wrap actif, FAUX inactif.
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
;   Vérifie si le mode retour automatique est actif.
; arguments:
;   aucun
; retourne:
;    f Indicateur Booléean VRAI si actif.
DEFCODE "?WRAP",5,,QWRAP
    DPUSH
    clr T
    btsc.b video_flags,#F_WRAP
    setm T
    NEXT
    
    
; nom: SCROLL ( f -- )
;   Active ou désactive le défilement de l'écran lorsque le curseur
;   atteint la fin de celui-ci, i.e. position {64,24}
;   Ce blocage du défilement ne concerne que EMIT.    
; arguments:
;   f Indicateur Booléen, VRAI définelement actif, FAUX inactif
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
    