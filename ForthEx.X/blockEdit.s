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

; NOM: blockedit.s
; DATE: 2017-04-12
; DESCRIPTION: 
;   Éditeur de texte simple qui travail sur un seul écran à la fois et permet
;   de sauvegarder le texte de cet écran dans un bloc. Ultérieurement ce
;   bloc peut-être évalué avec la commande LOAD. 
;   L'idée d'un éditeur de bloc viens de l'origine même du langage. Charles Moore
;   Travaillait sur un terminal vidéo de 16 lignes de 64 caractères, ce qui fait qu'un
;   écran occupait 1024 caractères. Il avait donc eu l'idée de sauvegarder le contenu
;   de la mémoire vidéo sur l'unité de stockage permanent sans modification.
;   Chaque écran sauvegardé s'appelait un bloc.
;   Le problème c'est que BLKED utilise un écran de 23 lignes au lieu de 16 ce qui
;   fait qu'un bloc serait de 1472 caractères au lieu de 1024. Mais comme le standard
;   ANSI Forth défini toujours les blocs comme étant 1024 caractères je devais trouver
;   une solution pour sauvegarder les écrans dans des blocs. Entre autre solutions il y a
;   1) M'écarter du standard et modifier la taille des blocs à 1472 octets.
;   2) Utiliser 2 blocs standards pour sauvegarder un écran, occasionne une perte d'espace.
;   3) Compressser le contenu de l'écran pour le faire entrer dans un bloc standard, gain d'espace.
;   J'ai opté pour la 3ième solution.     
;   En principe Lorsqu'on écris du code source les lignes ne sont pas pleines.
;   Parfois on laisse même des lignes vides pour rendre le texte plus facile à lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronquées après le dernier caractère
;   et un caractère de fin de ligne est ajouté. Il y a 23 lignes de texte sur 
;   un écran donc BLKED. Donc si la longueur moyenne des lignes est inférieure à
;   (BLOCK_SIZE-23)/23 l'écran peut être sauvegardé dans un bloc. Le mot SCR-SIZE
;   défini dans le fichier block.s permet de connaître la taille occupée par un écran dans un bloc.
;   Il est problable que dans la majorité des cas un écran avec les lignes tronquées après
;   le dernier caractère répondra à ce critère. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   BLKED réserve la ligne 24 comme ligne d'état donc un bloc de texte occupe les
;   lignes 1..23.     
;   Le curseur peut-être déplacé n'importe où sur l'écran et le texte modifié.
;   Cependant le curseur ne peut sortir des limites de l'écran, il n'y a pas de défilement.
;   L'éditeur fonctionne en mode écrasement, donc si le curseur est déplacé au dessus d'un
;   caractère il sera remplacé par le caractère tapé à cet endroit. La seule façon d'insérer
;   un caractère au milieu d'un ligne est d'utiliser la touche INSERT suivie du caractère.     
; HTML:
; <br><table border="single">     
; <tr><th colspan="2">COMMANDES</th></tr>
; <tr><th>touche</th><th>fonction</th></tr>
; <tr><td><center>&uarr;</center></td><td>Déplace le curseur d'une ligne vers le haut.</td></tr>
; <tr><td><center>&darr;</center></td><td>Déplace le curseur d'une ligne vers le bas.</td></tr>
; <tr><td><center>&larr;</center></td><td>Déplace le curseur d'un caractère vers la gauche.</td></tr>
; <tr><td><center>&rarr;</center></td><td>Déplace le curseur d'un caractère vers la droite.</td></tr>    
; <tr><td><center>&crarr;</center></td><td>Va au début de la ligne suivante.</td></tr>
; <tr><td>HOME</td><td>Va au début de la ligne.</td></tr>
; <tr><td>END</td><td>Va à la fin de la ligne.</td></tr>
; <tr><td>PAGE<br>UP</td><td>Déplace le curseur dans le coin supérieur gauche de l'écran.</td></tr>
; <tr><td>PAGE<br>DOWN</td><td>Déplace le curseur à la fin du texte.</td></tr>    
; <tr><td>DELETE</td><td>Efface le caractère à la position du curseur.</td></tr>
; <tr><td>INSERT</td><td>Insère un espace à la position du curseur. S'il y a un caractère à la colonne 64 il est perdu.</td></tr>    
; <tr><td><center>&lAarr;</center></td><td>Efface le caractère à gauche du curseur.</td></tr>
; <tr><td>CTRL-D</td><td>Efface la ligne du curseur et place celui-ci à la marge gauche.</td></tr>     
; <tr><td>CTRL-K</td><td>Efface à partir du curseur jusqu'à la fin de la ligne.</td></tr>    
; <tr><td>CTRL-L</td><td>Efface tout l'écran.</td></tr> 
; <tr><td>CTRL-X</td><td>Supprime la ligne sur laquelle le curseur réside.</td></tr>
; <tr><td>CTRL-Y</td><td>Insère une ligne vide à la position du curseur.</td></tr>
; <tr><td>CTRL-B</td><td>Sauvegarde de l'écran dans le bloc.</td></tr>
; <tr><td>CTRL-V</td><td>Copie le contenu de l'écran vers un autre bloc et affiche le nouveau bloc.</td></tr>     
; <tr><td>CTRL-N</td><td>Sauvegarde le bloc actuel et charge le bloc suivant pour édition.</td></tr>
; <tr><td>CTRL-P</td><td>Sauvegarde le bloc actuel et charge le bloc précédent pour édition.</td></tr>     
; <tr><td>CTRL-O</td><td>Sauvegarde le bloc actuel et saisie d'un numéro de bloc pour édition.</td></tr>
; <tr><td>CTRL-E</td><td>Quitte l'éditeur, le contenu de l'écran n'est pas sauvegardé.</td></tr>
; </table><br>
; :HTML     
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilisées par l'éditeur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; EDITLN ( -- n )
;   Nombre de lignes de texte utilisées par BLKED.
; arguments:
;   aucun
; retourne:
;   n Nombre de lignes, 23, i.e. {1..23}, ligne 24 réservée.
HEADLESS EDITLN,CODE
;DEFCODE "EDITLN",6,,EDITLN
     DPUSH
     mov #LPS-1,T
     NEXT
     
