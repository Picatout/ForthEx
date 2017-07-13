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
;   �diteur de texte simple qui travail sur un seul �cran � la fois et permet
;   de sauvegarder le texte de cet �cran dans un bloc. Ult�rieurement ce
;   bloc peut-�tre �valu� avec la commande LOAD. 
;   L'id�e d'un �diteur de bloc viens de l'origine m�me du langage. Charles Moore
;   Travaillait sur un terminal vid�o de 16 lignes de 64 caract�res, ce qui fait qu'un
;   �cran occupait 1024 caract�res. Il avait donc eu l'id�e de sauvegarder le contenu
;   de la m�moire vid�o sur l'unit� de stockage permanent sans modification.
;   Chaque �cran sauvegard� s'appelait un bloc.
;   Le probl�me c'est que BLKED utilise un �cran de 23 lignes au lieu de 16 ce qui
;   fait qu'un bloc serait de 1472 caract�res au lieu de 1024. Mais comme le standard
;   ANSI Forth d�fini toujours les blocs comme �tant 1024 caract�res je devais trouver
;   une solution pour sauvegarder les �crans dans des blocs. Entre autre solutions il y a
;   1) M'�carter du standard et modifier la taille des blocs � 1472 octets.
;   2) Utiliser 2 blocs standards pour sauvegarder un �cran, occasionne une perte d'espace.
;   3) Compressser le contenu de l'�cran pour le faire entrer dans un bloc standard, gain d'espace.
;   J'ai opt� pour la 3i�me solution.     
;   En principe Lorsqu'on �cris du code source les lignes ne sont pas pleines.
;   Parfois on laisse m�me des lignes vides pour rendre le texte plus facile � lire.
;   Lors de la sauvegarde dans un bloc les lignes sont tronqu�es apr�s le dernier caract�re
;   et un caract�re de fin de ligne est ajout�. Il y a 23 lignes de texte sur 
;   un �cran donc BLKED. Donc si la longueur moyenne des lignes est inf�rieure �
;   (BLOCK_SIZE-23)/23 l'�cran peut �tre sauvegard� dans un bloc. Le mot SCR-SIZE
;   d�fini dans le fichier block.s permet de conna�tre la taille occup�e par un �cran dans un bloc.
;   Il est problable que dans la majorit� des cas un �cran avec les lignes tronqu�es apr�s
;   le dernier caract�re r�pondra � ce crit�re. Au pire il suffira de raccourcir les commentaires.    
; FONCTIONNEMENT:
;   BLKED r�serve la ligne 24 comme ligne d'�tat donc un bloc de texte occupe les
;   lignes 1..23.     
;   Le curseur peut-�tre d�plac� n'importe o� sur l'�cran et le texte modifi�.
;   Cependant le curseur ne peut sortir des limites de l'�cran, il n'y a pas de d�filement.
;   L'�diteur fonctionne en mode �crasement, donc si le curseur est d�plac� au dessus d'un
;   caract�re il sera remplac� par le caract�re tap� � cet endroit. La seule fa�on d'ins�rer
;   un caract�re au milieu d'un ligne est d'utiliser la touche INSERT suivie du caract�re.     
; HTML:
; <br><table border="single">     
; <tr><th colspan="2">COMMANDES</th></tr>
; <tr><th>touche</th><th>fonction</th></tr>
; <tr><td><center>&uarr;</center></td><td>D�place le curseur d'une ligne vers le haut.</td></tr>
; <tr><td><center>&darr;</center></td><td>D�place le curseur d'une ligne vers le bas.</td></tr>
; <tr><td><center>&larr;</center></td><td>D�place le curseur d'un caract�re vers la gauche.</td></tr>
; <tr><td><center>&rarr;</center></td><td>D�place le curseur d'un caract�re vers la droite.</td></tr>    
; <tr><td><center>&crarr;</center></td><td>Va au d�but de la ligne suivante.</td></tr>
; <tr><td>HOME</td><td>Va au d�but de la ligne.</td></tr>
; <tr><td>END</td><td>Va � la fin de la ligne.</td></tr>
; <tr><td>PAGE<br>UP</td><td>D�place le curseur dans le coin sup�rieur gauche de l'�cran.</td></tr>
; <tr><td>PAGE<br>DOWN</td><td>D�place le curseur � la fin du texte.</td></tr>    
; <tr><td>DELETE</td><td>Efface le caract�re � la position du curseur.</td></tr>
; <tr><td>INSERT</td><td>Ins�re un espace � la position du curseur. S'il y a un caract�re � la colonne 64 il est perdu.</td></tr>    
; <tr><td><center>&lAarr;</center></td><td>Efface le caract�re � gauche du curseur.</td></tr>
; <tr><td>CTRL-D</td><td>Efface la ligne du curseur et place celui-ci � la marge gauche.</td></tr>     
; <tr><td>CTRL-K</td><td>Efface � partir du curseur jusqu'� la fin de la ligne.</td></tr>    
; <tr><td>CTRL-L</td><td>Efface tout l'�cran.</td></tr> 
; <tr><td>CTRL-X</td><td>Supprime la ligne sur laquelle le curseur r�side.</td></tr>
; <tr><td>CTRL-Y</td><td>Ins�re une ligne vide � la position du curseur.</td></tr>
; <tr><td>CTRL-B</td><td>Sauvegarde de l'�cran dans le bloc.</td></tr>
; <tr><td>CTRL-V</td><td>Copie le contenu de l'�cran vers un autre bloc et affiche le nouveau bloc.</td></tr>     
; <tr><td>CTRL-N</td><td>Sauvegarde le bloc actuel et charge le bloc suivant pour �dition.</td></tr>
; <tr><td>CTRL-P</td><td>Sauvegarde le bloc actuel et charge le bloc pr�c�dent pour �dition.</td></tr>     
; <tr><td>CTRL-O</td><td>Sauvegarde le bloc actuel et saisie d'un num�ro de bloc pour �dition.</td></tr>
; <tr><td>CTRL-E</td><td>Quitte l'�diteur, le contenu de l'�cran n'est pas sauvegard�.</td></tr>
; </table><br>
; :HTML     
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constantes utilis�es par l'�diteur.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; EDITLN ( -- n )
;   Nombre de lignes de texte utilis�es par BLKED.
; arguments:
;   aucun
; retourne:
;   n Nombre de lignes, 23, i.e. {1..23}, ligne 24 r�serv�e.
HEADLESS EDITLN,CODE
;DEFCODE "EDITLN",6,,EDITLN
     DPUSH
     mov #LPS-1,T
     NEXT
     
