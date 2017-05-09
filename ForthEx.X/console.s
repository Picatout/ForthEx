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
; DESCRIPTION: fonction associé à la console.
;    Système de console basé sur des tables de vecteurs pour chaque
;    type de terminal. les tables contiennent le XT de chaque fonction.
;    Les fonctions sont celles définies dans le standard DPANS-94
;    ref: http://lars.nocrew.org/dpans/dpans10.htm#10.6.1
;
;    Il a 2 terminaux, la console LOCAL constituée du clavier et du moniteur
;    branché à l'ordinateur ForthEx et la REMOTE qui utilise le port sériel RS-232
;    pour se connecté à un PC qui utilise à émulateur de terminal VT102.
;    On passe d'une console à l'autre avec les 2 phrases suivantes:
;    REMOTE CONSOLE  \ l'interface utilisateur utilise le port sériel.
;    LOCAL CONSOLE   \ l'interface utilisateur utilise le clavier et le moniteur
;                    \ de l'ordinateur ForthEx. C'est la console par défaut.    
;
;    La variable système SYSCONS contient le vecteur de la console sélectionnée.
;    Ce vecteur est une table contenant les fonctions à exécuter pour chacun des
;    mots définis dans DPANS-94, tel qu'indiquer dans la table suivante.
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
;  Exemple de définition d'un mot vectorisé.
; : KEY  SYSCONS @ FN_KEY VEXEC ;
    

; table des vecteurs pour la console LOCAL.
    
; table des vecteurs pour pour la console REMOTE.
    

; définitions des mot du standard DPANS-94

; constantes numéro de fonction.    
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
    
; table des vecteurs pour la console sérielle.    
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
;  empile le vecteur de la table LCONSOLE
; arguments:
;   aucun
; retourne:
;   a-addr  adresse de la table LCONSOLE    
DEFWORD "LOCAL",5,,LOCAL 
    .word LCPAGE,LCCONS,EXIT

; nom: REMOTE ( -- a-addr )
;  empile le vecteur de la table LREMOTE
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
;  détermine la console active. Cette information
;  est enregistrée dans la variable système SYSCONS    
; arguments:
;   a-addr   adresse de la table des fonctions de la nouvelle console
; retourne:
;   rien.   
DEFWORD "CONSOLE",7,,CONSOLE
    .word SYSCONS,STORE,EXIT
    
    
; nom: KEY  ( -- c )  
;   Lecture d'un caractère à partir de la console active
;   les caractères invalides sont rejetés jusqu'à la réception
;   d'un caractère valide. Les caractères valides sont les
;   caractères ASCII {32..126}. Pour accepter tous les caractères
;   Il faut utiliser EKEY.
;   Attend indéfiniement la réception d'un caractère.    
; arguments:
;   aucun
;  retourne:
;    c   caractère reçu de la console 
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
;  Réception d'un événement clavier incluant les codes de 
;  contrôles. Attend indéfiniment la réception d'un caractère.    
; arguments:
;   aucun
; retourne:
;   c   caractère reçu
DEFWORD "EKEY",4,,EKEY 
    .word SYSCONS,FETCH,LIT,FN_EKEY,VEXEC,EXIT

; nom: EKEY? ( -- f )
;   Vérifie s'il y a un caractère dans la file de réception.
;   retourne un booléen indiquant l'état.
; arguments:
;   aucun
; retourne:
;    f   booléen VRAI|FAUX
DEFWORD "EKEY?",5,,EKEYQ  
    .word SYSCONS,FETCH,LIT,FN_EKEYQ,VEXEC,EXIT
    
    
; nom: EMIT ( c -- )
;  transmet un caractère à la console.
; argument:
;    c   caractère à transmettre
; retourne:
;    rien    
DEFWORD "EMIT",4,,EMIT 
    .word SYSCONS,FETCH,LIT,FN_EMIT,VEXEC,EXIT
    
    