; TEXTEND  ( -- )
;   Positionne le curseur à la fin du texte. Balaie la mémoire tampon de l'écran à partir
;   de la fin de la ligne 23 et s'arrête après le premier caractère non blanc.     
; arguments:
;   aucun
; retourne:
;   rien 
HEADLESS TEXTEND,HWORD     
;DEFWORD "TEXTEND",7,,TEXTEND     
     .word SCRBUF,LIT,CPL,EDITLN,STAR,DUP,TOR,PLUS
     .word RFROM,LIT,0,DODO
1:   .word ONEMINUS,DUP,ECFETCH,BL,UGREATER,ZBRANCH,2f-$
     .word UNLOOP,BRANCH,9f-$
2:   .word DOLOOP,1b-$
9:   .word ONEPLUS,SCRBUF,MINUS,LIT,CPL,SLASHMOD
     .word ONEPLUS,SWAP,ONEPLUS,SWAP
     .word DUP,EDITLN,UGREATER,ZBRANCH,2f-$
     .word TWODROP,LIT,CPL,EDITLN
2:   .word EDATXY,EXIT
     
;  KCASE  ( c n -- c f )    
;   compare le caractère 'c' reçu du clavier avec la valeur n.  
; arguments:
;    c  Caractère reçu du clavier
;    n  Valeur de comparaison
;  retourne:
;    c  retourne le caractère reçu.
;    f  T si c==n, F si c<>n
HEADLESS KCASE,HWORD
    .word OVER,EQUAL,DUP,ZBRANCH,2f-$
    .word SWAP,DROP
2:  .word EXIT
  