; TEXTEND  ( -- )
;   Positionne le curseur � la fin du texte. Balaie la m�moire tampon de l'�cran � partir
;   de la fin de la ligne 23 et s'arr�te apr�s le premier caract�re non blanc.     
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
;   compare le caract�re 'c' re�u du clavier avec la valeur n.  
; arguments:
;    c  Caract�re re�u du clavier
;    n  Valeur de comparaison
;  retourne:
;    c  retourne le caract�re re�u.
;    f  T si c==n, F si c<>n
HEADLESS KCASE,HWORD
    .word OVER,EQUAL,DUP,ZBRANCH,2f-$
    .word SWAP,DROP
2:  .word EXIT
  
; nom: SAVELINE ( n -- )
;   Sauvegarde de la ligne d'�cran 'n' dans le tampon PAD.
;   Pour que RESTORELINE restitue la ligne d'�cran � son �tat original
;   l'application doit �viter d'�craser le contenu des 64 premiers caract�res
;   du  PAD entre les 2 appels.
; arguments:
;   n Num�ro de ligne {1..24}
; retourne:
;   rien  
DEFWORD "SAVELINE",8,,SAVELINE ; ( n -- )
    .word LNADR  ; s: src
    .word PAD,FETCH,LIT,CPL,MOVE 
    .word EXIT
    
; nom: RESTORELINE  ( n -- )
;   Restaure la ligne d'�cran � partir du tampon PAD.
; arguments:
;   n Num�ro de la ligne � restaurer {1..24}.
; retourne:
;   rien
DEFWORD "RESTORELINE",11,,RESTORELINE 
    .word LNADR,PAD,FETCH,LIT,CPL,ROT ; s: src len n
    .word SWAP,MOVE
    .word EXIT
    
