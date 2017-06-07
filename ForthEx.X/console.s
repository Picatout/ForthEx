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
;    On passe d'une console à l'autre avec les 2 phrases suivantes:
;    REMOTE CONSOLE  \ l'interface utilisateur utilise le port sériel.
;    LOCAL CONSOLE   \ l'interface utilisateur utilise le clavier et le moniteur
;                    \ de l'ordinateur ForthEx. C'est la console par défaut.    
;
;    La variable système SYSCONS contient le vecteur de la console sélectionnée.
;    Ce vecteur est une table contenant les fonctions à exécuter pour chacune des
;    fonctions suivante:
        
;FNBR |  NOM       |  NOM        | NOM
;     |  FONCTION  |  LOCAL      | REMOTE         
;========================================
;0    |  KEY       |  LC-KEY     | VT-KEY
;1    |  KEY?      |  LC-KEY?    | VT-CHAR?
;2    |  EKEY      |  LC-EKEY    | VT-ECHAR
;3    |  EKEY?     |  LC-EKEY?   | SGETC?
;4    |  EMIT      |  LC-EMIT    | VT-EMIT
;5    |  EMIT?     |  LC-EMIT?   | VT-EMIT?    
;6    |  AT-XY     |  CURPOS     | VT-AT-XY
;7    |  PAGE      |  LC-PAGE    | VT-PAGE
;8    |  EKEY>CHAR |  LC-FILTER  | VT-FILTER
;9    |  GETCUR    |  LC-GETCUR  | VT-GETCUR
;10   |  B/W       |  LC-B/W     |  VT-B/W   
;11   |  INSRTLN   |  LC-INSRTLN | VT-INSRTLN    
;12   |  RMVLN     |  LC-RMVLN   | VT-RMVLN
;13   |  DELLN     |  LC-DELLN   | VT-DELLN
    
;  Exemple de définition d'un mot vectorisé.
; : KEY  SYSCONS @ FN_KEY VEXEC ;
    


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
.equ FN_BSLASHW,10
.equ FN_INSRTLN,11
.equ FN_RMVLN,12
.equ FN_DELLN,13    
  
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
    .word LCGETCUR ; tvout.s
    .word LCBSLASHW   ; tvout.s
    .word LCINSRTLN ; tvout.s
    .word LCRMVLN ; tvout.s
    .word LCDELLN ; tvout.s
    
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
    .word VTGETCUR ; vt102.s
    .word VTBSLASHW   ; vt102.s
    .word VTINSRTLN ; vt102.2
    .word VTRMVLN ; vt102.s
    .word VTDELLN ; vt102.s
    
; nom: ED-CONS ( -- a-addr )
;   Retourne l'adresse du vecteur des fonctions pour la console de l'éditeur de bloc.
; arguments:
;   aucun
; retourne:
;   Adresse du vecteur contenant les CFA des fonctions de la console de l'éditeur.
DEFTABLE "ED-CONS"7,,EDCONS
    .word VTKEY    ; vt102.s
    .word VTKEYQ   ; vt102.s
    .word VTEKEY   ; serial.s
    .word SGETCQ   ; serial.s
    .word EDEMIT   ; vt102.s
    .word SREADYQ  ; serial.s
    .word VTATXY   ; vt102.s
    .word VTPAGE   ; vt102.s
    .word VTFILTER ; vt102.s
    .word VTGETCUR ; vt102.s
    .word VTBSLASHW   ; vt102.s
    .word VTINSRTLN ; vt102.2
    .word VTRMVLN ; vt102.s
    .word VTDELLN ; vt102.s
    
    
; nom: SYSCONS   ( -- a-addr )
;   Variable système qui contient l'adresse de la table des fonctions du 
;   périphérique utilisé par la console.
;   La console peut fonctionné en mode LOCAL ou REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr  Adresse de la variable.    
DEFUSER "SYSCONS",7,,SYSCONS 
    
; nom: LOCAL ( -- a-addr )
;   Efface l'écran local et empile l'adresse de la table des fonctions
;   de la console locale.    
; arguments:
;   aucun
; retourne:
;   a-addr Adresse de la table LCONSOLE   
DEFWORD "LOCAL",5,,LOCAL 
    .word LCPAGE,LCCONS,EXIT

    
; nom: REMOTE ( -- a-addr )
;   Active le port sériel et envoie une commande au terminal VT102 
;   pour effacer l'écran. Ensuite empile l'adresse de la table des fonctions
;   de la console REMOTE.    
; arguments:
;   aucun
; retourne:
;   a-addr Adresse de la table LREMOTE    
DEFWORD "REMOTE",6,,REMOTE
    .word TRUE,SERENBL
    .word LIT,4,LIT,0,DODO
1:  .word LIT,65,SPUTC,DOLOOP,1b-$
    .word LIT,CTRL_L,SPUTC,VTCONS,EXIT
    
    
; nom: CONSOLE ( a-addr --  )
;   Détermine la CONSOLE active {LOCAL,REMOTE}    
;   Affecte la variable système SYSCONS avec l'adresse 'a-addr'.
;   Cette adresse correspond à une table fonctions à utiliser par la console.
; arguments:
;   a-addr Adresse de la table des fonctions qui seront utilisées par la console.
; retourne:
;   rien   
DEFWORD "CONSOLE",7,,CONSOLE
    .word SYSCONS,STORE,EXIT
    
    
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
    .word LIT,CTRL_X,EMIT,EXIT
    
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
    .word SYSCONS,FETCH,LIT,FN_RMVLN,VEXEC,EXIT
    
    
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
    
    
; nom: GETCUR  ( -- u1 u2 )
;   Retourne la position du curseur texte.
; arguments:
;   aucun
; retourne:
;   u1 Colonne  {1..64}
;   u2 Ligne    {1..24}
DEFWORD "GETCUR",6,,GETCUR
    .word SYSCONS,FETCH,LIT,FN_GETCUR,VEXEC,EXIT

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
    