; nom: SAVELINE ( n -- )
;   Sauvegarde de la ligne d'écran 'n' dans le tampon PAD.
;   Pour que RESTORELINE restitue la ligne d'écran à son état original
;   l'application doit éviter d'écraser le contenu des 64 premiers caractères
;   du  PAD entre les 2 appels.
; arguments:
;   n Numéro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word LNADR  ; s: src
    .word PAD,FETCH,LIT,CPL,MOVE 
    .word EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'écran à partir du tampon PAD.
; arguments:
;   n Numéro de la ligne à restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word LNADR,PAD,FETCH,LIT,CPL,ROT ; s: src len n
    .word SWAP,MOVE
    .word EXIT
    
; ED-WITHELN ( n -- )
;   Console LOCAL et REMOTE.    
;   Imprime une ligne blanche et laisse le curseur au début de celle-ci
;   À la sortie le mode vidéo est inversé, i.e. noir/blanc.
; arguments:
;   n Numéro de la ligne {1..24}
; retourne:
;   rien
HEADLESS EDWHITELN,HWORD    
;DEFWORD "ED-WHITELN",10,,EDWHITELN
    .word DUP,LCWHITELN,ISLOCAL,TBRANCH,2f-$
    .word VTWHITELN
2:  .word EXIT
    
  
; nom: PROMPT  ( c-addr u n -- )
;   Affiche un message en vidéo inversé sur la ligne 'n' de l'écran.
;   Utilise SAVELINE pour conserver le contenu original de cette ligne dans
;   la mémoire tampon PAD.  Les applications qui utilisent PROMPT et doivent restaurer
;   le contenu original de la ligne utilisée par PROMPT doivent s'assurer
;   de ne pas écraser les 64 premiers caractères du PAD.
;   Après l'exécution de PROMPT la sortie vidéo est en mode inversée et le curseur
;   est positionné après le prompt permettant une saisie d'information par l'application.    
; arguments:
;   c-addr Adresse du premier caractère du message à afficher.
;   u Nombre de caractères du message, maximum 63.
;   n Numéro de la ligne sur laquelle le message sera affiché, {1..24}
; retourne:
;   rien    
DEFWORD "PROMPT",6,,PROMPT ; ( c-addr u n+ -- )
    .word DUP,SAVELINE,WHITELN ; s: c-addr u n+
    .word LIT,CPL-1,AND,TYPE,EXIT 
    
; nom: MSGLINE  ( u1 c-addr u2 n -- )
;   Affiche un message en inverse vidéo à l'écran et attend une touche au clavier
;   avant de poursuivre l'exécution l'exécution. Le message doit tenir sur une 
;   seule ligne d'écran. Cette ligne d'écran est sauvegardée et restaurée à la 
;   sortie de ce mot. Le curseur texte est retourné à la position qu'il avait 
;   avant l'appel de MSGLINE.    
; arguments:
;   u1 Durée maximale d'attente en msec ou zéro pour attendre indéfiniment.    
;   c-addr Adresse du premier caractère du message.
;   u1  Longueur du message, limité à 63 caractères.
;   n  Numéro de la ligne où doit-être affiché le message.
; retourne:
;   rien    
DEFWORD "MSGLINE",7,,MSGLINE ; ( u1 c-addr u2 n -- )
     .word XYQ,TWOTOR ; S: u1 c-addr u2 n R: col line
     .word DUP,TOR,PROMPT ; s: u1  r: col line n
     .word DUP,ZBRANCH,2f-$
     .word TICKS,PLUS
1:   .word KEYQ,TBRANCH,2f-$,DUP,TICKS,SWAP,MINUS,ZEROGT,ZBRANCH,1b-$,DROP,BRANCH,4f-$
2:   .word DROP,KEY,DROP
4:   .word FALSE,BSLASHW,RFROM,RESTORELINE
     .word TWORFROM,ATXY,EXIT
  
HEADLESS SAVEFAILED,HWORD
    .word LIT,1000 
    .word STRQUOTE
    .byte 30
    .ascii "Failed to save screen."
    .align 2
9:  .word LIT,LPS,MSGLINE,EXIT
    