; ED-WITHELN ( n -- )
;   Console LOCAL et REMOTE.    
;   Imprime une ligne blanche et laisse le curseur au d�but de celle-ci
;   � la sortie le mode vid�o est invers�, i.e. noir/blanc.
; arguments:
;   n Num�ro de la ligne {1..24}
; retourne:
;   rien
HEADLESS EDWHITELN,HWORD    
;DEFWORD "ED-WHITELN",10,,EDWHITELN
    .word DUP,LCWHITELN,ISLOCAL,TBRANCH,2f-$
    .word VTWHITELN
2:  .word EXIT
    
  
; nom: PROMPT  ( c-addr u n -- )
;   Affiche un message en vid�o invers� sur la ligne 'n' de l'�cran.
;   Utilise SAVELINE pour conserver le contenu original de cette ligne dans
;   la m�moire tampon PAD.  Les applications qui utilisent PROMPT et doivent restaurer
;   le contenu original de la ligne utilis�e par PROMPT doivent s'assurer
;   de ne pas �craser les 64 premiers caract�res du PAD.
;   Apr�s l'ex�cution de PROMPT la sortie vid�o est en mode invers�e et le curseur
;   est positionn� apr�s le prompt permettant une saisie d'information par l'application.    
; arguments:
;   c-addr Adresse du premier caract�re du message � afficher.
;   u Nombre de caract�res du message, maximum 63.
;   n Num�ro de la ligne sur laquelle le message sera affich�, {1..24}
; retourne:
;   rien    
DEFWORD "PROMPT",6,,PROMPT ; ( c-addr u n+ -- )
    .word DUP,SAVELINE,WHITELN ; s: c-addr u n+
    .word LIT,CPL-1,AND,TYPE,EXIT 
    
; nom: MSGLINE  ( u1 c-addr u2 n -- )
;   Affiche un message en inverse vid�o � l'�cran et attend une touche au clavier
;   avant de poursuivre l'ex�cution l'ex�cution. Le message doit tenir sur une 
;   seule ligne d'�cran. Cette ligne d'�cran est sauvegard�e et restaur�e � la 
;   sortie de ce mot. Le curseur texte est retourn� � la position qu'il avait 
;   avant l'appel de MSGLINE.    
; arguments:
;   u1 Dur�e maximale d'attente en msec ou z�ro pour attendre ind�finiment.    
;   c-addr Adresse du premier caract�re du message.
;   u1  Longueur du message, limit� � 63 caract�res.
;   n  Num�ro de la ligne o� doit-�tre affich� le message.
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
;   Sauvegarde l'�cran actuel et charge le bloc suivant pour �dition.
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
;   Sauvegarde l'�cran actuel et charge le bloc pr�c�dent pour �dition.
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
;   Demande le num�ro du bloc.
; arguments:
;   aucun
; retourne:
;   n+|0  Num�ro du bloc ou 0.  
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
;   Charge un nouveau bloc pour �dition. Le num�ro du bloc est fourni par l'utilisateur.    
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS OPENBLOCK,HWORD  
;DEFWORD "OPENBLOCK",9,,OPENBLOCK
    .word SAVESCREEN,BLOCKQ,QDUP,ZBRANCH,9f-$,BLKTOSCR
9:  .word EXIT
    
; COPYBLOCK  ( -- )    
;   Copie le contenu de l'�cran vers un autre bloc et affiche le nouveau bloc.
; arguments:
;   aucun
; retourne:
;   rien
HEADLESS COPYBLOCK,HWORD
    .word SAVESCREEN,BLOCKQ,QDUP,ZBRANCH,9f-$,DUP,SCRTOBLK,TBRANCH,8f-$,DROP,EXIT
8:  .word SCR,STORE
9:  .word EXIT
  
; Supprime le caract�re � la position du curseur.
HEADLESS EDDEL,HWORD
    .word LCDEL,ISLOCAL,TBRANCH,2f-$
    .word VTDEL
2:  .word EXIT
    
