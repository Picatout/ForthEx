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

; NOM: strings.s
; DATE: 2017-04-16
; DESCRIPTION: manipulation des cha�nes de caract�res.
    
    
;obtient le caract�re � l'adresse et avance l'adresse
; � utilis� si addr pointe vers m�moire EDS    
;  arguments:
;	addr  adresse
;  retourne:
;     addr+1   adresse avanc�e d'un caract�re
;     c        caract�re obtenu    
DEFWORD "ESTR>",5,,ESTRFROM ;( addr -- addr+1 c )
    .word DUP,ECFETCH,TOR,CHARPLUS,RFROM,EXIT
    
;obtient le caract�re en m�moire flash � l'adresse
;  arguments:
;	addr  adresse
;  retourne:
;     addr+1   adresse avanc�e d'un caract�re
;     c        caract�re obtenu    
DEFWORD "STR>",4,,STRFROM ; ( addr -- addr+1 c )
    .word DUP,CFETCH,TOR,CHARPLUS,RFROM,EXIT
    
; copie une chaine compt�e de la m�moire FLASH vers la m�moire RAM
; arguments:
;   c-addr1    adresse cha�ne en flash
;   c-addr2    adresse destination en RAM
; retourne:
;   rien    
DEFWORD "CSTR>RAM",8,,CSTRTORAM ; ( addr1 addr2 -- )    
    .word TOR, DUP,CFETCH,ONEPLUS,RFROM,NROT
    .word LIT,0,DODO
2:  .word STRFROM,SWAP,TOR,OVER,CSTORE,ONEPLUS,RFROM
    .word DOLOOP,2b-$
    .word TWODROP,EXIT
    
    
; comparaison de 2 cha�nes:
; les 2 cha�nes doivent-�tre en m�moire RAM.
; arguments:
;   addr1   descripteur cha�ne 1
;   addr2   descriptieur cha�ne 2
; retourne:
;   f       vrai si identique    
;           faux si diff�rente
DEFWORD "STR=",4,,STREQUAL ; ( addr1 addr2 -- f )
    .word TOR,ESTRFROM,RFROM,ESTRFROM
    .word ROT,OVER,EQUAL,ZBRANCH,6f-$
    .word LIT,0,DODO
2:  .word TOR,ESTRFROM,RFROM,ESTRFROM
    .word ROT,EQUAL,ZBRANCH,4f-$
    .word DOLOOP,2b-$ 
    .word TWODROP,LIT,-1,EXIT
4:  .word UNLOOP,BRANCH,8f-$
6:  .word DROP
8:  .word TWODROP,LIT,0    
9:  .word EXIT