HEADLESS SAVESUCCESS,HWORD
    .word LIT,1000
    .word STRQUOTE
    .byte 13
    .ascii "Screen saved."
    .align 2
    .word BRANCH,9b-$
    
; NEXTBLOCK ( -- )
;   Sauvegarde l'écran actuel et charge le bloc suivant pour édition.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS NEXTBLOCK,HWORD    
;DEFWORD "NEXTBLOCK",9,,NEXTBLOCK
    .word SCR,FETCH,DUP,SCRTOBLK,TBRANCH,2f-$
    .word SAVEFAILED,EXIT
2:  .word ONEPLUS,DUP,BLKDEVFETCH,BLKVALIDQ,ZBRANCH,9f-$
    .word BLKTOSCR,EXIT
9:  .word DROP,EXIT
    
; PREVBLOCK  ( -- )
;   Sauvegarde l'écran actuel et charge le bloc précédent pour édition.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS PREVBLOCK,HWORD  
;DEFWORD "PREVBLOCK",9,,PREVBLOCK
    .word SCR,FETCH,DUP,SCRTOBLK,TBRANCH,2f-$
    .word SAVEFAILED,EXIT
2:  .word ONEMINUS,QDUP,ZBRANCH,9f-$
    .word BLKTOSCR
9:  .word EXIT


; BLOCK?  ( -- n+|0 )
;   Demande le numéro du bloc.
; arguments:
;   aucun
; retourne:
;   n+|0  Numéro du bloc ou 0.  
HEADLESS BLOCKQ,HWORD  
;DEFWORD "BLOCK?",6,,BLOCKQ  
    .word XYQ,STRQUOTE
    .byte 8
    .ascii "block#? "
    .align 2
    .word LIT,LPS,PROMPT
    .word TIB,FETCH,LIT,CPL,GETX,MINUS,ACCEPT,FALSE,BSLASHW
    .word DUP,ZBRANCH,8f-$,TIB,FETCH,SWAP,SRCSTORE,LIT,0,TOIN,STORE
    .word BL,WORD,DUP,CFETCH,TBRANCH,7f-$,DROP,FALSE,BRANCH,8f-$
7:  .word QNUMBER,TBRANCH,8f-$,DROP,FALSE
8:  .word LIT,LPS,RESTORELINE,NROT,ATXY
9:  .word EXIT
    
    
; OPENBLOCK  ( -- )
;   Charge un nouveau bloc pour édition. Le numéro du bloc est fourni par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS OPENBLOCK,HWORD  
;DEFWORD "OPENBLOCK",9,,OPENBLOCK
    .word SAVESCREEN,BLOCKQ,QDUP,ZBRANCH,9f-$,BLKTOSCR
9:  .word EXIT
    
; COPYBLOCK  ( -- )    
;   Copie le contenu de l'écran vers un autre bloc et affiche le nouveau bloc.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS COPYBLOCK,HWORD
    .word SAVESCREEN,BLOCKQ,QDUP,ZBRANCH,9f-$,DUP,SCRTOBLK,TBRANCH,8f-$,DROP,EXIT
8:  .word SCR,STORE
9:  .word EXIT
  
; Supprime le caractère à la position du curseur.
HEADLESS EDDEL,HWORD
    .word LCDEL,ISLOCAL,TBRANCH,2f-$
    .word VTDEL
2:  .word EXIT
    
; Déplace le texte d'un position vers la droite
; pour laisser un espace à la position du curseur.
HEADLESS EDINSERTBL,HWORD
    .word CURADR,DUP,ONEPLUS,LIT,CPL,GETX,MINUS,MOVE
    .word BL,CURADR,CSTORE,ISLOCAL,TBRANCH,2f-$,VTINSERT
2:  .word EXIT
    
; Déplace le curseur à la fin du texte sur cette ligne.    
HEADLESS EDEND,HWORD
    .word LCEND, ISLOCAL,TBRANCH,2f-$
    .word LCXYQ,VTATXY
2:  .word EXIT
   