; D�place le texte d'un position vers la droite
; pour laisser un espace � la position du curseur.
HEADLESS EDINSERTBL,HWORD
    .word CURADR,DUP,ONEPLUS,LIT,CPL,GETX,MINUS,MOVE
    .word BL,CURADR,CSTORE,ISLOCAL,TBRANCH,2f-$,VTINSERT
2:  .word EXIT
    
; D�place le curseur � la fin du texte sur cette ligne.    
HEADLESS EDEND,HWORD
    .word LCEND, ISLOCAL,TBRANCH,2f-$
    .word LCXYQ,VTATXY
2:  .word EXIT
   
; D�place le curseur au d�but de la ligne.    
HEADLESS EDHOME,HWORD
    .word LCHOME,ISLOCAL,TBRANCH,2f-$
    .word VTHOME
2:  .word EXIT  
  
; D�place le curseur 1 ligne vers le haut.    
HEADLESS EDUP,HWORD
    .word LCUP,ISLOCAL,TBRANCH,2f-$
    .word VTUP
2:  .word EXIT
    
;D�place le curseur une ligne vers le bas.     
HEADLESS EDDOWN,HWORD
    .word LCXYQ,SWAP,DROP,EDITLN,EQUAL,TBRANCH,9f-$
    .word LCDOWN,ISLOCAL,TBRANCH,9f-$
    .word VTDOWN    
9:  .word EXIT

; D�place le curseur au d�but de la ligne suivante
; sauf s'il est sur la derni�re ligne.    
HEADLESS EDCRLF,HWORD
    .word GETY,EDITLN,EQUAL,TBRANCH,9f-$
    .word LCCRLF,ISLOCAL,TBRANCH,9f-$
2:  .word VTCRLF    
9:  .word EXIT
    
; v�rifie si c'est la derni�re position de l'�cran.
HEADLESS LASTPOS,HWORD
    .word LCXYQ,EDITLN,EQUAL,ZBRANCH,9f-$
    .word LIT,CPL,EQUAL,EXIT
9:  .word DROP,FALSE,EXIT    
    
; Affiche le caract�re � la position du curseur.
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

; efface le caract�re avant le curseur.  
HEADLESS EDBACKDEL,HWORD 
    .word GETX,ONEMINUS,ZBRANCH,9f-$,LCBACKDEL,ISLOCAL,TBRANCH,9f-$
    .word VTBACKDEL
9:  .word EXIT

; D�place le curseur 1 caract�re � gauche.  
HEADLESS EDLEFT,HWORD
    .word LCLEFT,ISLOCAL,TBRANCH,2f-$
    .word VTLEFT
2:  .word EXIT

; D�place le curseur 1 caract�re � droite.    
HEADLESS EDRIGHT,HWORD
    .word LCRIGHT,ISLOCAL,TBRANCH,2f-$
    .word VTRIGHT    
2:  .word EXIT

; D�place le carseur dans le coin sup�rieur gauche.    
HEADLESS EDTOP,HWORD
    .word LCTOP,ISLOCAL,TBRANCH,2f-$
    .word VTTOP
2:  .word EXIT
  
; nom: SCR-SIZE ( -- n )
;    Calcule la taille que la m�moire tampon vid�o occuperait dans un bloc 
;    s'il �tait sauvegard� avec SCR>BLK. Seul les lignes 1..23 sont sauvegard�es.
;    BLKED utilise la ligne 24 comme ligne d'�tat.    
;        
; arguments:
;   aucun
; retourne:
;   n Taille qui serait occup�e par l'�cran dans un bloc.    
DEFWORD "SCR-SIZE",8,,SCRSIZE ; ( -- n )
    .word LIT,0,EDITLN,OVER,DODO
1:  .word SCRBUF,DOI,LIT,CPL,DUP,TOR
    .word STAR,PLUS,RFROM,MINUSTRAILING,SWAP,DROP,ONEPLUS
    .word PLUS,DOLOOP,1b-$
    .word EXIT
    
    
