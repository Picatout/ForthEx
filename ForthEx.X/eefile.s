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

; NOM: fat8.s
; DATE: 2017-04-14 
;    
; DESCRIPTION: 
;   Un syst�me de fichiers simple pour utiliser avec l'EEPROM externe
;   le syst�me � bas� sur la dimension d'une page qui est de 256 octets pour la
;   25LC1024. Un bitmap de 64 octets est r�serv� pour indiquer les pages utilis�es.
;   Au d�but de chaque page 2 octets sont r�serv�es pour indiquer la prochaine 
;   page du fichier.    
;    
;   * Capacit� de 128Ko.
;   * Ce syst�me ne supporte pas les r�pertoires.
;   * Un maximum de 27 fichiers par EEPROM.
;   * La premi�re page de donn�e est la num�ro 2.    
;   * secteur de 512 octets.    
;    
;   STRUCTURE:
;   ==========
;   page 0    description du m�dia, et premi�res entr�es du r�pertoire
;   ---------
;   adr  octets utilisation
;------------------------------    
;    0    6     .byte 4 .ascii "EEFS" .byte 0  
;    6    2     indique premi�re page d'image BOOT s'il y en a une.
;    8    2     indique la grandeur de l'image en octets
;    10   4     r�serv�.    
;    16   64    bitmap de l'utilisation des pages
;    64   255   11 entr�es de r�pertoire
;    
;   page 1   entr�es de r�pertoires suppl�mentaires
;----------    
;   adr  octets utilisation
;------------------------------    
;    0    255   16 entr�es  de r�pertoires
;
;   ENTR�E R�PETOIRE  
;   -----------------
;   adr   octets  description
;-----------------------------    
;    0    2	    file_size   grandeur du fichier en octets maximum 65535
;    2    2         page1       no. de la premi�re page du fichier.
;				Si 0 l'entr�e est libre.    
;    4    12        nom_fichier Cha�ne compt�e maximum. Longueur maximale d'un
;                               nom 11 caract�res.
;
;   PAGE 2..511  pages de donn�es
;   ---------------    
;   adr   taille  description
;-----------------------------    
;   0      2       Num�ro de la page suivante ou 0 si derni�re page.
;   2      254     Donn�es du fichier.


.section .str.const psv
_eefs_magic:
.byte 4
.ascii "EEFS"

    
DEFCONST "EEFS_MAGIC",10,,EEFS_MAGIC,_eefs_magic

    
; formatate du syst�me de fichier
; arguments:
;   aucun
; retourne:
;   rien
DEFWORD "EEFORMAT",8,,EEFORMAT ; ( -- )
    .word PAD,FETCH,DUP,LIT,64,LIT,0,FILL ; S: tib
    .word LIT,8,LIT,0,DODO ; S: tib
2:  .word DUP,LIT,64,DUP,DOI,MSTAR,EEWRITE,DOLOOP,2b-$
    .word DUP,EEFS_MAGIC,DUP,LIT,6,PLUS,SWAP,DODO
2:  .word DOI,CFETCH,OVER,CSTORE,ONEPLUS,DOLOOP,2b-$
    .word DROP,LIT,6,LIT,0,DUP,EEWRITE
    .word EXIT
 
; v�rifie si l'EEPROM est format�e
; arguments:
;   aucun
; retourne:    
;   f   vrai|faux
DEFWORD "?EEFS",5,,QEEFS ; ( -- f )
    .word TIB,FETCH,DUP,LIT,6,LIT,0,DUP,EEREAD ; S: tib
    .word EEFS_MAGIC,PAD,FETCH,DUP,TOR,CSTRTORAM
    .word RFROM,STREQUAL,EXIT

; monte le syst�me de fichier EEFS
; retourne:
;   f    indicateur bool�en succ�s/�chec
DEFWORD "EEMOUNT",7,,EEMOUNT ; ( -- f )
    .word QEEFS,DUP,TBRANCH,2f-$,EXIT
2:       
    .word EXIT
    
; d�monte le syst�me de fichier EEFS    
DEFWORD "EEUMOUNT",8,,EEUMOUNT ; ( -- )

    .word EXIT
    
    
; recherche d'un nom dans le r�pertoire. 
;  arguments:
;    addr   adresse du nom comme cha�ne compt�e.
;  retourne:    
;     0 ou un pointeur sur l'ent�re du r�pertoire.
DEFWORD "DIRFIND",7,,DIRFIND ; ( addr1 -- addr2|0 )
    
    .word EXIT
    
; recherche d'un r�pertoire libre.
;  arguments:
;	aucun
;  retourne:
;     0 si aucun libre ou pointeur entr�e.
DEFWORD "?DIR",4,,QDIR ; ( -- addr|0)
    
    .word EXIT
   
; recherche d'une page libre
; arguments:
;   aucun
; retourne:
;   n  0 si aucune, sinon n -> {2..511}
DEFWORD "?PAGE",5,,QPAGE ; ( -- n )
    
    .word EXIT
    
; ouverture d'un fichier.
; arguments:
;   addr  descripteur nom du fichier
;   n1    options flags  F_CREATE,F_WRITE,R_READ    
; retourne:
;   0 si �chec ou entr�e de r�pertoire
DEFWORD "FOPEN",5,,FOPEN ; ( addr n1 -- 0|addr )
    
    .word EXIT
    
; fermeture d'un fichier.
; arugments:
;    addr  addresse entr�e du r�pertoire
; retourne:
;    rien
DEFWORD "FCLOSE",6,,FCLOSE ;  ( addr -- )
    
    .word EXIT
    
; suppression d'un fichier.
; arguments:
;    addr  descripteur du nom de fichier.
; retourne:
;    rien
DEFWORD "FDELETE",7,,FDELETE  ; ( addr -- )

    .word EXIT

; renommer un fichier.
    
; copier un fichier.
    
; �criture dans le fichier.
    
; lecture du fichier.
    
    