; Déplace le curseur au début de la ligne.    
HEADLESS EDHOME,HWORD
    .word LCHOME,ISLOCAL,TBRANCH,2f-$
    .word VTHOME
2:  .word EXIT  
  
; Déplace le curseur 1 ligne vers le haut.    
HEADLESS EDUP,HWORD
    .word LCUP,ISLOCAL,TBRANCH,2f-$
    .word VTUP
2:  .word EXIT
    
;Déplace le curseur une ligne vers le bas.     
HEADLESS EDDOWN,HWORD
    .word LCXYQ,SWAP,DROP,EDITLN,EQUAL,TBRANCH,9f-$
    .word LCDOWN,ISLOCAL,TBRANCH,9f-$
    .word VTDOWN    
9:  .word EXIT

; Déplace le curseur au début de la ligne suivante
; sauf s'il est sur la dernière ligne.    
HEADLESS EDCRLF,HWORD
    .word GETY,EDITLN,EQUAL,TBRANCH,9f-$
    .word LCCRLF,ISLOCAL,TBRANCH,9f-$
2:  .word VTCRLF    
9:  .word EXIT
    
; vérifie si c'est la dernière position de l'écran.
HEADLESS LASTPOS,HWORD
    .word LCXYQ,EDITLN,EQUAL,ZBRANCH,9f-$
    .word LIT,CPL,EQUAL,EXIT
9:  .word DROP,FALSE,EXIT    
    
; Affiche le caractère à la position du curseur.
HEADLESS EDPUTC,HWORD ; ( c -- )
    .word LASTPOS,NOT,WRAP
    .word DUP,PUTC,ISLOCAL,ZBRANCH,2f-$,DROP,EXIT
2:  .word SPUTC,EXIT

; attend une touche au clavier.  
HEADLESS EDKEY,HWORD
    .word SCRSIZE,LIT,BLOCK_SIZE,GREATER,ZBRANCH,2f-$
    .word LIT,2000,STRQUOTE
    .byte 31
    .ascii "Screen to big to fit in a bloc."
    .align 2
    .word LIT,LPS,MSGLINE
2:  .word STATUSLN,EKEY,EXIT

; efface le caractère avant le curseur.  
HEADLESS EDBACKDEL,HWORD 
    .word GETX,ONEMINUS,ZBRANCH,9f-$,LCBACKDEL,ISLOCAL,TBRANCH,9f-$
    .word VTBACKDEL
9:  .word EXIT

; Déplace le curseur 1 caractère à gauche.  
HEADLESS EDLEFT,HWORD
    .word LCLEFT,ISLOCAL,TBRANCH,2f-$
    .word VTLEFT
2:  .word EXIT

; Déplace le curseur 1 caractère à droite.    
HEADLESS EDRIGHT,HWORD
    .word LCRIGHT,ISLOCAL,TBRANCH,2f-$
    .word VTRIGHT    
2:  .word EXIT

; Déplace le carseur dans le coin supérieur gauche.    
HEADLESS EDTOP,HWORD
    .word LCTOP,ISLOCAL,TBRANCH,2f-$
    .word VTTOP
2:  .word EXIT
  
; nom: SCR-SIZE ( -- n )
;    Calcule la taille que la mémoire tampon vidéo occuperait dans un bloc 
;    s'il était sauvegardé avec SCR>BLK. Seul les lignes 1..23 sont sauvegardées.
;    BLKED utilise la ligne 24 comme ligne d'état.    
;        
; arguments:
;   aucun
; retourne:
;   n Taille qui serait occupée par l'écran dans un bloc.    
DEFWORD "SCR-SIZE",8,,SCRSIZE ; ( -- n )
    .word LIT,0,EDITLN,OVER,DODO
1:  .word SCRBUF,DOI,LIT,CPL,DUP,TOR
    .word STAR,PLUS,RFROM,MINUSTRAILING,SWAP,DROP,ONEPLUS
    .word PLUS,DOLOOP,1b-$
    .word EXIT
    
    