; nom: BLK>SCR ( n+ -- )
;   Copie le contenu d'un bloc dans le tampon d'�cran arr�te au premier
;   caract�re non valide.
; arguments:
;   n+ Num�ro du bloc.
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
;   Sauvegarde de la m�moire tampon de l'�cran dans un bloc sur p�riph�rique de stockage.
;   Seul lignes 1..23 sont sauvegard�es.    
;   Si le contenu de l'�cran n'entre pas dans un bloc, l'op�ration est abaondonn�e et retourne faux.
;   Les espaces qui termines les lignes sont supprim�s et chaque ligne est compl�t�e
;   par un VK_CR.
;   * ne fonctionne qu'avec LOCAL CONSOLE. Cependant BLKEDIT utilise le frame buffer
;     local m�me lorsque la console est en mode REMOTE, donc BLKEDIT peut sauvegarder
;     le bloc en �dition.    
; arguments:
;   n+    num�ro du bloc o� sera sauvegard� l'�cran.
; retourne:
;   f     indicateur bool�en, T si sauvegarde r�ussie, F si trop grand.
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

  
; sauvegarde l'�cran dans le bloc. 
DEFWORD "SAVESCREEN",10,,SAVESCREEN ; ( -- )   
;HEADLESS SAVESCREEN,HWORD
    .word SCR,FETCH,SCRTOBLK
    .word TBRANCH,8f-$
    .word SAVEFAILED,EXIT
8:  .word SAVESUCCESS
    .word EXIT    

; avance le curseur � la prochaine tabulation.    
HEADLESS EDTAB, HWORD
    .word LCTAB,ISLOCAL,TBRANCH,2f-$
    .word LCXYQ,VTATXY
2:  .word EXIT    

; efface la ligne 23
;  n�cessaire apr�s une commande CTRL_X  
HEADLESS DELLN23,HWORD
    .word LCXYQ,LIT,1,LIT,23,TWODUP,LCATXY,LCDELLN
    .word ISLOCAL,TBRANCH,2f-$
    .word VTATXY,VTDELLN,TWODUP,VTATXY,BRANCH,9f-$
2:  .word TWODROP
9:  .word LCATXY,EXIT
  
; Affiche la ligne d'�tat    
; Indique le num�ro du bloc et la taille actuelle de l'�cran.    
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
;   Positionne le curseur � la colonnne 'n1' et la ligne 'n2'
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
;   Inverse l'affichage vid�o.
; arguments:
;   f Indicateur Bool�en, si VRAI inverse la sortie vid�o, si FAUX vid�o normal.
; retourne:
;   rien
HEADLESS EDBSLASHW,HWORD  
;DEFWORD "ED-B/W",6,,EDBSLASHW
    .word DUP,LCBSLASHW,ISLOCAL,ZBRANCH,2f-$,DROP,EXIT
2:  .word VTBSLASHW,EXIT
  
    
; ED-INSRTLN ( -- )
;   Console LOCAL et REMOTE    
;   Ins�re une ligne vide � la position du curseur. Les lignes � partir du curseur
;   en sont d�cal�es vers le bas. S'il y a du texte sur la derni�re ligne celui-ci dispara�t.
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
;   Vide la ligne du curseur et ram�ne celui-ci � gauche de l'�cran.
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
;   Supprime la ligne � la position du curseur. Les lignes sous celle-ci sont
;   d�cal�es vers haut pour combler le vide et la derni�re ligne de la console
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
  

;   Supprime du curseur jusqu'� la fin de la ligne.  
HEADLESS EDDELEOL,HWORD
    .word LCDELEOL,ISLOCAL,TBRANCH,9f-$,VTDELEOL
9:  .word EXIT
    
;   Efface tout l'�cran.    
HEADLESS EDCLS,HWORD
    .word LCCLS,ISLOCAL,TBRANCH,9f-$
2:  .word VTCLS
9:  .word EXIT
    
; nom: BLKED  ( n+ -- )  
;   �diteur de bloc texte. Edite 1 bloc � la fois.
;   Le curseur peut-�tre d�plac� � n'importe qu'elle position sur l'�cran et 
;   son contenu modifi� � volont� avant de le sauvegarder le bloc sur le
;   p�riph�irque de stockage actif. Si ce bloc contient du texte source ForthEx
;   il peut-�tre ult�rieurement �valu� par la commande LOAD ou THRU.  
; arguments:
;   n+   Le num�ro du bloc � �diter.
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
    
    