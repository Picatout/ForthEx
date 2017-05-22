;****************************************************************************
; Copyright 2015,2016,2017 Jacques Desch�nes
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
; NOM: eds.s
; DATE: 2017-05-21
; DESCRIPTION: 
;   Certains PIC24 et dsPIC33 poss�dent de la m�moire RAM au-del� de l'adresse
;   32767 (0x7FFF) Microchip appelle cette m�moire EDS (Extended Data Space).
;   Cette plage d'adresse entre en conflit avec la plage d'adresse PSV (Progam Visibility Space).
;   Il y a donc un m�canisme qui permet de diff�riencier ces 2 plages en utilisant
;   les registres DSRPAG et DSWPAG.  Puisque la machine virtuelle de ForthEx fonctionne
;   en lisant des listes d'adresses aussi bien en RAM qu'en FLASH le registre DSRPAG
;   qui d�termine qu'elle plage sera acc�d�e en lecture est configur� par d�faut pour
;   accc�d� la plage {0..32766} de la m�moire FLASH l� o� r�side le syst�me Forth.
;   Cependant il doit-exist� un m�canisme pour lire la m�moire EDS. Ce m�canisme
;   est constitu� d'une s�rie de mots sp�ciaux qui acc�dent cette m�moire en lecture.
;       
;   Pour l'acc�s en �criture ForthEx est configur�e par d�faut pour acc�der la m�moire
;   EDS puisque de toute fa�on on ne peut �crire en m�moire FLASH. Il n'est donc pas
;   n�cessaire d'avoir de mots sp�ciaux pour l'�criture dans la m�moire EDS.
    
; nom: E@  ( a-addr -- n )    
;   Retourne l'entier contenu � l'adresse a-addr. 
;   L'adresse doit-�tre align�e sur un nombre pair.    
;   Les adresses > 32767 acc�dent la m�moire EDS.
; arguments:
;   a-addr  Adresse � lire.
; retourne:
;   n	Entier contenu � cette adresse.    
DEFCODE "E@",2,,EFETCH ; ( addr -- n )
    SET_EDS
    mov [T],T
    RESET_EDS
    NEXT
    
; nom: EC@  ( c-addr -- c )    
;   Retourne le caract�re contenu � l'adressse c-addr.
;   Cette adresse est align�e sur un octet.    
;   Les adresses > 32767 acc�s la m�moire EDS.    
; arguments:
;   c-addr   Adresse � lire.
; retourne:
;   c	Caract�re contenu � cette adresse.    
DEFCODE "EC@",3,,ECFETCH 
    SET_EDS
    mov.b [T],T
    ze T,T
    RESET_EDS
    NEXT

; nom: ETBL@  ( n a-addr -- n )
;   Retourne l'�l�ment n d'un vecteur. Les valeurs d'indice d�bute � z�ro.
;   L'adresse de la table doit-�tre align�e sur une adresse paire.
;   Les adresses > 32767 sont en m�moire EDS.    
; arguments:
;   n  Indice dans le vecteur.
;   a-addr  Adresse du vecteur.
; retourne:
;   n    Valeur de l'�l�ment n du vecteur.    
DEFCODE "ETBL@",5,,ETBLFETCH
    SET_EDS
    mov [DSP--],W0
    mov #CELL_SIZE,W1
    mul.uu W1,W0,W0
    add T,W0,W0
    mov [W0],T
    RESET_EDS
    NEXT