; nom: BLK>SCR ( n+ -- )
;   Copie le contenu d'un bloc dans le tampon d'écran arrête au premier
;   caractère non valide.
; arguments:
;   n+ Numéro du bloc.
; retourne:
;   rien
DEFWORD "BLK>SCR",7,,BLKTOSCR
    .word EDCLS,DUP,TEXTBLOCK,QDUP,TBRANCH,1f-$
    .word DROP,SCR,STORE,EXIT
1:  .word ROT,SCR,STORE
    .word LIT,0,DODO 
1:  .word DUP,ECFETCH,DUP,LIT,VK_CR,EQUAL,ZBRANCH,2f-$,DROP,EDCRLF,BRANCH,3f-$
2:  .word EDPUTC
3:  .word ONEPLUS,DOLOOP,1b-$
9:  .word DROP,TEXTEND,EXIT
    
    
; nom: SCR>BLK  ( n+ -- f )
;   Sauvegarde de la mémoire tampon de l'écran dans un bloc sur périphérique de stockage.
;   Seul lignes 1..23 sont sauvegardées.    
;   Si le contenu de l'écran n'entre pas dans un bloc, l'opération est abaondonnée et retourne faux.
;   Les espaces qui termines les lignes sont supprimés et chaque ligne est complétée
;   par un VK_CR.
;   * ne fonctionne qu'avec LOCAL CONSOLE. Cependant BLKEDIT utilise le frame buffer
;     local même lorsque la console est en mode REMOTE, donc BLKEDIT peut sauvegarder
;     le bloc en édition.    
; arguments:
;   n+    numéro du bloc où sera sauvegardé l'écran.
; retourne:
;   f     indicateur booléen, T si sauvegarde réussie, F si trop grand.
DEFWORD "SCR>BLK",7,,SCRTOBLK
    .word SCRSIZE,LIT,BLOCK_SIZE,UGREATER,ZBRANCH,2f-$
    .word FALSE,EXIT
2:  .word DUP,BUFFER,SWAP,BLKDEVFETCH,BUFFEREDQ,UPDATE ; s: data
    .word EDITLN,LIT,0,DODO 
1:  .word TOR,DOI,ONEPLUS,LNADR ; S: scrline r: data
    .word LIT,CPL,MINUSTRAILING,TOR ; S: scrline r: data len
    .word TWORFETCH,MOVE ; R: data len
    .word TWORFROM,PLUS,LIT,VK_CR,OVER,CSTORE,ONEPLUS,DOLOOP,1b-$
    .word LIT,0,SWAP,ONEMINUS,CSTORE,SAVEBUFFERS,TRUE
    .word EXIT

  
; sauvegarde l'écran dans le bloc. 
DEFWORD "SAVESCREEN",10,,SAVESCREEN ; ( -- )   
;HEADLESS SAVESCREEN,HWORD
    .word SCR,FETCH,SCRTOBLK
    .word TBRANCH,8f-$
    .word SAVEFAILED,EXIT
8:  .word SAVESUCCESS
    .word EXIT    

; avance le curseur à la prochaine tabulation.    
HEADLESS EDTAB, HWORD
    .word LCTAB,ISLOCAL,TBRANCH,2f-$
    .word LCXYQ,VTATXY
2:  .word EXIT    

; efface la ligne 23
;  nécessaire après une commande CTRL_X  
HEADLESS DELLN23,HWORD
    .word LCXYQ,LIT,1,LIT,23,TWODUP,LCATXY,LCDELLN
    .word ISLOCAL,TBRANCH,2f-$
    .word VTATXY,VTDELLN,TWODUP,VTATXY,BRANCH,9f-$
2:  .word TWODROP
9:  .word LCATXY,EXIT
  