; nom: EMIT? ( -- f )
;  vérifie si le terminal est prêt à recevoir
; arguments:
;    aucun
; retourne:
;    f      indicateur booléen FALSE|TRUE
DEFWORD "EMIT?",5,,EMITQ
    .word SYSCONS,FETCH,LIT,FN_EMITQ,VEXEC,EXIT
    
    
; nom: AT-XY ( u1 u2 -- )
;   Positionne le curseur de la console.
; arguments:
;   u1   colonne 
;   u2   ligne
;  retourne:
;    rien
DEFWORD "AT-XY",5,,ATXY 
    .word SYSCONS,FETCH,LIT,FN_ATXY,VEXEC,EXIT
    
; nom: PAGE ( -- )
;  Efface l'écran du terminal
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "PAGE",4,,PAGE 
    .word SYSCONS,FETCH,LIT,FN_PAGE,VEXEC,EXIT
    
; nom: EKEY>CHAR ( u -- u false | char true )
;   converti un code reçu de la console en caractère affichable.
;   Si le code est valide.
; arguments:
;   u  code reçu de la console
; retourne:
;    u FALSE  si le code n'est pas dans l'ensemble {32..126}
;    c TRUE   si le code est dans l'ensemble {32..126}
DEFWORD "EKEY>CHAR",9,,EKEYTOCHAR
    .word SYSCONS,FETCH,LIT,FN_EKEYTOCHAR,VEXEC,EXIT
    

; nom: SPACE ( -- )
; imprime un espace
; arguments:
;   aucun
; retourne:
;    rien
;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "SPACE",5,,SPACE ; ( -- )
    .word LIT,VK_SPACE,EMIT,EXIT


; nom: SPACES
; imprime n espaces
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "SPACES",6,,SPACES ; ( n -- )
    .word DUP,LIT,0,GREATER,TBRANCH,1f-$
    .word DROP,EXIT
1:  .word LIT,0,DODO
2:  .word SPACE,DOLOOP,2b-$
    .word EXIT

; nom: CLEARLN
;  efface la ligne sur laquelle le curseur est situé.
; arguments:     
;   aucun
; retourne:
;    rien
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "CLEARLN",7,,CLEARLN   ; ( -- )
    .word LIT,CTRL_X,EMIT,EXIT
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;
; imprime une chaîne de
; caractère à l'écran
;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "TYPE",4,,TYPE  ; (c-addr n+ .. )
    .word DUP,TBRANCH,1f-$
    .word TWODROP, EXIT
1:  .word LIT, 0, DODO
2:  .word DUP,CFETCH,EMIT,ONEPLUS
    .word DOLOOP,2b-$
    .word DROP, EXIT     

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; efface le caractère
; sous le curseur
;;;;;;;;;;;;;;;;;;;;;;;;;;;
DEFWORD "DELETE",6,,DELETE  ; ( -- )
    .word LIT,VK_DELETE,EMIT,EXIT
   
; supprime le dernier caractère reçu    
DEFWORD "DELBACK",7,,DELBACK ; ( -- )
    .word LIT,VK_BACK,EMIT,EXIT

; supprime la ligne en cours de saisie.
DEFWORD "DELLINE",7,,DELLINE ; ( -- )
    .word LIT,CTRL_X,EMIT,EXIT
    
; envoie une commande nouvelle ligne à la console
DEFWORD "CR",2,,CR ; ( -- )
    .word LIT,VK_CR,EMIT,EXIT
    
; efface l'écran.    
DEFWORD "CLS",3,,CLS 
    .word SYSCONS,FETCH,LIT,FN_PAGE,VEXEC,EXIT
    
    
; nom: GETCUR  ( -- u1 u2 )
;   retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1    colonne  {0..63}
;   u2    ligne    {0..23}
DEFWORD "GETCUR",6,,GETCUR
    .word SYSCONS,FETCH,LIT,FN_GETCUR,VEXEC,EXIT