; Affiche la ligne d'état    
; Indique le numéro du bloc et la taille actuelle de l'écran.    
HEADLESS STATUSLN,HWORD
    .word LCXYQ,SCRSIZE ; S: col line size
    .word LIT,LPS,WHITELN
    .word STRQUOTE
    .byte  6
    .ascii "bloc#:"
    .align 2
    .word TYPE,SCR,FETCH,UDOT,SPACE,TAB
    .word STRQUOTE
    .byte 5
    .ascii "size:"
    .align 2
    .word TYPE,UDOT,SPACE,TAB
    .word STRQUOTE
    .byte 4
    .ascii "col:"
    .align 2
    .word TYPE,OVER,UDOT,SPACE,TAB
    .word STRQUOTE
    .byte 5
    .ascii "line:"
    .align 2
    .word TYPE,DUP,UDOT
    .word FALSE,BSLASHW
    .word EDATXY,EXIT
   
; ED-AT-XY ( n1 n2 -- )
;   Console locate et remote.
;   Positionne le curseur à la colonnne 'n1' et la ligne 'n2'
; arguments:
;   n1 Colonne {1..64}
;   n2 Ligne {1..24}
; retourne:
;   rien
HEADLESS EDATXY,HWORD    
;DEFWORD "ED-AT-XY",8,,EDATXY
    .word TWODUP,LCATXY,ISLOCAL,ZBRANCH,2f-$,TWODROP,EXIT
2:  .word VTATXY,EXIT

; ED-B/W  ( f -- )  
;   Console LOCAL et REMOTE    
;   Inverse l'affichage vidéo.
; arguments:
;   f Indicateur Booléen, si VRAI inverse la sortie vidéo, si FAUX vidéo normal.
; retourne:
;   rien
HEADLESS EDBSLASHW,HWORD  
;DEFWORD "ED-B/W",6,,EDBSLASHW
    .word DUP,LCBSLASHW,ISLOCAL,ZBRANCH,2f-$,DROP,EXIT
2:  .word VTBSLASHW,EXIT
  
    
; ED-INSRTLN ( -- )
;   Console LOCAL et REMOTE    
;   Insère une ligne vide à la position du curseur. Les lignes à partir du curseur
;   en sont décalées vers le bas. S'il y a du texte sur la dernière ligne celui-ci disparaît.
; arguments:    
;   aucun
; retourne:
;   rien
HEADLESS EDINSRTLN,HWORD  
;DEFWORD "ED-INSRTLN",10,,EDINSRTLN
    .word LCINSRTLN,ISLOCAL,TBRANCH,9f-$
    .word VTINSRTLN
9:  .word EXIT    
  
; ED-DELLN ( -- )
;   Console LOCAL et REMOTE
;   Vide la ligne du curseur et ramène celui-ci à gauche de l'écran.
; arguments:    
;   aucun
; retourne:
;   rien
HEADLESS EDDELLN,HWORD  
;DEFWORD "ED-DELLN",8,,EDDELLN
    .word LCDELLN,ISLOCAL,TBRANCH,9f-$
    .word VTDELLN
9:  .word EXIT
  
; ED-RMVLN  ( -- )
;   Console LOCAL et REMOTE    
;   Supprime la ligne à la position du curseur. Les lignes sous celle-ci sont
;   décalées vers haut pour combler le vide et la dernière ligne de la console
;   se retrouve vide.
; arguments:    
;   aucun
; retourne:
;   rien
HEADLESS EDRMVLN,HWORD  
;DEFWORD "ED-RMVLN",8,,EDRMVLN
    .word LCRMVLN,ISLOCAL,TBRANCH,9f-$
    .word VTRMVLN
9:  .word EXIT
  

;   Supprime du curseur jusqu'à la fin de la ligne.  
HEADLESS EDDELEOL,HWORD
    .word LCDELEOL,ISLOCAL,TBRANCH,9f-$,VTDELEOL
9:  .word EXIT
    
;   Efface tout l'écran.    
HEADLESS EDCLS,HWORD
    .word LCCLS,ISLOCAL,TBRANCH,9f-$
2:  .word VTCLS
9:  .word EXIT
    
; nom: BLKED  ( n+ -- )  
;   Éditeur de bloc texte. Edite 1 bloc à la fois.
;   Le curseur peut-être déplacé à n'importe qu'elle position sur l'écran et 
;   son contenu modifié à volonté avant de le sauvegarder le bloc sur le
;   périphéirque de stockage actif. Si ce bloc contient du texte source ForthEx
;   il peut-être ultérieurement évalué par la commande LOAD ou THRU.  
; arguments:
;   n+   Le numéro du bloc à éditer.
; retourne:
;   rien  
DEFWORD "BLKED",5,,BLKED ; ( n+ -- )
    .word BLKTOSCR
1:  .word EDKEY,DUP,QPRTCHAR,ZBRANCH,2f-$
    .word EDPUTC,BRANCH,1b-$
2:  .word DUP,BL,ULESS,ZBRANCH,4f-$    
    ; c<32
2:  .word LIT,VK_CR,KCASE,ZBRANCH,2f-$,EDCRLF,BRANCH,1b-$
2:  .word LIT,VK_BACK,KCASE,ZBRANCH,2f-$,EDBACKDEL,BRANCH,1b-$
2:  .word LIT,VK_TAB,KCASE,ZBRANCH,2f-$,EDTAB,BRANCH,1b-$ 
2:  .word LIT,CTRL_L,KCASE,ZBRANCH,2f-$,EDCLS,BRANCH,1b-$  
2:  .word LIT,CTRL_D,KCASE,ZBRANCH,2f-$,EDDELLN,BRANCH,1b-$  
2:  .word LIT,CTRL_N,KCASE,ZBRANCH,2f-$,NEXTBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_P,KCASE,ZBRANCH,2f-$,PREVBLOCK,BRANCH,1b-$ 
2:  .word LIT,CTRL_E,KCASE,ZBRANCH,2f-$,EDCLS,EXIT
2:  .word LIT,CTRL_B,KCASE,ZBRANCH,2f-$,SAVESCREEN,BRANCH,1b-$
2:  .word LIT,CTRL_V,KCASE,ZBRANCH,2f-$,COPYBLOCK,BRANCH,1b-$  
2:  .word LIT,CTRL_O,KCASE,ZBRANCH,2f-$,OPENBLOCK,BRANCH,1b-$  
2:  .word LIT,CTRL_K,KCASE,ZBRANCH,2f-$,EDDELEOL,BRANCH,1b-$
2:  .word LIT,CTRL_X,KCASE,ZBRANCH,2f-$,EDRMVLN,DELLN23,BRANCH,1b-$  
2:  .word LIT,CTRL_Y,KCASE,ZBRANCH,2f-$,EDINSRTLN,BRANCH,1b-$
2:  .word DROP,BRANCH,1b-$
    ; c>=127
4:  .word LIT,VK_DELETE,KCASE,ZBRANCH,4f-$,EDDEL,BRANCH,1b-$    
4:  .word LIT,VK_INSERT,KCASE,ZBRANCH,4f-$,EDINSERTBL,BRANCH,1b-$  
4:  .word LIT,VK_LEFT,KCASE,ZBRANCH,4f-$,EDLEFT,BRANCH,1b-$
4:  .word LIT,VK_RIGHT,KCASE,ZBRANCH,4f-$,EDRIGHT,BRANCH,1b-$ 
4:  .word LIT,VK_UP,KCASE,ZBRANCH,4f-$,EDUP,BRANCH,1b-$
4:  .word LIT,VK_DOWN,KCASE,ZBRANCH,4f-$,EDDOWN,BRANCH,1b-$
4:  .word LIT,VK_HOME,KCASE,ZBRANCH,4f-$,EDHOME,BRANCH,1b-$
4:  .word LIT,VK_END,KCASE,ZBRANCH,4f-$,EDEND,BRANCH,1b-$
4:  .word LIT,VK_PGUP,KCASE,ZBRANCH,4f-$,EDTOP,BRANCH,1b-$  
4:  .word LIT,VK_PGDN,KCASE,ZBRANCH,4f-$,TEXTEND,BRANCH,1b-$
4:  .word DROP,BRANCH,1b-$
   
    .word EXIT
    
    